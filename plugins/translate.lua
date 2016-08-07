do

local mime = require("mime")
require("./plugins/hastebin")

local bing_key = cred_data.bing_key
local accountkey = mime.b64(bing_key..':'..bing_key)

local function translate(source_lang, target_lang, text)
  if not target_lang then target_lang = 'de' end
  local url = 'https://api.datamarket.azure.com/Bing/MicrosoftTranslator/Translate?$format=json&Text=%27'..URL.escape(text)..'%27&To=%27'..target_lang..'%27&From=%27'..source_lang..'%27'
  local response_body = {}
  local request_constructor = {
      url = url,
      method = "GET",
      sink = ltn12.sink.table(response_body),
      headers = {
	    Authorization = "Basic "..accountkey
	  }
  }
  local ok, response_code, response_headers, response_status_line = https.request(request_constructor)
  if not ok or response_code ~= 200 then return 'Ein Fehler ist aufgetreten.' end

  local trans = json:decode(table.concat(response_body)).d.results[1].Text

  return trans
end

local function detect_language(text)
  local url = 'https://api.datamarket.azure.com/Bing/MicrosoftTranslator/Detect?$format=json&Text=%27'..URL.escape(text)..'%27'
  local response_body = {}
  local request_constructor = {
      url = url,
      method = "GET",
      sink = ltn12.sink.table(response_body),
      headers = {
	    Authorization = "Basic "..accountkey
	  }
  }
  local ok, response_code, response_headers, response_status_line = https.request(request_constructor)
  if not ok or response_code ~= 200 then return 'en' end
  
  local language = json:decode(table.concat(response_body)).d.results[1].Code
  print('Erkannte Sprache: '..language)
  return language
end

local function get_all_languages()
  local url = 'https://api.datamarket.azure.com/Bing/MicrosoftTranslator/GetLanguagesForTranslation?$format=json'
  local response_body = {}
  local request_constructor = {
      url = url,
      method = "GET",
      sink = ltn12.sink.table(response_body),
      headers = {
	    Authorization = "Basic "..accountkey
	  }
  }
  local ok, response_code, response_headers, response_status_line = https.request(request_constructor)
  if not ok or response_code ~= 200 then return 'Ein Fehler ist aufgetreten.' end
  
  local lang_table = json:decode(table.concat(response_body)).d.results
  
  local languages = ""
  for i in pairs(lang_table) do
    languages = languages..lang_table[i].Code..'\n'
  end
  
  local link = upload(languages)
  return link
end

local function run(msg, matches)
  if matches[1] == '!getlanguages' then
    return get_all_languages()
  end
  
  if matches[1] == 'whatlang' and matches[2] then
    local text = matches[2]
	local lang = detect_language(text)
	return 'Erkannte Sprache: '..lang
  end

  -- Third pattern
  if #matches == 1 then
    print("First")
    local text = matches[1]
	local language = detect_language(text)
    return translate(language, nil, text)
  end

  -- Second pattern
  if #matches == 3 and matches[1] == "to:" then
    print("Second")
    local target = matches[2]
    local text = matches[3]
	local language = detect_language(text)
    return translate(language, target, text)
  end

  -- First pattern
  if #matches == 3 then
    print("Third")
    local source = matches[1]
    local target = matches[2]
    local text = matches[3]
    return translate(source, target, text)
  end

end

return {
  description = "Übersetze Text", 
  usage = {
    "!translate [Text]: Übersetze Text in deutsch",
    "!translate to:Zielsprache [Text]: Übersetze Text in Zielsprache",
    "!translate Quellsprache,Zielsprache [Text]: Übersetze Text von beliebiger Sprache in beliebige Sprache",
	"!getlanguages: Postet alle verfügbaren Sprachcodes",
	"!whatlang [Text]: Gibt erkannte Sprache zurück"
  },
  patterns = {
    "^!translate ([%w]+),([%a]+) (.+)",
    "^!translate (to%:)([%w]+) (.+)",
    "^!translate (.+)",
	"^!getlanguages$",
	"^!(whatlang) (.+)"
  }, 
  run = run 
}

end

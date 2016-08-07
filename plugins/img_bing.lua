do

local mime = require("mime")

local _blacklist

local function getBingeImage(text)
  local bing_key = cred_data.bing_key
  local accountkey = mime.b64(bing_key..':'..bing_key)
  local url = 'https://api.datamarket.azure.com/Bing/Search/Image?$format=json&Query=%27'..URL.escape(text)..'%27'
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
  if not ok or response_code ~= 200 then return nil end

  local bing = json:decode(table.concat(response_body)).d.results
  return bing
end

local function show_blacklist()
  if not _blacklist[1] then
    return "Keine Wörter geblacklisted!\nBlackliste welche mit !imgblacklist add [Wort]"
  else
    local sort_alph = function( a,b ) return a < b end
    table.sort( _blacklist, sort_alph )
    local blacklist = "Folgende Wörter stehen auf der Blacklist:\n"
    for v,word in pairs(_blacklist) do
      blacklist = blacklist..'- '..word..'\n'
    end
	return blacklist
  end
end

local function add_blacklist()
  print('Blacklisting '..word..' - saving to redis set telegram:img_blacklist')
  if redis:sismember("telegram:img_blacklist", word) == true then
    return '"'..word..'" steht schon auf der Blacklist.'
  else
    redis:sadd("telegram:img_blacklist", word)
    return '"'..word..'" blacklisted!'
  end
end

local function remove_blacklist()
  print('De-blacklisting '..word..' - removing from redis set telegram:img_blacklist')
  if redis:sismember("telegram:img_blacklist", word) == true then
    redis:srem("telegram:img_blacklist", word)
    return '"'..word..'" erfolgreich von der Blacklist gelöscht!'
  else
    return '"'..word..'" steht nicht auf der Blacklist.'
  end
end

local function cache_bing_image(results, text)
  local cache = {}
  for v in pairs(results) do
    table.insert(cache, results[v].MediaUrl)
  end
  cache_data('img_bing', string.lower(text), cache, 1209600, 'set')
end

local function run(msg, matches)
  local receiver = get_receiver(msg)
  local text = matches[1]
  _blacklist = redis:smembers("telegram:img_blacklist")
  
  print ('Checking if search contains blacklisted words: '..text)
  if is_blacklisted(text) then
    return "Vergiss es ._."
  end
  
  local hash = 'telegram:cache:img_bing:'..string.lower(text)
  local results = redis:smembers(hash)
  if not results[1] then
    print('doing web request')
    results = getBingeImage(text)
    if not results[1] then
      return "Kein Bild gefunden!"
    end
    cache_bing_image(results, text)
  end
  
    -- Random image from table
  local i = math.random(#results)
  local url = nil
  
  local failed = true
  local nofTries = 0
  while failed and nofTries < #results do 
      if not results[i].MediaUrl then
        url = results[i]
	  else
	    url = results[i].MediaUrl
	  end
	  print("Bilder-URL: ", url)
	  
	  if string.ends(url, ".gif") then
		failed = not send_document_from_url(receiver, url, nil, nil, true)
	  elseif string.ends(url, ".jpg") or string.ends(url, ".jpeg") or string.ends(url, ".png") then
		failed = not send_photo_from_url(receiver, url, nil, nil, true)
	  end
	  
	  nofTries = nofTries + 1
	  i = i+1
	  if i > #results then
		i = 1
	  end 
  end
  
  if failed then
	  return "Fehler beim Herunterladen eines Bildes."
  end
end

return {
  description = "Sucht Bild mit Bing-API und versendet es (SafeSearch aktiv)", 
  usage = {
    "!bingimg [Suchbegriff]"
  },
  patterns = {
    "^!bingimg (.*)$"
  }, 
  run = run 
}
end
do

local BASE_URL = 'http://api.golem.de/api'


function get_golem_articles ()
  local apikey = cred_data.golem_apikey
  local limit = 3 -- Anzahl der Artikel, geht von 1 - 50
  local url = BASE_URL..'/article/latest/limit/?key='..apikey..'&format=json&limit='..limit
  local res,code  = http.request(url)
  if code ~= 200 then return "HTTP-FEHLER" end
  local data = json:decode(res).data
  return data
end

local function send_golem_articles(data, receiver)
  local text = ""
  for article in pairs(data) do
    local headline = data[article].headline
	local abstracttext = data[article].abstracttext
	local url = data[article].url
    text = text..headline..'\n'..abstracttext..'\n— '..url..'\n\n'
  end
  send_large_msg(receiver, text, ok_cb, false)
end

local function run(msg, matches)
  local data = get_golem_articles()
  local receiver = get_receiver(msg)
  send_golem_articles(data, receiver)
end

return {
  description = "Sendet aktuelle Golem-Artikel", 
  usage = "!golem: Sendet aktuelle Golem-Artikel (Anzahl: 3)",
  patterns = {"^!golem$"},
  run = run 
}

end

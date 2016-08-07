local BASE_URL = 'https://www.tagesschau.de/api'

local makeOurDate = function(dateString)
  local pattern = "(%d+)%-(%d+)%-(%d+)T(%d+)%:(%d+)%:(%d+)"
  local year, month, day, hours, minutes, seconds = dateString:match(pattern)
  return day..'.'..month..'.'..year..' um '..hours..':'..minutes..':'..seconds
end

local function get_tagesschau_article(article, receiver)
  local url = BASE_URL..'/'..article..'.json'
  local res,code  = https.request(url)
  local data = json:decode(res)
  if code == 404 then return "Artikel nicht gefunden!" end
  if code ~= 200 then return "HTTP-Fehler" end
  if not data then return "HTTP-Fehler" end
  if data.type ~= "story" then
    print('Typ "'..data.type..'" wird nicht unterstützt')
    send_typing_abort(receiver, ok_cb, true)
    return nil
  end
  
  local title = data.topline..': '..data.headline
  local news = data.shorttext
  local posted_at = makeOurDate(data.date)..' Uhr'
  if data.banner[1] then
    send_photo_from_url(receiver, data.banner[1].variants[1].modPremium)
  end
  
  local text = title..'\n'..posted_at..'\n'..news
  return text
end

local function run(msg, matches)
  local article = matches[1]
  local text = get_tagesschau_article(article, get_receiver(msg))
  return text
end

return {
  description = "Sendet Tagesschau-Artikel", 
  usage = "Link zu Tagesschau-Artikel",
  patterns = {"tagesschau.de/([A-Za-z0-9-_-_-/]+).html"},
  run = run 
}

end
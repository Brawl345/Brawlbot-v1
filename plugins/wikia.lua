do

local BASE_URL = '.wikia.com/api/v1/Articles/Details?abstract=400'

function send_wikia_article (wikia, article)
  local url = 'http://'..wikia..BASE_URL..'&titles='..article
  local res,code  = http.request(url)
  if code ~= 200 then return "HTTP-FEHLER" end
  if string.match(res, "Not a valid Wikia") then return 'Kein valides Wikia!' end
  local data = json:decode(res)

  local keyset={}
  local n=0
  for id,_ in pairs(data.items) do
    n=n+1
    keyset[n]=id
  end
  
  local id = keyset[1]
  if not id then return 'Diese Seite existiert nicht!' end

  local title = data.items[id].title
  local abstract = data.items[id].abstract
  local article_url = data.basepath..data.items[id].url
  
  local text = title..':\n'..abstract..'\n— '..article_url
  return text
end

function run(msg, matches)
  local wikia = matches[1]
  local article = matches[2]
  return send_wikia_article(wikia, article)
end

return {
  description = "Sendet Wikia-Artikel.", 
  usage = "URL zu Wikia-Artikel in irgendeinem Wikia",
  patterns = {"https?://(.+).wikia.com/wiki/(.+)"},
  run = run 
}

end

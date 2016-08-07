do

local function get_heise_article(article)
  local url = 'https://query.yahooapis.com/v1/public/yql?q=select%20content,src,strong%20from%20html%20where%20url=%22http://www.heise.de/newsticker/meldung/'..article..'.html%22%20and%20xpath=%22//div[@id=%27mitte_news%27]/article/header/h2|//div[@id=%27mitte_news%27]/article/div/p[1]/strong|//div[@id=%27mitte_news%27]/article/div/figure/img%22&format=json'
  local res,code  = https.request(url)
  local data = json:decode(res).query.results
  if code ~= 200 then return "HTTP-Fehler" end
  
  local title = data.h2
  local teaser = data.strong
  if data.img then
    image_url = 'https:'..data.img.src
  end
  local text = title..'\n'..teaser
  
  if data.img then
    return text, image_url
  else
    return text
  end
end

local function run(msg, matches)
  local article = URL.escape(matches[1])
  local text, image_url = get_heise_article(article)
  if image_url then
    local receiver = get_receiver(msg)
    local cb_extra = {
      receiver=receiver,
      url=image_url
    }
    send_msg(receiver, text, send_photo_from_url_callback, cb_extra)
  else
    return text
  end
end

return {
  description = "Sendet Heise-Artikel", 
  usage = "Link zu Heise-Artikel",
  patterns = {"heise.de/newsticker/meldung/(.*).html$"},
  run = run 
}

end
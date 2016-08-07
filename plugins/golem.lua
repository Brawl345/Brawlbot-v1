do

local BASE_URL = 'http://api.golem.de/api'

function get_golem_data (article_identifier)
  local apikey = cred_data.golem_apikey
  local url = BASE_URL..'/article/meta/'..article_identifier..'/?key='..apikey..'&format=json'
  local res,code  = http.request(url)
  if code ~= 200 then return "HTTP-FEHLER" end
  local data = json:decode(res).data
  return data
end

function send_golem_data (data, receiver)
  local headline = data.headline
  if data.subheadline ~= "" then
    subheadline = '\n'..data.subheadline
  else
    subheadline = ""
  end
  local subheadline = data.subheadline
  local abstracttext = data.abstracttext
  local text = headline..subheadline..'\n'..abstracttext
  local image_url = data.leadimg.url
  local cb_extra = {
    receiver=receiver,
    url=image_url
  }
  send_msg(receiver, text, send_photo_from_url_callback, cb_extra)
end

function run(msg, matches)
  local article_identifier = matches[2]
  local data = get_golem_data(article_identifier)
  local receiver = get_receiver(msg)
  send_golem_data(data, receiver)
end

return {
  description = "Sendet Golem-Info.", 
  usage = "URL zu Golem-Artikel",
  patterns = {"golem.de/news/([A-Za-z0-9-_-]+)-(%d+).html"},
  run = run 
}

end

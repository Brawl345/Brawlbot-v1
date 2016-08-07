do

local BASE_URL = 'https://backend.deviantart.com'

function get_da_data (da_code)
  local url = BASE_URL..'/oembed?url='..da_code
  local res,code  = https.request(url)
  if code ~= 200 then return "HTTP-FEHLER" end
  local data = json:decode(res)
  return data
end

function send_da_data(data, receiver)
  local title = data.title
  local category = data.category
  local author_name = data.author_name
  local text = title..' von '..author_name..'\n'..category
  
  if data.rating == "adult" then
    local text = title..' von '..author_name..'\n'..category..'\n(NSFW)'
    send_msg(receiver, text, ok_cb, false)
  else
    local image_url = data.fullsize_url
    if image_url == nil then
      image_url = data.url
    end 
    local cb_extra = {
    receiver=receiver,
    url=image_url
    }
    send_msg(receiver, text, send_photo_from_url_callback, cb_extra)
  end
end

function run(msg, matches)
  local da_code = 'http://'..matches[1]..'.deviantart.com/art/'..matches[2]
  local data = get_da_data(da_code)
  local receiver = get_receiver(msg)
  send_da_data(data, receiver)
end



return {
  description = "Sendet deviantArt-Info", 
  usage = "URL zu deviantArt-Werk",
  patterns = {"http://(.*).deviantart.com/art/(.*)"},
  run = run 
}

end
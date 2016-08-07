do

local BASE_URL = 'https://api.instagram.com/v1'
local access_token = cred_data.instagram_access_token

function get_insta_data (insta_code)
  local url = BASE_URL..'/media/shortcode/'..insta_code..'?access_token='..access_token
  local res,code  = https.request(url)
  if code ~= 200 then return "HTTP-FEHLER" end
  local data = json:decode(res).data
  return data
end

function send_instagram_data(data, receiver)
  -- Header
  local username = data.user.username
  local full_name = data.user.full_name
  if username == full_name then
    header = full_name..' hat ein'
  else
    header = full_name..' ('..username..') hat ein'
  end
  if data.type == 'video' then
    header = header..' Video gepostet'
  else
    header = header..' Foto gepostet'
  end
  
  -- Caption
  if data.caption == nil then
    caption = ''
  else
    caption = ':\n'..data.caption.text
  end
  
  -- Footer
  local comments = comma_value(data.comments.count)
  local likes = comma_value(data.likes.count)
  local footer = '\n'..likes..' Likes, '..comments..' Kommentare'
  if data.type == 'video' then
    footer = '\n'..data.videos.standard_resolution.url..footer
  end
  
  -- Image
  local image_url = data.images.standard_resolution.url
  local cb_extra = {
    receiver=receiver,
    url=image_url
  }
  
  -- Send all
  send_msg(receiver, header..caption..footer, send_photo_from_url_callback, cb_extra)
end

function run(msg, matches)
  local insta_code = matches[1]
  local data = get_insta_data(insta_code)
  local receiver = get_receiver(msg)
  send_instagram_data(data, receiver)
end

return {
  description = "Sendet Instagram-Info.", 
  usage = "URL zu Instagram-Post",
  patterns = {"instagram.com/p/([A-Za-z0-9-_-]+)"},
  run = run 
}

end

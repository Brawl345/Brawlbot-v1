do

local BASE_URL = 'https://api.flickr.com/services/rest'

function get_flickr_photo_data (photo_id)
  local apikey = cred_data.flickr_apikey
  local url = BASE_URL..'/?method=flickr.photos.getInfo&api_key='..apikey..'&photo_id='..photo_id..'&format=json&nojsoncallback=1'
  local res,code  = https.request(url)
  if code ~= 200 then return "HTTP-FEHLER" end
  local data = json:decode(res).photo
  return data
end

function send_flickr_photo_data(data, receiver)
  local title = data.title._content
  local username = data.owner.username
  local taken = data.dates.taken
  local views = data.views
  if data.usage.candownload == 1 then
    local text = '"'..title..'", aufgenommen '..taken..' von '..username..' ('..data.views..' Aufrufe)'
    local image_url = 'https://farm'..data.farm..'.staticflickr.com/'..data.server..'/'..data.id..'_'..data.originalsecret..'_o_d.'..data.originalformat
    local cb_extra = {
      receiver=receiver,
      url=image_url
    }
	if data.originalformat == 'gif' then
	  send_msg(receiver, text, send_document_from_url_callback, cb_extra)
	else
	  send_msg(receiver, text, send_photo_from_url_callback, cb_extra)
	end
  else
    local text = '"'..title..'", aufgenommen '..taken..' von '..username..' ('..data.views..' Aufrufe)\nBild konnte nicht gedownloadet werden (Keine Berechtigung)'
    send_msg(receiver, text, ok_cb, false)
  end
end

function run(msg, matches)
  local photo_id = matches[2]
  local data = get_flickr_photo_data(photo_id)
  local receiver = get_receiver(msg)
  send_flickr_photo_data(data, receiver)
end

return {
  description = "Sendet Flickr-Info.", 
  usage = "URL zu Flickr-Foto",
  patterns = {"flickr.com/photos/([A-Za-z0-9-_-]+)/([0-9]+)"},
  run = run 
}

end

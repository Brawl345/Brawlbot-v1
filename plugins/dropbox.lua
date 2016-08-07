do

local function send_dropbox_data(link, receiver)
  if string.ends(link, ".png") or string.ends(link, ".jpeg") or string.ends(link, ".jpg") then
    send_photo_from_url(receiver, link)
  elseif string.ends(link, ".webp") or string.ends(link, ".gif") then
    send_document_from_url(receiver, link)
  else
    send_msg(receiver, link, ok_cb, false)
  end
end

local function run(msg, matches)
  local folder = matches[1]
  local file = matches[2]
  local receiver = get_receiver(msg)
  local link = 'https://dl.dropboxusercontent.com/s/'..folder..'/'..file
  
  local v,code  = https.request(link)
  if code == 200 then
    send_dropbox_data(link, receiver)
  else
    return nil
  end
end


return {
  description = "Dropbox-Plugin", 
  usage = {
    "Dropbox-URL: Postet Bild oder Direktlink"
  },
  patterns = {
    "dropbox.com/s/([a-z0-9]+)/([A-Za-z0-9-_-.-.-]+)"
  }, 
  run = run 
}
end
do

-- Thanks to Akamaru for the API entrypoints and the idea

local function send_gfycat_video(name, receiver)
  local BASE_URL = "https://gfycat.com"
  local url = BASE_URL..'/cajax/get/'..name
  local res,code  = https.request(url)
  if code ~= 200 then return "HTTP-FEHLER" end
  local data = json:decode(res).gfyItem
  local file = download_to_file(data.webmUrl)
  local cb_extra = {file_path=file}
  if file == nil then
	send_msg(receiver, 'Fehler beim Herunterladen von '..name, ok_cb, false)
  else
    send_video(receiver, file, rmtmp_cb, cb_extra)
  end
end

local function send_gfycat_thumb(name, receiver)
  local BASE_URL = "https://thumbs.gfycat.com"
  local url = BASE_URL..'/'..name..'-poster.jpg'
  local file = download_to_file(url)
  local cb_extra = {file_path=file}
  if file == nil then
	print('Fehler beim Herunterladen des Thumbnails von '..name)
  else
    send_photo(receiver, file, rmtmp_cb, cb_extra)
  end
end

local function run(msg, matches)
  local name = matches[1]
  local receiver = get_receiver(msg)
  send_gfycat_video(name, receiver)
  if matches[2] ~= 'NSFW' then
    send_gfycat_thumb(name, receiver)
  end
end

return {
  description = "Postet Gfycat-Video",
  usage = "URL zu gfycat-Video (hänge 'NSFW' an, wenn es NSFW ist)",
  patterns = {
    "gfycat.com/([A-Za-z0-9-_-]+) (NSFW)",
    "gfycat.com/([A-Za-z0-9-_-]+)"
  }, 
  run = run
}

end
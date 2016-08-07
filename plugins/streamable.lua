local function send_streamable_video(shortcode, receiver)
  local BASE_URL = "https://api.streamable.com"
  local url = BASE_URL..'/videos/'..shortcode
  local res,code  = https.request(url)
  if code ~= 200 then return 'HTTP-Fehler' end
  local data = json:decode(res)
  if data.status ~= 2 then return "Video ist (noch) nicht verfügbar." end
  
  if data.files.webm then
    if data.title == "" then title = shortcode..'.webm' else title = data.title..'.webm' end
    url = 'https:'..data.files.webm.url
    if data.files.webm.size > 20000000 then
	  local size = math.floor(data.files.webm.size / 1000000)
	  return 'Video ist größer als 20 MB ('..size..' MB)!\nDirektlink: '..url
	end
  elseif data.files.mp4 then
    if data.title == "" then title = shortcode..'.mp4' else title = data.title..'.mp4' end
    url = 'https:'..data.files.mp4.url
    if data.files.mp4.size > 20000000 then
	  local size = math.floor(data.files.mp4.size / 1000000)
	  return 'Video ist größer als 20 MB ('..size..' MB)!\nDirektlink: '..url
	end
  end
  
  local file = download_to_file(url, title)
  local cb_extra = {file_path=file}
  send_video(receiver, file, rmtmp_cb, cb_extra)
end

local function run(msg, matches)
  local shortcode = matches[1]
  local receiver = get_receiver(msg)
  
  if string.len(shortcode) > 4 then
    send_typing_abort(receiver, ok_cb, true)
    return nil
  end

  return send_streamable_video(shortcode, receiver)
end

return {
  description = "Postet Streamable-Video",
  usage = "URL zu Streamable-Video",
  patterns = {
    "streamable.com/([A-Za-z0-9-_-]+)",
  }, 
  run = run
}

end
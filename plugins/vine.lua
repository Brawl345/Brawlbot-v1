-- This is a proprietary plugin, property of Andreas Bielawski, (c) 2015+ <andi (dot) b (at) outlook (dot) de>do

local BASE_URL = 'https://vine.co'

local function get_vine_data (vine_code)
  local res, code = https.request(BASE_URL..'/v/'..vine_code..'/embed/simple')
  if code ~= 200 then return "HTTP-FEHLER" end
  local json_data = string.match(res, '<script type%="application/json" id%="configuration">(.-)</script>')
  local data = json:decode(json_data).post
  return data
end

local function send_vine_data(data, receiver)
  local title = data.description
  local author_name = data.user.username
  local creation_date = data.createdPretty
  local loops = data.loops.count
  local video_url = data.videoUrls[1].videoUrl
  local profile_name = string.gsub(data.user.profileUrl, '/', '')
  local text = '"'..title..'", hochgeladen von '..author_name..' ('..profile_name..') im '..creation_date..', '..loops..'x angesehen'
  if data.explicitContent == 1 then
    text = text..' (🔞 NSFW 🔞)'
  end
  
  --[[ Send image if not NSFW (remove comment to enable)
  if data.explicitContent == 1 then
    send_msg(receiver, text, ok_cb, false)
  else
    local cb_extra = {
      receiver=receiver,
      url=data.thumbnailUrl
    }
    send_msg(receiver, text, send_photo_from_url_callback, cb_extra) 
  end --]]
  
  -- Send text, put comment to disable and remove comment above to enable
  -- posting of thumbnail image
  send_msg(receiver, text, ok_cb, false)
  
  -- Send video
  local file = download_to_file(video_url, data.shortId..'.mp4')
  local cb_extra = {file_path=file}
  send_video(receiver, file, rmtmp_cb, cb_extra)
end

local function run(msg, matches)
  local vine_code = matches[1]
  local data = get_vine_data(vine_code)
  local receiver = get_receiver(msg)
  send_vine_data(data, receiver)
end

return {
  description = "Sendet Vine-Info.", 
  usage = "URL zu Vine.co-Video",
  patterns = {"vine.co/v/([A-Za-z0-9-_-]+)"},
  run = run 
}

end

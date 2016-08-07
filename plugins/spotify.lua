do

local BASE_URL = 'https://api.spotify.com/v1'

function get_track_data (track)
  local url = BASE_URL..'/tracks/'..track
  local res,code  = https.request(url)
  if code ~= 200 then return "HTTP-FEHLER" end
  local data = json:decode(res)
  return data
end

function send_track_data(data, receiver)
	local name = data.name
    local album = data.album.name
    local artist = data.artists[1].name
	local preview = data.preview_url
	local milliseconds = data.duration_ms
	
	-- convert s to mm:ss
	local totalseconds = math.floor(milliseconds / 1000)
    local duration = makeHumanTime(totalseconds)
	
    local text = '"'..name..' von '..artist..'" aus dem Album "'..album..'" ('..duration..')'
	if preview then
	  local file = download_to_file(preview, 'VORSCHAU: '..name..'.mp3')
      send_msg(receiver, text, ok_cb, false)
	  send_document(receiver, file, ok_cb, false)
	else
	  send_msg(receiver, text, ok_cb, false)
	end
end

function run(msg, matches)
  local track = matches[1]
  local data = get_track_data(track)
  local receiver = get_receiver(msg)
  send_track_data(data, receiver)
end

return {
  description = "Sendet Spotify-Info.", 
  usage = "Link zu Spotify-Track",
  patterns = {
    "open.spotify.com/track/([A-Za-z0-9-]+)",
    "play.spotify.com/track/([A-Za-z0-9-]+)"
  },
  run = run 
}

end

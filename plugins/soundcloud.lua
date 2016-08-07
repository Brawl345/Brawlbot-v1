do

local BASE_URL = 'http://api.soundcloud.com/resolve.json'

function send_soundcloud_info (sc_url)
  local client_id = cred_data.soundcloud_client_id
  local url = BASE_URL..'?url=http://soundcloud.com/'..sc_url..'&client_id='..client_id

  local res,code  = http.request(url)
  if code ~= 200 then return "HTTP-FEHLER" end
  local data = json:decode(res)
  
  local title = data.title
  local description = data.description
  local user = data.user.username
  local user = 'Unbekannt'
  local genre = data.genre
  local playback_count = data.playback_count
  local milliseconds = data.duration

  -- convert ms to hh:mm:ss
  local totalseconds = math.floor(milliseconds / 1000)
  local milliseconds = milliseconds % 1000
  local seconds = totalseconds % 60
  local minutes = math.floor(totalseconds / 60)
  local hours = math.floor(minutes / 60)
  local duration = string.format("%02d:%02d:%02d", hours,  minutes, seconds)
  
  local text = '"'..title..'" von "'..user..'"\n(Tag: '..genre..', '..duration..' Stunden; '..playback_count..' mal angehört)\n'..description
  return text
end

function run(msg, matches)
  local sc_url = matches[1]
  return send_soundcloud_info(sc_url)
end

return {
  description = "Sendet Soundcloud-Info.", 
  usage = "Link zu SoundCloud-Track",
  patterns = {"soundcloud.com/([A-Za-z0-9-/-_-.]+)"},
  run = run 
}

end

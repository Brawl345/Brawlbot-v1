do

local BASE_URL = 'https://api.spotify.com/v1/search'


local function get_spotify_result (track)
  local limit = '4'
  local url = BASE_URL..'?type=track&q='..track..'&market=DE&limit='..limit
  local res,code  = https.request(url)
  if code ~= 200 then return "HTTP-FEHLER" end
  local data = json:decode(res).tracks
  if not data.items[1] then return 'Nichts gefunden!' end
  return data
end

local function send_spotify_data(data, receiver)
  local text = ""
  for track in pairs(data.items) do
    text = text..'"'..data.items[track].name..'" von '..data.items[track].artists[1].name
	  
	if data.items[track].album.name and data.items[track].album.name ~= data.items[track].name then
	  text = text..' aus dem Album '..data.items[track].album.name
	end
	
	-- convert ms to mm:ss
	local milliseconds = data.items[track].duration_ms
	local totalseconds = math.floor(milliseconds / 1000)
    local milliseconds = milliseconds % 1000
    local seconds = totalseconds % 60
    local minutes = math.floor(totalseconds / 60)
    local hours = math.floor(minutes / 60)
    local minutes = minutes % 60
	local duration = string.format("%02d:%02d",  minutes, seconds)
	
	text = text..'\nLänge: '..duration

    if data.items[track].preview_url then
      text = text..'\nVorschau: '..data.items[track].preview_url
    end
	
	text = text..'\n'..data.items[track].external_urls.spotify..'\n\n'
	
  end
  send_large_msg(receiver, text, ok_cb, false)
end

local function run(msg, matches)
  local track = URL.escape(matches[1])
  local data = get_spotify_result(track)
  if data == "Nichts gefunden!" then
    return 'Nichts gefunden!'
  elseif not data then
    return 'HTTP-Fehler!'
  else
    local receiver = get_receiver(msg)
    send_spotify_data(data, receiver)
  end
end

return {
  description = "Sucht nach Tracks auf Spotify", 
  usage = "!spotify [Track]: Sucht nach einem Track auf Spotify",
  patterns = {"^!spotify (.*)$"},
  run = run 
}

end

do

local BASE_URL = 'https://vimeo.com/api/v2'

function send_vimeo_data (vimeo_code)
  local url = BASE_URL..'/video/'..vimeo_code..'.json'
  local res,code  = http.request(url)
  if code ~= 200 then return "HTTP FEHLER" end
  local data = json:decode(res)
  
  local title = data[1].title
  local uploader = data[1].user_name
  local totalseconds = data[1].duration
  
  -- convert s to hh:mm:ss
  local seconds = totalseconds % 60
  local minutes = math.floor(totalseconds / 60)
  local minutes = minutes % 60
  local hours = math.floor(totalseconds / 3600)
  local duration = string.format("%02d:%02d:%02d", hours,  minutes, seconds)
  
  if not data[1].stats_number_of_plays then
    return title..'\n(Hochgeladen von: '..uploader..', '..duration..' Stunden)'
  else
    local viewCount = ', '..data[1].stats_number_of_plays..' mal angsehen)' or ""
	return title..'\n(Hochgeladen von: '..uploader..', '..duration..' Stunden'..viewCount
  end
end

function run(msg, matches)
  local vimeo_code = matches[1]
  return send_vimeo_data(vimeo_code)
end

return {
  description = "Sendet Vimeo-Info.", 
  usage = "URL zu Vimeo-Video",
  patterns = {"vimeo.com/(%d+)"},
  run = run 
}

end

do

local BASE_URL = 'https://api.dailymotion.com'

function send_dailymotion_info (dm_code)
  local url = BASE_URL..'/video/'..dm_code
  local res,code  = https.request(url)
  if code ~= 200 then return "HTTP-FEHLER" end
  local data = json:decode(res)
  
  local title = data.title
  local channel = data.channel
  local text = title..'\nHochgeladen in die Kategorie "'..channel..'"'
  return text
end

function run(msg, matches)
  local dm_code = matches[1]
  return send_dailymotion_info(dm_code)
end

return {
  description = "Sendet Dailymotion-Info.", 
  usage = "URL zu Dailymotion-Video",
  patterns = {"dailymotion.com/video/([A-Za-z0-9-_-]+)"},
  run = run 
}

end

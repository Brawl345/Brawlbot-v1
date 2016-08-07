do

local BASE_URL = 'https://api.twitch.tv'

function send_twitch_info (twitch_name)
  local url = BASE_URL..'/kraken/channels/'..twitch_name
  local res,code  = https.request(url)
  if code ~= 200 then return "HTTP-FEHLER" end
  local data = json:decode(res)

  local display_name = data.display_name
  local name = data.name
  if not data.game then
    game = 'nichts'
  else
    game = data.game
  end
  local status = data.status
  local views = comma_value(data.views)
  local followers = comma_value(data.followers)
  local text = display_name..' ('..name..') streamt '..game..'\n'..status..'\n'..views..' Zuschauer insgesamt und '..followers..' Follower'
  
  return text
end

function run(msg, matches)
  local twitch_name = matches[1]
  return send_twitch_info(twitch_name)
end

return {
  description = "Sendet Twitch-Info.", 
  usage = "URL zu Twitch-Kanal",
  patterns = {"twitch.tv/([A-Za-z0-9-_-]+)"},
  run = run 
}

end

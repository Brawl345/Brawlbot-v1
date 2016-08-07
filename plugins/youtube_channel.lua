do

local BASE_URL = 'https://www.googleapis.com/youtube/v3'

local makeOurDate = function(dateString)
  local pattern = "(%d+)%-(%d+)%-(%d+)T"
  local year, month, day = dateString:match(pattern)
  return day..'.'..month..'.'..year
end

function get_yt_channel_data (channel_name)
  local apikey = cred_data.google_apikey
  local url = BASE_URL..'/channels?part=snippet,statistics&key='..apikey..'&forUsername='..channel_name..'&fields=items%28snippet%28publishedAt,localized%28title,description%29%29,statistics%28viewCount,subscriberCount,videoCount%29%29'
  local res,code  = https.request(url)
  if code ~= 200 then return "HTTP-FEHLER" end
  local data = json:decode(res).items[1]
  if data == nil then
    local url = BASE_URL..'/channels?part=snippet,statistics&key='..apikey..'&id='..channel_name..'&fields=items%28snippet%28publishedAt,localized%28title,description%29%29,statistics%28viewCount,subscriberCount,videoCount%29%29'
    local res,code  = https.request(url)
	if code ~= 200 then return "HTTP-FEHLER" end
    data = json:decode(res).items[1]
  end
  return data
end

function send_yt_channel_data(data, receiver)
  local name = data.snippet.localized.title
  local creation_date = makeOurDate(data.snippet.publishedAt)
  local description = data.snippet.localized.description
  local views = comma_value(data.statistics.viewCount)
  local subscriber = comma_value(data.statistics.subscriberCount)
  if subscriber == "0" then subscriber = "0 (ausgblendet?)" end
  local videos = comma_value(data.statistics.videoCount)
  local text = name..', registriert am '..creation_date..' hat '..views..' Video-Aufrufe insgesamt, '..subscriber..' Abonnenten und '..videos..' Videos\n'..description
  send_msg(receiver, text, ok_cb, false)
end

function run(msg, matches)
  local channel_name = matches[1]
  local data = get_yt_channel_data(channel_name)
  local receiver = get_receiver(msg)
  send_yt_channel_data(data, receiver)
end

return {
  description = "Sendet YouTube-Kanal-Info.", 
  usage = "URL zu YouTube-Kanal",
  patterns = {
    "youtube.com/user/([A-Za-z0-9-_-]+)",
    "youtube.com/channel/([A-Za-z0-9-_-]+)"
  },
  run = run 
}

end

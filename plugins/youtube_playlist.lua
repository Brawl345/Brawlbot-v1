do

local BASE_URL = 'https://www.googleapis.com/youtube/v3'

local makeOurDate = function(dateString)
  local pattern = "(%d+)%-(%d+)%-(%d+)T"
  local year, month, day = dateString:match(pattern)
  return day..'.'..month..'.'..year
end

function get_pl_data (pl_code)
  local apikey = cred_data.google_apikey
  local url = BASE_URL..'/playlists?part=snippet,contentDetails&key='..apikey..'&id='..pl_code..'&fields=items(snippet(publishedAt,channelTitle,localized(title,description)),contentDetails(itemCount))'
  local res,code  = https.request(url)
  if code ~= 200 then return "HTTP-FEHLER" end
  local data = json:decode(res).items[1]
  return data
end

function send_youtubepl_data(data, receiver)
  local title = data.snippet.localized.title
  if data.snippet.localized.description == '(null)' or data.snippet.localized.description == '' then
    description = ''
  else
    description = '\n'..data.snippet.localized.description
  end
  local author = data.snippet.channelTitle
  local creation_date = makeOurDate(data.snippet.publishedAt)
  if data.contentDetails.itemCount == 1 then
    itemCount = data.contentDetails.itemCount..' Video'
  else
    itemCount = comma_value(data.contentDetails.itemCount)..' Videos'
  end
  local text = title..description..'\nErstellt von '..author..' am '..creation_date..', '..itemCount
  send_msg(receiver, text, ok_cb, false)
end

function run(msg, matches)
  local pl_code = matches[1]
  local data = get_pl_data(pl_code)
  local receiver = get_receiver(msg)
  send_youtubepl_data(data, receiver)
end

return {
  description = "Sendet YouTube-Playlist-Info.", 
  usage = "URL zu YouTube-Playlist",
  patterns = {"youtube.com/playlist%?list=([A-Za-z0-9-_-]+)"},
  run = run 
}

end

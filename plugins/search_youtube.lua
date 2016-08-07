
do

require("./plugins/youtube")

-- HOW TO USE:
-- 1. Go to the Google Developers Console.
-- 2. Select a project.
-- 3. In the sidebar on the left, select APIs & auth. In the list of APIs, choose "YouTube Data API" an make sure the status is ON for the YouTube Data API v3.
-- 4. In the sidebar on the left, select Credentials.
-- 5. Generate an API-Key (browser key, leave the referer field blank)
-- 6. Write this in your data/credentials.lua:
-- 	  google_apikey = "YOURKEY-HERE",
-- Your quota is 50.000.000 per day and a search takes 100 points. So if you manage to use this in one day, you're a real spammer :P

local function searchYoutubeVideo(text)
  local apikey = cred_data.google_apikey
  local data = httpsRequest('https://www.googleapis.com/youtube/v3/search?part=snippet&key='..apikey..'&maxResults=1&type=video&q=' .. URL.escape(text))
  if not data then
    print("HTTP-Fehler")
    return nil
  elseif not data.items[1] then
    return "YouTube-Video nicht gefunden!"
  end
  videoId = data.items[1].id.videoId
  videoURL = 'https://youtube.com/watch?v='..videoId
  return videoURL
end

function httpsRequest(url)
  local res,code  = https.request(url)
  if code ~= 200 then return nil end
  return json:decode(res)
end

function run(msg, matches)
  local text = msg.text:sub(string.len(matches[1]) + 1,-1)
  local link = searchYoutubeVideo(text)
  if link == "YouTube-Video nicht gefunden!" or nil then return "YouTube-Video nicht gefunden!" end
  local yt_code = videoId
  local data = get_yt_data(yt_code)
  local receiver = get_receiver(msg)
  send_youtube_data(data, receiver, link, true)
end

return {
  description = "Sucht YouTube-Video und sendet es", 
  usage = "!yt [Suchbegriff]: Sucht YouTube-Video",
  patterns = {
    "^!youtube",
    "^!yt",
	"^!duröhre"
  }, 
  run = run 
}

end

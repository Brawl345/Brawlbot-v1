local OAuth = require "OAuth"

local consumer_key = cred_data.tw_consumer_key
local consumer_secret = cred_data.tw_consumer_secret
local access_token = cred_data.tw_access_token
local access_token_secret = cred_data.tw_access_token_secret

local client = OAuth.new(consumer_key, consumer_secret, {
    RequestToken = "https://api.twitter.com/oauth/request_token", 
    AuthorizeUser = {"https://api.twitter.com/oauth/authorize", method = "GET"},
    AccessToken = "https://api.twitter.com/oauth/access_token"
}, {
    OAuthToken = access_token,
    OAuthTokenSecret = access_token_secret
})

function run(msg, matches)
  if consumer_key:isempty() then
    return "Twitter Consumer Key ist leer, führe !creds add tw_consumer_key KEY aus"
  end
  if consumer_secret:isempty() then
    return "Twitter Consumer Secret ist leer, führe !creds add tw_consumer_secret KEY aus"
  end
  if access_token:isempty() then
    return "Twitter Access Token ist leer, führe !creds add tw_access_token KEY aus"
  end
  if access_token_secret:isempty() then
    return "Twitter Access Token Secret ist leer, führe !creds add tw_access_token_secret KEY aus"
  end

  local twitter_url = "https://api.twitter.com/1.1/statuses/show/" .. matches[1] .. ".json"
  local response_code, response_headers, response_status_line, response_body = client:PerformRequest("GET", twitter_url)
  local response = json:decode(response_body)
  
  local full_name = response.user.name
  local user_name = response.user.screen_name
  if response.user.verified then
    user_name = user_name..' ✅'
  end
  local header = "Tweet von " ..full_name.. " (@" ..user_name.. ")\n"
  
  local text = response.text
  
  -- favorites & retweets
  if response.retweet_count == 0 then
    retweets = ""
  else
    retweets = response.retweet_count..'x retweeted'
  end
  if response.favorite_count == 0 then
    favorites = ""
  else
    favorites = response.favorite_count..'x favorisiert'
  end
  if retweets == "" and favorites ~= "" then
    footer = favorites
  elseif retweets ~= "" and favorites == "" then
    footer = retweets
  elseif retweets ~= "" and favorites ~= "" then
    footer = retweets..' - '..favorites
  else
    footer = ""
  end
  
  -- replace short URLs
  if response.entities.urls then
    for k, v in pairs(response.entities.urls) do 
        local short = v.url
        local long = v.expanded_url
        text = text:gsub(short, long)
    end
  end

  -- remove images
  local images = {}
  local videos = {}
  if response.entities.media and response.extended_entities.media then
    for k, v in pairs(response.extended_entities.media) do
        local url = v.url
        local pic = v.media_url_https
		if v.video_info then
		  if not v.video_info.variants[3] then
		    local vid = v.video_info.variants[1].url
			table.insert(videos, vid)
		  else
		    local vid = v.video_info.variants[3].url
		    table.insert(videos, vid)
		  end
		end
        text = text:gsub(url, "")
        table.insert(images, pic)
    end
  end
  
    -- quoted tweet
  if response.quoted_status then
    local quoted_text = response.quoted_status.text
	local quoted_name = response.quoted_status.user.name
	local quoted_screen_name = response.quoted_status.user.screen_name
	if response.quoted_status.user.verified then
      quoted_screen_name = quoted_screen_name..' ✅'
    end
	quote = 'Als Antwort auf '..quoted_name..' (@'..quoted_screen_name..'):\n'..quoted_text
	text = text..'\n\n'..quote..'\n'
  end
  
  -- send the parts 
  local receiver = get_receiver(msg)
  local text = unescape(text)
  send_msg(receiver, header .. "\n" .. text.."\n"..footer, ok_cb, false)
  for k, v in pairs(images) do
    local file = download_to_file(v)
    send_photo(receiver, file, ok_cb, false)
  end
  for k, v in pairs(videos) do
    local file = download_to_file(v)
	send_document(receiver, file, ok_cb, false)
  end

  return nil
end

return {
    description = "Sendet Tweet und Bilder in den Chat.", 
    usage = "URL zu Tweet",
    patterns = {"twitter.com/[^/]+/statuse?s?/([0-9]+)"}, 
    run = run 
}

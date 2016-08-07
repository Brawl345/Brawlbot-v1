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

local function resolve_url(url)
  local response_body = {}
  local request_constructor = {
    url = url,
    method = "HEAD",
    sink = ltn12.sink.table(response_body),
    headers = {},
    redirect = false
  }

  local ok, response_code, response_headers, response_status_line = http.request(request_constructor)
  if ok and response_headers.location then
    return response_headers.location
  else
    return url
  end
end

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

  local twitter_url = "https://api.twitter.com/1.1/users/show/"..matches[1]..".json"
  local response_code, response_headers, response_status_line, response_body = client:PerformRequest("GET", twitter_url)
  local response = json:decode(response_body)
  
  local full_name = response.name
  local user_name = response.screen_name
  if response.verified then
    user_name = user_name..' ✅'
  end
  if response.protected then
    user_name = user_name..' 🔒'
  end
  local header = full_name.. " (@" ..user_name.. ")\n"
  
  local description = unescape(response.description)
  if response.location then
    location = response.location
  else
    location = ''
  end
  if response.url and response.location ~= '' then
    url = ' | '..resolve_url(response.url)..'\n'
  elseif response.url and response.location == '' then
    url = resolve_url(response.url)..'\n'
  else
    url = '\n'
  end
  
  local body = description..'\n'..location..url
  
  local favorites = comma_value(response.favourites_count)
  local follower = comma_value(response.followers_count)
  local following = comma_value(response.friends_count)
  local statuses = comma_value(response.statuses_count)
  local footer = statuses..' Tweets, '..follower..' Follower, '..following..' folge ich, '..favorites..' Tweets favorisiert'
  local pic_url = string.gsub(response.profile_image_url_https, "normal", "400x400")
  send_photo_from_url(get_receiver(msg), pic_url)
  

  return header..body..footer
end

return {
    description = "Sendet Informationen über Twitter-User", 
    usage = "URL zu Twitter-User",
    patterns = {"twitter.com/([A-Za-z0-9-_-.-_-]+)$"}, 
    run = run 
}

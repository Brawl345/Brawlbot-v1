local BASE_URL = 'https://disqus.com/api'
local api_key = cred_data.disqus_api_key -- API Key, NOT Access-Token!


-- 2016-02-17T17:43:47
local makeOurDate = function(dateString)
  local pattern = "(%d+)%-(%d+)%-(%d+)T(%d+)%:(%d+)%:(%d+)"
  local year, month, day, hour, minute, second = dateString:match(pattern)
  return day..'.'..month..'.'..year..' um '..hour..':'..minute..':'..second
end

local function get_disqus_comment(access_token, comment_id)
  local url = BASE_URL..'/3.0/posts/details.json?post='..comment_id..'&api_key='..api_key
  local res,code  = https.request(url)
  if code ~= 200 then return "HTTP-FEHLER" end
  local data = json:decode(res).response
  
  local name = data.author.name
  local forum = data.forum
  local likes = data.likes
  local comment = data.raw_message
  local created_at = makeOurDate(data.createdAt)
  
  local header = name..' am '..created_at..' auf '..forum..':\n'
  if likes == 0 then
    footer = ''
  elseif likes == 1 then
    footer = '\n'..likes..' Like'
  else
    footer = '\n'..likes..' Likes'
  end
  return header..comment..footer
end

local function run(msg, matches)
  if not api_key or api_key == '' then
    return "DISQUS API-Key ist leer, führe !creds add disqus_api_secret [KEY] aus!"
  end
  
  return get_disqus_comment(access_token, matches[2])
end
  
return {
    description = "DISQUS für Telegram", 
    usage = "Link zu DISQUS-Kommentar (mit ID, also #comment-[ID]): Postet Kommentar",
    patterns = {
	  "https?://(.*)/%#comment%-(%d+)",
	  "^!(disqus)$",
	  "^!disqus (auth) (.+)$"
	}, 
    run = run
}

end
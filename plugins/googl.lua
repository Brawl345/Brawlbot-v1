do

local BASE_URL = 'https://www.googleapis.com/urlshortener/v1'

local makeOurDate = function(dateString)
  local pattern = "(%d+)%-(%d+)%-(%d+)"
  -- 2015-10-24T13:17:53.446+00:00
  local year, month, day = dateString:match(pattern)
  return day..'.'..month..'.'..year
end

local function send_googl_info (shorturl)
  local apikey = cred_data.google_apikey
  local url = BASE_URL..'/url?key='..apikey..'&shortUrl=http://goo.gl/'..shorturl..'&projection=FULL&fields=longUrl,created,analytics(allTime(shortUrlClicks))'
  local res,code  = https.request(url)
  if code ~= 200 then return "HTTP-FEHLER" end
  local data = json:decode(res)
  
  local longUrl = data.longUrl
  local shortUrlClicks = data.analytics.allTime.shortUrlClicks
  local created = makeOurDate(data.created)
  local text = longUrl..'\n'..shortUrlClicks..' mal geklickt (erstellt am '..created..')'
  
  return text
end

local function run(msg, matches)
  local shorturl = matches[1]
  return send_googl_info(shorturl)
end

return {
  description = "Sendet Goo.gl-Info.", 
  usage = "Goo.gl-Link",
  patterns = {"goo.gl/([A-Za-z0-9-_-/-/]+)"},
  run = run 
}

end

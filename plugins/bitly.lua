do

local BASE_URL = 'https://api-ssl.bitly.com/v3/expand'

local function expand_bitly_link (shorturl)
  local access_token = cred_data.bitly_access_token
  local url = BASE_URL..'?access_token='..access_token..'&shortUrl=https://bit.ly/'..shorturl
  local res,code  = https.request(url)
  if code ~= 200 then return "HTTP-FEHLER" end
  local data = json:decode(res).data.expand[1]
  cache_data('bitly', shorturl, data)
  return data.long_url
end

local function run(msg, matches)
  local shorturl = matches[1]
  local hash = 'telegram:cache:bitly:'..shorturl
  if redis:exists(hash) == false then
    return expand_bitly_link(shorturl)
  else
    local data = redis:hgetall(hash)
	return data.long_url
  end
end

return {
  description = "Verlängert Bitly-Links", 
  usage = "Verlängert bit.ly, bitly.com, j.mp und andib.tk Links",
  patterns = {
	"bit.ly/([A-Za-z0-9-_-]+)",
	"bitly.com/([A-Za-z0-9-_-]+)",
	"j.mp/([A-Za-z0-9-_-]+)",
	"andib.tk/([A-Za-z0-9-_-]+)"
  },
  run = run 
}

end

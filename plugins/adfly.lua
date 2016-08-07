local BASE_URL = 'https://andibi.tk/dl/adfly.php'

local function expand_adfly_link (adfly_code)
  local url = BASE_URL..'/?url=http://adf.ly/'..adfly_code
  local res,code  = https.request(url)
  if code ~= 200 then return "HTTP-FEHLER" end
  if res == 'Fehler: Keine Adf.ly-URL gefunden!' then return res end
  cache_data('adfly', adfly_code, res, 31536000, 'key')
  return res
end

local function run(msg, matches)
  local adfly_code = matches[1]
  local hash = 'telegram:cache:adfly:'..adfly_code
  if redis:exists(hash) == false then
    return expand_adfly_link(adfly_code)
  else
    local data = redis:get(hash)
	return data
  end
end

return {
  description = "Verlängert Adfly-Links", 
  usage = "Adf.ly-Link",
  patterns = {
	"adf.ly/([A-Za-z0-9-_-]+)"
  },
  run = run 
}

end

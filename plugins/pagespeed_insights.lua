do

local BASE_URL = 'https://www.googleapis.com/pagespeedonline/v2'

function get_pagespeed (test_url)
  local apikey = cred_data.google_apikey
  local url = BASE_URL..'/runPagespeed?url='..test_url..'&key='..apikey..'&fields=id,ruleGroups(SPEED(score))'
  local res,code  = https.request(url)
  if code ~= 200 then return "HTTP-FEHLER" end
  local data = json:decode(res)
  return data.id..' hat einen PageSpeed-Score von '..data.ruleGroups.SPEED.score..' Punkten.'
end

function run(msg, matches)
  local test_url = matches[1]
  return get_pagespeed(test_url)
end

return {
  description = "Sendet PageSpeed-Score.", 
  usage = "!speed [URL]: Sendet PageSpeed-Score dieser Seite",
  patterns = {"^!speed (https?://[%w-_%.%?%.:/%+=&]+)"},
  run = run 
}

end
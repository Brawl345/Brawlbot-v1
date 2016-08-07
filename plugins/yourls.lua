do

local SITE_URL = cred_data.yourls_site_url
local signature = cred_data.yourls_signature_token
local BASE_URL = SITE_URL..'/yourls-api.php'

local function prot_url(url)
   local url, h = string.gsub(url, "http://", "")
   local url, hs = string.gsub(url, "https://", "")
   local protocol = "http"
   if hs == 1 then
      protocol = "https"
   end
   return url, protocol
end

local function create_yourls_link (long_url, protocol, data, receiver)
  local url = BASE_URL..'?format=simple&signature='..signature..'&action=shorturl&url='..long_url
  if protocol == "http" then
    link,code  = http.request(url)
  else
    link,code  = https.request(url)
  end
  if code ~= 200 then
    link = 'Ein Fehler ist aufgetreten. '..link
  end
  send_msg(receiver, link, ok_cb, false)
end

local function run(msg, matches)
  local long_url = matches[1]
  local baseurl, protocol = prot_url(SITE_URL)
  local receiver = get_receiver(msg)
  create_yourls_link(long_url, protocol, data, receiver)
end

return {
  description = "Kürzt einen Link", 
  usage = "!yourls [Link]: Kürzt einen Link mit YOURLS",
  patterns = {
	"^!yourls (https?://[%w-_%.%?%.:/%+=&]+)"
  },
  run = run 
}

end

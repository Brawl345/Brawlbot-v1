local BASE_URL = 'https://api-ssl.bitly.com'

local client_id = cred_data.bitly_client_id
local client_secret = cred_data.bitly_client_secret
local redirect_uri = cred_data.bitly_redirect_uri

local function get_bitly_access_token(hash, code)
  local req = post_petition(BASE_URL..'/oauth/access_token', 'client_id='..client_id..'&client_secret='..client_secret..'&code='..code..'&redirect_uri='..redirect_uri)
  if not req.access_token then return 'Fehler beim Einloggen!' end
  
  local access_token = req.access_token
  local login_name = req.login
  redis:hset(hash, 'bitly', access_token)
  return 'Erfolgreich als "'..login_name..'" eingeloggt!'
end

local function get_bitly_user_info(receiver, bitly_access_token)
  local url = BASE_URL..'/v3/user/info?access_token='..bitly_access_token..'&format=json'
  local res,code  = https.request(url)
  if code == 401 then return 'Login fehlgeschlagen!' end
  if code ~= 200 then return 'HTTP-Fehler!' end
  
  local data = json:decode(res).data
  
  if data.full_name then
    name = data.full_name..' ('..data.login..')'
  else
    name = data.login
  end
  
  local text = 'Eingeloggt als '..data.login..'\nProfil: '..data.profile_url
  
  local cb_extra = {
    receiver=receiver,
    url=string.gsub(data.profile_image, 'http', 'https') -- srsly bitly?
  }
  
  send_msg(receiver, text, send_photo_from_url_callback, cb_extra)
end

local function create_bitlink (long_url, domain, bitly_access_atoken)
  local url = BASE_URL..'/v3/shorten?access_token='..bitly_access_token..'&domain='..domain..'&longUrl='..long_url..'&format=txt'
  local text,code  = https.request(url)
  if code ~= 200 then return 'FEHLER: '..text end
  return text
end

function run(msg, matches)
  local hash = 'user:'..msg.from.id
  bitly_access_token = redis:hget(hash, 'bitly')
  
  if matches[1] == 'auth' and matches[2] then
    return get_bitly_access_token(hash, matches[2])
  end
  
  if matches[1] == 'auth' then
    return 'Bitte authentifiziere dich zuerst, indem du folgende Seite aufrufst:\nhttps://bitly.com/oauth/authorize?client_id='..client_id..'&redirect_uri='..redirect_uri
  end
  
  if matches[1] == 'unauth' and bitly_access_token then
    redis:hdel(hash, 'bitly')
	return 'Erfolgreich ausgeloggt! Du kannst den Zugriff hier endgültig entziehen:\nhttps://bitly.com/a/settings/connected'
  elseif matches[1] == 'unauth' and not bitly_access_token then
    return 'Wie willst du dich ausloggen, wenn du gar nicht eingeloggt bist?'
  end
  
  if matches[1] == 'me' and bitly_access_token then
    local text = get_bitly_user_info(get_receiver(msg), bitly_access_token)
	if text then return text else return end
  elseif matches[1] == 'me' and not bitly_access_token then
    return 'Du bist nicht eingeloggt! Logge dich ein mit\n!short auth'
  end

  if not bitly_access_token then
    print('Not signed in, will use global bitly access_token')
    bitly_access_token = cred_data.bitly_access_token
  end
  
  if matches[2] == nil then
    long_url = url_encode(matches[1])
	domain = 'bit.ly'
  else
    long_url = url_encode(matches[2])
	domain = matches[1]
  end
  return create_bitlink(long_url, domain, bitly_access_token)
end

return {
  description = "Kürzt einen Link", 
  usage = {
    "!short [Link]: Kürzt einen Link mit der Standard Bitly-Adresse",
	"!short [j.mp|bit.ly|bitly.com] [Link]: Kürzt einen Link mit der ausgewählten Kurz-URL",
	"!short auth: Loggt deinen Account ein und nutzt ihn für deine Links (empfohlen!)",
	"!short me: Gibt den eingeloggten Account aus",
	"!short unauth: Loggt deinen Account aus"
  },
  patterns = {
    "^!short (auth) (.+)$",
    "^!short (auth)$",
	"^!short (unauth)$",
	"^!short (me)$",
  	"^!short (j.mp) (https?://[%w-_%.%?%.:/%+=&]+)$",
	"^!short (bit.ly) (https?://[%w-_%.%?%.:/%+=&]+)$",
	"^!short (bitly.com) (https?://[%w-_%.%?%.:/%+=&]+)$",
	"^!short (https?://[%w-_%.%?%.:/%+=&]+)$"
  },
  run = run 
}

end

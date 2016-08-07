do

local BASE_URL = 'https://gender-api.com/get'

local function get_gender_data (name)
  local apikey = cred_data.gender_apikey
  local url = BASE_URL..'?name='..name..'&key='..apikey
  local res,code  = https.request(url)
  if code ~= 200 then return "HTTP-FEHLER" end
  local data = json:decode(res)
  cache_data('gender', string.lower(name), data, 345600)
  return data
end

local function send_gender_data(data, receiver)
  if data.gender == "female" then
    gender = 'weiblich'
  end
  if data.gender == "male" then
    gender = 'männlich'
  end
  if data.gender == "unknown" then
    gender = 'unbekanntem Geschlechts'
  end
  local accuracy = data.accuracy
  local text = name..' ist zu '..accuracy..'% '..gender
  send_msg(receiver, text, ok_cb, false)
end

local function run(msg, matches)
  name = matches[1]
  local receiver = get_receiver(msg)
  local hash = 'telegram:cache:gender:'..string.lower(name)
  if redis:exists(hash) == false then
    data = get_gender_data(name)
  else
    data = redis:hgetall(hash)
  end
  send_gender_data(data, receiver)
end

return {
  description = "Sendet Geschlecht", 
  usage = "!geschlecht [Name]: Sendet Geschlecht",
  patterns = {
	"^!geschlecht (.*)$",
	"^!gender (.*)$"
	},
  run = run 
}

end

do

require("./plugins/time")

local BASE_URL = "https://api.forecast.io/forecast"
local apikey = cred_data.forecastio_apikey
local google_apikey = cred_data.google_apikey

local function get_city_name(lat, lng)
  local city = redis:hget('telegram:cache:weather:pretty_names', lat..','..lng)
  if city then return city end
  local url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng='..lat..','..lng..'&result_type=political&language=de&key='..google_apikey
  local res, code = https.request(url)
  if code ~= 200 then return 'Unbekannte Stadt' end
  local data = json:decode(res).results[1]
  local city = data.formatted_address
  print('Setting '..lat..','..lng..' in redis hash telegram:cache:weather:pretty_names to "'..city..'"')
  redis:hset('telegram:cache:weather:pretty_names', lat..','..lng, city)
  return city
end

local function get_weather(lat, lng)
  print('Finde Wetter in '..lat..', '..lng)
  local text = redis:get('telegram:cache:weather:'..lat..','..lng)
  if text then print('...aus dem Cache..') return text end

  local url = BASE_URL..'/'..apikey..'/'..lat..','..lng..'?lang=de&units=si&exclude=minutely,hourly,daily,alerts,flags'
  
  local response_body = {}
  local request_constructor = {
      url = url,
      method = "GET",
      sink = ltn12.sink.table(response_body)
   }
  local ok, response_code, response_headers, response_status_line = https.request(request_constructor)
  if not ok then return nil end
  local data = json:decode(table.concat(response_body))
  local ttl = string.sub(response_headers["cache-control"], 9)

  
  local weather = data.currently
  local city = get_city_name(lat, lng)
  local temperature = string.gsub(round(weather.temperature, 1), "%.", "%,")
  local feelslike = string.gsub(round(weather.apparentTemperature, 1), "%.", "%,")
  local temp = 'Wetter in '..city..':\n'..temperature..' °C'
  local conditions = ' | '..weather.summary
  if weather.icon == 'clear-day' then
	conditions = conditions..' ☀️'
  elseif weather.icon == 'clear-night' then
	conditions = conditions..' 🌙'
  elseif weather.icon == 'rain' then
    conditions = conditions..' ☔️'
  elseif weather.icon == 'snow' then
	 conditions = conditions..' ❄️'
  elseif weather.icon == 'sleet' then
     conditions = conditions..' 🌨'
  elseif weather.icon == 'wind' then
     conditions = conditions..' 💨'
  elseif weather.icon == 'fog' then
     conditions = conditions..' 🌫'
  elseif weather.icon == 'cloudy' then
     conditions = conditions..' ☁️☁️'
  elseif weather.icon == 'partly-cloudy-day' then
     conditions = conditions..' 🌤'
  elseif weather.icon == 'partly-cloudy-night' then
     conditions = conditions..' 🌙☁️'
  else
     conditions = conditions..''
  end
  local windspeed = ' | 💨 '..string.gsub(round(weather.windSpeed, 1), "%.", "%,")..' m/s'
  
  local text = temp..conditions..windspeed
  
  if temperature ~= feelslike then
    text = text..'\n(gefühlt: '..feelslike..' °C)'
  end
  
  cache_data('weather', lat..','..lng, text, tonumber(ttl), 'key')
  return text
end

local function run(msg, matches)
  local user_id = msg.from.id

  if matches[1] ~= '!wetter' and matches[1] ~= '!w' then 
    city = matches[1]
  else
    local set_location = get_location(user_id)
	if not set_location then
	  city = 'Berlin, Deutschland'
	else
	  city = set_location
	end
  end
  
  local lat = redis:hget('telegram:cache:weather:'..string.lower(city), 'lat')
  local lng = redis:hget('telegram:cache:weather:'..string.lower(city), 'lng')
  if not lat and not lng then
    print('Koordinaten nicht eingespeichert, frage Google...')
    lat,lng = get_latlong(city)
  end
  
  if not lat and not lng then
    return 'Den Ort "'..city..'" gibt es nicht!'
  end

  redis:hset('telegram:cache:weather:'..string.lower(city), 'lat', lat)
  redis:hset('telegram:cache:weather:'..string.lower(city), 'lng', lng)
  
  local text = get_weather(lat, lng)
  if not text then
    text = 'Konnte das Wetter von dieser Stadt nicht bekommen.'
  end
  return text
end

return {
  description = "Wetter für deinen oder einen gewählten Ort", 
  usage = {
    "!wetter: Wetter für deinen Wohnort (!location set [Ort])",
    "!wetter (Stadt): Wetter für diese Stadt"
  },
  patterns = {
    "^!wetter$",
	"^!wetter (.*)$",
	"^!w$",
	"^!w (.*)$"
  }, 
  run = run 
}

end

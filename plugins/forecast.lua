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


local function get_condition_symbol(weather, n)
  if weather.data[n].icon == 'clear-day' then
	return '☀️'
  elseif weather.data[n].icon == 'clear-night' then
    return '🌙'
  elseif weather.data[n].icon == 'rain' then
    return '☔️'
  elseif weather.data[n].icon == 'snow' then
	return '❄️'
  elseif weather.data[n].icon == 'sleet' then
    return '🌨'
  elseif weather.data[n].icon == 'wind' then
    return '💨'
  elseif weather.data[n].icon == 'fog' then
    return '🌫'
  elseif weather.data[n].icon == 'cloudy' then
    return '☁️☁️'
  elseif weather.data[n].icon == 'partly-cloudy-day' then
    return '🌤'
  elseif weather.data[n].icon == 'partly-cloudy-night' then
    return '🌙☁️'
  else
    return ''
  end
end

local function get_temp(weather, n, hourly)
  if hourly then
    local temperature = string.gsub(round(weather.data[n].temperature, 1), "%.", "%,")
	local condition = weather.data[n].summary
	return temperature..'°C | '..get_condition_symbol(weather, n)..' '..condition
  else
    local day = string.gsub(round(weather.data[n].temperatureMax, 1), "%.", "%,")
    local night = string.gsub(round(weather.data[n].temperatureMin, 1), "%.", "%,")
    local condition = weather.data[n].summary
    return '☀️ '..day..'°C | 🌙 '..night..'°C | '..get_condition_symbol(weather, n)..' '..condition
  end
end

local function get_forecast(lat, lng)
  print('Finde Wetter in '..lat..', '..lng)
  local text = redis:get('telegram:cache:forecast:'..lat..','..lng)
  if text then print('...aus dem Cache..') return text end

  local url = BASE_URL..'/'..apikey..'/'..lat..','..lng..'?lang=de&units=si&exclude=currently,minutely,hourly,alerts,flags'
  
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

  
  local weather = data.daily
  local city = get_city_name(lat, lng)
  
  local header = 'Vorhersage für '..city..':\n'..weather.summary..'\n'
  
  local text = 'Heute: '..get_temp(weather, 1)
  local text = text..'\nMorgen: '..get_temp(weather, 2)
  
  for day in pairs(weather.data) do
	if day > 2 then 
	  text = text..'\n'..convert_timestamp(weather.data[day].time, '%a, %d.%m')..': '..get_temp(weather, day)
    end
  end
  
  local text = string.gsub(text, "Mon", "Mo")
  local text = string.gsub(text, "Tue", "Di")
  local text = string.gsub(text, "Wed", "Mi")
  local text = string.gsub(text, "Thu", "Do")
  local text = string.gsub(text, "Fri", "Fr")
  local text = string.gsub(text, "Sat", "Sa")
  local text = string.gsub(text, "Sun", "So")
  
  cache_data('forecast', lat..','..lng, header..text, tonumber(ttl), 'key')
  
  return header..text
end

local function get_forecast_hourly(lat, lng)
  print('Finde stündliches Wetter in '..lat..', '..lng)
  local text = redis:get('telegram:cache:forecast:'..lat..','..lng..':hourly')
  if text then print('...aus dem Cache..') return text end

  local url = BASE_URL..'/'..apikey..'/'..lat..','..lng..'?lang=de&units=si&exclude=currently,minutely,daily,alerts,flags'
  
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

  
  local weather = data.hourly
  local city = get_city_name(lat, lng)
  
  local header = '24-Stunden-Vorhersage für '..city..':\n'..weather.summary
  local text = ""
  
  for hour in pairs(weather.data) do
	if hour < 26 then 
	  text = text..'\n'..convert_timestamp(weather.data[hour].time, '%H:%M Uhr')..' | '..get_temp(weather, hour, true)
	end
  end
  
  cache_data('forecast', lat..','..lng..':hourly', header..text, tonumber(ttl), 'key')
  
  return header..text
end

local function run(msg, matches)
  local user_id = msg.from.id
  local city = get_location(user_id)
  
  if matches[2] then
    city = matches[2]
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
  
  if matches[1] == '!forecasth' or matches[1] == '!fh' then
    text = get_forecast_hourly(lat, lng)
  else
    text = get_forecast(lat, lng)
  end
  if not text then
    text = 'Konnte die Wettervorhersage für diese Stadt nicht bekommen.'
  end
  return text
end

return {
  description = "Wettervorhersage für deinen oder einen gewählten Ort", 
  usage = {
    "!f: Wettervorhersage für deine Stadt (!location set [Ort])",
    "!f (Stadt): Wettervorhersage für diese Stadt",
    "!fh: 24-Stunden-Wettervorhersage für deine Stadt (!location set [Ort])",
    "!fh (Stadt): 24-Stunden-Wettervorhersage für diese Stadt"
  },
  patterns = {
    "^(!f)$",
	"^(!f) (.*)$",
	"^(!fh)$",
	"^(!fh) (.*)$",
	"^(!forecast)$",
	"^(!forecast) (.*)$",
	"^(!forecasth)$",
	"^(!forecasth) (.*)$"
  }, 
  run = run 
}

end
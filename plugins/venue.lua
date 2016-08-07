do

local apikey = cred_data.google_apikey

local function run(msg, matches)
  if msg.media then
    local lat = msg.media.latitude
	local lng = msg.media.longitude
	local url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng='..lat..','..lng..'&result_type=street_address&language=de&key='..apikey
    local res, code = https.request(url)
    if code ~= 200 then return 'Unbekannte Stadt' end
    local data = json:decode(res).results[1]
    local city = data.formatted_address
    return city
  end
end

local function pre_process(msg)
  if not msg.text and msg.media then
    msg.text = '['..msg.media.type..']'
  end
  return msg
end

return {
  description = "Wenn ein Standort gepostet wird, poste die genaue Adresse",
  usage = "STANDORT: Sende Infos über Standort",
  run = run,
  patterns = {
    '%[geo%]',
	'%[venue%]'
  },
  pre_process = pre_process
}

end
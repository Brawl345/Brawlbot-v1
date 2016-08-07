do

local BASE_URL = 'http://ip-api.com/json'

function get_host_data (host, receiver)
  local url = BASE_URL..'/'..host..'?lang=de&fields=country,regionName,city,zip,lat,lon,isp,org,as,status,message,reverse,query'
  local res,code  = http.request(url)
  if code ~= 200 then return "HTTP-FEHLER: "..code end
  local data = json:decode(res)
  if data.status == 'fail' then
    return 'Host konnte nicht aufgelöst werden: '..data.message
  end

  local isp = data.isp
  
  if data.lat and data.lon then
    local lat = tostring(data.lat)
    local lon = tostring(data.lon)
	local url = "https://maps.googleapis.com/maps/api/staticmap?zoom=16&size=600x300&maptype=hybrid&center="..lat..","..lon.."&markers=color:red%7Clabel:•%7C"..lat..","..lon
    send_photo_from_url(receiver, url)
  end
  
  if data.query == host then
    query = ''
  else
    query = ' / '..data.query
  end
  
  if data.reverse ~= "" and data.reverse ~= host then
    host_addr = ' ('..data.reverse..')'
  else
    host_addr = ''
  end
  
  -- Location
  if data.zip ~= "" then
    zipcode = data.zip..' '
  else
    zipcode = ''
  end
  
  local city = data.city

  if data.regionName ~= "" then
    region = ', '..data.regionName
  else
    region = ''
  end
  
  if data.country ~= "" then
    country = ', '..data.country
  else
    country = ''
  end
  
  local text = host..query..host_addr..' ist bei '..isp..':\n'
  local location = zipcode..city..region..country
  return text..location
end

function run(msg, matches)
  local host = matches[1]
  local receiver = get_receiver(msg)
  return get_host_data(host, receiver)
end

return {
  description = "Sendet Infos zum Server hinter Adresse oder IP", 
  usage = "!ip [IP]/[Domain]: Sendet Server-Infos",
  patterns = {
    "^!ip (.*)$",
	"^!dns (.*)$"
  },
  run = run 
}

end

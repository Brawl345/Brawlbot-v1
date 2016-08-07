do

local BASE_URL = 'https://apps.p.mashape.com/google/application'
local function get_playstore_data (appid)
  local apikey = cred_data.x_mashape_key
  local url = BASE_URL..'/'..appid..'?mashape-key='..apikey
  local res,code  = https.request(url)
  if code ~= 200 then return "HTTP-FEHLER" end
  local data = json:decode(res).data
  return data
end

local function send_playstore_data(data, receiver)
  local title = data.title
  local developer = data.developer.id
  local category = data.category.name
  local rating = data.rating.average
  local installs = data.performance.installs
  local description = data.description
  if data.version == "Varies with device" then
    appversion = "variiert je nach Gerät"
  else
    appversion = data.version
  end
  if data.price == 0 then
    price = "Gratis"
  else
    price = data.price
  end
  local text = title..' von '..developer..' aus der Kategorie '..category..', durschnittlich bewertet mit '..rating..' Sternen.\n'..description..'\n'..installs..' Installationen, Version '..appversion
  send_msg(receiver, text, ok_cb, false)
end

local function run(msg, matches)
  local appid = matches[1]
  local data = get_playstore_data(appid)
  if data.title == nil then
    return
  else
    local receiver = get_receiver(msg)
    send_playstore_data(data, receiver)
   end
end

return {
  description = "Sendet Play Store Info.", 
  usage = "URL zu Android-App im Google Play Store",
  patterns = {"play.google.com/store/apps/details%?id=(.*)"},
  run = run 
}

end

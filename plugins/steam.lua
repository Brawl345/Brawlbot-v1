-- See https://wiki.teamfortress.com/wiki/User:RJackson/StorefrontAPI

do

local BASE_URL = 'http://store.steampowered.com/api/appdetails/'
local DESC_LENTH = 450

local function get_steam_data (appid)
  local url = BASE_URL
  url = url..'?appids='..appid
  url = url..'&l=german&cc=DE'
  local res,code  = http.request(url)
  if code ~= 200 then return nil end
  local data = json:decode(res)[appid].data
  return data
end


local function price_info (data)
  local price = '' -- If no data is empty
  
  if data then
    local initial = data.initial
    local final = data.final or data.initial
    local min = math.min(data.initial, data.final)
    price = tostring(min/100)
    if data.discount_percent and initial ~= final then
      price = price..data.currency..' ('..data.discount_percent..'% OFF)'
    end
    price = price..' €'
  end

  return price
end


local function send_steam_data(data, receiver)
  local description = string.sub(unescape(data.about_the_game:gsub("%b<>", "")), 1, DESC_LENTH) .. '...'
  local title = data.name
  local price = price_info(data.price_overview)

  local text = title..' '..price..'\n'..description
  local image_url = data.header_image
  local cb_extra = {
    receiver = receiver,
    url = image_url
  }
  send_msg(receiver, text, send_photo_from_url_callback, cb_extra)
end


local function run(msg, matches)
  local appid = matches[1]
  local data = get_steam_data(appid)
  local receiver = get_receiver(msg)
  send_steam_data(data, receiver)
end

return {
  description = "Postet Info zu Steam-Spiel",
  usage = "Link zu Steam-Spiel",
  patterns = {
    "store.steampowered.com/app/([0-9]+)",
	"steamcommunity.com/app/([0-9]+)"
  },
  run = run
}

end

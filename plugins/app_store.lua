do

local BASE_URL = 'https://itunes.apple.com/lookup'

local makeOurDate = function(dateString)
  local pattern = "(%d+)%-(%d+)%-(%d+)T"
  local year, month, day = dateString:match(pattern)
  return day..'.'..month..'.'..year
end

local function get_appstore_data()
  local url = BASE_URL..'/?id='..appid..'&country=de'
  local res,code  = https.request(url)
  if code ~= 200 then return "HTTP-FEHLER" end
  local data = json:decode(res).results[1]
  
  if data == nil then return 'NOTFOUND' end
  if data.wrapperType ~= 'software' then return nil end
  
  return data
end

local function send_appstore_data(data, receiver)  
  -- Header
  local name = data.trackName
  local author = data.sellerName
  local price = data.formattedPrice
  local version = data.version
  
  -- Body
  local description = string.sub(unescape(data.description), 1, 150) .. '...'
  local min_ios_ver = data.minimumOsVersion
  local size = string.gsub(round(data.fileSizeBytes / 1000000, 2), "%.", "%,") -- wtf Apple, it's 1024, not 1000!
  local release = makeOurDate(data.releaseDate)
  if data.isGameCenterEnabled then
    game_center = '\nUnterstützt Game Center'
  else
    game_center = ''
  end
  local category_count = tablelength(data.genres)
  if category_count == 1 then
    category = '\nKategorie: '..data.genres[1]
  else
    local category_loop = '\nKategorien: '
    for v in pairs(data.genres) do
      if v < category_count then
        category_loop = category_loop..data.genres[v]..', '
	  else
	    category_loop = category_loop..data.genres[v]
	  end
    end
	  category = category_loop
  end
  
  -- Footer
  if data.averageUserRating and data.userRatingCount then
    avg_rating = 'Bewertung: '..string.gsub(data.averageUserRating, "%.", "%,")..' Sterne '
	ratings = 'von '..comma_value(data.userRatingCount)..' Bewertungen'
  else
    avg_rating = ""
	ratings = ""
  end
  
  
  local header = name..' v'..version..' von '..author..' ('..price..'):'
  local body = '\n'..description..'\nBenötigt mind. iOS '..min_ios_ver..'\nGröße: '..size..' MB\nErstveröffentlicht am '..release..game_center..category
  local footer = '\n'..avg_rating..ratings
  local text = header..body..footer
  
  -- Picture
  if data.screenshotUrls[1] and data.ipadScreenshotUrls[1] then
    image_url = data.screenshotUrls[1]
  elseif data.screenshotUrls[1] and not data.ipadScreenshotUrls[1] then
    image_url = data.screenshotUrls[1]
  elseif not data.screenshotUrls[1] and data.ipadScreenshotUrls[1] then
    image_url = data.ipadScreenshotUrls[1]
  else
    image_url = nil
  end
  
  if image_url then
    local cb_extra = {
      receiver=receiver,
      url=image_url
    }
    send_msg(receiver, text, send_photo_from_url_callback, cb_extra)
  else
    send_msg(receiver, text, ok_cb, false)
  end
end

local function run(msg, matches)
  local receiver = get_receiver(msg)
  if not matches[3] then
    appid = matches[1]
  else
    appid = matches[3]
  end
  local data = get_appstore_data()
  if data == nil then print('Das Appstore-Plugin unterstützt zurzeit nur Apps!') end
  if data == 'HTTP-FEHLER' or data == 'NOTFOUND' then
    return 'App nicht gefunden!'
  else
    send_appstore_data(data, receiver)
  end
end

return {
  description = "Sendet iPhone App-Store Info.", 
  usage = "Link zu App auf iTunes",
  patterns = {
	"itunes.apple.com/(.*)/app/(.*)/id(%d+)",
	"^!itunes (%d+)$",
	"itunes.apple.com/app/id(%d+)"
  },
  run = run
}

end

do

local xml = require("xml") 

local BASE_URL = 'http://thetvdb.com/api'

local makeOurDate = function(dateString)
  local pattern = "(%d+)%-(%d+)%-(%d+)"
  local year, month, day = dateString:match(pattern)
  return day..'.'..month..'.'..year
end

local function get_tv_info(series)
  local url = BASE_URL..'/GetSeries.php?seriesname='..series..'&language=de'
  local res,code  = http.request(url)
  if code ~= 200 then return "HTTP-ERROR" end
  local result = xml.load(res)
  if not xml.find(result, 'seriesid') then return "NOTFOUND" end
  return result
end

local function send_tv_data(result, receiver)
  local title = xml.find(result, 'SeriesName')[1]
  local id = xml.find(result, 'seriesid')[1]
  
  if xml.find(result, 'AliasNames') and xml.find(result, 'AliasNames')[1] ~= title then
    alias = '\noder: '..xml.find(result, 'AliasNames')[1]
  else
    alias = ''
  end
  
  if xml.find(result, 'Overview') then
    desc = '\n'..string.sub(xml.find(result, 'Overview')[1], 1, 250) .. '...'
  else
    desc = ''
  end
  
  if xml.find(result, 'FirstAired') then
    aired = '\nErstausstrahlung: '..makeOurDate(xml.find(result, 'FirstAired')[1])
  else
    aired = ''
  end
 
  
  if xml.find(result, 'Network') then
    publisher = '\nPublisher: '..xml.find(result, 'Network')[1]
  else
    publisher = ''
  end
  
  if xml.find(result, 'IMDB_ID') then
    imdb = '\nIMDB: http://www.imdb.com/title/'..xml.find(result, 'IMDB_ID')[1]
  else
    imdb = ''
  end
  
  local text = title..alias..aired..publisher..imdb..desc..'\n— http://thetvdb.com/?id='..id..'&tab=series'
  if xml.find(result, 'banner') then
    local image_url = 'http://www.thetvdb.com/banners/'..xml.find(result, 'banner')[1]
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
  local series = URL.escape(matches[1])
  local receiver = get_receiver(msg)
  local tv_info = get_tv_info(series)
  if tv_info == "NOTFOUND" then
    return "Serie nicht gefunden!"
  elseif tv_info == "HTTP-ERROR" then
    return "HTTP-FEHLER"
  else
    send_tv_data(tv_info, receiver)
  end
end

return {
  description = "Sendet Infos zu einer TV-Serie.", 
  usage = "!tv [TV-Serie]: Sendet Infos zur TV-Serie",
  patterns = {"^!tv (.+)$"},
  run = run 
}

end

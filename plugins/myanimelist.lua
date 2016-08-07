-- Few things modified by Akamaru <akamaru.de>

do

local xml = require("xml") 

local user = cred_data.mal_user
local password = cred_data.mal_pw

local BASE_URL = 'http://'..user..':'..password..'@myanimelist.net/api'

local function delete_tags(str)
  str = string.gsub( str, '<br />', '')
  str = string.gsub( str, '%[i%]', '')
  str = string.gsub( str, '%[/i%]', '')
  str = string.gsub( str, '&mdash;', ' — ')
  return str
end

local makeOurDate = function(dateString)
  local pattern = "(%d+)%-(%d+)%-(%d+)"
  local year, month, day = dateString:match(pattern)
  return day..'.'..month..'.'..year
end

local function get_mal_info(query, typ)
  if typ == 'anime' then
    url = BASE_URL..'/anime/search.xml?q='..query
  elseif typ == 'manga' then
    url = BASE_URL..'/manga/search.xml?q='..query
  end
  local res,code  = http.request(url)
  if code ~= 200 then return "HTTP-Fehler" end
  local result = xml.load(res)
  return result
end

local function send_anime_data(result, receiver)
  local title = xml.find(result, 'title')[1]
  local id = xml.find(result, 'id')[1]
  local mal_url = 'http://myanimelist.net/anime/'..id
  
  if xml.find(result, 'synonyms')[1] then
    alt_name = '\noder: '..unescape(delete_tags(xml.find(result, 'synonyms')[1]))
  else
    alt_name = ''
  end
  
  if xml.find(result, 'synopsis')[1] then
    desc = '\n'..unescape(delete_tags(string.sub(xml.find(result, 'synopsis')[1], 1, 200))) .. '...'
  else
    desc = ''
  end

  if xml.find(result, 'episodes')[1] then
    episodes = '\nEpisoden: '..xml.find(result, 'episodes')[1]
  else
    episodes = ''
  end
  
  if xml.find(result, 'status')[1] then
    status = ' ('..xml.find(result, 'status')[1]..')'
  else
    status = ''
  end
  
  if xml.find(result, 'score')[1] ~= "0.00" then
    score = '\nScore: '..string.gsub(xml.find(result, 'score')[1], "%.", "%,")
  else
    score = ''
  end
  
  if xml.find(result, 'type')[1] then
    typ = '\nTyp: '..xml.find(result, 'type')[1]
  else
    typ = ''
  end
 
  if xml.find(result, 'start_date')[1] ~= "0000-00-00" then
    startdate = '\nVeröffentlichungszeitraum: '..makeOurDate(xml.find(result, 'start_date')[1])
  else
    startdate = ''
  end
 
  if xml.find(result, 'end_date')[1] ~= "0000-00-00" then
    enddate = ' - '..makeOurDate(xml.find(result, 'end_date')[1])
  else
    enddate = ''
  end
  
  local text = title..alt_name..typ..episodes..status..score..startdate..enddate..'\n'..desc..'\n— '..mal_url
  if xml.find(result, 'image') then
    local image_url = xml.find(result, 'image')[1]
    local cb_extra = {
      receiver=receiver,
      url=image_url
    }
    send_msg(receiver, text, send_photo_from_url_callback, cb_extra)
  else
    send_msg(receiver, text, ok_cb, false)
  end 
end

local function send_manga_data(result, receiver)
  local title = xml.find(result, 'title')[1]
  local id = xml.find(result, 'id')[1]
  local mal_url = 'http://myanimelist.net/manga/'..id
  
  if xml.find(result, 'type')[1] then
    typ = ' ('..xml.find(result, 'type')[1]..')'
  else
    typ = ''
  end
  
  if xml.find(result, 'synonyms')[1] then
    alt_name = '\noder: '..unescape(delete_tags(xml.find(result, 'synonyms')[1]))
  else
    alt_name = ''
  end

  if xml.find(result, 'chapters')[1] then
    chapters = '\nKapitel: '..xml.find(result, 'chapters')[1]
  else
    chapters = ''
  end
  
  if xml.find(result, 'status')[1] then
    status = ' ('..xml.find(result, 'status')[1]..')'
  else
    status = ''
  end

  if xml.find(result, 'volumes')[1] then
    volumes = '\nBände '..xml.find(result, 'volumes')[1]
  else
    volumes = ''
  end
  
  if xml.find(result, 'score')[1] ~= "0.00" then
    score = '\nScore: '..xml.find(result, 'score')[1]
  else
    score = ''
  end
 
  if xml.find(result, 'start_date')[1] ~= "0000-00-00" then
    startdate = '\nVeröffentlichungszeitraum: '..makeOurDate(xml.find(result, 'start_date')[1])
  else
    startdate = ''
  end
 
  if xml.find(result, 'end_date')[1] ~= "0000-00-00" then
    enddate = ' - '..makeOurDate(xml.find(result, 'end_date')[1])
  else
    enddate = ''
  end
  
  if xml.find(result, 'synopsis')[1] then
    desc = '\n'..unescape(delete_tags(string.sub(xml.find(result, 'synopsis')[1], 1, 200))) .. '...'
  else
    desc = ''
  end
 
  local text = title..alt_name..typ..chapters..status..volumes..score..startdate..enddate..'\n'..desc..'\n— '..mal_url
  if xml.find(result, 'image') then
    local image_url = xml.find(result, 'image')[1]
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
  local query = URL.escape(matches[2])
  local receiver = get_receiver(msg)
  if matches[1] == 'anime' then
    local anime_info = get_mal_info(query, 'anime')
    if anime_info == "HTTP-Fehler" then
      return "Anime nicht gefunden!"
    else
      send_anime_data(anime_info, receiver)
    end
  elseif matches[1] == 'manga' then
    local manga_info = get_mal_info(query, 'manga')
    if manga_info == "HTTP-Fehler" then
      return "Manga nicht gefunden!"
    else
      send_manga_data(manga_info, receiver)
    end
  end
end

return {
  description = "Sendet Infos zu einem Anime oder Manga.", 
  usage =  {
    "!anime [Anime]: Sendet Infos zum Anime",
	"!manga [Manga]: Sendet Infos zum Manga"
  },
  patterns = {
  "^!(anime) (.+)$",
  "myanimelist.net/(anime)/[0-9]+/(.*)$",
  "^!(manga) (.+)$",
  "myanimelist.net/(manga)/[0-9]+/(.*)$"
  },
  run = run 
}

end

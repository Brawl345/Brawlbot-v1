do

local BASE_URL = 'https://graph.facebook.com/v2.5'
local fb_access_token = cred_data.fb_access_token

local makeOurDate = function(dateString)
  local pattern = "(%d+)%/(%d+)%/(%d+)"
  local month, day, year = dateString:match(pattern)
  return day..'.'..month..'.'..year
end

local function get_fb_id(name)
  local url = BASE_URL..'/'..name..'?access_token='..fb_access_token..'&locale=de_DE'
  local res,code  = https.request(url)
  if code ~= 200 then return nil end
  local data = json:decode(res)
  return data.id
end

local function fb_post (id, story_id)
  local url = BASE_URL..'/'..id..'_'..story_id..'?access_token='..fb_access_token..'&locale=de_DE&fields=from,name,story,message,link'
  local res,code  = https.request(url)
  if code ~= 200 then return nil end
  local data = json:decode(res)
  
  local from = data.from.name
  local message = data.message
  local name = data.name
  if data.link then
    link = '\n'..data.name..':\n'..data.link
  else
    link = ""
  end
  
  if data.story then
    story = ' ('..data.story..')'
  else
    story = ""
  end
  
  local text = from..story..':\n'..message..'\n'..link
  return text
end

local function send_facebook_photo(photo_id, receiver)
  local url = BASE_URL..'/'..photo_id..'?access_token='..fb_access_token..'&locale=de_DE&fields=images,from,name'
  local res,code  = https.request(url)
  if code ~= 200 then return nil end
  local data = json:decode(res)
  
  local from = data.from.name
  if data.name then
    text = from..' hat ein Bild gepostet:\n'..data.name
  else
    text = from..' hat ein Bild gepostet:'
  end
  local image_url = data.images[1].source
  local cb_extra = {
    receiver=receiver,
    url=image_url
  }
  send_msg(receiver, text, send_photo_from_url_callback, cb_extra)
end

local function send_facebook_video(video_id, receiver)
  local url = BASE_URL..'/'..video_id..'?access_token='..fb_access_token..'&locale=de_DE&fields=description,from,source,title'
  local res,code  = https.request(url)
  if code ~= 200 then return nil end
  local data = json:decode(res)

  local from = data.from.name
  local description = data.description
  local source = data.source
  if data.title then
    text = from..' hat ein Video gepostet:\n'..description..'\n'..source..'\n('..data.title..')'
  else
    text = from..' hat ein Video gepostet:\n'..description..'\n'..source
  end
  send_msg(receiver, text, ok_cb, false)
end

local function facebook_info(name)
  local url = BASE_URL..'/'..name..'?access_token='..fb_access_token..'&locale=de_DE&fields=about,name,birthday,category,founded,general_info,is_verified'
  local res,code  = https.request(url)
  if code ~= 200 then return nil end
  local data = json:decode(res)
  
  local name = data.name
  if data.is_verified then
    name = name..' ✅'
  end
  
  local category = data.category
  
  if data.about then
    about = '\n'..data.about
  else
    about = ""
  end
  
  if data.general_info then
    general_info = '\n'..data.general_info
  else
    general_info = ""
  end
  
  if data.birthday and data.founded then
    birth = '\nGeburtstag: '..makeOurDate(data.birthday)
  elseif data.birthday and not data.founded then
    birth = '\nGeburtstag: '..makeOurDate(data.birthday)
  elseif data.founded and not data.birthday then
    birth = '\nGegründet: '..data.founded
  else
    birth = ""
  end
  
  local text = name..' ('..category..')'..about..general_info..birth
  return text
end

local function run(msg, matches)
  if matches[1] == 'permalink' or matches[2] == 'posts' then
    story_id = matches[3]
    if not matches[4] then
	  id = get_fb_id(matches[1])
	else
	  id = matches[4]
	end
    return fb_post(id, story_id)
  elseif matches[1] == 'photo' or matches[2] == 'photos' then
    if not matches[4] then
      photo_id = matches[2]
    else
      photo_id = matches[4]
    end
    local receiver = get_receiver(msg)
    send_facebook_photo(photo_id, receiver)
  elseif matches[1] == 'video' or matches[2] == 'videos' then
    if not matches[3] then
      video_id = matches[2]
    else
      video_id = matches[3]
    end
    local receiver = get_receiver(msg)
    send_facebook_video(video_id, receiver)
  else
    return facebook_info(matches[1])
  end
end

return {
  description = "Sendet Facebook-Post, -Foto, -Video oder -Info", 
  usage = "URL zu öffentlichem Facebook-Post, -Foto, -Video oder -Info",
  patterns = {
	"facebook.com/([A-Za-z0-9-._-]+)/(posts)/(%d+)",
	"facebook.com/(permalink).php%?(story_fbid)=(%d+)&id=(%d+)",
    "facebook.com/(photo).php%?fbid=(%d+)",
    "facebook.com/([A-Za-z0-9-._-]+)/(photos)/a.(%d+[%d%.]*)/(%d+)",
    "facebook.com/(video).php%?v=(%d+)",
	"facebook.com/([A-Za-z0-9-._-]+)/(videos)/(%d+[%d%.]*)",
	"facebook.com/([A-Za-z0-9-._-]+)"
  },
  run = run
}

end

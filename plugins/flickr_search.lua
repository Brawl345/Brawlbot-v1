do

local function get_flickr(term)
  local apikey = cred_data.flickr_apikey
  local BASE_URL = 'https://api.flickr.com/services/rest'
  local url = BASE_URL..'/?method=flickr.photos.search&api_key='..apikey..'&format=json&nojsoncallback=1&privacy_filter=1&safe_search=3&extras=url_o&text='..term
  local b,c = https.request(url)
  if c ~= 200 then return nil end
  local photo = json:decode(b).photos.photo
  -- truly randomize
  math.randomseed(os.time())
  -- random max json table size
  local i = math.random(#photo)
  local link_image = photo[i].url_o
  return link_image
end

local function run(msg, matches)
  local term = matches[1]
  local receiver = get_receiver(msg)
  local url = get_flickr(term)
  if string.ends(url, ".gif") then
    send_document_from_url(receiver, url)
  else
   send_photo_from_url(receiver, url)
  end
end

return {
  description = "Sendet zufälliges Bild von Flickr (beta)", 
  usage = "!flickr [Suchbegriff]: Postet Bild von Flickr",
  patterns = {"^!flickr (.*)$"},
  run = run 
}

end

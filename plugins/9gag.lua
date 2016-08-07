do

local function get_9GAG()
  local url = "http://api-9gag.herokuapp.com/"
  local b,c = http.request(url)
  if c ~= 200 then return nil end
  local gag = json:decode(b)
  -- random max json table size
  local i = math.random(#gag)  local link_image = gag[i].src
  local title = gag[i].title
  if link_image:sub(0,2) == '//' then
    link_image = msg.text:sub(3,-1)
  end
  return link_image, title
end

local function run(msg, matches)
  local receiver = get_receiver(msg)
  local url, title = get_9GAG()
  local cb_extra = {
    receiver=receiver,
    url=url
  }
  send_msg(receiver, title, send_photo_from_url_callback, cb_extra)
end

return {
  description = "Sendet ein zufälliges Bild von 9GAG", 
  usage = "!9gag: Sendet ein zufälliges Bild von 9GAG.",
  patterns = {
    "^!9gag$",
	"^!9fag$"
  },
  run = run
}

end

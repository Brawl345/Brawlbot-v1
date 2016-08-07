do

local function get_last_id()
  local res,code  = https.request("http://xkcd.com/info.0.json")
  if code ~= 200 then return "HTTP ERROR" end
  local data = json:decode(res)
  return data.num
end

local function get_xkcd(id)
  local res,code  = http.request("http://xkcd.com/"..id.."/info.0.json")
  if code ~= 200 then return "HTTP ERROR" end
  local data = json:decode(res)
  local link_image = data.img
  if link_image:sub(0,2) == '//' then
    link_image = msg.text:sub(3,-1)
  end
  return link_image, data.title, data.alt
end


local function get_xkcd_random()
  local last = get_last_id()
  math.randomseed(os.time())
  i = math.random(1, last)
  return get_xkcd(i)
end

local function send_title(cb_extra, success, result)
  if success then
    local message = cb_extra[2] .. "\n" .. cb_extra[3]
    send_msg(cb_extra[1], message, ok_cb, false)
  end
end

local function run(msg, matches)
  local receiver = get_receiver(msg)
  if matches[1] == "!xkcd" then
    url, title, alt = get_xkcd_random()
  else
    url, title, alt = get_xkcd(matches[1])
  end
  file_path = download_to_file(url)
  send_photo(receiver, file_path, send_title, {receiver, title})
  return false
end

return {
    description = "Sendet einen zufälligen XKCD-Comic, wenn keine ID gegeben ist.", 
    usage = {
	"!xkcd [id]: Sendet XKCD-Comic",
	"URL zu XKCD-Comic"
    },
    patterns = {
      "^!xkcd$",
      "^!xkcd (%d+)",
      "xkcd.com/(%d+)"
    }, 
    run = run 
}

end
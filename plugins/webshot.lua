local helpers = require "OAuth.helpers"

local base = 'https://screenshotmachine.com/'
local url = base .. 'processor.php'

local function get_webshot_url(param, size)
   local response_body = {}
   local request_constructor = {
      url = url,
      method = "GET",
      sink = ltn12.sink.table(response_body),
      headers = {
         referer = base,
         dnt = "1",
         origin = base,
         ["User-Agent"] = "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.101 Safari/537.36"
      },
      redirect = false
   }

   local arguments = {
      urlparam = param,
      size = size,
	  cacheLimit = "0"
   }

   request_constructor.url = url .. "?" .. helpers.url_encode_arguments(arguments)

   local ok, response_code, response_headers, response_status_line = https.request(request_constructor)
   if not ok or response_code ~= 200 then
      return nil
   end

   local response = table.concat(response_body)
   return string.match(response, "href='(.-)'")
end

local function run(msg, matches)
   if not matches[2] then
     webshot_url = matches[1]
	 size = "X"
   else
     webshot_url = matches[2]
	 size = string.upper(matches[1])
   end
   local find = get_webshot_url(webshot_url, size)
   if find then
      local imgurl = base .. find
      local receiver = get_receiver(msg)
	  if size == "F" then
	    send_document_from_url(receiver, imgurl)
	  else
        send_photo_from_url(receiver, imgurl)
	  end
   end
end


return {
  description = "Sendet einen Screenshot einer Website.",
  usage = {
    "!webshot [URL]/!scrot [URL]: Fertigt Bild mit Größe 1024x768 (X) an",
	"!webshot/!scrot [T|S|E|N|M|L|X|F] [URL]: Fertigt Bild mit bestimmter Größe an (T = tiny, F = full)"
  },
  patterns = {
    "^!webshot ([T|t|S|s|E|e|N|n|M|m|L|l|X|x|F|f]) ([%w-_%.%?%.:,/%+=&#!]+)$",
	"^!scrot ([T|t|S|s|E|e|N|n|M|m|L|l|X|x|F|f]) ([%w-_%.%?%.:,/%+=&#!]+)$",
    "^!webshot ([%w-_%.%?%.:,/%+=&#!]+)$",
	"^!scrot ([%w-_%.%?%.:,/%+=&#!]+)$"
  },
  run = run
}

local function run(msg, patterns)
   local response_body = {}
   local request_constructor = {
      url = patterns[1],
      method = "HEAD",
      sink = ltn12.sink.table(response_body),
      headers = {},
      redirect = false
   }

   local ok, response_code, response_headers, response_status_line = http.request(request_constructor)
   if ok and response_headers.location then
      return response_headers.location
   else
      return "Fehler beim Erweitern der URL."
   end
end

return {
   description = "Erweitert einen verkürzten Link",
   usage = "!expand [URL]: Erweitert einen verkürzten Link",
   patterns = {
      "^!expand (https?://[%w-_%.%?%.:/%+=&]+)$"
   },
   run = run
}

do

local BASE_URL = 'https://api.imgur.com/3'

local function get_imgur_data (imgur_code)
  local client_id = cred_data.imgur_client_id
  local response_body = {}
  local request_constructor = {
      url = BASE_URL..'/image/'..imgur_code,
      method = "GET",
      sink = ltn12.sink.table(response_body),
      headers = {
	    Authorization = 'Client-ID '..client_id
	  }
  }
  local ok, response_code, response_headers, response_status_line = https.request(request_constructor)
  if not ok then
    return nil
  end

  local response_body = json:decode(table.concat(response_body))
  
  if response_body.status ~= 200 then return nil end
    
  return response_body.data.link
end

local function run(msg, matches)
  local imgur_code = matches[1]
  if imgur_code == "login" then return nil end
  local link = get_imgur_data(imgur_code)
  if link then
    local receiver = get_receiver(msg)
	if string.ends(link, ".gif") then
	  send_document_from_url(receiver, link)
	else
	  send_photo_from_url(receiver, link)
	end
  end
end

return {
  description = "Postet Imgur-Bild.", 
  usage = "URL zu Imgur-Bild",
  patterns = {
    "imgur.com/([A-Za-z0-9]+).gifv",
    "https://imgur.com/([A-Za-z0-9]+)"
  },
  run = run 
}

end

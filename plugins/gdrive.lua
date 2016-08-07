do

local BASE_URL = 'https://www.googleapis.com/drive/v2'

local function get_drive_document_data (docid)
  local apikey = cred_data.google_apikey
  local url = BASE_URL..'/files/'..docid..'?key='..apikey..'&fields=id,title,mimeType,ownerNames,exportLinks,fileExtension'
  local res,code  = https.request(url)
  local res = string.gsub(res, 'image/', '')
  local res = string.gsub(res, 'application/', '')
  if code ~= 200 then return "HTTP-FEHLER" end
  local data = json:decode(res)
  return data
end

local function send_drive_document_data(data, receiver)
  local title = data.title
  local mimetype = data.mimeType
  local id = data.id
  local owner = data.ownerNames[1]
  local text = '"'..title..'", freigegeben von '..owner
  if data.exportLinks then
    if data.exportLinks.png then
      local image_url = data.exportLinks.png
      local cb_extra = {
        receiver=receiver,
        url=image_url
      }
      send_msg(receiver, text, send_photo_from_url_callback, cb_extra)
	else
      local pdf_url = data.exportLinks.pdf
	  send_msg(receiver, text, ok_cb, false)
      send_document_from_url(receiver, pdf_url)
	end
  else
    local get_file_url = 'https://drive.google.com/uc?id='..id
	local ext = data.fileExtension
    if mimetype == "png" or mimetype == "jpg" or mimetype == "jpeg" or mimetype == "gif" or mimetype == "webp" then
	  local respbody = {}
      local options = {
        url = get_file_url,
        sink = ltn12.sink.table(respbody),
        redirect = false
      }
      local response = {https.request(options)} -- luasec doesn't support 302 redirects, so we must contact gdrive again
      local code = response[2]
      local headers = response[3]
	  local file_url = headers.location
	  if ext == "jpg"  or ext == "jpeg" or ext == "png" then
        send_photo_from_url(receiver, file_url)
	  else
	    send_document_from_url(receiver, file_url)
	  end
	else
	  local text = '"'..title..'", freigegeben von '..owner..'\nDirektlink: '..get_file_url
	  send_msg(receiver, text, ok_cb, false)
	end
  end
end

local function run(msg, matches)
  local docid = matches[2]
  local data = get_drive_document_data(docid)
  local receiver = get_receiver(msg)
  send_drive_document_data(data, receiver)
end

return {
  description = "Sendet Google-Drive-Info und PDF", 
  usage = "URL zu Google-Drive-Dateien",
  patterns = {
    "docs.google.com/(.*)/d/([A-Za-z0-9-_-]+)",
	"drive.google.com/(.*)/d/([A-Za-z0-9-_-]+)",
    "drive.google.com/(open)%?id=([A-Za-z0-9-_-]+)"
  },
  run = run 
}

end

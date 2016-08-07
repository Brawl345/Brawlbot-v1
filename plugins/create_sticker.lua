do

local apikey = cred_data.cloudinary_apikey
local api_secret = cred_data.cloudinary_api_secret
local public_id = cred_data.cloudinary_public_id
local BASE_URL = 'https://api.cloudinary.com/v1_1/'..public_id..'/image'

local function upload_image(file_url)
  local timestamp = os.time()
  local signature = sha1('timestamp='..timestamp..api_secret)
  local upload_url = BASE_URL..'/upload?api_key='..apikey..'&file='..file_url..'&timestamp='..timestamp..'&signature='..signature
  local res,code  = https.request(upload_url)
  if code ~= 200 then return "HTTP-FEHLER" end
  local data = json:decode(res)
  return data.public_id
end

local function destroy_image(image_id)
  local timestamp = os.time()
  local signature = sha1('public_id='..image_id..'&timestamp='..timestamp..api_secret)
  local destroy_url = BASE_URL..'/destroy?api_key='..apikey..'&public_id='..image_id..'&timestamp='..timestamp..'&signature='..signature
  local res,code  = https.request(destroy_url)
  if code ~= 200 then print("Löschen fehlgeschlagen") end 
  local data = json:decode(res)
  if data.result == "ok" then
    print("Datei von Cloudinary-Server gelöscht")
  else
    print("Löschen fehlgeschlagen")
  end
end

local function run(msg, matches)
  if not sha1 then
    print('sha1 Library wird zum ersten Mal geladen...')
    sha1 = require 'sha1'
  end
  local file_url = matches[1]
  local image_id = upload_image(file_url)
  local file_url = 'https://res.cloudinary.com/'..public_id..'/image/upload/w_512/'..image_id..'.webp'
  local receiver = get_receiver(msg)
  send_document_from_url(receiver, file_url, cb_extra)
  destroy_image(image_id)
end

return {
  description = "Erstellt einen Sticker on-the-fly.", 
  usage = "!sticker [Bilder-URL]: Erstelt einen Sticker aus einem Bild",
  patterns = {
	"^!sticker (https?://[%w-_%.%?%.:/%+=&]+)"
  },
  run = run 
}

end

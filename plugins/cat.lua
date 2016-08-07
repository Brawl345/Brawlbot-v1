
local function run(msg, matches)
  local receiver = get_receiver(msg)
  local apikey = cred_data.cat_apikey or "" -- apply for one here: http://thecatapi.com/api-key-registration.html
  if matches[1] == 'gif' then
    local url = 'http://thecatapi.com/api/images/get?type=gif&apikey='..apikey
    send_document_from_url(receiver, url)
  else
    local url = 'http://thecatapi.com/api/images/get?type=jpg,png&apikey='..apikey
    send_photo_from_url(receiver, url)
  end
end

return {
  description = "Postet das Bild einer zufälligen Katze", 
  usage = {
    "!cat: Postet eine zufällige Katze",
	"!cat gif: Postet eine zufällige, animierte Katze"
  }, 
  patterns = {
    "^!cat$",
	"^!cat (gif)$"
  }, 
  run = run 
}


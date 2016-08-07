
function run(msg, matches)
  local url = matches[1]
  local receiver = get_receiver(msg)
  send_photo_from_url(receiver, url)
end

return {
    description = "Sendet Bild, wenn User einen Link zu einem Bild postet",
    usage = "Direktlink zu einem Bild",
    patterns = {
    	"(https?://[%w-_%%%.%?%.:,/%+=~&%[%]]+%.[Pp][Nn][Gg])$",
    	"(https?://[%w-_%%%.%?%.:,/%+=~&%[%]]+%.[Jj][Pp][Ee]?[Gg])$"
   }, 
    run = run 
}
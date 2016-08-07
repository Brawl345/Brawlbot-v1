-- by Akamaru [https://ponywave.de]
-- modified by iCON

local function run(msg, matches)
  local receiver = get_receiver(msg)
  local url = 'http://www.speedtest.net/result/'..matches[1]..'.png'
  send_photo_from_url(receiver, url)
end

return {
  description = "Speedtest.net Mirror", 
  usage = "Link zu Speedtest.net-Ergebnisseite: Postet Bild direkt",
  patterns = {
    "speedtest.net/my%-result/(%d+)",
	"speedtest.net/my%-result/i/(%d+)"
  }, 
  run = run 
}
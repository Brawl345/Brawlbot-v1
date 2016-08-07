do

function run(msg, matches)
  local lat = matches[1]
  local lon = matches[2]
  local receiver = get_receiver(msg)

  local zooms = {16, 18}

  local urls = {}
  for i in ipairs(zooms) do
    local zoom = zooms[i]
    local url = "https://maps.googleapis.com/maps/api/staticmap?zoom=" .. zoom .. "&size=600x300&maptype=hybrid&center=" .. lat .. "," .. lon .. "&markers=color:red%7Clabel:•%7C" .. lat .. "," .. lon
    table.insert(urls, url)
  end

  send_photos_from_url(receiver, urls)

  return "https://google.com/maps/place/@" .. lat .. "," .. lon
end

return {
  description = "Erzeugt eine Karte mit den angegebenen Koordinaten", 
  usage = "!gps Breitengrad,Längengrad: Sendet Karte mit diesen Koordinaten",
  patterns = {
    "^!gps ([^,]*)[,%s]([^,]*)$",
	"google.de/maps/@([^,]*)[,%s]([^,]*)",
	"google.com/maps/@([^,]*)[,%s]([^,]*)",
	"google.de/maps/place/@([^,]*)[,%s]([^,]*)",
	"google.com/maps/place/@([^,]*)[,%s]([^,]*)"
  }, 
  run = run 
}

end

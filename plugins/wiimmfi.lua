do

local function getplayer(game)
  local url = 'http://wiimmfi.de/game'
  local res,code = http.request(url)
  if code ~= 200 then return "Fehler beim Abrufen von wiimmfi.de" end
  if game == 'mkw' then
    local players = string.match(res, "<td align%=center><a href%=\"/game/mariokartwii\".->(.-)</a>")
    if players == nil then players = 0 end
    text = 'Es spielen gerade '..players..' Spieler Mario Kart Wii'
  else
    local players = string.match(res, "</tr><tr.->(.-)<th colspan%=3")
    local players = string.gsub(players, "</a></td><td>.-<a href=\".-\">", "%: ")
    local players = string.gsub(players, "<td.->", "")
    local players = string.gsub(players, "Wii</td>", "")
    local players = string.gsub(players, "WiiWare</td>", "")
    local players = string.gsub(players, "NDS</td>", "")
    local players = string.gsub(players, "<th.->", "")
    local players = string.gsub(players, "<tr.->", "")
    local players = string.gsub(players, "</tr>", "")
    local players = string.gsub(players, "</th>", "")
    local players = string.gsub(players, "<a.->", "")
    local players = string.gsub(players, "</a>", "")
    local players = string.gsub(players, "</td>", "")
    if players == nil then players = 'Momentan spielt keiner auf Wiimmfi :(' end
    text = players
  end
  return text
end

local function run(msg, matches)
  if matches[1] == "mkw" then
    return getplayer('mkw')
  else
    return getplayer()
  end
end

return {
  description = "Zeigt alle Wiimmfi-Spieler an.", 
  usage = {
    "!wfc: Zeigt alle Wiimmfi-Spieler an.",
	"!mkw: Zeigt alle Mario-Kart-Wii-Spieler an."
  },
  patterns = {
    "^!(mkw)$",
    "^!wiimmfi$",
    "^!wfc$"
  }, 
  run = run 
}

end

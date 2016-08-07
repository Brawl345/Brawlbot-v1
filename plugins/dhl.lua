local BASE_URL = 'https://mobil.dhl.de'

local function sendungsstatus(id)
  local url = BASE_URL..'/shipmentdetails.html?shipmentId='..id
  local res,code = https.request(url)
  if code ~= 200 then return "Fehler beim Abrufen von mobil.dhl.de" end
  local status = string.match(res, "<div id%=\"detailShortStatus\">(.-)</div>")
  local status = all_trim(status)
  local zeit = string.match(res, "<div id%=\"detailStatusDateTime\">(.-)</div>")
  local zeit = all_trim(zeit)
  if not zeit or zeit == '<br />' then
    return status
  end
  return status..'\nStand: '..zeit
end

local function run(msg, matches)
  local sendungs_id = matches[1]
  if string.len(sendungs_id) < 8 then return nil end
  return sendungsstatus(sendungs_id)
end

return {
  description = "Zeigt den aktuellen Status einer DHL-Sendung an.", 
  usage = {
    "!dhl (Sendungsnummer): Aktueller Status der Sendung"
  },
  patterns = {
    "^!dhl (%d+)$"
  }, 
  run = run 
}

end

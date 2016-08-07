do

local BASE_URL = 'https://currencyconverter.p.mashape.com'

local function get_currency_data (from, to, amount)
  local apikey = cred_data.x_mashape_key
  local url = BASE_URL..'/?from='..from..'&from_amount='..amount..'&to='..to..'&mashape-key='..apikey
  local res,code  = https.request(url)
  if code ~= 200 then return "HTTP-FEHLER" end
  local data = json:decode(res)
  return data
end

local function send_currency_data(data, receiver)
  if data.error ~= nil then
    return
  else
    local from = data.from
    local to = data.to
    local from_amount = string.gsub(data.from_amount, "%.", "%,")
    local dot_to_amount = round(data.to_amount, 2)
	local to_amount = string.gsub(dot_to_amount, "%.", "%,")
    local text = from_amount..' '..from..' = '..to_amount..' '..to
    send_msg(receiver, text, ok_cb, false)
  end
end

local function run(msg, matches)
  local from = string.upper(matches[1])
  if matches[2] == nil then
    to = "EUR"
  else
    to = string.upper(matches[2])
  end
  if matches[3] == nil then
   	amount = 1
  else
    amount = string.gsub(matches[3],"%,","%.")
  end
  if matches[1] == "!eur" then
    to = "USD"
	from = "EUR"
  end
  local data = get_currency_data(from, to, amount)
  local receiver = get_receiver(msg)
  send_currency_data(data, receiver)
end

return {
  description = "Wandelt Geldeinheiten um. 💶 💶 💶", 
  usage = "!money [von] [zu] [Menge]: Wandelt Geldeinheiten um (Symbole: http://bit.ly/botmoney)",
  patterns = {
    "^!money ([A-Za-z]+)$",
    "^!money ([A-Za-z]+) ([A-Za-z]+)$",
	"^!money ([A-Za-z]+) ([A-Za-z]+) (%d+[%d%.,]*)$",
	"^(!eur)$"
  },
  run = run 
}

end

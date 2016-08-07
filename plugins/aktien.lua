do

local function get_stock (symbol)
  local BASE_URL = 'https://query.yahooapis.com/v1/public/yql'
  local url = BASE_URL..'?q=select%20*%20from%20yahoo.finance.quotes%20where%20symbol="'..symbol..'"&env=http%3A%2F%2Fdatatables.org%2Falltables.env&format=json'
  local res,code  = https.request(url)
  if code ~= 200 then return "HTTP-FEHLER" end
  local data = json:decode(res).query.results.quote
  return data
end

function send_stock_data(data, receiver)
   -- local ask = data.Ask
  local bid = data.Bid
  local change = data.Change
  local percent = data.ChangeinPercent
  local currency = data.Currency
  local range = data.DaysRange
  local name = data.Name
  local yesterday = data.PreviousClose
  local year_range = data.YearRange
  local symbol = data.symbol
  
  local text = name..' ('..symbol..') Aktien in '..currency..':\nAktueller Preis: '..bid..' ('..change..' / '..percent..')\nGestriger Preis: '..yesterday..'\nHeute: '..range..'\nDieses Jahr: '..year_range
  send_msg(receiver, text, ok_cb, false)
end

local function run(msg, matches)
  local symbol = string.upper(matches[1])
  local data = get_stock(symbol)
  local receiver = get_receiver(msg)
  if data.Bid ~= nil then
    send_stock_data(data, receiver)
  else
    return "Dieses Symbol existiert nicht."
  end
end

return {
  description = "Sendet Aktieninfos", 
  usage = "!aktien [Symbol]: Sendet Aktieninfos",
  patterns = {
    "^!aktien ([A-Za-z0-9]+)$",
	"^!stocks ([A-Za-z0-9]+)$",
	"^!aktie ([A-Za-z0-9]+)$",
	"^!stock ([A-Za-z0-9]+)$"
  },
  run = run 
}

end

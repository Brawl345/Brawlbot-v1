do

function run(msg, matches)
 local text = msg.text
 local url = "https://brawlbot.tk/apis/chatter-bot-api/cleverbot.php?text="..URL.escape(text)
 local query = https.request(url)
 if query == nil then return 'Ein Fehler ist aufgetreten :(' end
 local decode = json:decode(query)
 local answer = string.gsub(decode.clever, "&Auml;", "Ä")
 local answer = string.gsub(answer, "&auml;", "ä")
 local answer = string.gsub(answer, "&Ouml;", "Ö")
 local answer = string.gsub(answer, "&ouml;", "ö")
 local answer = string.gsub(answer, "&Uuml;", "Ü")
 local answer = string.gsub(answer, "&uuml;", "ü")
 local answer = string.gsub(answer, "&szlig;", "ß")
 return answer
end


return {
  description = "Chat mit CleverBot", 
  usage = "!cbot [Text]: Befragt den Cleverbot",
  patterns = {
	"^!cbot (.*)$"
 },
 run = run
}

end
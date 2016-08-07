-- TTS plugin in lua
local function run(msg, matches)
    local receiver = get_receiver(msg)
	if matches[2] == nil then
      text = matches[1]
	  lang = 'de'
	else
	  text = matches[2]
	  lang = matches[1]
	end
    local b = 1
    
	local text = string.gsub(text, "%+", "plus")
    while b ~= 0 do
        text,b = text:gsub('^+','+')
        text = text:trim()
    end

    local text = string.gsub(text, "%s+", "+")
	-- because everyone loves german umlauts, right? :3
	local text = string.gsub(text, "ä", "ae")
	local text = string.gsub(text, "Ä", "Ae")
	local text = string.gsub(text, "ö", "oe")
	local text = string.gsub(text, "Ö", "Oe")
	local text = string.gsub(text, "ü", "ue")
	local text = string.gsub(text, "Ü", "Ue")
	local text = string.gsub(text, "ß", "ss")
	local text = string.gsub(text, "%&", "und")
	if string.len(text) > 160 then return 'Text zu lang!' end
	local text = string.gsub(text, " ", "+")
	local url = 'http://tts.baidu.com/text2audio?lan='..lang..'&ie=UTF-8&text='..text
    local file = download_to_file(url, text..'.mp3')
	if not file then
	  return "Ein Fehler ist aufgetreten, besuche die URL eventuell direkt?\n"..url
	end
    local cb_extra = {file_path=file}
    send_audio(receiver, file, rmtmp_cb, cb_extra)
end

return {
  description = "Text-To-Speech",
  usage = {
    "!tts [Text]: Sendet Sprachnachricht mit dem Text",
	"!tts(Sprache) [Text]: Sendet Sprachnachricht in der Sprache mit dem Text (bspw. !ttsen Hello)"
  },
  patterns = {
    "^!tts (.+)$",
    "^!tts(%w+) (.+)$"
  },
  run = run
}
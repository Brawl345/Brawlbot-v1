do

local function run(msg, matches)
  local user_name = get_name(msg)
  local receiver = get_receiver(msg)
  local GDRIVE_URL = 'https://de2319bd4b4b51a5ef2939a7638c1d35646f49f8.googledrive.com/host/0B_mfIlDgPiyqU25vUHZqZE9IUXc'
  if user_name == "DefenderX" then user_name = "Deffu" end
	
  if string.match(msg.text, "[Ff][Gg][Tt].? [Ss][Ww][Ii][Ff][Tt]") then
    return 'Dünnes Eis, '..user_name..'!'
  elseif string.match(msg.text, "[Tt]it") then
    return 'ten'
  elseif string.match(msg.text, "([Ee][Ii][Nn][Zz][Ii][Gg][Ss][Tt][Ee][Ss])") then
	return '*einziges'
  elseif string.match(msg.text, "([Ee][Ii][Nn][Zz][Ii][Gg][Ss][Tt][Ee][Rr])") then
    return '*einziger'
  elseif string.match(msg.text, "([Ee][Ii][Nn][Zz][Ii][Gg][Ss][Tt][Ee])") then
    return '*einzige'
  elseif string.match(msg.text, "[Bb][Oo][Tt]%??") then
    return 'Ich bin da, '..user_name..'!'
  elseif string.match(msg.text, "[Ll][Oo][Dd]") then
    return 'ಠ_ಠ'
  elseif string.match(msg.text, "[Ll][Ff]") then
    return '( ͡° ͜ʖ ͡°)'
  elseif string.match(msg.text, "[Nn][Bb][Cc]") or string.match(msg.text, "[Ii][Dd][Cc]") or string.match(msg.text, "[Kk][Aa]") or string.match(msg.text, "[Ii][Dd][Kk]")  then
    return  [[¯\_(ツ)_/¯]]
  elseif string.match(msg.text, "[Ff][Rr][Oo][Ss][Cc][Hh]") then
    return "🐸🐸🐸"
  elseif string.match(msg.text, "[Ii][Nn][Ll][Oo][Vv][Ee]") then
   send_document_from_url(receiver, GDRIVE_URL..'/inlove.gif')
  elseif string.match(msg.text, "[Ww][Aa][Tt]") then
    local WAT_URL = GDRIVE_URL..'/wat'
    local wats = {
      "/wat1.jpg",
      "/wat2.jpg",
      "/wat3.jpg",
	  "/wat4.jpg",
	  "/wat5.jpg",
	  "/wat6.jpg",
	  "/wat7.jpg",
	  "/wat8.jpg"
    }
  	local random_wat = math.random(5)
    send_photo_from_url(receiver, WAT_URL..wats[random_wat])
  end
  
end

return {
  description = "Auto-Responder", 
  usage = "",
  patterns = {
	"([Ff][Gg][Tt].? [Ss][Ww][Ii][Ff][Tt])",
	"^([Tt]it)$",
	"([Ee][Ii][Nn][Zz][Ii][Gg][Ss][Tt][Ee][Ss])",
	"([Ee][Ii][Nn][Zz][Ii][Gg][Ss][Tt][Ee][Rr])",
	"([Ee][Ii][Nn][Zz][Ii][Gg][Ss][Tt][Ee])",
	"^[Bb][Oo][Tt]%??$",
	"^!([Ll][Oo][Dd])$",
	"^!([Ll][Ff])$",
	"^!([Kk][Aa])$",
	"^!([Ii][Dd][Kk])$",
	"^!([Nn][Bb][Cc])$",
	"^!([Ii][Dd][Cc])$",
	"^%*([Ff][Rr][Oo][Ss][Cc][Hh])%*",
	"^!([Ff][Rr][Oo][Ss][Cc][Hh])$",
	"^%(([Ii][Nn][Ll][Oo][Vv][Ee])%)$",
	"^![Ww][Aa][Tt]$"
  }, 
  run = run 
}

end
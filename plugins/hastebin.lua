
function upload(text, noraw)
  local base = "http://hastebin.com/"
  local pet = post_petition(base.."documents", text)
  if pet == nil then
    return '', ''
  end
  local key = pet.key
  if noraw then
    return base..key
  else
    return base..'raw/'..key
  end
end

function run(msg, matches)
  local text = matches[1]
  local link = upload(text)
  return link
end

return {
  description = "Hastebin-Schnittstelle",
  usage = "!paste [Text]: Postet Text auf Hastebin",
  patterns = {
    "^!paste (.*)$"
  },
  run = run
}

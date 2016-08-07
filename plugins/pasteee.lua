
local key = cred_data.pasteee_key

function upload(text, noraw)
  local url = "https://paste.ee/api"
  local pet = post_petition(url, 'key='..key..'&paste='..text..'&format=json')
  if pet.status ~= 'success' then return 'Ein Fehler ist aufgetreten: '..pet.error end
  if noraw then
    return pet.paste.link
  else
    return pet.paste.raw
  end
end

function run(msg, matches)
  local text = matches[1]
  local link = upload(text)
  return link
end

return {
  description = "Paste.ee-Schnittstelle",
  usage = "!pasteee [Text]: Postet Text auf Paste.ee",
  patterns = {
    "^!pasteee (.*)$"
  },
  run = run
}

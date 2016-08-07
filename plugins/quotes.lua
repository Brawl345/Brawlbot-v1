do

require("./plugins/pasteee")

local function save_quote(msg)
  if msg.text:sub(11):isempty() then
    return "Benutzung: !addquote [Zitat]"
  end
  
  local quote = msg.text:sub(11)
  local hash = get_redis_hash(msg, 'quotes')
  print('Saving quote to redis set '..hash)
  redis:sadd(hash, quote)
  return 'Gespeichert: "'..quote..'"'
end

local function delete_quote(msg)
  if msg.text:sub(11):isempty() then
    return "Benutzung: !delquote [Zitat]"
  end
  
  local quote = msg.text:sub(11)
  local hash = get_redis_hash(msg, 'quotes')
  print('Deleting quote from redis set '..hash)
  if redis:sismember(hash, quote) == true then
    redis:srem(hash, quote)
    return 'Zitat erfolgreich gelöscht!'
  else
    return 'Dieses Zitat existiert nicht.'
  end
end

local function get_quote(msg)
  local to_id = tostring(msg.to.id)
  local hash = get_redis_hash(msg, 'quotes')
  
  if hash then
    print('Getting quote from redis set '..hash)
  	local quotes_table = redis:smembers(hash)
	if not quotes_table[1] then
	  return 'Es wurden noch keine Zitate gespeichert.\nSpeichere doch welche mit !addquote [Zitat]'
	else
	  return quotes_table[math.random(1,#quotes_table)]
	end
  end
end

local function list_quotes(msg)
  local hash = get_redis_hash(msg, 'quotes')
  
  if hash then
    print('Getting quotes from redis set '..hash)
    local quotes_table = redis:smembers(hash)
	local text = ""
    for num,quote in pairs(quotes_table) do
      text = text..num..") "..quote..'\n'
    end
	if not text or text == "" then
	  return 'Es wurden noch keine Zitate gespeichert.\nSpeichere doch welche mit !addquote [Zitat]'
	else
	  return upload(text)
	end
  end
end

local function run(msg, matches)
  if matches[1] == "quote" then
    return get_quote(msg)
  elseif matches[1] == "addquote" then
    return save_quote(msg)
  elseif matches[1] == "delquote" then
    if not is_sudo(msg) then
      return "Du bist kein Superuser. Dieser Vorfall wird gemeldet."
    else
      return delete_quote(msg)
	end
  elseif matches[1] == "listquotes" then
    return list_quotes(msg)
  end
end

return {
  description = "Zitate speichern, löschen und abrufen.",
  usage = {
    "!addquote [Zitat]: Fügt Zitat hinzu.",
	"!quote: Gibt zufälliges Zitat aus.",
	"!delquote [Zitat]: Löscht das Zitat (nur Superuser)",
	"!listquotes: Listet alle Zitate auf"
  },
  patterns = {
    "^!(delquote) (.+)$",
    "^!(addquote) (.+)$",
    "^!(quote)$",
	"^!(listquotes)$"
  },
  run = run
}

end
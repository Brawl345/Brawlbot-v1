local function save_value(msg, name, value)
  if (not name or not value) then
    return "Benutzung: !set Variable Wert"
  end

  local hash = get_redis_hash(msg, 'variables')
  if hash then
     print('Saving variable to redis hash '..hash)
    redis:hset(hash, name, value)
    return "Gespeichert: "..name.." = "..value
  end
end

local function delete_value(msg, name)
  local hash = get_redis_hash(msg, 'variables')
  if redis:hexists(hash, name) == true then
    print('Deleting variable from redis hash '..hash)
    redis:hdel(hash, name)
    return 'Variable "'..name..'" erfolgreich gelöscht!'
  else
    return 'Du kannst keine Variable löschen, die nicht existiert .-.'
  end
end

local function run(msg, matches)
  local name = string.sub(matches[1], 1, 50)
  local value = string.sub(matches[2], 1, 1000)

  if value == "nil" then
    text = delete_value(msg, name)
  else
    text = save_value(msg, name, value)
  end
  return text
end

return {
  description = "Setzt Variablen, nutze !get zum Abrufen.", 
  usage = {
    "!set [Variable] [Wert]: Speichert eine Variable mit einem Wert.",
	"!set (Variable) nil: Löscht Variable"
  },
  patterns = {
    "^!set ([^%s]+) (.+)$"
  }, 
  run = run 
}


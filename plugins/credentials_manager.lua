local hash = "telegram:credentials"

-- See: http://www.lua.org/pil/19.3.html
function pairsByKeys (t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
    i = i + 1
    if a[i] == nil then
	  return nil
    else
	  return a[i], t[a[i]]
    end
  end
  return iter
end

function reload_creds()
  cred_data = redis:hgetall(hash)
end

function list_creds()
  reload_creds()
  if redis:exists("telegram:credentials") == true then
    local text = ""
    for var, key in pairsByKeys(cred_data) do
      text = text..var..' = '..key..'\n'
    end
    return text
  else
    create_cred()
	return "Es wurden noch keine Logininformationen gespeichert, lege Tabelle an...\nSpeichere Keys mit !creds add [Variable] [Key] ein!"
  end
end

function add_creds(var, key)
  print('Saving credential for '..var..' to redis hash '..hash)
  redis:hset(hash, var, key)
  reload_creds()
  return var..' = '..key..'\neingespeichert!'
end

function del_creds(var)
  if redis:hexists(hash, var) == true then
    print('Deleting credential for '..var..' from redis hash '..hash)
    redis:hdel(hash, var)
	reload_creds()
    return 'Key von "'..var..'" erfolgreich gelöscht!'
  else
    return 'Du hast keine Logininformationen für diese Variable eingespeichert.'
  end
end

function rename_creds(var, newvar)
  if redis:hexists(hash, var) == true then
    local key = redis:hget(hash, var)
	if redis:hsetnx(hash, newvar, key) == true then
	  redis:hdel(hash, var)
	  reload_creds()
	  return '"'..var..'" erfolgreich zu "'..newvar..'" umbenannt.'
	else
	  return "Variable konnte nicht umbenannt werden: Zielvariable existiert bereits."
	end
  else
    return 'Die zu umbennende Variable existiert nicht.'
  end
end

function run(msg, matches)
  local receiver = get_receiver(msg)
 
  if not is_sudo(msg) then
    return 'Du bist kein Superuser. Dieser Vorfall wird gemeldet!'
  end

  if msg.to.type == 'chat' then
    return 'Das Plugin solltest du nur per PN nutzen!'
  end
  
  if matches[1] == "!creds" then
    return list_creds()
  elseif matches[1] == "!creds add" then
    local var = string.lower(string.sub(matches[2], 1, 50))
    local key = string.sub(matches[3], 1, 1000)
    return add_creds(var, key)
  elseif matches[1] == "!creds del" then
    local var = string.lower(matches[2])
    return del_creds(var)
  elseif matches[1] == "!creds rename" then
    local var = string.lower(string.sub(matches[2], 1, 50))
    local newvar = string.lower(string.sub(matches[3], 1, 1000))
    return rename_creds(var, newvar)
  end
end

return {
  description = "Loginmanager für Telegram (nur Superuser)", 
  usage = {
    "!creds: Zeigt alle Logindaten und API-Keys",
	"!creds add [Variable] [Key]: Speichert Key mit der Variable ein",
	"!creds del [Variable]: Löscht Key mit der Variable",
	"!creds rename [Variable] [Neuer Name]: Benennt Variable um, behält Key bei"
  },
  patterns = {
    "^(!creds)$",
	"^(!creds add) ([^%s]+) (.+)$",
	"^(!creds del) (.+)$",
	"^(!creds rename) ([^%s]+) (.+)$"
  }, 
  run = run,
  privileged = true
}
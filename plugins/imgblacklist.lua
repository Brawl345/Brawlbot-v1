local _blacklist

local function show_blacklist()
  if not _blacklist[1] then
    return "Keine Wörter geblacklisted!\nBlackliste welche mit !imgblacklist add [Wort]"
  else
    local sort_alph = function( a,b ) return a < b end
    table.sort( _blacklist, sort_alph )
    local blacklist = "Folgende Wörter stehen auf der Blacklist:\n"
    for v,word in pairs(_blacklist) do
      blacklist = blacklist..'- '..word..'\n'
    end
	return blacklist
  end
end

local function add_blacklist()
  print('Blacklisting '..word..' - saving to redis set telegram:img_blacklist')
  if redis:sismember("telegram:img_blacklist", word) == true then
    return '"'..word..'" steht schon auf der Blacklist.'
  else
    redis:sadd("telegram:img_blacklist", word)
    return '"'..word..'" blacklisted!'
  end
end

local function remove_blacklist()
  print('De-blacklisting '..word..' - removing from redis set telegram:img_blacklist')
  if redis:sismember("telegram:img_blacklist", word) == true then
    redis:srem("telegram:img_blacklist", word)
    return '"'..word..'" erfolgreich von der Blacklist gelöscht!'
  else
    return '"'..word..'" steht nicht auf der Blacklist.'
  end
end

function run(msg, matches)
  local action = matches[1]
  if matches[2] then word = string.lower(matches[2]) end
  _blacklist = redis:smembers("telegram:img_blacklist")

  if action == "add" and word == nil then
    return "Benutzung: !imgblacklist add [Wort]"
  elseif action == "add" and word then
    return add_blacklist()
  end
  
  if action == "remove" and word == nil then
    return "Benutzung: !imgblacklist remove [Wort]"
  elseif action == "remove" and word then
    return remove_blacklist()
  end

  return show_blacklist()
end

return {
  description = "Blacklist-Manager für Bilder-Plugins (nur Superuser)", 
  usage = {
	"!imgblacklist show: Zeigt Blacklist",
	"!imgblacklist add [Wort]: Fügt Wort der Blacklist hinzu",
	"!imgblacklist remove [Wort]: Entfernt Wort aus der Blacklist"
  },
  patterns = {
	"^!imgblacklist show$",
    "^!imgblacklist (add) (.*)$",
	"^!imgblacklist (remove) (.*)$"
  }, 
  run = run,
  privileged = true
}
end
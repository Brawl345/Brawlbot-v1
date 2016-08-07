local url = 'http://www.tagesschau.de/api'
local hash = 'telegram:tagesschau'

local makeOurDate = function(dateString)
  local pattern = "(%d+)%-(%d+)%-(%d+)T(%d+)%:(%d+)%:(%d+)"
  local year, month, day, hours, minutes, seconds = dateString:match(pattern)
  return day..'.'..month..'.'..year..' um '..hours..':'..minutes..':'..seconds
end

local function abonniere_eilmeldungen(id)
  if redis:sismember(hash..':subs', id) == false then
    redis:sadd(hash..':subs', id)
	return 'Eilmeldungen abonniert.'
  else
    return 'Die Eilmeldungen wurden hier bereits abonniert.'
  end
end

local function deabonniere_eilmeldungen(id)
  if redis:sismember(hash..':subs', id) == true then
    redis:srem(hash..':subs', id)
	return 'Eilmeldungen deabonniert.'
  else
    return 'Die Eilmeldungen wurden hier noch nicht abonniert.'
  end
end

local function cron()
  print('Prüfe auf Tagesschau-Eilmeldungen...')
  local last_eil = redis:get(hash..':last_entry')
  local res,code  = http.request(url)
  local data = json:decode(res)
  if code ~= 200 then return end
  if not data then return end
  if data.breakingnews[1] then
    if data.breakingnews[1].details ~= last_eil then
      local title = '#Eilmeldung: '..data.breakingnews[1].headline
      local news = data.breakingnews[1].shorttext
      local posted_at = makeOurDate(data.breakingnews[1].date)..' Uhr'
	  local post_url = string.gsub(data.breakingnews[1].details, '/api/', '/')
	  local post_url = string.gsub(post_url, '.json', '.html')
      local eil = title..'\n'..posted_at..'\n'..news..'\n— '..post_url
      redis:set(hash..':last_entry', data.breakingnews[1].details)
	  for _,user in pairs(redis:smembers(hash..':subs')) do
        send_large_msg(user, eil)
      end
    end
  end
end

local function run(msg, matches)
  local id = "user#id" .. msg.from.id
  if is_chat_msg(msg) then
	id = "chat#id" .. msg.to.id
  end
  
  if matches[1] == "sync" then
    if not is_sudo(msg) then
	  return "Nur Superuser können die Eilmeldungen aktualisieren."
	end
	cron()
  end
   
  if matches[1] == "subscribe" or matches[1] == "sub" then
    return abonniere_eilmeldungen(id)
  end

  if matches[1] == "unsubscribe" or matches[1] == "uns" then
    return deabonniere_eilmeldungen(id)
  end
end

return {
  description = "Tagesschau-Eilmeldungen abonnieren", 
  usage = {
    "!eil sub: Eilmeldungen abonnieren",
    "!eil uns: Eilmeldungen deabonnieren",
    "!eil sync: Nach neuen Eilmeldungen prüfen (nur Superuser)"
  },
  patterns = {
    "^!eil (subscribe)$",
    "^!eil (sub)$",
    "^!eil (unsubscribe)$",
    "^!eil (uns)$",
    "^!eil (sync)$"
  },
  run = run,
  cron = cron
}

end
local BASE_URL = 'https://maker.ifttt.com/trigger'

local function set_ifttt_key(hash, key)
  print('Setting ifttt in redis hash '..hash..' to '..key)
  redis:hset(hash, 'ifttt', key)
  return 'Schlüssel eingespeichert. Das Plugin kann jetzt verwendet werden'
end

local function do_ifttt_request(key, event, value1, value2, value3)
  if not value1 then
    url = BASE_URL..'/'..event..'/with/key/'..key
  elseif not value2 then
    url = BASE_URL..'/'..event..'/with/key/'..key..'/?value1='..URL.escape(value1)
  elseif not value3 then
    url = BASE_URL..'/'..event..'/with/key/'..key..'/?value1='..URL.escape(value1)..'&value2='..URL.escape(value2)
  else
    url = BASE_URL..'/'..event..'/with/key/'..key..'/?value1='..URL.escape(value1)..'&value2='..URL.escape(value2)..'&value3='..URL.escape(value3)
  end
  
  local res,code = https.request(url)
  if code ~= 200 then return "Ein Fehler ist aufgetreten, Aktion wurde nicht ausgeführt." end
  
  return "Event "..event.." ausgeführt!"
end

local function run(msg, matches)
  local hash = 'user:'..msg.from.id
  local key = redis:hget(hash, 'ifttt')
  local event = matches[1]
  local value1 = matches[2]
  local value2 = matches[3]
  local value3 = matches[4]
  
  if event == '_set' then
    return set_ifttt_key(hash, value1)
  end
  
  if not key then
    return 'Bitte speichere zuerst deinen Schlüssel ein. Aktiviere dazu den IFTTT Maker Channel unter https://ifttt.com/maker und speichere deinen Schlüssel mit\n!ifttt _set KEY\nein'
  end
  
  if event == '_unauth' then
    redis:hdel(hash, 'ifttt')
	return 'Erfolgreich ausgeloggt!'
  end
  
  return do_ifttt_request(key, event, value1, value2, value3)
end

return {
  description = "IFTTT Maker für Telegram",
  usage = {
    "!ifttt _set [Key]: Speichere deinen Schlüssel ein (erforderlich)",
	"!ifttt _unauth: Löscht deinen Account aus dem Brawlbot",
	"!ifttt [Event] (Value1)&(Value2)&(Value3): Führt [Event] aus, mit den optionalen Parametern Value1, Value2 und Value3.",
	"Beispiel: !ifttt DeinFestgelegterName Hallo&NochEinHallo: Führt 'DeinFestgelegterName' mit den Parametern 'Hallo' und 'NochEinHallo' aus."
  },
  patterns = {
    "^!ifttt (_set) (.*)$",
	"^!ifttt (_unauth)$",
	"^!ifttt (.*)%&(.*)%&(.*)%&(.*)",
	"^!ifttt (.*)%&(.*)%&(.*)",
	"^!ifttt (.*)%&(.*)",
	"^!ifttt (.*)$"
  },
  run = run
}

end
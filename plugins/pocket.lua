local BASE_URL = 'https://getpocket.com/v3'
local consumer_key = cred_data.pocket_consumer_key
local headers = {
   ["Content-Type"] = "application/x-www-form-urlencoded; charset=UTF8",
  ["X-Accept"] = "application/json"
}

local function list_pocket_items(access_token)
  local items = post_petition(BASE_URL..'/get', 'consumer_key='..consumer_key..'&access_token='..access_token..'&state=unread&sort=newest&detailType=simple', headers)
  
  if items.status == 2 then return 'Keine Elemente eingespeichert.' end
  if items.status ~= 1 then return 'Ein Fehler beim Holen der Elemente ist aufgetreten.' end
  
  local text = ''
  for element in orderedPairs(items.list) do
    title = items.list[element].given_title
	if not title or title == "" then title = items.list[element].resolved_title end
    text = text..'#'..items.list[element].item_id..': '..title..'\n— '..items.list[element].resolved_url..'\n\n'
  end
  
  return text
end

local function set_pocket_access_token(hash, access_token)
  if string.len(access_token) ~= 30 then return 'Inkorrekter Access-Token' end
  print('Setting pocket in redis hash '..hash..' to users access_token')
  redis:hset(hash, 'pocket', access_token)
  return 'Authentifizierung abgeschlossen. Das Plugin kann jetzt verwendet werden'
end

local function add_pocket_item(access_token, url)
  local result = post_petition(BASE_URL..'/add', 'consumer_key='..consumer_key..'&access_token='..access_token..'&url='..url, headers)
  if result.status ~= 1 then return 'Ein Fehler beim Hinzufügen der URL ist aufgetreten :(' end
  local given_url = result.item.given_url
  if result.item.title == "" then
    title = 'Seite'
  else
    title = '"'..result.item.title..'"'
  end
  local code = result.item.response_code
  
  local text = title..' ('..given_url..') hinzugefügt!'
  if code ~= "200" and code ~= "0" then text = text..'\nAber die Seite liefert Fehler '..code..' zurück.' end
  return text
end

local function modify_pocket_item(access_token, action, id)
  local result = post_petition(BASE_URL..'/send', 'consumer_key='..consumer_key..'&access_token='..access_token..'&actions=[{"action":"'..action..'","item_id":'..id..'}]', headers)
  if result.status ~= 1 then return 'Ein Fehler ist aufgetreten :(' end
  
  if action == 'readd' then
    if result.action_results[1] == false then
	  return 'Dieser Eintrag existiert nicht!'
	end
    local url = result.action_results[1].normal_url
	return url..' wieder de-archiviert'
  end
  if result.action_results[1] == true then
    return 'Aktion ausgeführt.'
  else
    return 'Ein Fehler ist aufgetreten.'
  end
end  

local function run(msg, matches)
  local hash = 'user:'..msg.from.id
  local access_token = redis:hget(hash, 'pocket')
  
  if matches[1] == 'set' then
    local access_token = matches[2]
    return set_pocket_access_token(hash, access_token)
  end
  
  if not access_token then
    return 'Bitte authentifiziere dich zuerst, indem du folgende Seite aufrufst:\nhttps://brawlbot.tk/apis/callback/pocket/connect.php'
  end
  
  if matches[1] == 'unauth' then
    redis:hdel(hash, 'pocket')
	return 'Erfolgreich ausgeloggt! Du kannst den Zugriff hier endgültig entziehen:\nhttps://getpocket.com/connected_applications'
  end
  
  if matches[1] == 'add' then
    return add_pocket_item(access_token, matches[2])
  end
  
  if matches[1] == 'archive' or matches[1] == 'delete' or matches[1] == 'readd' or matches[1] == 'favorite' or matches[1] == 'unfavorite' then
    return modify_pocket_item(access_token, matches[1], matches[2])
  end
  
  if msg.to.type == 'chat' then
    return 'Ausgeben deiner privaten Pocket-Liste in einem öffentlichen Chat wird feige verweigert. Bitte schreibe mich privat an!'
  else
    return list_pocket_items(access_token)
  end
end

return {
  description = "Pocket-Plugin für Telegram",
  usage = {
    "!pocket: Postet Liste deiner Links",
	"!pocket add (url): Fügt diese URL deiner Liste hinzu",
	"!pocket archive [id]: Archiviere diesen Eintrag",
	"!pocket readd [id]: De-archiviere diesen Eintrag",
	"!pocket favorite [id]: Favorisiere diesen Eintrag",
	"!pocket unfavorite [id]: Entfavorisiere diesen Eintrag",
	"!pocket delete [id]: Lösche diesen Eintrag",
	"!pocket unauth: Löscht deinen Account aus dem Brawlbot"
  },
  patterns = {
    "^!pocket (set) (.+)$",
	"^!pocket (add) (https?://[%w-_%.%?%.:/%%%+=&~]+)$",
	"^!pocket (archive) (%d+)$",
	"^!pocket (readd) (%d+)$",
	"^!pocket (unfavorite) (%d+)$",
	"^!pocket (favorite) (%d+)$",
	"^!pocket (delete) (%d+)$",
	"^!pocket (unauth)$",
    "^!pocket$"
  },
  run = run
}

end
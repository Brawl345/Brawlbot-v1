do

require("./plugins/time")

local function set_location(user_id, location)
  local hash = 'user:'..user_id
  local set_location = get_location(user_id)
  if set_location == location then
    return 'Dieser Ort wurde bereits gesetzt'
  else
    print('Setting location in redis hash '..hash..' to location')
    redis:hset(hash, 'location', location)
    return 'Dein Wohnort wurde auf "'..location..'" festgelegt.'
  end
end

local function del_location(user_id)
  local hash = 'user:'..user_id
  local set_location = get_location(user_id)
  if not set_location then
    return 'Du hast keinen Ort gesetzt'
  else
    print('Setting location in redis hash '..hash..' to false')
	-- We set the location to false, because deleting the value blocks redis for a few milliseconds
    redis:hset(hash, 'location', false)
    return 'Dein Wohnort "'..set_location..'" wurde gelöscht!'
  end
end

local function run(msg, matches)
  local user_id = msg.from.id
  
  if matches[1] == 'set' then
    return set_location(user_id, matches[2])
  elseif matches[1] == 'del' then
    return del_location(user_id)
  else
    local set_location = get_location(user_id)
    if not set_location then
      return 'Du hast keinen Ort gesetzt'
    else
	  local lat,lng = get_latlong(set_location)
	  local receiver = get_receiver(msg)
	  send_location(receiver, lat, lng, ok_cb, false)
      return 'Gesetzter Wohnort: '..set_location
    end
  end
end

return {
  description = "Orte-Manager", 
  usage = {
    "!location: Gibt deinen gesetzten Wohnort aus",
    "!location set (Ort): Setzt deinen Wohnort auf diesen Ort",
	"!location del: Löscht deinen angegebenen Wohnort"
  },
  patterns = {
	"^!location (set) (.*)$",
    "^!location (del)$",
	"^!location$"
  }, 
  run = run 
}

end

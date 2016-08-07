do

local function save_chatname(msg)
  local hash = get_redis_hash(msg, 'data')
  local chat_name = msg.to.title
  local saved_name = redis:hget(hash, 'chat_name')
  if chat_name ~= saved_name then
    print('Saving chat name '..chat_name..' to redis hash '..hash)
    redis:hset(hash, 'chat_name', chat_name)
    return "Chatname '"..chat_name.."' gespeichert, wird jetzt immer darauf zurückgesetzt."
  else
    return "Chatname ist bereits eingespeichert."
  end
end

local function delete_chatname(msg)
  local hash = get_redis_hash(msg, 'data')
  local saved_name = redis:hget(hash, 'chat_name')
  if saved_name then
    print('Deleting chat name '..saved_name..' from redis hash '..hash)
    redis:hdel(hash, 'chat_name')
    return "Chatname gelöscht, wird jetzt nicht mehr darauf zurückgesetzt."
  else
    return "Chatname wurde noch nicht eingespeichert."
  end
end

local function ren_chat(msg, new_chat_name)
  local receiver = get_receiver(msg)
  local hash = get_redis_hash(msg, 'data')
  local saved_name = redis:hget(hash, 'chat_name')
  
  if new_chat_name == saved_name then return 'Das war ja ein lahmer Trollversuch...' end
  
  if not saved_name then
    rename_chat(receiver, new_chat_name, ok_cb, false)
  else
    print('Changing chat name from '..saved_name..' to '..new_chat_name..' in redis hash '..hash)
    redis:hset(hash, 'chat_name', new_chat_name)
	rename_chat(receiver, new_chat_name, ok_cb, false)
    return "Chatname wurde permanent auf '"..new_chat_name.."' geändert."
  end
end

local function save_chatphoto(msg, path)
  local hash = get_redis_hash(msg, 'data')
  local saved_path = redis:hget(hash, 'chat_photo')
  if path ~= saved_path then
    print('Saving chat photo path '..path..' to redis hash '..hash)
    redis:hset(hash, 'chat_photo', path)
    return "Bild mit dem Pfad '"..path.."' gespeichert, wird jetzt immer darauf zurückgesetzt."
  else
    return "Bildpfad ist bereits eingespeichert."
  end
end

local function delete_chatphoto(msg)
  local hash = get_redis_hash(msg, 'data')
  local saved_path = redis:hget(hash, 'chat_photo')
  if saved_path then
    print('Deleting chat photo path '..saved_path..' from redis hash '..hash)
    redis:hdel(hash, 'chat_photo')
    return "Bildpfad gelöscht, wird jetzt nicht mehr darauf zurückgesetzt."
  else
    return "Bildpfad wurde noch nicht eingespeichert."
  end
end

function run(msg, matches)
  if msg.to.type ~= 'chat' then
    return 'Dieses Plugin kannst du nur in Chats nutzen!'
  end
  
  if matches[1] == "rename" and matches[2] then
	local new_chat_name = matches[2]
	return ren_chat(msg, new_chat_name)
  elseif matches[1] == "setname" then
	return save_chatname(msg)
  elseif matches[1] == "delname" then
	return delete_chatname(msg)
  elseif matches[1] == "setphoto" and matches[2] then
    local path = matches[2]
    return save_chatphoto(msg, path)
  elseif matches[1] == "delphoto" then
    return delete_chatphoto(msg)
  end
end

return {
  description = "Benennt Gruppe um und setzt Namen und Foto (nur Superuser)",
  usage = {
    "!rename [Name]: Benennt Gruppe um",
	"!setname: Setzt Gruppennamen und setzt immer darauf zurück",
	"!delname: Speichert Gruppennamen nicht mehr",
	"!setphoto (Pfad/zu/bild.jpg): Speichert Gruppenfoto und setzt es immer darauf zurück",
	"!delphoto: Speichert Gruppenfoto nicht mehr"
  },
  patterns = {
    "^!(rename) (.+)$",
	"^!(setname)$",
	"^!(delname)$",
	"^!(setphoto) (.*)$",
	"^!(delphoto)$"
  }, 
  run = run,
  privileged = true
}

end
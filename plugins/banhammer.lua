-- Füge deinen Nutzernamen unten hinzu

local function is_user_whitelisted(id)
  local hash = 'whitelist:user#id'..id
  local white = redis:get(hash) or false
  return white
end

local function is_chat_whitelisted(id)
  local hash = 'whitelist:chat#id'..id
  local white = redis:get(hash) or false
  return white
end

local function kick_user(user_id, chat_id)
  local chat = 'chat#id'..chat_id
  local user = 'user#id'..user_id

  if user_id == tostring(our_id) then
    send_msg(chat, "Ich werde mich nicht selbst kicken!", ok_cb,  true)
  else
    chat_del_user(chat, user, ok_cb, true)
  end
end

local function ban_user(user_id, chat_id)
  local chat = 'chat#id'..chat_id
  if user_id == tostring(our_id) then
    send_msg(chat, "Ich werde mich nicht selbst kicken!", ok_cb,  true)
  else
    -- Save to redis
    local hash =  'banned:'..chat_id..':'..user_id
    redis:set(hash, true)
    -- Kick from chat
    kick_user(user_id, chat_id)
  end
end

local function is_banned(user_id, chat_id)
  local hash =  'banned:'..chat_id..':'..user_id
  local banned = redis:get(hash)
  return banned or false
end

local function makesudo(user_id, msg, delete)
  local set = 'telegram:sudo_users'
  local is_sudo = redis:sismember(set, user_id)
  if delete then
    if not is_sudo then
	  return user_id..' ist kein Superuser.'
	else
	  if string.match(user_id, msg.from.id) then
	    return 'Das Löschen deiner User-ID aus den Superusern wird feige verweigert.'
	  else
	    print('deleting user id '..user_id..' from redis set '..set)
	    redis:srem(set, user_id)
	    sudo_users = load_sudo_users()
	    return user_id..' ist jetzt kein Superuser mehr.'
	  end
	end
  else
	if not is_sudo then
	  print('saving user id '..user_id..' to redis set '..set)
	  redis:sadd(set, user_id)
	  sudo_users = load_sudo_users()
	  return user_id..' ist jetzt ein Superuser.'
	else
	  return user_id..' ist bereits ein Superuser.'
	end
  end
end

local function pre_process(msg)

  -- SERVICE MESSAGE
  if msg.action and msg.action.type then
    local action = msg.action.type
    -- Check if banned user joins chat
    if action == 'chat_add_user' or action == 'chat_add_user_link' then
      local user_id
      if msg.action.link_issuer then
        user_id = msg.from.id
      else
	    user_id = msg.action.user.id
      end
      print('Checking invited user '..user_id)
      local banned = is_banned(user_id, msg.to.id)
      if banned then
        print('User is banned!')
        kick_user(user_id, msg.to.id)
      end
    end
    -- No further checks
    return msg
  end

  -- BANNED USER TALKING
  if msg.to.type == 'chat' then
    local user_id = msg.from.id
    local chat_id = msg.to.id
    local banned = is_banned(user_id, chat_id)
    if banned then
      print('Banned user talking!')
      ban_user(user_id, chat_id)
      msg.text = ''
    end
  end
  
  -- WHITELIST
  local hash = 'whitelist:enabled'
  local whitelist = redis:get(hash)
  local issudo = is_sudo(msg)

  -- Allow all sudo users even if whitelist is allowed
  if whitelist and not issudo then
    print('Whitelist enabled and not sudo')
    -- Check if user or chat is whitelisted
    local allowed = is_user_whitelisted(msg.from.id)
	local has_been_warned = redis:hget('user:'..msg.from.id, 'has_been_warned')

    if not allowed then
      print('User '..msg.from.id..' not whitelisted')
      if msg.to.type == 'chat' then
        allowed = is_chat_whitelisted(msg.to.id)
        if not allowed then
          print ('Chat '..msg.to.id..' not whitelisted')
        else
          print ('Chat '..msg.to.id..' whitelisted :)')
		end
      else
	    if not has_been_warned then
	      local user_name = get_name(msg)
		  local receiver = get_receiver(msg)
		  send_msg(receiver, "Hey "..user_name..", dies ist der Bot von @DEINUSERNAME und kann nur nach Freischaltung durch ihn benutzt werden." , ok_cb, false)
		  redis:hset('user:'..msg.from.id, 'has_been_warned', true)
		else
		  print('User was already warned!')
		end
      end
    else
      print('User '..msg.from.id..' allowed :)')
    end

    if not allowed then
      msg.text = ''
    end

  else 
    print('Whitelist not enabled or is sudo')
  end

  return msg
end

local function run(msg, matches)

  -- Silent ignore
  if not is_sudo(msg) then
    return nil
  end

  if matches[1] == 'ban' then
    local user_id = matches[3]
    local chat_id = msg.to.id

    if msg.to.type == 'chat' then
      if matches[2] == 'user' then
        ban_user(user_id, chat_id)
        return 'User '..user_id..' gebannt'
      end
      if matches[2] == 'delete' then
        local hash =  'banned:'..chat_id..':'..user_id
        redis:del(hash)
        return 'User '..user_id..' ist nicht mehr gebannt'
      end
    else
      return 'Das ist keine Chat-Gruppe'
    end
  end
  
  if matches[1] == 'makesudo' then
    local user_id = matches[3]
	if matches[2] == 'user' then
	  return makesudo(user_id)
	end
	if matches[2] == 'delete' then
	  return makesudo(user_id, msg, true)
	end
  end

  if matches[1] == 'kick' then
    if msg.to.type == 'chat' then
      kick_user(matches[2], msg.to.id)
    else
      return 'Das ist keine Chat-Gruppe'
    end
  end

  if matches[1] == 'whitelist' then
    if matches[2] == 'enable' then
      local hash = 'whitelist:enabled'
      redis:set(hash, true)
      return 'Whitelist aktiviert'
    end

    if matches[2] == 'disable' then
      local hash = 'whitelist:enabled'
      redis:del(hash)
      return 'Whitelist deaktiviert'
    end

    if matches[2] == 'user' then
      local hash = 'whitelist:user#id'..matches[3]
      redis:set(hash, true)
      return 'User '..matches[3]..' whitelisted'
    end

    if matches[2] == 'chat' then
      if msg.to.type ~= 'chat' then
        return 'Das ist keine Chat-Gruppe!'
      end
      local hash = 'whitelist:chat#id'..msg.to.id
      redis:set(hash, true)
      return 'Chat '..msg.to.id..' whitelisted'
    end

    if matches[2] == 'delete' and matches[3] == 'user' then
      local hash = 'whitelist:user#id'..matches[4]
      redis:del(hash)
      return 'User '..matches[4]..' von der Whitelist entfernt!'
    end

    if matches[2] == 'delete' and matches[3] == 'chat' then
      if msg.to.type ~= 'chat' then
        return 'Das ist keine Chat-Gruppe!'
      end
      local hash = 'whitelist:chat#id'..msg.to.id
      redis:del(hash)
      return 'Chat '..msg.to.id..' von der Whitelist entfernt'
    end

  end
end

return {
  description = "Banhammer-Plugin für Whitelist, Kicks und Banns (nur Superuser)", 
  usage = {
    "!whitelist <enable>/<disable>: Aktiviert/deaktiviert Whitelist",
    "!whitelist user <user_id>: Whiteliste User",
    "!whitelist chat: Whiteliste ganze Gruppe",
    "!whitelist delete user <user_id>: Lösche User von der Whitelist",
    "!whitelist delete chat: Lösche ganze Gruppe von der Whitelist",
    "!ban user <user_id>: Kicke User vom Chat und kicke ihn, wenn er erneut beitritt",
    "!ban delete <user_id>: Entbanne User",
    "!kick <user_id>: Kicke User vom Chat",
	"!makesudo user <user_id>: Macht User zum Superuser",
	"!makesudo delete <user_id>: Macht User zum Superuser",
  },
  patterns = {
    "^!(whitelist) (enable)$",
    "^!(whitelist) (disable)$",
    "^!(whitelist) (user) (%d+)$",
    "^!(whitelist) (chat)$",
    "^!(whitelist) (delete) (user) (%d+)$",
    "^!(whitelist) (delete) (chat)$",
    "^!(ban) (user) (%d+)$",
    "^!(ban) (delete) (%d+)$",
    "^!(kick) (%d+)$",
    "^!!tgservice (.+)$",
	"^!(makesudo) (user) (%d+)$",
	"^!(makesudo) (delete) (%d+)$"
  }, 
  run = run,
  pre_process = pre_process
}

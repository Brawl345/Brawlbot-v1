-- INFO: Stats must be activated, so that it can collect all members of a group and save his/her id to redis.
-- You can deactivate it afterwards.

-- See https://stackoverflow.com/a/32854917
function isWordFoundInString(word,input)
  return select(2,input:gsub('^' .. word .. '%W+','')) +
         select(2,input:gsub('%W+' .. word .. '$','')) +
         select(2,input:gsub('^' .. word .. '$','')) +
         select(2,input:gsub('%W+' .. word .. '%W+','')) > 0
end


local function pre_process(msg)
  local notify_users = redis:smembers('notify:ls')
  
  -- I call this beautiful lady the "if soup"
  if msg.to.type == 'chat' then
    if msg.text then
      for _,user in pairs(notify_users) do
	    if isWordFoundInString('@'..user, string.lower(msg.text)) then
		  local chat_id = msg.to.id
		  local id = redis:hget('notify:'..user, 'id')
		  -- check, if user has sent at least one message to the group,
		  -- so that we don't send the user some private text, when he/she is not
		  -- in the group.
		  if redis:sismember('chat:'..chat_id..':users', id) then
		  
		    -- ignore message, if user is mentioning him/herself
		    if id == tostring(msg.from.id) then break; end

	        local send_date = run_command('date -d @'..msg.date..' +"%d.%m.%Y um %H:%M:%S Uhr"')
			local send_date = string.gsub(send_date, "\n", "")
		    local from = string.gsub(msg.from.print_name, "%_", " ")
			local chat_name = string.gsub(msg.to.print_name, "%_", " ")
		    local text = from..' am '..send_date..' in "'..chat_name..'":\n\n'..msg.text
	        send_msg('user#id'..id, text, ok_cb, false)
		  end
	    end
	  end
	end
  end

  return msg
end

local function run(msg, matches)
  if not msg.from.username then
    return 'Du hast keinen Usernamen und kannst daher dieses Feature nicht nutzen. Tut mir leid!' 
  end
  
  local username = string.lower(msg.from.username)
  
  local hash = 'notify:'..username
  
  if matches[1] == "del" then
    if not redis:sismember('notify:ls', username) then
	  return 'Du wirst noch gar nicht benachrichtigt!'
	end
    print('Setting notify in redis hash '..hash..' to false')
    redis:hset(hash, 'notify', false)
    print('Removing '..username..' from redis set notify:ls')
    redis:srem('notify:ls', username)
	return 'Du erhälst jetzt keine Benachrichtigungen mehr, wenn du angesprochen wirst.'
  else
    if redis:sismember('notify:ls', username) then
	  return 'Du wirst schon benachrichtigt!'
	end
    print('Setting notify in redis hash '..hash..' to true')
    redis:hset(hash, 'notify', true)
    print('Setting id in redis hash '..hash..' to '..msg.from.id)
    redis:hset(hash, 'id', msg.from.id)
    print('Adding '..username..' to redis set notify:ls')
    redis:sadd('notify:ls', username)
    return 'Du erhälst jetzt Benachrichtigungen, wenn du angesprochen wirst!'
  end
end

return {
  description = "Benachrichtigt User, wenn er/sie erwähnt wird.", 
  usage = {
    "!notify: Benachrichtigt dich privat, wenn du erwähnt wirst",
    "!notify del: Benachrichtigt dich nicht mehr"
  },
  patterns = {
    "^!notify (del)$",
    "^!notify$"
  },
  run = run,
  pre_process = pre_process,
  notyping = true
}

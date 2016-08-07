local function user_print_name(user)
  if user.print_name then
    return user.print_name
  end
  local text = ''
  if user.first_name then
    text = user.last_name..' '
  end
  if user.lastname then
    text = text..user.last_name
  end
  return text
end

local function returnids(cb_extra, success, result)
  local receiver = cb_extra.receiver
  local chat_id = "chat#id"..result.id
  local chatname = result.print_name

  local text = 'IDs für "'..chatname..'"'
  ..' ('..chat_id..')\n'
  ..'Hier sind '..result.members_num..' Mitglieder:'
  ..'\n---------\n'
   for k,v in pairs(result.members) do
     text = text .. v.print_name .. " (user#id" .. v.id .. ")\n"
  end
  local text = string.gsub(text, "%_", " ")
 send_large_msg(receiver, text)
end

local function run(msg, matches)
  local receiver = get_receiver(msg)
  if matches[1] == "!id" then
    local text = string.gsub(user_print_name(msg.from), "%_", " ") .. ' (user#id' .. msg.from.id .. ')'
    if is_chat_msg(msg) then
      text = text .. "\nDu bist in der Gruppe " .. string.gsub(user_print_name(msg.to), "%_", " ") .. " (chat#id" .. msg.to.id  .. ")"
    end
    return text
  elseif matches[1] == "chat" then
    -- !ids? (chat) (%d+)
    if matches[2] and is_sudo(msg) then
      local chat = 'chat#id'..matches[2]
      chat_info(chat, returnids, {receiver=receiver})
    else
      if not is_chat_msg(msg) then
        return "Du bist nicht einer Gruppe."
      end
      local chat = get_receiver(msg)
      chat_info(chat, returnids, {receiver=receiver})
    end
  elseif matches[1] == "member" and matches[2] == "@" then
    local nick = matches[3]
    local chat = get_receiver(msg)
    if not is_chat_msg(msg) then
      return "Du bist nicht in einer Gruppe."
    end
    chat_info(chat, function (extra, success, result)
      local receiver = extra.receiver
      local nick = extra.nick
      local found
      for k,user in pairs(result.members) do
        if user.username == nick then
          found = user
        end
      end
      if not found then
        send_msg(receiver, "User in diesem Chat nicht gefunden.", ok_cb, false)
      else
        local text = "ID: "..found.id
        send_msg(receiver, text, ok_cb, false)
      end
    end, {receiver=chat, nick=nick})
  elseif matches[1] == "members" and matches[2] == "name" then
    local text = matches[3]
    local chat = get_receiver(msg)
    if not is_chat_msg(msg) then
      return "Du bist nicht in einer Gruppe."
    end
    chat_info(chat, function (extra, success, result)
      local members = result.members
      local receiver = extra.receiver
      local text = extra.text

      local founds = {}
      for k,member in pairs(members) do
        local fields = {'first_name', 'print_name', 'username'}
        for k,field in pairs(fields) do
          if member[field] and type(member[field]) == "string" then
            if member[field]:match(text) then
              local id = tostring(member.id)
              founds[id] = member
            end
          end
        end
      end
      if next(founds) == nil then -- Empty table
        send_msg(receiver, "User in diesem Chat nicht gefunden.", ok_cb, false)
      else
        local text = ""
        for k,user in pairs(founds) do
		  if user.first_name then
		    text = text..'Vorname: '..user.first_name..'\n'
		  end
		  
		  if user.print_name then
		    text = text..'Anzeigename: '.. string.gsub(user.print_name, "%_", " ")..'\n'
		  end
		  
		  if user.username then
		    text = text..'Username: '..user.username..'\n'
		  end
		 
		 text = text..'ID: '..user.id..'\n\n'
        end
        send_msg(receiver, text, ok_cb, false)
      end
    end, {receiver=chat, text=text})
  end
end


return {
   description = "Zeige dir IDs und IDs aller Gruppenmitglieder an.",
   usage = {
     "!id: Zeigt deine ID an",
	 "!ids chat: Zeigt IDs im aktuellen Chat an",
	 "!ids (Chat-ID): Zeigt IDs in diesem Chat an",
    "!id member @<username>: Gibt die ID von @<username> im aktuellen Chat aus",
    "!id members name <text>: Suche nach Usern mit <text> in first_name, print_name oder username im aktuellen Chat"
  },
  patterns = {
    "^!id$",
    "^!ids? (chat) (%d+)$",
    "^!ids? (chat)$",
    "^!id (member) (@)(.+)",
    "^!id (members) (name) (.+)"
  },
   run = run
}

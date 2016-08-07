
local function template_add_user(base, to_username, from_username, chat_name, chat_id)
   base = base or ''
   to_username = ' @' .. (to_username or '')
   from_username = '@' .. (from_username or '')
   chat_name = chat_name or ''
   chat_name = string.gsub(chat_name, "_", " ")
   chat_id = "chat#id" .. (chat_id or '')
   if to_username == "@" then
      to_username = ''
   end
   if from_username == "@" then
      from_username = ''
   end
   base = string.gsub(base, "{to_username}", to_username)
   base = string.gsub(base, "{from_username}", from_username)
   base = string.gsub(base, "{chat_name}", chat_name)
   base = string.gsub(base, "{chat_id}", chat_id)
   return base
end

function chat_new_user_link(msg)
   local pattern = cred_data.initial_chat_msg
   local to_username = msg.from.username
   local from_username = (msg.action.link_issuer.username or '') .. ' (durch Link)'
   -- GSUB GROUP NAME
   local chat_name = string.gsub(msg.to.print_name, "_", " ")
   local chat_id = msg.to.id
   pattern = template_add_user(pattern, to_username, from_username, chat_name, chat_id)
   -- {to_username} {from_username} {chat_name} {chat_id} are the available patterns, set with !creds add initial_chat_msg
   if pattern ~= '' then
      local receiver = get_receiver(msg)
      send_msg(receiver, pattern, ok_cb, false)
   end
end

function chat_new_user(msg)
   local pattern = cred_data.initial_chat_msg
   local to_username = msg.action.user.username
   local from_username = msg.from.username
   if msg.action.user.id == our_id then return end
   local chat_name = msg.to.print_name
   local chat_id = msg.to.id
   pattern = template_add_user(pattern, to_username, from_username, chat_name, chat_id)
   -- {to_username} {from_username} {chat_name} {chat_id} are the available patterns, set with !creds add initial_chat_msg
   if pattern ~= '' then
      local receiver = get_receiver(msg)
      send_msg(receiver, pattern, ok_cb, false)
   end
end

function chat_delete_user(msg)
   local pattern = cred_data.leave_chat_msg
   local to_username = msg.action.user.username
   local from_username = msg.from.username
   if to_username == from_username then return nil end
   local chat_name = msg.to.print_name
   local chat_id = msg.to.id
   pattern = template_add_user(pattern, to_username, from_username, chat_name, chat_id)
   -- {to_username} {from_username} {chat_name} {chat_id} are the available patterns, set with !creds add leave_chat_msg
   if pattern ~= '' then
      local receiver = get_receiver(msg)
      send_msg(receiver, pattern, ok_cb, false)
   end
end


local function run(msg, matches)
   if not msg.service then
      return "Versuchst du mich etwa zu trollen?"
   end

   if matches[1] == "chat_add_user" then
      chat_new_user(msg)
   elseif matches[1] == "chat_add_user_link" then
      chat_new_user_link(msg)
   elseif matches[1] == "chat_del_user" then
      chat_delete_user(msg)
   end
end

return {
   description = "Serivce-Plugin: User betritt Chat",
   usage = "User betritt Chat: Bot sendet Willkommensnachricht",
   patterns = {
      "^!!tgservice (chat_add_user)$",
      "^!!tgservice (chat_add_user_link)$",
	  "^!!tgservice (chat_del_user)$"
   },
   run = run,
   notyping = true
}

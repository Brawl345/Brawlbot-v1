
local function chat_reset_name(msg, receiver)
  local hash = get_redis_hash(msg, 'data')
  local saved_name = redis:hget(hash, 'chat_name')
  if saved_name or saved_name ~= "" then
    rename_chat(receiver, saved_name, ok_cb, false)
  end
end

local function chat_reset_photo(msg, receiver)
  local hash = get_redis_hash(msg, 'data')
  local saved_path = redis:hget(hash, 'chat_photo')
  if saved_path or saved_path ~= "" then
    chat_set_photo(receiver, saved_path, ok_cb, false)
  end
end


local function run(msg, matches)
  local receiver = get_receiver(msg)
  -- avoid this plugins to process user messages
  if not msg.service then
    return nil
  end
  print("Service message received: " .. matches[1])
  
  -- do not process service messages produced by the bot, to avoid a loop
  if msg.from.id == 0 then return nil end
  
  if matches[1] == "chat_rename" then
    chat_reset_name(msg, receiver)
  elseif matches[1] == "chat_change_photo" then
    chat_reset_photo(msg, receiver)
  end
end


return {
   description = "Service-Plugin: Chat-Name und Foto",
   usage = "Resettet Chat-Namen und Foto (nur bei bestimmten Gruppen)",
   patterns = {
      "^!!tgservice (chat_rename)$",
	  "^!!tgservice (chat_change_photo)$"
   },
   run = run
}

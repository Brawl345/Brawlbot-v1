
local function run(msg, matches)
  local destination = matches[1]
  local text = matches[2]
  send_large_msg(destination, text)
end

return {
  description = "Sprich mit deinem Bot in Chats (nur Superuser).",
  usage = "!s chat#id[0-9]+ [Nachricht]: Sendet Nachricht an Gruppe",
  patterns = {
    "^!s +(chat#id[0-9]+) +(.+)$"
  }, 
  run = run,
  privileged = true
}

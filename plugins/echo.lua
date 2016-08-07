local function run(msg, matches)
  local text = matches[1]
  local b = 1

  while b ~= 0 do
    text = text:trim()
	text,b = text:gsub('^!+','')
  end
  return text
end

return {
  description = "Gibt die Nachricht aus", 
  usage = "!echo [Nachricht]: Gibt die Nachricht aus",
  patterns = {"^!echo +(.+)$"}, 
  run = run 
}


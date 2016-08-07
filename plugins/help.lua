do

-- Returns true if is not empty
local function has_usage_data(dict)
  if (dict.usage == nil or dict.usage == '') then
    return false
  end
  return true
end

-- Get commands for that plugin
local function plugin_help(name)
  local plugin = plugins[name]
  if not plugin then return 'Dieses Plugin existiert nicht.' end

  local text = plugin.description..'\n'
  if (type(plugin.usage) == "table") then
    for ku,usage in pairs(plugin.usage) do
      text = text..usage..'\n'
    end
    text = text..'\n'
  elseif has_usage_data(plugin) then -- Is not empty
    text = text..plugin.usage..'\n\n'
  else
    text = text..'\n'
  end
  return text
end

-- !help command
local function help_all(msg)
  local ret = ""
  for name in pairs(plugins) do
    ret = ret..'Plugin: '..name..'\n'..plugin_help(name)
  end
  local ret = ret..'Schreibe "!hilfe [Pluginname]" für die Hilfe für ein Plugin.'
  if msg.to.type == 'chat' then
    local user_name = get_name(msg)
    send_msg('chat#id' .. msg.to.id, 'Hey '..user_name..', ich hab dir die Hilfe privat gesendet ;)', ok_cb, false)
	send_large_msg('user#id' .. msg.from.id, ret, ok_cb, false)
  else
    return ret
  end
end

local function run(msg, matches)
  if matches[1] == "!hilfe" or matches[1] == "!help" then
    return help_all(msg)
  else 
    local text = plugin_help(matches[1])
    return text
  end
end

return {
  description = "Hilfe-Plugin", 
  usage = {
    "!hilfe: Zeige Hilfen für alle Plugins.",
    "!hilfe [Pluginname]: Zeige Hilfe für das ausgewählte Plugin."
  },
  patterns = {
    "^!hilfe$",
    "^!hilfe (.+)",
    "^!help$",
    "^!help (.+)"
  }, 
  run = run 
}

end

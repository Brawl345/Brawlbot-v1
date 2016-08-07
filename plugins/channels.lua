-- Checks if bot was disabled on specific chat
local function is_channel_disabled(msg)
  local hash = 'chat:'..msg.to.id..':disabled'
  local disabled = redis:get(hash)
  
	if not disabled or disabled == "false" then
		return false
	end

  return disabled
end

local function enable_channel(msg)
  local hash = 'chat:'..msg.to.id..':disabled'
  local disabled = redis:get(hash)
  if disabled then
    print('Setting redis variable '..hash..' to false')
    redis:set(hash, false)
    return 'Channel aktiviert'
  else
    return 'Channel ist nicht deaktiviert!'
  end
end

local function disable_channel(msg)
  local hash = 'chat:'..msg.to.id..':disabled'
  local disabled = redis:get(hash)
  if disabled ~= "true" then
    print('Setting redis variable '..hash..' to true')
    redis:set(hash, true)
    return 'Channel deaktiviert'
  else
    return 'Channel ist bereits deaktiviert!'
  end
end

local function pre_process(msg)
	
	-- If is sudo can reeanble the channel
	if is_sudo(msg) then
	  if msg.text == "!channel enable" then
	    enable_channel(msg)
	  end
	end

  if is_channel_disabled(msg) then
    print('Channel wurde deaktiviert')
  	msg.text = ""
  end

	return msg
end

local function run(msg, matches)
	-- Enable a channel
	if matches[1] == 'enable' then
		return enable_channel(msg)
	end
	-- Disable a channel
	if matches[1] == 'disable' then
		return disable_channel(msg)
	end
end

return {
  description = "(De)aktiviert den Bot im Chat (nur Superuser).", 
  usage = {
	"!channel enable: Aktiviert den Bot im Chat",
	"!channel disable: Deaktiviert den Bot im Chat"
  },
  patterns = {
	"^!channel? (enable)",
	"^!channel? (disable)"
  }, 
  run = run,
  privileged = true,
  pre_process = pre_process
}
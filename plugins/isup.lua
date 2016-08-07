do

local function prot_url(url)
   local url, h = string.gsub(url, "http://", "")
   local url, hs = string.gsub(url, "https://", "")
   local protocol = "http"
   if hs == 1 then
      protocol = "https"
   end
   return url, protocol
end

local function get_base_redis(id, option, extra)
   local ex = ''
   if option ~= nil then
      ex = ex .. ':' .. option
      if extra ~= nil then
         ex = ex .. ':' .. extra
      end
   end
   return 'isup:' .. id .. ex
end

local function print_cron(id)
   local uhash = get_base_redis(id)
   local subs = redis:smembers(uhash)
   local text = id .. ' prüft folgende Webseiten:\n---------\n'
   for k,v in pairs(subs) do
      text = text .. k .. ") " .. v .. '\n'
   end
   return text
end

local function save_cron(id, url)
  local url = string.lower(url)
  local baseurl, protocol = prot_url(url)
  local prothash = get_base_redis(baseurl, "protocol")
  local checkhash = get_base_redis(baseurl, "check")
  local uhash = get_base_redis(id)
  
   if redis:sismember(uhash, baseurl) then
      return url..' wird bereits geprüft.'
   end
   
   print('Saving...')
   redis:set(prothash, protocol)
   redis:sadd(checkhash, id)
   redis:sadd(uhash, baseurl)
  return url.." wird jetzt alle fünf Minuten geprüft!"
end

local function delete_cron(id, n)
   n = tonumber(n)

   local uhash = get_base_redis(id)
   local subs = redis:smembers(uhash)
   if n < 1 or n > #subs then
      return "ID zu hoch!"
   end
   local sub = subs[n]
   local lhash = get_base_redis(sub, "check")

   redis:srem(uhash, sub)
   redis:srem(lhash, id)

   local left = redis:smembers(lhash)
   if #left < 1 then -- no one subscribed, remove it
      local prothash = get_base_redis(sub, "protocol")
	  local downhash = get_base_redis(sub, "down")
      redis:del(prothash)
	  redis:del(downhash)
   end

   return sub.." wird nicht mehr geprüft."
end
  
local function is_up_socket(ip, port)
  print('Connect to', ip, port)
  local c = socket.try(socket.tcp())
  c:settimeout(3)
  local conn = c:connect(ip, port)
  if not conn then
    return false
  else
    c:close()
    return true
  end
end

local function is_up_http(url)
  -- Parse URL from input, default to http
  local parsed_url = URL.parse(url,  { scheme = 'http', authority = '' })
  -- Fix URLs without subdomain not parsed properly
  if not parsed_url.host and parsed_url.path then
    parsed_url.host = parsed_url.path
    parsed_url.path = ""
  end
  -- Re-build URL
  local url = URL.build(parsed_url)

  local protocols = {
    ["https"] = https,
    ["http"] = http
  }
  local options =  {
    url = url,
    redirect = false,
    method = "GET"
  }
  local response = { protocols[parsed_url.scheme].request(options) }
  local code = tonumber(response[2])
  if code == nil or code >= 400 then
    return false
  end
  return true
end

local function isup(url)
  local pattern = '^(%d%d?%d?%.%d%d?%d?%.%d%d?%d?%.%d%d?%d?):?(%d?%d?%d?%d?%d?)$'
  local ip,port = string.match(url, pattern)
  local result = nil

  -- !isup 8.8.8.8:53
  if ip then
    port = port or '80'
    result = is_up_socket(ip, port)
  else
    result = is_up_http(url)
  end
  return result
end

local function cron()
  local keys = redis:keys(get_base_redis("*", "check"))
  for k,v in pairs(keys) do
    local base = string.match(v, "isup:(.+):check")  -- Get the URL base

	print('ISUP: '..base)
	local prot = redis:get(get_base_redis(base, "protocol"))
	local url = prot .. "://" .. base
	local hash = 'isup:'..base..':down'
	local isdown = redis:get(hash)
	if not isup(url) then
	  if isdown ~= 'true' then
	    redis:set(hash, 'true')
	    local text = url..' ist DOWN! ❌'
          for e, receiver in pairs(redis:smembers(v)) do
            send_msg(receiver, text, ok_cb, false)
          end
	  else
	    print(base..' ist immer noch down')
	  end
    else
	  if isdown == 'true' then
	    redis:set(hash, 'false')
		local text = url..' ist wieder UP! ✅'
        for e, receiver in pairs(redis:smembers(v)) do
          send_msg(receiver, text, ok_cb, false)
        end
	  end
    end
  end
end

local function run(msg, matches)
   local id = "user#id" .. msg.from.id

   if is_chat_msg(msg) then
      id = "chat#id" .. msg.to.id
   end

   
  if matches[1] == 'cron show' then
    if not is_sudo(msg) then 
      return 'Du bist kein Superuser. Dieser Vorfall wird gemeldet.'
    end
    return print_cron(id)
	
  elseif matches[1] == 'cron check' then
    if not is_sudo(msg) then 
      return 'Du bist kein Superuser. Dieser Vorfall wird gemeldet.'
    end
    return cron()
	
  elseif matches[1] == 'cron delete' then
    if not is_sudo(msg) then 
      return 'Du bist kein Superuser. Dieser Vorfall wird gemeldet.'
    end
    return delete_cron(id, matches[2])

  elseif matches[1] == 'cron' then
    if not is_sudo(msg) then 
      return 'Du bist kein Superuser. Dieser Vorfall wird gemeldet.'
    end
    return save_cron(id, matches[2])

  elseif isup(matches[1]) then
    return matches[1]..' ist UP! ✅'
  else
    return matches[1]..' ist DOWN! ❌'
  end
end

return {
  description = "Checkt, ob eine Webseite up ist.",
  usage = {
    "!isup [Host]: Checkt, ob die Seite up ist",
    "!isup cron [Host]: Checkt diese Seite alle 5 Minuten (nur Superuser)",
	"!isup cron check: Prüfe alle Seiten jetzt",
	"!isup cron show: Listet alle zu prüfenden Seiten auf",
    "!isup cron delete [ID]: Checkt diese Seite nicht mehr"
  },
  patterns = {
    "^!isup (cron check)$",
    "^!isup (cron show)$",
    "^!isup (cron delete) (%d+)$",
    "^!isup (cron) (.*)$",
    "^!isup (.*)$",
    "^!ping (.*)$"
  },
  run = run,
  cron = cron
}

end

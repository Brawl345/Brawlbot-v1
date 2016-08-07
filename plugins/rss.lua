feedparser = require("feedparser")
 
 
local function tail(n, k)
  local u, r=''
  for i=1,k do
    n,r = math.floor(n/0x40), n%0x40
    u = string.char(r+0x80) .. u
  end
  return u, n
end
 
local function to_utf8(a)
  local n, r, u = tonumber(a)
  if n<0x80 then                        -- 1 byte
    return string.char(n)
  elseif n<0x800 then                   -- 2 byte
    u, n = tail(n, 1)
    return string.char(n+0xc0) .. u
  elseif n<0x10000 then                 -- 3 byte
    u, n = tail(n, 2)
    return string.char(n+0xe0) .. u
  elseif n<0x200000 then                -- 4 byte
    u, n = tail(n, 3)
    return string.char(n+0xf0) .. u
  elseif n<0x4000000 then               -- 5 byte
    u, n = tail(n, 4)
    return string.char(n+0xf8) .. u
  else                                  -- 6 byte
    u, n = tail(n, 5)
    return string.char(n+0xfc) .. u
  end
end

local function unescape_for_rss(str)
  str = string.gsub( str, '&lt;', '<' )
  str = string.gsub( str, '&gt;', '>' )
  str = string.gsub( str, '&quot;', '"' )
  str = string.gsub( str, '&apos;', "'" )
  str = string.gsub( str, "&Auml;", "Ä")
  str = string.gsub( str, "&auml;", "ä")
  str = string.gsub( str, "&Ouml;", "Ö")
  str = string.gsub( str, "&ouml;", "ö")
  str = string.gsub( str, "Uuml;", "Ü")
  str = string.gsub( str, "&uuml;", "ü")
  str = string.gsub( str, "&szlig;", "ß")
  str = string.gsub(str, '&#(%d+);', to_utf8)
  str = string.gsub( str, '&#x(%d+);', function(n) return string.char(tonumber(n,16)) end )
  str = string.gsub( str, '&amp;', '&' ) -- Be sure to do this after all others
  return str
end


local function get_base_redis(id, option, extra)
   local ex = ''
   if option ~= nil then
      ex = ex .. ':' .. option
      if extra ~= nil then
         ex = ex .. ':' .. extra
      end
   end
   return 'rss:' .. id .. ex
end

local function prot_url(url)
   local url, h = string.gsub(url, "http://", "")
   local url, hs = string.gsub(url, "https://", "")
   local protocol = "http"
   if hs == 1 then
      protocol = "https"
   end
   return url, protocol
end

local function get_rss(url, prot)
   local res, code = nil, 0
   if prot == "http" then
      res, code = http.request(url)
   elseif prot == "https" then
      res, code = https.request(url)
   end
   if code ~= 200 then
      return nil, "Fehler beim Erreichen von " .. url
   end
   local parsed = feedparser.parse(res)
   if parsed == nil then
      return nil, "Fehler beim Dekodieren des Feeds.\nBist du sicher, dass "..url.." ein Feed ist?"
   end
   return parsed, nil
end

local function get_new_entries(last, nentries)
   local entries = {}
   for k,v in pairs(nentries) do
      if v.id == last then
         return entries
      else
         table.insert(entries, v)
      end
   end
   return entries
end

local function print_subs(id, chat_name)
   local uhash = get_base_redis(id)
   local subs = redis:smembers(uhash)
   local text = '"'..chat_name..'" hat abonniert:\n---------\n'
   for k,v in pairs(subs) do
      text = text .. k .. ") " .. v .. '\n'
   end
   return text
end

local function subscribe(id, url)
   local baseurl, protocol = prot_url(url)

   local prothash = get_base_redis(baseurl, "protocol")
   local lasthash = get_base_redis(baseurl, "last_entry")
   local lhash = get_base_redis(baseurl, "subs")
   local uhash = get_base_redis(id)

   if redis:sismember(uhash, baseurl) then
      return "Du hast "..url.." bereits abonniert."
   end

   local parsed, err = get_rss(url, protocol)
   if err ~= nil then
      return err
   end

   local last_entry = ""
   if #parsed.entries > 0 then
      last_entry = parsed.entries[1].id
   end

   local name = parsed.feed.title

   redis:set(prothash, protocol)
   redis:set(lasthash, last_entry)
   redis:sadd(lhash, id)
   redis:sadd(uhash, baseurl)

   return "Du hast "..name.." abonniert!"
end

local function unsubscribe(id, n)
   if #n > 3 then
      return "Du kannst nicht mehr als drei Feeds abonnieren!"
   end
   n = tonumber(n)

   local uhash = get_base_redis(id)
   local subs = redis:smembers(uhash)
   if n < 1 or n > #subs then
      return "Abonnement-ID zu hoch!"
   end
   local sub = subs[n]
   local lhash = get_base_redis(sub, "subs")

   redis:srem(uhash, sub)
   redis:srem(lhash, id)

   local left = redis:smembers(lhash)
   if #left < 1 then -- no one subscribed, remove it
      local prothash = get_base_redis(sub, "protocol")
      local lasthash = get_base_redis(sub, "last_entry")
      redis:del(prothash)
      redis:del(lasthash)
   end

   return "Du hast "..sub.." deabonniert."
end

local function cron()
   -- sync every 15 mins?
   local keys = redis:keys(get_base_redis("*", "subs"))
   for k,v in pairs(keys) do
      local base = string.match(v, "rss:(.+):subs")  -- Get the URL base
	  print('RSS: '..base)
      local prot = redis:get(get_base_redis(base, "protocol"))
      local last = redis:get(get_base_redis(base, "last_entry"))
      local url = prot .. "://" .. base
      local parsed, err = get_rss(url, prot)
      if err ~= nil then
         return
      end
      local newentr = get_new_entries(last, parsed.entries)
      local subscribers = {}
      local text = ''  -- Send one message per feed with the latest entries
      for k2, v2 in pairs(newentr) do
         local title = v2.title or 'Kein Titel'
         local link = v2.link or v2.id or 'Kein Link'
		 if v2.content then 
		   if string.len(v2.content) > 250 then
		     content = string.sub(unescape_for_rss(v2.content:gsub("%b<>", "")), 1, 250) .. '...'
		   else
		     content = unescape_for_rss(v2.content:gsub("%b<>", ""))
		  end
		 elseif v2.summary then
		   if string.len(v2.summary) > 250 then
		     content = string.sub(unescape_for_rss(v2.summary:gsub("%b<>", "")), 1, 250) .. '...'
		   else
		     content = unescape_for_rss(v2.summary:gsub("%b<>", ""))
		   end
		 else
		   content = ''
		 end
		 text = text..'\n'..title..'\n'..content..'\n\n — '..link..'\n'
      end
      if text ~= '' then
         local newlast = newentr[1].id
         redis:set(get_base_redis(base, "last_entry"), newlast)
         for k2, receiver in pairs(redis:smembers(v)) do
            send_large_msg(receiver, text, ok_cb, false)
         end
      end
   end
end

local function run(msg, matches)
   local id = "user#id" .. msg.from.id

   if is_chat_msg(msg) then
      id = "chat#id" .. msg.to.id
   end

   if matches[1] == "!rss" then
     local chat_name = string.gsub(msg.to.print_name, "%_", " ")
     return print_subs(id, chat_name)
   end
   
   if matches[1] == "sync" then
      if not is_sudo(msg) then
         return "Nur Superuser können die Feeds neu syncen."
      end
      cron()
   end
   
   if matches[1] == "subscribe" or matches[1] == "sub" then
      if not is_sudo(msg) then
         return "Nur Superuser können Feeds hinzufügen."
      else
        return subscribe(id, matches[2])
	  end
   end

   if matches[1] == "unsubscribe" or matches[1] == "uns" then
      if not is_sudo(msg) then
         return "Nur Superuser können Feeds deabonnieren."
      else
        return unsubscribe(id, matches[2])
	  end
   end
end


return {
   description = "RSS-Reader",
   usage = {
      "!rss: Feed-Abonnements anzeigen",
      "!rss subscribe (url): Diesen Feed abonnieren",
      "!rss unsubscribe (id): Diesen Feed deabonnieren",
      "!rss sync: Synce Feeds (nur Superuser)"
   },
   patterns = {
      "^!rss$",
      "^!rss (subscribe) (https?://[%w-_%.%?%.:/%+=&%~]+)$",
      "^!rss (sub) (https?://[%w-_%.%?%.:/%+=&%~]+)$",
      "^!rss (unsubscribe) (%d+)$",
      "^!rss (uns) (%d+)$",
      "^!rss (sync)$"
   },
   run = run,
   cron = cron
}

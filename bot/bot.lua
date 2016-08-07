require("./bot/utils")

VERSION = '06.2016'

-- This function is called when tg receive a msg
function on_msg_receive (msg)

  if not started then
    return
  end

  local receiver = get_receiver(msg)
  
  -- vardump(msg)
  msg = pre_process_service_msg(msg)
  if msg_valid(msg) then
    msg = pre_process_msg(msg)
  if msg then
    match_plugins(msg)
    -- mark_read(receiver, ok_cb, false)
    end
  end
end

function ok_cb(extra, success, result)
end

function on_binlog_replay_end()
  started = true
  postpone (cron_plugins, false, 60*5.0)
  -- See plugins/isup.lua as an example for cron

  -- load sudo_users and credentials
  sudo_users = load_sudo_users()
  cred_data = load_cred()
   
  -- load plugins
  plugins = {}
  load_plugins()
end

function msg_valid(msg)
  -- Dont process outgoing messages
  if msg.out then
    print('\27[36mNot valid: msg from us\27[39m')
    return false
  end
  
   -- Before bot was started
  if msg.date < now then
    print('\27[36mNot valid: old msg\27[39m')
	return false
  end

  if not msg.to.id then
    print('\27[36mNot valid: To id not provided\27[39m')
    return false
  end

  if not msg.from.id then
    print('\27[36mNot valid: From id not provided\27[39m')
    return false
  end
  
  if msg.unread == 0 then
    print('\27[36mNot valid: read\27[39m')
    return false
  end 
  
  if msg.from.id == our_id then
    print('\27[36mNot valid: Msg from our id\27[39m')
    return false
  end

  if msg.to.type == 'encr_chat' then
    print('\27[36mNot valid: Encrypted chat\27[39m')
    return false
  end
  
  if msg.from.id == 777000 then
    print('Telegram notification, posting to all sudoers...')
    for _,user in pairs(sudo_users) do
      send_large_msg('user#id'..user, msg.text, ok_cb, false)
    end
    return false
  end
  
  return true
end

function pre_process_service_msg(msg)
   if msg.service then
      local action = msg.action or {type=""}
      -- Double ! to discriminate of normal actions
      msg.text = "!!tgservice " .. action.type

      -- wipe the data to allow the bot to read service messages
      if msg.out then
         msg.out = false
      end
      if msg.from.id == our_id then
         msg.from.id = 0
      end
   end
   return msg
end


-- Apply plugin.pre_process function
function pre_process_msg(msg)
  for name,plugin in orderedPairs(plugins) do
    if plugin.pre_process and msg then
	  print('Preprocess', name)
	  msg = plugin.pre_process(msg)
    end
  end

  return msg
end

-- Go over enabled plugins patterns.
function match_plugins(msg)
  for name, plugin in pairs(plugins) do
    match_plugin(plugin, name, msg)
  end
end

-- Check if plugin is deactivated in this chat
local function is_plugin_disabled_on_chat(plugin_name, msg)
  local hash = get_redis_hash(msg, 'disabled_plugins')
  local disabled = redis:hget(hash, plugin_name)
  
  -- Plugin is disabled
  if disabled == 'true' then
    print('Plugin '..plugin_name..' ist in diesem Chat deaktiviert')
	return true
  else
    return false
  end
end

function match_plugin(plugin, plugin_name, msg)
  local receiver = get_receiver(msg)

  -- Go over patterns. If one matches is enough.
  for k, pattern in pairs(plugin.patterns) do
    local matches = match_pattern(pattern, msg.text)
    -- local matches = match_pattern(pattern, msg.text, true)
    if matches then
      print("msg matches: ", pattern)
	  
	  if is_plugin_disabled_on_chat(plugin_name, msg) then
        return nil
	  end
      -- Function exists
      if plugin.run then
	    if not plugin.notyping then send_typing(receiver, ok_cb, true) end
        if not warns_user_not_allowed(plugin, msg) then
          local result = plugin.run(msg, matches)
          if result then
			send_large_msg(receiver, result)
          end
        end
      end
      -- One pattern matches
      return
    end
  end
end

-- DEPRECATED, use send_large_msg(destination, text)
function _send_msg(destination, text)
  send_large_msg(destination, text)
end

-- Load superusers from redis
function load_sudo_users()
  if redis:exists("telegram:sudo_users") == false then
  -- If sudo_users set doesnt exists
    print ("Created new sudo_users set: telegram:sudo_users")
    create_sudo_users()
  end
  local sudo_users = redis:smembers("telegram:sudo_users")
  for v,user in pairs(sudo_users) do
    print("Superuser: " .. user)
  end
  return sudo_users
end

-- Load credentials from redis
function load_cred()
  if redis:exists("telegram:credentials") == false then
  -- If credentials hash doesnt exists
    print ("Created new credentials hash: telegram:credentials")
    create_cred()
  end
  return redis:hgetall("telegram:credentials")
end

-- create credentials hash with redis
function create_cred()
  cred = {
  bitly_access_token = "",
  cloudinary_apikey = "",
  cloudinary_api_secret = "",
  cloudinary_public_id = "",
  derpibooru_apikey = "",
  fb_access_token = "",
  flickr_apikey = "",
  ftp_site = "",
  ftp_username = "",
  ftp_password = "",
  gender_apikey = "",
  golem_apikey = "",
  google_apikey = "",
  google_cse_id = "",
  gitlab_private_token = "",
  gitlab_project_id = "",
  instagram_access_token = "",
  lyricsnmusic_apikey = "",
  mal_username = "",
  mal_pw = "",
  neutrino_userid = "",
  neutrino_apikey = "",
  owm_apikey = "",
  page2images_restkey = "",
  soundcloud_client_id = "",
  tw_consumer_key = "",
  tw_consumer_secret = "",
  tw_access_token = "",
  tw_access_token_secret = "",
  x_mashape_key = "",
  yandex_translate_apikey = "",
  yandex_rich_content_apikey = "",
  yourls_site_url = "",
  yourls_signature_token = ""
  }
  redis:hmset("telegram:credentials", cred)
  print ('saved credentials into reds hash telegram:credentials')
end

function create_sudo_users()
  redis:sadd("telegram:sudo_users", '0')
  redis:sadd("telegram:sudo_users", '1')
  redis:sadd("telegram:sudo_users", our_id)
  print('saved sudo_users into reds set telegram:sudo_users')
  print('please add yourself with redis: SADD telegram:sudo_users YOURID')
end

-- create plugin set if it doesn't exist
function create_plugin_set()
  enabled_plugins = {
    "9gag",
	"aktien",
	"app_store",
	"banhammer",
	"btc",
	"calculator",
	"cat",
    "channels",
	"cleverbot",
	"credentials_manager",
	"dailymotion",
	"date",
	"deviantart",
	"dns",
	"dropbox",
	"echo",
    "eur",
	"expand",
	"forecast",
	"games",
    "get",
	"gfycat",
    "giphy",
	"github",
    "google",
    "gps",
	"hackernews",
	"hastebin",
	"hello",
    "help",
	"id",
    "images",
	"imdb",
    "img_google",
	"ip_info",
	"isup",
    "location",
	"lyrics",
	"magische_miesmuschel",
    "media",
	"miiverse",
	"minecraft",
	"minecraft_skin",
	"mkw-wiimmfi",
	"music163",
	"notiz_an_mich",
    "plugins",
	"qr",
	"quotes",
	"random",
	"reddit",
	"roll",
	"rss",
	"search_youtube",
    "set",
    "stats",
	"steam",
	"surrogate",
	"tex",
    "time",
	"translate",
	"tts",
	"tweet",
	"urban_dictionary",
	"url_title",
    "version",
	"vimeo",
	"vine",
	"weather",
	"webshot",
	"wiimmfi",
	"wiki",
    "xkcd",
    "youtube",
	"yt_mp3"
  }
  print ('enabling a few plugins - saving to redis set telegram:enabled_plugins')
  for _,plugin in pairs(enabled_plugins) do
    redis:sadd("telegram:enabled_plugins", plugin)
  end
end

function on_our_id (id)
  our_id = id
end

function on_user_update (user, what)
  --vardump (user)
end

function on_chat_update (chat, what)
  --vardump (chat)
end

function on_secret_chat_update (schat, what)
  --vardump (schat)
end

function on_get_difference_end ()
end

-- Enable plugins in Redis
function load_plugins()
  enabled_plugins = redis:smembers('telegram:enabled_plugins')
  if not enabled_plugins[1] then
    create_plugin_set()
  end
  for k, v in pairs(enabled_plugins) do
    print("Lade Plugin", v)

    local ok, err =  pcall(function()
      local t = loadfile("plugins/"..v..'.lua')()
      plugins[v] = t
    end)

    if not ok then
      print('\27[31mFehler beim Laden vom Plugin '..v..'\27[39m')
      print('\27[31m'..err..'\27[39m')
    end

  end
end

-- Call and postpone execution for cron plugins
function cron_plugins()

  for name, plugin in pairs(plugins) do
    -- Only plugins with cron function
    if plugin.cron ~= nil then
      plugin.cron()
    end
  end

  -- Called again in 5 mins
  postpone (cron_plugins, false, 5*60.0)
end

-- Start and load values
our_id = 0
now = os.time()
math.randomseed(now)

started = false

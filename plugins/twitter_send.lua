local OAuth = require "OAuth"

local consumer_key = cred_data.tw_consumer_key
local consumer_secret = cred_data.tw_consumer_secret

local function can_send_tweet(msg)
  local hash = 'user:'..msg.from.id
  local var = redis:hget(hash, 'can_send_tweet')
  if var == "true" then
    return true
  else
    return false
  end
end

local client = OAuth.new(consumer_key, consumer_secret, {
    RequestToken = "https://api.twitter.com/oauth/request_token", 
    AuthorizeUser = {"https://api.twitter.com/oauth/authorize", method = "GET"},
    AccessToken = "https://api.twitter.com/oauth/access_token"
}) 

local function do_twitter_authorization_flow(hash, is_chat)
  local callback_url = "oob"
  local values = client:RequestToken({ oauth_callback = callback_url })
  local oauth_token = values.oauth_token
  local oauth_token_secret = values.oauth_token_secret
  
  -- save temporary oauth keys
  redis:hset(hash, 'oauth_token', oauth_token)
  redis:hset(hash, 'oauth_token_secret', oauth_token_secret)
  
  local auth_url = client:BuildAuthorizationUrl({ oauth_callback = callback_url, force_login = true })

  if is_chat then
    return 'Bitte rufe die folgende URL auf:\n'..auth_url..'\nund übergebe mir die PIN IM CHAT VON GERADE mit\n!tw auth PIN'
  else
    return 'Bitte rufe die folgende URL auf:\n'..auth_url..'\nund übergebe mir die PIN mit\n!tw auth PIN'
  end
end

local function get_twitter_access_token(hash, oauth_verifier, oauth_token, oauth_token_secret)
  local oauth_verifier = tostring(oauth_verifier)       -- must be a string

  -- now we'll use the tokens we got in the RequestToken call, plus our PIN
  local client = OAuth.new(consumer_key, consumer_secret, {
	RequestToken = "https://api.twitter.com/oauth/request_token", 
    AuthorizeUser = {"https://api.twitter.com/oauth/authorize", method = "GET"},
    AccessToken = "https://api.twitter.com/oauth/access_token"
  }, {
    OAuthToken = oauth_token,
    OAuthVerifier = oauth_verifier
  })
  client:SetTokenSecret(oauth_token_secret)

  local values, err, headers, status, body = client:GetAccessToken()
  if err then return 'Einloggen fehlgeschlagen!' end

  -- save permanent oauth keys
  redis:hset(hash, 'oauth_token', values.oauth_token)
  redis:hset(hash, 'oauth_token_secret', values.oauth_token_secret)
  
  return 'Erfolgreich eingeloggt als "@'..values.screen_name..'" (User-ID: '..values.user_id..')'
end

local function reset_twitter_auth(hash, frominvalid)
  redis:hdel(hash, 'oauth_token')
  redis:hdel(hash, 'oauth_token_secret')
  if frominvalid then
    return 'Authentifizierung nicht erfolgreich, wird zurückgesetzt...'
  else
    return 'Erfolgreich abgemeldet! Entziehe den Zugriff endgültig auf https://twitter.com/settings/applications'
  end
end

local function resolve_url(url)
  local response_body = {}
  local request_constructor = {
    url = url,
    method = "HEAD",
    sink = ltn12.sink.table(response_body),
    headers = {},
    redirect = false
  }

  local ok, response_code, response_headers, response_status_line = http.request(request_constructor)
  if ok and response_headers.location then
    return response_headers.location
  else
    return url
  end
end

local function twitter_verify_credentials(receiver, oauth_token, oauth_token_secret)
  local client = OAuth.new(consumer_key, consumer_secret, {
    RequestToken = "https://api.twitter.com/oauth/request_token", 
    AuthorizeUser = {"https://api.twitter.com/oauth/authorize", method = "GET"},
    AccessToken = "https://api.twitter.com/oauth/access_token"
  }, {
    OAuthToken = oauth_token,
    OAuthTokenSecret = oauth_token_secret
  })

  local response_code, response_headers, response_status_line, response_body = 
  client:PerformRequest(
    "GET", "https://api.twitter.com/1.1/account/verify_credentials.json", {
      include_entities = false,
	  skip_status = true,
	  include_email = false
    }
  )
  
  local response = json:decode(response_body)
  if response_code == 401 then
    return reset_twitter_auth(hash, true)
  end
  if response_code ~= 200 then
    return 'HTTP-Fehler '..response_code..': '..data.errors[1].message
  end
  
  -- TODO: copied straight from the twitter_user plugin, maybe we can do it better?
  local full_name = response.name
  local user_name = response.screen_name
  if response.verified then
    user_name = user_name..' ✅'
  end
  if response.protected then
    user_name = user_name..' 🔒'
  end
  local header = full_name.. " (@" ..user_name.. ")\n"
  
  local description = unescape(response.description)
  if response.location then
    location = response.location
  else
    location = ''
  end
  if response.url and response.location ~= '' then
    url = ' | '..resolve_url(response.url)..'\n'
  elseif response.url and response.location == '' then
    url = resolve_url(response.url)..'\n'
  else
    url = '\n'
  end
  
  local body = description..'\n'..location..url
  
  local favorites = comma_value(response.favourites_count)
  local follower = comma_value(response.followers_count)
  local following = comma_value(response.friends_count)
  local statuses = comma_value(response.statuses_count)
  local footer = statuses..' Tweets, '..follower..' Follower, '..following..' folge ich, '..favorites..' Tweets favorisiert'
  
  local text = 'Eingeloggter Account:\n'..header..body..footer
  
  local cb_extra = {
    receiver=receiver,
    url=string.gsub(response.profile_image_url_https, "normal", "400x400")
  }
  
  send_msg(receiver, text, send_photo_from_url_callback, cb_extra)
end

local function send_tweet(tweet, oauth_token, oauth_token_secret, hash)
  local client = OAuth.new(consumer_key, consumer_secret, {
    RequestToken = "https://api.twitter.com/oauth/request_token", 
    AuthorizeUser = {"https://api.twitter.com/oauth/authorize", method = "GET"},
    AccessToken = "https://api.twitter.com/oauth/access_token"
  }, {
    OAuthToken = oauth_token,
    OAuthTokenSecret = oauth_token_secret
  })

  local response_code, response_headers, response_status_line, response_body = 
  client:PerformRequest(
    "POST", "https://api.twitter.com/1.1/statuses/update.json", {
      status = tweet
    }
  )
  
  local data = json:decode(response_body)
  if response_code == 401 then
    return reset_twitter_auth(hash, true)
  end
  if response_code ~= 200 then
    return 'HTTP-Fehler '..response_code..': '..data.errors[1].message
  end
  
  local statusnumber = comma_value(data.user.statuses_count)
  local screen_name = data.user.screen_name
  local status_id = data.id_str 

  return 'Tweet #'..statusnumber..' gesendet! Sieh ihn dir an: https://twitter.com/'..screen_name..'/status/'..status_id
end

local function add_to_twitter_whitelist(user_id)
  local hash = 'user:'..user_id
  local whitelisted = redis:hget(hash, 'can_send_tweet')
  if whitelisted ~= 'true' then
    print('Setting can_send_tweet in redis hash '..hash..' to true')
    redis:hset(hash, 'can_send_tweet', true)
    return 'User '..user_id..' kann jetzt Tweets senden!'
  else
    return 'User '..user_id..' kann schon Tweets senden.'
  end
end

local function del_from_twitter_whitelist(user_id)
  local hash = 'user:'..user_id
  local whitelisted = redis:hget(hash, 'can_send_tweet')
  if whitelisted == 'true' then
    print('Setting can_send_tweet in redis hash '..hash..' to false')
    redis:hset(hash, 'can_send_tweet', false)
    return 'User '..user_id..' kann jetzt keine Tweets mehr senden!'
  else
    return 'User '..user_id..' ist nicht whitelisted.'
  end
end

local function run(msg, matches)
  if not consumer_key or consumer_key == '' then
    return "Twitter Consumer Key ist leer, führe !creds add tw_consumer_key [KEY] aus!"
  end
  if not consumer_secret or consumer_secret == '' then
    return "Twitter Consumer Secret ist leer, führe !creds add tw_consumer_secret [KEY] aus!"
  end
  
  if matches[1] == "twwhitelist add" and matches[2] then
    if not is_sudo(msg) then
	  return 'Du bist kein Superuser. Dieser Vorfall wird gemeldet!'
	else
      return add_to_twitter_whitelist(matches[2])
    end
  end

  if matches[1] == "twwhitelist del" and matches[2] then
    if not is_sudo(msg) then
	  return 'Du bist kein Superuser. Dieser Vorfall wird gemeldet!'
	else
      return del_from_twitter_whitelist(matches[2])
    end
  end
  
  local hash = get_redis_hash(msg, 'twitter')
  local oauth_token = redis:hget(hash, 'oauth_token')
  local oauth_token_secret = redis:hget(hash, 'oauth_token_secret')
  
  -- Thanks to the great doc at https://github.com/ignacio/LuaOAuth#a-more-involved-example
  if not oauth_token and not oauth_token_secret then
    if msg.to.type == 'chat' then
      if not is_sudo(msg) then
	    return 'Du bist kein Superuser und es ist noch kein Account gesetzt. Ausführung wird feige verweigert.'
	  else
        local text = do_twitter_authorization_flow(hash, true)
	    send_msg('chat#id' .. msg.to.id, 'Bitte warten, der Administrator meldet sich an...', ok_cb, false)
	    send_msg('user#id' .. msg.from.id, text, ok_cb, false)
	  end
    else
	  return do_twitter_authorization_flow(hash)
	end
  end
  
  if matches[1] == 'auth' and matches[2] then
    if msg.to.type == 'chat' then
      if not is_sudo(msg) then
	    return 'Du bist kein Superuser. Dieser Vorfall wird gemeldet!'
	  end
	end
    if string.len(matches[2]) > 7 then return 'Invalide PIN!' end
    return get_twitter_access_token(hash, matches[2], oauth_token, oauth_token_secret)
  end
  
  if matches[1] == 'unauth' then
    if msg.to.type == 'chat' then
	  if not is_sudo(msg) then
	    return 'Du bist kein Superuser. Dieser Vorfall wird gemeldet!'
	  end
	end
	return reset_twitter_auth(hash)
  end
  
  if matches[1] == 'verify' then
    local receiver = get_receiver(msg)
	return twitter_verify_credentials(receiver, oauth_token, oauth_token_secret)
  end
  
  
  if msg.to.type == 'chat' then
    if not can_send_tweet(msg) then
	  return "Du darfst keine Tweets senden. Entweder wurdest du noch gar nicht freigeschaltet oder ausgeschlossen."
	else
	  return send_tweet(matches[1], oauth_token, oauth_token_secret)
	end
  else
    return send_tweet(matches[1], oauth_token, oauth_token_secret, hash)
  end
  
  if msg.to.type == 'chat' then
    if not can_send_tweet(msg) then
      return "Du darfst keine Tweets senden. Entweder wurdest du noch gar nicht freigeschaltet oder ausgeschlossen."
    else
      return send_tweet(matches[1], oauth_token, oauth_token_secret, hash)
    end
  else
    return 'Bitte benutze dieses Plugin nur in einem Chat!'
  end
end

return {
    description = "Sendet einen Tweet (in Chats: nur freigeschaltete User)", 
    usage = {
	  "!tw [Text]: Sendet einen Tweet an den Account, der im Chat angemeldet ist",
	  "!tw verify: Gibt den angemeldeten User aus, inklusive Profilbild",
	  "!twwitelist add (user): Schaltet User für die Tweet-Funktion frei",
	  "!twwhitelist del (user): Entfernt User von der Tweet-Whitelist",
	  "!tw auth <PIN>: Meldet mit dieser PIN an (Setup)",
	  "!tw unauth: Meldet Twitter-Account ab"
	},
    patterns = {
	  "^!tw (auth) (%d+)",
	  "^!tw (unauth)$",
	  "^!tw (verify)$",
	  "^!tw (.+)",
	  "^!(twwhitelist add) (%d+)",
	  "^!(twwhitelist del) (%d+)"
	}, 
    run = run
}

end

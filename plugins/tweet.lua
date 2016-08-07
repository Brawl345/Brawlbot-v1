
local OAuth = require "OAuth"

local consumer_key = cred_data.tw_consumer_key
local consumer_secret = cred_data.tw_consumer_secret
local access_token = cred_data.tw_access_token
local access_token_secret = cred_data.tw_access_token_secret

local twitter_url = "https://api.twitter.com/1.1/statuses/user_timeline.json"

local client = OAuth.new(consumer_key,
                         consumer_secret,
                         { RequestToken = "https://api.twitter.com/oauth/request_token",
                           AuthorizeUser = {"https://api.twitter.com/oauth/authorize", method = "GET"},
                           AccessToken = "https://api.twitter.com/oauth/access_token"},
                         { OAuthToken = access_token,
                           OAuthTokenSecret = access_token_secret})


local function send_generics_from_url_callback(cb_extra, success, result)
   -- cb_extra is a table containing receiver, urls and remove_path
   local receiver = cb_extra.receiver
   local urls = cb_extra.urls
   local remove_path = cb_extra.remove_path
   local f = cb_extra.func

   -- The previously image to remove
   if remove_path ~= nil then
      os.remove(remove_path)
      print("Deleted: "..remove_path)
   end

   -- Nil or empty, exit case (no more urls)
   if urls == nil or #urls == 0 then
      return false
   end

   -- Take the head and remove from urls table
   local head = table.remove(urls, 1)

   local file_path = download_to_file(head, false)
   local cb_extra = {
      receiver = receiver,
      urls = urls,
      remove_path = file_path,
      func = f
   }

   -- Send first and postpone the others as callback
   f(receiver, file_path, send_generics_from_url_callback, cb_extra)
end

local function send_generics_from_url(f, receiver, urls)
   local cb_extra = {
      receiver = receiver,
      urls = urls,
      remove_path = nil,
      func = f
   }
   send_generics_from_url_callback(cb_extra)
end

local function send_gifs_from_url(receiver, urls)
   send_generics_from_url(send_document, receiver, urls)
end

local function send_videos_from_url(receiver, urls)
   send_generics_from_url(send_video, receiver, urls)
end

local function send_all_files(receiver, urls)
   local data = {
      images = {
         func = send_photos_from_url,
         urls = {}
      },
      gifs = {
         func = send_gifs_from_url,
         urls = {}
      },
      videos = {
         func = send_videos_from_url,
         urls = {}
      }
   }

   local table_to_insert = nil
   for i,url in pairs(urls) do
      local _, _, extension = string.match(url, "(https?)://([^\\]-([^\\%.]+))$")
      local mime_type = mimetype.get_content_type_no_sub(extension)
      if extension == 'gif' then
         table_to_insert = data.gifs.urls
      elseif mime_type == 'image' then
         table_to_insert = data.images.urls
      elseif mime_type == 'video' then
         table_to_insert = data.videos.urls
      else
         table_to_insert = nil
      end
      if table_to_insert then
         table.insert(table_to_insert, url)
      end
   end
   for k, v in pairs(data) do
      if #v.urls > 0 then
      end
      v.func(receiver, v.urls)
   end
end

local function check_keys()
   if consumer_key:isempty() then
      return "Twitter Consumer Key is empty, write it in plugins/twitter.lua"
   end
   if consumer_secret:isempty() then
      return "Twitter Consumer Secret is empty, write it in plugins/twitter.lua"
   end
   if access_token:isempty() then
      return "Twitter Access Token is empty, write it in plugins/twitter.lua"
   end
   if access_token_secret:isempty() then
      return "Twitter Access Token Secret is empty, write it in plugins/twitter.lua"
   end
   return ""
end


local function analyze_tweet(tweet)
   local header = "Tweet von " .. tweet.user.name .. " (@" .. tweet.user.screen_name .. ")\nhttps://twitter.com/statuses/" .. tweet.id_str
   local text = tweet.text

   -- replace short URLs
   if tweet.entities.urls then
      for k, v in pairs(tweet.entities.urls) do
         local short = v.url
         local long = v.expanded_url
         text = text:gsub(short, long)
      end
   end

   -- remove urls
   local urls = {}
   if tweet.extended_entities and tweet.extended_entities.media then
      for k, v in pairs(tweet.extended_entities.media) do
         if v.video_info and v.video_info.variants then  -- If it's a video!
            table.insert(urls, v.video_info.variants[1].url)
         else -- If not, is an image
            table.insert(urls, v.media_url)
         end
         text = text:gsub(v.url, "")  -- Replace the URL in text
		 text = unescape(text)
      end
   end

   return header, text, urls
end


local function sendTweet(receiver, tweet)
   local header, text, urls = analyze_tweet(tweet)
   -- send the parts
   local text = unescape(text)
   send_msg(receiver, header .. "\n" .. text, ok_cb, false)
   send_all_files(receiver, urls)
   return nil
end


local function getTweet(msg, base, all)
   local receiver = get_receiver(msg)

   local response_code, response_headers, response_status_line, response_body = client:PerformRequest("GET", twitter_url, base)

   if response_code ~= 200 then
      return "Konnte nicht verbinden, evtl. existiert der User nicht?"
   end

   local response = json:decode(response_body)
   if #response == 0 then
      return "Konnte keinen Tweet bekommen, sorry"
   end
   if all then
      for i,tweet in pairs(response) do
         sendTweet(receiver, tweet)
      end
   else
      local i = math.random(#response)
      local tweet = response[i]
      sendTweet(receiver, tweet)
   end

   return nil
end

function isint(n)
  return n==math.floor(n)
end

local function run(msg, matches)
   local checked = check_keys()
   if not checked:isempty() then
      return checked
   end

   local base = {include_rts = 1}

   if matches[1] == 'id' then
      local userid = tonumber(matches[2])
      if userid == nil or not isint(userid) then
         return "The id of a user is a number, check this web: http://gettwitterid.com/"
      end
      base.user_id = userid
   elseif matches[1] == 'name' then
      base.screen_name = matches[2]
   else
      return ""
   end

   local count = 200
   local all = false
   if #matches > 2 and matches[3] == 'last' then
      count = 1
      if #matches == 4 then
         local n = tonumber(matches[4])
         if n > 10 then
            return "Du kannst nur 10 Tweets auf einmal abfragen!"
         end
         count = matches[4]
         all = true
      end
   end
   base.count = count

   return getTweet(msg, base, all)
end


return {
   description = "Zufällige Tweets von Usern",
   usage = {
     "!tweet id [id]: Zufälliger Tweet vom User mit dieser ID",
	 "!tweet id [id] last: Aktuellster Tweet vom User mit dieser ID",
	 "!tweet name [Name]: Zufälliger Tweet vom User mit diesem Namen",
	 "!tweet name [Name] last: Aktuellster Tweet vom User mit diesem Namen"
   },
   patterns = {
      "^!tweet (id) ([%w_%.%-]+)$",
      "^!tweet (id) ([%w_%.%-]+) (last)$",
      "^!tweet (id) ([%w_%.%-]+) (last) ([%d]+)$",
      "^!tweet (name) ([%w_%.%-]+)$",
      "^!tweet (name) ([%w_%.%-]+) (last)$",
      "^!tweet (name) ([%w_%.%-]+) (last) ([%d]+)$"
   },
   run = run
}
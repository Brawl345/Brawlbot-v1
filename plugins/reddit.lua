do

local BASE_URL = 'https://www.reddit.com'

function get_reddit_data (subreddit, reddit_code)
  local url = BASE_URL..'/r/'..subreddit..'/comments/'..reddit_code..'.json'
  local res,code  = https.request(url)
  if code ~= 200 then return "HTTP FEHLER" end
  local data = json:decode(res)
  return data
end

function send_reddit_data(data, receiver)
  local title = data[1].data.children[1].data.title
  local author = data[1].data.children[1].data.author
  local subreddit = data[1].data.children[1].data.subreddit
  if string.len(data[1].data.children[1].data.selftext) > 300 then
    selftext = string.sub(unescape(data[1].data.children[1].data.selftext:gsub("%b<>", "")), 1, 300) .. '...'
  else
    selftext = unescape(data[1].data.children[1].data.selftext:gsub("%b<>", ""))
  end
  if not data[1].data.children[1].data.is_self then
    url = data[1].data.children[1].data.url
  else
    url = ''
  end
  local score = comma_value(data[1].data.children[1].data.score)
  local comments = comma_value(data[1].data.children[1].data.num_comments)
  local text = author..' in /r/'..subreddit..' ('..score..' Upvotes - '..comments..' Kommentare):\n'..title..'\n'..selftext..url
  send_msg(receiver, text, ok_cb, false)
end

function run(msg, matches)
  local subreddit = matches[1]
  local reddit_code = matches[2]
  local data = get_reddit_data(subreddit, reddit_code)
  local receiver = get_receiver(msg)
  send_reddit_data(data, receiver)
end

return {
  description = "Gibt Reddit-Post aus.", 
  usage = "URL zu Reddit-Post.",
  patterns = {"reddit.com/r/([A-Za-z0-9-/-_-.]+)/comments/([A-Za-z0-9-/-_-.]+)"},
  run = run 
}

end

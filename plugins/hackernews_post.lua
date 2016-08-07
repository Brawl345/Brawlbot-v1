do

local BASE_URL = 'https://hacker-news.firebaseio.com/v0'

function send_hackernews_post (hn_code)
  local url = BASE_URL..'/item/'..hn_code..'.json'
  local res,code  = https.request(url)
  if code ~= 200 then return "HTTP-FEHLER" end
  local data = json:decode(res)
  
  local by = data.by
  local title = data.title
  
  if data.url then
    url = '\n'..data.url
  else
    url = ''
  end

  if data.text then
    post = '\n'..unescape_html(data.text)
	post = string.gsub(post, '<p>', ' ')
  else
    post = ''
  end
  local text = '"'..title..'" von "'..by..'"'..post..url
  
  return text
end

function run(msg, matches)
  local hn_code = matches[1]
  return send_hackernews_post(hn_code)
end

return {
  description = "Sendet Hackernews-Post", 
  usage = "URL zu Hackernews-Post",
  patterns = {"news.ycombinator.com/item%?id=(%d+)"},
  run = run 
}

end

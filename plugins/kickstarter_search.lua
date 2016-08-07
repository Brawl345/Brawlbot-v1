do

local function search_kicker(tag)
  local url = 'https://www.kickstarter.com/projects/search.json?search=&term='..tag
  local res,code  = https.request(url)
  local data = json:decode(res).projects[1]
  if code ~= 200 then return "HTTP-Fehler" end
  if not data then return "Nichts gefunden!" end
 
  local title = data.name  
  local from = data.creator.name
  local country = data.country
  local desc = data.blurb
  local pledged = comma_value(string.gsub(data.pledged, "%.(.*)", ""))
  local goal = comma_value(data.goal)
  local currency = data.currency_symbol
  local created = run_command('date -d @'..data.launched_at..' +%d.%m.%Y')
  local ending = run_command('date -d @'..data.deadline..' +%d.%m.%Y')
  local url = data.urls.web.project
  if data.photo.full then
    image_url = data.photo.full
  end
  
  local text = title..' von '..from..' ('..country..')\n'..pledged..currency..' von '..goal..currency..' erreicht\n'..'Erstellt am '..created..'Endet am '..ending..'\n'..desc..'\n'..url
 
  if data.photo.full then
    return text, image_url
  else
    return text
  end
end

local function run(msg, matches)
  local tag = matches[1]
  local text, image_url = search_kicker(tag)
  local receiver = get_receiver(msg)
  if image_url then
    local file = download_to_file(image_url)
    send_photo(receiver, file, ok_cb, false)
  end
  return text
end

return {
  description = "Suche für Kickstarter", 
  usage = "!kicks [BEGRIFF]",
  patterns = {
    "^![Kk][Ii][Cc][Kk][Ss] (.*)$",
    "https?://www.kickstarter.com/projects/[a-zA-Z0-9]+/(.*)$"},
  run = run 
}

end
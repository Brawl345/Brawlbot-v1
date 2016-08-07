do

local BASE_URL = 'https://www.omdbapi.com'

function get_imdb_data (movie, id)
  if id then
    url = BASE_URL..'/?i=tt'..movie
  else
    url = BASE_URL..'/?t='..movie
  end
  local res,code  = https.request(url)
  if code ~= 200 then return "HTTP-FEHLER" end
  local data = json:decode(res)
  return data
end

function send_imdb_data(data, receiver)
  if data.Response == "False" then
    text = 'Film nicht gefunden!'
	send_msg(receiver, text, ok_cb, false)
  else
    local title = data.Title
	local release = data.Released
	if data.Type ~= "movie" then Type = '\nTyp: '..data.Type else Type = '' end
	if data.Runtime ~= "N/A" then runtime = '\nLaufzeit: '..data.Runtime else runtime = '' end
	if data.Genre ~= "N/A" then genre = '\nGenre: '..data.Genre else genre = '' end
	local director = data.Director
	if data.Writer ~= "N/A" then writer = '\nWriter: '..data.Writer else writer = '' end
	local actors = data.Actors
	if data.Plot ~= "N/A" then plot = '\nStory: '..data.Plot else plot = '' end
	if data.Metascore ~= "N/A" and data.imdbRating ~= "N/A" then
	  score = '\nBewertung: '..data.Metascore..' Metascore-Punkte und '..data.imdbRating..' von 10 Punkten von '..data.imdbVotes..' Votes auf IMDB'
	elseif data.Metascore ~= "N/A" and data.imdbRating == "N/A" then
	  score = '\nBewertung: '..data.Metascore..' Metascore-Punkte'
	elseif data.Metascore == "N/A" and data.imdbRating ~= "N/A" then
	  score = '\nBewertung: '..data.imdbRating..' von 10 Punkten von '..data.imdbVotes..' Votes auf IMDB'
    else
	  score = ''
	end
	local link = 'http://imdb.com/title/'..data.imdbID
	local text = title..Type..'\nErscheinungsdatm: '..release..runtime..genre..'\nDirector: '..director..writer..'\nSchauspieler: '..actors..plot..score..'\n-- '..link
	if data.Poster ~= "N/A" then
	  local image_url = data.Poster
      local cb_extra = {
        receiver=receiver,
        url=image_url
      }
      send_msg(receiver, text, send_photo_from_url_callback, cb_extra)
	else
      send_msg(receiver, text, ok_cb, false)
	end
  end
end

function run(msg, matches)
  if matches[2] then
    local movie = matches[2]
	data = get_imdb_data(movie, true)
  else
    local movie = url_encode(matches[1]:gsub(' ', '+'))
    data = get_imdb_data(movie, nil)
  end
  local receiver = get_receiver(msg)
  send_imdb_data(data, receiver)
end

return {
  description = "Zeigt Info zu einem Film (von IMDB, englisch)",
  usage = "!imdb [Film]: Zeigt Info zu Film",
  patterns = {
    "^!imdb (.+)",
	"imdb.com/title/(tt)(%d+[%d%.,]*)"
  },
  run = run
}

end

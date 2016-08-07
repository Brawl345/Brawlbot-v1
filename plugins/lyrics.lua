do

local apikey = cred_data.lyricsnmusic_apikey

function getLyrics(text)
  local q = string.match(text, "!lyrics (.+)")
  q = url_encode(q)
  b = http.request("http://api.lyricsnmusic.com/songs?api_key="..apikey.."&q=" .. q)
  response = json:decode(b)
  local reply = ""
  if #response > 0 then
    -- grab first match
    local result = response[1]
    reply = result.title .. " - " .. result.artist.name .. "\n" .. result.snippet .. "\n" .. result.url
  else
    reply = nil
  end
  return reply
end

function url_encode(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w %-%_%.%~])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str
end

function run(msg, matches)
  local lyrics = getLyrics(msg.text)
  if (lyrics == nil) then
    return "Zzzzz..."
  else
    return lyrics
  end
end

return {
    description = "Postet Liedertext",
    usage = "!lyrics [Lied]: Postet Liedertext",
    patterns = {"^!lyrics (.*)$"},
    run = run
}

end
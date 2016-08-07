do

local function run(msg, matches)
  local eq = URL.escape(matches[1])

  local url = "http://latex.codecogs.com/png.download?"
    .."\\dpi{300}%20\\LARGE%20"..eq

  local receiver = get_receiver(msg)
  send_photo_from_url(receiver, url)
end

return {
  description = "LaTeX in ein Bild konvertieren",
  usage = "!tex [TeX]: Konvertiet LaTeX in ein Bild.",
  patterns = {
    "!tex (.*)"
  },
  run = run
}

end


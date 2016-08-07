
do

local function get_clypit_details(shortcode)
  local BASE_URL = "http://api.clyp.it"
  local url = BASE_URL..'/'..shortcode
  local res,code  = http.request(url)
  if code ~= 200 then return 'HTTP-Fehler' end
  local data = json:decode(res)

  local title = data.Title
  local duration = string.gsub(round(data.Duration, 1), "%.", "%,")

  local text = title..' - '..duration..'s'
  local audio = download_to_file(data.Mp3Url, text..'.mp3')
  return audio
end

local function run(msg, matches)
  local shortcode = matches[1]
  local receiver = get_receiver(msg)

  local audio = get_clypit_details(shortcode)
  if not audio then return 'HTTP-Fehler oder Clip existiert nicht' end

  local cb_extra = {file_path=audio}
  send_audio(receiver, audio, rmtmp_cb, cb_extra)
end

return {
  description = "Postet Clypit-Audio",
  usage = "URL zu Clypit-Audio",
  patterns = {
    "clyp.it/([A-Za-z0-9-_-]+)",
  }, 
  run = run
}

end
-- Thanks @Akamaru [https://ponywave.de]
-- modified by iCON

local dest_dir = cred_data.youtube_dl_dest_dir -- WITH ENDING SLASH!!!!
if not dest_dir then dest_dir = '/tmp/' end

local function convert_video(link)
  local text = run_command('youtube-dl -o "'..dest_dir..'%(title)s.%(ext)s" -f mp4 '..link)
  local video = string.match(text, '%[download%] Destination: (.*).mp4')
  if not video then
    video = string.match(text, '%[download%] (.*).mp4 has already been downloaded')
  end
  return  video..'.mp4'
end

local function convert_audio(link)
  local text = run_command('youtube-dl -o "'..dest_dir..'%(title)s.%(ext)s" --extract-audio --audio-format mp3 '..link)
  local audio = string.match(text, '%[ffmpeg%] Destination: (.*).mp3')
  return audio..'.mp3'
end

function run(msg, matches)
  local video_link = matches[2]
  local receiver = get_receiver(msg)

  if matches[1] == 'mp4' then
    local file = convert_video(video_link)
    send_video(receiver, file, ok_cb, false)
  end
  
  if matches[1] == 'mp3' then
    local file = convert_audio(video_link)
	send_audio(receiver, file, ok_cb, false)
  end
end

return {
  description = "Downloadet Audio/Video von verschiedenen Seiten (https://rg3.github.io/youtube-dl/supportedsites.html) mit youtube-dl", 
  usage = {
	"!mp4 [Link]: Lädt Video von unterstützten Seiten",
	"!mp3 [Link]: Lädt Audio des Videos von unterstützten Seiten"
  },
  patterns = {
    "^!(mp4) (https?://[%w-_%.%?%.:/%+=&]+)$",
	"^!(mp3) (https?://[%w-_%.%?%.:/%+=&]+)$"
  }, 
  run = run
}
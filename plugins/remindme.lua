
function remindme(data)
  print('Cron:	remindme')
  local receiver = data[1]
  local text = data[2]
  send_msg(receiver, text, ok_cb, false)
end

function run(msg, matches)
  if matches[2] == 's' then
    minutes = 1
    seconds = tonumber(matches[1])
	if seconds > 3600 then return 'Bitte nicht länger als eine Stunde!' end
	remindtime = seconds
  elseif matches[2] == 'm' then
    minutes = tonumber(matches[1])
	seconds = 60.0
	if minutes > 60 then return 'Bitte nicht länger als eine Stunde!' end
	remindtime = math.floor(minutes * 60)
  end
  local text = matches[3]
  local receiver = get_receiver(msg)
  
  local current_timestamp = msg.date
  local dest_timestamp = current_timestamp+remindtime
  local dest_time = run_command('date -d @'..dest_timestamp..' +"%H:%M:%S"')
  local dest_time = string.gsub(dest_time, "%\n", "")

  postpone(remindme, {receiver, text}, minutes*seconds)
  return 'OK, ich werde dich um '..dest_time..' erinnern (BETA)!'
end

return {
  description = "Erinnert dich an etwas in XX Sekunden/Minuten (BETA)", 
  usage = {
    "!remindme (Zahl)s [Text]: Erinnert dich in XX Sekunden",
	"!remindme (Zahl)m [Text]: Erinnert dich in XX Minuten"
  },
  patterns = {
    "^!remindme (%d+)(s) (.+)$",
    "^!remindme (%d+)(m) (.+)$",
  }, 
  run = run 
}


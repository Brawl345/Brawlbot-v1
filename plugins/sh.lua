function run_sh(msg)
     name = get_name(msg)
     text = ''
	 bash = msg.text:sub(4,-1)
     text = run_command(bash)
     return text
end

function run(msg, matches)
  local receiver = get_receiver(msg)
  if string.starts(msg.text, '!sh') then
    text = run_sh(msg)
    send_msg(receiver, text, ok_cb, false)
    return
  end

  if string.starts(msg.text, '!uptime') then
    text = run_command('uptime')
    send_msg(receiver, text, ok_cb, false)
    return
  end

end

return {
    description = "Führt Befehle in der Konsole aus (nur Superuser).", 
    usage = "!sh [Befehl]: Führt Konsolenbefehl aus.",
    patterns = {"^!uptime", "^!sh (.*)$"}, 
    run = run,
    privileged = true
}

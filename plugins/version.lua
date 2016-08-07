do

function run(msg, matches)
  return 'Brawlbot '.. VERSION ..  [[

Geforkt von https://github.com/yagop/telegram-bot
Veröffentlicht unter der GNU GPLv2.
Enthält proprietären Code von Andreas Bielawski, © 2014-2016

Ankündigungen und Updates: https://telegram.me/brawlbot_updates]]
end

return {
  description = "Zeigt die Version und Lizenz des Bots", 
  usage = "!version: Zeigt die Version des Bots an",
  patterns = {"^!version$"}, 
  run = run 
}

end

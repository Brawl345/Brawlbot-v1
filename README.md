Brawlbot v1/Legacy
============

# Eine neue Version auf Basis der Bot-API ist [hier](https://github.com/Brawl345/Brawlbot-v2) zu finden! Diese Version wurde eingestellt.

Ein Telegram-Bot auf Basis von [tg](https://github.com/vysheng/tg), der Plugins nutzt. Ein Fork von [yagops Telegram-Bot](https://github.com/yagop/telegram-bot).

**(c) 2014-2016 Andreas Bielawski**

Funktionen
----------
- Wenn ein User einen Link zu einem Bild (png, jpg, jpeg) sendet, wird es gedownloadet und gesendet.
- Wenn ein User einen Link zu einer Medien-Datei (gif, mp4, pdf, etc.) sendet, wird sie gedownloadet und gesendet.
- Wenn ein User eine Twitter-URL sendet, wird der Text und evtl. das Bild gesendet. OAuth-Key wird benötigt.
- Wenn ein User ein YouTube-, Vimeo- oder Dailymotion-Video sendet, wird der Titel, optional die Beschreibung, der Autor und die Aufrufeanzahl gesendet.
- Viele Plugins integriert, bspw. für Danbooru, Google Bilder, Bing Bilder, RSS, Währungen, Yahoo! Finance, Gender-API, Vine, Instagram, Facebook, Bing Translate uvm.
- Setzt auf Redis für schnelle Perfomance
- Stetige Weiterentwicklung

[![](https://i.imgur.com/0oijl0g.png)](https://i.imgur.com/BiTeLie.png)
[![](https://i.imgur.com/mdLM6KM.png)](https://i.imgur.com/AtOIpTm.png)
[![](https://i.imgur.com/inYiCeJ.png)](https://i.imgur.com/msrHN3s.png)
[![](https://i.imgur.com/PwUJoYj.png)](https://i.imgur.com/CjinnHU.png)
[![](https://i.imgur.com/3QWMv4C.png)](https://i.imgur.com/DGWUMB6.png)
[![](https://i.imgur.com/S2DItDc.png)](https://i.imgur.com/Xsx27vy.png)
[![](https://i.imgur.com/uIbFeU7.png)](https://i.imgur.com/ccC3TzB.png)
[![](https://i.imgur.com/SX4iLKo.png)](https://i.imgur.com/b9Zygjj.png)
[![](https://i.imgur.com/qmgc8YF.png)](https://i.imgur.com/aW4mWqh.png)
[![](https://i.imgur.com/g793izW.png)](https://i.imgur.com/Rn0BMka.png)
[![](https://i.imgur.com/Nuu0kR4.png)](https://i.imgur.com/XJBAtuI.png)

Befehle
------------
Eine Hilfe zu allen Befehlen erhälst du mit `!hilfe`.

Installation
------------
```bash
# Getestet auf Ubuntu 14.04, für andere Distris, checke https://github.com/vysheng/tg#installation
$ sudo apt-get install libreadline-dev libconfig-dev libssl-dev lua5.2 liblua5.2-dev libevent-dev make unzip git redis-server libjansson-dev libpython-dev
# Nach den Abhängigkeiten kommt jetzt die Installation des Bots
$ cd $HOME
$ git clone https://gitlab.com/iCON/brawlbot.git
$ cd brawlbot
$ git clone —recursive https://github.com/vysheng/tg.git
$ ./launch.sh install
$ ./launch.sh # Fragt dich nach deiner Telefonnummer und dem Verifizierungscode
```

Mehr [`Plugins`](https://gitlab.com/iCON/brawlbot/tree/master/plugins) aktivieren
-------------
Schau dir die Plugins-Liste mit `!plugins` an.

Aktiviere oder deaktiviere ein Plugin mit `!plugins enable [name-ohne-.lua]`.

Deaktiviere ein aktiviertes Plugin mit `!plugins disable [name-ohne-.lua]`.

Diese Kommandos benötigen einen privilegierten User (Superuser). Starte redis und führe das folgende Kommando aus: `SADD telegra:sudo_users MYID` - ersetze "MYID" durch deine ID, die du mit `!id` bekommst. Weitere Superuser kannst du danach mit `!makesudo user <user_id>` hinzufügen.

## API-Keys eintragen
Trage deine Keys mit dem Logininformationen-Manager ein. Die Logindaten werden in Redis gespeichert, ziehe bitte `!hilfe credentials_manager` zur Rate!

Als einen Daemon starten
------------
## Upstart
Wenn deine Distribution mit [upstart](http://upstart.ubuntu.com/) kommt, kannst du den Bot damit starten (empfohlen wird aber daemontools):
```bash
$ sed -i "s/yourusername/$(whoami)/g" etc/telegram.conf
$ sed -i "s_telegrambotpath_$(pwd)_g" etc/telegram.conf
$ sudo cp etc/telegram.conf /etc/init/
$ sudo start telegram # Zum Starten
$ sudo stop telegram # Zum Stoppen
```

## Daemontools
Falls du [Daemontools](http://cr.yp.to/daemontools.html) installiert hast, kannst du den Bot über Daemontools starten, was den Vorteil hat, dass er sich bei einem Absturz automatisch neu startet!
```bash
$ mkdir -p ~/daemons/run-telegraam-bot
$ nano ~/daemons/run-telegraam-bot/run
```
Füge ein:
````bash
#!/bin/sh
export USER=username-hier-eintragen
export HOME=/home/$USER
. $HOME/.bash_profile
echo "Starting Bot"
cd $HOME/pfad/zum/telegram-bot
exec ./tg/bin/telegram-cli -k tg/tg-server.pub -s ./bot/bot.lua -l 1 --disable-link-preview >/dev/null 2>&1
```
```bash
$ chmod +x ~/daemons/run-telegraam-bot/run
$ ln -s ~/daemons/run-telegraam-bot ~/service/telegram-bot
```
Starte den Daemon dann mit `svc -u ~/service/telegram-bot` und stoppe ihn mit  `svc -d ~/service/telegram-bot` (warte zwischen dem Stoppen und dem Neustarten ein paar Sekunden).
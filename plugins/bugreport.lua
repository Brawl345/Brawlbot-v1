do

local token = cred_data.gitlab_private_token
local id = cred_data.gitlab_project_id
local BASE_URL = 'https://gitlab.com/api/v3'

local makeOurDate = function(dateString)
  local pattern = "(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)"
  local year, month, day, hours, minutes, seconds = dateString:match(pattern)
  return day..'.'..month..'.'..year..' um '..hours..':'..minutes..':'..seconds..' UTC'
end

local function get_bugs ()
  local url = BASE_URL..'/projects/'..id..'/issues?state=opened&private_token='..token
  local res,code  = https.request(url)
  if code ~= 200 then return "Konnte keine Verbindung zu gitlab.com aufbauen - versuche es bitte erneut!" end
  local data = json:decode(res)
  local buglist = ""
  for bugs in pairs(data) do
    buglist = buglist..'\n#'..data[bugs].iid..' - '..data[bugs].title
  end
  if buglist == "" then buglist = "Keine offenen Bugreports! Bug-free, yay!" end
  return buglist
end

local function post_bug (title, description)
  local post_url = BASE_URL..'/projects/'..id..'/issues?private_token='..token
  local pet = post_petition(post_url, 'title='..title..'&description='..description)
  if pet.id then
    if pet.description then desc = '\nBeschreibung: '..pet.description else desc = '' end
    message = 'Bugreport #'..pet.iid..' erfolgreich gepostet!\nTitel: '..pet.title..desc..'\n\nBug-ID: '..pet.id..' - Teile diese mit niemandem und bewahre sie gut auf!\nDu kannst den Bugreport und dessen Status mit\n!bugs get '..pet.id..'\nabrufen.'
  elseif pet.message then
    message = 'Ein Fehler ist aufgetreten: '..pet.message
  else
    message = 'Ein unbekannter Fehler ist aufgetreten'
  end
  return message
end

local function get_bugreport (bug_num)
  local url = BASE_URL..'/projects/'..id..'/issues/'..bug_num..'?private_token='..token
  local res,code  = https.request(url)
  if code == 404 then return "Ein Bug mit dieser Nummer wurde nicht gefunden." end
  if code ~= 200 then return "Konnte keine Verbindung zu gitlab.com aufbauen - versuche es bitte erneut!" end
  local data = json:decode(res)
  local iid = data.iid
  local title = data.title
  if data.description then
    description = ':\nBeschreibung: '..data.description
  else
    description = ''
  end
  local state = data.state
  local updated = makeOurDate(data.updated_at)
  local bug = '#'..iid..': '..title..description..'\n\nStatus: '..state..'\nZuletzt aktualisiert: '..updated
  return bug
end

local function run(msg, matches)
  if msg.to.type == 'chat' then
    return 'Bitte verwende diesen Befehl nur im Einzelchat!'
  else
    local receiver = get_receiver(msg)
    if matches[1] == "list" then
      return get_bugs()
    end
  
    if matches[1] == "report" and matches[2] and matches[3] then
	  local user_name = get_name(msg)
      local title = matches[2]
	  local description = matches[3]..'\nReportet von: '..user_name
      return post_bug(title, description)
    end
  
    if matches[1] == "get" and string.match(matches[2], "(%d+[%d%-]*)") then
      local bug_num = matches[2]
	  return get_bugreport(bug_num)
    end
  end
end

return {
  description = "Bug-Report-Plugin", 
  usage = {
    "!bugs list: Listet bekannte Bugs auf",
	"!bugs report [Titel]|[Beschreibung]: Erstelle einen Bug-Report - ACHTUNG, ein Missbrauch dieser Funktion führt zum Ausschluss!",
	"!bugs get [Bug-ID]: Siehe diesen Bug-Report an"
  },
  patterns = {
    "^!bugs? (list)$",
	"^!bugs? (report) (.+)|(.+)$",
	"^!bugs? (get) (%d+[%d%-]*)"
  },
  run = run 
}

end

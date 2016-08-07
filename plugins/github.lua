do

local BASE_URL = 'https://api.github.com'

function get_gh_data()
  if gh_commit_sha == nil then
    url = BASE_URL..'/repos/'..gh_code
  else
    url = BASE_URL..'/repos/'..gh_code..'/git/commits/'..gh_commit_sha
  end
  local res,code  = https.request(url)
  if code ~= 200 then return "HTTP-FEHLER" end
  local data = json:decode(res)
  return data
end

function send_github_data(data, receiver)
  local name = data.name
  local description = data.description
  local owner = data.owner.login
  local clone_url = data.clone_url
  if data.language == nil or data.language == "" then
    language = ''
  else
    language = '\nSprache: '..data.language
  end
  if data.open_issues_count == 0 then
    issues = ''
  else
    issues = '\nOffene Bugreports: '..data.open_issues_count
  end
  if data.homepage == nil or data.homepage == "" then
    homepage = ''
  else
    homepage = '\nHomepage: '..data.homepage
  end
  local text = name..' von '..owner..'\n'..description..'\ngit clone '..clone_url..language..issues..homepage
  send_msg(receiver, text, ok_cb, false)
end

function send_gh_commit_data(data, receiver)
  local committer = data.committer.name
  local message = data.message
  local text = gh_code..'@'..gh_commit_sha..' von '..committer..':\n'..message
  send_msg(receiver, text, ok_cb, false)
end

function run(msg, matches)
  gh_code = matches[1]..'/'..matches[2]
  gh_commit_sha = matches[3]
  local data = get_gh_data()
  local receiver = get_receiver(msg)
  if not gh_commit_sha then
    send_github_data(data, receiver)
  else
    send_gh_commit_data(data, receiver)
  end
end

return {
  description = "Sendet GitHub-Info.", 
  usage = {
    "Link zu GitHub-Repo",
	"Link zu GitHub-Commit"
  },
  patterns = {
    "github.com/([A-Za-z0-9-_-.-._.]+)/([A-Za-z0-9-_-.-._.]+)/commit/([a-z0-9-]+)",
    "github.com/([A-Za-z0-9-_-.-._.]+)/([A-Za-z0-9-_-.-._.]+)/?$"
  },
  run = run 
}

end

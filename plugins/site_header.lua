-- by Akamaru [https://ponywave.de]
-- modified by iCON

require("./plugins/sh")

local function run(msg, matches)
  local url = matches[2]
  
  if matches[1] == 'head' then
    return run_command('curl --head '..url)
  else
    return run_command('dig '..url..' ANY')
  end
end

return {
  description = "Führe curl --head und dig aus.", 
  usage = {
    "!head [URL]: Führt curl --head aus",
	"!dig [URL]: Führt dig ANY aus"
  },
  patterns = {
    "^!(head) ([%w-_%.%?%.:,/%+=&#!]+)$",
    "^!(dig) ([%w-_%.%?%.:,/%+=&#!]+)$"
  },
  run = run
}
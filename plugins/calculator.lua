-- Function reference: http://mathjs.org/docs/reference/functions/categorical.html

local function mathjs(exp)
  local exp = string.gsub(exp, "%,", "%.")
  local url = 'http://api.mathjs.org/v1/'
  url = url..'?expr='..URL.escape(exp)
  local b,c = http.request(url)
  local text = nil
  if c == 200 then
    text = 'Ergebnis: '..string.gsub(b, "%.", "%,")
  
  elseif c == 400 then
    text = b
  else
    text = 'Unerwarteter Fehler\n'
      ..'Ist api.mathjs.org erreichbar?'
  end
  return text
end

local function run(msg, matches)
  return mathjs(matches[1])
end

return {
  description = "Rechnen mit der mathjs-API",
  usage = {
    "!calc [Ausdruck]: Rechnet",
	"Weitere Hilfe: + = Plus, - = Minus, * = Mal, / = geteilt"
  },
  patterns = {
    "^!calc (.*)$"
  },
  run = run
}
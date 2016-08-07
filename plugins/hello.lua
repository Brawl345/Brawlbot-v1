
function run(msg, matches)
  return "Hallo, " .. matches[1]
end

return {
  description = "Sagt zu jemandem Hallo", 
  usage = "sag Hallo zu [Name]",
  patterns = {
    "^say hello to (.*)$",
    "^Say hello to (.*)$",
	"^Sag Hallo zu (.*)$",
	"^sag Hallo zu (.*)$",
	"^sag hallo zu (.*)$"
  }, 
  run = run 
}
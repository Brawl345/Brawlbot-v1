possibles = {
    "Ja",
    "Nein",
    "Eines Tages vielleicht"
}

function frag_die_muschel()
    local random = math.random(3)
    return possibles[random]
end

function run(msg, matches)
    local result = frag_die_muschel()
    return result
end


return {
    description = "Befrage die magische Miesmuschel",
    usage = "Magische Miesmuschel, [Frage]: Befragt die magische Miesmuschel",
    patterns = {
	"^Magische Miesmuschel, (.*)$",
	"^magische Miesmuschel, (.*)$",
	"^Magische miesmuschel, (.*)$",
	"^magische miesmuschel, (.*)$"
	}, 
    run = run
}

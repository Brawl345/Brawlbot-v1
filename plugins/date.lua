function run(msg, matches)
	text = os.date("%A, %d. %B %Y")
	
	-- Days
	text = string.gsub(text, "Monday", "Montag")
	text = string.gsub(text, "Tuesday", "Dienstag")
	text = string.gsub(text, "Wednesday", "Mittwoch")
	text = string.gsub(text, "Thursday", "Donnerstag")
	text = string.gsub(text, "Friday", "Freitag")
	text = string.gsub(text, "Saturday", "Samstag")
	text = string.gsub(text, "Sunday", "Sonntag")
	
	-- Months
	text = string.gsub(text, "January", "Januar")
	text = string.gsub(text, "February", "Februar")
	text = string.gsub(text, "March", "März")
	text = string.gsub(text, "April", "April")
	text = string.gsub(text, "May", "Mai")
	text = string.gsub(text, "June", "Juni")
	text = string.gsub(text, "July", "Juli")
	text = string.gsub(text, "August", "August")
	text = string.gsub(text, "September", "September")
	text = string.gsub(text, "October", "Oktober")
	text = string.gsub(text, "November", "November")
	text = string.gsub(text, "December", "Dezember")

	return text
end

return {
    description = "Zeigt das aktuelle Datum an", 
    usage = "!date: Zeigt aktuelles Datum",
    patterns = {"^![D|d]ate$","^![D|d]atum$"}, 
    run = run 
}
--by Akamaru [https://ponywave.de]

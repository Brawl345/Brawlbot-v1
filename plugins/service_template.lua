local function run(msg, matches)
   -- avoid this plugins to process user messages
   if not msg.service then
      -- return "Versuchst du mich etwa zu trollen?"
      return nil
   end
   print("Service message received: " .. matches[1])
end


return {
   description = "Service-Plugin: Template",
   usage = "",
   patterns = {
      "^!!tgservice (.*)$" -- Do not use the (.*) match in your service plugin
   },
   run = run
}

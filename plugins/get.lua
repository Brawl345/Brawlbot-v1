local function get_value(msg, var_name)
  local hash = get_redis_hash(msg, 'variables')
  if hash then
    local value = redis:hget(hash, var_name)
    if not value then
      return'Nicht gefunden, benutze "!get", um alle Variablen aufzulisten.'
    else
      return var_name..' = '..value
    end
  end
end

local function list_variables(msg)
  local hash = get_redis_hash(msg, 'variables')
  
  if hash then
    print('Getting variable from redis hash '..hash)
    local names = redis:hkeys(hash)
    local text = ''
	for i=1, #names do
	  variables = get_value(msg, names[i])
      text = text..variables.."\n"
    end
	if text == '' or text == nil then
	  return 'Keine Variablen vorhanden!'
	else
      return text
	end
  end
end

local function run(msg, matches)
  if matches[2] then
    return get_value(msg, matches[2])
  else
    return list_variables(msg)
  end
end

return {
  description = "Bekommt Variablen, die mit !set gesetzt wurden", 
  usage = {
    "!get: Gibt alle Variablen aus",
    "!get (Variable): Gibt die Variable aus."
  },
  patterns = {
    "^(!get) (.+)$",
    "^!get$"
  },
  run = run
}

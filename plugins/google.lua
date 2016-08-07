function googlethat(query)
  local BASE_URL = 'https://www.googleapis.com/customsearch/v1'
  local apikey = cred_data.google_apikey
  local cseid = cred_data.google_cse_id
  local number = 5 -- Set number of results 

  local api        = BASE_URL.."/?key="..apikey.."&cx="..cseid.."&gl=de&num="..number.."&safe=medium&fields=searchInformation%28formattedSearchTime,formattedTotalResults%29,items%28title,link%29&"
  local parameters = "q=".. (URL.escape(query) or "")
  -- Do the request
  local res, code = https.request(api..parameters)
  if code == 403 then return 'QUOTAEXCEEDED' end
  if code ~= 200 then return nil end
  local data = json:decode(res)
  if data.searchInformation.formattedTotalResults == "0" then return nil end
  
  local results={}
  for key,result in ipairs(data.items) do
    table.insert(results, {
	  result.title,
      result.link
    })
  end
  
  local stats = data.searchInformation.formattedTotalResults..' Ergebnisse, gefunden in '..data.searchInformation.formattedSearchTime..' Sekunden'
  return results, stats
end

function stringlinks(results, stats)
  local stringresults=""
  for key,val in ipairs(results) do
    stringresults=stringresults..val[1].." - "..val[2].."\n"
  end
  return stringresults..stats
end

function run(msg, matches)
  local results, stats = googlethat(matches[1])
  if results == 'QUOTAEXCEEDED' then
    return 'Kontingent für heute erreicht, keine weiteren Suchanfragen möglich.'
  end
  if results == nil then
    return 'Nichts gefunden!'
  else
    return stringlinks(results, stats)
  end
end

return {
   description = "Durchsucht Google",
   usage = "!google [Suchbegriff]: Durchsucht Google",
   patterns = {
      "^!google (.*)$",
      "^%.[g|G]oogle (.*)$"
   },
   run = run
}
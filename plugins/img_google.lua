local _blacklist

local function getGoogleImage(text)
  local apikey = cred_data.google_apikey
  local cseid = cred_data.google_cse_id
  local url = 'https://www.googleapis.com/customsearch/v1?cx='..cseid..'&key='..apikey..'&searchType=image&num=10&fields=items(link)&safe=high&q='..URL.escape(text)
  local res, code = https.request(url)
  if code == 403 then return 'QUOTAEXCEEDED' end
  if code ~= 200 then return nil end

  local google = json:decode(res).items
  return google
end

local function cache_google_image(results, text)
  local cache = {}
  for v in pairs(results) do
    table.insert(cache, results[v].link)
  end
  cache_data('img_google', string.lower(text), cache, 1209600, 'set')
end

function run(msg, matches)
  local receiver = get_receiver(msg)
  local text = matches[1]  
  
  print ('Checking if search contains blacklisted words: '..text)
  if is_blacklisted(text) then
    return "Vergiss es ._."
  end
  
  local hash = 'telegram:cache:img_google:'..string.lower(text)
  local results = redis:smembers(hash)
  if not results[1] then
    print('doing web request')
    results = getGoogleImage(text)
	if results == 'QUOTAEXCEEDED' then
	  return 'Kontingent für heute erreicht - nur noch gecachte Suchanfragen möglich (oder !bingimg <Suchbegriff>).'
	end
    if not results then
      return "Kein Bild gefunden!"
    end
    cache_google_image(results, text)
  end
  -- Random image from table
  local i = math.random(#results)
  local url = nil
  
  local failed = true
  local nofTries = 0
  while failed and nofTries < #results do 
      if not results[i].link then
        url = results[i]
	  else
	    url = results[i].link
	  end
	  print("Bilder-URL: ", url)
	  
	  if string.ends(url, ".gif") then
		failed = not send_document_from_url(receiver, url, nil, nil, true)
	  elseif string.ends(url, ".jpg") or string.ends(url, ".jpeg") or string.ends(url, ".png") then
		failed = not send_photo_from_url(receiver, url, nil, nil, true)
	  end
	  
	  nofTries = nofTries + 1
	  i = i+1
	  if i > #results then
		i = 1
	  end 
  end
  
  if failed then
	  return "Fehler beim Herunterladen eines Bildes."
  end
end

return {
  description = "Sucht Bild mit Google-API und versendet es (SafeSearch aktiv)", 
  usage = {
    "!img [Suchbegriff]"
  },
  patterns = {
    "^!img (.*)$",
    "^!googleimg (.*)$"
  }, 
  run = run 
}
end
canroll = {
    "1",
    "2",
    "3",
    "4",
    "5",
    "6"
}


function roll_dice()
    local randomroll = math.random(6)
    return canroll[randomroll]
end

function run(msg, matches)
    local user_name = get_name(msg)
    local resultroll = roll_dice()
    return user_name .. " hat eine " .. resultroll .. " gewürfelt"
end


return {
    description = "Rollt einen Würfel",
    usage = "!roll: Rollt einen Würfel",
    patterns = {"^!roll"},
    run = run
}

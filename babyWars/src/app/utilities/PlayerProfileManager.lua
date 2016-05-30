
local PlayerProfileManager = {}

local PLAYER_PROFILE_PATH = "babyWars/res/data/playerProfile/"

local s_PlayerProfileList = {}

function PlayerProfileManager.getPlayerProfile(account)
    if (not s_PlayerProfileList[account]) then
        local fullFileName = PLAYER_PROFILE_PATH .. account .. ".lua"
        local file = io.open(fullFileName, "r")
        if (not file) then
            return nil
        else
            file:close()
            s_PlayerProfileList[account] = {
                fullFileName = fullFileName,
                account      = account,
                profile      = dofile(fullFileName),
            }
        end
    end

    return s_PlayerProfileList[account].profile
end

function PlayerProfileManager.isAccountAndPasswordValid(account, password)
    local profile = PlayerProfileManager.getPlayerProfile(account)
    return (profile) and (profile.password == password)
end

return PlayerProfileManager


local PlayerProfileManager = {}

local SerializationFunctions = require("babyWars.src.app.utilities.SerializationFunctions")

local PLAYER_PROFILE_PATH = "babyWars/res/data/playerProfile/"

local s_PlayerProfileList = {}

--------------------------------------------------------------------------------
-- The util functions.
--------------------------------------------------------------------------------
local function generatePlayerProfile(account, password)
    return {
        password = password,
        nickname = account,

        rankScore = 1000,

        gameRecords = {
            win  = 0,
            lose = 0,
            draw = 0
        },

        skillConfigurations = {
            {
                passive = {},
                active1 = {},
                active2 = {},
            },
            {
                passive = {},
                active1 = {},
                active2 = {},
            },
            {
                passive = {},
                active1 = {},
                active2 = {},
            },
        },

        warLists = {
            created = {},
            ongoing = {},
        }
    }
end

local function serializePlayerProfile(fullFileName, profile)
    local file = io.open(fullFileName, "w")
    file:write("return ")
    file:write(SerializationFunctions.serialize(profile))
    file:close()
end

--------------------------------------------------------------------------------
-- The public functions.
--------------------------------------------------------------------------------
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

function PlayerProfileManager.createPlayerProfile(account, password)
    if (PlayerProfileManager.getPlayerProfile(account)) then
        return
    end

    local fullFileName = PLAYER_PROFILE_PATH .. account .. ".lua"
    local profile = generatePlayerProfile(account, password)
    serializePlayerProfile(fullFileName, profile)

    s_PlayerProfileList[account] = {
        fullFileName = fullFileName,
        account      = account,
        profile      = profile,
    }

    return s_PlayerProfileList[account].profile
end

return PlayerProfileManager

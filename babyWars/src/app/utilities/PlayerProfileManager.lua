
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
            [2] = {win  = 0, lose = 0, draw = 0,},
            [3] = {win  = 0, lose = 0, draw = 0,},
            [4] = {win  = 0, lose = 0, draw = 0,},
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

local function toFullFileName(account)
    return PLAYER_PROFILE_PATH .. account .. ".lua"
end

local function serialize(fullFileName, data)
    local file = io.open(fullFileName, "w")
    file:write("return ")
    SerializationFunctions.appendToFile(data, "", file)
    file:close()
end

--------------------------------------------------------------------------------
-- The public functions.
--------------------------------------------------------------------------------
function PlayerProfileManager.getPlayerProfile(account)
    if (not s_PlayerProfileList[account]) then
        local fullFileName = toFullFileName(account)
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

    local fullFileName = toFullFileName(account)
    local profile = generatePlayerProfile(account, password)
    serialize(fullFileName, profile)

    s_PlayerProfileList[account] = {
        fullFileName = fullFileName,
        account      = account,
        profile      = profile,
    }

    return s_PlayerProfileList[account].profile
end

function PlayerProfileManager.updateProfilesWithBeginningWar(sceneWarFileName, configuration)
    for _, player in pairs(configuration.players) do
        local account = player.account
        local profile = PlayerProfileManager.getPlayerProfile(account)

        profile.warLists.ongoing[sceneWarFileName] = 1
        serialize(toFullFileName(account), profile)
    end

    return PlayerProfileManager
end

function PlayerProfileManager.updateProfilesWithModelSceneWar(modelSceneWar)
    local sceneWarFileName   = modelSceneWar:getFileName()
    local modelPlayerManager = modelSceneWar:getModelPlayerManager()
    local playersCount       = modelPlayerManager:getPlayersCount()
    local alivePlayersCount  = 0
    local alivePlayerAccount = nil

    modelSceneWar:getModelPlayerManager():forEachModelPlayer(function(modelPlayer, playerIndex)
        local account = modelPlayer:getAccount()
        if (modelPlayer:isAlive() then
            alivePlayersCount  = alivePlayersCount + 1
            alivePlayerAccount = account
        else
            local profile = PlayerProfileManager.getPlayerProfile(account)
            if (profile.warLists.ongoing[sceneWarFileName]) then
                profile.gameRecords[playersCount].lose = profile.gameRecords[playersCount].lose + 1
                profile.warLists.ongoing[sceneWarFileName] = nil
                serialize(toFullFileName(account), profile)
            end
        end
    end)

    if (alivePlayersCount == 1) then
        local profile = PlayerProfileManager.getPlayerProfile(alivePlayerAccount)
        profile.gameRecords[playersCount].win = profile.gameRecords[playersCount].win + 1
        profile.warLists.ongoing[sceneWarFileName] = nil
        serialize(toFullFileName(alivePlayerAccount), profile)
    end

    return PlayerProfileManager
end

return PlayerProfileManager

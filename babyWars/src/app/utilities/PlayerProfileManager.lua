
local PlayerProfileManager = {}

local SerializationFunctions = require("src.app.utilities.SerializationFunctions")

local PLAYER_PROFILE_PATH          = "babyWars/res/data/playerProfile/"
local SINGLE_SKILL_CONFIGURATION   = {
    maxPoints = 100,
    passive   = {},
    active1   = {},
    active2   = {},
}
local SINGLE_GAME_RECORD           = {
    win  = 0,
    lose = 0,
    draw = 0,
}
local DEFAULT_RANK_SCORE           = 1000
local DEFAULT_GAME_RECORDS         = {
    [2] = SINGLE_GAME_RECORD,
    [3] = SINGLE_GAME_RECORD,
    [4] = SINGLE_GAME_RECORD,
}
local DEFAULT_WAR_LIST             = {
    created = {},
    ongoing = {},
}
local DEFAULT_SKILL_CONFIGURATIONS = {}
for i = 1, 10 do
    DEFAULT_SKILL_CONFIGURATIONS[i] = SINGLE_SKILL_CONFIGURATION
end

local s_IsInitialized     = false
local s_PlayerProfileList = {}

--------------------------------------------------------------------------------
-- The util functions.
--------------------------------------------------------------------------------
local function generatePlayerProfile(account, password)
    return {
        password = password,
        nickname = account,

        rankScore           = DEFAULT_RANK_SCORE,
        gameRecords         = DEFAULT_GAME_RECORDS,
        skillConfigurations = DEFAULT_SKILL_CONFIGURATIONS,
        warLists            = DEFAULT_WAR_LIST,
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
function PlayerProfileManager.init()
    if (s_IsInitialized) then
        return
    end

    os.execute("mkdir " .. PLAYER_PROFILE_PATH)

    s_IsInitialized = true
    return PlayerProfileManager
end

function PlayerProfileManager.getPlayerProfile(account)
    if ((type(account) ~= "string") or (string.len(account) == 0)) then
        return nil
    end

    local lowerAccount = string.lower(account)
    if (not s_PlayerProfileList[lowerAccount]) then
        local fullFileName = toFullFileName(lowerAccount)
        local file = io.open(fullFileName, "r")
        if (not file) then
            return nil
        else
            file:close()
            s_PlayerProfileList[lowerAccount] = {
                fullFileName = fullFileName,
                profile      = dofile(fullFileName),
            }
        end
    end

    return s_PlayerProfileList[lowerAccount].profile
end

function PlayerProfileManager.getSkillConfiguration(account, configurationID)
    local profile = PlayerProfileManager.getPlayerProfile(account)
    if (not profile) then
        return nil, "PlayerProfileManager.getSkillConfiguration() the profile doesn't exist."
    else
        return profile.skillConfigurations[configurationID]
    end
end

function PlayerProfileManager.setSkillConfiguration(account, configurationID, modelSkillConfiguration)
    local profile = PlayerProfileManager.getPlayerProfile(account)
    assert(profile, "PlayerProfileManager.setSkillConfiguration() the profile doesn't exist.")

    profile.skillConfigurations[configurationID] = modelSkillConfiguration:toSerializableTable()
    serialize(toFullFileName(account), profile)

    return PlayerProfileManager
end

function PlayerProfileManager.isAccountAndPasswordValid(account, password)
    local profile = PlayerProfileManager.getPlayerProfile(account)
    return (profile) and (profile.password == password)
end

function PlayerProfileManager.createPlayerProfile(account, password)
    if (not PlayerProfileManager.getPlayerProfile(account)) then
        local fullFileName = toFullFileName(account)
        local profile      = generatePlayerProfile(account, password)
        serialize(fullFileName, profile)
    end

    return PlayerProfileManager.getPlayerProfile(account)
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
        if (modelPlayer:isAlive()) then
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

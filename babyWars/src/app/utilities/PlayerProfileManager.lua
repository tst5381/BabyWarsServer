
local PlayerProfileManager = {}

local SerializationFunctions = require("src.app.utilities.SerializationFunctions")

local decode = SerializationFunctions.decode
local encode = SerializationFunctions.encode
local io     = io

local PLAYER_PROFILE_PATH          = "babyWars\\res\\data\\playerProfile\\"
local SINGLE_SKILL_CONFIGURATION   = {
    maxPoints = 100,
    passive   = {},
    active1   = {},
    active2   = {},
}
local DEFAULT_RANK_SCORE           = 1000
local DEFAULT_GAME_RECORDS         = {
    [2] = {playersCount = 2, win = 0, lose = 0, draw = 0},
    [3] = {playersCount = 3, win = 0, lose = 0, draw = 0},
    [4] = {playersCount = 4, win = 0, lose = 0, draw = 0},
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
        account  = account,
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

local function loadProfile(account)
    local fullFileName = toFullFileName(account)
    local file         = io.open(fullFileName, "rb")
    if (not file) then
        return nil
    else
        local data = file:read("*a")
        file:close()

        return decode("PlayerProfile", data)
    end
end

local function serializeProfile(account, profile)
    local file = io.open(toFullFileName(account), "wb")
    file:write(encode("PlayerProfile", profile))
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
    local lowerAccount = string.lower(account)
    if (not s_PlayerProfileList[lowerAccount]) then
        local profile = loadProfile(account)
        if (not profile) then
            return nil
        else
            s_PlayerProfileList[lowerAccount] = {
                fullFileName = toFullFileName(account),
                profile      = profile,
            }
        end
    end

    return s_PlayerProfileList[lowerAccount].profile
end

function PlayerProfileManager.createPlayerProfile(account, password)
    assert(not PlayerProfileManager.getPlayerProfile(account), "PlayerProfileManager.createPlayerProfile() the profile has been created already.")
    serializeProfile(account, generatePlayerProfile(account, password))

    return PlayerProfileManager.getPlayerProfile(account)
end

function PlayerProfileManager.isAccountRegistered(account)
    return PlayerProfileManager.getPlayerProfile(account) ~= nil
end

function PlayerProfileManager.isAccountAndPasswordValid(account, password)
    if (not account) then
        return false
    else
        local profile = PlayerProfileManager.getPlayerProfile(account)
        return (profile) and (profile.password == password)
    end
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
    serializeProfile(account, profile)

    return PlayerProfileManager
end

function PlayerProfileManager.updateProfilesWithBeginningWar(sceneWarFileName, configuration)
    for _, player in pairs(configuration.players) do
        local account = player.account
        local profile = PlayerProfileManager.getPlayerProfile(account)

        profile.warLists.ongoing[sceneWarFileName] = 1
        serializeProfile(account, profile)
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
                serializeProfile(account, profile)
            end
        end
    end)

    if (alivePlayersCount == 1) then
        local profile = PlayerProfileManager.getPlayerProfile(alivePlayerAccount)
        profile.gameRecords[playersCount].win = profile.gameRecords[playersCount].win + 1
        profile.warLists.ongoing[sceneWarFileName] = nil
        serializeProfile(alivePlayerAccount, profile)
    end

    return PlayerProfileManager
end

return PlayerProfileManager

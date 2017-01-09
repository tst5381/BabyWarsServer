
local PlayerProfileManager = {}

local SerializationFunctions = require("src.app.utilities.SerializationFunctions")

local decode = SerializationFunctions.decode
local encode = SerializationFunctions.encode
local io     = io

local PLAYER_PROFILE_PATH          = "babyWars\\res\\data\\playerProfile\\"
local DEFAULT_SINGLE_GAME_RECORD   = {rankScore = 1000, win = 0, lose = 0, draw = 0}
local DEFAULT_GAME_RECORDS         = {}
for i = 1, 6 do
    DEFAULT_GAME_RECORDS[i] = DEFAULT_SINGLE_GAME_RECORD
end
local SINGLE_SKILL_CONFIGURATION   = {
    basePoints = 100,
    passive    = {},
    active1    = {},
    active2    = {},
}
local DEFAULT_SKILL_CONFIGURATIONS = {}
for i = 1, require("src.app.utilities.SkillDataAccessors").getSkillConfigurationsCount() do
    DEFAULT_SKILL_CONFIGURATIONS[i] = SINGLE_SKILL_CONFIGURATION
end
local DEFAULT_WAR_LIST             = {
    created = {},
    ongoing = {},
}

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

local function serializeProfile(profile)
    local file = io.open(toFullFileName(profile.account), "wb")
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
    serializeProfile(generatePlayerProfile(account, password))

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
    return PlayerProfileManager.getPlayerProfile(account).skillConfigurations[configurationID]
end

function PlayerProfileManager.setSkillConfiguration(account, configurationID, skillConfiguration)
    local profile = PlayerProfileManager.getPlayerProfile(account)
    assert(profile, "PlayerProfileManager.setSkillConfiguration() the profile doesn't exist.")

    profile.skillConfigurations[configurationID] = skillConfiguration
    serializeProfile(profile)

    return PlayerProfileManager
end

function PlayerProfileManager.updateProfilesWithBeginningWar(warConfiguration)
    local sceneWarFileName = warConfiguration.sceneWarFileName
    for _, player in pairs(warConfiguration.players) do
        local account = player.account
        local profile = PlayerProfileManager.getPlayerProfile(account)

        profile.warLists.ongoing[sceneWarFileName] = {sceneWarFileName = sceneWarFileName}
        serializeProfile(profile)
    end

    return PlayerProfileManager
end

function PlayerProfileManager.updateProfilesWithModelSceneWar(modelSceneWar)
    local sceneWarFileName   = modelSceneWar:getFileName()
    local modelPlayerManager = modelSceneWar:getModelPlayerManager()
    local gameRecordIndex    = modelPlayerManager:getPlayersCount() * 2 - 3 + (modelSceneWar:isFogOfWarByDefault() and 1 or 0)

    if (modelSceneWar:getRemainingVotesForDraw() == 0) then
        modelPlayerManager:forEachModelPlayer(function(modelPlayer, playerIndex)
            if (modelPlayer:isAlive()) then
                local profile = PlayerProfileManager.getPlayerProfile(modelPlayer:getAccount())
                assert(profile.warLists.ongoing[sceneWarFileName],
                    "PlayerProfileManager.updateProfilesWithModelSceneWar() the war ends in draw, while some alive players are not participating in it.")

                profile.gameRecords[gameRecordIndex].draw  = profile.gameRecords[gameRecordIndex].draw + 1
                profile.warLists.ongoing[sceneWarFileName] = nil
                serializeProfile(profile)
            end
        end)

    else
        local alivePlayersCount  = 0
        local alivePlayerAccount = nil
        modelPlayerManager:forEachModelPlayer(function(modelPlayer, playerIndex)
            local account = modelPlayer:getAccount()
            if (modelPlayer:isAlive()) then
                alivePlayersCount  = alivePlayersCount + 1
                alivePlayerAccount = account
            else
                local profile = PlayerProfileManager.getPlayerProfile(account)
                if (profile.warLists.ongoing[sceneWarFileName]) then
                    profile.gameRecords[gameRecordIndex].lose = profile.gameRecords[gameRecordIndex].lose + 1
                    profile.warLists.ongoing[sceneWarFileName] = nil
                    serializeProfile(profile)
                end
            end
        end)

        if (alivePlayersCount == 1) then
            local profile = PlayerProfileManager.getPlayerProfile(alivePlayerAccount)
            profile.gameRecords[gameRecordIndex].win = profile.gameRecords[gameRecordIndex].win + 1
            profile.warLists.ongoing[sceneWarFileName] = nil
            serializeProfile(profile)
        end
    end

    return PlayerProfileManager
end

return PlayerProfileManager

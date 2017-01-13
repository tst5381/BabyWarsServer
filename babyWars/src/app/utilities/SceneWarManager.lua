
local SceneWarManager = {}

local GameConstantFunctions   = require("src.app.utilities.GameConstantFunctions")
local LocalizationFunctions   = require("src.app.utilities.LocalizationFunctions")
local PlayerProfileManager    = require("src.app.utilities.PlayerProfileManager")
local SerializationFunctions  = require("src.app.utilities.SerializationFunctions")
local SkillDataAccessors      = require("src.app.utilities.SkillDataAccessors")
local Actor                   = require("src.global.actors.Actor")

local ngx                   = ngx
local io, string, pairs, os = io, string, pairs, os

local SCENE_WAR_PATH           = "babyWars\\res\\data\\sceneWar\\"
local JOINABLE_WAR_LIST_PATH   = SCENE_WAR_PATH .. "JoinableList.lua"
local ONGOING_WAR_LIST_PATH    = SCENE_WAR_PATH .. "OngoingWarList.lua"
local REPLAY_LIST_PATH         = SCENE_WAR_PATH .. "ReplayNameList.lua"
local SCENE_WAR_NEXT_NAME_PATH = SCENE_WAR_PATH .. "NextName.lua"

local DEFAULT_EXECUTED_ACTIONS = {}
local DEFAULT_TURN_DATA        = {
    turnIndex     = 1,
    playerIndex   = 1,
    turnPhaseCode = 1,
}
local DISABLED_SKILL_CONFIGURATION = {basePoints = 0}

local s_IsInitialized = false

local s_JoinableWarList
local s_OngoingWarList
local s_ReplayList
local s_SceneWarNextName
local s_ReplayDataList      = {}

--------------------------------------------------------------------------------
-- The util functions.
--------------------------------------------------------------------------------
local function getPlayersCount(warFieldFileName)
    return require("res.data.templateWarField." .. warFieldFileName).playersCount
end

local function isRandomWarField(warFieldFileName)
    return string.find(warFieldFileName, "Random", 1, true) == 1
end

local function pickRandomWarField(warFieldFileName)
    local list = require("res.data.templateWarField." .. warFieldFileName).list
    return list[math.random(#list)]
end

local function toFullFileName(shortName)
    return SCENE_WAR_PATH .. shortName .. ".lua"
end

local function generateReplayConfiguration(warData)
    local players = {}
    for playerIndex, player in pairs(warData.players) do
        players[playerIndex] = {
            account     = player.account,
            nickname    = player.nickname,
        }
    end

    return {
        sceneWarFileName    = warData.sceneWarFileName,
        warFieldFileName    = warData.warField.warFieldFileName,
        players             = players,
    }
end

local function generateWarConfiguration(warData)
    local players = {}
    for playerIndex, player in pairs(warData.players) do
        players[playerIndex] = {
            playerIndex = playerIndex,
            account     = player.account,
            nickname    = player.nickname,
        }
    end

    return {
        createdTime         = warData.createdTime,
        defaultWeatherCode  = warData.weather.defaultWeatherCode,
        intervalUntilBoot   = warData.intervalUntilBoot,
        isFogOfWarByDefault = warData.isFogOfWarByDefault,
        isRandomWarField    = warData.isRandomWarField,
        isRankMatch         = warData.isRankMatch,
        maxBaseSkillPoints  = warData.maxBaseSkillPoints,
        maxDiffScore        = warData.maxDiffScore,
        players             = players,
        sceneWarFileName    = warData.sceneWarFileName,
        warFieldFileName    = warData.warField.warFieldFileName,
        warPassword         = warData.warPassword,
    }
end

local function serializeWarData(warData)
    local file = io.open(toFullFileName(warData.sceneWarFileName), "wb")
    file:write(SerializationFunctions.encode("SceneWar", warData))
    file:close()
end

local function loadWarData(sceneWarFileName)
    local file = io.open(toFullFileName(sceneWarFileName), "rb")
    assert(file, "SceneWarManager-loadWarData() invalid sceneWarFileName: " .. (sceneWarFileName or ""))

    local warData = SerializationFunctions.decode("SceneWar", file:read("*a"))
    file:close()
    return warData
end

local function serializeSceneWarNextName(name)
    local file = io.open(SCENE_WAR_NEXT_NAME_PATH, "w")
    file:write(name)
    file:close()
end

local function loadSceneWarNextName()
    local file = io.open(SCENE_WAR_NEXT_NAME_PATH, "r")
    if (not file) then
        return nil
    else
        local name = file:read("*a")
        file:close()
        return name
    end
end

local function serializeJoinableWarList(list)
    local file = io.open(JOINABLE_WAR_LIST_PATH, "wb")
    file:write(SerializationFunctions.encode("JoinableWarList", {list = list or {}}))
    file:close()
end

local function loadJoinableWarList()
    local file = io.open(JOINABLE_WAR_LIST_PATH, "rb")
    if (not file) then
        return nil
    else
        local list = SerializationFunctions.decode("JoinableWarList", file:read("*a")).list or {}
        file:close()

        for sceneWarFileName, joinableWarItem in pairs(list) do
            local warData                    = loadWarData(sceneWarFileName)
            joinableWarItem.warData          = warData
            joinableWarItem.warConfiguration = generateWarConfiguration(warData)
        end

        return list
    end
end

local function serializeOngoingWarList(list)
    local file = io.open(ONGOING_WAR_LIST_PATH, "wb")
    file:write(SerializationFunctions.encode("OngoingWarListForServer", {list = list or {}}))
    file:close()
end

local function loadOngoingWarList()
    local file = io.open(ONGOING_WAR_LIST_PATH, "rb")
    if (not file) then
        return nil
    else
        local list = SerializationFunctions.decode("OngoingWarListForServer", file:read("*a")).list or {}
        file:close()

        return list
    end
end

local function serializeReplayList(list)
    local file = io.open(REPLAY_LIST_PATH, "wb")
    file:write(SerializationFunctions.encode("ReplayListForServer", {list = list or {}}))
    file:close()
end

local function loadReplayList()
    local file = io.open(REPLAY_LIST_PATH, "rb")
    if (not file) then
        return nil
    else
        local list = SerializationFunctions.decode("ReplayListForServer", file:read("*a")).list or {}
        file:close()

        return list
    end
end

local function loadReplayData(sceneWarFileName)
    local file = io.open(toFullFileName(sceneWarFileName), "rb")
    local data = file:read("*a")
    file:close()
    return data
end

local function getOngoingWarListItem(sceneWarFileName)
    local item = s_OngoingWarList[sceneWarFileName]
    if ((item) and (not item.actorSceneWar)) then
        local warData = loadWarData(item.sceneWarFileName)
        assert(not warData.isEnded, "SceneWarManager-getOngoingWarListItem() the war is ended.")

        item.actorSceneWar    = Actor.createWithModelAndViewName("sceneWar.modelSceneWar", warData)
        item.warConfiguration = generateWarConfiguration(warData)
        item.actorSceneWar:getModel():onStartRunning()
    end

    return item
end

local function getNextName(name)
    local byteList = {}
    local byteNext9, byteNextz = string.byte("9") + 1, string.byte("z") + 1
    local byte0, bytea         = string.byte("0"),     string.byte("a")
    local inc = 1

    for i = #name, 1, -1 do
        byteList[i] = name:byte(i) + inc
        inc = 0
        if (byteList[i] == byteNext9) then
            byteList[i] = bytea
        elseif (byteList[i] == byteNextz) then
            byteList[i] = byte0
            inc = 1
        end
    end

    return string.char(unpack(byteList))
end

local function isWarReadyForStart(warConfiguration)
    local players = warConfiguration.players
    for i = 1, getPlayersCount(warConfiguration.warFieldFileName) do
        if (not players[i]) then
            return false
        end
    end

    return true
end

--------------------------------------------------------------------------------
-- The functions for generating the new game data.
--------------------------------------------------------------------------------
local function generateSinglePlayerData(account, skillConfigurationID, playerIndex)
    local skillConfiguration
    if     (not skillConfigurationID) then skillConfiguration = DISABLED_SKILL_CONFIGURATION
    elseif (skillConfigurationID > 0) then skillConfiguration = PlayerProfileManager.getSkillConfiguration(account, skillConfigurationID)
    else                                   skillConfiguration = SkillDataAccessors.getSkillPresets()[-skillConfigurationID]
    end
    assert(skillConfiguration, "SceneWarManager-generateSinglePlayerData() failed to generate the skill configuration data.")

    return {
        playerIndex         = playerIndex,
        account             = account,
        nickname            = PlayerProfileManager.getPlayerProfile(account).nickname,
        fund                = 0,
        isAlive             = true,
        damageCost          = 0,
        skillActivatedCount = 0,
        skillConfiguration  = skillConfiguration,
    }
end

local function generatePlayersData(playerIndex, account, skillConfigurationID)
    return {
        [playerIndex] = generateSinglePlayerData(account, skillConfigurationID, playerIndex),
    }
end

local function generateSceneWarData(sceneWarFileName, param)
    local warFieldFileName = param.warFieldFileName
    local isRandom         = isRandomWarField(warFieldFileName)
    if (isRandom) then
        warFieldFileName = pickRandomWarField(warFieldFileName)
    end

    return {
        actionID                   = 0,
        createdTime                = ngx.time(),
        intervalUntilBoot          = param.intervalUntilBoot,
        executedActions            = DEFAULT_EXECUTED_ACTIONS,
        isFogOfWarByDefault        = param.isFogOfWarByDefault,
        isRandomWarField           = isRandom,
        isRankMatch                = param.isRankMatch,
        isTotalReplay              = false,
        isWarEnded                 = false,
        maxBaseSkillPoints         = param.maxBaseSkillPoints,
        maxDiffScore               = param.maxDiffScore,
        remainingIntervalUntilBoot = param.intervalUntilBoot,
        sceneWarFileName           = sceneWarFileName,
        warPassword                = param.warPassword,

        warField = {warFieldFileName = warFieldFileName},
        turn     = DEFAULT_TURN_DATA,
        players  = generatePlayersData(param.playerIndex, param.playerAccount, param.skillConfigurationID),
        weather  = {defaultWeatherCode = param.defaultWeatherCode},
    }
end

--------------------------------------------------------------------------------
-- The functions for initialization.
--------------------------------------------------------------------------------
local function initJoinableWarList()
    s_JoinableWarList = loadJoinableWarList()
    if (not s_JoinableWarList) then
        s_JoinableWarList = {}
        serializeJoinableWarList(s_JoinableWarList)
    end
end

local function initOngoingWarList()
    s_OngoingWarList = loadOngoingWarList()
    if (not s_OngoingWarList) then
        s_OngoingWarList = {}
        serializeOngoingWarList(s_OngoingWarList)
    end
end

local function initReplayList()
    s_ReplayList = loadReplayList()
    if (not s_ReplayList) then
        s_ReplayList = {}
        serializeReplayList(s_ReplayList)
    end
end

local function initSceneWarNextName()
    s_SceneWarNextName = loadSceneWarNextName()
    if (not s_SceneWarNextName) then
        s_SceneWarNextName = "0000000000000000"
        serializeSceneWarNextName(s_SceneWarNextName)
    end
end

--------------------------------------------------------------------------------
-- The public functions.
--------------------------------------------------------------------------------
function SceneWarManager.init()
    if (s_IsInitialized) then
        return
    end
    s_IsInitialized = true

    os.execute("mkdir " .. SCENE_WAR_PATH)
    initJoinableWarList()
    initOngoingWarList()
    initReplayList()
    initSceneWarNextName()

    return SceneWarManager
end

function SceneWarManager.createNewWar(param)
    local sceneWarFileName = s_SceneWarNextName
    local warData          = generateSceneWarData(sceneWarFileName, param)
    serializeWarData(warData)

    s_JoinableWarList[sceneWarFileName] = {
        sceneWarFileName = sceneWarFileName,
        warData          = warData,
        warConfiguration = generateWarConfiguration(warData),
    }
    serializeJoinableWarList(s_JoinableWarList)

    s_SceneWarNextName = getNextName(s_SceneWarNextName)
    serializeSceneWarNextName(s_SceneWarNextName)

    PlayerProfileManager.updateProfileOnCreatingWar(param.playerAccount, sceneWarFileName)

    return sceneWarFileName
end

function SceneWarManager.getNextSceneWarFileName()
    return s_SceneWarNextName
end

function SceneWarManager.getOngoingModelSceneWar(sceneWarFileName)
    local ongoingWarListItem = getOngoingWarListItem(sceneWarFileName)
    if (ongoingWarListItem) then
        return ongoingWarListItem.actorSceneWar:getModel()
    else
        return nil
    end
end

function SceneWarManager.getOngoingSceneWarConfiguration(sceneWarFileName)
    return getOngoingWarListItem(sceneWarFileName).warConfiguration
end

function SceneWarManager.forEachOngoingModelSceneWar(callback)
    for sceneWarFileName, _ in pairs(s_OngoingWarList) do
        callback(SceneWarManager.getOngoingModelSceneWar(sceneWarFileName))
    end

    return SceneWarManager
end

function SceneWarManager.getJoinableSceneWarConfiguration(sceneWarFileName)
    if (not s_JoinableWarList[sceneWarFileName]) then
        return nil, "SceneWarManager.getJoinableSceneWarConfiguration() the war that the param specifies doesn't exist or is not joinable."
    end

    return s_JoinableWarList[sceneWarFileName].warConfiguration
end

function SceneWarManager.getJoinableWarConfigurations(playerAccount, sceneWarShortName)
    local candidateWarList
    if (not sceneWarShortName) then
        candidateWarList = s_JoinableWarList
    else
        candidateWarList = {}
        local prefix = "000000000000"
        while (true) do
            local sceneWarFileName = prefix .. sceneWarShortName
            if (s_JoinableWarList[sceneWarFileName]) then
                candidateWarList[sceneWarFileName] = 1
                prefix = getNextName(prefix)
            else
                break
            end
        end
    end

    local list = {}
    for sceneWarFileName, _ in pairs(candidateWarList) do
        local warConfiguration = s_JoinableWarList[sceneWarFileName].warConfiguration
        if (not SceneWarManager.hasPlayerJoinedWar(playerAccount, warConfiguration)) then
            list[sceneWarFileName] = warConfiguration
        end
    end

    -- TODO: Limit the length of the list.

    return list
end

function SceneWarManager.hasPlayerJoinedWar(playerAccount, warConfiguration)
    for _, player in pairs(warConfiguration.players) do
        if (player.account == playerAccount) then
            return true
        end
    end

    return false
end

function SceneWarManager.isWarReadyForStartAfterJoin(warConfiguration)
    local joinedPlayersCount = 0
    for playerIndex, player in pairs(warConfiguration.players) do
        joinedPlayersCount = joinedPlayersCount + 1
    end

    return joinedPlayersCount == getPlayersCount(warConfiguration.warFieldFileName) - 1
end

function SceneWarManager.joinWar(param)
    local sceneWarFileName = param.sceneWarFileName
    local playerIndex      = param.playerIndex
    local playerAccount    = param.playerAccount
    local warConfiguration = SceneWarManager.getJoinableSceneWarConfiguration(sceneWarFileName)

    warConfiguration.players[playerIndex] = {
        account     = playerAccount,
        playerIndex = playerIndex,
        nickname    = PlayerProfileManager.getPlayerProfile(playerAccount).nickname,
    }
    local joiningWarData = s_JoinableWarList[sceneWarFileName].warData
    joiningWarData.players[playerIndex] = generateSinglePlayerData(playerAccount, param.skillConfigurationID, playerIndex)

    PlayerProfileManager.updateProfileOnJoiningWar(playerAccount, sceneWarFileName)

    if (not isWarReadyForStart(warConfiguration)) then
        serializeWarData(joiningWarData)
    else
        PlayerProfileManager.updateProfilesOnBeginningWar(warConfiguration)

        s_JoinableWarList[sceneWarFileName] = nil
        serializeJoinableWarList(s_JoinableWarList)

        joiningWarData.enterTurnTime = ngx.time()
        local modelSceneWar = Actor.createModel("sceneWar.modelSceneWar", joiningWarData)
        modelSceneWar:onStartRunning()
        serializeWarData(modelSceneWar:toSerializableTable())

        s_OngoingWarList[sceneWarFileName] = {
            sceneWarFileName = sceneWarFileName,
            warConfiguration = warConfiguration,
            actorSceneWar    = Actor.createWithModelAndViewInstance(modelSceneWar),
        }
        serializeOngoingWarList(s_OngoingWarList)
    end

    return SceneWarManager
end

function SceneWarManager.getReplayConfigurations(pageIndex)
    -- TODO: limit the length of the list.
    local list = {}
    for sceneWarFileName, listItem in pairs(s_ReplayList) do
        listItem.replayConfiguration = listItem.replayConfiguration or generateReplayConfiguration(loadWarData(sceneWarFileName))
        list[#list + 1] = listItem.replayConfiguration
    end

    return list
end

function SceneWarManager.getEncodedReplayData(sceneWarFileName)
    if (not s_ReplayList[sceneWarFileName]) then
        return nil
    else
        return loadReplayData(sceneWarFileName)
    end
end

function SceneWarManager.updateModelSceneWarWithAction(action)
    local sceneWarFileName = action.sceneWarFileName
    local modelSceneWar    = SceneWarManager.getOngoingModelSceneWar(sceneWarFileName)
    modelSceneWar:executeAction(action)
    PlayerProfileManager.updateProfilesWithModelSceneWar(modelSceneWar)

    if (not modelSceneWar:isEnded()) then
        if (modelSceneWar:getModelTurnManager():isTurnPhaseRequestToBegin()) then
            modelSceneWar:setEnterTurnTime(ngx.time())
        end

        serializeWarData(modelSceneWar:toSerializableTable())
    else
        s_OngoingWarList[sceneWarFileName] = nil
        serializeOngoingWarList(s_OngoingWarList)

        local warData = modelSceneWar:toSerializableReplayData()
        serializeWarData(warData)

        s_ReplayList[sceneWarFileName] = {
            sceneWarFileName    = sceneWarFileName,
            replayConfiguration = generateReplayConfiguration(warData),
        }
        serializeReplayList(s_ReplayList)
    end

    return SceneWarManager
end

return SceneWarManager

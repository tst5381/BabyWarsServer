
local OnlineWarManager = {}

local GameConstantFunctions  = requireFW("src.app.utilities.GameConstantFunctions")
local LocalizationFunctions  = requireFW("src.app.utilities.LocalizationFunctions")
local PlayerProfileManager   = requireFW("src.app.utilities.PlayerProfileManager")
local SerializationFunctions = requireFW("src.app.utilities.SerializationFunctions")
local TableFunctions         = requireFW("src.app.utilities.TableFunctions")
local WarFieldManager        = requireFW("src.app.utilities.WarFieldManager")
local Actor                  = requireFW("src.global.actors.Actor")

local ngx, io, math, os, string, table = ngx, io, math, os, string, table
local pairs, ipairs                    = pairs, ipairs

local SCENE_WAR_PATH           = "FreeWarsServer\\userdata\\wars\\"
local JOINABLE_WAR_LIST_PATH   = SCENE_WAR_PATH .. "JoinableWarList.spdata"
local ONGOING_WAR_LIST_PATH    = SCENE_WAR_PATH .. "OngoingWarList.spdata"
local REPLAY_LIST_PATH         = SCENE_WAR_PATH .. "ReplayList.spdata"
local SCENE_WAR_NEXT_NAME_PATH = SCENE_WAR_PATH .. "NextWarID.spdata"

local REPLAY_RECENT_LIST_CAPACITY = 30
local DEFAULT_TURN_DATA           = {
    turnIndex     = 1,
    playerIndex   = 1,
    turnPhaseCode = 1,
}

local s_IsInitialized = false

local s_NextWarID
local s_JoinableWarList
local s_OngoingWarList
local s_ReplayList

--------------------------------------------------------------------------------
-- The util functions.
--------------------------------------------------------------------------------
local function getWarFileName(warID)
    return SCENE_WAR_PATH .. warID .. ".spdata"
end

local function isWarReadyForStart(warConfiguration)
    local players = warConfiguration.players
    for i = 1, WarFieldManager.getPlayersCount(warConfiguration.warFieldFileName) do
        if (not players[i]) then
            return false
        end
    end

    return true
end

local function removePlayerFromPlayersData(playersData, playerAccount)
    for playerIndex, player in pairs(playersData) do
        if (player.account == playerAccount) then
            playersData[playerIndex] = nil
            return
        end
    end

    error("OnlineWarManager-removePlayerFromPlayersData() failed to find the player data with account: " .. (playerAccount or ""))
end

local function getJoinedPlayersCount(warConfiguration)
    local count = 0
    for playerIndex, _ in pairs(warConfiguration.players) do
        count = count + 1
    end

    return count
end

--------------------------------------------------------------------------------
-- The functions for generating the new game data.
--------------------------------------------------------------------------------
local function generateSinglePlayerData(account, playerIndex, teamIndex, startingEnergy, startingFund)
    return {
        account           = account,
        energy            = startingEnergy,
        fund              = startingFund,
        isActivatingSkill = false,
        isAlive           = true,
        nickname          = PlayerProfileManager.getPlayerProfile(account).nickname,
        playerIndex       = playerIndex,
        teamIndex         = teamIndex,
    }
end

local function generateSceneWarData(warID, param)
    local playerIndex      = param.playerIndex
    local warFieldFileName = param.warFieldFileName
    return {
        actionID                  = 0,
        attackModifier            = param.attackModifier,
        createdTime               = ngx.time(),
        energyGainModifier        = param.energyGainModifier,
        executedActions           = {},
        incomeModifier            = param.incomeModifier,
        intervalUntilBoot         = param.intervalUntilBoot,
        isActiveSkillEnabled      = param.isActiveSkillEnabled,
        isFogOfWarByDefault       = param.isFogOfWarByDefault,
        isPassiveSkillEnabled     = param.isPassiveSkillEnabled,
        isRandomWarField          = WarFieldManager.isRandomWarField(warFieldFileName),
        isRankMatch               = param.isRankMatch,
        isTotalReplay             = false,
        isWarEnded                = false,
        maxDiffScore              = param.maxDiffScore,
        moveRangeModifier         = param.moveRangeModifier,
        startingEnergy            = param.startingEnergy,
        startingFund              = param.startingFund,
        visionModifier            = param.visionModifier,
        warID                     = warID,
        warPassword               = param.warPassword,

        players  = {[playerIndex] = generateSinglePlayerData(param.playerAccount, playerIndex, param.teamIndex, param.startingEnergy, param.startingFund)},
        turn     = TableFunctions.clone(DEFAULT_TURN_DATA),
        warField = {warFieldFileName = warFieldFileName},
        weather  = {defaultWeatherCode = param.defaultWeatherCode},
    }
end

local function generateReplayConfiguration(warData)
    local players = {}
    for playerIndex, player in pairs(warData.players) do
        players[playerIndex] = {
            teamIndex = player.teamIndex,
            account   = player.account,
            nickname  = player.nickname,
        }
    end

    return {
        actionsCount     = #warData.executedActions,
        warID            = warData.warID,
        warFieldFileName = warData.warField.warFieldFileName,
        players          = players,
    }
end

local function generateWarConfiguration(warData)
    local players = {}
    for playerIndex, player in pairs(warData.players) do
        players[playerIndex] = {
            playerIndex = playerIndex,
            teamIndex   = player.teamIndex,
            account     = player.account,
            nickname    = player.nickname,
        }
    end

    return {
        attackModifier            = warData.attackModifier,
        createdTime               = warData.createdTime,
        defaultWeatherCode        = warData.weather.defaultWeatherCode,
        energyGainModifier        = warData.energyGainModifier,
        enterTurnTime             = warData.enterTurnTime,
        incomeModifier            = warData.incomeModifier,
        intervalUntilBoot         = warData.intervalUntilBoot,
        isActiveSkillEnabled      = warData.isActiveSkillEnabled,
        isFogOfWarByDefault       = warData.isFogOfWarByDefault,
        isPassiveSkillEnabled     = warData.isPassiveSkillEnabled,
        isRandomWarField          = warData.isRandomWarField,
        isRankMatch               = warData.isRankMatch,
        maxDiffScore              = warData.maxDiffScore,
        moveRangeModifier         = warData.moveRangeModifier,
        playerIndexInTurn         = (warData.enterTurnTime) and (warData.turn.playerIndex) or (nil),
        players                   = players,
        startingEnergy            = warData.startingEnergy,
        startingFund              = warData.startingFund,
        visionModifier            = warData.visionModifier,
        warFieldFileName          = warData.warField.warFieldFileName,
        warID                     = warData.warID,
        warPassword               = warData.warPassword,
    }
end

--------------------------------------------------------------------------------
-- The functions for serializing/load data.
--------------------------------------------------------------------------------
local function serializeWarData(warData)
    local file = io.open(getWarFileName(warData.warID), "wb")
    file:write(SerializationFunctions.encode("SceneWar", warData))
    file:close()
end

local function loadWarData(warID)
    local file = io.open(getWarFileName(warID), "rb")
    assert(file, "OnlineWarManager-loadWarData() invalid warID: " .. (warID or ""))

    local warData = SerializationFunctions.decode("SceneWar", file:read("*a"))
    warData.attackModifier    = warData.attackModifier    or 0
    warData.incomeModifier    = warData.incomeModifier    or 100
    warData.moveRangeModifier = warData.moveRangeModifier or 0
    warData.visionModifier    = warData.visionModifier    or 0
    for playerIndex, playerData in pairs(warData.players) do
        playerData.teamIndex = playerData.teamIndex or playerIndex
    end

    file:close()
    return warData
end

local function serializeNextWarId(warID)
    local file = io.open(SCENE_WAR_NEXT_NAME_PATH, "wb")
    file:write(SerializationFunctions.encode("WarIdForIndexing", {warID = warID}))
    file:close()
end

local function loadNextWarId()
    local file = io.open(SCENE_WAR_NEXT_NAME_PATH, "rb")
    if (not file) then
        return nil
    else
        local warID = SerializationFunctions.decode("WarIdForIndexing", file:read("*a")).warID
        file:close()
        return warID
    end
end

local function serializeJoinableWarList(list)
    local file = io.open(JOINABLE_WAR_LIST_PATH, "wb")
    file:write(SerializationFunctions.encode("JoinableWarList", {list = list}))
    file:close()
end

local function loadJoinableWarList()
    local file = io.open(JOINABLE_WAR_LIST_PATH, "rb")
    if (not file) then
        return nil
    else
        local list = SerializationFunctions.decode("JoinableWarList", file:read("*a")).list
        file:close()

        for warID, joinableWarItem in pairs(list) do
            local warData                    = loadWarData(warID)
            joinableWarItem.warData          = warData
            joinableWarItem.warConfiguration = generateWarConfiguration(warData)
        end

        return list
    end
end

local function serializeOngoingWarList(list)
    local file = io.open(ONGOING_WAR_LIST_PATH, "wb")
    file:write(SerializationFunctions.encode("OngoingWarListForServer", {list = list}))
    file:close()
end

local function loadOngoingWarList()
    local file = io.open(ONGOING_WAR_LIST_PATH, "rb")
    if (not file) then
        return nil
    else
        local list = SerializationFunctions.decode("OngoingWarListForServer", file:read("*a")).list
        file:close()

        for warID, item in pairs(list) do
            local warData       = loadWarData(warID)
            assert(not warData.isEnded, "OnlineWarManager-loadOngoingWarList() the war is ended.")
            local modelSceneWar = Actor.createModel("warOnline.ModelWarOnline", warData)
            modelSceneWar:onStartRunning()

            item.actorSceneWar    = Actor.createWithModelAndViewInstance(modelSceneWar)
            item.warConfiguration = generateWarConfiguration(warData)
        end

        return list
    end
end

local function serializeReplayList(list)
    local file = io.open(REPLAY_LIST_PATH, "wb")
    file:write(SerializationFunctions.encode("ReplayListForServer", list))
    file:close()
end

local function loadReplayList()
    local file = io.open(REPLAY_LIST_PATH, "rb")
    if (not file) then
        return nil
    else
        local list = SerializationFunctions.decode("ReplayListForServer", file:read("*a"))
        file:close()
        return list
    end
end

local function loadReplayData(warID)
    local file = io.open(getWarFileName(warID), "rb")
    local data = file:read("*a")
    file:close()
    return data
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
        s_ReplayList = {
            fullList   = {},
            recentList = {},
        }
        serializeReplayList(s_ReplayList)
    end
end

local function initNextWarId()
    s_NextWarID = loadNextWarId()
    if (not s_NextWarID) then
        s_NextWarID = 1
        serializeNextWarId(s_NextWarID)
    end
end

--------------------------------------------------------------------------------
-- The public functions.
--------------------------------------------------------------------------------
function OnlineWarManager.init()
    if (s_IsInitialized) then
        return
    end
    s_IsInitialized = true

    os.execute("mkdir " .. SCENE_WAR_PATH)
    initJoinableWarList()
    initOngoingWarList()
    initReplayList()
    initNextWarId()

    return OnlineWarManager
end

function OnlineWarManager.createNewWar(param)
    local warID   = s_NextWarID
    local warData = generateSceneWarData(warID, param)
    serializeWarData(warData)

    s_JoinableWarList[warID] = {
        warID            = warID,
        warData          = warData,
        warConfiguration = generateWarConfiguration(warData),
    }
    serializeJoinableWarList(s_JoinableWarList)

    s_NextWarID = s_NextWarID + 1
    serializeNextWarId(s_NextWarID)

    PlayerProfileManager.updateProfileOnCreatingWar(param.playerAccount, warID)

    return warID
end

function OnlineWarManager.getNextWarId()
    return s_NextWarID
end

function OnlineWarManager.getOngoingModelSceneWar(warID)
    local item = s_OngoingWarList[warID]
    if (not item) then
        return nil
    else
        return item.actorSceneWar:getModel()
    end
end

function OnlineWarManager.getOngoingSceneWarConfiguration(warID)
    return s_OngoingWarList[warID].warConfiguration
end

function OnlineWarManager.getOngoingWarConfigurationsForPlayer(playerAccount)
    local list = {}
    for warID, _ in pairs(PlayerProfileManager.getPlayerProfile(playerAccount).warLists.ongoing) do
        list[warID] = OnlineWarManager.getOngoingSceneWarConfiguration(warID)
    end

    return list
end

function OnlineWarManager.getWaitingWarConfigurationsForPlayer(playerAccount)
    local list = {}
    for warID, _ in pairs(PlayerProfileManager.getPlayerProfile(playerAccount).warLists.waiting) do
        list[warID] = s_JoinableWarList[warID].warConfiguration
    end

    return list
end

function OnlineWarManager.isPlayerWaitingForWarId(playerAccount, warID)
    return PlayerProfileManager.getPlayerProfile(playerAccount).warLists.waiting[warID] ~= nil
end

function OnlineWarManager.exitWar(playerAccount, warID)
    local warItem = s_JoinableWarList[warID]
    removePlayerFromPlayersData(warItem.warData.players, playerAccount)
    serializeWarData(warItem.warData)

    PlayerProfileManager.updateProfileOnExitWar(playerAccount, warID)

    local warConfiguration = warItem.warConfiguration
    removePlayerFromPlayersData(warConfiguration.players, playerAccount)
    if (getJoinedPlayersCount(warConfiguration) == 0) then
        s_JoinableWarList[warID] = nil
        serializeJoinableWarList(s_JoinableWarList)
    end

    return self
end

function OnlineWarManager.forEachOngoingModelSceneWar(callback)
    for warID, _ in pairs(s_OngoingWarList) do
        callback(OnlineWarManager.getOngoingModelSceneWar(warID))
    end

    return OnlineWarManager
end

function OnlineWarManager.getJoinableSceneWarConfiguration(warID)
    if (not s_JoinableWarList[warID]) then
        return nil, "OnlineWarManager.getJoinableSceneWarConfiguration() the war that the param specifies doesn't exist or is not joinable."
    end

    return s_JoinableWarList[warID].warConfiguration
end

function OnlineWarManager.getJoinableWarConfigurations(playerAccount, specifiedWarID)
    if (not specifiedWarID) then
        local list = {}
        for warID, item in pairs(s_JoinableWarList) do
            local warConfiguration = item.warConfiguration
            if (not OnlineWarManager.hasPlayerJoinedWar(playerAccount, warConfiguration)) then
                list[warID] = item.warConfiguration
            end
        end
        return list

    elseif (s_JoinableWarList[specifiedWarID]) then
        local warConfiguration = s_JoinableWarList[specifiedWarID].warConfiguration
        if (not OnlineWarManager.hasPlayerJoinedWar(playerAccount, warConfiguration)) then
            return {warID = warConfiguration}
        end
    end

    return nil
end

function OnlineWarManager.hasPlayerJoinedWar(playerAccount, warConfiguration)
    for _, player in pairs(warConfiguration.players) do
        if (player.account == playerAccount) then
            return true
        end
    end

    return false
end

function OnlineWarManager.isWarReadyForStartAfterJoin(warConfiguration)
    local joinedPlayersCount = 0
    for playerIndex, player in pairs(warConfiguration.players) do
        joinedPlayersCount = joinedPlayersCount + 1
    end

    return joinedPlayersCount == WarFieldManager.getPlayersCount(warConfiguration.warFieldFileName) - 1
end

function OnlineWarManager.joinWar(param)
    local warID            = param.warID
    local playerIndex      = param.playerIndex
    local playerAccount    = param.playerAccount
    local warConfiguration = OnlineWarManager.getJoinableSceneWarConfiguration(warID)

    warConfiguration.players[playerIndex] = {
        account     = playerAccount,
        nickname    = PlayerProfileManager.getPlayerProfile(playerAccount).nickname,
        playerIndex = playerIndex,
        teamIndex   = param.teamIndex,
    }
    local joiningWarData = s_JoinableWarList[warID].warData
    joiningWarData.players[playerIndex] = generateSinglePlayerData(playerAccount, playerIndex, param.teamIndex, joiningWarData.startingEnergy, joiningWarData.startingFund)

    PlayerProfileManager.updateProfileOnJoiningWar(playerAccount, warID)

    if (not isWarReadyForStart(warConfiguration)) then
        serializeWarData(joiningWarData)
    else
        PlayerProfileManager.updateProfilesOnBeginningWar(warConfiguration)

        s_JoinableWarList[warID] = nil
        serializeJoinableWarList(s_JoinableWarList)

        warConfiguration.playerIndexInTurn = 1
        warConfiguration.enterTurnTime     = ngx.time()
        joiningWarData  .enterTurnTime     = warConfiguration.enterTurnTime

        if (joiningWarData.isRandomWarField) then
            warConfiguration.warFieldFileName        = WarFieldManager.getRandomWarFieldFilename(joiningWarData.warField.warFieldFileName)
            joiningWarData.warField.warFieldFileName = warConfiguration.warFieldFileName
        end

        local modelSceneWar = Actor.createModel("warOnline.ModelWarOnline", joiningWarData)
        modelSceneWar:onStartRunning()
        serializeWarData(modelSceneWar:toSerializableTable())

        s_OngoingWarList[warID] = {
            warID            = warID,
            warConfiguration = warConfiguration,
            actorSceneWar    = Actor.createWithModelAndViewInstance(modelSceneWar),
        }
        serializeOngoingWarList(s_OngoingWarList)
    end

    return OnlineWarManager
end

function OnlineWarManager.getReplayConfigurations(warID)
    if (warID) then
        local item = s_ReplayList.fullList[warID]
        if (not item) then
            return nil
        else
            item.replayConfiguration = item.replayConfiguration or generateReplayConfiguration(loadWarData(warID))
            return {[warID] = item.replayConfiguration}
        end
    else
        local list = {}
        for _, warID in ipairs(s_ReplayList.recentList) do
            local item = s_ReplayList.fullList[warID]
            item.replayConfiguration = item.replayConfiguration or generateReplayConfiguration(loadWarData(warID))
            list[warID] = item.replayConfiguration
        end

        return list
    end
end

function OnlineWarManager.getEncodedReplayData(warID)
    if (not s_ReplayList.fullList[warID]) then
        return nil
    else
        return loadReplayData(warID)
    end
end

function OnlineWarManager.updateWithModelWarOnline(modelWarOnline)
    local warID = modelWarOnline:getWarId()
    if (not modelWarOnline:isEnded()) then
        if (modelWarOnline:getModelTurnManager():isTurnPhaseRequestToBegin()) then
            local warConfiguration = OnlineWarManager.getOngoingSceneWarConfiguration(warID)
            warConfiguration.enterTurnTime     = modelWarOnline:getEnterTurnTime()
            warConfiguration.playerIndexInTurn = modelWarOnline:getModelTurnManager():getPlayerIndex()
        end

        serializeWarData(modelWarOnline:toSerializableTable())
    else
        s_OngoingWarList[warID] = nil
        serializeOngoingWarList(s_OngoingWarList)

        local warData = modelWarOnline:toSerializableReplayData()
        serializeWarData(warData)

        local recentList = s_ReplayList.recentList
        recentList[#recentList + 1] = warID
        if (#recentList > REPLAY_RECENT_LIST_CAPACITY) then
            table.remove(recentList, 1)
        end
        s_ReplayList.fullList[warID] = {
            warID               = warID,
            replayConfiguration = generateReplayConfiguration(warData),
        }
        serializeReplayList(s_ReplayList)
    end

    return OnlineWarManager
end

return OnlineWarManager


local SceneWarManager = {}

local ModelSkillConfiguration = require("src.app.models.common.ModelSkillConfiguration")
local SerializationFunctions  = require("src.app.utilities.SerializationFunctions")
local PlayerProfileManager    = require("src.app.utilities.PlayerProfileManager")
local LocalizationFunctions   = require("src.app.utilities.LocalizationFunctions")
local Actor                   = require("src.global.actors.Actor")

local SCENE_WAR_PATH               = "babyWars\\res\\data\\sceneWar\\"
local SCENE_WAR_NEXT_NAME_PATH     = SCENE_WAR_PATH .. "NextName.lua"
local SCENE_WAR_JOINABLE_LIST_PATH = SCENE_WAR_PATH .. "JoinableList.lua"

local DEFAULT_TURN_DATA = {
    turnIndex   = 1,
    playerIndex = 1,
    phase       = "requestToBegin",
}

local s_IsInitialized = false

local s_SceneWarNextName
local s_JoinableWarNameList
local s_JoinableWarList = {}
local s_OngoingWarList  = {}

--------------------------------------------------------------------------------
-- The util functions.
--------------------------------------------------------------------------------
local function getPlayersCount(warFieldFileName)
    return require("res.data.templateWarField." .. warFieldFileName).playersCount
end

local function serialize(fullFileName, data)
    local file = io.open(fullFileName, "w")
    file:write("return ")
    SerializationFunctions.appendToFile(data, "", file)
    file:close()
end

local function toFullFileName(shortName)
    return SCENE_WAR_PATH .. shortName .. ".lua"
end

local function createActorSceneWar(warData)
    local modelSceneWar = Actor.createModel("sceneWar.ModelSceneWar", warData)
    return Actor.createWithModelAndViewInstance(modelSceneWar)
end

local function generateWarConfiguration(warData)
    local players = {}
    for playerIndex, player in pairs(warData.players) do
        players[playerIndex] = {
            account  = player.account,
            nickname = player.nickname,
        }
    end

    return {
        warFieldFileName = warData.warField.tileMap.template,
        warPassword      = warData.warPassword,
        maxSkillPoints   = warData.maxSkillPoints,
        players          = players,

        -- TODO: add code to generate the real configuration of the weather/fog.
        fog              = false,
        weather          = "Clear",
    }
end

local function loadOngoingWar(sceneWarFileName)
    local warData = dofile(toFullFileName(sceneWarFileName))
    if (warData.isEnded) then
        return nil, "SceneWarManager.loadOngoingWar() the war specified by the param is ended."
    end

    return {
        actorSceneWar = createActorSceneWar(warData),
        configuration = generateWarConfiguration(warData),
    }
end

local function getOngoingWarListItem(sceneWarFileName)
    if (not s_OngoingWarList[sceneWarFileName]) then
        local item, err = loadOngoingWar(sceneWarFileName)
        if (not item) then
            return nil, err
        end

        s_OngoingWarList[sceneWarFileName] = item
        item.actorSceneWar:getModel():onStartRunning()
    end

    return s_OngoingWarList[sceneWarFileName]
end

local function removeOngoingWarListItem(sceneWarFileName)
    s_OngoingWarList[sceneWarFileName] = nil
end

local function loadJoinableWar(sceneWarFileName)
    local warData = dofile(toFullFileName(sceneWarFileName))
    return {
        warData       = warData,
        configuration = generateWarConfiguration(warData),
    }
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

local function hasPlayerJoinedWar(playerAccount, configuration)
    for _, player in pairs(configuration.players) do
        if (player.account == playerAccount) then
            return true
        end
    end

    return false
end

local function isWarReadyForStart(configuration)
    local players = configuration.players
    for i = 1, getPlayersCount(configuration.warFieldFileName) do
        if (not players[i]) then
            return false
        end
    end

    return true
end

--------------------------------------------------------------------------------
-- The functions for generating the new game data.
--------------------------------------------------------------------------------
local function generateWarFieldData(warFieldFileName)
    return {
        tileMap = {
            template = warFieldFileName,
        },
        unitMap = {
            template = warFieldFileName,
        },
    }
end

local function generateWeatherData(defaultWeather, isRandom)
    -- TODO: add code to do the real job.
    return {
        current = "Clear",
    }
end

local function generateSinglePlayerData(account, skillConfigurationID)
    return {
        account             = account,
        nickname            = PlayerProfileManager.getPlayerProfile(account).nickname,
        fund                = 0,
        isAlive             = true,
        damageCost          = 0,
        skillActivatedCount = 0,
        skillConfiguration  = (skillConfigurationID == 0) and
            ({maxPoints = 0})                             or
            ModelSkillConfiguration:create(PlayerProfileManager.getSkillConfiguration(account, skillConfigurationID)):toSerializableTable(),
    }
end

local function generatePlayersData(playerIndex, account, skillConfigurationID)
    return {
        [playerIndex] = generateSinglePlayerData(account, skillConfigurationID),
    }
end

local function generateSceneWarData(fileName, param)
    return {
        fileName       = fileName,
        warPassword    = param.warPassword,
        maxSkillPoints = param.maxSkillPoints,
        isEnded        = false,
        actionID       = 0,

        warField       = generateWarFieldData(param.warFieldFileName),
        turn           = DEFAULT_TURN_DATA,
        players        = generatePlayersData(param.playerIndex, param.playerAccount, param.skillConfigurationID),
        weather        = generateWeatherData(),
    }, toFullFileName(fileName)
end

--------------------------------------------------------------------------------
-- The functions for initialization.
--------------------------------------------------------------------------------
local function initSceneWarNextName()
    local file = io.open(SCENE_WAR_NEXT_NAME_PATH, "r")
    if (file) then
        file:close()
        s_SceneWarNextName = dofile(SCENE_WAR_NEXT_NAME_PATH)
    else
        s_SceneWarNextName = "0000000000000000"
        serialize(SCENE_WAR_NEXT_NAME_PATH, s_SceneWarNextName)
    end
end

local function initJoinableWarNameList()
    local file = io.open(SCENE_WAR_JOINABLE_LIST_PATH)
    if (file) then
        file:close()
        s_JoinableWarNameList = dofile(SCENE_WAR_JOINABLE_LIST_PATH)
    else
        s_JoinableWarNameList = {}
        serialize(SCENE_WAR_JOINABLE_LIST_PATH, s_JoinableWarNameList)
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
    initSceneWarNextName()
    initJoinableWarNameList()

    return SceneWarManager
end

function SceneWarManager.createNewWar(param)
    local sceneWarFileName      = s_SceneWarNextName
    local warData, fullFileName = generateSceneWarData(sceneWarFileName, param)
    if (not warData) then
        return nil, "SceneWarManager.createNewWar() failed because some param is invalid."
    end

    s_JoinableWarNameList[sceneWarFileName] = 1
    s_JoinableWarList[sceneWarFileName] = {
        configuration = generateWarConfiguration(warData),
        warData       = warData,
    }
    s_SceneWarNextName = getNextName(s_SceneWarNextName)
    serialize(SCENE_WAR_JOINABLE_LIST_PATH, s_JoinableWarNameList)
    serialize(fullFileName, warData)
    serialize(SCENE_WAR_NEXT_NAME_PATH, s_SceneWarNextName)

    return sceneWarFileName
end

function SceneWarManager.getOngoingModelSceneWar(sceneWarFileName)
    return getOngoingWarListItem(sceneWarFileName).actorSceneWar:getModel()
end

function SceneWarManager.getOngoingSceneWarData(sceneWarFileName)
    local item = getOngoingWarListItem(sceneWarFileName)
    if (not item) then
        return nil, "SceneWarManager.getOngoingSceneWarData() the war is invalid or ended."
    end

    return item.actorSceneWar:getModel():toSerializableTable()
end

function SceneWarManager.getOngoingSceneWarConfiguration(sceneWarFileName)
    return getOngoingWarListItem(sceneWarFileName).configuration
end

function SceneWarManager.getJoinableSceneWarList(playerAccount, sceneWarShortName)
    local candidateWarNameList
    if (not sceneWarShortName) then
        candidateWarNameList = s_JoinableWarNameList
    else
        candidateWarNameList = {}
        local prefix = "000000000000"
        while (true) do
            local sceneWarFileName = prefix .. sceneWarShortName
            if (s_JoinableWarNameList[sceneWarFileName]) then
                candidateWarNameList[sceneWarFileName] = 1
                prefix = getNextName(prefix)
            else
                break
            end
        end
    end

    local list = {}
    for sceneWarFileName, _ in pairs(candidateWarNameList) do
        if (not s_JoinableWarList[sceneWarFileName]) then
            s_JoinableWarList[sceneWarFileName] = loadJoinableWar(sceneWarFileName)
        end

        local configuration = s_JoinableWarList[sceneWarFileName].configuration
        if (not hasPlayerJoinedWar(playerAccount, configuration)) then
            list[sceneWarFileName] = configuration
        end
    end

    -- TODO: Rendomize the items and limit the length of the list.

    return list
end

function SceneWarManager.getJoinableSceneWarConfiguration(sceneWarFileName)
    if (not s_JoinableWarNameList[sceneWarFileName]) then
        return nil, "SceneWarManager.getJoinableSceneWarConfiguration() the war that the param specifies doesn't exist or is not joinable."
    end
    if (not s_JoinableWarList[sceneWarFileName]) then
        s_JoinableWarList[sceneWarFileName] = loadJoinableWar(sceneWarFileName)
    end

    return s_JoinableWarList[sceneWarFileName].configuration
end

function SceneWarManager.joinWar(param)
    local sceneWarFileName = param.sceneWarFileName
    local playerIndex      = param.playerIndex
    local playerAccount    = param.playerAccount
    local configuration    = SceneWarManager.getJoinableSceneWarConfiguration(sceneWarFileName)

    if (not configuration) then
        return nil, "SceneWarManager.joinWar() the war that the param specifies doesn't exist or is not joinable."
    elseif (hasPlayerJoinedWar(playerAccount, configuration)) then
        return nil, "SceneWarManager.joinWar() the player has already joined the war."
    elseif (configuration.players[playerIndex]) then
        return nil, "SceneWarManager.joinWar() the specified player index is already used by another player."
    elseif (configuration.warPassword ~= param.warPassword) then
        return nil, "The password is incorrect."
    end

    configuration.players[playerIndex] = {
        account  = playerAccount,
        nickname = PlayerProfileManager.getPlayerProfile(playerAccount).nickname,
    }
    local joiningSceneWar = s_JoinableWarList[sceneWarFileName].warData
    joiningSceneWar.players[playerIndex] = generateSinglePlayerData(playerAccount, param.skillConfigurationID)
    serialize(toFullFileName(sceneWarFileName), joiningSceneWar)

    if (not isWarReadyForStart(configuration)) then
        return LocalizationFunctions.getLocalizedText(55)
    else
        PlayerProfileManager.updateProfilesWithBeginningWar(sceneWarFileName, configuration)

        s_JoinableWarList[sceneWarFileName]     = nil
        s_JoinableWarNameList[sceneWarFileName] = nil
        serialize(SCENE_WAR_JOINABLE_LIST_PATH, s_JoinableWarNameList)

        return LocalizationFunctions.getLocalizedText(56, sceneWarFileName:sub(13))
    end
end

function SceneWarManager.updateModelSceneWarWithAction(action)
    local sceneWarFileName = action.fileName
    local modelSceneWar    = SceneWarManager.getOngoingModelSceneWar(sceneWarFileName)
    assert(modelSceneWar, "SceneWarManager.updateModelSceneWarWithAction() the param sceneWarFileName is invalid:" .. (sceneWarFileName or ""))

    local cloneAction = {}
    for k, v in pairs(action) do
        cloneAction[k] = v
    end

    serialize(toFullFileName(sceneWarFileName), modelSceneWar:doSystemAction(cloneAction):toSerializableTable())
    PlayerProfileManager.updateProfilesWithModelSceneWar(modelSceneWar)

    if (modelSceneWar:isEnded()) then
        removeOngoingWarListItem(sceneWarFileName)
    end

    return SceneWarManager
end

function SceneWarManager.isPlayerInTurn(sceneWarFileName, playerAccount)
    local modelSceneWar = SceneWarManager.getOngoingModelSceneWar(sceneWarFileName)
    if (not modelSceneWar) then
        return false
    else
        local playerIndex = modelSceneWar:getModelTurnManager():getPlayerIndex()
        return modelSceneWar:getModelPlayerManager():getModelPlayer(playerIndex):getAccount() == playerAccount
    end
end

return SceneWarManager

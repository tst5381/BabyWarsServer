
local SceneWarManager = {}

local Actor                  = require("babyWars.src.global.actors.Actor")
local SerializationFunctions = require("babyWars.src.app.utilities.SerializationFunctions")
local PlayerProfileManager   = require("babyWars.src.app.utilities.PlayerProfileManager")

local SCENE_WAR_PATH               = "babyWars/res/data/sceneWar/"
local SCENE_WAR_NEXT_NAME_PATH     = SCENE_WAR_PATH .. "NextName.lua"
local SCENE_WAR_JOINABLE_LIST_PATH = SCENE_WAR_PATH .. "JoinableList.lua"

local s_IsInitialized = false

local s_SceneWarNextName
local s_JoinableWarNameList
local s_JoinableWarList = {}
local s_OngoingWarList  = {}

--------------------------------------------------------------------------------
-- The util functions.
--------------------------------------------------------------------------------
local function getPlayersCount(warFieldFileName)
    return require("babyWars.res.data.templateWarField." .. warFieldFileName).playersCount
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
    modelSceneWar:onStartRunning()
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
        players          = players,
        -- TODO: add code to generate the real configuration of the weather/fog/max skill points.
        fog              = "off",
        weather          = "clear",
        maxSkillPoints   = "Unavailable",
    }
end

local function loadOngoingWar(sceneWarFileName)
    local fullFileName = toFullFileName(sceneWarFileName)
    local warData = dofile(fullFileName)

    return {
        fullFileName  = fullFileName,
        actorSceneWar = createActorSceneWar(warData),
        configuration = generateWarConfiguration(warData),
    }
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

local function generateTurnData()
    return {
        turnIndex   = 1,
        playerIndex = 1,
        phase       = "requestToBegin",
    }
end

local function generateWeatherData(defaultWeather, isRandom)
    -- TODO: add code to do the real job.
    return {
        current = "clear",
    }
end

local function generateSinglePlayerData(account, skillIndex)
    local playerProfile = PlayerProfileManager.getPlayerProfile(account)
    return {
        account       = account,
        nickname      = playerProfile.nickname,
        fund          = 0,
        isAlive       = true,
        currentEnergy = 0,
        -- TODO: load the skill configuration.
        passiveSkill = {

        },
        activeSkill1 = {
            energyRequirement = 3,
        },
        activeSkill2 = {
            energyRequirement = 6,
        },
    }
end

local function generatePlayersData(playerIndex, account, skillIndex)
    return {
        [playerIndex] = generateSinglePlayerData(account, skillIndex),
    }
end

local function generateSceneWarData(fileName, param)
    -- TODO:validate the params.
    return {
        fileName    = fileName,
        warPassword = param.warPassword,
        warField    = generateWarFieldData(param.warFieldFileName),
        turn        = generateTurnData(),
        players     = generatePlayersData(param.playerIndex, param.playerAccount, param.skillIndex),
        weather     = generateWeatherData(),
    }, toFullFileName(fileName)
end

--------------------------------------------------------------------------------
-- The public functions.
--------------------------------------------------------------------------------
function SceneWarManager.init()
    if (s_IsInitialized) then
        return
    end
    s_IsInitialized = true

    s_SceneWarNextName    = dofile(SCENE_WAR_NEXT_NAME_PATH)
    s_JoinableWarNameList = dofile(SCENE_WAR_JOINABLE_LIST_PATH)

    return SceneWarManager
end

function SceneWarManager.createNewWar(param)
    local sceneWarFileName = s_SceneWarNextName
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
    if (not sceneWarFileName) then
        return nil
    else
        if (s_OngoingWarList[sceneWarFileName] == nil) then
            s_OngoingWarList[sceneWarFileName] = loadOngoingWar(sceneWarFileName)
        end

        return s_OngoingWarList[sceneWarFileName].actorSceneWar:getModel()
    end
end

function SceneWarManager.getOngoingSceneWarData(fileName)
    assert(type(fileName) == "string", "SceneWarManager.getOngoingSceneWarData() the param fileName is invalid.")

    local modelSceneWar = SceneWarManager.getOngoingModelSceneWar(fileName)
    return (modelSceneWar) and (modelSceneWar:toSerializableTable()) or nil
end

function SceneWarManager.getOngoingSceneWarConfiguration(sceneWarFileName)
    if (not sceneWarFileName) then
        return nil
    else
        if (s_OngoingWarList[sceneWarFileName] == nil) then
            s_OngoingWarList[sceneWarFileName] = loadOngoingWar(sceneWarFileName)
        end

        return s_OngoingWarList[sceneWarFileName].configuration
    end
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

function SceneWarManager.joinWar(param)
    local sceneWarFileName = param.sceneWarFileName
    if (not s_JoinableWarNameList[sceneWarFileName]) then
        return nil, "SceneWarManager.joinWar() the war that the param specifies doesn't exist or is not joinable."
    end
    if (not s_JoinableWarList[sceneWarFileName]) then
        s_JoinableWarList[sceneWarFileName] = loadJoinableWar(sceneWarFileName)
    end

    local playerIndex   = param.playerIndex
    local playerAccount = param.playerAccount
    local configuration = s_JoinableWarList[sceneWarFileName].configuration
    if (hasPlayerJoinedWar(playerAccount, configuration)) then
        return nil, "SceneWarManager.joinWar() the player has already joined the war."
    end
    if (configuration.players[playerIndex]) then
        return nil, "SceneWarManager.joinWar() the specified player index is already used by another player."
    end
    if (configuration.warPassword ~= param.warPassword) then
        return nil, "The password is incorrect."
    end
    -- TODO: validate other params, such as the war password, max skill points, and so on.

    configuration.players[playerIndex] = {
        account  = playerAccount,
        nickname = PlayerProfileManager.getPlayerProfile(playerAccount).nickname,
    }
    local joiningSceneWar = s_JoinableWarList[sceneWarFileName].warData
    joiningSceneWar.players[playerIndex] = generateSinglePlayerData(playerAccount, param.skillIndex)
    serialize(toFullFileName(sceneWarFileName), joiningSceneWar)

    if (not isWarReadyForStart(configuration)) then
        return "Join war successfully. Please wait for more players to join."
    else
        for _, player in pairs(configuration.players) do
            PlayerProfileManager.updatePlayerProfileWithOngoingWarConfiguration(player.account, sceneWarFileName, configuration)
        end
        s_JoinableWarList[sceneWarFileName]     = nil
        s_JoinableWarNameList[sceneWarFileName] = nil
        serialize(SCENE_WAR_JOINABLE_LIST_PATH, s_JoinableWarNameList)

        return "Join war successfully. The war has started."
    end
end

function SceneWarManager.updateModelSceneWarWithAction(fileName, action)
    assert(SceneWarManager.getOngoingModelSceneWar(fileName) ~= nil, "SceneWarManager.updateModelSceneWarWithAction() the param fileName is invalid.")

    local cloneAction = {}
    for k, v in pairs(action) do
        cloneAction[k] = v
    end

    serialize(s_OngoingWarList[fileName].fullFileName,
        s_OngoingWarList[fileName].actorSceneWar:getModel():doSystemAction(cloneAction):toSerializableTable()
    )

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

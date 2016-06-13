
local SceneWarManager = {}

local Actor                  = require("babyWars.src.global.actors.Actor")
local SerializationFunctions = require("babyWars.src.app.utilities.SerializationFunctions")
local PlayerProfileManager   = require("babyWars.src.app.utilities.PlayerProfileManager")

local SCENE_WAR_PATH               = "babyWars/res/data/sceneWar/"
local SCENE_WAR_NEXT_NAME_PATH     = SCENE_WAR_PATH .. "NextName.lua"
local SCENE_WAR_JOINABLE_LIST_PATH = SCENE_WAR_PATH .. "JoinableList.lua"

local s_IsInitialized = false

local s_SceneWarNextName
local s_JoinableSceneWarConfigurationList
local s_JoinableSceneWarList = {}
local s_OngoingSceneWarList  = {}

--------------------------------------------------------------------------------
-- The util functions.
--------------------------------------------------------------------------------
local function serialize(fullFileName, data)
    local file = io.open(fullFileName, "w")
    file:write("return ")
    SerializationFunctions.appendToFile(data, "", file)
    file:close()
end

local function toFullFileName(shortName)
    return SCENE_WAR_PATH .. shortName .. ".lua"
end

local function createActorSceneWar(fileName)
    local fullFileName = toFullFileName(fileName)
    local file = io.open(fullFileName, "r")
    if (file) then
        file:close()

        local modelSceneWar = Actor.createModel("ModelSceneWar", dofile(fullFileName))
        modelSceneWar:onStartRunning()
        return Actor.createWithModelAndViewInstance(modelSceneWar), fullFileName
    else
        return nil
    end
end

local function tickSceneWarNextName()
    local byteList = {}
    local byteNext9, byteNextz = string.byte("9") + 1, string.byte("z") + 1
    local byte0, bytea         = string.byte("0"),     string.byte("a")
    local inc = 1

    for i = #s_SceneWarNextName, 1, -1 do
        byteList[i] = s_SceneWarNextName:byte(i) + inc
        inc = 0
        if (byteList[i] == byteNext9) then
            byteList[i] = bytea
        elseif (byteList[i] == byteNextz) then
            byteList[i] = byte0
            inc = 1
        end
    end

    s_SceneWarNextName = string.char(unpack(byteList))
    serialize(SCENE_WAR_NEXT_NAME_PATH, s_SceneWarNextName)
end

local function hasPlayerJoinedWar(playerAccount, configuration)
    for _, player in pairs(configuration.players) do
        if (player.account == playerAccount) then
            return true
        end
    end

    return false
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
        phase       = "beginning",
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

local function generatePlayersData(warFieldFileName, playerIndex, account, skillIndex)
    local data = {
        [playerIndex] = generateSinglePlayerData(account, skillIndex),
    }
    for i = 1, require("babyWars.res.data.templateWarField." .. warFieldFileName).playersCount do
        data[i] = data[i] or {}
    end

    return data
end

local function generateSceneWarData(fileName, param)
    return {
        fileName = fileName,
        warField = generateWarFieldData(param.warFieldFileName),
        turn     = generateTurnData(),
        players  = generatePlayersData(param.warFieldFileName, param.playerIndex, param.playerAccount, param.skillIndex),
        weather  = generateWeatherData(),
    }, toFullFileName(fileName)
end

local function generateWarConfigurationData(param)
    return {
        warFieldFileName = param.warFieldFileName,
        players          = {
            [param.playerIndex] = {
                account  = param.playerAccount,
                nickname = PlayerProfileManager.getPlayerProfile(param.playerAccount).nickname,
            },
        },
        -- TODO: add code to record the real configuration of the weather/fog/max skill points.
        fog              = "off",
        weather          = "clear",
        maxSkillPoints   = "Unavailable",
    }
end

--------------------------------------------------------------------------------
-- The public functions.
--------------------------------------------------------------------------------
function SceneWarManager.init()
    if (s_IsInitialized) then
        return
    end
    s_IsInitialized = true

    s_SceneWarNextName                  = dofile(SCENE_WAR_NEXT_NAME_PATH)
    s_JoinableSceneWarConfigurationList = dofile(SCENE_WAR_JOINABLE_LIST_PATH)

    return SceneWarManager
end

function SceneWarManager.createNewWar(param)
    local data, fullFileName = generateSceneWarData(s_SceneWarNextName, param)
    if (not data) then
        return nil, "SceneWarManager.createNewWar() failed because some param is invalid."
    end

    s_JoinableSceneWarConfigurationList[s_SceneWarNextName] = generateWarConfigurationData(param)
    s_JoinableSceneWarList[s_SceneWarNextName]              = data
    serialize(SCENE_WAR_JOINABLE_LIST_PATH, s_JoinableSceneWarConfigurationList)
    serialize(fullFileName, data)
    tickSceneWarNextName()

    return data
end

function SceneWarManager.getOngoingModelSceneWar(fileName)
    if (not fileName) then
        return nil
    else
        if (s_OngoingSceneWarList[fileName] == nil) then
            local actorSceneWar, fullFileName = createActorSceneWar(fileName)
            if (not actorSceneWar) then
                return nil
            else
                s_OngoingSceneWarList[fileName] = {
                    actorSceneWar = actorSceneWar,
                    fullFileName  = fullFileName
                }
            end
        end

        return s_OngoingSceneWarList[fileName].actorSceneWar:getModel()
    end
end

function SceneWarManager.getOngoingSceneWarData(fileName)
    assert(type(fileName) == "string", "SceneWarManager.getOngoingSceneWarData() the param fileName is invalid.")

    local modelSceneWar = SceneWarManager.getOngoingModelSceneWar(fileName)
    return (modelSceneWar) and (modelSceneWar:toSerializableTable()) or nil
end

function SceneWarManager.getJoinableSceneWarList(playerAccount)
    local list = {}
    for sceneWarFileName, configuration in pairs(s_JoinableSceneWarConfigurationList) do
        if (not hasPlayerJoinedWar(playerAccount, configuration)) then
            list[sceneWarFileName] = configuration
        end
    end
    -- TODO: Rendomize the items and limit the length of the list.

    return list
end

function SceneWarManager.getJoinableSceneWarData(fileName)
    if (s_JoinableSceneWarConfigurationList[fileName] == nil) then
        ngx.log(ngx.ERR, "SceneWarManager.getJoinableSceneWarData() the war scene that the param fileName indicates is not joinable.")
        return nil
    end
    if (s_JoinableSceneWarList[fileName] == nil) then
        s_JoinableSceneWarList[fileName] = dofile(toFullFileName(fileName))
    end

    return s_JoinableSceneWarList[fileName]
end

function SceneWarManager.updateModelSceneWarWithAction(fileName, action)
    assert(SceneWarManager.getOngoingModelSceneWar(fileName) ~= nil, "SceneWarManager.updateModelSceneWarWithAction() the param fileName is invalid.")

    local cloneAction = {}
    for k, v in pairs(action) do
        cloneAction[k] = v
    end

    serialize(s_OngoingSceneWarList[fileName].fullFileName,
        s_OngoingSceneWarList[fileName].actorSceneWar:getModel():doSystemAction(cloneAction):toSerializableTable()
    )

    return SceneWarManager
end

return SceneWarManager


local SceneWarManager = {}

local Actor                  = require("babyWars.src.global.actors.Actor")
local SerializationFunctions = require("babyWars.src.app.utilities.SerializationFunctions")
local PlayerProfileManager   = require("babyWars.src.app.utilities.PlayerProfileManager")

local DATA_SCENE_WAR_PATH           = "babyWars/res/data/sceneWar/"
local DATA_SCENE_WAR_NEXT_NAME_PATH = DATA_SCENE_WAR_PATH .. "NextName.lua"

local s_SceneWarNextName
local s_ActorSceneWarList = {}

--------------------------------------------------------------------------------
-- The util functions.
--------------------------------------------------------------------------------
local function createActorSceneWar(fileName)
    local fullFileName = DATA_SCENE_WAR_PATH .. fileName .. ".lua"
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
    local file = io.open(DATA_SCENE_WAR_NEXT_NAME_PATH, "w")
    file:write(string.format("return %q\n", s_SceneWarNextName))
    file:close()
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

local function generatePlayersData(warFieldFileName, playerIndex, account, skillIndex)
    local playerProfile = PlayerProfileManager.getPlayerProfile(account)
    local data = {
        [playerIndex] = {
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
        },
    }
    for i = 1, require("babyWars.res.data.templateWarField." .. warFieldFileName).playersCount do
        data[i] = data[i] or {}
    end

    return data
end

local function generateNewWarData(fileName, param)
    return {
        fileName = fileName,
        warField = generateWarFieldData(param.warFieldFileName),
        turn     = generateTurnData(),
        players  = generatePlayersData(param.warFieldFileName, param.playerIndex, param.playerAccount, param.skillIndex),
        weather  = generateWeatherData(),
    }
end

--------------------------------------------------------------------------------
-- The public functions.
--------------------------------------------------------------------------------
function SceneWarManager.init()
    if (not s_SceneWarNextName) then
        s_SceneWarNextName = dofile(DATA_SCENE_WAR_NEXT_NAME_PATH)
    end

    return SceneWarManager
end

function SceneWarManager.getModelSceneWar(fileName)
    if (not fileName) then
        return nil
    else
        if (s_ActorSceneWarList[fileName] == nil) then
            local actorSceneWar, fullFileName = createActorSceneWar(fileName)
            if (not actorSceneWar) then
                return nil
            else
                s_ActorSceneWarList[fileName] = {
                    actorSceneWar = actorSceneWar,
                    fullFileName  = fullFileName
                }
            end
        end

        return s_ActorSceneWarList[fileName].actorSceneWar:getModel()
    end
end

function SceneWarManager.getSceneWarData(fileName)
    assert(type(fileName) == "string", "SceneWarManager.getSceneWarData() the param fileName is invalid.")

    local modelSceneWar = SceneWarManager.getModelSceneWar(fileName)
    return (modelSceneWar) and (modelSceneWar:toSerializableTable()) or nil
end

function SceneWarManager.createNewWar(param)
    local shortName = s_SceneWarNextName
    tickSceneWarNextName()

    local data = generateNewWarData(shortName, param)
    if (not data) then
        return nil, "SceneWarManager.createNewWar() failed because some param is invalid."
    end

    local file = io.open(DATA_SCENE_WAR_PATH .. shortName .. ".lua", "w")
    file:write("return ")
    file:write(SerializationFunctions.toString(data))
    file:close()

    return data
end

function SceneWarManager.updateModelSceneWarWithAction(fileName, action)
    assert(SceneWarManager.getModelSceneWar(fileName) ~= nil, "SceneWarManager.updateModelSceneWarWithAction() the param fileName is invalid.")

    local cloneAction = {}
    for k, v in pairs(action) do
        cloneAction[k] = v
    end

    local file = io.open(s_ActorSceneWarList[fileName].fullFileName, "w")
    file:write("return ")
    SerializationFunctions.appendToFile(s_ActorSceneWarList[fileName].actorSceneWar:getModel():doSystemAction(cloneAction):toSerializableTable(), "", file)
    file:close()

    return SceneWarManager
end

return SceneWarManager


local SceneWarManager = {}

local Actor = require("babyWars.src.global.actors.Actor")

local SCENE_WAR_DATA_PATH = "babyWars/res/data/warScene/"

local s_ActorSceneWarList = {}

--------------------------------------------------------------------------------
-- The util functions.
--------------------------------------------------------------------------------
local function createActorSceneWar(fileName)
    local fullFileName = SCENE_WAR_DATA_PATH .. fileName .. ".lua"
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

--------------------------------------------------------------------------------
-- The public functions.
--------------------------------------------------------------------------------
function SceneWarManager.getModelSceneWar(fileName)
    if (not fileName) then
        return nil
    else
        if (s_ActorSceneWarList.fileName == nil) then
            local actorSceneWar, fullFileName = createActorSceneWar(fileName)
            if (not actorSceneWar) then
                return nil
            else
                s_ActorSceneWarList.fileName = {
                    actorSceneWar = actorSceneWar,
                    fullFileName  = fullFileName
                }
            end
        end

        return s_ActorSceneWarList.fileName.actorSceneWar:getModel()
    end
end

function SceneWarManager.updateModelSceneWarWithAction(fileName, action)
    assert(s_ActorSceneWarList.fileName ~= nil, "SceneWarManager.updateModelSceneWarWithAction() the param fileName is invalid.")

    local file = io.open(s_ActorSceneWarList.fileName.fullFileName, "w")
    for _, str in ipairs(s_ActorSceneWarList.fileName.actorSceneWar:getModel():doSystemAction(action):toStringList()) do
        file:write(str)
    end
    file:close()

    return SceneWarManager
end

return SceneWarManager

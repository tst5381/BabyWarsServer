
local PlayerProfileManager = {}

local SerializationFunctions = requireFW("src.app.utilities.SerializationFunctions")
local TableFunctions         = requireFW("src.app.utilities.TableFunctions")

local decode                 = SerializationFunctions.decode
local encode                 = SerializationFunctions.encode
local io, math, pairs, table = io, math, pairs, table

local PLAYER_PROFILE_PATH           = "FreeWarsServer\\userdata\\playerProfile\\"
local DATA_LISTS_PATH               = PLAYER_PROFILE_PATH .. "dataLists\\"
local PLAYER_ACCOUNT_LIST_FILE_NAME = DATA_LISTS_PATH .. "playerAccountList.spdata"
local RANKING_LIST_FILE_NAME        = DATA_LISTS_PATH .. "rankingList.spdata"

local HEARTBEAT_INTERVAL             = 10                          -- 10 seconds, the same as the WebSocketManager on clients.
local ONLINE_DURATION_UPDATE_COUNTER = 60 * 5 / HEARTBEAT_INTERVAL -- serialize the duration every 5 minutes.
local RECENT_WAR_LIST_CAPACITY       = 20

local DEFAULT_SINGLE_GAME_RECORD   = {rankScore = 1000, win = 0, lose = 0, draw = 0}
local DEFAULT_GAME_RECORDS         = {}
for i = 1, 6 do
    DEFAULT_GAME_RECORDS[i] = DEFAULT_SINGLE_GAME_RECORD
end
local DEFAULT_WAR_LIST             = {
    ongoing = {},
    waiting = {},
    recent  = {},
}

local s_IsInitialized     = false
local s_PlayerProfileList = {}
local s_PlayerAccountList, s_NextPlayerID
local s_RankingLists

--------------------------------------------------------------------------------
-- The util functions.
--------------------------------------------------------------------------------
local function binarySearch(array, predicate)
    local lowerBound, upperBound = 1, #array
    while (lowerBound <= upperBound) do
        local mid = math.floor((lowerBound + upperBound) / 2)
        local p   = predicate(array[mid])
        if     (p == 0) then return mid, true
        elseif (p >  0) then lowerBound = mid + 1
        else                 upperBound = mid - 1
        end
    end

    return lowerBound, false
end

local function updateRecentWarList(profile, warID)
    profile.warLists.recent = profile.warLists.recent or {}
    local list = profile.warLists.recent
    list[#list + 1] = warID
    if (#list > RECENT_WAR_LIST_CAPACITY) then
        table.remove(list, 1)
    end
end

local function generatePlayerProfile(account, password, playerID)
    return {
        playerID            = playerID,
        account             = account,
        password            = password,
        nickname            = account,
        totalOnlineDuration = 0,

        gameRecords = DEFAULT_GAME_RECORDS,
        warLists    = DEFAULT_WAR_LIST,
    }
end

local function toFullFileName(account)
    return PLAYER_PROFILE_PATH .. account .. ".spdata"
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

local function loadPlayerAccountList()
    local file = io.open(PLAYER_ACCOUNT_LIST_FILE_NAME, "rb")
    if (not file) then
        return nil
    else
        local data = file:read("*a")
        file:close()
        return decode("PlayerAccountList", data).list
    end
end

local function serializePlayerAccountList(list)
    local file = io.open(PLAYER_ACCOUNT_LIST_FILE_NAME, "wb")
    file:write(encode("PlayerAccountList", {list = list}))
    file:close()
end

local function loadRankingLists()
    local file = io.open(RANKING_LIST_FILE_NAME, "rb")
    if (not file) then
        return nil
    else
        local data = file:read("*a")
        file:close()
        return decode("RankingListsForServer", data).lists
    end
end

local function serializeRankingLists(rankingLists)
    local file = io.open(RANKING_LIST_FILE_NAME, "wb")
    file:write(encode("RankingListsForServer", {lists = rankingLists}))
    file:close()
end

--------------------------------------------------------------------------------
-- The functions for updating ranking list.
--------------------------------------------------------------------------------
local function getRankScoreModifierOnWin(winnerScore, loserScore)
    local diff = winnerScore - loserScore
    if     (diff == 0) then return 20
    elseif (diff > 0)  then return 20 - math.min(20, math.floor(  diff  / 10))
    else                    return 20 + math.min(20, math.floor((-diff) / 10))
    end
end

local function getRankScoreModifierOnDraw(score1, score2)
    local diff = score1 - score2
    if     (diff == 0) then return 0
    elseif (diff >  0) then return -math.min(20, math.floor(  diff  / 10))
    else                    return  math.min(20, math.floor((-diff) / 10))
    end
end

local function updateRankingListOnScoreChanged(gameTypeIndex, account, oldScore, newScore)
    local rankingList             = s_RankingLists[gameTypeIndex].list
    local oldRankIndex, findedOld = binarySearch(rankingList, function(item)
        return item.rankScore - oldScore
    end)
    if (findedOld) then
        local accounts = rankingList[oldRankIndex].accounts
        for i, accountInList in ipairs(accounts) do
            if (accountInList == account) then
                table.remove(accounts, i)
                break
            end
        end
        if (#accounts == 0) then
            table.remove(rankingList, oldRankIndex)
        end
    end

    local newRankIndex, findedNew = binarySearch(rankingList, function(item)
        return item.rankScore - newScore
    end)
    if (findedNew) then
        local accounts = rankingList[newRankIndex].accounts
        accounts[#accounts + 1] = account
    else
        table.insert(rankingList, newRankIndex, {
            rankScore = newScore,
            accounts = {account},
        })
    end
end

local function updateRankingsOnPlayerLose(modelPlayerManager, lostPlayerIndex, gameTypeIndex)
    local loserAccount  = modelPlayerManager:getModelPlayer(lostPlayerIndex):getAccount()
    local loserProfile  = PlayerProfileManager.getPlayerProfile(loserAccount)
    local loserScore    = loserProfile.gameRecords[gameTypeIndex].rankScore
    local totalModifier = 0

    modelPlayerManager:forEachModelPlayer(function(modelPlayer, playerIndex)
        if (modelPlayer:isAlive()) then
            local winnerAccount = modelPlayer:getAccount()
            local winnerProfile = PlayerProfileManager.getPlayerProfile(winnerAccount)
            local winnerScore   = winnerProfile.gameRecords[gameTypeIndex].rankScore
            local modifier      = getRankScoreModifierOnWin(winnerScore, loserScore)

            if (modifier ~= 0) then
                updateRankingListOnScoreChanged(gameTypeIndex, winnerAccount, winnerScore, winnerScore + modifier)

                totalModifier = totalModifier + modifier
                winnerProfile.gameRecords[gameTypeIndex].rankScore = winnerScore + modifier
                serializeProfile(winnerProfile)
            end
        end
    end)

    if (totalModifier ~= 0) then
        updateRankingListOnScoreChanged(gameTypeIndex, loserAccount, loserScore, loserScore - totalModifier)
        serializeRankingLists(s_RankingLists)

        loserProfile.gameRecords[gameTypeIndex].rankScore = loserScore - totalModifier
    end
end

local function updateRankingsOnDraw(modelPlayerManager, gameTypeIndex)
    local alivePlayers      = {}
    local alivePlayersCount = 0
    modelPlayerManager:forEachModelPlayer(function(modelPlayer)
        if (modelPlayer:isAlive()) then
            alivePlayersCount = alivePlayersCount + 1
            alivePlayers[alivePlayersCount] = {
                modelPlayer   = modelPlayer,
                profile       = PlayerProfileManager.getPlayerProfile(modelPlayer:getAccount()),
                totalModifier = 0,
            }
        end
    end)

    for i = 1, alivePlayersCount do
        local oldScore = alivePlayers[i].profile.gameRecords[gameTypeIndex].rankScore
        for j = i + 1, alivePlayersCount do
            local modifier  = getRankScoreModifierOnDraw(oldScore, alivePlayers[j].profile.gameRecords[gameTypeIndex].rankScore)
            alivePlayers[i].totalModifier = alivePlayers[i].totalModifier + modifier
            alivePlayers[j].totalModifier = alivePlayers[j].totalModifier - modifier
        end

        local newScore = oldScore + alivePlayers[i].totalModifier
        updateRankingListOnScoreChanged(gameTypeIndex, alivePlayers[i].profile.account, oldScore, newScore)
        alivePlayers[i].profile.gameRecords[gameTypeIndex].rankScore = newScore
    end

    serializeRankingLists(s_RankingLists)
end

--------------------------------------------------------------------------------
-- The initializers.
--------------------------------------------------------------------------------
local function initPlayerIdList()
    s_PlayerAccountList = loadPlayerAccountList()
    if (not s_PlayerAccountList) then
        s_PlayerAccountList = {}
        serializePlayerAccountList(s_PlayerAccountList)
    end
    s_NextPlayerID = #s_PlayerAccountList + 1
end

local function initRankingLists()
    s_RankingLists = loadRankingLists()
    if (not s_RankingLists) then
        s_RankingLists = {
            {list = {}}, {list = {}}, {list = {}}, {list = {}}, {list = {}}, {list = {}},
        }
        serializeRankingLists(s_RankingLists)
    end
end

--------------------------------------------------------------------------------
-- The public functions.
--------------------------------------------------------------------------------
function PlayerProfileManager.init()
    if (s_IsInitialized) then
        return
    end

    os.execute("mkdir " .. PLAYER_PROFILE_PATH)
    os.execute("mkdir " .. DATA_LISTS_PATH)
    initPlayerIdList()
    initRankingLists()

    s_IsInitialized = true
    return PlayerProfileManager
end

function PlayerProfileManager.getRankingLists()
    return s_RankingLists
end

function PlayerProfileManager.getPlayerProfile(account)
    local lowerAccount = string.lower(account)
    if (not s_PlayerProfileList[lowerAccount]) then
        local profile = loadProfile(account)
        if (not profile) then
            return nil
        else
            profile.heartbeatCounter = 0
            s_PlayerProfileList[lowerAccount] = {
                fullFileName = toFullFileName(account),
                profile      = profile,
            }
        end
    end

    return s_PlayerProfileList[lowerAccount].profile
end

function PlayerProfileManager.getParticipatedWarsCount(account)
    local warLists = PlayerProfileManager.getPlayerProfile(account).warLists
    return TableFunctions.getPairsCount(warLists.ongoing) + TableFunctions.getPairsCount(warLists.waiting)
end

function PlayerProfileManager.createPlayerProfile(account, password)
    assert(not PlayerProfileManager.getPlayerProfile(account), "PlayerProfileManager.createPlayerProfile() the profile has been created already.")
    serializeProfile(generatePlayerProfile(account, password, s_NextPlayerID))

    s_PlayerAccountList[s_NextPlayerID] = account
    serializePlayerAccountList(s_PlayerAccountList)
    s_NextPlayerID = s_NextPlayerID + 1

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
        return (profile) and (profile.account == account) and (profile.password == password)
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

function PlayerProfileManager.updateProfileWithNetworkHeartbeat(account)
    local profile = PlayerProfileManager.getPlayerProfile(account)
    profile.heartbeatCounter    = profile.heartbeatCounter    + 1
    profile.totalOnlineDuration = profile.totalOnlineDuration + HEARTBEAT_INTERVAL
    if (profile.heartbeatCounter >= ONLINE_DURATION_UPDATE_COUNTER) then
        profile.heartbeatCounter = 0
        serializeProfile(profile)
    end

    return PlayerProfileManager
end

function PlayerProfileManager.updateProfileOnCreatingWar(account, warID)
    local profile  = PlayerProfileManager.getPlayerProfile(account)
    profile.warLists.waiting[warID] = {warID = warID}
    serializeProfile(profile)

    return PlayerProfileManager
end

function PlayerProfileManager.updateProfileOnExitWar(account, warID)
    local profile = PlayerProfileManager.getPlayerProfile(account)
    profile.warLists.waiting[warID] = nil
    serializeProfile(profile)

    return PlayerProfileManager
end

function PlayerProfileManager.updateProfileOnJoiningWar(account, warID)
    return PlayerProfileManager.updateProfileOnCreatingWar(account, warID)
end

function PlayerProfileManager.updateProfilesOnBeginningWar(warConfiguration)
    local warID = warConfiguration.warID
    for _, player in pairs(warConfiguration.players) do
        local profile  = PlayerProfileManager.getPlayerProfile(player.account)
        local warLists = profile.warLists
        warLists.ongoing[warID] = warLists.waiting[warID]
        warLists.waiting[warID] = nil

        serializeProfile(profile)
    end

    return PlayerProfileManager
end

function PlayerProfileManager.updateProfilesWithModelSceneWar(modelSceneWar)
    local warID              = modelSceneWar:getWarId()
    local modelPlayerManager = modelSceneWar:getModelPlayerManager()
    local gameTypeIndex      = modelPlayerManager:getPlayersCount() * 2 - 3 + (modelSceneWar:isFogOfWarByDefault() and 1 or 0)

    if (modelSceneWar:getRemainingVotesForDraw() == 0) then
        if (modelSceneWar:isRankMatch()) then
            updateRankingsOnDraw(modelPlayerManager, gameTypeIndex)
        end

        modelPlayerManager:forEachModelPlayer(function(modelPlayer, playerIndex)
            if (modelPlayer:isAlive()) then
                local profile = PlayerProfileManager.getPlayerProfile(modelPlayer:getAccount())
                assert(profile.warLists.ongoing[warID],
                    "PlayerProfileManager.updateProfilesWithModelSceneWar() the war ends in draw, while some alive players are not participating in it.")

                profile.warLists.ongoing[warID]         = nil
                profile.gameRecords[gameTypeIndex].draw = profile.gameRecords[gameTypeIndex].draw + 1
                updateRecentWarList(profile, warID)
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
                if (profile.warLists.ongoing[warID]) then
                    if (modelSceneWar:isRankMatch()) then
                        updateRankingsOnPlayerLose(modelPlayerManager, playerIndex, gameTypeIndex)
                    end

                    profile.warLists.ongoing[warID]         = nil
                    profile.gameRecords[gameTypeIndex].lose = profile.gameRecords[gameTypeIndex].lose + 1
                    updateRecentWarList(profile, warID)
                    serializeProfile(profile)
                end
            end
        end)

        if (alivePlayersCount == 1) then
            local profile = PlayerProfileManager.getPlayerProfile(alivePlayerAccount)
            profile.warLists.ongoing[warID]        = nil
            profile.gameRecords[gameTypeIndex].win = profile.gameRecords[gameTypeIndex].win + 1
            updateRecentWarList(profile, warID)
            serializeProfile(profile)
        end
    end

    return PlayerProfileManager
end

return PlayerProfileManager

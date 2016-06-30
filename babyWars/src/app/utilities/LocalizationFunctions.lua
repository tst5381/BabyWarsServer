
local LocalizationFunctions = {}

local s_LanguageCode = 1

local s_LongText1_1 = [[
--- 注：游戏尚有部分功能未完成开发，请谅解。---

--- 游戏流程 ---
首先，您需要通过主菜单的“注册/登陆”功能连接到游戏（若您曾经成功登陆过，则游戏会尝试自动登陆--暂未完成）。成功后，主菜单将出现新的选项，您可以通过它们来进入战局。

自行建立战局-开战的流程：
1. 通过“新建战局”选项创建新的战局。在里面，您可以随意选择模式（天梯或自由战斗）、地图、回合顺序、密码等多种设定。
2. 耐心等待他人加入您所创建的战局（满员前，您无法进入战局）。
3. 当战局满员后，您可以进入“继续”选项，里面将出现该战局（未满员时，该战局将*不会*出现！）。点击相应选项即可进入战局。

加入他人战局的流程：
1. 点击“参战”，里面将列出您可以加入的、由他人所建立的战局。您也可以通过里面的“搜索”按钮，用房间号来筛选出您所希望加入的战局。
2. 选中您所希望加入的战局，再选择回合顺序、密码等设定，并确认加入战局（注意，游戏不会自动进入战局画面）。
3. 回到主菜单选择“继续”，里面会出现该战局（前提是该战局已经满员。若未满员，则该战局不会出现，您仍需等候他人加入）。点击相应选项即可进入战局。
]]

local s_LongText2_1 = [[
--- 战局操作 ---
本作的战局操作方式类似于《Advanced Wars: Days of Ruin》。

战局画面的左（右）上角有一个关于玩家简要信息的标识框。点击它将弹出战局菜单，您可以通过菜单实现退出、结束回合等操作。
战局画面的左（右）下角有光标所在的地形（部队）的标识框。点击它会弹出该地形（部队）的详细信息框。

您可以随意拖动地图（使用单个手指滑动画面）和缩放地图（使用两个手指滑动画面）。

您可以预览战斗的预估伤害值：在为部队选择攻击目标时，把光标拖拽到目标之上即可（请不要直接点击目标，这将被游戏解读为直接对该目标进行攻击，而不预览战斗伤害值）。
]]

local s_LongText3_1 = [[
--- 关于本作 ---
《BabyWars》（暂名）是以《Advanced Wars》系列的设定为基础的同人作品。本作旨在为高级战争的爱好者们提供一个兼顾公平性和自由度的联网对战平台。

本作的兵种、地形等设定取材于《Advanced Wars: Days of Ruin》，不设CO系统，而使用允许玩家自由搭配的技能系统代替（《Advanced Wars: Dual Strike》中的技能装备的强化版，但目前尚未完成开发）。

本作有一定复杂度，建议您可以先游玩一下原作，以便更快上手。

作者：Babygogogo

协力（排名不分先后）：


原作：《Advanced Wars》系列
原作开发商：Intelligent Systems
]]

--------------------------------------------------------------------------------
-- The private functions.
--------------------------------------------------------------------------------
local s_Texts = {
    [1] = {
        [1] = function(...) return "主  菜  单" end,
        [2] = function(...) return "Main Menu" end,
    },
    [2] = {
        [1] = function(...) return "新 建 战 局"  end,
        [2] = function(...) return "New Game" end,
    },
    [3] = {
        [1] = function(...) return "继 续"    end,
        [2] = function(...) return "Continue" end,
    },
    [4] = {
        [1] = function(...) return "参 战" end,
        [2] = function(...) return "Join" end,
    },
    [5] = {
        [1] = function(...) return "配 置 技 能"    end,
        [2] = function(...) return "Config Skills" end,
    },
    [6] = {
        [1] = function(...) return "注 册 / 登 陆" end,
        [2] = function(...) return "Login"        end,
    },
    [7] = {
        [1] = function(...) return "帮 助" end,
        [2] = function(...) return "Help" end,
    },
    [8] = {
        [1] = function(...) return "返 回" end,
        [2] = function(...) return "Back" end,
    },
    [9] = {
        [1] = function(...) return "游 戏 流 程" end,
        [2] = function(...) return "Game Flow"  end,
    },
    [10] = {
        [1] = function(...) return "战 局 操 作" end,
        [2] = function(...) return "War Control" end,
    },
    [11] = {
        [1] = function(...) return "关 于 本 作" end,
        [2] = function(...) return "About" end,
    },
    [12] = {
        [1] = function(...) return s_LongText1_1     end,
        [2] = function(...) return "Untranslated..." end,
    },
    [13] = {
        [1] = function(...) return s_LongText2_1     end,
        [2] = function(...) return "Untranslated..." end,
    },
    [14] = {
        [1] = function(...) return s_LongText3_1     end,
        [2] = function(...) return "Untranslated..." end,
    },
    [15] = {
        [1] = function(...) return "账 号："  end,
        [2] = function(...) return "Account:" end,
    },
    [16] = {
        [1] = function(...) return "密 码："  end,
        [2] = function(...) return "Password:" end,
    },
    [17] = {
        [1] = function(...) return "注 册"  end,
        [2] = function(...) return "Register" end,
    },
    [18] = {
        [1] = function(...) return "登 陆"  end,
        [2] = function(...) return "Login" end,
    },
    [19] = {
        [1] = function(...) return "账号密码只能使用英文字符和/或数字，且最少6位。请检查后重试。"                               end,
        [2] = function(...) return "Only alphanumeric characters and/or underscores are allowed for account and password." end,
    },
    [20] = {
        [1] = function(...) return "请输入6位以上英文和/或数字"    end,
        [2] = function(...) return "input at least 6 characters" end,
    },
    [21] = {
        [1] = function(account) return "您已使用账号【" .. account .. "】进行了登陆。"      end,
        [2] = function(account) return "You have already logged in as " .. account .. "." end,
    },
    [22] = {
        [1] = function() return "账号或密码错误，请重试。"    end,
        [2] = function() return "Invalid account/password." end,
    },
    [23] = {
        [1] = function(account) return "您的账号【" .. account .. "】在另一台设备上被登陆，您已被迫下线！"     end,
        [2] = function(account) return "Another device is logging in with your account!" .. account .. "." end,
    },
    [24] = {
        [1] = function(account, password)
            return "您确定要用以下账号和密码进行注册吗？\n" .. account .. "\n" .. password
        end,
        [2] = function(account, password)
            return "Are you sure to register with the following account and password:\n" .. account .. "\n" .. password
        end,
    },
    [25] = {
        [1] = function() return "该账号已被注册，请使用其他账号。"                                  end,
        [2] = function() return "The account is registered already. Please use another account." end,
    },
    [26] = {
        [1] = function(account) return "欢迎登陆，【" .. account .. "】！" end,
        [2] = function(account) return "Welcome, " .. account .. "!"      end,
    },
    [27] = {
        [1] = function(account) return "欢迎注册，【" .. account .. "】！祝您游戏愉快！"            end,
        [2] = function(account) return "Welcome, " .. account .. "!\nThank you for registering!" end,
    },
    [28] = {
        [1] = function() return "是"  end,
        [2] = function() return "Yes" end,
    },
    [29] = {
        [1] = function() return "否" end,
        [2] = function() return "No" end,
    },
    [30] = {
        [1] = function() return "已成功连接服务器。"       end,
        [2] = function() return "Connection established." end,
    },
    [31] = {
        [1] = function() return "连接服务器失败，正在尝试重新连接…"       end,
        [2] = function() return "Connection lost. Now reconnecting..." end,
    },
    [32] = {
        [1] = function(err) return "与服务器的连接出现错误：" .. (err or "") .. "\n正在尝试重新连接…"                end,
        [2] = function(err) return "Connection lost with error: " .. (err or "") .. "Now reconnecting..." end,
    },
    [33] = {
        [1] = function() return "下 一 步" end,
        [2] = function() return "Next"  end,
    },
    [34] = {
        [1] = function() return "行 动 次 序"  end,
        [2] = function() return "Player Index" end,
    },
    [35] = {
        [1] = function() return "战 争 迷 雾" end,
        [2] = function() return "Fog of War" end,
    },
    [36] = {
        [1] = function() return "天 气"   end,
        [2] = function() return "Weather" end,
    },
    [37] = {
        [1] = function() return "技 能 配 置" end,
        [2] = function() return "Skills"     end,
    },
    [38] = {
        [1] = function() return "技 能 点 上 限"    end,
        [2] = function() return "Max Skill Points" end,
    },
    [39] = {
        [1] = function() return "密 码（可 选）"       end,
        [2] = function() return "Password (optional)" end,
    },
    [40] = {
        [1] = function() return "正 常" end,
        [2] = function() return "Clear" end,
    },
    [41] = {
        [1] = function() return "随 机"  end,
        [2] = function() return "Random" end,
    },
    [42] = {
        [1] = function() return "雨 天" end,
        [2] = function() return "Rainy" end,
    },
    [43] = {
        [1] = function() return "雪 天" end,
        [2] = function() return "Snowy" end,
    },
    [44] = {
        [1] = function() return "沙 尘 暴" end,
        [2] = function() return "Sandy"    end,
    },
    [45] = {
        [1] = function() return "暂 不 可 用"  end,
        [2] = function() return "Unavailable" end,
    },
    [46] = {
        [1] = function() return "确 认"   end,
        [2] = function() return "Confirm" end,
    },
    [47] = {
        [1] = function() return "留空或4位数字"        end,
        [2] = function() return "input 0 or 4 digits" end,
    },
    [48] = {
        [1] = function() return "作者："   end,
        [2] = function() return "Author: " end,
    },
    [49] = {
        [1] = function() return "回 合 内"   end,
        [2] = function() return "In Turn" end,
    },
    [50] = {
        [1] = function(err) return "无法创建战局。请重试或联系作者解决。\n" .. (err or "") end,
        [2] = function(err) return "Failed to create the war:\n" .. (err or "")         end,
    },
    [51] = {
        [1] = function(warShortName) return "【" .. warShortName .. "】战局已创建，请等待其他玩家参战。"                                          end,
        [2] = function(warShortName) return "The war [" .. warShortName .. "] is created successfully. Please wait for other players to join." end,
    },
    [52] = {
        [1] = function() return "无法进入战局，可能因为该战局已结束。"                           end,
        [2] = function() return "Failed entering the war, possibly because the war has ended." end,
    },
    [53] = {
        [1] = function(err) return "无法获取可参战列表。请重试或联系作者解决。\n" .. (err or "") end,
        [2] = function(err) return "Failed to get the joinable war list:\n" .. (err or "")   end,
    },
    [54] = {
        [1] = function(err) return "无法加入战局，可能因为您选择的行动顺序已被其他玩家占用，或密码不正确。\n" end,
        [2] = function(err) return "Failed to join the war:\n" .. (err or "")                          end,
    },
    [55] = {
        [1] = function() return "参战成功。战局尚未满员，请耐心等候。"                            end,
        [2] = function() return "Join war successfully. Please wait for more players to join." end,
    },
    [56] = {
        [1] = function(warShortName) return "【" .. warShortName .. '】参战成功。战局已开始，您可以通过"继续"选项进入战局。' end,
        [2] = function(warShortName) return "Join war [" .. warShortName .. "] successfully. The war has started."      end,
    },
    [57] = {
        [1] = function() return "查 找："   end,
        [2] = function() return "Find:" end,
    },
    [58] = {
        [1] = function() return "房号"   end,
        [2] = function() return "War ID" end,
    },
    [59] = {
        [1] = function() return "您输入的房号无效，请重试。"                 end,
        [2] = function() return "The War ID is invalid. Please try again." end,
    },
    [60] = {
        [1] = function() return "当前没有可加入（或符合查找条件）的战局。请等候，或自行建立战局。"                    end,
        [2] = function() return "Sorry, but no war is currently joinable. Please wait for or create a new war." end,
    },
    [61] = {
        [1] = function() return "您输入的密码无效，请重试。"                   end,
        [2] = function() return "The password is invalid. Please try again." end,
    },
    [62] = {
        [1] = function(nickname) return "玩家：" .. nickname    end,
        [2] = function(nickname) return "Player:  " .. nickname end,
    },
    [63] = {
        [1] = function(fund) return "金钱：" .. fund     end,
        [2] = function(fund) return "Fund:     " .. fund end,
    },
    [64] = {
        [1] = function(energy) return "能量：" .. energy    end,
        [2] = function(energy) return "Energy:  " .. energy end,
    },
    [65] = {
        [1] = function() return "退 出" end,
        [2] = function() return "Quit" end,
    },
    [66] = {
        [1] = function() return "您将回到主界面（可以随时再回到本战局）。\n是否确定退出？" end,
        [2] = function() return "You are quitting the war (you may reenter it later).\nAre you sure?" end,
    },
    [67] = {
        [1] = function() return "投 降" end,
        [2] = function() return "Surrender" end,
    },
    [68] = {
        [1] = function() return "您将输掉本战局，且无法反悔！\n是否确定投降？"              end,
        [2] = function() return "You will lose the game by surrendering!\nAre you sure?" end,
    },
    [69] = {
        [1] = function() return "结 束 回 合" end,
        [2] = function() return "End Turn" end,
    },
    [70] = {
        [1] = function(emptyProducersCount, idleUnitsCount)
            return string.format("空闲工厂机场海港数量：%d\n空闲部队数量：%d\n您是否确定结束回合？", emptyProducersCount, idleUnitsCount)
        end,
        [2] = function(emptyProducersCount, idleUnitsCount)
            return string.format("Idle factories count: %d\n Idle units count: %d\nAre you sure to end turn?", emptyProducersCount, idleUnitsCount)
        end,
    },
    [71] = {
        [1] = function() return "当前是您对手的回合，请耐心等候。"           end,
        [2] = function() return "It's your opponent's turn. Please wait." end,
    },
    [72] = {
        [1] = function(turnIndex, nickname)
            return string.format("回合：%d\n玩家：%s\n战斗开始！", turnIndex, nickname)
        end,
        [2] = function(turnIndex, nickname)
            return string.format("Turn:     %d\nPlayer:  %s\nFight!", turnIndex, nickname)
        end,
    },
    [73] = {
        [1] = function() return "您 已 投 降 …"     end,
        [2] = function() return "You surrender..." end,
    },
    [74] = {
        [1] = function() return "您 已 获 胜 ！" end,
        [2] = function() return "You win!"      end,
    },
    [75] = {
        [1] = function() return "您 已 战 败 …" end,
        [2] = function() return "You lose..."  end,
    },
    [76] = {
        [1] = function(nickname) return "玩家【" .. nickname .. "】已战败！"        end,
        [2] = function(nickname) return "Player [" .. nickname .. "] is defeated!" end,
    },
    [77] = {
        [1] = function(nickname) return "玩家【" .. nickname .. "】已投降！"        end,
        [2] = function(nickname) return "Player [" .. nickname .. "] surrendered!" end,
    },
    [78] = {
        [1] = function() return "攻 击"  end,
        [2] = function() return "Attack" end,
    },
    [79] = {
        [1] = function() return "占 领"   end,
        [2] = function() return "Capture" end,
    },
    [80] = {
        [1] = function() return "待 机" end,
        [2] = function() return "Wait" end,
    },
    [81] = {
        [1] = function() return "合 流" end,
        [2] = function() return "Join" end,
    },
    [82] = {
        [1] = function() return "装 载" end,
        [2] = function() return "Load"  end,
    },
    [83] = {
        [1] = function() return "卸 载"  end,
        [2] = function() return "Unload" end,
    },
    [84] = {
        [1] = function() return "发 射"  end,
        [2] = function() return "Launch" end,
    },
    [85] = {
        [1] = function() return "建 造"  end,
        [2] = function() return "Build" end,
    },
    [86] = {
        [1] = function() return "生 产"   end,
        [2] = function() return "Produce" end,
    },
    [87] = {
        [1] = function() return "补 给"  end,
        [2] = function() return "Supply" end,
    },
    [88] = {
        [1] = function() return "下 潜" end,
        [2] = function() return "Dive" end,
    },
    [89] = {
        [1] = function() return "上 浮"   end,
        [2] = function() return "Surface" end,
    },
    [90] = {
        [1] = function(attack, counter) return string.format("攻：    %d%%\n防：    %s%%", attack, counter or "--") end,
        [2] = function(attack, counter) return string.format("Atk:   %d%%\nDef:   %s%%", attack, counter or "--") end,
    },
    [91] = {
        [1] = function(moveRange, moveTypeName) return "移动力：" .. moveRange .. "（" .. moveTypeName .. "）"       end,
        [2] = function(moveRange, moveTypeName) return "Movement Range:  " .. moveRange .. "(" .. moveTypeName .. ")" end,
    },
    [92] = {
        [1] = function(vision) return "视野：" .. vision    end,
        [2] = function(vision) return "Vision:  " .. vision end,
    },
    [93] = {
        [1] = function(currentFuel, maxFuel, consumption, destroyOnRunOut)
            return string.format("燃料存量：%d / %d     每回合消耗：%d     耗尽后消灭：%s", currentFuel, maxFuel, consumption, (destroyOnRunOut) and ("是") or ("否"))
        end,
        [2] = function(currentFuel, maxFuel, consumption, destroyOnRunOut)
            return "Fuel:    Amount:  " .. currentFuel .. " / " .. maxFuel .. "    ConsumptionPerTurn:  " .. consumption ..
                "\n            " .. ((destroyOnRunOut) and ("This unit is destroyed when out of fuel.") or ("This unit can't move when out of fuel."))
        end,
    },
    [94] = {
        [1] = function(weaponName, currentAmmo, maxAmmo, minRange, maxRange)
            return "主武器：" .. weaponName ..
                "      弹药量：" .. currentAmmo .. " / " .. maxAmmo ..
                "      射程：" .. ((minRange == maxRange) and (minRange) or (minRange .. " - " .. maxRange))
        end,
        [2] = function(weaponName, currentAmmo, maxAmmo, minRange, maxRange)
            return "Primary Weapon: " .. weaponName ..
                "    Ammo:  "      .. currentAmmo .. " / " .. maxAmmo ..
                "    Range:  "     .. ((minRange == maxRange) and (minRange) or (minRange .. " - " .. maxRange))
        end,
    },
    [95] = {
        [1] = function() return "主武器：无"                    end,
        [2] = function() return "Primary Weapon: Not equipped." end,
    },
    [96] = {
        [1] = function() return "极强："   end,
        [2] = function() return "Fatal:" end,
    },
    [97] = {
        [1] = function() return "较强："   end,
        [2] = function() return "Good:" end,
    },
    [98] = {
        [1] = function(weaponName, minRange, maxRange)
            return "副武器：" .. weaponName ..
                "      射程：" .. ((minRange == maxRange) and (minRange) or (minRange .. " - " .. maxRange))
        end,
        [2] = function(weaponName, minRange, maxRange)
            return "Secondary Weapon: " .. weaponName ..
                "    Range:  "     .. ((minRange == maxRange) and (minRange) or (minRange .. " - " .. maxRange))
        end,
    },
    [99] = {
        [1] = function() return "副武器：无"                       end,
        [2] = function() return "Secondary Weapon: Not equipped." end,
    },
    [100] = {
        [1] = function() return "防御："   end,
        [2] = function() return "Defense:" end,
    },
    [101] = {
        [1] = function() return "极弱：" end,
        [2] = function() return "Fatal:" end,
    },
    [102] = {
        [1] = function() return "较弱：" end,
        [2] = function() return "Weak:" end,
    },
    [103] = {
        [1] = function(bonus, catagory) return "防御加成：" .. bonus .. "%（" .. catagory .. "）"     end,
        [2] = function(bonus, catagory) return "DefenseBonus: " .. bonus .. "% (" .. catagory .. ")" end,
    },
    [104] = {
        [1] = function(amount, catagory) return "维修：+" .. amount .. "HP（" .. catagory .. "）"   end,
        [2] = function(amount, catagory) return "Repair:  +" .. amount .. "HP (" .. catagory .. ")" end,
    },
    [105] = {
        [1] = function() return "维修：无"      end,
        [2] = function() return "Repair:  None" end,
    },
    [106] = {
        [1] = function(currentPoint, maxPoint) return "占领点数：" .. currentPoint .. " / " .. maxPoint      end,
        [2] = function(currentPoint, maxPoint) return "CapturePoint:  " .. currentPoint .. " / " .. maxPoint end,
    },
    [107] = {
        [1] = function() return "占领点数：无"         end,
        [2] = function() return "CapturePoint:  None" end,
    },
    [108] = {
        [1] = function(income) return "收入：" .. income    end,
        [2] = function(income) return "Income:  " .. income end,
    },
    [109] = {
        [1] = function() return "收入：无"      end,
        [2] = function() return "Income:  None" end,
    },
    [110] = {
        [1] = function(moveType)
            if     (moveType == "infantry")  then return "步兵"
            elseif (moveType == "mech")      then return "炮兵"
            elseif (moveType == "tireA")     then return "重型轮胎"
            elseif (moveType == "tireB")     then return "轻型轮胎"
            elseif (moveType == "tank")      then return "履带"
            elseif (moveType == "air")       then return "飞行"
            elseif (moveType == "ship")      then return "航行"
            elseif (moveType == "transport") then return "海运"
            else                                  return "未知"
            end
        end,
        [2] = function(moveType)
            if     (moveType == "infantry")  then return "infantry"
            elseif (moveType == "mech")      then return "mech"
            elseif (moveType == "tireA")     then return "tireA"
            elseif (moveType == "tireB")     then return "tireB"
            elseif (moveType == "tank")      then return "tank"
            elseif (moveType == "air")       then return "air"
            elseif (moveType == "ship")      then return "ship"
            elseif (moveType == "transport") then return "transport"
            else                                  return "unrecognized"
            end
        end,
    },
    [111] = {
        [1] = function(moveType, moveCost) return LocalizationFunctions.getLocalizedText(110, moveType) .. "：" .. (moveCost or "--") end,
        [2] = function(moveType, moveCost) return LocalizationFunctions.getLocalizedText(110, moveType) .. ":  " .. (moveCost or "--") end,
    },
    [112] = {
        [1] = function() return "移动力消耗："  end,
        [2] = function() return "Move Cost:  " end,
    },
    [113] = {
        [1] = function(unitType)
            if     (unitType == "infantry")   then return "步兵"
            elseif (unitType == "mech")       then return "炮兵"
            elseif (unitType == "bike")       then return "轮胎兵"
            elseif (unitType == "recon")      then return "侦察车"
            elseif (unitType == "flare")      then return "照明车"
            elseif (unitType == "antiair")    then return "对空战车"
            elseif (unitType == "tank")       then return "轻型坦克"
            elseif (unitType == "mdtank")     then return "中型坦克"
            elseif (unitType == "wartank")    then return "战争坦克"
            elseif (unitType == "artillery")  then return "自走炮"
            elseif (unitType == "antitank")   then return "反坦克炮"
            elseif (unitType == "rockets")    then return "火箭炮"
            elseif (unitType == "missiles")   then return "对空导弹"
            elseif (unitType == "rig")        then return "后勤车"
            elseif (unitType == "fighter")    then return "战斗机"
            elseif (unitType == "bomber")     then return "轰炸机"
            elseif (unitType == "duster")     then return "攻击机"
            elseif (unitType == "bcopter")    then return "武装直升机"
            elseif (unitType == "tcopter")    then return "运输直升机"
            elseif (unitType == "seaplane")   then return "舰载机"
            elseif (unitType == "battleship") then return "战列舰"
            elseif (unitType == "carrier")    then return "航空母舰"
            elseif (unitType == "submarine")  then return "潜艇"
            elseif (unitType == "cruiser")    then return "巡洋舰"
            elseif (unitType == "lander")     then return "登陆舰"
            elseif (unitType == "gunboat")    then return "炮舰"
            else                                   return "未知"
            end
        end,
        [2] = function(unitType)
            if     (unitType == "infantry")   then return "Inf"
            elseif (unitType == "mech")       then return "Mech"
            elseif (unitType == "bike")       then return "Bike"
            elseif (unitType == "recon")      then return "Recon"
            elseif (unitType == "flare")      then return "Flare"
            elseif (unitType == "antiair")    then return "AAir"
            elseif (unitType == "tank")       then return "Tank"
            elseif (unitType == "mdtank")     then return "MTank"
            elseif (unitType == "wartank")    then return "WTank"
            elseif (unitType == "artillery")  then return "Artlry"
            elseif (unitType == "antitank")   then return "ATank"
            elseif (unitType == "rockets")    then return "Rocket"
            elseif (unitType == "missiles")   then return "Missile"
            elseif (unitType == "rig")        then return "Rig"
            elseif (unitType == "fighter")    then return "Fighter"
            elseif (unitType == "bomber")     then return "Bomber"
            elseif (unitType == "duster")     then return "Duster"
            elseif (unitType == "bcopter")    then return "BCopter"
            elseif (unitType == "tcopter")    then return "TCopter"
            elseif (unitType == "seaplane")   then return "Seapl"
            elseif (unitType == "battleship") then return "BShip"
            elseif (unitType == "carrier")    then return "Carrier"
            elseif (unitType == "submarine")  then return "Sub"
            elseif (unitType == "cruiser")    then return "Cruiser"
            elseif (unitType == "lander")     then return "Lander"
            elseif (unitType == "gunboat")    then return "GBoat"
            else                                   return "Unknown"
            end
        end,
    },
    [114] = {
        [1] = function(unitType)
            if     (unitType == "infantry")   then return "步兵：最便宜的部队。能占领建筑和发射导弹，但攻防很弱。"
            elseif (unitType == "mech")       then return "炮兵：能占领建筑和发射导弹。火力不错，但移动力和防御较弱。"
            elseif (unitType == "bike")       then return "摩托兵：能占领建筑和发射导弹。在平坦地形上移动力不错，但攻防很弱。"
            elseif (unitType == "recon")      then return "侦察车：移动力优秀，视野广。能有效打击步兵系，但对其他部队的攻防较差。"
            elseif (unitType == "flare")      then return "照明车：能够远程投射大范围的照明弹。攻防能力一般。"
            elseif (unitType == "antiair")    then return "对空战车：能够有效打击空军和步兵系，但对坦克系较弱。"
            elseif (unitType == "tank")       then return "轻型坦克：各属性均衡，是陆军的中流砥柱。"
            elseif (unitType == "mdtank")     then return "中型坦克：攻防比轻型坦克更强，但移动力稍弱。"
            elseif (unitType == "wartank")    then return "战争坦克：攻防最强的坦克。移动力较差。"
            elseif (unitType == "artillery")  then return "自走炮：最便宜的远程部队，能够有效打击陆军和海军。防御较弱。"
            elseif (unitType == "antitank")   then return "反坦克炮：对近身攻击能够作出反击的远程部队。对坦克系尤其有效。防御力优秀，但移动力差。"
            elseif (unitType == "rockets")    then return "火箭炮：攻击力和射程都比自走炮优秀的远程部队。防御力很差。"
            elseif (unitType == "missiles")   then return "对空导弹：射程很远，能秒杀任何空军的远程部队。无法攻击陆军和海军，且防御很差。"
            elseif (unitType == "rig")        then return "后勤车：能够装载一个步兵或炮兵。能够建造临时机场或海港、补给临近的部队。不能攻击。"
            elseif (unitType == "fighter")    then return "战斗机：拥有最高的移动力，对空军的战斗力很优秀。无法攻击陆军和海军。"
            elseif (unitType == "bomber")     then return "轰炸机：能对陆军和海军造成致命打击。无法攻击空军。"
            elseif (unitType == "duster")     then return "攻击机：移动力优秀，能对空军造成有效打击，也能对陆军造成一定损伤。"
            elseif (unitType == "bcopter")    then return "武装直升机：能对陆军和直升机系造成有效打击，也能一定程度打击海军。"
            elseif (unitType == "tcopter")    then return "运输直升机：能够装载一个步兵或炮兵。不能攻击。"
            elseif (unitType == "seaplane")   then return "舰载机：能够对任何部队都造成有效打击。只能用航母生产。燃料和弹药都很少。"
            elseif (unitType == "battleship") then return "战列舰：攻防优秀，而且能移动后立刻进行攻击的远程部队。不能攻击空军。"
            elseif (unitType == "carrier")    then return "航空母舰：能够生产舰载机，以及装载两个空军单位。自身只能对空军造成少量伤害，防御力较差。"
            elseif (unitType == "submarine")  then return "潜艇：能够下潜使得敌军难以发现，且下潜后只能被潜艇和巡洋舰攻击。能有效打击巡洋舰以外的海军，无法攻击空军和陆军。"
            elseif (unitType == "cruiser")    then return "巡洋舰：能够对潜艇和空军造成毁灭性打击，对其他海军也有一定打击能力。能够装载两个直升机部队。不能攻击陆军。"
            elseif (unitType == "lander")     then return "登陆舰：能够在海滩地形装载和卸载最多两个陆军部队。不能攻击。"
            elseif (unitType == "gunboat")    then return "炮舰：能够装载一个步兵或炮兵。能够有效打击海军，但只有一枚弹药。防御力较差。"
            else                                   return "未知"
            end
        end,
        [2] = function(unitType)
            if     (unitType == "infantry")   then return "Infantry units are cheap. They can capture bases but have low firepower."
            elseif (unitType == "mech")       then return "Mech units can capture bases, traverse most terrain types, and have superior firepower."
            elseif (unitType == "bike")       then return "Bikes are infantry units with high mobility. They can capture bases but have low firepower."
            elseif (unitType == "recon")      then return "Recon units have high movement range and are strong against infantry units."
            elseif (unitType == "flare")      then return "Flares fire bright rockets that reveal a 13-square area in Fog of War."
            elseif (unitType == "antiair")    then return "Anti-Air units work well against infantry and air units. They're weak against tanks."
            elseif (unitType == "tank")       then return "Tank units have high movement range and are inexpensive, so they're easy to deploy."
            elseif (unitType == "mdtank")     then return "Md(Medium) tank units' defensive and offensive ratings are the second best among ground units."
            elseif (unitType == "wartank")    then return "War Tank units are the strongest tanks in terms of both attack and defense."
            elseif (unitType == "artillery")  then return "Artillery units are an inexpensive way to gain indirect offensive attack capabilities."
            elseif (unitType == "antitank")   then return "Anti-Tanks can counter-attack when under direct fire."
            elseif (unitType == "rockets")    then return "Rockets units are valuable, because they can fire on both land and naval units."
            elseif (unitType == "missiles")   then return "Missiles units are essential in defending against air units. Their vision range is large."
            elseif (unitType == "rig")        then return "Rig units can carry 1 foot soldier and build temp airports/seaports."
            elseif (unitType == "fighter")    then return "Fighter units are strong vs. other air units. They also have the highest movements."
            elseif (unitType == "bomber")     then return "Bomber units can fire on ground and naval units with a high destructive force."
            elseif (unitType == "duster")     then return "Dusters are somewhat powerful planes that can attack both ground and air units."
            elseif (unitType == "bcopter")    then return "B(Battle) copter units can fire on many unit types, so they're quite valuable."
            elseif (unitType == "tcopter")    then return "T(transport) copters can transport both infantry and mech units."
            elseif (unitType == "seaplane")   then return "Seaplanes are produced at sea by carriers. They can attack any unit."
            elseif (unitType == "battleship") then return "Battleships can launch indirect attack after moving."
            elseif (unitType == "carrier")    then return "Carriers can carrier 2 air units and produce seaplanes."
            elseif (unitType == "submarine")  then return "Submerged submarines are difficult to find, and only cruisers and subs can fire on them."
            elseif (unitType == "cruiser")    then return "Cruisers are strong against subs and air units, and they can carry two copter units."
            elseif (unitType == "lander")     then return "Landers can transport two ground units. If the lander sinks, the units vanish."
            elseif (unitType == "gunboat")    then return "Gunboats can carry 1 foot soldier and attack other naval units."
            else                                   return "Unknown"
            end
        end,
    },
    [115] = {
        [1] = function(weaponType)
            if     (weaponType == "MachineGun")   then return "机关枪"
            elseif (weaponType == "Barzooka")     then return "反坦克火箭筒"
            elseif (weaponType == "Cannon")       then return "加农炮"
            elseif (weaponType == "TankGun")      then return "坦克炮"
            elseif (weaponType == "HeavyTankGun") then return "重型坦克炮"
            elseif (weaponType == "MegaGun")      then return "弩级主炮"
            elseif (weaponType == "Rockets")      then return "火箭炮"
            elseif (weaponType == "AAMissiles")   then return "对空导弹"
            elseif (weaponType == "Bombs")        then return "炸弹"
            elseif (weaponType == "Missiles")     then return "导弹"
            elseif (weaponType == "AAGun")        then return "防空炮"
            elseif (weaponType == "Torpedoes")    then return "鱼雷"
            elseif (weaponType == "ASMissiles")   then return "反舰导弹"
            else                                       return "未知"
            end
        end,
        [2] = function(weaponType)
            if     (weaponType == "MachineGun")   then return "Machine Gun"
            elseif (weaponType == "Barzooka")     then return "Barzooka"
            elseif (weaponType == "Cannon")       then return "Cannon"
            elseif (weaponType == "TankGun")      then return "Tank Gun"
            elseif (weaponType == "HeavyTankGun") then return "Heavy Tank Gun"
            elseif (weaponType == "MegaGun")      then return "Mega Gun"
            elseif (weaponType == "Rockets")      then return "Rockets"
            elseif (weaponType == "AAMissiles")   then return "AA Missiles"
            elseif (weaponType == "Bombs")        then return "Bombs"
            elseif (weaponType == "Missiles")     then return "Missiles"
            elseif (weaponType == "AAGun")        then return "AA Gun"
            elseif (weaponType == "Torpedoes")    then return "Torpedoes"
            elseif (weaponType == "ASMissiles")   then return "AS Missiles"
            else                                       return "unrecognized"
            end
        end,
    },
    [116] = {
        [1] = function(tileType)
            if     (tileType == "plain")         then return "平原"
            elseif (tileType == "river")         then return "河流"
            elseif (tileType == "sea")           then return "海洋"
            elseif (tileType == "beach")         then return "海滩"
            elseif (tileType == "road")          then return "道路"
            elseif (tileType == "bridgeOnRiver") then return "桥梁"
            elseif (tileType == "bridgeOnSea")   then return "桥梁"
            elseif (tileType == "wood")          then return "森林"
            elseif (tileType == "mountain")      then return "山地"
            elseif (tileType == "wasteland")     then return "荒野"
            elseif (tileType == "ruins")         then return "废墟"
            elseif (tileType == "fire")          then return "火焰"
            elseif (tileType == "rough")         then return "巨浪"
            elseif (tileType == "mist")          then return "迷雾"
            elseif (tileType == "reef")          then return "礁石"
            elseif (tileType == "plasma")        then return "等离子体"
            elseif (tileType == "meteor")        then return "陨石"
            elseif (tileType == "silo")          then return "导弹发射井"
            elseif (tileType == "hq")            then return "总部"
            elseif (tileType == "city")          then return "城市"
            elseif (tileType == "comtower")      then return "指挥塔"
            elseif (tileType == "radar")         then return "雷达"
            elseif (tileType == "factory")       then return "工厂"
            elseif (tileType == "airport")       then return "机场"
            elseif (tileType == "seaport")       then return "海港"
            elseif (tileType == "tempairport")   then return "临时机场"
            elseif (tileType == "tempseaport")   then return "临时海港"
            else                                      return "未知"
            end
        end,
        [2] = function(tileType)
            if     (tileType == "plain")         then return "Plain"
            elseif (tileType == "river")         then return "River"
            elseif (tileType == "sea")           then return "Sea"
            elseif (tileType == "beach")         then return "Beach"
            elseif (tileType == "road")          then return "Road"
            elseif (tileType == "bridgeOnRiver") then return "Bridge"
            elseif (tileType == "bridgeOnSea")   then return "Bridge"
            elseif (tileType == "wood")          then return "Wood"
            elseif (tileType == "mountain")      then return "Mtn"
            elseif (tileType == "wasteland")     then return "Wstld"
            elseif (tileType == "ruins")         then return "Ruins"
            elseif (tileType == "fire")          then return "Fire"
            elseif (tileType == "rough")         then return "Rough"
            elseif (tileType == "mist")          then return "Mist"
            elseif (tileType == "reef")          then return "Reef"
            elseif (tileType == "plasma")        then return "Plasma"
            elseif (tileType == "meteor")        then return "Meteor"
            elseif (tileType == "silo")          then return "Silo"
            elseif (tileType == "hq")            then return "HQ"
            elseif (tileType == "city")          then return "City"
            elseif (tileType == "comtower")      then return "Com"
            elseif (tileType == "radar")         then return "Radar"
            elseif (tileType == "factory")       then return "Fctry"
            elseif (tileType == "airport")       then return "APort"
            elseif (tileType == "seaport")       then return "SPort"
            elseif (tileType == "tempairport")   then return "TempAP"
            elseif (tileType == "tempseaport")   then return "TempSP"
            else                                      return "未知"
            end
        end,
    },
    [117] = {
        [1] = function(tileType)
            if     (tileType == "plain")         then return "平原：允许空军和陆军通过。"
            elseif (tileType == "river")         then return "河流：只允许空军、步兵和炮兵通过。"
            elseif (tileType == "sea")           then return "海洋：允许空军和海军快速通过。"
            elseif (tileType == "beach")         then return "海滩：登陆舰和炮艇可以在这里装载和卸载部队。允许大多数部队通过。"
            elseif (tileType == "road")          then return "道路：允许空军和陆军快速通过。"
            elseif (tileType == "bridgeOnRiver") then return "桥梁：河流及陆地上的桥梁允许空军和陆军快速通过。"
            elseif (tileType == "bridgeOnSea")   then return "桥梁：海洋上的桥梁允许空军和陆军快速通过，海军也能经过和停留。"
            elseif (tileType == "wood")          then return "森林：允许空军和陆军通过。在雾战时，为陆军提供隐蔽场所。"
            elseif (tileType == "mountain")      then return "山地：允许空军、步兵和炮兵。在雾战时，为步兵和炮兵提供额外视野。"
            elseif (tileType == "wasteland")     then return "荒野：允许空军和陆军通过，但会减缓步兵和炮兵以外的陆军的移动。"
            elseif (tileType == "ruins")         then return "废墟：允许空军和陆军通过。雾战时，为陆军提供隐蔽场所。"
            elseif (tileType == "fire")          then return "火焰：不允许任何部队通过。在雾战时无条件照明周围5格内的区域。"
            elseif (tileType == "rough")         then return "巨浪：允许空军和海军通过，但会减缓海军的移动。"
            elseif (tileType == "mist")          then return "迷雾：允许空军和海军通过。在雾战时，为海军提供隐蔽场所。"
            elseif (tileType == "reef")          then return "礁石：允许空军和海军通过，但会减缓海军的移动。在雾战时，为海军提供隐蔽场所。"
            elseif (tileType == "plasma")        then return "等离子体：不允许任何部队通过。"
            elseif (tileType == "meteor")        then return "陨石：不允许任何部队通过。可以被部队攻击和破坏。"
            elseif (tileType == "silo")          then return "导弹发射井：步兵系可以在这里发射一次导弹，用来打击任意位置的小范围的部队。"
            elseif (tileType == "hq")            then return "总部：可以提供资金和维修陆军。若我方总部被占领，则我方战败。"
            elseif (tileType == "city")          then return "城市：可以提供资金和维修陆军。"
            elseif (tileType == "comtower")      then return "指挥塔：可以提供资金，且为我方全体部队提供攻击加成。"
            elseif (tileType == "radar")         then return "雷达：可以提供资金，且在雾战时照明5格范围内的区域。"
            elseif (tileType == "factory")       then return "工厂：可以提供资金、生产和维修陆军。"
            elseif (tileType == "airport")       then return "机场：可以提供资金、生产和维修空军。"
            elseif (tileType == "seaport")       then return "海港：可以提供资金、生产和维修海军。"
            elseif (tileType == "tempairport")   then return "临时机场：可以维修空军。不提供资金，也不能生产部队。"
            elseif (tileType == "tempseaport")   then return "临时海港：可以维修海军。不提供资金，也不能生产部队。"
            else                                      return "未知"
            end
        end,
        [2] = function(tileType)
            if     (tileType == "plain")         then return "Plains are easily traveled but offer little defense."
            elseif (tileType == "river")         then return "Rivers can be passed by foot soldiers only."
            elseif (tileType == "sea")           then return "Seas provide good mobility for air and naval units."
            elseif (tileType == "beach")         then return "Beaches provide places for landers and gunboats to load and unload units."
            elseif (tileType == "road")          then return "Roads provide optimum mobility but little defensive cover."
            elseif (tileType == "bridgeOnRiver") then return "Naval units can't pass under river/land bridges."
            elseif (tileType == "bridgeOnSea")   then return "Naval units can pass under sea bridges."
            elseif (tileType == "wood")          then return "Woods provide hiding places for ground units in Fog of War."
            elseif (tileType == "mountain")      then return "Mountains add 3 vision for foot soldiers in Fog of War."
            elseif (tileType == "wasteland")     then return "Wastelands impair mobility for all but air units and foot soldiers."
            elseif (tileType == "ruins")         then return "Ruins provide hiding places for ground units in Fog of War."
            elseif (tileType == "fire")          then return "Fires prevent unit movement and illuminate a 5-square area in Fog of War."
            elseif (tileType == "rough")         then return "Rough seas slow the movement of naval units."
            elseif (tileType == "mist")          then return "Mists provide hiding places for naval units in Fog of War."
            elseif (tileType == "reef")          then return "Reefs provide hiding places for naval units in Fog of War."
            elseif (tileType == "plasma")        then return "Plasma is impassable."
            elseif (tileType == "meteor")        then return "Meteors are impassable but can be destroyed."
            elseif (tileType == "silo")          then return "Silos can be launched by infantry units and damage a 13-square area."
            elseif (tileType == "hq")            then return "HQs provide resupply for ground units. Battle ends if it's captured."
            elseif (tileType == "city")          then return "Cities provide resupply for ground units."
            elseif (tileType == "comtower")      then return "Command towers boosts your attack once captured."
            elseif (tileType == "radar")         then return "Radars reveal a 5-square area in Fog of War once captured."
            elseif (tileType == "factory")       then return "Factories can be used to resupply and produce ground units once captured."
            elseif (tileType == "airport")       then return "Airports can be used to resupply and produce air units once captured."
            elseif (tileType == "seaport")       then return "Seaports can be used to resupply and produce naval units once captured."
            elseif (tileType == "tempairport")   then return "Temp airports provide resupply for air units."
            elseif (tileType == "tempseaport")   then return "Temp seaports provide resupply for naval units."
            else                                      return "未知"
            end
        end,
    },
}

--------------------------------------------------------------------------------
-- The public functions.
--------------------------------------------------------------------------------
function LocalizationFunctions.setLanguageCode(languageCode)
    assert((languageCode == 1) or (languageCode == 2), "LocalizationFunctions.setLanguageCode() the param is invalid.")
    s_LanguageCode = languageCode

    return LocalizationFunctions
end

function LocalizationFunctions.getLanguageCode()
    return s_LanguageCode
end

function LocalizationFunctions.getLocalizedText(textCode, ...)
    return s_Texts[textCode][s_LanguageCode](...)
end

return LocalizationFunctions

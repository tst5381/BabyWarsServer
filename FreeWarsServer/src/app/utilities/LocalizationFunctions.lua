
local LocalizationFunctions = {}

local s_LanguageCode = 1

local s_LongText1_1 = [[
--- 注：游戏尚有部分功能未完成开发，请谅解。---

--- 游戏流程 ---
首先，您需要通过主菜单的“注册/登陆”功能以进入游戏大厅。成功后，主菜单将出现新的选项，您可以通过它们来进入战局。

自行建立战局-开战的流程：
1. 通过“新建战局”选项来创建新的战局。在里面，您可以随意更改地图、回合顺序、雾战、积分战等多种设定。
2. 耐心等待他人加入您所创建的战局（满员前，您无法进入战局）。
3. 当战局满员后，点击“继续”选项，里面将出现该战局（未满员时，该战局将不会出现！）。点击相应选项即可进入战局。

加入他人战局的流程：
1. 点击“参战”，里面将列出您可以加入的的战局。您也可以通过里面的“搜索”按钮，用房间号来筛选出您所希望加入的战局。
2. 选中您所希望加入的战局，再选择回合顺序、密码等设定，并确认加入战局（注意，游戏不会自动进入战局画面）。
3. 回到主菜单选择“继续”，里面会出现该战局（前提是该战局已经满员）。点击相应选项即可进入战局。
]]
local s_LongText1_2 = "Untranslated"

local s_LongText2_1 = [[
--- 战局操作 ---
本作的战局操作方式类似于《Advance War: Days of Ruin》。

点击您的空闲的工厂等建筑将出现可生产的部队的列表，由此您可以选择需要生产何种部队。一旦选定就将无法撤销。

点击您的未行动的部队将出现移动范围，由此您可以规划其移动路线及进一步的动作。当您完全规划好一个部队的行动后，它就将按照此规划进行行动。
在规划完全确定前，您都可以通过点击无关的棋盘格子来中途撤销，部队不会有任何动作；但若完全确定了规划，则部队将立刻进行行动，您无法撤销。

指定移动路线：选中想要移动的部队，将光标从部队身上拖动出来，则游戏将按照您的拖动来画出移动路线。
该部队将严格按照路线来移动，由此您可以侦查或避开特定目标。

战局画面的左（右）上角有一个关于玩家简要信息的标识框。点击它将弹出战局菜单，您可以通过菜单实现退出、结束回合等操作。
战局画面的左（右）下角有光标所在的地形（部队）的标识框。点击它会弹出该地形（部队）的详细信息框。

您可以随意拖动地图（使用单个手指滑动画面）和缩放地图（使用两个手指滑动画面）。

您可以预览对手部队的移动/攻击范围：点击对方部队即可。可以同时预览多个部队的攻击范围。
]]
local s_LongText2_2 = "Untranslated"

local s_LongText3_1 = [[
--- 关于本作 ---
《FreeWars》（暂名）是以《Advance Wars》系列的设定为基础的同人作品。本作旨在为高级战争的爱好者们提供一个兼顾公平性和自由度的联网对战平台。

本作的兵种、地形等设定取材于《Advance Wars: Days of Ruin》，CO系统则取材于《Advance Wars: Dual Strike》，且允许玩家自由搭配技能。

本作有一定复杂度，建议您可以先游玩一下原作，以便更快上手。

QQ交流群：368142455

作者：Babygogogo

协力（字母序）：
RushFTK
3Au
新CO
赵天同

原作：《Advance Wars》系列
原作开发商：Intelligent Systems
]]
local s_LongText3_2 = "Untranslated"

local s_LongText4_1 = [[
--- 基础概念 ---
回合制：您与您的对手以回合的形式进行游戏。在您的回合中，在游戏规则的限制下，您可以生产新的部队，可以使部队依照您的想法进行行动（当然也可以不动）。
所有必要的行动都完成后，您需要通过战场菜单来结束回合，此时将轮到对手依次行动；所有对手都行动完成后，将再次轮到您进行行动。

胜负判定：若您消灭了某对手的所有部队，或是占领了对方的“总部”（如果总部不止一个，占领任意一个皆可），那么该对手败北；若您是战场上剩下的最后一个玩家，那么您就取得了该战局的胜利。
您也可以在您自己的回合内进行投降，这样您将直接败北。

相同的部队及建筑：不计技能的情况下，所有玩家可用的部队、建筑的种类和属性值都是完全相同的。胜负将直接取决于玩家的指挥水平！

技能：技能是本作最大的特色。每个玩家都可以为自己装配独特的技能，以此获得战场上的某些优势。详细帮助请点击“技能系统”进行查看。

资金：资金主要从您所占有的建筑中获取（每个回合初自动结算入账）。资金主要用于生产（在工厂、机场和海港中）和维修部队。资金直接决定我方部队的数量和质量，因此极为重要。

占领：步兵系部队能够占领建筑。每个建筑都有20点占领点数，步兵系每次进行占领都会将其点数减去该部队的当前HP；当点数降到0或以下，则占领完成。若占领完成前，该部队离开该建筑或被摧毁，则占领点数恢复为20。
仔细规划占领顺序，适当干扰对手占领，能为后续的战斗奠定良好基础。

地形：地形对不同部队的移动速度有不同的影响。刚上手时可能会有些迷惑，您可以多利用预览攻击范围的功能，使您的部队远离对方的威胁。
某些地形能给在其上的部队（不论属于哪位玩家）提供防御力加成（空军除外）。善用这一点，能让您的部队阵型更加坚不可摧。

部队HP：所有部队的HP最大值都是10。如果部队当前HP低于10，则其图标右下角会显示其当前HP。如果部队的HP降为0，则它将被摧毁。
HP直接影响部队的攻击力（4HP的部队的攻击力只有满HP时的40%），因此战斗时要尽量避免被对方先手进攻，并制造我方先手进攻的机会。

直接攻击：您可以把您的直接系部队移动到敌军的旁边，并进行攻击。直接系部队可以在同一回合内同时进行移动和攻击。

间接攻击：您的间接系部队可以远距离对敌军进行攻击。间接攻击不会受到反击，但一般而言，间接系部队不能在同一回合内同时进行移动和攻击。

攻击伤害预览：所有部队的进攻和反击都是必中的。在您选取攻击对象时，游戏会显示该次攻击中，您的部队将造成的伤害以及会被对方反击造成的伤害。伤害预览是忽略幸运因素的，但仍有巨大的参考价值。

幸运伤害：所有部队的进攻和反击都会附带幸运伤害。该伤害与敌我兵种无关，与进攻方当前HP有关。幸运伤害可以被防御方的防御加成（包括地形加成）部分抵消。

部队晋升：部队刚出场时晋升等级为0。每消灭一个敌方部队都可以晋升一次，最多可以晋升到3级。晋升等级会显示在部队图标的左下角（I， II， V）。晋升会加强部队的攻防，三个等级的加成分别是：
I：+5攻/+0防    II：+10攻/+0防    V：+20攻/+20防

主副武器：每个部队都可能有主武器、副武器，也可能只有其中一个或是两种都没有。其中，主武器有弹药量限制：一旦弹药量降为0，则该部队无法再以主武器进行攻击。副武器没有弹药量限制。
主副武器的威力和可攻击对象都各有不同。

燃料：每个部队都有燃料限制。若燃料降为0，则该部队无法移动（但其他行动不受影响）。某些部队若耗尽燃料，在下回合开始前将被自动摧毁。

建造材料：某些部队拥有建造材料，可用于建造特定地形或部队。这些材料一般情况下无法被补给。

部队合流：若一个部队的HP少于10，则您可以指定一个同种类的部队走到该部队所在位置并进行合流。合流后，两个部队的HP值将直接相加，超出10的部分会被等额转换为金钱并可以马上使用。
燃料、弹药、建造材料也将相加（超出上限的舍去），晋升等级则保留较高的那个值。

装载：某些部队可以装载其他部队（操作方法为把装载对象移动到装载者上，并选择装载）。装载后，若装载者移动，则被装载的部队也跟着移动；由此可以迅速移动被装载的部队。但若装载者被摧毁，则装载的部队也跟着消失。
某些装载者可通过卸载指令将装载的部队以待机的形式放置在邻接的格子上；另一些装载者可以弹射装载的部队，后者可以直接进行攻击等行动。

维修：您可以将部队放置在具有维修功能的我方建筑上，那么在下回合初，该部队将自动回复HP（默认2点，不超过上限10）并消耗相应的资金。部队的燃料和弹药也会同时免费补满。
某些部队也能够维修装载在其上的其他部队。

雾战：在雾战中，您只能看见在自己的部队和建筑视野内的敌军部队和建筑，视野外的都将被隐藏。在您的回合中，您可以通过移动部队等手段来扩展视野。占领建筑也有所帮助。
某些地形能够遮蔽视野，您必须有部队在其旁边、或者曾经路过、或以照明弹照明过，才能看到其中可能隐藏着的敌军；相对地，您也可以利用它们来隐藏您的部队。

行动阻挡：若您规划的部队移动路线被隐藏着的敌方部队（不论是被雾战隐藏或是下潜的潜艇）阻挡，则您的部队会在被阻挡的地方直接停下，原先规划的行动也会被取消。要仔细规划部队的移动路线！

照明弹：照明车在雾战中能够发射照明弹，远距离地探明一个区域内的敌军（包括隐蔽地形内的，不包括下潜的潜艇）。

后勤车：后勤车不能进攻，但具有装载、补给邻接部队、建造临时建筑的功能。后勤车能在回合初自动补给邻接的部队（但不能防止后者因耗尽燃料而摧毁）。后勤车建造临时建筑的过程与占领类似，但须消耗自带的建造材料。

航母：航母本身战力较差，但可以用自带的建造材料建造强力的舰载机（需消耗金钱），建造的舰载机会自动装载在航母上。航母能够维修和弹射装载的飞机，因此能形成很大的威胁（但也很贵）。

潜艇：潜艇能够下潜（刚建造时也默认为下潜状态），下潜后对对方不可见（除非有对方部队邻接着潜艇），而且只会受到特定部队的攻击。下潜须在每回合初消耗额外的燃料。
]]
local s_LongText4_2 = "Untranslated"

local s_LongText5_1 = [[
--- 技能系统 ---
概述：通过使用战场上获得的能量，您可以购买战局内永久生效的日常技能，或者发动即时生效但时间短暂的主动技能，从而获得优势。
游戏对技能的组合没有限制。也就是说，只要能量足够，您就可以随意组合您需要的技能。

能量：能量是通过战斗积累的。能量的积累速度只与您对敌方部队造成的HP损伤量、以及自己的部队受到的HP损伤量有关，与部队造价无关。
一个回合中，如果您发动了主动技，则直至您的下个回合开始前，您都无法再通过战斗获得能量。
能量值没有上限。您可以一直积累能量，直到必要时才一次性发动强大的技能。

日常技：日常技是购买后，从下一回合开始生效，直至战局结束才失效的技能。
同名技能可以多次购买，其效果会自动线性叠加。

主动技（特技）：主动技是购买（即发动）后即时生效，直至您的下个回合初失效的技能。您需要提前一回合进行特技宣言，然后才能发动特技。同一回合中，您可以任意发动不限种类和次数的主动技。
比如，如果能量足够，您可以一个回合再动N次，同时增加M%的攻击力。

特技宣言：特技宣言是发动特技前的必须动作，并需要消耗一定的能量值。
发起宣言后，您在下个回合既可以发动特技，也可以不发动，但消耗掉的能量将不予退回。

技能效果叠加：具有持续性的技能的效果是可以线性叠加的。以全军攻击力为例，如果您的日常技能是全军攻击力+10%，某回合分别发动了全军攻击力+10%和+20%的主动技各一次，那么最终效果是全军攻击力+40%。
]]
local s_LongText5_2 = "Untranslated"

local s_LongText6_1 = [[
请注意：
1. 默认情况下，您必须提前一回合发出特技宣言，才能发动特技。
2. 大部分特技的效果只维持到您下个回合初。
3. 一旦发动特技，则直至您下个回合开始前，您都无法再通过战斗获得能量。
4. 您可以多次发动同一个特技；如果可能，其效果将被自动叠加（比如全军加攻等技能）。
5. 您可以任意多次交替发动特技和操作部队。
6. 如有部分按钮不可点击，则是因为您的能量不足。
]]
local s_LongText6_2 = [[
Note:
1. You have to make a skill declaration so that you may activate active skills in your next turn.
2. The skill effect lasts till the beginning of your next turn.
3. Once you activate a skill, you won't get any energy through battles until your next turn begins."
4. You may activate a same skill multiple times.
5. You may move your units, activate skills, again move your units, again activate skills and so on.
6. If your energy is not enough, some buttons will be unavailable.
]]

local s_LongText7_1 = [[
请注意：
1. 本回合研发的日常技将在您的下个回合初生效，直至您战败或获胜时失效。
2. 研发日常技能期间，您仍然可以通过战斗获得能量。
3. 如您多次研发同一个日常技能，则该技能效果将被自动线性叠加。
4. 研发日常技能的时机、种类和次数都没有限制。
5. 如有部分按钮不可点击，则是因为您的能量不足。
]]
local s_LongText7_2 = [[
Note:
1. The skills will be effective from the beginning of your next turn to your lose/victory.
2. You will get energy through battles as usual during the research.
3. You may research a same skill multiple times. The effects will be automatically summarized.
4. You may research any skills any times at any time in your turn.
5. If your energy is not enough, some buttons will be unavailable.
]]

local s_LongText8_1 = [[
本选项控制战局内所有玩家能否使用主动技（特技）。

主动技（特技）是使用能量购买（即发动）后即时生效，直至您的下个回合初失效的技能。
任意玩家都可以任意发动不限种类和次数的主动技。

默认为“是”。
]]

local s_LongText8_2 = [[
Untranslated...
]]

local s_LongText9_1 = [[
本选项可控制战局内所有玩家能否使用日常技。

日常技是使用能量购买后，从您的下个回合初开始生效，直至战局结束才失效的技能。
任意玩家都可以任意购买不限种类和次数的日常技。

默认为“是”。
]]

local s_LongText9_2 = [[
Untranslated...
]]

local s_LongText10_1 = [[
本选项影响战局内所有玩家获取能量的速度。

默认（100%）情况下，您的部队每受到1HP伤害、或每对敌军造成1HP伤害，则您获得100能量。其他玩家亦然。
如选择“0%”，则全体玩家都不能通过战斗获取能量。

默认为“100%”。
]]

local s_LongText10_2 = [[
Untranslated...
]]

local s_LongText11_1 = [[
本选项影响战局是明战或雾战。

明战下，您可以观察到整个战场的情况。雾战下，您只能看到自己军队的视野内的战场情况。
雾战难度相对较大。如果您是新手，建议先通过明战熟悉游戏系统，再尝试雾战模式。

默认为“否”（即明战）。
]]

local s_LongText11_2 = [[
Untranslated...
]]

local s_LongText12_1 = [[
本选项影响所有玩家的回合收入。

默认（100%）情况下，您的每个建筑在每个回合初为您提供1000金钱（少数特殊建筑除外）。其他玩家亦然。
如选择0%，则全体玩家都没有金钱收入。

默认为“100%”。
]]

local s_LongText12_2 = [[
Untranslated...
]]

local s_LongText13_1 = [[
本选项影响所有玩家的每回合的时限。

如果某个玩家的回合时间超出了本限制，则服务器将自动为该玩家执行投降操作。
当战局满员，或某个玩家结束回合后，则服务器自动开始下个玩家回合的倒计时（无论该玩家是否在线）。
因此，请仅在已约好对手的情况下才选择“15分”，以免造成不必要的败绩。

默认为“3天”。
]]

local s_LongText13_2 = [[
Untranslated...
]]

local s_LongText14_1 = [[
本选项影响参战玩家之间的最大积分差距。

积分代表着一个玩家的实力。通过本选项，您可以限制参战玩家之间的积分差距，以避免实力差距过大而影响游戏体验。
请注意，此选项不限制正负差距。也就是说，参战玩家的积分既可能比您的少，也可能比您的多。

默认为“100”。
]]

local s_LongText14_2 = [[
Untranslated...
]]

local s_LongText15_1 = [[
本选项影响您在回合中的行动顺序。

本游戏固定了每回合中的行动顺序为：
1 红方
2 蓝方
3 黄方
4 黑方
其中，2人局不存在黄方和黑方，3人局不存在黑方。
每个玩家只能选择其中一项，不能重复。

默认为当前可用选项中最靠前的一项。
]]

local s_LongText15_2 = [[
Untranslated...
]]

local s_LongText16_1 = [[
本选项规定本战局的结果是否影响玩家的积分。

积分代表着一个玩家的实力。
积分赛中，如果您获胜，则您的积分将增加，败者的积分将减少。您原本的积分越是比对方少，则获得的积分越多，反之亦然。
如果和局，且您的分数较对手少，则您也可以获得少量积分，反之亦然。
非积分赛中，无论战果如何，您的积分都不会受到影响。

很显然，积分赛中，您的对手不会轻易认输。如果要玩积分赛，请全力以赴吧。

默认为“否”（即非积分赛）。
]]

local s_LongText16_2 = [[
Untranslated...
]]

local s_LongText17_1 = [[
本选项规定本战局所有玩家的初始能量值。

能量值可以用来发动主动技或购买日常技，是游戏中重要的资源。

默认为“0”。
]]

local s_LongText17_2 = [[
Untranslated...
]]

local s_LongText18_1 = [[
本选项规定本战局所有玩家的初始资金。

资金可以用来购买新的单位，是游戏中重要的资源。

默认为“0”。
]]

local s_LongText18_2 = [[
Untranslated...
]]

local s_LongText19_1 = [[
本选项规定本战局所有玩家发动特技前是否需要宣言。

如果选“是”，则玩家需要提前一个回合进行宣言，下回合才能发动特技（也可以不发动）。宣言需要消耗一定能量。
如果选“否”，则玩家只要能量足够，就可以随时发动特技。

默认为“是”。
]]

local s_LongText19_2 = [[
Untranslated...
]]

local s_LongText20_1 = [[
本选项规定本战局所有玩家所有部队的移动力加成。

如果选正数，则部队的移动力相应增加，反之亦然。
部队的最终移动力最低为1。

默认为“0”。
]]

local s_LongText20_2 = [[
Untranslated...
]]

local s_LongText21_1 = [[
本选项规定本战局所有玩家所有部队的攻击力加成。

如果选正数，则部队的攻击力相应增加，反之亦然。
本加成与其他加成（如技能、部队等级、指挥塔等）是线性叠加的。也就是说，如果其他加成合计为+20%，而本加成为-30%攻，则合计为-10%攻。

默认为“0%”。
]]

local s_LongText21_2 = [[
Untranslated...
]]

local s_LongText22_1 = [[
本选项规定本战局所有玩家所有部队/建筑的视野加成。

如果选正数，则部队/建筑的视野相应增加，反之亦然。
部队/建筑的最终视野最低为1。

默认为“0”。
]]

local s_LongText22_2 = [[
Untranslated...
]]

local s_LongText23_1 = [[
本选项规定您所属的队伍。

战局中，属于同一队伍的玩家共享视野，部队能够相互穿越，不能相互攻击/装载/用后勤车补给。
此外，可以使用队友的建筑来维修/补给自己的部队（消耗自己的金钱），但不能占领队友的建筑。

默认为当前未被其他玩家选用的队伍中最靠前的一项。
]]

local s_LongText23_2 = [[
Untranslated...
]]

local s_LongText24_1 = [[
本选项规定战局存档的位置。

本游戏有多个相互独立的存档位置，您可以任选一个用于保存战局的进度。
进入战局后，您可以随时存档/读档，但不能再更改存档的位置。

默认为"1"。
]]

local s_LongText24_2 = [[
Untranslated...
]]

local s_LongText25_1 = [[
关于预备主动技的说明：
1. 预备主动技用于改变您的主动技的具体效果。
2. 设置预备主动技后，在您的下个回合初，系统会自动用预备主动技替换掉您的主动技。之后，只要能量足够，您就可以在您的回合中发动主动技。
3. 您可以任意设置预备主动技，其威力、类别都没有限制。
4. 预备主动技最多包含四个技能，且不能包含重复的技能。
5. 设定预备主动技不需要消耗能量。
]]

local s_LongText25_2 = [[
Untranslated...
]]

--------------------------------------------------------------------------------
-- The private functions.
--------------------------------------------------------------------------------
local s_Texts = {
    [1] = {
        [1] = function(textType)
            if     (textType == "About")               then return "关 于 本 作"
            elseif (textType == "AuxiliaryCommands")   then return "辅 助 功 能"
            elseif (textType == "Back")                then return "返 回"
            elseif (textType == "Campaign")            then return "战 役"
            elseif (textType == "Close")               then return "关 闭"
            elseif (textType == "ConfigSkills")        then return "配 置 技 能"
            elseif (textType == "Confirm")             then return "确 定"
            elseif (textType == "Continue")            then return "继 续"
            elseif (textType == "EssentialConcept")    then return "基 础 概 念"
            elseif (textType == "Exit")                then return "退 出"
            elseif (textType == "ExitWar")             then return "退 出 战 局"
            elseif (textType == "Free Game")           then return "自 由 战 斗"
            elseif (textType == "GameFlow")            then return "游 戏 流 程"
            elseif (textType == "Help")                then return "帮 助"
            elseif (textType == "JoinWar")             then return "参 战"
            elseif (textType == "Load Game")           then return "读 档"
            elseif (textType == "Login")               then return "注 册 / 登 陆"
            elseif (textType == "MainMenu")            then return "主  菜  单"
            elseif (textType == "ManageReplay")        then return "管 理 回 放"
            elseif (textType == "MultiPlayersGame")    then return "多 人 对 战"
            elseif (textType == "MyProfile")           then return "我 的 战 绩"
            elseif (textType == "NewGame")             then return "新 建 战 局"
            elseif (textType == "RankingList")         then return "排 行 榜"
            elseif (textType == "Save")                then return "保 存"
            elseif (textType == "SetMessageIndicator") then return "开/关信息提示"
            elseif (textType == "SetMusic")            then return "开 / 关 音 乐"
            elseif (textType == "SinglePlayerGame")    then return "单 机 模 式"
            elseif (textType == "SkillSystem")         then return "技 能 系 统"
            elseif (textType == "ViewGameRecord")      then return "浏 览 战 绩"
            elseif (textType == "WarControl")          then return "战 局 操 作"
            else                                            return "未知1:" .. (textType or "")
            end
        end,
        [2] = function(textType)
            if     (textType == "About")               then return "About"
            elseif (textType == "AuxiliaryCommands")   then return "AuxiliaryCmds"
            elseif (textType == "Back")                then return "Back"
            elseif (textType == "Campaign")            then return "Campaign"
            elseif (textType == "Close")               then return "Close"
            elseif (textType == "ConfigSkills")        then return "Config Skills"
            elseif (textType == "Confirm")             then return "Confirm"
            elseif (textType == "Continue")            then return "Continue"
            elseif (textType == "EssentialConcept")    then return "Concept"
            elseif (textType == "Exit")                then return "Exit"
            elseif (textType == "ExitWar")             then return "Exit"
            elseif (textType == "Free Game")           then return "Free Game"
            elseif (textType == "GameFlow")            then return "Game Flow"
            elseif (textType == "Help")                then return "Help"
            elseif (textType == "JoinWar")             then return "Join"
            elseif (textType == "Load Game")           then return "Load Game"
            elseif (textType == "Login")               then return "Login"
            elseif (textType == "MainMenu")            then return "Main Menu"
            elseif (textType == "ManageReplay")        then return "ManageReplay"
            elseif (textType == "MultiPlayersGame")    then return "MultiPlayers"
            elseif (textType == "MyProfile")           then return "My Profile"
            elseif (textType == "NewGame")             then return "New Game"
            elseif (textType == "RankingList")         then return "RankingList"
            elseif (textType == "Save")                then return "Save"
            elseif (textType == "SetMessageIndicator") then return "Set Message"
            elseif (textType == "SetMusic")            then return "Set Music"
            elseif (textType == "SinglePlayerGame")    then return "SinglePlayer"
            elseif (textType == "SkillSystem")         then return "Skills"
            elseif (textType == "ViewGameRecord")      then return "View Records"
            elseif (textType == "WarControl")          then return "Controlling"
            else                                            return "Unknown1:" .. (textType or "")
            end
        end,
    },
    [2] = {
        [1] = function(textCode)
            if     (textCode == 1) then return s_LongText1_1
            elseif (textCode == 2) then return s_LongText2_1
            elseif (textCode == 3) then return s_LongText3_1
            elseif (textCode == 4) then return s_LongText4_1
            elseif (textCode == 5) then return s_LongText5_1
            else                        return "未知[2]: " .. (textCode or "")
            end
        end,
        [2] = function(textCode)
            if     (textCode == 1) then return s_LongText1_2
            elseif (textCode == 2) then return s_LongText2_2
            elseif (textCode == 3) then return s_LongText3_2
            elseif (textCode == 4) then return s_LongText4_2
            elseif (textCode == 5) then return s_LongText5_2
            else                        return "Unknown[2]: " .. (textCode or "")
            end
        end,
    },
    [3] = {
        [1] = function(textType)
            if     (textType == "ActiveSkill")             then return "主 动 技 能"
            elseif (textType == "Clear")                   then return "清 空"
            elseif (textType == "Configuration")           then return "配 置"
            elseif (textType == "ConfirmActivateSkill")    then return "是否确定要发动主动技？"
            elseif (textType == "ConfirmExitConfiguring")  then return "是否确定要停止配置技能，并返回上层菜单？"
            elseif (textType == "ConfirmGiveUpSettings")   then return "您确定要放弃更改吗？"
            elseif (textType == "ConfirmReserveSkills")    then return "您确定要设置这些预备技能吗？"
            elseif (textType == "CurrentEnergy")           then return "当前能量"
            elseif (textType == "CurrentPosition")         then return "当前位置"
            elseif (textType == "Default")                 then return "默认"
            elseif (textType == "Disable")                 then return "禁 用"
            elseif (textType == "Disabled")                then return "已 禁 用"
            elseif (textType == "DuplicatedReserveSkills") then return "预备技能中包含重复的技能，请删除后重试。"
            elseif (textType == "Enable")                  then return "启 用"
            elseif (textType == "EnergyCost")              then return "消耗能量"
            elseif (textType == "EnergyRequirement")       then return "能量槽长度"
            elseif (textType == "GettingConfiguration")    then return "正在从服务器获取配置数据，请稍候。若长时间没有反应，请返回并重试。"
            elseif (textType == "Level")                   then return "等级"
            elseif (textType == "MaxPoints")               then return "可用总技能点"
            elseif (textType == "MinEnergy")               then return "最小能量槽"
            elseif (textType == "Modifier")                then return "幅度"
            elseif (textType == "NoActiveSkills")          then return "您目前没有主动技能，无法发动。"
            elseif (textType == "None")                    then return "无"
            elseif (textType == "NoReserveSkills")         then return "您尚未设定任何预备技能。"
            elseif (textType == "NoSkills")                then return "没有任何技能"
            elseif (textType == "PassiveSkill")            then return "日 常 技 能"
            elseif (textType == "Selected")                then return "已 选 定"
            elseif (textType == "SetEnergyRequirement")    then return "设定能量槽长度"
            elseif (textType == "SetSkillPoint")           then return "设定基准技能点数"
            elseif (textType == "SettingConfiguration")    then return "正在传输配置数据到服务器，请稍候。若长时间没有反应，请重试。"
            elseif (textType == "Skill")                   then return "技 能"
            elseif (textType == "SkillActive")             then return "主动技能"
            elseif (textType == "SkillPassive")            then return "日常技能"
            elseif (textType == "SkillPoints")             then return "技能点"
            elseif (textType == "SkillResearching")        then return "研发中的日常技能"
            elseif (textType == "SkillReserve")            then return "预备主动技能"
            elseif (textType == "TotalPoints")             then return "已用技能点"
            else                                                return "未知[3]: " .. (textType or "")
            end
        end,
        [2] = function(textType)
            if     (textType == "ActiveSkill")             then return "Active"
            elseif (textType == "Clear")                   then return "Clear"
            elseif (textType == "Configuration")           then return "Configuration"
            elseif (textType == "ConfirmActivateSkill")    then return "Are you sure to activate the active skills?"
            elseif (textType == "ConfirmExitConfiguring")  then return "Are you sure to quit the configuration?"
            elseif (textType == "ConfirmGiveUpSettings")   then return "Are you sure to give up the modified settings?"
            elseif (textType == "ConfirmReserveSkills")    then return "Are you sure to update the reserve skills?"
            elseif (textType == "CurrentEnergy")           then return "CurrentEnergy"
            elseif (textType == "CurrentPosition")         then return "Add"
            elseif (textType == "Default")                 then return "Default"
            elseif (textType == "Disable")                 then return "Disable"
            elseif (textType == "Disabled")                then return "Disabled"
            elseif (textType == "DuplicatedReserveSkills") then return "Duplicated reserve skills are not allowed."
            elseif (textType == "Enable")                  then return "Enable"
            elseif (textType == "EnergyCost")              then return "EnergyCost"
            elseif (textType == "EnergyRequirement")       then return "Energy Requirement"
            elseif (textType == "GettingConfiguration")    then return "Getting data from the server. Please wait."
            elseif (textType == "Level")                   then return "Level"
            elseif (textType == "MaxPoints")               then return "Max Skill Points"
            elseif (textType == "MinEnergy")               then return "Min Energy"
            elseif (textType == "Modifier")                then return "Modifier"
            elseif (textType == "NoActiveSkills")          then return "You have no active skills."
            elseif (textType == "None")                    then return "None"
            elseif (textType == "NoSkills")                then return "No skills"
            elseif (textType == "NoReserveSkills")         then return "You haven't set any reserve skill yet."
            elseif (textType == "PassiveSkill")            then return "Passive"
            elseif (textType == "SetSkillPoint")           then return "SetSkillPoint"
            elseif (textType == "Selected")                then return "Selected"
            elseif (textType == "SetEnergyRequirement")    then return "Set Energy"
            elseif (textType == "SettingConfiguration")    then return "Transfering data to the server. Please wait."
            elseif (textType == "Skill")                   then return "Skill"
            elseif (textType == "SkillActive")             then return "Active Skills"
            elseif (textType == "SkillPassive")            then return "Passive Skills"
            elseif (textType == "SkillPoints")             then return "Points"
            elseif (textType == "SkillResearching")        then return "Researching Skills"
            elseif (textType == "SkillReserve")            then return "Reserve Skills"
            elseif (textType == "TotalPoints")             then return "Total Points"
            else                                                return "Unknown[3]: " .. (textType or "")
            end
        end,
    },
    [4] = {
        [1] = function(skillID)
            if     (skillID == 1)  then return "我方全体部队的攻击力"
            elseif (skillID == 2)  then return "我方全体部队的防御力"
            elseif (skillID == 3)  then return "我方全体部队的当前HP"
            elseif (skillID == 4)  then return "对方全体部队的当前HP"
            elseif (skillID == 5)  then return "我方全体部队的移动力"
            elseif (skillID == 6)  then return "我方全体远程部队的射程上限"
            elseif (skillID == 7)  then return "使我方步兵系以外的全体部队变为未行动的状态。"
            elseif (skillID == 8)  then return "我方所有建筑的金钱收入"
            elseif (skillID == 9)  then return "增加我方资金，数量为我军当前收入的"
            elseif (skillID == 10) then return "对方能量值"
            elseif (skillID == 11) then return "我方建筑及部队的维修量"
            elseif (skillID == 12) then return "我方步兵系的占领速度（四舍五入）"
            elseif (skillID == 13) then return "我方能量值获取速度（四舍五入）"
            elseif (skillID == 14) then return "我方能量值获取速度（不受战局设定影响）"
            else                        return "未知4:" .. (skillID or "")
            end
        end,
        [2] = function(skillID)
            return "Untranslated..."
        end,
    },
    [5] = {
        [1] = function(skillID)
            if     (skillID == 1)  then return "全军攻击力"
            elseif (skillID == 2)  then return "全军防御力"
            elseif (skillID == 3)  then return "全军HP"
            elseif (skillID == 4)  then return "敌军HP"
            elseif (skillID == 5)  then return "全军移动力"
            elseif (skillID == 6)  then return "远程部队射程"
            elseif (skillID == 7)  then return "再动"
            elseif (skillID == 8)  then return "我军收入"
            elseif (skillID == 9)  then return "我军资金"
            elseif (skillID == 10) then return "敌军能量值"
            elseif (skillID == 11) then return "我军维修量"
            elseif (skillID == 12) then return "占领速度"
            elseif (skillID == 13) then return "能量增速"
            elseif (skillID == 14) then return "能量增速"
            else                        return "未知5:" .. (skillID or "")
            end
        end,
        [2] = function(skillID)
            return "Untranslated..."
        end,
    },
    [6] = {
        [1] = function(skillCategory)
            if     (skillCategory == "SkillCategoryPassiveAttack")      then return "攻 击 类"
            elseif (skillCategory == "SkillCategoryPassiveDefense")     then return "防 御 类"
            elseif (skillCategory == "SkillCategoryPassiveMoney")       then return "金 钱 类"
            elseif (skillCategory == "SkillCategoryPassiveMovement")    then return "移 动 类"
            elseif (skillCategory == "SkillCategoryPassiveAttackRange") then return "射 程 类"
            elseif (skillCategory == "SkillCategoryPassiveCapture")     then return "占 领 类"
            elseif (skillCategory == "SkillCategoryPassiveRepair")      then return "维 修 类"
            elseif (skillCategory == "SkillCategoryPassivePromotion")   then return "晋 升 类"
            elseif (skillCategory == "SkillCategoryPassiveEnergy")      then return "能 量 类"
            elseif (skillCategory == "SkillCategoryPassiveVision")      then return "视 野 类"
            elseif (skillCategory == "SkillCategoryActiveAttack")       then return "攻 击 类"
            elseif (skillCategory == "SkillCategoryActiveDefense")      then return "防 御 类"
            elseif (skillCategory == "SkillCategoryActiveMoney")        then return "金 钱 类"
            elseif (skillCategory == "SkillCategoryActiveMovement")     then return "移 动 类"
            elseif (skillCategory == "SkillCategoryActiveAttackRange")  then return "射 程 类"
            elseif (skillCategory == "SkillCategoryActiveCapture")      then return "占 领 类"
            elseif (skillCategory == "SkillCategoryActiveHP")           then return "HP 类"
            elseif (skillCategory == "SkillCategoryActivePromotion")    then return "晋 升 类"
            elseif (skillCategory == "SkillCategoryActiveEnergy")       then return "能 量 类"
            elseif (skillCategory == "SkillCategoryActiveLogistics")    then return "后 勤 类"
            elseif (skillCategory == "SkillCategoryActiveVision")       then return "视 野 类"
            else                                                        return "未知6:" .. (skillCategory or "")
            end
        end,
        [2] = function(skillCategory)
            if     (skillCategory == "SkillCategoryPassiveAttack")      then return "Attack"
            elseif (skillCategory == "SkillCategoryPassiveDefense")     then return "Defense"
            elseif (skillCategory == "SkillCategoryPassiveMoney")       then return "Money"
            elseif (skillCategory == "SkillCategoryPassiveMovement")    then return "Movement"
            elseif (skillCategory == "SkillCategoryPassiveAttackRange") then return "AttackRange"
            elseif (skillCategory == "SkillCategoryPassiveCapture")     then return "Capture"
            elseif (skillCategory == "SkillCategoryPassiveRepair")      then return "Repair"
            elseif (skillCategory == "SkillCategoryPassivePromotion")   then return "Promotion"
            elseif (skillCategory == "SkillCategoryPassiveEnergy")      then return "Energy"
            elseif (skillCategory == "SkillCategoryPassiveVision")      then return "Vision"
            elseif (skillCategory == "SkillCategoryActiveAttack")       then return "Attack"
            elseif (skillCategory == "SkillCategoryActiveDefense")      then return "Defense"
            elseif (skillCategory == "SkillCategoryActiveMoney")        then return "Money"
            elseif (skillCategory == "SkillCategoryActiveMovement")     then return "Movement"
            elseif (skillCategory == "SkillCategoryActiveAttackRange")  then return "AttackRange"
            elseif (skillCategory == "SkillCategoryActiveCapture")      then return "Capture"
            elseif (skillCategory == "SkillCategoryActiveHP")           then return "HP"
            elseif (skillCategory == "SkillCategoryActivePromotion")    then return "Promotion"
            elseif (skillCategory == "SkillCategoryActiveEnergy")       then return "Energy"
            elseif (skillCategory == "SkillCategoryActiveLogistics")    then return "Logistics"
            elseif (skillCategory == "SkillCategoryActiveVision")       then return "Vision"
            else                                                        return "Unknown6:" .. (skillCategory or "")
            end
        end,
    },
    [7] = {
        [1] = function(errType, text)
            text = text or ""
            if     (errType == "InvalidSkillGroupPassive") then return "日常技能不合法。" .. text
            elseif (errType == "InvalidSkillGroupActive1") then return "主动技能 1 不合法。" .. text
            elseif (errType == "InvalidSkillGroupActive2") then return "主动技能 2 不合法。" .. text
            elseif (errType == "ReduplicatedSkills")       then return "同一组别中，不能多次使用同名技能。"
            elseif (errType == "InvalidEnergyRequirement") then return "未满足技能所需的能量槽长度。"
            elseif (errType == "SkillPointsExceedsLimit")  then return "技能点数超出上限。"
            else                                                return "未知[7]: " .. (errType or "")
            end
        end,
        [2] = function(errType)
            if     (errType == "InvalidSkillGroupPassive") then return "Invalid Passive Skills."
            elseif (errType == "InvalidSkillGroupActive1") then return "Invalid Active Skills 1."
            elseif (errType == "InvalidSkillGroupActive2") then return "Invalid Active Skills 2."
            elseif (errType == "ReduplicatedSkills")       then return "Some skills are reduplicated."
            elseif (errType == "InvalidEnergyRequirement") then return "The energy requirement is not large enough for some skills."
            elseif (errType == "SkillPointsExceedsLimit")  then return "The skill points is beyond the limit."
            else                                                return "Unknown[7]: " .. (errType or "")
            end
        end,
    },
    [8] = {
        [1] = function(textType)
            if     (textType == "ExitWarConfirmation") then return "确定要退出该战局吗？"
            elseif (textType == "JoinWarConfirmation") then return "请仔细检查各项设定。\n确定要参战吗？"
            elseif (textType == "NewWarConfirmation")  then return "请仔细检查各项设定。\n确定要创建战局吗？"
            elseif (textType == "NoContinuableWar")    then return "您没有可以继续进行的战局。"
            elseif (textType == "NoWaitingWar")        then return "您没有可以退出的战局。"
            elseif (textType == "TransferingData")     then return "正在传输数据。若长时间没有反应，请返回重试。"
            else                                            return "未知8:" .. (textType or "")
            end
        end,
        [2] = function(textType)
            if     (textType == "ExitWarConfirmation") then return "Are you sure to exit the war?"
            elseif (textType == "JoinWarConfirmation") then return "Are you sure to join the war?"
            elseif (textType == "NewWarConfirmation")  then return "Are you sure to create the war?"
            elseif (textType == "NoContinuableWar")    then return "No war is continuable currently."
            elseif (textType == "NoWaitingWar")        then return "There's no war that you can exit currently."
            elseif (textType == "TransferingData")     then return "Transfering data. If it's not responding, please retry."
            else                                            return "Unknown8:"
            end
        end,
    },
    [9] = {
        [1] = function(textType)
            if     (textType == "AttackRange")        then return "射程"
            elseif (textType == "CanAttackAfterMove") then return "可移动后攻击"
            elseif (textType == "ConsumptionPerTurn") then return "每回合消耗"
            elseif (textType == "DestroyOnRunOut")    then return "耗尽后消灭"
            elseif (textType == "MaxAmmo")            then return "主武器最大弹药量"
            elseif (textType == "MaxFuel")            then return "最大燃料值"
            elseif (textType == "Movement")           then return "移动力"
            elseif (textType == "MoveType")           then return "移动类型"
            elseif (textType == "ProductionCost")     then return "造价"
            elseif (textType == "Vision")             then return "视野"
            elseif (textType == false)                then return "否"
            elseif (textType == true)                 then return "是"
            else                                           return "未知9: " .. (textType or "")
            end
        end,
        [2] = function(textType)
            if     (textType == "AttackRange")        then return "AttackRange"
            elseif (textType == "CanAttackAfterMove") then return "CanAttackAfterMove"
            elseif (textType == "ConsumptionPerTurn") then return "ConsumptionPerTurn"
            elseif (textType == "DestroyOnRunOut")    then return "DestroyOnRunOut"
            elseif (textType == "MaxAmmo")            then return "MaxAmmo"
            elseif (textType == "MaxFuel")            then return "MaxFuel"
            elseif (textType == "Movement")           then return "Movement"
            elseif (textType == "MoveType")           then return "MoveType"
            elseif (textType == "ProductionCost")     then return "ProductionCost"
            elseif (textType == "Vision")             then return "Vision"
            elseif (textType == false)                then return "No"
            elseif (textType == true)                 then return "Yes"
            else                                           return "Unknown9: " .. (textType or "")
            end
        end,
    },
    [10] = {
        [1] = function(textType)
            if     (textType == "Delete")                        then return "删 除"
            elseif (textType == "DeleteConfirmation")            then return "您是否确认要删除此回放数据？"
            elseif (textType == "DeleteReplay")                  then return "删 除 回 放"
            elseif (textType == "Download")                      then return "下 载"
            elseif (textType == "DownloadReplay")                then return "下 载 回 放"
            elseif (textType == "DownloadStarted")               then return "正在下载回放数据，请稍候。若长时间没有反应，请重试。"
            elseif (textType == "GetMore")                       then return "获取更多数据"
            elseif (textType == "InvalidWarName")                then return "您输入的房间号无效，请检查后重试。"
            elseif (textType == "LoadingReplay")                 then return "正在载入回放，请耐心等候。"
            elseif (textType == "NoDownloadableReplay")          then return "当前没有可下载的回放数据。请返回。"
            elseif (textType == "NoMoreReplay")                  then return "已没有更多的可下载的回放数据。"
            elseif (textType == "NoReplayData")                  then return "本机没有可供播放或删除的回放数据。请返回。"
            elseif (textType == "Playback")                      then return "播 放"
            elseif (textType == "ReplayDataExists")              then return "该回放数据已下载完成。"
            elseif (textType == "ReplayDataNotExists")           then return "该回放数据不存在，无法下载。若一直遇到此问题，请与作者联系。"
            elseif (textType == "RetrievingReplayConfiguration") then return "正在获取回放数据，请稍候。若长时间没有反应，请重试。"
            else                                                      return "未知10:" .. (textType or "")
            end
        end,
        [2] = function(textType)
            if     (textType == "Delete")                        then return "Delete"
            elseif (textType == "DeleteConfirmation")            then return "Are you sure to delete this replay data?"
            elseif (textType == "DeleteReplay")                  then return "Delete"
            elseif (textType == "Download")                      then return "Download"
            elseif (textType == "DownloadReplay")                then return "Download"
            elseif (textType == "DownloadStarted")               then return "The download has been started. Please wait."
            elseif (textType == "GetMore")                       then return "Get More"
            elseif (textType == "InvalidWarName")                then return "The war name is invalid. Please check and retry."
            elseif (textType == "LoadingReplay")                 then return "Loading the replay. Please wait."
            elseif (textType == "NoDownloadableReplay")          then return "There's no downloadable replay currently."
            elseif (textType == "NoMoreReplay")                  then return "There's no more downloadable replay data."
            elseif (textType == "NoReplayData")                  then return "There's no replay data on the device."
            elseif (textType == "Playback")                      then return "Playback"
            elseif (textType == "ReplayDataExists")              then return "The replay data has been downloaded already."
            elseif (textType == "ReplayDataNotExists")           then return "The replay data doesn't exist and can't be downloaded."
            elseif (textType == "RetrievingReplayConfiguration") then return "Retrieving replay data. Please wait."
            else                                                      return "Unknown10:" .. (textType or "")
            end
        end,
    },
    [11] = {
        [1] = function(textType)
            if     (textType == "NoMoreNextTurn")      then return "已经是最后一回合，无法继续快进。"
            elseif (textType == "NoMorePreviousTurn")  then return "已经是战局最初状态，无法继续快退。"
            elseif (textType == "NoMoreReplayActions") then return "所有步骤已全部回放完毕。"
            elseif (textType == "Progress")            then return "进度"
            elseif (textType == "SwitchTurn")          then return "已切换回合"
            else                                            return "未知11:" .. (textType or "")
            end
        end,
        [2] = function(textType)
            if     (textType == "NoMoreNextTurn")      then return "There're no more turns."
            elseif (textType == "NoMorePreviousTurn")  then return "It's the beginning of the replay."
            elseif (textType == "NoMoreReplayActions") then return "The replay is finished."
            elseif (textType == "Progress")            then return "Progress"
            elseif (textType == "SwitchTurn")          then return "Turn switched"
            else                                            return "Unknown11:" .. (textType or "")
            end
        end,
    },
    [12] = {
        [1] = function(actionName)
            if     (actionName == "ActionActivateSkill")          then return "发动主动技"
            elseif (actionName == "ActionAttack")                 then return "攻击"
            elseif (actionName == "ActionBeginTurn")              then return "开始回合"
            elseif (actionName == "ActionBuildModelTile")         then return "建造"
            elseif (actionName == "ActionCaptureModelTile")       then return "占领"
            elseif (actionName == "ActionDeclareSkill")           then return "发起特技宣言"
            elseif (actionName == "ActionDestroyOwnedModelUnit")  then return "自爆"
            elseif (actionName == "ActionDive")                   then return "下潜"
            elseif (actionName == "ActionDropModelUnit")          then return "卸载"
            elseif (actionName == "ActionEndTurn")                then return "结束回合"
            elseif (actionName == "ActionJoinModelUnit")          then return "合流"
            elseif (actionName == "ActionLaunchFlare")            then return "照明弹"
            elseif (actionName == "ActionLaunchSilo")             then return "发射导弹"
            elseif (actionName == "ActionLoadModelUnit")          then return "装载"
            elseif (actionName == "ActionProduceModelUnitOnTile") then return "生产部队"
            elseif (actionName == "ActionProduceModelUnitOnUnit") then return "生产舰载机"
            elseif (actionName == "ActionResearchPassiveSkill")   then return "研发日常技"
            elseif (actionName == "ActionSupplyModelUnit")        then return "补给"
            elseif (actionName == "ActionSurface")                then return "上浮"
            elseif (actionName == "ActionSurrender")              then return "投降"
            elseif (actionName == "ActionTickActionId")           then return ""
            elseif (actionName == "ActionVoteForDraw")            then return "表决和局"
            elseif (actionName == "ActionWait")                   then return "待机"
            else                                                  return "未知12:" .. (actionName or "")
            end
        end,
        [2] = function(actionName)
            if     (actionName == "ActionActivateSkill")          then return "ActivateSkill"
            elseif (actionName == "ActionAttack")                 then return "Attack"
            elseif (actionName == "ActionBeginTurn")              then return "BeginTurn"
            elseif (actionName == "ActionBuildModelTile")         then return "BuildTile"
            elseif (actionName == "ActionCaptureModelTile")       then return "Capture"
            elseif (actionName == "ActionDeclareSkill")           then return "DeclareSkill"
            elseif (actionName == "ActionDestroyOwnedModelUnit")  then return "SelfDestruction"
            elseif (actionName == "ActionDive")                   then return "Dive"
            elseif (actionName == "ActionDropModelUnit")          then return "Drop"
            elseif (actionName == "ActionEndTurn")                then return "EndTurn"
            elseif (actionName == "ActionJoinModelUnit")          then return "Join"
            elseif (actionName == "ActionLaunchFlare")            then return "LaunchFlare"
            elseif (actionName == "ActionLaunchSilo")             then return "LaunchSilo"
            elseif (actionName == "ActionLoadModelUnit")          then return "Load"
            elseif (actionName == "ActionProduceModelUnitOnTile") then return "ProduceUnitOnTile"
            elseif (actionName == "ActionProduceModelUnitOnUnit") then return "ProduceUnitOnUnit"
            elseif (actionName == "ActionResearchPassiveSkill")   then return "ResearchSkill"
            elseif (actionName == "ActionSupplyModelUnit")        then return "Supply"
            elseif (actionName == "ActionSurface")                then return "Surface"
            elseif (actionName == "ActionSurrender")              then return "Surrender"
            elseif (actionName == "ActionTickActionId")           then return ""
            elseif (actionName == "ActionVoteForDraw")            then return "VoteForDraw"
            elseif (actionName == "ActionWait")                   then return "Wait"
            else                                                  return "Unknown12:" .. (actionName or "")
            end
        end,
    },
    [13] = {
        [1] = function(textType)
            if     (textType == "Account")             then return "账号"
            elseif (textType == "Draw")                then return "平"
            elseif (textType == "EmptyRankingList")    then return "该排行榜尚未有数据。"
            elseif (textType == "FogOff")              then return "明战"
            elseif (textType == "FogOn")               then return "雾战"
            elseif (textType == "GameRecords")         then return "战绩"
            elseif (textType == "Lose")                then return "负"
            elseif (textType == "Nickname")            then return "昵称"
            elseif (textType == "NoLimit")             then return "不限"
            elseif (textType == "None")                then return "无"
            elseif (textType == "Overview")            then return "总 览"
            elseif (textType == "Players")             then return "人局"
            elseif (textType == "RankIndex")           then return "名次"
            elseif (textType == "RankingList")         then return "排行榜"
            elseif (textType == "RankScore")           then return "积分"
            elseif (textType == "RecentWars")          then return "最近结束的战局"
            elseif (textType == "TotalOnlineDuration") then return "在线总时长"
            elseif (textType == "TransferingData")     then return "正在获取数据，请稍候。"
            elseif (textType == "WaitingWars")         then return "已参加且未满员的战局"
            elseif (textType == "Win")                 then return "胜"
            else                                            return "未知13:" .. (textType or "")
            end
        end,
        [2] = function(textType)
            if     (textType == "Account")             then return "Account"
            elseif (textType == "Draw")                then return "Draw"
            elseif (textType == "EmptyRankingList")    then return "The ranking list is empty currently."
            elseif (textType == "FogOff")              then return "Fog Off"
            elseif (textType == "FogOn")               then return "Fog On"
            elseif (textType == "GameRecords")         then return "Game Records"
            elseif (textType == "Lose")                then return "Lose"
            elseif (textType == "Nickname")            then return "Nickname"
            elseif (textType == "NoLimit")             then return "No Limit"
            elseif (textType == "None")                then return "None"
            elseif (textType == "Overview")            then return "Overview"
            elseif (textType == "Players")             then return "P"
            elseif (textType == "RankIndex")           then return "Index"
            elseif (textType == "RankingList")         then return "Ranking List"
            elseif (textType == "RankScore")           then return "RankScore"
            elseif (textType == "RecentWars")          then return "Recent wars"
            elseif (textType == "TotalOnlineDuration") then return "Total play time"
            elseif (textType == "TransferingData")     then return "Retrieving data from the server. Please wait."
            elseif (textType == "WaitingWars")         then return "Waiting Wars"
            elseif (textType == "Win")                 then return "Win"
            else                                            return "Unknown13:" .. (textType or "")
            end
        end,
    },
    [14] = {
        [1] = function(textType)
            if     (textType == "ActionsCount")                 then return "行动数"
            elseif (textType == "Advanced Settings")            then return "高 级 设 置"
            elseif (textType == "AttackModifier")               then return "攻击力加成"
            elseif (textType == "ConfirmContinueWar")           then return "进 入 战 局"
            elseif (textType == "ConfirmCreateWar")             then return "确 认 新 建 战 局"
            elseif (textType == "ConfirmExitWar")               then return "确 认 退 出 战 局"
            elseif (textType == "ConfirmJoinWar")               then return "确 认 参 战"
            elseif (textType == "ContinueWar")                  then return "继 续"
            elseif (textType == "CreateWar")                    then return "新 建 战 局"
            elseif (textType == "CustomConfiguration")          then return "自定义配置"
            elseif (textType == "Default")                      then return "默认"
            elseif (textType == "DisableSkills")                then return "禁用技能"
            elseif (textType == "EnableActiveSkill")            then return "启用主动技"
            elseif (textType == "EnablePassiveSkill")           then return "启用日常技"
            elseif (textType == "EnableSkillDeclaration")       then return "启用宣言"
            elseif (textType == "Energy Gain Modifier")         then return "能 量 增 速"
            elseif (textType == "EnergyGainModifier")           then return "能量增速"
            elseif (textType == "ExitWar")                      then return "退 出 战 局"
            elseif (textType == "FogOfWar")                     then return "战争迷雾"
            elseif (textType == "Income Modifier")              then return "收 入 倍 率"
            elseif (textType == "IncomeModifier")               then return "收入倍率"
            elseif (textType == "IntervalUntilBoot")            then return "回合限时"
            elseif (textType == "InvalidWarPassword")           then return "您输入的密码不符合要求，请重新输入。"
            elseif (textType == "JoinWar")                      then return "参 战"
            elseif (textType == "MaxBaseSkillPoints")           then return "全员技能基准点上限"
            elseif (textType == "MaxDiffScore")                 then return "最大分差"
            elseif (textType == "MoveRangeModifier")            then return "移动力加成"
            elseif (textType == "No")                           then return "否"
            elseif (textType == "NoAvailableOption")            then return "无可用选项"
            elseif (textType == "NoData")                       then return "无数据"
            elseif (textType == "NoLimit")                      then return "不限"
            elseif (textType == "None")                         then return "无"
            elseif (textType == "Overview")                     then return "战局设定总览"
            elseif (textType == "PlayerIndex")                  then return "行动次序"
            elseif (textType == "PreviousSaveIndex")            then return "上次存档位置"
            elseif (textType == "RankMatch")                    then return "积分赛"
            elseif (textType == "RetrievingCreateWarResult")    then return "正在创建战局，请稍候。若长时间没有反应，请返回重试。"
            elseif (textType == "RetrievingExitableWar")        then return "正在获取可以退出的战局数据。若长时间没有反应，请返回重试。"
            elseif (textType == "RetrievingExitWarResult")      then return "正在退出战局，请稍候。若长时间没有反应，请返回尝试。"
            elseif (textType == "RetrievingJoinWarResult")      then return "正在参战，请稍候。若长时间没有反应，请返回重试。"
            elseif (textType == "RetrievingSkillConfiguration") then return "正在获取技能数据，请稍候。"
            elseif (textType == "RetrievingWarData")            then return "正在进入战局，请稍候。若长时间没有反应，请返回重试。"
            elseif (textType == "Save Index")                   then return "存 档 位 置"
            elseif (textType == "SaveIndex")                    then return "存档位置"
            elseif (textType == "Selected")                     then return "已选定"
            elseif (textType == "SkillConfiguration")           then return "我方技能配置"
            elseif (textType == "Starting Energy")              then return "初 始 能 量"
            elseif (textType == "Starting Fund")                then return "初 始 资 金"
            elseif (textType == "StartingEnergy")               then return "初始能量"
            elseif (textType == "StartingFund")                 then return "初始资金"
            elseif (textType == "TeamIndex")                    then return "所属队伍"
            elseif (textType == "VisionModifier")               then return "视野加成"
            elseif (textType == "WarFieldName")                 then return "地图名称"
            elseif (textType == "Yes")                          then return "是"
            else                                                     return "未知14:" .. (textType or "")
            end
        end,
        [2] = function(textType)
            if     (textType == "ActionsCount")                 then return "Actions"
            elseif (textType == "Advanced Settings")            then return "Advanced"
            elseif (textType == "AttackModifier")               then return "AttackModifier"
            elseif (textType == "ConfirmContinueWar")           then return "Confirm"
            elseif (textType == "ConfirmCreateWar")             then return "Confirm"
            elseif (textType == "ConfirmExitWar")               then return "Confirm"
            elseif (textType == "ConfirmJoinWar")               then return "Confirm"
            elseif (textType == "ContinueWar")                  then return "Continue"
            elseif (textType == "CreateWar")                    then return "New War"
            elseif (textType == "CustomConfiguration")          then return "Custom"
            elseif (textType == "Default")                      then return "Default"
            elseif (textType == "DisableSkills")                then return "Disable Skills"
            elseif (textType == "EnableActiveSkill")            then return "EnableActiveSkill"
            elseif (textType == "EnablePassiveSkill")           then return "EnablePassiveSkill"
            elseif (textType == "EnableSkillDeclaration")       then return "EnableSkillDeclaration"
            elseif (textType == "Energy Gain Modifier")         then return "EnergyGain"
            elseif (textType == "EnergyGainModifier")           then return "EnergyGain"
            elseif (textType == "ExitWar")                      then return "Exit War"
            elseif (textType == "FogOfWar")                     then return "Fog of War"
            elseif (textType == "Income Modifier")              then return "IncomeModifier"
            elseif (textType == "IncomeModifier")               then return "IncomeModifier"
            elseif (textType == "IntervalUntilBoot")            then return "Interval until Boot"
            elseif (textType == "InvalidWarPassword")           then return "The password is not valid. Please reenter it."
            elseif (textType == "JoinWar")                      then return "Join War"
            elseif (textType == "MaxBaseSkillPoints")           then return "Max Skill Points"
            elseif (textType == "MaxDiffScore")                 then return "Max Diff Score"
            elseif (textType == "MoveRangeModifier")            then return "MobilityModifier"
            elseif (textType == "No")                           then return "No"
            elseif (textType == "NoAvailableOption")            then return "No Options"
            elseif (textType == "NoData")                       then return "No Data"
            elseif (textType == "NoLimit")                      then return "No Limit"
            elseif (textType == "None")                         then return "None"
            elseif (textType == "Overview")                     then return "Overview"
            elseif (textType == "PlayerIndex")                  then return "Player Index"
            elseif (textType == "PreviousSaveIndex")            then return "SaveIndex"
            elseif (textType == "RankMatch")                    then return "Ranking Match"
            elseif (textType == "RetrievingCreateWarResult")    then return "Creating the war, please wait."
            elseif (textType == "RetrievingExitableWar")        then return "Transfering data. please wait."
            elseif (textType == "RetrievingExitWarResult")      then return "Exiting the war, please wait"
            elseif (textType == "RetrievingJoinWarResult")      then return "Joining the war, please wait."
            elseif (textType == "RetrievingSkillConfiguration") then return "Retrieving data..."
            elseif (textType == "RetrievingWarData")            then return "Retrieving war data, please wait."
            elseif (textType == "Save Index")                   then return "SaveIndex"
            elseif (textType == "SaveIndex")                    then return "SaveIndex"
            elseif (textType == "Selected")                     then return "Selected"
            elseif (textType == "SkillConfiguration")           then return "Skill Configuration"
            elseif (textType == "Starting Energy")              then return "Starting Energy"
            elseif (textType == "Starting Fund")                then return "Starting Fund"
            elseif (textType == "StartingEnergy")               then return "Starting Energy"
            elseif (textType == "StartingFund")                 then return "Starting Fund"
            elseif (textType == "VisionModifier")               then return "VisionModifier"
            elseif (textType == "TeamIndex")                    then return "TeamIndex"
            elseif (textType == "WarFieldName")                 then return "Map"
            elseif (textType == "Yes")                          then return "Yes"
            else                                                     return "Unknown14:" .. (textType or "")
            end
        end,
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
        [1] = function(textType)
            if     (textType == "ActivateSkill")             then return "发动特技"
            elseif (textType == "ConfigSkill")               then return "配 置 技 能"
            elseif (textType == "ConfirmationActiveSkill")   then return "您确定要发动如下特技吗？"
            elseif (textType == "ConfirmationDeclareSkill")  then return "发起宣言需要扣除2500能量，并将允许您下回合发动特技(也可以不发动)。\n确定要宣言吗？"
            elseif (textType == "ConfirmationResearchSkill") then return "您确定要研发如下日常技吗？"
            elseif (textType == "CurrentEnergy")             then return "当前能量值"
            elseif (textType == "DeclareSkill")              then return "发起特技宣言"
            elseif (textType == "EffectListActiveSkill")     then return "主动技消耗表"
            elseif (textType == "EffectListPassiveSkill")    then return "日常技消耗表"
            elseif (textType == "EnergyCost")                then return "能量消耗"
            elseif (textType == "HasDeclaredSkill")          then return "已发起了特技宣言"
            elseif (textType == "HasUpdatedReserveSkills")   then return "已设置了预备主动技"
            elseif (textType == "HelpForActiveSkill")        then return s_LongText6_1
            elseif (textType == "HelpForPassiveSkill")       then return s_LongText7_1
            elseif (textType == "Level")                     then return "等级"
            elseif (textType == "MaxModifierPassive")        then return "日常增幅上限"
            elseif (textType == "Modifier")                  then return "增幅"
            elseif (textType == "No")                        then return "否"
            elseif (textType == "NoAvailableOption")         then return "无可用选项"
            elseif (textType == "ResearchPassiveSkill")      then return "研发日常技"
            elseif (textType == "SkillInfo")                 then return "技 能 信 息"
            elseif (textType == "UpdateReserveSkill")        then return "设定预备主动技"
            elseif (textType == "UpdateReserve")             then return "设定预备技"
            elseif (textType == "Yes")                       then return "是"
            else                                                  return "未知22:" .. (textType or "")
            end
        end,
        [2] = function(textType)
            if     (textType == "ActivateSkill")             then return "ActivateSkill"
            elseif (textType == "ConfigSkill")               then return "Config Skill"
            elseif (textType == "ConfirmationActiveSkill")   then return "Are you sure to activate the skill below?"
            elseif (textType == "ConfirmationDeclareSkill")  then return "The declaration costs 2500 energy and enable you to activate active skills next turn.\nAre you sure?"
            elseif (textType == "ConfirmationResearchSkill") then return "Are you sure to research the skill below?"
            elseif (textType == "CurrentEnergy")             then return "Current Energy"
            elseif (textType == "DeclareSkill")              then return "Declare Skill"
            elseif (textType == "EffectListActiveSkill")     then return "ActiveList"
            elseif (textType == "EffectListPassiveSkill")    then return "PassiveList"
            elseif (textType == "EnergyCost")                then return "Cost"
            elseif (textType == "HasDeclaredSkill")          then return "has declared skill activation"
            elseif (textType == "HasUpdatedReserveSkills")   then return "has updated reserve skills"
            elseif (textType == "HelpForActiveSkill")        then return s_LongText6_2
            elseif (textType == "HelpForPassiveSkill")       then return s_LongText7_2
            elseif (textType == "Level")                     then return "Level"
            elseif (textType == "MaxModifierPassive")        then return "Max Passive Modifier"
            elseif (textType == "Modifier")                  then return "Modifier"
            elseif (textType == "No")                        then return "No"
            elseif (textType == "NoAvailableOption")         then return "No Options"
            elseif (textType == "ResearchPassiveSkill")      then return "ResearchSkill"
            elseif (textType == "SkillInfo")                 then return "Skill Info"
            elseif (textType == "UpdateReserveSkill")        then return "ReserveSkill"
            elseif (textType == "UpdateReserve")             then return "ReserveSkill"
            elseif (textType == "Yes")                       then return "Yes"
            else                                                  return "Unknown22:" .. (textType or "")
            end
        end,
    },
    [23] = {
        [1] = function(skillID)
            if     (skillID == 1)  then return "增加我方全体部队的攻击力。"
            elseif (skillID == 2)  then return "增加我方全体部队的防御力。"
            elseif (skillID == 3)  then return "增加我方全体部队的当前HP，但最多不超过10。"
            elseif (skillID == 4)  then return "减少对方全体部队的当前HP，但最少剩余1。"
            elseif (skillID == 5)  then return "增加我方全体部队的移动力。"
            elseif (skillID == 6)  then return "增加我方全体远程部队的射程上限。"
            elseif (skillID == 7)  then return "使我方步兵系以外的全体部队变为未行动的状态。"
            elseif (skillID == 8)  then return "增加我方所有建筑的金钱收入。"
            elseif (skillID == 9)  then return "以我军当前收入的某个百分比，增加我军资金。"
            elseif (skillID == 10) then return "减少所有对手的能量值，但最少剩余0。"
            elseif (skillID == 11) then return "增加我方建筑及部队的维修量。"
            elseif (skillID == 12) then return "增加我方步兵系的占领速度（四舍五入）。"
            elseif (skillID == 13) then return "增加我方的能量获取速度（四舍五入）。"
            elseif (skillID == 14) then return "增加我方的能量获取速度（不受战局设定影响）。"
            else                        return "未知23:" .. (skillID or "")
            end
        end,
        [2] = function(skillID)
            return "Untranslated..."
        end,
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
        [1] = function(textType)
            if     (textType == "Energy") then return "能量"
            elseif (textType == "Player") then return "玩家"
            elseif (textType == "Fund")   then return "金钱"
            else                               return "未知25:" .. (textType or "")
            end
        end,
        [2] = function(textType)
            if     (textType == "Energy") then return "Energy"
            elseif (textType == "Player") then return "Player"
            elseif (textType == "Fund")   then return "Fund"
            else                               return "Unknown25:" .. (textType or "")
            end
        end,
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
        [1] = function(textType)
            if     (textType == "ConnectionEstablished") then return "已成功连接服务器。"
            elseif (textType == "StartConnecting")       then return "正在连接服务器，请稍候。"
            else                                              return "未知30:" .. (textType or "")
            end
        end,
        [2] = function(textType)
            if     (textType == "ConnectionEstablished") then return "Connection established."
            elseif (textType == "StartConnecting")       then return "Now connecting to the server. Please wait."
            else                                              return "Unknown30:" .. (textType or "")
            end
        end,
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
        [1] = function(textType)
            if     (textType == "BaseSkillPoints")      then return "全员技能基准点上限"
            elseif (textType == "BaseSkillPointsShort") then return "技能点上限"
            elseif (textType == "Black")                then return "黑方"
            elseif (textType == "Blue")                 then return "蓝方"
            elseif (textType == "BootCountdown")        then return "自动投降倒计时"
            elseif (textType == "Day")                  then return "天"
            elseif (textType == "FogOfWar")             then return "战 争 迷 雾"
            elseif (textType == "Hour")                 then return "时"
            elseif (textType == "MaxDiffScore")         then return "最 大 分 差"
            elseif (textType == "Minute")               then return "分"
            elseif (textType == "No")                   then return "否"
            elseif (textType == "Password")             then return "输入密码(可选)"
            elseif (textType == "PlayerIndex")          then return "行 动 次 序"
            elseif (textType == "RankMatch")            then return "积 分 赛"
            elseif (textType == "Red")                  then return "红方"
            elseif (textType == "Second")               then return "秒"
            elseif (textType == "SkillConfiguration")   then return "我方技能配置"
            elseif (textType == "Weather")              then return "天 气"
            elseif (textType == "Yellow")               then return "黄方"
            elseif (textType == "Yes")                  then return "是"
            else                                             return "未知34:" .. (textType or "")
            end
        end,
        [2] = function(textType)
            if     (textType == "BaseSkillPoints")      then return "Max Base Skill Points"
            elseif (textType == "BaseSkillPointsShort") then return "SkillPoints"
            elseif (textType == "Black")                then return "Black"
            elseif (textType == "Blue")                 then return "Blue"
            elseif (textType == "BootCountdown")        then return "BootCountdown"
            elseif (textType == "Day")                  then return "d"
            elseif (textType == "FogOfWar")             then return "Fog of War"
            elseif (textType == "Hour")                 then return "h"
            elseif (textType == "MaxDiffScore")         then return "Max Diff Score"
            elseif (textType == "Minute")               then return "m"
            elseif (textType == "No")                   then return "No"
            elseif (textType == "Password")             then return "Password (optional)"
            elseif (textType == "PlayerIndex")          then return "Player Index"
            elseif (textType == "RankMatch")            then return "Ranking Match"
            elseif (textType == "Red")                  then return "Red"
            elseif (textType == "Second")               then return "s"
            elseif (textType == "SkillConfiguration")   then return "Skill Configuration"
            elseif (textType == "Weather")              then return "Weather"
            elseif (textType == "Yellow")               then return "Yellow"
            elseif (textType == "Yes")                  then return "Yes"
            else                                             return "Unknown34:" .. (textType or "")
            end
        end,
    },
    [35] = {
        [1] = function(textType)
            if     (textType == "HelpForAttackModifier")         then return s_LongText21_1
            elseif (textType == "HelpForEnableActiveSkill")      then return s_LongText8_1
            elseif (textType == "HelpForEnablePassiveSkill")     then return s_LongText9_1
            elseif (textType == "HelpForEnableSkillDeclaration") then return s_LongText19_1
            elseif (textType == "HelpForEnergyGainModifier")     then return s_LongText10_1
            elseif (textType == "HelpForFogOfWar")               then return s_LongText11_1
            elseif (textType == "HelpForIncomeModifier")         then return s_LongText12_1
            elseif (textType == "HelpForIntervalUntilBoot")      then return s_LongText13_1
            elseif (textType == "HelpForMaxDiffScore")           then return s_LongText14_1
            elseif (textType == "HelpForMoveRangeModifier")      then return s_LongText20_1
            elseif (textType == "HelpForPlayerIndex")            then return s_LongText15_1
            elseif (textType == "HelpForRankMatch")              then return s_LongText16_1
            elseif (textType == "HelpForReserveSkills")          then return s_LongText25_1
            elseif (textType == "HelpForSaveIndex")              then return s_LongText24_1
            elseif (textType == "HelpForStartingEnergy")         then return s_LongText17_1
            elseif (textType == "HelpForStartingFund")           then return s_LongText18_1
            elseif (textType == "HelpForTeamIndex")              then return s_LongText23_1
            elseif (textType == "HelpForVisionModifier")         then return s_LongText22_1
            else                                                      return "未知35:" .. (textType or "")
            end
        end,
        [2] = function(textType)
            if     (textType == "HelpForAttackModifier")         then return s_LongText21_2
            elseif (textType == "HelpForEnableActiveSkill")      then return s_LongText8_2
            elseif (textType == "HelpForEnablePassiveSkill")     then return s_LongText9_2
            elseif (textType == "HelpForEnableSkillDeclaration") then return s_LongText19_2
            elseif (textType == "HelpForEnergyGainModifier")     then return s_LongText10_2
            elseif (textType == "HelpForFogOfWar")               then return s_LongText11_2
            elseif (textType == "HelpForIncomeModifier")         then return s_LongText12_2
            elseif (textType == "HelpForIntervalUntilBoot")      then return s_LongText13_2
            elseif (textType == "HelpForMaxDiffScore")           then return s_LongText14_2
            elseif (textType == "HelpForMoveRangeModifier")      then return s_LongText20_2
            elseif (textType == "HelpForPlayerIndex")            then return s_LongText15_2
            elseif (textType == "HelpForRankMatch")              then return s_LongText16_2
            elseif (textType == "HelpForReserveSkills")          then return s_LongText25_2
            elseif (textType == "HelpForSaveIndex")              then return s_LongText24_2
            elseif (textType == "HelpForStartingEnergy")         then return s_LongText17_2
            elseif (textType == "HelpForStartingFund")           then return s_LongText18_2
            elseif (textType == "HelpForTeamIndex")              then return s_LongText23_2
            elseif (textType == "HelpForVisionModifier")         then return s_LongText22_2
            else                                                      return "Unknown35:" .. (textType or "")
            end
        end,
    },
    --[[
    [36] = {
        [1] = function() return "天 气"   end,
        [2] = function() return "Weather" end,
    },
    [37] = {
        [1] = function() return "我 方 技 能 配 置" end,
        [2] = function() return "Skills"     end,
    },
    [38] = {
        [1] = function() return "基 准 技 能 点 上 限"    end,
        [2] = function() return "Max Skill Points" end,
    },
    [39] = {
        [1] = function() return "密 码（可 选）"       end,
        [2] = function() return "Password (optional)" end,
    },
    --]]
    [40] = {
        [1] = function(weatherType)
            if     (weatherType == "Clear")  then return "正 常"
            elseif (weatherType == "Random") then return "随 机"
            elseif (weatherType == "Rainy")  then return "雨 天"
            elseif (weatherType == "Snowy")  then return "雪 天"
            elseif (weatherType == "Sandy")  then return "沙 尘 暴"
            else                                  return "未知[40]: " .. (weatherType or "")
            end
        end,
        [2] = function(weatherType)
            if     (weatherType == "Clear")  then return "Clear"
            elseif (weatherType == "Random") then return "Random"
            elseif (weatherType == "Rainy")  then return "Rainy"
            elseif (weatherType == "Snowy")  then return "Snowy"
            elseif (weatherType == "Sandy")  then return "Sandy"
            else                                  return "Unknown[40]: " .. (weatherType or "")
            end
        end,
    },
    --[[
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
    --]]
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
        [1] = function(textType)
            if     (textType == "Author")  then return "作者: "
            elseif (textType == "Players") then return "已参战玩家: "
            elseif (textType == "Empty")   then return "(空缺)"
            else                                return "未知48:" .. (textType or "")
            end
        end,
        [2] = function()
            if     (textType == "Author")  then return "Author: "
            elseif (textType == "Players") then return "Players: "
            elseif (textType == "Empty")   then return "(Empty)"
            else                                return "Unknown48:" .. (textType or "")
            end
        end,
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
        [1] = function(textType, additionalText)
            if     (textType == "NewWarCreated") then return "[" .. additionalText .. "] 战局已创建，请等待其他玩家参战。"
            else                                      return "未知51:" .. (textType or "")
            end
        end,
        [2] = function(textType, additionalText)
            if     (textType == "NewWarCreated") then return "The war [" .. additionalText .. "] is created successfully. Please wait for other players to join."
            else                                      return "Unknown51:" .. (textType or "")
            end
        end,
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
        [1] = function(textType, additionalText)
            if     (textType == "ExitWarSuccessfully") then return "您已退出战局 [" .. additionalText .. "]。"
            elseif (textType == "JoinWarNotStarted")   then return "该战局尚未开始，请耐心等待更多玩家加入。"
            elseif (textType == "JoinWarStarted")      then return "该战局已开始，您可以通过[继续]选项进入战局。"
            elseif (textType == "JoinWarSuccessfully") then return "您已成功参战 [" .. additionalText .. "]。"
            else                                            return "未知56:" .. (textType or "")
            end
        end,
        [2] = function(textType, additionalText)
            if     (textType == "ExitWarSuccessfully") then return "Exit war [" .. additionalText .. "] successfully."
            elseif (textType == "JoinWarNotStarted")   then return "The war is not started. Please wait for more players to join."
            elseif (textType == "JoinWarStarted")      then return "The war is started."
            elseif (textType == "JoinWarSuccessfully") then return "Join war [" .. additionalText .. "] successfully."
            else                                            return "Unknown56:" .. (textType or "")
            end
        end,
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
    --[[
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
    ]]
    [65] = {
        [1] = function(textType)
            if     (textType == "ActionID")                then return "行动数"
            elseif (textType == "ActivateSkill")           then return "发 动 技 能"
            elseif (textType == "AgreeDraw")               then return "同 意 和 局"
            elseif (textType == "Author")                  then return "作者"
            elseif (textType == "AuxiliaryCommands")       then return "辅 助 功 能"
            elseif (textType == "AverageAttackDamage")     then return "主动攻击平均伤害"
            elseif (textType == "AverageKillPercentage")   then return "主动攻击致命率"
            elseif (textType == "BackToMainScene")         then return "返 回 主 界 面"
            elseif (textType == "Channel Private")         then return "私 聊"
            elseif (textType == "Channel Public")          then return "公 共 频 道"
            elseif (textType == "Chat")                    then return "聊 天"
            elseif (textType == "CurrentTurnIndex")        then return "当前回合数"
            elseif (textType == "DamageChart")             then return "基础伤害表"
            elseif (textType == "DamageCostPerEnergy")     then return "每单位能量价值"
            elseif (textType == "DestroyOwnedUnit")        then return "摧毁光标所在部队"
            elseif (textType == "DisagreeDraw")            then return "拒 绝 和 局"
            elseif (textType == "DrawOrSurrender")         then return "求 和 / 投 降"
            elseif (textType == "EndTurn")                 then return "结 束 回 合"
            elseif (textType == "Energy")                  then return "能 量"
            elseif (textType == "EnergyGainModifier")      then return "能量增速"
            elseif (textType == "FindIdleUnit")            then return "寻 找 空 闲 部 队"
            elseif (textType == "FindIdleTile")            then return "寻 找 空 闲 建 筑"
            elseif (textType == "Fund")                    then return "资 金"
            elseif (textType == "Help")                    then return "帮 助"
            elseif (textType == "HideUI")                  then return "隐 藏 界 面"
            elseif (textType == "HighScore")               then return "最高分"
            elseif (textType == "IdleTiles")               then return "空闲工厂/机场/海港数量"
            elseif (textType == "IdleUnits")               then return "空闲部队数量"
            elseif (textType == "Income")                  then return "收 入"
            elseif (textType == "Load Game")               then return "读 档"
            elseif (textType == "Lost")                    then return "已战败"
            elseif (textType == "LostUnitValueForPlayer")  then return "玩家损失总值"
            elseif (textType == "MainWeapon")              then return "主武器"
            elseif (textType == "MapName")                 then return "地图"
            elseif (textType == "Nickname")                then return "昵 称"
            elseif (textType == "NoHistoricalChat")        then return "没有历史消息"
            elseif (textType == "Player")                  then return "玩 家"
            elseif (textType == "ProposeDraw")             then return "求 和"
            elseif (textType == "QuitWar")                 then return "退 出"
            elseif (textType == "ReceiveChatText")         then return "收到聊天消息"
            elseif (textType == "ReloadWar")               then return "重 新 载 入"
            elseif (textType == "Save Game")               then return "存 盘"
            elseif (textType == "Score Info")              then return "评 分 信 息"
            elseif (textType == "ScoreForPower")           then return "力量分"
            elseif (textType == "ScoreForSpeed")           then return "速度分"
            elseif (textType == "ScoreForTechnique")       then return "技术分"
            elseif (textType == "Send")                    then return "发 送"
            elseif (textType == "SkillInfo")               then return "技 能 信 息"
            elseif (textType == "SubWeapon")               then return "副武器"
            elseif (textType == "Surrender")               then return "投 降"
            elseif (textType == "TargetTurnsCount")        then return "目标回合数"
            elseif (textType == "TileInfo")                then return "据 点 信 息 统 计"
            elseif (textType == "TilesCount")              then return "据点数量"
            elseif (textType == "TotalScore")              then return "总得分"
            elseif (textType == "TotalAttacksCount")       then return "主动攻击次数"
            elseif (textType == "TotalUnitValueForAI")     then return "AI部队总值"
            elseif (textType == "TotalUnitValueForPlayer") then return "玩家部队总值"
            elseif (textType == "TouchMeToInput")          then return "点我输入"
            elseif (textType == "TurnIndex")               then return "回合数"
            elseif (textType == "UnitPropertyList")        then return "部队基础属性表"
            elseif (textType == "UnitsCount")              then return "部队数量"
            elseif (textType == "UnitsValue")              then return "部队基础价值"
            elseif (textType == "War")                     then return "战局"
            elseif (textType == "WarID")                   then return "战局代号"
            elseif (textType == "WarInfo")                 then return "战 场 信 息"
            elseif (textType == "WarMenu")                 then return "战 场 菜 单"
            else                                                return "未知65:" .. (textType or "")
            end
        end,
        [2] = function(textType)
            if     (textType == "ActionID")                then return "Actions"
            elseif (textType == "ActivateSkill")           then return "ActivateSkill"
            elseif (textType == "AgreeDraw")               then return "AgreeDraw"
            elseif (textType == "Author")                  then return "Author"
            elseif (textType == "AuxiliaryCommands")       then return "AuxiliaryCmds"
            elseif (textType == "AverageAttackDamage")     then return "AverageDamage"
            elseif (textType == "AverageKillPercentage")   then return "AverageKills"
            elseif (textType == "BackToMainScene")         then return "Quit"
            elseif (textType == "Channel Private")         then return "PrivateChat"
            elseif (textType == "Channel Public")          then return "PublicChat"
            elseif (textType == "Chat")                    then return "Chat"
            elseif (textType == "CurrentTurnIndex")        then return "CurrentTurnIndex"
            elseif (textType == "DamageChart")             then return "DamageChart"
            elseif (textType == "DamageCostPerEnergy")     then return "DamageCostPerEnergy"
            elseif (textType == "DestroyOwnedUnit")        then return "Destroy Unit"
            elseif (textType == "DisagreeDraw")            then return "DisagreeDraw"
            elseif (textType == "DrawOrSurrender")         then return "Set draw / surrender"
            elseif (textType == "EndTurn")                 then return "End Turn"
            elseif (textType == "Energy")                  then return "Energy"
            elseif (textType == "EnergyGainModifier")      then return "EnergyGain"
            elseif (textType == "FindIdleTile")            then return "FildIdleTile"
            elseif (textType == "FindIdleUnit")            then return "FindIdleUnit"
            elseif (textType == "Fund")                    then return "Fund"
            elseif (textType == "Help")                    then return "Help"
            elseif (textType == "HideUI")                  then return "Hide UI"
            elseif (textType == "HighScore")               then return "HighScore"
            elseif (textType == "IdleTiles")               then return "Idle factories/airports/seaports"
            elseif (textType == "IdleUnits")               then return "Idle units"
            elseif (textType == "Income")                  then return "Income"
            elseif (textType == "Load Game")               then return "Load"
            elseif (textType == "Lost")                    then return "Lost"
            elseif (textType == "LostUnitValueForPlayer")  then return "Lost Unit Value For Player"
            elseif (textType == "MainWeapon")              then return "Main"
            elseif (textType == "MapName")                 then return "Map Name"
            elseif (textType == "Nickname")                then return "Nickname"
            elseif (textType == "NoHistoricalChat")        then return "No message so far"
            elseif (textType == "Player")                  then return "Player"
            elseif (textType == "ProposeDraw")             then return "ProposeDraw"
            elseif (textType == "QuitWar")                 then return "Quit"
            elseif (textType == "ReceiveChatText")         then return "ReceiveChatText"
            elseif (textType == "ReloadWar")               then return "Reload"
            elseif (textType == "Save Game")               then return "Save"
            elseif (textType == "Score Info")              then return "Score Info"
            elseif (textType == "ScoreForPower")           then return "Power"
            elseif (textType == "ScoreForSpeed")           then return "Speed"
            elseif (textType == "ScoreForTechnique")       then return "Technique"
            elseif (textType == "Send")                    then return "Send"
            elseif (textType == "SkillInfo")               then return "Skill Info"
            elseif (textType == "SubWeapon")               then return "Sub"
            elseif (textType == "Surrender")               then return "Surrender"
            elseif (textType == "TargetTurnsCount")        then return "TargetTurnsCount"
            elseif (textType == "TileInfo")                then return "TileInfo"
            elseif (textType == "TilesCount")              then return "Num of bases"
            elseif (textType == "TotalScore")              then return "Total Score"
            elseif (textType == "TotalAttacksCount")       then return "TotalAttacks"
            elseif (textType == "TotalUnitValueForAI")     then return "Total Unit Value for AI"
            elseif (textType == "TotalUnitValueForPlayer") then return "Total Unit Value for player"
            elseif (textType == "TouchMeToInput")          then return "TouchMeToInput"
            elseif (textType == "TurnIndex")               then return "Turn"
            elseif (textType == "UnitPropertyList")        then return "UnitProperties"
            elseif (textType == "UnitsCount")              then return "Num of units"
            elseif (textType == "UnitsValue")              then return "Value of units"
            elseif (textType == "War")                     then return "War"
            elseif (textType == "WarID")                   then return "War ID"
            elseif (textType == "WarInfo")                 then return "War Info"
            elseif (textType == "WarMenu")                 then return "War Menu"
            else                                                return "Unknown65:" .. (textType or "")
            end
        end,
    },
    [66] = {
        [1] = function(textType)
            if     (textType == "AgreeDraw")            then return "您确定要同意和局吗？"
            elseif (textType == "ConfirmationLoadGame") then return "未存盘的数据都将丢失。\n此外，将要读入的数据未必属于本战局。\n\n您确定要读档吗？"
            elseif (textType == "ConfirmationSaveGame") then return "已有的存盘数据将被覆盖。\n\n您确定要存盘吗？"
            elseif (textType == "DestroyOwnedUnit")     then return "摧毁部队将没有任何补偿！\n您确定要这样做吗？"
            elseif (textType == "DisagreeDraw")         then return "您确定要拒绝和局吗？"
            elseif (textType == "EndTurnConfirmation")  then return "您确定要结束回合吗？"
            elseif (textType == "ExitGame")             then return "是否确定退出游戏？"
            elseif (textType == "FailLoadGame")         then return "读档失败，可能是因为该存档位置没有数据。"
            elseif (textType == "FailSaveGame")         then return "存盘失败，请重试。"
            elseif (textType == "NoIdleTile")           then return "您的所有建筑均已被占用。"
            elseif (textType == "NoIdleTilesOrUnits")   then return "您的所有建筑和部队均已生产或行动完毕。"
            elseif (textType == "NoIdleUnit")           then return "您的所有部队均已行动。"
            elseif (textType == "ProposeDraw")          then return "求和需要战局内所有玩家一致同意才能生效。\n若中途有玩家战败，则需要重新求和。\n您确定要求和吗？"
            elseif (textType == "RequireVoteForDraw")   then return "已有玩家提出求和。您需要先表决是否同意和局，才能结束本回合。"
            elseif (textType == "QuitWar")              then return "您将回到主界面（可以随时再回到本战局）。\n是否确定？"
            elseif (textType == "ReloadWar")            then return "是否确定要重新载入战局？"
            elseif (textType == "SkillNotDeclared")     then return "您尚未发起特技宣言。"
            elseif (textType == "SucceedLoadGame")      then return "已成功读档，正在载入战局。"
            elseif (textType == "SucceedSaveGame")      then return "已成功存盘。"
            elseif (textType == "Surrender")            then return "您将输掉本战局，且无法反悔！\n是否确定投降？"
            else                                             return "未知66:" .. (textType or "")
            end
        end,
        [2] = function(textType)
            if     (textType == "AgreeDraw")            then return "Are you sure to approve the draw?"
            elseif (textType == "ConfirmationLoadGame") then return "The current data will be lost.\nAre you sure to load game?"
            elseif (textType == "ConfirmationSaveGame") then return "The existing data will be overwritten.\nAre you sure to save game?"
            elseif (textType == "DestroyOwnedUnit")     then return "You won't get anything in return!\nAre you sure to destroy it?"
            elseif (textType == "DisagreeDraw")         then return "Are you sure to decline the draw?"
            elseif (textType == "EndTurnConfirmation")  then return "Are you sure to end you turn?"
            elseif (textType == "ExitGame")             then return "Are you sure to exit the game?"
            elseif (textType == "FailLoadGame")         then return "Fail to load game. Please retry."
            elseif (textType == "FailSaveGame")         then return "Fail to save game. Please retry."
            elseif (textType == "NoIdleTile")           then return "None of your tiles is idle."
            elseif (textType == "NoIdleTilesOrUnits")   then return "All your buildings and units have taken action already."
            elseif (textType == "NoIdleUnit")           then return "None of your units is idle."
            elseif (textType == "ProposeDraw")          then return "Are you sure to propose a draw?"
            elseif (textType == "RequireVoteForDraw")   then return "A draw has been proposed. You must approve/decline it before ending your turn."
            elseif (textType == "QuitWar")              then return "You are quitting the war (you may reenter it later).\nAre you sure?"
            elseif (textType == "ReloadWar")            then return "Are you sure to reload the war?"
            elseif (textType == "SkillNotDeclared")     then return "You haven't made a skill declaration."
            elseif (textType == "SucceedLoadGame")      then return "Load game successfully. Now entering the game..."
            elseif (textType == "SucceedSaveGame")      then return "Save game successfully."
            elseif (textType == "Surrender")            then return "You will lose the game by surrendering!\nAre you sure?"
            else                                             return "Unrecognized:[66]" .. textType
            end
        end,
    },
    --[[
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
    --]]
    [72] = {
        [1] = function(turnIndex, nickname)
            return string.format("回合：%d\n玩家：%s\n战斗开始！", turnIndex, nickname)
        end,
        [2] = function(turnIndex, nickname)
            return string.format("Turn:     %d\nPlayer:  %s\nFight!", turnIndex, nickname)
        end,
    },
    [73] = {
        [1] = function(textType)
            if     (textType == "Draw")      then return "握 手 言 和"
            elseif (textType == "Lose")      then return "您 已 战 败 …"
            elseif (textType == "Win")       then return "您 已 获 胜 !"
            elseif (textType == "ReplayEnd") then return "回 放 结 束"
            elseif (textType == "Surrender") then return "您 已 投 降 …"
            else                                  return "未知73:" .. (textType or "")
            end
        end,
        [2] = function(textType)
            if     (textType == "Draw")      then return "End with draw."
            elseif (textType == "Lose")      then return "You lose…"
            elseif (textType == "Win")       then return "You win!"
            elseif (textType == "ReplayEnd") then return "Replay ended."
            elseif (textType == "Surrender") then return "You lose…"
            else                                  return "Unknown73:" .. (textType or "")
            end
        end,
    },
    [74] = {
        [1] = function(textType, additionalText)
            if     (textType == "AgreeDraw")    then return "玩家[" .. additionalText .. "]已提议和局。"
            elseif (textType == "DisagreeDraw") then return "玩家[" .. additionalText .. "]已否决和局。"
            elseif (textType == "EndWithDraw")  then return "所有玩家均已同意和局！"
            elseif (textType == "Lose")         then return "玩家[" .. additionalText .. "]已战败！"
            elseif (textType == "Surrender")    then return "玩家[" .. additionalText .. "]已投降！"
            else                                     return "未知74:" .. (textType or "")
            end
        end,
        [2] = function(textType, additionalText)
            if     (textType == "AgreeDraw")    then return "Player [" .. additionalText .. "] proposed a draw."
            elseif (textType == "DisagreeDraw") then return "Player [" .. additionalText .. "] declined the draw."
            elseif (textType == "EndWithDraw")  then return "All the players have approved the draw!"
            elseif (textType == "Lose")         then return "Player [" .. additionalText .. "] is defeated!"
            elseif (textType == "Surrender")    then return "Player [" .. additionalText .. "] surrendered!"
            else                                     return "Unknown74:" .. (textType or "")
            end
        end,
    },
    --[[
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
    --]]
    [78] = {
        [1] = function(actionType)
            if     (actionType == "Wait")                   then return "待 机"
            elseif (actionType == "Attack")                 then return "攻 击"
            elseif (actionType == "CaptureModelTile")       then return "占 领"
            elseif (actionType == "LoadModelUnit")          then return "装 载"
            elseif (actionType == "Dive")                   then return "下 潜"
            elseif (actionType == "DropModelUnit")          then return "卸 载"
            elseif (actionType == "LaunchModelUnit")        then return "弹 射"
            elseif (actionType == "JoinModelUnit")          then return "合 流"
            elseif (actionType == "SupplyModelUnit")        then return "补 给"
            elseif (actionType == "Surface")                then return "上 浮"
            elseif (actionType == "BuildModelTile")         then return "建 造"
            elseif (actionType == "ProduceModelUnitOnUnit") then return "生 产"
            elseif (actionType == "LaunchSilo")             then return "发 射"
            elseif (actionType == "LaunchFlare")            then return "照 明"
            else                                                 return "未知78:" .. (actionType or "")
            end
        end,
        [2] = function(actionType)
            if     (actionType == "Wait")                   then return "Wait"
            elseif (actionType == "Attack")                 then return "Attack"
            elseif (actionType == "CaptureModelTile")       then return "Capture"
            elseif (actionType == "LoadModelUnit")          then return "Load"
            elseif (actionType == "Dive")                   then return "Dive"
            elseif (actionType == "DropModelUnit")          then return "Drop"
            elseif (actionType == "LaunchModelUnit")        then return "Launch"
            elseif (actionType == "JoinModelUnit")          then return "Join"
            elseif (actionType == "SupplyModelUnit")        then return "Supply"
            elseif (actionType == "Surface")                then return "Surface"
            elseif (actionType == "BuildModelTile")         then return "Build"
            elseif (actionType == "ProduceModelUnitOnUnit") then return "Produce"
            elseif (actionType == "LaunchSilo")             then return "Launch"
            elseif (actionType == "LaunchFlare")            then return "Flare"
            else                                                 return "Unknown78:" .. (actionType or "")
            end
        end,
    },
    [79] = {
        [1] = function() return "生 产"   end,
        [2] = function() return "Produce" end,
    },
    [80] = {
        [1] = function(textType)
            if     (textType == "NotInTurn")       then return "当前是您对手的回合，请耐心等候。"
            elseif (textType == "TransferingData") then return "正在传输数据，请稍后。\n若长时间没有反应，请重新载入战局。"
            else                                        return "未知文本类型[80]: " .. (textType or "")
            end
        end,
        [2] = function(textType)
            if     (textType == "NotInTurn")       then return "It's your opponent's turn. Please wait."
            elseif (textType == "TransferingData") then return "Transfering data.\nIf it's not responding, please reload the war."
            else                                        return "Unknown textType[80]: " .. (textType or "")
            end
        end,
    },
    [81] = {
        [1] = function(errType, text)
            text = (text) and ("" .. text) or ("")
            if     (errType == "AutoSyncWar")                    then return "检测到数据不同步，正在自动重新载入。"
            elseif (errType == "CorruptedAction")                then return "网络传输出现错误。请重试或刷新场景。" .. text
            elseif (errType == "DefeatedPlayer")                 then return "您在该战局中已被打败，无法再次进入。"
            elseif (errType == "EndedWar")                       then return "该战局已结束，无法再次进入。"
            elseif (errType == "FailToGetSkillConfiguration")    then return "无法获取技能配置，请重试。\n" .. text
            elseif (errType == "InvalidAccountForProfile")       then return "该账号不存在，无法获取其战绩。"
            elseif (errType == "InvalidAccountOrPassword")       then return "账号/密码不正确。将自动回到主界面。" .. text
            elseif (errType == "InvalidGameVersion")             then return "游戏版本无效，请下载新版。\n新版版本号：" .. text
            elseif (errType == "InvalidLogin")                   then return "账号/密码不正确，请检查后重试。"
            elseif (errType == "InvalidSkillConfiguration")      then return "技能配置无效，请检查后重试。" .. text
            elseif (errType == "InvalidWarFileName")             then return "战局不存在，或已结束。" .. text
            elseif (errType == "InvalidWarPassword")             then return "战局密码不正确，请检查后重试。"
            elseif (errType == "MultiJoinWar")                   then return "您已参战。"
            elseif (errType == "MultiLogin")                     then return "您的账号[" .. text .. "]在另一台设备上被登陆，您已被迫下线！"
            elseif (errType == "NoReplayData")                   then return "该回放数据不存在，无法下载。若一直遇到此问题，请与作者联系。"
            elseif (errType == "NotExitableWar")                 then return "该战局可能已经开始，无法退出。"
            elseif (errType == "NotJoinableWar")                 then return "战局可能已经开始，无法参战。请选择其他战局。"
            elseif (errType == "OccupiedPlayerIndex")            then return "您指定的行动顺序已被其他玩家占用。请使用其他顺序。"
            elseif (errType == "OutOfSync")                      then return "战局数据不同步。将自动刷新。" .. text .. "\n若无限刷新，请联系作者，谢谢！"
            elseif (errType == "OverloadedRankScore")            then return "您的积分超出了该战局的限制。请选择其它战局。"
            elseif (errType == "OverloadedSkillPoints")          then return "您选择的技能配置的点数超出了上限。请检查后重试。"
            elseif (errType == "OverloadedWarsCount")            then return "您已参加的战局数量太多，暂无法创建房间或参战。请耐心等候已有的战局结束。"
            elseif (errType == "RegisteredAccount")              then return "该账号已被注册，请使用其他账号。"
            elseif (errType == "SucceedToSetSkillConfiguration") then return "技能配置已保存。" .. text
            else                                                      return "未知81:" .. (errType or "")
            end
        end,
        [2] = function(errType, text)
            text = (text) and ("" .. text) or ("")
            if     (errType == "AutoSyncWar")                    then return "The war is out-of-sync. Now synchronizing."
            elseif (errType == "CorruptedAction")                then return "Data transfer error." .. text
            elseif (errType == "DefeatedPlayer")                 then return "You have been defeated in the war."
            elseif (errType == "EndedWar")                       then return "The war is ended."
            elseif (errType == "FailToGetSkillConfiguration")    then return "Failed to get the skill configuration. Please retry.\n" .. text
            elseif (errType == "InvalidAccountForProfile")       then return "The account doesn't exist."
            elseif (errType == "InvalidAccountOrPassword")       then return "Invalid account/password." .. text
            elseif (errType == "InvalidGameVersion")             then return "Your game version is invalid. Please download the latest version:" .. text
            elseif (errType == "InvalidLogin")                   then return "Invalid account/password for login. Please check and retry."
            elseif (errType == "InvalidSkillConfiguration")      then return "The skill configuration is invalid. Please check and retry.\n" .. text
            elseif (errType == "InvalidWarFileName")             then return "The war is ended or invalid." .. text
            elseif (errType == "InvalidWarPassword")             then return "The war password is invalid. Please check and retry."
            elseif (errType == "MultiJoinWar")                   then return "You have already joined the war."
            elseif (errType == "MultiLogin")                     then return "Another device is logging in with your account [" .. account .. "], and you're kicked offline!"
            elseif (errType == "NoReplayData")                   then return "The replay data doesn't exist."
            elseif (errType == "NotExitableWar")                 then return "The war has begun already. You can no longer exit."
            elseif (errType == "NotJoinableWar")                 then return "The war has begun already. Please join another war."
            elseif (errType == "OccupiedPlayerIndex")            then return "The player index has been used by another player."
            elseif (errType == "OutOfSync")                      then return "The war data is out of sync." .. text
            elseif (errType == "OverloadedRankScore")            then return "Your rank score exceeds the limit of the war. Please choose another war to join."
            elseif (errType == "OverloadedSkillPoints")          then return "The skill points of the selected configuration is beyond the limitation."
            elseif (errType == "OverloadedWarsCount")            then return "You have joined too many wars. Please wait until one of them ends."
            elseif (errType == "RegisteredAccount")              then return "The account is registered already. Please use another account."
            elseif (errType == "SucceedToSetSkillConfiguration") then return "Save skill configuration successfully." .. text
            else                                                      return "Unknown81:" .. (errType or "")
            end
        end,
    },
    --[[
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
    --]]
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
        [1] = function(bonus, category) return "防御加成：" .. bonus .. "%（" .. category .. "）"     end,
        [2] = function(bonus, category) return "DefenseBonus: " .. bonus .. "% (" .. category .. ")" end,
    },
    [104] = {
        [1] = function(amount, category) return "维修：+" .. amount .. "HP（" .. category .. "）"   end,
        [2] = function(amount, category) return "Repair:  +" .. amount .. "HP (" .. category .. ")" end,
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
            if     (moveType == "Infantry")  then return "步兵"
            elseif (moveType == "Mech")      then return "炮兵"
            elseif (moveType == "TireA")     then return "重型轮胎"
            elseif (moveType == "TireB")     then return "轻型轮胎"
            elseif (moveType == "Tank")      then return "履带"
            elseif (moveType == "Air")       then return "飞行"
            elseif (moveType == "Ship")      then return "航行"
            elseif (moveType == "Transport") then return "海运"
            else                                  return "未知"
            end
        end,
        [2] = function(moveType)
            if     (moveType == "Infantry")  then return "Infantry"
            elseif (moveType == "Mech")      then return "Mech"
            elseif (moveType == "TireA")     then return "TireA"
            elseif (moveType == "TireB")     then return "TireB"
            elseif (moveType == "Tank")      then return "Tank"
            elseif (moveType == "Air")       then return "Air"
            elseif (moveType == "Ship")      then return "Ship"
            elseif (moveType == "Transport") then return "Transport"
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
            if     (unitType == "Infantry")        then return "步兵"
            elseif (unitType == "Mech")            then return "炮兵"
            elseif (unitType == "Bike")            then return "摩托兵"
            elseif (unitType == "Recon")           then return "侦察车"
            elseif (unitType == "Flare")           then return "照明车"
            elseif (unitType == "AntiAir")         then return "对空战车"
            elseif (unitType == "Tank")            then return "轻型坦克"
            elseif (unitType == "MediumTank")      then return "中型坦克"
            elseif (unitType == "WarTank")         then return "战争坦克"
            elseif (unitType == "Artillery")       then return "自走炮"
            elseif (unitType == "AntiTank")        then return "反坦克炮"
            elseif (unitType == "Rockets")         then return "火箭炮"
            elseif (unitType == "Missiles")        then return "对空导弹"
            elseif (unitType == "Rig")             then return "后勤车"
            elseif (unitType == "Fighter")         then return "战斗机"
            elseif (unitType == "Bomber")          then return "轰炸机"
            elseif (unitType == "Duster")          then return "攻击机"
            elseif (unitType == "BattleCopter")    then return "武装直升机"
            elseif (unitType == "TransportCopter") then return "运输直升机"
            elseif (unitType == "Seaplane")        then return "舰载机"
            elseif (unitType == "Battleship")      then return "战列舰"
            elseif (unitType == "Carrier")         then return "航空母舰"
            elseif (unitType == "Submarine")       then return "潜艇"
            elseif (unitType == "Cruiser")         then return "巡洋舰"
            elseif (unitType == "Lander")          then return "登陆舰"
            elseif (unitType == "Gunboat")         then return "炮舰"
            elseif (unitType == "Meteor")          then return "陨石"
            else                                        return "未知"
            end
        end,
        [2] = function(unitType)
            if     (unitType == "Infantry")        then return "Inf"
            elseif (unitType == "Mech")            then return "Mech"
            elseif (unitType == "Bike")            then return "Bike"
            elseif (unitType == "Recon")           then return "Recon"
            elseif (unitType == "Flare")           then return "Flare"
            elseif (unitType == "AntiAir")         then return "AAir"
            elseif (unitType == "Tank")            then return "Tank"
            elseif (unitType == "MediumTank")      then return "MTank"
            elseif (unitType == "WarTank")         then return "WTank"
            elseif (unitType == "Artillery")       then return "Artlry"
            elseif (unitType == "AntiTank")        then return "ATank"
            elseif (unitType == "Rockets")         then return "Rocket"
            elseif (unitType == "Missiles")        then return "Missile"
            elseif (unitType == "Rig")             then return "Rig"
            elseif (unitType == "Fighter")         then return "Fighter"
            elseif (unitType == "Bomber")          then return "Bomber"
            elseif (unitType == "Duster")          then return "Duster"
            elseif (unitType == "BattleCopter")    then return "BCopter"
            elseif (unitType == "TransportCopter") then return "TCopter"
            elseif (unitType == "Seaplane")        then return "Seapl"
            elseif (unitType == "Battleship")      then return "BShip"
            elseif (unitType == "Carrier")         then return "Carrier"
            elseif (unitType == "Submarine")       then return "Sub"
            elseif (unitType == "Cruiser")         then return "Cruiser"
            elseif (unitType == "Lander")          then return "Lander"
            elseif (unitType == "Gunboat")         then return "GBoat"
            elseif (unitType == "Meteor")          then return "Meteor"
            else                                        return "Unknown"
            end
        end,
    },
    [114] = {
        [1] = function(unitType)
            if     (unitType == "Infantry")        then return "步兵：最便宜的部队。能占领建筑和发射导弹，但攻防很弱。"
            elseif (unitType == "Mech")            then return "炮兵：能占领建筑和发射导弹。火力不错，但移动力和防御较弱。"
            elseif (unitType == "Bike")            then return "摩托兵：能占领建筑和发射导弹。在平坦地形上移动力不错，但攻防很弱。"
            elseif (unitType == "Recon")           then return "侦察车：移动力优秀，视野广。能有效打击步兵系，但对其他部队的攻防较差。"
            elseif (unitType == "Flare")           then return "照明车：能够远程投射大范围的照明弹。攻防能力一般。"
            elseif (unitType == "AntiAir")         then return "对空战车：能够有效打击空军和步兵系，但对坦克系较弱。"
            elseif (unitType == "Tank")            then return "轻型坦克：各属性均衡，是陆军的中流砥柱。"
            elseif (unitType == "MediumTank")      then return "中型坦克：攻防比轻型坦克更强，但移动力稍弱。"
            elseif (unitType == "WarTank")         then return "战争坦克：攻防最强的坦克。移动力较差。"
            elseif (unitType == "Artillery")       then return "自走炮：最便宜的远程部队，能够有效打击陆军和海军。防御较弱。"
            elseif (unitType == "AntiTank")        then return "反坦克炮：对近身攻击能够作出反击的远程部队。对坦克系尤其有效。防御力优秀，但移动力差。"
            elseif (unitType == "Rockets")         then return "火箭炮：攻击力和射程都比自走炮优秀的远程部队。防御力很差。"
            elseif (unitType == "Missiles")        then return "对空导弹：射程很远，能秒杀任何空军的远程部队。无法攻击陆军和海军，且防御很差。"
            elseif (unitType == "Rig")             then return "后勤车：能够装载一个步兵或炮兵。能够建造临时机场或海港、补给临近的部队。不能攻击。"
            elseif (unitType == "Fighter")         then return "战斗机：拥有最高的移动力，对空军的战斗力很优秀。无法攻击陆军和海军。"
            elseif (unitType == "Bomber")          then return "轰炸机：能对陆军和海军造成致命打击。无法攻击空军。"
            elseif (unitType == "Duster")          then return "攻击机：移动力优秀，能对空军造成有效打击，也能对陆军造成一定损伤。"
            elseif (unitType == "BattleCopter")    then return "武装直升机：能对陆军和直升机系造成有效打击，也能一定程度打击海军。"
            elseif (unitType == "TransportCopter") then return "运输直升机：能够装载一个步兵或炮兵。不能攻击。"
            elseif (unitType == "Seaplane")        then return "舰载机：能够对任何部队都造成有效打击。只能用航母生产。燃料和弹药都很少。"
            elseif (unitType == "Battleship")      then return "战列舰：攻防优秀，而且能移动后立刻进行攻击的远程部队。不能攻击空军。"
            elseif (unitType == "Carrier")         then return "航空母舰：能够生产舰载机，以及装载两个空军单位。自身只能对空军造成少量伤害，防御力较差。"
            elseif (unitType == "Submarine")       then return "潜艇：能够下潜使得敌军难以发现，且下潜后只能被潜艇和巡洋舰攻击。能有效打击巡洋舰以外的海军，无法攻击空军和陆军。"
            elseif (unitType == "Cruiser")         then return "巡洋舰：能够对潜艇和空军造成毁灭性打击，对其他海军也有一定打击能力。能够装载两个直升机部队。不能攻击陆军。"
            elseif (unitType == "Lander")          then return "登陆舰：能够在海滩地形装载和卸载最多两个陆军部队。不能攻击。"
            elseif (unitType == "Gunboat")         then return "炮舰：能够装载一个步兵或炮兵。能够有效打击海军，但只有一枚弹药。防御力较差。"
            else                                        return "未知"
            end
        end,
        [2] = function(unitType)
            if     (unitType == "Infantry")        then return "Infantry units are cheap. They can capture bases but have low firepower."
            elseif (unitType == "Mech")            then return "Mech units can capture bases, traverse most terrain types, and have superior firepower."
            elseif (unitType == "Bike")            then return "Bikes are infantry units with high mobility. They can capture bases but have low firepower."
            elseif (unitType == "Recon")           then return "Recon units have high movement range and are strong against infantry units."
            elseif (unitType == "Flare")           then return "Flares fire bright rockets that reveal a 13-square area in Fog of War."
            elseif (unitType == "AntiAir")         then return "Anti-Air units work well against infantry and air units. They're weak against tanks."
            elseif (unitType == "Tank")            then return "Tank units have high movement range and are inexpensive, so they're easy to deploy."
            elseif (unitType == "MediumTank")      then return "Md(Medium) tank units' defensive and offensive ratings are the second best among ground units."
            elseif (unitType == "WarTank")         then return "War Tank units are the strongest tanks in terms of both attack and defense."
            elseif (unitType == "Artillery")       then return "Artillery units are an inexpensive way to gain indirect offensive attack capabilities."
            elseif (unitType == "AntiTank")        then return "Anti-Tanks can counter-attack when under direct fire."
            elseif (unitType == "Rockets")         then return "Rockets units are valuable, because they can fire on both land and naval units."
            elseif (unitType == "Missiles")        then return "Missiles units are essential in defending against air units. Their vision range is large."
            elseif (unitType == "Rig")             then return "Rig units can carry 1 foot soldier and build temp airports/seaports."
            elseif (unitType == "Fighter")         then return "Fighter units are strong vs. other air units. They also have the highest movements."
            elseif (unitType == "Bomber")          then return "Bomber units can fire on ground and naval units with a high destructive force."
            elseif (unitType == "Duster")          then return "Dusters are somewhat powerful planes that can attack both ground and air units."
            elseif (unitType == "BattleCopter")    then return "B(Battle) copter units can fire on many unit types, so they're quite valuable."
            elseif (unitType == "TransportCopter") then return "T(transport) copters can transport both infantry and mech units."
            elseif (unitType == "Seaplane")        then return "Seaplanes are produced at sea by carriers. They can attack any unit."
            elseif (unitType == "Battleship")      then return "Battleships can launch indirect attack after moving."
            elseif (unitType == "Carrier")         then return "Carriers can carrier 2 air units and produce seaplanes."
            elseif (unitType == "Submarine")       then return "Submerged submarines are difficult to find, and only cruisers and subs can fire on them."
            elseif (unitType == "Cruiser")         then return "Cruisers are strong against subs and air units, and they can carry two copter units."
            elseif (unitType == "Lander")          then return "Landers can transport two ground units. If the lander sinks, the units vanish."
            elseif (unitType == "Gunboat")         then return "Gunboats can carry 1 foot soldier and attack other naval units."
            else                                        return "Unknown"
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
            if     (tileType == "Plain")         then return "平原"
            elseif (tileType == "River")         then return "河流"
            elseif (tileType == "Sea")           then return "海洋"
            elseif (tileType == "Beach")         then return "海滩"
            elseif (tileType == "Road")          then return "道路"
            elseif (tileType == "BridgeOnRiver") then return "桥梁"
            elseif (tileType == "BridgeOnSea")   then return "桥梁"
            elseif (tileType == "Wood")          then return "森林"
            elseif (tileType == "Mountain")      then return "山地"
            elseif (tileType == "Wasteland")     then return "荒野"
            elseif (tileType == "Ruins")         then return "���墟"
            elseif (tileType == "Fire")          then return "火焰"
            elseif (tileType == "Rough")         then return "巨浪"
            elseif (tileType == "Mist")          then return "迷雾"
            elseif (tileType == "Reef")          then return "礁石"
            elseif (tileType == "Plasma")        then return "等离子体"
            elseif (tileType == "GreenPlasma")   then return "绿色等离子"
            elseif (tileType == "Meteor")        then return "陨石"
            elseif (tileType == "Silo")          then return "导弹发射塔"
            elseif (tileType == "EmptySilo")     then return "空发射塔"
            elseif (tileType == "Headquarters")  then return "总部"
            elseif (tileType == "City")          then return "城市"
            elseif (tileType == "CommandTower")  then return "指挥塔"
            elseif (tileType == "Radar")         then return "雷达"
            elseif (tileType == "Factory")       then return "工厂"
            elseif (tileType == "Airport")       then return "机场"
            elseif (tileType == "Seaport")       then return "海港"
            elseif (tileType == "TempAirport")   then return "临时机场"
            elseif (tileType == "TempSeaport")   then return "临时海港"
            else                                      return "未知116: " .. (tileType or "")
            end
        end,
        [2] = function(tileType)
            if     (tileType == "Plain")         then return "Plain"
            elseif (tileType == "River")         then return "River"
            elseif (tileType == "Sea")           then return "Sea"
            elseif (tileType == "Beach")         then return "Beach"
            elseif (tileType == "Road")          then return "Road"
            elseif (tileType == "BridgeOnRiver") then return "Bridge"
            elseif (tileType == "BridgeOnSea")   then return "Bridge"
            elseif (tileType == "Wood")          then return "Wood"
            elseif (tileType == "Mountain")      then return "Mtn"
            elseif (tileType == "Wasteland")     then return "Wstld"
            elseif (tileType == "Ruins")         then return "Ruins"
            elseif (tileType == "Fire")          then return "Fire"
            elseif (tileType == "Rough")         then return "Rough"
            elseif (tileType == "Mist")          then return "Mist"
            elseif (tileType == "Reef")          then return "Reef"
            elseif (tileType == "Plasma")        then return "Plasma"
            elseif (tileType == "GreenPlasma")   then return "Plasma"
            elseif (tileType == "Meteor")        then return "Meteor"
            elseif (tileType == "Silo")          then return "Silo"
            elseif (tileType == "EmptySilo")     then return "Silo"
            elseif (tileType == "Headquarters")  then return "HQ"
            elseif (tileType == "City")          then return "City"
            elseif (tileType == "CommandTower")  then return "Com"
            elseif (tileType == "Radar")         then return "Radar"
            elseif (tileType == "Factory")       then return "Fctry"
            elseif (tileType == "Airport")       then return "APort"
            elseif (tileType == "Seaport")       then return "SPort"
            elseif (tileType == "TempAirport")   then return "TempAP"
            elseif (tileType == "TempSeaport")   then return "TempSP"
            else                                      return "Unknown116: " .. (tileType or "")
            end
        end,
    },
    [117] = {
        [1] = function(tileType)
            if     (tileType == "Plain")         then return "平原：允许空军和陆军通过。"
            elseif (tileType == "River")         then return "河流：允许空军、步兵和炮兵通过。"
            elseif (tileType == "Sea")           then return "海洋：允许空军和海军通过。"
            elseif (tileType == "Beach")         then return "海滩：登陆舰和炮舰可以在这里装载和卸载部队。允许大多数部队通过。"
            elseif (tileType == "Road")          then return "道路：允许空军和陆军通过。"
            elseif (tileType == "BridgeOnRiver") then return "桥梁：河流及陆地上的桥梁允许空军和陆军通过。"
            elseif (tileType == "BridgeOnSea")   then return "桥梁：海洋上的桥梁允许空军和陆军通过，海军也能在桥下经过和停留。"
            elseif (tileType == "Wood")          then return "森林：允许空军和陆军通过。在雾战时，为陆军提供隐蔽场所。"
            elseif (tileType == "Mountain")      then return "山地：允许空军、步兵和炮兵通过。在雾战时，为步兵和炮兵提供额外视野。"
            elseif (tileType == "Wasteland")     then return "荒野：允许空军和陆军通过，但会减缓步兵和炮兵以外的陆军的移动。"
            elseif (tileType == "Ruins")         then return "废墟：允许空军和陆军通过。雾战时，为陆军提供隐蔽场所。"
            elseif (tileType == "Fire")          then return "火焰：不允许任何部队通过。在雾战时无条件照明周围5格内的区域。"
            elseif (tileType == "Rough")         then return "巨浪：允许空军和海军通过，但会减缓海军的移动。"
            elseif (tileType == "Mist")          then return "迷雾：允许空军和海军通过。在雾战时，为海军提供隐蔽场所。"
            elseif (tileType == "Reef")          then return "礁石：允许空军和海军通过，但会减缓海军的移动。在雾战时，为海军提供隐蔽场所。"
            elseif (tileType == "Plasma")        then return "等离子体：不允许任何部队通过。若直接或间接相连的陨石被击破则消失。"
            elseif (tileType == "GreenPlasma")   then return "绿色等离子：不允许任何部队通过。"
            elseif (tileType == "Meteor")        then return "陨石：不允许任何部队通过。可以被部队攻击和破坏。"
            elseif (tileType == "Silo")          then return "导弹发射塔：步兵系可以在这里发射一次导弹，用来打击任意位置的小范围的部队。"
            elseif (tileType == "EmptySilo")     then return "空发射塔：使用过的导弹发射塔，无法再次发射导弹。允许空军和陆军通过。"
            elseif (tileType == "Headquarters")  then return "总部：可以提供资金和维修陆军。若我方总部被占领，则我方战败。"
            elseif (tileType == "City")          then return "城市：可以提供资金和维修陆军。"
            elseif (tileType == "CommandTower")  then return "指挥塔：可以提供资金，且为我方全体部队提供5%攻防加成。"
            elseif (tileType == "Radar")         then return "雷达：可以提供资金，且在雾战时照明5格范围内的区域。"
            elseif (tileType == "Factory")       then return "工厂：可以提供资金、生产和维修陆军。"
            elseif (tileType == "Airport")       then return "机场：可以提供资金、生产和维修空军。"
            elseif (tileType == "Seaport")       then return "海港：可以提供资金、生产和维修海军。"
            elseif (tileType == "TempAirport")   then return "临时机场：可以维修空军。不提供资金，也不能生产部队。"
            elseif (tileType == "TempSeaport")   then return "临时海港：可以维修海军。不提供资金，也不能生产部队。"
            else                                      return "未知117: " .. (tileType or "")
            end
        end,
        [2] = function(tileType)
            if     (tileType == "Plain")         then return "Plains are easily traveled but offer little defense."
            elseif (tileType == "River")         then return "Rivers can be passed by foot soldiers only."
            elseif (tileType == "Sea")           then return "Seas provide good mobility for air and naval units."
            elseif (tileType == "Beach")         then return "Beaches provide places for landers and gunboats to load and unload units."
            elseif (tileType == "Road")          then return "Roads provide optimum mobility but little defensive cover."
            elseif (tileType == "BridgeOnRiver") then return "Naval units can't pass under river/land bridges."
            elseif (tileType == "BridgeOnSea")   then return "Naval units can pass under sea bridges."
            elseif (tileType == "Wood")          then return "Woods provide hiding places for ground units in Fog of War."
            elseif (tileType == "Mountain")      then return "Mountains add 3 vision for foot soldiers in Fog of War."
            elseif (tileType == "Wasteland")     then return "Wastelands impair mobility for all but air units and foot soldiers."
            elseif (tileType == "Ruins")         then return "Ruins provide hiding places for ground units in Fog of War."
            elseif (tileType == "Fire")          then return "Fires prevent unit movement and illuminate a 5-square area in Fog of War."
            elseif (tileType == "Rough")         then return "Rough seas slow the movement of naval units."
            elseif (tileType == "Mist")          then return "Mists provide hiding places for naval units in Fog of War."
            elseif (tileType == "Reef")          then return "Reefs provide hiding places for naval units in Fog of War."
            elseif (tileType == "Plasma")        then return "Plasma is impassable."
            elseif (tileType == "GreenPlasma")   then return "Green Plasma is impassable."
            elseif (tileType == "Meteor")        then return "Meteors are impassable but can be destroyed."
            elseif (tileType == "Silo")          then return "Silos can be launched by infantry units and damage a 13-square area."
            elseif (tileType == "EmptySilo")     then return "Empty Silos can't be launched."
            elseif (tileType == "Headquarters")  then return "HQs provide resupply for ground units. Battle ends if it's captured."
            elseif (tileType == "City")          then return "Cities provide resupply for ground units."
            elseif (tileType == "CommandTower")  then return "Command towers boosts your attack once captured."
            elseif (tileType == "Radar")         then return "Radars reveal a 5-square area in Fog of War once captured."
            elseif (tileType == "Factory")       then return "Factories can be used to resupply and produce ground units once captured."
            elseif (tileType == "Airport")       then return "Airports can be used to resupply and produce air units once captured."
            elseif (tileType == "Seaport")       then return "Seaports can be used to resupply and produce naval units once captured."
            elseif (tileType == "TempAirport")   then return "Temp airports provide resupply for air units."
            elseif (tileType == "TempSeaport")   then return "Temp seaports provide resupply for naval units."
            else                                      return "Unknown117: " .. (tileType or "")
            end
        end,
    },
    [118] = {
        [1] = function(categoryType)
            if     (categoryType == "GroundUnits")       then return "陆军"
            elseif (categoryType == "NavalUnits")        then return "海军"
            elseif (categoryType == "AirUnits")          then return "空军"
            elseif (categoryType == "Ground/NavalUnits") then return "陆军/海军"
            elseif (categoryType == "FootUnits")         then return "步兵/炮兵"
            elseif (categoryType == "None")              then return "无"
            else                                              return "未知"
            end
        end,
        [2] = function(categoryType)
            if     (categoryType == "GroundUnits")       then return "Ground Units"
            elseif (categoryType == "NavalUnits")        then return "Naval Units"
            elseif (categoryType == "AirUnits")          then return "Air Units"
            elseif (categoryType == "Ground/NavalUnits") then return "Ground/Naval Units"
            elseif (categoryType == "FootUnits")         then return "Foot Units"
            elseif (categoryType == "None")              then return "None"
            else                                              return "Unknown"
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

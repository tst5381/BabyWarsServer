
return {
    fileName    = "0000000000000000",
    warPassword = "",
    isEnded     = false,
    actionID    = 0,

    warField = {
        tileMap = {
            template = "JiangQi",
        },

        unitMap = {
            template = "JiangQi",
        },
    },

    turn = {
        turnIndex   = 1,
        playerIndex = 1,
        phase       = "requestToBegin",
    },

    players = {
        {
            account            = "babygogogo",
            nickname           = "Red Alice",
            fund               = 0,
            isAlive            = true,
            currentEnergy      = 0,
            skillConfiguration = {
                maxPoints = 100,
                passive   = {
                    {name = "GlobalAttackModifier",  level = 5,},
                    {name = "GlobalDefenseModifier", level = -15,},
                    {name = "GlobalCostModifier",    level = 15,},
                },
                active1   = {},
                active2   = {},
            },
        },
        {
            account            = "tester1",
            nickname           = "Blue Bob",
            fund               = 0,
            isAlive            = true,
            currentEnergy      = 0,
            skillConfiguration = {
                maxPoints = 100,
                passive   = {
                    {name = "GlobalAttackModifier",  level = 20,},
                    {name = "GlobalDefenseModifier", level = 30,},
                    {name = "GlobalCostModifier",    level = -30,},
                },
                active1   = {},
                active2   = {},
            },
        },
    },

    weather = {
        current = "clear"
    },
}


return {
    fileName    = "0000000000000003",
    warPassword = "",
    isEnded     = false,
    actionID    = 0,
    maxSkillPoints = 100,

    warField = {
        tileMap = {
            template = "FullTest",
        },

        unitMap = {
            template = "FullTest",
        },
    },

    turn = {
        turnIndex   = 1,
        playerIndex = 1,
        phase       = "requestToBegin",
    },

    players = {
        {
            account                = "babygogogo",
            nickname               = "Red Alice",
            fund                   = 0,
            isAlive                = true,
            damageCost             = 0,
            skillActivatedCount    = 0,
            skillConfiguration = {
                maxPoints = 100,
                passive   = {
                    {id = 1, level = 5,},
                    {id = 2, level = -15,},
                    {id = 3, level = 15,},
                },
                active1   = {
                    {id = 1, level = 30},
                    energyRequirement = 3,
                },
                active2   = {
                    {id = 1, level = 30},
                    {id = 3, level = 30},
                    energyRequirement = 6,
                },
            },
        },
        {
            account                = "tester1",
            nickname               = "Blue Bob",
            fund                   = 0,
            isAlive                = true,
            damageCost             = 0,
            skillActivatedCount    = 0,
            skillConfiguration = {
                maxPoints = 100,
                passive   = {
                    {id = 1, level = 20,},
                    {id = 2, level = 30,},
                    {id = 3, level = -30,},
                },
                active1   = {},
                active2   = {
                    {id = 1, level = 30},
                    {id = 2, level = 30},
                    {id = 3, level = 10},
                    energyRequirement = 6,
                },
            },
        },
        {
            account                = "tester2",
            nickname               = "Yellow Cat",
            fund                   = 0,
            isAlive                = true,
            damageCost             = 0,
            skillActivatedCount    = 0,
            skillConfiguration = {
                maxPoints = 100,
                passive = {},
                active1 = {},
                active2 = {},
            },
        },
        {
            account                = "tester3",
            nickname               = "Black Dog",
            fund                   = 0,
            isAlive                = true,
            damageCost             = 0,
            skillActivatedCount    = 0,
            skillConfiguration = {
                maxPoints = 100,
                passive = {},
                active1 = {},
                active2 = {},
            },
        },
    },

    weather = {
        current = "Clear"
    },
}

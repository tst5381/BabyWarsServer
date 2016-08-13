
return {
    fileName    = "0000000000000003",
    warPassword = "",
    isEnded     = false,
    actionID    = 0,
    maxSkillPoints = 100,

    warField = {
        tileMap = {
            template = "FullTest",

            grids = {
                {
                    GridIndexable = {
                        gridIndex = {x = 17, y = 5},
                    },
                    objectID = 107,
                },
                {
                    GridIndexable = {
                        gridIndex = {x = 18, y = 5},
                    },
                    objectID = 107,
                },
                {
                    GridIndexable = {
                        gridIndex = {x = 19, y = 5},
                    },
                    objectID = 107,
                },
                {
                    GridIndexable = {
                        gridIndex = {x = 19, y = 4},
                    },
                    objectID = 107,
                },
                {
                    GridIndexable = {
                        gridIndex = {x = 17, y = 3},
                    },
                    objectID = 107,
                },
                {
                    GridIndexable = {
                        gridIndex = {x = 18, y = 3},
                    },
                    objectID = 107,
                },
                {
                    GridIndexable = {
                        gridIndex = {x = 19, y = 3},
                    },
                    objectID = 107,
                },
                {
                    GridIndexable = {
                        gridIndex = {x = 17, y = 2},
                    },
                    objectID = 107,
                },
                {
                    GridIndexable = {
                        gridIndex = {x = 17, y = 1},
                    },
                    objectID = 107,
                },
                {
                    GridIndexable = {
                        gridIndex = {x = 18, y = 1},
                    },
                    objectID = 107,
                },
                {
                    GridIndexable = {
                        gridIndex = {x = 19, y = 1},
                    },
                    objectID = 107,
                },
            },
        },

        unitMap = {
            template = "FullTest",

            grids = {
                -- There's a template map, so that the grids data is ignored even if it's not empty.
            },
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
            activatingSkillGroupID = 0,
            skillConfiguration = {
                maxPoints = 100,
                passive   = {
                    {id = 1, level = 5,},
                    {id = 2, level = -15,},
                    {id = 3, level = 15,},
                },
                active1   = {
                    {id = 1, level = 30},
                    isEnabled         = true,
                    energyRequirement = 3,
                },
                active2   = {
                    {id = 1, level = 30},
                    {id = 3, level = 30},
                    isEnabled         = true,
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
            activatingSkillGroupID = 0,
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
                    isEnabled         = true,
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
            activatingSkillGroupID = 0,
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
            activatingSkillGroupID = 0,
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

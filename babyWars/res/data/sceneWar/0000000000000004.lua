
return {
    fileName    = "0000000000000004",
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
                        gridIndex = {x = 19, y = 2},
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
            -- There's no template map, so that the grids data is used.
            mapSize = {width = 25, height = 16},
            availableUnitId = 5,

            grids = {
                {
                    tiledID = 163,
                    unitID  = 1,
                    GridIndexable = {gridIndex = {x = 6, y = 7}},
                },
                {
                    tiledID = 164,
                    unitID  = 2,
                    GridIndexable = {gridIndex = {x = 7, y = 7}},
                },
                {
                    tiledID = 165,
                    unitID  = 3,
                    GridIndexable = {gridIndex = {x = 8, y = 7}},
                },
                {
                    tiledID = 166,
                    unitID  = 4,
                    GridIndexable = {gridIndex = {x = 9, y = 7}},
                },
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
            skillConfiguration = {
                maxPoints = 100,
                skillActivatedCount    = 0,
                passive = {},
                active1 = {},
                active2 = {},
            },
        },
        {
            account                = "tester1",
            nickname               = "Blue Bob",
            fund                   = 0,
            isAlive                = true,
            damageCost             = 0,
            skillConfiguration = {
                maxPoints = 100,
                skillActivatedCount    = 0,
                passive = {},
                active1 = {},
                active2 = {},
            },
        },
        {
            account                = "tester2",
            nickname               = "Yellow Cat",
            fund                   = 0,
            isAlive                = true,
            damageCost             = 0,
            skillConfiguration = {
                maxPoints = 100,
                skillActivatedCount    = 0,
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
            skillConfiguration = {
                maxPoints = 100,
                skillActivatedCount    = 0,
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

   HO  S           AccountAndPassword3               account            password�          ActionActivateSkillp           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData            skillID         
   skillLevel            isActiveSkill�          ActionAttack�           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID       ~     targetGridIndex            attackDamage            counterDamage            lostPlayerIndex          ActionBeginTurn�            
   actionCode            playerAccount            playerPassword            warID        
    actionID            income            lostPlayerIndex       
  
   repairData         
   supplyData�           ActionBeginTurn.RepairData^               remainingFund           	   onMapData           
   loadedDatao        +   ActionBeginTurn.RepairData.RepairDataLoaded6               unitID            repairAmount�        *   ActionBeginTurn.RepairData.RepairDataOnMapQ               unitID            repairAmount       ~  	   gridIndexg           ActionBeginTurn.SupplyData?              	   onMapData           
   loadedDataQ        +   ActionBeginTurn.SupplyData.SupplyDataLoaded               unitIDk        *   ActionBeginTurn.SupplyData.SupplyDataOnMap3               unitID       ~  	   gridIndexr          ActionBuildModelTileP           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID�          ActionCaptureModelTileq           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID            lostPlayerIndex�        
   ActionChat�            
   actionCode            playerAccount            playerPassword            warID        
 	   channelID            senderPlayerIndex            chatText�           ActionDeclareSkill�            
   actionCode            playerAccount            playerPassword            warID        
    actionID`          ActionDestroyOwnedModelUnit7           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       ~  	   gridIndexh       
   ActionDiveP           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID|           ActionDownloadReplayDataV            
   actionCode            warID            encodedReplayData�          ActionDropModelUnit�           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID        x      dropDestinations            isDropBlocked�           ActionEndTurn�            
   actionCode            playerAccount            playerPassword            warID        
    actionID�           ActionExitWarr            
   actionCode            playerAccount            playerPassword            warID�          ActionGeneric�           
   ActionChat&       "     ActionDownloadReplayData       (     ActionExitWar0       , 
 "   ActionGetJoinableWarConfigurations/       .  !   ActionGetOngoingWarConfigurations$       0     ActionGetPlayerProfile"       2     ActionGetRankingList+       4     ActionGetReplayConfigurations/       6  !   ActionGetWaitingWarConfigurations       :     ActionJoinWar       B     ActionLogin       D     ActionLogout       F     ActionMessage$       H     ActionNetworkHeartbeat       J      ActionNewWar       R "    ActionRegister"       T $    ActionReloadSceneWar        V &    ActionRunSceneMain       X (    ActionRunSceneWar        ` ,    ActionSyncSceneWar!        �    ActionActivateSkill        �    ActionAttack        �    ActionBeginTurn"        �    ActionBuildModelTile$        �    ActionCaptureModelTile         �    ActionDeclareSkill)        �    ActionDestroyOwnedModelUnit         � 
   ActionDive!       $ �    ActionDropModelUnit       & �    ActionEndTurn!       8 �    ActionJoinModelUnit       < �    ActionLaunchFlare       > �    ActionLaunchSilo!       @ �    ActionLoadModelUnit*       L �    ActionProduceModelUnitOnTile*       N �    ActionProduceModelUnitOnUnit#       Z �    ActionSupplyModelUnit       \ �    ActionSurface       ^ �    ActionSurrender       b �    ActionVoteForDraw       d � 
   ActionWait�        "   ActionGetJoinableWarConfigurations�            
   actionCode            playerAccount            playerPassword            warID#       � 
      warConfigurations�        !   ActionGetOngoingWarConfigurations�            
   actionCode            playerAccount            playerPassword#       �       warConfigurations~           ActionGetPlayerProfileZ            
   actionCode            playerAccount       �     playerProfile           ActionGetRankingList]            
   actionCode            rankingListIndex       �      rankingList�           ActionGetReplayConfigurations]            
   actionCode            warID&       �       replayConfigurations�        !   ActionGetWaitingWarConfigurations�            
   actionCode            playerAccount            playerPassword#       �       warConfigurationsq          ActionJoinModelUnitP           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID�           ActionJoinWar�            
   actionCode            playerAccount            playerPassword            warID        
    playerIndex            warPassword            isWarStarted�          ActionLaunchFlareq           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID       ~     targetGridIndex�          ActionLaunchSiloq           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID       ~     targetGridIndexq          ActionLoadModelUnitP           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID�           ActionLoginx            
   actionCode            clientVersion            loginAccount            loginPasswordt           ActionLogoutZ            
   actionCode            messageCode             messageParamsu           ActionMessageZ            
   actionCode            messageCode             messageParams�           ActionNetworkHeartbeat}            
   actionCode            heartbeatCounter            playerAccount            playerPassword^          ActionNewWarD           
   actionCode            playerAccount            playerPassword            warID        
    warPassword            warFieldFileName            playerIndex!            isFogOfWarByDefault             defaultWeatherCode            isRankMatch            maxDiffScore            intervalUntilBoot             energyGainModifier#            isPassiveSkillEnabled"            isActiveSkillEnabled             incomeModifier        "    startingEnergy        $    startingFundF          ActionProduceModelUnitOnTile           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles            tiledID       ~  	   gridIndex            cost�          ActionProduceModelUnitOnUnitf           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID            cost[           ActionRedisB            
   actionCode"            encodedActionGeneric�           ActionRegister~            
   actionCode            clientVersion            registerAccount            registerPassword�           ActionReloadSceneWar�            
   actionCode            playerAccount            playerPassword            warID       � 
    warDataz           ActionRunSceneMainZ            
   actionCode            messageCode             messageParams�           ActionRunSceneWar�            
   actionCode            playerAccount            playerPassword            warID       � 
    warDatas          ActionSupplyModelUnitP           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitIDk          ActionSurfaceP           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID�           ActionSurrender�            
   actionCode            playerAccount            playerPassword            warID        
    actionID�           ActionSyncSceneWar�            
   actionCode            playerAccount            playerPassword            warID        
    actionID�           ActionVoteForDraw�            
   actionCode            playerAccount            playerPassword            warID        
    actionID         	   doesAgreeh       
   ActionWaitP           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID7        
   AttackDoer          h     primaryWeaponN        #   AttackDoer.PrimaryWeaponCurrentAmmo               currentAmmo4           AttackTaker            	   currentHP:        	   Buildable#               currentBuildPoint=        
   Capturable%   !            currentCapturePoint3           Capturer               isCapturing5           ChatChannel          t      messages^           ChatChannel.ChatMessage9               text            senderPlayerIndex-           Diver               isDivingP           DropDestination3               unitID       ~  	   gridIndex8           FlareLauncher               currentAmmo0        	   FuelOwner               current=        	   GridIndex&               x            yA           GridIndexable&               x            y7           JoinableWarList          �       list4           MaterialOwner               currento           MovePathY          ~   	   pathNodes            fuelConsumption         	   isBlocked?           OngoingWarListForServer          �       list7           PlayerAccountList                listh        
   PlayerInfoP               playerIndex            account            nickname�           PlayerProfile�               playerID            account            password            nickname       � 
     gameRecords       �     warLists!            totalOnlineDuration�           PlayerProfile.SingleGameRecord\            	   rankScore            win            lose            drawx           PlayerProfile.WarListsT          �       ongoing       �       waiting             recent�           PlayerProfileForClient�               account            nickname       �      gameRecords       �     warLists        
    playerID!            totalOnlineDurationd           PlayerProfileForClient.WarLists7          �       waiting             recent1        
   Promotable               current1           RankingList          �      listT           RankingListItem7            	   rankScore             accounts<           RankingListsForServer          �      listsu           ReplayConfigurationT               warID            warFieldFileName       �      players;           ReplayListForClient          �       list]           ReplayListForServer<          �       fullList          
   recentList          SceneWar              warID            actionID         
   isWarEnded        
    isRandomWarField!            isFogOfWarByDefault            isTotalReplay            warPassword       *      executedActions       �       players       �     turn       �     warField       �     weather#            remainingVotesForDraw            isRankMatch             maxDiffScore        "    createdTime        $    intervalUntilBoot        &    enterTurnTime         (    energyGainModifier#        *    isPassiveSkillEnabled"        ,    isActiveSkillEnabled        .    incomeModifier        0    startingEnergy        2    startingFund       � 4    chatDataa           SceneWar.ChatDataB          r     publicChannel       r      privateChannels�           SceneWar.FogMapData�               forcingFogCode.             expiringPlayerIndexForForcingFog,            expiringTurnIndexForForcingFog       �       mapsForPathso           SceneWar.SingleFogMapForPathsD               playerIndex#            encodedFogMapForPathsi          SceneWar.SinglePlayerDataB              playerIndex            account            nickname            fund        
    isAlive            energy        �     skillConfiguration            hasVotedForDraw            isActivatingSkill            isSkillDeclared            canActivateSkill=           SceneWar.TileMapData          �       tilesv           SceneWar.TurnDataW            	   turnIndex            playerIndex            turnPhaseCode�           SceneWar.UnitMapDatab               availableUnitID       �    
   unitsOnMap       �       unitsLoaded�           SceneWar.WarFieldDatal               warFieldFileName       �     fogMap       �     tileMap       �     unitMap�           SceneWar.WeatherData�                currentWeatherCode             defaultWeatherCode+            expiringPlayerIndexForWeather)            expiringTurnIndexForWeather�            SingleGameRecordForPlayerProfile\            	   rankScore            win            lose            draw�           SingleSkillConfigurationf          �      passiveSkills!       �      researchingSkills       �      activeSkillsc        *   SingleSkillConfiguration.SingleSkillActive+               id            levelg        +   SingleSkillConfiguration.SingleSkillPassive.               id            modifier>           TileBuilder%   !            isBuildingModelTile�           TileData�               positionIndex            baseID            objectID       j     AttackTaker       l 
 	   Buildable       n  
   Capturable       �     GridIndexable�          UnitData�              unitID            tiledID         	   stateCode            isLoaded       f 
 
   AttackDoer       j     AttackTaker       p     Capturer       v     Diver       z     FlareLauncher       |  	   FuelOwner       �     GridIndexable       �     MaterialOwner       �  
   Promotable       �     TileBuilder       �  
   UnitLoader2        
   UnitLoader                loaded�          WarConfigurationj              warID            warFieldFileName            warPassword!        
    isFogOfWarByDefault             defaultWeatherCode            isRandomWarField       �       players            isRankMatch            maxDiffScore            createdTime            intervalUntilBoot            enterTurnTime            playerIndexInTurn             energyGainModifier#             isPassiveSkillEnabled"        "    isActiveSkillEnabled        $    incomeModifier        &    startingEnergy        (    startingFund5           WarIdForIndexing               warID
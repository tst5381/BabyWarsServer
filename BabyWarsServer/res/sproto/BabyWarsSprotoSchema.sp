   �P  S           AccountAndPassword3               account            password`          ActionActivateSkillGroup:           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData            skillGroupID�          ActionAttack�           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID       �     targetGridIndex            attackDamage            counterDamage            lostPlayerIndex          ActionBeginTurn�            
   actionCode            playerAccount            playerPassword            warID        
    actionID            income            lostPlayerIndex       
  
   repairData         
   supplyData�           ActionBeginTurn.RepairData^               remainingFund           	   onMapData           
   loadedDatao        +   ActionBeginTurn.RepairData.RepairDataLoaded6               unitID            repairAmount�        *   ActionBeginTurn.RepairData.RepairDataOnMapQ               unitID            repairAmount       �  	   gridIndexg           ActionBeginTurn.SupplyData?              	   onMapData           
   loadedDataQ        +   ActionBeginTurn.SupplyData.SupplyDataLoaded               unitIDk        *   ActionBeginTurn.SupplyData.SupplyDataOnMap3               unitID       �  	   gridIndexr          ActionBuildModelTileP           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID�          ActionCaptureModelTileq           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID            lostPlayerIndex�        
   ActionChat�            
   actionCode            playerAccount            playerPassword            warID        
 	   channelID            senderPlayerIndex            chatText`          ActionDestroyOwnedModelUnit7           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �  	   gridIndexh       
   ActionDiveP           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID|           ActionDownloadReplayDataV            
   actionCode            warID            encodedReplayData�          ActionDropModelUnit�           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID        z      dropDestinations            isDropBlocked�           ActionEndTurn�            
   actionCode            playerAccount            playerPassword            warID        
    actionID�           ActionExitWarr            
   actionCode            playerAccount            playerPassword            warID6          ActionGeneric           
   ActionChat&             ActionDownloadReplayData       &     ActionExitWar0       * 
 "   ActionGetJoinableWarConfigurations/       ,  !   ActionGetOngoingWarConfigurations$       .     ActionGetPlayerProfile"       0     ActionGetRankingList+       2     ActionGetReplayConfigurations)       4     ActionGetSkillConfiguration/       6  !   ActionGetWaitingWarConfigurations       :     ActionJoinWar       B     ActionLogin       D     ActionLogout       F     ActionMessage$       H      ActionNetworkHeartbeat       J "    ActionNewWar       R $    ActionRegister"       T &    ActionReloadSceneWar        V (    ActionRunSceneMain       X *    ActionRunSceneWar)       Z ,    ActionSetSkillConfiguration        b .    ActionSyncSceneWar&        �    ActionActivateSkillGroup        �    ActionAttack        �    ActionBeginTurn"        �    ActionBuildModelTile$        �    ActionCaptureModelTile)        �    ActionDestroyOwnedModelUnit        � 
   ActionDive!       " �    ActionDropModelUnit       $ �    ActionEndTurn!       8 �    ActionJoinModelUnit       < �    ActionLaunchFlare       > �    ActionLaunchSilo!       @ �    ActionLoadModelUnit*       L �    ActionProduceModelUnitOnTile*       N �    ActionProduceModelUnitOnUnit#       \ �    ActionSupplyModelUnit       ^ �    ActionSurface       ` �    ActionSurrender       d �    ActionVoteForDraw       f � 
   ActionWait�        "   ActionGetJoinableWarConfigurations�            
   actionCode            playerAccount            playerPassword            warID#       � 
      warConfigurations�        !   ActionGetOngoingWarConfigurations�            
   actionCode            playerAccount            playerPassword#       �       warConfigurations~           ActionGetPlayerProfileZ            
   actionCode            playerAccount       �     playerProfile           ActionGetRankingList]            
   actionCode            rankingListIndex       �      rankingList�           ActionGetReplayConfigurations]            
   actionCode            warID&       �       replayConfigurations�           ActionGetSkillConfiguration�            
   actionCode            playerAccount            playerPassword"            skillConfigurationID        � 
    skillConfiguration�        !   ActionGetWaitingWarConfigurations�            
   actionCode            playerAccount            playerPassword#       �       warConfigurationsq          ActionJoinModelUnitP           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID&          ActionJoinWar           
   actionCode            playerAccount            playerPassword            warID        
    playerIndex"            skillConfigurationID            warPassword            isWarStarted         	   teamIndex�          ActionLaunchFlareq           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID       �     targetGridIndex�          ActionLaunchSiloq           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID       �     targetGridIndexq          ActionLoadModelUnitP           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID�           ActionLoginx            
   actionCode            clientVersion            loginAccount            loginPasswordt           ActionLogoutZ            
   actionCode            messageCode             messageParamsu           ActionMessageZ            
   actionCode            messageCode             messageParams�           ActionNetworkHeartbeat}            
   actionCode            heartbeatCounter            playerAccount            playerPassword�          ActionNewWar�           
   actionCode            playerAccount            playerPassword            warID        
    warPassword            warFieldFileName            playerIndex"            skillConfigurationID             maxBaseSkillPoints!            isFogOfWarByDefault             defaultWeatherCode            isRankMatch            maxDiffScore            intervalUntilBoot            incomeModifier             startingFund         "    energyGainModifier        $    moveRangeModifier        &    attackModifier        (    visionModifier        * 	   teamIndexF          ActionProduceModelUnitOnTile           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles            tiledID       �  	   gridIndex            cost�          ActionProduceModelUnitOnUnitf           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID            cost[           ActionRedisB            
   actionCode"            encodedActionGeneric�           ActionRegister~            
   actionCode            clientVersion            registerAccount            registerPassword�           ActionReloadSceneWar�            
   actionCode            playerAccount            playerPassword            warID       � 
    warDataz           ActionRunSceneMainZ            
   actionCode            messageCode             messageParams�           ActionRunSceneWar�            
   actionCode            playerAccount            playerPassword            warID       � 
    warData�           ActionSetSkillConfiguration�            
   actionCode            playerAccount            playerPassword"            skillConfigurationID        � 
    skillConfigurations          ActionSupplyModelUnitP           
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
   AttackDoer          j     primaryWeaponN        #   AttackDoer.PrimaryWeaponCurrentAmmo               currentAmmo4           AttackTaker            	   currentHP:        	   Buildable#               currentBuildPoint=        
   Capturable%   !            currentCapturePoint3           Capturer               isCapturing5           ChatChannel          v      messages^           ChatChannel.ChatMessage9               text            senderPlayerIndex-           Diver               isDivingP           DropDestination3               unitID       �  	   gridIndex8           FlareLauncher               currentAmmo0        	   FuelOwner               current=        	   GridIndex&               x            yA           GridIndexable&               x            y7           JoinableWarList          �       list4           MaterialOwner               currento           MovePathY          �   	   pathNodes            fuelConsumption         	   isBlocked?           OngoingWarListForServer          �       list�        
   PlayerInfok               playerIndex            account            nickname         	   teamIndex�           PlayerProfile�               account            password            nickname       �      gameRecords#       � 
     skillConfigurations       �     warLists!            totalOnlineDuration�           PlayerProfile.SingleGameRecord\            	   rankScore            win            lose            drawx           PlayerProfile.WarListsT          �       ongoing       �       waiting             recent�           PlayerProfileForClient�               account            nickname       �      gameRecords       �     warLists!        
    totalOnlineDurationd           PlayerProfileForClient.WarLists7          �       waiting             recent1        
   Promotable               current1           RankingList          �      listT           RankingListItem7            	   rankScore             accounts<           RankingListsForServer          �      listsu           ReplayConfigurationT               warID            warFieldFileName       �      players;           ReplayListForClient          �       list]           ReplayListForServer<          �       fullList          
   recentList3          SceneWar              warID            actionID             maxBaseSkillPoints         
   isWarEnded        
    isRandomWarField!            isFogOfWarByDefault            isTotalReplay            warPassword       (      executedActions       �       players       �     turn       �     warField       �     weather#            remainingVotesForDraw            isRankMatch             maxDiffScore        "    createdTime        $    intervalUntilBoot        &    enterTurnTime        (    incomeModifier        *    startingFund       � ,    chatData         .    energyGainModifier        0    moveRangeModifier        2    attackModifier        4    visionModifiera           SceneWar.ChatDataB          t     publicChannel       t      privateChannels�           SceneWar.FogMapData�               forcingFogCode.             expiringPlayerIndexForForcingFog,            expiringTurnIndexForForcingFog       �       mapsForPathso           SceneWar.SingleFogMapForPathsD               playerIndex#            encodedFogMapForPathsG          SceneWar.SinglePlayerData               playerIndex            account            nickname            fund        
    isAlive         
   damageCost!            skillActivatedCount        �     skillConfiguration            hasVotedForDraw         	   teamIndex=           SceneWar.TileMapData          �       tilesv           SceneWar.TurnDataW            	   turnIndex            playerIndex            turnPhaseCode�           SceneWar.UnitMapDatab               availableUnitID       �    
   unitsOnMap       �       unitsLoaded�           SceneWar.WarFieldDatal               warFieldFileName       �     fogMap       �     tileMap       �     unitMap�           SceneWar.WeatherData�                currentWeatherCode             defaultWeatherCode+            expiringPlayerIndexForWeather)            expiringTurnIndexForWeather�            SingleGameRecordForPlayerProfile\            	   rankScore            win            lose            draw�           SingleSkillConfiguration�            
   basePoints$            activatingSkillGroupID       �      passive       �     active1       � 
    active2t        )   SingleSkillConfiguration.ActiveSkillGroup=               energyRequirement       �      skills]        $   SingleSkillConfiguration.SingleSkill+               id            level>           TileBuilder%   !            isBuildingModelTile�           TileData�               positionIndex            baseID            objectID       l     AttackTaker       n 
 	   Buildable       p  
   Capturable       �     GridIndexable�          UnitData�              unitID            tiledID         	   stateCode            isLoaded       h 
 
   AttackDoer       l     AttackTaker       r     Capturer       x     Diver       |     FlareLauncher       ~  	   FuelOwner       �     GridIndexable       �     MaterialOwner       �  
   Promotable       �     TileBuilder       �  
   UnitLoader2        
   UnitLoader                loaded�          WarConfiguration�              warID            warFieldFileName            warPassword             maxBaseSkillPoints!        
    isFogOfWarByDefault             defaultWeatherCode            isRandomWarField       �       players            isRankMatch            maxDiffScore            createdTime            intervalUntilBoot            enterTurnTime            playerIndexInTurn            incomeModifier             startingFund         "    energyGainModifier        $    moveRangeModifier        &    attackModifier        (    visionModifier5           WarIdForIndexing               warID
   �I  S           AccountAndPassword3               account            password`          ActionActivateSkillGroup:           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData            skillGroupID�          ActionAttack�           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID       x     targetGridIndex            attackDamage            counterDamage            lostPlayerIndex          ActionBeginTurn�            
   actionCode            playerAccount            playerPassword            warID        
    actionID            income            lostPlayerIndex       
  
   repairData         
   supplyData�           ActionBeginTurn.RepairData^               remainingFund           	   onMapData           
   loadedDatao        +   ActionBeginTurn.RepairData.RepairDataLoaded6               unitID            repairAmount�        *   ActionBeginTurn.RepairData.RepairDataOnMapQ               unitID            repairAmount       x  	   gridIndexg           ActionBeginTurn.SupplyData?              	   onMapData           
   loadedDataQ        +   ActionBeginTurn.SupplyData.SupplyDataLoaded               unitIDk        *   ActionBeginTurn.SupplyData.SupplyDataOnMap3               unitID       x  	   gridIndexr          ActionBuildModelTileP           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID�          ActionCaptureModelTileq           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID            lostPlayerIndex`          ActionDestroyOwnedModelUnit7           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       x  	   gridIndexh       
   ActionDiveP           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID|           ActionDownloadReplayDataV            
   actionCode            warID            encodedReplayData�          ActionDropModelUnit�           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID        r      dropDestinations            isDropBlocked�           ActionEndTurn�            
   actionCode            playerAccount            playerPassword            warID        
    actionID�          ActionGeneric�  &            ActionDownloadReplayData0       &  "   ActionGetJoinableWarConfigurations%       (     ActionGetOngoingWarList$       , 
    ActionGetPlayerProfile"       .     ActionGetRankingList+       0     ActionGetReplayConfigurations)       2     ActionGetSkillConfiguration       6     ActionJoinWar       >     ActionLogin       @     ActionLogout       B     ActionMessage$       D     ActionNetworkHeartbeat       F     ActionNewWar       N     ActionRegister"       P      ActionReloadSceneWar        R "    ActionRunSceneMain       T $    ActionRunSceneWar)       V &    ActionSetSkillConfiguration        ^ (    ActionSyncSceneWar&        �    ActionActivateSkillGroup        �    ActionAttack        �    ActionBeginTurn"        �    ActionBuildModelTile$        �    ActionCaptureModelTile)        �    ActionDestroyOwnedModelUnit        � 
   ActionDive!         �    ActionDropModelUnit       " �    ActionEndTurn!       4 �    ActionJoinModelUnit       8 �    ActionLaunchFlare       : �    ActionLaunchSilo!       < �    ActionLoadModelUnit*       H �    ActionProduceModelUnitOnTile*       J �    ActionProduceModelUnitOnUnit#       X �    ActionSupplyModelUnit       Z �    ActionSurface       \ �    ActionSurrender       ` �    ActionVoteForDraw       b � 
   ActionWait�        "   ActionGetJoinableWarConfigurations�            
   actionCode            playerAccount            playerPassword            warID#       � 
      warConfigurations�           ActionGetOngoingWarList}            
   actionCode            playerAccount            playerPassword       *      ongoingWarListt        *   ActionGetOngoingWarList.OngoingWarListItem<          �     warConfiguration            isInTurn~           ActionGetPlayerProfileZ            
   actionCode            playerAccount       �     playerProfile           ActionGetRankingList]            
   actionCode            rankingListIndex       �      rankingList�           ActionGetReplayConfigurations_            
   actionCode         	   pageIndex$       �      replayConfigurations�           ActionGetSkillConfiguration�            
   actionCode            playerAccount            playerPassword"            skillConfigurationID        � 
    skillConfigurationq          ActionJoinModelUnitP           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID          ActionJoinWar�            
   actionCode            playerAccount            playerPassword            warID        
    playerIndex"            skillConfigurationID            warPassword            isWarStarted�          ActionLaunchFlareq           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID       x     targetGridIndex�          ActionLaunchSiloq           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID       x     targetGridIndexq          ActionLoadModelUnitP           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData       �     path            launchUnitID�           ActionLoginx            
   actionCode            clientVersion            loginAccount            loginPasswordt           ActionLogoutZ            
   actionCode            messageCode             messageParamsu           ActionMessageZ            
   actionCode            messageCode             messageParamsb           ActionNetworkHeartbeat>            
   actionCode            heartbeatCounter�          ActionNewWar�           
   actionCode            playerAccount            playerPassword            warID        
    warPassword            warFieldFileName            playerIndex"            skillConfigurationID             maxBaseSkillPoints!            isFogOfWarByDefault             defaultWeatherCode            isRankMatch            maxDiffScore            intervalUntilBootF          ActionProduceModelUnitOnTile           
   actionCode            playerAccount            playerPassword            warID        
    actionID       �       revealedUnits       �       revealedTiles            tiledID       x  	   gridIndex            cost�          ActionProduceModelUnitOnUnitf           
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
   AttackDoer          f     primaryWeaponN        #   AttackDoer.PrimaryWeaponCurrentAmmo               currentAmmo4           AttackTaker            	   currentHP:        	   Buildable#               currentBuildPoint=        
   Capturable%   !            currentCapturePoint3           Capturer               isCapturing-           Diver               isDivingP           DropDestination3               unitID       x  	   gridIndex8           FlareLauncher               currentAmmo0        	   FuelOwner               current=        	   GridIndex&               x            yA           GridIndexable&               x            y7           JoinableWarList          �       list4           MaterialOwner               currento           MovePathY          x   	   pathNodes            fuelConsumption         	   isBlocked?           OngoingWarListForServer          �       listh        
   PlayerInfoP               playerIndex            account            nickname�           PlayerProfile�               account            password            nickname       �      gameRecords#       � 
     skillConfigurations       �     warLists�           PlayerProfile.SingleGameRecord\            	   rankScore            win            lose            draw^           PlayerProfile.WarLists:          �       ongoing       �       waiting�           PlayerProfileForClientl               account            nickname       �      gameRecords       �     warListsJ           PlayerProfileForClient.WarLists          �       waiting1        
   Promotable               current1           RankingList          �      listT           RankingListItem7            	   rankScore             accounts<           RankingListsForServer          �      listsu           ReplayConfigurationT               warID            warFieldFileName       �      players;           ReplayListForClient          �       list;           ReplayListForServer          �       listT          SceneWar>              warID            actionID             maxBaseSkillPoints         
   isWarEnded        
    isRandomWarField!            isFogOfWarByDefault            isTotalReplay            warPassword       $      executedActions       �       players       �     turn       �     warField       �     weather#            remainingVotesForDraw            isRankMatch             maxDiffScore        "    createdTime        $    intervalUntilBoot        &    enterTurnTime�           SceneWar.FogMapData�               forcingFogCode.             expiringPlayerIndexForForcingFog,            expiringTurnIndexForForcingFog       �       mapsForPathso           SceneWar.SingleFogMapForPathsD               playerIndex#            encodedFogMapForPaths,          SceneWar.SinglePlayerData              playerIndex            account            nickname            fund        
    isAlive         
   damageCost!            skillActivatedCount        �     skillConfiguration            hasVotedForDraw=           SceneWar.TileMapData          �       tilesv           SceneWar.TurnDataW            	   turnIndex            playerIndex            turnPhaseCode�           SceneWar.UnitMapDatab               availableUnitID       �    
   unitsOnMap       �       unitsLoaded�           SceneWar.WarFieldDatal               warFieldFileName       �     fogMap       �     tileMap       �     unitMap�           SceneWar.WeatherData�                currentWeatherCode             defaultWeatherCode+            expiringPlayerIndexForWeather)            expiringTurnIndexForWeather�            SingleGameRecordForPlayerProfile\            	   rankScore            win            lose            draw�           SingleSkillConfiguration�            
   basePoints$            activatingSkillGroupID       �      passive       �     active1       � 
    active2t        )   SingleSkillConfiguration.ActiveSkillGroup=               energyRequirement       �      skills]        $   SingleSkillConfiguration.SingleSkill+               id            level>           TileBuilder%   !            isBuildingModelTile�           TileData�               positionIndex            baseID            objectID       h     AttackTaker       j 
 	   Buildable       l  
   Capturable       z     GridIndexable�          UnitData�              unitID            tiledID         	   stateCode            isLoaded       d 
 
   AttackDoer       h     AttackTaker       n     Capturer       p     Diver       t     FlareLauncher       v  	   FuelOwner       z     GridIndexable       ~     MaterialOwner       �  
   Promotable       �     TileBuilder       �  
   UnitLoader2        
   UnitLoader                loaded�          WarConfiguration}              warID            warFieldFileName            warPassword             maxBaseSkillPoints!        
    isFogOfWarByDefault             defaultWeatherCode            isRandomWarField       �       players            isRankMatch            maxDiffScore            createdTime            intervalUntilBoot5           WarIdForIndexing               warID
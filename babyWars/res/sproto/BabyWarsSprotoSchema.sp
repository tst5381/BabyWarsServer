   �(  S           AccountAndPassword3               account            password	          ActionBeginTurn�            
   actionCode            playerAccount            playerPassword            sceneWarFileName        
    actionID            income            lostPlayerIndex         
   repairData�           ActionBeginTurn.RepairData^               remainingFund       
    	   onMapData           
   loadedDatao        +   ActionBeginTurn.RepairData.RepairDataLoaded6               unitID            repairAmount�        *   ActionBeginTurn.RepairData.RepairDataOnMapQ               unitID            repairAmount       J  	   gridIndex�           ActionEndTurn�            
   actionCode            playerAccount            playerPassword            sceneWarFileName        
    actionID�          ActionGeneric�  0         "   ActionGetJoinableWarConfigurations%            ActionGetOngoingWarList+            ActionGetReplayConfigurations)        
    ActionGetSkillConfiguration            ActionJoinWar            ActionLogin            ActionLogout             ActionMessage$       "     ActionNetworkHeartbeat       $     ActionNewWar       (     ActionRegister"       *     ActionReloadSceneWar        ,     ActionRunSceneMain       .     ActionRunSceneWar)       0      ActionSetSkillConfiguration        4 "    ActionSyncSceneWar        $    ActionBeginTurn        &    ActionEndTurn       2 (    ActionSurrender       6 * 
   ActionWait�        "   ActionGetJoinableWarConfigurations�            
   actionCode            playerAccount            playerPassword            sceneWarShortName#       � 
      warConfigurations�           ActionGetOngoingWarList}            
   actionCode            playerAccount            playerPassword             ongoingWarListt        *   ActionGetOngoingWarList.OngoingWarListItem<          �     warConfiguration            isInTurn�           ActionGetReplayConfigurations_            
   actionCode         	   pageIndex$       `      replayConfigurations�           ActionGetSkillConfiguration�            
   actionCode            playerAccount            playerPassword"            skillConfigurationID        x 
    skillConfiguration          ActionJoinWar�            
   actionCode            playerAccount            playerPassword            sceneWarFileName        
    playerIndex"            skillConfigurationID            warPassword            isWarStarted�           ActionLoginx            
   actionCode            clientVersion            loginAccount            loginPasswordt           ActionLogoutZ            
   actionCode            messageCode             messageParamsu           ActionMessageZ            
   actionCode            messageCode             messageParamsb           ActionNetworkHeartbeat>            
   actionCode            heartbeatCounter�          ActionNewWarl           
   actionCode            playerAccount            playerPassword            sceneWarFileName        
    warPassword            warFieldFileName            playerIndex"            skillConfigurationID             maxBaseSkillPoints!            isFogOfWarByDefault             defaultWeatherCode[           ActionRedisB            
   actionCode"            encodedActionGeneric�           ActionRegister~            
   actionCode            clientVersion            registerAccount            registerPassword�           ActionReloadSceneWar�            
   actionCode            playerAccount            playerPassword            sceneWarFileName       d 
    warDataz           ActionRunSceneMainZ            
   actionCode            messageCode             messageParams�           ActionRunSceneWar�            
   actionCode            playerAccount            playerPassword            sceneWarFileName       d 
    warData�           ActionSetSkillConfiguration�            
   actionCode            playerAccount            playerPassword"            skillConfigurationID        x 
    skillConfiguration�           ActionSurrender�            
   actionCode            playerAccount            playerPassword            sceneWarFileName        
    actionID�           ActionSyncSceneWar�            
   actionCode            playerAccount            playerPassword            sceneWarFileName        
    actionIDs       
   ActionWait[           
   actionCode            playerAccount            playerPassword            sceneWarFileName        
    actionID       R     path            launchUnitID       �       revealedUnits       �       revealedTiles!       �       actingUnitsData!       �       actingTilesData7        
   AttackDoer          :     primaryWeaponN        #   AttackDoer.PrimaryWeaponCurrentAmmo               currentAmmo4           AttackTaker            	   currentHP:        	   Buildable#               currentBuildPoint=        
   Capturable%   !            currentCapturePoint3           Capturer               isCapturing-           Diver               isDiving8           FlareLauncher               currentAmmo0        	   FuelOwner               current=        	   GridIndex&               x            yA           GridIndexable&               x            y7           JoinableWarList          v       list4           MaterialOwner               currento           MovePathY          J   	   pathNodes            fuelConsumption         	   isBlocked?           OngoingWarListForServer          v       listh        
   PlayerInfoP               playerIndex            account            nickname�           PlayerProfile�               account            password            nickname       Z      gameRecords#       x 
     skillConfigurations       \     warLists�           PlayerProfile.SingleGameRecord\            	   rankScore            win            lose            draw^           PlayerProfile.WarLists:          v       ongoing       v       created1        
   Promotable               current�           ReplayConfiguration_               sceneWarFileName            warFieldFileName       V      players;           ReplayListForServer          v       list�          SceneWar�              sceneWarFileName            actionID             maxBaseSkillPoints         
   isWarEnded        
    isRandomWarField!            isFogOfWarByDefault            isTotalReplay            warPassword             executedActions       j       players       n     turn       r     warField       t     weather�           SceneWar.FogMapData�               forcingFogCode.             expiringPlayerIndexForForcingFog,            expiringTurnIndexForForcingFog       h       mapsForPathso           SceneWar.SingleFogMapForPathsD               playerIndex#            encodedFogMapForPaths          SceneWar.SinglePlayerData�               playerIndex            account            nickname            fund        
    isAlive         
   damageCost!            skillActivatedCount        x     skillConfiguration=           SceneWar.TileMapData          �       tilesv           SceneWar.TurnDataW            	   turnIndex            playerIndex            turnPhaseCode�           SceneWar.UnitMapDatab               availableUnitID       �    
   unitsOnMap       �       unitsLoaded�           SceneWar.WarFieldDatal               warFieldFileName       f     fogMap       l     tileMap       p     unitMap�           SceneWar.WeatherData�                currentWeatherCode             defaultWeatherCode+            expiringPlayerIndexForWeather)            expiringTurnIndexForWeatherH           SceneWarFileNameForIndex"               sceneWarFileName�           SingleSkillConfiguration�            
   basePoints$            activatingSkillGroupID       |      passive       z     active1       z 
    active2t        )   SingleSkillConfiguration.ActiveSkillGroup=               energyRequirement       |      skills]        $   SingleSkillConfiguration.SingleSkill+               id            level>           TileBuilder%   !            isBuildingModelTile�           TileData�               positionIndex            baseID            objectID       <     AttackTaker       > 
 	   Buildable       @  
   Capturable       L     GridIndexable�          UnitData�              unitID            tiledID         	   stateCode            isLoaded       8 
 
   AttackDoer       <     AttackTaker       B     Capturer       D     Diver       F     FlareLauncher       H  	   FuelOwner       L     GridIndexable       P     MaterialOwner       ^  
   Promotable       ~     TileBuilder       �  
   UnitLoader2        
   UnitLoader                loaded+          WarConfiguration              sceneWarFileName            warFieldFileName            warPassword             maxBaseSkillPoints!        
    isFogOfWarByDefault             defaultWeatherCode            isRandomWarField       V       players
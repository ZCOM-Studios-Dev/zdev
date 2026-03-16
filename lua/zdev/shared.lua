local _f = 'zdev/shared.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
--if ZDEV.FILE.Loaded( _f ) then return end

local function FormatFolder( folder )
	local result = string.upper( folder )
	result = string.Left( result , 3)
	return result
end
--[[ ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  ZDEV CORE: FILE
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ ]]

-- ZDEV_UID: ZDEV_FUNC_CB2F5AEB | Path: ZDEV.FILE.InitDataDirectory
function ZDEV.FILE.InitDataDirectory( )
  zdev.log( "D", " Initializing data-folder hierarchy structure..." )

  local dir_root, dir_weap = ZDEV.DATA.RootDir, ZDEV.FILE.DIR.Weapons
  -- ■■ CREATE ROOT DIR and subfolders

  local b_exists = tobool( file.IsDir( dir_root, "DATA") )
  if not b_exists then
    file.CreateDir( dir_root )
    zdev.log( "D", " Created Root Data Directory: " .. dir_root )

    b_exists = tobool( file.IsDir( dir_weap, "DATA" ) )
    if not b_exists then
      file.CreateDir( dir_weap )
      zdev.log( "D", " \t Created sub-directory: " .. dir_weap )
    end
  end

end

-- ZDEV_UID: ZDEV_FUNC_EADB8134 | Path: ZDEV.FILE.InitDataFiles
function ZDEV.FILE.InitDataFiles( )
  zdev.log( "I", " Initializing core-data file(s)..." )

  local dir_root, dir_weap = ZDEV.DATA.RootDir, ZDEV.FILE.DIR.Weapons
  local file_cnfg, file_users = ZDEV.FILE.DataConfig, ZDEV.FILE.DIR.Players

  -- ■■ CREATE ROOT DIR and subfolders

  local b_exists = tobool( file.Exists( dir_root .. "/" .. file_cnfg, "DATA") )

  if not b_exists then
    file.Write( dir_root .. "/" .. file_cnfg, ZDEV.CNFG )
    zdev.log( "I", " Created Core-Data File: " .. file_cnfg )
  end

  b_exists = tobool( file.Exists( dir_root .. "/" .. file_users, "DATA") )
  if not b_exists then
    file.Write( dir_root .. "/" .. file_users, ZDEV.PLYR )
    zdev.log( "I", " \t Created Core-Data File: " .. file_users )
  end

end


--[[ ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  ZDEV CORE: FILE
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ ]]
-- ZDEV_UID: ZDEV_FUNC_AF202117 | Path: ZDEV.CONT.LoadMaterials
function ZDEV.CONT.LoadMaterials( subdir )
	local roottbl = FormatFolder( subdir )
	ZDEV.CONT.MATS[ roottbl ] = {}
	local dir = "materials"
	local path = dir .. "/"..subdir
	local f, d = file.Find( path .. "--[[", "THIRDPARTY" )
	PrintTable( d )
	for k ,v in pairs( d ) do

		local tblid = FormatFolder( tostring(v) )
		ZDEV.CONT.MATS[ roottbl ][ tblid ] = {}

		local path2 = path .. "/" .. v
		local m, f = file.Find( path2 .. "--[[", "THIRDPARTY" )
		for l, p in pairs( m ) do
			local filepath = tostring(subdir.."/"..v.."/".. p)
			ZDEV.CONT.MATS[ roottbl ][ tblid ][l] = filepath
			print('')
			resource.AddFile( dir.."/"..filepath )

		end
	end
end

-- ZDEV_UID: ZDEV_FUNC_0DDF5DAB | Path: ZDEV.CONT.GetMaterials
function ZDEV.CONT.GetMaterials()
	return ZDEV.CONT.MATS
end




---------------------------------------------------------------------------
-- ZDEV Compressed Neural Input System
-- Reduces 61+ inputs to 6 highly compressed float values
---------------------------------------------------------------------------

ZDEV.CompressedInputs = {}

-- Configuration for input compression
local COMPRESSION_CONFIG = {
    CLOSE_COMBAT_RANGE = 300,
    MEDIUM_RANGE = 800,
    LONG_RANGE = 1500,
    RECENT_TIME_THRESHOLD = 5.0,
    STALE_TIME_THRESHOLD = 15.0,
    CRITICAL_HEALTH = 0.25,
    LOW_HEALTH = 0.5,
    MIN_LIGHT_LEVEL = 0.3,
    GOOD_LIGHT_LEVEL = 0.7
}

-- Compresses all sensory data into 6 critical values
function ZDEV.CompressedInputs.CompressSensoryData(sensorData)
    local compressed = {}
    
    -- Extract key sensor values with safe defaults
    local playerDist = sensorData.playerDist or 9999
    local hasLOS = sensorData.hasLOS or false
    local coverBetweenEnemy = sensorData.coverBetweenEnemy or false
    local myHealthFrac = sensorData.myHealthFrac or 1.0
    local weaponReady = sensorData.weaponReady or true
    local allySupport = sensorData.allySupport or 0
    local lightingLevel = sensorData.lightingLevel or 0.5
    local heightAdvantage = sensorData.heightAdvantage or 0
    local environmentalHazard = sensorData.environmentalHazard or 0
    local visibleEnemyCount = sensorData.visibleEnemyCount or 0
    local playerWeaponThreat = sensorData.playerWeaponThreat or 0.5
    local playerMovementThreat = sensorData.playerMovementThreat or 0.5
    local timeSinceEnemySeen = sensorData.timeSinceEnemySeen or 10.0
    local recentDamageThreat = sensorData.recentDamageThreat or 0
    local exposedFraction = sensorData.exposedFraction or 0.5
    local ammoStatusThreat = sensorData.ammoStatusThreat or 0
    
    -- COMPRESSED INPUT 1: TACTICAL SITUATION (0-1)
    local distanceComponent = 0
    if playerDist <= COMPRESSION_CONFIG.CLOSE_COMBAT_RANGE then
        distanceComponent = 1.0
    elseif playerDist <= COMPRESSION_CONFIG.MEDIUM_RANGE then
        distanceComponent = 0.6
    elseif playerDist <= COMPRESSION_CONFIG.LONG_RANGE then
        distanceComponent = 0.3
    else
        distanceComponent = 0.1
    end
    
    local losComponent = hasLOS and 0.4 or 0.0
    local coverComponent = coverBetweenEnemy and 0.0 or 0.2
    compressed[1] = math.Clamp(distanceComponent + losComponent + coverComponent, 0, 1)
    
    -- COMPRESSED INPUT 2: COMBAT READINESS (0-1)
    local healthComponent = myHealthFrac * 0.5
    local weaponComponent = weaponReady and 0.2 or 0.0
    local supportComponent = math.Clamp(allySupport * 0.3, 0, 0.3)
    compressed[2] = math.Clamp(healthComponent + weaponComponent + supportComponent, 0, 1)
    
    -- COMPRESSED INPUT 3: ENVIRONMENTAL AWARENESS (0-1)
    local lightComponent = 0
    if lightingLevel >= COMPRESSION_CONFIG.GOOD_LIGHT_LEVEL then
        lightComponent = 0.4
    elseif lightingLevel >= COMPRESSION_CONFIG.MIN_LIGHT_LEVEL then
        lightComponent = 0.2
    else
        lightComponent = 0.0
    end
    
    local heightComponent = math.Clamp((heightAdvantage + 1) * 0.25, 0, 0.3)
    local hazardComponent = math.Clamp((1.0 - environmentalHazard) * 0.3, 0, 0.3)
    compressed[3] = math.Clamp(lightComponent + heightComponent + hazardComponent, 0, 1)
    
    -- COMPRESSED INPUT 4: TARGET INTELLIGENCE (0-1)
    local enemyCountComponent = math.Clamp(math.log(visibleEnemyCount + 1) / 3, 0, 0.4)
    local weaponThreatComponent = playerWeaponThreat * 0.3
    local movementThreatComponent = playerMovementThreat * 0.3
    compressed[4] = math.Clamp(enemyCountComponent + weaponThreatComponent + movementThreatComponent, 0, 1)
    
    -- COMPRESSED INPUT 5: TEMPORAL CONTEXT (0-1)
    local timeComponent = 0
    if timeSinceEnemySeen <= COMPRESSION_CONFIG.RECENT_TIME_THRESHOLD then
        timeComponent = 0.5
    elseif timeSinceEnemySeen <= COMPRESSION_CONFIG.STALE_TIME_THRESHOLD then
        timeComponent = 0.2
    else
        timeComponent = 0.0
    end
    
    local damageComponent = recentDamageThreat * 0.3
    local ammoComponent = ammoStatusThreat * 0.2
    compressed[5] = math.Clamp(timeComponent + damageComponent + ammoComponent, 0, 1)
    
    -- COMPRESSED INPUT 6: STRATEGIC POSITION (0-1)
    local exposureComponent = (1.0 - exposedFraction) * 0.4
    local positioningComponent = 0.3
    
    if hasLOS and not coverBetweenEnemy then
        positioningComponent = 0.6
    elseif hasLOS and coverBetweenEnemy then
        positioningComponent = 0.4
    elseif coverBetweenEnemy then
        positioningComponent = 0.2
    end
    
    compressed[6] = math.Clamp(exposureComponent + positioningComponent * 0.6, 0, 1)
    
    return compressed
end

-- Helper function to create sensor data structure
function ZDEV.CompressedInputs.CreateSensorDataFromGatherInputs(playerDist, playerHealth, hasLOS, visibleEnemyCount, 
                                                               lightingLevel, coverBetweenEnemy, heightAdvantage, 
                                                               weaponReady, myHealthFrac, exposedFraction, 
                                                               timeSinceEnemySeen, playerWeaponThreat, 
                                                               playerMovementThreat, recentDamageThreat, 
                                                               ammoStatusThreat, environmentalHazard, allySupport)
    return {
        playerDist = playerDist,
        playerHealth = playerHealth,
        hasLOS = hasLOS,
        visibleEnemyCount = visibleEnemyCount,
        lightingLevel = lightingLevel,
        coverBetweenEnemy = coverBetweenEnemy,
        heightAdvantage = heightAdvantage,
        weaponReady = weaponReady,
        myHealthFrac = myHealthFrac,
        exposedFraction = exposedFraction,
        timeSinceEnemySeen = timeSinceEnemySeen,
        playerWeaponThreat = playerWeaponThreat,
        playerMovementThreat = playerMovementThreat,
        recentDamageThreat = recentDamageThreat,
        ammoStatusThreat = ammoStatusThreat,
        environmentalHazard = environmentalHazard,
        allySupport = allySupport
    }
end

-- Debug function to explain compressed inputs
function ZDEV.CompressedInputs.ExplainCompressedInputs(compressedInputs)
    local explanations = {
        "TACTICAL SITUATION: Distance urgency + LOS + Cover assessment",
        "COMBAT READINESS: Health + Weapon status + Ally support",
        "ENVIRONMENTAL AWARENESS: Lighting + Height + Hazard assessment", 
        "TARGET INTELLIGENCE: Enemy count + Weapon/Movement threats",
        "TEMPORAL CONTEXT: Time factors + Recent damage + Ammo status",
        "STRATEGIC POSITION: Exposure + Positioning advantages"
    }
    
    for i, explanation in ipairs(explanations) do
        MsgC(Color(0,255,255), string.format("[COMPRESSED INPUT %d] %.3f - %s\n", 
             i, compressedInputs[i] or 0, explanation))
    end
end

--zdev.IncludeFilesIn("zdev/shared/")




include( "shared/zd_sh_core.lua")
include( "shared/zd_sh_editor.lua")
include( "shared/zd_sh_effect.lua")
include( "shared/zd_sh_player.lua")
include( "shared/zd_sh_weapon.lua")
include( "shared/zd_sh_simple_nn.lua")
include( "shared/zd_sh_advanced_nn.lua")
include( "shared/meta/zd_sh_meta_ent.lua")
include( "shared/meta/zd_sh_meta_ply.lua")
include( "shared/meta/zd_sh_meta_wep.lua")
include( "shared/sh_items.lua")
include( "shared/sh_items_defs.lua")

ZDEV.FILE.SetLoaded( _f )

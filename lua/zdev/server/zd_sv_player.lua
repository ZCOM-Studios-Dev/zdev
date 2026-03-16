local _f = 'zdev/server/zd_sv_player.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end

ZDEV.FILE.SetLoaded( _f )



ZDEV.PLYR = ZDEV.PLYR or {}
ZDEV.PLYR.__INDEX = {}
ZDEV.DATA.Players = ZDEV.DATA.Players or {}

local t_Players = {}

local PLAYERS = {}

-- ZDEV_UID: ZDEV_FUNC_A4F336B0 | Path: ZDEV.PLYR.SearchByIP
function ZDEV.PLYR.SearchByIP( ip )

	for k, v in pairs( ZDEV.DATA.Players ) do
		if v.ip == ip then
			return k, v
		end
	end

	return false;

end  

-- ZDEV_UID: ZDEV_FUNC_07B428D9 | Path: ZDEV.PLYR.DataFileExists
function ZDEV.PLYR.DataFileExists( ply )
	local uid = ply:UniqueID()
	local s_file = "zdev/plyr/" .. tostring(uid) .. ".txt"
	return tobool( file.Exists( s_file, "DATA" ) )  
end

-- ZDEV_UID: ZDEV_FUNC_836CE245 | Path: ZDEV.PLYR.QueryAllPlayers
function ZDEV.PLYR.QueryAllPlayers()

	zdev.log( "Q", "Querying All Players from DataBase" )
	--include("zdev/server/database.lua") -- check database.lua for an example of how to create database instances

	local query = MYSQL_DB:query("SELECT * FROM players") -- In mysqloo 9 a query can be started before the database is connected
	function query:onSuccess(data)
		local row = data[1]
		for k,v in pairs(row) do
			zdev.log( "Q", tostring(k) .. " = " .. tostring(v) )
		end
	end

	function query:onError(err)
		zdev.log("E","An error occured while executing the query: " .. err)
	end

	query:start()

end

-- HOOKS =============================================
-- ZDEV_UID: ZDEV_FUNC_F7940C74 | Path: ZDEV.PLYR.Authed
function ZDEV.PLYR.Authed( ply, sid, uid )


	local ip = ply:IPAddress()

	if PLAYERS[ ip ] then
		zdev.log( "W", "Found player IP Address in local table " .. ip )
	end

	ply.ZData = {ip = ip}

	ply:InitZData( )
	
	local b_file = ply:ZDataExists( )

	if b_file then
		ply:LoadZData( )
	end
	
end

hook.Add( "PlayerAuthed", "ZDEV.PLYR.Authed", ZDEV.PLYR.Authed )

-- ZDEV_UID: ZDEV_FUNC_B0A60EB2 | Path: ZDEV.PLYR.Connected
function ZDEV.PLYR.Connected( name, ip )
	
	MsgC( Color(255,150,0), "=========================================================================\n")
	zdev.log( "S", "Player connected to server: " .. tostring( name ) .. " (" .. tostring( ip ) )
 
	PLAYERS[ ip ] = { name = name, ip = ip }
	PrintTable( PLAYERS)

	if not t_Players[ ip ] then
		t_Players[ ip ] = { nick = name }
	end

end
hook.Add( "PlayerConnected", "ZDEV.PLYR.Connected", ZDEV.PLYR.Connected )

local s_msg_greet = "Welcome to ZCOM's Development Server"
-- ZDEV_UID: ZDEV_FUNC_66AC69A0 | Path: ZDEV.PLYR.InitialSpawn
function ZDEV.PLYR.InitialSpawn( ply )
	--ply:zdev_LoadDataFile( )
	ply:PrintMessage( HUD_PRINTCENTER, s_msg_greet )

	ply:SetNWInt( 'ZDEV_Exp', 0)
	ply:SetNWInt( 'ZDEV_Lvl', 1)
	ply:SetNWInt( 'ZDEV_Rank', 1)
	ply:SetNWInt( 'ZDEV_Gold', 100)

	ply:SetNWFloat( 'ZDEV_Hunger', 0)
	ply:SetNWFloat( 'ZDEV_Thirst', 0)
	ply:SetNWFloat( 'ZDEV_Energy', 1)
	ply:SetNWFloat( 'ZDEV_Stamina', 1)

	ply:SetNWInt( 'ZDEV_WeightCapacity', 30)
	ply:SetNWInt( 'ZDEV_Weight', 5)

	ply:SetNWInt( 'ZDEV_STAT_Strength', 1)
	ply:SetNWInt( 'ZDEV_STAT_Endurance', 1)
	ply:SetNWInt( 'ZDEV_STAT_Intellect', 1)
	ply:SetNWInt( 'ZDEV_STAT_Dexterity', 1)
	ply:SetNWInt( 'ZDEV_STAT_Agility', 1)
	ply:SetNWInt( 'ZDEV_STAT_Willpower', 1)
	ply:SetNWInt( 'ZDEV_STAT_Luck', 1)
		
	ply:SetNWString( 'ZDEV_EQUIP_Melee', "")
	ply:SetNWString( 'ZDEV_EQUIP_Primary', "")
	ply:SetNWString( 'ZDEV_EQUIP_Sidearm', "")
	ply:SetNWString( 'ZDEV_EQUIP_Gadget', "")
	ply:SetNWString( 'ZDEV_EQUIP_Throwable', "")
	ply:SetNWString( 'ZDEV_EQUIP_Head', "")
	ply:SetNWString( 'ZDEV_EQUIP_Chest', "")
	ply:SetNWString( 'ZDEV_EQUIP_Shoulders', "")
	ply:SetNWString( 'ZDEV_EQUIP_Hands', "")
	ply:SetNWString( 'ZDEV_EQUIP_Wasit', "")
	ply:SetNWString( 'ZDEV_EQUIP_Legs', "")
	ply:SetNWString( 'ZDEV_EQUIP_Feet', "")

	ply:SetNWBool( 'ZDEV_STATE_Poisoned', false)
	ply:SetNWBool( 'ZDEV_STATE_Injured', false)
	ply:SetNWBool( 'ZDEV_STATE_Bleeding', false)
	ply:SetNWBool( 'ZDEV_STATE_Crippled', false)
	ply:SetNWBool( 'ZDEV_STATE_Encumbered', false)
	ply:SetNWBool( 'ZDEV_STATE_Lethargic', false)
	ply:SetNWBool( 'ZDEV_STATE_Dillusional', false)
	ply:SetNWBool( 'ZDEV_STATE_Hypothermic', false)
	ply:SetNWBool( 'ZDEV_STATE_Infected', false)
	ply:SetNWBool( 'ZDEV_STATE_Drunk', false)

	timer.Create( "ZDEV_SaveTimer_" .. tostring(ply:UniqueID()) .. "_SV", 120, 0, function()
	
		local t_SaveData = {
			zdev_exp = ply:GetNWInt( 'ZDEV_Exp' ), 
			zdev_lvl = ply:GetNWInt( 'ZDEV_Lvl' ), 
			zdev_rank = ply:GetNWInt( 'ZDEV_Rank' ), 
			zdev_gold = ply:GetNWInt( 'ZDEV_Gold' ), 

			zdev_hunger = ply:GetNWFloat( 'ZDEV_Hunger' ), 
			zdev_thirst = ply:GetNWFloat( 'ZDEV_Thirst' ), 
			zdev_energy = ply:GetNWFloat( 'ZDEV_Energy' ), 
			zdev_weightcapacity = ply:GetNWInt( 'ZDEV_WeightCapacity' ), 
			zdev_weight = ply:GetNWInt( 'ZDEV_Weight' ), 

			zdev_stat_strength = ply:GetNWInt( 'ZDEV_STAT_Strength' ), 
			zdev_stat_endurance = ply:GetNWInt( 'ZDEV_STAT_Endurance' ), 
			zdev_stat_intellect = ply:GetNWInt( 'ZDEV_STAT_Intellect' ), 
			zdev_stat_dexterity = ply:GetNWInt( 'ZDEV_STAT_Dexterity' ), 
			zdev_stat_agility = ply:GetNWInt( 'ZDEV_STAT_Agility' ), 
			zdev_stat_willpower = ply:GetNWInt( 'ZDEV_STAT_Willpower' ), 
			zdev_stat_luck = ply:GetNWInt( 'ZDEV_STAT_Luck' ), 

			zdev_equip_melee = ply:GetNWString( 'ZDEV_EQUIP_Melee' ), 
			zdev_equip_primary = ply:GetNWString( 'ZDEV_EQUIP_Primary' ), 
			zdev_equip_sidearm = ply:GetNWString( 'ZDEV_EQUIP_Sidearm' ), 
			zdev_equip_gadget = ply:GetNWString( 'ZDEV_EQUIP_Gadget' ), 
			zdev_equip_throwable = ply:GetNWString( 'ZDEV_EQUIP_Throwable' ), 
			zdev_equip_head = ply:GetNWString( 'ZDEV_EQUIP_Head' ), 
			zdev_equip_chest = ply:GetNWString( 'ZDEV_EQUIP_Chest' ), 
			zdev_equip_shoulders = ply:GetNWString( 'ZDEV_EQUIP_Shoulders' ), 
			zdev_equip_hands = ply:GetNWString( 'ZDEV_EQUIP_Hands' ), 
			zdev_equip_wasit = ply:GetNWString( 'ZDEV_EQUIP_Wasit' ), 
			zdev_equip_legs = ply:GetNWString( 'ZDEV_EQUIP_Legs' ), 
			zdev_equip_feet = ply:GetNWString( 'ZDEV_EQUIP_Feet' ), 

			zdev_state_poisoned = ply:GetNWBool( 'ZDEV_STATE_Poisoned' ), 
			zdev_state_injured = ply:GetNWBool( 'ZDEV_STATE_Injured' ), 
			zdev_state_bleeding = ply:GetNWBool( 'ZDEV_STATE_Bleeding' ), 
			zdev_state_crippled = ply:GetNWBool( 'ZDEV_STATE_Crippled' ), 
			zdev_state_encumbered = ply:GetNWBool( 'ZDEV_STATE_Encumbered' ), 
			zdev_state_lethargic = ply:GetNWBool( 'ZDEV_STATE_Lethargic' ), 
			zdev_state_dillusional = ply:GetNWBool( 'ZDEV_STATE_Dillusional' ), 
			zdev_state_hypothermic = ply:GetNWBool( 'ZDEV_STATE_Hypothermic' ), 
			zdev_state_infected = ply:GetNWBool( 'ZDEV_STATE_Infected' ), 
			zdev_state_drunk = ply:GetNWBool( 'ZDEV_STATE_Drunk' ) 
		}

		local s_SaveData = util.TableToJSON( t_SaveData, true )

		file.Write( "zdev/plyr/" .. tostring(ply:UniqueID())..".txt", s_SaveData )
	

	end)

end
hook.Add( "PlayerInitialSpawn", "ZDEV.PLYR.InitialSpawn", ZDEV.PLYR.InitialSpawn )

local s_msg_spawn = "You have respawned."
-- ZDEV_UID: ZDEV_FUNC_B6185974 | Path: ZDEV.PLYR.Spawn
function ZDEV.PLYR.Spawn( ply )

	ply:SetNWFloat( "ZDEV_STAT_Stamina", 1 )

	ply:PrintMessage( HUD_PRINTCENTER, s_msg_spawn )

	zdev.log( "D" , "Player Spawned " .. tostring( ply ) )

end
hook.Add( "PlayerSpawn", "ZDEV.PLYR.Spawn", ZDEV.PLYR.Spawn )

-- ZDEV_UID: ZDEV_FUNC_3B1B0DA2 | Path: ZDEV.PLYR.Disconnected
function ZDEV.PLYR.Disconnected( ply )
	zdev.log( "W", "Player " .. tostring( self ) .. " disconnected.")
	ply:SaveZData( )
end
hook.Add( "PlayerDisconnected", "ZDEV.PLYR.Disconnected", ZDEV.PLYR.Disconnected )


-- ZDEV_UID: ZDEV_FUNC_BDED8D1F | Path: ZDEV.PLYR.DoDeath
function ZDEV.PLYR.DoDeath( ply, atk, dmg )
end
hook.Add( "DoPlayerDeath", "ZDEV.PLYR.DoDeath", ZDEV.PLYR.DoDeath )

-- ZDEV_UID: ZDEV_FUNC_2419EB5F | Path: ZDEV.PLYR.Death
function ZDEV.PLYR.Death( ply, atk, dmg )

	if not ply:IsBot() then 
		local deaths = ply:GetZData( "deaths" ) or 0
		ply:SetZData( "deaths", deaths + 1 )
	end

	if atk:IsPlayer() and IsValid( atk ) then
		atk:SetZData( "kills", kills + 1 )
	end

end
hook.Add( "PlayerDeath", "ZDEV.PLYR.Death", ZDEV.PLYR.Death )

-- ZDEV_UID: ZDEV_FUNC_1F4C50DF | Path: ZDEV.PLYR.TakeDamage
function ZDEV.PLYR.TakeDamage( ply, dmg )
end
hook.Add( "EntityTakeDamage", "ZDEV.PLYR.TakeDamage", ZDEV.PLYR.TakeDamage )

-- ZDEV_UID: ZDEV_FUNC_7BCF1633 | Path: ZDEV.PLYR.PlayerShouldTakeDamage
function ZDEV.PLYR.PlayerShouldTakeDamage( pl, atk )

end

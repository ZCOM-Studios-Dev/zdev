local _f = 'zdev/shared/zd_sh_weapon.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end

if ZDEV.WEAP then
	zdev.log( "S", "ZDEV Weapon Master-Table located.")
end

ZDEV.WEAP = ZDEV.WEAP or {}

zdev.log( "D", "Loading Ammo System")

--[[ ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

	ZDEV CORE: AMMO

■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ ]]

ZDEV.WEAP.AMMO = {
	[AMMO_9MM]			= { name = "9mm", icon = "R", iconfont = "csd" },
	[AMMO_45]			 = { name = ".45", icon = "M", iconfont = "csd" },
	[AMMO_357]			= { name = ".357", icon = "T", iconfont = "csd" },
	[AMMO_50]			 = { name = ".50", icon = "U", iconfont = "csd" },
	[AMMO_338]			= { name = ".338", icon = "W", iconfont = "csd" },
	[AMMO_57]			 = { name = "5.7", icon = "S", iconfont = "csd" },
	[AMMO_556]			= { name = "5.56", icon = "N", iconfont = "csd" },
	[AMMO_762]			= { name = "7.62", icon = "V", iconfont = "csd" },
	[AMMO_22]			 = { name = "22LR", icon = "R", iconfont = "csd" },
	[AMMO_SHELL]		= { name = "Shell", icon = "J", iconfont = "csd" },
	[AMMO_GRENADE]	= { name = "Grenade", icon = "O", iconfont = "csd" },
	[AMMO_ENERGY]	 = { name = "Energy", icon = "z", iconfont = "HalfLife2" },
	[AMMO_ARROW]		= { name = "Arrow", icon = "|", iconfont = "HalfLife2" }
}

-- ZDEV_UID: ZDEV_FUNC_D7056E30 | Path: ZDEV.AMMO.GetID
function ZDEV.AMMO.GetID( s_ammo )
	--local t_id = { "ammo_338", "ammo_357","ammo_45", "ammo_556", "ammo_57", "ammo_762", "ammo_9", "ammo_ahell" }
	return ZDEV.AMMO.ID[ s_ammo ]
end

-- ZDEV_UID: ZDEV_FUNC_075E6E4A | Path: ZDEV.AMMO.GetIcon
function ZDEV.AMMO.GetIcon( ammo )
	return tostring(ZDEV.AMMO[ ammo ].icon)
end

-- ZDEV_UID: ZDEV_FUNC_AFD79260 | Path: ZDEV.AMMO.GetLabel
function ZDEV.AMMO.GetLabel( ammo )
	return ZDEV.AMMO[ ammo ].label
end

-- ZDEV_UID: ZDEV_FUNC_AA1BEFD2 | Path: ZDEV.AMMO.GetName
function ZDEV.AMMO.GetName( ammo )
	return ZDEV.AMMO[ ammo ].name
end

-- ZDEV_UID: ZDEV_FUNC_8E132CE0 | Path: ZDEV.AMMO.FindByName
function ZDEV.AMMO.FindByName( s_name )
	for k, v in pairs( ZDEV.AMMO.GetAll() ) do
		if type(v) == "table" and v.name == s_name then
			return v
		end
	end
end

zdev.log( "D", "Loading Weapon System")

ZDEV.WEAP.IndexPath = "zdev/weap/weapon_index.txt"
ZDEV.WEAP.DataPath = "zdev/weap/	"

ZDEV.WEAP.INDEX = ZDEV.WEAP.INDEX or {}

-- ZDEV_UID: ZDEV_FUNC_D06CE55F | Path: ZDEV.WEAP.ForEach
ZDEV.WEAP.ForEach = function() for k, v in pairs( ZDEV.WEAP.INDEX ) do return k, v end end

ZDEV.WEAP.HOLDTYPE = {	"normal", "knife", "slam", "crowbar", "pistol", "smg", "ar2", "revolver", "crossbow", "grenade", "rpg", "shotgun", "melee2", "duel", "camera", "magic", "melee", "physgun" }


ZDEV.WEAP.GROUP = {
	[GROUP_MELEE]					= { tag = "mel", name = "Melee" },
	[GROUP_GADGET]				 = { tag = "gadg", name = "Gadget" },
	[GROUP_GRENADE]				= { tag = "gren", name = "Grenade" },
	[GROUP_PISTOL]				 = { tag = "pist", name = "Pistol" },
	[GROUP_SMG]						= { tag = "smg", name = "SMG" },
	[GROUP_SHOTGUN]				= { tag = "shot", name = "Shotgun" },
	[GROUP_RIFLE]					= { tag = "rif", name = "Rifle" },
	[GROUP_SNIPER]				 = { tag = "snip", name = "Sniper" },
	[GROUP_DEPLOY]				 = { tag = "depl", name = "Deploy" },
	[GROUP_THROW]				 = { tag = "thro", name = "Throwable" },
	[GROUP_EXPLOSIVE]			 = { tag = "expl", name = "Explosive" },
	[GROUP_NULL]					 = { tag = "", name = "UNKNOWN" }
}

-- ZDEV_UID: ZDEV_FUNC_F72F044F | Path: ZDEV.WEAP.GroupName
function ZDEV.WEAP.GroupName( id )
	if not ZDEV.WEAP.GROUP[ id ] then return end
	return ZDEV.WEAP.GROUP[ id ].name
end

ZDEV.WEAP.PROJECTILES = {
	[PROJECTILE_NULL]		= { name = "NULL", icon = Material(""), gravity = nil},
	[PROJECTILE_GRENADE]	= { name = "Grenade", icon = Material(""), gravity = true},
	[PROJECTILE_MINE]		= { name = "Mine", icon = Material(""), gravity = true},
	[PROJECTILE_ACTIVATE]	= { name = "Activate", icon = Material(""), gravity = false},
	[PROJECTILE_DETONATE] 	= { name = "Detonate", icon = Material(""), gravity = true},
	[PROJECTILE_DEPLOY]		= { name = "Deploy", icon = Material(""), gravity = true}
}

ZDEV.WEAP.b_Debug = true

--[[ ==============================================================

	WEAPONS

================================================================== ]]

local id_translate = {
	type = {
		["gren"]	= "GR",
		["gadg"]	= "GA",
		["pist"]	= "PI",
		["smg"]	 = "SM",
		["shot"]	= "SH",
		["rif"]	 = "RI",
		["snip"]	= "SP",
		["mel"]	 = "ME",
		["dplo"]	= "DE"
	}
}

-- ZDEV_UID: ZDEV_FUNC_920BBF64 | Path: ZDEV.WEAP.IsHoldTypeValid
function ZDEV.WEAP.IsHoldTypeValid( htype )
	return tobool( table.HasValue( ZDEV.WEAP.HOLDTYPE, htype) )
end

--[[ ==============================================================
	ZDEV.WEAP.NewID
 • Generate a unique ID to identify the target script internally
================================================================== ]]
-- ZDEV_UID: ZDEV_FUNC_1DC756F0 | Path: ZDEV.WEAP.NewID
function ZDEV.WEAP.NewID( class )

	local newID = ""
	for i = 1, 6 do
		local rand = math.random( 1, 9 )
		newID = newID .. rand
	end

	return newID

end

-- ZDEV_UID: ZDEV_FUNC_FB6ECFF3 | Path: ZDEV.WEAP.GetID
function ZDEV.WEAP.GetID( arg )
	if type(arg) == "string" then
		return ZDEV.WEAP.IDFromClass( arg )
	elseif type(arg) == "table" then
		for k, v in pairs( arg ) do
			if k == "id" then
				return v
			end
		end
	elseif arg:IsWeapon() or arg:IsScripted() then
		if arg.id then
			return arg.id
		end
	end

	return false
end

-- ZDEV_UID: ZDEV_FUNC_EAD411E7 | Path: ZDEV.WEAP.IDFromClass
function ZDEV.WEAP.IDFromClass( class )
	for k, v in pairs( ZDEV.WEAP.INDEX ) do
		if v.ClassName == class then
			return k
		end
	end
end

-- ZDEV_UID: ZDEV_FUNC_7B9F3D31 | Path: ZDEV.WEAP.FindByID
function ZDEV.WEAP.FindByID( id )
	for k, v in pairs( ZDEV.WEAP.INDEX ) do
		if k == id then
			return v.ClassName
		end
	end
end

--[[ ==============================================================
	ZDEV.WEAP.InitWeaponData
 • Copy pertinent data SWEP to a global table to better sort our SWEPs
================================================================== ]]
-- ZDEV_UID: ZDEV_FUNC_437E7FD0 | Path: ZDEV.WEAP.InitializeWeapon
function ZDEV.WEAP.InitializeWeapon( data )

end

-- ZDEV_UID: ZDEV_FUNC_C04CF33C | Path: ZDEV.WEAP.WeaponInitialized
function ZDEV.WEAP.WeaponInitialized( id )

end

-- ZDEV_UID: ZDEV_FUNC_2C99E9F5 | Path: ZDEV.WEAP.StoredSWEPTable
function ZDEV.WEAP.StoredSWEPTable( s_class )

end

-- ZDEV_UID: ZDEV_FUNC_CAF7B3DA | Path: ZDEV.WEAP.SWEPTable
function ZDEV.WEAP.SWEPTable( s_class )

end

-- ZDEV_UID: ZDEV_FUNC_C225C613 | Path: ZDEV.WEAP.MergedSWEPTable
function ZDEV.WEAP.MergedSWEPTable( s_class )
	zdev.log( "D", "Processing COMPLETE SWEP data-table for classname: " .. s_class )

	local t_s, t_g, t_data

	zdev.log( "D", "\t Stored Table" )
	t_s = weapons.GetStored( s_class )
	ZDEV.UTIL.AnalyzeTable( t_s )

	zdev.log( "D", "\t Copy Table" )
	t_g = weapons.Get( s_class )
	ZDEV.UTIL.AnalyzeTable( t_g )

	zdev.log( "D", "\t Merged Table" )
	t_data = table.Merge( t_s, t_g )
	ZDEV.UTIL.AnalyzeTable( t_data )

	return t_data
end

--[[ ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	ZDEV CORE: FILE - Weapons
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ ]]
-- ZDEV_UID: ZDEV_FUNC_9A3DFD71 | Path: ZDEV.WEAP.SaveFile
function ZDEV.WEAP.SaveFile( s_file, t_data )

	local s_data = util.TableToJSON( t_data, true )
	s_file = tostring( ZDEV.DATA.DIR .. "/weap/" .. s_file )

	local b_exists = file.Exists( s_file, "DATA" )

	zdev.log( "D", " Creating file: " .. tostring( s_file ) .. " . . . " )
	file.Write( s_file , s_data )

end

-- ZDEV_UID: ZDEV_FUNC_E3109661 | Path: ZDEV.WEAP.LoadFile
function ZDEV.WEAP.LoadFile( weap )

	local s_class

	if type( weap ) == "string" then
		s_class = weap
	elseif type( weap ) == "Weapon" then
		s_class = weap:GetClass() 
	elseif type( weap ) == "table" then
		s_class = weap.ClassName
	else
		zdev.log( "E", "Cannot load file for "..tostring(weap) .. " invalid type passed as arg #1." )
		return false
	end

	local s_path = ZDEV.WEAP.DataPath
	local t_data =	util.JSONToTable( file.Read( s_path .. s_class .. ".txt" ) )

	zdev.log( "S", "Loaded file: " .. tostring(s_path) )
	return t_data

end

-- ZDEV_UID: ZDEV_FUNC_3F60E11D | Path: ZDEV.WEAP.SaveIndex
function ZDEV.WEAP.SaveIndex()
	local t_weaps, s_weaps

	t_weaps = ZDEV.WEAP.INDEX
	s_weaps = util.TableToJSON( t_weaps, true )

	file.Write( ZDEV.WEAP.IndexPath, s_weaps )
	zdev.log( "D", "Saved weapons-index table to file." )
end

-- ZDEV_UID: ZDEV_FUNC_93330FE0 | Path: ZDEV.WEAP.LoadIndex
function ZDEV.WEAP.LoadIndex( )

	local s_file = ZDEV.WEAP.IndexPath
	if !file.Exists( ZDEV.WEAP.IndexPath,	"DATA" ) then return end
	local t_weaps = file.Read( util.JSONToTable( s_file ), "DATA")

	ZDEV.WEAP.INDEX = t_weaps
	zdev.log( "S", "Loaded Weapon-Index file")

end

-- ZDEV_UID: ZDEV_FUNC_2168AABB | Path: ZDEV.WEAP.RegisterWeapon
function ZDEV.WEAP.RegisterWeapon( class )

	local w = weapons.GetStored( class )

	local id = ZDEV.WEAP.NewID( class )
	local t_weap = table.Copy( w )

	t_weap.id = id

	ZDEV.WEAP.INDEX[ id ] = t_weap

	zdev.log( "D", "Registered Weapon: " .. tostring(class) .. " [" .. tostring(id) .. "]" )
end

-- ZDEV_UID: ZDEV_FUNC_3E310734 | Path: ZDEV.WEAP.RegisterWeapons
function ZDEV.WEAP.RegisterWeapons( )

	zdev.log( "D", " Registering all ZDEV SWEPs to global table. ")

	local weps = weapons.GetList()

	for k, w in ipairs( weps ) do
		local class = w.ClassName
		-- If weapon's class contains the string '_st_'
			if string.find( class, "zdev_", 0, false) then
			local name = w.PrintName
			ZDEV.WEAP.RegisterWeapon( class )
			ZDEV.WEAP.SaveFile( class .. ".txt", w )
		end
	end

end

ZDEV.FILE.SetLoaded( _f )

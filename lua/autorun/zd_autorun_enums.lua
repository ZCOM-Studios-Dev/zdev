local _f = 'autorun/zd_autorun_enums.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

if SERVER then
	AddCSLuaFile()
end

Msg('■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■\n')
MsgC(Color(50,255,200),'\tZDEV Enums Loaded.\n',color_white)
Msg('■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■\n')
--[[
	zd_autorun_enums.lua
	Enum definitions for Garry's Mod addon.
	Author: zcomstudios
	Description: Contains enumerations used throughout the addon.
]]
-- ■■ ENUMERATOR: LOGTYPE ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

LOGTYPE_ERROR 		= 1
LOGTYPE_WARNING 	= 2
LOGTYPE_SUCCESS 	= 3
LOGTYPE_INFO		= 4
LOGTYPE_DEBUG		= 5
LOGTYPE_STOP		= 6
LOGTYPE_QUERY		= 7
LOGTYPE_HINT		= 8
LOGTYPE_CRITICAL	= 9
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

-- ■■ ENUMERATOR: HUDMSG ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
HUDMSG_INFO			= 1
HUDMSG_HINT			= 2
HUDMSG_WARN			= 3
HUDMSG_ERROR		= 4
HUDMSG_ANNOUNCE		= 5
HUDMSG_MARKER		= 6
HUDMSG_WORLD		= 7

-- ■■ ENUMERATOR: WEAPONGROUP ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
GROUP_MELEE			= 0
GROUP_GADGET		= 1
GROUP_GRENADE		= 2
GROUP_PISTOL		= 3
GROUP_SMG	        = 4
GROUP_SHOTGUN		= 5
GROUP_RIFLE			= 6
GROUP_SNIPER		= 7
GROUP_DEPLOY		= 8
GROUP_THROW			= 10
GROUP_EXPLOSIVE		= 11
GROUP_NULL    	  	= 17

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
MELEE_BLUNT 	= 1
NELEE_SLASH		= 2
NELEE_HEAVY		= 3
MELEE_ENERGY	= 4
MELEE_OTHER		= 5

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
PROJECTILE_NULL		= 0
PROJECTILE_GRENADE	= 1
PROJECTILE_MINE		= 2
PROJECTILE_ACTIVATE	= 3
PROJECTILE_DETONATE = 4
PROJECTILE_DEPLOY	= 5

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
AMMO_NULL        = 0
AMMO_9MM         = 1
AMMO_45          = 2
AMMO_357         = 3
AMMO_50          = 4
AMMO_338         = 5
AMMO_57          = 6
AMMO_556         = 7
AMMO_762         = 8
AMMO_22          = 9
AMMO_SHELL       = 10
AMMO_GRENADE     = 11
AMMO_ENERGY      = 12
AMMO_ARROW       = 13
AMMO_GADGET		 = 14

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
RANK_NULL 		= -1
RANK_PLAYER 	= 0
RANK_TRAINEE	= 1
RANK_PRIVATE 	= 2
RANK_CORPORAL 	= 3
RANK_SERGEANT 	= 4
RANK_LIEUTENANT = 5
RANK_CAPTAIN 	= 6
RANK_MAJOR 		= 7
RANK_COLONEL 	= 8

-- ■■ ENUMERATOR: AI ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
AI_NULL 		= 0
AI_NEUTRAL		= 1
AI_HOSTILE		= 2
AI_PASSIVE		= 3
AI_FRIENDLY 	= 4
AI_LOGIC		= 5
AI_IGNORE 		= 6

-- ■■ ENUMERATOR: FACTIONS ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
FACTION_NONE 		= 0
FACTION_NEUTRAL		= 1
FACTION_OVERWATCH 	= 2
FACTION_RESISTANCE 	= 3
FACTION_ZOMBIES 	= 4
FACTION_ANTLION 	= 5

-- ■■ ENUMERATOR: BEHAVIORS ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
BEHAVIOR_FLEE		= 1
BEHAVIOR_ATTACK		= 2
BEHAVIOR_DEFEND		= 3
BEHAVIOR_IDLE		= 4
BEHAVIOR_PATROL		= 5
BEHAVIOR_FOLLOW		= 6
BEHAVIOR_GUARD		= 7
BEHAVIOR_STALK		= 8
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

FX_NULL			= 0
FX_EXPLODE		= 1
FX_MUZZLE		= 2
FX_CONSTANT		= 3
FX_TRACER		= 4
FX_SPRITE		= 5
FX_PARTICLE		= 6
FX_GENERIC		= 7

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- FXTYPE
FXTYPE_NULL		= -1
FXTYPE_UNDEFINED = 0
FXTYPE_GENERIC	= 1
FXTYPE_POINT	= 2
FXTYPE_TRACER	= 3
FXTYPE_CSENT	= 4
FXTYPE_TRAIL	= 5
FXTYPE_SPRITE	= 6
FXTYPE_OTHER	= 7
--

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- EMITTER TYPE
EMIT_INSTANT 		= 1		-- Explosions, etc. Init emitter
EMIT_CONSTANT 		= 2		-- Sparks, welding, burning, etc (Render Emit)
EMIT_TIMED 			= 3		-- Controlled, timed-function emitters. (Think Emit)
EMIT_GENERIC		= 4 	-- The default emitter type can be used when unsure

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- ITEM-PICKUP TYPE
PICKUP_NULL			= 0
PICKUP_INSTANT		= 1
PICKUP_BUFF			= 2
PICKUP_PERMANENT	= 3
PICKUP_MISC 		= 4

UPMODE_NULL 		= 0
UPMODE_TOUCH		= 1
UPMODE_USE			= 2
UPMODE_CONSUME		= 3
UPMODE_DESTROY		= 4

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- ITEM TYPE
ITEM_NULL			= 0
ITEM_RECOVERY		= 1
	RECOVERY_NULL		= 0
	RECOVERY_EDIBLE		= 1
	RECOVERY_MEDICAL	= 2
	RECOVERY_CHEMICAL	= 3
	RECOVERY_MISC		= 4
ITEM_EQUIPMENT		= 2
	EQUIP_NULL			= 0
	EQUIP_CLOTHING		= 1
	EQUIP_GEAR			= 2
	EQUIP_STORAGE		= 3
	EQUIP_ARMOR			= 4
	EQUIP_ATTACHMENT	= 5
	EQUIP_WEAPON		= 6
	EQUIP_MISC			= 7

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- SLOT TYPE
SLOT_NULL				= 0
SLOT_HELMET				= 1
SLOT_SHOULDER_L			= 2
SLOT_SHOULDER_R			= 3
SLOT_CHESTPIECE			= 4
SLOT_SLEEVE_L			= 5
SLOW_SLEEVE_R			= 6
SLOT_GLOVE_L			= 7
SLOT_GLOVE_R			= 8
SLOT_WAIST				= 9
SLOT_LEGGINGS			= 10
SLOT_FOOTWEAR			= 11

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- INVENTORY TYPE
INVENTORY_NULL				= 0
INVENTORY_BACKPACK			= 1
INVENTORY_SATCHELL			= 2
INVENTORY_BAG				= 3
INVENTORY_POCKET_TOP_L		= 4
INVENTORY_POCKET_TOP_R		= 5
INVENTORY_POCKET_PANTS_L 	= 6
INVENTORY_POCKET_PANTS_R 	= 7
INVENTORY_STASH				= 8
INVENTORY_SAFE				= 9
INVENTORY_DEPOSIT			= 10
INVENTORY_BANK				= 11


ZDEV.FILE.SetLoaded( _f )
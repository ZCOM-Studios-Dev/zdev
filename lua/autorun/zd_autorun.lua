local _f = 'zd_autorun.lua';  Msg("■ ") MsgC(Color(255,255,50),'ZDEV File: ',color_white,_f .. '\n')
--
--[[■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	ZDEV - ZCOM's Development Addon
----------------------------------------------------------
	By Adrian 'ZCOM' L. at ZCOM Studios
	Copyright (c) 2020 by ZCOM Studios, All rights reserved.
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■]]
if SERVER then
	require( "zdev" )
	require( "znnet" )
end
-- Client stub: shared/client files reference zdev.log() etc. from the binary module.
-- If the client binary (gmcl_zdev) is not present, provide a safe no-op table.
zdev = zdev or { log = function() end }
--[[═════════════════════════════════════════════════════════════════════════
  ZDEV CORE: FILE - Users
═════════════════════════════════════════════════════════════════════════ ]] 
--[[================================================
    CONVARS
==================================================]] 

MsgC( Color(100,255,100), "■■█ ZDEV Core Addon █■■", Color(255,255,150), "[v0.7.2]", Color(150,255,150), " By ZCOM Studios", Color(0,200,255)," (https:--zcomstudios.com/)" .. "\n" )

ZDEV = ZDEV or {}	-- General Data-Table
ZD = ZD or {}		-- Primary Hook-Table
ZDEV_ADDONS = ZDEV_ADDONS or {}	-- All relevant addon data for dependencies and resource tracking

--[[■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- SHARED
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■]]
ZDEV.ADON = {}
ZDEV.HOOK = {}
ZDEV.DBUG = {}
ZDEV.DBUG.LOG = {}
ZDEV.UTIL = {}
ZDEV.MATH = {}
ZDEV.MATH.CALC = {}
ZDEV.DATA = {}
ZDEV.VARS = {}
ZDEV.FILE = {}
ZDEV.FILE.INDEX = {}
ZDEV.FILE.DIR = {}
ZDEV.CONV = {}
ZDEV.CMDS = {}
ZDEV.CMDS.DEV = {}
ZDEV.MAPS = {}
ZDEV.NPCS = {}
ZDEV.WEAP = {}
ZDEV.AMMO = {}
ZDEV.ENTS = {}
ZDEV.MDLS = {}
ZDEV.BOTS = {}
ZDEV.TIMR = {}
ZDEV.GAME = {}
ZDEV.PLYR = {}
ZDEV.MATS = {}
ZDEV.SEFX = {}
ZDEV.REND = {}
ZDEV.MSQL = {}
ZDEV.EDIT = {
	ENVM = {},
	PART = {},
	MATS = {},
	NPCS = {},
	ENTS = {},
	WEAP = {}
}
--[[■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- CONTENT
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■]]
ZDEV.CONT = {}
	ZDEV.CONT.SEFX = {}
	ZDEV.CONT.SOUN = {}
	ZDEV.CONT.MODL = {}
	ZDEV.CONT.MATS = {}
	ZDEV.CONT.FONT = {}
	ZDEV.CONT.MAPS = {}
	ZDEV.CONT.PRTL = {}

--[[■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- DEBUGGING/FILE & DATA STRUCTURE/LOGGING FUNCTIONS
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■]]

ZDEV.FILE.DIR.ROOT = "zdev"
ZDEV.DATA.DIR = ZDEV.FILE.DIR.ROOT .. "data/"
local function timer_zdev( t )
	local path = ZDEV.FILE.DIR.ROOT .. ZDEV.DATA.DIR
	--ZDEV.UTIL.ScanDir( "zdev", "DATA" )
	--local f, d = file.Find( path .. "*", "DATA" )
	local f, d = file.Find( "zdev--[[", "DATA", "nameasc" )
	--print( d, path, f )
	local data, contents
	for k1, d1 in ipairs( d ) do
		--print( k1, d1 )
	end
	for k2, f1 in ipairs( f ) do
		--print( k2, f1 )
	end
end
timer.Create( "ZDEV_DataFileRefreshRate", 9, 0, timer_zdev, ZDEV )

-- ZDEV_UID: ZDEV_FUNC_107F5005 | Path: ZDEV.ADON.AddAddon
ZDEV.ADON.AddAddon = function( id, v )
	zdev.log( "S", "Registering Addon: " .. tostring(id) .. " " .. tostring(v.name) )

	if not ZDEV_ADDONS or ZDEV_ADDONS == nil then 		ZDEV_ADDONS = {} 	end
	ZDEV_ADDONS[ id ] = v

	MsgC(color_white, " ◈ ", Color(150,255,150), "ZDEV Addon Registered: \t", Color(50,255,50), v.name, Color(255,255,0), v.version .. "\n")

end

-- ZDEV_UID: ZDEV_FUNC_B625D863 | Path: ZDEV.FILE.GetAllLoaded
function ZDEV.FILE.GetAllLoaded()
	return table.GetKeys(ZDEV.FILE.INDEX)
end

-- ZDEV_UID: ZDEV_FUNC_FA280C27 | Path: ZDEV.FILE.Loaded
function ZDEV.FILE.Loaded( s_file )
	return tobool(ZDEV.FILE.INDEX[s_file])
end

-- ZDEV_UID: ZDEV_FUNC_A7C35901 | Path: ZDEV.FILE.SetLoaded
function ZDEV.FILE.SetLoaded( s_file )
	ZDEV.FILE.INDEX[s_file] = true
end



if (SERVER) then

	include( "zd_autorun_debug.lua")
	include( "zd_autorun_enums.lua")
	include( "zd_autorun_util.lua")

	AddCSLuaFile( "zd_autorun_debug.lua")
	AddCSLuaFile( "zd_autorun_enums.lua")
	AddCSLuaFile( "zd_autorun_util.lua")

	--[[■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	-- SERVER
	■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■]]

	ZDEV.GAME = {}
	ZDEV.PLYR = {}
	ZDEV.PLYR._INDEX = {}
	ZDEV.INDX = {}
	ZDEV.REGS = {}
	ZDEV.MSQL = {}

	ZDEV.FILE.DIR.ROOT = ZDEV.DATA.RootDir or "zdev/"
	ZDEV.FILE.DIR.PATH = "data"
	ZDEV.FILE.DIR.Logs = "logs/"
	ZDEV.FILE.DIR.Players = "plyr/"
	ZDEV.FILE.DIR.Weapons = "weap/"
	ZDEV.FILE.DIR.Entities = "ents/"
	ZDEV.FILE.DIR.Effects = "sefx/"
	ZDEV.FILE.DIR.Materials = "mats/"
	ZDEV.FILE.DIR.NPCs = "npcs/"
	ZDEV.FILE.DIR.Maps = "maps/"
	ZDEV.FILE.DIR.Config = "cnfg/"


	--[[■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	-- LOCAL DATA-FILES (TEXT/JSON)
	■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■]]
	ZDEV.VARS.b_DataDirInitialized = false
	-- ZDEV_UID: ZDEV_FUNC_8E90F53A | Path: ZDEV.FILE.InitDataDirs
	function ZDEV.FILE.InitDataDirs()

		if !ZDEV.VARS.b_DataDirInitialized then

			zdev.log( "N", "Initializing data folder sub-directories and core-files.")

			local root = ZDEV.FILE.DIR.ROOT
			for l, d in pairs( ZDEV.FILE.DIR ) do
				local path = root .. "/" .. d
				-- Create the new directory for data
				if !file.IsDir( path, "DATA" ) then
					file.CreateDir( path )
					zdev.log( "W", "Data directory '" .. tostring(d) .. "' created." )
				-- Since it exists, LOAD the current files into the table
				else
					zdev.log( "I", "Data directory '" .. tostring(d) .. "' already exists." )
				end
				ZDEV.DATA[ tostring(l) ] = { dir = path };
			end

		--	DebugPrintTable( ZDEV.DATA )
			ZDEV.VARS.b_DataDirInitialized = true
		end

	end

	ZDEV.FILE.InitDataDirs()

	-- ZDEV_UID: ZDEV_FUNC_DA5A67C6 | Path: ZDEV.CONV.Create
	function ZDEV.CONV.Create( var, val, flags, help )

		ZDEV.CONV._INDEX = ZDEV.CONV._INDEX or {}
		local conv = { var = var, val = val, flags = flags, help = help }
		table.insert( ZDEV.CONV._INDEX, conv )
		zdev.log( "I", "Created Convar '" .. tostring(var) .. "' = '" .. tostring(val) .. "'")
		CreateConVar( var, val, flags, help ) 

	end

	ZDEV.CONV.Create( "zd_dev", "0", {FCVAR_CHEAT,FCVAR_SERVER_CAN_EXECUTE,FCVAR_PROTECTED}, "Toggle Developer mode for the ZDEV addon.")


	local b_firstrun = false
	local indx_files = {}
	timer.Create( "zdev_auto_filecheck", 6, 0, function() 

		if !ZDEV then return end
		if !GetConVar( "zd_dev" ):GetBool() then return end
		if ZDEV.FILE.INDEX then
			indx_files = ZDEV.FILE.INDEX
			if !b_firstrun then
				b_firstrun = true
				for k, v in ipairs( indx_files ) do
					
					if ZDEV.FILE.Loaded( v ) then
						zdev.log( "S", "Files check passed for (" .. tostring(v) .. ")" )
					end
				end
			end
		end
		
		zdev.log( "S", "FIles check passed!" )

	end)

	ZDEV.MSQL = ZDEV.MSQL or {}
	ZDEV.MSQL.Database = {
		["database"] = "zdev_test",
		["username"] = "zdev",
		["password"] = "(xi.OZYELzJNul8@",
		["host"] = "127.0.0.1",
		["port"] = "3306",
	}

	local has_mysqloo, mysqloo = pcall(require, "mysqloo")
	if not has_mysqloo or not mysqloo then
		zdev.log( "E", "MySQLoo module not found! Database functionality disabled." )
		ZDEV.MSQL.Connect = nil
		return
	end
	--[[■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	-- REMOTE DATA - MYSQL (MySQLoo)
	■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■]]

	ZDEV.MSQL.Connect = msqloo.connect( ZDEV.MSQL.Database["host"], ZDEV.MSQL.Database["database"], ZDEV.MSQL.Database["password"], ZDEV.MSQL.Database["user"], ZDEV.MSQL.Database["port"] )

	if ZDEV.MSQL.Connect then
		function ZDEV.MSQL.Connect:onConnected()
			MsgC( Color(200,200,255), "ZDEV ", Color(200,100,255), "MySQL Database", Color(255,150,255), "Establishing secure Connection-Pool: ", Color(100,255,100), "SUCCESS\n" )
			local t_lastInfo = {
				count = ZDEV.MSQL.Connect:queueSize(),
				version = ZDEV.MSQL.Connect:serverInfo(),
				host = ZDEV.MSQL.Database["host"],
				ping = ZDEV.MSQL.Connect:ping()
			}
			for k, v in pairs( t_lastInfo ) do
				v = tostring(v)
				local clr1, clr2 = Color(200,200,200), Color(0,200,255)
				MsgC( clr1, "\t" .. tostring(k) .. ": ", clr2, v .. "\n" )
			end
			if not ZDEV.MSQL.Connect then return end
			local q = ZDEV.MSQL.Connect:query( "SELECT * FROM players" )
			function q:onSuccess( data )
				print( "Query successful!" )
				PrintTable( data )
			end
			function q:onError( err, sql )
				print( "Query errored!" )
				print( "Query:", sql )
				print( "Error:", err )
			end
			q:start()
		end
		function MYSQL_DB:onConnectionFailed( err )
			print( "Connection to database failed!" )
			print( "Error:", err )
		end
		ZDEV.MSQL.Connect:connect()
	end

	--AddCSLuaFile( "zdev/shared.lua" )
	--AddCSLuaFile( "zdev/cl_init.lua" )
	include( "zdev/init.lua" )

end

if (CLIENT) then 
	
	include( "zd_autorun_debug.lua")
	include( "zd_autorun_enums.lua")
	include( "zd_autorun_util.lua")

	--[[■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	-- CLIENT
	Defines all ZDEV client-side global tables and namespaces

	■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■]]

	ZDEV.LPLY = {}
	ZDEV.VGUI = {}
		ZDEV.VGUI.MENU = {}
		ZDEV.VGUI.DERM = {}
		ZDEV.VGUI.SKIN = {}
		ZDEV.VGUI.HTTP = {}
	ZDEV.CHUD = {}
	ZDEV.REND = {}
	ZDEV.SEFX = {}
	ZDEV.DRAW = {}
	ZDEV.TEXT = {}
	ZDEV.CHAT = {}
	ZDEV.VIEW = {}
	ZDEV.FONT = {}
	ZDEV.EDIT = {}
	ZDEV.EDIT.PART = {}
	ZDEV.EDIT.EMIT = {}
	--[[■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

		CLIENT CONVARS
	==================================================]]--
	--[[
		zd_cl_autorun.lua
		Client-side autorun script for Garry's Mod addon.
		Author: zcomstudios
		Description: Handles client initialization and setup for the addon.
	]]
	CreateClientConVar( "zd_hud_visor", "1", true, false, "Toggle drawing of Visor material overlay texture")
	CreateClientConVar( "zd_hud_vitals", "1", true, false, "Toggle drawing of Health, Armor and other vitals")
	CreateClientConVar( "zd_hud_ammo", "1", true, false, "Toggle drawing rounds in clip, ammo count, etc")
	CreateClientConVar( "zd_hud_crosshair", "1", true, false, "Toggle drawing custom crosshair/reticle")
	CreateClientConVar( "zd_hud_info", "1", true, false, "Toggle drawing player info in top left HUD")
	CreateClientConVar( "zd_hud_chat", "0", true, false, "Toggle drawing chat messages and custom chatbox")
	CreateClientConVar( "zd_hud_messages", "1", true, false, "Toggle drawing chat messages and custom chatbox")
	CreateClientConVar( "zd_hud_effects", "1", true, false, "Toggle drawing chat messages and custom chatbox")
	CreateClientConVar( "zd_hud_font_pri", "", true, false, "Font-name of the primary font used for large numbers")
	CreateClientConVar( "zd_hud_font_sec", "", true, false, "Font-name of the secondary font used for small details")
	CreateClientConVar( "zd_hud_clr_pri", "255 150 0 255", true, false, "R G B values for the primary color of the HUD")

	CreateClientConVar( "zd_hud_clr_sec", "255 150 0 255", true, false, "R G B values for the secondary color of the HUD")
	CreateClientConVar( "zd_xhair_clr", "255 150 0 255", true, false, "R G B values for the color of the Crosshair")

	CreateClientConVar( "zd_dev_console_x", "100", true, false, "Developer Lua-Console X Position ")
	CreateClientConVar( "zd_dev_console_y", "400", true, false, "Developer Lua-Console Y Position ")
	CreateClientConVar( "zd_dev_console_w", "600", true, false, "Developer Lua-Console Width ")
	CreateClientConVar( "zd_dev_console_h", "200", true, false, "Developer Lua-Console Height ")

	CreateClientConVar( "zd_dev_hud_time", "0", true, false, "Toggle drawing global time-function(s) output on the HUD")
	CreateClientConVar( "zd_dev_hud_xhair", "1", true, false, "Toggle drawing development crosshair on HUD")
	CreateClientConVar( "zd_dev_hud_grid", "1", true, false, "Toggle drawing development grid on HUD")
	CreateClientConVar( "zd_dev_hud_entinfo", "1", true, false, "")
	CreateClientConVar( "zd_dev_hud_ents", "1", true, false, "")

	CreateClientConVar( "zd_debug_render", "0", true, false, "")
	CreateClientConVar( "zd_debug_render_entinfo", "0", true, false, "")

	---Editor: Light [zedit_light]
	--CreateClientConVar( "zedit_light", "0", true, false, "")
	CreateClientConVar( "zedit_particle_toggle", "0", true, false, "")
	CreateClientConVar( "zedit_particle_show_helpers", "1", true, false, "")
	CreateClientConVar( "zedit_particle_show_timegraph", "1", true, false, "")
	CreateClientConVar( "zedit_particle_emitter", "0e001", true, false, "")
	CreateClientConVar( "zedit_particle_entity", "0", true, false, "")
	CreateClientConVar( "zedit_particle_pos", "0 0 0", true, false, "")
	CreateClientConVar( "zedit_particle_offset", "0 0 16", true, false, "") -- Arguments: Right, Fwd, Up )
	CreateClientConVar( "zedit_particle_id", "1", true, false, "")
	CreateClientConVar( "zedit_particle_count_min", "1", true, false, "")
	CreateClientConVar( "zedit_particle_count_max", "5", true, false, "")
	CreateClientConVar( "zedit_particle_delay", "0", true, false, "")
	CreateClientConVar( "zedit_particle_repeat", "1", true, false, "")
	CreateClientConVar( "zedit_particle_mat", "sprites/efx_0a_glow_25", true, false, "")
	CreateClientConVar( "zedit_particle_lifetime", "0", true, false, "")
	CreateClientConVar( "zedit_particle_dietime", "0.5", true, false, "")
	CreateClientConVar( "zedit_particle_size_s", "5", true, false, "")
	CreateClientConVar( "zedit_particle_alpha_s", "255", true, false, "")
	CreateClientConVar( "zedit_particle_length_s", "1", true, false, "")
	CreateClientConVar( "zedit_particle_size_e", "1", true, false, "")
	CreateClientConVar( "zedit_particle_alpha_e", "0", true, false, "")
	CreateClientConVar( "zedit_particle_length_e", "0", true, false, "")
	CreateClientConVar( "zedit_particle_airres", "100", true, false, "")
	CreateClientConVar( "zedit_particle_bounce", "0.5", true, false, "")
	CreateClientConVar( "zedit_particle_collide", "1", true, false, "")
	CreateClientConVar( "zedit_particle_lighting", "1", true, false, "")
	CreateClientConVar( "zedit_particle_gravity", "0 0 -100", true, false, "")
	CreateClientConVar( "zedit_particle_velocity", "0 0 0", true, false, "")
	CreateClientConVar( "zedit_particle_velocity_mul", "1.0", true, false, "")
	CreateClientConVar( "zedit_particle_angles", "0 0 0", true, false, "")
	CreateClientConVar( "zedit_particle_angular_velocity", "0 0 0", true, false, "")
	CreateClientConVar( "zedit_particle_color", "255 255 255 255", true, false, "")
	CreateClientConVar( "zedit_particle_color_r", "255", true, false, "")
	CreateClientConVar( "zedit_particle_color_g", "255", true, false, "")
	CreateClientConVar( "zedit_particle_color_b", "255", true, false, "")
	CreateClientConVar( "zedit_particle_color_a", "255", true, false, "")
	CreateClientConVar( "zedit_particle_roll", "0", true, false, "")
	CreateClientConVar( "zedit_particle_rolldelta", "0", true, false, "")

	CreateClientConVar( "zedit_env_toggle", "0", true, false, "")
	CreateClientConVar( "zedit_env_tool_mode", "0", true, true, "")
	CreateClientConVar( "zedit_env_brush_mode", "1", true, true, "")
	CreateClientConVar( "zedit_env_brush_radius", "128", true, false, "")
	CreateClientConVar( "zedit_env_brush_spacing", "16", true, false, "")
	CreateClientConVar( "zedit_env_brush_density", "0.5", true, false, "")
	CreateClientConVar( "zedit_env_brush_flow", "32", true, false, "")
	CreateClientConVar( "zedit_env_factor_trees", "1.0", true, false, "")
	CreateClientConVar( "zedit_env_factor_shrubs", "1.0", true, false, "")
	CreateClientConVar( "zedit_env_factor_grass", "1.0", true, false, "")
	CreateClientConVar( "zedit_env_factor_rocks", "1.0", true, false, "")
	CreateClientConVar( "zedit_env_factor_misc", "1.0", true, false, "")

	-- ZDEV_UID: ZDEV_FUNC_6F602247 | Path: ZDEV.CONV.EditorCallback
	function ZDEV.CONV.EditorCallback(convar_name, value_old, value_new)
		local LP = LocalPlayer()
		if value_new == 1 then
			LP:DrawViewModel( false )
			zdev.log( "F", "ZDEV Editor Mode: OFF")
		else
			LP:DrawViewModel( true )
			zdev.log( "S", "ZDEV Editor Mode: ON")
		end
	end
	cvars.AddChangeCallback("zedit_particle_toggle", ZDEV.CONV.EditorCallback )
	cvars.AddChangeCallback("zedit_env_toggle", ZDEV.CONV.EditorCallback )


	--[[ =============================================
		FONTS
	==================================================]]--
	ZDEV.FONT._INDEX = {}

	-- ZDEV_UID: ZDEV_FUNC_30DE908D | Path: ZDEV.FONT.GetFontFiles
	function ZDEV.FONT.GetFontFiles( )
		local f, d = file.Find( "resource/fonts--[[", "THIRDPARTY", "nameasc" )
		--PrintTable( f )
		return f
	end

	--function ZDEV.FONT.Register( newname, name, extended, size, weight, blur, scan, antialias, u, i, s, symbol, rotary, shadow, additive, outline )
	-- ZDEV_UID: ZDEV_FUNC_29501EC9 | Path: ZDEV.FONT.Register
	function ZDEV.FONT.Register( newname, fontdata )

		local	t_fontdata = {
			font = name,
			extended = extended,
			size = size,
			weight = weight,
			blursize = blur,
			scanlines = scan,
			antialias = antialias,
			underline = u,
			italic = i,
			strikeout = s,
			symbol = symbol,
			rotary = rotary,
			shadow = shadow,
			additive = additive,
			outline = outline	}

		surface.CreateFont( newname, fontdata )

		if not ZDEV.FONT._INDEX[ newname ] then
			ZDEV.FONT._INDEX[ newname ] = fontdata
		end
		--print('')
	end

	--[[ =============================================
		MATERIALS
	==================================================]]--
	ZDEV.MATS = ZDEV.MATS or {}
	ZDEV.CONT.MATS = ZDEV.CONT.MATS or {}
	ZDEV.CONT.MATS._INDEX = ZDEV.CONT.MATS._INDEX or {}

	function ZDEV.CONT.MATS.GetFiles( )
		local f, d = file.Find( "materials--[[", "THIRDPARTY", "nameasc" )
		if not f or not d then
			zdev.log( "E", "No materials found in THIRDPARTY directory!" )
			return {}
		end
		return f
	end

	--ZDEV.CONT.MATS.GetFiles( )

	include( "zdev/cl_init.lua" )
	--zdev.IncludeFilesIn("zdev/client/")
	--include( "autorun/client/cl_ui3d2d.lua")
	--include( "autorun/client/cl_ui3d2d_extras.lua")
	
end

--timer.Simple( 0, function() include( "autorun/zd_snpcs_autorun.lua") end )

--zdev.log( "S", "Loading file: ../addons/zdev_core/lua/autorun/zd_autorun.lua" )

ZDEV.FILE.SetLoaded( _f )
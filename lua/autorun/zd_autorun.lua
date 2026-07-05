local _f = 'autorun/zd_autorun.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',Color(150,255,150),"(AUTORUN)",color_white,_f .. '\n')
--
--[[■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	ZDEV - ZCOM's Development Addon
----------------------------------------------------------
	By Adrian 'ZCOM' L. at ZCOM Studios
	Copyright (c) 2020 by ZCOM Studios, All rights reserved.
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■]]
if SERVER then
	AddCSLuaFile()
end

-- Both zdev and znnet are pure-Lua modules in lua/includes/modules/, so require
-- on both realms. pcall guards against missing files / syntax errors; the stub
-- below then provides a no-op fallback so call sites don't error.
pcall( require, "zdev" )
pcall( require, "znnet" )

-- Defense-in-depth fallback if require above failed for any reason.
-- The structured wrapper in zd_autorun_debug.lua decorates whatever lands here.
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

-- Version is published as a comparable integer so child addons can gate on it.
-- VERSION_NUM = major*100 + minor*10 + patch  (e.g. 0.7.2 -> 702). Keep both in sync.
ZDEV.VERSION     = "0.7.2"
ZDEV.VERSION_NUM = 702

ZDEV.Settings = ZDEV.Settings or {}
-- Master kill switch for the unfinished inventory + equipment systems.
-- Flip to true to re-enable; all gated paths across the addon check this flag.
ZDEV.Settings.InventoryEnabled = false

--[[■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- SHARED
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■]]
-- Namespace cleanup 2026-07-02: removed never-referenced tables
-- (HOOK, MATH, MAPS, NPCS, BOTS, TIMR — see ROADMAP.md "Namespace Cleanup")
ZDEV.ADON = {}
-- DBUG must PERSIST across autorun re-runs (zdev_reload / lua_refresh):
-- it holds _Originals (pristine pre-intercept Msg/print/Error — wiping it
-- makes zd_sv_debug_console re-capture our own wrappers = double-wrap) and
-- MSG_TYPE, which surviving hooks/intercepts index between the wipe and the
-- shared file re-running.
ZDEV.DBUG = ZDEV.DBUG or {}
ZDEV.DBUG.LOG = {}
ZDEV.UTIL = {}
ZDEV.DATA = {}
ZDEV.VARS = {}
ZDEV.FILE = {}
ZDEV.FILE.INDEX = {}
ZDEV.FILE.DIR = {}
-- ── Load tracking (Sidekick Phase B1) ─────────────────────────────────────
-- Rich per-file load metadata alongside the boolean INDEX. META is keyed by
-- the same _f string files pass to SetLoaded; INDEX semantics are unchanged.
ZDEV.FILE.META = {}          -- _f -> { order, systime, oclock, realm, include_path, parent, chain, duration_ms, include_count, generation }
ZDEV.FILE._SEQ = 0           -- monotonic load-order counter (per realm)
ZDEV.FILE.GENERATION = 1     -- bumped by ResetTracking() on zdev_reload
ZDEV.FILE._STACK = {}        -- live include stack (frames: {path, t0, parent})
ZDEV.FILE._ATTEMPTS = {}     -- include path -> attempt count (catches guard-skipped re-includes)

-- Wrap the global include() to maintain the include stack. The pristine
-- original lives in a top-level global so a zd_autorun re-run (lua_refresh)
-- never double-wraps; a full Lua state reset restores the native include.
ZDEV_ORIG_INCLUDE = ZDEV_ORIG_INCLUDE or include
include = function( path )
	local stack = ZDEV.FILE._STACK
	stack[#stack + 1] = { path = path, t0 = SysTime(), parent = stack[#stack] }
	local ret = { ZDEV_ORIG_INCLUDE( path ) }
	stack[#stack] = nil
	ZDEV.FILE._ATTEMPTS[path] = ( ZDEV.FILE._ATTEMPTS[path] or 0 ) + 1
	return unpack( ret )
end
ZDEV.CONV = {}
ZDEV.CMDS = {}
ZDEV.CMDS.DEV = {}
ZDEV.WEAP = {}
ZDEV.AMMO = {}
ZDEV.ENTS = {}
ZDEV.MDLS = {}
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

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ADDON DEPENDENCY REGISTRAR
    Called by child addons (ZDEV Weapons, ZDEV NPCs, ...) from their
    self-contained dependency gate, AFTER the gate has confirmed that
    ZDEV Core is present. Version-checks the child against this Core
    build, records it in ZDEV_ADDONS, and returns the ZDEV namespace
    so the child can localize it.

    spec = {
        id       = "zdev_weapons",   -- unique registry key
        name     = "ZDEV Weapons",   -- human-readable
        version  = "1.0.0",          -- child's own version (display only)
        min_core = 702,              -- (optional) minimum ZDEV.VERSION_NUM required
    }
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
-- ZDEV_UID: ZDEV_FUNC_REG10001 | Path: ZDEV.ADON.Register
function ZDEV.ADON.Register( spec )
	if not istable( spec ) or not spec.id then
		MsgC( Color(255,80,80), "[ZDEV] ", color_white, "ZDEV.ADON.Register called with an invalid spec.\n" )
		return ZDEV
	end

	local name = spec.name or spec.id

	-- Soft version gate: warn but still load, so a stale child degrades rather than dies.
	if spec.min_core and ZDEV.VERSION_NUM < spec.min_core then
		MsgC( Color(255,80,80), "[ZDEV] ", color_white,
			name .. " requests Core v" .. tostring(spec.min_core) ..
			" but this is Core v" .. tostring(ZDEV.VERSION_NUM) ..
			" — some features may not work.\n" )
		spec.core_outdated = true
	end

	-- Load-tracking metadata (Sidekick Phase B1): when and where in the load
	-- sequence this addon registered.
	spec.registered_systime = SysTime()
	spec.registered_at      = os.time()
	spec.registered_order   = ZDEV.FILE._SEQ
	ZDEV.ADON.EVENTS = ZDEV.ADON.EVENTS or {}
	ZDEV.ADON.EVENTS[#ZDEV.ADON.EVENTS + 1] = { id = spec.id, systime = spec.registered_systime }

	ZDEV.ADON.AddAddon( spec.id, spec )

	return ZDEV   -- hand the namespace back so the child can do: local ZDEV = ZDEV.ADON.Register(...)
end

-- Core registers itself so the addon registry always has a root entry for
-- children (and the Sidekick Addons view) to hang off.
ZDEV.ADON.Register( { id = "zdev", name = "ZDEV Core", version = ZDEV.VERSION } )

-- ZDEV_UID: ZDEV_FUNC_B625D863 | Path: ZDEV.FILE.GetAllLoaded
function ZDEV.FILE.GetAllLoaded()
	return table.GetKeys(ZDEV.FILE.INDEX)
end

-- ZDEV_UID: ZDEV_FUNC_FA280C27 | Path: ZDEV.FILE.Loaded
function ZDEV.FILE.Loaded( s_file )
	return tobool(ZDEV.FILE.INDEX[s_file])
end

-- ZDEV_UID: ZDEV_FUNC_A7C35901 | Path: ZDEV.FILE.SetLoaded
-- Records rich load metadata (Sidekick Phase B1). Called as the LAST
-- statement of every ZDEV file, while that file is still the top frame of
-- the include stack — which is what lets us correlate the inconsistent _f
-- header strings with real include paths.
function ZDEV.FILE.SetLoaded( s_file )
	ZDEV.FILE.INDEX[s_file] = true

	local meta = ZDEV.FILE.META[s_file]
	if meta then
		meta.include_count = meta.include_count + 1
		return
	end

	ZDEV.FILE._SEQ = ZDEV.FILE._SEQ + 1
	local stack = ZDEV.FILE._STACK
	local top = stack[#stack]
	local chain
	if top then
		chain = {}
		for i = 1, #stack do chain[i] = stack[i].path end
	end

	meta = {
		order         = ZDEV.FILE._SEQ,
		systime       = SysTime(),
		oclock        = os.time(),
		realm         = SERVER and "SERVER" or "CLIENT",
		include_path  = top and top.path or "(engine)",
		parent        = top and top.parent and top.parent.path or nil,
		chain         = chain,
		duration_ms   = top and math.Round( ( SysTime() - top.t0 ) * 1000, 2 ) or nil,
		include_count = 1,
		generation    = ZDEV.FILE.GENERATION,
	}
	ZDEV.FILE.META[s_file] = meta

	if ZDEV.Sidekick and ZDEV.Sidekick.OnFileLoaded then
		ZDEV.Sidekick.OnFileLoaded( s_file, meta )
	end
end

-- ZDEV_UID: ZDEV_FUNC_RESETTRK1 | Path: ZDEV.FILE.ResetTracking
-- Called alongside INDEX = {} on zdev_reload so the next include pass
-- records a fresh generation of load metadata.
function ZDEV.FILE.ResetTracking()
	ZDEV.FILE.META = {}
	ZDEV.FILE._ATTEMPTS = {}
	ZDEV.FILE._SEQ = 0
	ZDEV.FILE.GENERATION = ZDEV.FILE.GENERATION + 1
end

-- ZDEV_UID: ZDEV_FUNC_FILERPT1 | Path: ZDEV.FILE.PrintReport
-- Console tree of the load order: files sorted by order, indented by include
-- depth, with source include path, per-file timing, and re-include flags.
-- Shared command: run 'zdev_files_report' in the client console for the
-- CLIENT realm; use 'lua_run ZDEV.FILE.PrintReport()' for SERVER on a listen host.
function ZDEV.FILE.PrintReport()
	local rows = {}
	for f, m in pairs( ZDEV.FILE.META ) do
		rows[#rows + 1] = { file = f, m = m }
	end
	table.sort( rows, function( a, b ) return a.m.order < b.m.order end )

	MsgC( Color(255,255,50), "\n■ ZDEV load report — ", color_white,
		( SERVER and "SERVER" or "CLIENT" ) .. " realm, generation " ..
		ZDEV.FILE.GENERATION .. ", " .. #rows .. " files\n" )

	for _, row in ipairs( rows ) do
		local m = row.m
		local depth = m.chain and #m.chain or 0
		MsgC( Color(120,120,120), string.format( "%3d ", m.order ),
			color_white, string.rep( "  ", depth ) .. row.file,
			Color(120,180,255), "  [" .. ( m.include_path or "?" ) .. "]",
			Color(120,255,120), m.duration_ms and string.format( "  %.2fms", m.duration_ms ) or "" )
		if m.include_count > 1 then
			MsgC( Color(255,180,50), "  (loaded " .. m.include_count .. "x)" )
		end
		Msg( "\n" )
	end

	local dupes = {}
	for path, n in pairs( ZDEV.FILE._ATTEMPTS ) do
		if n > 1 then dupes[#dupes + 1] = path .. " (" .. n .. "x)" end
	end
	if #dupes > 0 then
		table.sort( dupes )
		MsgC( Color(255,180,50), "\n■ Multiple include attempts (guard-skipped or re-run):\n" )
		for _, s in ipairs( dupes ) do MsgC( Color(255,180,50), "   " .. s .. "\n" ) end
	end
	Msg( "\n" )
end

concommand.Add( "zdev_files_report", function() ZDEV.FILE.PrintReport() end )

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    COMMAND / CONVAR REGISTRATION (canonical + deprecated aliases)
    Convention (docs/CONVENTIONS.md): zdev_<domain>_<action>. Old names stay
    as aliases that warn once per session, then dispatch to the canonical
    handler. Dispatch goes through _INDEX at call time so zdev_reload
    hot-swaps handlers without re-registering aliases.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
ZDEV.CMDS._INDEX  = ZDEV.CMDS._INDEX  or {}   -- canonical name -> handler
ZDEV.CMDS._WARNED = ZDEV.CMDS._WARNED or {}   -- deprecated name -> true (warned this session)

-- ZDEV_UID: ZDEV_FUNC_CMDWARN1 | Path: ZDEV.CMDS.WarnDeprecated
function ZDEV.CMDS.WarnDeprecated( old, new )
	if ZDEV.CMDS._WARNED[old] then return end
	ZDEV.CMDS._WARNED[old] = true
	MsgC( Color(255,180,50), "[ZDEV] '", Color(255,255,255), old,
		Color(255,180,50), "' is deprecated — use '", Color(255,255,255), new,
		Color(255,180,50), "'.\n" )
end

-- ZDEV_UID: ZDEV_FUNC_CMDREG01 | Path: ZDEV.CMDS.Register
-- opts = { aliases = {"old_name", ...}, help = "", flags = ..., autocomplete = fn }
function ZDEV.CMDS.Register( name, fn, opts )
	opts = opts or {}
	ZDEV.CMDS._INDEX[name] = fn
	concommand.Add( name, function( ... ) return ZDEV.CMDS._INDEX[name]( ... ) end,
		opts.autocomplete, opts.help or "", opts.flags )
	if opts.aliases then
		for _, old in ipairs( opts.aliases ) do
			concommand.Add( old, function( ... )
				ZDEV.CMDS.WarnDeprecated( old, name )
				return ZDEV.CMDS._INDEX[name]( ... )
			end, opts.autocomplete, "DEPRECATED: use " .. name, opts.flags )
		end
	end
end

-- ZDEV_UID: ZDEV_FUNC_CONVLGCY | Path: ZDEV.CONV.LegacyAlias
-- Registers a deprecated alias for an ALREADY-REGISTERED canonical convar:
-- copies a customized legacy value into the canonical var once, then mirrors
-- legacy writes to the canonical var with a one-time deprecation warning.
-- Code must read the canonical name only.
function ZDEV.CONV.LegacyAlias( name, old )
	local cv = GetConVar( name )
	if not cv then return end
	local default = cv:GetDefault()
	local ov = CreateClientConVar( old, default, true, false, "DEPRECATED: use " .. name )
	if ov:GetString() ~= default and cv:GetString() == default then
		cv:SetString( ov:GetString() )
	end
	cvars.AddChangeCallback( old, function( _, _, new )
		ZDEV.CMDS.WarnDeprecated( old, name )
		RunConsoleCommand( name, new )
	end, "zdev_cvar_migrate" )
end

-- ZDEV_UID: ZDEV_FUNC_CONVCL01 | Path: ZDEV.CONV.ClientVar
-- Client convar with optional legacy-name migration (Phase 4 of the sweep).
-- opts = { legacy = "old_name", userinfo = bool }
function ZDEV.CONV.ClientVar( name, default, help, opts )
	local cv = CreateClientConVar( name, default, true, opts and opts.userinfo or false, help or "" )
	if opts and opts.legacy then
		ZDEV.CONV.LegacyAlias( name, opts.legacy )
	end
	return cv
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

	ZDEV.CONV.Create( "zdev_dev", "0", {FCVAR_CHEAT,FCVAR_SERVER_CAN_EXECUTE,FCVAR_PROTECTED}, "Toggle Developer mode for the ZDEV addon.")
	-- Legacy alias (Sweep Phase 4a): writes to zd_dev mirror to zdev_dev with a
	-- one-time warning. Not archived, so no value migration is needed.
	ZDEV.CONV.Create( "zd_dev", "0", {FCVAR_CHEAT,FCVAR_SERVER_CAN_EXECUTE,FCVAR_PROTECTED}, "DEPRECATED: use zdev_dev")
	cvars.AddChangeCallback( "zd_dev", function( _, _, new )
		ZDEV.CMDS.WarnDeprecated( "zd_dev", "zdev_dev" )
		RunConsoleCommand( "zdev_dev", new )
	end, "zdev_cvar_migrate" )


	local b_firstrun = false
	local indx_files = {}
	timer.Create( "zdev_auto_filecheck", 6, 0, function() 

		if !ZDEV then return end
		if !GetConVar( "zdev_dev" ):GetBool() then return end
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

	-- Database config is set above in ZDEV.MSQL.Database.
	-- The actual connection is handled by zd_sv_database.lua (TMysql4).
	-- It reads ZDEV.MSQL.Database and connects automatically on load.
	zdev.log("I", "Database config set. Connection will be established by zd_sv_database.lua")

	--AddCSLuaFile( "zdev/shared.lua" )
	--AddCSLuaFile( "zdev/cl_init.lua" )
	include( "zdev/init.lua" )

	-- Reload all ZDEV files without restarting the map.
	-- Clears the file-loaded index so every guarded include re-runs.
	concommand.Add("zdev_reload", function(ply)
		if IsValid(ply) and not ply:IsAdmin() then
			ply:ChatPrint("[ZDEV] Reload requires admin.")
			return
		end
		ZDEV.FILE.INDEX = {}
		ZDEV.FILE.ResetTracking()
		include("zdev/init.lua")
		net.Start("zdev_reload")
		if IsValid(ply) then net.Send(ply) else net.Broadcast() end
		zdev.log("S", "ZDEV server reload complete.")
	end)
end

if (CLIENT) then 
	
	include( "zd_autorun_debug.lua")
	include( "zd_autorun_enums.lua")
	include( "zd_autorun_util.lua")

	--[[■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	-- CLIENT
	Defines all ZDEV client-side global tables and namespaces

	■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■]]

	ZDEV.VGUI = {}
		ZDEV.VGUI.MENU = {}
		ZDEV.VGUI.DERM = {}
		ZDEV.VGUI.SKIN = {}
		ZDEV.VGUI.HTTP = {}
	ZDEV.CHUD = {}
	ZDEV.REND = {}
	ZDEV.SEFX = {}
	ZDEV.DRAW = {}
	ZDEV.FONT = {}
	-- NOTE: ZDEV.EDIT is created with its full subtable set in the SHARED block
	-- above. Re-assigning `ZDEV.EDIT = {}` here used to wipe ENVM/MATS/NPCS/
	-- ENTS/WEAP on clients — only add what the shared block doesn't have.
	ZDEV.EDIT.PART = ZDEV.EDIT.PART or {}
	ZDEV.EDIT.EMIT = ZDEV.EDIT.EMIT or {}
	--[[■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

		CLIENT CONVARS
	==================================================]]--
	--[[
		zd_cl_autorun.lua
		Client-side autorun script for Garry's Mod addon.
		Author: zcomstudios
		Description: Handles client initialization and setup for the addon.
	]]
	-- Canonicalized (Sweep Phase 4a): zdev_* names are authoritative; the old
	-- zd_* names stay registered as mirroring legacy aliases via ClientVar.
	ZDEV.CONV.ClientVar( "zdev_hud_visor", "1", "Toggle drawing of Visor material overlay texture", { legacy = "zd_hud_visor" } )
	ZDEV.CONV.ClientVar( "zdev_hud_vitals", "1", "Toggle drawing of Health, Armor and other vitals", { legacy = "zd_hud_vitals" } )
	ZDEV.CONV.ClientVar( "zdev_hud_ammo", "1", "Toggle drawing rounds in clip, ammo count, etc", { legacy = "zd_hud_ammo" } )
	ZDEV.CONV.ClientVar( "zdev_hud_crosshair", "1", "Toggle drawing custom crosshair/reticle", { legacy = "zd_hud_crosshair" } )
	ZDEV.CONV.ClientVar( "zdev_hud_info", "1", "Toggle drawing player info in top left HUD", { legacy = "zd_hud_info" } )
	ZDEV.CONV.ClientVar( "zdev_hud_chat", "0", "Toggle drawing chat messages and custom chatbox", { legacy = "zd_hud_chat" } )
	ZDEV.CONV.ClientVar( "zdev_hud_messages", "1", "Toggle drawing HUD messages (info, hints, warnings, announcements)", { legacy = "zd_hud_messages" } )
	ZDEV.CONV.ClientVar( "zdev_hud_markers", "1", "Toggle drawing 3D world markers (entity/position indicators)", { legacy = "zd_hud_markers" } )
	ZDEV.CONV.ClientVar( "zdev_hud_exp", "1", "Toggle drawing experience bar, XP popups, and level-up announcements", { legacy = "zd_hud_exp" } )
	ZDEV.CONV.ClientVar( "zdev_hud_effects", "1", "Toggle drawing custom screen effects", { legacy = "zd_hud_effects" } )
	ZDEV.CONV.ClientVar( "zdev_hud_font_pri", "", "Font-name of the primary font used for large numbers", { legacy = "zd_hud_font_pri" } )
	ZDEV.CONV.ClientVar( "zdev_hud_font_sec", "", "Font-name of the secondary font used for small details", { legacy = "zd_hud_font_sec" } )
	ZDEV.CONV.ClientVar( "zdev_hud_clr_pri", "255 150 0 255", "R G B values for the primary color of the HUD", { legacy = "zd_hud_clr_pri" } )

	ZDEV.CONV.ClientVar( "zdev_hud_clr_sec", "255 150 0 255", "R G B values for the secondary color of the HUD", { legacy = "zd_hud_clr_sec" } )
	ZDEV.CONV.ClientVar( "zdev_hud_xhair_clr", "255 150 0 255", "R G B values for the color of the Crosshair", { legacy = "zd_xhair_clr" } )

	ZDEV.CONV.ClientVar( "zdev_dev_console_x", "100", "Developer Lua-Console X Position", { legacy = "zd_dev_console_x" } )
	ZDEV.CONV.ClientVar( "zdev_dev_console_y", "400", "Developer Lua-Console Y Position", { legacy = "zd_dev_console_y" } )
	ZDEV.CONV.ClientVar( "zdev_dev_console_w", "600", "Developer Lua-Console Width", { legacy = "zd_dev_console_w" } )
	ZDEV.CONV.ClientVar( "zdev_dev_console_h", "200", "Developer Lua-Console Height", { legacy = "zd_dev_console_h" } )

	ZDEV.CONV.ClientVar( "zdev_dev_hud_time", "0", "Toggle drawing global time-function(s) output on the HUD", { legacy = "zd_dev_hud_time" } )
	ZDEV.CONV.ClientVar( "zdev_dev_hud_xhair", "1", "Toggle drawing development crosshair on HUD", { legacy = "zd_dev_hud_xhair" } )
	ZDEV.CONV.ClientVar( "zdev_dev_hud_grid", "1", "Toggle drawing development grid on HUD", { legacy = "zd_dev_hud_grid" } )
	ZDEV.CONV.ClientVar( "zdev_dev_hud_entinfo", "1", "Toggle drawing entity info on HUD", { legacy = "zd_dev_hud_entinfo" } )
	ZDEV.CONV.ClientVar( "zdev_dev_hud_ents", "1", "Toggle drawing tracked entities on HUD", { legacy = "zd_dev_hud_ents" } )

	ZDEV.CONV.ClientVar( "zdev_debug_render", "0", "Toggle debug render overlays", { legacy = "zd_debug_render" } )
	ZDEV.CONV.ClientVar( "zdev_debug_render_entinfo", "0", "Toggle debug render entity info", { legacy = "zd_debug_render_entinfo" } )

	-- zedit_* editor convars + ZDEV.CONV.EditorCallback moved to their owning
	-- feature files (Sweep Phase 3): particle → zd_cl_menu_editor_particle.lua,
	-- env → zdev/shared/zd_sh_editor.lua. Each convar must have exactly ONE
	-- registration point — this autorun copy was first to run, silently
	-- overriding the editors' own defaults.


	--[[ =============================================
		FONTS
	==================================================]]--
	ZDEV.FONT._INDEX  = ZDEV.FONT._INDEX  or {}  -- newname -> fontdata
	ZDEV.FONT._ALIAS  = ZDEV.FONT._ALIAS  or {}  -- newname -> existing cached name (exact dedupe only)
	ZDEV.FONT._WARNED = ZDEV.FONT._WARNED or {}  -- de-noise key -> true

	-- 0=silent, 1=warn on exact dedupe, 2=warn on near-miss too
	CreateClientConVar( "zdev_font_warn_dedupe", "1", true, false,
		"Warn when ZDEV.FONT.Register deduplicates a font. 0=off, 1=exact, 2=near-miss" )

	-- Fields that define font identity. All must match for "exact"; one mismatch = "near".
	local FONT_IDENT_FIELDS = {
		"font", "size", "weight", "antialias", "shadow", "additive",
		"outline", "extended", "scanlines", "blursize",
		"italic", "underline", "strikeout", "symbol", "rotary"
	}

	-- ZDEV_UID: ZDEV_FUNC_30DE908D | Path: ZDEV.FONT.GetFontFiles
	function ZDEV.FONT.GetFontFiles( )
		local f, d = file.Find( "resource/fonts--[[", "THIRDPARTY", "nameasc" )
		--PrintTable( f )
		return f
	end

	-- Compare two font property tables.
	-- Returns: "exact" | "near" | nil, differing_field_name (only meaningful for "near")
	-- ZDEV_UID: ZDEV_FUNC_F0N7M4TC | Path: ZDEV.FONT.PropertiesMatch
	function ZDEV.FONT.PropertiesMatch( a, b )
		if not a or not b then return nil end
		local diffs, diff_field = 0, nil
		for _, k in ipairs( FONT_IDENT_FIELDS ) do
			local av, bv = a[k], b[k]
			-- Normalize booleans: GMod treats nil/false as equivalent for these flags.
			if av == nil or av == false then av = false end
			if bv == nil or bv == false then bv = false end
			if av ~= bv then
				diffs = diffs + 1
				diff_field = diff_field or k
				if diffs > 1 then return nil end
			end
		end
		if diffs == 0 then return "exact" end
		return "near", diff_field
	end

	-- ZDEV_UID: ZDEV_FUNC_29501EC9 | Path: ZDEV.FONT.Register
	function ZDEV.FONT.Register( newname, fontdata )
		if not newname or not fontdata then return end

		local warn_level = GetConVar( "zdev_font_warn_dedupe" )
		warn_level = warn_level and warn_level:GetInt() or 0

		-- Same-name re-register: if properties match exactly, it's a true no-op duplicate.
		-- If they differ, the caller wants to update — fall through to re-create.
		local existing = ZDEV.FONT._INDEX[ newname ]
		if existing and ZDEV.FONT.PropertiesMatch( fontdata, existing ) == "exact" then
			if warn_level >= 1 then
				local key = "self:" .. newname
				if not ZDEV.FONT._WARNED[ key ] then
					ZDEV.FONT._WARNED[ key ] = true
					zdev.log( "W", "Font '" .. newname .. "' re-registered with identical properties — skipped." )
				end
			end
			return
		end

		for cachedName, cachedData in pairs( ZDEV.FONT._INDEX ) do
			if cachedName ~= newname then
				local kind, field = ZDEV.FONT.PropertiesMatch( fontdata, cachedData )

				if kind == "exact" then
					-- Skip surface.CreateFont entirely — saves a font slot.
					ZDEV.FONT._ALIAS[ newname ] = cachedName
					if warn_level >= 1 then
						local key = newname .. "->" .. cachedName
						if not ZDEV.FONT._WARNED[ key ] then
							ZDEV.FONT._WARNED[ key ] = true
							zdev.log( "W", "Font '" .. newname .. "' is a duplicate of '" .. cachedName .. "' — aliased, slot saved." )
						end
					end
					return

				elseif kind == "near" and warn_level >= 2 then
					local key = newname .. "->" .. cachedName .. ":" .. tostring(field)
					if not ZDEV.FONT._WARNED[ key ] then
						ZDEV.FONT._WARNED[ key ] = true
						zdev.log( "W", "Font '" .. newname .. "' is near-identical to '" .. cachedName .. "' (differs only in '" .. tostring(field) .. "') — possible typo?" )
					end
					-- Fall through: still register it. Near-miss is informational only.
				end
			end
		end

		surface.CreateFont( newname, fontdata )
		ZDEV.FONT._INDEX[ newname ] = fontdata
	end

	-- Resolve an alias to its underlying cached font name.
	-- Downstream addons can call this before surface.SetFont if they want alias awareness.
	-- ZDEV_UID: ZDEV_FUNC_F0N7R5LV | Path: ZDEV.FONT.Resolve
	function ZDEV.FONT.Resolve( name )
		return ZDEV.FONT._ALIAS[ name ] or name
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

	-- Receive a server-triggered reload: re-run the full client init chain.
	net.Receive("zdev_reload", function()
		ZDEV.FILE.INDEX = {}
		ZDEV.FILE.ResetTracking()
		include("zdev/cl_init.lua")
		zdev.log("S", "ZDEV client reload complete.")
	end)
end

--timer.Simple( 0, function() include( "autorun/zd_snpcs_autorun.lua") end )

--zdev.log( "S", "Loading file: ../addons/zdev_core/lua/autorun/zd_autorun.lua" )

ZDEV.FILE.SetLoaded( _f )
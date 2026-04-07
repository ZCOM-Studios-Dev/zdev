local _f = 'zdev/client/vgui/zd_cl_menu_editor_particle.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end

local LP = LocalPlayer()
local SW, SH = ScrW(), ScrH()
local CurTime = CurTime
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local tonumber = tonumber
local Vector = Vector
local Color = Color
local math = math
local string = string
local table = table
local file = file
local util = util

ZEDIT = ZEDIT or {}
ZEDIT.FX = ZEDIT.FX or {}

if !ZEDIT.FX.PARTICLE then ZEDIT.FX.PARTICLE = {} end

ZEDIT.FX.SAVE_DIR          = "zdev/sefx/emitters/"
ZEDIT.FX.ACTIVE_EMITTERS   = {}
ZEDIT.FX.PREVIEW_HOOK      = "ZEDIT_ParticlePreview"
ZEDIT.FX.PREVIEW_ENABLED   = false
ZEDIT.FX.PREVIEW_RATE      = 0.1
ZEDIT.FX.LAST_PREVIEW      = 0
ZEDIT.FX.NEXT_PREVIEW_RATE = 0.1

-- Multi-material list (persists across menu opens)
if not ZEDIT.FX.PARTICLE_MATERIALS then
	ZEDIT.FX.PARTICLE_MATERIALS = { "particles/fire1" }
end

-- ─── Existing single-value ConVars (kept for legacy project loading) ───────
CreateClientConVar( "zedit_particle_id",               "particle_01",  true, false, "Particle ID" )
CreateClientConVar( "zedit_particle_mat",              "particles/fire1", true, false, "Particle material (legacy)" )
CreateClientConVar( "zedit_particle_lifetime",         "0.5",  true, false, "Particle lifetime" )
CreateClientConVar( "zedit_particle_dietime",          "1.0",  true, false, "Particle die time" )
CreateClientConVar( "zedit_particle_size_s",           "8",    true, false, "Start size" )
CreateClientConVar( "zedit_particle_size_e",           "2",    true, false, "End size" )
CreateClientConVar( "zedit_particle_alpha_s",          "255",  true, false, "Start alpha" )
CreateClientConVar( "zedit_particle_alpha_e",          "0",    true, false, "End alpha" )
CreateClientConVar( "zedit_particle_length_s",         "0",    true, false, "Start length" )
CreateClientConVar( "zedit_particle_length_e",         "0",    true, false, "End length" )
CreateClientConVar( "zedit_particle_roll",             "0",    true, false, "Roll angle" )
CreateClientConVar( "zedit_particle_rolldelta",        "0",    true, false, "Roll delta" )
CreateClientConVar( "zedit_particle_angles",           "0 0 0",true, false, "Angles" )
CreateClientConVar( "zedit_particle_angular_velocity", "0 0 0",true, false, "Angular velocity" )
CreateClientConVar( "zedit_particle_airres",           "50",   true, false, "Air resistance" )
CreateClientConVar( "zedit_particle_bounce",           "0.5",  true, false, "Bounce" )
CreateClientConVar( "zedit_particle_collide",          "0",    true, false, "Collide" )
CreateClientConVar( "zedit_particle_lighting",         "0",    true, false, "Lighting" )
CreateClientConVar( "zedit_particle_color",            "255 200 100", true, false, "Color" )
CreateClientConVar( "zedit_particle_color_r",          "255",  true, false, "Color R" )
CreateClientConVar( "zedit_particle_color_g",          "200",  true, false, "Color G" )
CreateClientConVar( "zedit_particle_color_b",          "100",  true, false, "Color B" )
CreateClientConVar( "zedit_particle_color_a",          "255",  true, false, "Color A" )
CreateClientConVar( "zedit_particle_gravity",          "0 0 -100", true, false, "Gravity vector" )
CreateClientConVar( "zedit_particle_velocity",         "0 0 50",   true, false, "Velocity vector" )
CreateClientConVar( "zedit_particle_velocity_mul",     "1",    true, false, "Velocity multiplier" )
CreateClientConVar( "zedit_particle_count_min",        "1",    true, false, "Min particle count" )
CreateClientConVar( "zedit_particle_count_max",        "5",    true, false, "Max particle count" )
CreateClientConVar( "zedit_particle_repeat",           "0.1",  true, false, "Repeat rate" )
CreateClientConVar( "zedit_particle_preview",          "0",    true, false, "Preview enabled" )

-- ─── Range min/max ConVars (new — each slider controls a _min and _max) ────
CreateClientConVar( "zedit_particle_lifetime_min",      "0.5",  true, false, "Lifetime min" )
CreateClientConVar( "zedit_particle_lifetime_max",      "0.5",  true, false, "Lifetime max" )
CreateClientConVar( "zedit_particle_dietime_min",       "1.0",  true, false, "Die time min" )
CreateClientConVar( "zedit_particle_dietime_max",       "1.0",  true, false, "Die time max" )
CreateClientConVar( "zedit_particle_size_s_min",        "8",    true, false, "Start size min" )
CreateClientConVar( "zedit_particle_size_s_max",        "8",    true, false, "Start size max" )
CreateClientConVar( "zedit_particle_size_e_min",        "2",    true, false, "End size min" )
CreateClientConVar( "zedit_particle_size_e_max",        "2",    true, false, "End size max" )
CreateClientConVar( "zedit_particle_alpha_s_min",       "255",  true, false, "Start alpha min" )
CreateClientConVar( "zedit_particle_alpha_s_max",       "255",  true, false, "Start alpha max" )
CreateClientConVar( "zedit_particle_alpha_e_min",       "0",    true, false, "End alpha min" )
CreateClientConVar( "zedit_particle_alpha_e_max",       "0",    true, false, "End alpha max" )
CreateClientConVar( "zedit_particle_length_s_min",      "0",    true, false, "Start length min" )
CreateClientConVar( "zedit_particle_length_s_max",      "0",    true, false, "Start length max" )
CreateClientConVar( "zedit_particle_length_e_min",      "0",    true, false, "End length min" )
CreateClientConVar( "zedit_particle_length_e_max",      "0",    true, false, "End length max" )
CreateClientConVar( "zedit_particle_color_r_min",       "255",  true, false, "Color R min" )
CreateClientConVar( "zedit_particle_color_r_max",       "255",  true, false, "Color R max" )
CreateClientConVar( "zedit_particle_color_g_min",       "200",  true, false, "Color G min" )
CreateClientConVar( "zedit_particle_color_g_max",       "200",  true, false, "Color G max" )
CreateClientConVar( "zedit_particle_color_b_min",       "100",  true, false, "Color B min" )
CreateClientConVar( "zedit_particle_color_b_max",       "100",  true, false, "Color B max" )
CreateClientConVar( "zedit_particle_color_a_min",       "255",  true, false, "Color A min" )
CreateClientConVar( "zedit_particle_color_a_max",       "255",  true, false, "Color A max" )
CreateClientConVar( "zedit_particle_roll_min",          "0",    true, false, "Roll min" )
CreateClientConVar( "zedit_particle_roll_max",          "0",    true, false, "Roll max" )
CreateClientConVar( "zedit_particle_rolldelta_min",     "0",    true, false, "Roll delta min" )
CreateClientConVar( "zedit_particle_rolldelta_max",     "0",    true, false, "Roll delta max" )
CreateClientConVar( "zedit_particle_airres_min",        "50",   true, false, "Air resistance min" )
CreateClientConVar( "zedit_particle_airres_max",        "50",   true, false, "Air resistance max" )
CreateClientConVar( "zedit_particle_bounce_min",        "0.5",  true, false, "Bounce min" )
CreateClientConVar( "zedit_particle_bounce_max",        "0.5",  true, false, "Bounce max" )
CreateClientConVar( "zedit_particle_velocity_mul_min",  "1",    true, false, "Velocity mul min" )
CreateClientConVar( "zedit_particle_velocity_mul_max",  "1",    true, false, "Velocity mul max" )
CreateClientConVar( "zedit_particle_repeat_min",        "0.1",  true, false, "Repeat rate min" )
CreateClientConVar( "zedit_particle_repeat_max",        "0.1",  true, false, "Repeat rate max" )

-- ─── Project data ────────────────────────────────────────────────────────────
ZEDIT.FX.PROJECTS = {
	Name     = "NewProject",
	Filename = "zedit_particle_new.txt",
	Author   = "Author Name",
	Particles = {},
	Emitters  = {}
}

ZEDIT.FX.CurrentProject = {
	Name      = "Untitled",
	Filename  = "untitled.json",
	Author    = "Unknown",
	Particles = {},
	LastSave  = 0
}

function ZEDIT.FX.NewProject( name )
	ZEDIT.FX.CurrentProject = {
		Name     = name or "Untitled",
		Filename = string.lower(string.gsub(name or "untitled", " ", "_")) .. ".json",
		Author   = "Unknown",
		Particles = {},
		LastSave = 0
	}
	zdev.log( "S", "Created new particle project: " .. ZEDIT.FX.CurrentProject.Name )
end

-- ─── ConVar accessors ────────────────────────────────────────────────────────
function ZEDIT.FX.GetConVars()
	return {
		id       = GetConVarString( "zedit_particle_id" ),
		-- Multi-material list (copied so saves are independent snapshots)
		materials = table.Copy( ZEDIT.FX.PARTICLE_MATERIALS ),
		-- Legacy single-material key kept for backward compat
		material  = GetConVarString( "zedit_particle_mat" ),

		-- Spawn / timing
		count_min       = GetConVarNumber( "zedit_particle_count_min" ),
		count_max       = GetConVarNumber( "zedit_particle_count_max" ),
		repeat_min      = GetConVar( "zedit_particle_repeat_min" ):GetFloat(),
		repeat_max      = GetConVar( "zedit_particle_repeat_max" ):GetFloat(),
		lifetime_min    = GetConVar( "zedit_particle_lifetime_min" ):GetFloat(),
		lifetime_max    = GetConVar( "zedit_particle_lifetime_max" ):GetFloat(),
		dietime_min     = GetConVar( "zedit_particle_dietime_min" ):GetFloat(),
		dietime_max     = GetConVar( "zedit_particle_dietime_max" ):GetFloat(),

		-- Size
		size_s_min      = GetConVarNumber( "zedit_particle_size_s_min" ),
		size_s_max      = GetConVarNumber( "zedit_particle_size_s_max" ),
		size_e_min      = GetConVarNumber( "zedit_particle_size_e_min" ),
		size_e_max      = GetConVarNumber( "zedit_particle_size_e_max" ),
		length_s_min    = GetConVarNumber( "zedit_particle_length_s_min" ),
		length_s_max    = GetConVarNumber( "zedit_particle_length_s_max" ),
		length_e_min    = GetConVarNumber( "zedit_particle_length_e_min" ),
		length_e_max    = GetConVarNumber( "zedit_particle_length_e_max" ),

		-- Alpha
		alpha_s_min     = GetConVarNumber( "zedit_particle_alpha_s_min" ),
		alpha_s_max     = GetConVarNumber( "zedit_particle_alpha_s_max" ),
		alpha_e_min     = GetConVarNumber( "zedit_particle_alpha_e_min" ),
		alpha_e_max     = GetConVarNumber( "zedit_particle_alpha_e_max" ),

		-- Color
		color_r_min     = GetConVarNumber( "zedit_particle_color_r_min" ),
		color_r_max     = GetConVarNumber( "zedit_particle_color_r_max" ),
		color_g_min     = GetConVarNumber( "zedit_particle_color_g_min" ),
		color_g_max     = GetConVarNumber( "zedit_particle_color_g_max" ),
		color_b_min     = GetConVarNumber( "zedit_particle_color_b_min" ),
		color_b_max     = GetConVarNumber( "zedit_particle_color_b_max" ),
		color_a_min     = GetConVarNumber( "zedit_particle_color_a_min" ),
		color_a_max     = GetConVarNumber( "zedit_particle_color_a_max" ),

		-- Rotation
		roll_min        = GetConVarNumber( "zedit_particle_roll_min" ),
		roll_max        = GetConVarNumber( "zedit_particle_roll_max" ),
		rolldelta_min   = GetConVarNumber( "zedit_particle_rolldelta_min" ),
		rolldelta_max   = GetConVarNumber( "zedit_particle_rolldelta_max" ),
		angles          = GetConVarString( "zedit_particle_angles" ),
		ang_velocity    = GetConVarString( "zedit_particle_angular_velocity" ),

		-- Physics
		airres_min      = GetConVarNumber( "zedit_particle_airres_min" ),
		airres_max      = GetConVarNumber( "zedit_particle_airres_max" ),
		bounce_min      = GetConVar( "zedit_particle_bounce_min" ):GetFloat(),
		bounce_max      = GetConVar( "zedit_particle_bounce_max" ):GetFloat(),
		collide         = GetConVar( "zedit_particle_collide" ):GetBool(),
		lighting        = GetConVar( "zedit_particle_lighting" ):GetBool(),
		gravity         = GetConVarString( "zedit_particle_gravity" ),
		velocity        = GetConVarString( "zedit_particle_velocity" ),
		velocity_mul_min = GetConVarNumber( "zedit_particle_velocity_mul_min" ),
		velocity_mul_max = GetConVarNumber( "zedit_particle_velocity_mul_max" ),
	}
end

function ZEDIT.FX.SetConVars( data )
	if not data then return end
	-- Materials: update global list rather than a convar
	if data.materials and type( data.materials ) == "table" then
		ZEDIT.FX.PARTICLE_MATERIALS = table.Copy( data.materials )
	end
	for k, v in pairs( data ) do
		if k ~= "materials" then
			local cvar = GetConVar( "zedit_particle_" .. k )
			if cvar then RunConsoleCommand( "zedit_particle_" .. k, tostring(v) ) end
		end
	end
end

-- ─── Particle list management ────────────────────────────────────────────────
function ZEDIT.FX.NewParticle( menu, id, data )
	data.id = id or "particle_" .. #ZEDIT.FX.CurrentProject.Particles + 1
	ZEDIT.FX.CurrentProject.Particles[ #ZEDIT.FX.CurrentProject.Particles + 1 ] = data
	if menu and menu.Particles then menu.Particles[ id ] = data end
	zdev.log( "S", "Added particle: " .. data.id )
end

function ZEDIT.FX.RemoveParticle( index )
	if ZEDIT.FX.CurrentProject.Particles[ index ] then
		local id = ZEDIT.FX.CurrentProject.Particles[ index ].id
		table.remove( ZEDIT.FX.CurrentProject.Particles, index )
		zdev.log( "I", "Removed particle: " .. tostring(id) )
	end
end

function ZEDIT.FX.DuplicateParticle( index )
	local p = ZEDIT.FX.CurrentProject.Particles[ index ]
	if p then
		local dup = table.Copy( p )
		dup.id = p.id .. "_copy"
		ZEDIT.FX.CurrentProject.Particles[ #ZEDIT.FX.CurrentProject.Particles + 1 ] = dup
		zdev.log( "S", "Duplicated particle: " .. dup.id )
	end
end

-- ─── File operations ─────────────────────────────────────────────────────────
function ZEDIT.FX.EnsureDirectory()
	if not file.Exists( ZEDIT.FX.SAVE_DIR, "DATA" ) then
		file.CreateDir( ZEDIT.FX.SAVE_DIR )
	end
end

function ZEDIT.FX.SaveProject( filename )
	ZEDIT.FX.EnsureDirectory()
	filename = filename or ZEDIT.FX.CurrentProject.Filename
	if not string.EndsWith( filename, ".json" ) then filename = filename .. ".json" end

	local data = {
		Name      = ZEDIT.FX.CurrentProject.Name,
		Author    = ZEDIT.FX.CurrentProject.Author,
		Particles = ZEDIT.FX.CurrentProject.Particles,
		SaveTime  = os.time()
	}

	local json = util.TableToJSON( data, true )
	file.Write( ZEDIT.FX.SAVE_DIR .. filename, json )
	ZEDIT.FX.CurrentProject.Filename = filename
	ZEDIT.FX.CurrentProject.LastSave = CurTime()
	zdev.log( "S", "Saved project: " .. filename )
	return true
end

function ZEDIT.FX.LoadProject( filename )
	if not file.Exists( ZEDIT.FX.SAVE_DIR .. filename, "DATA" ) then
		zdev.log( "F", "File not found: " .. filename )
		return false
	end

	local json = file.Read( ZEDIT.FX.SAVE_DIR .. filename, "DATA" )
	local data = util.JSONToTable( json )

	if data then
		ZEDIT.FX.CurrentProject = {
			Name      = data.Name   or "Loaded",
			Filename  = filename,
			Author    = data.Author or "Unknown",
			Particles = data.Particles or {},
			LastSave  = CurTime()
		}
		zdev.log( "S", "Loaded project: " .. filename )
		return true
	end
	return false
end

function ZEDIT.FX.GetSavedFiles()
	ZEDIT.FX.EnsureDirectory()
	local files = file.Find( ZEDIT.FX.SAVE_DIR .. "*.json", "DATA" )
	return files or {}
end

function ZEDIT.FX.DeleteProject( filename )
	if file.Exists( ZEDIT.FX.SAVE_DIR .. filename, "DATA" ) then
		file.Delete( ZEDIT.FX.SAVE_DIR .. filename )
		zdev.log( "I", "Deleted project: " .. filename )
		return true
	end
	return false
end

function ZEDIT.FX.ExportToClipboard()
	local json = util.TableToJSON( ZEDIT.FX.CurrentProject, true )
	SetClipboardText( json )
	zdev.log( "S", "Exported project to clipboard" )
end

function ZEDIT.FX.ImportFromText( text )
	local data = util.JSONToTable( text )
	if data then
		ZEDIT.FX.CurrentProject = {
			Name      = data.Name   or "Imported",
			Filename  = "imported_" .. os.time() .. ".json",
			Author    = data.Author or "Unknown",
			Particles = data.Particles or {},
			LastSave  = 0
		}
		zdev.log( "S", "Imported project from text" )
		return true
	end
	zdev.log( "F", "Failed to parse import data" )
	return false
end

-- ─── Spawn / preview ─────────────────────────────────────────────────────────

-- Helper: return a random value in [vmin, vmax]; fall back to `legacy` if both nil.
local function rv( vmin, vmax, legacy )
	vmin = vmin or legacy or 0
	vmax = vmax or legacy or vmin
	if vmin == vmax then return vmin end
	return math.Rand( math.min(vmin,vmax), math.max(vmin,vmax) )
end

function ZEDIT.FX.SpawnParticle( pos, data )
	local emitter = ParticleEmitter( pos )
	if not emitter then return end

	-- Material: prefer the multi-material table, fall back to legacy single string
	local mats = data.materials
	local mat
	if mats and #mats > 0 then
		mat = mats[ math.random( 1, #mats ) ]
	else
		mat = data.material or "particles/fire1"
	end

	local count = math.random(
		math.max( 1, data.count_min or 1 ),
		math.max( 1, data.count_max or data.count_min or 1 )
	)

	local vel_parts  = string.Explode( " ", data.velocity or "0 0 50" )
	local grav_parts = string.Explode( " ", data.gravity  or "0 0 -100" )
	local v_vel  = Vector( tonumber(vel_parts[1])  or 0, tonumber(vel_parts[2])  or 0, tonumber(vel_parts[3])  or 50 )
	local v_grav = Vector( tonumber(grav_parts[1]) or 0, tonumber(grav_parts[2]) or 0, tonumber(grav_parts[3]) or -100 )

	for _ = 1, count do
		local p = emitter:Add( mat, pos + VectorRand() * 2 )
		if p then
			p:SetLifeTime(     0 )
			p:SetDieTime(      rv( data.dietime_min,     data.dietime_max,     data.dietime     ) )
			p:SetStartSize(    rv( data.size_s_min,      data.size_s_max,      data.start_size  ) )
			p:SetEndSize(      rv( data.size_e_min,      data.size_e_max,      data.end_size    ) )
			p:SetStartAlpha(   rv( data.alpha_s_min,     data.alpha_s_max,     data.start_alpha ) )
			p:SetEndAlpha(     rv( data.alpha_e_min,     data.alpha_e_max,     data.end_alpha   ) )
			p:SetStartLength(  rv( data.length_s_min,    data.length_s_max,    data.start_length) )
			p:SetEndLength(    rv( data.length_e_min,    data.length_e_max,    data.end_length  ) )
			p:SetRoll(      math.rad( rv( data.roll_min,      data.roll_max,      data.roll      ) ) )
			p:SetRollDelta( math.rad( rv( data.rolldelta_min, data.rolldelta_max, data.rolldelta ) ) )
			p:SetAirResistance( rv( data.airres_min, data.airres_max, data.airres ) )
			p:SetBounce(        rv( data.bounce_min, data.bounce_max, data.bounce ) )
			p:SetCollide(  data.collide  or false )
			p:SetLighting( data.lighting or false )
			p:SetColor(
				math.Clamp( math.Round( rv( data.color_r_min, data.color_r_max, data.color_r ) ), 0, 255 ),
				math.Clamp( math.Round( rv( data.color_g_min, data.color_g_max, data.color_g ) ), 0, 255 ),
				math.Clamp( math.Round( rv( data.color_b_min, data.color_b_max, data.color_b ) ), 0, 255 )
			)
			p:SetGravity( v_grav )
			p:SetVelocity( (v_vel + VectorRand() * 10) * rv( data.velocity_mul_min, data.velocity_mul_max, data.velocity_mul ) )
		end
	end

	emitter:Finish()
end

function ZEDIT.FX.StartPreview()
	ZEDIT.FX.PREVIEW_ENABLED = true
	hook.Add( "Think", ZEDIT.FX.PREVIEW_HOOK, function()
		if not ZEDIT.FX.PREVIEW_ENABLED then return end
		if CurTime() - ZEDIT.FX.LAST_PREVIEW < ZEDIT.FX.NEXT_PREVIEW_RATE then return end
		ZEDIT.FX.LAST_PREVIEW = CurTime()

		-- Randomise the *next* interval so repeat-rate ranges create burst patterns
		local cv_rmin = GetConVar( "zedit_particle_repeat_min" )
		local cv_rmax = GetConVar( "zedit_particle_repeat_max" )
		if cv_rmin and cv_rmax then
			local rmin, rmax = cv_rmin:GetFloat(), cv_rmax:GetFloat()
			ZEDIT.FX.NEXT_PREVIEW_RATE = (rmin == rmax) and rmin or math.Rand( math.min(rmin,rmax), math.max(rmin,rmax) )
		else
			ZEDIT.FX.NEXT_PREVIEW_RATE = GetConVar( "zedit_particle_repeat" ):GetFloat()
		end

		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		local tr  = ply:GetEyeTrace()
		local pos = tr.HitPos + tr.HitNormal * 8
		ZEDIT.FX.SpawnParticle( pos, ZEDIT.FX.GetConVars() )
	end )
	zdev.log( "S", "Preview started" )
end

function ZEDIT.FX.StopPreview()
	ZEDIT.FX.PREVIEW_ENABLED = false
	hook.Remove( "Think", ZEDIT.FX.PREVIEW_HOOK )
	zdev.log( "I", "Preview stopped" )
end

function ZEDIT.FX.SpawnOnce()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	local tr  = ply:GetEyeTrace()
	ZEDIT.FX.SpawnParticle( tr.HitPos + tr.HitNormal * 8, ZEDIT.FX.GetConVars() )
end

function ZEDIT.FX.SpawnAll()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	local tr  = ply:GetEyeTrace()
	local pos = tr.HitPos + tr.HitNormal * 8
	for _, data in ipairs( ZEDIT.FX.CurrentProject.Particles ) do
		ZEDIT.FX.SpawnParticle( pos, data )
	end
end

-- ─────────────────────────────────────────────────────────────────────────────
--  ZD_RangeSlider  —  dual-handle range slider for DForm
--  CreateRangeSlider( parent_form, label, cvar_min, cvar_max,
--                     range_min, range_max, decimals )
--  Returns a DPanel sized 62px tall; add it with form:AddItem(pnl).
-- ─────────────────────────────────────────────────────────────────────────────
local function CreateRangeSlider( parent_form, label, cvar_min_name, cvar_max_name, range_min, range_max, decimals )
	decimals = decimals or 0

	-- Layout constants
	local PAD      = 6
	local LABEL_H  = 15
	local TRACK_Y  = LABEL_H + 5   -- top of handle region
	local HANDLE_W = 10
	local HANDLE_H = 20
	local TRACK_H  = 6
	local ENTRY_Y  = TRACK_Y + HANDLE_H + 4
	local ENTRY_H  = 16
	local TOTAL_H  = ENTRY_Y + ENTRY_H + 4   -- 64 px

	-- Live state (upvalues shared between Paint, input handlers, Think)
	local val_min     = GetConVar( cvar_min_name ):GetFloat()
	local val_max     = GetConVar( cvar_max_name ):GetFloat()
	local dragging    = nil   -- "min" | "max" | "tie" | nil
	local drag_start  = nil   -- x at mouse-down (tie-break)
	local hover_h     = nil   -- "min" | "max" | nil

	local te_min, te_max  -- forward refs; set after panel creation

	-- Helpers
	local function fmt( v ) return string.format( "%." .. decimals .. "f", v ) end

	local function val_to_x( v, w )
		local tw = w - PAD * 2 - HANDLE_W
		return PAD + HANDLE_W * 0.5 + ( v - range_min ) / ( range_max - range_min ) * tw
	end

	local function x_to_val( x, w )
		local tw = w - PAD * 2 - HANDLE_W
		local t  = math.Clamp( ( x - PAD - HANDLE_W * 0.5 ) / tw, 0, 1 )
		local v  = range_min + t * ( range_max - range_min )
		return decimals == 0 and math.Round(v) or ( math.Round( v * 10^decimals ) / 10^decimals )
	end

	local function set_min( v )
		v     = math.Clamp( v, range_min, val_max )
		if decimals == 0 then v = math.Round(v) end
		val_min = v
		RunConsoleCommand( cvar_min_name, tostring(v) )
		if IsValid(te_min) then te_min:SetValue( fmt(v) ) end
	end

	local function set_max( v )
		v     = math.Clamp( v, val_min, range_max )
		if decimals == 0 then v = math.Round(v) end
		val_max = v
		RunConsoleCommand( cvar_max_name, tostring(v) )
		if IsValid(te_max) then te_max:SetValue( fmt(v) ) end
	end

	-- ── Panel ──
	local pnl = vgui.Create( "DPanel", parent_form )
	pnl:SetTall( TOTAL_H )

	pnl.Paint = function( self, w, h )
		draw.RoundedBox( 3, 0, 0, w, h, Color( 28, 30, 40, 220 ) )

		-- Label
		draw.SimpleText( label, "DermaDefault", PAD, 2, color_white )

		-- Track background
		local tx  = PAD + HANDLE_W * 0.5
		local tw  = w - PAD * 2 - HANDLE_W
		local ty  = TRACK_Y + math.floor( (HANDLE_H - TRACK_H) * 0.5 )
		draw.RoundedBox( 2, tx, ty, tw, TRACK_H, Color( 18, 18, 28, 255 ) )

		-- Filled region between handles
		local xlo = val_to_x( val_min, w )
		local xhi = val_to_x( val_max, w )
		local fw  = xhi - xlo

		if fw > 1 then
			-- Two-tone gradient: green (min) → red (max)
			local half = math.max( 1, fw * 0.5 )
			surface.SetDrawColor( 50,  200,  80, 210 )
			surface.DrawRect( xlo, ty, half, TRACK_H )
			surface.SetDrawColor( 210,  70,  50, 210 )
			surface.DrawRect( xlo + half, ty, fw - half, TRACK_H )
		elseif fw == 0 then
			-- Coincident tick
			surface.SetDrawColor( 255, 230, 80, 220 )
			surface.DrawRect( xlo - 1, ty - 2, 2, TRACK_H + 4 )
		end

		-- Min handle (green)
		local xm  = xlo - HANDLE_W * 0.5
		local clr_min = ( hover_h == "min" or dragging == "min" ) and Color( 90, 255, 110 ) or Color( 50, 195, 80 )
		draw.RoundedBox( 2, xm, TRACK_Y, HANDLE_W, HANDLE_H, clr_min )

		-- Max handle (red)
		local xM  = xhi - HANDLE_W * 0.5
		local clr_max = ( hover_h == "max" or dragging == "max" ) and Color( 255,  90, 80 ) or Color( 195,  55, 50 )
		draw.RoundedBox( 2, xM, TRACK_Y, HANDLE_W, HANDLE_H, clr_max )
	end

	pnl.OnMousePressed = function( self, btn )
		if btn ~= MOUSE_LEFT then return end
		local mx, my = self:CursorPos()
		local w = self:GetWide()

		-- Only respond within handle row
		if my < TRACK_Y or my > TRACK_Y + HANDLE_H then return end

		local xlo  = val_to_x( val_min, w )
		local xhi  = val_to_x( val_max, w )
		local near_min = math.abs( mx - xlo ) <= HANDLE_W + 2
		local near_max = math.abs( mx - xhi ) <= HANDLE_W + 2

		if near_min and near_max then
			-- Coincident — use directional tie-breaking (Option B)
			dragging   = "tie"
			drag_start = mx
		elseif near_min then
			dragging = "min"
		elseif near_max then
			dragging = "max"
		else
			-- Click on track: snap nearest handle to cursor
			if math.abs( mx - xlo ) <= math.abs( mx - xhi ) then
				dragging = "min"
			else
				dragging = "max"
			end
		end

		self:MouseCapture( true )
	end

	pnl.OnMouseReleased = function( self, btn )
		if btn ~= MOUSE_LEFT then return end
		dragging   = nil
		drag_start = nil
		self:MouseCapture( false )
	end

	pnl.OnCursorMoved = function( self, mx, my )
		local w = self:GetWide()

		-- Resolve tie-break: 2 px of directional intent
		if dragging == "tie" and drag_start then
			if math.abs( mx - drag_start ) > 2 then
				dragging = ( mx < drag_start ) and "min" or "max"
			end
		end

		-- Hover
		local xlo = val_to_x( val_min, w )
		local xhi = val_to_x( val_max, w )
		if my >= TRACK_Y and my <= TRACK_Y + HANDLE_H then
			if math.abs( mx - xlo ) <= HANDLE_W + 2 then hover_h = "min"
			elseif math.abs( mx - xhi ) <= HANDLE_W + 2 then hover_h = "max"
			else hover_h = nil end
		else
			hover_h = nil
		end

		-- Drag
		if dragging == "min" then
			set_min( x_to_val( mx, w ) )
		elseif dragging == "max" then
			set_max( x_to_val( mx, w ) )
		end
	end

	-- Sync from ConVar when changed externally (e.g. console, SetConVars)
	pnl.Think = function( self )
		local cv_lo = GetConVar( cvar_min_name )
		local cv_hi = GetConVar( cvar_max_name )
		if not cv_lo or not cv_hi then return end
		local nlo, nhi = cv_lo:GetFloat(), cv_hi:GetFloat()
		if nlo ~= val_min then
			val_min = nlo
			if IsValid(te_min) then te_min:SetValue( fmt(nlo) ) end
		end
		if nhi ~= val_max then
			val_max = nhi
			if IsValid(te_max) then te_max:SetValue( fmt(nhi) ) end
		end
	end

	-- Reposition text entries when the DForm sets our width
	pnl.PerformLayout = function( self, w, h )
		if IsValid(te_min) then te_min:SetPos( PAD, ENTRY_Y ) ; te_min:SetSize( 54, ENTRY_H ) end
		if IsValid(te_max) then te_max:SetPos( w - PAD - 54, ENTRY_Y ) ; te_max:SetSize( 54, ENTRY_H ) end
	end

	-- ── Text entries (created after pnl so closures can reference them) ──
	te_min = vgui.Create( "DTextEntry", pnl )
	te_min:SetPos( PAD, ENTRY_Y )
	te_min:SetSize( 54, ENTRY_H )
	te_min:SetValue( fmt( val_min ) )
	te_min:SetNumeric( true )
	te_min.OnEnter = function( self )
		set_min( tonumber( self:GetValue() ) or val_min )
		self:SetValue( fmt( val_min ) )
	end
	te_min.OnLoseFocus = te_min.OnEnter

	te_max = vgui.Create( "DTextEntry", pnl )
	te_max:SetPos( 200, ENTRY_Y )   -- placeholder; PerformLayout will correct this
	te_max:SetSize( 54, ENTRY_H )
	te_max:SetValue( fmt( val_max ) )
	te_max:SetNumeric( true )
	te_max.OnEnter = function( self )
		set_max( tonumber( self:GetValue() ) or val_max )
		self:SetValue( fmt( val_max ) )
	end
	te_max.OnLoseFocus = te_max.OnEnter

	return pnl
end


-- ─────────────────────────────────────────────────────────────────────────────
--  ZDEV_UID: ZDEV_FUNC_600762EB | Path: ZDEV.VGUI.ParticleEditor
-- ─────────────────────────────────────────────────────────────────────────────
function ZDEV.VGUI.ParticleEditor( ply, cmd, arg )

	local W, H = SW * 0.3, SH * 0.95
	local menu = ZDEV.VGUI.CreateFrame( W, H, "ZDEV - Particle Emitter Editor" )
	menu:SetPos( 0, 0 )

	menu.Particles = ZEDIT.FX.CurrentProject.Particles

	local function RefreshParticleList()
		if not IsValid( menu.lv ) then return end
		menu.lv:Clear()
		for i, p in ipairs( ZEDIT.FX.CurrentProject.Particles ) do
			local mat_str
			local mats = p.materials
			if mats and #mats > 0 then
				mat_str = #mats > 1 and ( "x" .. #mats .. " mats" ) or mats[1]
			else
				mat_str = p.material or "(none)"
			end
			menu.lv:AddLine( i, p.id, mat_str, p.dietime_min or p.dietime or 1, p.size_s_min or p.start_size or 8 )
		end
	end

	-- ── Menu bar ─────────────────────────────────────────────────────────────
	menu.mb = vgui.Create( "DMenuBar", menu )
	menu.mb:DockMargin( 2, 2, 2, 0 )

	menu.mb.m1 = menu.mb:AddMenu( "File" )
	menu.mb.m1:AddOption( "New Project", function()
		Derma_StringRequest( "New Project", "Enter project name:", "NewEmitter", function(txt)
			ZEDIT.FX.NewProject( txt )
			RefreshParticleList()
		end )
	end ):SetIcon( "icon16/page_white_add.png" )
	menu.mb.m1:AddOption( "Open", function()
		local files = ZEDIT.FX.GetSavedFiles()
		local dm = DermaMenu()
		for _, f in ipairs( files ) do
			dm:AddOption( f, function()
				ZEDIT.FX.LoadProject( f )
				RefreshParticleList()
			end ):SetIcon( "icon16/page_white_text.png" )
		end
		dm:Open()
	end ):SetIcon( "icon16/folder.png" )
	menu.mb.m1:AddOption( "Save",     function() ZEDIT.FX.SaveProject() end ):SetIcon( "icon16/disk.png" )
	menu.mb.m1:AddOption( "Save As…", function()
		Derma_StringRequest( "Save As", "Enter filename:", ZEDIT.FX.CurrentProject.Filename, function(txt)
			ZEDIT.FX.SaveProject( txt )
		end )
	end ):SetIcon( "icon16/page_save.png" )
	menu.mb.m1:AddSpacer()
	menu.mb.m1:AddOption( "Export to Clipboard", function() ZEDIT.FX.ExportToClipboard() end ):SetIcon( "icon16/page_copy.png" )
	menu.mb.m1:AddOption( "Import from Text…", function()
		local f  = ZDEV.VGUI.CreateFrame( SW*0.4, SH*0.3, "Import JSON" )
		local te = vgui.Create( "DTextEntry", f )
		te:Dock( FILL ) ; te:SetMultiline( true ) ; te:SetPlaceholderText( "Paste JSON data here…" )
		local btn = ZDEV.VGUI.CreateButton( f, 100, 28, "IMPORT", "raj", Color(100,255,100), function()
			if ZEDIT.FX.ImportFromText( te:GetValue() ) then RefreshParticleList() ; f:Close() end
		end )
		btn:Dock( BOTTOM )
	end ):SetIcon( "icon16/page_paste.png" )
	menu.mb.m1:AddSpacer()
	menu.mb.m1:AddOption( "Close", function() menu:Close() end ):SetIcon( "icon16/cross.png" )

	menu.mb.m2 = menu.mb:AddMenu( "Edit" )
	menu.mb.m2:AddOption( "Add Particle", function()
		ZEDIT.FX.NewParticle( menu, ZEDIT.FX.GetConVars().id, ZEDIT.FX.GetConVars() )
		RefreshParticleList()
	end ):SetIcon( "icon16/add.png" )
	menu.mb.m2:AddOption( "Clear All Particles", function()
		Derma_Query( "Clear all particles?", "Confirm", "Yes", function()
			ZEDIT.FX.CurrentProject.Particles = {}
			RefreshParticleList()
		end, "No" )
	end ):SetIcon( "icon16/bin.png" )

	menu.mb.m3 = menu.mb:AddMenu( "Spawn" )
	menu.mb.m3:AddOption( "Spawn Current",        function() ZEDIT.FX.SpawnOnce()    end ):SetIcon( "icon16/wand.png" )
	menu.mb.m3:AddOption( "Spawn All Particles",  function() ZEDIT.FX.SpawnAll()     end ):SetIcon( "icon16/lightning.png" )
	menu.mb.m3:AddSpacer()
	menu.mb.m3:AddOption( "Start Preview Loop",   function() ZEDIT.FX.StartPreview() end ):SetIcon( "icon16/control_play_blue.png" )
	menu.mb.m3:AddOption( "Stop Preview",         function() ZEDIT.FX.StopPreview()  end ):SetIcon( "icon16/control_stop_blue.png" )

	-- ── Info bar ─────────────────────────────────────────────────────────────
	menu.pn_info = vgui.Create( "DPanel", menu )
	menu.pn_info:Dock( TOP )
	menu.pn_info:SetTall( 40 )
	menu.pn_info:DockMargin( 2, 2, 2, 2 )
	menu.pn_info.Paint = function( self, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, Color( 40, 45, 55, 255 ) )
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 1, Color( 80, 120, 180, 255 ) )
		draw.SimpleText( "Project: " .. ZEDIT.FX.CurrentProject.Name, "DermaDefaultBold", 8, 8, color_white )
		draw.SimpleText( "Particles: " .. #ZEDIT.FX.CurrentProject.Particles, "DermaDefault", 8, 22, Color(180,180,180) )
		local status = ZEDIT.FX.PREVIEW_ENABLED and "LIVE" or "STOPPED"
		local clr    = ZEDIT.FX.PREVIEW_ENABLED and Color(100,255,100) or Color(150,150,150)
		draw.SimpleText( "Preview: " .. status, "DermaDefaultBold", w - 100, 14, clr )
	end

	-- ── Toolbar ───────────────────────────────────────────────────────────────
	menu.pn = vgui.Create( "DPanel", menu )
	menu.pn:Dock( TOP ) ; menu.pn:SetTall( 32 ) ; menu.pn:DockMargin( 2, 0, 2, 2 )
	menu.pn.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color( 50, 55, 65, 255 ) ) end

	local function tb_btn( text, clr, fn )
		local b = ZDEV.VGUI.CreateButton( menu.pn, 64, 28, text, "raj", clr, fn )
		b:Dock( LEFT ) ; b:DockMargin( 2, 2, 2, 2 )
		return b
	end

	tb_btn( "ADD",   Color(100,255,100), function() ZEDIT.FX.NewParticle( menu, ZEDIT.FX.GetConVars().id, ZEDIT.FX.GetConVars() ) ; RefreshParticleList() end )
	tb_btn( "SPAWN", Color(100,200,255), function() ZEDIT.FX.SpawnOnce() end )
	tb_btn( "LOOP",  Color(255,200,100), function()
		if ZEDIT.FX.PREVIEW_ENABLED then ZEDIT.FX.StopPreview() else ZEDIT.FX.StartPreview() end
	end )
	local btn_save = ZDEV.VGUI.CreateButton( menu.pn, 64, 28, "SAVE", "raj", Color(255,150,100), function() ZEDIT.FX.SaveProject() end )
	btn_save:Dock( RIGHT ) ; btn_save:DockMargin( 2, 2, 2, 2 )

	-- ── Particle list ─────────────────────────────────────────────────────────
	menu.lv_pnl = vgui.Create( "DPanel", menu )
	menu.lv_pnl:Dock( TOP ) ; menu.lv_pnl:SetTall( H * 0.15 ) ; menu.lv_pnl:DockMargin( 2, 0, 2, 2 )
	menu.lv_pnl.Paint = function( self, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, Color( 35, 40, 50, 255 ) )
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 1, Color( 60, 100, 150, 255 ) )
	end

	menu.lv = vgui.Create( "DListView", menu.lv_pnl )
	menu.lv:Dock( FILL ) ; menu.lv:DockMargin( 2, 2, 2, 2 ) ; menu.lv:SetMultiSelect( false )
	menu.lv:AddColumn( "#"        ):SetWidth( 25 )
	menu.lv:AddColumn( "ID"       ):SetWidth( 80 )
	menu.lv:AddColumn( "Material" ):SetWidth( 100 )
	menu.lv:AddColumn( "DieTime"  ):SetWidth( 50 )
	menu.lv:AddColumn( "Size"     ):SetWidth( 40 )

	menu.lv.OnRowSelected = function( lst, index )
		local p = ZEDIT.FX.CurrentProject.Particles[ index ]
		if p then ZEDIT.FX.SetConVars( p ) end
	end

	menu.lv.OnRowRightClick = function( lst, index )
		local dm = DermaMenu()
		dm:AddOption( "Edit", function()
			local p = ZEDIT.FX.CurrentProject.Particles[ index ]
			if p then ZEDIT.FX.SetConVars( p ) end
		end ):SetIcon( "icon16/pencil.png" )
		dm:AddOption( "Duplicate", function()
			ZEDIT.FX.DuplicateParticle( index ) ; RefreshParticleList()
		end ):SetIcon( "icon16/page_copy.png" )
		dm:AddOption( "Spawn This", function()
			local p = ZEDIT.FX.CurrentProject.Particles[ index ]
			if p then
				local ply2 = LocalPlayer()
				if IsValid(ply2) then
					local tr = ply2:GetEyeTrace()
					ZEDIT.FX.SpawnParticle( tr.HitPos + tr.HitNormal * 8, p )
				end
			end
		end ):SetIcon( "icon16/wand.png" )
		dm:AddSpacer()
		dm:AddOption( "Delete", function()
			Derma_Query( "Delete this particle?", "Confirm", "Yes", function()
				ZEDIT.FX.RemoveParticle( index ) ; RefreshParticleList()
			end, "No" )
		end ):SetIcon( "icon16/delete.png" )
		dm:Open()
	end

	RefreshParticleList()

	-- ── Properties scroll panel ───────────────────────────────────────────────
	menu.sp_L = vgui.Create( "DScrollPanel", menu )
	menu.sp_L:Dock( FILL ) ; menu.sp_L:DockMargin( 2, 0, 2, 2 )
	menu.sp_L.Paint = function( self, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, Color( 45, 50, 60, 255 ) )
	end

	local form_item_h = 18
	menu.sp_L.f = vgui.Create( "DForm", menu.sp_L )
	menu.sp_L.f:Dock( TOP )
	menu.sp_L.f:SetName( "Particle Properties" )

	-- ── Particle ID entry ─────────────────────────────────────────────────────
	menu.sp_L.f:TextEntry( "Particle ID", "zedit_particle_id" ):SetTall( form_item_h )

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	SPRITE MATERIALS  —  multi-material table
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.sp_L.f:ControlHelp( "━━━━━ Sprite Materials ━━━━━" ):SetTall( form_item_h )

	-- Container for the material rows; height is rebuilt by RefreshMaterials()
	local mat_list_pnl = vgui.Create( "DPanel", menu.sp_L.f )
	mat_list_pnl:SetTall( 4 )
	mat_list_pnl.Paint = function( s, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, Color( 25, 28, 38, 200 ) )
	end

	local ROW_H = 30

	local function RefreshMaterials()
		-- Clear existing children
		mat_list_pnl:Clear()

		local mats = ZEDIT.FX.PARTICLE_MATERIALS
		local total_h = 4

		for i, mat_path in ipairs( mats ) do
			local row = vgui.Create( "DPanel", mat_list_pnl )
			row:SetPos( 2, total_h )
			row:SetSize( mat_list_pnl:GetWide() - 4, ROW_H )
			row.Paint = function( s, w, h )
				draw.RoundedBox( 3, 0, 0, w, h, Color( 35, 38, 50, 200 ) )
			end

			-- Thumbnail
			local img = vgui.Create( "DImage", row )
			img:SetPos( 2, 2 )
			img:SetSize( 26, 26 )
			img:SetImage( mat_path )
			img:SetKeepAspect( true )

			-- Path text entry
			local path_te = vgui.Create( "DTextEntry", row )
			path_te:SetPos( 32, 6 )
			path_te:SetSize( row:GetWide() - 32 - 26, 18 )
			path_te:SetValue( mat_path )
			path_te.OnEnter = function( self )
				mats[i] = self:GetValue()
				img:SetImage( mats[i] )
			end
			path_te.OnLoseFocus = path_te.OnEnter

			-- Remove button
			local rm = vgui.Create( "DButton", row )
			rm:SetPos( row:GetWide() - 24, 5 )
			rm:SetSize( 20, 20 )
			rm:SetText( "✕" )
			rm:SetFont( "DermaDefault" )
			rm.DoClick = function()
				table.remove( ZEDIT.FX.PARTICLE_MATERIALS, i )
				RefreshMaterials()
			end

			-- Reflow on width change
			row.PerformLayout = function( self, w, h )
				if IsValid(path_te) then path_te:SetSize( w - 32 - 26, 18 ) end
				if IsValid(rm)      then rm:SetPos( w - 24, 5 ) end
			end

			total_h = total_h + ROW_H + 2
		end

		-- "+ Add Material" button
		local add_row = vgui.Create( "DButton", mat_list_pnl )
		add_row:SetPos( 2, total_h )
		add_row:SetSize( mat_list_pnl:GetWide() - 4, 22 )
		add_row:SetText( "+ Add Material" )
		add_row:SetFont( "DermaDefault" )
		add_row.DoClick = function()
			table.insert( ZEDIT.FX.PARTICLE_MATERIALS, "particles/fire1" )
			RefreshMaterials()
		end
		total_h = total_h + 22 + 4

		mat_list_pnl:SetTall( total_h )
	end

	-- PerformLayout propagates new width into each row's path entry
	mat_list_pnl.PerformLayout = function( self, w, h )
		for _, child in ipairs( self:GetChildren() ) do
			if IsValid(child) then
				child:SetWide( w - 4 )
				if child.PerformLayout then child:PerformLayout( w - 4, child:GetTall() ) end
			end
		end
	end

	menu.sp_L.f:AddItem( mat_list_pnl )
	RefreshMaterials()

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	SPAWN SETTINGS
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.sp_L.f:ControlHelp( "━━━━━ Spawn Settings ━━━━━" ):SetTall( form_item_h )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Count",       "zedit_particle_count_min",  "zedit_particle_count_max",  1,    200,  0 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Repeat Rate", "zedit_particle_repeat_min", "zedit_particle_repeat_max", 0.01, 10.0, 2 ) )

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	TIME SETTINGS
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.sp_L.f:ControlHelp( "━━━━━ Time Settings ━━━━━" ):SetTall( form_item_h )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Lifetime", "zedit_particle_lifetime_min", "zedit_particle_lifetime_max", 0.0,  20.0, 2 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Die Time", "zedit_particle_dietime_min",  "zedit_particle_dietime_max",  0.0,  20.0, 2 ) )

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	SIZE & ALPHA
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.sp_L.f:ControlHelp( "━━━━━ Size & Alpha ━━━━━" ):SetTall( form_item_h )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Start Size",   "zedit_particle_size_s_min",   "zedit_particle_size_s_max",   0, 200,  1 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "End Size",     "zedit_particle_size_e_min",   "zedit_particle_size_e_max",   0, 200,  1 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Start Alpha",  "zedit_particle_alpha_s_min",  "zedit_particle_alpha_s_max",  0, 255,  0 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "End Alpha",    "zedit_particle_alpha_e_min",  "zedit_particle_alpha_e_max",  0, 255,  0 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Start Length", "zedit_particle_length_s_min", "zedit_particle_length_s_max", 0, 200,  1 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "End Length",   "zedit_particle_length_e_min", "zedit_particle_length_e_max", 0, 200,  1 ) )

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	COLOR
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.sp_L.f:ControlHelp( "━━━━━ Color ━━━━━" ):SetTall( form_item_h )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Red",   "zedit_particle_color_r_min", "zedit_particle_color_r_max", 0, 255, 0 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Green", "zedit_particle_color_g_min", "zedit_particle_color_g_max", 0, 255, 0 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Blue",  "zedit_particle_color_b_min", "zedit_particle_color_b_max", 0, 255, 0 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Alpha", "zedit_particle_color_a_min", "zedit_particle_color_a_max", 0, 255, 0 ) )
	menu.sp_L.f:CheckBox( "Use Lighting", "zedit_particle_lighting" ):SetTall( form_item_h )

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	ROTATION
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.sp_L.f:ControlHelp( "━━━━━ Rotation ━━━━━" ):SetTall( form_item_h )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Roll",       "zedit_particle_roll_min",      "zedit_particle_roll_max",      0,    360,  0 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Roll Delta", "zedit_particle_rolldelta_min", "zedit_particle_rolldelta_max", -360, 360,  0 ) )
	menu.sp_L.f:TextEntry( "Angles (P Y R)",   "zedit_particle_angles"           ):SetTall( form_item_h )
	menu.sp_L.f:TextEntry( "Angular Velocity", "zedit_particle_angular_velocity" ):SetTall( form_item_h )

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	PHYSICS
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.sp_L.f:ControlHelp( "━━━━━ Physics ━━━━━" ):SetTall( form_item_h )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Air Resistance",    "zedit_particle_airres_min",       "zedit_particle_airres_max",       0,   500,  0 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Bounce",            "zedit_particle_bounce_min",       "zedit_particle_bounce_max",       0,   2.0,  2 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Velocity Mul",      "zedit_particle_velocity_mul_min", "zedit_particle_velocity_mul_max", 0,  20.0,  2 ) )
	menu.sp_L.f:CheckBox( "Collide", "zedit_particle_collide" ):SetTall( form_item_h )
	menu.sp_L.f:TextEntry( "Gravity (X Y Z)",  "zedit_particle_gravity"  ):SetTall( form_item_h )
	menu.sp_L.f:TextEntry( "Velocity (X Y Z)", "zedit_particle_velocity" ):SetTall( form_item_h )

	-- ── Bottom action bar ────────────────────────────────────────────────────
	menu.pn_bottom = vgui.Create( "DPanel", menu )
	menu.pn_bottom:Dock( BOTTOM ) ; menu.pn_bottom:SetTall( 36 ) ; menu.pn_bottom:DockMargin( 2, 2, 2, 2 )
	menu.pn_bottom.Paint = function( self, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, Color( 40, 45, 55, 255 ) )
	end

	local btn_apply = ZDEV.VGUI.CreateButton( menu.pn_bottom, 80, 30, "UPDATE", "raj", Color(100,200,255), function()
		local sel = menu.lv:GetSelectedLine()
		if sel then
			ZEDIT.FX.CurrentProject.Particles[ sel ] = ZEDIT.FX.GetConVars()
			RefreshParticleList()
			zdev.log( "S", "Updated particle at index " .. sel )
		else
			zdev.log( "I", "No particle selected to update" )
		end
	end )
	btn_apply:Dock( LEFT ) ; btn_apply:DockMargin( 2, 2, 2, 2 )

	local btn_reset = ZDEV.VGUI.CreateButton( menu.pn_bottom, 64, 30, "RESET", "raj", Color(255,200,100), function()
		RunConsoleCommand( "zedit_particle_id",          "particle_01" )
		RunConsoleCommand( "zedit_particle_dietime_min", "1" )
		RunConsoleCommand( "zedit_particle_dietime_max", "1" )
		RunConsoleCommand( "zedit_particle_size_s_min",  "8" )
		RunConsoleCommand( "zedit_particle_size_s_max",  "8" )
		RunConsoleCommand( "zedit_particle_size_e_min",  "2" )
		RunConsoleCommand( "zedit_particle_size_e_max",  "2" )
		ZEDIT.FX.PARTICLE_MATERIALS = { "particles/fire1" }
		RefreshMaterials()
		zdev.log( "I", "Reset particle settings to defaults" )
	end )
	btn_reset:Dock( LEFT ) ; btn_reset:DockMargin( 0, 2, 2, 2 )

	local btn_close = ZDEV.VGUI.CreateButton( menu.pn_bottom, 64, 30, "CLOSE", "raj", Color(255,100,100), function()
		ZEDIT.FX.StopPreview() ; menu:Close()
	end )
	btn_close:Dock( RIGHT ) ; btn_close:DockMargin( 2, 2, 2, 2 )

	menu.OnClose = function() ZEDIT.FX.StopPreview() end

	return menu
end

-- ─── Console commands ─────────────────────────────────────────────────────────
concommand.Add( "zedit_particle_editor", function()
	ZDEV.VGUI.ParticleEditor()
end )

-- Legacy typo alias
concommand.Add( "zedit_paticle_editor", function()
	ZDEV.VGUI.ParticleEditor()
end )

concommand.Add( "zedit_particle_spawn", function()
	ZEDIT.FX.SpawnOnce()
end )

concommand.Add( "zedit_particle_preview_start", function()
	ZEDIT.FX.StartPreview()
end )

concommand.Add( "zedit_particle_preview_stop", function()
	ZEDIT.FX.StopPreview()
end )

ZDEV.VGUI.AddToMainMenu( "zedit_particle_editor" )

ZDEV.FILE.SetLoaded( _f )

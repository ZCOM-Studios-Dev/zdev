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
ZEDIT.FX.ACTIVE_SYSTEMS    = {}
ZEDIT.FX.PREVIEW_HOOK      = "ZEDIT_ParticlePreview"
ZEDIT.FX.PREVIEW_ENABLED   = false
ZEDIT.FX.PREVIEW_RATE      = 0.1
ZEDIT.FX.LAST_PREVIEW      = 0
ZEDIT.FX.NEXT_PREVIEW_RATE = 0.1

-- Multi-material list for the currently-edited emitter (persists across menu opens)
if not ZEDIT.FX.PARTICLE_MATERIALS then
	ZEDIT.FX.PARTICLE_MATERIALS = { "particles/fire1" }
end

-- Callback for UI refresh when materials change via SetConVars
ZEDIT.FX.OnMaterialsChanged = nil

-- ─── Preview Window State ────────────────────────────────────────────────────
ZEDIT.FX.PREVIEW_WINDOW_OPEN  = false
ZEDIT.FX.PREVIEW_FRAME        = nil
ZEDIT.FX.PREVIEW_ORIGIN       = Vector( 0, 0, 16000 )   -- far above to stay out of sight
ZEDIT.FX.PREVIEW_CAM_DIST     = 250
ZEDIT.FX.PREVIEW_CAM_PITCH    = 30
ZEDIT.FX.PREVIEW_CAM_YAW      = 0
ZEDIT.FX.PREVIEW_RT            = nil
ZEDIT.FX.PREVIEW_RT_MAT        = nil
ZEDIT.FX.PREVIEW_RT_SIZE       = 512
ZEDIT.FX._RENDERING_PREVIEW    = false

-- Registers the canonical zdev_edit_particle_* convar and its deprecated
-- zedit_particle_* alias (value-migrating, write-mirroring) in one call.
local function EditorVar( name, default, shouldsave, userinfo, help )
	local cv = CreateClientConVar( name, default, shouldsave, userinfo, help or "" )
	ZDEV.CONV.LegacyAlias( name, ( string.gsub( name, "^zdev_edit_", "zedit_" ) ) )
	return cv
end

-- ─── Editor-state ConVars (owned here since Sweep Phase 3; were in zd_autorun) ─
EditorVar( "zdev_edit_particle_toggle",           "0",     true, false, "Particle editor mode toggle" )
EditorVar( "zdev_edit_particle_show_helpers",     "1",     true, false, "Draw emitter helpers" )
EditorVar( "zdev_edit_particle_show_timegraph",   "1",     true, false, "Draw the time graph" )
EditorVar( "zdev_edit_particle_emitter",          "0e001", true, false, "Active emitter ID" )
EditorVar( "zdev_edit_particle_entity",           "0",     true, false, "Attach-entity index" )
EditorVar( "zdev_edit_particle_pos",              "0 0 0", true, false, "Emitter world position" )
EditorVar( "zdev_edit_particle_offset",           "0 0 16",true, false, "Emitter offset (right fwd up)" )
EditorVar( "zdev_edit_particle_delay",            "0",     true, false, "Emit delay" )
-- Editor-mode viewmodel toggle (ZDEV.CONV.EditorCallback lives in zd_sh_editor.lua).
-- Identifier makes re-adding on zdev_reload replace instead of stack.
cvars.AddChangeCallback( "zdev_edit_particle_toggle", function( ... ) ZDEV.CONV.EditorCallback( ... ) end, "zdev_editor_mode" )

-- ─── Existing single-value ConVars (kept for legacy project loading) ───────
EditorVar( "zdev_edit_particle_id",               "particle_01",  true, false, "Particle ID" )
EditorVar( "zdev_edit_particle_mat",              "particles/fire1", true, false, "Particle material (legacy)" )
EditorVar( "zdev_edit_particle_lifetime",         "0.5",  true, false, "Particle lifetime" )
EditorVar( "zdev_edit_particle_dietime",          "1.0",  true, false, "Particle die time" )
EditorVar( "zdev_edit_particle_size_s",           "8",    true, false, "Start size" )
EditorVar( "zdev_edit_particle_size_e",           "2",    true, false, "End size" )
EditorVar( "zdev_edit_particle_alpha_s",          "255",  true, false, "Start alpha" )
EditorVar( "zdev_edit_particle_alpha_e",          "0",    true, false, "End alpha" )
EditorVar( "zdev_edit_particle_length_s",         "0",    true, false, "Start length" )
EditorVar( "zdev_edit_particle_length_e",         "0",    true, false, "End length" )
EditorVar( "zdev_edit_particle_roll",             "0",    true, false, "Roll angle" )
EditorVar( "zdev_edit_particle_rolldelta",        "0",    true, false, "Roll delta" )
EditorVar( "zdev_edit_particle_angles",           "0 0 0",true, false, "Angles" )
EditorVar( "zdev_edit_particle_angular_velocity", "0 0 0",true, false, "Angular velocity" )
EditorVar( "zdev_edit_particle_airres",           "50",   true, false, "Air resistance" )
EditorVar( "zdev_edit_particle_bounce",           "0.5",  true, false, "Bounce" )
EditorVar( "zdev_edit_particle_collide",          "0",    true, false, "Collide" )
EditorVar( "zdev_edit_particle_lighting",         "0",    true, false, "Lighting" )
EditorVar( "zdev_edit_particle_color",            "255 200 100", true, false, "Color" )
EditorVar( "zdev_edit_particle_color_r",          "255",  true, false, "Color R" )
EditorVar( "zdev_edit_particle_color_g",          "200",  true, false, "Color G" )
EditorVar( "zdev_edit_particle_color_b",          "100",  true, false, "Color B" )
EditorVar( "zdev_edit_particle_color_a",          "255",  true, false, "Color A" )
EditorVar( "zdev_edit_particle_gravity",          "0 0 -100", true, false, "Gravity vector" )
EditorVar( "zdev_edit_particle_velocity",         "0 0 50",   true, false, "Velocity vector" )
EditorVar( "zdev_edit_particle_velocity_mul",     "1",    true, false, "Velocity multiplier" )
EditorVar( "zdev_edit_particle_count_min",        "1",    true, false, "Min particle count" )
EditorVar( "zdev_edit_particle_count_max",        "5",    true, false, "Max particle count" )
EditorVar( "zdev_edit_particle_repeat",           "0.1",  true, false, "Repeat rate" )
EditorVar( "zdev_edit_particle_preview",          "0",    true, false, "Preview enabled" )

-- ─── Range min/max ConVars ─────────────────────────────────────────────────
EditorVar( "zdev_edit_particle_lifetime_min",      "0.5",  true, false, "Lifetime min" )
EditorVar( "zdev_edit_particle_lifetime_max",      "0.5",  true, false, "Lifetime max" )
EditorVar( "zdev_edit_particle_dietime_min",       "1.0",  true, false, "Die time min" )
EditorVar( "zdev_edit_particle_dietime_max",       "1.0",  true, false, "Die time max" )
EditorVar( "zdev_edit_particle_size_s_min",        "8",    true, false, "Start size min" )
EditorVar( "zdev_edit_particle_size_s_max",        "8",    true, false, "Start size max" )
EditorVar( "zdev_edit_particle_size_e_min",        "2",    true, false, "End size min" )
EditorVar( "zdev_edit_particle_size_e_max",        "2",    true, false, "End size max" )
EditorVar( "zdev_edit_particle_alpha_s_min",       "255",  true, false, "Start alpha min" )
EditorVar( "zdev_edit_particle_alpha_s_max",       "255",  true, false, "Start alpha max" )
EditorVar( "zdev_edit_particle_alpha_e_min",       "0",    true, false, "End alpha min" )
EditorVar( "zdev_edit_particle_alpha_e_max",       "0",    true, false, "End alpha max" )
EditorVar( "zdev_edit_particle_length_s_min",      "0",    true, false, "Start length min" )
EditorVar( "zdev_edit_particle_length_s_max",      "0",    true, false, "Start length max" )
EditorVar( "zdev_edit_particle_length_e_min",      "0",    true, false, "End length min" )
EditorVar( "zdev_edit_particle_length_e_max",      "0",    true, false, "End length max" )
EditorVar( "zdev_edit_particle_color_r_min",       "255",  true, false, "Color R min" )
EditorVar( "zdev_edit_particle_color_r_max",       "255",  true, false, "Color R max" )
EditorVar( "zdev_edit_particle_color_g_min",       "200",  true, false, "Color G min" )
EditorVar( "zdev_edit_particle_color_g_max",       "200",  true, false, "Color G max" )
EditorVar( "zdev_edit_particle_color_b_min",       "100",  true, false, "Color B min" )
EditorVar( "zdev_edit_particle_color_b_max",       "100",  true, false, "Color B max" )
EditorVar( "zdev_edit_particle_color_a_min",       "255",  true, false, "Color A min" )
EditorVar( "zdev_edit_particle_color_a_max",       "255",  true, false, "Color A max" )
EditorVar( "zdev_edit_particle_roll_min",          "0",    true, false, "Roll min" )
EditorVar( "zdev_edit_particle_roll_max",          "0",    true, false, "Roll max" )
EditorVar( "zdev_edit_particle_rolldelta_min",     "0",    true, false, "Roll delta min" )
EditorVar( "zdev_edit_particle_rolldelta_max",     "0",    true, false, "Roll delta max" )
EditorVar( "zdev_edit_particle_airres_min",        "50",   true, false, "Air resistance min" )
EditorVar( "zdev_edit_particle_airres_max",        "50",   true, false, "Air resistance max" )
EditorVar( "zdev_edit_particle_bounce_min",        "0.5",  true, false, "Bounce min" )
EditorVar( "zdev_edit_particle_bounce_max",        "0.5",  true, false, "Bounce max" )
EditorVar( "zdev_edit_particle_velocity_mul_min",  "1",    true, false, "Velocity mul min" )
EditorVar( "zdev_edit_particle_velocity_mul_max",  "1",    true, false, "Velocity mul max" )
EditorVar( "zdev_edit_particle_repeat_min",        "0.1",  true, false, "Repeat rate min" )
EditorVar( "zdev_edit_particle_repeat_max",        "0.1",  true, false, "Repeat rate max" )

-- ─── Per-axis velocity range ConVars ────────────────────────────────────────
EditorVar( "zdev_edit_particle_vel_x_min",         "0",    true, false, "Velocity X min" )
EditorVar( "zdev_edit_particle_vel_x_max",         "0",    true, false, "Velocity X max" )
EditorVar( "zdev_edit_particle_vel_y_min",         "0",    true, false, "Velocity Y min" )
EditorVar( "zdev_edit_particle_vel_y_max",         "0",    true, false, "Velocity Y max" )
EditorVar( "zdev_edit_particle_vel_z_min",         "0",    true, false, "Velocity Z min" )
EditorVar( "zdev_edit_particle_vel_z_max",         "50",   true, false, "Velocity Z max" )

-- ─── Per-axis gravity range ConVars ─────────────────────────────────────────
EditorVar( "zdev_edit_particle_grav_x_min",        "0",    true, false, "Gravity X min" )
EditorVar( "zdev_edit_particle_grav_x_max",        "0",    true, false, "Gravity X max" )
EditorVar( "zdev_edit_particle_grav_y_min",        "0",    true, false, "Gravity Y min" )
EditorVar( "zdev_edit_particle_grav_y_max",        "0",    true, false, "Gravity Y max" )
EditorVar( "zdev_edit_particle_grav_z_min",        "-100", true, false, "Gravity Z min" )
EditorVar( "zdev_edit_particle_grav_z_max",        "-100", true, false, "Gravity Z max" )

-- ─── Per-emitter spawn offset ConVars ───────────────────────────────────────
EditorVar( "zdev_edit_particle_spawn_x",           "0",    true, false, "Spawn offset X" )
EditorVar( "zdev_edit_particle_spawn_y",           "0",    true, false, "Spawn offset Y" )
EditorVar( "zdev_edit_particle_spawn_z",           "0",    true, false, "Spawn offset Z" )

-- ─── Emission Type ConVars ──────────────────────────────────────────────────
EditorVar( "zdev_edit_particle_emission_mode",     "1",    true, false, "Emission: 0=Instantaneous, 1=Continuous" )

-- ─── Spawn Volume ConVars ───────────────────────────────────────────────────
EditorVar( "zdev_edit_particle_spawn_vol_type",    "1",    true, false, "Volume type: 0=Sphere, 1=Box, 2=Cylinder" )
EditorVar( "zdev_edit_particle_spawn_vol_pos_x_min", "0",   true, false, "Spawn volume position X min" )
EditorVar( "zdev_edit_particle_spawn_vol_pos_x_max", "0",   true, false, "Spawn volume position X max" )
EditorVar( "zdev_edit_particle_spawn_vol_pos_y_min", "0",   true, false, "Spawn volume position Y min" )
EditorVar( "zdev_edit_particle_spawn_vol_pos_y_max", "0",   true, false, "Spawn volume position Y max" )
EditorVar( "zdev_edit_particle_spawn_vol_pos_z_min", "0",   true, false, "Spawn volume position Z min" )
EditorVar( "zdev_edit_particle_spawn_vol_pos_z_max", "0",   true, false, "Spawn volume position Z max" )
EditorVar( "zdev_edit_particle_spawn_vol_scale_x_min", "10", true, false, "Spawn volume scale X min" )
EditorVar( "zdev_edit_particle_spawn_vol_scale_x_max", "10", true, false, "Spawn volume scale X max" )
EditorVar( "zdev_edit_particle_spawn_vol_scale_y_min", "10", true, false, "Spawn volume scale Y min" )
EditorVar( "zdev_edit_particle_spawn_vol_scale_y_max", "10", true, false, "Spawn volume scale Y max" )
EditorVar( "zdev_edit_particle_spawn_vol_scale_z_min", "10", true, false, "Spawn volume scale Z min" )
EditorVar( "zdev_edit_particle_spawn_vol_scale_z_max", "10", true, false, "Spawn volume scale Z max" )
EditorVar( "zdev_edit_particle_spawn_vol_uniform_scale", "1", true, false, "Use uniform scaling for spawn volume" )

-- ─── Project data (System -> Emitter architecture) ──────────────────────────
ZEDIT.FX.CurrentProject = ZEDIT.FX.CurrentProject or {
	Name      = "Untitled",
	Filename  = "untitled.json",
	Author    = "Unknown",
	Systems   = {},
	Particles = {},
	LastSave  = 0
}

ZEDIT.FX.SelectedSystemIdx  = 1
ZEDIT.FX.SelectedEmitterIdx = 1

function ZEDIT.FX.NewProject( name )
	ZEDIT.FX.CurrentProject = {
		Name     = name or "Untitled",
		Filename = string.lower(string.gsub(name or "untitled", " ", "_")) .. ".json",
		Author   = "Unknown",
		Systems  = {},
		Particles = {},
		LastSave = 0
	}
	ZEDIT.FX.SelectedSystemIdx  = 1
	ZEDIT.FX.SelectedEmitterIdx = 1
	zdev.log( "S", "Created new particle project: " .. ZEDIT.FX.CurrentProject.Name )
end

-- ─── ConVar accessors ────────────────────────────────────────────────────────
function ZEDIT.FX.GetConVars()
	return {
		id       = GetConVarString( "zdev_edit_particle_id" ),
		materials = table.Copy( ZEDIT.FX.PARTICLE_MATERIALS ),
		material  = GetConVarString( "zdev_edit_particle_mat" ),

		count_min       = GetConVarNumber( "zdev_edit_particle_count_min" ),
		count_max       = GetConVarNumber( "zdev_edit_particle_count_max" ),
		repeat_min      = GetConVar( "zdev_edit_particle_repeat_min" ):GetFloat(),
		repeat_max      = GetConVar( "zdev_edit_particle_repeat_max" ):GetFloat(),
		lifetime_min    = GetConVar( "zdev_edit_particle_lifetime_min" ):GetFloat(),
		lifetime_max    = GetConVar( "zdev_edit_particle_lifetime_max" ):GetFloat(),
		dietime_min     = GetConVar( "zdev_edit_particle_dietime_min" ):GetFloat(),
		dietime_max     = GetConVar( "zdev_edit_particle_dietime_max" ):GetFloat(),

		size_s_min      = GetConVarNumber( "zdev_edit_particle_size_s_min" ),
		size_s_max      = GetConVarNumber( "zdev_edit_particle_size_s_max" ),
		size_e_min      = GetConVarNumber( "zdev_edit_particle_size_e_min" ),
		size_e_max      = GetConVarNumber( "zdev_edit_particle_size_e_max" ),
		length_s_min    = GetConVarNumber( "zdev_edit_particle_length_s_min" ),
		length_s_max    = GetConVarNumber( "zdev_edit_particle_length_s_max" ),
		length_e_min    = GetConVarNumber( "zdev_edit_particle_length_e_min" ),
		length_e_max    = GetConVarNumber( "zdev_edit_particle_length_e_max" ),

		alpha_s_min     = GetConVarNumber( "zdev_edit_particle_alpha_s_min" ),
		alpha_s_max     = GetConVarNumber( "zdev_edit_particle_alpha_s_max" ),
		alpha_e_min     = GetConVarNumber( "zdev_edit_particle_alpha_e_min" ),
		alpha_e_max     = GetConVarNumber( "zdev_edit_particle_alpha_e_max" ),

		color_r_min     = GetConVarNumber( "zdev_edit_particle_color_r_min" ),
		color_r_max     = GetConVarNumber( "zdev_edit_particle_color_r_max" ),
		color_g_min     = GetConVarNumber( "zdev_edit_particle_color_g_min" ),
		color_g_max     = GetConVarNumber( "zdev_edit_particle_color_g_max" ),
		color_b_min     = GetConVarNumber( "zdev_edit_particle_color_b_min" ),
		color_b_max     = GetConVarNumber( "zdev_edit_particle_color_b_max" ),
		color_a_min     = GetConVarNumber( "zdev_edit_particle_color_a_min" ),
		color_a_max     = GetConVarNumber( "zdev_edit_particle_color_a_max" ),

		roll_min        = GetConVarNumber( "zdev_edit_particle_roll_min" ),
		roll_max        = GetConVarNumber( "zdev_edit_particle_roll_max" ),
		rolldelta_min   = GetConVarNumber( "zdev_edit_particle_rolldelta_min" ),
		rolldelta_max   = GetConVarNumber( "zdev_edit_particle_rolldelta_max" ),
		angles          = GetConVarString( "zdev_edit_particle_angles" ),
		ang_velocity    = GetConVarString( "zdev_edit_particle_angular_velocity" ),

		airres_min      = GetConVarNumber( "zdev_edit_particle_airres_min" ),
		airres_max      = GetConVarNumber( "zdev_edit_particle_airres_max" ),
		bounce_min      = GetConVar( "zdev_edit_particle_bounce_min" ):GetFloat(),
		bounce_max      = GetConVar( "zdev_edit_particle_bounce_max" ):GetFloat(),
		collide         = GetConVar( "zdev_edit_particle_collide" ):GetBool(),
		lighting        = GetConVar( "zdev_edit_particle_lighting" ):GetBool(),
		velocity_mul_min = GetConVarNumber( "zdev_edit_particle_velocity_mul_min" ),
		velocity_mul_max = GetConVarNumber( "zdev_edit_particle_velocity_mul_max" ),

		vel_x_min       = GetConVar( "zdev_edit_particle_vel_x_min" ):GetFloat(),
		vel_x_max       = GetConVar( "zdev_edit_particle_vel_x_max" ):GetFloat(),
		vel_y_min       = GetConVar( "zdev_edit_particle_vel_y_min" ):GetFloat(),
		vel_y_max       = GetConVar( "zdev_edit_particle_vel_y_max" ):GetFloat(),
		vel_z_min       = GetConVar( "zdev_edit_particle_vel_z_min" ):GetFloat(),
		vel_z_max       = GetConVar( "zdev_edit_particle_vel_z_max" ):GetFloat(),

		grav_x_min      = GetConVar( "zdev_edit_particle_grav_x_min" ):GetFloat(),
		grav_x_max      = GetConVar( "zdev_edit_particle_grav_x_max" ):GetFloat(),
		grav_y_min      = GetConVar( "zdev_edit_particle_grav_y_min" ):GetFloat(),
		grav_y_max      = GetConVar( "zdev_edit_particle_grav_y_max" ):GetFloat(),
		grav_z_min      = GetConVar( "zdev_edit_particle_grav_z_min" ):GetFloat(),
		grav_z_max      = GetConVar( "zdev_edit_particle_grav_z_max" ):GetFloat(),

		gravity         = GetConVarString( "zdev_edit_particle_gravity" ),
		velocity        = GetConVarString( "zdev_edit_particle_velocity" ),

		-- Per-emitter spawn offset
		spawn_x         = GetConVar( "zdev_edit_particle_spawn_x" ):GetFloat(),
		spawn_y         = GetConVar( "zdev_edit_particle_spawn_y" ):GetFloat(),
		spawn_z         = GetConVar( "zdev_edit_particle_spawn_z" ):GetFloat(),

		-- Emission type and spawn volume
		emission_mode   = GetConVarNumber( "zdev_edit_particle_emission_mode" ),
		spawn_vol_type  = GetConVarNumber( "zdev_edit_particle_spawn_vol_type" ),
		spawn_vol_pos_x_min = GetConVar( "zdev_edit_particle_spawn_vol_pos_x_min" ):GetFloat(),
		spawn_vol_pos_x_max = GetConVar( "zdev_edit_particle_spawn_vol_pos_x_max" ):GetFloat(),
		spawn_vol_pos_y_min = GetConVar( "zdev_edit_particle_spawn_vol_pos_y_min" ):GetFloat(),
		spawn_vol_pos_y_max = GetConVar( "zdev_edit_particle_spawn_vol_pos_y_max" ):GetFloat(),
		spawn_vol_pos_z_min = GetConVar( "zdev_edit_particle_spawn_vol_pos_z_min" ):GetFloat(),
		spawn_vol_pos_z_max = GetConVar( "zdev_edit_particle_spawn_vol_pos_z_max" ):GetFloat(),
		spawn_vol_scale_x_min = GetConVar( "zdev_edit_particle_spawn_vol_scale_x_min" ):GetFloat(),
		spawn_vol_scale_x_max = GetConVar( "zdev_edit_particle_spawn_vol_scale_x_max" ):GetFloat(),
		spawn_vol_scale_y_min = GetConVar( "zdev_edit_particle_spawn_vol_scale_y_min" ):GetFloat(),
		spawn_vol_scale_y_max = GetConVar( "zdev_edit_particle_spawn_vol_scale_y_max" ):GetFloat(),
		spawn_vol_scale_z_min = GetConVar( "zdev_edit_particle_spawn_vol_scale_z_min" ):GetFloat(),
		spawn_vol_scale_z_max = GetConVar( "zdev_edit_particle_spawn_vol_scale_z_max" ):GetFloat(),
		spawn_vol_uniform_scale = GetConVarNumber( "zdev_edit_particle_spawn_vol_uniform_scale" ),
	}
end

function ZEDIT.FX.SetConVars( data )
	if not data then return end
	if data.materials and type( data.materials ) == "table" then
		ZEDIT.FX.PARTICLE_MATERIALS = table.Copy( data.materials )
		if ZEDIT.FX.OnMaterialsChanged then
			ZEDIT.FX.OnMaterialsChanged()
		end
	end
	for k, v in pairs( data ) do
		if k ~= "materials" then
			local cvar = GetConVar( "zdev_edit_particle_" .. k )
			if cvar then RunConsoleCommand( "zdev_edit_particle_" .. k, tostring(v) ) end
		end
	end
end

-- ─── System management ──────────────────────────────────────────────────────

function ZEDIT.FX.NewSystem( name )
	local sys = {
		id       = string.lower( string.gsub( name or "system", " ", "_" ) ) .. "_" .. math.random( 1000, 9999 ),
		name     = name or "New System",
		emitters = {}
	}
	table.insert( ZEDIT.FX.CurrentProject.Systems, sys )
	ZEDIT.FX.SelectedSystemIdx = #ZEDIT.FX.CurrentProject.Systems
	ZEDIT.FX.SelectedEmitterIdx = 1
	zdev.log( "S", "Created particle system: " .. sys.name )
	return sys
end

function ZEDIT.FX.RemoveSystem( index )
	local sys = ZEDIT.FX.CurrentProject.Systems[ index ]
	if sys then
		table.remove( ZEDIT.FX.CurrentProject.Systems, index )
		zdev.log( "I", "Removed particle system: " .. tostring( sys.name ) )
		if ZEDIT.FX.SelectedSystemIdx > #ZEDIT.FX.CurrentProject.Systems then
			ZEDIT.FX.SelectedSystemIdx = math.max( 1, #ZEDIT.FX.CurrentProject.Systems )
		end
		ZEDIT.FX.SelectedEmitterIdx = 1
	end
end

function ZEDIT.FX.DuplicateSystem( index )
	local sys = ZEDIT.FX.CurrentProject.Systems[ index ]
	if sys then
		local dup = table.Copy( sys )
		dup.id   = sys.id .. "_copy"
		dup.name = sys.name .. " (Copy)"
		table.insert( ZEDIT.FX.CurrentProject.Systems, dup )
		zdev.log( "S", "Duplicated system: " .. dup.name )
	end
end

function ZEDIT.FX.GetSelectedSystem()
	return ZEDIT.FX.CurrentProject.Systems[ ZEDIT.FX.SelectedSystemIdx ]
end

-- ─── Emitter management ─────────────────────────────────────────────────────

function ZEDIT.FX.AddEmitter( sys_index, emitter_data )
	local sys = ZEDIT.FX.CurrentProject.Systems[ sys_index ]
	if not sys then return end
	emitter_data.id = emitter_data.id or ( "emitter_" .. #sys.emitters + 1 )
	table.insert( sys.emitters, emitter_data )
	ZEDIT.FX.SelectedEmitterIdx = #sys.emitters
	zdev.log( "S", "Added emitter '" .. emitter_data.id .. "' to system '" .. sys.name .. "'" )
end

function ZEDIT.FX.RemoveEmitter( sys_index, em_index )
	local sys = ZEDIT.FX.CurrentProject.Systems[ sys_index ]
	if not sys then return end
	if sys.emitters[ em_index ] then
		local id = sys.emitters[ em_index ].id
		table.remove( sys.emitters, em_index )
		zdev.log( "I", "Removed emitter: " .. tostring(id) )
		if ZEDIT.FX.SelectedEmitterIdx > #sys.emitters then
			ZEDIT.FX.SelectedEmitterIdx = math.max( 1, #sys.emitters )
		end
	end
end

function ZEDIT.FX.DuplicateEmitter( sys_index, em_index )
	local sys = ZEDIT.FX.CurrentProject.Systems[ sys_index ]
	if not sys or not sys.emitters[ em_index ] then return end
	local dup = table.Copy( sys.emitters[ em_index ] )
	dup.id = dup.id .. "_copy"
	table.insert( sys.emitters, dup )
	zdev.log( "S", "Duplicated emitter: " .. dup.id )
end

function ZEDIT.FX.GetSelectedEmitter()
	local sys = ZEDIT.FX.GetSelectedSystem()
	if not sys then return nil end
	return sys.emitters[ ZEDIT.FX.SelectedEmitterIdx ]
end

-- ─── Legacy particle management ─────────────────────────────────────────────

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
		Systems   = ZEDIT.FX.CurrentProject.Systems,
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
		local systems = data.Systems or {}
		if #systems == 0 and data.Particles and #data.Particles > 0 then
			systems = { { id = "migrated_system", name = "Migrated System", emitters = data.Particles } }
			zdev.log( "I", "Migrated " .. #data.Particles .. " legacy particles into a system" )
		end
		ZEDIT.FX.CurrentProject = {
			Name = data.Name or "Loaded", Filename = filename, Author = data.Author or "Unknown",
			Systems = systems, Particles = data.Particles or {}, LastSave = CurTime()
		}
		ZEDIT.FX.SelectedSystemIdx  = 1
		ZEDIT.FX.SelectedEmitterIdx = 1
		zdev.log( "S", "Loaded project: " .. filename .. " (" .. #systems .. " systems)" )
		return true
	end
	return false
end

function ZEDIT.FX.GetSavedFiles()
	ZEDIT.FX.EnsureDirectory()
	return file.Find( ZEDIT.FX.SAVE_DIR .. "*.json", "DATA" ) or {}
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
	SetClipboardText( util.TableToJSON( ZEDIT.FX.CurrentProject, true ) )
	zdev.log( "S", "Exported project to clipboard" )
end

function ZEDIT.FX.ImportFromText( text )
	local data = util.JSONToTable( text )
	if data then
		local systems = data.Systems or {}
		if #systems == 0 and data.Particles and #data.Particles > 0 then
			systems = { { id = "imported", name = "Imported", emitters = data.Particles } }
		end
		ZEDIT.FX.CurrentProject = {
			Name = data.Name or "Imported", Filename = "imported_" .. os.time() .. ".json",
			Author = data.Author or "Unknown", Systems = systems,
			Particles = data.Particles or {}, LastSave = 0
		}
		ZEDIT.FX.SelectedSystemIdx  = 1
		ZEDIT.FX.SelectedEmitterIdx = 1
		zdev.log( "S", "Imported project from text" )
		return true
	end
	zdev.log( "F", "Failed to parse import data" )
	return false
end

-- ─── Code generation helpers ────────────────────────────────────────────────

-- Format a number cleanly: strip trailing zeros, keep decimals when needed
local function fmtnum( v )
	if v == math.floor( v ) then return tostring( math.floor( v ) ) end
	return string.format( "%.3f", v ):gsub( "0+$", "" ):gsub( "%.$", "" )
end

-- Generate a Lua expression for a randomised range value
-- When min == max, return a constant; otherwise return math.Rand(min, max)
local function rv_expr( vmin, vmax )
	vmin = vmin or 0
	vmax = vmax or vmin
	if vmin == vmax then return fmtnum( vmin ) end
	return "math.Rand( " .. fmtnum( math.min(vmin, vmax) ) .. ", " .. fmtnum( math.max(vmin, vmax) ) .. " )"
end

-- Generate a Lua expression for a randomised integer range
local function ri_expr( vmin, vmax )
	vmin = math.max( 1, vmin or 1 )
	vmax = math.max( 1, vmax or vmin )
	if vmin == vmax then return tostring( vmin ) end
	return "math.random( " .. tostring( vmin ) .. ", " .. tostring( vmax ) .. " )"
end

-- Generate the particle-spawning code block for a single emitter
local function GenEmitterBlock( em, indent, pos_var )
	local I  = indent or "\t\t"
	local I2 = I .. "\t"
	local lines = {}
	local function L( s ) lines[ #lines + 1 ] = s end

	-- Materials
	local mats = em.materials
	if mats and #mats > 1 then
		L( I .. "local _mats = {" )
		for _, m in ipairs( mats ) do L( I .. "\t\"" .. m .. "\"," ) end
		L( I .. "}" )
		L( I .. "local _mat = _mats[ math.random( 1, #_mats ) ]" )
	else
		local mat = ( mats and mats[1] ) or em.material or "particles/fire1"
		L( I .. "local _mat = \"" .. mat .. "\"" )
	end

	-- Spawn offset
	local ox = em.spawn_x or 0
	local oy = em.spawn_y or 0
	local oz = em.spawn_z or 0
	if ox ~= 0 or oy ~= 0 or oz ~= 0 then
		L( I .. "local _offset = Vector( " .. fmtnum(ox) .. ", " .. fmtnum(oy) .. ", " .. fmtnum(oz) .. " )" )
		L( I .. "local _spos = " .. pos_var .. " + _offset" )
	else
		L( I .. "local _spos = " .. pos_var )
	end

	-- Count
	local cmin = math.max( 1, em.count_min or 1 )
	local cmax = math.max( 1, em.count_max or cmin )
	L( I .. "local _count = " .. ri_expr( cmin, cmax ) )

	L( I .. "local _em = ParticleEmitter( " .. pos_var .. " )" )
	L( I .. "if _em then" )
	L( I2 .. "for _ = 1, _count do" )

	local I3 = I2 .. "\t"
	L( I3 .. "local p = _em:Add( _mat, _spos + VectorRand() * 2 )" )
	L( I3 .. "if p then" )

	local I4 = I3 .. "\t"
	L( I4 .. "p:SetLifeTime( 0 )" )
	L( I4 .. "p:SetDieTime( " .. rv_expr( em.dietime_min, em.dietime_max ) .. " )" )
	L( I4 .. "p:SetStartSize( " .. rv_expr( em.size_s_min, em.size_s_max ) .. " )" )
	L( I4 .. "p:SetEndSize( " .. rv_expr( em.size_e_min, em.size_e_max ) .. " )" )
	L( I4 .. "p:SetStartAlpha( " .. rv_expr( em.alpha_s_min, em.alpha_s_max ) .. " )" )
	L( I4 .. "p:SetEndAlpha( " .. rv_expr( em.alpha_e_min, em.alpha_e_max ) .. " )" )
	L( I4 .. "p:SetStartLength( " .. rv_expr( em.length_s_min, em.length_s_max ) .. " )" )
	L( I4 .. "p:SetEndLength( " .. rv_expr( em.length_e_min, em.length_e_max ) .. " )" )

	-- Roll (convert degrees to radians)
	local roll_min = em.roll_min or 0
	local roll_max = em.roll_max or 0
	if roll_min == roll_max then
		L( I4 .. "p:SetRoll( math.rad( " .. fmtnum( roll_min ) .. " ) )" )
	else
		L( I4 .. "p:SetRoll( math.rad( " .. rv_expr( roll_min, roll_max ) .. " ) )" )
	end

	local rd_min = em.rolldelta_min or 0
	local rd_max = em.rolldelta_max or 0
	if rd_min == rd_max then
		L( I4 .. "p:SetRollDelta( math.rad( " .. fmtnum( rd_min ) .. " ) )" )
	else
		L( I4 .. "p:SetRollDelta( math.rad( " .. rv_expr( rd_min, rd_max ) .. " ) )" )
	end

	L( I4 .. "p:SetAirResistance( " .. rv_expr( em.airres_min, em.airres_max ) .. " )" )
	L( I4 .. "p:SetBounce( " .. rv_expr( em.bounce_min, em.bounce_max ) .. " )" )
	L( I4 .. "p:SetCollide( " .. tostring( em.collide or false ) .. " )" )
	L( I4 .. "p:SetLighting( " .. tostring( em.lighting or false ) .. " )" )

	-- Color
	local cr = rv_expr( em.color_r_min, em.color_r_max )
	local cg = rv_expr( em.color_g_min, em.color_g_max )
	local cb = rv_expr( em.color_b_min, em.color_b_max )
	L( I4 .. "p:SetColor( math.Clamp( math.Round( " .. cr .. " ), 0, 255 ), math.Clamp( math.Round( " .. cg .. " ), 0, 255 ), math.Clamp( math.Round( " .. cb .. " ), 0, 255 ) )" )

	-- Gravity
	L( I4 .. "p:SetGravity( Vector( " .. rv_expr( em.grav_x_min, em.grav_x_max ) .. ", " .. rv_expr( em.grav_y_min, em.grav_y_max ) .. ", " .. rv_expr( em.grav_z_min, em.grav_z_max ) .. " ) )" )

	-- Velocity
	local vmul_min = em.velocity_mul_min or 1
	local vmul_max = em.velocity_mul_max or 1
	local vel_expr = "Vector( " .. rv_expr( em.vel_x_min, em.vel_x_max ) .. ", " .. rv_expr( em.vel_y_min, em.vel_y_max ) .. ", " .. rv_expr( em.vel_z_min, em.vel_z_max ) .. " )"
	if vmul_min == 1 and vmul_max == 1 then
		L( I4 .. "p:SetVelocity( " .. vel_expr .. " )" )
	elseif vmul_min == vmul_max then
		L( I4 .. "p:SetVelocity( " .. vel_expr .. " * " .. fmtnum( vmul_min ) .. " )" )
	else
		L( I4 .. "local _vmul = " .. rv_expr( vmul_min, vmul_max ) )
		L( I4 .. "p:SetVelocity( " .. vel_expr .. " * _vmul )" )
	end

	L( I3 .. "end" )   -- if p
	L( I2 .. "end" )   -- for
	L( I2 .. "_em:Finish()" )
	L( I .. "end" )     -- if _em

	return table.concat( lines, "\n" )
end

-- ─── Export: Scripted Effect (EFFECT) ───────────────────────────────────────

function ZEDIT.FX.GenerateEffectCode( system )
	if not system or not system.emitters or #system.emitters == 0 then
		return "-- No emitters in system"
	end

	local name = string.lower( string.gsub( system.name or "particle_effect", " ", "_" ) )
	local lines = {}
	local function L( s ) lines[ #lines + 1 ] = s end

	L( "-- ─────────────────────────────────────────────────────────────────────────" )
	L( "-- Scripted Effect: " .. ( system.name or name ) )
	L( "-- Generated by ZDEV Particle Editor on " .. os.date( "%Y-%m-%d %H:%M" ) )
	L( "-- Place in: lua/effects/" .. name .. "/init.lua" )
	L( "-- ─────────────────────────────────────────────────────────────────────────" )
	L( "" )
	L( "function EFFECT:Init( data )" )
	L( "\tlocal pos = data:GetOrigin()" )
	L( "" )

	for i, em in ipairs( system.emitters ) do
		if #system.emitters > 1 then
			L( "\t-- Emitter " .. i .. ": " .. ( em.id or "emitter_" .. i ) )
		end
		L( GenEmitterBlock( em, "\t", "pos" ) )
		if i < #system.emitters then L( "" ) end
	end

	L( "end" )
	L( "" )
	L( "function EFFECT:Think()" )
	L( "\treturn false" )
	L( "end" )
	L( "" )
	L( "function EFFECT:Render()" )
	L( "end" )

	return table.concat( lines, "\n" )
end

-- ─── Export: Scripted Entity (SENT) ─────────────────────────────────────────

function ZEDIT.FX.GenerateEntityCode( system )
	if not system or not system.emitters or #system.emitters == 0 then
		return { shared = "-- No emitters in system", cl_init = "", init = "" }
	end

	local name = string.lower( string.gsub( system.name or "particle_ent", " ", "_" ) )

	-- Compute the fastest repeat rate across all emitters for the Think interval
	local min_rate = 999
	for _, em in ipairs( system.emitters ) do
		local rmin = em.repeat_min or 0.1
		if rmin < min_rate then min_rate = rmin end
	end
	min_rate = math.max( 0.01, min_rate )

	-- ── shared.lua ──
	local sh = {}
	local function SL( s ) sh[ #sh + 1 ] = s end
	SL( "-- ─────────────────────────────────────────────────────────────────────────" )
	SL( "-- Scripted Entity: " .. ( system.name or name ) )
	SL( "-- Generated by ZDEV Particle Editor on " .. os.date( "%Y-%m-%d %H:%M" ) )
	SL( "-- Place in: lua/entities/" .. name .. "/" )
	SL( "-- ─────────────────────────────────────────────────────────────────────────" )
	SL( "" )
	SL( "ENT.Type      = \"anim\"" )
	SL( "ENT.Base      = \"base_anim\"" )
	SL( "ENT.PrintName = \"" .. ( system.name or "Particle Entity" ) .. "\"" )
	SL( "ENT.Author    = \"" .. ( ZEDIT.FX.CurrentProject.Author or "ZDEV" ) .. "\"" )
	SL( "ENT.Spawnable = true" )

	-- ── init.lua (server) ──
	local sv = {}
	local function VL( s ) sv[ #sv + 1 ] = s end
	VL( "AddCSLuaFile( \"cl_init.lua\" )" )
	VL( "AddCSLuaFile( \"shared.lua\" )" )
	VL( "include( \"shared.lua\" )" )
	VL( "" )
	VL( "function ENT:Initialize()" )
	VL( "\tself:SetModel( \"models/hunter/blocks/cube025x025x025.mdl\" )" )
	VL( "\tself:PhysicsInit( SOLID_VPHYSICS )" )
	VL( "\tself:SetMoveType( MOVETYPE_VPHYSICS )" )
	VL( "\tself:SetSolid( SOLID_VPHYSICS )" )
	VL( "end" )

	-- ── cl_init.lua (client) ──
	local cl = {}
	local function CL( s ) cl[ #cl + 1 ] = s end
	CL( "include( \"shared.lua\" )" )
	CL( "" )

	-- Per-emitter spawn functions
	for i, em in ipairs( system.emitters ) do
		CL( "-- Emitter " .. i .. ": " .. ( em.id or "emitter_" .. i ) )
		CL( "local function SpawnEmitter_" .. i .. "( pos )" )
		CL( GenEmitterBlock( em, "\t", "pos" ) )
		CL( "end" )
		CL( "" )
	end

	-- Build per-emitter repeat rate state
	CL( "function ENT:Initialize()" )
	CL( "\tself._nextFire = {}" )
	for i, em in ipairs( system.emitters ) do
		CL( "\tself._nextFire[" .. i .. "] = 0" )
	end
	CL( "end" )
	CL( "" )

	CL( "function ENT:Think()" )
	CL( "\tlocal now = CurTime()" )
	CL( "\tlocal pos = self:GetPos()" )
	CL( "" )

	for i, em in ipairs( system.emitters ) do
		local rmin = em.repeat_min or 0.1
		local rmax = em.repeat_max or rmin
		CL( "\tif now >= self._nextFire[" .. i .. "] then" )
		CL( "\t\tSpawnEmitter_" .. i .. "( pos )" )
		CL( "\t\tself._nextFire[" .. i .. "] = now + " .. rv_expr( rmin, rmax ) )
		CL( "\tend" )
		if i < #system.emitters then CL( "" ) end
	end

	CL( "" )
	CL( "\tself:SetNextClientThink( now + " .. fmtnum( min_rate ) .. " )" )
	CL( "\treturn true" )
	CL( "end" )
	CL( "" )
	CL( "function ENT:Draw()" )
	CL( "\tself:DrawModel()" )
	CL( "end" )

	return {
		shared  = table.concat( sh, "\n" ),
		cl_init = table.concat( cl, "\n" ),
		init    = table.concat( sv, "\n" ),
	}
end

-- ─── Export window ──────────────────────────────────────────────────────────

function ZEDIT.FX.ShowExportWindow( title, code_text, filename_hint )
	local ew = math.floor( ScrW() * 0.5 )
	local eh = math.floor( ScrH() * 0.7 )
	local frame = ZDEV.VGUI.CreateFrame( ew, eh, title )
	frame:Center()
	frame:MakePopup()
	frame:SetSizable( true )

	local te = vgui.Create( "DTextEntry", frame )
	te:Dock( FILL )
	te:DockMargin( 4, 4, 4, 4 )
	te:SetMultiline( true )
	te:SetValue( code_text )
	te:SetFont( "DermaDefault" )
	te:SetEditable( true )

	local bar = vgui.Create( "DPanel", frame )
	bar:Dock( BOTTOM )
	bar:SetTall( 34 )
	bar:DockMargin( 4, 0, 4, 4 )
	bar.Paint = function() end

	ZDEV.VGUI.CreateButton( bar, 120, 28, "Copy to Clipboard", "DermaDefault", Color( 100, 220, 120 ), function()
		SetClipboardText( te:GetValue() )
		zdev.log( "S", "Copied code to clipboard" )
	end ):Dock( LEFT )

	ZDEV.VGUI.CreateButton( bar, 130, 28, "Save to Data", "DermaDefault", Color( 180, 200, 255 ), function()
		local save_name = filename_hint or "exported_code.lua.txt"
		Derma_StringRequest( "Save File", "Filename (saved in garrysmod/data/zdev/exports/):", save_name, function( txt )
			if not string.EndsWith( txt, ".txt" ) then txt = txt .. ".txt" end
			local dir = "zdev/exports/"
			if not file.Exists( dir, "DATA" ) then file.CreateDir( dir ) end
			file.Write( dir .. txt, te:GetValue() )
			zdev.log( "S", "Saved export: " .. dir .. txt )
		end )
	end ):Dock( LEFT )

	ZDEV.VGUI.CreateButton( bar, 80, 28, "Close", "DermaDefault", Color( 255, 100, 100 ), function()
		frame:Close()
	end ):Dock( RIGHT )

	return frame
end

-- Show a tabbed export window for multi-file SENT exports
function ZEDIT.FX.ShowExportWindowTabs( title, file_tabs )
	local ew = math.floor( ScrW() * 0.5 )
	local eh = math.floor( ScrH() * 0.7 )
	local frame = ZDEV.VGUI.CreateFrame( ew, eh, title )
	frame:Center()
	frame:MakePopup()
	frame:SetSizable( true )

	local sheet = vgui.Create( "DPropertySheet", frame )
	sheet:Dock( FILL )
	sheet:DockMargin( 4, 4, 4, 4 )

	local text_entries = {}

	for _, tab in ipairs( file_tabs ) do
		local pnl = vgui.Create( "DPanel" )
		pnl.Paint = function() end

		local te = vgui.Create( "DTextEntry", pnl )
		te:Dock( FILL )
		te:DockMargin( 2, 2, 2, 2 )
		te:SetMultiline( true )
		te:SetValue( tab.code )
		te:SetFont( "DermaDefault" )
		te:SetEditable( true )
		text_entries[ tab.name ] = te

		sheet:AddSheet( tab.name, pnl, tab.icon or "icon16/page_white_code.png" )
	end

	local bar = vgui.Create( "DPanel", frame )
	bar:Dock( BOTTOM )
	bar:SetTall( 34 )
	bar:DockMargin( 4, 0, 4, 4 )
	bar.Paint = function() end

	ZDEV.VGUI.CreateButton( bar, 140, 28, "Copy Active Tab", "DermaDefault", Color( 100, 220, 120 ), function()
		local active = sheet:GetActiveTab()
		if active then
			local name = active:GetText()
			if text_entries[ name ] then
				SetClipboardText( text_entries[ name ]:GetValue() )
				zdev.log( "S", "Copied " .. name .. " to clipboard" )
			end
		end
	end ):Dock( LEFT )

	ZDEV.VGUI.CreateButton( bar, 130, 28, "Save All to Data", "DermaDefault", Color( 180, 200, 255 ), function()
		local dir = "zdev/exports/"
		if not file.Exists( dir, "DATA" ) then file.CreateDir( dir ) end
		for tab_name, te in pairs( text_entries ) do
			local fname = string.gsub( tab_name, "%.", "_" ) .. ".txt"
			file.Write( dir .. fname, te:GetValue() )
		end
		zdev.log( "S", "Saved all tabs to " .. dir )
	end ):Dock( LEFT )

	ZDEV.VGUI.CreateButton( bar, 80, 28, "Close", "DermaDefault", Color( 255, 100, 100 ), function()
		frame:Close()
	end ):Dock( RIGHT )

	return frame
end

-- ─── Spawn / preview ─────────────────────────────────────────────────────────

local function rv( vmin, vmax, legacy )
	vmin = vmin or legacy or 0
	vmax = vmax or legacy or vmin
	if vmin == vmax then return vmin end
	return math.Rand( math.min(vmin,vmax), math.max(vmin,vmax) )
end

function ZEDIT.FX.SpawnParticle( pos, data )
	local emitter = ParticleEmitter( pos )
	if not emitter then return end

	-- Apply per-emitter spawn offset
	local offset = Vector( data.spawn_x or 0, data.spawn_y or 0, data.spawn_z or 0 )
	local spawn_pos = pos + offset

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

	local has_vel_range = data.vel_x_min or data.vel_x_max or data.vel_y_min or data.vel_y_max or data.vel_z_min or data.vel_z_max
	local legacy_vel
	if not has_vel_range then
		local vel_parts = string.Explode( " ", data.velocity or "0 0 50" )
		legacy_vel = Vector( tonumber(vel_parts[1]) or 0, tonumber(vel_parts[2]) or 0, tonumber(vel_parts[3]) or 50 )
	end

	local has_grav_range = data.grav_x_min or data.grav_x_max or data.grav_y_min or data.grav_y_max or data.grav_z_min or data.grav_z_max
	local legacy_grav
	if not has_grav_range then
		local grav_parts = string.Explode( " ", data.gravity or "0 0 -100" )
		legacy_grav = Vector( tonumber(grav_parts[1]) or 0, tonumber(grav_parts[2]) or 0, tonumber(grav_parts[3]) or -100 )
	end

	for _ = 1, count do
		local p = emitter:Add( mat, spawn_pos + VectorRand() * 2 )
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
			if has_grav_range then
				p:SetGravity( Vector(
					rv( data.grav_x_min, data.grav_x_max, 0 ),
					rv( data.grav_y_min, data.grav_y_max, 0 ),
					rv( data.grav_z_min, data.grav_z_max, -100 )
				) )
			else
				p:SetGravity( legacy_grav )
			end
			local vmul = rv( data.velocity_mul_min, data.velocity_mul_max, data.velocity_mul )
			if has_vel_range then
				p:SetVelocity( Vector(
					rv( data.vel_x_min, data.vel_x_max, 0 ),
					rv( data.vel_y_min, data.vel_y_max, 0 ),
					rv( data.vel_z_min, data.vel_z_max, 50 )
				) * vmul )
			else
				p:SetVelocity( (legacy_vel + VectorRand() * 10) * vmul )
			end
		end
	end
	emitter:Finish()
end

-- ─── System spawn ───────────────────────────────────────────────────────────

function ZEDIT.FX.SpawnSystemOnce( pos, system )
	if not system or not system.emitters then return end
	for _, em_data in ipairs( system.emitters ) do
		ZEDIT.FX.SpawnParticle( pos, em_data )
	end
end

-- ─── Active System Management ───────────────────────────────────────────────

local active_system_counter = 0

function ZEDIT.FX.SpawnSystem( pos, system )
	if not system or not system.emitters or #system.emitters == 0 then return end
	active_system_counter = active_system_counter + 1
	local uid = "ZEDIT_ActiveSys_" .. active_system_counter
	local em_states = {}
	for i, em in ipairs( system.emitters ) do
		em_states[i] = { data = table.Copy( em ), next_fire = 0 }
	end
	local instance = {
		uid = uid, system = table.Copy( system ), pos = pos,
		em_states = em_states, start_time = CurTime()
	}
	ZEDIT.FX.ACTIVE_SYSTEMS[ uid ] = instance
	hook.Add( "Think", uid, function()
		local now = CurTime()
		for i, state in ipairs( em_states ) do
			if now >= state.next_fire then
				ZEDIT.FX.SpawnParticle( instance.pos, state.data )
				local rmin = state.data.repeat_min or state.data["repeat"] or 0.1
				local rmax = state.data.repeat_max or rmin
				state.next_fire = now + rv( rmin, rmax, 0.1 )
			end
		end
	end )
	zdev.log( "S", "Spawned active system: " .. system.name .. " [" .. uid .. "] with " .. #system.emitters .. " emitters" )
	return uid
end

function ZEDIT.FX.StopSystem( uid )
	if ZEDIT.FX.ACTIVE_SYSTEMS[ uid ] then
		hook.Remove( "Think", uid )
		ZEDIT.FX.ACTIVE_SYSTEMS[ uid ] = nil
		zdev.log( "I", "Stopped active system: " .. uid )
	end
end

function ZEDIT.FX.StopAllSystems()
	for uid, _ in pairs( ZEDIT.FX.ACTIVE_SYSTEMS ) do
		hook.Remove( "Think", uid )
	end
	ZEDIT.FX.ACTIVE_SYSTEMS = {}
	zdev.log( "I", "Stopped all active systems" )
end

-- ─── Spawn position helper ──────────────────────────────────────────────────
-- Always spawn at the player's eye trace for normal spawning.
-- Preview window spawning is handled separately.

function ZEDIT.FX.GetSpawnPos()
	local ply = LocalPlayer()
	if not IsValid(ply) then return Vector(0,0,0) end
	local tr = ply:GetEyeTrace()
	return tr.HitPos + tr.HitNormal * 8
end

-- Get spawn position for preview window (separate from normal spawning)
function ZEDIT.FX.GetPreviewSpawnPos()
	return ZEDIT.FX.PREVIEW_ORIGIN
end

-- ─── Preview Window (3D render target) ──────────────────────────────────────

function ZEDIT.FX.InitPreviewRT()
	if ZEDIT.FX.PREVIEW_RT then return end
	local sz = ZEDIT.FX.PREVIEW_RT_SIZE
	ZEDIT.FX.PREVIEW_RT = GetRenderTarget( "ZEDIT_FX_PreviewRT_" .. sz, sz, sz )
	ZEDIT.FX.PREVIEW_RT_MAT = CreateMaterial( "ZEDIT_FX_PreviewMat_" .. SysTime(), "UnlitGeneric", {
		["$basetexture"] = ZEDIT.FX.PREVIEW_RT:GetName(),
		["$translucent"] = "1",
		["$vertexcolor"] = "1",
	} )
end

-- Render the preview scene into the RT once per frame
hook.Add( "RenderScene", "ZEDIT_FX_PreviewCapture", function()
	if not ZEDIT.FX.PREVIEW_WINDOW_OPEN then return end
	if ZEDIT.FX._RENDERING_PREVIEW then return end
	if not ZEDIT.FX.PREVIEW_RT then return end

	ZEDIT.FX._RENDERING_PREVIEW = true

	local origin = ZEDIT.FX.PREVIEW_ORIGIN
	local ang = Angle( ZEDIT.FX.PREVIEW_CAM_PITCH, ZEDIT.FX.PREVIEW_CAM_YAW, 0 )
	local cam_pos = origin - ang:Forward() * ZEDIT.FX.PREVIEW_CAM_DIST

	local sz = ZEDIT.FX.PREVIEW_RT_SIZE
	render.PushRenderTarget( ZEDIT.FX.PREVIEW_RT )
	render.Clear( 18, 20, 28, 255, true, true )
	render.RenderView( {
		origin = cam_pos, angles = ang,
		x = 0, y = 0, w = sz, h = sz,
		fov = 70, drawviewmodel = false, drawhud = false,
		drawportals = true,
	} )
	render.PopRenderTarget()

	ZEDIT.FX._RENDERING_PREVIEW = false
end )

-- Draw a reference grid and spawn volume at the preview origin
hook.Add( "PostDrawTranslucentRenderables", "ZEDIT_FX_PreviewGrid", function()
	if not ZEDIT.FX._RENDERING_PREVIEW then return end
	local o = ZEDIT.FX.PREVIEW_ORIGIN
	local half = 150
	local step = 30
	-- Floor grid
	for i = -half, half, step do
		render.DrawLine( o + Vector(i, -half, 0), o + Vector(i, half, 0), Color(50, 50, 60, 120), false )
		render.DrawLine( o + Vector(-half, i, 0), o + Vector(half, i, 0), Color(50, 50, 60, 120), false )
	end
	-- Axis indicators
	render.DrawLine( o, o + Vector(half, 0, 0),  Color(220, 50, 50, 180), false )
	render.DrawLine( o, o + Vector(0, half, 0),  Color(50, 220, 50, 180), false )
	render.DrawLine( o, o + Vector(0, 0, half),  Color(50, 50, 220, 180), false )

	-- Draw spawn volume
	local vol_type = GetConVarNumber( "zdev_edit_particle_spawn_vol_type" )
	local pos_x = math.Clamp( GetConVar( "zdev_edit_particle_spawn_vol_pos_x_max" ):GetFloat() + GetConVar( "zdev_edit_particle_spawn_vol_pos_x_min" ):GetFloat(), -200, 200 ) * 0.5
	local pos_y = math.Clamp( GetConVar( "zdev_edit_particle_spawn_vol_pos_y_max" ):GetFloat() + GetConVar( "zdev_edit_particle_spawn_vol_pos_y_min" ):GetFloat(), -200, 200 ) * 0.5
	local pos_z = math.Clamp( GetConVar( "zdev_edit_particle_spawn_vol_pos_z_max" ):GetFloat() + GetConVar( "zdev_edit_particle_spawn_vol_pos_z_min" ):GetFloat(), -200, 200 ) * 0.5
	local vol_pos = o + Vector( pos_x, pos_y, pos_z )

	local uniform = GetConVarNumber( "zdev_edit_particle_spawn_vol_uniform_scale" ) ~= 0
	local scale_x = GetConVar( "zdev_edit_particle_spawn_vol_scale_x_max" ):GetFloat()
	local scale_y = uniform and scale_x or GetConVar( "zdev_edit_particle_spawn_vol_scale_y_max" ):GetFloat()
	local scale_z = uniform and scale_x or GetConVar( "zdev_edit_particle_spawn_vol_scale_z_max" ):GetFloat()

	if vol_type == 0 then
		-- Sphere
		render.DrawWireframeSphere( vol_pos, scale_x, 8, 8, Color( 100, 200, 255, 200 ) )
		-- Draw a few sample emission points inside the sphere
		for _ = 1, 3 do
			local rand_pos = vol_pos + VectorRand() * scale_x * 0.7
			render.DrawWireframeSphere( rand_pos, 2, 4, 4, Color( 200, 255, 150, 150 ) )
		end
	elseif vol_type == 1 then
		-- Box
		local min = vol_pos - Vector( scale_x, scale_y, scale_z ) * 0.5
		local max = vol_pos + Vector( scale_x, scale_y, scale_z ) * 0.5
		render.DrawWireframeBox( vol_pos, Angle(0, 0, 0), min - vol_pos, max - vol_pos, Color( 100, 200, 255, 200 ) )
		-- Draw a few sample emission points inside the box
		for _ = 1, 3 do
			local rand_pos = vol_pos + Vector(
				math.random(-scale_x/2, scale_x/2),
				math.random(-scale_y/2, scale_y/2),
				math.random(-scale_z/2, scale_z/2)
			)
			render.DrawWireframeSphere( rand_pos, 2, 4, 4, Color( 200, 255, 150, 150 ) )
		end
	elseif vol_type == 2 then
		-- Cylinder (draw as 8-sided prism approximation)
		local h = scale_z
		local r = scale_x
		local pts = 8
		for i = 0, pts - 1 do
			local a1 = (i / pts) * math.pi * 2
			local a2 = ((i + 1) / pts) * math.pi * 2
			local p1_bot = vol_pos + Vector( math.cos(a1) * r, math.sin(a1) * r, -h * 0.5 )
			local p2_bot = vol_pos + Vector( math.cos(a2) * r, math.sin(a2) * r, -h * 0.5 )
			local p1_top = vol_pos + Vector( math.cos(a1) * r, math.sin(a1) * r, h * 0.5 )
			local p2_top = vol_pos + Vector( math.cos(a2) * r, math.sin(a2) * r, h * 0.5 )
			render.DrawLine( p1_bot, p2_bot, Color( 100, 200, 255, 200 ), false )
			render.DrawLine( p1_top, p2_top, Color( 100, 200, 255, 200 ), false )
			render.DrawLine( p1_bot, p1_top, Color( 100, 200, 255, 200 ), false )
		end
		-- Draw a few sample emission points inside the cylinder
		for _ = 1, 3 do
			local angle = math.random() * math.pi * 2
			local dist = math.random(0, r)
			local rand_pos = vol_pos + Vector( math.cos(angle) * dist, math.sin(angle) * dist, math.random(-h/2, h/2) )
			render.DrawWireframeSphere( rand_pos, 2, 4, 4, Color( 200, 255, 150, 150 ) )
		end
	end
end )

function ZEDIT.FX.OpenPreviewWindow()
	if IsValid( ZEDIT.FX.PREVIEW_FRAME ) then
		ZEDIT.FX.PREVIEW_FRAME:MakePopup()
		return
	end

	ZEDIT.FX.InitPreviewRT()
	ZEDIT.FX.PREVIEW_WINDOW_OPEN = true

	local pw, ph = 420, 420
	local frm = vgui.Create( "DFrame" )
	frm:SetSize( pw, ph )
	frm:SetTitle( "Particle Preview" )
	frm:SetPos( ScrW() - pw - 10, 10 )
	frm:MakePopup()
	frm:SetSizable( true )
	frm:SetMinWidth( 200 )
	frm:SetMinHeight( 200 )
	frm:SetDeleteOnClose( true )
	frm.Paint = function( self, w, h )
		draw.RoundedBox( 6, 0, 0, w, h, Color( 25, 28, 35, 245 ) )
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 1, Color( 80, 120, 180, 255 ) )
	end
	ZEDIT.FX.PREVIEW_FRAME = frm

	-- 3D viewport panel (fills the frame body)
	local vp = vgui.Create( "DPanel", frm )
	vp:Dock( FILL )
	vp:DockMargin( 4, 4, 4, 4 )

	-- Camera orbit state
	local dragging = false
	local last_mx, last_my = 0, 0

	vp.Paint = function( self, w, h )
		if ZEDIT.FX.PREVIEW_RT_MAT then
			surface.SetDrawColor( 255, 255, 255, 255 )
			surface.SetMaterial( ZEDIT.FX.PREVIEW_RT_MAT )
			surface.DrawTexturedRect( 0, 0, w, h )
		else
			draw.RoundedBox( 0, 0, 0, w, h, Color( 30, 30, 40, 255 ) )
			draw.SimpleText( "Initializing...", "DermaDefault", w*0.5, h*0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
		-- Crosshair at center
		surface.SetDrawColor( 255, 255, 255, 40 )
		surface.DrawRect( w*0.5 - 8, h*0.5, 16, 1 )
		surface.DrawRect( w*0.5, h*0.5 - 8, 1, 16 )
	end

	vp.OnMousePressed = function( self, btn )
		if btn == MOUSE_LEFT then
			dragging = true
			last_mx, last_my = self:CursorPos()
			self:MouseCapture( true )
		end
	end
	vp.OnMouseReleased = function( self, btn )
		if btn == MOUSE_LEFT then
			dragging = false
			self:MouseCapture( false )
		end
	end
	vp.OnCursorMoved = function( self, mx, my )
		if dragging then
			local dx = mx - last_mx
			local dy = my - last_my
			ZEDIT.FX.PREVIEW_CAM_YAW   = ZEDIT.FX.PREVIEW_CAM_YAW   - dx * 0.5
			ZEDIT.FX.PREVIEW_CAM_PITCH  = math.Clamp( ZEDIT.FX.PREVIEW_CAM_PITCH + dy * 0.5, -89, 89 )
			last_mx, last_my = mx, my
		end
	end
	vp.OnMouseWheeled = function( self, delta )
		ZEDIT.FX.PREVIEW_CAM_DIST = math.Clamp( ZEDIT.FX.PREVIEW_CAM_DIST - delta * 20, 30, 2000 )
	end

	frm.OnClose = function()
		ZEDIT.FX.PREVIEW_WINDOW_OPEN = false
		ZEDIT.FX.PREVIEW_FRAME = nil
	end
end

function ZEDIT.FX.ClosePreviewWindow()
	if IsValid( ZEDIT.FX.PREVIEW_FRAME ) then
		ZEDIT.FX.PREVIEW_FRAME:Close()
	end
	ZEDIT.FX.PREVIEW_WINDOW_OPEN = false
	ZEDIT.FX.PREVIEW_FRAME = nil
end

-- ─── Preview / spawn controls ───────────────────────────────────────────────

function ZEDIT.FX.StartPreview()
	ZEDIT.FX.PREVIEW_ENABLED = true
	hook.Add( "Think", ZEDIT.FX.PREVIEW_HOOK, function()
		if not ZEDIT.FX.PREVIEW_ENABLED then return end
		if CurTime() - ZEDIT.FX.LAST_PREVIEW < ZEDIT.FX.NEXT_PREVIEW_RATE then return end
		ZEDIT.FX.LAST_PREVIEW = CurTime()

		local sys = ZEDIT.FX.GetSelectedSystem()
		if sys and #sys.emitters > 0 then
			local min_rate = 999
			for _, em in ipairs( sys.emitters ) do
				local rmin = em.repeat_min or em["repeat"] or 0.1
				if rmin < min_rate then min_rate = rmin end
			end
			ZEDIT.FX.NEXT_PREVIEW_RATE = math.max( 0.01, min_rate )
		else
			local cv_rmin = GetConVar( "zdev_edit_particle_repeat_min" )
			local cv_rmax = GetConVar( "zdev_edit_particle_repeat_max" )
			if cv_rmin and cv_rmax then
				local rmin, rmax = cv_rmin:GetFloat(), cv_rmax:GetFloat()
				ZEDIT.FX.NEXT_PREVIEW_RATE = (rmin == rmax) and rmin or math.Rand( math.min(rmin,rmax), math.max(rmin,rmax) )
			else
				ZEDIT.FX.NEXT_PREVIEW_RATE = GetConVar( "zdev_edit_particle_repeat" ):GetFloat()
			end
		end

		local pos = ZEDIT.FX.GetSpawnPos()

		if sys and #sys.emitters > 0 then
			ZEDIT.FX.SpawnSystemOnce( pos, sys )
		else
			ZEDIT.FX.SpawnParticle( pos, ZEDIT.FX.GetConVars() )
		end

		-- Also spawn at preview origin when preview window is open
		if ZEDIT.FX.PREVIEW_WINDOW_OPEN and IsValid( ZEDIT.FX.PREVIEW_FRAME ) then
			local preview_pos = ZEDIT.FX.GetPreviewSpawnPos()
			if sys and #sys.emitters > 0 then
				ZEDIT.FX.SpawnSystemOnce( preview_pos, sys )
			else
				ZEDIT.FX.SpawnParticle( preview_pos, ZEDIT.FX.GetConVars() )
			end
		end
	end )
	zdev.log( "S", "Preview started" )
end

function ZEDIT.FX.StopPreview()
	ZEDIT.FX.PREVIEW_ENABLED = false
	hook.Remove( "Think", ZEDIT.FX.PREVIEW_HOOK )
	zdev.log( "I", "Preview stopped" )
end

function ZEDIT.FX.SpawnOnce()
	local pos = ZEDIT.FX.GetSpawnPos()
	local sys = ZEDIT.FX.GetSelectedSystem()
	if sys and #sys.emitters > 0 then
		ZEDIT.FX.SpawnSystemOnce( pos, sys )
	else
		ZEDIT.FX.SpawnParticle( pos, ZEDIT.FX.GetConVars() )
	end
end

function ZEDIT.FX.SpawnAll()
	local pos = ZEDIT.FX.GetSpawnPos()
	for _, sys in ipairs( ZEDIT.FX.CurrentProject.Systems ) do
		ZEDIT.FX.SpawnSystemOnce( pos, sys )
	end
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Drawing helpers
-- ─────────────────────────────────────────────────────────────────────────────

local function DrawFilledCircle( x, y, radius, clr )
	local segs = 20
	draw.NoTexture()
	surface.SetDrawColor( clr )
	local poly = {}
	for i = 0, segs do
		local a = math.rad( i / segs * 360 )
		poly[ #poly + 1 ] = { x = x + math.cos(a) * radius, y = y + math.sin(a) * radius }
	end
	surface.DrawPoly( poly )
end

-- Choose a "nice" tick step for ruler markings based on the visible range
local function NiceTickStep( view_range, max_ticks )
	if view_range <= 0 then return 1 end
	max_ticks = max_ticks or 8
	local rough = view_range / max_ticks
	if rough <= 0 then return 1 end
	local pow10 = math.floor( math.log10( rough ) )
	local base  = 10 ^ pow10
	local norm  = rough / base
	local nice
	if norm <= 1.0 then nice = 1
	elseif norm <= 2.0 then nice = 2
	elseif norm <= 5.0 then nice = 5
	else nice = 10 end
	return nice * base
end

-- ─────────────────────────────────────────────────────────────────────────────
--  ZD_RangeSlider  (v2)
--  Features: circle handles, ruler tick marks, mouse-wheel zoom
-- ─────────────────────────────────────────────────────────────────────────────
local function CreateRangeSlider( parent_form, label, cvar_min_name, cvar_max_name, range_min, range_max, decimals )
	decimals = decimals or 0

	-- Compact horizontal layout: label | input_min | [====slider====] | input_max
	local PAD        = 6
	local ENTRY_H    = 16
	local ENTRY_W    = 45
	local LABEL_W    = 60
	local SLIDER_MIN_X = LABEL_W + ENTRY_W + PAD * 3
	local TOTAL_H    = ENTRY_H + PAD * 2
	local BASE_Y     = PAD

	-- Zoom state: the visible window on the value axis
	local view_min = range_min
	local view_max = range_max

	-- Value state
	local val_min     = GetConVar( cvar_min_name ):GetFloat()
	local val_max     = GetConVar( cvar_max_name ):GetFloat()
	local dragging    = nil
	local drag_start  = nil
	local hover_h     = nil

	local te_min, te_max   -- text entry forward refs

	-- Helpers
	local function fmt( v ) return string.format( "%." .. decimals .. "f", v ) end

	local function get_slider_bounds( w )
		local track_w = w - SLIDER_MIN_X - ENTRY_W - PAD * 2
		return SLIDER_MIN_X, SLIDER_MIN_X + track_w
	end

	local function val_to_slider_x( v, w )
		local track_x, track_end = get_slider_bounds( w )
		local track_w = track_end - track_x
		local vr = view_max - view_min
		if vr <= 0 then return track_x end
		return track_x + ( v - view_min ) / vr * track_w
	end

	local function slider_x_to_val( x, w )
		local track_x, track_end = get_slider_bounds( w )
		local track_w = track_end - track_x
		local t = math.Clamp( ( x - track_x ) / track_w, 0, 1 )
		local v = view_min + t * ( view_max - view_min )
		v = math.Clamp( v, range_min, range_max )
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

		-- Label (left side)
		draw.SimpleText( label, "DermaDefault", PAD, BASE_Y + 2, color_white )

		-- Slider track and handles
		local track_x, track_end = get_slider_bounds( w )
		local track_w = track_end - track_x
		local track_cy = BASE_Y + math.floor( ENTRY_H * 0.5 )
		local track_h = 3

		-- Draw track background
		draw.RoundedBox( 2, track_x, track_cy - 2, track_w, track_h, Color( 18, 18, 28, 255 ) )

		-- Filled region between handles
		local xlo = math.Clamp( val_to_slider_x( val_min, w ), track_x, track_end )
		local xhi = math.Clamp( val_to_slider_x( val_max, w ), track_x, track_end )
		local fw = xhi - xlo

		if fw > 1 then
			local half = math.max( 1, fw * 0.5 )
			surface.SetDrawColor( 50, 200, 80, 210 )
			surface.DrawRect( xlo, track_cy - 2, half, track_h )
			surface.SetDrawColor( 210, 70, 50, 210 )
			surface.DrawRect( xlo + half, track_cy - 2, fw - half, track_h )
		elseif fw <= 1 then
			surface.SetDrawColor( 255, 230, 80, 220 )
			surface.DrawRect( xlo - 1, track_cy - 3, 2, track_h + 2 )
		end

		-- Draw circle handles (small, compact version)
		local handle_r = 4
		local clr_min = ( hover_h == "min" or dragging == "min" ) and Color( 90, 255, 110, 255 ) or Color( 50, 195, 80, 255 )
		DrawFilledCircle( xlo, track_cy, handle_r, clr_min )
		surface.DrawCircle( xlo, track_cy, handle_r, Color( 200, 200, 210, 180 ) )

		local clr_max = ( hover_h == "max" or dragging == "max" ) and Color( 255, 90, 80, 255 ) or Color( 195, 55, 50, 255 )
		DrawFilledCircle( xhi, track_cy, handle_r, clr_max )
		surface.DrawCircle( xhi, track_cy, handle_r, Color( 200, 200, 210, 180 ) )
	end

	-- ── Mouse input ──

	pnl.OnMousePressed = function( self, btn )
		if btn ~= MOUSE_LEFT then return end
		local mx, my = self:CursorPos()
		local w = self:GetWide()
		local track_x, track_end = get_slider_bounds( w )
		local track_cy = BASE_Y + math.floor( ENTRY_H * 0.5 )
		local handle_r = 4

		-- Only respond in the slider area
		if my < BASE_Y or my > BASE_Y + ENTRY_H then return end

		local xlo = math.Clamp( val_to_slider_x( val_min, w ), track_x, track_end )
		local xhi = math.Clamp( val_to_slider_x( val_max, w ), track_x, track_end )
		local near_min = math.abs( mx - xlo ) <= handle_r + 4
		local near_max = math.abs( mx - xhi ) <= handle_r + 4
		local on_bar = mx >= track_x and mx <= track_end and not near_min and not near_max

		-- Keyboard modifier handling
		if input.IsKeyDown( KEY_LCONTROL ) then
			if near_min then
				set_min( 0 )
				return
			elseif near_max then
				set_max( 0 )
				return
			elseif on_bar then
				set_min( 0 )
				set_max( 0 )
				return
			end
		end

		if input.IsKeyDown( KEY_LSHIFT ) then
			if near_min then
				set_min( 1 )
				return
			elseif near_max then
				set_max( 1 )
				return
			end
		end

		-- Normal dragging
		if near_min and near_max then
			dragging = "tie"
			drag_start = mx
		elseif near_min then
			dragging = "min"
		elseif near_max then
			dragging = "max"
		elseif on_bar then
			if math.abs( mx - xlo ) <= math.abs( mx - xhi ) then
				dragging = "min"
			else
				dragging = "max"
			end
		end
		if dragging then
			self:MouseCapture( true )
		end
	end

	pnl.OnMouseReleased = function( self, btn )
		if btn ~= MOUSE_LEFT then return end
		dragging   = nil
		drag_start = nil
		self:MouseCapture( false )
	end

	pnl.OnCursorMoved = function( self, mx, my )
		local w = self:GetWide()
		local track_x, track_end = get_slider_bounds( w )
		local handle_r = 4

		-- Resolve tie-break
		if dragging == "tie" and drag_start then
			if math.abs( mx - drag_start ) > 2 then
				dragging = ( mx < drag_start ) and "min" or "max"
			end
		end

		-- Hover detection
		local xlo = math.Clamp( val_to_slider_x( val_min, w ), track_x, track_end )
		local xhi = math.Clamp( val_to_slider_x( val_max, w ), track_x, track_end )
		if my >= BASE_Y and my <= BASE_Y + ENTRY_H then
			if math.abs( mx - xlo ) <= handle_r + 4 then hover_h = "min"
			elseif math.abs( mx - xhi ) <= handle_r + 4 then hover_h = "max"
			else hover_h = nil end
		else
			hover_h = nil
		end

		-- Drag
		if dragging == "min" then
			set_min( slider_x_to_val( mx, w ) )
		elseif dragging == "max" then
			set_max( slider_x_to_val( mx, w ) )
		end
	end

	-- ── Mouse wheel zoom ──
	pnl.OnMouseWheeled = function( self, delta )
		local mx = select( 1, self:CursorPos() )
		local w  = self:GetWide()
		-- Center zoom on the value under the cursor
		local center_val = view_min + ( math.Clamp( (mx - PAD) / (w - PAD*2), 0, 1 ) ) * ( view_max - view_min )
		local cur_range  = view_max - view_min
		local factor     = 0.75
		local new_range
		if delta > 0 then
			new_range = cur_range * factor        -- zoom in
		else
			new_range = cur_range / factor        -- zoom out
		end
		-- Clamp to sane bounds
		local full_range = range_max - range_min
		local min_range  = full_range * 0.01
		new_range = math.Clamp( new_range, min_range, full_range )
		-- Re-center
		local t = math.Clamp( ( center_val - view_min ) / cur_range, 0, 1 )
		view_min = center_val - new_range * t
		view_max = center_val + new_range * ( 1 - t )
		-- Clamp to absolute bounds
		if view_min < range_min then
			view_max = view_max + ( range_min - view_min )
			view_min = range_min
		end
		if view_max > range_max then
			view_min = view_min - ( view_max - range_max )
			view_max = range_max
		end
		view_min = math.max( view_min, range_min )
		view_max = math.min( view_max, range_max )
		return true   -- consume the event (prevent parent scroll)
	end

	-- Sync from ConVar when changed externally
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

	pnl.PerformLayout = function( self, w, h )
		if IsValid(te_min) then
			te_min:SetPos( PAD + LABEL_W, BASE_Y )
			te_min:SetSize( ENTRY_W, ENTRY_H )
		end
		if IsValid(te_max) then
			te_max:SetPos( w - PAD - ENTRY_W, BASE_Y )
			te_max:SetSize( ENTRY_W, ENTRY_H )
		end
	end

	-- ── Text entries (left and right side at same height as slider) ──
	te_min = vgui.Create( "DTextEntry", pnl )
	te_min:SetPos( PAD + LABEL_W, BASE_Y )
	te_min:SetSize( ENTRY_W, ENTRY_H )
	te_min:SetValue( fmt( val_min ) )
	te_min:SetNumeric( true )
	te_min.OnEnter = function( self )
		set_min( tonumber( self:GetValue() ) or val_min )
		self:SetValue( fmt( val_min ) )
	end
	te_min.OnLoseFocus = te_min.OnEnter

	te_max = vgui.Create( "DTextEntry", pnl )
	te_max:SetPos( 200, BASE_Y )  -- will be positioned correctly in PerformLayout
	te_max:SetSize( ENTRY_W, ENTRY_H )
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

	local W, H = SW * 0.35, SH * 0.95
	local menu = ZDEV.VGUI.CreateFrame( W, H, "ZDEV - Particle System Editor" )
	menu:SetPos( 0, 0 )

	local RefreshSystemList, RefreshEmitterList, RefreshMaterials

	-- ── Menu bar ─────────────────────────────────────────────────────────────
	menu.mb = vgui.Create( "DMenuBar", menu )
	menu.mb:DockMargin( 2, 2, 2, 0 )

	-- FILE menu
	menu.mb.m1 = menu.mb:AddMenu( "File" )
	menu.mb.m1:AddOption( "New Project", function()
		Derma_StringRequest( "New Project", "Enter project name:", "NewProject", function(txt)
			ZEDIT.FX.NewProject( txt )
			RefreshSystemList()
		end )
	end ):SetIcon( "icon16/page_white_add.png" )
	menu.mb.m1:AddOption( "Open", function()
		ZDEV.VGUI.FilePicker({
			title       = "Open Project",
			dir         = ZEDIT.FX.SAVE_DIR,
			ext         = "*.json",
			allowDelete = true,
			onSelect    = function( filename )
				ZEDIT.FX.LoadProject( filename )
				RefreshSystemList()
			end,
		})
	end ):SetIcon( "icon16/folder.png" )
	menu.mb.m1:AddOption( "Save",     function() ZEDIT.FX.SaveProject() end ):SetIcon( "icon16/disk.png" )
	menu.mb.m1:AddOption( "Save As...", function()
		Derma_StringRequest( "Save As", "Enter filename:", ZEDIT.FX.CurrentProject.Filename, function(txt)
			ZEDIT.FX.SaveProject( txt )
		end )
	end ):SetIcon( "icon16/page_save.png" )
	menu.mb.m1:AddSpacer()
	menu.mb.m1:AddOption( "Export to Clipboard", function() ZEDIT.FX.ExportToClipboard() end ):SetIcon( "icon16/page_copy.png" )
	menu.mb.m1:AddOption( "Import from Text...", function()
		local f  = ZDEV.VGUI.CreateFrame( SW*0.4, SH*0.3, "Import JSON" )
		local te = vgui.Create( "DTextEntry", f )
		te:Dock( FILL ) ; te:SetMultiline( true ) ; te:SetPlaceholderText( "Paste JSON data here..." )
		local btn = ZDEV.VGUI.CreateButton( f, 100, 28, "IMPORT", "raj", Color(100,255,100), function()
			if ZEDIT.FX.ImportFromText( te:GetValue() ) then RefreshSystemList() ; f:Close() end
		end )
		btn:Dock( BOTTOM )
	end ):SetIcon( "icon16/page_paste.png" )
	menu.mb.m1:AddSpacer()
	menu.mb.m1:AddOption( "Close", function() menu:Close() end ):SetIcon( "icon16/cross.png" )

	-- VIEW menu
	menu.mb.m_view = menu.mb:AddMenu( "View" )
	local preview_opt = menu.mb.m_view:AddOption( "Show Preview Window", function()
		if ZEDIT.FX.PREVIEW_WINDOW_OPEN then
			ZEDIT.FX.ClosePreviewWindow()
		else
			ZEDIT.FX.OpenPreviewWindow()
		end
	end )
	preview_opt:SetIcon( "icon16/monitor.png" )
	preview_opt:SetIsCheckable( true )
	preview_opt:SetChecked( ZEDIT.FX.PREVIEW_WINDOW_OPEN )
	-- Keep the checkbox in sync when the menu is opened
	menu.mb.m_view.Think = function( self )
		if IsValid( preview_opt ) then
			preview_opt:SetChecked( ZEDIT.FX.PREVIEW_WINDOW_OPEN )
		end
	end

	-- SPAWN menu
	menu.mb.m2 = menu.mb:AddMenu( "Spawn" )
	menu.mb.m2:AddOption( "Spawn Selected System (Once)",  function() ZEDIT.FX.SpawnOnce() end ):SetIcon( "icon16/wand.png" )
	menu.mb.m2:AddOption( "Spawn All Systems (Once)",      function() ZEDIT.FX.SpawnAll() end ):SetIcon( "icon16/lightning.png" )
	menu.mb.m2:AddSpacer()
	menu.mb.m2:AddOption( "Spawn System (Persistent)",     function()
		local pos = ZEDIT.FX.GetSpawnPos()
		local sys = ZEDIT.FX.GetSelectedSystem()
		if sys then ZEDIT.FX.SpawnSystem( pos, sys ) end
	end ):SetIcon( "icon16/control_play.png" )
	menu.mb.m2:AddOption( "Stop All Active Systems",       function() ZEDIT.FX.StopAllSystems() end ):SetIcon( "icon16/control_stop.png" )
	menu.mb.m2:AddSpacer()
	menu.mb.m2:AddOption( "Start Preview Loop",   function() ZEDIT.FX.StartPreview() end ):SetIcon( "icon16/control_play_blue.png" )
	menu.mb.m2:AddOption( "Stop Preview",          function() ZEDIT.FX.StopPreview()  end ):SetIcon( "icon16/control_stop_blue.png" )

	-- EXPORT menu
	menu.mb.m_export = menu.mb:AddMenu( "Export" )
	menu.mb.m_export:AddOption( "Export as Scripted Effect (EFFECT)", function()
		local sys = ZEDIT.FX.GetSelectedSystem()
		if not sys or #sys.emitters == 0 then
			Derma_Message( "Select a system with at least one emitter first.", "Export", "OK" )
			return
		end
		local code = ZEDIT.FX.GenerateEffectCode( sys )
		local name = string.lower( string.gsub( sys.name or "effect", " ", "_" ) )
		ZEDIT.FX.ShowExportWindow( "Export: Scripted Effect — " .. sys.name, code, name .. "_init.lua" )
	end ):SetIcon( "icon16/script_code.png" )

	menu.mb.m_export:AddOption( "Export as Scripted Entity (SENT)", function()
		local sys = ZEDIT.FX.GetSelectedSystem()
		if not sys or #sys.emitters == 0 then
			Derma_Message( "Select a system with at least one emitter first.", "Export", "OK" )
			return
		end
		local files = ZEDIT.FX.GenerateEntityCode( sys )
		local name = string.lower( string.gsub( sys.name or "ent", " ", "_" ) )
		ZEDIT.FX.ShowExportWindowTabs( "Export: Scripted Entity — " .. sys.name, {
			{ name = "shared.lua",  code = files.shared,  icon = "icon16/script_code.png" },
			{ name = "init.lua",    code = files.init,    icon = "icon16/server.png" },
			{ name = "cl_init.lua", code = files.cl_init, icon = "icon16/monitor.png" },
		} )
	end ):SetIcon( "icon16/brick.png" )

	menu.mb.m_export:AddSpacer()

	menu.mb.m_export:AddOption( "Export Project JSON to Clipboard", function()
		ZEDIT.FX.ExportToClipboard()
	end ):SetIcon( "icon16/page_copy.png" )

	-- ── Info bar ─────────────────────────────────────────────────────────────
	menu.pn_info = vgui.Create( "DPanel", menu )
	menu.pn_info:Dock( TOP )
	menu.pn_info:SetTall( 50 )
	menu.pn_info:DockMargin( 2, 2, 2, 2 )
	menu.pn_info.Paint = function( self, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, Color( 40, 45, 55, 255 ) )
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 1, Color( 80, 120, 180, 255 ) )
		draw.SimpleText( "Project: " .. ZEDIT.FX.CurrentProject.Name, "DermaDefaultBold", 8, 4, color_white )
		draw.SimpleText( "Systems: " .. #ZEDIT.FX.CurrentProject.Systems, "DermaDefault", 8, 18, Color(180,180,180) )
		local sys = ZEDIT.FX.GetSelectedSystem()
		draw.SimpleText( "Emitters: " .. ( sys and #sys.emitters or 0 ), "DermaDefault", 8, 32, Color(160,160,180) )
		local active_count = table.Count( ZEDIT.FX.ACTIVE_SYSTEMS )
		local status = ZEDIT.FX.PREVIEW_ENABLED and "PREVIEW" or ( active_count > 0 and ( active_count .. " ACTIVE" ) or "IDLE" )
		local clr    = ZEDIT.FX.PREVIEW_ENABLED and Color(100,255,100) or ( active_count > 0 and Color(255,200,80) or Color(150,150,150) )
		draw.SimpleText( status, "DermaDefaultBold", w - 80, 18, clr )
	end

	-- ── Toolbar ──────────────────────────────────────────────────────────────
	menu.pn = vgui.Create( "DPanel", menu )
	menu.pn:Dock( TOP ) ; menu.pn:SetTall( 32 ) ; menu.pn:DockMargin( 2, 0, 2, 2 )
	menu.pn.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color( 50, 55, 65, 255 ) ) end

	local function tb_btn( text, clr, fn )
		local b = ZDEV.VGUI.CreateButton( menu.pn, 64, 28, text, "raj", clr, fn )
		b:Dock( LEFT ) ; b:DockMargin( 2, 2, 2, 2 )
		return b
	end

	tb_btn( "SPAWN", Color(100,200,255), function() ZEDIT.FX.SpawnOnce() end )
	tb_btn( "ACTIVE", Color(130,255,130), function()
		local pos = ZEDIT.FX.GetSpawnPos()
		local sys = ZEDIT.FX.GetSelectedSystem()
		if sys then ZEDIT.FX.SpawnSystem( pos, sys ) end
	end )
	tb_btn( "LOOP", Color(255,200,100), function()
		if ZEDIT.FX.PREVIEW_ENABLED then ZEDIT.FX.StopPreview() else ZEDIT.FX.StartPreview() end
	end )
	tb_btn( "STOP", Color(255,100,100), function()
		ZEDIT.FX.StopPreview()
		ZEDIT.FX.StopAllSystems()
	end )
	local btn_save = ZDEV.VGUI.CreateButton( menu.pn, 64, 28, "SAVE", "raj", Color(255,150,100), function() ZEDIT.FX.SaveProject() end )
	btn_save:Dock( RIGHT ) ; btn_save:DockMargin( 2, 2, 2, 2 )

	-- ═════════════════════════════════════════════════════════════════════════
	--  SYSTEM LIST
	-- ═════════════════════════════════════════════════════════════════════════
	local sys_header = vgui.Create( "DPanel", menu )
	sys_header:Dock( TOP ) ; sys_header:SetTall( 22 ) ; sys_header:DockMargin( 2, 0, 2, 0 )
	sys_header.Paint = function( s, w, h )
		draw.RoundedBox( 3, 0, 0, w, h, Color( 55, 60, 75, 255 ) )
		draw.SimpleText( "  Particle Systems", "DermaDefaultBold", 4, 3, Color( 200, 220, 255 ) )
	end

	local sys_tb = vgui.Create( "DPanel", menu )
	sys_tb:Dock( TOP ) ; sys_tb:SetTall( 26 ) ; sys_tb:DockMargin( 2, 0, 2, 2 )
	sys_tb.Paint = function( s, w, h ) draw.RoundedBox( 3, 0, 0, w, h, Color( 45, 50, 60, 255 ) ) end

	local function sys_tb_btn( text, clr, fn )
		local b = ZDEV.VGUI.CreateButton( sys_tb, 50, 22, text, "DermaDefault", clr, fn )
		b:Dock( LEFT ) ; b:DockMargin( 2, 2, 2, 2 )
		return b
	end

	sys_tb_btn( "+ New", Color(100,255,100), function()
		Derma_StringRequest( "New System", "System name:", "New System", function(txt)
			ZEDIT.FX.NewSystem( txt )
			RefreshSystemList()
		end )
	end )
	sys_tb_btn( "Dup", Color(180,200,255), function()
		ZEDIT.FX.DuplicateSystem( ZEDIT.FX.SelectedSystemIdx )
		RefreshSystemList()
	end )
	sys_tb_btn( "Del", Color(255,100,100), function()
		local sys = ZEDIT.FX.GetSelectedSystem()
		if sys then
			Derma_Query( "Delete system '" .. sys.name .. "'?", "Confirm", "Yes", function()
				ZEDIT.FX.RemoveSystem( ZEDIT.FX.SelectedSystemIdx )
				RefreshSystemList()
			end, "No" )
		end
	end )

	menu.sys_lv_pnl = vgui.Create( "DPanel", menu )
	menu.sys_lv_pnl:Dock( TOP ) ; menu.sys_lv_pnl:SetTall( H * 0.08 ) ; menu.sys_lv_pnl:DockMargin( 2, 0, 2, 2 )
	menu.sys_lv_pnl.Paint = function( self, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, Color( 30, 35, 45, 255 ) )
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 1, Color( 60, 100, 150, 255 ) )
	end

	menu.sys_lv = vgui.Create( "DListView", menu.sys_lv_pnl )
	menu.sys_lv:Dock( FILL ) ; menu.sys_lv:DockMargin( 2, 2, 2, 2 ) ; menu.sys_lv:SetMultiSelect( false )
	menu.sys_lv:AddColumn( "#" ):SetWidth( 20 )
	menu.sys_lv:AddColumn( "Name" ):SetWidth( 120 )
	menu.sys_lv:AddColumn( "Emitters" ):SetWidth( 50 )
	menu.sys_lv:AddColumn( "ID" ):SetWidth( 80 )

	menu.sys_lv.OnRowSelected = function( lst, index )
		ZEDIT.FX.SelectedSystemIdx = index
		ZEDIT.FX.SelectedEmitterIdx = 1
		RefreshEmitterList()
		local em = ZEDIT.FX.GetSelectedEmitter()
		if em then ZEDIT.FX.SetConVars( em ) end
	end

	menu.sys_lv.OnRowRightClick = function( lst, index )
		local dm = DermaMenu()
		dm:AddOption( "Rename", function()
			local sys = ZEDIT.FX.CurrentProject.Systems[ index ]
			if sys then
				Derma_StringRequest( "Rename System", "New name:", sys.name, function(txt)
					sys.name = txt ; RefreshSystemList()
				end )
			end
		end ):SetIcon( "icon16/pencil.png" )
		dm:AddOption( "Duplicate", function()
			ZEDIT.FX.DuplicateSystem( index ) ; RefreshSystemList()
		end ):SetIcon( "icon16/page_copy.png" )
		dm:AddOption( "Spawn Once", function()
			local sys = ZEDIT.FX.CurrentProject.Systems[ index ]
			if sys then ZEDIT.FX.SpawnSystemOnce( ZEDIT.FX.GetSpawnPos(), sys ) end
		end ):SetIcon( "icon16/wand.png" )
		dm:AddOption( "Spawn Active", function()
			local sys = ZEDIT.FX.CurrentProject.Systems[ index ]
			if sys then ZEDIT.FX.SpawnSystem( ZEDIT.FX.GetSpawnPos(), sys ) end
		end ):SetIcon( "icon16/control_play.png" )
		dm:AddSpacer()
		dm:AddOption( "Delete", function()
			Derma_Query( "Delete this system?", "Confirm", "Yes", function()
				ZEDIT.FX.RemoveSystem( index ) ; RefreshSystemList()
			end, "No" )
		end ):SetIcon( "icon16/delete.png" )
		dm:Open()
	end

	-- ═════════════════════════════════════════════════════════════════════════
	--  EMITTER LIST
	-- ═════════════════════════════════════════════════════════════════════════
	local em_header = vgui.Create( "DPanel", menu )
	em_header:Dock( TOP ) ; em_header:SetTall( 22 ) ; em_header:DockMargin( 2, 0, 2, 0 )
	em_header.Paint = function( s, w, h )
		draw.RoundedBox( 3, 0, 0, w, h, Color( 55, 60, 75, 255 ) )
		local sys = ZEDIT.FX.GetSelectedSystem()
		local title = sys and ( "  Emitters - " .. sys.name ) or "  Emitters (no system selected)"
		draw.SimpleText( title, "DermaDefaultBold", 4, 3, Color( 255, 220, 150 ) )
	end

	local em_tb = vgui.Create( "DPanel", menu )
	em_tb:Dock( TOP ) ; em_tb:SetTall( 26 ) ; em_tb:DockMargin( 2, 0, 2, 2 )
	em_tb.Paint = function( s, w, h ) draw.RoundedBox( 3, 0, 0, w, h, Color( 45, 50, 60, 255 ) ) end

	local function em_tb_btn( text, clr, fn )
		local b = ZDEV.VGUI.CreateButton( em_tb, 60, 22, text, "DermaDefault", clr, fn )
		b:Dock( LEFT ) ; b:DockMargin( 2, 2, 2, 2 )
		return b
	end

	em_tb_btn( "+ Add", Color(100,255,100), function()
		local sys = ZEDIT.FX.GetSelectedSystem()
		if not sys then zdev.log( "I", "Create a system first!" ) ; return end
		ZEDIT.FX.AddEmitter( ZEDIT.FX.SelectedSystemIdx, ZEDIT.FX.GetConVars() )
		RefreshEmitterList()
	end )
	em_tb_btn( "Dup", Color(180,200,255), function()
		ZEDIT.FX.DuplicateEmitter( ZEDIT.FX.SelectedSystemIdx, ZEDIT.FX.SelectedEmitterIdx )
		RefreshEmitterList()
	end )
	em_tb_btn( "Update", Color(100,200,255), function()
		local sys = ZEDIT.FX.GetSelectedSystem()
		if sys and sys.emitters[ ZEDIT.FX.SelectedEmitterIdx ] then
			sys.emitters[ ZEDIT.FX.SelectedEmitterIdx ] = ZEDIT.FX.GetConVars()
			RefreshEmitterList()
			zdev.log( "S", "Updated emitter at index " .. ZEDIT.FX.SelectedEmitterIdx )
		end
	end )
	em_tb_btn( "Del", Color(255,100,100), function()
		local sys = ZEDIT.FX.GetSelectedSystem()
		if sys and sys.emitters[ ZEDIT.FX.SelectedEmitterIdx ] then
			Derma_Query( "Delete this emitter?", "Confirm", "Yes", function()
				ZEDIT.FX.RemoveEmitter( ZEDIT.FX.SelectedSystemIdx, ZEDIT.FX.SelectedEmitterIdx )
				RefreshEmitterList()
			end, "No" )
		end
	end )

	menu.em_lv_pnl = vgui.Create( "DPanel", menu )
	menu.em_lv_pnl:Dock( TOP ) ; menu.em_lv_pnl:SetTall( H * 0.08 ) ; menu.em_lv_pnl:DockMargin( 2, 0, 2, 2 )
	menu.em_lv_pnl.Paint = function( self, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, Color( 35, 40, 50, 255 ) )
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 1, Color( 100, 80, 50, 255 ) )
	end

	menu.em_lv = vgui.Create( "DListView", menu.em_lv_pnl )
	menu.em_lv:Dock( FILL ) ; menu.em_lv:DockMargin( 2, 2, 2, 2 ) ; menu.em_lv:SetMultiSelect( false )
	menu.em_lv:AddColumn( "#" ):SetWidth( 20 )
	menu.em_lv:AddColumn( "ID" ):SetWidth( 80 )
	menu.em_lv:AddColumn( "Sprites" ):SetWidth( 60 )
	menu.em_lv:AddColumn( "DieTime" ):SetWidth( 50 )
	menu.em_lv:AddColumn( "Size" ):SetWidth( 40 )

	menu.em_lv.OnRowSelected = function( lst, index )
		ZEDIT.FX.SelectedEmitterIdx = index
		local em = ZEDIT.FX.GetSelectedEmitter()
		if em then ZEDIT.FX.SetConVars( em ) end
	end

	menu.em_lv.OnRowRightClick = function( lst, index )
		local dm = DermaMenu()
		dm:AddOption( "Edit", function()
			ZEDIT.FX.SelectedEmitterIdx = index
			local em = ZEDIT.FX.GetSelectedEmitter()
			if em then ZEDIT.FX.SetConVars( em ) end
		end ):SetIcon( "icon16/pencil.png" )
		dm:AddOption( "Duplicate", function()
			ZEDIT.FX.DuplicateEmitter( ZEDIT.FX.SelectedSystemIdx, index )
			RefreshEmitterList()
		end ):SetIcon( "icon16/page_copy.png" )
		dm:AddOption( "Spawn This Emitter", function()
			local sys = ZEDIT.FX.GetSelectedSystem()
			if sys and sys.emitters[ index ] then
				ZEDIT.FX.SpawnParticle( ZEDIT.FX.GetSpawnPos(), sys.emitters[ index ] )
			end
		end ):SetIcon( "icon16/wand.png" )
		dm:AddSpacer()
		dm:AddOption( "Delete", function()
			Derma_Query( "Delete this emitter?", "Confirm", "Yes", function()
				ZEDIT.FX.RemoveEmitter( ZEDIT.FX.SelectedSystemIdx, index )
				RefreshEmitterList()
			end, "No" )
		end ):SetIcon( "icon16/delete.png" )
		dm:Open()
	end

	-- ═════════════════════════════════════════════════════════════════════════
	--  ACTIVE SYSTEMS LIST
	-- ═════════════════════════════════════════════════════════════════════════
	local act_header = vgui.Create( "DPanel", menu )
	act_header:Dock( TOP ) ; act_header:SetTall( 22 ) ; act_header:DockMargin( 2, 0, 2, 0 )
	act_header.Paint = function( s, w, h )
		draw.RoundedBox( 3, 0, 0, w, h, Color( 55, 45, 45, 255 ) )
		draw.SimpleText( "  Active Systems (" .. table.Count( ZEDIT.FX.ACTIVE_SYSTEMS ) .. ")", "DermaDefaultBold", 4, 3, Color( 255, 150, 100 ) )
	end

	menu.act_lv_pnl = vgui.Create( "DPanel", menu )
	menu.act_lv_pnl:Dock( TOP ) ; menu.act_lv_pnl:SetTall( H * 0.05 ) ; menu.act_lv_pnl:DockMargin( 2, 0, 2, 2 )
	menu.act_lv_pnl.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color( 40, 30, 30, 255 ) ) end

	menu.act_lv = vgui.Create( "DListView", menu.act_lv_pnl )
	menu.act_lv:Dock( FILL ) ; menu.act_lv:DockMargin( 2, 2, 2, 2 ) ; menu.act_lv:SetMultiSelect( false )
	menu.act_lv:AddColumn( "UID" ):SetWidth( 100 )
	menu.act_lv:AddColumn( "System" ):SetWidth( 100 )
	menu.act_lv:AddColumn( "Emitters" ):SetWidth( 50 )

	local function RefreshActiveList()
		menu.act_lv:Clear()
		for uid, inst in pairs( ZEDIT.FX.ACTIVE_SYSTEMS ) do
			menu.act_lv:AddLine( uid, inst.system.name, #inst.em_states )
		end
	end

	menu.act_lv.OnRowRightClick = function( lst, index )
		local line = lst:GetLine( index )
		if not line then return end
		local uid = line:GetColumnText( 1 )
		local dm = DermaMenu()
		dm:AddOption( "Stop", function()
			ZEDIT.FX.StopSystem( uid ) ; RefreshActiveList()
		end ):SetIcon( "icon16/control_stop.png" )
		dm:Open()
	end

	menu.act_lv_pnl.Think = function( self )
		if not self.m_flNextRefresh or CurTime() > self.m_flNextRefresh then
			self.m_flNextRefresh = CurTime() + 1.0
			RefreshActiveList()
		end
	end

	-- ═════════════════════════════════════════════════════════════════════════
	--  EMITTER PROPERTIES
	-- ═════════════════════════════════════════════════════════════════════════
	menu.sp_L = vgui.Create( "DScrollPanel", menu )
	menu.sp_L:Dock( FILL ) ; menu.sp_L:DockMargin( 2, 0, 2, 2 )
	menu.sp_L.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color( 45, 50, 60, 255 ) ) end

	local form_item_h = 18
	menu.sp_L.f = vgui.Create( "DForm", menu.sp_L )
	menu.sp_L.f:Dock( TOP )
	menu.sp_L.f:SetName( "Emitter Properties" )

	menu.sp_L.f:TextEntry( "Emitter ID", "zdev_edit_particle_id" ):SetTall( form_item_h )

	--[[  SPAWN OFFSET  ]]
	menu.sp_L.f:ControlHelp( "===== Spawn Offset =====" ):SetTall( form_item_h )
	menu.sp_L.f:NumSlider( "Offset X", "zdev_edit_particle_spawn_x", -500, 500, 1 ):SetTall( form_item_h + 8 )
	menu.sp_L.f:NumSlider( "Offset Y", "zdev_edit_particle_spawn_y", -500, 500, 1 ):SetTall( form_item_h + 8 )
	menu.sp_L.f:NumSlider( "Offset Z", "zdev_edit_particle_spawn_z", -500, 500, 1 ):SetTall( form_item_h + 8 )

	--[[  EMISSION MODE  ]]
	menu.sp_L.f:ControlHelp( "===== Emission Mode =====" ):SetTall( form_item_h )
	local emission_pnl = vgui.Create( "DPanel" )
	emission_pnl:SetTall( 32 )
	emission_pnl.Paint = function() end
	local emission_combo = vgui.Create( "DComboBox", emission_pnl )
	emission_combo:Dock( FILL )
	emission_combo:DockMargin( 2, 4, 2, 4 )
	emission_combo:AddChoice( "Instantaneous (all at once)", 0 )
	emission_combo:AddChoice( "Continuous (constant rate)", 1 )
	emission_combo:SetValue( GetConVarNumber( "zdev_edit_particle_emission_mode" ) )
	emission_combo.OnSelect = function( self, idx, val, data )
		RunConsoleCommand( "zdev_edit_particle_emission_mode", tostring( data ) )
	end
	menu.sp_L.f:AddItem( emission_pnl )

	--[[  SPRITE MATERIALS  ]]
	menu.sp_L.f:ControlHelp( "===== Sprite Materials =====" ):SetTall( form_item_h )

	local mat_list_pnl = vgui.Create( "DPanel", menu.sp_L.f )
	mat_list_pnl:SetTall( 4 )
	mat_list_pnl.Paint = function( s, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color( 25, 28, 38, 200 ) ) end

	local ROW_H = 30

	RefreshMaterials = function()
		mat_list_pnl:Clear()
		local mats = ZEDIT.FX.PARTICLE_MATERIALS
		local total_h = 4
		for i, mat_path in ipairs( mats ) do
			local row = vgui.Create( "DPanel", mat_list_pnl )
			row:SetPos( 2, total_h )
			row:SetSize( mat_list_pnl:GetWide() - 4, ROW_H )
			row.Paint = function( s, w, h ) draw.RoundedBox( 3, 0, 0, w, h, Color( 35, 38, 50, 200 ) ) end

			local img = vgui.Create( "DImage", row )
			img:SetPos( 2, 2 ) ; img:SetSize( 26, 26 ) ; img:SetImage( mat_path ) ; img:SetKeepAspect( true )

			local path_te = vgui.Create( "DTextEntry", row )
			path_te:SetPos( 32, 6 ) ; path_te:SetSize( row:GetWide() - 32 - 50, 18 ) ; path_te:SetValue( mat_path )
			path_te.OnEnter = function( self ) mats[i] = self:GetValue() ; img:SetImage( mats[i] ) end
			path_te.OnLoseFocus = path_te.OnEnter

			local browse = vgui.Create( "DButton", row )
			browse:SetSize( 22, 20 ) ; browse:SetText( "..." ) ; browse:SetFont( "DermaDefault" )
			browse:SetTooltip( "Browse materials" )
			browse.DoClick = function()
				ZDEV.VGUI.MaterialBrowser({
					title    = "Select Material [" .. i .. "]",
					startDir = "particles",
					onSelect = function( mat )
						mats[i] = mat
						RefreshMaterials()
					end,
				})
			end

			local rm = vgui.Create( "DButton", row )
			rm:SetSize( 20, 20 ) ; rm:SetText( "X" ) ; rm:SetFont( "DermaDefault" )
			rm.DoClick = function() table.remove( ZEDIT.FX.PARTICLE_MATERIALS, i ) ; RefreshMaterials() end

			row.PerformLayout = function( self, w, h )
				if IsValid(path_te) then path_te:SetPos( 32, 6 ) ; path_te:SetSize( w - 32 - 50, 18 ) end
				if IsValid(browse)  then browse:SetPos( w - 46, 5 ) end
				if IsValid(rm)      then rm:SetPos( w - 22, 5 ) end
			end
			total_h = total_h + ROW_H + 2
		end

		-- "+ Add Material" row with browse option
		local add_pnl = vgui.Create( "DPanel", mat_list_pnl )
		add_pnl:SetPos( 2, total_h ) ; add_pnl:SetSize( mat_list_pnl:GetWide() - 4, 22 )
		add_pnl.Paint = function() end

		local add_btn = vgui.Create( "DButton", add_pnl )
		add_btn:Dock( FILL ) ; add_btn:DockMargin( 0, 0, 2, 0 )
		add_btn:SetText( "+ Add Material" ) ; add_btn:SetFont( "DermaDefault" )
		add_btn.DoClick = function() table.insert( ZEDIT.FX.PARTICLE_MATERIALS, "particles/fire1" ) ; RefreshMaterials() end

		local browse_btn = vgui.Create( "DButton", add_pnl )
		browse_btn:Dock( RIGHT ) ; browse_btn:SetWide( 70 )
		browse_btn:SetText( "Browse..." ) ; browse_btn:SetFont( "DermaDefault" )
		browse_btn.DoClick = function()
			ZDEV.VGUI.MaterialBrowser({
				title    = "Add Material",
				startDir = "particles",
				onSelect = function( mat )
					table.insert( ZEDIT.FX.PARTICLE_MATERIALS, mat )
					RefreshMaterials()
				end,
			})
		end

		total_h = total_h + 22 + 4
		mat_list_pnl:SetTall( total_h )
	end

	mat_list_pnl.PerformLayout = function( self, w, h )
		for _, child in ipairs( self:GetChildren() ) do
			if IsValid(child) then
				child:SetWide( w - 4 )
				if child.PerformLayout then child:PerformLayout( w - 4, child:GetTall() ) end
			end
		end
	end

	menu.sp_L.f:AddItem( mat_list_pnl )
	ZEDIT.FX.OnMaterialsChanged = RefreshMaterials
	RefreshMaterials()

	--[[  SPAWN VOLUME  ]]
	menu.sp_L.f:ControlHelp( "===== Spawn Volume =====" ):SetTall( form_item_h )
	local vol_type_pnl = vgui.Create( "DPanel" )
	vol_type_pnl:SetTall( 32 )
	vol_type_pnl.Paint = function() end
	local vol_type_combo = vgui.Create( "DComboBox", vol_type_pnl )
	vol_type_combo:Dock( FILL )
	vol_type_combo:DockMargin( 2, 4, 2, 4 )
	vol_type_combo:AddChoice( "Sphere", 0 )
	vol_type_combo:AddChoice( "Box", 1 )
	vol_type_combo:AddChoice( "Cylinder", 2 )
	vol_type_combo:SetValue( GetConVarNumber( "zdev_edit_particle_spawn_vol_type" ) )
	vol_type_combo.OnSelect = function( self, idx, val, data )
		RunConsoleCommand( "zdev_edit_particle_spawn_vol_type", tostring( data ) )
	end
	menu.sp_L.f:AddItem( vol_type_pnl )

	menu.sp_L.f:ControlHelp( "--- Volume Position (randomized) ---" ):SetTall( form_item_h )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Pos X", "zdev_edit_particle_spawn_vol_pos_x_min", "zdev_edit_particle_spawn_vol_pos_x_max", -200, 200, 1 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Pos Y", "zdev_edit_particle_spawn_vol_pos_y_min", "zdev_edit_particle_spawn_vol_pos_y_max", -200, 200, 1 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Pos Z", "zdev_edit_particle_spawn_vol_pos_z_min", "zdev_edit_particle_spawn_vol_pos_z_max", -200, 200, 1 ) )

	menu.sp_L.f:ControlHelp( "--- Volume Scale (size) ---" ):SetTall( form_item_h )
	local vol_uniform_pnl = vgui.Create( "DPanel" )
	vol_uniform_pnl:SetTall( 20 )
	vol_uniform_pnl.Paint = function() end
	local vol_uniform_check = vgui.Create( "DCheckBoxLabel", vol_uniform_pnl )
	vol_uniform_check:Dock( FILL )
	vol_uniform_check:DockMargin( 4, 2, 4, 2 )
	vol_uniform_check:SetText( "Uniform Scale (all axes)" )
	vol_uniform_check:SetConVar( "zdev_edit_particle_spawn_vol_uniform_scale" )
	vol_uniform_check:SetValue( GetConVarNumber( "zdev_edit_particle_spawn_vol_uniform_scale" ) ~= 0 )
	menu.sp_L.f:AddItem( vol_uniform_pnl )

	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Scale X", "zdev_edit_particle_spawn_vol_scale_x_min", "zdev_edit_particle_spawn_vol_scale_x_max", 0.1, 100, 1 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Scale Y", "zdev_edit_particle_spawn_vol_scale_y_min", "zdev_edit_particle_spawn_vol_scale_y_max", 0.1, 100, 1 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Scale Z", "zdev_edit_particle_spawn_vol_scale_z_min", "zdev_edit_particle_spawn_vol_scale_z_max", 0.1, 100, 1 ) )

	--[[  SPAWN SETTINGS  ]]
	menu.sp_L.f:ControlHelp( "===== Spawn Settings =====" ):SetTall( form_item_h )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Count",       "zdev_edit_particle_count_min",  "zdev_edit_particle_count_max",  1,    200,  0 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Repeat Rate", "zdev_edit_particle_repeat_min", "zdev_edit_particle_repeat_max", 0.01, 10.0, 2 ) )

	--[[  TIME SETTINGS  ]]
	menu.sp_L.f:ControlHelp( "===== Time Settings =====" ):SetTall( form_item_h )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Lifetime", "zdev_edit_particle_lifetime_min", "zdev_edit_particle_lifetime_max", 0.0,  20.0, 2 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Die Time", "zdev_edit_particle_dietime_min",  "zdev_edit_particle_dietime_max",  0.0,  20.0, 2 ) )

	--[[  SIZE & ALPHA  ]]
	menu.sp_L.f:ControlHelp( "===== Size & Alpha =====" ):SetTall( form_item_h )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Start Size",   "zdev_edit_particle_size_s_min",   "zdev_edit_particle_size_s_max",   0, 200,  1 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "End Size",     "zdev_edit_particle_size_e_min",   "zdev_edit_particle_size_e_max",   0, 200,  1 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Start Alpha",  "zdev_edit_particle_alpha_s_min",  "zdev_edit_particle_alpha_s_max",  0, 255,  0 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "End Alpha",    "zdev_edit_particle_alpha_e_min",  "zdev_edit_particle_alpha_e_max",  0, 255,  0 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Start Length", "zdev_edit_particle_length_s_min", "zdev_edit_particle_length_s_max", 0, 200,  1 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "End Length",   "zdev_edit_particle_length_e_min", "zdev_edit_particle_length_e_max", 0, 200,  1 ) )

	--[[  COLOR  ]]
	menu.sp_L.f:ControlHelp( "===== Color =====" ):SetTall( form_item_h )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Red",   "zdev_edit_particle_color_r_min", "zdev_edit_particle_color_r_max", 0, 255, 0 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Green", "zdev_edit_particle_color_g_min", "zdev_edit_particle_color_g_max", 0, 255, 0 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Blue",  "zdev_edit_particle_color_b_min", "zdev_edit_particle_color_b_max", 0, 255, 0 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Alpha", "zdev_edit_particle_color_a_min", "zdev_edit_particle_color_a_max", 0, 255, 0 ) )
	menu.sp_L.f:CheckBox( "Use Lighting", "zdev_edit_particle_lighting" ):SetTall( form_item_h )

	--[[  ROTATION  ]]
	menu.sp_L.f:ControlHelp( "===== Rotation =====" ):SetTall( form_item_h )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Roll",       "zdev_edit_particle_roll_min",      "zdev_edit_particle_roll_max",      0,    360,  0 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Roll Delta", "zdev_edit_particle_rolldelta_min", "zdev_edit_particle_rolldelta_max", -360, 360,  0 ) )
	menu.sp_L.f:TextEntry( "Angles (P Y R)",   "zdev_edit_particle_angles"           ):SetTall( form_item_h )
	menu.sp_L.f:TextEntry( "Angular Velocity", "zdev_edit_particle_angular_velocity" ):SetTall( form_item_h )

	--[[  VELOCITY  ]]
	menu.sp_L.f:ControlHelp( "===== Velocity =====" ):SetTall( form_item_h )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Velocity X",   "zdev_edit_particle_vel_x_min",  "zdev_edit_particle_vel_x_max",  -500, 500, 1 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Velocity Y",   "zdev_edit_particle_vel_y_min",  "zdev_edit_particle_vel_y_max",  -500, 500, 1 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Velocity Z",   "zdev_edit_particle_vel_z_min",  "zdev_edit_particle_vel_z_max",  -500, 500, 1 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Velocity Mul", "zdev_edit_particle_velocity_mul_min", "zdev_edit_particle_velocity_mul_max", 0, 20.0, 2 ) )

	--[[  GRAVITY  ]]
	menu.sp_L.f:ControlHelp( "===== Gravity =====" ):SetTall( form_item_h )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Gravity X",    "zdev_edit_particle_grav_x_min", "zdev_edit_particle_grav_x_max", -500, 500, 1 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Gravity Y",    "zdev_edit_particle_grav_y_min", "zdev_edit_particle_grav_y_max", -500, 500, 1 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Gravity Z",    "zdev_edit_particle_grav_z_min", "zdev_edit_particle_grav_z_max", -500, 500, 1 ) )

	--[[  PHYSICS  ]]
	menu.sp_L.f:ControlHelp( "===== Physics =====" ):SetTall( form_item_h )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Air Resistance", "zdev_edit_particle_airres_min", "zdev_edit_particle_airres_max", 0, 500, 0 ) )
	menu.sp_L.f:AddItem( CreateRangeSlider( menu.sp_L.f, "Bounce",         "zdev_edit_particle_bounce_min", "zdev_edit_particle_bounce_max", 0, 2.0, 2 ) )
	menu.sp_L.f:CheckBox( "Collide", "zdev_edit_particle_collide" ):SetTall( form_item_h )

	-- ═════════════════════════════════════════════════════════════════════════
	--  BOTTOM ACTION BAR
	-- ═════════════════════════════════════════════════════════════════════════
	menu.pn_bottom = vgui.Create( "DPanel", menu )
	menu.pn_bottom:Dock( BOTTOM ) ; menu.pn_bottom:SetTall( 36 ) ; menu.pn_bottom:DockMargin( 2, 2, 2, 2 )
	menu.pn_bottom.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color( 40, 45, 55, 255 ) ) end

	local btn_reset = ZDEV.VGUI.CreateButton( menu.pn_bottom, 64, 30, "RESET", "raj", Color(255,200,100), function()
		RunConsoleCommand( "zdev_edit_particle_id",          "emitter_01" )
		RunConsoleCommand( "zdev_edit_particle_dietime_min", "1" )
		RunConsoleCommand( "zdev_edit_particle_dietime_max", "1" )
		RunConsoleCommand( "zdev_edit_particle_size_s_min",  "8" )
		RunConsoleCommand( "zdev_edit_particle_size_s_max",  "8" )
		RunConsoleCommand( "zdev_edit_particle_size_e_min",  "2" )
		RunConsoleCommand( "zdev_edit_particle_size_e_max",  "2" )
		RunConsoleCommand( "zdev_edit_particle_vel_x_min",   "0" )
		RunConsoleCommand( "zdev_edit_particle_vel_x_max",   "0" )
		RunConsoleCommand( "zdev_edit_particle_vel_y_min",   "0" )
		RunConsoleCommand( "zdev_edit_particle_vel_y_max",   "0" )
		RunConsoleCommand( "zdev_edit_particle_vel_z_min",   "0" )
		RunConsoleCommand( "zdev_edit_particle_vel_z_max",   "50" )
		RunConsoleCommand( "zdev_edit_particle_grav_x_min",  "0" )
		RunConsoleCommand( "zdev_edit_particle_grav_x_max",  "0" )
		RunConsoleCommand( "zdev_edit_particle_grav_y_min",  "0" )
		RunConsoleCommand( "zdev_edit_particle_grav_y_max",  "0" )
		RunConsoleCommand( "zdev_edit_particle_grav_z_min",  "-100" )
		RunConsoleCommand( "zdev_edit_particle_grav_z_max",  "-100" )
		RunConsoleCommand( "zdev_edit_particle_spawn_x",     "0" )
		RunConsoleCommand( "zdev_edit_particle_spawn_y",     "0" )
		RunConsoleCommand( "zdev_edit_particle_spawn_z",     "0" )
		ZEDIT.FX.PARTICLE_MATERIALS = { "particles/fire1" }
		RefreshMaterials()
		zdev.log( "I", "Reset emitter settings to defaults" )
	end )
	btn_reset:Dock( LEFT ) ; btn_reset:DockMargin( 2, 2, 2, 2 )

	local btn_close = ZDEV.VGUI.CreateButton( menu.pn_bottom, 64, 30, "CLOSE", "raj", Color(255,100,100), function()
		ZEDIT.FX.StopPreview() ; menu:Close()
	end )
	btn_close:Dock( RIGHT ) ; btn_close:DockMargin( 2, 2, 2, 2 )

	-- ═════════════════════════════════════════════════════════════════════════
	--  REFRESH FUNCTIONS
	-- ═════════════════════════════════════════════════════════════════════════

	RefreshSystemList = function()
		if not IsValid( menu.sys_lv ) then return end
		menu.sys_lv:Clear()
		for i, sys in ipairs( ZEDIT.FX.CurrentProject.Systems ) do
			menu.sys_lv:AddLine( i, sys.name, #sys.emitters, sys.id )
		end
		if ZEDIT.FX.SelectedSystemIdx <= #ZEDIT.FX.CurrentProject.Systems then
			menu.sys_lv:SelectItem( menu.sys_lv:GetLine( ZEDIT.FX.SelectedSystemIdx ) )
		end
		RefreshEmitterList()
	end

	RefreshEmitterList = function()
		if not IsValid( menu.em_lv ) then return end
		menu.em_lv:Clear()
		local sys = ZEDIT.FX.GetSelectedSystem()
		if not sys then return end
		for i, em in ipairs( sys.emitters ) do
			local mat_str
			local mats = em.materials
			if mats and #mats > 0 then
				mat_str = #mats > 1 and ( "x" .. #mats .. " sprites" ) or mats[1]
			else
				mat_str = em.material or "(none)"
			end
			menu.em_lv:AddLine( i, em.id or ("emitter_" .. i), mat_str, em.dietime_min or em.dietime or 1, em.size_s_min or em.start_size or 8 )
		end
		if ZEDIT.FX.SelectedEmitterIdx <= #sys.emitters then
			menu.em_lv:SelectItem( menu.em_lv:GetLine( ZEDIT.FX.SelectedEmitterIdx ) )
		end
	end

	RefreshSystemList()

	menu.OnClose = function()
		ZEDIT.FX.StopPreview()
		ZEDIT.FX.OnMaterialsChanged = nil
	end

	return menu
end

-- ─── Console commands ─────────────────────────────────────────────────────────
ZDEV.CMDS.Register( "zdev_edit_particle_editor", function()
	ZDEV.VGUI.ParticleEditor()
end, { aliases = { "zedit_particle_editor" } } )

ZDEV.CMDS.Register( "zdev_edit_particle_spawn", function()
	ZEDIT.FX.SpawnOnce()
end, { aliases = { "zedit_particle_spawn" } } )

ZDEV.CMDS.Register( "zdev_edit_particle_preview_start", function()
	ZEDIT.FX.StartPreview()
end, { aliases = { "zedit_particle_preview_start" } } )

ZDEV.CMDS.Register( "zdev_edit_particle_preview_stop", function()
	ZEDIT.FX.StopPreview()
end, { aliases = { "zedit_particle_preview_stop" } } )

ZDEV.CMDS.Register( "zdev_edit_particle_stop_all", function()
	ZEDIT.FX.StopAllSystems()
	ZEDIT.FX.StopPreview()
end, { aliases = { "zedit_particle_stop_all" } } )

ZDEV.CMDS.Register( "zdev_edit_particle_preview_window", function()
	if ZEDIT.FX.PREVIEW_WINDOW_OPEN then
		ZEDIT.FX.ClosePreviewWindow()
	else
		ZEDIT.FX.OpenPreviewWindow()
	end
end, { aliases = { "zedit_particle_preview_window" } } )

ZDEV.VGUI.AddToMainMenu( "zdev_edit_particle_editor" )

ZDEV.FILE.SetLoaded( _f )

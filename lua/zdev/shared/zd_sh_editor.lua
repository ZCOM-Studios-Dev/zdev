local _f = 'zdev/shared/zd_sh_editor.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end

if !ZDEV.EDIT then
	zdev.log( "E", "Primary Data-Table is nil or invalid! 'ZDEV.EDIT' ")
	return
end

BRUSH_NONE			= 0
BRUSH_GRASS 		= 1
BRUSH_SHRUB 		= 2	
BRUSH_TREE 			= 3
BRUSH_ROCK 			= 4
BRUSH_OTHER 		= 5

EDITMODE_NONE 		= 0
EDITMODE_EFFECT 	= 1
EDITMODE_ENV 		= 2
EDITMODE_NPC 		= 3
EDITMODE_WEAPON 	= 4
EDITMODE_ENTITY 	= 5
EDITMODE_PLAYER 	= 6
EDITMODE_MATERIAL 	= 7

EDIT_TOOL_NONE 		= 0
EDIT_TOOL_VIEW 		= 1
EDIT_TOOL_SELECT 	= 2
EDIT_TOOL_BRUSH 	= 3
EDIT_TOOL_ERASE 	= 4

-- ─── Editor convars (owned here since Sweep Phase 3; canonicalized Phase 4b:
-- zdev_edit_env_* authoritative, old zedit_env_* names mirror via LegacyAlias) ─
if CLIENT then
	local function EditorVar( name, default, shouldsave, userinfo, help )
		local cv = CreateClientConVar( name, default, shouldsave, userinfo, help or "" )
		ZDEV.CONV.LegacyAlias( name, ( string.gsub( name, "^zdev_edit_", "zedit_" ) ) )
		return cv
	end

	EditorVar( "zdev_edit_env_toggle", "0", true, false, "" )
	EditorVar( "zdev_edit_env_tool_mode", "0", true, true, "" )
	EditorVar( "zdev_edit_env_brush_mode", "1", true, true, "" )
	EditorVar( "zdev_edit_env_brush_radius", "128", true, false, "" )
	EditorVar( "zdev_edit_env_brush_spacing", "16", true, false, "" )
	EditorVar( "zdev_edit_env_brush_density", "0.5", true, false, "" )
	EditorVar( "zdev_edit_env_brush_flow", "32", true, false, "" )
	EditorVar( "zdev_edit_env_factor_trees", "1.0", true, false, "" )
	EditorVar( "zdev_edit_env_factor_shrubs", "1.0", true, false, "" )
	EditorVar( "zdev_edit_env_factor_grass", "1.0", true, false, "" )
	EditorVar( "zdev_edit_env_factor_rocks", "1.0", true, false, "" )
	EditorVar( "zdev_edit_env_factor_misc", "1.0", true, false, "" )

	-- Shared editor-mode toggle callback (particle editor also hooks it).
	-- NOTE pre-existing quirk preserved verbatim: change callbacks receive
	-- value_new as a STRING, so `== 1` is never true — the else branch always
	-- runs. Fixing that changes behavior; tracked in PLAN_CONSISTENCY_SWEEP
	-- Phase 6 notes, not silently altered here.
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
	-- Identifier makes re-adding on zdev_reload replace instead of stack.
	cvars.AddChangeCallback( "zdev_edit_env_toggle", function( ... ) ZDEV.CONV.EditorCallback( ... ) end, "zdev_editor_mode" )
end

local REGISTRY = {}

ZDEV.EDIT.ENVM = {
	Name = "Environment Editor",
	Version = 1.0,
	AdminOnly = true,
	Settings = {
		brush_size = 128,
		brush_density = 0.5,
		brush_type = BRUSH_GRASS,
		brush_flow = 1.0,
		brush_hardness = 0.5
	},
	Tool = {
		[EDIT_TOOL_NONE] = { Name="None"},
		[EDIT_TOOL_VIEW] = { Name="View"},
		[EDIT_TOOL_SELECT] = { Name="Select"},
		[EDIT_TOOL_BRUSH] = { Name="Brush", 
			Type={
				[BRUSH_NONE] = {Name="None"},
				[BRUSH_GRASS] = {Name="Grass"},
				[BRUSH_SHRUB] = {Name="Brush"},
				[BRUSH_TREE] = {Name="Tree"},
				[BRUSH_ROCK] = {Name="Rock"},
				[BRUSH_OTHER] = {Name="Other"}
			}
		},
		[EDIT_TOOL_ERASE] = { Name="Eraser"}
	},
	Models = {
		grass = {
			"models/props_foliage2/grass_golf1.mdl",
			"models/props_foliage2/grass_golf2.mdl",
			"models/props_foliage2/grass_wasteland1.mdl",
			"models/props_foliage2/grass-wasteland02.mdl",
			"models/props_foliage2/grass_wasteland3.mdl",
			"models/props_foliage2/grass_wasteland4.mdl",
			"models/props_foliage2/grass_wasteland5.mdl",
			"models/props_foliage2/grass_wasteland6.mdl",
			"models/props_foliage2/grass_wasteland7.mdl",
			"models/props_foliage2/greengrass1.mdl",
			"models/props_foliage2/greengrass2.mdl",
			"models/props_foliage2/greengrass3.mdl",
			"models/props/de_dust/hr_dust/foliage/short_grass_01.mdl",
			"models/props/de_dust/hr_dust/foliage/short_grass_02.mdl",
			"models/props/de_prodigy/prodgrassa.mdl",
			"models/props_foliage/lowgrass03.mdl",
			"models/props_foliage/grass3.mdl",
			"models/props_foliage/grass_cluster01.mdl",
			"models/props/de_dust/hr_dust/foliage/short_grass_02.mdl",
			"models/props/de_dust/hr_dust/foliage/short_grass_01.mdl"
		}
	}
}

function ZDEV.EDIT.ENVM.SpawnGrass( spawnpos, radius )

	local pos = Vector( spawnpos.x + math.random( -radius, radius ), spawnpos.y + math.random( -radius, radius ), spawnpos.z )

	local mdl = table.Random( ZDEV.EDIT.ENVM.Models.grass )

	local prop = ents.Create( "prop_dynamic" )
		prop:SetModel( mdl )
		prop:SetPos( pos )
		prop:SetAngles( Angle( p, y, math.random( 360 ) ) )
		prop:SetOwner( ply )
		prop:SetCollisionGroup( COLLISION_GROUP_WORLD )
		prop:DrawShadow( false )
		prop:Spawn()

		local pos1 = prop:GetPos()
		local tr = util.QuickTrace( pos1, Vector(0,0,10) + Vector(0,0,-1) * 9, prop )

		debugoverlay.Line( pos1, tr.HitPos, 3, Color(0,255,0), true )

		local gndpos = tr.HitPos
		prop:SetPos( gndpos )

	local index = prop:EntIndex()
	REGISTRY[ index ] = { ent = prop, model = mdl, pos = pos }

	print( "SPAWN GRASS" )

end

ZDEV.CMDS.Register( "zdev_edit_env_spawn_grass", function( ply, cmd, arg )
	print( ply, cmd, arg )
	local tr = ply:GetEyeTrace()
	local pos = tr.HitPos
	local size = GetConVarNumber( "zdev_edit_env_brush_radius" )
	ZDEV.EDIT.ENVM.SpawnGrass( pos, size )
end, { aliases = { "zedit_env_spawn_grass" } } )

function ZDEV.EDIT.ENVM.RemoveGrassByIndex( index )

	local ent = REGISTRY[ index ].ent
	if ent and IsValid( ent ) then
		SafeRemoveEntity( ent )
		REGISTRY[ index ] = nil
	end

end

function ZDEV.EDIT.ENVM.ChangeTool( toolmode )

end

function ZDEV.EDIT.ENVM.ChangeBrushMode( mode )

end

function ZDEV.EDIT.ENVM.BrushErase( ply )

	local tr = ply:GetEyeTrace()
	local pos = tr.HitPos
	local size = GetConVarNumber( "zdev_edit_env_brush_radius" )

	for k, e in pairs( ents.FindInSphere( pos, size ) ) do

		if IsValid(e) and REGISTRY[ e:EntIndex() ] then
			SafeRemoveEntity( e )
		end

	end

end

local size_max = 1024
function ZDEV.EDIT.ENVM.BrushPaint( ply )

	local size = GetConVarNumber( "zdev_edit_env_brush_radius" )
	local density = GetConVarNumber( "zdev_edit_env_brush_density" )
	local brushmode = GetConVarNumber( "zdev_edit_env_brush_mode" )

	local pos = ply:GetEyeTrace().HitPos

	local max = math.Round( density * 20, 0 )
	for i = 1, max do
		RunConsoleCommand( "zdev_edit_env_spawn_grass" )
		--ZDEV.EDIT.ENVM.SpawnGrass( pos, size )
	end

end

function ZDEV.EDIT.ENVM.RemoveHooks( )
	hook.Remove( "PlayerBindPress", "ZDEV.EDIT.ENVM.Hook_Spawn" )
end

function ZDEV.EDIT.ENVM.AddHooks( )

	hook.Add( "PlayerBindPress", "ZDEV.EDIT.ENVM.Hook_Spawn", function( ply, bind, pressed ) 
		if string.find( bind, "+attack" ) then
			ZDEV.EDIT.ENVM.BrushPaint( ply )
		end
	end)

end

function ZDEV.EDIT.ENVM.Hook_Spawn( )

end

hook.Add( "PlayerBindPress", "ZDEV.EDIT.ENVM.BrushPaint", function( ply, bind, pressed )
	if GetConVar( "zdev_edit_env_toggle" ):GetBool() then
		if string.find( bind, "+attack" ) then
			ZDEV.EDIT.ENVM.BrushPaint( ply )
			print( "PAINT" )
		end
	end
end)

--[[■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  ZDEV particle editor
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ ]] 
ZDEV.EDIT.EMIT = {}

--[[============================================
    CONVARS
==================================================]] 
function ZDEV.EDIT.EMIT.GetConVars( )

	local convars = {
		id = GetConVarString( "zdev_edit_particle_id"),
		emitter = GetConVarString( "zdev_edit_particle_emitter" ),
		entity = GetConVarString( "zdev_edit_particle_entity" ),
		pos = GetConVarString( "zdev_edit_particle_pos" ),
		offset = GetConVarString( "zdev_edit_particle_offset" ),
		material = GetConVarString( "zdev_edit_particle_mat" ),
		rep = GetConVar("zdev_edit_particle_repeat"):GetFloat(),
		lifetime = GetConVar("zdev_edit_particle_lifetime"):GetFloat(),
		dietime = GetConVar("zdev_edit_particle_dietime"):GetFloat(),
		start_size = GetConVarNumber("zdev_edit_particle_size_s"),
		start_alpha = GetConVarNumber("zdev_edit_particle_alpha_s"),
		start_length = GetConVarNumber("zdev_edit_particle_length_s"),
		end_size = GetConVarNumber("zdev_edit_particle_size_e"),
		end_alpha = GetConVarNumber("zdev_edit_particle_alpha_e"),
		end_length = GetConVarNumber("zdev_edit_particle_length_e"),
		roll = GetConVarNumber("zdev_edit_particle_roll"),
		rolldelta = GetConVarNumber("zdev_edit_particle_rolldelta"),
		angles = GetConVarString("zdev_edit_particle_angles"),
		ang_velocity = GetConVarString("zdev_edit_particle_angular_velocity"),
		airres = GetConVarNumber("zdev_edit_particle_airres"),
		bounce = GetConVar("zdev_edit_particle_bounce"):GetFloat(),
		collide = GetConVar("zdev_edit_particle_collide"):GetBool(),
		lighting = GetConVar("zdev_edit_particle_lighting"):GetBool(),
		color = string.ToColor( GetConVar("zdev_edit_particle_color"):GetString() ),
		color_r = GetConVarNumber("zdev_edit_particle_color_r"),
		color_g = GetConVarNumber("zdev_edit_particle_color_g"),
		color_b = GetConVarNumber("zdev_edit_particle_color_b"),
		color_a = GetConVarNumber("zdev_edit_particle_color_a"),
		gravity = GetConVarString("zdev_edit_particle_gravity"),
		velocity = GetConVarString("zdev_edit_particle_velocity"),
		velocity_mul = GetConVarNumber( "zdev_edit_particle_velocity_mul"),
		count_min = GetConVarNumber("zdev_edit_particle_count_min"),
		count_max = GetConVarNumber("zdev_edit_particle_count_max")
	}

	return convars
end


ZDEV.FILE.SetLoaded( _f )

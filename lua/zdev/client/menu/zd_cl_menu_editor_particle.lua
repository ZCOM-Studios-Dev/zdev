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

ZEDIT.FX.SAVE_DIR = "zdev/sefx/emitters/"
ZEDIT.FX.ACTIVE_EMITTERS = {}
ZEDIT.FX.PREVIEW_HOOK = "ZEDIT_ParticlePreview"
ZEDIT.FX.PREVIEW_ENABLED = false
ZEDIT.FX.PREVIEW_RATE = 0.1
ZEDIT.FX.LAST_PREVIEW = 0

-- ConVars for editor
CreateClientConVar( "zedit_particle_id", "particle_01", true, false, "Particle ID" )
CreateClientConVar( "zedit_particle_mat", "particles/fire1", true, false, "Particle material" )
CreateClientConVar( "zedit_particle_lifetime", "0.5", true, false, "Particle lifetime" )
CreateClientConVar( "zedit_particle_dietime", "1.0", true, false, "Particle die time" )
CreateClientConVar( "zedit_particle_size_s", "8", true, false, "Start size" )
CreateClientConVar( "zedit_particle_size_e", "2", true, false, "End size" )
CreateClientConVar( "zedit_particle_alpha_s", "255", true, false, "Start alpha" )
CreateClientConVar( "zedit_particle_alpha_e", "0", true, false, "End alpha" )
CreateClientConVar( "zedit_particle_length_s", "0", true, false, "Start length" )
CreateClientConVar( "zedit_particle_length_e", "0", true, false, "End length" )
CreateClientConVar( "zedit_particle_roll", "0", true, false, "Roll angle" )
CreateClientConVar( "zedit_particle_rolldelta", "0", true, false, "Roll delta" )
CreateClientConVar( "zedit_particle_angles", "0 0 0", true, false, "Angles" )
CreateClientConVar( "zedit_particle_angular_velocity", "0 0 0", true, false, "Angular velocity" )
CreateClientConVar( "zedit_particle_airres", "50", true, false, "Air resistance" )
CreateClientConVar( "zedit_particle_bounce", "0.5", true, false, "Bounce" )
CreateClientConVar( "zedit_particle_collide", "0", true, false, "Collide" )
CreateClientConVar( "zedit_particle_lighting", "0", true, false, "Lighting" )
CreateClientConVar( "zedit_particle_color", "255 200 100", true, false, "Color" )
CreateClientConVar( "zedit_particle_color_r", "255", true, false, "Color R" )
CreateClientConVar( "zedit_particle_color_g", "200", true, false, "Color G" )
CreateClientConVar( "zedit_particle_color_b", "100", true, false, "Color B" )
CreateClientConVar( "zedit_particle_color_a", "255", true, false, "Color A" )
CreateClientConVar( "zedit_particle_gravity", "0 0 -100", true, false, "Gravity vector" )
CreateClientConVar( "zedit_particle_velocity", "0 0 50", true, false, "Velocity vector" )
CreateClientConVar( "zedit_particle_velocity_mul", "1", true, false, "Velocity multiplier" )
CreateClientConVar( "zedit_particle_count_min", "1", true, false, "Min particle count" )
CreateClientConVar( "zedit_particle_count_max", "5", true, false, "Max particle count" )
CreateClientConVar( "zedit_particle_repeat", "0.1", true, false, "Repeat rate" )
CreateClientConVar( "zedit_particle_preview", "0", true, false, "Preview enabled" )

ZEDIT.FX.PROJECTS = {
	Name = "NewProject",
	Filename = "zedit_particle_new.txt",
	Author = "Author Name",
	Particles = {},
	Emitters = {}
}

ZEDIT.FX.CurrentProject = {
	Name = "Untitled",
	Filename = "untitled.json",
	Author = "Unknown",
	Particles = {},
	LastSave = 0
}

function ZEDIT.FX.NewProject( name )
	ZEDIT.FX.CurrentProject = {
		Name = name or "Untitled",
		Filename = string.lower(string.gsub(name or "untitled", " ", "_")) .. ".json",
		Author = "Unknown",
		Particles = {},
		LastSave = 0
	}
	zdev.log( "S", "Created new particle project: " .. ZEDIT.FX.CurrentProject.Name )
end

function ZEDIT.FX.GetConVars( )
	local convars = {
		id = GetConVarString( "zedit_particle_id"),
		material = GetConVarString( "zedit_particle_mat" ),
		lifetime = GetConVar("zedit_particle_lifetime"):GetFloat(),
		dietime = GetConVar("zedit_particle_dietime"):GetFloat(),
		start_size = GetConVarNumber("zedit_particle_size_s"),
		start_alpha = GetConVarNumber("zedit_particle_alpha_s"),
		start_length = GetConVarNumber("zedit_particle_length_s"),
		end_size = GetConVarNumber("zedit_particle_size_e"),
		end_alpha = GetConVarNumber("zedit_particle_alpha_e"),
		end_length = GetConVarNumber("zedit_particle_length_e"),
		roll = GetConVarNumber("zedit_particle_roll"),
		rolldelta = GetConVarNumber("zedit_particle_rolldelta"),
		angles = GetConVarString("zedit_particle_angles"),
		ang_velocity = GetConVarString("zedit_particle_angular_velocity"),
		airres = GetConVarNumber("zedit_particle_airres"),
		bounce = GetConVar("zedit_particle_bounce"):GetFloat(),
		collide = GetConVar("zedit_particle_collide"):GetBool(),
		lighting = GetConVar("zedit_particle_lighting"):GetBool(),
		color = GetConVarString("zedit_particle_color"),
		color_r = GetConVarNumber("zedit_particle_color_r"),
		color_g = GetConVarNumber("zedit_particle_color_g"),
		color_b = GetConVarNumber("zedit_particle_color_b"),
		color_a = GetConVarNumber("zedit_particle_color_a"),
		gravity = GetConVarString("zedit_particle_gravity"),
		velocity = GetConVarString("zedit_particle_velocity"),
		velocity_mul = GetConVarNumber("zedit_particle_velocity_mul"),
		count_min = GetConVarNumber("zedit_particle_count_min"),
		count_max = GetConVarNumber("zedit_particle_count_max"),
		repeat_rate = GetConVar("zedit_particle_repeat"):GetFloat()
	}
	return convars
end

function ZEDIT.FX.SetConVars( data )
	if not data then return end
	for k, v in pairs( data ) do
		local cvar = GetConVar( "zedit_particle_" .. k )
		if cvar then RunConsoleCommand( "zedit_particle_" .. k, tostring(v) ) end
	end
end

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

-- File Operations
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
		Name = ZEDIT.FX.CurrentProject.Name,
		Author = ZEDIT.FX.CurrentProject.Author,
		Particles = ZEDIT.FX.CurrentProject.Particles,
		SaveTime = os.time()
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
			Name = data.Name or "Loaded",
			Filename = filename,
			Author = data.Author or "Unknown",
			Particles = data.Particles or {},
			LastSave = CurTime()
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
			Name = data.Name or "Imported",
			Filename = "imported_" .. os.time() .. ".json",
			Author = data.Author or "Unknown",
			Particles = data.Particles or {},
			LastSave = 0
		}
		zdev.log( "S", "Imported project from text" )
		return true
	end
	zdev.log( "F", "Failed to parse import data" )
	return false
end

-- Realtime Preview System
function ZEDIT.FX.SpawnParticle( pos, data )
	local emitter = ParticleEmitter( pos )
	if not emitter then return end

	local count = math.random( data.count_min or 1, data.count_max or 1 )
	local vel_parts = string.Explode( " ", data.velocity or "0 0 50" )
	local grav_parts = string.Explode( " ", data.gravity or "0 0 -100" )
	local v_vel = Vector( tonumber(vel_parts[1]) or 0, tonumber(vel_parts[2]) or 0, tonumber(vel_parts[3]) or 50 )
	local v_grav = Vector( tonumber(grav_parts[1]) or 0, tonumber(grav_parts[2]) or 0, tonumber(grav_parts[3]) or -100 )
	local vel_mul = data.velocity_mul or 1

	for i = 1, count do
		local p = emitter:Add( data.material or "particles/fire1", pos + VectorRand() * 2 )
		if p then
			p:SetLifeTime( 0 )
			p:SetDieTime( data.dietime or 1 )
			p:SetStartSize( data.start_size or 8 )
			p:SetEndSize( data.end_size or 2 )
			p:SetStartAlpha( data.start_alpha or 255 )
			p:SetEndAlpha( data.end_alpha or 0 )
			p:SetStartLength( data.start_length or 0 )
			p:SetEndLength( data.end_length or 0 )
			p:SetRoll( math.rad( data.roll or 0 ) )
			p:SetRollDelta( math.rad( data.rolldelta or 0 ) )
			p:SetAirResistance( data.airres or 50 )
			p:SetBounce( data.bounce or 0.5 )
			p:SetCollide( data.collide or false )
			p:SetLighting( data.lighting or false )
			p:SetColor( data.color_r or 255, data.color_g or 200, data.color_b or 100 )
			p:SetGravity( v_grav )
			p:SetVelocity( (v_vel + VectorRand() * 10) * vel_mul )
		end
	end

	emitter:Finish()
end

function ZEDIT.FX.StartPreview()
	ZEDIT.FX.PREVIEW_ENABLED = true
	hook.Add( "Think", ZEDIT.FX.PREVIEW_HOOK, function()
		if not ZEDIT.FX.PREVIEW_ENABLED then return end
		local rate = GetConVar("zedit_particle_repeat"):GetFloat()
		if CurTime() - ZEDIT.FX.LAST_PREVIEW < rate then return end
		ZEDIT.FX.LAST_PREVIEW = CurTime()

		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		local tr = ply:GetEyeTrace()
		local pos = tr.HitPos + tr.HitNormal * 8

		local data = ZEDIT.FX.GetConVars()
		ZEDIT.FX.SpawnParticle( pos, data )
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
	local tr = ply:GetEyeTrace()
	local pos = tr.HitPos + tr.HitNormal * 8
	local data = ZEDIT.FX.GetConVars()
	ZEDIT.FX.SpawnParticle( pos, data )
end

function ZEDIT.FX.SpawnAll()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	local tr = ply:GetEyeTrace()
	local pos = tr.HitPos + tr.HitNormal * 8

	for _, data in ipairs( ZEDIT.FX.CurrentProject.Particles ) do
		ZEDIT.FX.SpawnParticle( pos, data )
	end
end

-- ZDEV_UID: ZDEV_FUNC_600762EB | Path: ZDEV.VGUI.ParticleEditor
function ZDEV.VGUI.ParticleEditor( ply, cmd, arg )

	local W, H = SW * 0.3, SH * 0.95
	local menu = ZDEV.VGUI.CreateFrame( W, H, "ZDEV - Particle Emitter Editor" )
	menu:SetPos(0,0)

	menu.Particles = ZEDIT.FX.CurrentProject.Particles

	local function RefreshParticleList()
		if menu.lv then
			menu.lv:Clear()
			for i, p in ipairs( ZEDIT.FX.CurrentProject.Particles ) do
				menu.lv:AddLine( i, p.id, p.material, p.dietime, p.start_size )
			end
		end
	end

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	MENU BAR
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.mb = vgui.Create( "DMenuBar", menu )
	menu.mb:DockMargin(2,2,2,0)

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
	menu.mb.m1:AddOption( "Save", function()
		ZEDIT.FX.SaveProject()
	end ):SetIcon( "icon16/disk.png" )
	menu.mb.m1:AddOption( "Save As...", function()
		Derma_StringRequest( "Save As", "Enter filename:", ZEDIT.FX.CurrentProject.Filename, function(txt)
			ZEDIT.FX.SaveProject( txt )
		end )
	end ):SetIcon( "icon16/page_save.png" )
	menu.mb.m1:AddSpacer()
	menu.mb.m1:AddOption( "Export to Clipboard", function()
		ZEDIT.FX.ExportToClipboard()
	end ):SetIcon( "icon16/page_copy.png" )
	menu.mb.m1:AddOption( "Import from Text...", function()
		local f = ZDEV.VGUI.CreateFrame( SW*0.4, SH*0.3, "Import JSON" )
		local te = vgui.Create( "DTextEntry", f )
		te:Dock( FILL )
		te:SetMultiline( true )
		te:SetPlaceholderText( "Paste JSON data here..." )
		local btn = ZDEV.VGUI.CreateButton( f, 100, 28, "IMPORT", "raj", Color(100,255,100), function()
			if ZEDIT.FX.ImportFromText( te:GetValue() ) then
				RefreshParticleList()
				f:Close()
			end
		end )
		btn:Dock( BOTTOM )
	end ):SetIcon( "icon16/page_paste.png" )
	menu.mb.m1:AddSpacer()
	menu.mb.m1:AddOption( "Close", function() menu:Close() end ):SetIcon( "icon16/cross.png" )

	menu.mb.m2 = menu.mb:AddMenu( "Edit" )
	menu.mb.m2:AddOption( "Add Particle", function()
		local data = ZEDIT.FX.GetConVars()
		ZEDIT.FX.NewParticle( menu, data.id, data )
		RefreshParticleList()
	end ):SetIcon( "icon16/add.png" )
	menu.mb.m2:AddOption( "Clear All Particles", function()
		Derma_Query( "Clear all particles?", "Confirm", "Yes", function()
			ZEDIT.FX.CurrentProject.Particles = {}
			RefreshParticleList()
		end, "No" )
	end ):SetIcon( "icon16/bin.png" )

	menu.mb.m3 = menu.mb:AddMenu( "Spawn" )
	menu.mb.m3:AddOption( "Spawn Current", function()
		ZEDIT.FX.SpawnOnce()
	end ):SetIcon( "icon16/wand.png" )
	menu.mb.m3:AddOption( "Spawn All Particles", function()
		ZEDIT.FX.SpawnAll()
	end ):SetIcon( "icon16/lightning.png" )
	menu.mb.m3:AddSpacer()
	menu.mb.m3:AddOption( "Start Preview Loop", function()
		ZEDIT.FX.StartPreview()
	end ):SetIcon( "icon16/control_play_blue.png" )
	menu.mb.m3:AddOption( "Stop Preview", function()
		ZEDIT.FX.StopPreview()
	end ):SetIcon( "icon16/control_stop_blue.png" )

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	TOP INFO PANEL
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.pn_info = vgui.Create( "DPanel", menu )
	menu.pn_info:Dock( TOP )
	menu.pn_info:SetTall( 40 )
	menu.pn_info:DockMargin( 2, 2, 2, 2 )
	menu.pn_info.Paint = function( self, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, Color( 40, 45, 55, 255 ) )
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 1, Color(80, 120, 180, 255) )
		draw.SimpleText( "Project: " .. ZEDIT.FX.CurrentProject.Name, "DermaDefaultBold", 8, 8, color_white )
		draw.SimpleText( "Particles: " .. #ZEDIT.FX.CurrentProject.Particles, "DermaDefault", 8, 22, Color(180,180,180) )
		local status = ZEDIT.FX.PREVIEW_ENABLED and "LIVE" or "STOPPED"
		local clr = ZEDIT.FX.PREVIEW_ENABLED and Color(100,255,100) or Color(150,150,150)
		draw.SimpleText( "Preview: " .. status, "DermaDefaultBold", w - 100, 14, clr )
	end

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	TOOLBAR PANEL
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.pn = vgui.Create( "DPanel", menu )
	menu.pn:Dock( TOP )
	menu.pn:SetTall( 32 )
	menu.pn:DockMargin( 2, 0, 2, 2 )
	menu.pn.Paint = function( self, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, Color( 50, 55, 65, 255 ) )
	end

	menu.pn.btn_add = ZDEV.VGUI.CreateButton( menu.pn, 64, 28, "ADD", "raj", Color(100,255,100), function()
		local data = ZEDIT.FX.GetConVars()
		ZEDIT.FX.NewParticle( menu, data.id, data )
		RefreshParticleList()
	end )
	menu.pn.btn_add:Dock( LEFT )
	menu.pn.btn_add:DockMargin( 2, 2, 2, 2 )

	menu.pn.btn_spawn = ZDEV.VGUI.CreateButton( menu.pn, 64, 28, "SPAWN", "raj", Color(100,200,255), function()
		ZEDIT.FX.SpawnOnce()
	end )
	menu.pn.btn_spawn:Dock( LEFT )
	menu.pn.btn_spawn:DockMargin( 0, 2, 2, 2 )

	menu.pn.btn_preview = ZDEV.VGUI.CreateButton( menu.pn, 64, 28, "LOOP", "raj", Color(255,200,100), function()
		if ZEDIT.FX.PREVIEW_ENABLED then
			ZEDIT.FX.StopPreview()
		else
			ZEDIT.FX.StartPreview()
		end
	end )
	menu.pn.btn_preview:Dock( LEFT )
	menu.pn.btn_preview:DockMargin( 0, 2, 2, 2 )

	menu.pn.btn_save = ZDEV.VGUI.CreateButton( menu.pn, 64, 28, "SAVE", "raj", Color(255,150,100), function()
		ZEDIT.FX.SaveProject()
	end )
	menu.pn.btn_save:Dock( RIGHT )
	menu.pn.btn_save:DockMargin( 2, 2, 2, 2 )

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	PARTICLE LIST VIEW
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.lv_pnl = vgui.Create( "DPanel", menu )
	menu.lv_pnl:Dock( TOP )
	menu.lv_pnl:SetTall( H * 0.15 )
	menu.lv_pnl:DockMargin( 2, 0, 2, 2 )
	menu.lv_pnl.Paint = function( self, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, Color( 35, 40, 50, 255 ) )
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 1, Color(60, 100, 150, 255) )
	end

	menu.lv = vgui.Create( "DListView", menu.lv_pnl )
	menu.lv:Dock( FILL )
	menu.lv:DockMargin( 2, 2, 2, 2 )
	menu.lv:SetMultiSelect( false )
	menu.lv:AddColumn( "#" ):SetWidth( 25 )
	menu.lv:AddColumn( "ID" ):SetWidth( 80 )
	menu.lv:AddColumn( "Material" ):SetWidth( 100 )
	menu.lv:AddColumn( "DieTime" ):SetWidth( 50 )
	menu.lv:AddColumn( "Size" ):SetWidth( 40 )

	menu.lv.OnRowSelected = function( lst, index, pnl )
		local p = ZEDIT.FX.CurrentProject.Particles[ index ]
		if p then ZEDIT.FX.SetConVars( p ) end
	end

	menu.lv.OnRowRightClick = function( lst, index, pnl )
		local dm = DermaMenu()
		dm:AddOption( "Edit", function()
			local p = ZEDIT.FX.CurrentProject.Particles[ index ]
			if p then ZEDIT.FX.SetConVars( p ) end
		end ):SetIcon( "icon16/pencil.png" )
		dm:AddOption( "Duplicate", function()
			ZEDIT.FX.DuplicateParticle( index )
			RefreshParticleList()
		end ):SetIcon( "icon16/page_copy.png" )
		dm:AddOption( "Spawn This", function()
			local p = ZEDIT.FX.CurrentProject.Particles[ index ]
			if p then
				local ply = LocalPlayer()
				if IsValid(ply) then
					local tr = ply:GetEyeTrace()
					ZEDIT.FX.SpawnParticle( tr.HitPos + tr.HitNormal * 8, p )
				end
			end
		end ):SetIcon( "icon16/wand.png" )
		dm:AddSpacer()
		dm:AddOption( "Delete", function()
			Derma_Query( "Delete this particle?", "Confirm", "Yes", function()
				ZEDIT.FX.RemoveParticle( index )
				RefreshParticleList()
			end, "No" )
		end ):SetIcon( "icon16/delete.png" )
		dm:Open()
	end

	RefreshParticleList()

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	PROPERTIES SCROLL PANEL
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.sp_L = vgui.Create( "DScrollPanel", menu )
	menu.sp_L:Dock( FILL )
	menu.sp_L:DockMargin( 2, 0, 2, 2 )
	menu.sp_L.Paint = function( self, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, Color(45, 50, 60, 255) )
	end

	local form_item_h = 18

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	MATERIAL SECTION
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.sp_L.f = vgui.Create( "DForm", menu.sp_L )
	menu.sp_L.f:Dock( TOP )
	menu.sp_L.f:SetName( "Particle Properties" )

	local mat_pnl = vgui.Create( "DPanel", menu.sp_L.f )
	mat_pnl:SetTall( 80 )
	mat_pnl.Paint = function( s, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, Color(30,30,40,200) )
	end

	local mat_img = vgui.Create( "DImage", mat_pnl )
	mat_img:SetPos( 4, 4 )
	mat_img:SetSize( 72, 72 )
	mat_img:SetImage( GetConVarString("zedit_particle_mat") )

	local mat_btn = vgui.Create( "DButton", mat_pnl )
	mat_btn:SetPos( 82, 4 )
	mat_btn:SetSize( 100, 24 )
	mat_btn:SetText( "Browse..." )
	mat_btn.DoClick = function()
		if ZDEV.VGUI.Editor_Materials then
			ZDEV.VGUI.Editor_Materials( "zd_menu_dev_mat", LocalPlayer(), {GetConVarString("zedit_particle_mat")} )
		end
	end

	menu.sp_L.f:AddItem( mat_pnl )

	-- ID and Material
	local f_id = menu.sp_L.f:TextEntry( "Particle ID", "zedit_particle_id" )
	f_id:SetTall( form_item_h )
	local f_mat = menu.sp_L.f:TextEntry( "Material Path", "zedit_particle_mat" )
	f_mat:SetTall( form_item_h )
	f_mat.OnValueChange = function( self, val )
		timer.Simple( 0.1, function() if IsValid(mat_img) then mat_img:SetImage( val ) end end )
	end

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	SPAWN SETTINGS
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.sp_L.f:ControlHelp( "━━━━━ Spawn Settings ━━━━━" ):SetTall( form_item_h )
	menu.sp_L.f:NumSlider( "Count (Min)", "zedit_particle_count_min", 1, 100, 0 ):SetTall( form_item_h )
	menu.sp_L.f:NumSlider( "Count (Max)", "zedit_particle_count_max", 1, 100, 0 ):SetTall( form_item_h )
	menu.sp_L.f:NumSlider( "Repeat Rate", "zedit_particle_repeat", 0.01, 5.0, 2 ):SetTall( form_item_h )

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	TIME SETTINGS
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.sp_L.f:ControlHelp( "━━━━━ Time Settings ━━━━━" ):SetTall( form_item_h )
	menu.sp_L.f:NumSlider( "Lifetime", "zedit_particle_lifetime", 0.0, 10.0, 2 ):SetTall( form_item_h )
	menu.sp_L.f:NumSlider( "Die Time", "zedit_particle_dietime", 0.1, 10.0, 2 ):SetTall( form_item_h )

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	SIZE SETTINGS
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.sp_L.f:ControlHelp( "━━━━━ Size & Alpha ━━━━━" ):SetTall( form_item_h )
	menu.sp_L.f:NumSlider( "Start Size", "zedit_particle_size_s", 0, 100, 1 ):SetTall( form_item_h )
	menu.sp_L.f:NumSlider( "End Size", "zedit_particle_size_e", 0, 100, 1 ):SetTall( form_item_h )
	menu.sp_L.f:NumSlider( "Start Alpha", "zedit_particle_alpha_s", 0, 255, 0 ):SetTall( form_item_h )
	menu.sp_L.f:NumSlider( "End Alpha", "zedit_particle_alpha_e", 0, 255, 0 ):SetTall( form_item_h )
	menu.sp_L.f:NumSlider( "Start Length", "zedit_particle_length_s", 0, 100, 1 ):SetTall( form_item_h )
	menu.sp_L.f:NumSlider( "End Length", "zedit_particle_length_e", 0, 100, 1 ):SetTall( form_item_h )

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	COLOR SETTINGS
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.sp_L.f:ControlHelp( "━━━━━ Color ━━━━━" ):SetTall( form_item_h )
	menu.sp_L.f:NumSlider( "Red", "zedit_particle_color_r", 0, 255, 0 ):SetTall( form_item_h )
	menu.sp_L.f:NumSlider( "Green", "zedit_particle_color_g", 0, 255, 0 ):SetTall( form_item_h )
	menu.sp_L.f:NumSlider( "Blue", "zedit_particle_color_b", 0, 255, 0 ):SetTall( form_item_h )
	menu.sp_L.f:NumSlider( "Alpha", "zedit_particle_color_a", 0, 255, 0 ):SetTall( form_item_h )
	menu.sp_L.f:CheckBox( "Use Lighting", "zedit_particle_lighting" ):SetTall( form_item_h )

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	ROTATION SETTINGS
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.sp_L.f:ControlHelp( "━━━━━ Rotation ━━━━━" ):SetTall( form_item_h )
	menu.sp_L.f:NumSlider( "Roll", "zedit_particle_roll", 0, 360, 0 ):SetTall( form_item_h )
	menu.sp_L.f:NumSlider( "Roll Delta", "zedit_particle_rolldelta", -360, 360, 0 ):SetTall( form_item_h )
	menu.sp_L.f:TextEntry( "Angles (P Y R)", "zedit_particle_angles" ):SetTall( form_item_h )
	menu.sp_L.f:TextEntry( "Angular Velocity", "zedit_particle_angular_velocity" ):SetTall( form_item_h )

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	PHYSICS SETTINGS
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.sp_L.f:ControlHelp( "━━━━━ Physics ━━━━━" ):SetTall( form_item_h )
	menu.sp_L.f:NumSlider( "Air Resistance", "zedit_particle_airres", 0, 500, 0 ):SetTall( form_item_h )
	menu.sp_L.f:NumSlider( "Bounce", "zedit_particle_bounce", 0, 2, 2 ):SetTall( form_item_h )
	menu.sp_L.f:CheckBox( "Collide", "zedit_particle_collide" ):SetTall( form_item_h )
	menu.sp_L.f:TextEntry( "Gravity (X Y Z)", "zedit_particle_gravity" ):SetTall( form_item_h )
	menu.sp_L.f:TextEntry( "Velocity (X Y Z)", "zedit_particle_velocity" ):SetTall( form_item_h )
	menu.sp_L.f:NumSlider( "Velocity Multiplier", "zedit_particle_velocity_mul", 0, 10, 2 ):SetTall( form_item_h )

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	BOTTOM ACTION BAR
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.pn_bottom = vgui.Create( "DPanel", menu )
	menu.pn_bottom:Dock( BOTTOM )
	menu.pn_bottom:SetTall( 36 )
	menu.pn_bottom:DockMargin( 2, 2, 2, 2 )
	menu.pn_bottom.Paint = function( self, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, Color( 40, 45, 55, 255 ) )
	end

	menu.pn_bottom.btn_apply = ZDEV.VGUI.CreateButton( menu.pn_bottom, 80, 30, "UPDATE", "raj", Color(100,200,255), function()
		local sel = menu.lv:GetSelectedLine()
		if sel then
			local data = ZEDIT.FX.GetConVars()
			ZEDIT.FX.CurrentProject.Particles[ sel ] = data
			RefreshParticleList()
			zdev.log( "S", "Updated particle at index " .. sel )
		else
			zdev.log( "I", "No particle selected to update" )
		end
	end )
	menu.pn_bottom.btn_apply:Dock( LEFT )
	menu.pn_bottom.btn_apply:DockMargin( 2, 2, 2, 2 )

	menu.pn_bottom.btn_reset = ZDEV.VGUI.CreateButton( menu.pn_bottom, 64, 30, "RESET", "raj", Color(255,200,100), function()
		RunConsoleCommand( "zedit_particle_id", "particle_01" )
		RunConsoleCommand( "zedit_particle_mat", "particles/fire1" )
		RunConsoleCommand( "zedit_particle_dietime", "1" )
		RunConsoleCommand( "zedit_particle_start_size", "8" )
		RunConsoleCommand( "zedit_particle_end_size", "2" )
		zdev.log( "I", "Reset particle settings to defaults" )
	end )
	menu.pn_bottom.btn_reset:Dock( LEFT )
	menu.pn_bottom.btn_reset:DockMargin( 0, 2, 2, 2 )

	menu.pn_bottom.btn_close = ZDEV.VGUI.CreateButton( menu.pn_bottom, 64, 30, "CLOSE", "raj", Color(255,100,100), function()
		ZEDIT.FX.StopPreview()
		menu:Close()
	end )
	menu.pn_bottom.btn_close:Dock( RIGHT )
	menu.pn_bottom.btn_close:DockMargin( 2, 2, 2, 2 )

	menu.OnClose = function()
		ZEDIT.FX.StopPreview()
	end

	return menu
end

concommand.Add( "zedit_particle_editor", function( ply, cmd, arg )
	ZDEV.VGUI.ParticleEditor()
end )

-- Legacy command support
concommand.Add( "zedit_paticle_editor", function( ply, cmd, arg )
	ZDEV.VGUI.ParticleEditor()
end )

-- Spawn commands
concommand.Add( "zedit_particle_spawn", function( ply, cmd, arg )
	ZEDIT.FX.SpawnOnce()
end )

concommand.Add( "zedit_particle_preview_start", function( ply, cmd, arg )
	ZEDIT.FX.StartPreview()
end )

concommand.Add( "zedit_particle_preview_stop", function( ply, cmd, arg )
	ZEDIT.FX.StopPreview()
end )

ZDEV.VGUI.AddToMainMenu( "zedit_particle_editor" )

ZDEV.FILE.SetLoaded( _f )

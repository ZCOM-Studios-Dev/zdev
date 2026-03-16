local _f = 'zdev/client/vgui/zd_cl_menu_dev_part.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end

local player = player
local ents = ents
local util = util
local math = math
local string = string
local bit = bit
local gamemode = gamemode
local hook = hook
local Vector = Vector
local VectorRand = VectorRand
local Angle = Angle
local AngleRand = AngleRand
local Entity = Entity
local Color = Color
local FrameTime = FrameTime
local RealTime = RealTime
local CurTime = CurTime
local SysTime = SysTime
local EyePos = EyePos
local EyeAngles = EyeAngles
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local tonumber = tonumber
local Lerp = Lerp
local type = type

--ZDEV = ZDEV or {}
-- print('')

local cli = LocalPlayer()
local SW, SH = ScrW(), ScrH()

CreateClientConVar( "zedit_particle_filename", "zdev_fx_emitter_new.txt", true, false, "" )
CreateClientConVar( "zedit_particle_emitters", "1", true, false, "" )
CreateClientConVar( "zedit_particle_particles", "1", true, false, "" )
CreateClientConVar( "zedit_particle_parent", "0", true, false, "" )

local EDITOR = {}
EDITOR.Directories = {
	SaveData = {"zdev/sefx/"},
	Materials = {
		""
	}
}
EDITOR.File = {
	Current = { name="newfile.txt",dir="zdev/sefx/",path="DATA",lastsave=0 },
	LastSaved ={ name="lastsave.txt", dir="zdev/sefx/", path="DATA", lastsave=CurTime()},
	Loaded = { name="loaded.txt", dir="zdev/sefx/", path="DATA", lastsave=0},
	Emitters = {
		EmitterID = 0,
		Particles = {
			ParticleID = 0
		}
	},
	m_bMouseCapture = false,
	m_bKeyCapture = false
}

-- Local tables for storing information real-time aboutthe CURRENT selection
local FILES = {}
local EMITTERS = {}		-- Contains all the emitters that are currently Open in the editor
local emitter = {
	b_Open = false,
	FileName = ""
}		-- CURRENTLY OPEN emitter data

local PARTICLES = {}	-- Contains all the particles thatare currently open in the editor
local particle = {}		-- CURRENTLY SELECTED PARTICLE data 

emitter.Name = "#NAME_OF_EMITTER"
emitter.ID = "#EMITTER_ID"
emitter.m_bSpawned = false
emitter.Entity = nil
emitter.Parent = nil
emitter.Pos = Vector(0,0,0)
emitter.Ang = Angle(0,0,0)
emitter.Particles = {}

local function SaveFile( pnl )
	local p = ZDEV.EDIT.EMIT.GetConVars()

	ZDEV.EDIT.EMIT[ p.emitter ] = p

	local file_cur = EDITOR.File.Current

	if file_cur.name then
		file.Write( file_cur.dir .. file_cur.name, util.TableToJSON(  p ) )
		EDITOR.File.Current.lastsave = CurTime()
		zdev.log( "S", "Saved partile effect data-file" .. tostring( file_cur.name ) )
	end

end

local function FileOpen( pnl )
	local file_cur = EDITOR.File.Current
end

local function NewFile( name, shouldsave )

	FILE.Name = name
	FILE.DateCreated = os.time()
	FILE.Directory = "zdev/sefx/emit/"
	FILE.EMITTERS = {}

	EDITOR.File.Current.name = name
	local file_cur = EDITOR.File.Current

	if bshouldsave then
		file.Write( file_cur.dir .. file_cur.name, util.TableToJSON( EMITTER ) )
	end
end

local function LoadFile( name )
	local path = EDITOR.File.Current.path
	local dir = EDITOR.File.Current.dir

	local data_json = file.Read( dir .. name, "rw")
	local data_tbl = util.JSONToTable( data_json )

	EMITTER = data_tbl
	return data_tbl
end

local function NewEmitter( id, name, filename )

	local emitter = {
		id = id, 
		Name = name,
		FileName = filename,
		particles = {},
	}

	table.insert( EMITTERS, 1, emitter )

end

local function NewParticle( id, name, emitter )


end

local function PaintTimeGraph( )
	local x, y, w, h = 0, SH * 0.925, SW, SH * 0.075
	local space_w = 15
	local size_h = h * 0.5
	draw.RoundedBox( 0, x, y, w, h, Color(150,150,150,255) )
	for i = 1, 100 do
		draw.RoundedBox( 0, x + i * space_w, y + size_h * 0.5, 1, size_h , Color(50,50,50,255) )
		draw.DrawText( tostring(i), "DefaultSmall", x+ i * space_w, y, Color(0,0,0,255), TEXT_ALIGN_CENTER )
	end
	for i = 1, 100 do
		draw.RoundedBox( 0, x + space_w*0.5 + i * space_w , y + size_h*0.75, 1, size_h * 0.5 , Color(0,0,0,255) )
	end

end
-- hook.Add( "HUDPaint", "ZDEV.EDIT.ParticleEditor", function()
-- 	if GetConVar( "zedit_particle_show_timegraph" ):GetBool() then
-- 		PaintTimeGraph( )
-- 	end
-- end )

local function GetCurrentConVars()

	local particle = {
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
		velocity = GetConVarString("zedit_particle_velocity")
	}
	return particle
end

-- ZDEV_UID: ZDEV_FUNC_513CD781 | Path: ZDEV.VGUI.ParticleMenu
function ZDEV.VGUI.ParticleMenu( )
	--gui.EnableScreenClicker( true )

	RunConsoleCommand( "zedit_particle_toggle", "1" )

	local menu, list = {}, {}

	local menu_w, menu_h = SW * 0.2, SH 
	menu = ZDEV.VGUI.CreateFrame( menu_w, menu_h, "ZDEV Particle/Sprite Editor")
	menu:SetPos( 0, 0 )
	--menu:ParentToHUD()
	--menu:SetKeyboardInputEnabled( true )
	--menu:SetMouseInputEnabled( true )
	--gui.EnableScreenClicker( true )
	menu.OnClose = function( self )
		RunConsoleCommand( "zedit_particle_toggle", "0" )
	end

	local list_w, list_h = SW * 0.6, SH * 0.5
	menu.li = ZDEV.VGUI.CreateFrame( list_w, list_h, "Emitter/Particle Index" )
	menu.li.OnClose = function( self )
		menu:Close()
	end

	menu.li.sp = vgui.Create( "DScrollPanel", menu )
	menu.li.sp:Dock(FILL)
	menu.li.sp:SetWide( list_w )
	menu.li.sp.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color(120,120,120, 255) )
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 1, Color(255,100,100, 255) )
	end

	menu.li.sp = {}
	--[[


	menu.li.sp.tl = vgui.Create("DTileLayout", menu.li)
		menu.li.sp.tl:SetBaseSize(32) -- Tile size
		menu.li.sp.tl:Dock(TOP)
		menu.li.sp.tl:SetDrawBackground(true)
		menu.li.sp.tl:SetBackgroundColor(Color(50, 75, 100))
		menu.li.sp.tl:MakeDroppable("efx_emit_part") -- Allows us to rearrange children
		for i = 1, 9 do
			menu.li.sp.tl:Add( Label(" Label " .. i) )
		end
]]
--	menu.li.sp:AddItem( menu.li.sp.tl )

	menu.li.sp.nt = vgui.Create( "DTree", menu.li )
	menu.li.sp.nt:Dock(FILL)
	menu.li.sp.nt:DockMargin( 1, 1, 1, list_h * 0.75)
		for j, c in pairs( EDITOR.File.Emitters.Particles ) do
			
			local val = "NODE_NAME"
			if type( c ) == "table" then val = table.GetFirstValue(c)
			elseif type( c ) == "number" then val = c end

			menu.li.sp.nt:AddNode( val, "icon16/folder.png")
		end
	
--	menu.li.sp:AddItem( menu.li.sp.nt )

	menu.li.sp.lv = vgui.Create( "DListView", menu.li )
	menu.li.sp.lv:Dock(FILL)
	menu.li.sp.lv:DockMargin( 1, list_h * 0.25, 1, 1 )

		for cv, val in pairs( GetCurrentConVars() ) do
			menu.li.sp.lv:AddColumn( cv, 1 )
		end
		for k, v in pairs( EDITOR.File.Emitters.Particles ) do
			menu.li.sp.lv:AddLine( )

		end
	--menu.li.sp:AddItem( menu.li.sp.lv )
	
	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	 CENTER PANEL
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.p_b = vgui.Create( "DPanel", menu )
	menu.p_b:Dock(BOTTOM)
	menu.p_b:DockMargin( 1, 1, 1, 1 )
	menu.p_b.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color(60,60,60,100) )
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 1, Color(100,100,255,255) )
	end

	  --[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	    DMENU BAR
	  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	  menu.mb = vgui.Create( "DMenuBar", menu )
	  menu.mb:DockMargin(2,2,2,0)

	  menu.mb.m1 = menu.mb:AddMenu( "File" )
	    menu.mb.m1:AddOption( "New", function()
			 Derma_StringRequest( "New Filename","Enter the name of the new file.","emitter_name.txt",
			 function( s_txt )
				NewFile( s_txt, true )
				zdev.log( "S", " Created New file")
			 end,
			 function( s_txt )
				zdev.log( "F", " Cancelled New file")
			end,"New","Cancel")
		 end ):SetIcon( "icon16/page_white_go.png")
	    menu.mb.m1:AddOption( "Open", function()
	    	ZDEV.VGUI.FileManager( "data", "zdev", "sefx" )
	    end ):SetIcon( "icon16/folder.png")
	    menu.mb.m1:AddOption( "Save", function()
	      Derma_StringRequest( "Save Filename","Directory: 'zdev/weapons/'","weapon_filename.txt",
	      function( s_txt )
		  	SaveFile( menu ) 
	        --ZDEV.WEAP.SaveFile( s_txt, t_WeaponData )
	      end,
	      function( s_txt )
	        zdev.log( "D", " Cancelled File-save Dialogue")
	      end,"Save","Cancel")
	    end ):SetIcon( "icon16/page_save.png")
	    menu.mb.m1:AddOption( "Update", function()
	      weapons.Register( t_WeaponData, s_ClassName )
	    end ):SetIcon( "icon16/page_go.png")
	    menu.mb.m1:AddOption( "Close", function() end ):SetIcon( "icon16/cross.png")

	  menu.mb.m2 = menu.mb:AddMenu( "Edit" )
	    menu.mb.m2:AddOption( "Copy", function() end ):SetIcon( "icon16/page_copy.png")
	    menu.mb.m2:AddOption( "Paste", function() end ):SetIcon( "icon16/paste_plain.png")
	    menu.mb.m2:AddOption( "Delete", function() end ):SetIcon( "icon16/delete.png")
	    menu.mb.m2:AddOption( "Lock", function() end ):SetIcon( "icon16/lock.png")
	  menu.mb.m3a = menu.mb:AddMenu( "View" )
	    menu.mb.m3a:AddOption( "Show Timegraph", function() 
			RunConsoleCommand( "zedit_particle_show_timegraph", "1")
		end ):SetIcon( "icon16/clock.png")
		menu.mb.m3a:AddOption( "Hide Timegraph", function() 
			RunConsoleCommand( "zedit_particle_show_timegraph", "0")
		end ):SetIcon( "icon16/clock_delete.png")

	  menu.mb.m4 = menu.mb:AddMenu( "Data" )
		 menu.mb.m4:AddOption("View as KeyValues", function()
			local s_table = util.TableToKeyValues( weapons.GetStored( class ) )
			local df = ZDEV.VGUI.CreateFrame( SW * 0.33, SH * 0.33, class .. " SWEP Table - KeyValues" )
			df.te = ZDEV.VGUI.CreateTextEntry( df, df:GetWide(), df:GetTall(), s_table, "command", true, FILL )
		 end)
		 menu.mb.m4:AddOption("View as JSON", function()
			local s_table = util.TableToJSON( weapons.GetStored( class ), true )
			local df = ZDEV.VGUI.CreateFrame( SW * 0.33, SH * 0.33, class .. " SWEP Table - JSON" )
			df.te = ZDEV.VGUI.CreateTextEntry( df, df:GetWide(), df:GetTall(), s_table, "command", true, FILL )
		 end)
		 menu.mb.m4:AddOption("Export to KeyValues", function()
		 local t_wep = weapons.GetStored( class )
			ZDEV.DATA.ExportToJSON( t_wep, string.lower( class ) )
		 end)
		 menu.mb.m4:AddOption("Export to JSON", function()
		 local t_wep = weapons.GetStored( class )
			ZDEV.DATA.ExportToJSON( t_wep, string.lower( class ) )
		 end)
	  menu.mb.m4 = menu.mb:AddMenu( "Options" )
	    menu.mb.m4:AddOption( "Settings", function() end ):SetIcon( "icon16/cog.png")

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    TOP PANEL / PROJECT/FILE INFO
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.p_t = vgui.Create( "DPanel", menu )
	menu.p_t:Dock(TOP)
	menu.p_t:DockMargin( 1, 1, 1, 1 )
	menu.p_t:SetTall( menu_h * 0.15 )
	local count_i = 0
	local count_o = 0
	menu.p_t.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color(60,60,60,100) )
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 2, Color(100,100,255,255) )

		local file_cur = EDITOR.File.Current.name
		draw.DrawText( file_cur, "command", 0.1, 0.05, color_white, TEXT_ALIGN_LEFT )

		local particles_keys = table.GetKeys( EDITOR.File.Emitters.Particles )
		for k, v in pairs( EDITOR.File.Emitters.Particles ) do
			count_i = count_i + 1
			draw.DrawText( k .. " = " .. tostring( v ), "command", 0.15, 0.05 + count_i * 9, color_white, TEXT_ALIGN_LEFT )
			
			if type( v ) == "table" then 
				for j, c in pairs( v ) do
					count_o = count_o + 1
					draw.DrawText( tostring( j ) .. " = " .. tostring( c ), "visitor", 0.175, 0.05 + count_o * 9, Color(255,150,0), TEXT_ALIGN_LEFT )
				end
			end
		end
		count_i = 0
		count_o = 0
	end

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    BOTTOM PANEL / TIMELINE
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	 CENTER PANEL
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.p_b = vgui.Create( "DPanel", menu )
	menu.p_b:Dock(BOTTOM)
	menu.p_b:DockMargin( 1, 1, 1, 1 )
	menu.p_b.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color(60,60,60,100) )
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 1, Color(100,100,255,255) )
	end

	menu.p_b.bt01 =  ZDEV.VGUI.CreateButton( menu.p_b, 64, 24, "ADD", "raj", Color(100,255,100), function()
		local convars = GetCurrentConVars()
		table.insert( EDITOR.File.Emitters.Particles, 1, convars )
		zdev.log( "S", "Added particle with ID: " .. tostring( convars.id ) .. " to current Emitter" )
	end )
	menu.p_b.bt01:Dock( LEFT )

	menu.p_b.bt02 =  ZDEV.VGUI.CreateButton( menu.p_b, 64, 24, "RESET", "raj", Color(255,150,50), function()
	end )
	menu.p_b.bt02:Dock( LEFT )

	menu.p_b.bt03 =  ZDEV.VGUI.CreateButton( menu.p_b, 64, 24, "TEST", "raj", Color(100,150,255), function()
		local convars = GetCurrentConVars()
		PrintTable( convars )
	end )
	menu.p_b.bt03:Dock( LEFT )

	menu.p_b.tl = vgui.Create( "DPanel", menu.p_b )
	menu.p_b.tl:Dock( FILL )
	--menu.p_b.tl:DockMargin( menu_w * 0.025, 1, menu_w * 0.025, 1 )
	menu.p_b.tl.Paint = function( self, w, h )
		draw.RoundedBox( 6, 0, 0, w, h, Color(200,200,200,255) )
	end
	menu.p_b.tl.PaintOver = function( self, w, h )
		for i = 1, 60 do
			local w_s = w/60
			draw.DrawText( i, "micro", -w_s*0.5 + w_s * i, 0, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM )
			draw.RoundedBox( 0, -w_s*0.5 + w_s * i, 0, 1, h * 0.33, Color(50,50,50,255) )
		end

		for k, v in ipairs( PARTICLES ) do
			local life, die = v.lifetime, v.dietime
			draw.RoundedBox( 0, 0, h - k*1, life * w, 2, Color(100,255,100) )
			draw.RoundedBox( 0, (life * w), (h-1) - k*1, die * w, 2, Color(255,100,100) )
		end
	end

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    LEFT PANEL - PROPERTIES
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.sp_L = vgui.Create( "DScrollPanel", menu )
	menu.sp_L:Dock(FILL)
	menu.sp_L:SetWide( menu_w * 0.25)
	menu.sp_L.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color(120,120,120, 255) )
--		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 1, Color(255,100,100, 255) )
	end



	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.sp_L.f = vgui.Create( "DForm", menu.sp_L )
	menu.sp_L.f:Dock( TOP )
	menu.sp_L.f:SetName( "Properties" )
	local ch_1 = menu.sp_L.f:ControlHelp( "Material" )
	ch_1:SetTall( form_item_h)
	ch_1.Paint = function( self, w, h ) 
		draw.RoundedBox(4,0,0,w,h,Color(0,0,0,100) )
	end
	local mat = vgui.Create( "DImage", menu.sp_L.f )
	mat:Dock( TOP )
	--mat:SetWide( menu.sp_L:GetWide())
	--mat:SetTall( mat:GetWide() )
	mat:SetSize( 256, 256 )
	mat:SetImage( GetConVarString("zedit_particle_mat")..".vmt" )
	mat.PaintOver = function( self, w, h )
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 2, Color(0,0,0,100) )
	end
	local btn_file = vgui.Create( "DButton", menu.sp_L.f )
	--btn_file:Dock(BOTTOM)
	--btn_file:DockMargin( mat:GetWide() * 0.9, mat:GetTall() * 0.95, 0, 0 )
	btn_file:SetText( "..." )
	btn_file.DoClick = function( self )
	--	ZDEV.VGUI.FileManager( "zd_vgui_filebrowser", LocalPlayer(), {"THIRDPARTY","materials","" } )
		ZDEV.VGUI.Editor_Materials( "zd_menu_dev_mat", LocalPlayer(),{GetConVar("zedit_particle_mat"):GetString()})
	end

	local form_item_h = 12

	local f_mat = menu.sp_L.f:AddItem( mat, btn_file )
	local f_te1 = menu.sp_L.f:TextEntry( "Material", "zedit_particle_mat" )
	f_te1:SetFont( "DefaultSmall")
	f_te1:SetTextColor( Color(0,0,0,255) )
	f_te1:SetTall(form_item_h)
	local f_te2 = menu.sp_L.f:TextEntry( "Color", "zedit_particle_color" )
	f_te2:SetFont( "DefaultSmall")
	f_te2:SetTall(form_item_h)
	local f_cb1 = menu.sp_L.f:CheckBox( "Lighting", "zedit_particle_lighting" )
	f_cb1:SetTall( form_item_h)
	local f_ns0a = menu.sp_L.f:NumSlider( "Count (Min)", "zedit_particle_count_min", 0, 999, 0)
	f_ns0a:SetTall( form_item_h)
	local f_ns0b = menu.sp_L.f:NumSlider( "Count (Max)", "zedit_particle_count_max", 0, 999, 0)
	f_ns0b:SetTall( form_item_h)
	local f_ch2 = menu.sp_L.f:ControlHelp( "Time")	f_ch2:SetTall( form_item_h)
	local f_ns1a = menu.sp_L.f:NumSlider( "Repeat Rate", "zedit_particle_repeat", 0.000, 99.999, 3 )
	f_ns1a:SetTall( form_item_h)
	local f_ns1 = menu.sp_L.f:NumSlider( "Lifetime", "zedit_particle_lifetime", 0.000, 9.999, 3 )
	f_ns1:SetTall( form_item_h)
	local f_ns2 = menu.sp_L.f:NumSlider( "Dietime", "zedit_particle_dietime", 0.000, 9.999, 3)
	f_ns2:SetTall( form_item_h)
	local f_ch3 = menu.sp_L.f:ControlHelp( "Start")
	f_ch3:SetTall( form_item_h)
	local f_ns3 = menu.sp_L.f:NumSlider( "Start Size", "zedit_particle_size_s", 0.00, 99.99, 3 )
	f_ns3:SetTall( form_item_h)
	local f_ns4 = menu.sp_L.f:NumSlider( "Start Alpha", "zedit_particle_alpha_s", 0, 255, 0)
	f_ns4:SetTall( form_item_h)
	local f_ns5 = menu.sp_L.f:NumSlider( "Start Length", "zedit_particle_length_s", 0.00, 99.99, 3 )
	f_ns5:SetTall( form_item_h)
	local f_ch4 = menu.sp_L.f:ControlHelp( "End")
	f_ch4:SetTall( form_item_h)
	local f_ns6 = menu.sp_L.f:NumSlider( "End Size", "zedit_particle_size_e", 0.000, 99.999, 3 )
	f_ns6:SetTall( form_item_h)
	local f_ns7 = menu.sp_L.f:NumSlider( "End Alpha", "zedit_particle_alpha_e", 0, 255, 0 )
	f_ns7:SetTall( form_item_h)
	local f_ns8 = menu.sp_L.f:NumSlider( "End Length", "zedit_particle_length_e", 0.000, 99.999, 3 )
	f_ns8:SetTall( form_item_h)
	local f_ch5 = menu.sp_L.f:ControlHelp( "Rotation")
	f_ch5:SetTall( form_item_h)
	local f_te3 = menu.sp_L.f:TextEntry( "Angles (p y r)", "zedit_particle_angles" )
	f_te3:SetTall( form_item_h)
	local f_te4 = menu.sp_L.f:TextEntry( "Angular Velocity (p y r)", "zedit_particle_angular_velocity" )
	f_te4:SetTall( form_item_h)
	local f_ns9 = menu.sp_L.f:NumSlider( "Roll", "zedit_particle_roll", 0, 360, 2 )
	f_ns9:SetTall( form_item_h)
	local f_ns10 = menu.sp_L.f:NumSlider( "Roll-Delta", "zedit_particle_rolldelta", 0, 360, 2 )
	f_ns10:SetTall( form_item_h)
	local f_ch6 = menu.sp_L.f:ControlHelp( "Movement")
	f_ch6:SetTall( form_item_h)
	local f_ns11 = menu.sp_L.f:NumSlider( "Bounce", "zedit_particle_bounce", 0, 9.99, 3 )
	f_ns11:SetTall( form_item_h)
	local f_cb7 = menu.sp_L.f:CheckBox( "Collide", "zedit_particle_collide" )
	f_cb7:SetTall( form_item_h)
	local f_ns12 = menu.sp_L.f:NumSlider( "Air Resistance", "zedit_particle_airres", 0, 999, 0 )
	f_ns12:SetTall( form_item_h)
	local f_te5 = menu.sp_L.f:TextEntry( "Gravity (x y z)", "zedit_particle_gravity" )
	f_te5:SetTall( form_item_h)
	local f_te6 = menu.sp_L.f:TextEntry( "Velocity (x y z)", "zedit_particle_velocity" )
	f_te6:SetTall( form_item_h)
	local f_te7 = menu.sp_L.f:TextEntry( "Velocity Multiplier", "zedit_particle_velocity_mul", 0.00, 99.99, 3 )
	f_te7:SetTall( form_item_h)

		--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	    CENTER PANEL
		━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	menu.sp_R = vgui.Create( "DScrollPanel", menu )
	menu.sp_R:Dock(RIGHT)
	menu.sp_R:SetWide( menu_w * 0.15)
	menu.sp_R.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color(60,60,60, 100) )
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 1, Color(255,200,50, 255) )
	end

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    CENTER PANEL
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	menu.p_c = vgui.Create( "DPanel", menu )
	menu.p_c:Dock(FILL)
	menu.p_c:DockMargin( 1, 1, 1, 1 )
	menu.p_c.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color(60,60,60, 100) )
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 1, Color(100,255,100, 255) )
	end

	menu.p_c.lv = vgui.Create( "DListView", menu.p_c )
	menu.p_c.lv:Dock( TOP )
	menu.p_c.lv:DockMargin( 1, 1, 1, 29 )
	menu.p_c.lv:SetTall( menu_h * 0.25 )
	menu.p_c.lv:SetMultiSelect( true )
	menu.p_c.lv:AddColumn( "#" )
	menu.p_c.lv:AddColumn( "ID" )
	menu.p_c.lv:AddColumn( "Material" )
	menu.p_c.lv:AddColumn( "Lifetime" )
	menu.p_c.lv:AddColumn( "Dietime" )
	menu.p_c.lv:AddColumn( "Start Size" )
	menu.p_c.lv:AddColumn( "Start Alpha" )
	menu.p_c.lv:AddColumn( "Start Length" )
	menu.p_c.lv:AddColumn( "End Size" )
	menu.p_c.lv:AddColumn( "End Alpha" )
	menu.p_c.lv:AddColumn( "End Length" )
	menu.p_c.lv:AddColumn( "Air" )
	menu.p_c.lv:AddColumn( "Bounce" )
	menu.p_c.lv:AddColumn( "Collide" )
	menu.p_c.lv:AddColumn( "Lighting" )
	menu.p_c.lv:AddColumn( "Roll" )
	menu.p_c.lv:AddColumn( "Roll Delta" )
	menu.p_c.lv:AddColumn( "Color" )
	menu.p_c.lv:AddColumn( "Gravity" )
	menu.p_c.lv:AddColumn( "Velocity" )
	menu.p_c.lv:AddColumn( "Angles" )
	menu.p_c.lv:AddColumn( "Angular Velocity" )

	for i, p in ipairs( PARTICLES ) do

		local num, id, mat, life, die = i, p.id, p.material, p.lifetime, p.dietime
		local size_s, alpha_a, len_a, size_e, alpha_e, len_e = p.start_size, p.start_alpha, p.start_length, p.end_sie, p.end_alpha, p.end_length
		local air, bounce, coll, color = p.airres, p.bounce, p.collide, Color(p.color_r, p.color_g, p.color_b, p.color_a )
		local grav, vel = p.gravity, p.velocity
		local roll, rolldelta, ang, ang_vel = p.roll, p.rolldelta, Angle(p.angles). Angle(p.ang_velocity)
		local light = p.lighting

		menu.p_c.lv:AddLine( num, id, mat, life, die, size_s, alpha_a, len_a, size_e, alpha_e, len_e, air, bounce, coll, light, roll, rolldelta, color, grav, vel, ang, ang_vel )

	end

	menu.p_c.pl_C = vgui.Create( "DPanel", menu.p_c)
	menu.p_c.pl_C:Dock( FILL )
	menu.p_c.pl_C.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color(60,60,60,255) )
	end

	menu.p_c.pl_C.mp = vgui.Create( "DAdjustableModelPanel", menu.p_c.pl_C )
	menu.p_c.pl_C.mp:StretchToParent(1,1,1,1)
	menu.p_c.pl_C.mp:Dock( FILL )
	menu.p_c.pl_C.mp:SetModel( "models/hunter/plates/plate.mdl" )
	menu.p_c.pl_C.mp:SetFOV( 40 )
	menu.p_c.pl_C.mp:SetAmbientLight(Color(150, 150, 150, 255))
--	menu.p_c.pl_C.mp:SetPaintBackgroundEnabled( true )
--	menu.p_c.pl_C.mp:SetPaintBackground( true )
	--menu.p_c.pl_C.mp:SetBackgroundColor( Color(60,60,60) )
	--menu.p_c.pl_C.mp.Paint = function( self, w, h )
	--	draw.RoundedBox( 0, 0, 0, w, h, Color(60,60,60,255) )
--	end
	menu.p_c.pl_C.mp.PostDrawModel = function( self, ent )
		if ( !IsValid( self.Entity ) ) then return end

		local x, y = self:LocalToScreen( 0, 0 )
		local w, h = self:GetSize()

		self:LayoutEntity( self.Entity )

		local ang = self.aLookAngle
		if ( !ang ) then
			ang = ( self.vLookatPos - self.vCamPos ):Angle()
		end
		local emit_pos = Vector(0,0,0)
		cam.Start3D( self.vCamPos, ang, self.fFOV, x, y, w, h, 5, self.FarZ )

			render.SetColorMaterial()
			render.DrawBox( Vector(0,0,0), Angle(0,0,0), Vector(-1,-1,-1), Vector(1,1,1), Color(200,100,50,100), true )


			local emit = ParticleEmitter( emit_pos )
			emit:SetNoDraw( false)
		for k, p in ipairs( PARTICLES ) do

		--		draw.DrawText( table.ToString(p,"Table",true) ,"DermaDefault",0, 0, Color( 255, 255, 255, 255 ),TEXT_ALIGN_LEFT)

				local num, id, mat, life, die = k, p.id, p.material, p.lifetime, p.dietime
				local size_s, alpha_s, len_s, size_e, alpha_e, len_e = p.start_size, p.start_alpha, p.start_length, p.end_size, p.end_alpha, p.end_length
				local air, bounce, coll, color = p.airres, p.bounce, p.collide, Color(p.color_r, p.color_g, p.color_b, p.color_a )
				local grav, vel = string.Explode(" ",p.gravity,false), string.Explode(" ",p.velocity,false)

				local v_grav = Vector( grav[1], grav[2], grav[3])
				local v_vel = Vector( vel[1], vel[2], vel[3])

				local pa = emit:Add( mat, emit_pos )
				pa:SetLifeTime( life )
				pa:SetDieTime( die )
				pa:SetStartSize( size_s )
				pa:SetStartAlpha( alpha_s )
				pa:SetStartLength( len_s )
				pa:SetEndSize( size_e )
				pa:SetEndAlpha( alpha_e )
				pa:SetEndLength( len_e )
				pa:SetAirResistance( air )
				pa:SetBounce( bounce )
				pa:SetCollide( coll )
				--pa:SetColor( color )
				--pa:SetGravity( Vector(0,0,100) )
			--	pa:SetVelocity( VectorRand() * 300 )
			end

			emit:Draw()
			emit:Finish()

		cam.End3D()


	end
	]]
	
--[[
	menu.p_c.pl_C.mv = vgui.Create( "DModelPanel", menu.p_c.pl_C )
	menu.p_c.pl_C.mv:Dock( FILL )
	menu.p_c.pl_C.mv.dock_r = menu.p_c.pl_C:GetWide() * 0.5
	menu.p_c.pl_C.mv:DockMargin( 1, 1, menu.p_c.pl_C.mv.dock_r, 1)
	menu.p_c.pl_C.mv:SetModel( "models/hunter/plates/plate.mdl" ) -- you can only change colors on playermodels
	function menu.p_c.pl_C.mv:LayoutEntity( ent )
		return
	end -- disables default rotation
--	function icon.Entity:GetPlayerColor()
--		return Vector (1, 0, 0)
	--end

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    BUTTON-BAR BOTTOM
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	menu.p_c.pl_T = vgui.Create( "DPanel", menu.p_c )
	menu.p_c.pl_T:Dock( BOTTOM  )
	--menu.p_c.pl_T:DockMargin( 1, 1, 1, menu_h * 0.4 )


	menu.p_c.pl_T.bt0 = ZDEV.VGUI.CreateButton( menu.p_c.pl_T, 64, 28, "ADD", "sadmachine", Color(100,255,100), function( self )

		-- Capture the current convar values and store them into table
		local particle = {
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
			velocity = GetConVarString("zedit_particle_velocity")
		}
		-- Insert table into PARTICLES INDEX
		table.insert( PARTICLES, #PARTICLES, particle )
		-- Run command to increase value of next particle id
		RunConsoleCommand( "zedit_particle_id", particle.id .. "" .. #PARTICLES )

		menu.p_c.lv:DataLayout()
		menu.p_c.lv:InvalidateLayout( true )

		DebugPrintTable( particle )

	end)
	menu.p_c.pl_T.bt0:Dock(LEFT)
	menu.p_c.pl_T.bt1 = ZDEV.VGUI.CreateButton( menu.p_c.pl_T, 64, 28, "CONSOLE",  "sadmachine", Color(255,150,100),function( self ) RunConsoleCommand( "zd_dev_console") end )
	menu.p_c.pl_T.bt1:Dock(LEFT)
	menu.p_c.pl_T.bt2 = ZDEV.VGUI.CreateButton( menu.p_c.pl_T, 64, 28, "GO-TO",  "sadmachine", Color(255,150,0),function( self )	ZDEV.VGUI.FileManager( "lua" )	end )
	menu.p_c.pl_T.bt2:Dock(LEFT)
	menu.p_c.pl_T.btx = ZDEV.VGUI.CreateButton( menu.p_c.pl_T, 64, 28, "CLOSE",  "sadmachine", Color(255,100,100),function( self )	menu:Close() end )
	menu.p_c.pl_T.btx:Dock(RIGHT)

]]

	menu:SetPopupStayAtBack( true )
	return menu
end
concommand.Add( "zd_menu_dev_part", ZDEV.VGUI.ParticleMenu )
ZDEV.VGUI.AddToMainMenu( "zd_menu_dev_part" )

ZDEV.FILE.SetLoaded( _f )

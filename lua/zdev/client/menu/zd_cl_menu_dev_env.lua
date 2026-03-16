local _f = 'zdev/client/vgui/zd_cl_menu_dev_env.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
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
	Emitters = {},
	m_bMouseCapture = false,
	m_bKeyCapture = false
}

-- Local tables for storing information real-time aboutthe CURRENT selection
local EMITTERS = {}		-- Contains all the emitters that are currently Open in the editor
local emitter = {
	open = false,
	filename = ""
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

local function NewEmitter( )
 --awd
end

local function PaintTimeGraph( )
	local x, y, w, h = 0, SH * 0.925, SW, SH * 0.075
	local space_w = 15
	local size_h = h * 0.5
	draw.RoundedBox( 0, x, y, w, h, Color(150,150,150,255) )
	for i = 1, 100 do
		draw.RoundedBox( 0, x + i * space_w, y + size_h * 0.5, 1, size_h , Color(50,50,50,255) )
		draw.DrawText( tostring(i/10), "DefaultSmall", x+ i * space_w, y, Color(0,0,0,255), TEXT_ALIGN_CENTER )
	end
	for i = 1, 100 do
		draw.RoundedBox( 0, x + space_w*0.5 + i * space_w , y + size_h*0.75, 1, size_h * 0.5 , Color(0,0,0,255) )
	end

end
hook.Add( "HUDPaint", "ZDEV.EDIT.ParticleEditor", function()
	if GetConVar( "zedit_particle_show_timegraph" ):GetBool() then
		PaintTimeGraph( )
	end
end )

-- ZDEV_UID: ZDEV_FUNC_D14BF9F9 | Path: ZDEV.VGUI.EnvironmentMenu
function ZDEV.VGUI.EnvironmentMenu( )

	RunConsoleCommand( "zedit_env_toggle", "1" )

	local menu = {}
	local menu_w, menu_h = SW * 0.2, SH 
	menu = ZDEV.VGUI.CreateFrame( menu_w, menu_h, "ZDEV Environment Editor")
	menu:SetPos( 0, 0 )
	--menu:ParentToHUD()
	menu:SetKeyboardInputEnabled( true )
	menu:SetMouseInputEnabled( true )
	--gui.EnableScreenClicker( true )
	menu.OnClose = function( self )
		RunConsoleCommand( "zedit_env_toggle", "0" )
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

	menu:SetPopupStayAtBack( true )
	return menu
end
concommand.Add( "zd_menu_dev_env", ZDEV.VGUI.EnvironmentMenu )
ZDEV.VGUI.AddToMainMenu( "zd_menu_dev_env" )

ZDEV.FILE.SetLoaded( _f )

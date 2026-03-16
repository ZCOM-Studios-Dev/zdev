local _f = 'zdev/client/vgui/zd_cl_menu_dev.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')

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
local TEAM_SPY = TEAM_SPY
local TEAM_MERC = TEAM_MERC

--ZDEV = ZDEV or {}
-- print('')

local cli = LocalPlayer()
local SW, SH = ScrW(), ScrH()

local t_nodes_ents = {
	["Entities"] = { 
		["prop"] = {"prop_physics",	"prop_dynamic",	"prop_dynamic_ornament"},
		["env"] = {"env_sprite", "env_lightglow", "env_explosion", "env_physexplosion"},
		["Info"] = {"info_target","info_particle_system"}
	},
	["NPCs"] = {
		"zdev_nextbot_chase",
		"zdev_nextbot_citizen"
	},
	["Weapons"] = {
		"zdev_weapon_pist_usp",
		"zdev_weapon_pist_p228",
		["Pistols"] = {
			"zdev_weapon_pist_glock",
			"zdev_weapon_pist_fiveseven"
		}
	}
}

local t_list_ents = {}

local t_typeconv = {
  ["int"] = "Int",
  ["number"] = "Int",
  ["boolean"] = "Boolean",
  ["float"] = "Float",
  ["string"] = "Generic",
  ["IMaterial"]= "Generic",
  ["Angle"] = "VectorColor",
  ["Vector"] = "VectorColor",
  ["table"] = "Generic",
  ["choice"] = "Combo",
  ["entity"] = "Generic",
  ["sound"] = "Generic",
  ["textureID"] = "Generic",
  ["table"] = "Combo"
}

DEV = {}
DEV.SelectedEnt = {}
DEV.ENTS = {}
DEV.KEYVALUES = {}
DEV.PROPERTIES = {}
local e_lastSpawn
local function PopulateRows( pr, tbl )

	for k, v in pairs( tbl ) do

		print( k, type(v) )

		if type(v) ~= "function" then 
			local s_DataType = t_typeconv[ type(v) ]
			local t_setup = {}
			local row = pr:CreateRow( "Main", k )
			row:Setup( s_DataType, t_Setup )
			row:SetValue( v )
			row.DataChanged = function( self, data )

				if s_DataType == "Boolean" then
					data = tobool(data)
				end

				pr.rows[ k ] = row

			end
		end

	end
	
	pr:InvalidateLayout( true )
	pr:SizeToChildren( false, true )

end
  --[[=============================================================
    ZDEV Test VGUI Mwnu
  ==================================================================]]
-- ZDEV_UID: ZDEV_FUNC_BCF5B694 | Path: ZDEV.VGUI.DevMenu
function ZDEV.VGUI.DevMenu( ply, cmd, arg )

	DEV = DEV or {}

	cli = LocalPlayer()
	if !cli or !IsValid(cli) or cli ~= LocalPlayer() then return end
	e_lastSpawn = cli:GetNWEntity( "LastDevSpawn" )
	
	t_list_ents = t_list_ents or {}

	local menu = {}
	local menu_w, menu_h = SW * 0.66, SH * 0.66
	menu = ZDEV.VGUI.CreateFrame( menu_w, menu_h, "ZDEV Dev Menu")
	menu.t_list_ents = {}
	menu._DevSelectEnt = function( entindex )
		local ent, tbl
		ent = Entity( entindex )
		DEV.SelectedEnt = ent
		tbl = ent:GetSaveTable()
		PopulateRows( menu.pr, tbl )
	end
	local wide, tall = menu_w, menu_h
  --[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    DMENU BAR
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.mb = vgui.Create( "DMenuBar", menu )
	menu.mb:DockMargin(2,2,2,0)

	menu.mb.m1 = menu.mb:AddMenu( "File" )
		menu.mb.m1:AddOption( "New", function() ZDEV.VGUI.FileManager() end ):SetIcon( "icon16/page_white_go.png")
		menu.mb.m1:AddOption( "Open", function()
			ZDEV.VGUI.FileManager( "data", "zdev", "weapons" )
		end ):SetIcon( "icon16/folder.png")
		menu.mb.m1:AddOption( "Save", function()
			Derma_StringRequest( "Save Filename","Directory: 'zdev/weapons/'","weapon_filename.txt",
		function( s_txt )
			ZDEV.WEAP.SaveFile( s_txt, t_WeaponData )
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
	menu.mb.m4 = menu.mb:AddMenu( "View" )
		menu.mb.m4:AddOption( "Toggle HUD Time-Globals", function() 
			local conv = GetConVar("zd_dev_hud_time"):GetBool()
			local new
			if ( conv == true ) then new = 0 
			elseif ( conv == nil or conv == false ) then new = 1 end
			LocalPlayer():ConCommand( "zd_dev_hud_time "..new )
		end) 
		menu.mb.m4:AddOption( "Toggle Dev Crosshair", function() 
			local conv = GetConVar("zd_dev_hud_xhair"):GetBool()
			local new
			if ( conv == true ) then new = 0 
			elseif ( conv == nil or conv == false ) then new = 1 end
			LocalPlayer():ConCommand( "zd_dev_hud_xhair "..new )
		end) 
		menu.mb.m4:AddOption( "Toggle Dev HUD-Grid", function() 
			local conv = GetConVar("zd_dev_hud_grid"):GetBool()
			local new
			if ( conv == true ) then new = 0 
			elseif ( conv == nil or conv == false ) then new = 1 end
			LocalPlayer():ConCommand( "zd_dev_hud_grid "..new )
		end) 
	menu.mb.m3 = menu.mb:AddMenu( "Options" )



		menu.mb.m3:AddOption( "Settings", function() 
		end ):SetIcon( "icon16/cog.png")
	
	menu.spL = vgui.Create("DScrollPanel", menu )
	menu.spR = vgui.Create("DScrollPanel", menu )
	menu.spC = vgui.Create("DScrollPanel", menu )

	menu.nt = ZDEV.VGUI.CreateNodeTree( menu.spL, 2, 26, wide, tall, t_nodes_ents )
	menu.spL:AddItem( menu.nt )
	
	menu.pr = vgui.Create( "DProperties", menu.spR )
	menu.spR:AddItem( menu.pr )

	menu.lv = vgui.Create( "DListView", menu.spC )
	menu.spC:AddItem( menu.lv )
	
	menu.spL:Dock( LEFT )
	--menu.spL:DockMargin(2, 2, 2, tall*0.33)
	menu.spL:SetSize( wide *0.2, tall*0.5 )
	menu.spL.Paint = function( self, w, h )
		local clr = Color(0,200,255, 100)
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 2, clr )
		draw.RoundedBox(0, 0, 0, w, h, ColorAlpha(clr,30) )
	end
	menu.spR:Dock( RIGHT )
	--menu.spR:DockMargin( 2,2,2,tall*0.33 )
	menu.spR:SetSize( wide *0.2, tall*0.5)
	menu.spR.Paint = function( self, w, h )
		local clr = Color(255,180,50)
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 2, clr )
		draw.RoundedBox(0, 0, 0, w, h, ColorAlpha(clr,30) )
	end
	menu.spC:Dock( TOP )
	--menu.spC:DockMargin(wide*0.15, 2, wide*0.15, tall*0.33)
	menu.spC:SetSize( wide *0.66, tall*0.33)
	menu.spC.Paint = function( self, w, h )
		local clr = Color(100,255,100, 100)
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 2, clr )
		draw.RoundedBox(0, 0, 0, w, h, ColorAlpha(clr,30) )
	end
--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
NODE TREE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]	

	menu.nt:Dock( TOP )
	menu.nt:SetTall( menu_h*0.5)
	--menu.nt:DockMargin(2, 2, 2,2)
	menu.nt.OnNodeSelected = function( self, node )
		--menu._DevSelectEnt( node._name )
	end

	local n = menu.nt:AddNode( "Materials" )
	n:MakeFolder( "materials", "THIRDPARTY", true )

  --[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    LISTVIEW
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

	menu.lv:Dock(TOP)
	menu.lv:SetTall( menu_h * 0.33)
	--menu.lv:SetSize( wide, tall*0.5 - 30 )
	menu.lv:SetMultiSelect( false )
	menu.lv:AddColumn( "Index" )
	menu.lv:AddColumn( "Classname" )
	menu.lv:AddColumn( "BaseClass" )
	for k, i in pairs( ents.GetAll() ) do
		local n = i
		menu.lv:AddLine( n:EntIndex(), n:GetClass(), tostring(n:GetPos()) )
	end
	menu.lv.OnRowSelected = function( lst, index, pnl )
		print(lst, index, pnl )
		
		menu._DevSelectEnt( pnl:GetColumnText(1) )
		--ZDEV.DBUG.GetNPCInfo( Entity(pnl:GetColumnText(1) ) )
		--DebugPrintTable( ZDEV.DBUG.NPC )
	end

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	PANELLIST:LEFT - PROPERTIES
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.pr:Dock( TOP )
	menu.pr:SetTall( menu_h )
	local row_tgtname = menu.pr:CreateRow( "Global", "EntityName")
	row_tgtname:Setup( "Generic" )
	row_tgtname:SetValue( tostring(DEV.SelectedEnt) )
	row_tgtname.DataChanged = function( _, val )
		DEV.PROPERTIES["EntityName"] = val
	end
	--menu.pr:DockMargin( 2, 2, 2, 2 )
	--menu.pr:SetSize( wide, tall * 0.33)
	--menu.pr:MoveBelow( menu.lv )
	menu.pr.rows = {}



  --[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    BUTTON-BAR BOTTOM
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.dPL = vgui.Create( "DPanelList", menu )
	menu.dPL:Dock( BOTTOM )

	menu.dPL.bt0 = ZDEV.VGUI.CreateButton( menu.dPL, 64, 28, "SPAWN", "sadmachine", Color(100,255,100), function( self )	RunConsoleCommand("zd_ent_create", DEV.SelectedClass )	timer.Simple( 0.1, function() 
		local ent = cli:GetNWEntity( "LastDevSpawn" )
		print(ent)
		t_list_ents[ #t_list_ents + 1 ] = ent:EntIndex()
	end ) end )
	menu.dPL.bt0:Dock(LEFT)

	menu.dPL.bt1 = ZDEV.VGUI.CreateButton( menu.dPL, 64, 28, "CONSOLE",  "sadmachine", Color(255,150,100),function( self ) RunConsoleCommand( "zd_dev_console") end )
	menu.dPL.bt1:Dock(LEFT)

	menu.dPL.bt2 = ZDEV.VGUI.CreateButton( menu.dPL, 64, 28, "GO-TO",  "sadmachine", Color(255,150,0),function( self )	ZDEV.VGUI.FileManager( "lua" )	end )
	menu.dPL.bt2:Dock(LEFT)

	menu.dPL.btx = ZDEV.VGUI.CreateButton( menu.dPL, 64, 28, "CLOSE",  "sadmachine", Color(255,100,100),function( self )	menu:Close() end )
	menu.dPL.btx:Dock(RIGHT)

end
concommand.Add( "zd_menu_dev", ZDEV.VGUI.DevMenu )
ZDEV.VGUI.AddToMainMenu( "zd_menu_dev" )

local function SendZDevConCmd( cmd )
	net.Start( "zdev_con_lua_tosv", false)
		net.WriteEntity( LocalPlayer() )
		net.WriteString( cmd )
	net.SendToServer()
end

local function inQuad(fraction, beginning, change)
	return change * (fraction ^ 2) + beginning
end


CONSOLE = CONSOLE or {}
CONSOLE.CMD = CONSOLE.CMD or ""
CONSOLE.LOG = CONSOLE.LOG or ""

--[[
-- ZDEV_UID: ZDEV_FUNC_B82A89AD | Path: ZDEV.VGUI.DevConsole
function ZDEV.VGUI.DevConsole( ply, cnd, arg )

	--gui.EnableScreenClicker( true )

	CONSOLE = CONSOLE or {}
	CONSOLE.CMD = CONSOLE.CMD or ""
	CONSOLE.LOG = CONSOLE.LOG or ""

	local conv = {}
	conv.con_x = GetConVar( "zd_dev_console_x" ):GetInt() or SW * 0.1
	conv.con_y = GetConVar( "zd_dev_console_y"):GetInt() or SH * 0.33
	conv.con_w, conv.con_h = GetConVar( "zd_dev_console_w"):GetInt() or SW * 0.33, GetConVar( "zd_dev_console_h" ):GetInt() or SH * 0.2

	local con = ZDEV.VGUI.CreateFrame( conv.con_w, conv.con_h, "ZDEV Development Lua Console" )
	con:SetPos( conv.con_w *-1, conv.con_y)
	con:SetKeyboardInputEnabled( true )
	con.OnClose = function( self )
		gui.EnableScreenClicker( false )
	end
	local anim = Derma_Anim("EaseInQuad", con, function(pnl, anim, delta, data)
		--local cur_x, cur_y = con:GetPos()
		pnl:SetPos(inQuad(delta, 0, conv.con_x), conv.con_y) -- Change the X coordinate from 200 to 200+600
	end)
	anim:Start(2) -- Animate for two seconds
	con.Think = function(self)
		if anim:Active() then
			anim:Run()
		end
	end

	con.log = vgui.Create( "DLabel", con )
	con.log:Dock( FILL )
	con.log:DockMargin(1, 1, 1, 1)
	con.log:SetText( CONSOLE.LOG )
	con.log:SetFont("reactor7")
	con.log:SetTextColor( Color(0,200,255) )
	con.log.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color(0,50,90) )
	end
	con.te = vgui.Create( "DTextEntry", con )
	con.te.command = ""
	con.te:Dock( BOTTOM )
	con.te:SetMultiline( false )
	con.te:DockMargin(1,1,1,1)
	con.te.OnKeyCodeTyped = function( elf, keyCode )
		if keyCode == KEY_ENTER then
			--table.insert( CONSOLE.LOG, 0, CONSOLE.CMD )
			CONSOLE.LOG = " >" .. con.te:GetValue() .. "\n" .. CONSOLE.LOG
			con.log:SetText( CONSOLE.LOG )

			print( CONSOLE.CMD )
			SendZDevConCmd( con.te:GetValue() )
		end
	end
	con.te.OnValueChange = function( new )
		print( new )
		CONSOLE.CMD = con.te:GetValue()
		return true
	end

	ZDEV.VGUI.CONSOLE = con

end
concommand.Add( "+zd_dev_console", ZDEV.VGUI.DevConsole )

-- ZDEV_UID: ZDEV_FUNC_592FDFA6 | Path: ZDEV.VGUI.DevConsole_Close
function ZDEV.VGUI.DevConsole_Close( ply, cnd, arg )
	if ZDEV.VGUI.CONSOLE then

		ZDEV.VGUI.CONSOLE:Close()
	end
end
concommand.Add( "-zd_dev_console", ZDEV.VGUI.DevConsole_Close )

hook.Add( "OnContextMenuOpen", "ZDEV.VGUI.DevConsole", ZDEV.VGUI.DevConsole )
hook.Add( "OnContextMenuClose", "ZDEV.VGUI.DevConsole.Close", ZDEV.VGUI.DevConsole_Close )
]] 
ZDEV.FILE.SetLoaded( _f )

local _f = 'zdev/client/vgui/zd_cl_menu_dev_efx.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
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

EFX = {}
EFX.INDEX = {}
EFX.File = "zdev/sefx/effects_index.txt"
EFX.LastSave = 0
EFX.LastLoad = 0
EFX.Spawned = {}
EFX.Table = {}
EFX.Cache = {}

local t_allowedColumns = {File = true,	Folder = true,	ID = true,	Name = true }

local t_list_efx = t_list_efx or {}
local t_col, t_line = {}, {}


-- FUNC-CL Store local Cache of All registered scripted effects and store a copy in the passed menu
local function CacheEffects( menu )

	t_col = {}

	for k, i in pairs( effects.GetList() ) do -- For
		t_line = {}

		for j, c in pairs( i ) do	-- For every key/value in every effect's table

			local c_msgclr = Color(100,100,100)

			if !EFX.Table[ j ] then		-- If we haven't stored this key/val set into the masterEffect-Index table then do it
				EFX.Table[ j ] = c
				c_msgclr = Color(100,255,100 )
			else
				c_msgclr = Color(255,100,100)
			end

			MsgC( c_msgclr, tostring( j ), color_white, " = ", c_msgclr, tostring( c ) .. "\n" )

			table.insert( t_col, j )	-- Store all keys into the Collumns  table
			table.insert( t_line, c )	-- All values into the lines table

		end

		if !t_list_efx[ k ] then
			t_list_efx[ k ] = i
			if i.Folder then
				EFX.Cache[ k ] = i
				ZDEV.SEFX.Register( i )
			end
		end -- If we haven't stored this effect, do it

	end

	menu.m_iLastCache = CurTime()
	menu.t_list_efx = t_list_efx

	for h, x in SortedPairs(t_allowedColumns, true) do
		menu.lv:AddColumn( h )
	end

	menu.lv.lines = t_line

	return t_list_efx

end

--[[
	FUNC-CL Load MetaTable Functions into Panel
]]
local function LoadMetaFuncs( pnl )

	local t_meta = ZDEV.UTIL.DumpEntityMeta( EffectData() )

	for k, v in SortedPairs( t_meta, false ) do

		local btn = ZDEV.VGUI.CreateButton( menu.pl, 64, 28, string.upper(k), "command", Color(255,200,100), function( self )
			print( k, v )
		end)
		pnl:SetSize( pnl:GetWide()/5, pnl:GetTall()/5 )
		pnl:Add( btn )

	end

end

-- ZDEV_UID: ZDEV_FUNC_CDFA21EE | Path: ZDEV.VGUI.EffectsMenu
function ZDEV.VGUI.EffectsMenu( ply, cmd, arg )

	EFX = EFX or {}

	cli = LocalPlayer()
	if !cli or !IsValid(cli) or cli ~= LocalPlayer() then return end
	e_lastSpawn = cli:GetNWEntity( "LastEfxSpawn" )

	local menu = {}
	local menu_w, menu_h = SW * 0.66, SH * 0.66
	menu = ZDEV.VGUI.CreateFrame( menu_w, menu_h, "ZDEV Effects Menu")
	menu.t_list_efx = {}
	menu._SelectEfx = function( name )
		EFX.SelectedEfx = efxname
		tbl = ZDEV.SEFX.GetByName( name )
		PopulateRows( menu.pr, tbl )
	end

	menu.CreateNew = function( class )

	end

	local wide, tall = menu_w, menu_h

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    DMENU BAR
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.mb = vgui.Create( "DMenuBar", menu )
	menu.mb:DockMargin(2,2,2,0)

	menu.mb.m1 = menu.mb:AddMenu( "File" )
		menu.mb.m1:AddOption( "New Scripted Effect", function() end):SetIcon( "icon16/script_code_red.png")
		menu.mb.m1:AddOption( "New Scripted Emitter", function() end):SetIcon( "icon16/script_code.png" )
		menu.mb.m1:AddOption( "New Sprite", function() end):SetIcon( "icon16/wand.png")
		menu.mb.m1:AddOption( "New Client Light", function() end):SetIcon( "icon16/lightbulb.png" )
		menu.mb.m1:AddOption( "Open", function() ZDEV.VGUI.FileManager( "data", "zdev", "weapons" )	end ):SetIcon( "icon16/folder.png")
		menu.mb.m1:AddOption( "Save", function() Derma_StringRequest( "Save Filename","Directory: 'zdev/weapons/'","weapon_filename.txt", function( s_txt )ZDEV.WEAP.SaveFile( s_txt, t_WeaponData )	end,function( s_txt )	zdev.log( "D", " Cancelled File-save Dialogue")	end,"Save","Cancel")	end ):SetIcon( "icon16/page_save.png")
		menu.mb.m1:AddOption( "Update", function()	weapons.Register( t_WeaponData, s_ClassName ) end ):SetIcon( "icon16/page_go.png")
		menu.mb.m1:AddOption( "Close", function() end ):SetIcon( "icon16/cross.png")

	menu.mb.m2 = menu.mb:AddMenu( "Edit" )
		menu.mb.m2:AddOption( "Copy", function() end ):SetIcon( "icon16/page_copy.png")
		menu.mb.m2:AddOption( "Paste", function() end ):SetIcon( "icon16/paste_plain.png")
		menu.mb.m2:AddOption( "Delete", function() end ):SetIcon( "icon16/delete.png")
		menu.mb.m2:AddOption( "Lock", function() end ):SetIcon( "icon16/lock.png")
	menu.mb.m3 = menu.mb:AddMenu( "Insert" )
		menu.mb.m3:AddOption( "New", function() end ):SetIcon( "icon16/page_copy.png")
	menu.mb.m4 = menu.mb:AddMenu( "View" )
	menu.mb.m9 = menu.mb:AddMenu( "Options" )
		menu.mb.m9:AddOption( "Settings", function() end ):SetIcon( "icon16/cog.png")
--================================================

	menu.spL = vgui.Create("DScrollPanel", menu )
	menu.spR = vgui.Create("DScrollPanel", menu )
	menu.spC = vgui.Create("DScrollPanel", menu )
	menu.nt = ZDEV.VGUI.CreateNodeTree( menu.spL, 2, 26, wide, tall, {} )
	menu.spL:AddItem( menu.nt )
	menu.pr = vgui.Create( "DProperties", menu.spR )
	menu.spR:AddItem( menu.pr )
	menu.lv = vgui.Create( "DListView", menu.spC )
	menu.spC:AddItem( menu.lv )
	menu.pl = vgui.Create( "DIconLayout", menu.spC )
	menu.spC:AddItem( menu.pl )

	-- CAche effects once we've added the ListViewPanel to the menu
	menu.t_list_efx = CacheEffects( menu )


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
	menu.spC:SetSize( wide *0.66, tall*0.8)
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

	local n = menu.nt:AddNode( "Effects" )
	n:MakeFolder( "effects", "LUA", true )

	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
		  LISTVIEW
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

	menu.lv:Dock(TOP)
	menu.lv:SetTall( menu_h * 0.33)
	--menu.lv:SetSize( wide, tall*0.5 - 30 )
	menu.lv:SetMultiSelect( false )
	for k, v in pairs( EFX.Cache ) do
		if v.Folder and isstring( v.Folder ) then
			v.File = string.Replace( v.Folder, "effects/", "" )
			menu.lv:AddLine( v.File, v.ID, v.Folder, v.Name )
		end
	end
	menu.lv.OnRowSelected = function( lst, index, pnl )
		print(lst, index, pnl )
		menu._SelectEfx( pnl:GetColumnText(1) )
		--ZDEV.DBUG.GetNPCInfo( Entity(pnl:GetColumnText(1) ) )
	end

	menu.pl:MoveBelow( menu.lv )
	menu.pl:Dock(FILL)
	menu.pl:SetTall( menu_h * 0.33 )
	menu.pl:SetSpaceY( 5 )
	menu.pl:SetSpaceX( 5 )
	menu.pl.Paint = function( self, w, h )
		draw.RoundedBox( 6, 0, 0, w, h, Color(75,30,75,200) )
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 2, Color(200,100,200,200)  )
	end
	if !menu.pl.m_bLoadedMetaFuncs then
		LoadMetaFuncs( menu.pl )
		menu.pl.m_bLoadedMetaFuncs = true
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
	menu.pr.rows = {}


	--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    BUTTON-BAR BOTTOM
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.dPL = vgui.Create( "DPanelList", menu )
	menu.dPL:Dock( BOTTOM )
	menu.dPL.bt0 = ZDEV.VGUI.CreateButton( menu.dPL, 64, 28, "SPAWN", "sadmachine", Color(100,255,100), function( self )
		RunConsoleCommand("zdev_ent_create", DEV.SelectedClass )
		timer.Simple( 0.1, function() local ent = cli:GetNWEntity( "LastDevSpawn" )	t_list_ents[ #t_list_ents + 1 ] = ent:EntIndex() end )
	end)
	menu.dPL.bt0:Dock(LEFT)
	-- (CONSOLE button removed Phase 6: dead command — see zd_cl_menu_dev.lua note.)
	menu.dPL.bt2 = ZDEV.VGUI.CreateButton( menu.dPL, 64, 28, "GO-TO",  "sadmachine", Color(255,150,0),function( self )	ZDEV.VGUI.FileManager( "lua" )	end )
	menu.dPL.bt2:Dock(LEFT)
	menu.dPL.btx = ZDEV.VGUI.CreateButton( menu.dPL, 64, 28, "CLOSE",  "sadmachine", Color(255,100,100),function( self )	menu:Close() end )
	menu.dPL.btx:Dock(RIGHT)

	ZDEV.VGUI.INDEX = ZDEV.VGUI.INDEX or {}
	ZDEV.VGUI.INDEX.MENU = ZDEV.VGUI.INDEX.MENU or {}
	ZDEV.VGUI.INDEX.MENU.EFX = menu

end

ZDEV.CMDS.Register( "zdev_menu_dev_efx", ZDEV.VGUI.EffectsMenu, { aliases = { "zd_menu_dev_efx" } } )
ZDEV.VGUI.AddToMainMenu( "zdev_menu_dev_efx" )

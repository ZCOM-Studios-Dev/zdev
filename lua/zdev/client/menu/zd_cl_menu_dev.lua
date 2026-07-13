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
			local conv = GetConVar("zdev_dev_hud_time"):GetBool()
			local new
			if ( conv == true ) then new = 0 
			elseif ( conv == nil or conv == false ) then new = 1 end
			LocalPlayer():ConCommand( "zdev_dev_hud_time "..new )
		end) 
		menu.mb.m4:AddOption( "Toggle Dev Crosshair", function() 
			local conv = GetConVar("zdev_dev_hud_xhair"):GetBool()
			local new
			if ( conv == true ) then new = 0 
			elseif ( conv == nil or conv == false ) then new = 1 end
			LocalPlayer():ConCommand( "zdev_dev_hud_xhair "..new )
		end) 
		menu.mb.m4:AddOption( "Toggle Dev HUD-Grid", function() 
			local conv = GetConVar("zdev_dev_hud_grid"):GetBool()
			local new
			if ( conv == true ) then new = 0 
			elseif ( conv == nil or conv == false ) then new = 1 end
			LocalPlayer():ConCommand( "zdev_dev_hud_grid "..new )
		end) 
	menu.mb.m3 = menu.mb:AddMenu( "Options" )



		menu.mb.m3:AddOption( "Settings", function() 
		end ):SetIcon( "icon16/cog.png")
	
  --[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    LEFT SIDEBAR - Node Tree
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.spL = vgui.Create("DScrollPanel", menu )
	menu.spL:Dock( LEFT )
	menu.spL:SetSize( wide *0.2, tall*0.5 )
	menu.spL.Paint = function( self, w, h )
		local clr = Color(0,200,255, 100)
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 2, clr )
		draw.RoundedBox(0, 0, 0, w, h, ColorAlpha(clr,30) )
	end

	menu.nt = ZDEV.VGUI.CreateNodeTree( menu.spL, 2, 26, wide, tall, t_nodes_ents )
	menu.spL:AddItem( menu.nt )
	menu.nt:Dock( TOP )
	menu.nt:SetTall( menu_h*0.5)
	menu.nt.OnNodeSelected = function( self, node ) end
	local n = menu.nt:AddNode( "Materials" )
	n:MakeFolder( "materials", "THIRDPARTY", true )

  --[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    RIGHT SIDEBAR - Properties
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.spR = vgui.Create("DScrollPanel", menu )
	menu.spR:Dock( RIGHT )
	menu.spR:SetSize( wide *0.2, tall*0.5)
	menu.spR.Paint = function( self, w, h )
		local clr = Color(255,180,50)
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 2, clr )
		draw.RoundedBox(0, 0, 0, w, h, ColorAlpha(clr,30) )
	end

	menu.pr = vgui.Create( "DProperties", menu.spR )
	menu.spR:AddItem( menu.pr )
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
    CENTER - Tabbed Content (DPropertySheet)
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.tabs = vgui.Create( "DPropertySheet", menu )
	menu.tabs:Dock( FILL )
	menu.tabs:DockMargin( 2, 2, 2, 2 )

	--------------------------------------------------------------
	-- TAB: Items  (populated with dense item button grid)
	--------------------------------------------------------------
	local pnlItems = vgui.Create( "DPanel" )
	pnlItems.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color(25, 28, 35, 240) )
	end

	-- Filter bar at top
	local filterBar = vgui.Create( "DPanel", pnlItems )
	filterBar:Dock( TOP )
	filterBar:SetTall( 22 )
	filterBar:DockMargin( 2, 2, 2, 0 )
	filterBar.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color(40, 45, 55, 255) )
	end

	local filterLabel = vgui.Create( "DLabel", filterBar )
	filterLabel:Dock( LEFT )
	filterLabel:SetWide( 40 )
	filterLabel:SetText( " Filter:" )
	filterLabel:SetFont( "DermaDefault" )
	filterLabel:SetTextColor( Color(180, 200, 255) )

	local filterEntry = vgui.Create( "DTextEntry", filterBar )
	filterEntry:Dock( FILL )
	filterEntry:DockMargin( 2, 2, 2, 2 )
	filterEntry:SetPlaceholderText( "Search items..." )
	filterEntry:SetFont( "DermaDefault" )

	-- Scrollable item grid
	local itemScroll = vgui.Create( "DScrollPanel", pnlItems )
	itemScroll:Dock( FILL )
	itemScroll:DockMargin( 2, 2, 2, 2 )

	-- Category display order and colors
	local CAT_ORDER = {
		{ key = "consumable", label = "CONSUMABLES",  clr = Color(80, 200, 80) },
		{ key = "ammo",       label = "AMMO",          clr = Color(255, 180, 50) },
		{ key = "weapon",     label = "WEAPONS",       clr = Color(255, 80, 80) },
		{ key = "equipment",  label = "EQUIPMENT",     clr = Color(60, 140, 255) },
		{ key = "tool",       label = "TOOLS",          clr = Color(180, 180, 180) },
		{ key = "material",   label = "MATERIALS",      clr = Color(160, 120, 80) },
	}

	-- Rarity colors for item name text
	local RARITY_CLR = {
		common    = Color(180, 180, 180),
		uncommon  = Color(80, 200, 80),
		rare      = Color(60, 120, 255),
		epic      = Color(180, 60, 255),
		legendary = Color(255, 180, 40),
	}

	-- Sort items into category buckets
	local catBuckets = {}
	for _, cat in ipairs( CAT_ORDER ) do
		catBuckets[cat.key] = {}
	end
	if ZDEV.Items then
		for id, def in pairs( ZDEV.Items ) do
			-- Skip sub-namespace helpers (WEAPON_SLOTS table, IsWeaponSlot function, DrawIcon function)
			if type(def) == "table" and def.category then
				local cat = def.category or "tool"
				if not catBuckets[cat] then catBuckets[cat] = {} end
				table.insert( catBuckets[cat], { id = id, def = def } )
			end
		end
	end
	-- Alpha-sort within each category
	for _, bucket in pairs( catBuckets ) do
		table.sort( bucket, function(a, b) return a.def.name < b.def.name end )
	end

	-- Build rows for each category
	local ROW_H   = 20
	local BTN_W   = 44
	local BTN_H   = 18
	local ICON_SZ = 16
	local allItemRows = {}

	local function BuildItemRows( parentPanel )
		-- Clear existing
		for _, row in ipairs( allItemRows ) do
			if IsValid(row) then row:Remove() end
		end
		allItemRows = {}

		local filterText = filterEntry:GetValue():lower()

		for _, cat in ipairs( CAT_ORDER ) do
			local items = catBuckets[cat.key]
			if not items or #items == 0 then continue end

			-- Filter items by search text
			local filtered = {}
			for _, item in ipairs( items ) do
				if filterText == "" or item.def.name:lower():find( filterText, 1, true ) or item.id:lower():find( filterText, 1, true ) then
					table.insert( filtered, item )
				end
			end
			if #filtered == 0 then continue end

			-- Category header
			local header = vgui.Create( "DPanel", parentPanel )
			header:Dock( TOP )
			header:SetTall( 18 )
			header:DockMargin( 0, 2, 0, 0 )
			header.Paint = function( self, w, h )
				draw.RoundedBox( 0, 0, 0, w, h, ColorAlpha(cat.clr, 40) )
				surface.SetDrawColor( cat.clr.r, cat.clr.g, cat.clr.b, 120 )
				surface.DrawRect( 0, h - 1, w, 1 )
				draw.SimpleText( cat.label .. " (" .. #filtered .. ")", "DermaDefaultBold", 4, h * 0.5, cat.clr, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
			end
			table.insert( allItemRows, header )

			-- Item rows
			for _, item in ipairs( filtered ) do
				local row = vgui.Create( "DPanel", parentPanel )
				row:Dock( TOP )
				row:SetTall( ROW_H )
				row:DockMargin( 0, 1, 0, 0 )
				local rarClr = RARITY_CLR[item.def.rarity] or RARITY_CLR.common
				row.Paint = function( self, w, h )
					local bgAlpha = self:IsHovered() and 50 or 20
					draw.RoundedBox( 0, 0, 0, w, h, Color(60, 65, 75, bgAlpha) )
				end

				-- Icon
				local icon = vgui.Create( "DImage", row )
				icon:Dock( LEFT )
				icon:SetWide( ICON_SZ )
				icon:DockMargin( 2, 2, 2, 2 )
				if item.def.icon then
					icon:SetImage( item.def.icon )
				end

				-- Name label
				local nameLabel = vgui.Create( "DLabel", row )
				nameLabel:Dock( LEFT )
				nameLabel:SetWide( 140 )
				nameLabel:DockMargin( 2, 0, 2, 0 )
				nameLabel:SetText( item.def.name )
				nameLabel:SetFont( "DermaDefault" )
				nameLabel:SetTextColor( rarClr )
				nameLabel:SetTooltip( item.id .. "\n" .. (item.def.description or "") .. "\n[" .. (item.def.rarity or "common") .. "] W:" .. (item.def.width or 1) .. " H:" .. (item.def.height or 1) .. " Wt:" .. (item.def.weight or 0) )

				-- Grid size indicator
				local sizeLabel = vgui.Create( "DLabel", row )
				sizeLabel:Dock( LEFT )
				sizeLabel:SetWide( 28 )
				sizeLabel:DockMargin( 0, 0, 2, 0 )
				sizeLabel:SetText( item.def.width .. "x" .. item.def.height )
				sizeLabel:SetFont( "DermaDefault" )
				sizeLabel:SetTextColor( Color(120, 120, 140) )
				sizeLabel:SetContentAlignment( 5 )

				-- Spawn button (spawn item entity at trace pos)
				local btnSpawn = vgui.Create( "DButton", row )
				btnSpawn:Dock( LEFT )
				btnSpawn:SetWide( BTN_W )
				btnSpawn:DockMargin( 1, 1, 0, 1 )
				btnSpawn:SetText( "Spawn" )
				btnSpawn:SetFont( "DermaDefault" )
				btnSpawn:SetTextColor( Color(100, 255, 100) )
				btnSpawn.Paint = function( self, w, h )
					local bg = self:IsHovered() and Color(50, 80, 50, 200) or Color(30, 40, 30, 180)
					draw.RoundedBox( 2, 0, 0, w, h, bg )
				end
				btnSpawn.DoClick = function()
					RunConsoleCommand( "zdev_item_spawn", item.id )
				end

				-- Give button (add to player inventory)
				local btnGive = vgui.Create( "DButton", row )
				btnGive:Dock( LEFT )
				btnGive:SetWide( BTN_W )
				btnGive:DockMargin( 1, 1, 0, 1 )
				btnGive:SetText( "Give" )
				btnGive:SetFont( "DermaDefault" )
				btnGive:SetTextColor( Color(100, 180, 255) )
				btnGive.Paint = function( self, w, h )
					local bg = self:IsHovered() and Color(40, 60, 80, 200) or Color(25, 35, 50, 180)
					draw.RoundedBox( 2, 0, 0, w, h, bg )
				end
				btnGive.DoClick = function()
					RunConsoleCommand( "zdev_item_give", item.id )
				end

				-- Use button (force-use the item on player)
				local btnUse = vgui.Create( "DButton", row )
				btnUse:Dock( LEFT )
				btnUse:SetWide( 32 )
				btnUse:DockMargin( 1, 1, 0, 1 )
				btnUse:SetText( "Use" )
				btnUse:SetFont( "DermaDefault" )
				btnUse:SetTextColor( Color(255, 220, 100) )
				btnUse.Paint = function( self, w, h )
					local bg = self:IsHovered() and Color(70, 60, 30, 200) or Color(40, 35, 20, 180)
					draw.RoundedBox( 2, 0, 0, w, h, bg )
				end
				btnUse.DoClick = function()
					RunConsoleCommand( "zdev_item_use", item.id )
				end

				table.insert( allItemRows, row )
			end
		end
	end

	-- Initial build
	BuildItemRows( itemScroll )

	-- Rebuild on filter change
	filterEntry.OnValueChange = function( self, val )
		BuildItemRows( itemScroll )
	end

	if ZDEV.Settings and ZDEV.Settings.InventoryEnabled then
		menu.tabs:AddSheet( "Items", pnlItems, "icon16/box.png" )
	end

	--------------------------------------------------------------
	-- TAB: Equipment  (empty placeholder)
	--------------------------------------------------------------
	local pnlEquip = vgui.Create( "DPanel" )
	pnlEquip.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color(25, 28, 35, 240) )
		draw.SimpleText( "Equipment — Coming Soon", "DermaDefaultBold", w * 0.5, h * 0.5, Color(120, 120, 140), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end
	if ZDEV.Settings and ZDEV.Settings.InventoryEnabled then
		menu.tabs:AddSheet( "Equipment", pnlEquip, "icon16/shield.png" )
	end

	--------------------------------------------------------------
	-- TAB: Weapons  (empty placeholder)
	--------------------------------------------------------------
	local pnlWeapons = vgui.Create( "DPanel" )
	pnlWeapons.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color(25, 28, 35, 240) )
		draw.SimpleText( "Weapons — Coming Soon", "DermaDefaultBold", w * 0.5, h * 0.5, Color(120, 120, 140), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end
	menu.tabs:AddSheet( "Weapons", pnlWeapons, "icon16/gun.png" )

	--------------------------------------------------------------
	-- TAB: Effects  (empty placeholder)
	--------------------------------------------------------------
	local pnlEffects = vgui.Create( "DPanel" )
	pnlEffects.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color(25, 28, 35, 240) )
		draw.SimpleText( "Effects — Coming Soon", "DermaDefaultBold", w * 0.5, h * 0.5, Color(120, 120, 140), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end
	menu.tabs:AddSheet( "Effects", pnlEffects, "icon16/wand.png" )

	--------------------------------------------------------------
	-- TAB: Entities  (migrated existing entity listview)
	--------------------------------------------------------------
	local pnlEnts = vgui.Create( "DPanel" )
	pnlEnts.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color(25, 28, 35, 240) )
	end

	menu.lv = vgui.Create( "DListView", pnlEnts )
	menu.lv:Dock( FILL )
	menu.lv:DockMargin( 2, 2, 2, 2 )
	menu.lv:SetMultiSelect( false )
	menu.lv:AddColumn( "Index" )
	menu.lv:AddColumn( "Classname" )
	menu.lv:AddColumn( "Position" )
	for k, i in pairs( ents.GetAll() ) do
		menu.lv:AddLine( i:EntIndex(), i:GetClass(), tostring(i:GetPos()) )
	end
	menu.lv.OnRowSelected = function( lst, index, pnl )
		menu._DevSelectEnt( pnl:GetColumnText(1) )
	end

	menu.tabs:AddSheet( "Entities", pnlEnts, "icon16/bricks.png" )

	--------------------------------------------------------------
	-- TAB: NPCs  (empty placeholder)
	--------------------------------------------------------------
	local pnlNPCs = vgui.Create( "DPanel" )
	pnlNPCs.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color(25, 28, 35, 240) )
		draw.SimpleText( "NPCs — Coming Soon", "DermaDefaultBold", w * 0.5, h * 0.5, Color(120, 120, 140), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end
	menu.tabs:AddSheet( "NPCs", pnlNPCs, "icon16/user.png" )

	--------------------------------------------------------------
	-- TAB: Misc  (empty placeholder)
	--------------------------------------------------------------
	local pnlMisc = vgui.Create( "DPanel" )
	pnlMisc.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color(25, 28, 35, 240) )
		draw.SimpleText( "Misc — Coming Soon", "DermaDefaultBold", w * 0.5, h * 0.5, Color(120, 120, 140), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end
	menu.tabs:AddSheet( "Misc", pnlMisc, "icon16/cog.png" )



  --[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    BUTTON-BAR BOTTOM
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
	menu.dPL = vgui.Create( "DPanelList", menu )
	menu.dPL:Dock( BOTTOM )

	menu.dPL.bt0 = ZDEV.VGUI.CreateButton( menu.dPL, 64, 28, "SPAWN", "sadmachine", Color(100,255,100), function( self )	RunConsoleCommand("zdev_ent_create", DEV.SelectedClass )	timer.Simple( 0.1, function()
		local ent = cli:GetNWEntity( "LastDevSpawn" )
		print(ent)
		t_list_ents[ #t_list_ents + 1 ] = ent:EntIndex()
	end ) end )
	menu.dPL.bt0:Dock(LEFT)

	-- (CONSOLE button removed Phase 6: it ran "zd_dev_console", a command whose
	-- +/- registration has been commented out for some time — dead UI.)

	menu.dPL.bt2 = ZDEV.VGUI.CreateButton( menu.dPL, 64, 28, "GO-TO",  "sadmachine", Color(255,150,0),function( self )	ZDEV.VGUI.FileManager( "lua" )	end )
	menu.dPL.bt2:Dock(LEFT)

	menu.dPL.btx = ZDEV.VGUI.CreateButton( menu.dPL, 64, 28, "CLOSE",  "sadmachine", Color(255,100,100),function( self )	menu:Close() end )
	menu.dPL.btx:Dock(RIGHT)

end
ZDEV.CMDS.Register( "zdev_menu_dev", ZDEV.VGUI.DevMenu, { aliases = { "zd_menu_dev" } } )
ZDEV.VGUI.AddToMainMenu( "zdev_menu_dev" )

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
	conv.con_x = GetConVar( "zdev_dev_console_x" ):GetInt() or SW * 0.1
	conv.con_y = GetConVar( "zdev_dev_console_y"):GetInt() or SH * 0.33
	conv.con_w, conv.con_h = GetConVar( "zdev_dev_console_w"):GetInt() or SW * 0.33, GetConVar( "zdev_dev_console_h" ):GetInt() or SH * 0.2

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

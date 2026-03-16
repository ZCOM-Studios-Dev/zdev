local _f = 'zdev/client/vgui/zd_cl_menu_admin.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
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
local TEAM_SPY = TEAM_SPY
local TEAM_MERC = TEAM_MERC

ZDEV = ZDEV or {}
-- print('')

local cli = LocalPlayer()
local SW, SH = ScrW(), ScrH()

local t_TypeConvert = {
  ["number"] = "Int",
  ["boolean"] = "Boolean",
  ["float"] = "Float",
  ["string"] = "String",
  ["IMaterial"]= "String",
  ["Angle"] = "String",
  ["Vector"] = "String"
}
local t_PlyrTable = {}

local ADMIN = {}
ADMIN.SelectedPlayers = {}
ADMIN.BOTS = {}
ADMIN.CMDS = {}

--[[=============================================================
  FUNC-CL ZDEV Test VGUI Mwnu
==================================================================]]
local t_PlyrTable = {}
-- ZDEV_UID: ZDEV_FUNC_FCC5C1B0 | Path: ZDEV.VGUI.AdminMenu
function ZDEV.VGUI.AdminMenu( ply, cmd, arg )

  if !cli or !IsValid(cli) or cli ~= LocalPlayer() then
    cli = LocalPlayer()
  end

  local menu = {}
  local menu_w, menu_h = SW * 0.66, SH * 0.66
  menu = ZDEV.VGUI.CreateFrame( menu_w, menu_h, "ZDEV Admin Menu")

	menu.lv = vgui.Create( "DListView", menu )
  menu.sp = vgui.Create( "DScrollPanel", menu )
  menu.spL = vgui.Create( "DScrollPanel", menu )
  menu.spR = vgui.Create( "DScrollPanel", menu )
  menu.pr = vgui.Create( "DProperties", menu.spL )
  menu.dPL = vgui.Create( "DPanelList", menu )


	menu.lv:Dock( TOP )
	menu.lv:SetSize( menu_w * 0.2, menu_h * 0.2 )
	menu.lv:SetMultiSelect( false )
  menu.lv.rows = {}

  menu.lv.co1 = menu.lv:AddColumn( "UserID" )
  menu.lv.co1:SetFixedWidth( 32 )
	menu.lv.co2 = menu.lv:AddColumn( "Name" )
  menu.lv.co2:SetFixedWidth( 128 )
	menu.lv.co3 = menu.lv:AddColumn( "UniqueID" )
  menu.lv.co3:SetFixedWidth( 128 )
  menu.lv.co4 = menu.lv:AddColumn( "SteamID" )
  menu.lv.co4:SetFixedWidth( 128 )
  menu.lv.co5 = menu.lv:AddColumn( "UserGroup" )
  menu.lv.co5:SetFixedWidth( 64 )
  menu.lv.co6 = menu.lv:AddColumn( "Rank" )
  menu.lv.co6:SetFixedWidth( 64 )
  menu.lv.co6 = menu.lv:AddColumn( "Gold" )
  menu.lv.co6:SetFixedWidth( 64 )

	menu.lv.OnRowSelected = function( lst, index, pnl )
    local ply = Player( pnl:GetColumnText( 1 ) )
		DebugPrintTable( ply:GetTable() )
    t_PlyrTable = ply:GetTable()
    menu.spL:Rebuild( )
    menu.pr:InvalidateLayout( true )    
	end
--[[
  menu.lv.Paint = function( self, w, h )

  end

  menu.lv.PaintOver = function( self, w, h )
    local t_selected = self:GetSelected()
    for k,v in pairs( t_selected ) do
      local x, y = v:GetPos()
      local w2, h2 = v:GetSize()
      draw.RoundedBox( 2, x, y+h2, w2, h2, Color(255,200,0,50) )
      ZDEV.DRAW.OutlinedBox( x, y+h2, w2, h2, 2, Color(255,200,0,255) )
    end
  end
  ]]

  local i = 0
	for k, n in pairs( player.GetAll() ) do
		if IsValid( n ) then
      i = i + 1
      local rank = n:GetNWInt("rank")
      local rank_name = ZDEV.RANK.Name( rank )
      local gold = n:GetNWInt("gold")
			menu.lv.rows[ i ] = menu.lv:AddLine( n:UserID(), n:Nick(), n:UniqueID(),n:SteamID(),n:GetUserGroup(), rank_name, gold )
    --[[


      menu.lv.rows[ i ].Paint = function( self, w, h )
        
      end
      menu.lv.rows[ i ].PaintOver = function( self, w, h )
        if self.m_bSelected then
          ZDEV.DRAW.OutlinedBox( 2, 0, 0, w, h, Color(255,200,0,255) )
        end
      end
]]
		end
	end

  menu.spL:Dock( LEFT )
  menu.spL:SetSize( menu_w * 0.2, menu_h * 0.2 )
  menu.spL:DockMargin( 2, 2, 2, 24 )
  menu.spL.Paint = function( self, w, h )
    ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 1, color_white )
  end

  menu.pr:SetSize( menu_w, menu_h )
  menu.pr:Dock( FILL )
  menu.pr:DockMargin( 2, 2, 2, 2 )
  menu.pr.rows = {}

  for k, v in pairs( t_PlyrTable ) do
      menu.pr.rows[ k ] = menu.pr:CreateRow( "Core", k )
      menu.pr.rows[ k ]:Setup( tostring(s_DataType) )
      menu.pr.rows[ k ]:SetValue( v )
      menu.pr.rows[ k ].DataChanged = function( self, data )
      end
  end
  menu.spL:AddItem( menu.pr )

  menu.spR:Dock( RIGHT )
  menu.spR:SetSize( menu_w * 0.15, menu_h * 0.2 )
  menu.spR:DockMargin( 2, 2, 2, 24 )
  menu.spR.clr_br = Color(0,200,255)
  menu.spR.Paint = function( self, w, h )

    draw.RoundedBox( 2, 0,0, w, h, ColorAlpha( self.clr_br, 50) )
    ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 1, self.clr_br)
  end

  menu.spR.btn1 = ZDEV.VGUI.CreateButton( menu.spR, 128, 32, "FreezeBones", "bios", Color(0,200,255), nil )
  menu.spR.btn1:Dock(TOP)
  menu.spR:AddItem( menu.spR.btn1 )




  menu.dPL:Dock( BOTTOM )

  menu.dPL.bt0 = ZDEV.VGUI.CreateButton( menu.dPL,  w, h, "Kill Silent", fnt, Color(100,200,255,255), nil )
  menu.dPL.bt0:Dock( LEFT )
  menu.dPL.bt0.DoClick = function( self )
    if cli:IsSuperAdmin() or cli:IsAdmin() then
      cli:ConCommand( "zd_kill " .. "" )
    end
  end

  menu.dPL.bt1 = vgui.Create( "DButton", menu.dPL )
  menu.dPL.bt1:Dock( RIGHT )
  menu.dPL.bt1:SetText( "✓" )
  menu.dPL.bt1:SetFont( "command" )
  menu.dPL.bt1:SetTextColor( Color(100,255,100,255) )
  menu.dPL.bt1:SetColor( Color(0,200,0,255) )
  menu.dPL.bt1.DoClick = function( self )
    --weapons.Register( t_WeaponData, s_ClassName )
    ZDEV.VGUI.FileManager( "lua" )
  end

  menu.dPL.bt2 = vgui.Create( "DButton", menu.dPL )
  menu.dPL.bt2:Dock( RIGHT )
  menu.dPL.bt2:SetFont( "command" )
  menu.dPL.bt2:SetText( "✕" )
  menu.dPL.bt2:SetTextColor( Color(255,0,0,255) )
  menu.dPL.bt2:SetColor( Color(200,0,0,255) )
  menu.dPL.bt2.DoClick = function( self )
    menu:Close()
    --weapons.Register( t_WeaponData, s_ClassName )
    --ZDEV.VGUI.FileManager( "lua" )
  end

end
concommand.Add( "zd_menu_admin", ZDEV.VGUI.AdminMenu )
ZDEV.VGUI.AddToMainMenu( "zd_menu_admin" )

ZDEV.FILE.SetLoaded( _f )


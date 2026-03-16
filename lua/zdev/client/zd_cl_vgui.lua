local _f = 'zdev/client/zd_cl_vgui.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end


if not ZDEV.VGUI then ZDEV.VGUI = {} end
ZDEV.VGUI.MENU = {}

local SW, SH = ScrW(), ScrH()
local _VGUI = {}
local MAT = {
  BTN = {
    base = Material( "vgui/btn/btn02_base01_blk.png" ),
    hover = Material( "vgui/btn/btn02_ovr01_org.png"),
  },
  SLOT = {
    base = Material("ui/ui_slot.png"),
    hover = Material("ui/ui_slot_hover.png"),
    active = Material("ui/ui_slot_active.png"),
    selected = Material("ui/ui_slot_selected.png"),
    disabled = Material("ui/ui_slot_disabled.png")
  },
  EQUIP = {
    bg = Material("ui/ui_equipment_bg.png"),
    bg_outline = Material("ui/ui_equipment_bg_outline.png")
  }
}
-- ZDEV_UID: ZDEV_FUNC_1C9A4181 | Path: ZDEV.VGUI.CreateFrame
function ZDEV.VGUI.CreateFrame( w, h, title )

	local f = vgui.Create( "DFrame" )
	f:SetSize( w, h )
	f:Center()
	f:MakePopup( true )
	f:ShowCloseButton( true )
	f:SetTitle( title )
	f.Paint = function( self, w, h )
		draw.RoundedBox( 6, 0, 0, w, h, Color(0,0,0,150) )
		ZDEV.DRAW.TexturedRect( 0, 0, w, h, Material("vgui/bg/gradient_1.png"), Color(255,255,255,255) )
		ZDEV.DRAW.TexturedRect( 0, 0, w, 24, Material("vgui/panel/pnl_glow_1.png"), Color( 255,225,255,255) )
	end

	_VGUI.DFrame = _VGUI.DFrame or {}
	table.insert( _VGUI.DFrame, f )

	return f

end


--[[
    3D2D VGUI Frame Rendering using ui3d2d
    Renders a VGUI-like frame in world space in front of the player's camera
    Usage: ZDEV.VGUI.Render3DFrame()
]] 
--include("includes/cl_ui3d2d.lua")

-- ZDEV_UID: ZDEV_FUNC_3D2D_FRAME | Path: ZDEV.VGUI.Render3DFrame
function ZDEV.VGUI.Render3DFrame(opts)
    opts = opts or {}
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local eyePos = ply:EyePos()
    local eyeAng = ply:EyeAngles()
    local dist = opts.dist or 64
    local scale = opts.scale or 0.1
    local frameW = opts.w or 320
    local frameH = opts.h or 180
    local pos = eyePos + eyeAng:Forward() * dist + eyeAng:Right() * (opts.offsetX or 0) + eyeAng:Up() * (opts.offsetY or 0)
    local ang = Angle(0, eyeAng.y - 90, 90)
    if ui3d2d.startDraw(pos, ang, scale) then
        -- Draw frame background
        draw.RoundedBox(8, 0, 0, frameW, frameH, Color(40, 60, 100, 220))
        -- Draw frame title
        draw.SimpleText(opts.title or "ZDEV 3D2D Frame", "DermaLarge", 16, 16, Color(255,255,255), TEXT_ALIGN_LEFT)
        -- Example: Draw a button
        local btnX, btnY, btnW, btnH = 32, 64, 120, 32
        local btnColor = ui3d2d.isHovering(btnX, btnY, btnW, btnH) and Color(100,255,100) or Color(80,120,80)
        draw.RoundedBox(6, btnX, btnY, btnW, btnH, btnColor)
        draw.SimpleText("Click Me", "DermaDefaultBold", btnX + btnW/2, btnY + btnH/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        if ui3d2d.isHovering(btnX, btnY, btnW, btnH) and ui3d2d.isPressed() then
            chat.AddText(Color(0,255,0), "[ZDEV] 3D2D Button Pressed!")
        end
        -- You can add more VGUI-like controls here
    end
    ui3d2d.endDraw()
end

local mat_hov = Material("vgui/btn/00_on.png")
local mat_bg = Material("vgui/btn/01.png")
local mat_clk0 = Material("vgui/btn/btn02_ovr01_org.png")
local mat_clk1 = Material("vgui/btn/btn02_ovr02_cyn.png")
-- ZDEV_UID: ZDEV_FUNC_D6CD0327 | Path: ZDEV.VGUI.CreateButton
function ZDEV.VGUI.CreateButton( parent,  w, h, text, fnt, clr, click )
  local text_w, text_h
  fnt = fnt or "bios"
  clr = clr or color_white
	local btn = vgui.Create( "DButton", parent )
	btn:SetText( text )
	btn:SetSize( w, h )
  btn:SetTextColor( clr )
  btn.mat = mat_bg
	if click and type( click ) == "function" then
		btn.DoClick = click
	end
	btn.Paint = function( self, w, h )
    text_w, text_h = ZDEV.UTIL.GetTextSize(  text , fnt )
		if self:IsHovered() then
      self.mat = mat_hov
    else
      self.mat = mat_bg
    end
		ZDEV.DRAW.MaterialBox( 0, 0, w, h, self.mat, Color(255,255,255,255) )
     draw.DrawText(text, fnt, w/2, h/2 - text_h/2, clr, TEXT_ALIGN_CENTER )
    return true
	end
	btn.PaintOver = function( self, w, h )

      return true
    
  end
	return btn
end

-- ZDEV_UID: ZDEV_FUNC_2C850790 | Path: ZDEV.VGUI.CreateTextEntry
function ZDEV.VGUI.CreateTextEntry( parent, w, h, text, font, multi, dock, dm_L, dm_T, dm_R, dm_D )

  w, h, text, font, multi, dock, dm_L, dm_T, dm_R, dm_D = w or 64, h or 16, text or "...", font or "bios", multi or false, dock or TOP, dm_L or 1, dm_T or 1, dm_R or 1, dm_D or 1 

  local te = vgui.Create( "DTextEntry", parent )
  te:SetSize( w, h )
  te:Dock( dock )
  te:DockMargin( dm_L, dm_T, dm_R, dm_D  )
  te:SetValue( text )
  te:SetFont( font )
  te:SetMultiline( multi )
  te:SetTextColor( Color(0,0,0,255) )
  return te

end

local i_callstack = 0
local s_tabpre = "\t"
local function ProcessNodeData( node, data )

  i_callstack = i_callstack or 0
  s_tagpre = ""
  --MsgC( Color(100,255,100), tostring( i_callstack ), color_white, " | Node-Data: " .. tostring(node) .. "\n" )

  for k, v in pairs( data ) do
  
    --MsgC( Color(200,200,200), s_tagpre .. tostring(k) .. " = " .. tostring(v) .. "\n" )

    if type( v ) == "table" then
      local n = node:AddNode( k )
     -- MsgC( color_white, s_tagpre .. ">" .. tostring(k) .. " = " .. tostring( v ) .. "\n" )
      i_callstack = i_callstack + 1
      ProcessNodeData( n, v )
    else
      local n2 = node:AddNode( v )
      n2._name = v 
     -- MsgC( Color(255,200,0), s_tagpre .. " " .. tostring(k) .. " = " ..tostring(v) .. "\n" )
    end
  end

  --s_tagpre = s_tagpre .. " \t"

end

-- ZDEV_UID: ZDEV_FUNC_6DD2DDB8 | Path: ZDEV.VGUI.CreateNodeTree
function ZDEV.VGUI.CreateNodeTree( parent, x, y, w, h, nodedata )

  local dt  = vgui.Create( "DTree", parent )
  dt:SetSize( w, h )
  dt:SetPos( x, y )
  dt.t_nodes = {}
  if nodedata then
    ProcessNodeData( dt, nodedata )
  end

  return dt

end

ZDEV.VGUI.MenuCommands = {}

-- ZDEV_UID: ZDEV_FUNC_624000A0 | Path: ZDEV.VGUI.AddToMainMenu
function ZDEV.VGUI.AddToMainMenu( cmd )
  if !table.HasValue( ZDEV.VGUI.MenuCommands, cmd ) then
    table.insert( ZDEV.VGUI.MenuCommands, cmd )
    --zdev.log( "I","Added command to Main Menu: '" .. cmd .. "'" )
  end
end

-- ZDEV_UID: ZDEV_FUNC_FADA9C18 | Path: ZDEV.VGUI.MainMenu
function ZDEV.VGUI.MainMenu()

  local menu = ZDEV.VGUI.CreateFrame( SW * 0.33, SH * 0.66, "ZDEV Menu")
  menu:SetKeyboardInputEnabled( true )
  menu:SetMouseInputEnabled( true )

  menu.pl = vgui.Create( "DPanelList", menu )
  menu.pl:Dock( FILL )
  menu.pl:SetPos( 2, 24 )
  menu.pl:SetWide( SW * 0.25 )
 -- menu.pl:StretchToParent( 2,32,2,2 )
  menu.pl:SetPaintBackground( true )
  menu.pl:SetBackgroundColor( Color( 50,50,50 ))
  menu.pl.Paint = function( self, w, h )
    local clr_bg = self:GetBackgroundColor()
    draw.RoundedBox( 0, 0, 0, w, h,  clr_bg)
    ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 2, Color( 0,200,255))
  end

  for k, cmd in pairs( ZDEV.VGUI.MenuCommands ) do

    local b1 = vgui.Create( "DButton", menu.pl )
    b1:SetText( string.upper( string.gsub(cmd, "zdev_vgui_","" ) ) )				-- Set the text on the button
    b1:Dock( TOP )
    b1:SetTall( 32 )					-- Set the size
    b1.DoClick = function()				-- A custom function run when clicked ( note the . instead of : )
      RunConsoleCommand( cmd, "" )			-- Run the console command "say hi" when you click it ( command, args )
      menu:Close()
    end
    menu.pl:AddItem( b1 )

  end

end
concommand.Add( "zd_menu_main", ZDEV.VGUI.MainMenu )


local s_dir
-- ZDEV_UID: ZDEV_FUNC_867B4D3E | Path: ZDEV.VGUI.ModelSelect
function ZDEV.VGUI.ModelSelect()

  --ZDEV.VGUI.ModelSelect.LastDir = ""

  local frame = ZDEV.VGUI.CreateFrame( SW * 0.33, SH * 0.33, "File Management")

  local browser = vgui.Create( "DFileBrowser", frame )
  browser:Dock( FILL )

  browser:SetPath( "GAME" ) -- The access path i.e. GAME, LUA, DATA etc.
  browser:SetBaseFolder( "models/weapons" ) -- The root folder
  browser:SetName( "World Models" ) -- Name to display in tree
  browser:SetSearch( "vm" ) -- Search folders starting with "props_"
  browser:SetFileTypes( "*.mdl" ) -- File type filter
  browser:SetOpen( true ) -- Opens the tree ( same as double clicking )
  browser:SetCurrentFolder( "weapons" ) -- Set the folder to use
  browser:SetModels( true ) -- Use SpawnIcons instead of a list

  function browser:OnSelect( path, pnl ) -- Called when a file is clicked
    RunConsoleCommand( "gm_spawn", path ) -- Spawn the model we clicked
    frame:Close()
  end

end

-- ZDEV_UID: ZDEV_FUNC_7E952CF3 | Path: ZDEV.VGUI.PlayerInfo
function ZDEV.VGUI.PlayerInfo()

  if not GetConVar("zdev_hud_draw_info"):GetBool() then return end

  local av = vgui.Create("AvatarImage", GetHUDPanel() )
  av:SetSize( 64, 64 )
  av:SetPos( SW * 0.5 - 32, 8 )
  av:SetPlayer( LocalPlayer(), 64 )
  av:SetMouseInputEnabled( true )

end

-- ZDEV_UID: ZDEV_FUNC_54BEF803 | Path: ZDEV.VGUI.MaterialBrowser
function ZDEV.VGUI.MaterialBrowser( )

  

end
concommand.Add( "zd_vgui_materialbrowser", function( ply, cmd, arg ) ZDEV.VGUI.MaterialBrowser( ) end )

-- ZDEV_UID: ZDEV_FUNC_1BEE50A7 | Path: ZDEV.VGUI.FileManager
function ZDEV.VGUI.FileManager( cmd, ply, arg )

  local root, dir, subdir 
  root = arg[1]
  dir = arg[2]
  subdir = arg[3]

  local s_SelectedDir = ""

  MsgC( Color(255,255,0), "▶\t", color_white, " VGUI Panel - File/Directory Browser\n" )

  local menu = ZDEV.VGUI.CreateFrame( SW * 0.33, SH * 0.33, "File Management")

  menu.dFB = vgui.Create( "DFileBrowser", menu )
    menu.dPL = vgui.Create( "DPanelList", menu )
      menu.dPL.dTE = vgui.Create( "DTextEntry", menu.dPL )
     -- menu.dPL.bt0 = vgui.Create( "DButton", menu.dPL )
     -- menu.dPL.bt1 = vgui.Create( "DButton", menu.dPL )
      menu.dPL.bt0 = ZDEV.VGUI.CreateButton( menu.dPL, 90, 45, "✓ SAVE", "bios", Color(100,255,100) )
      menu.dPL.bt1 = ZDEV.VGUI.CreateButton( menu.dPL, 90, 45,  "✕ CANCEL", "bios", Color(255,100,100) )

  menu.dFB:Dock( FILL )

  menu.dFB:SetPath( string.upper(root) ) -- The access path i.e. GAME, LUA, DATA etc.
  menu.dFB:SetOpen( true ) -- Open the tree to show sub-folders
  dir = dir or "zdev"
  subdir = subdir or "info"
  menu.dFB:SetBaseFolder( dir ) -- The root folder
  menu.dFB:SetCurrentFolder( subdir ) -- Show files from persist

  function menu.dFB:OnSelect( path, pnl ) -- Called when a file is clicked
    s_SelectedDir = path
    menu.dPL.dTE:SetText( s_SelectedDir )
    MsgC( Color(0,255,0), "• File", color_white, " - ", Color(255,255,0), tostring(path) .. "\n" )

  end

  menu.dPL:Dock( BOTTOM )
  menu.dPL:SetTall(42)
  menu.dPL.Paint = function( self, w, h )
    draw.RoundedBox( 0, 0, 0, w, h, Color(0,0,0,150) )
  end

  menu.dPL.dTE:Dock( TOP )
  menu.dPL.dTE:SetTall( 16 )


  menu.dPL.bt0:Dock( LEFT )
  menu.dPL.bt0:SetText( "✓ SAVE" )
  menu.dPL.bt0:SetFont( "bios" )
  menu.dPL.bt0:SetTextColor( Color(100,255,100,255) )
  menu.dPL.bt0:SetColor( Color(0,200,0,255) )
  menu.dPL.bt0.DoClick = function( self )

    MsgC( Color(0,255,0), "◓ Button ", color_white, " - Clicked Save \n" )

    
    --weapons.Register( t_WeaponData, s_ClassName )
    --ZDEV.VGUI.FileManager( "lua" )
  end

  menu.dPL.bt1:Dock( LEFT )
  menu.dPL.bt1:SetFont( "bios" )
  menu.dPL.bt1:SetText( "X Cancel")
  menu.dPL.bt1:SetTextColor( Color(255,0,0,255) )
  menu.dPL.bt1:SetColor( Color(200,0,0,255) )
  menu.dPL.bt1.DoClick = function( self )

    MsgC( Color(0,255,0), "◓ Button ", color_white, " - Clicked Cancel \n" )

    --weapons.Register( t_WeaponData, s_ClassName )
    --ZDEV.VGUI.FileManager( "lua" )
  end

end
concommand.Add( "zd_vgui_filebrowser", ZDEV.VGUI.FileManager )



ZDEV.FILE.SetLoaded( _f )
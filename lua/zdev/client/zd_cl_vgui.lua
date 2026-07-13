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
ZDEV.CMDS.Register( "zdev_menu_main", ZDEV.VGUI.MainMenu, { aliases = { "zd_menu_main" } } )


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

-- ─────────────────────────────────────────────────────────────────────────────
-- ZDEV_UID: ZDEV_FUNC_54BEF803 | Path: ZDEV.VGUI.MaterialBrowser
--
--  Reusable material/texture browser with directory tree and preview.
--
--  opts fields:
--    title      (string)    Window title                  default "Material Browser"
--    root       (string)    Starting subdirectory         default "materials"
--    startDir   (string)    Initial directory to display  default "particles"
--    path       (string)    GMod search path              default "GAME"
--    w          (number)    Window width                  default ScrW()*0.55
--    h          (number)    Window height                 default ScrH()*0.7
--    onSelect   (function)  Called with the clean material path (no prefix/ext)
--
--  Also works standalone via concommand: zd_vgui_materialbrowser
-- ─────────────────────────────────────────────────────────────────────────────
function ZDEV.VGUI.MaterialBrowser( opts )
  opts = opts or {}
  local title    = opts.title    or "Material Browser"
  local root     = opts.root     or "materials"
  local startDir = opts.startDir or "particles"
  local gpath    = opts.path     or "GAME"
  local fw       = opts.w        or math.floor( ScrW() * 0.55 )
  local fh       = opts.h        or math.floor( ScrH() * 0.7 )
  local onSelect = opts.onSelect

  local frame = ZDEV.VGUI.CreateFrame( fw, fh, title )
  frame:Center()
  frame:MakePopup()
  frame:SetSizable( true )
  frame:SetMinWidth( 500 )
  frame:SetMinHeight( 380 )

  -- ── Recent materials tracking ──
  if not ZDEV.MatBrowser_RecentMaterials then
    ZDEV.MatBrowser_RecentMaterials = {}
  end

  -- ── State ──
  local selected_mat_path = nil   -- clean path e.g. "particles/fire1"
  local selected_mat      = nil   -- IMaterial object for preview
  local current_dir       = root .. "/" .. startDir

  -- ── Clean a file path into a usable material path ──
  local function CleanMatPath( filepath )
    -- Strip leading "materials/" and file extension
    local p = filepath
    p = string.gsub( p, "^materials/", "" )
    p = string.gsub( p, "%.[vV][mM][tT]$", "" )
    p = string.gsub( p, "%.[vV][tT][fF]$", "" )
    p = string.gsub( p, "%.[pP][nN][gG]$", "" )
    return p
  end

  -- ═══════════════════════════════════════════════════════════════════════════
  --  Layout:  [ Tree (left) ]  [ File List + Preview (right) ]
  -- ═══════════════════════════════════════════════════════════════════════════

  local split = vgui.Create( "DHorizontalDivider", frame )
  split:Dock( FILL )
  split:DockMargin( 4, 4, 4, 4 )
  split:SetDividerWidth( 4 )
  split:SetLeftWidth( math.floor( fw * 0.25 ) )
  split:SetLeftMin( 120 )
  split:SetRightMin( 300 )

  -- ── Left: Directory Tree ──────────────────────────────────────────────────

  local tree_pnl = vgui.Create( "DPanel" )
  tree_pnl.Paint = function( s, w, h )
    draw.RoundedBox( 4, 0, 0, w, h, Color( 25, 28, 38, 255 ) )
  end

  local tree_label = vgui.Create( "DLabel", tree_pnl )
  tree_label:Dock( TOP )
  tree_label:SetTall( 20 )
  tree_label:DockMargin( 4, 2, 4, 0 )
  tree_label:SetText( "Directories" )
  tree_label:SetFont( "DermaDefaultBold" )

  local tree = vgui.Create( "DTree", tree_pnl )
  tree:Dock( FILL )
  tree:DockMargin( 2, 2, 2, 2 )

  split:SetLeft( tree_pnl )

  -- ── Right: file list + preview ────────────────────────────────────────────

  local right_pnl = vgui.Create( "DPanel" )
  right_pnl.Paint = function( s, w, h )
    draw.RoundedBox( 4, 0, 0, w, h, Color( 25, 28, 38, 255 ) )
  end

  local right_split = vgui.Create( "DVerticalDivider", right_pnl )
  right_split:Dock( FILL )
  right_split:DockMargin( 2, 2, 2, 2 )
  right_split:SetDividerHeight( 4 )
  right_split:SetTopHeight( math.floor( fh * 0.40 ) )
  right_split:SetTopMin( 100 )
  right_split:SetBottomMin( 140 )

  -- ── File list (top right) ──
  local file_container = vgui.Create( "DPanel" )
  file_container.Paint = function() end

  local path_bar = vgui.Create( "DLabel", file_container )
  path_bar:Dock( TOP )
  path_bar:SetTall( 18 )
  path_bar:DockMargin( 4, 2, 4, 2 )
  path_bar:SetFont( "DermaDefault" )
  path_bar:SetTextColor( Color( 160, 180, 220 ) )
  path_bar:SetText( current_dir )

  local file_list = vgui.Create( "DListView", file_container )
  file_list:Dock( FILL )
  file_list:DockMargin( 2, 0, 2, 2 )
  file_list:SetMultiSelect( false )
  file_list:AddColumn( "Name" )
  file_list:AddColumn( "Type" ):SetFixedWidth( 50 )

  right_split:SetTop( file_container )

  -- ── Preview panel (bottom right) ──
  local preview_pnl = vgui.Create( "DPanel" )
  preview_pnl.Paint = function( s, w, h )
    draw.RoundedBox( 4, 0, 0, w, h, Color( 18, 20, 28, 255 ) )

    if selected_mat and not selected_mat:IsError() then
      -- Render material preview centered with aspect ratio
      local tex = selected_mat:GetTexture( "$basetexture" )
      local tw, th = 256, 256
      if tex then tw, th = tex:Width(), tex:Height() end

      local max_w = w - 16
      local max_h = h - 60
      local scale = math.min( max_w / tw, max_h / th, 1 )
      local dw, dh = math.floor( tw * scale ), math.floor( th * scale )
      local dx = math.floor( ( w - dw ) * 0.5 )
      local dy = 8

      -- Checkerboard background for transparency
      local cb_size = 8
      for cy = dy, dy + dh - 1, cb_size do
        for cx = dx, dx + dw - 1, cb_size do
          local even = ( math.floor( (cx - dx) / cb_size ) + math.floor( (cy - dy) / cb_size ) ) % 2 == 0
          surface.SetDrawColor( even and 40 or 60, even and 40 or 60, even and 40 or 60, 255 )
          surface.DrawRect( cx, cy, math.min( cb_size, dx + dw - cx ), math.min( cb_size, dy + dh - cy ) )
        end
      end

      surface.SetDrawColor( 255, 255, 255, 255 )
      surface.SetMaterial( selected_mat )
      surface.DrawTexturedRect( dx, dy, dw, dh )

      -- Border
      surface.SetDrawColor( 80, 120, 180, 200 )
      surface.DrawOutlinedRect( dx - 1, dy - 1, dw + 2, dh + 2 )

      -- Info text
      local info_y = dy + dh + 6
      draw.SimpleText( selected_mat_path or "", "DermaDefault", 8, info_y, Color( 200, 220, 255 ) )
      draw.SimpleText( tw .. " x " .. th, "DermaDefault", 8, info_y + 14, Color( 150, 150, 170 ) )
      local shader = selected_mat:GetShader() or ""
      if shader ~= "" then
        draw.SimpleText( "Shader: " .. shader, "DermaDefault", 8, info_y + 28, Color( 130, 140, 160 ) )
      end
    else
      draw.SimpleText( selected_mat_path and "Failed to load material" or "Select a material to preview",
        "DermaDefault", w * 0.5, h * 0.5, Color( 120, 120, 140 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    end
  end

  right_split:SetBottom( preview_pnl )

  split:SetRight( right_pnl )

  -- ═══════════════════════════════════════════════════════════════════════════
  --  File population
  -- ═══════════════════════════════════════════════════════════════════════════

  local function PopulateFiles( dir )
    current_dir = dir
    file_list:Clear()
    if IsValid( path_bar ) then path_bar:SetText( dir ) end

    local files, dirs = file.Find( dir .. "/*", gpath )
    files = files or {}
    dirs  = dirs  or {}

    -- Subdirectories first
    for _, d in ipairs( dirs ) do
      local line = file_list:AddLine( d, "DIR" )
      line._isDir  = true
      line._dirPath = dir .. "/" .. d
    end

    -- Files
    for _, f in ipairs( files ) do
      local ext = string.GetExtensionFromFilename( f ) or ""
      ext = string.lower( ext )
      if ext == "vmt" or ext == "vtf" or ext == "png" then
        local line = file_list:AddLine( f, string.upper( ext ) )
        line._isDir    = false
        line._filePath = dir .. "/" .. f
      end
    end
  end

  -- ═══════════════════════════════════════════════════════════════════════════
  --  Directory tree population
  -- ═══════════════════════════════════════════════════════════════════════════

  local function AddTreeNode( parent_node, dir_path, name )
    local node = parent_node:AddNode( name )
    node:SetExpanded( false )
    node._dirPath = dir_path

    -- Lazy-load children on expand
    local populated = false
    node.DoPopulate = function( self )
      if populated then return end
      populated = true
      local _, sub_dirs = file.Find( dir_path .. "/*", gpath )
      if sub_dirs then
        for _, sd in ipairs( sub_dirs ) do
          AddTreeNode( self, dir_path .. "/" .. sd, sd )
        end
      end
    end

    node.DoClick = function( self )
      self:DoPopulate()
      PopulateFiles( dir_path )
    end

    return node
  end

  -- Build root nodes for common material directories
  local root_node = tree:AddNode( root )
  root_node._dirPath = root
  root_node.DoClick = function( self ) PopulateFiles( root ) end

  local _, root_dirs = file.Find( root .. "/*", gpath )
  if root_dirs then
    -- Prioritise common sprite/particle directories at the top
    local priority = { particles = true, effects = true, sprites = true, particle = true }
    local sorted = {}
    local rest   = {}
    for _, d in ipairs( root_dirs ) do
      if priority[ string.lower(d) ] then
        table.insert( sorted, d )
      else
        table.insert( rest, d )
      end
    end
    table.sort( sorted )
    table.sort( rest )
    for _, d in ipairs( sorted ) do AddTreeNode( root_node, root .. "/" .. d, d ) end
    for _, d in ipairs( rest )   do AddTreeNode( root_node, root .. "/" .. d, d ) end
  end
  root_node:SetExpanded( true )

  -- ═══════════════════════════════════════════════════════════════════════════
  --  File list interaction
  -- ═══════════════════════════════════════════════════════════════════════════

  -- Single click → preview (or navigate into subdirectory)
  file_list.OnRowSelected = function( self, idx, row )
    if row._isDir then return end
    if row._filePath then
      selected_mat_path = CleanMatPath( row._filePath )
      selected_mat      = Material( selected_mat_path )
    end
  end

  -- Double-click → navigate into directory, or select material
  file_list.OnRowDCClick = function( self, idx, row )
    if row._isDir and row._dirPath then
      PopulateFiles( row._dirPath )
      return
    end
    if row._filePath and onSelect then
      selected_mat_path = CleanMatPath( row._filePath )
      onSelect( selected_mat_path )
      frame:Close()
    end
  end

  -- ═══════════════════════════════════════════════════════════════════════════
  --  Helper: Track and apply material selection
  -- ═══════════════════════════════════════════════════════════════════════════

  local function ApplyMaterialSelection()
    if selected_mat_path and onSelect then
      -- Add to recents
      table.insert( ZDEV.MatBrowser_RecentMaterials, 1, selected_mat_path )
      -- Keep only last 10
      if #ZDEV.MatBrowser_RecentMaterials > 10 then
        table.remove( ZDEV.MatBrowser_RecentMaterials )
      end
      -- Remove duplicates
      local seen = {}
      local deduped = {}
      for _, mat in ipairs( ZDEV.MatBrowser_RecentMaterials ) do
        if not seen[mat] then
          seen[mat] = true
          table.insert( deduped, mat )
        end
      end
      ZDEV.MatBrowser_RecentMaterials = deduped

      onSelect( selected_mat_path )
      frame:Close()
    end
  end

  -- ═══════════════════════════════════════════════════════════════════════════
  --  Bottom bar with Recent materials panel and selection
  -- ═══════════════════════════════════════════════════════════════════════════

  local bottom_container = vgui.Create( "DPanel", frame )
  bottom_container:Dock( BOTTOM )
  bottom_container:SetTall( 120 )
  bottom_container:DockMargin( 4, 0, 4, 4 )
  bottom_container.Paint = function() end

  -- Recent materials panel
  local recent_pnl = vgui.Create( "DPanel", bottom_container )
  recent_pnl:Dock( FILL )
  recent_pnl.Paint = function( s, w, h )
    draw.RoundedBox( 3, 0, 0, w, h, Color( 25, 28, 38, 200 ) )
    draw.SimpleText( "Recent Materials", "DermaDefaultBold", 8, 4, Color( 150, 180, 220 ) )
  end

  local recent_scroll = vgui.Create( "DScrollPanel", recent_pnl )
  recent_scroll:Dock( FILL )
  recent_scroll:DockMargin( 4, 18, 4, 4 )

  local function RefreshRecentButtons()
    recent_scroll:Clear()
    for _, mat_path in ipairs( ZDEV.MatBrowser_RecentMaterials ) do
      local btn = vgui.Create( "DButton", recent_scroll )
      btn:Dock( TOP )
      btn:SetTall( 20 )
      btn:DockMargin( 2, 2, 2, 2 )
      btn:SetText( mat_path )
      btn:SetFont( "DermaDefault" )
      btn.DoClick = function()
        selected_mat_path = mat_path
        selected_mat = Material( mat_path )
        if IsValid( path_entry ) then path_entry:SetValue( mat_path ) end
      end
      btn.Paint = function( s, w, h )
        local bg_col = btn:IsHovered() and Color( 80, 120, 200, 200 ) or Color( 50, 60, 80, 200 )
        draw.RoundedBox( 2, 0, 0, w, h, bg_col )
        draw.SimpleText( mat_path, "DermaDefault", 4, 2, color_white )
      end
    end
  end

  -- Input bar at bottom
  local input_bar = vgui.Create( "DPanel", bottom_container )
  input_bar:Dock( BOTTOM )
  input_bar:SetTall( 34 )
  input_bar:DockMargin( 0, 4, 0, 0 )
  input_bar.Paint = function() end

  -- Selected path text entry (allows manual typing, ENTER to confirm)
  local path_entry = vgui.Create( "DTextEntry", input_bar )
  path_entry:Dock( FILL )
  path_entry:DockMargin( 0, 4, 8, 4 )
  path_entry:SetPlaceholderText( "Material path... (ENTER to select)" )
  path_entry:SetValue( selected_mat_path or "" )
  path_entry.OnEnter = function( self )
    local v = string.Trim( self:GetValue() )
    if v ~= "" then
      selected_mat_path = v
      selected_mat = Material( v )
      ApplyMaterialSelection()
    end
  end

  -- Keep text entry in sync with selection
  local old_on_row = file_list.OnRowSelected
  file_list.OnRowSelected = function( self, idx, row )
    old_on_row( self, idx, row )
    if selected_mat_path and IsValid( path_entry ) then
      path_entry:SetValue( selected_mat_path )
      RefreshRecentButtons()
    end
  end

  local btn_select = ZDEV.VGUI.CreateButton( input_bar, 90, 26, "Select", "DermaDefault", Color( 100, 220, 120 ), function()
    -- Allow manual entry to override
    local manual = string.Trim( path_entry:GetValue() )
    if manual ~= "" then selected_mat_path = manual end
    ApplyMaterialSelection()
  end )
  btn_select:Dock( RIGHT ) ; btn_select:DockMargin( 0, 3, 0, 3 )

  RefreshRecentButtons()

  -- ── Initial population ──
  PopulateFiles( current_dir )

  return frame
end
ZDEV.CMDS.Register( "zdev_vgui_materialbrowser", function( ply, cmd, arg ) ZDEV.VGUI.MaterialBrowser() end,
	{ aliases = { "zd_vgui_materialbrowser" } } )

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
ZDEV.CMDS.Register( "zdev_vgui_filebrowser", ZDEV.VGUI.FileManager, { aliases = { "zd_vgui_filebrowser" } } )

-- ─────────────────────────────────────────────────────────────────────────────
-- ZDEV_UID: ZDEV_FUNC_FILEPICKER | Path: ZDEV.VGUI.FilePicker
--
--  Reusable DATA-directory file picker popup.
--
--  opts fields:
--    title        (string)    Window title              default "Open File"
--    dir          (string)    DATA subdirectory to scan  default ""
--    ext          (string)    Glob filter                default "*.json"
--    w            (number)    Window width               default 480
--    h            (number)    Window height              default 360
--    onSelect     (function)  Called with filename when a file is opened
--    onDelete     (function)  Called with filename after deletion (optional)
--    allowDelete  (bool)      Show the Delete button     default false
-- ─────────────────────────────────────────────────────────────────────────────
function ZDEV.VGUI.FilePicker( opts )
  opts = opts or {}
  local title       = opts.title       or "Open File"
  local dir         = opts.dir         or ""
  local ext         = opts.ext         or "*.json"
  local fw          = opts.w           or 480
  local fh          = opts.h           or 360
  local onSelect    = opts.onSelect
  local onDelete    = opts.onDelete
  local allowDelete = opts.allowDelete or false

  local frame = ZDEV.VGUI.CreateFrame( fw, fh, title )
  frame:Center()
  frame:MakePopup()

  -- ── File list ──
  local lv = vgui.Create( "DListView", frame )
  lv:Dock( FILL )
  lv:DockMargin( 4, 4, 4, 4 )
  lv:SetMultiSelect( false )
  lv:AddColumn( "Filename" ):SetFixedWidth( math.floor( fw * 0.44 ) )
  lv:AddColumn( "Size" ):SetFixedWidth( 70 )
  lv:AddColumn( "Modified" )

  local function PopulateFiles()
    lv:Clear()
    if not file.Exists( dir, "DATA" ) then
      lv:AddLine( "(directory not found)", "", "" )
      return
    end
    local files_list = file.Find( dir .. ext, "DATA" ) or {}
    for _, fname in ipairs( files_list ) do
      local full_path = dir .. fname
      local sz = file.Size( full_path, "DATA" ) or 0
      local sz_str
      if sz >= 1024 then
        sz_str = string.format( "%.1f KB", sz / 1024 )
      else
        sz_str = sz .. " B"
      end
      local t = file.Time( full_path, "DATA" ) or 0
      local date_str = ( t > 0 ) and os.date( "%Y-%m-%d %H:%M", t ) or "—"
      local line = lv:AddLine( fname, sz_str, date_str )
      line._filename = fname
    end
    if #files_list == 0 then
      lv:AddLine( "(no files)", "", "" )
    end
  end

  PopulateFiles()

  -- ── Double-click to select ──
  lv.OnRowDCClick = function( self, idx, row )
    if row._filename and onSelect then
      onSelect( row._filename )
      frame:Close()
    end
  end

  -- ── Bottom button bar ──
  local bar = vgui.Create( "DPanel", frame )
  bar:Dock( BOTTOM )
  bar:SetTall( 32 )
  bar:DockMargin( 4, 0, 4, 4 )
  bar.Paint = function() end

  local btn_open = ZDEV.VGUI.CreateButton( bar, 90, 28, "Open", "DermaDefault", Color( 100, 220, 120 ), function()
    local sel = lv:GetSelectedLine()
    if sel then
      local row = lv:GetLine( sel )
      if row and row._filename and onSelect then
        onSelect( row._filename )
        frame:Close()
      end
    end
  end )
  btn_open:Dock( LEFT ) ; btn_open:DockMargin( 0, 2, 4, 2 )

  local btn_refresh = ZDEV.VGUI.CreateButton( bar, 90, 28, "Refresh", "DermaDefault", Color( 180, 200, 255 ), function()
    PopulateFiles()
  end )
  btn_refresh:Dock( LEFT ) ; btn_refresh:DockMargin( 0, 2, 4, 2 )

  if allowDelete then
    local btn_delete = ZDEV.VGUI.CreateButton( bar, 90, 28, "Delete", "DermaDefault", Color( 255, 100, 100 ), function()
      local sel = lv:GetSelectedLine()
      if sel then
        local row = lv:GetLine( sel )
        if row and row._filename then
          Derma_Query( "Delete '" .. row._filename .. "'?", "Confirm Delete", "Yes", function()
            local full_path = dir .. row._filename
            if file.Exists( full_path, "DATA" ) then
              file.Delete( full_path )
            end
            if onDelete then onDelete( row._filename ) end
            PopulateFiles()
          end, "No" )
        end
      end
    end )
    btn_delete:Dock( RIGHT ) ; btn_delete:DockMargin( 4, 2, 0, 2 )
  end

  return frame
end


ZDEV.FILE.SetLoaded( _f )
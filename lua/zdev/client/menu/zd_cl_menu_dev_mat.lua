local _f = 'zdev/client/vgui/zd_cl_menu_dev_mat.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end

local pairs    = pairs
local ipairs   = ipairs
local tostring = tostring
local tonumber = tonumber
local string   = string
local table    = table
local math     = math
local file     = file
local util     = util
local Color    = Color
local Material = Material

local SW, SH = ScrW(), ScrH()

-- ─── Save directory ──────────────────────────────────────────────────────────
local SAVE_DIR = "zdev/materials/"

-- ─── Palette (precomputed — no per-frame Color allocation in Paint) ──────────
local CLR_PANEL_L    = Color( 28, 32, 42, 255 )
local CLR_PANEL_R    = Color( 30, 34, 44, 255 )
local CLR_HEADER     = Color( 55, 60, 75, 255 )
local CLR_ROW_EVEN   = Color( 38, 42, 52, 255 )
local CLR_ROW_ODD    = Color( 32, 36, 46, 255 )
local CLR_KEY_TEXT   = Color( 130, 200, 255 )
local CLR_ACCENT     = Color( 0, 140, 200, 120 )
local CLR_INSET      = Color( 26, 30, 40, 255 )
local CLR_INSET_OUT  = Color( 60, 80, 120, 80 )
local CLR_BAR        = Color( 38, 42, 52, 255 )
local CLR_LBL        = Color( 180, 200, 220 )
local CLR_SEL_BG     = Color( 22, 26, 36, 200 )
local CLR_FIELD_BG   = Color( 38, 42, 54, 255 )
local CLR_OK         = Color( 120, 220, 120 )
local CLR_ERR        = Color( 255, 120, 120 )
local CLR_PREV_BG    = Color( 20, 22, 30, 255 )
local CLR_PREV_OUT   = Color( 80, 100, 140, 100 )
local CLR_CHECKER_A  = Color( 46, 50, 60, 255 )
local CLR_CHECKER_B  = Color( 34, 38, 48, 255 )
local CLR_PREV_TEXT  = Color( 100, 100, 100 )
local CLR_PREV_INFO  = Color( 150, 170, 190, 200 )

-- ─── Texture-path parameter lookup (case-insensitive) ────────────────────────
local TEXTURE_PARAMS = {}
for _, k in ipairs({
	"$basetexture", "$basetexture2", "$bumpmap", "$normalmap",
	"$detail", "$envmap", "$envmapmask", "$phongexponenttexture",
	"$blendmodulatetexture", "$dudvmap", "$refracttinttexture",
	"$refracttexture", "$reflecttexture", "$underwateroverlay",
	"$bottommaterial", "$fallbackmaterial", "$selfillummask",
	"$phongwarptexture", "$lightwarptexture", "$normal",
	"$toksfix", "$iris",
}) do TEXTURE_PARAMS[k] = true end

local function IsTextureParam( key )
	return TEXTURE_PARAMS[ string.lower( string.Trim(key) ) ] or false
end

-- ─── Helper: resolve texture paths for CreateMaterial ────────────────────────
-- .png/.jpg files must be loaded through Material() first, then referenced by
-- their generated texture name (wiki: Global.CreateMaterial)
local function ResolveTexturePath( v )
	local lower = string.lower( v )
	if string.EndsWith( lower, ".png" ) or string.EndsWith( lower, ".jpg" ) then
		local ok, m = pcall( Material, v )
		if ok and m and not m:IsError() then
			local tex = m:GetTexture( "$basetexture" )
			if tex then return tex:GetName() end
		end
	end
	return v
end

-- ─── VMT parser  (text → {shader, properties[]}) ────────────────────────────
local function ParseVMT( text )
	local result = { shader = "", properties = {} }
	if not text or text == "" then return result end

	local lines = string.Explode( "\n", text )
	local found_shader = false
	local depth = 0

	for _, raw_line in ipairs( lines ) do
		local line = string.Trim( raw_line )
		-- strip comments
		local cpos = string.find( line, "//", 1, true )
		if cpos then line = string.Trim( string.sub( line, 1, cpos - 1 ) ) end

		if line ~= "" then
			-- opening brace
			if string.find( line, "{", 1, true ) then
				-- shader may be on the same line as the brace: "ShaderName" {
				if not found_shader then
					local s = string.match( line, '^"?([^"{]+)"?' )
					if s then result.shader = string.Trim( s ) end
					found_shader = true
				end
				depth = depth + 1
			-- closing brace
			elseif string.find( line, "}", 1, true ) then
				depth = depth - 1
			-- shader name (line before first brace)
			elseif not found_shader and depth == 0 then
				result.shader = string.gsub( line, '"', '' )
				found_shader = true
			-- key-value at depth 1 only (skip Proxies etc.)
			elseif depth == 1 then
				local key, val
				-- "$key" "value"
				key, val = string.match( line, '"([^"]+)"%s+"([^"]*)"' )
				if not key then
					-- "$key" value
					key, val = string.match( line, '"([^"]+)"%s+(%S+)' )
				end
				if not key then
					-- $key "value"
					key, val = string.match( line, '(%$%S+)%s+"([^"]*)"' )
				end
				if not key then
					-- $key value
					key, val = string.match( line, '(%$%S+)%s+(%S+)' )
				end
				if key then
					table.insert( result.properties, { key = key, value = val or "" } )
				end
			end
		end
	end
	return result
end

-- ─── VMT generator  ({shader, properties[]} → text) ─────────────────────────
local function GenerateVMT( shader, properties )
	local lines = { '"' .. (shader or "VertexLitGeneric") .. '"', '{' }
	for _, prop in ipairs( properties or {} ) do
		local k = prop.key or ""
		local v = prop.value or ""
		table.insert( lines, '\t"' .. k .. '" "' .. v .. '"' )
	end
	table.insert( lines, '}' )
	return table.concat( lines, "\n" )
end

-- ─── Material preview panel ──────────────────────────────────────────────────
-- Draws the material fully CONTAINED inside a centered square (1:1) area,
-- preserving the texture's own aspect ratio — never cropped or stretched.
-- (DImage:SetKeepAspect crops overflow, which is why the old preview cut
--  materials off.)
local function CreatePreviewPanel( parent )
	local pnl = vgui.Create( "DPanel", parent )
	pnl.m_zMat      = nil
	pnl.m_zDimText  = ""
	pnl.m_zEmptyText = "no material"

	pnl.SetPreviewMaterial = function( self, mat )
		if mat and not mat:IsError() then
			self.m_zMat = mat
			local mw, mh = mat:Width(), mat:Height()
			self.m_zDimText = ( mw and mh and mw > 0 and mh > 0 ) and ( mw .. " x " .. mh ) or ""
		else
			self.m_zMat     = nil
			self.m_zDimText = ""
		end
	end

	pnl.GetPreviewMaterial = function( self )
		return self.m_zMat
	end

	pnl.Paint = function( self, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, CLR_PREV_BG )

		local pad  = 6
		local side = math.min( w, h ) - pad * 2
		if side < 8 then return end
		local x0 = math.floor( ( w - side ) * 0.5 )
		local y0 = math.floor( ( h - side ) * 0.5 )

		-- checkerboard backing (shows through translucent materials)
		surface.SetDrawColor( CLR_CHECKER_A )
		surface.DrawRect( x0, y0, side, side )
		surface.SetDrawColor( CLR_CHECKER_B )
		local cell  = 20
		local cells = math.ceil( side / cell )
		for cy = 0, cells - 1 do
			for cx = 0, cells - 1 do
				if ( cx + cy ) % 2 == 1 then
					local cw = math.min( cell, side - cx * cell )
					local ch = math.min( cell, side - cy * cell )
					if cw > 0 and ch > 0 then
						surface.DrawRect( x0 + cx * cell, y0 + cy * cell, cw, ch )
					end
				end
			end
		end

		local mat = self.m_zMat
		if mat and not mat:IsError() then
			local mw = mat:Width()
			local mh = mat:Height()
			if not mw or mw <= 0 then mw = 512 end
			if not mh or mh <= 0 then mh = 512 end

			-- fit the ENTIRE texture inside the square, keeping its aspect
			local scale = math.min( side / mw, side / mh )
			local dw = math.max( 1, math.floor( mw * scale ) )
			local dh = math.max( 1, math.floor( mh * scale ) )

			surface.SetDrawColor( 255, 255, 255, 255 )
			surface.SetMaterial( mat )
			surface.DrawTexturedRect(
				x0 + math.floor( ( side - dw ) * 0.5 ),
				y0 + math.floor( ( side - dh ) * 0.5 ), dw, dh )

			if self.m_zDimText ~= "" then
				draw.SimpleText( self.m_zDimText, "DermaDefault", w - 8, h - 4,
					CLR_PREV_INFO, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM )
			end
		else
			draw.SimpleText( self.m_zEmptyText, "DermaLarge", w * 0.5, h * 0.5,
				CLR_PREV_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end

		surface.SetDrawColor( CLR_PREV_OUT )
		surface.DrawOutlinedRect( x0, y0, side, side )
	end

	return pnl
end

-- ─── Helper: add a dummy child so the DTree shows an expand arrow ────────────
local function AddExpandPlaceholder( node )
	local dummy = node:AddNode( "Loading...", "icon16/hourglass.png" )
	dummy.m_zDummy = true
	-- Safety net: clicking the dummy expands (and thereby populates) the parent
	dummy.DoClick = function( self )
		local parent = self:GetParentNode()
		if IsValid( parent ) then parent:SetExpanded( true ) end
	end
	return dummy
end

-- ─── Helper: remove all dummy children before real population ────────────────
local function RemovePlaceholders( node )
	for _, child in ipairs( node:GetChildNodes() ) do
		if IsValid( child ) and child.m_zDummy then
			child:Remove()
		end
	end
end

-- ─── File tree lazy loading ──────────────────────────────────────────────────
-- Stock DTree_Node never calls a custom DoPopulate — both the expander arrow
-- and double-click route through SetExpanded, so that is where we hook the
-- population (fixes the stale "Loading..." placeholder).
local PopulateTreeNode  -- forward declaration (mutual recursion with MakeLazyFolderNode)

local function WireLazyExpand( node )
	AddExpandPlaceholder( node )
	local origSetExpanded = node.SetExpanded  -- class method via __index, captured before override
	node.SetExpanded = function( self, expand, ... )
		if expand and not self.m_bZPopulated and self.DoPopulate then
			self:DoPopulate()
		end
		origSetExpanded( self, expand, ... )
	end
end

local function MakeLazyFolderNode( node, folder, searchPath )
	node.m_zFolder      = folder
	node.m_zSearchPath  = searchPath
	node.DoPopulate = function( self )
		PopulateTreeNode( self, self.m_zFolder, self.m_zSearchPath )
	end
	WireLazyExpand( node )
end

-- File tree builder (lazy, .vmt + .png only)
PopulateTreeNode = function( node, folder, searchPath )
	if node.m_bZPopulated then return end
	node.m_bZPopulated = true

	RemovePlaceholders( node )

	-- Sub-directories
	local _, dirs = file.Find( folder .. "/*", searchPath )
	for _, d in ipairs( dirs or {} ) do
		local child = node:AddNode( d, "icon16/folder.png" )
		MakeLazyFolderNode( child, folder .. "/" .. d, searchPath )
	end

	-- .vmt files
	local vmt_files = file.Find( folder .. "/*.vmt", searchPath ) or {}
	for _, f in ipairs( vmt_files ) do
		local child = node:AddNode( f, "icon16/page_white_text.png" )
		child.m_zFilePath   = folder .. "/" .. f
		child.m_zSearchPath = searchPath
		child.m_zIsFile     = true
		child.m_zExt        = "vmt"
	end

	-- .png files
	local png_files = file.Find( folder .. "/*.png", searchPath ) or {}
	for _, f in ipairs( png_files ) do
		local child = node:AddNode( f, "icon16/picture.png" )
		child.m_zFilePath   = folder .. "/" .. f
		child.m_zSearchPath = searchPath
		child.m_zIsFile     = true
		child.m_zExt        = "png"
	end
end


-- ─────────────────────────────────────────────────────────────────────────────
--  Texture Replacement Popup
-- ─────────────────────────────────────────────────────────────────────────────
local function OpenTextureReplacer( current_vtf_path, onReplace )
	local frm = ZDEV.VGUI.CreateFrame( 480, 560, "Texture Preview / Replace" )
	frm:Center()
	frm:MakePopup()

	-- Preview (square, full-fit)
	local preview = CreatePreviewPanel( frm )
	preview:Dock( TOP )
	preview:SetTall( 220 )
	preview:DockMargin( 4, 4, 4, 4 )
	preview.m_zEmptyText = "no texture"
	local ok, mat = pcall( Material, current_vtf_path )
	if ok then preview:SetPreviewMaterial( mat ) end

	-- Path entry
	local lbl = vgui.Create( "DLabel", frm )
	lbl:Dock( TOP ) ; lbl:SetText( "Texture path (relative to materials/, no extension):" )
	lbl:DockMargin( 4, 4, 4, 2 ) ; lbl:SetFont( "DermaDefaultBold" )

	local path_te = vgui.Create( "DTextEntry", frm )
	path_te:Dock( TOP ) ; path_te:SetTall( 24 ) ; path_te:DockMargin( 4, 0, 4, 4 )
	path_te:SetValue( current_vtf_path or "" )

	-- Update preview when typing
	path_te.OnEnter = function( self )
		local p = self:GetValue()
		local ok2, m2 = pcall( Material, p )
		if ok2 then preview:SetPreviewMaterial( m2 ) end
	end

	-- Mini file tree for browsing
	local tree_lbl = vgui.Create( "DLabel", frm )
	tree_lbl:Dock( TOP ) ; tree_lbl:SetText( "Browse materials:" )
	tree_lbl:DockMargin( 4, 4, 4, 2 ) ; tree_lbl:SetFont( "DermaDefault" )

	local tree = vgui.Create( "DTree", frm )
	tree:Dock( FILL ) ; tree:DockMargin( 4, 0, 4, 4 )

	local root_game = tree:AddNode( "Game Materials", "icon16/folder.png" )
	MakeLazyFolderNode( root_game, "materials", "GAME" )

	tree.OnNodeSelected = function( self, node )
		if not node.m_zIsFile then return end
		local fp = node.m_zFilePath or ""
		-- Strip "materials/" prefix and extension for VMT path
		local rel = string.gsub( fp, "^materials/", "" )
		rel = string.StripExtension( rel )
		path_te:SetValue( rel )
		local ok3, m3 = pcall( Material, rel )
		if ok3 then preview:SetPreviewMaterial( m3 ) end
	end

	-- Button bar
	local btn_bar = vgui.Create( "DPanel", frm )
	btn_bar:Dock( BOTTOM ) ; btn_bar:SetTall( 32 ) ; btn_bar:DockMargin( 4, 4, 4, 4 )
	btn_bar.Paint = function() end

	local btn_replace = vgui.Create( "DButton", btn_bar )
	btn_replace:Dock( LEFT ) ; btn_replace:SetWide( 120 ) ; btn_replace:SetText( "Replace" )
	btn_replace:SetIcon( "icon16/accept.png" )
	btn_replace.DoClick = function()
		local new_path = path_te:GetValue()
		if onReplace then onReplace( new_path ) end
		frm:Close()
	end

	local btn_close = vgui.Create( "DButton", btn_bar )
	btn_close:Dock( RIGHT ) ; btn_close:SetWide( 80 ) ; btn_close:SetText( "Close" )
	btn_close:SetIcon( "icon16/cross.png" )
	btn_close.DoClick = function() frm:Close() end
end


-- ─────────────────────────────────────────────────────────────────────────────
--  ZDEV_UID: ZDEV_FUNC_4DA2FF67 | Path: ZDEV.VGUI.Editor_Materials
-- ─────────────────────────────────────────────────────────────────────────────
function ZDEV.VGUI.Editor_Materials( cmd, ply, arg )

	-- ── State ────────────────────────────────────────────────────────────────
	local EDITOR = {
		SelectedFile    = "",         -- full path (e.g. "materials/brick/brick01.vmt")
		MaterialPath    = "",         -- Material() path (e.g. "brick/brick01")
		SearchPath      = "GAME",     -- which search path the file came from
		Shader          = "",
		Properties      = {},         -- { {key, value}, ... }
		RawVMT          = "",
		IsModified      = false,
		SyncLock        = false,      -- prevents recursive sync loops
	}

	-- Ensure save directory exists
	if not file.Exists( SAVE_DIR, "DATA" ) then file.CreateDir( SAVE_DIR ) end

	local menu_w = math.max( SW * 0.72, 900 )
	local menu_h = math.max( SH * 0.80, 600 )
	local menu   = ZDEV.VGUI.CreateFrame( menu_w, menu_h, "Material Editor" )
	menu:Center()

	-- Forward refs for panels we need across scopes
	local tree_panel, preview_img, shader_entry, prop_scroll, selected_lbl
	local raw_vmt_frame  -- toggled popup
	local sheet, inspect_sheet

	-- ── Helpers ──────────────────────────────────────────────────────────────
	local function UpdateTitle()
		local t = "Material Editor"
		if EDITOR.SelectedFile ~= "" then t = t .. " — " .. EDITOR.SelectedFile end
		if EDITOR.IsModified then t = t .. " *" end
		menu:SetTitle( t )
	end

	-- Rebuild the property table rows from EDITOR.Properties
	local prop_rows = {}  -- {DPanel, ...} — so we can clear/rebuild

	local function RebuildPropertyTable()
		if not IsValid( prop_scroll ) then return end

		-- Clear existing rows
		for _, row in ipairs( prop_rows ) do
			if IsValid( row ) then row:Remove() end
		end
		prop_rows = {}

		-- Column header
		local hdr = vgui.Create( "DPanel", prop_scroll )
		hdr:Dock( TOP ) ; hdr:SetTall( 22 ) ; hdr:DockMargin( 0, 0, 0, 1 )
		hdr.Paint = function( s, w, h )
			surface.SetDrawColor( CLR_HEADER )
			surface.DrawRect( 0, 0, w, h )
		end
		local function hdr_lbl( text, dock, wide )
			local l = vgui.Create( "DLabel", hdr )
			l:Dock( dock ) ; if wide then l:SetWide( wide ) end
			l:SetText( "  " .. text ) ; l:SetFont( "DermaDefaultBold" )
		end
		hdr_lbl( "Property", LEFT, 160 )
		hdr_lbl( "Value",    FILL )
		table.insert( prop_rows, hdr )

		-- Data rows
		for i, prop in ipairs( EDITOR.Properties ) do
			local row = vgui.Create( "DPanel", prop_scroll )
			row:Dock( TOP ) ; row:SetTall( 24 ) ; row:DockMargin( 0, 0, 0, 1 )
			local even = ( i % 2 == 0 )
			row.Paint = function( s, w, h )
				surface.SetDrawColor( even and CLR_ROW_EVEN or CLR_ROW_ODD )
				surface.DrawRect( 0, 0, w, h )
			end

			-- Property name (label)
			local key_lbl = vgui.Create( "DLabel", row )
			key_lbl:Dock( LEFT ) ; key_lbl:SetWide( 160 )
			key_lbl:SetText( "  " .. prop.key ) ; key_lbl:SetFont( "DermaDefault" )
			key_lbl:SetTextColor( CLR_KEY_TEXT )

			-- Preview button (texture params only) — dock RIGHT before value fills
			local is_tex = IsTextureParam( prop.key )
			if is_tex then
				local btn_prev = vgui.Create( "DButton", row )
				btn_prev:Dock( RIGHT ) ; btn_prev:SetWide( 28 )
				btn_prev:SetText( "" ) ; btn_prev:SetIcon( "icon16/image.png" )
				btn_prev:SetTooltip( "Preview / Replace texture" )
				btn_prev.DoClick = function()
					OpenTextureReplacer( prop.value, function( new_path )
						prop.value = new_path
						-- Sync: update VMT text and UI
						EDITOR.RawVMT = GenerateVMT( EDITOR.Shader, EDITOR.Properties )
						EDITOR.IsModified = true
						RebuildPropertyTable()
						UpdateTitle()
						-- Update raw editor if open
						if IsValid( raw_vmt_frame ) and raw_vmt_frame.te then
							raw_vmt_frame.te:SetValue( EDITOR.RawVMT )
						end
					end )
				end
			end

			-- Value (editable text entry) — fills remaining
			local val_te = vgui.Create( "DTextEntry", row )
			val_te:Dock( FILL ) ; val_te:DockMargin( 2, 2, 2, 2 )
			val_te:SetValue( prop.value )
			val_te:SetFont( "DermaDefault" )

			val_te.OnValueChange = function( self, new_val )
				if EDITOR.SyncLock then return end
				prop.value = new_val
				EDITOR.IsModified = true
				-- Regenerate VMT text
				EDITOR.SyncLock = true
				EDITOR.RawVMT = GenerateVMT( EDITOR.Shader, EDITOR.Properties )
				if IsValid( raw_vmt_frame ) and raw_vmt_frame.te then
					raw_vmt_frame.te:SetValue( EDITOR.RawVMT )
				end
				UpdateTitle()
				EDITOR.SyncLock = false
			end

			table.insert( prop_rows, row )
		end
	end

	-- Full update: parse VMT text → update shader, properties, preview, table
	local function SyncFromVMT( vmt_text )
		if EDITOR.SyncLock then return end
		EDITOR.SyncLock = true

		EDITOR.RawVMT = vmt_text
		local parsed = ParseVMT( vmt_text )
		EDITOR.Shader     = parsed.shader
		EDITOR.Properties = parsed.properties

		-- Update shader entry
		if IsValid( shader_entry ) then shader_entry:SetValue( EDITOR.Shader ) end

		-- Update preview from material
		if IsValid( preview_img ) and EDITOR.MaterialPath ~= "" then
			local ok, mat = pcall( Material, EDITOR.MaterialPath )
			if ok then preview_img:SetPreviewMaterial( mat ) end
		end

		-- Rebuild property table
		RebuildPropertyTable()

		-- Update raw editor popup if open
		if IsValid( raw_vmt_frame ) and raw_vmt_frame.te then
			raw_vmt_frame.te:SetValue( vmt_text )
		end

		EDITOR.SyncLock = false
	end

	-- Load a material from the file tree
	local function LoadFromTree( filepath, searchPath, ext )
		EDITOR.SelectedFile = filepath
		EDITOR.SearchPath   = searchPath

		-- Derive Material() path
		local rel = string.gsub( filepath, "^materials/", "" )
		if ext == "vmt" then
			EDITOR.MaterialPath = string.StripExtension( rel )
		else
			EDITOR.MaterialPath = rel  -- keep .png extension
		end

		-- Update selected label
		if IsValid( selected_lbl ) then
			selected_lbl:SetText( "  " .. filepath )
		end

		-- Update preview
		if IsValid( preview_img ) then
			local ok, mat = pcall( Material, EDITOR.MaterialPath )
			if ok and mat and not mat:IsError() then
				preview_img:SetPreviewMaterial( mat )
			else
				preview_img:SetPreviewMaterial( nil )
			end
		end

		if ext == "vmt" then
			-- Read raw VMT content
			local content = file.Read( filepath, searchPath )
			if not content then content = file.Read( filepath, "DATA" ) end
			if content then
				SyncFromVMT( content )
				EDITOR.IsModified = false
			else
				-- Fallback: use Material():GetKeyValues()
				local ok, mat = pcall( Material, EDITOR.MaterialPath )
				if ok and mat and not mat:IsError() then
					local kv_ok, kv = pcall( function() return mat:GetKeyValues() end )
					if kv_ok and kv then
						local fallback = util.TableToKeyValues( kv )
						SyncFromVMT( fallback )
					end
				end
				EDITOR.IsModified = false
			end
		else
			-- PNG — no VMT to parse
			EDITOR.Shader = ""
			EDITOR.Properties = {}
			EDITOR.RawVMT = "-- PNG image file: " .. filepath .. " --"
			if IsValid( shader_entry ) then shader_entry:SetValue( "(image)" ) end
			RebuildPropertyTable()
			EDITOR.IsModified = false
		end

		UpdateTitle()
		zdev.log( "S", "Loaded material: " .. filepath )
	end

	-- Save arbitrary text as .txt in data/zdev/materials/
	local function SaveTextAs( filename, text )
		if not filename or filename == "" then return end
		if not string.EndsWith( filename, ".txt" ) then filename = filename .. ".txt" end
		file.CreateDir( SAVE_DIR )
		file.Write( SAVE_DIR .. filename, text )
		zdev.log( "S", "Saved material to: " .. SAVE_DIR .. filename )
	end

	-- Save the INSPECT tab's current VMT text
	local function SaveAsTxt( filename )
		SaveTextAs( filename, EDITOR.RawVMT )
		EDITOR.IsModified = false
		UpdateTitle()
	end


	-- ─── MENU BAR ────────────────────────────────────────────────────────────
	local mb = vgui.Create( "DMenuBar", menu )
	mb:DockMargin( 2, 2, 2, 0 )

	-- File menu
	local m_file = mb:AddMenu( "File" )

	m_file:AddOption( "New VMT", function()
		EDITOR.SelectedFile = ""
		EDITOR.MaterialPath = ""
		local template = '"VertexLitGeneric"\n{\n\t"$basetexture" "models/debug/debugwhite"\n\t"$model" "1"\n}'
		SyncFromVMT( template )
		EDITOR.IsModified = true
		if IsValid( selected_lbl ) then selected_lbl:SetText( "  (new material)" ) end
		if IsValid( preview_img ) then preview_img:SetPreviewMaterial( nil ) end
		UpdateTitle()
	end ):SetIcon( "icon16/page_white_add.png" )

	m_file:AddSpacer()

	m_file:AddOption( "Save as .txt…", function()
		local default_name = "material"
		if EDITOR.SelectedFile ~= "" then
			default_name = string.StripExtension( string.GetFileFromFilename( EDITOR.SelectedFile ) )
		end
		Derma_StringRequest( "Save Material", "Filename (saved to data/" .. SAVE_DIR .. "):",
			default_name .. ".txt",
			function( fname ) SaveAsTxt( fname ) end,
			nil, "Save", "Cancel" )
	end ):SetIcon( "icon16/disk.png" )

	m_file:AddOption( "Load from data…", function()
		-- Browse data/zdev/materials/ for .txt and .vmt files
		file.CreateDir( SAVE_DIR )
		local txt_files = file.Find( SAVE_DIR .. "*.txt", "DATA" ) or {}
		local vmt_files = file.Find( SAVE_DIR .. "*.vmt", "DATA" ) or {}

		if #txt_files == 0 and #vmt_files == 0 then
			Derma_Message( "No saved files found in data/" .. SAVE_DIR, "Load" )
			return
		end

		local dm = DermaMenu()
		for _, f in ipairs( txt_files ) do
			dm:AddOption( f, function()
				local content = file.Read( SAVE_DIR .. f, "DATA" )
				if content then
					EDITOR.SelectedFile = SAVE_DIR .. f
					EDITOR.MaterialPath = ""
					if IsValid( selected_lbl ) then selected_lbl:SetText( "  data/" .. SAVE_DIR .. f ) end
					SyncFromVMT( content )
					EDITOR.IsModified = false
					UpdateTitle()
				end
			end ):SetIcon( "icon16/page_white_text.png" )
		end
		for _, f in ipairs( vmt_files ) do
			dm:AddOption( f, function()
				local content = file.Read( SAVE_DIR .. f, "DATA" )
				if content then
					EDITOR.SelectedFile = SAVE_DIR .. f
					EDITOR.MaterialPath = string.StripExtension( f )
					if IsValid( selected_lbl ) then selected_lbl:SetText( "  data/" .. SAVE_DIR .. f ) end
					SyncFromVMT( content )
					EDITOR.IsModified = false
					UpdateTitle()
				end
			end ):SetIcon( "icon16/page_code.png" )
		end
		dm:Open()
	end ):SetIcon( "icon16/folder_page.png" )

	m_file:AddSpacer()
	m_file:AddOption( "Close", function() menu:Close() end ):SetIcon( "icon16/cross.png" )

	-- View menu
	local m_view = mb:AddMenu( "View" )

	m_view:AddOption( "Raw VMT Editor", function()
		if IsValid( raw_vmt_frame ) then
			raw_vmt_frame:SetVisible( not raw_vmt_frame:IsVisible() )
			if raw_vmt_frame:IsVisible() then raw_vmt_frame:MakePopup() end
			return
		end

		raw_vmt_frame = ZDEV.VGUI.CreateFrame( 500, 460, "Raw VMT Editor" )
		raw_vmt_frame:SetPos( menu:GetX() + menu:GetWide() + 8, menu:GetY() )
		raw_vmt_frame:MakePopup()
		raw_vmt_frame:SetDeleteOnClose( false )

		local te = vgui.Create( "DTextEntry", raw_vmt_frame )
		te:Dock( FILL ) ; te:DockMargin( 4, 4, 4, 4 )
		te:SetMultiline( true )
		te:SetVerticalScrollbarEnabled( true )
		te:SetFont( "BudgetLabel" )
		te:SetValue( EDITOR.RawVMT )
		te:SetUpdateOnType( true )
		raw_vmt_frame.te = te

		te.OnValueChange = function( self, new_text )
			if EDITOR.SyncLock then return end
			EDITOR.RawVMT = new_text
			EDITOR.IsModified = true

			-- Re-parse and rebuild property table
			EDITOR.SyncLock = true
			local parsed = ParseVMT( new_text )
			EDITOR.Shader     = parsed.shader
			EDITOR.Properties = parsed.properties
			if IsValid( shader_entry ) then shader_entry:SetValue( EDITOR.Shader ) end
			RebuildPropertyTable()
			UpdateTitle()
			EDITOR.SyncLock = false
		end

		-- Bottom buttons
		local btn_bar = vgui.Create( "DPanel", raw_vmt_frame )
		btn_bar:Dock( BOTTOM ) ; btn_bar:SetTall( 32 ) ; btn_bar:DockMargin( 4, 0, 4, 4 )
		btn_bar.Paint = function() end

		local btn_save = vgui.Create( "DButton", btn_bar )
		btn_save:Dock( LEFT ) ; btn_save:SetWide( 100 ) ; btn_save:SetText( "Save .txt…" )
		btn_save:SetIcon( "icon16/disk.png" )
		btn_save.DoClick = function()
			local default_name = "material"
			if EDITOR.SelectedFile ~= "" then
				default_name = string.StripExtension( string.GetFileFromFilename( EDITOR.SelectedFile ) )
			end
			Derma_StringRequest( "Save", "Filename:", default_name .. ".txt",
				function( fname ) SaveAsTxt( fname ) end, nil, "Save", "Cancel" )
		end

		local btn_load = vgui.Create( "DButton", btn_bar )
		btn_load:Dock( LEFT ) ; btn_load:SetWide( 100 ) ; btn_load:DockMargin( 4, 0, 0, 0 )
		btn_load:SetText( "Load .txt…" ) ; btn_load:SetIcon( "icon16/folder_page.png" )
		btn_load.DoClick = function()
			file.CreateDir( SAVE_DIR )
			local files = file.Find( SAVE_DIR .. "*", "DATA" ) or {}
			if #files == 0 then Derma_Message( "No files found.", "Load" ) ; return end
			local dm = DermaMenu()
			for _, f in ipairs( files ) do
				dm:AddOption( f, function()
					local c = file.Read( SAVE_DIR .. f, "DATA" )
					if c then te:SetValue( c ) end
				end ):SetIcon( "icon16/page_white_text.png" )
			end
			dm:Open()
		end

		local btn_close = vgui.Create( "DButton", btn_bar )
		btn_close:Dock( RIGHT ) ; btn_close:SetWide( 80 ) ; btn_close:SetText( "Close" )
		btn_close:SetIcon( "icon16/cross.png" )
		btn_close.DoClick = function() raw_vmt_frame:SetVisible( false ) end
	end ):SetIcon( "icon16/page_code.png" )

	m_view:AddOption( "Refresh Preview", function()
		if EDITOR.MaterialPath ~= "" and IsValid( preview_img ) then
			local ok, mat = pcall( Material, EDITOR.MaterialPath )
			if ok then preview_img:SetPreviewMaterial( mat ) end
		end
	end ):SetIcon( "icon16/picture.png" )


	-- ─── TAB SHEET ───────────────────────────────────────────────────────────
	sheet = vgui.Create( "DPropertySheet", menu )
	sheet:Dock( FILL )
	sheet:DockMargin( 4, 2, 4, 4 )


	-- ═══ INSPECT TAB ═════════════════════════════════════════════════════════
	local inspect_pnl = vgui.Create( "DPanel", sheet )
	inspect_pnl:SetPaintBackground( false )
	inspect_sheet = sheet:AddSheet( "INSPECT", inspect_pnl, "icon16/zoom.png" )

	-- ─── LEFT PANEL — File Tree ──────────────────────────────────────────────
	local left_pnl = vgui.Create( "DPanel", inspect_pnl )
	left_pnl:Dock( LEFT )
	left_pnl:SetWide( math.Clamp( menu_w * 0.30, 220, 340 ) )
	left_pnl:DockMargin( 4, 4, 0, 4 )
	left_pnl.Paint = function( s, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, CLR_PANEL_L )
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 1, CLR_ACCENT )
	end

	-- Tree label
	local tree_lbl = vgui.Create( "DLabel", left_pnl )
	tree_lbl:Dock( TOP ) ; tree_lbl:SetTall( 18 ) ; tree_lbl:DockMargin( 6, 4, 4, 2 )
	tree_lbl:SetText( "Materials (.vmt / .png)" ) ; tree_lbl:SetFont( "DermaDefaultBold" )

	-- File tree
	local tree = vgui.Create( "DTree", left_pnl )
	tree:Dock( FILL ) ; tree:DockMargin( 4, 2, 4, 4 )

	-- Game materials root
	local root_game = tree:AddNode( "Garry's Mod", "icon16/controller.png" )
	MakeLazyFolderNode( root_game, "materials", "GAME" )

	-- Addon materials root
	local root_addons = tree:AddNode( "Addons", "icon16/plugin.png" )
	MakeLazyFolderNode( root_addons, "materials", "THIRDPARTY" )

	-- Saved materials root (data directory)
	local root_saved = tree:AddNode( "Saved (data/)", "icon16/folder_user.png" )
	root_saved.DoPopulate = function( self )
		if self.m_bZPopulated then return end
		self.m_bZPopulated = true
		RemovePlaceholders( self )
		file.CreateDir( SAVE_DIR )
		local files = file.Find( SAVE_DIR .. "*", "DATA" ) or {}
		for _, f in ipairs( files ) do
			local ext = string.GetExtensionFromFilename( f ) or ""
			if ext == "txt" or ext == "vmt" then
				local child = self:AddNode( f, "icon16/page_white_text.png" )
				child.m_zFilePath   = SAVE_DIR .. f
				child.m_zSearchPath = "DATA"
				child.m_zIsFile     = true
				child.m_zExt        = "vmt"  -- treat .txt as VMT content too
			end
		end
	end
	WireLazyExpand( root_saved )

	-- Tree selection handler
	tree.OnNodeSelected = function( self, node )
		if not node.m_zIsFile then return end

		local fp   = node.m_zFilePath or ""
		local sp   = node.m_zSearchPath or "GAME"
		local ext  = node.m_zExt or "vmt"

		LoadFromTree( fp, sp, ext )
	end

	tree_panel = tree  -- store ref


	-- ─── RIGHT PANEL — Preview + Properties ──────────────────────────────────
	local right_pnl = vgui.Create( "DPanel", inspect_pnl )
	right_pnl:Dock( FILL )
	right_pnl:DockMargin( 4, 4, 4, 4 )
	right_pnl.Paint = function( s, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, CLR_PANEL_R )
	end

	-- Selected file label (top of right panel)
	selected_lbl = vgui.Create( "DLabel", right_pnl )
	selected_lbl:Dock( TOP ) ; selected_lbl:SetTall( 20 ) ; selected_lbl:DockMargin( 4, 4, 4, 0 )
	selected_lbl:SetText( "  (no file selected)" ) ; selected_lbl:SetFont( "DermaDefault" )
	selected_lbl:SetTextColor( CLR_LBL )
	selected_lbl.Paint = function( s, w, h )
		draw.RoundedBox( 3, 0, 0, w, h, CLR_SEL_BG )
	end

	-- Material preview (square 1:1 area, entire texture always visible)
	preview_img = CreatePreviewPanel( right_pnl )
	preview_img:Dock( TOP )
	preview_img:SetTall( math.Clamp( menu_h * 0.38, 200, 380 ) )
	preview_img:DockMargin( 4, 4, 4, 4 )
	preview_img.m_zEmptyText = "no material selected"

	-- Shader section
	local shader_pnl = vgui.Create( "DPanel", right_pnl )
	shader_pnl:Dock( TOP ) ; shader_pnl:SetTall( 28 ) ; shader_pnl:DockMargin( 4, 0, 4, 2 )
	shader_pnl.Paint = function( s, w, h )
		draw.RoundedBox( 3, 0, 0, w, h, CLR_FIELD_BG )
	end

	local shader_lbl = vgui.Create( "DLabel", shader_pnl )
	shader_lbl:Dock( LEFT ) ; shader_lbl:SetWide( 60 ) ; shader_lbl:DockMargin( 6, 0, 0, 0 )
	shader_lbl:SetText( "Shader:" ) ; shader_lbl:SetFont( "DermaDefaultBold" )

	shader_entry = vgui.Create( "DTextEntry", shader_pnl )
	shader_entry:Dock( FILL ) ; shader_entry:DockMargin( 4, 3, 4, 3 )
	shader_entry:SetFont( "DermaDefault" )
	shader_entry:SetValue( "" )
	shader_entry.OnValueChange = function( self, val )
		if EDITOR.SyncLock then return end
		EDITOR.Shader = val
		EDITOR.IsModified = true
		EDITOR.SyncLock = true
		EDITOR.RawVMT = GenerateVMT( EDITOR.Shader, EDITOR.Properties )
		if IsValid( raw_vmt_frame ) and raw_vmt_frame.te then
			raw_vmt_frame.te:SetValue( EDITOR.RawVMT )
		end
		UpdateTitle()
		EDITOR.SyncLock = false
	end

	-- Property table header label
	local prop_hdr_lbl = vgui.Create( "DLabel", right_pnl )
	prop_hdr_lbl:Dock( TOP ) ; prop_hdr_lbl:SetTall( 18 ) ; prop_hdr_lbl:DockMargin( 6, 4, 4, 2 )
	prop_hdr_lbl:SetText( "VMT Properties" ) ; prop_hdr_lbl:SetFont( "DermaDefaultBold" )

	-- Property table (scrollable)
	prop_scroll = vgui.Create( "DScrollPanel", right_pnl )
	prop_scroll:Dock( FILL ) ; prop_scroll:DockMargin( 4, 0, 4, 4 )
	prop_scroll.Paint = function( s, w, h )
		draw.RoundedBox( 3, 0, 0, w, h, CLR_INSET )
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 1, CLR_INSET_OUT )
	end


	-- ─── BOTTOM BAR (INSPECT) ────────────────────────────────────────────────
	local bottom_bar = vgui.Create( "DPanel", inspect_pnl )
	bottom_bar:Dock( BOTTOM ) ; bottom_bar:SetTall( 36 ) ; bottom_bar:DockMargin( 4, 0, 4, 4 )
	bottom_bar.Paint = function( s, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, CLR_BAR )
	end

	local btn_save = ZDEV.VGUI.CreateButton( bottom_bar, 110, 30, "SAVE .TXT", "raj", Color(100,220,100), function()
		local default_name = "material"
		if EDITOR.SelectedFile ~= "" then
			default_name = string.StripExtension( string.GetFileFromFilename( EDITOR.SelectedFile ) )
		end
		Derma_StringRequest( "Save Material", "Filename (saved to data/" .. SAVE_DIR .. "):",
			default_name .. ".txt",
			function( fname ) SaveAsTxt( fname ) end,
			nil, "Save", "Cancel" )
	end )
	btn_save:Dock( LEFT ) ; btn_save:DockMargin( 4, 3, 4, 3 )

	local btn_add_prop = ZDEV.VGUI.CreateButton( bottom_bar, 110, 30, "ADD PROP", "raj", Color(100,180,255), function()
		Derma_StringRequest( "Add Property", 'Property key (e.g. $basetexture):', "$",
			function( key )
				Derma_StringRequest( "Add Property", "Value for " .. key .. ":", "",
					function( val )
						table.insert( EDITOR.Properties, { key = key, value = val } )
						EDITOR.RawVMT = GenerateVMT( EDITOR.Shader, EDITOR.Properties )
						EDITOR.IsModified = true
						RebuildPropertyTable()
						if IsValid( raw_vmt_frame ) and raw_vmt_frame.te then
							raw_vmt_frame.te:SetValue( EDITOR.RawVMT )
						end
						UpdateTitle()
					end, nil, "Add", "Cancel" )
			end, nil, "Next", "Cancel" )
	end )
	btn_add_prop:Dock( LEFT ) ; btn_add_prop:DockMargin( 0, 3, 4, 3 )

	local btn_reload = ZDEV.VGUI.CreateButton( bottom_bar, 90, 30, "RELOAD", "raj", Color(255,200,100), function()
		if EDITOR.SelectedFile ~= "" then
			local ext = string.GetExtensionFromFilename( EDITOR.SelectedFile ) or "vmt"
			if ext == "txt" then ext = "vmt" end
			LoadFromTree( EDITOR.SelectedFile, EDITOR.SearchPath, ext )
			zdev.log( "I", "Reloaded: " .. EDITOR.SelectedFile )
		end
	end )
	btn_reload:Dock( LEFT ) ; btn_reload:DockMargin( 0, 3, 4, 3 )

	local btn_close = ZDEV.VGUI.CreateButton( bottom_bar, 80, 30, "CLOSE", "raj", Color(255,100,100), function()
		if IsValid( raw_vmt_frame ) then raw_vmt_frame:Remove() end
		menu:Close()
	end )
	btn_close:Dock( RIGHT ) ; btn_close:DockMargin( 4, 3, 4, 3 )


	-- ═══ CREATE TAB ══════════════════════════════════════════════════════════
	-- Dashboard for building a material from scratch with CreateMaterial().
	-- CreateMaterial caches by name and never updates an existing one, so each
	-- rebuild mints a fresh counter-suffixed name (cleaned up on map shutdown).
	local create_pnl = vgui.Create( "DPanel", sheet )
	create_pnl:SetPaintBackground( false )

	local SHADER_LIST = {
		"UnlitGeneric", "VertexLitGeneric", "LightmappedGeneric",
		"Refract", "Water", "WorldVertexTransition",
		"Sprite", "Cable", "Modulate", "Wireframe",
	}

	local QUICK_FLAGS = {
		"$model", "$translucent", "$alphatest", "$vertexcolor",
		"$vertexalpha", "$additive", "$nocull", "$ignorez",
		"$selfillum", "$phong", "$halflambert", "$nofog",
	}

	local PARAM_PRESETS = {
		{ key = "$basetexture",          value = "models/debug/debugwhite" },
		{ key = "$basetexture2",         value = "" },
		{ key = "$bumpmap",              value = "dev/flat_normal" },
		{ key = "$envmap",               value = "env_cubemap" },
		{ key = "$envmaptint",           value = "[1 1 1]" },
		{ key = "$envmapmask",           value = "" },
		{ key = "$color",                value = "[1 1 1]" },
		{ key = "$color2",               value = "[1 1 1]" },
		{ key = "$alpha",                value = "1" },
		{ key = "$surfaceprop",          value = "default" },
		{ key = "$detail",               value = "" },
		{ key = "$detailscale",          value = "4" },
		{ key = "$detailblendfactor",    value = "1" },
		{ key = "$phongexponent",        value = "60" },
		{ key = "$phongboost",           value = "1" },
		{ key = "$phongfresnelranges",   value = "[0.5 0.8 1]" },
		{ key = "$selfillummask",        value = "" },
		{ key = "$selfillumtint",        value = "[1 1 1]" },
		{ key = "$refractamount",        value = "0.2" },
		{ key = "$refracttint",          value = "[1 1 1]" },
		{ key = "$basetexturetransform", value = "center .5 .5 scale 1 1 rotate 0 translate 0 0" },
	}

	local PREVIEW_MODELS = {
		{ label = "Cube",   mdl = "models/hunter/blocks/cube075x075x075.mdl" },
		{ label = "Sphere", mdl = "models/hunter/misc/sphere075x075.mdl" },
		{ label = "Barrel", mdl = "models/props_c17/oildrum001.mdl" },
	}

	local CREATE = {
		BaseName    = "my_material",
		Shader      = "UnlitGeneric",
		Params      = {
			{ key = "$basetexture", value = "models/debug/debugwhite" },
			{ key = "$vertexcolor", value = "1" },
		},
		Counter     = 0,
		Mat         = nil,
		MatName     = "",
		PreviewMode = "2d",
		SyncLock    = false,
	}

	-- Forward refs (populated below; closures capture the slots — lua-closures)
	local create_preview, model_preview, create_status, vmt_te, c_param_scroll
	local c_name_te, c_shader_combo
	local flag_checks = {}
	local create_rows = {}
	local BuildCreateMaterial, RebuildCreateRows, SetPreviewModel

	-- ── Param helpers ────────────────────────────────────────────────────────
	local function FindParam( key )
		key = string.lower( key )
		for i, p in ipairs( CREATE.Params ) do
			if string.lower( p.key ) == key then return i, p end
		end
	end

	local function SetParam( key, value )
		local _, p = FindParam( key )
		if p then p.value = value else table.insert( CREATE.Params, { key = key, value = value } ) end
	end

	local function RemoveParam( key )
		local i = FindParam( key )
		if i then table.remove( CREATE.Params, i ) end
	end

	local function RefreshFlagChecks()
		CREATE.SyncLock = true
		for key, chk in pairs( flag_checks ) do
			if IsValid( chk ) then
				local _, p = FindParam( key )
				chk:SetChecked( p ~= nil and p.value ~= "0" and p.value ~= "" )
			end
		end
		CREATE.SyncLock = false
	end

	-- ── LEFT COLUMN — shader / name / flags / params ─────────────────────────
	local c_left = vgui.Create( "DPanel", create_pnl )
	c_left:Dock( LEFT )
	c_left:SetWide( math.Clamp( menu_w * 0.46, 380, 560 ) )
	c_left:DockMargin( 4, 4, 0, 4 )
	c_left.Paint = function( s, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, CLR_PANEL_L )
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 1, CLR_ACCENT )
	end

	-- Name row
	local name_row = vgui.Create( "DPanel", c_left )
	name_row:Dock( TOP ) ; name_row:SetTall( 28 ) ; name_row:DockMargin( 6, 6, 6, 2 )
	name_row.Paint = function( s, w, h )
		draw.RoundedBox( 3, 0, 0, w, h, CLR_FIELD_BG )
	end

	local name_lbl = vgui.Create( "DLabel", name_row )
	name_lbl:Dock( LEFT ) ; name_lbl:SetWide( 60 ) ; name_lbl:DockMargin( 6, 0, 0, 0 )
	name_lbl:SetText( "Name:" ) ; name_lbl:SetFont( "DermaDefaultBold" )

	c_name_te = vgui.Create( "DTextEntry", name_row )
	c_name_te:Dock( FILL ) ; c_name_te:DockMargin( 4, 3, 4, 3 )
	c_name_te:SetValue( CREATE.BaseName )
	c_name_te.OnValueChange = function( self, val )
		CREATE.BaseName = val
	end

	-- Shader row
	local shader_row = vgui.Create( "DPanel", c_left )
	shader_row:Dock( TOP ) ; shader_row:SetTall( 28 ) ; shader_row:DockMargin( 6, 2, 6, 2 )
	shader_row.Paint = function( s, w, h )
		draw.RoundedBox( 3, 0, 0, w, h, CLR_FIELD_BG )
	end

	local c_shader_lbl = vgui.Create( "DLabel", shader_row )
	c_shader_lbl:Dock( LEFT ) ; c_shader_lbl:SetWide( 60 ) ; c_shader_lbl:DockMargin( 6, 0, 0, 0 )
	c_shader_lbl:SetText( "Shader:" ) ; c_shader_lbl:SetFont( "DermaDefaultBold" )

	c_shader_combo = vgui.Create( "DComboBox", shader_row )
	c_shader_combo:Dock( FILL ) ; c_shader_combo:DockMargin( 4, 3, 4, 3 )
	for _, s in ipairs( SHADER_LIST ) do c_shader_combo:AddChoice( s ) end
	c_shader_combo:SetValue( CREATE.Shader )
	c_shader_combo.OnSelect = function( _, _, value )
		CREATE.Shader = value
		BuildCreateMaterial()
	end

	-- Quick flags (each toggles a "$key" "1" param)
	local flags_lbl = vgui.Create( "DLabel", c_left )
	flags_lbl:Dock( TOP ) ; flags_lbl:SetTall( 16 ) ; flags_lbl:DockMargin( 8, 4, 6, 0 )
	flags_lbl:SetText( "Quick flags" ) ; flags_lbl:SetFont( "DermaDefaultBold" )

	local FLAG_ROW_H = 20
	local flags_pnl = vgui.Create( "DPanel", c_left )
	flags_pnl:Dock( TOP )
	flags_pnl:SetTall( math.ceil( #QUICK_FLAGS / 2 ) * FLAG_ROW_H + 4 )
	flags_pnl:DockMargin( 6, 0, 6, 2 )
	flags_pnl:SetPaintBackground( false )
	flags_pnl.m_zChecks = {}
	flags_pnl.PerformLayout = function( s, w, h )
		local colw = math.floor( w * 0.5 )
		for i, chk in ipairs( s.m_zChecks ) do
			local col = ( i - 1 ) % 2
			local row = math.floor( ( i - 1 ) / 2 )
			chk:SetPos( 4 + col * colw, row * FLAG_ROW_H + 2 )
			chk:SetSize( colw - 8, FLAG_ROW_H - 2 )
		end
	end

	for _, key in ipairs( QUICK_FLAGS ) do
		local chk = vgui.Create( "DCheckBoxLabel", flags_pnl )
		chk:SetText( key )
		chk:SetTextColor( CLR_LBL )
		chk.OnChange = function( self, b )
			if CREATE.SyncLock then return end
			if b then SetParam( key, "1" ) else RemoveParam( key ) end
			RebuildCreateRows()
			BuildCreateMaterial()
		end
		flag_checks[ key ] = chk
		table.insert( flags_pnl.m_zChecks, chk )
	end

	-- Add-parameter bar
	local add_bar = vgui.Create( "DPanel", c_left )
	add_bar:Dock( TOP ) ; add_bar:SetTall( 28 ) ; add_bar:DockMargin( 6, 2, 6, 2 )
	add_bar:SetPaintBackground( false )

	local btn_custom = vgui.Create( "DButton", add_bar )
	btn_custom:Dock( RIGHT ) ; btn_custom:SetWide( 70 )
	btn_custom:SetText( "Custom…" )
	btn_custom.DoClick = function()
		Derma_StringRequest( "Add Parameter", 'Parameter key (e.g. $basetexture):', "$",
			function( key )
				key = string.Trim( key )
				if key == "" or key == "$" then return end
				Derma_StringRequest( "Add Parameter", "Value for " .. key .. ":", "",
					function( val )
						SetParam( key, val )
						RebuildCreateRows()
						BuildCreateMaterial()
					end, nil, "Add", "Cancel" )
			end, nil, "Next", "Cancel" )
	end

	local btn_add = vgui.Create( "DButton", add_bar )
	btn_add:Dock( RIGHT ) ; btn_add:SetWide( 50 ) ; btn_add:DockMargin( 0, 0, 4, 0 )
	btn_add:SetText( "Add" ) ; btn_add:SetIcon( "icon16/add.png" )

	local add_combo = vgui.Create( "DComboBox", add_bar )
	add_combo:Dock( FILL ) ; add_combo:DockMargin( 0, 2, 4, 2 )
	for _, preset in ipairs( PARAM_PRESETS ) do add_combo:AddChoice( preset.key ) end
	add_combo:SetValue( "$basetexture" )

	btn_add.DoClick = function()
		local key = string.Trim( add_combo:GetValue() or "" )
		if key == "" then return end
		local default_val = ""
		for _, preset in ipairs( PARAM_PRESETS ) do
			if preset.key == key then default_val = preset.value break end
		end
		local _, existing = FindParam( key )
		if not existing then SetParam( key, default_val ) end
		RebuildCreateRows()
		BuildCreateMaterial()
	end

	-- Parameter list
	local c_params_lbl = vgui.Create( "DLabel", c_left )
	c_params_lbl:Dock( TOP ) ; c_params_lbl:SetTall( 16 ) ; c_params_lbl:DockMargin( 8, 2, 6, 0 )
	c_params_lbl:SetText( "Parameters" ) ; c_params_lbl:SetFont( "DermaDefaultBold" )

	c_param_scroll = vgui.Create( "DScrollPanel", c_left )
	c_param_scroll:Dock( FILL ) ; c_param_scroll:DockMargin( 6, 2, 6, 6 )
	c_param_scroll.Paint = function( s, w, h )
		draw.RoundedBox( 3, 0, 0, w, h, CLR_INSET )
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 1, CLR_INSET_OUT )
	end

	RebuildCreateRows = function()
		if not IsValid( c_param_scroll ) then return end

		for _, row in ipairs( create_rows ) do
			if IsValid( row ) then row:Remove() end
		end
		create_rows = {}

		-- Column header
		local hdr = vgui.Create( "DPanel", c_param_scroll )
		hdr:Dock( TOP ) ; hdr:SetTall( 22 ) ; hdr:DockMargin( 0, 0, 0, 1 )
		hdr.Paint = function( s, w, h )
			surface.SetDrawColor( CLR_HEADER )
			surface.DrawRect( 0, 0, w, h )
		end
		local function hdr_lbl( text, dock, wide )
			local l = vgui.Create( "DLabel", hdr )
			l:Dock( dock ) ; if wide then l:SetWide( wide ) end
			l:SetText( "  " .. text ) ; l:SetFont( "DermaDefaultBold" )
		end
		hdr_lbl( "Parameter", LEFT, 150 )
		hdr_lbl( "Value",     FILL )
		table.insert( create_rows, hdr )

		for i, prop in ipairs( CREATE.Params ) do
			local row = vgui.Create( "DPanel", c_param_scroll )
			row:Dock( TOP ) ; row:SetTall( 24 ) ; row:DockMargin( 0, 0, 0, 1 )
			local even = ( i % 2 == 0 )
			row.Paint = function( s, w, h )
				surface.SetDrawColor( even and CLR_ROW_EVEN or CLR_ROW_ODD )
				surface.DrawRect( 0, 0, w, h )
			end

			local key_lbl = vgui.Create( "DLabel", row )
			key_lbl:Dock( LEFT ) ; key_lbl:SetWide( 150 )
			key_lbl:SetText( "  " .. prop.key ) ; key_lbl:SetFont( "DermaDefault" )
			key_lbl:SetTextColor( CLR_KEY_TEXT )

			-- Remove button
			local btn_del = vgui.Create( "DButton", row )
			btn_del:Dock( RIGHT ) ; btn_del:SetWide( 24 )
			btn_del:SetText( "" ) ; btn_del:SetIcon( "icon16/delete.png" )
			btn_del:SetTooltip( "Remove parameter" )
			btn_del.DoClick = function()
				table.remove( CREATE.Params, i )
				RebuildCreateRows()
				BuildCreateMaterial()
			end

			-- Texture browse button (texture params only)
			if IsTextureParam( prop.key ) then
				local btn_tex = vgui.Create( "DButton", row )
				btn_tex:Dock( RIGHT ) ; btn_tex:SetWide( 26 )
				btn_tex:SetText( "" ) ; btn_tex:SetIcon( "icon16/image.png" )
				btn_tex:SetTooltip( "Browse / preview texture" )
				btn_tex.DoClick = function()
					OpenTextureReplacer( prop.value, function( new_path )
						prop.value = new_path
						RebuildCreateRows()
						BuildCreateMaterial()
					end )
				end
			end

			-- Value entry — rebuilds on Enter / focus loss (NOT per keystroke,
			-- since every rebuild mints a new cached material)
			local val_te = vgui.Create( "DTextEntry", row )
			val_te:Dock( FILL ) ; val_te:DockMargin( 2, 2, 2, 2 )
			val_te:SetValue( prop.value )
			val_te:SetFont( "DermaDefault" )
			val_te.OnEnter = function( self )
				local v = self:GetValue()
				if v == prop.value then return end
				prop.value = v
				BuildCreateMaterial()
				RefreshFlagChecks()
			end
			local origLoseFocus = val_te.OnLoseFocus  -- captured before override
			val_te.OnLoseFocus = function( self )
				if origLoseFocus then origLoseFocus( self ) end
				local v = self:GetValue()
				if v ~= prop.value then
					prop.value = v
					BuildCreateMaterial()
					RefreshFlagChecks()
				end
			end

			table.insert( create_rows, row )
		end

		RefreshFlagChecks()
	end

	-- ── RIGHT COLUMN — preview / status / generated VMT / actions ───────────
	local c_right = vgui.Create( "DPanel", create_pnl )
	c_right:Dock( FILL )
	c_right:DockMargin( 4, 4, 4, 4 )
	c_right.Paint = function( s, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, CLR_PANEL_R )
	end

	-- Top bar: preview mode toggle + model picker + status
	local c_top_bar = vgui.Create( "DPanel", c_right )
	c_top_bar:Dock( TOP ) ; c_top_bar:SetTall( 26 ) ; c_top_bar:DockMargin( 6, 6, 6, 2 )
	c_top_bar:SetPaintBackground( false )

	local function SetPreviewMode( mode )
		CREATE.PreviewMode = mode
		if IsValid( create_preview ) then create_preview:SetVisible( mode == "2d" ) end
		if IsValid( model_preview )  then model_preview:SetVisible(  mode == "3d" ) end
	end

	local btn_2d = vgui.Create( "DButton", c_top_bar )
	btn_2d:Dock( LEFT ) ; btn_2d:SetWide( 40 ) ; btn_2d:SetText( "2D" )
	btn_2d.DoClick = function() SetPreviewMode( "2d" ) end

	local btn_3d = vgui.Create( "DButton", c_top_bar )
	btn_3d:Dock( LEFT ) ; btn_3d:SetWide( 40 ) ; btn_3d:DockMargin( 2, 0, 0, 0 )
	btn_3d:SetText( "3D" )
	btn_3d.DoClick = function() SetPreviewMode( "3d" ) end

	local model_combo = vgui.Create( "DComboBox", c_top_bar )
	model_combo:Dock( LEFT ) ; model_combo:SetWide( 110 ) ; model_combo:DockMargin( 6, 2, 0, 2 )
	for _, m in ipairs( PREVIEW_MODELS ) do model_combo:AddChoice( m.label, m.mdl ) end
	model_combo:SetValue( "Cube" )
	model_combo.OnSelect = function( _, _, _, data )
		if data then SetPreviewModel( data ) end
	end

	create_status = vgui.Create( "DLabel", c_top_bar )
	create_status:Dock( FILL ) ; create_status:DockMargin( 8, 0, 0, 0 )
	create_status:SetText( "" ) ; create_status:SetFont( "DermaDefault" )
	create_status:SetTextColor( CLR_LBL )

	-- Bottom action bar (created bottom-up: bar, then VMT box above it)
	local c_btn_bar = vgui.Create( "DPanel", c_right )
	c_btn_bar:Dock( BOTTOM ) ; c_btn_bar:SetTall( 36 ) ; c_btn_bar:DockMargin( 6, 2, 6, 6 )
	c_btn_bar.Paint = function( s, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, CLR_BAR )
	end

	-- Generated VMT (read-only, live)
	vmt_te = vgui.Create( "DTextEntry", c_right )
	vmt_te:Dock( BOTTOM ) ; vmt_te:SetTall( 130 ) ; vmt_te:DockMargin( 6, 0, 6, 2 )
	vmt_te:SetMultiline( true )
	vmt_te:SetVerticalScrollbarEnabled( true )
	vmt_te:SetEditable( false )
	vmt_te:SetFont( "BudgetLabel" )

	local vmt_lbl = vgui.Create( "DLabel", c_right )
	vmt_lbl:Dock( BOTTOM ) ; vmt_lbl:SetTall( 16 ) ; vmt_lbl:DockMargin( 8, 0, 6, 0 )
	vmt_lbl:SetText( "Generated VMT" ) ; vmt_lbl:SetFont( "DermaDefaultBold" )

	-- Preview area (2D square-fit panel + 3D model panel, toggled)
	local preview_holder = vgui.Create( "DPanel", c_right )
	preview_holder:Dock( FILL ) ; preview_holder:DockMargin( 6, 2, 6, 2 )
	preview_holder:SetPaintBackground( false )

	create_preview = CreatePreviewPanel( preview_holder )
	create_preview:Dock( FILL )
	create_preview.m_zEmptyText = "material not built"

	-- plain DPanel holder, NOT a scroll panel (DModelPanel scissor rect breaks
	-- inside DScrollPanel — gmod-vgui-layout Rule 1)
	model_preview = vgui.Create( "DModelPanel", preview_holder )
	model_preview:Dock( FILL )
	model_preview:SetVisible( false )

	SetPreviewModel = function( mdl )
		if not IsValid( model_preview ) then return end
		model_preview:SetModel( mdl )
		local ent = model_preview.Entity
		if not IsValid( ent ) then return end
		local mn, mx = ent:GetRenderBounds()
		local center = ( mn + mx ) * 0.5
		local size = ( mx - mn ):Length()
		model_preview:SetFOV( 40 )
		model_preview:SetCamPos( center + Vector( size * 0.9, size * 0.9, size * 0.55 ) )
		model_preview:SetLookAt( center )
		if CREATE.MatName ~= "" then ent:SetMaterial( "!" .. CREATE.MatName ) end
	end

	-- ── Build / rebuild the live material ────────────────────────────────────
	BuildCreateMaterial = function()
		CREATE.Counter = CREATE.Counter + 1
		local base = CREATE.BaseName
		if base == "" then base = "preview" end
		base = string.lower( string.gsub( base, "[^%w_/]", "_" ) )
		local name = "zdev_matlab/" .. base .. "_" .. CREATE.Counter

		local data = {}
		for _, p in ipairs( CREATE.Params ) do
			local k = string.Trim( p.key or "" )
			if k ~= "" then
				local v = p.value or ""
				if IsTextureParam( k ) and v ~= "" then v = ResolveTexturePath( v ) end
				data[ k ] = v
			end
		end

		local ok, mat = pcall( CreateMaterial, name, CREATE.Shader, data )
		if ok and mat and not mat:IsError() then
			CREATE.Mat     = mat
			CREATE.MatName = name
			if IsValid( create_status ) then
				create_status:SetText( "!" .. name .. "  —  " .. CREATE.Shader )
				create_status:SetTextColor( CLR_OK )
			end
		else
			CREATE.Mat     = nil
			CREATE.MatName = ""
			if IsValid( create_status ) then
				create_status:SetText( "CreateMaterial failed" .. ( isstring( mat ) and ( ": " .. mat ) or "" ) )
				create_status:SetTextColor( CLR_ERR )
			end
		end

		if IsValid( create_preview ) then create_preview:SetPreviewMaterial( CREATE.Mat ) end
		if IsValid( model_preview ) and IsValid( model_preview.Entity ) then
			model_preview.Entity:SetMaterial( CREATE.Mat and ( "!" .. name ) or "" )
		end
		if IsValid( vmt_te ) then vmt_te:SetValue( GenerateVMT( CREATE.Shader, CREATE.Params ) ) end
	end

	-- ── Action buttons ───────────────────────────────────────────────────────
	local c_btn_build = ZDEV.VGUI.CreateButton( c_btn_bar, 100, 30, "REBUILD", "raj", Color(100,220,100), function()
		BuildCreateMaterial()
	end )
	c_btn_build:Dock( LEFT ) ; c_btn_build:DockMargin( 4, 3, 4, 3 )

	local c_btn_send = ZDEV.VGUI.CreateButton( c_btn_bar, 130, 30, "SEND TO INSPECT", "raj", Color(100,180,255), function()
		local vmt = GenerateVMT( CREATE.Shader, CREATE.Params )
		EDITOR.SelectedFile = ""
		EDITOR.MaterialPath = ""
		SyncFromVMT( vmt )
		EDITOR.IsModified = true
		if IsValid( selected_lbl ) then
			selected_lbl:SetText( "  (from CREATE: " .. ( CREATE.MatName ~= "" and CREATE.MatName or "unbuilt" ) .. ")" )
		end
		if IsValid( preview_img ) then preview_img:SetPreviewMaterial( CREATE.Mat ) end
		UpdateTitle()
		sheet:SetActiveTab( inspect_sheet.Tab )
	end )
	c_btn_send:Dock( LEFT ) ; c_btn_send:DockMargin( 0, 3, 4, 3 )

	local c_btn_save = ZDEV.VGUI.CreateButton( c_btn_bar, 100, 30, "SAVE .TXT", "raj", Color(255,200,100), function()
		Derma_StringRequest( "Save Material", "Filename (saved to data/" .. SAVE_DIR .. "):",
			CREATE.BaseName .. ".txt",
			function( fname ) SaveTextAs( fname, GenerateVMT( CREATE.Shader, CREATE.Params ) ) end,
			nil, "Save", "Cancel" )
	end )
	c_btn_save:Dock( LEFT ) ; c_btn_save:DockMargin( 0, 3, 4, 3 )

	local c_btn_reset = ZDEV.VGUI.CreateButton( c_btn_bar, 90, 30, "RESET", "raj", Color(255,100,100), function()
		CREATE.BaseName = "my_material"
		CREATE.Shader   = "UnlitGeneric"
		CREATE.Params   = {
			{ key = "$basetexture", value = "models/debug/debugwhite" },
			{ key = "$vertexcolor", value = "1" },
		}
		if IsValid( c_name_te ) then c_name_te:SetValue( CREATE.BaseName ) end
		if IsValid( c_shader_combo ) then c_shader_combo:SetValue( CREATE.Shader ) end
		RebuildCreateRows()
		BuildCreateMaterial()
	end )
	c_btn_reset:Dock( RIGHT ) ; c_btn_reset:DockMargin( 4, 3, 4, 3 )

	sheet:AddSheet( "CREATE", create_pnl, "icon16/wand.png" )

	-- Initial CREATE state
	RebuildCreateRows()
	SetPreviewModel( PREVIEW_MODELS[1].mdl )
	SetPreviewMode( "2d" )
	BuildCreateMaterial()


	-- ─── Cleanup ─────────────────────────────────────────────────────────────
	menu.OnClose = function()
		if IsValid( raw_vmt_frame ) then raw_vmt_frame:Remove() end
	end

	-- If an initial material was passed (e.g. from particle editor)
	if arg and arg[1] and arg[1] ~= "" then
		local init_path = arg[1]
		-- Try loading as a material path
		EDITOR.MaterialPath = init_path
		EDITOR.SelectedFile = "materials/" .. init_path .. ".vmt"
		if IsValid( selected_lbl ) then selected_lbl:SetText( "  " .. EDITOR.SelectedFile ) end

		local ok, mat = pcall( Material, init_path )
		if ok and mat and not mat:IsError() then
			if IsValid( preview_img ) then preview_img:SetPreviewMaterial( mat ) end
			local kv_ok, kv = pcall( function() return mat:GetKeyValues() end )
			if kv_ok and kv then
				local text = util.TableToKeyValues( kv )
				SyncFromVMT( text )
			end
		end
		EDITOR.IsModified = false
		UpdateTitle()
	end

	return menu
end

-- ─── Console commands ────────────────────────────────────────────────────────
ZDEV.CMDS.Register( "zdev_menu_dev_mat", ZDEV.VGUI.Editor_Materials, { aliases = { "zd_menu_dev_mat" } } )

ZDEV.VGUI.AddToMainMenu( "zdev_menu_dev_mat" )

ZDEV.FILE.SetLoaded( _f )

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
		if line == "" then continue end

		-- opening brace
		if string.find( line, "{", 1, true ) then
			-- shader may be on the same line as the brace: "ShaderName" {
			if not found_shader then
				local s = string.match( line, '^"?([^"{]+)"?' )
				if s then result.shader = string.Trim( s ) end
				found_shader = true
			end
			depth = depth + 1
			continue
		end

		-- closing brace
		if string.find( line, "}", 1, true ) then
			depth = depth - 1
			continue
		end

		-- shader name (line before first brace)
		if not found_shader and depth == 0 then
			result.shader = string.gsub( line, '"', '' )
			found_shader = true
			continue
		end

		-- key-value at depth 1 only (skip Proxies etc.)
		if depth == 1 then
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

-- ─── Helper: add a dummy child so the DTree shows an expand arrow ────────────
local function AddExpandPlaceholder( node )
	local dummy = node:AddNode( "Loading...", "icon16/hourglass.png" )
	dummy.m_zDummy = true
	-- If the user somehow clicks the dummy itself, redirect to parent's populate
	dummy.DoClick = function( self )
		print("[ZDEV MatEdit] Dummy clicked — forcing parent populate")
		local parent = self:GetParentNode()
		if IsValid( parent ) and parent.DoPopulate then
			parent:DoPopulate()
			parent:SetExpanded( true )
		end
	end
	return dummy
end

-- ─── Helper: remove all dummy children before real population ────────────────
local function RemovePlaceholders( node )
	local children = node:GetChildNodes()
	print("[ZDEV MatEdit] RemovePlaceholders: " .. #children .. " children on node '" .. tostring(node:GetText()) .. "'")
	for _, child in ipairs( children ) do
		if IsValid( child ) and child.m_zDummy then
			print("[ZDEV MatEdit]   Removing dummy: " .. tostring(child:GetText()))
			child:Remove()
		end
	end
end

-- ─── File tree builder (lazy, .vmt + .png only) ─────────────────────────────
local function PopulateTreeNode( node, folder, searchPath )
	print("[ZDEV MatEdit] PopulateTreeNode called:")
	print("[ZDEV MatEdit]   node text  = " .. tostring(node:GetText()))
	print("[ZDEV MatEdit]   folder     = " .. tostring(folder))
	print("[ZDEV MatEdit]   searchPath = " .. tostring(searchPath))
	print("[ZDEV MatEdit]   already populated = " .. tostring(node.m_bZPopulated))

	if node.m_bZPopulated then
		print("[ZDEV MatEdit]   SKIPPING — already populated")
		return
	end
	node.m_bZPopulated = true

	-- Remove the "Loading..." placeholder(s)
	RemovePlaceholders( node )

	-- Sub-directories
	local files_raw, dirs = file.Find( folder .. "/*", searchPath )
	print("[ZDEV MatEdit]   file.Find('" .. folder .. "/*', '" .. searchPath .. "') => dirs=" .. tostring(dirs and #dirs or "nil") .. ", files=" .. tostring(files_raw and #files_raw or "nil"))

	for _, d in ipairs( dirs or {} ) do
		local child  = node:AddNode( d, "icon16/folder.png" )
		child.m_zFolder     = folder .. "/" .. d
		child.m_zSearchPath = searchPath
		-- Add placeholder so the expand arrow appears on this child too
		AddExpandPlaceholder( child )
		child.DoPopulate    = function( self )
			print("[ZDEV MatEdit] DoPopulate fired for: '" .. tostring(self:GetText()) .. "' folder='" .. tostring(self.m_zFolder) .. "'")
			PopulateTreeNode( self, self.m_zFolder, self.m_zSearchPath )
		end
	end
	print("[ZDEV MatEdit]   Added " .. #(dirs or {}) .. " subdirectories")

	-- .vmt files
	local vmt_files = file.Find( folder .. "/*.vmt", searchPath ) or {}
	for _, f in ipairs( vmt_files ) do
		local child = node:AddNode( f, "icon16/page_white_text.png" )
		child.m_zFilePath   = folder .. "/" .. f
		child.m_zSearchPath = searchPath
		child.m_zIsFile     = true
		child.m_zExt        = "vmt"
	end
	print("[ZDEV MatEdit]   Added " .. #vmt_files .. " .vmt files")

	-- .png files
	local png_files = file.Find( folder .. "/*.png", searchPath ) or {}
	for _, f in ipairs( png_files ) do
		local child = node:AddNode( f, "icon16/picture.png" )
		child.m_zFilePath   = folder .. "/" .. f
		child.m_zSearchPath = searchPath
		child.m_zIsFile     = true
		child.m_zExt        = "png"
	end
	print("[ZDEV MatEdit]   Added " .. #png_files .. " .png files")
	print("[ZDEV MatEdit]   Total children after populate: " .. #node:GetChildNodes())
end


-- ─────────────────────────────────────────────────────────────────────────────
--  Texture Replacement Popup
-- ─────────────────────────────────────────────────────────────────────────────
local function OpenTextureReplacer( current_vtf_path, onReplace )
	local frm = ZDEV.VGUI.CreateFrame( 480, 520, "Texture Preview / Replace" )
	frm:Center()
	frm:MakePopup()

	-- Preview image
	local preview = vgui.Create( "DImage", frm )
	preview:Dock( TOP )
	preview:SetTall( 200 )
	preview:DockMargin( 4, 4, 4, 4 )
	preview:SetKeepAspect( true )
	-- Attempt to render the texture (Material loads VTF via the path)
	local ok, mat = pcall( Material, current_vtf_path )
	if ok and mat and not mat:IsError() then
		preview:SetMaterial( mat )
	else
		preview:SetImage( "icon16/image.png" )
	end

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
		if ok2 and m2 and not m2:IsError() then
			preview:SetMaterial( m2 )
		end
	end

	-- Mini file tree for browsing
	local tree_lbl = vgui.Create( "DLabel", frm )
	tree_lbl:Dock( TOP ) ; tree_lbl:SetText( "Browse materials:" )
	tree_lbl:DockMargin( 4, 4, 4, 2 ) ; tree_lbl:SetFont( "DermaDefault" )

	local tree = vgui.Create( "DTree", frm )
	tree:Dock( FILL ) ; tree:DockMargin( 4, 0, 4, 4 )

	local root_game = tree:AddNode( "Game Materials", "icon16/folder.png" )
	root_game.m_zFolder     = "materials"
	root_game.m_zSearchPath = "GAME"
	AddExpandPlaceholder( root_game )
	root_game.DoPopulate    = function( self ) PopulateTreeNode( self, "materials", "GAME" ) end

	tree.OnNodeSelected = function( self, node )
		if not node.m_zIsFile then return end
		local fp = node.m_zFilePath or ""
		-- Strip "materials/" prefix and extension for VMT path
		local rel = string.gsub( fp, "^materials/", "" )
		rel = string.StripExtension( rel )
		path_te:SetValue( rel )
		local ok3, m3 = pcall( Material, rel )
		if ok3 and m3 and not m3:IsError() then
			preview:SetMaterial( m3 )
		end
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
			surface.SetDrawColor( 55, 60, 75, 255 )
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
				surface.SetDrawColor( even and Color(38,42,52) or Color(32,36,46) )
				surface.DrawRect( 0, 0, w, h )
			end

			-- Property name (label)
			local key_lbl = vgui.Create( "DLabel", row )
			key_lbl:Dock( LEFT ) ; key_lbl:SetWide( 160 )
			key_lbl:SetText( "  " .. prop.key ) ; key_lbl:SetFont( "DermaDefault" )
			key_lbl:SetTextColor( Color( 130, 200, 255 ) )

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
			if ok and mat and not mat:IsError() then
				preview_img:SetMaterial( mat )
			end
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
				preview_img:SetMaterial( mat )
			else
				preview_img:SetImage( "icon16/error.png" )
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

	-- Save current VMT text as .txt in data/zdev/materials/
	local function SaveAsTxt( filename )
		if not filename or filename == "" then return end
		if not string.EndsWith( filename, ".txt" ) then filename = filename .. ".txt" end
		file.CreateDir( SAVE_DIR )
		file.Write( SAVE_DIR .. filename, EDITOR.RawVMT )
		EDITOR.IsModified = false
		UpdateTitle()
		zdev.log( "S", "Saved material to: " .. SAVE_DIR .. filename )
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
		if IsValid( preview_img ) then preview_img:SetImage( "icon16/page_white.png" ) end
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
			if ok and mat and not mat:IsError() then
				preview_img:SetMaterial( mat )
			end
		end
	end ):SetIcon( "icon16/picture.png" )


	-- ─── LEFT PANEL — File Tree ──────────────────────────────────────────────
	local left_pnl = vgui.Create( "DPanel", menu )
	left_pnl:Dock( LEFT )
	left_pnl:SetWide( math.Clamp( menu_w * 0.30, 220, 340 ) )
	left_pnl:DockMargin( 4, 4, 0, 4 )
	left_pnl.Paint = function( s, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, Color( 28, 32, 42, 255 ) )
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 1, Color( 0, 140, 200, 120 ) )
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
	root_game.m_zFolder     = "materials"
	root_game.m_zSearchPath = "GAME"
	AddExpandPlaceholder( root_game )
	root_game.DoPopulate    = function( self )
		print("[ZDEV MatEdit] ROOT 'Garry's Mod' DoPopulate fired!")
		PopulateTreeNode( self, "materials", "GAME" )
	end
	root_game.DoClick = function( self )
		print("[ZDEV MatEdit] ROOT 'Garry's Mod' DoClick fired! Expanded=" .. tostring(self:IsExpanded()))
	end

	-- Addon materials root
	local root_addons = tree:AddNode( "Addons", "icon16/plugin.png" )
	root_addons.m_zFolder     = "materials"
	root_addons.m_zSearchPath = "THIRDPARTY"
	AddExpandPlaceholder( root_addons )
	root_addons.DoPopulate    = function( self )
		print("[ZDEV MatEdit] ROOT 'Addons' DoPopulate fired!")
		PopulateTreeNode( self, "materials", "THIRDPARTY" )
	end

	-- Saved materials root (data directory)
	local root_saved = tree:AddNode( "Saved (data/)", "icon16/folder_user.png" )
	AddExpandPlaceholder( root_saved )
	root_saved.DoPopulate = function( self )
		print("[ZDEV MatEdit] ROOT 'Saved' DoPopulate fired!")
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
	local right_pnl = vgui.Create( "DPanel", menu )
	right_pnl:Dock( FILL )
	right_pnl:DockMargin( 4, 4, 4, 4 )
	right_pnl.Paint = function( s, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, Color( 30, 34, 44, 255 ) )
	end

	-- Selected file label (top of right panel)
	selected_lbl = vgui.Create( "DLabel", right_pnl )
	selected_lbl:Dock( TOP ) ; selected_lbl:SetTall( 20 ) ; selected_lbl:DockMargin( 4, 4, 4, 0 )
	selected_lbl:SetText( "  (no file selected)" ) ; selected_lbl:SetFont( "DermaDefault" )
	selected_lbl:SetTextColor( Color( 180, 200, 220 ) )
	selected_lbl.Paint = function( s, w, h )
		draw.RoundedBox( 3, 0, 0, w, h, Color( 22, 26, 36, 200 ) )
	end

	-- Material preview
	local preview_container = vgui.Create( "DPanel", right_pnl )
	preview_container:Dock( TOP )
	preview_container:SetTall( math.Clamp( menu_h * 0.36, 180, 340 ) )
	preview_container:DockMargin( 4, 4, 4, 4 )
	preview_container.Paint = function( s, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, Color( 20, 22, 30, 255 ) )
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 1, Color( 80, 100, 140, 100 ) )
		if not IsValid( preview_img ) or preview_img:GetMaterial() == nil then
			draw.SimpleText( "Material Preview", "DermaLarge", w * 0.5, h * 0.5,
				Color( 100, 100, 100 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
	end

	preview_img = vgui.Create( "DImage", preview_container )
	preview_img:Dock( FILL ) ; preview_img:DockMargin( 4, 4, 4, 4 )
	preview_img:SetKeepAspect( true )
	preview_img:SetImage( "gui/noicon" )

	-- Shader section
	local shader_pnl = vgui.Create( "DPanel", right_pnl )
	shader_pnl:Dock( TOP ) ; shader_pnl:SetTall( 28 ) ; shader_pnl:DockMargin( 4, 0, 4, 2 )
	shader_pnl.Paint = function( s, w, h )
		draw.RoundedBox( 3, 0, 0, w, h, Color( 38, 42, 54, 255 ) )
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
		draw.RoundedBox( 3, 0, 0, w, h, Color( 26, 30, 40, 255 ) )
		ZDEV.DRAW.OutlinedBox( 0, 0, w, h, 1, Color( 60, 80, 120, 80 ) )
	end


	-- ─── BOTTOM BAR ──────────────────────────────────────────────────────────
	local bottom_bar = vgui.Create( "DPanel", menu )
	bottom_bar:Dock( BOTTOM ) ; bottom_bar:SetTall( 36 ) ; bottom_bar:DockMargin( 4, 0, 4, 4 )
	bottom_bar.Paint = function( s, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, Color( 38, 42, 52, 255 ) )
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
			if IsValid( preview_img ) then preview_img:SetMaterial( mat ) end
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
concommand.Add( "zd_menu_dev_mat", ZDEV.VGUI.Editor_Materials )

ZDEV.VGUI.AddToMainMenu( "zd_menu_dev_mat" )

ZDEV.FILE.SetLoaded( _f )

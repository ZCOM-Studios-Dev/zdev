local _f = 'zd_cl_menu_fonts.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')

-- ConCommands BEFORE the reload guard so they re-register on zdev_reload
ZDEV.CMDS.Register( "zdev_menu_fonts", function()
	ZDEV.VGUI.FontLab()
end, { aliases = { "zd_menu_font" } } )

if ZDEV.FILE.Loaded( _f ) then return end

if not CLIENT then return end

--[[ ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  ZDEV VGUI: Font Lab (Phase 1)
  configure visually → preview live → export as code   (see ROADMAP.md)

  - Browser: everything in ZDEV.FONT._INDEX (+ aliases)
  - Editor:  every surface.CreateFont field with a proper widget
  - Preview: debounced, content-addressed scratch fonts (each distinct
             config is created EXACTLY once — the wiki forbids re-creating
             a font name, so we never do)
  - Export:  raw surface.CreateFont / ZDEV house style, clipboard + data file
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ ]]

ZDEV.VGUI = ZDEV.VGUI or {}

-- =============================================================================
-- Theme & fonts
-- =============================================================================

surface.CreateFont( "ZDEV_FontLab_UI", {
	font = "Tahoma", size = 13, weight = 700, antialias = true
} )
surface.CreateFont( "ZDEV_FontLab_Mono", {
	font = "Consolas", size = 12, weight = 500, antialias = true
} )

local CLR_BG      = Color( 24, 24, 28, 255 )
local CLR_PANEL   = Color( 32, 32, 38, 255 )
local CLR_INSET   = Color( 18, 18, 22, 255 )
local CLR_LIGHT   = Color( 225, 225, 220, 255 )
local CLR_OUTLINE = Color( 60, 60, 68, 255 )
local CLR_TEXT    = Color( 220, 220, 225, 255 )
local CLR_DIM     = Color( 130, 135, 145, 255 )
local CLR_ACCENT  = Color( 0, 180, 140, 255 )

-- =============================================================================
-- Font data model
-- =============================================================================

-- Stable field order for serialization, code-gen and the editor layout
local FIELD_ORDER = {
	"font", "extended", "size", "weight", "blursize", "scanlines",
	"antialias", "underline", "italic", "strikeout", "symbol",
	"rotary", "shadow", "additive", "outline"
}

local DEFAULT_FONTDATA = {
	font = "Arial", extended = false, size = 24, weight = 500,
	blursize = 0, scanlines = 0, antialias = true, underline = false,
	italic = false, strikeout = false, symbol = false, rotary = false,
	shadow = false, additive = false, outline = false
}

local NUMERIC_FIELDS = {
	size      = { min = 4, max = 128 },
	weight    = { min = 0, max = 1000 },
	blursize  = { min = 0, max = 80 },
	scanlines = { min = 0, max = 10 }
}

local BOOL_FIELDS = {
	"antialias", "extended", "shadow", "additive", "outline",
	"italic", "underline", "strikeout", "symbol", "rotary"
}

local RAMP_SIZES = { 12, 16, 24, 32, 48 }

-- =============================================================================
-- Content-addressed preview font pool
-- =============================================================================
-- The wiki warns: "do NOT create the font more than once". So every distinct
-- config hashes to a unique name and is created exactly once per Lua session.
-- Pool lives on ZDEV.FONT so zdev_reload doesn't lose track of created names.

ZDEV.FONT._LAB_POOL = ZDEV.FONT._LAB_POOL or {}

local function SerializeIdent( d )
	local parts = {}
	for _, k in ipairs( FIELD_ORDER ) do
		local v = d[ k ]
		if type( v ) == "boolean" then v = v and 1 or 0 end
		table.insert( parts, tostring( v or "" ) )
	end
	return table.concat( parts, "|" )
end

local function GetPreviewFont( d )
	local name = "ZDEV_FontLab_" .. util.CRC( SerializeIdent( d ) )
	if not ZDEV.FONT._LAB_POOL[ name ] then
		local data = table.Copy( d )
		if not data.font or data.font == "" then data.font = "Arial" end
		surface.CreateFont( name, data )
		ZDEV.FONT._LAB_POOL[ name ] = true
	end
	return name
end

local function PoolCount()
	return table.Count( ZDEV.FONT._LAB_POOL )
end

-- =============================================================================
-- Code generation
-- =============================================================================

local function FieldToLua( v )
	if type( v ) == "string" then return string.format( "%q", v ) end
	return tostring( v )
end

local function GenBody( d, indent )
	local lines = {}
	for _, k in ipairs( FIELD_ORDER ) do
		local v = d[ k ]
		if v == nil then v = DEFAULT_FONTDATA[ k ] end
		table.insert( lines, indent .. k .. " = " .. FieldToLua( v ) )
	end
	return table.concat( lines, ",\n" )
end

local function GenCode_Raw( name, d )
	return "surface.CreateFont( " .. string.format( "%q", name ) .. ", {\n"
		.. GenBody( d, "\t" ) .. "\n} )\n"
end

local function GenCode_ZDEV( name, d )
	return "local _fonts = {}\n\n"
		.. "_fonts[" .. string.format( "%q", name ) .. "] = {\n"
		.. GenBody( d, "\t" ) .. "\n}\n\n"
		.. "for newname, fontdata in pairs( _fonts ) do\n"
		.. "\tZDEV.FONT.Register( newname, fontdata )\n"
		.. "end\n"
end

local EXPORT_STYLES = {
	{ label = "ZDEV house style (Register loop)", gen = GenCode_ZDEV },
	{ label = "Raw surface.CreateFont",           gen = GenCode_Raw }
}

-- =============================================================================
-- The Lab
-- =============================================================================

-- ZDEV_UID: ZDEV_FUNC_BD728EC3 | Path: ZDEV.VGUI.FontLab
function ZDEV.VGUI.FontLab()
	if IsValid( ZDEV.VGUI.FontLabFrame ) then
		ZDEV.VGUI.FontLabFrame:MakePopup()
		return ZDEV.VGUI.FontLabFrame
	end

	local SW, SH = ScrW(), ScrH()

	-- Editor state
	local cur = table.Copy( DEFAULT_FONTDATA )
	local curName = "my_font"

	-- Widget refs + forward-declared helpers (lua-closures rule: declare the
	-- upvalue slots before any callback that captures them)
	local nameEntry, familyEntry, sampleEntry, exportEntry, styleCombo
	local browser, canvas, slotLabel, rampCheck
	local sliders, checks = {}, {}
	local MarkDirty, ResolvePreview, GenExport, LoadIntoEditor, RebuildBrowser

	local frame = ZDEV.VGUI.CreateFrame( SW * 0.85, SH * 0.85, "ZDEV: Font Lab" )
	frame:SetSizable( true )
	frame:SetMinWidth( 900 )
	frame:SetMinHeight( 560 )
	ZDEV.VGUI.FontLabFrame = frame

	frame.PF = nil               -- resolved preview fonts { main=, ramp={ {size,name} } }
	frame.DirtyAt = nil          -- debounce timestamp

	-- ==========================================================================
	-- Panes (side-docked first, FILL last — dock uses z-order)
	-- ==========================================================================

	local leftPane = vgui.Create( "DPanel", frame )
	leftPane:Dock( LEFT )
	leftPane:SetWide( 270 )
	leftPane:DockMargin( 4, 2, 2, 4 )
	leftPane.Paint = function( self, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, CLR_PANEL )
	end

	local rightPane = vgui.Create( "DPanel", frame )
	rightPane:Dock( RIGHT )
	rightPane:SetWide( 310 )
	rightPane:DockMargin( 2, 2, 4, 4 )
	rightPane.Paint = function( self, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, CLR_PANEL )
	end

	local centerPane = vgui.Create( "DPanel", frame )
	centerPane:Dock( FILL )
	centerPane:DockMargin( 2, 2, 2, 4 )
	centerPane:SetPaintBackground( false )

	-- ==========================================================================
	-- Center: sample entry (TOP), export (BOTTOM), preview canvas (FILL)
	-- ==========================================================================

	sampleEntry = vgui.Create( "DTextEntry", centerPane )
	sampleEntry:Dock( TOP )
	sampleEntry:DockMargin( 0, 0, 0, 2 )
	sampleEntry:SetTall( 24 )
	sampleEntry:SetUpdateOnType( true )
	sampleEntry:SetValue( "The quick brown fox jumps over the lazy dog — 0123456789" )

	local exportPnl = vgui.Create( "DPanel", centerPane )
	exportPnl:Dock( BOTTOM )
	exportPnl:SetTall( 190 )
	exportPnl:SetZPos( 1 )
	exportPnl.Paint = function( self, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, CLR_PANEL )
	end

	canvas = vgui.Create( "DPanel", centerPane )
	canvas:Dock( FILL )
	canvas:DockMargin( 0, 0, 0, 2 )
	canvas:SetZPos( 2 )

	-- Export panel internals
	local exportBar = vgui.Create( "DPanel", exportPnl )
	exportBar:Dock( TOP )
	exportBar:SetTall( 28 )
	exportBar:SetPaintBackground( false )

	styleCombo = vgui.Create( "DComboBox", exportBar )
	styleCombo:Dock( LEFT )
	styleCombo:DockMargin( 4, 3, 4, 3 )
	styleCombo:SetWide( 220 )
	for i, s in ipairs( EXPORT_STYLES ) do
		styleCombo:AddChoice( s.label, i, i == 1 )
	end

	local copyBtn = vgui.Create( "DButton", exportBar )
	copyBtn:Dock( RIGHT )
	copyBtn:DockMargin( 2, 3, 4, 3 )
	copyBtn:SetWide( 90 )
	copyBtn:SetText( "Copy Code" )

	local saveBtn = vgui.Create( "DButton", exportBar )
	saveBtn:Dock( RIGHT )
	saveBtn:DockMargin( 2, 3, 2, 3 )
	saveBtn:SetWide( 100 )
	saveBtn:SetText( "Save to Data" )

	exportEntry = vgui.Create( "DTextEntry", exportPnl )
	exportEntry:Dock( FILL )
	exportEntry:DockMargin( 4, 0, 4, 4 )
	exportEntry:SetMultiline( true )
	exportEntry:SetFont( "ZDEV_FontLab_Mono" )

	-- ==========================================================================
	-- Right pane: parameter editor
	-- ==========================================================================

	local function AddLabel( parent, text )
		local lbl = vgui.Create( "DLabel", parent )
		lbl:Dock( TOP )
		lbl:DockMargin( 8, 6, 8, 0 )
		lbl:SetFont( "ZDEV_FontLab_UI" )
		lbl:SetTextColor( CLR_DIM )
		lbl:SetText( text )
		return lbl
	end

	AddLabel( rightPane, "REGISTRY NAME" )
	nameEntry = vgui.Create( "DTextEntry", rightPane )
	nameEntry:Dock( TOP )
	nameEntry:DockMargin( 8, 2, 8, 0 )
	nameEntry:SetTall( 22 )
	nameEntry:SetUpdateOnType( true )
	nameEntry:SetValue( curName )

	AddLabel( rightPane, "FONT FAMILY  (OS font-viewer name, not filename)" )
	familyEntry = vgui.Create( "DTextEntry", rightPane )
	familyEntry:Dock( TOP )
	familyEntry:DockMargin( 8, 2, 8, 0 )
	familyEntry:SetTall( 22 )
	familyEntry:SetUpdateOnType( true )
	familyEntry:SetValue( cur.font )

	local knownCombo = vgui.Create( "DComboBox", rightPane )
	knownCombo:Dock( TOP )
	knownCombo:DockMargin( 8, 2, 8, 0 )
	knownCombo:SetTall( 20 )
	knownCombo:SetValue( "— pick a known family —" )
	do
		local seen = {}
		for _, data in pairs( ZDEV.FONT._INDEX ) do
			if data.font and not seen[ data.font ] then
				seen[ data.font ] = true
				knownCombo:AddChoice( data.font )
			end
		end
		for _, fam in ipairs( { "Arial", "Tahoma", "Consolas", "Courier New", "Verdana", "Trebuchet MS", "Roboto", "coolvetica" } ) do
			if not seen[ fam ] then
				seen[ fam ] = true
				knownCombo:AddChoice( fam )
			end
		end
	end

	for _, key in ipairs( { "size", "weight", "blursize", "scanlines" } ) do
		local cfg = NUMERIC_FIELDS[ key ]
		local slider = vgui.Create( "DNumSlider", rightPane )
		slider:Dock( TOP )
		slider:DockMargin( 8, 2, 8, 0 )
		slider:SetTall( 24 )
		slider:SetText( key )
		slider:SetMin( cfg.min )
		slider:SetMax( cfg.max )
		slider:SetDecimals( 0 )
		slider:SetValue( cur[ key ] )
		slider.Label:SetTextColor( CLR_TEXT )
		sliders[ key ] = slider
	end

	AddLabel( rightPane, "FLAGS" )
	for i = 1, #BOOL_FIELDS, 2 do
		local row = vgui.Create( "DPanel", rightPane )
		row:Dock( TOP )
		row:DockMargin( 8, 2, 8, 0 )
		row:SetTall( 18 )
		row:SetPaintBackground( false )

		for col = 0, 1 do
			local key = BOOL_FIELDS[ i + col ]
			if key then
				local cb = vgui.Create( "DCheckBoxLabel", row )
				if col == 0 then
					cb:Dock( LEFT )
					cb:SetWide( 140 )
				else
					cb:Dock( FILL )
				end
				cb:SetText( key )
				cb:SetTextColor( CLR_TEXT )
				cb:SetValue( cur[ key ] and true or false )
				checks[ key ] = cb
			end
		end
	end

	rampCheck = vgui.Create( "DCheckBoxLabel", rightPane )
	rampCheck:Dock( TOP )
	rampCheck:DockMargin( 8, 8, 8, 0 )
	rampCheck:SetText( "size ramp preview (12/16/24/32/48)" )
	rampCheck:SetTextColor( CLR_DIM )
	rampCheck:SetValue( true )

	local registerBtn = vgui.Create( "DButton", rightPane )
	registerBtn:Dock( TOP )
	registerBtn:DockMargin( 8, 10, 8, 0 )
	registerBtn:SetTall( 28 )
	registerBtn:SetText( "Register / Update  →  ZDEV.FONT" )

	slotLabel = AddLabel( rightPane, "" )

	-- ==========================================================================
	-- Left pane: browser
	-- ==========================================================================

	AddLabel( leftPane, "REGISTERED FONTS  (ZDEV.FONT._INDEX)" )

	local newBtn = vgui.Create( "DButton", leftPane )
	newBtn:Dock( BOTTOM )
	newBtn:DockMargin( 8, 4, 8, 8 )
	newBtn:SetTall( 24 )
	newBtn:SetText( "New Font (reset editor)" )
	newBtn:SetZPos( 1 )

	browser = vgui.Create( "DListView", leftPane )
	browser:Dock( FILL )
	browser:DockMargin( 8, 4, 8, 0 )
	browser:SetZPos( 2 )
	browser:SetMultiSelect( false )
	browser:AddColumn( "Name" )
	browser:AddColumn( "Family" )
	browser:AddColumn( "Size" ):SetFixedWidth( 38 )

	-- ==========================================================================
	-- Helpers (assign into forward-declared slots — NOT `local function`)
	-- ==========================================================================

	GenExport = function()
		local _, idx = styleCombo:GetSelected()
		local style = EXPORT_STYLES[ idx or 1 ] or EXPORT_STYLES[ 1 ]
		exportEntry:SetValue( style.gen( curName, cur ) )
	end

	ResolvePreview = function()
		local pf = { main = GetPreviewFont( cur ), ramp = {} }
		if rampCheck:GetChecked() then
			for _, s in ipairs( RAMP_SIZES ) do
				local d = table.Copy( cur )
				d.size = s
				table.insert( pf.ramp, { size = s, name = GetPreviewFont( d ) } )
			end
		end
		frame.PF = pf
		slotLabel:SetText( "session preview fonts created: " .. PoolCount() )
		GenExport()
	end

	MarkDirty = function()
		frame.DirtyAt = RealTime() + 0.30
	end

	LoadIntoEditor = function( name, data )
		curName = name
		cur = table.Copy( DEFAULT_FONTDATA )
		for k, v in pairs( data ) do cur[ k ] = v end

		nameEntry:SetValue( name )
		familyEntry:SetValue( cur.font or "" )
		for key, slider in pairs( sliders ) do
			slider:SetValue( cur[ key ] or DEFAULT_FONTDATA[ key ] )
		end
		for key, cb in pairs( checks ) do
			cb:SetValue( cur[ key ] and true or false )
		end
		MarkDirty()
	end

	RebuildBrowser = function()
		browser:Clear()
		local names = {}
		for name in pairs( ZDEV.FONT._INDEX ) do table.insert( names, name ) end
		table.sort( names )
		for _, name in ipairs( names ) do
			local d = ZDEV.FONT._INDEX[ name ]
			local line = browser:AddLine( name, d.font or "?", d.size or "?" )
			line.FontID = name
		end
		for alias, target in pairs( ZDEV.FONT._ALIAS or {} ) do
			local d = ZDEV.FONT._INDEX[ target ] or {}
			local line = browser:AddLine( alias .. "  →  " .. target, d.font or "?", d.size or "?" )
			line.FontID = target
		end
	end

	-- ==========================================================================
	-- Wiring
	-- ==========================================================================

	nameEntry.OnValueChange = function( self, v )
		curName = string.Trim( v or "" )
		MarkDirty()
	end

	familyEntry.OnValueChange = function( self, v )
		cur.font = string.Trim( v or "" )
		MarkDirty()
	end

	knownCombo.OnSelect = function( self, idx, label )
		familyEntry:SetValue( label )   -- fires OnValueChange → MarkDirty
	end

	for key, slider in pairs( sliders ) do
		slider.OnValueChanged = function( self, val )
			cur[ key ] = math.Round( val )
			MarkDirty()
		end
	end

	for key, cb in pairs( checks ) do
		cb.OnChange = function( self, checked )
			cur[ key ] = checked and true or false
			MarkDirty()
		end
	end

	rampCheck.OnChange = function() MarkDirty() end
	sampleEntry.OnValueChange = function() end   -- canvas reads it live; no font work needed

	styleCombo.OnSelect = function() GenExport() end

	copyBtn.DoClick = function()
		SetClipboardText( exportEntry:GetValue() or "" )
		MsgC( CLR_ACCENT, "[ZDEV] Font Lab: code copied to clipboard\n" )
	end

	saveBtn.DoClick = function()
		local fname = "zdev/fontlab/export_" .. ( curName ~= "" and curName or "unnamed" ) .. ".txt"
		file.CreateDir( "zdev/fontlab" )
		file.Write( fname, exportEntry:GetValue() or "" )
		MsgC( CLR_ACCENT, "[ZDEV] Font Lab: saved data/" .. fname .. "\n" )
	end

	registerBtn.DoClick = function()
		if curName == "" then
			MsgC( Color( 255, 120, 60 ), "[ZDEV] Font Lab: enter a registry name first\n" )
			return
		end
		ZDEV.FONT.Register( curName, table.Copy( cur ) )
		RebuildBrowser()
		MsgC( CLR_ACCENT, "[ZDEV] Font Lab: registered '" .. curName .. "'\n" )
	end

	browser.OnRowSelected = function( self, rowIndex, row )
		local id = row.FontID
		if id and ZDEV.FONT._INDEX[ id ] then
			LoadIntoEditor( id, ZDEV.FONT._INDEX[ id ] )
		end
	end

	newBtn.DoClick = function()
		LoadIntoEditor( "my_font", DEFAULT_FONTDATA )
	end

	-- Debounce: font creation happens here, never inside Paint
	frame.Think = function( self )
		if self.DirtyAt and RealTime() >= self.DirtyAt then
			self.DirtyAt = nil
			ResolvePreview()
		end
	end

	-- ==========================================================================
	-- Preview canvas
	-- ==========================================================================

	canvas.Paint = function( self, w, h )
		draw.RoundedBox( 4, 0, 0, w, h, CLR_INSET )
		surface.SetDrawColor( CLR_OUTLINE )
		surface.DrawOutlinedRect( 0, 0, w, h )

		local pf = frame.PF
		if not pf then
			draw.SimpleText( "resolving preview...", "ZDEV_FontLab_UI", w / 2, h / 2, CLR_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			return
		end

		local sample = sampleEntry:GetValue()
		if sample == "" then sample = "Sample" end
		local x, y = 16, 12

		draw.SimpleText( string.format( "PREVIEW  —  %s  @  %dpx   (weight %d, blur %d, scan %d)",
			cur.font ~= "" and cur.font or "Arial", cur.size or 0, cur.weight or 0,
			cur.blursize or 0, cur.scanlines or 0 ),
			"ZDEV_FontLab_UI", x, y, CLR_DIM )
		y = y + 22

		-- Main sample on dark
		surface.SetFont( pf.main )
		local tw, th = surface.GetTextSize( sample )
		draw.SimpleText( sample, pf.main, x, y, CLR_TEXT )
		y = y + th + 10

		-- Main sample on light strip
		surface.SetDrawColor( CLR_LIGHT )
		surface.DrawRect( x - 6, y - 4, math.min( w - 20, tw + 12 ), th + 8 )
		draw.SimpleText( sample, pf.main, x, y, Color( 25, 25, 30 ) )
		y = y + th + 18

		-- Size ramp
		if #pf.ramp > 0 then
			draw.SimpleText( "SIZE RAMP", "ZDEV_FontLab_UI", x, y, CLR_DIM )
			y = y + 20
			for _, r in ipairs( pf.ramp ) do
				if y > h - 20 then break end
				draw.SimpleText( r.size, "ZDEV_FontLab_Mono", x, y + 2, CLR_ACCENT )
				surface.SetFont( r.name )
				local _, rh = surface.GetTextSize( sample )
				draw.SimpleText( sample, r.name, x + 34, y, CLR_TEXT )
				y = y + rh + 6
			end
		end
	end

	-- ==========================================================================
	-- Initial population
	-- ==========================================================================

	RebuildBrowser()
	ResolvePreview()

	return frame
end

-- Back-compat: the old menu entry point
ZDEV.VGUI.FontMenu = ZDEV.VGUI.FontLab

ZDEV.VGUI.AddToMainMenu( "zdev_menu_fonts" )

ZDEV.FILE.SetLoaded( _f )

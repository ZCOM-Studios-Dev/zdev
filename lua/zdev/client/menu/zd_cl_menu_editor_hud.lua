local _f = 'zdev/client/menu/zd_cl_menu_editor_hud.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	zd_cl_menu_editor_hud.lua  —  ZDEV HUD EDITOR (in-game, real-time)

	UE5-UserWidget-style editor over the CHUD widget system:

	  · zdev_edit_hud_toggle 1  (or zdev_edit_hud_editor) enters editor mode —
	    the HUD freezes, every element gets a wireframe, the mouse activates.
	  · HIERARCHY: a DTree of the whole HUD — the CANVAS root, every element,
	    and (for widget-tree elements) every child node, all selectable.
	    Right-click nodes for add/rename/reorder/duplicate/delete.
	  · PALETTE: one button per widget component (TEXT, TEXT RIGHT, LED NUMBER,
	    TITLE CHIP, SHAPE, PROGRESS BAR, SEGMENT BAR, containers, ...). Clicking
	    adds it to the selected container. "NEW PANEL" creates a user-made
	    top-level element that persists in profiles.
	  · INSPECTOR: TRANSFORM rows for elements; NODE/RECT/PROPERTY rows for
	    widget nodes, generated from each widget type's schema (fonts, colours,
	    bindings, alignment — the lot). Edits apply to the live HUD instantly.
	  · CANVAS: click selects an element, click-drag moves it (grid-snapped),
	    wheel scales. Double-click drills into the widget node under the
	    cursor; dragging a selected node moves it inside its free container.
	  · Layout persists automatically ("_active" profile) + named snapshots.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- ─── Convars + commands (BEFORE the reload guard — gmod-file-load-order) ────
ZDEV.CONV.ClientVar( "zdev_edit_hud_toggle", "0",  "Toggle the ZDEV HUD editor mode (0/1)" )
ZDEV.CONV.ClientVar( "zdev_edit_hud_snap",   "1",  "HUD editor: snap dragged elements to the grid (0/1)" )
ZDEV.CONV.ClientVar( "zdev_edit_hud_grid",   "8",  "HUD editor: snap grid size in design pixels" )

ZDEV.CMDS.Register( "zdev_edit_hud_editor", function()
	local cv = GetConVar( "zdev_edit_hud_toggle" )
	cv:SetBool( not cv:GetBool() )
end, { help = "Toggle the ZDEV in-game HUD editor" } )

if ZDEV.FILE.Loaded( _f ) then return end

local CHUD = ZDEV.CHUD
local WIDG = ZDEV.CHUD.WIDG
local DRAW = ZDEV.DRAW
local UI   = ZDEV.DRAW.UI
local FX   = ZDEV.DRAW.FX

local SimpleText = draw.SimpleText
local Clamp      = math.Clamp
local floor      = math.floor
local Round      = math.Round
local max, min   = math.max, math.min
local istable    = istable
local A_C, A_L, A_R = TEXT_ALIGN_CENTER, TEXT_ALIGN_LEFT, TEXT_ALIGN_RIGHT
local A_T           = TEXT_ALIGN_TOP

local ANCH = {
	tl = { 0.0, 0.0 }, t = { 0.5, 0.0 }, tr = { 1.0, 0.0 },
	l  = { 0.0, 0.5 }, c = { 0.5, 0.5 }, r  = { 1.0, 0.5 },
	bl = { 0.0, 1.0 }, b = { 0.5, 1.0 }, br = { 1.0, 1.0 },
}

-- Chrome derives from the single reskin point (VISUAL_STYLE_GUIDE.md §8).
-- Cyan (THEME.accent) is reserved for interactive/selected state only.
local THEME = ZDEV.DRAW.UI.THEME
local function opaque( c, a ) return Color( c.r, c.g, c.b, a ) end
local T_BG     = opaque( THEME.bg, 245 )
local T_PANEL  = opaque( THEME.panel, 250 )
local T_LINE   = THEME.border
local T_ACCENT = THEME.accent
local T_TEXT   = THEME.text
local T_DIM    = THEME.textDim

local EDITOR = {
	selected   = nil,      -- selected element id
	selNode    = nil,      -- selected widget node (table ref) within it, or nil
	drag       = nil,      -- element drag: { id, gx, gy }
	nodeDrag   = nil,      -- node drag: { id, node, sx, sy, mx, my, s }
	hover      = nil,
	canvas     = nil,      -- fullscreen input panel
	frame      = nil,      -- inspector window
	props      = nil,      -- DProperties
	nodeBar    = nil,      -- node action toolbar
	tree       = nil,      -- hierarchy DTree
	treeHolder = nil,
	tnByNode   = {},       -- widget node -> DTree_Node
	tnByElem   = {},       -- element id  -> DTree_Node
	lastClick  = 0,
	lastClickId = nil,
}

local cvSnap = GetConVar( "zdev_edit_hud_snap" )
local cvGrid = GetConVar( "zdev_edit_hud_grid" )

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	LAYOUT HELPERS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local function snapVal( v )
	if not cvSnap:GetBool() then return Round( v ) end
	local g = max( cvGrid:GetInt(), 1 )
	return Round( v / g ) * g
end

-- Set layout offsets from a desired screen-space rect origin.
local function setRectOrigin( id, rx, ry )
	local def = CHUD.Elements[ id ]
	local l   = CHUD.Layout[ id ]
	if not ( def and l ) then return end
	local ui = CHUD.UIScale()
	local _, _, w, h = CHUD.GetRect( id )
	local a = ANCH[ l.anchor ] or ANCH.tl
	l.x = snapVal( ( rx + a[ 1 ] * w - a[ 1 ] * ScrW() ) / ui )
	l.y = snapVal( ( ry + a[ 2 ] * h - a[ 2 ] * ScrH() ) / ui )
end

-- Change anchor while keeping the element visually in place.
local function rebaseAnchor( id, newAnchor )
	local l = CHUD.Layout[ id ]
	if not l or not ANCH[ newAnchor ] then return end
	local rx, ry, w, h = CHUD.GetRect( id )
	l.anchor = newAnchor
	if rx then
		local ui = CHUD.UIScale()
		local a = ANCH[ newAnchor ]
		l.x = Round( ( rx + a[ 1 ] * w - a[ 1 ] * ScrW() ) / ui )
		l.y = Round( ( ry + a[ 2 ] * h - a[ 2 ] * ScrH() ) / ui )
	end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	NODE GEOMETRY  (screen-space mapping of widget-node rects)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local function elemScale( id )
	local l = CHUD.Layout[ id ]
	return CHUD.UIScale() * ( ( l and l.scale ) or 1 )
end

-- Screen rect of a widget node (from its last-paint element-local rect).
local function NodeScreenRect( id, node )
	local ex, ey = CHUD.GetRect( id )
	if not ex then return nil end
	local rx, ry, rw, rh = WIDG.GetNodeRect( node )
	if not rx then return nil end
	local s = elemScale( id )
	return ex + rx * s, ey + ry * s, rw * s, rh * s, s
end

-- Deepest widget node under a screen point within an element.
local function NodeAtScreen( id, mx, my )
	local l = CHUD.Layout[ id ]
	local root = l and l.tree
	if not istable( root ) then return nil end
	local ex, ey = CHUD.GetRect( id )
	if not ex then return nil end
	local s = elemScale( id )
	return WIDG.NodeAt( root, ( mx - ex ) / s, ( my - ey ) / s )
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	INSPECTOR ROW HELPERS  (DProperties — typed rows per glua-type-system
	Rule 2, value coercion per gmod-vgui-layout Rule 9)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local RefreshInspector   -- fwd (lua-closures Rule 3)
local RefreshTree
local SelectElement
local SelectNode
local AddFromPalette
local OpenContextMenu
local OpenNodeMenu

local function addNumberRow( props, cat, label, get, set, isInt, minV, maxV )
	local row = props:CreateRow( cat, label )
	row:Setup( isInt and "Int" or "Float", { min = minV or -4096, max = maxV or 4096 } )
	row:SetValue( get() )
	row.DataChanged = function( _, val )
		val = tonumber( val )
		if val == nil then return end
		if minV then val = max( val, minV ) end
		if maxV then val = min( val, maxV ) end
		if isInt then val = floor( val + 0.5 ) end
		set( val )
		CHUD.MarkDirty()
	end
	return row
end

local function addBoolRow( props, cat, label, get, set )
	local row = props:CreateRow( cat, label )
	row:Setup( "Boolean" )
	row:SetValue( get() and true or false )
	row.DataChanged = function( _, val )
		set( tobool( val ) )
		CHUD.MarkDirty()
	end
	return row
end

local function addComboRow( props, cat, label, options, get, set )
	if isfunction( options ) then options = options() end
	options = options or {}
	local row = props:CreateRow( cat, label )
	row:Setup( "Combo", { text = tostring( get() ) } )
	local cur = get()
	for _, opt in ipairs( options ) do
		row:AddChoice( tostring( opt ), opt, opt == cur )
	end
	row.DataChanged = function( _, val )
		set( val )
		CHUD.MarkDirty()
	end
	return row
end

local function addColorRow( props, cat, label, get, set )
	local row = props:CreateRow( cat, label )
	row:Setup( "VectorColor" )
	local c = get() or Color( 255, 255, 255 )
	-- DProperty_VectorColor expects a Color in SetValue (glua-type-system Rule 2)
	row:SetValue( Color( c.r or 255, c.g or 255, c.b or 255, c.a or 255 ) )
	row.DataChanged = function( _, val )
		local old = get() or Color( 255, 255, 255 )
		local nc
		if IsColor( val ) or ( istable( val ) and val.r ) then
			nc = Color( val.r, val.g, val.b, old.a or 255 )
		else
			-- string form: "r g b" — may be 0..1 (vector) or 0..255 scale
			local r, g, b = string.match( tostring( val ), "([%d%.]+)%s+([%d%.]+)%s+([%d%.]+)" )
			if not r then return end
			r, g, b = tonumber( r ), tonumber( g ), tonumber( b )
			if r <= 1 and g <= 1 and b <= 1 then r, g, b = r * 255, g * 255, b * 255 end
			nc = Color( floor( r + 0.5 ), floor( g + 0.5 ), floor( b + 0.5 ), old.a or 255 )
		end
		set( nc )
		CHUD.MarkDirty()
	end
	return row
end

local function addStringRow( props, cat, label, get, set )
	local row = props:CreateRow( cat, label )
	row:Setup( "Generic" )
	row:SetValue( tostring( get() or "" ) )
	row.DataChanged = function( _, val )
		set( tostring( val ) )
		CHUD.MarkDirty()
	end
	return row
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	STYLED BUTTON
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local function StyleButton( b )
	b:SetTextColor( T_TEXT )
	b:SetFont( "ZDEV_HUD_Label" )
	b.Paint = function( self, w, h )
		DRAW.Rect( 0, 0, w, h, self:IsHovered() and Color( 30, 44, 56, 255 ) or T_PANEL )
		DRAW.OutlinedBox( 0, 0, w, h, 1, self:IsHovered() and T_ACCENT or T_LINE )
	end
	return b
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	INSPECTOR  —  element view (TRANSFORM + element params) or node view
	(NODE / RECT / schema-generated PROPERTIES).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local function BuildElementInspector( props, id, def, l )
	local TC = "TRANSFORM"
	addBoolRow( props, TC, "Enabled", function() return l.enabled end, function( v ) l.enabled = v end )
	if not def.fullscreen then
		addComboRow( props, TC, "Anchor", CHUD.AnchorNames,
			function() return l.anchor end,
			function( v ) rebaseAnchor( id, v ) RefreshInspector() end )
		addNumberRow( props, TC, "X Offset", function() return l.x end, function( v ) l.x = v end )
		addNumberRow( props, TC, "Y Offset", function() return l.y end, function( v ) l.y = v end )
		addNumberRow( props, TC, "Scale", function() return l.scale end, function( v ) l.scale = v end, false, 0.1, 8 )
		addNumberRow( props, TC, "Rotation", function() return l.rot end, function( v ) l.rot = v end, false, -180, 180 )
		addNumberRow( props, TC, "Parallax", function() return l.parallax end, function( v ) l.parallax = v end, false, -2, 2 )
	end
	addNumberRow( props, TC, "Alpha", function() return l.alpha end, function( v ) l.alpha = v end, false, 0, 1 )

	-- user-created panels: size + label are element-level data
	if def.custom then
		local CC = "CUSTOM PANEL"
		addStringRow( props, CC, "Label",
			function() return def.label end,
			function( v )
				if v == "" then return end
				def.label = v
				l.custom = istable( l.custom ) and l.custom or {}
				l.custom.label = v
				RefreshTree()
			end )
		addNumberRow( props, CC, "Width",
			function() return def.size.w end,
			function( v )
				def.size.w = v
				if istable( l.custom ) and istable( l.custom.size ) then l.custom.size.w = v end
			end, true, 8, 1920 )
		addNumberRow( props, CC, "Height",
			function() return def.size.h end,
			function( v )
				def.size.h = v
				if istable( l.custom ) and istable( l.custom.size ) then l.custom.size.h = v end
			end, true, 8, 1080 )
	end

	-- ── ELEMENT PARAMETERS (schema-driven) ─────────────────────────────
	if def.params then
		local keys = def.paramOrder
		if not keys then
			keys = {}
			for k in pairs( def.params ) do keys[ #keys + 1 ] = k end
			table.sort( keys )
		end
		local PC = "PARAMETERS"
		for _, k in ipairs( keys ) do
			local spec = def.params[ k ]
			if spec then
				local label = spec.label or k
				local get = function() return l.params[ k ] end
				local set = function( v ) l.params[ k ] = v end
				if spec.type == "bool" then
					addBoolRow( props, PC, label, get, set )
				elseif spec.type == "int" then
					addNumberRow( props, PC, label, get, set, true, spec.min, spec.max )
				elseif spec.type == "number" then
					addNumberRow( props, PC, label, get, set, false, spec.min, spec.max )
				elseif spec.type == "color" then
					addColorRow( props, PC, label, get, set )
				elseif spec.type == "select" then
					addComboRow( props, PC, label, spec.options or {}, get, set )
				else
					addStringRow( props, PC, label, get, set )
				end
			end
		end
	end
end

local function BuildNodeInspector( props, id, node )
	local l    = CHUD.Layout[ id ]
	local root = l.tree
	local t    = WIDG.Types[ node.type ]
	local NC   = "NODE  ·  " .. ( t and t.label or string.upper( node.type or "?" ) )

	addStringRow( props, NC, "Name",
		function() return node.name end,
		function( v )
			if v == "" then return end
			node.name = v
			RefreshTree()
		end )
	addBoolRow( props, NC, "Visible",
		function() return node.visible ~= false end,
		function( v ) node.visible = v RefreshTree() end )

	-- ── RECT (design px; x/y only meaningful inside free containers) ───
	if node ~= root then
		local parent = WIDG.FindParent( root, node )
		local pt = parent and WIDG.Types[ parent.type ]
		local free = pt and ( pt.layout == "free" or pt.layout == nil )
		local RC = free and "RECT" or "RECT  (position managed by " .. ( pt and pt.label or "parent" ) .. ")"
		if free then
			addNumberRow( props, RC, "X", function() return node.x end, function( v ) node.x = v end, true )
			addNumberRow( props, RC, "Y", function() return node.y end, function( v ) node.y = v end, true )
		end
		addNumberRow( props, RC, "Width",  function() return node.w end, function( v ) node.w = v end, true, 1, 1920 )
		addNumberRow( props, RC, "Height", function() return node.h end, function( v ) node.h = v end, true, 1, 1080 )
	end

	-- ── PROPERTIES (widget schema) ──────────────────────────────────────
	if t and t.schema then
		local keys = t.schemaOrder
		if not keys then
			keys = {}
			for k in pairs( t.schema ) do keys[ #keys + 1 ] = k end
			table.sort( keys )
		end
		local PC = "PROPERTIES"
		for _, k in ipairs( keys ) do
			local spec = t.schema[ k ]
			if spec then
				local label = spec.label or k
				local get = function() return node.props[ k ] end
				local set = function( v ) node.props[ k ] = v end
				if spec.type == "bool" then
					addBoolRow( props, PC, label, get, set )
				elseif spec.type == "int" then
					addNumberRow( props, PC, label, get, set, true, spec.min, spec.max )
				elseif spec.type == "number" then
					addNumberRow( props, PC, label, get, set, false, spec.min, spec.max )
				elseif spec.type == "color" then
					addColorRow( props, PC, label, get, set )
				elseif spec.type == "select" then
					addComboRow( props, PC, label, spec.options or {}, get, set )
				else
					addStringRow( props, PC, label, get, set )
				end
			end
		end
	end
end

-- Node action toolbar (docked above the property grid when a node is selected)
local function BuildNodeBar( holder, id, node )
	local l    = CHUD.Layout[ id ]
	local root = l.tree
	local isRoot = ( node == root )

	local bar = vgui.Create( "DPanel", holder )
	bar:Dock( TOP )
	bar:SetTall( 22 )
	bar:DockMargin( 0, 0, 0, 4 )
	bar:SetPaintBackground( false )
	EDITOR.nodeBar = bar

	local function mkBtn( txt, wide, fn )
		local b = StyleButton( vgui.Create( "DButton", bar ) )
		b:SetText( txt ) b:Dock( LEFT ) b:SetWide( wide ) b:DockMargin( 0, 0, 3, 0 )
		b.DoClick = fn
		return b
	end

	if not isRoot then
		mkBtn( "▲", 26, function()
			if WIDG.MoveNode( root, node, -1 ) then CHUD.MarkDirty() RefreshTree() end
		end )
		mkBtn( "▼", 26, function()
			if WIDG.MoveNode( root, node, 1 ) then CHUD.MarkDirty() RefreshTree() end
		end )
		mkBtn( "DUPLICATE", 80, function()
			local parent, idx = WIDG.FindParent( root, node )
			if not parent then return end
			local copy = WIDG.SanitizeNode( node )
			if not copy then return end
			copy.name = ( node.name or node.type ) .. " 2"
			copy.x, copy.y = ( copy.x or 0 ) + 8, ( copy.y or 0 ) + 8
			WIDG.AddChild( parent, copy, idx + 1 )
			CHUD.MarkDirty() RefreshTree()
			SelectNode( id, copy )
		end )
		local del = mkBtn( "DELETE", 60, function()
			WIDG.RemoveNode( root, node )
			EDITOR.selNode = nil
			CHUD.MarkDirty() RefreshTree() RefreshInspector()
		end )
		del:SetTextColor( THEME.bad )
	else
		local lbl = vgui.Create( "DLabel", bar )
		lbl:Dock( FILL )
		lbl:SetFont( "ZDEV_HUD_Label" )
		lbl:SetTextColor( T_DIM )
		lbl:SetText( "ROOT — sized by the element; add children via PALETTE" )
	end
end

RefreshInspector = function()
	local frame = EDITOR.frame
	if not IsValid( frame ) then return end
	if IsValid( EDITOR.props )   then EDITOR.props:Remove() end
	if IsValid( EDITOR.nodeBar ) then EDITOR.nodeBar:Remove() end
	EDITOR.props, EDITOR.nodeBar = nil, nil

	local id  = EDITOR.selected
	local def = id and CHUD.Elements[ id ]
	local l   = id and CHUD.Layout[ id ]
	if not ( def and l ) then
		EDITOR.selNode = nil
		return
	end

	-- validate the node still belongs to this element's tree
	local node = EDITOR.selNode
	if node and istable( l.tree ) then
		if node ~= l.tree and not WIDG.FindParent( l.tree, node ) then
			node = nil
			EDITOR.selNode = nil
		end
	else
		node = nil
		EDITOR.selNode = nil
	end

	if node then BuildNodeBar( frame.inspectorHolder, id, node ) end

	local props = vgui.Create( "DProperties", frame.inspectorHolder )
	props:Dock( FILL )
	EDITOR.props = props

	if node then
		BuildNodeInspector( props, id, node )
	else
		BuildElementInspector( props, id, def, l )
	end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	HIERARCHY TREE  —  CANVAS root › elements › widget nodes.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local function syncTreeSelection()
	local tree = EDITOR.tree
	if not IsValid( tree ) then return end
	local tn
	if EDITOR.selNode then
		tn = EDITOR.tnByNode[ EDITOR.selNode ]
	elseif EDITOR.selected then
		tn = EDITOR.tnByElem[ EDITOR.selected ]
	end
	if IsValid( tn ) then tree:SetSelectedItem( tn ) end
end

RefreshTree = function()
	local holder = EDITOR.treeHolder
	if not IsValid( holder ) then return end
	if IsValid( EDITOR.tree ) then EDITOR.tree:Remove() end
	EDITOR.tnByNode, EDITOR.tnByElem = {}, {}

	local tree = vgui.Create( "DTree", holder )
	tree:Dock( FILL )
	tree.Paint = function( _, w, h )
		DRAW.Rect( 0, 0, w, h, T_PANEL )
		DRAW.OutlinedBox( 0, 0, w, h, 1, T_LINE )
	end
	EDITOR.tree = tree

	local rootTn = tree:AddNode( "HUD CANVAS", "icon16/monitor.png" )
	rootTn.Label:SetTextColor( T_TEXT )
	rootTn.DoClick = function()
		SelectElement( nil, true )
	end

	local ids = {}
	for id, def in pairs( CHUD.Elements ) do
		if not def.noEditor then ids[ #ids + 1 ] = id end
	end
	table.sort( ids, function( a, b )
		local la = CHUD.Elements[ a ].label or a
		local lb = CHUD.Elements[ b ].label or b
		if la == lb then return a < b end
		return la < lb
	end )

	local function addWidgetNode( parentTn, id, wnode )
		local t = WIDG.Types[ wnode.type ]
		local label = wnode.name or wnode.type
		if wnode.visible == false then label = label .. "  · hidden" end
		local tn = parentTn:AddNode( label, ( t and t.icon ) or "icon16/bullet_white.png" )
		tn.Label:SetTextColor( T_TEXT )
		tn.chudId, tn.wnode = id, wnode
		tn.DoClick = function() SelectNode( id, wnode, true ) end
		tn.DoRightClick = function()
			SelectNode( id, wnode, true )
			OpenNodeMenu( id, wnode )
			return true
		end
		EDITOR.tnByNode[ wnode ] = tn
		if istable( wnode.children ) then
			for i = 1, #wnode.children do
				addWidgetNode( tn, id, wnode.children[ i ] )
			end
			if EDITOR.selNode and wnode ~= EDITOR.selNode
				and WIDG.ContainsNode( wnode, EDITOR.selNode ) then
				tn:SetExpanded( true )
			end
		end
		return tn
	end

	for _, id in ipairs( ids ) do
		local def = CHUD.Elements[ id ]
		local on = CHUD.IsElementVisible( id )
		local label = def.label or id
		if not on then label = label .. "  · off" end
		local tn = rootTn:AddNode( label,
			def.custom and "icon16/application_form.png" or "icon16/application.png" )
		tn.Label:SetTextColor( T_TEXT )
		tn.chudId = id
		tn.DoClick = function() SelectElement( id, true ) end
		tn.DoRightClick = function()
			SelectElement( id, true )
			OpenContextMenu( id )
			return true
		end
		EDITOR.tnByElem[ id ] = tn

		local l = CHUD.Layout[ id ]
		if l and istable( l.tree ) then
			addWidgetNode( tn, id, l.tree )
			if id == EDITOR.selected then tn:SetExpanded( true ) end
		end
	end

	rootTn:SetExpanded( true )
	syncTreeSelection()
end

SelectElement = function( id, fromTree )
	EDITOR.selected = id
	EDITOR.selNode  = nil
	RefreshInspector()
	if not fromTree then syncTreeSelection() end
end

SelectNode = function( id, node, fromTree )
	EDITOR.selected = id
	EDITOR.selNode  = node
	RefreshInspector()
	if not fromTree then syncTreeSelection() end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	PALETTE  —  add widgets to the selected container / element root.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
AddFromPalette = function( entry )
	local id = EDITOR.selected
	if not id then
		notification.AddLegacy( "HUD Editor: select an element first (or NEW PANEL)", NOTIFY_ERROR, 3 )
		return
	end
	local l = CHUD.Layout[ id ]
	local root = l and l.tree
	if not istable( root ) then
		notification.AddLegacy( "HUD Editor: this element is fixed-function — it can't hold widgets", NOTIFY_ERROR, 4 )
		return
	end
	if WIDG.CountNodes( root ) >= 128 then
		notification.AddLegacy( "HUD Editor: node limit reached (128) for this element", NOTIFY_ERROR, 3 )
		return
	end

	-- target: selected container, else the selection's parent, else the root
	local target = root
	local sel = EDITOR.selNode
	if sel then
		local t = WIDG.Types[ sel.type ]
		if t and t.container then
			target = sel
		else
			local parent = WIDG.FindParent( root, sel )
			if parent then target = parent end
		end
	end

	local node = WIDG.NewNode( entry.type, { name = entry.label, props = entry.props } )
	if not node then return end
	node.x, node.y = 8, 8
	WIDG.AddChild( target, node )
	CHUD.MarkDirty()
	RefreshTree()
	SelectNode( id, node )
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	CONTEXT MENUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local function addPaletteSubmenu( m, id, node )
	local sub, opt = m:AddSubMenu( "Add Widget" )
	opt:SetIcon( "icon16/add.png" )
	for _, entry in ipairs( WIDG.Palette ) do
		sub:AddOption( entry.label, function()
			if node then SelectNode( id, node ) else SelectElement( id ) end
			AddFromPalette( entry )
		end )
	end
end

OpenNodeMenu = function( id, node )
	local l = CHUD.Layout[ id ]
	local root = l and l.tree
	if not ( root and node ) then return end
	local isRoot = ( node == root )
	local t = WIDG.Types[ node.type ]
	local m = DermaMenu()

	if t and t.container then addPaletteSubmenu( m, id, node ) end

	m:AddOption( "Rename", function()
		Derma_StringRequest( "Rename Node", "Node name:", node.name or "", function( txt )
			if txt ~= "" then
				node.name = txt
				CHUD.MarkDirty() RefreshTree() RefreshInspector()
			end
		end )
	end ):SetIcon( "icon16/pencil.png" )

	m:AddOption( node.visible == false and "Show" or "Hide", function()
		node.visible = not ( node.visible ~= false )
		CHUD.MarkDirty() RefreshTree() RefreshInspector()
	end ):SetIcon( "icon16/lightbulb_off.png" )

	if not isRoot then
		m:AddOption( "Move Up", function()
			if WIDG.MoveNode( root, node, -1 ) then CHUD.MarkDirty() RefreshTree() end
		end ):SetIcon( "icon16/arrow_up.png" )
		m:AddOption( "Move Down", function()
			if WIDG.MoveNode( root, node, 1 ) then CHUD.MarkDirty() RefreshTree() end
		end ):SetIcon( "icon16/arrow_down.png" )
		m:AddOption( "Duplicate", function()
			local parent, idx = WIDG.FindParent( root, node )
			if not parent then return end
			local copy = WIDG.SanitizeNode( node )
			if not copy then return end
			copy.name = ( node.name or node.type ) .. " 2"
			copy.x, copy.y = ( copy.x or 0 ) + 8, ( copy.y or 0 ) + 8
			WIDG.AddChild( parent, copy, idx + 1 )
			CHUD.MarkDirty() RefreshTree()
			SelectNode( id, copy )
		end ):SetIcon( "icon16/page_copy.png" )
		m:AddSpacer()
		m:AddOption( "Delete", function()
			WIDG.RemoveNode( root, node )
			EDITOR.selNode = nil
			CHUD.MarkDirty() RefreshTree() RefreshInspector()
		end ):SetIcon( "icon16/delete.png" )
	end

	m:Open()
end

OpenContextMenu = function( id )
	local def = CHUD.Elements[ id ]
	local l   = CHUD.Layout[ id ]
	if not ( def and l ) then return end
	local m = DermaMenu()

	if istable( l.tree ) then addPaletteSubmenu( m, id, nil ) end

	m:AddOption( l.enabled ~= false and "Disable Element" or "Enable Element", function()
		l.enabled = not ( l.enabled ~= false )
		CHUD.MarkDirty() RefreshInspector() RefreshTree()
	end ):SetIcon( "icon16/lightbulb_off.png" )
	m:AddOption( "Centre Horizontally", function()
		rebaseAnchor( id, ( l.anchor == "tl" or l.anchor == "t" or l.anchor == "tr" ) and "t"
			or ( ( l.anchor == "bl" or l.anchor == "b" or l.anchor == "br" ) and "b" or "c" ) )
		l.x = 0
		CHUD.MarkDirty() RefreshInspector()
	end ):SetIcon( "icon16/shape_align_center.png" )
	m:AddOption( "Reset Element", function()
		CHUD.ResetElement( id )
		EDITOR.selNode = nil
		RefreshInspector() RefreshTree()
	end ):SetIcon( "icon16/arrow_undo.png" )

	if def.custom then
		m:AddSpacer()
		m:AddOption( "Delete Custom Panel", function()
			Derma_Query( "Delete custom panel '" .. ( def.label or id ) .. "'?", "HUD Editor", "Delete", function()
				WIDG.RemoveCustomElement( id )
				if EDITOR.selected == id then EDITOR.selected, EDITOR.selNode = nil, nil end
				RefreshTree() RefreshInspector()
			end, "Cancel" )
		end ):SetIcon( "icon16/delete.png" )
	end

	m:AddSpacer()
	m:AddOption( "Cancel" ):SetIcon( "icon16/cross.png" )
	m:Open()
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	HUD OVERLAY  (drawn by the CHUD pipeline while editor mode is active)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local function paintNodeOutlines( node, ex, ey, s )
	local rx, ry, rw, rh = WIDG.GetNodeRect( node )
	if rx then
		local x, y, w, h = ex + rx * s, ey + ry * s, rw * s, rh * s
		if node == EDITOR.selNode then
			DRAW.OutlinedBox( x, y, w, h, 1, T_ACCENT )
			UI.CornerBrackets( x - 2, y - 2, w + 4, h + 4, 7, 1, T_ACCENT )
			SimpleText( DRAW.LetterSpace( node.name or node.type ), "ZDEV_HUD_Label",
				x + 1, y - 13, T_ACCENT, A_L, A_T )
		else
			DRAW.OutlinedBox( x, y, w, h, 1, Color( 255, 255, 255, 16 ) )
		end
	end
	if istable( node.children ) then
		for i = 1, #node.children do
			paintNodeOutlines( node.children[ i ], ex, ey, s )
		end
	end
end

local function PaintOverlay()
	local sw, sh = ScrW(), ScrH()
	local acc = T_ACCENT

	-- faint alignment grid
	local g = max( cvGrid:GetInt(), 4 ) * CHUD.UIScale() * 4
	FX.GridLines( 0, 0, sw, sh, g, Color( 255, 255, 255, 8 ), 1 )

	-- edge status strip + centred inverted mode chip (amber = active edit mode)
	DRAW.Rect( 0, 0, sw, 26, opaque( THEME.bg, 220 ) )
	DRAW.Rect( 0, 26, sw, 1, T_LINE )
	local title = DRAW.LetterSpace( "ZDEV // HUD EDIT MODE" )
	surface.SetFont( "ZDEV_HUD_Title" )
	local tw = surface.GetTextSize( title )
	UI.TitleChip( ( sw - tw - 16 ) * 0.5, 3, title,
		{ font = "ZDEV_HUD_Title", bg = THEME.warn, fg = THEME.chipText, padX = 8, padY = 2 } )
	SimpleText( DRAW.LetterSpace( "LMB SELECT+DRAG   2xLMB SELECT NODE   WHEEL SCALE   RMB MENU" ), "ZDEV_HUD_Label",
		sw - 16, 13, T_DIM, A_R, A_C )

	-- hover tracking (canvas may be under the inspector frame — that's fine,
	-- vgui.GetHoveredPanel keeps us honest)
	local mx, my = gui.MousePos()
	EDITOR.hover = nil
	local hovered = vgui.GetHoveredPanel()
	if hovered == EDITOR.canvas or EDITOR.drag or EDITOR.nodeDrag then
		EDITOR.hover = CHUD.ElementAt( mx, my )
	end

	-- element wireframes
	for id, def in pairs( CHUD.Elements ) do
		if not def.fullscreen and not def.noEditor then
			local x, y, w, h = CHUD.GetRect( id )
			if x then
				local sel = ( id == EDITOR.selected )
				local hov = ( id == EDITOR.hover )
				local on  = CHUD.IsElementVisible( id )
				local boxClr = ( sel and not EDITOR.selNode ) and acc
					or ( hov and Color( 255, 255, 255, 130 ) or Color( 255, 255, 255, on and 55 or 25 ) )

				DRAW.OutlinedBox( x, y, w, h, 1, boxClr )
				if sel and not EDITOR.selNode then
					UI.CornerBrackets( x - 3, y - 3, w + 6, h + 6, 10, 2, acc )
				end
				SimpleText( DRAW.LetterSpace( def.label or id ), "ZDEV_HUD_Label",
					x + 2, y - 14, ( sel and not EDITOR.selNode ) and acc
						or ( on and T_DIM or Color( 120, 120, 120, 120 ) ), A_L, A_T )
			end
		end
	end

	-- selection readout + anchor guide
	local sid = EDITOR.selected
	if sid then
		local def = CHUD.Elements[ sid ]
		local l = CHUD.Layout[ sid ]
		local x, y, w, h = CHUD.GetRect( sid )
		if x and l and def and not def.fullscreen then
			-- widget-node hairlines + selected-node highlight
			if istable( l.tree ) then
				paintNodeOutlines( l.tree, x, y, elemScale( sid ) )
			end

			-- anchor pivot marker + leader line back to the screen anchor point
			local a = ANCH[ l.anchor ] or ANCH.tl
			local pvx, pvy = x + a[ 1 ] * w, y + a[ 2 ] * h
			local ax, ay = a[ 1 ] * sw, a[ 2 ] * sh
			UI.TechLine( ax, ay, pvx, pvy, { clr = DRAW.Alpha( acc, 110 ), elbow = true, cap = "dot" } )
			DRAW.Cross( pvx, pvy, 7, 2, 1, acc )

			local info = string.format( "%s   X %d  Y %d   S %.2f   R %.1f   PX %.2f",
				string.upper( l.anchor ), l.x, l.y, l.scale or 1, l.rot or 0, l.parallax or 0 )
			local ty = y + h + 6
			if ty > sh - 24 then ty = y - 30 end
			SimpleText( DRAW.LetterSpace( info, " " ), "ZDEV_HUD_Label", x, ty, acc, A_L, A_T )
		end

		-- full-screen alignment guides while dragging
		if ( EDITOR.drag or EDITOR.nodeDrag ) and x then
			DRAW.Line( 0, y, sw, y, Color( 255, 255, 255, 40 ) )
			DRAW.Line( x, 0, x, sh, Color( 255, 255, 255, 40 ) )
			DRAW.Line( 0, y + h, sw, y + h, Color( 255, 255, 255, 25 ) )
			DRAW.Line( x + w, 0, x + w, sh, Color( 255, 255, 255, 25 ) )
		end
	end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	CANVAS  (fullscreen input surface: select / drag / wheel / context menu)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
-- Begin dragging a widget node (only inside free-layout containers).
local function StartNodeDrag( id, node, mx, my )
	local l = CHUD.Layout[ id ]
	local root = l and l.tree
	if not istable( root ) or node == root then return false end
	local parent = WIDG.FindParent( root, node )
	local pt = parent and WIDG.Types[ parent.type ]
	if not ( pt and ( pt.layout == "free" or pt.layout == nil ) ) then return false end
	EDITOR.nodeDrag = {
		id = id, node = node,
		sx = node.x or 0, sy = node.y or 0,
		mx = mx, my = my, s = elemScale( id ),
	}
	return true
end

local function CreateCanvas()
	local cv = vgui.Create( "DPanel" )
	cv:SetSize( ScrW(), ScrH() )
	cv:SetPos( 0, 0 )
	cv:SetPaintBackground( false )
	cv:MakePopup()
	cv:SetKeyboardInputEnabled( false )   -- game keys keep working
	cv:SetCursor( "arrow" )

	cv.OnMousePressed = function( _, code )
		local mx, my = gui.MousePos()
		local id = CHUD.ElementAt( mx, my )

		if code == MOUSE_LEFT then
			-- double-click: drill into the widget node under the cursor
			local now = SysTime()
			local dbl = ( now - EDITOR.lastClick < 0.28 ) and ( EDITOR.lastClickId == id )
			EDITOR.lastClick, EDITOR.lastClickId = now, id

			if dbl and id then
				local node = NodeAtScreen( id, mx, my )
				if node then
					SelectNode( id, node )
					StartNodeDrag( id, node, mx, my )
					return
				end
			end

			-- click on the already-selected node → drag it in place
			if id and id == EDITOR.selected and EDITOR.selNode then
				local nx, ny, nw, nh = NodeScreenRect( id, EDITOR.selNode )
				if nx and mx >= nx and mx <= nx + nw and my >= ny and my <= ny + nh then
					if StartNodeDrag( id, EDITOR.selNode, mx, my ) then return end
				end
			end

			SelectElement( id )
			if id then
				local x, y = CHUD.GetRect( id )
				EDITOR.drag = { id = id, gx = mx - x, gy = my - y }
			end
		elseif code == MOUSE_RIGHT then
			if id and id == EDITOR.selected and EDITOR.selNode then
				local nx, ny, nw, nh = NodeScreenRect( id, EDITOR.selNode )
				if nx and mx >= nx and mx <= nx + nw and my >= ny and my <= ny + nh then
					OpenNodeMenu( id, EDITOR.selNode )
					return
				end
			end
			if id then
				SelectElement( id )
				OpenContextMenu( id )
			end
		end
	end

	cv.OnMouseReleased = function( _, code )
		if code ~= MOUSE_LEFT then return end
		if EDITOR.drag then
			EDITOR.drag = nil
			CHUD.MarkDirty()
			RefreshInspector()
		end
		if EDITOR.nodeDrag then
			EDITOR.nodeDrag = nil
			CHUD.MarkDirty()
			RefreshInspector()
		end
	end

	cv.Think = function()
		local d = EDITOR.drag
		if d then
			local mx, my = gui.MousePos()
			setRectOrigin( d.id, mx - d.gx, my - d.gy )
		end
		local nd = EDITOR.nodeDrag
		if nd then
			local mx, my = gui.MousePos()
			nd.node.x = snapVal( nd.sx + ( mx - nd.mx ) / nd.s )
			nd.node.y = snapVal( nd.sy + ( my - nd.my ) / nd.s )
		end
	end

	cv.OnMouseWheeled = function( _, delta )
		local id = EDITOR.selected or EDITOR.hover
		local def = id and CHUD.Elements[ id ]
		local l = id and CHUD.Layout[ id ]
		if not l or ( def and def.fullscreen ) then return end
		l.scale = Clamp( ( l.scale or 1 ) + delta * 0.05, 0.1, 8 )
		CHUD.MarkDirty()
	end

	return cv
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	INSPECTOR WINDOW  (IDE-style side panel)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local function CreateFrame()
	local fw, fh = 440, math.min( ScrH() - 60, 940 )
	local frame = vgui.Create( "DFrame" )
	frame:SetSize( fw, fh )
	frame:SetPos( ScrW() - fw - 24, ( ScrH() - fh ) * 0.5 )
	frame:SetTitle( "" )
	frame:SetDraggable( true )
	frame:ShowCloseButton( false )
	frame:SetDeleteOnClose( true )
	frame:MakePopup()
	frame:SetKeyboardInputEnabled( true )
	frame.Paint = function( self, w, h )
		DRAW.Rect( 0, 0, w, h, T_BG )
		DRAW.Rect( 0, 0, w, 28, T_PANEL )
		DRAW.Rect( 0, 28, w, 1, T_LINE )
		DRAW.OutlinedBox( 0, 0, w, h, 1, T_LINE )
		UI.CornerBrackets( 0, 0, w, h, 10, 1, T_LINE )
		UI.TitleChip( 8, 6, DRAW.LetterSpace( "ZDEV // HUD EDITOR" ), { font = "ZDEV_HUD_Label" } )
	end

	local closeBtn = StyleButton( vgui.Create( "DButton", frame ) )
	closeBtn:SetText( "EXIT" )
	closeBtn:SetSize( 56, 20 )
	closeBtn:SetPos( fw - 62, 4 )
	closeBtn.DoClick = function()
		GetConVar( "zdev_edit_hud_toggle" ):SetBool( false )
	end

	local body = vgui.Create( "DPanel", frame )
	body:Dock( FILL )
	body:DockMargin( 8, 34, 8, 8 )
	body:SetPaintBackground( false )

	-- ── profiles toolbar ────────────────────────────────────────────────
	local profBar = vgui.Create( "DPanel", body )
	profBar:Dock( TOP )
	profBar:SetTall( 26 )
	profBar:SetPaintBackground( false )

	local profCombo = vgui.Create( "DComboBox", profBar )
	profCombo:Dock( FILL )
	profCombo:DockMargin( 0, 2, 4, 2 )
	profCombo:SetValue( "profiles..." )
	local function refreshProfiles()
		profCombo:Clear()
		for _, n in ipairs( CHUD.ListProfiles() ) do profCombo:AddChoice( n ) end
	end
	refreshProfiles()

	local loadBtn = StyleButton( vgui.Create( "DButton", profBar ) )
	loadBtn:SetText( "LOAD" ) loadBtn:Dock( RIGHT ) loadBtn:SetWide( 48 ) loadBtn:DockMargin( 2, 2, 0, 2 )
	loadBtn.DoClick = function()
		local n = profCombo:GetSelected()
		if n and CHUD.LoadProfile( n ) then
			CHUD.MarkDirty() RefreshInspector() RefreshTree()
			notification.AddLegacy( "HUD profile loaded: " .. n, NOTIFY_GENERIC, 2 )
		end
	end

	local saveBtn = StyleButton( vgui.Create( "DButton", profBar ) )
	saveBtn:SetText( "SAVE AS" ) saveBtn:Dock( RIGHT ) saveBtn:SetWide( 62 ) saveBtn:DockMargin( 2, 2, 0, 2 )
	saveBtn.DoClick = function()
		Derma_StringRequest( "Save HUD Profile", "Profile name:", "", function( txt )
			if CHUD.SaveProfile( txt ) then
				refreshProfiles()
				notification.AddLegacy( "HUD profile saved: " .. txt, NOTIFY_GENERIC, 2 )
			end
		end )
	end

	local delBtn = StyleButton( vgui.Create( "DButton", profBar ) )
	delBtn:SetText( "DEL" ) delBtn:Dock( RIGHT ) delBtn:SetWide( 40 ) delBtn:DockMargin( 2, 2, 0, 2 )
	delBtn.DoClick = function()
		local n = profCombo:GetSelected()
		if n then
			Derma_Query( "Delete profile '" .. n .. "'?", "HUD Editor", "Delete", function()
				CHUD.DeleteProfile( n ) refreshProfiles()
			end, "Cancel" )
		end
	end

	-- ── palette ─────────────────────────────────────────────────────────
	local palWrap = vgui.Create( "DPanel", body )
	palWrap:Dock( TOP )
	palWrap:SetTall( 118 )
	palWrap:DockMargin( 0, 6, 0, 0 )
	palWrap:SetPaintBackground( false )
	palWrap.Paint = function( _, w, h )
		DRAW.OutlinedBox( 0, 0, w, h, 1, T_LINE )
		SimpleText( DRAW.LetterSpace( "PALETTE — ADD TO SELECTION" ), "ZDEV_HUD_Label", 6, 3, T_DIM, A_L, A_T )
	end

	local newPanelBtn = StyleButton( vgui.Create( "DButton", palWrap ) )
	newPanelBtn:SetText( "+ NEW PANEL" )
	newPanelBtn:SetSize( 100, 14 )
	palWrap.PerformLayout = function( self, w, h ) newPanelBtn:SetPos( w - 104, 2 ) end
	newPanelBtn.DoClick = function()
		local id = WIDG.CreateCustomElement()
		RefreshTree()
		SelectElement( id )
		notification.AddLegacy( "HUD Editor: created '" .. ( CHUD.Elements[ id ].label or id ) .. "'", NOTIFY_GENERIC, 2 )
	end

	local pal = vgui.Create( "DIconLayout", palWrap )
	pal:Dock( FILL )
	pal:DockMargin( 4, 20, 4, 4 )
	pal:SetSpaceX( 3 )
	pal:SetSpaceY( 3 )
	for _, entry in ipairs( WIDG.Palette ) do
		local b = StyleButton( pal:Add( "DButton" ) )
		b:SetSize( 96, 20 )
		b:SetText( entry.label )
		b.DoClick = function() AddFromPalette( entry ) end
	end

	-- ── hierarchy tree ──────────────────────────────────────────────────
	local treeHolder = vgui.Create( "DPanel", body )
	treeHolder:Dock( TOP )
	treeHolder:SetTall( 230 )
	treeHolder:DockMargin( 0, 6, 0, 6 )
	treeHolder:SetPaintBackground( false )
	EDITOR.treeHolder = treeHolder

	-- ── bottom bar ──────────────────────────────────────────────────────
	local bottom = vgui.Create( "DPanel", body )
	bottom:Dock( BOTTOM )
	bottom:SetTall( 54 )
	bottom:DockMargin( 0, 6, 0, 0 )
	bottom:SetPaintBackground( false )

	local snapRow = vgui.Create( "DPanel", bottom )
	snapRow:Dock( TOP ) snapRow:SetTall( 24 ) snapRow:SetPaintBackground( false )

	local snapChk = vgui.Create( "DCheckBoxLabel", snapRow )
	snapChk:Dock( LEFT ) snapChk:SetWide( 90 )
	snapChk:SetText( "GRID SNAP" )
	snapChk:SetTextColor( T_DIM )
	snapChk:SetConVar( "zdev_edit_hud_snap" )

	local gridSlider = vgui.Create( "DNumSlider", snapRow )
	gridSlider:Dock( FILL )
	gridSlider:SetText( "GRID" )
	if IsValid( gridSlider.Label ) then gridSlider.Label:SetTextColor( T_DIM ) end
	gridSlider:SetMin( 1 ) gridSlider:SetMax( 64 ) gridSlider:SetDecimals( 0 )
	gridSlider:SetConVar( "zdev_edit_hud_grid" )

	local btnRow = vgui.Create( "DPanel", bottom )
	btnRow:Dock( BOTTOM ) btnRow:SetTall( 24 ) btnRow:SetPaintBackground( false )

	local resetElem = StyleButton( vgui.Create( "DButton", btnRow ) )
	resetElem:SetText( "RESET ELEMENT" ) resetElem:Dock( LEFT ) resetElem:SetWide( 110 ) resetElem:DockMargin( 0, 2, 4, 0 )
	resetElem.DoClick = function()
		if EDITOR.selected then
			CHUD.ResetElement( EDITOR.selected )
			EDITOR.selNode = nil
			RefreshInspector() RefreshTree()
		end
	end

	local resetAll = StyleButton( vgui.Create( "DButton", btnRow ) )
	resetAll:SetText( "RESET ALL" ) resetAll:Dock( LEFT ) resetAll:SetWide( 84 ) resetAll:DockMargin( 0, 2, 4, 0 )
	resetAll.DoClick = function()
		Derma_Query( "Reset ALL HUD elements to defaults?", "HUD Editor", "Reset", function()
			CHUD.ResetAll()
			EDITOR.selNode = nil
			RefreshInspector() RefreshTree()
		end, "Cancel" )
	end

	-- ── inspector ───────────────────────────────────────────────────────
	local holder = vgui.Create( "DPanel", body )
	holder:Dock( FILL )
	holder:SetPaintBackground( false )
	frame.inspectorHolder = holder

	frame.OnClose = function()
		-- window closed by other means → leave editor mode cleanly
		if GetConVar( "zdev_edit_hud_toggle" ):GetBool() then
			GetConVar( "zdev_edit_hud_toggle" ):SetBool( false )
		end
	end

	return frame
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	OPEN / CLOSE  (driven by the zdev_edit_hud_toggle convar, like the
	environment editor's editor-mode pattern)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local function OpenEditor()
	if IsValid( EDITOR.canvas ) then return end
	CHUD.SetEditorMode( true )
	CHUD.EditorOverlay = PaintOverlay
	EDITOR.canvas = CreateCanvas()
	EDITOR.frame  = CreateFrame()
	RefreshTree()
	RefreshInspector()
	zdev.log( "S", "ZDEV HUD Editor: ON" )
end

local function CloseEditor()
	CHUD.SetEditorMode( false )
	EDITOR.drag, EDITOR.nodeDrag = nil, nil
	if IsValid( EDITOR.canvas ) then EDITOR.canvas:Remove() end
	if IsValid( EDITOR.frame )  then EDITOR.frame:Remove() end
	EDITOR.canvas, EDITOR.frame, EDITOR.props, EDITOR.nodeBar = nil, nil, nil, nil
	EDITOR.tree, EDITOR.treeHolder = nil, nil
	EDITOR.tnByNode, EDITOR.tnByElem = {}, {}
	EDITOR.selNode = nil
	CHUD.SaveProfile( "_active" )
	zdev.log( "S", "ZDEV HUD Editor: OFF (layout autosaved)" )
end

cvars.AddChangeCallback( "zdev_edit_hud_toggle", function( _, _, new )
	if tobool( new ) then OpenEditor() else CloseEditor() end
end, "zdev_hud_editor_mode" )

-- If the file hot-reloads while the editor is open, rebuild cleanly.
if GetConVar( "zdev_edit_hud_toggle" ):GetBool() then
	CloseEditor()
	OpenEditor()
end

zdev.log( "S", "Loaded file: '" .. _f .. "'" )
ZDEV.FILE.SetLoaded( _f )

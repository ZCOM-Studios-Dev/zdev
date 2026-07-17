local _f = 'zdev/client/hud/zd_cl_hud_widgets.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	zd_cl_hud_widgets.lua  —  ZDEV.CHUD.WIDG  (CHUD widget/component system)

	UE5-UserWidget-style composition layer for CHUD elements. Every widget-based
	element owns a TREE of nodes rooted in a container. Containers lay out their
	children (free canvas, vertical/horizontal stacks, overlap); leaves draw a
	single primitive (text, LED number, title chip, shape, bar, ...). The whole
	tree persists inside the element's layout (data/zdev/hud/*.json profiles)
	and is edited live from the HUD Editor's hierarchy view + palette.

	  · CHUD.RegisterWidget( type, spec )      — declare a widget type
	  · WIDG.NewNode( type, overrides )        — build a normalized node
	  · WIDG.TreePaint                         — def.Paint for tree elements
	  · WIDG.SanitizeNode( raw )               — profile-load validation
	  · WIDG.CreateCustomElement( label )      — user-made top-level panel
	  · WIDG.Eval( binding )                   — live data source (value, frac)

	Node shape (JSON-safe):
	  { type="text", name="HP LABEL", x=, y=, w=, h=, visible=true,
	    props={ ... per-type schema ... }, children={ ... containers only } }

	Hot-path rules honoured: per-node layout rects live in a weak side-table
	(profiles stay clean), binding results are cached per frame, text transforms
	are memoised, and paint reuses pooled opt tables — no per-frame allocation.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

if ZDEV.FILE.Loaded( _f ) then return end

ZDEV.CHUD = ZDEV.CHUD or {}
local CHUD = ZDEV.CHUD
CHUD.WIDG = CHUD.WIDG or {}
local WIDG = CHUD.WIDG

local DRAW = ZDEV.DRAW
local UI   = ZDEV.DRAW.UI
local ANIM = ZDEV.ANIM
local TH   = ZDEV.DRAW.UI.THEME

local SimpleText = draw.SimpleText
local Clamp      = math.Clamp
local floor      = math.floor
local max, min   = math.max, math.min
local istable, isstring = istable, isstring
local pairs, ipairs, tostring, tonumber = pairs, ipairs, tostring, tonumber
local A_L, A_C, A_R = TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, TEXT_ALIGN_RIGHT
local A_T, A_B      = TEXT_ALIGN_TOP, TEXT_ALIGN_BOTTOM

local EMPTY = {}

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	COLOUR ROLES  —  widget colour props are a role select + a custom Color.
	Roles resolve through the style-guide THEME so a reskin restyles every
	widget; "accent" follows the element's live accent (theme primary or the
	element's own override).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local ROLES = { "accent", "text", "dim", "good", "warn", "bad", "chip", "chipText", "bg", "panel", "border", "line", "custom" }
WIDG.ColorRoles = ROLES

local function roleColor( mode, custom, ctx )
	if mode == "custom" then
		if IsColor( custom ) or ( istable( custom ) and custom.r ) then return custom end
		return TH.text
	end
	if mode == "accent" then return ctx.pri or TH.accent end
	if mode == "dim" then return TH.textDim end
	return TH[ mode ] or ctx.pri or TH.text
end
WIDG.RoleColor = roleColor

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	DATA BINDINGS  —  named live data sources. Each returns (value, frac):
	value feeds text/LED widgets (through an optional string.format), frac
	(0..1, may be nil) feeds bars/segment bars and the low-state logic.
	Results are cached per frame.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local B = {}
WIDG.Bindings = B

local function bind( name, label, fn )
	B[ name ] = { label = label, fn = fn }
end

bind( "health", "Health", function( lp )
	local hp = max( lp:Health(), 0 )
	return hp, Clamp( hp / max( lp:GetMaxHealth(), 1 ), 0, 1 )
end )
bind( "health_max", "Health Max", function( lp )
	return max( lp:GetMaxHealth(), 1 ), nil
end )
bind( "health_pair", "Health / Max", function( lp )
	local hp = max( lp:Health(), 0 )
	local hm = max( lp:GetMaxHealth(), 1 )
	return string.format( "%03d/%03d", floor( hp ), hm ), Clamp( hp / hm, 0, 1 )
end )
bind( "armor", "Armor", function( lp )
	local ar = max( lp:Armor(), 0 )
	local am = max( lp.GetMaxArmor and lp:GetMaxArmor() or 100, 1 )
	return ar, Clamp( ar / am, 0, 1 )
end )
bind( "clip", "Weapon Clip", function( lp )
	local wep = lp:GetActiveWeapon()
	if not IsValid( wep ) then return 0, nil end
	local clip, cm = wep:Clip1(), wep:GetMaxClip1()
	if clip < 0 or cm <= 0 then return 0, nil end
	return clip, Clamp( clip / cm, 0, 1 )
end )
bind( "clip_max", "Clip Max", function( lp )
	local wep = lp:GetActiveWeapon()
	return IsValid( wep ) and max( wep:GetMaxClip1(), 0 ) or 0, nil
end )
bind( "clip_pair", "Clip / Max", function( lp )
	local wep = lp:GetActiveWeapon()
	if not IsValid( wep ) then return "--/--", nil end
	local clip, cm = wep:Clip1(), wep:GetMaxClip1()
	if clip < 0 or cm <= 0 then return "--/--", nil end
	return string.format( "%02d/%02d", Clamp( clip, 0, 99 ), Clamp( cm, 0, 99 ) ), Clamp( clip / cm, 0, 1 )
end )
bind( "reserve", "Reserve Ammo", function( lp )
	local wep = lp:GetActiveWeapon()
	if not IsValid( wep ) then return 0, nil end
	local at = wep:GetPrimaryAmmoType()
	return at >= 0 and lp:GetAmmoCount( at ) or 0, nil
end )
bind( "ammo_display", "Ammo (Clip or Reserve)", function( lp )
	local wep = lp:GetActiveWeapon()
	if not IsValid( wep ) then return 0, nil end
	local clip, cm = wep:Clip1(), wep:GetMaxClip1()
	if clip >= 0 and cm > 0 then return clip, Clamp( clip / cm, 0, 1 ) end
	local at = wep:GetPrimaryAmmoType()
	return at >= 0 and lp:GetAmmoCount( at ) or 0, 1
end )
bind( "weapon_name", "Weapon Name", function( lp )
	local wep = lp:GetActiveWeapon()
	if not IsValid( wep ) then return "UNARMED", nil end
	return wep.GetPrintName and wep:GetPrintName() or wep:GetClass(), nil
end )
bind( "player_name", "Player Name", function( lp )
	return lp:Nick(), nil
end )
bind( "rank", "ZDEV Rank", function( lp )
	local rankId = lp:GetNWInt( "ZDEV_Rank", 0 )
	if ZDEV.RANK and ZDEV.RANK[ rankId ] and ZDEV.RANK.Name then
		return ZDEV.RANK.Name( rankId ), nil
	end
	return "UNRANKED", nil
end )
bind( "steamid", "SteamID", function( lp )
	return lp:SteamID(), nil
end )
bind( "speed", "Move Speed", function( lp )
	local spd = lp:GetVelocity():Length2D()
	return floor( spd ), Clamp( spd / 400, 0, 1 )
end )
bind( "fps", "FPS", function()
	return floor( 1 / max( RealFrameTime(), 0.0001 ) ), nil
end )
bind( "ping", "Ping", function( lp )
	return lp:Ping(), nil
end )
bind( "time", "Clock (HH:MM)", function()
	return os.date( "%H:%M" ), nil
end )
bind( "curtime", "CurTime", function()
	return floor( CurTime() ), nil
end )
bind( "distance", "Aim Distance (HU)", function( lp )
	local tr = lp:GetEyeTrace()
	return floor( lp:GetShootPos():Distance( tr.HitPos ) ), nil
end )
bind( "version", "ZDEV Version", function()
	return "ZDEV " .. tostring( ZDEV.VERSION or "" ), nil
end )

-- per-frame binding cache (entry tables are reused — no steady-state alloc)
local bindCache = {}
function WIDG.Eval( name )
	if not name or name == "none" or name == "" then return nil, nil end
	local b = B[ name ]
	if not b then return nil, nil end
	local fr = FrameNumber()
	local c = bindCache[ name ]
	if c and c.fr == fr then return c[ 1 ], c[ 2 ] end
	local lp = LocalPlayer()
	if not IsValid( lp ) then return nil, nil end
	if not c then c = {} bindCache[ name ] = c end
	local ok, v, f = pcall( b.fn, lp )
	if not ok then v, f = nil, nil end
	c.fr, c[ 1 ], c[ 2 ] = fr, v, f
	return v, f
end

function WIDG.BindOptions()
	local out = { "none" }
	for name in pairs( B ) do out[ #out + 1 ] = name end
	table.sort( out, function( a, b )
		if a == "none" then return true end
		if b == "none" then return false end
		return a < b
	end )
	return out
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FONT OPTIONS  —  every ZDEV-registered font (index + aliases) plus a few
	stock GMod fonts, for the TEXT/LED/CHIP font property.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local FONT_EXTRA = {
	"DermaDefault", "DermaDefaultBold", "DermaLarge",
	"Trebuchet18", "Trebuchet24", "HudHintTextLarge", "BudgetLabel", "ConsoleText",
}

function WIDG.FontOptions()
	local seen, out = {}, {}
	local function add( name )
		if not seen[ name ] then
			seen[ name ] = true
			out[ #out + 1 ] = name
		end
	end
	if ZDEV.FONT and ZDEV.FONT._INDEX then
		for name in pairs( ZDEV.FONT._INDEX ) do add( name ) end
	end
	if ZDEV.FONT and ZDEV.FONT._ALIAS then
		for name in pairs( ZDEV.FONT._ALIAS ) do add( name ) end
	end
	for _, name in ipairs( FONT_EXTRA ) do add( name ) end
	table.sort( out )
	return out
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	TYPE REGISTRY

	CHUD.RegisterWidget( type, spec )
	  spec = {
	    label     = "TEXT",            -- palette / tree display name
	    category  = "WIDGETS",         -- palette grouping
	    container = false,             -- may hold children
	    layout    = "free",            -- containers: free|vstack|hstack|overlap
	    size      = { w = 90, h = 16 },-- default node size when spawned
	    icon      = "icon16/...",      -- editor tree icon
	    schema    = { key = { label=, type="number|int|bool|color|select|string",
	                          default=, min=, max=, options={} or fn() } },
	    schemaOrder = { ... },
	    Paint     = function( node, x, y, w, h, p, ctx ) ... end,
	  }
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
WIDG.Types = {}
WIDG.TypeOrder = {}

function CHUD.RegisterWidget( wtype, spec )
	spec.type  = wtype
	spec.label = spec.label or string.upper( wtype )
	spec.size  = spec.size or { w = 60, h = 16 }
	if not WIDG.Types[ wtype ] then WIDG.TypeOrder[ #WIDG.TypeOrder + 1 ] = wtype end
	WIDG.Types[ wtype ] = spec
	return spec
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	NODE SANITISATION / CONSTRUCTION  —  every tree that enters the system
	(authored defaults, profile JSON, editor spawns) passes through
	SanitizeNode: unknown types are dropped, all schema props are filled and
	type-coerced, depth/child counts capped.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function WIDG.SanitizeNode( src, depth )
	depth = depth or 1
	if depth > 10 or not istable( src ) then return nil end
	local t = WIDG.Types[ tostring( src.type ) ]
	if not t then return nil end

	local node = {
		type    = src.type,
		name    = ( isstring( src.name ) and src.name ~= "" ) and src.name or t.label,
		x       = tonumber( src.x ) or 0,
		y       = tonumber( src.y ) or 0,
		w       = max( tonumber( src.w ) or t.size.w or 24, 1 ),
		h       = max( tonumber( src.h ) or t.size.h or 12, 1 ),
		visible = src.visible ~= false,
		props   = {},
	}

	local sp = istable( src.props ) and src.props or EMPTY
	for k, spec in pairs( t.schema or EMPTY ) do
		local v = sp[ k ]
		local d = spec.default
		if spec.type == "color" then
			if istable( v ) and v.r then
				node.props[ k ] = Color( tonumber( v.r ) or 255, tonumber( v.g ) or 255,
					tonumber( v.b ) or 255, tonumber( v.a ) or 255 )
			elseif istable( d ) then
				node.props[ k ] = Color( d.r or 255, d.g or 255, d.b or 255, d.a or 255 )
			else
				node.props[ k ] = Color( 255, 255, 255, 255 )
			end
		elseif spec.type == "bool" then
			if v ~= nil then node.props[ k ] = tobool( v ) else node.props[ k ] = d and true or false end
		elseif spec.type == "number" or spec.type == "int" then
			v = tonumber( v )
			if v == nil then v = tonumber( d ) or 0 end
			if spec.min then v = max( v, spec.min ) end
			if spec.max then v = min( v, spec.max ) end
			node.props[ k ] = ( spec.type == "int" ) and floor( v + 0.5 ) or v
		else -- string / select
			if v ~= nil then node.props[ k ] = tostring( v )
			elseif d ~= nil then node.props[ k ] = tostring( d )
			else node.props[ k ] = "" end
		end
	end

	if t.container then
		node.children = {}
		if istable( src.children ) then
			for i = 1, min( #src.children, 64 ) do
				local c = WIDG.SanitizeNode( src.children[ i ], depth + 1 )
				if c then node.children[ #node.children + 1 ] = c end
			end
		end
	end

	return node
end

-- Build a fresh, fully-defaulted node of a type. `overrides` may carry
-- name/x/y/w/h and a partial props table (palette presets).
function WIDG.NewNode( wtype, overrides )
	local t = WIDG.Types[ wtype ]
	if not t then return nil end
	local src = { type = wtype }
	if istable( overrides ) then
		for k, v in pairs( overrides ) do src[ k ] = v end
	end
	return WIDG.SanitizeNode( src, 1 )
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	TREE UTILITIES  (editor-facing)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function WIDG.FindParent( root, node )
	if not ( istable( root ) and istable( root.children ) ) then return nil end
	for i = 1, #root.children do
		local c = root.children[ i ]
		if c == node then return root, i end
		local p, idx = WIDG.FindParent( c, node )
		if p then return p, idx end
	end
	return nil
end

function WIDG.AddChild( parent, node, index )
	local t = parent and WIDG.Types[ parent.type ]
	if not ( t and t.container and istable( node ) ) then return false end
	parent.children = parent.children or {}
	if index then
		table.insert( parent.children, Clamp( index, 1, #parent.children + 1 ), node )
	else
		parent.children[ #parent.children + 1 ] = node
	end
	return true
end

function WIDG.RemoveNode( root, node )
	local p, i = WIDG.FindParent( root, node )
	if not p then return false end
	table.remove( p.children, i )
	return true
end

-- Reorder a node within its parent ( dir = -1 up / +1 down ).
function WIDG.MoveNode( root, node, dir )
	local p, i = WIDG.FindParent( root, node )
	if not p then return false end
	local j = Clamp( i + dir, 1, #p.children )
	if j == i then return false end
	p.children[ i ], p.children[ j ] = p.children[ j ], p.children[ i ]
	return true
end

function WIDG.CountNodes( root )
	if not istable( root ) then return 0 end
	local n = 1
	if istable( root.children ) then
		for i = 1, #root.children do
			n = n + WIDG.CountNodes( root.children[ i ] )
		end
	end
	return n
end

-- Does `root`'s subtree contain `node`? (tree-panel expansion helper)
function WIDG.ContainsNode( root, node )
	if root == node then return true end
	if not ( istable( root ) and istable( root.children ) ) then return false end
	for i = 1, #root.children do
		if WIDG.ContainsNode( root.children[ i ], node ) then return true end
	end
	return false
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	LAYOUT + PAINT ENGINE  —  walks a tree in element-local design space.
	Computed rects are stored in a weak side-table (nodes stay JSON-clean)
	and read back by the editor for hit-testing / overlays.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local rects = setmetatable( {}, { __mode = "k" } )

local function rectOf( node )
	local r = rects[ node ]
	if not r then r = { 0, 0, 0, 0 } rects[ node ] = r end
	return r
end

-- Element-local rect of a node as of its last paint. nil if never painted.
function WIDG.GetNodeRect( node )
	local r = rects[ node ]
	if not r then return nil end
	return r[ 1 ], r[ 2 ], r[ 3 ], r[ 4 ]
end

local paintNode -- fwd (lua-closures Rule 3)

local function paintChildren( node, t, ax, ay, w, h, ctx )
	local ch = node.children
	if not ch or #ch == 0 then return end
	local p = node.props or EMPTY
	local lay = t.layout

	if lay == "vstack" or lay == "hstack" then
		local pad    = p.pad or 0
		local gap    = p.gap or 4
		local align  = p.align or "start"
		local cursor = pad
		for i = 1, #ch do
			local c = ch[ i ]
			local cw, chh = c.w or 10, c.h or 10
			local cx, cy
			if lay == "vstack" then
				if align == "stretch" then cx, cw = pad, w - pad * 2
				elseif align == "center" then cx = ( w - cw ) * 0.5
				elseif align == "end" then cx = w - pad - cw
				else cx = pad end
				cy = cursor
				if c.visible ~= false then cursor = cursor + chh + gap end
			else
				if align == "stretch" then cy, chh = pad, h - pad * 2
				elseif align == "center" then cy = ( h - chh ) * 0.5
				elseif align == "end" then cy = h - pad - chh
				else cy = pad end
				cx = cursor
				if c.visible ~= false then cursor = cursor + cw + gap end
			end
			paintNode( c, ax + cx, ay + cy, cw, chh, ctx )
		end
	elseif lay == "overlap" then
		local pad = p.pad or 0
		local ah  = p.alignH or "left"
		local av  = p.alignV or "top"
		for i = 1, #ch do
			local c = ch[ i ]
			local cw, chh = c.w or 10, c.h or 10
			local cx, cy
			if ah == "stretch" then cx, cw = pad, w - pad * 2
			elseif ah == "center" then cx = ( w - cw ) * 0.5
			elseif ah == "right" then cx = w - pad - cw
			else cx = pad end
			if av == "stretch" then cy, chh = pad, h - pad * 2
			elseif av == "center" then cy = ( h - chh ) * 0.5
			elseif av == "bottom" then cy = h - pad - chh
			else cy = pad end
			paintNode( c, ax + cx, ay + cy, cw, chh, ctx )
		end
	else -- free canvas
		for i = 1, #ch do
			local c = ch[ i ]
			paintNode( c, ax + ( c.x or 0 ), ay + ( c.y or 0 ), c.w or 10, c.h or 10, ctx )
		end
	end
end

paintNode = function( node, ax, ay, w, h, ctx )
	local r = rectOf( node )
	r[ 1 ], r[ 2 ], r[ 3 ], r[ 4 ] = ax, ay, w, h

	local t = WIDG.Types[ node.type ]
	if not t then return end

	local hidden = ( node.visible == false )
	if hidden then
		if not CHUD.EditorActive then return end
		DRAW.PushAlpha( 0.25 )      -- ghost hidden nodes while editing
	end

	if t.Paint then t.Paint( node, ax, ay, w, h, node.props or EMPTY, ctx ) end
	if t.container then paintChildren( node, t, ax, ay, w, h, ctx ) end

	if hidden then DRAW.PopAlpha() end
end

-- Deepest node whose last-paint rect contains the element-local point.
function WIDG.NodeAt( root, lx, ly )
	local best = nil
	local function walk( node )
		local rx, ry, rw, rh = WIDG.GetNodeRect( node )
		if rx and lx >= rx and lx <= rx + rw and ly >= ry and ly <= ry + rh then
			best = node
		end
		if istable( node.children ) then
			for i = 1, #node.children do walk( node.children[ i ] ) end
		end
	end
	if istable( root ) then walk( root ) end
	return best
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	ELEMENT ENTRY POINT  —  def.Paint for widget-tree elements. The root node
	always tracks the element's design size, so trees scale with it.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local ctx = { pri = nil, sec = nil }

function WIDG.TreePaint( def, w, h, p, pri, sec )
	local l = CHUD.Layout[ def.id ]
	local root = l and l.tree
	if not istable( root ) then return end

	local acc = pri
	if p and p.useTheme == false then
		local c = p.accent
		if IsColor( c ) or ( istable( c ) and c.r ) then acc = c end
	end
	ctx.pri, ctx.sec = acc, sec
	paintNode( root, 0, 0, w, h, ctx )
end

-- Standard element-level params for every widget-tree element.
function WIDG.ElementParams()
	return {
		useTheme = { label = "Use Theme Colour", type = "bool",  default = true },
		accent   = { label = "Accent",           type = "color", default = Color( 0, 200, 255 ) },
	}, { "useTheme", "accent" }
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	SHARED PAINT HELPERS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
-- low-state: an auxiliary binding's frac at-or-under a threshold
local function isLow( p )
	local lb = p.lowBind
	if not lb or lb == "none" or lb == "" then return false end
	local lf = p.lowFrac or 0
	if lf <= 0 then return false end
	local _, frac = WIDG.Eval( lb )
	return frac ~= nil and frac <= lf
end

-- memoised uppercase / letterspace transforms (bounded caches)
local txCache = { {}, {}, {} }   -- 1=upper 2=ls 3=both
local txCount = { 0, 0, 0 }
local function transform( s, upper, ls )
	local mode = ( upper and 1 or 0 ) + ( ls and 2 or 0 )
	if mode == 0 then return s end
	local cache = txCache[ mode ]
	local v = cache[ s ]
	if v then return v end
	v = s
	if upper then v = string.upper( v ) end
	if ls then v = DRAW.LetterSpace( v ) end
	if txCount[ mode ] > 400 then
		txCache[ mode ] = {}
		txCount[ mode ] = 0
		cache = txCache[ mode ]
	end
	cache[ s ] = v
	txCount[ mode ] = txCount[ mode ] + 1
	return v
end

-- bound-or-literal text value with optional string.format
local function textValue( p )
	local v
	if p.bind and p.bind ~= "none" and p.bind ~= "" then v = WIDG.Eval( p.bind ) end
	if v == nil then v = p.text or "" end
	local fmt = p.format
	if fmt and fmt ~= "" and fmt ~= "%s" then
		local ok, s = pcall( string.format, fmt, v )
		if ok then v = s end
	end
	return tostring( v )
end

local function alignX( alignH, x, w )
	if alignH == "center" then return x + w * 0.5, A_C end
	if alignH == "right" then return x + w, A_R end
	return x, A_L
end

local function alignY( alignV, y, h )
	if alignV == "center" then return y + h * 0.5, A_C end
	if alignV == "bottom" then return y + h, A_B end
	return y, A_T
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	CONTAINER TYPES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local function containerBGSchema()
	return {
		bg          = { label = "Background",    type = "bool",   default = false },
		bgMode      = { label = "BG Colour",     type = "select", default = "bg", options = ROLES },
		bgColor     = { label = "BG Custom",     type = "color",  default = Color( 10, 10, 12, 220 ) },
		border      = { label = "Border",        type = "bool",   default = false },
		borderMode  = { label = "Border Colour", type = "select", default = "border", options = ROLES },
		borderColor = { label = "Border Custom", type = "color",  default = Color( 255, 255, 255, 42 ) },
	}
end

local function containerBGPaint( node, x, y, w, h, p, c )
	if p.bg then DRAW.Rect( x, y, w, h, roleColor( p.bgMode, p.bgColor, c ) ) end
	if p.border then DRAW.OutlinedBox( x, y, w, h, 1, roleColor( p.borderMode, p.borderColor, c ) ) end
end

local PANEL_SCHEMA = containerBGSchema()
CHUD.RegisterWidget( "panel", {
	label = "PANEL", category = "CONTAINERS", container = true, layout = "free",
	size = { w = 140, h = 90 }, icon = "icon16/application.png",
	schema = PANEL_SCHEMA,
	schemaOrder = { "bg", "bgMode", "bgColor", "border", "borderMode", "borderColor" },
	Paint = containerBGPaint,
} )

local function stackSchema()
	local s = containerBGSchema()
	s.pad   = { label = "Padding", type = "int", default = 0, min = 0, max = 128 }
	s.gap   = { label = "Gap",     type = "int", default = 4, min = 0, max = 64 }
	s.align = { label = "Cross Align", type = "select", default = "start",
		options = { "start", "center", "end", "stretch" } }
	return s
end
local STACK_ORDER = { "pad", "gap", "align", "bg", "bgMode", "bgColor", "border", "borderMode", "borderColor" }

CHUD.RegisterWidget( "vstack", {
	label = "V-STACK", category = "CONTAINERS", container = true, layout = "vstack",
	size = { w = 120, h = 90 }, icon = "icon16/application_split.png",
	schema = stackSchema(), schemaOrder = STACK_ORDER,
	Paint = containerBGPaint,
} )

CHUD.RegisterWidget( "hstack", {
	label = "H-STACK", category = "CONTAINERS", container = true, layout = "hstack",
	size = { w = 160, h = 30 }, icon = "icon16/application_tile_horizontal.png",
	schema = stackSchema(), schemaOrder = STACK_ORDER,
	Paint = containerBGPaint,
} )

local OVERLAP_SCHEMA = containerBGSchema()
OVERLAP_SCHEMA.pad    = { label = "Padding", type = "int", default = 0, min = 0, max = 128 }
OVERLAP_SCHEMA.alignH = { label = "Align H", type = "select", default = "left",
	options = { "left", "center", "right", "stretch" } }
OVERLAP_SCHEMA.alignV = { label = "Align V", type = "select", default = "top",
	options = { "top", "center", "bottom", "stretch" } }

CHUD.RegisterWidget( "overlap", {
	label = "OVERLAP", category = "CONTAINERS", container = true, layout = "overlap",
	size = { w = 120, h = 90 }, icon = "icon16/application_double.png",
	schema = OVERLAP_SCHEMA,
	schemaOrder = { "pad", "alignH", "alignV", "bg", "bgMode", "bgColor", "border", "borderMode", "borderColor" },
	Paint = containerBGPaint,
} )

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	TEXT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
CHUD.RegisterWidget( "text", {
	label = "TEXT", category = "WIDGETS",
	size = { w = 90, h = 16 }, icon = "icon16/textfield.png",
	schema = {
		text        = { label = "Text",         type = "string", default = "TEXT" },
		bind        = { label = "Data Binding", type = "select", default = "none", options = WIDG.BindOptions },
		format      = { label = "Format",       type = "string", default = "" },
		font        = { label = "Font",         type = "select", default = "ZDEV_HUD_Label", options = WIDG.FontOptions },
		colorMode   = { label = "Colour",       type = "select", default = "text", options = ROLES },
		color       = { label = "Custom Colour", type = "color", default = Color( 235, 240, 245 ) },
		alpha       = { label = "Alpha",        type = "int",    default = 255, min = 0, max = 255 },
		alignH      = { label = "Align H",      type = "select", default = "left", options = { "left", "center", "right" } },
		alignV      = { label = "Align V",      type = "select", default = "top", options = { "top", "center", "bottom" } },
		uppercase   = { label = "Uppercase",    type = "bool",   default = false },
		letterspace = { label = "Letterspace",  type = "bool",   default = false },
		shadow      = { label = "Shadow",       type = "bool",   default = false },
		lowBind     = { label = "Low-State Binding", type = "select", default = "none", options = WIDG.BindOptions },
		lowFrac     = { label = "Low-State Frac",    type = "number", default = 0.33, min = 0, max = 1, decimals = 2 },
		lowText     = { label = "Low-State Text",    type = "string", default = "" },
	},
	schemaOrder = { "text", "bind", "format", "font", "colorMode", "color", "alpha",
		"alignH", "alignV", "uppercase", "letterspace", "shadow", "lowBind", "lowFrac", "lowText" },
	Paint = function( node, x, y, w, h, p, c )
		local s = textValue( p )
		local low = isLow( p )
		if low and p.lowText and p.lowText ~= "" then s = p.lowText end
		s = transform( s, p.uppercase, p.letterspace )
		local clr = low and TH.bad or roleColor( p.colorMode, p.color, c )
		if ( p.alpha or 255 ) < 255 then clr = DRAW.Alpha( clr, p.alpha ) end
		local tx, xa = alignX( p.alignH, x, w )
		local ty, ya = alignY( p.alignV, y, h )
		if p.shadow then
			DRAW.ShadowText( s, p.font or "ZDEV_HUD_Label", tx, ty, clr, xa, ya )
		else
			SimpleText( s, p.font or "ZDEV_HUD_Label", tx, ty, clr, xa, ya )
		end
	end,
} )

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	LED NUMBER  (HoloNumber ghost-zero readout)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local holoOpts = {}
CHUD.RegisterWidget( "led", {
	label = "LED NUMBER", category = "WIDGETS",
	size = { w = 90, h = 30 }, icon = "icon16/calculator.png",
	schema = {
		bind      = { label = "Data Binding", type = "select", default = "health", options = WIDG.BindOptions },
		digits    = { label = "Ghost Digits (0=off)", type = "int", default = 3, min = 0, max = 6 },
		font      = { label = "Font",     type = "select", default = "ZDEV_HUD_LED", options = WIDG.FontOptions },
		colorMode = { label = "Colour",   type = "select", default = "accent", options = ROLES },
		color     = { label = "Custom Colour", type = "color", default = Color( 0, 200, 255 ) },
		alignH    = { label = "Align H",  type = "select", default = "left", options = { "left", "center", "right" } },
		glow      = { label = "Glow",     type = "bool", default = true },
		glowSize  = { label = "Glow Size",  type = "int", default = 40, min = 4, max = 128 },
		glowAlpha = { label = "Glow Alpha", type = "int", default = 50, min = 0, max = 255 },
		split     = { label = "Chromatic Split", type = "int", default = 2, min = 0, max = 8 },
		lowBind   = { label = "Low-State Binding", type = "select", default = "none", options = WIDG.BindOptions },
		lowFrac   = { label = "Low-State Frac", type = "number", default = 0.33, min = 0, max = 1, decimals = 2 },
	},
	schemaOrder = { "bind", "digits", "font", "colorMode", "color", "alignH",
		"glow", "glowSize", "glowAlpha", "split", "lowBind", "lowFrac" },
	Paint = function( node, x, y, w, h, p, c )
		local v = WIDG.Eval( p.bind )
		v = floor( tonumber( v ) or 0 )
		local clr
		if isLow( p ) then
			clr = DRAW.Alpha( TH.bad, 120 + 135 * ANIM.Pulse( 7 ) )
		else
			clr = roleColor( p.colorMode, p.color, c )
		end
		local tx, xa = alignX( p.alignH, x, w )
		holoOpts.digits    = ( p.digits or 0 ) > 0 and p.digits or nil
		holoOpts.align     = xa
		holoOpts.glow      = p.glow
		holoOpts.glowSize  = p.glowSize or 40
		holoOpts.glowAlpha = p.glowAlpha or 50
		holoOpts.split     = p.split or 2
		UI.HoloNumber( tx, y + h * 0.5, v, p.font or "ZDEV_HUD_LED", clr, holoOpts )
	end,
} )

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	TITLE CHIP  (inversion chip — house signature)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local chipOpts = {}
CHUD.RegisterWidget( "chip", {
	label = "TITLE CHIP", category = "WIDGETS",
	size = { w = 70, h = 16 }, icon = "icon16/tag_blue.png",
	schema = {
		text        = { label = "Text",         type = "string", default = "TITLE" },
		bind        = { label = "Data Binding", type = "select", default = "none", options = WIDG.BindOptions },
		font        = { label = "Font",   type = "select", default = "ZDEV_HUD_Label", options = WIDG.FontOptions },
		bgMode      = { label = "Chip Colour",  type = "select", default = "chip", options = ROLES },
		bgColor     = { label = "Chip Custom",  type = "color", default = Color( 228, 232, 236 ) },
		fgMode      = { label = "Text Colour",  type = "select", default = "chipText", options = ROLES },
		fgColor     = { label = "Text Custom",  type = "color", default = Color( 10, 10, 12 ) },
		maxChars    = { label = "Max Chars (0=off)", type = "int", default = 24, min = 0, max = 64 },
		uppercase   = { label = "Uppercase",    type = "bool", default = true },
		letterspace = { label = "Letterspace",  type = "bool", default = true },
		lowBind     = { label = "Low-State Binding", type = "select", default = "none", options = WIDG.BindOptions },
		lowFrac     = { label = "Low-State Frac", type = "number", default = 0.33, min = 0, max = 1, decimals = 2 },
	},
	schemaOrder = { "text", "bind", "font", "bgMode", "bgColor", "fgMode", "fgColor",
		"maxChars", "uppercase", "letterspace", "lowBind", "lowFrac" },
	Paint = function( node, x, y, w, h, p, c )
		local s = textValue( p )
		local mc = p.maxChars or 0
		if mc > 0 and #s > mc then s = string.sub( s, 1, mc ) end
		s = transform( s, p.uppercase, p.letterspace )
		chipOpts.font = p.font or "ZDEV_HUD_Label"
		chipOpts.bg   = isLow( p ) and TH.bad or roleColor( p.bgMode, p.bgColor, c )
		chipOpts.fg   = roleColor( p.fgMode, p.fgColor, c )
		UI.TitleChip( x, y, s, chipOpts )
	end,
} )

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	SHAPE  (rect / outline / cut-corner box / lines / circle / ring / cross)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
CHUD.RegisterWidget( "shape", {
	label = "SHAPE", category = "WIDGETS",
	size = { w = 60, h = 60 }, icon = "icon16/shape_square.png",
	schema = {
		kind      = { label = "Kind", type = "select", default = "rect",
			options = { "rect", "outline", "cutbox", "line_h", "line_v", "circle", "ring", "cross" } },
		colorMode = { label = "Colour",        type = "select", default = "border", options = ROLES },
		color     = { label = "Custom Colour", type = "color",  default = Color( 255, 255, 255, 42 ) },
		fillMode  = { label = "Fill Colour (cutbox)", type = "select", default = "bg", options = ROLES },
		fillColor = { label = "Fill Custom",   type = "color",  default = Color( 10, 10, 12, 220 ) },
		thickness = { label = "Thickness",     type = "int",    default = 1, min = 1, max = 24 },
		cut       = { label = "Corner Cut",    type = "int",    default = 10, min = 0, max = 40 },
		corners   = { label = "Cut Corners (bitmask)", type = "int", default = 5, min = 0, max = 15 },
	},
	schemaOrder = { "kind", "colorMode", "color", "fillMode", "fillColor", "thickness", "cut", "corners" },
	Paint = function( node, x, y, w, h, p, c )
		local clr = roleColor( p.colorMode, p.color, c )
		local kind = p.kind or "rect"
		if kind == "rect" then
			DRAW.Rect( x, y, w, h, clr )
		elseif kind == "outline" then
			DRAW.OutlinedBox( x, y, w, h, p.thickness or 1, clr )
		elseif kind == "cutbox" then
			UI.CutCornerBox( x, y, w, h, p.cut or 10,
				roleColor( p.fillMode, p.fillColor, c ), clr, p.corners or 5, p.thickness or 1 )
		elseif kind == "line_h" then
			DRAW.Rect( x, y, w, p.thickness or 1, clr )
		elseif kind == "line_v" then
			DRAW.Rect( x, y, p.thickness or 1, h, clr )
		elseif kind == "circle" then
			DRAW.Disc( x + w * 0.5, y + h * 0.5, min( w, h ) * 0.5, clr )
		elseif kind == "ring" then
			DRAW.Ring( x + w * 0.5, y + h * 0.5, min( w, h ) * 0.5, p.thickness or 1, clr )
		elseif kind == "cross" then
			DRAW.Cross( x + w * 0.5, y + h * 0.5, min( w, h ) * 0.5, 0, p.thickness or 1, clr )
		end
	end,
} )

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	PROGRESS BAR  (smooth fill + loss ghost + optional segment ticks)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
-- stable per-node loss keys (UI.Bar needs a string key for its anim state)
local lossKeys = setmetatable( {}, { __mode = "k" } )
local lossN = 0
local function lossKeyFor( node )
	local k = lossKeys[ node ]
	if not k then
		lossN = lossN + 1
		k = "chudw" .. lossN
		lossKeys[ node ] = k
	end
	return k
end

local barOpts = {}
CHUD.RegisterWidget( "bar", {
	label = "PROGRESS BAR", category = "WIDGETS",
	size = { w = 160, h = 8 }, icon = "icon16/chart_bar.png",
	schema = {
		bind      = { label = "Data Binding", type = "select", default = "health", options = WIDG.BindOptions },
		value     = { label = "Static Value (unbound)", type = "number", default = 0.75, min = 0, max = 1, decimals = 2 },
		fillMode  = { label = "Fill Colour",   type = "select", default = "accent", options = ROLES },
		fillColor = { label = "Fill Custom",   type = "color",  default = Color( 0, 200, 255 ) },
		bgAlpha   = { label = "BG Alpha",      type = "int",    default = 200, min = 0, max = 255 },
		border    = { label = "Border",        type = "bool",   default = true },
		loss      = { label = "Loss Ghost",    type = "bool",   default = true },
		hatch     = { label = "Hatch Fill",    type = "bool",   default = false },
		segments  = { label = "Segment Ticks (0=off)", type = "int", default = 0, min = 0, max = 40 },
		dir       = { label = "Direction", type = "select", default = "right", options = { "right", "left", "up", "down" } },
		lowFrac   = { label = "Low-State Frac (0=off)", type = "number", default = 0, min = 0, max = 1, decimals = 2 },
	},
	schemaOrder = { "bind", "value", "fillMode", "fillColor", "bgAlpha", "border",
		"loss", "hatch", "segments", "dir", "lowFrac" },
	Paint = function( node, x, y, w, h, p, c )
		local _, frac = WIDG.Eval( p.bind )
		frac = frac or p.value or 0
		local low = ( p.lowFrac or 0 ) > 0 and frac <= p.lowFrac
		barOpts.fill    = low and TH.bad or roleColor( p.fillMode, p.fillColor, c )
		barOpts.bg      = DRAW.Alpha( TH.bg, p.bgAlpha or 200 )
		barOpts.border  = p.border and TH.border or false
		barOpts.loss    = p.loss
		barOpts.lossKey = p.loss and lossKeyFor( node ) or nil
		barOpts.lossClr = DRAW.Alpha( TH.bad, 150 )
		barOpts.hatch   = p.hatch
		barOpts.dir     = p.dir or "right"
		UI.Bar( x, y, w, h, frac, barOpts )
		local segs = p.segments or 0
		if segs > 1 then
			local vertical = ( p.dir == "up" or p.dir == "down" )
			if vertical then
				local segH = h / segs
				for i = 1, segs - 1 do
					DRAW.Rect( x, y + i * segH, w, 1, TH.bg )
				end
			else
				local segW = w / segs
				for i = 1, segs - 1 do
					DRAW.Rect( x + i * segW, y, 1, h, TH.bg )
				end
			end
		end
	end,
} )

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	SEGMENT BAR  (discrete pips)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local segOpts = {}
CHUD.RegisterWidget( "segbar", {
	label = "SEGMENT BAR", category = "WIDGETS",
	size = { w = 160, h = 6 }, icon = "icon16/chart_bar_edit.png",
	schema = {
		bind     = { label = "Data Binding", type = "select", default = "armor", options = WIDG.BindOptions },
		value    = { label = "Static Value (unbound)", type = "number", default = 0.6, min = 0, max = 1, decimals = 2 },
		count    = { label = "Segments", type = "int", default = 10, min = 1, max = 40 },
		gap      = { label = "Gap",      type = "int", default = 2, min = 0, max = 16 },
		onMode   = { label = "On Colour",     type = "select", default = "text", options = ROLES },
		onColor  = { label = "On Custom",     type = "color",  default = Color( 235, 240, 245 ) },
		offAlpha = { label = "Off Alpha",     type = "int",    default = 220, min = 0, max = 255 },
		border   = { label = "Border",        type = "bool",   default = false },
	},
	schemaOrder = { "bind", "value", "count", "gap", "onMode", "onColor", "offAlpha", "border" },
	Paint = function( node, x, y, w, h, p, c )
		local _, frac = WIDG.Eval( p.bind )
		frac = frac or p.value or 0
		local count = p.count or 10
		segOpts.on     = roleColor( p.onMode, p.onColor, c )
		segOpts.off    = DRAW.Alpha( TH.bg, p.offAlpha or 220 )
		segOpts.border = p.border and TH.border or false
		segOpts.gap    = p.gap or 2
		UI.SegmentBar( x, y, w, h, count, floor( frac * count + 0.5 ), segOpts )
	end,
} )

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	CORNER BRACKETS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
CHUD.RegisterWidget( "brackets", {
	label = "BRACKETS", category = "WIDGETS",
	size = { w = 60, h = 60 }, icon = "icon16/shape_handles.png",
	schema = {
		len       = { label = "Arm Length", type = "int", default = 9, min = 2, max = 64 },
		thickness = { label = "Thickness",  type = "int", default = 1, min = 1, max = 8 },
		colorMode = { label = "Colour",     type = "select", default = "border", options = ROLES },
		color     = { label = "Custom Colour", type = "color", default = Color( 255, 255, 255, 42 ) },
	},
	schemaOrder = { "len", "thickness", "colorMode", "color" },
	Paint = function( node, x, y, w, h, p, c )
		UI.CornerBrackets( x, y, w, h, p.len or 9, p.thickness or 1, roleColor( p.colorMode, p.color, c ) )
	end,
} )

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	IMAGE / MATERIAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local matCache = {}
local function getMat( path )
	local m = matCache[ path ]
	if m == nil then
		m = Material( path )
		matCache[ path ] = m
	end
	return m
end

local imgClr = Color( 255, 255, 255, 255 )
CHUD.RegisterWidget( "image", {
	label = "IMAGE", category = "WIDGETS",
	size = { w = 48, h = 48 }, icon = "icon16/picture.png",
	schema = {
		material = { label = "Material Path", type = "string", default = "vgui/gradient-u" },
		color    = { label = "Tint",  type = "color", default = Color( 255, 255, 255 ) },
		alpha    = { label = "Alpha", type = "int",   default = 255, min = 0, max = 255 },
	},
	schemaOrder = { "material", "color", "alpha" },
	Paint = function( node, x, y, w, h, p, c )
		local path = p.material or ""
		local m = path ~= "" and getMat( path ) or nil
		if m and not m:IsError() then
			local t = p.color
			imgClr.r = t and t.r or 255
			imgClr.g = t and t.g or 255
			imgClr.b = t and t.b or 255
			imgClr.a = p.alpha or 255
			DRAW.TexturedRect( x, y, w, h, m, imgClr )
		else
			DRAW.OutlinedBox( x, y, w, h, 1, TH.bad )
			DRAW.Line( x, y, x + w, y + h, TH.bad )
			DRAW.Line( x + w, y, x, y + h, TH.bad )
		end
	end,
} )

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	EDITOR PALETTE  —  spawnable presets (label + type + prop overrides).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
WIDG.Palette = {
	{ label = "TEXT",        type = "text" },
	{ label = "TEXT RIGHT",  type = "text", props = { alignH = "right" } },
	{ label = "LABEL",       type = "text", props = { colorMode = "dim", uppercase = true, letterspace = true } },
	{ label = "LED NUMBER",  type = "led" },
	{ label = "TITLE CHIP",  type = "chip" },
	{ label = "SHAPE",       type = "shape" },
	{ label = "PROG BAR",    type = "bar" },
	{ label = "SEG BAR",     type = "segbar" },
	{ label = "BRACKETS",    type = "brackets" },
	{ label = "IMAGE",       type = "image" },
	{ label = "PANEL",       type = "panel" },
	{ label = "V-STACK",     type = "vstack" },
	{ label = "H-STACK",     type = "hstack" },
	{ label = "OVERLAP",     type = "overlap" },
}

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	CUSTOM ELEMENTS  —  user-created top-level HUD panels. The registration
	marker persists inside the layout (layout.custom = { label, size }) so
	profiles can re-create them on load.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function WIDG.RegisterCustom( id, label, size )
	local w = ( istable( size ) and tonumber( size.w ) ) or 240
	local h = ( istable( size ) and tonumber( size.h ) ) or 120
	local params, order = WIDG.ElementParams()
	local def = CHUD.Register( id, {
		label = label, custom = true,
		size = { w = w, h = h },
		anchor = "c", x = 0, y = 0,
		order = 60, parallax = 0.1,
		params = params, paramOrder = order,
		tree = { type = "panel", name = "ROOT", props = { border = true } },
		Paint = WIDG.TreePaint,
	} )

	local l = CHUD.Layout[ id ]
	l.custom = istable( l.custom ) and l.custom or {}
	l.custom.label = tostring( l.custom.label or label )
	if not istable( l.custom.size ) then l.custom.size = { w = w, h = h } end

	-- def.size follows the persisted size (custom panels are resizable)
	def.size.w = max( tonumber( l.custom.size.w ) or w, 8 )
	def.size.h = max( tonumber( l.custom.size.h ) or h, 8 )
	def.label = l.custom.label

	return id, def
end

function WIDG.CreateCustomElement( label, size )
	local i = 1
	while CHUD.Elements[ "custom_" .. i ] do i = i + 1 end
	local id = "custom_" .. i
	WIDG.RegisterCustom( id, label or ( "PANEL " .. i ), size )
	CHUD.MarkDirty()
	return id
end

-- Re-register custom elements found in a freshly-loaded layout (called by
-- CHUD.LoadProfile and once at file load for the boot-time "_active" load).
function WIDG.RestoreCustomElements()
	for id, l in pairs( CHUD.Layout ) do
		if istable( l ) and istable( l.custom ) and not CHUD.Elements[ id ] then
			WIDG.RegisterCustom( id, tostring( l.custom.label or id ), l.custom.size )
		end
	end
end

function WIDG.RemoveCustomElement( id )
	local def = CHUD.Elements[ id ]
	if not ( def and def.custom ) then return false end
	return CHUD.RemoveElement( id )
end

WIDG.RestoreCustomElements()

zdev.log( "S", "Loaded file: '" .. _f .. "'" )
ZDEV.FILE.SetLoaded( _f )

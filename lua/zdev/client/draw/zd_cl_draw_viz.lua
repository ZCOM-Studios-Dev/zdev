local _f = 'zdev/client/draw/zd_cl_draw_viz.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	zd_cl_draw_viz.lua  —  ZDEV.DRAW.VIZ  (advanced 2D visualisations)

	Data-driven, parametrised charts for dashboards / debug HUDs / tactical
	overlays. All built on ZDEV.DRAW primitives; each takes a plain data array
	and an `opts` table and auto-scales.

	  BarChart, LineGraph, Sparkline, Gauge, Radar, Heatmap, Minimap

	Concave shapes (Radar) are filled with a centroid triangle-fan, because
	surface.DrawPoly is convex-only (rule glua-2d-drawing Rule 2).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

ZDEV.DRAW     = ZDEV.DRAW or {}
ZDEV.DRAW.VIZ = ZDEV.DRAW.VIZ or {}

local DRAW = ZDEV.DRAW
local VIZ  = ZDEV.DRAW.VIZ

local SimpleText  = draw.SimpleText
local rad         = math.rad
local cos, sin    = math.cos, math.sin
local floor       = math.floor
local max, min    = math.max, math.min
local Clamp       = math.Clamp
local pi          = math.pi
local TAU         = pi * 2

local function themeFont() return ( DRAW.UI and DRAW.UI.THEME and DRAW.UI.THEME.font ) or "DermaDefault" end
local function themeClr( k, d ) return ( DRAW.UI and DRAW.UI.THEME and DRAW.UI.THEME[ k ] ) or d end
local function opt( o, k, d ) if o and o[ k ] ~= nil then return o[ k ] end return d end

-- min/max of a numeric array
local function extents( vals )
	local lo, hi = math.huge, -math.huge
	for _, v in ipairs( vals ) do
		if v < lo then lo = v end
		if v > hi then hi = v end
	end
	if lo == math.huge then return 0, 1 end
	if lo == hi then hi = lo + 1 end
	return lo, hi
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	BAR CHART  —  vertical bars from a value array.
	opts = { bg, bar, border, gap, maxVal, labels, font, labelClr, valueClr,
	         gradient, baseline }
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function VIZ.BarChart( x, y, w, h, values, opts )
	local n = #values
	if n == 0 then return end
	local gap    = opt( opts, "gap", 3 )
	local barClr = opt( opts, "bar", themeClr( "accent", Color( 0, 200, 255 ) ) )
	local maxVal = opt( opts, "maxVal", nil )
	if not maxVal then local _, hi = extents( values ) maxVal = hi end
	maxVal = maxVal <= 0 and 1 or maxVal

	if opt( opts, "bg", false ) then DRAW.Rect( x, y, w, h, opts.bg ) end

	local barW = ( w - gap * ( n - 1 ) ) / n
	local labels = opt( opts, "labels", nil )
	local font   = opt( opts, "font", themeFont() )
	for i = 1, n do
		local frac = Clamp( values[ i ] / maxVal, 0, 1 )
		local bh = h * frac
		local bx = x + ( i - 1 ) * ( barW + gap )
		local by = y + h - bh
		local c = isfunction( barClr ) and barClr( frac, i ) or barClr
		if opt( opts, "gradient", false ) then
			DRAW.GradientV( bx, by, barW, bh, DRAW.Brighten( c, 1.3 ), c )
		else
			DRAW.Rect( bx, by, barW, bh, c )
		end
		if labels and labels[ i ] then
			SimpleText( labels[ i ], font, bx + barW / 2, y + h + 2, opt( opts, "labelClr", themeClr( "textDim", color_white ) ), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
		end
	end
	if opt( opts, "border", false ) then DRAW.OutlinedBox( x, y, w, h, 1, opts.border ) end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	LINE GRAPH  —  one or more series.
	series may be a flat array (single series) OR { {values=,clr=,fill=}, ... }.
	opts = { bg, grid, gridClr, border, minVal, maxVal, thickness, axis }
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function VIZ.LineGraph( x, y, w, h, series, opts )
	-- normalise to a list of series
	if series[ 1 ] and isnumber( series[ 1 ] ) then
		series = { { values = series, clr = themeClr( "accent", Color( 0, 200, 255 ) ) } }
	end

	if opt( opts, "bg", false ) then DRAW.Rect( x, y, w, h, opts.bg ) end

	-- global extents across all series (unless overridden)
	local lo = opt( opts, "minVal", nil )
	local hi = opt( opts, "maxVal", nil )
	if not lo or not hi then
		local gl, gh = math.huge, -math.huge
		for _, s in ipairs( series ) do
			local a, b = extents( s.values )
			gl = min( gl, a ) ; gh = max( gh, b )
		end
		lo = lo or gl ; hi = hi or gh
	end
	local span = ( hi - lo ) == 0 and 1 or ( hi - lo )

	-- grid
	if opt( opts, "grid", false ) then
		local gclr = opt( opts, "gridClr", DRAW.Alpha( themeClr( "border", Color( 40, 70, 90 ) ), 90 ) )
		for i = 0, 4 do
			local gy = y + ( i / 4 ) * h
			DRAW.Rect( x, gy, w, 1, gclr )
		end
	end

	local thickness = opt( opts, "thickness", 1.5 )
	for _, s in ipairs( series ) do
		local vals = s.values
		local nn = #vals
		if nn >= 2 then
			local step = w / ( nn - 1 )
			local pts = {}
			for i = 1, nn do
				local frac = ( vals[ i ] - lo ) / span
				pts[ i ] = { x = x + ( i - 1 ) * step, y = y + h - Clamp( frac, 0, 1 ) * h }
			end
			-- optional area fill under the line (convex per-segment quads to baseline)
			if s.fill then
				local baseY = y + h
				for i = 1, nn - 1 do
					DRAW.Poly( {
						{ x = pts[ i ].x,     y = pts[ i ].y },
						{ x = pts[ i + 1 ].x, y = pts[ i + 1 ].y },
						{ x = pts[ i + 1 ].x, y = baseY },
						{ x = pts[ i ].x,     y = baseY },
					}, isbool( s.fill ) and DRAW.Alpha( s.clr, 40 ) or s.fill )
				end
			end
			DRAW.PolyLine( pts, s.clr, thickness )
		end
	end

	if opt( opts, "border", false ) then DRAW.OutlinedBox( x, y, w, h, 1, opts.border ) end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	SPARKLINE  —  tiny inline trend line (no axes).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function VIZ.Sparkline( x, y, w, h, values, clr, thickness )
	local n = #values
	if n < 2 then return end
	local lo, hi = extents( values )
	local span = ( hi - lo ) == 0 and 1 or ( hi - lo )
	local step = w / ( n - 1 )
	local pts = {}
	for i = 1, n do
		pts[ i ] = { x = x + ( i - 1 ) * step, y = y + h - ( ( values[ i ] - lo ) / span ) * h }
	end
	DRAW.PolyLine( pts, clr or themeClr( "accent", Color( 0, 200, 255 ) ), thickness or 1 )
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	GAUGE  —  radial arc gauge. frac 0..1.
	opts = { radius, thickness, bg, fill, startAng, sweep, text, font, textClr,
	         needle }
	Angles: startAng is the CW start (deg), sweep the total arc span (deg).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function VIZ.Gauge( x, y, frac, opts )
	frac = Clamp( frac or 0, 0, 1 )
	local radius = opt( opts, "radius", 48 )
	local thick  = opt( opts, "thickness", 8 )
	local bg     = opt( opts, "bg", DRAW.Alpha( themeClr( "border", Color( 40, 70, 90 ) ), 120 ) )
	local fill   = opt( opts, "fill", themeClr( "accent", Color( 0, 200, 255 ) ) )
	if isfunction( fill ) then fill = fill( frac ) end
	local startAng = opt( opts, "startAng", 220 )
	local sweep    = opt( opts, "sweep", -260 ) -- negative = clockwise sweep in screen space
	local seg = opt( opts, "segments", 48 )

	-- background track
	DRAW.Arc( x, y, radius, thick, startAng, startAng + sweep, bg, seg )
	-- value arc
	DRAW.Arc( x, y, radius, thick, startAng, startAng + sweep * frac, fill, max( 1, floor( seg * frac ) ) )

	if opt( opts, "needle", false ) then
		local a = rad( startAng + sweep * frac )
		DRAW.ThickLine( x, y, x + cos( a ) * ( radius - thick - 2 ), y - sin( a ) * ( radius - thick - 2 ), 2, fill )
		DRAW.Disc( x, y, 3, fill )
	end

	local text = opt( opts, "text", nil )
	if text then
		SimpleText( text, opt( opts, "font", themeFont() ), x, y, opt( opts, "textClr", themeClr( "text", color_white ) ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	RADAR / SPIDER CHART.
	axes   = { "SPD", "DMG", ... }  (labels)
	values = { 0.8, 0.5, ... }      (each 0..1)
	opts = { radius, rings, gridClr, fill, line, labelFont, labelClr }
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function VIZ.Radar( x, y, axes, values, opts )
	local n = #axes
	if n < 3 then return end
	local radius = opt( opts, "radius", 60 )
	local rings  = opt( opts, "rings", 4 )
	local gridClr = opt( opts, "gridClr", DRAW.Alpha( themeClr( "border", Color( 40, 70, 90 ) ), 140 ) )
	local fillClr = opt( opts, "fill", DRAW.Alpha( themeClr( "accent", Color( 0, 200, 255 ) ), 70 ) )
	local lineClr = opt( opts, "line", themeClr( "accent", Color( 0, 200, 255 ) ) )
	local labelFont = opt( opts, "labelFont", themeFont() )

	-- angle for axis i (start at top, go clockwise)
	local function axPos( i, r )
		local a = -pi / 2 + ( i - 1 ) / n * TAU
		return x + cos( a ) * r, y + sin( a ) * r
	end

	-- concentric ring grids + radial spokes
	for ring = 1, rings do
		local rr = radius * ( ring / rings )
		for i = 1, n do
			local ax, ay = axPos( i, rr )
			local bx, by = axPos( i % n + 1, rr )
			DRAW.Line( ax, ay, bx, by, gridClr )
		end
	end
	for i = 1, n do
		local ax, ay = axPos( i, radius )
		DRAW.Line( x, y, ax, ay, gridClr )
		-- axis label just outside
		local lx, ly = axPos( i, radius + 12 )
		SimpleText( axes[ i ], labelFont, lx, ly, opt( opts, "labelClr", themeClr( "textDim", color_white ) ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	-- data polygon (centroid fan fill — handles concave shapes)
	local pts = {}
	for i = 1, n do
		local vx, vy = axPos( i, radius * Clamp( values[ i ] or 0, 0, 1 ) )
		pts[ i ] = { x = vx, y = vy }
	end
	for i = 1, n do
		local a, b = pts[ i ], pts[ i % n + 1 ]
		DRAW.Poly( { { x = x, y = y }, { x = a.x, y = a.y }, { x = b.x, y = b.y } }, fillClr )
	end
	-- outline + vertex dots
	for i = 1, n do
		local a, b = pts[ i ], pts[ i % n + 1 ]
		DRAW.ThickLine( a.x, a.y, b.x, b.y, 1.5, lineClr )
		DRAW.Disc( a.x, a.y, 2, lineClr )
	end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	HEATMAP  —  2D intensity grid. `grid` is a rows×cols array of 0..1 (or raw
	values with opts.maxVal). Cells are coloured by lerping loClr→hiClr.
	grid = { { v,v,v }, { v,v,v } }  (grid[row][col])
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function VIZ.Heatmap( x, y, w, h, grid, opts )
	local rows = #grid
	if rows == 0 then return end
	local cols = #grid[ 1 ]
	if cols == 0 then return end
	local loClr = opt( opts, "lo", Color( 20, 30, 60, 255 ) )
	local hiClr = opt( opts, "hi", Color( 255, 80, 40, 255 ) )
	local maxVal = opt( opts, "maxVal", 1 )
	local gap = opt( opts, "gap", 0 )
	local cw = ( w - gap * ( cols - 1 ) ) / cols
	local ch = ( h - gap * ( rows - 1 ) ) / rows
	for r = 1, rows do
		for c = 1, cols do
			local v = Clamp( ( grid[ r ][ c ] or 0 ) / maxVal, 0, 1 )
			DRAW.Rect( x + ( c - 1 ) * ( cw + gap ), y + ( r - 1 ) * ( ch + gap ), cw, ch, DRAW.LerpColor( v, loClr, hiClr ) )
		end
	end
	if opt( opts, "border", false ) then DRAW.OutlinedBox( x, y, w, h, 1, opts.border ) end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	MINIMAP  —  heading-up tactical map.  (mapping)
	Draws a framed map around `center` (a Vector, usually the player's pos) and
	plots `blips` (world Vectors) rotated so `heading` (deg, usually eye yaw) is
	up. opts = { scale (world-units per pixel), bg, border, ring, blipR, north,
	             player, playerClr, rotate }
	blips = { { pos = Vector, clr = Color, r = , label = }, ... }
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function VIZ.Minimap( x, y, size, center, heading, blips, opts )
	local hs = size * 0.5
	local cx, cy = x + hs, y + hs
	local scale = opt( opts, "scale", 12 ) -- world units per pixel
	local rotate = opt( opts, "rotate", true )
	local yaw = rad( rotate and ( heading or 0 ) or 0 )
	-- To make `heading` point up, rotate world delta by -(yaw - 90°)… we align
	-- the forward axis to screen-up (negative Y).
	local ca, sa = cos( -yaw ), sin( -yaw )

	-- frame
	DRAW.Rect( x, y, size, size, opt( opts, "bg", DRAW.Alpha( themeClr( "bg", Color( 10, 14, 18 ) ), 220 ) ) )
	DRAW.OutlinedBox( x, y, size, size, 1, opt( opts, "border", themeClr( "border", Color( 40, 70, 90 ) ) ) )
	if opt( opts, "ring", true ) then
		DRAW.CircleOutline( cx, cy, hs - 2, 1, DRAW.Alpha( themeClr( "accent", Color( 0, 200, 255 ) ), 90 ), 48 )
	end

	-- clip blips to the map box
	DRAW.PushClip( x, y, size, size )
	if blips then
		local blipR = opt( opts, "blipR", 3 )
		for _, b in ipairs( blips ) do
			local d = b.pos - center
			-- world X/Y → map space (heading-up). Note screen Y is down.
			local wx, wy = d.x / scale, d.y / scale
			local mx = wx * ca - wy * sa
			local my = wx * sa + wy * ca
			local px, py = cx + mx, cy - my
			-- keep inside the circle
			local dx, dy = px - cx, py - cy
			if dx * dx + dy * dy <= ( hs - blipR ) * ( hs - blipR ) then
				DRAW.Disc( px, py, b.r or blipR, b.clr or themeClr( "bad", Color( 235, 75, 75 ) ) )
				if b.label then
					SimpleText( b.label, themeFont(), px, py - ( b.r or blipR ) - 2, themeClr( "text", color_white ), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM )
				end
			end
		end
	end
	DRAW.PopClip()

	-- player arrow at centre (always up)
	if opt( opts, "player", true ) then
		local pc = opt( opts, "playerClr", themeClr( "accent", Color( 0, 200, 255 ) ) )
		DRAW.Triangle( cx, cy - 6, cx - 4, cy + 4, cx + 4, cy + 4, pc )
	end

	-- north indicator (rotates opposite to heading)
	if opt( opts, "north", true ) then
		local na = -yaw - pi / 2 -- world north (+? ) mapped; place "N" glyph on ring
		local nx = cx + cos( na ) * ( hs - 10 )
		local ny = cy - sin( na ) * ( hs - 10 )
		SimpleText( "N", themeFont(), nx, ny, themeClr( "bad", Color( 235, 75, 75 ) ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUI DATA COMPONENTS  (from the ZDEV UI aesthetic standard — cinematic telemetry:
	barcodes, data-matrix blocks, hex-dump rows, node/plexus graphs, wireframe globes,
	radial equalizers). All deterministic-from-seed so they don't strobe each frame
	unless `animate` is set.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- BARCODE strip. Widths/gaps derived deterministically from `seed`.
function VIZ.Barcode( x, y, w, h, seed, opts )
	seed = seed or 1
	local clr = opt( opts, "clr", themeClr( "text", color_white ) )
	local r, g, b, a = clr.r, clr.g, clr.b, clr.a or 255
	surface.SetDrawColor( r, g, b, a )
	local cx = x
	local i = 0
	while cx < x + w do
		i = i + 1
		local bw = 1 + ( ( seed * 7 + i * 13 ) % 4 )
		if ( ( seed + i * 5 ) % 3 ) ~= 0 then
			surface.DrawRect( cx, y, math.min( bw, x + w - cx ), h )
		end
		cx = cx + bw + 1
	end
end

-- DATA-MATRIX block: grid of lit/unlit cells (deterministic; optional `animate`).
function VIZ.DataMatrix( x, y, w, h, cols, rows, opts )
	cols = max( 1, floor( cols or 16 ) )
	rows = max( 1, floor( rows or 8 ) )
	local clr = opt( opts, "clr", themeClr( "accent", Color( 0, 200, 255 ) ) )
	local gap = opt( opts, "gap", 1 )
	local density = opt( opts, "density", 0.4 )
	local seed = opt( opts, "seed", 0 )
	local t = opt( opts, "animate", false ) and floor( RealTime() * 4 ) or 0
	local cw = ( w - gap * ( cols - 1 ) ) / cols
	local ch = ( h - gap * ( rows - 1 ) ) / rows
	for ry = 0, rows - 1 do
		for cxi = 0, cols - 1 do
			local hsh = ( ( ry * 31 + cxi * 17 + seed + t * 7 ) % 100 ) / 100
			if hsh < density then
				DRAW.Rect( x + cxi * ( cw + gap ), y + ry * ( ch + gap ), cw, ch, clr )
			end
		end
	end
end

-- DATA STREAM: hex-dump / fragment rows with an inline % bar (the Oracle look).
-- rows = { { id = "0x2F", text = "4AED:39:40…", pct = 0.98 }, ... }. Returns height.
function VIZ.DataStream( x, y, w, rows, opts )
	local font   = opt( opts, "font", themeFont() )
	local rowH   = opt( opts, "rowH", 14 )
	local idClr  = opt( opts, "idClr", themeClr( "accent", Color( 0, 200, 255 ) ) )
	local txtClr = opt( opts, "textClr", themeClr( "textDim", Color( 130, 150, 165 ) ) )
	local barClr = opt( opts, "barClr", themeClr( "accent", Color( 0, 200, 255 ) ) )
	local barW   = opt( opts, "barW", 64 )
	local idW    = opt( opts, "idW", 46 )
	for i, rrow in ipairs( rows ) do
		local ry = y + ( i - 1 ) * rowH
		if rrow.id then SimpleText( rrow.id, font, x, ry, idClr, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ) end
		if rrow.text then SimpleText( rrow.text, font, x + idW, ry, txtClr, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP ) end
		if rrow.pct then
			local bx = x + w - barW
			DRAW.Rect( bx, ry + 2, barW, rowH - 5, DRAW.Alpha( themeClr( "bg", Color( 10, 14, 18 ) ), 220 ) )
			DRAW.Rect( bx, ry + 2, barW * Clamp( rrow.pct, 0, 1 ), rowH - 5, barClr )
			SimpleText( floor( rrow.pct * 100 ) .. "%", font, bx + barW / 2, ry, themeClr( "text", color_white ), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
		end
	end
	return #rows * rowH
end

-- PLEXUS: node-network graph. `count` nodes placed deterministically; near nodes
-- are linked (alpha by proximity). opts.animate gently drifts them.
function VIZ.Plexus( x, y, w, h, count, opts )
	count = max( 2, floor( count or 12 ) )
	local seed    = opt( opts, "seed", 1 )
	local lineClr = opt( opts, "line", themeClr( "accent", Color( 0, 200, 255 ) ) )
	local nodeClr = opt( opts, "node", themeClr( "accent", Color( 0, 200, 255 ) ) )
	local maxDist = opt( opts, "maxDist", min( w, h ) * 0.45 )
	local nodes = {}
	local drift = opt( opts, "animate", false )
	local t = drift and RealTime() or 0
	for i = 1, count do
		local a = ( ( seed * 13 + i * 29 ) % 1000 ) / 1000
		local b = ( ( seed * 7  + i * 53 ) % 1000 ) / 1000
		local nx = x + a * w
		local ny = y + b * h
		if drift then nx = nx + sin( t * 0.5 + i ) * 3 ; ny = ny + cos( t * 0.4 + i * 1.3 ) * 3 end
		nodes[ i ] = { x = nx, y = ny }
	end
	for i = 1, count do
		for j = i + 1, count do
			local dx, dy = nodes[ i ].x - nodes[ j ].x, nodes[ i ].y - nodes[ j ].y
			local d = math.sqrt( dx * dx + dy * dy )
			if d < maxDist then
				DRAW.Line( nodes[ i ].x, nodes[ i ].y, nodes[ j ].x, nodes[ j ].y,
					DRAW.Alpha( lineClr, 140 * ( 1 - d / maxDist ) ) )
			end
		end
	end
	for i = 1, count do DRAW.Disc( nodes[ i ].x, nodes[ i ].y, opt( opts, "nodeR", 2 ), nodeClr ) end
end

-- GLOBE: rotating dotted wireframe sphere (orthographic). Front dots bright, back dim.
function VIZ.Globe( x, y, radius, opts )
	local clr  = opt( opts, "clr", themeClr( "accent", Color( 0, 200, 255 ) ) )
	local lats = opt( opts, "lats", 7 )
	local dots = opt( opts, "dots", 28 )
	local rot  = rad( RealTime() * opt( opts, "spin", 18 ) )
	DRAW.CircleOutline( x, y, radius, 1, DRAW.Alpha( clr, 110 ), 48 )
	local br, bg, bb = clr.r, clr.g, clr.b
	for i = 1, lats do
		local phi = ( i / ( lats + 1 ) - 0.5 ) * pi
		local cphi, sphi = cos( phi ), sin( phi )
		for k = 0, dots - 1 do
			local a  = ( k / dots ) * TAU + rot
			local x3 = cphi * cos( a )
			local z3 = cphi * sin( a )
			local px = x + x3 * radius
			local py = y - sphi * radius
			surface.SetDrawColor( br, bg, bb, z3 >= 0 and 210 or 45 )
			surface.DrawRect( px - 0.5, py - 0.5, 1.4, 1.4 )
		end
	end
end

-- RADIAL EQUALIZER: bars radiating from a centre ring. opts.values = {0..1,…} or animated.
function VIZ.Equalizer( x, y, radius, bands, opts )
	bands = max( 3, floor( bands or 32 ) )
	local clr    = opt( opts, "clr", themeClr( "accent", Color( 0, 200, 255 ) ) )
	local maxLen = opt( opts, "length", radius * 0.7 )
	local thick  = opt( opts, "thickness", 2 )
	local speed  = opt( opts, "speed", 4 )
	local vals   = opt( opts, "values", nil )
	DRAW.CircleOutline( x, y, radius, 1, DRAW.Alpha( clr, 120 ), 48 )
	for i = 0, bands - 1 do
		local a = ( i / bands ) * TAU
		local v = vals and Clamp( vals[ i + 1 ] or 0, 0, 1 ) or ( 0.5 + 0.5 * sin( RealTime() * speed + i * 0.5 ) )
		local ca, sa = cos( a ), sin( a )
		local len = maxLen * v
		DRAW.ThickLine( x + ca * radius, y + sa * radius,
			x + ca * ( radius + len ), y + sa * ( radius + len ), thick,
			DRAW.LerpColor( v, DRAW.Alpha( clr, 110 ), clr ) )
	end
end

zdev.log( "S", "Loaded file: '" .. _f .. "'" )
ZDEV.FILE.SetLoaded( _f )

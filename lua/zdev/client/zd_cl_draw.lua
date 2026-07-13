local _f = 'zdev/client/zd_cl_draw.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	zd_cl_draw.lua  —  ZDEV Core 2D Draw Library (CORE)
	Author:      zcomstudios
	Description: Time-saving utility functions for drawing basic 2D primitives
	             and the complementary components of common 2D rendering hooks
	             (HUDPaint, PaintOver, PostDrawHUD, VGUI Paint).

	This CORE file provides:
	  · ZDEV.DRAW.*        — primitives (rect, line, poly, circle, arc, gradient …)
	  · ZDEV.DRAW.TEXT.*   — animated / stylised text effects
	  · color + clip helpers

	Extension modules (loaded at the bottom of this file):
	  · draw/zd_cl_draw_anim.lua  — ZDEV.TWEEN (easing) + ZDEV.ANIM (animators)
	  · draw/zd_cl_draw_fx.lua    — ZDEV.DRAW.FX  (scanlines, glitch, glow, blur …)
	  · draw/zd_cl_draw_ui.lua    — ZDEV.DRAW.UI  (panels, callouts, markers, bars …)
	  · draw/zd_cl_draw_viz.lua   — ZDEV.DRAW.VIZ (charts, gauges, radar, heatmap …)

	Design goals: optimization, modularity, adaptability, parametrisation and
	consistency. Every public function is namespaced under ZDEV.DRAW / ZDEV.TWEEN
	/ ZDEV.ANIM — no new globals are introduced (legacy global aliases for the
	old Moat text effects are kept only for backwards-compat).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

ZDEV.DRAW      = ZDEV.DRAW or {}
ZDEV.DRAW.TEXT = ZDEV.DRAW.TEXT or {}
ZDEV.TWEEN     = ZDEV.TWEEN or {}

local DRAW = ZDEV.DRAW

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	Localised references (hot-path micro-optimisation)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local surface          = surface
local draw             = draw
local render           = render
local cam              = cam
local SetDrawColor     = surface.SetDrawColor
local SetMaterial      = surface.SetMaterial
local DrawRect         = surface.DrawRect
local DrawOutlinedRect = surface.DrawOutlinedRect
local DrawLine         = surface.DrawLine
local DrawPoly         = surface.DrawPoly
local DrawTexturedRect = surface.DrawTexturedRect
local DrawTexRectUV    = surface.DrawTexturedRectUV
local DrawTexRectRot   = surface.DrawTexturedRectRotated
local NoTexture        = draw.NoTexture
local SimpleText       = draw.SimpleText
local GetTextSize      = surface.GetTextSize
local SetFont          = surface.SetFont
local RoundedBox       = draw.RoundedBox

local rad, deg   = math.rad, math.deg
local cos, sin   = math.cos, math.sin
local atan2      = math.atan2
local abs, sqrt  = math.abs, math.sqrt
local floor      = math.floor
local min, max   = math.min, math.max
local Clamp      = math.Clamp
local pi         = math.pi
local TAU        = pi * 2

local color_white = color_white
local color_black = Color( 0, 0, 0 )

local GRAD_U = Material( "vgui/gradient-u" ) -- transparent at top,  solid at bottom
local GRAD_L = Material( "vgui/gradient-l" ) -- transparent at left, solid at right

-- Normalise a colour-ish argument to r,g,b,a numbers (accepts a Color or nil).
local function unpackClr( c )
	if not c then return 255, 255, 255, 255 end
	return c.r or 255, c.g or 255, c.b or 255, c.a or 255
end
DRAW.UnpackColor = unpackClr

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	COLOUR HELPERS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Linearly interpolate two colours. frac 0 => c1, 1 => c2.
function DRAW.LerpColor( frac, c1, c2 )
	frac = Clamp( frac, 0, 1 )
	return Color(
		c1.r + ( c2.r - c1.r ) * frac,
		c1.g + ( c2.g - c1.g ) * frac,
		c1.b + ( c2.b - c1.b ) * frac,
		( c1.a or 255 ) + ( ( c2.a or 255 ) - ( c1.a or 255 ) ) * frac
	)
end

-- Return a copy of clr with a new alpha (thin wrapper for consistency).
function DRAW.Alpha( clr, a )
	return Color( clr.r, clr.g, clr.b, a )
end

-- Multiply a colour's brightness (value) by mul, clamped 0-255.
function DRAW.Brighten( clr, mul )
	return Color( Clamp( clr.r * mul, 0, 255 ), Clamp( clr.g * mul, 0, 255 ), Clamp( clr.b * mul, 0, 255 ), clr.a )
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	ALPHA-MULTIPLIER STACK  (fade an ENTIRE composite of draw calls with one
	value — technique from HoloHUD2 render.StartAlphaMultiplier). Nested-aware:
	each push multiplies with the current multiplier, so fades compose.

		ZDEV.DRAW.PushAlpha( frac )   -- e.g. ZDEV.ANIM.Fade( "panel", shown )
			…draw a whole panel of many primitives…
		ZDEV.DRAW.PopAlpha()
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local GetAlphaMult = surface.GetAlphaMultiplier
local SetAlphaMult = surface.SetAlphaMultiplier
local alphaStack   = {}

-- Push a new alpha multiplier. `absolute` ignores the current multiplier.
function DRAW.PushAlpha( mult, absolute )
	local cur = GetAlphaMult()
	alphaStack[ #alphaStack + 1 ] = cur
	SetAlphaMult( absolute and mult or ( mult * cur ) )
end

-- Restore the previous alpha multiplier.
function DRAW.PopAlpha()
	local n = #alphaStack
	if n == 0 then SetAlphaMult( 1 ) return end
	SetAlphaMult( alphaStack[ n ] )
	alphaStack[ n ] = nil
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	SCISSOR / CLIP STACK   (clip custom drawing to a rectangle — see rule
	glua-2d-drawing Rule 4: poly/rect fills ignore DScrollPanel canvas bounds)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local clipStack = {}

-- Intersects with the current clip (if any) so nested clips behave correctly.
function DRAW.PushClip( x, y, w, h )
	local x2, y2 = x + w, y + h
	local top = clipStack[ #clipStack ]
	if top then
		x  = max( x,  top[ 1 ] ); y  = max( y,  top[ 2 ] )
		x2 = min( x2, top[ 3 ] ); y2 = min( y2, top[ 4 ] )
	end
	clipStack[ #clipStack + 1 ] = { x, y, x2, y2 }
	render.SetScissorRect( x, y, x2, y2, true )
end

function DRAW.PopClip()
	clipStack[ #clipStack ] = nil
	local top = clipStack[ #clipStack ]
	if top then
		render.SetScissorRect( top[ 1 ], top[ 2 ], top[ 3 ], top[ 4 ], true )
	else
		render.SetScissorRect( 0, 0, 0, 0, false )
	end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	RECTANGLES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Solid rectangle. clr may be a Color.
function DRAW.Rect( x, y, w, h, clr )
	local r, g, b, a = unpackClr( clr )
	SetDrawColor( r, g, b, a )
	DrawRect( x, y, w, h )
end

-- Outlined rectangle drawn inward by `thickness` pixels (1px default).
function DRAW.OutlinedBox( x, y, w, h, thickness, clr )
	thickness = thickness or 1
	local r, g, b, a = unpackClr( clr )
	SetDrawColor( r, g, b, a )
	for i = 0, thickness - 1 do
		DrawOutlinedRect( x + i, y + i, w - i * 2, h - i * 2 )
	end
end

-- A rectangle with an outline in one call (fillClr optional, outlineClr optional).
function DRAW.FramedBox( x, y, w, h, fillClr, outlineClr, thickness )
	if fillClr then DRAW.Rect( x, y, w, h, fillClr ) end
	if outlineClr then DRAW.OutlinedBox( x, y, w, h, thickness or 1, outlineClr ) end
end

-- Rounded box (thin namespaced wrapper over draw.RoundedBox for consistency).
function DRAW.RoundedBox( radius, x, y, w, h, clr )
	RoundedBox( radius, x, y, w, h, clr or color_white )
end

-- Textured rectangle. PRESERVED SIGNATURE (used across zdev + zdev_sweps).
function DRAW.TexturedRect( x, y, w, h, mat, clr )
	NoTexture()
	local r, g, b, a = unpackClr( clr )
	SetDrawColor( r, g, b, a )
	SetMaterial( mat )
	DrawTexturedRect( x, y, w, h )
end
DRAW.MaterialBox = DRAW.TexturedRect          -- PRESERVED ALIAS

-- Textured rectangle with explicit UV window. PRESERVED SIGNATURE.
function DRAW.UVTexturedRect( x, y, w, h, u, v, u0, v0, mat, clr )
	NoTexture()
	SetMaterial( mat )
	SetDrawColor( clr or color_white )
	DrawTexRectUV( x, y, w, h, u, v, u0, v0 )
end

-- Rotated textured rectangle about its centre. PRESERVED SIGNATURE.
function DRAW.TexturedRectRot( x, y, w, h, ang, mat, clr )
	NoTexture()
	SetMaterial( mat )
	SetDrawColor( clr or color_white )
	DrawTexRectRot( x, y, w, h, ang )
end

-- Rotated textured rectangle about an offset pivot (x0,y0). PRESERVED SIGNATURE.
function DRAW.TexturedRectRotPoint( x, y, w, h, rot, x0, y0, mat, clr )
	local c = cos( rad( rot ) )
	local s = sin( rad( rot ) )
	local nx = y0 * s - x0 * c
	local ny = y0 * c + x0 * s
	NoTexture()
	SetMaterial( mat )
	SetDrawColor( clr or color_white )
	DrawTexRectRot( x + nx, y + ny, w, h, rot )
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	GRADIENTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Vertical gradient from top colour c1 to bottom colour c2.
function DRAW.GradientV( x, y, w, h, c1, c2 )
	DRAW.Rect( x, y, w, h, c1 )
	local r, g, b, a = unpackClr( c2 )
	SetDrawColor( r, g, b, a )
	SetMaterial( GRAD_U )                       -- solid at bottom, fades to top
	DrawTexturedRect( x, y, w, h )
end

-- Horizontal gradient from left colour c1 to right colour c2.
function DRAW.GradientH( x, y, w, h, c1, c2 )
	DRAW.Rect( x, y, w, h, c1 )
	local r, g, b, a = unpackClr( c2 )
	SetDrawColor( r, g, b, a )
	SetMaterial( GRAD_L )                       -- solid at right, fades to left
	DrawTexturedRect( x, y, w, h )
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	DIAGONAL HATCH  (the 45° striped texture-fill that recurs across FUI kits —
	used for progress fills, region textures, "no signal" states). Clipped to the
	rect. `dir` +1 = "/" stripes (default), -1 = "\" stripes. `scroll` animates.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function DRAW.HatchRect( x, y, w, h, spacing, clr, thickness, dir, scroll )
	spacing   = spacing or 6
	thickness = thickness or 1
	dir       = dir or 1
	DRAW.PushClip( x, y, w, h )
	local off = scroll and ( ( RealTime() * scroll ) % spacing ) or 0
	if thickness <= 1 then
		local r, g, b, a = unpackClr( clr )
		SetDrawColor( r, g, b, a )
		local i = -h + off
		while i < w do
			if dir >= 0 then DrawLine( x + i, y + h, x + i + h, y )        -- "/"
			else             DrawLine( x + i, y, x + i + h, y + h ) end     -- "\"
			i = i + spacing
		end
	else
		local i = -h + off
		while i < w do
			if dir >= 0 then DRAW.ThickLine( x + i, y + h, x + i + h, y, thickness, clr )
			else             DRAW.ThickLine( x + i, y, x + i + h, y + h, thickness, clr ) end
			i = i + spacing
		end
	end
	DRAW.PopClip()
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	LINES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- 1px line.
function DRAW.Line( x1, y1, x2, y2, clr )
	local r, g, b, a = unpackClr( clr )
	SetDrawColor( r, g, b, a )
	DrawLine( x1, y1, x2, y2 )
end

-- Variable-thickness line via a rotated textured rect (surface.DrawLine is 1px only).
function DRAW.ThickLine( x1, y1, x2, y2, thickness, clr )
	thickness = thickness or 1
	if thickness <= 1 then return DRAW.Line( x1, y1, x2, y2, clr ) end
	local dx, dy = x2 - x1, y2 - y1
	local len = sqrt( dx * dx + dy * dy )
	if len < 0.5 then return end
	local r, g, b, a = unpackClr( clr )
	SetDrawColor( r, g, b, a )
	NoTexture()
	DrawTexRectRot( ( x1 + x2 ) * 0.5, ( y1 + y2 ) * 0.5, len, thickness,
		deg( atan2( y1 - y2, x2 - x1 ) ) )
end

-- Poly-line: connect a list of {x=,y=} points; optional thickness (default 1).
function DRAW.PolyLine( pts, clr, thickness )
	local n = #pts
	if n < 2 then return end
	thickness = thickness or 1
	if thickness <= 1 then
		local r, g, b, a = unpackClr( clr )
		SetDrawColor( r, g, b, a )
		for i = 1, n - 1 do
			DrawLine( pts[ i ].x, pts[ i ].y, pts[ i + 1 ].x, pts[ i + 1 ].y )
		end
	else
		for i = 1, n - 1 do
			DRAW.ThickLine( pts[ i ].x, pts[ i ].y, pts[ i + 1 ].x, pts[ i + 1 ].y, thickness, clr )
		end
	end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	POLYGONS  (surface.DrawPoly is convex-only, clockwise, texture-bound —
	           see rule glua-2d-drawing Rule 1/2)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Solid convex polygon from a vertex list ( { {x=,y=}, ... } , clockwise ).
function DRAW.Poly( pts, clr )
	local r, g, b, a = unpackClr( clr )
	SetDrawColor( r, g, b, a )
	NoTexture()
	DrawPoly( pts )
end

-- Triangle from three points.
function DRAW.Triangle( x1, y1, x2, y2, x3, y3, clr )
	DRAW.Poly( { { x = x1, y = y1 }, { x = x2, y = y2 }, { x = x3, y = y3 } }, clr )
end

-- Regular n-sided polygon centred at (x,y). rotation in degrees.
function DRAW.RegularPolygon( x, y, radius, sides, rotation, clr )
	sides = max( 3, floor( sides or 3 ) )
	local rot = rad( rotation or 0 )
	local pts = {}
	for i = 0, sides - 1 do
		local a = rot + ( i / sides ) * TAU
		pts[ i + 1 ] = { x = x + cos( a ) * radius, y = y + sin( a ) * radius }
	end
	DRAW.Poly( pts, clr )
end

-- Trapezoid. PRESERVED SIGNATURE.
function DRAW.Trapezoid( x, y, w, h, z, clr )
	NoTexture()
	local r, g, b, a = unpackClr( clr or color_white )
	SetDrawColor( r, g, b, a )
	DrawPoly( {
		{ x = ( w + z ) + x, y = y + h },
		{ x = x,             y = y + h },
		{ x = x + z,         y = y     },
		{ x = w + x,         y = y     },
	} )
end

-- Diamond / rhombus. PRESERVED SIGNATURE (x,y,w,h,col,col2).
function DRAW.Diamond( x, y, w, h, col, col2 )
	local dH = h / 2
	local dat = {
		{ x = x,         y = y + dH, u = 0,             v = 0.5 },
		{ x = x + dH,    y = y,      u = dH / w,        v = 0   },
		{ x = x + w - dH,y = y,      u = ( w - dH ) / w,v = 0   },
		{ x = x + w,     y = y + dH, u = 1,             v = 0.5 },
		{ x = x + w - dH,y = y + h,  u = ( w - dH ) / w,v = 1   },
		{ x = x + dH,    y = y + h,  u = dH / w,        v = 1   },
	}
	local r, g, b, a = unpackClr( col )
	SetDrawColor( r, g, b, a )
	NoTexture()
	DrawPoly( dat )
	if col2 then
		DRAW.Diamond( x + 5, y + 5, w - 10, h - 10, col2 )
	end
end

-- Star (8-point). PRESERVED SIGNATURE (x,y,r1,r2,col,ang).
function DRAW.Star( x, y, r1, r2, col, ang )
	ang = ang or 0
	NoTexture()
	local dat = {}
	for i = 1, 8 do
		local d1 = rad( 45 * i + ang )
		local d2 = rad( 90 * i )
		local dis = r1 + r2 * abs( cos( d2 ) )
		dat[ i ] = { x = x + dis * cos( d1 ), y = y + dis * sin( d1 ), u = 0, v = 0 }
	end
	local r, g, b, a = unpackClr( col )
	SetDrawColor( r, g, b, a )
	DrawPoly( dat )
end

-- Box (rounded). PRESERVED SIGNATURE (x,y,w,h,col,col2).
function DRAW.Box( x, y, w, h, col, col2 )
	w = max( w, h / 3 )
	RoundedBox( 16, x, y, w, h, col )
	if col2 then RoundedBox( 16, x + 5, y + 5, w - 10, h - 10, col2 ) end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	CIRCLES / ARCS / RINGS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Reusable 4-vertex quad, populated + consumed synchronously by DrawPoly.
-- Avoids allocating a table per arc segment (technique from HUD Mk.2 utils/draw).
local arcQuad = {
	{ x = 0, y = 0, u = 0, v = 0 },
	{ x = 0, y = 0, u = 1, v = 0 },
	{ x = 0, y = 0, u = 1, v = 1 },
	{ x = 0, y = 0, u = 0, v = 1 },
}
local aq1, aq2, aq3, aq4 = arcQuad[ 1 ], arcQuad[ 2 ], arcQuad[ 3 ], arcQuad[ 4 ]

-- Annular arc/ring segment. PRESERVED SIGNATURE:
-- Circle(x,y,r,r2,startang,endang,iter,col,col2). r = outer, r2 = inner band.
-- Uses incremental point rotation: two trig calls total (cos/sin of the per-step
-- delta) instead of four per segment, and a reused vertex quad (zero per-segment
-- allocation). Screen-space y is inverted (-sin), matching the original.
function DRAW.Circle( x, y, r, r2, startang, endang, iter, col, col2 )
	local rs    = rad( startang )
	local OutR  = abs( r - 4 )
	local OutR2 = abs( r2 + 4 )
	local step  = ( rad( endang ) - rs ) / iter
	local cs, sn = cos( step ), sin( step )
	-- running unit vector at the segment's leading edge (t1), rotated each step
	local cx, cy = cos( rs ), sin( rs )
	NoTexture()
	local cr, cg, cb, ca = unpackClr( col )
	SetDrawColor( cr, cg, cb, ca )
	for _ = 1, iter do
		-- current edge (t1)
		local x1o, y1o = cx * OutR  + x, -cy * OutR  + y
		local x1i, y1i = cx * OutR2 + x, -cy * OutR2 + y
		-- rotate to the next edge (t2)
		local nx = cx * cs - cy * sn
		cy = cx * sn + cy * cs
		cx = nx
		aq1.x = cx * OutR  + x ; aq1.y = -cy * OutR  + y
		aq2.x = cx * OutR2 + x ; aq2.y = -cy * OutR2 + y
		aq3.x = x1i ; aq3.y = y1i
		aq4.x = x1o ; aq4.y = y1o
		DrawPoly( arcQuad )
	end
	if col2 then DRAW.Circle( x, y, r + 1, r2 - 1, startang, endang, iter, col2 ) end
end

-- Build a disc vertex ring via incremental rotation (one cos/sin pair total).
local function discPoly( x, y, radius, quality )
	local step = TAU / quality
	local cs, sn = cos( step ), sin( step )
	local cx, cy = 1, 0
	local pts = {}
	for i = 1, quality do
		pts[ i ] = { x = x + cx * radius, y = y + cy * radius }
		local nx = cx * cs - cy * sn
		cy = cx * sn + cy * cs
		cx = nx
	end
	return pts
end

-- Filled disc. PRESERVED SIGNATURE (x,y,radius,quality).
function DRAW.CircleFilled( x, y, radius, quality )
	quality = max( 3, floor( quality or 32 ) )
	NoTexture()
	SetDrawColor( 255, 255, 255, 255 )
	DrawPoly( discPoly( x, y, radius, quality ) )
end

-- Filled disc with an explicit colour (convenience over CircleFilled).
function DRAW.Disc( x, y, radius, clr, quality )
	quality = max( 3, floor( quality or 32 ) )
	DRAW.Poly( discPoly( x, y, radius, quality ), clr )
end

-- Full ring (annulus) of the given band thickness.
function DRAW.Ring( x, y, radius, thickness, clr, segments )
	segments = max( 3, floor( segments or 48 ) )
	DRAW.Circle( x, y, radius, radius - thickness, 0, 360, segments, clr )
end

-- Arc: an annular segment from startAng to endAng (degrees, CW), band = thickness.
function DRAW.Arc( x, y, radius, thickness, startAng, endAng, clr, segments )
	segments = max( 1, floor( segments or 32 ) )
	DRAW.Circle( x, y, radius, radius - thickness, startAng, endAng, segments, clr )
end

-- Circle outline (1..n px) using a thin arc band.
function DRAW.CircleOutline( x, y, radius, thickness, clr, segments )
	DRAW.Ring( x, y, radius, thickness or 1, clr, segments )
end

-- Pie sector (solid wedge from centre). PRESERVED SIGNATURE (x,y,r,ang,rot,col).
function DRAW.Sector( x, y, r, ang, rot, col )
	local segments = 360
	local todraw = 360 * ( ang / 360 )
	rot = rot * ( segments / 360 )
	local poly = { { x = x, y = y } }
	for i = 1 + rot, todraw + rot do
		poly[ #poly + 1 ] = {
			x = cos( ( i * ( 360 / segments ) ) * ( pi / 180 ) ) * r + x,
			y = sin( ( i * ( 360 / segments ) ) * ( pi / 180 ) ) * r + y,
		}
	end
	DRAW.Poly( poly, col )
end

-- Dotted circle of rotated sprites. PRESERVED SIGNATURE (x,y,w,h,radius,seg,col).
function DRAW.DottedCircle( x, y, w, h, radius, seg, col )
	local r, g, b, a = unpackClr( col )
	NoTexture()
	SetDrawColor( r, g, b, a )
	local step = 360 / seg
	for i = 0, seg do
		local a2 = rad( ( i / seg ) * -360 )
		DrawTexRectRot( x + sin( a2 ) * radius, y + cos( a2 ) * radius, w, h, deg( a2 ) + step )
	end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	MARKER GLYPHS  (crosshair / directional primitives)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Plus / cross-hair with an optional centre gap.
function DRAW.Cross( x, y, size, gap, thickness, clr )
	gap = gap or 0
	thickness = thickness or 1
	DRAW.ThickLine( x - size, y, x - gap, y, thickness, clr )
	DRAW.ThickLine( x + gap, y, x + size, y, thickness, clr )
	DRAW.ThickLine( x, y - size, x, y - gap, thickness, clr )
	DRAW.ThickLine( x, y + gap, x, y + size, thickness, clr )
end

-- Chevron ( > pointing at dir degrees: 0=right, 90=down ).
function DRAW.Chevron( x, y, size, dir, thickness, clr )
	local a = rad( dir or 0 )
	local pa = a + rad( 140 )
	local pb = a - rad( 140 )
	DRAW.ThickLine( x + cos( pa ) * size, y + sin( pa ) * size, x, y, thickness or 2, clr )
	DRAW.ThickLine( x, y, x + cos( pb ) * size, y + sin( pb ) * size, thickness or 2, clr )
end

-- Line arrow from (x1,y1) to (x2,y2) with an arrow-head of headSize px.
function DRAW.Arrow( x1, y1, x2, y2, headSize, thickness, clr )
	headSize = headSize or 8
	DRAW.ThickLine( x1, y1, x2, y2, thickness or 2, clr )
	local a = atan2( y2 - y1, x2 - x1 )
	local ha = rad( 150 )
	DRAW.ThickLine( x2, y2, x2 + cos( a + ha ) * headSize, y2 + sin( a + ha ) * headSize, thickness or 2, clr )
	DRAW.ThickLine( x2, y2, x2 + cos( a - ha ) * headSize, y2 + sin( a - ha ) * headSize, thickness or 2, clr )
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FRAME GRID  (dashed corner brackets — the original ZDEV.DRAW.Grid, cleaned)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Dashed rectangular border. PRESERVED SIGNATURE (x,y,w,h,color).
function DRAW.Grid( x, y, w, h, clr )
	local r, g, b, a = unpackClr( clr )
	SetDrawColor( r, g, b, a )
	local val = 0
	for i = 0, w do val = val + 1 ; if val % 2 ~= 0 then DrawRect( x + i,     y,         1, 1 ) end end
	for i = 1, h do val = val + 1 ; if val % 2 ~= 0 then DrawRect( x + w,     y + i,     1, 1 ) end end
	for i = 1, w do val = val + 1 ; if val % 2 ~= 0 then DrawRect( x + w - i, y + h,     1, 1 ) end end
	for i = 1, h do val = val + 1 ; if val % 2 ~= 0 then DrawRect( x,         y + h - i, 1, 1 ) end end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	TEXT PRIMITIVES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Simple text (thin wrapper for a consistent call surface). Returns text w,h.
function DRAW.Text( text, font, x, y, clr, xa, ya )
	return SimpleText( text, font, x, y, clr or color_white, xa or TEXT_ALIGN_LEFT, ya or TEXT_ALIGN_TOP )
end

-- Text with a hard drop shadow.
function DRAW.ShadowText( text, font, x, y, clr, xa, ya, dist, shadowClr )
	dist = dist or 1
	xa = xa or TEXT_ALIGN_LEFT ; ya = ya or TEXT_ALIGN_TOP
	SimpleText( text, font, x + dist, y + dist, shadowClr or Color( 0, 0, 0, ( clr and clr.a ) or 255 ), xa, ya )
	SimpleText( text, font, x, y, clr or color_white, xa, ya )
end

-- Outlined text (via draw.SimpleTextOutlined).
function DRAW.OutlineText( text, font, x, y, clr, xa, ya, thickness, outlineClr )
	return draw.SimpleTextOutlined( text, font, x, y, clr or color_white,
		xa or TEXT_ALIGN_LEFT, ya or TEXT_ALIGN_TOP, thickness or 1, outlineClr or color_black )
end

-- Rotated text about (x,y). PRESERVED SIGNATURE (text,font,x,y,Tcol,ang).
function DRAW.TextRotated( text, font, x, y, Tcol, ang )
	render.PushFilterMag( TEXFILTER.ANISOTROPIC )
	render.PushFilterMin( TEXFILTER.ANISOTROPIC )
	local m = Matrix()
	m:SetTranslation( Vector( x, y, 0 ) )
	m:SetAngles( Angle( 0, ang, 0 ) )
	cam.PushModelMatrix( m )
		SimpleText( text, font, 0, 0, Tcol or color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	cam.PopModelMatrix()
	render.PopFilterMag()
	render.PopFilterMin()
end

-- Rotated box with centred text. PRESERVED SIGNATURE
-- (text,font,x,y,w,h,Tcol,ang,col,col2). (Previously crashed on undefined DrawSRPBox.)
function DRAW.TextRotatedBox( text, font, x, y, w, h, Tcol, ang, col, col2 )
	render.PushFilterMag( TEXFILTER.ANISOTROPIC )
	render.PushFilterMin( TEXFILTER.ANISOTROPIC )
	local m = Matrix()
	m:SetAngles( Angle( 0, ang, 0 ) )
	m:SetTranslation( Vector( x, y, 0 ) )
	cam.PushModelMatrix( m )
		DRAW.Box( 0, 0, w, h, col or color_black, col2 )
		SimpleText( text, font, w / 2, h / 2, Tcol or color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	cam.PopModelMatrix()
	render.PopFilterMag()
	render.PopFilterMin()
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	TEXT UTILITIES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Abbreviate large numbers ( 1500000 -> "1.50M" ). Technique from HoloHUD2
-- util.ShortenNumber. `decimals` (default 2); numbers below `minVal` (default 1e6)
-- pass through unchanged (rounded). Returns a string.
local SHORT_SUFFIX = { "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "De" }
function DRAW.ShortNumber( n, decimals, minVal )
	minVal = minVal or 1e6
	if n ~= n then return "NaN" end
	if n == math.huge then return "\226\136\158" end       -- ∞
	if n == -math.huge then return "-\226\136\158" end
	local neg = n < 0
	local a = abs( n )
	if a < minVal then return tostring( floor( n + 0.5 ) ) end
	local order = floor( math.log10( a ) / 3 )               -- 1=K, 2=M, 3=B…
	order = Clamp( order, 1, #SHORT_SUFFIX )
	local val = a / ( 10 ^ ( order * 3 ) )
	return ( neg and "-" or "" ) .. string.format( "%." .. ( decimals or 2 ) .. "f", val ) .. SHORT_SUFFIX[ order ]
end

-- Insert `sep` (default a space) between every character — the letter-spaced
-- "T A C T I C A L" HUD look (technique from HUD Mk.2 InsertSpaceBetweenChars).
function DRAW.LetterSpace( str, sep )
	if #str <= 1 then return str end
	sep = sep or " "
	local out = {}
	for i = 1, #str do out[ i ] = str:sub( i, i ) end
	return table.concat( out, sep )
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	ANIMATED / STYLISED TEXT  →  ZDEV.DRAW.TEXT.*
	(Originally Moat's text effects — https://steamcommunity.com/id/moat_ —
	 rewritten as namespaced, allocation-light functions. Legacy globals are
	 kept as thin aliases at the bottom for backwards compatibility.)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local TEXT = ZDEV.DRAW.TEXT

local function alignText( text, font, x, y, xalign, yalign )
	SetFont( font )
	local tw, th = GetTextSize( text )
	if xalign == TEXT_ALIGN_CENTER then x = x - tw / 2
	elseif xalign == TEXT_ALIGN_RIGHT then x = x - tw end
	if yalign == TEXT_ALIGN_BOTTOM then y = y - th end
	return x, y
end

-- Kept for the effects below; also exposed for callers.
function TEXT.Shadowed( shadow, text, font, x, y, clr, xa, ya )
	DRAW.ShadowText( text, font, x, y, clr, xa, ya, shadow )
end

function TEXT.Glowing( static, text, font, x, y, clr, xa, ya )
	xa = xa or TEXT_ALIGN_LEFT ; ya = ya or TEXT_ALIGN_TOP
	local initial_a, a_by_i = 20, 5
	local glow = static and 1 or abs( sin( ( RealTime() - 0.1 ) * 2 ) )
	for i = 1, 2 do
		draw.SimpleTextOutlined( text, font, x, y, clr, xa, ya, i,
			Color( clr.r, clr.g, clr.b, ( initial_a - ( i * a_by_i ) ) * glow ) )
	end
	SimpleText( text, font, x, y, clr, xa, ya )
end

function TEXT.Fading( speed, text, font, x, y, clr, fadeClr, xa, ya )
	local c = DRAW.LerpColor( abs( sin( ( RealTime() - 0.08 ) * speed ) ), clr, fadeClr )
	SimpleText( text, font, x, y, c, xa or TEXT_ALIGN_LEFT, ya or TEXT_ALIGN_TOP )
end

function TEXT.Enchanted( speed, text, font, x, y, clr, glowClr, xa, ya )
	xa = xa or TEXT_ALIGN_LEFT ; ya = ya or TEXT_ALIGN_TOP
	glowClr = glowClr or Color( 127, 0, 255 )
	x, y = alignText( text, font, x, y, xa, ya )
	SetFont( font )
	local cx = 0
	for i = 1, #text do
		local char = text:sub( i, i )
		local cw = GetTextSize( char )
		local c = DRAW.LerpColor( abs( sin( ( RealTime() - ( i * 0.08 ) ) * speed ) ), glowClr, clr )
		SimpleText( char, font, x + cx, y, c, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		cx = cx + cw
	end
end

local rb_c1, rb_c2, rb_next = Color( 0, 0, 0 ), Color( 255, 255, 255 ), 0
function TEXT.Rainbow( speed, text, font, x, y, xa, ya )
	rb_next = rb_next + 1 / ( 100 / speed )
	if rb_next >= 1 then rb_next = 0 ; rb_c1 = rb_c2 ; rb_c2 = ColorRand() end
	SimpleText( text, font, x, y, DRAW.LerpColor( rb_next, rb_c1, rb_c2 ), xa or TEXT_ALIGN_LEFT, ya or TEXT_ALIGN_TOP )
end

function TEXT.Bouncing( style, intensity, text, font, x, y, clr, xa, ya )
	xa = xa or TEXT_ALIGN_LEFT ; ya = ya or TEXT_ALIGN_TOP
	SetFont( font )
	x, y = alignText( text, font, x, y, xa, ya )
	local cx = 0
	for i = 1, #text do
		local char = text:sub( i, i )
		local cw = GetTextSize( char )
		local m = sin( ( RealTime() - ( i * 0.1 ) ) * ( 2 * intensity ) )
		local yp = 1
		if style == 1 then yp = yp - abs( m )
		elseif style == 2 then yp = yp + abs( m )
		else yp = yp - m end
		SimpleText( char, font, x + cx, y - ( 5 * yp ), clr, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		cx = cx + cw
	end
end

local elec_next, elec_a = CurTime(), 0
function TEXT.Electric( intensity, text, font, x, y, clr, xa, ya )
	xa = xa or TEXT_ALIGN_LEFT ; ya = ya or TEXT_ALIGN_TOP
	SetFont( font )
	local cw, ch = GetTextSize( text )
	SimpleText( text, font, x, y, clr, xa, ya )
	if elec_a > 0 then elec_a = elec_a - ( 1000 * FrameTime() ) end
	SetDrawColor( 102, 255, 255, elec_a )
	for _ = 1, math.random( 5 ) do
		DrawLine( x + math.random( cw ), y + math.random( ch ), x + math.random( cw ), y + math.random( ch ) )
	end
	if elec_next <= CurTime() then
		elec_next = CurTime() + math.Rand( 0.5 + ( 1 - intensity ), 1.5 + ( 1 - intensity ) )
		elec_a = 255
	end
end

function TEXT.Fire( intensity, text, font, x, y, clr, xa, ya, glow, shadow )
	xa = xa or TEXT_ALIGN_LEFT ; ya = ya or TEXT_ALIGN_TOP
	SetFont( font )
	local cw, ch = GetTextSize( text )
	local fh = ch * intensity
	for i = 1, cw do
		SetDrawColor( 255, math.random( 255 ), 0, 150 )
		DrawLine( x - 1 + i, y + ch, x - 1 + i + math.random( -4, 4 ), y + math.random( fh, ch ) )
	end
	if glow then TEXT.Glowing( true, text, font, x, y, clr, xa, ya ) end
	if shadow then SimpleText( text, font, x + 1, y + 1, color_black, xa, ya ) end
	SimpleText( text, font, x, y, clr, xa, ya )
end

function TEXT.Snowing( intensity, text, font, x, y, clr, clr2, xa, ya )
	xa = xa or TEXT_ALIGN_LEFT ; ya = ya or TEXT_ALIGN_TOP
	clr2 = clr2 or color_white
	SimpleText( text, font, x, y, clr, xa, ya )
	SetFont( font )
	local tw, th = GetTextSize( text )
	SetDrawColor( clr2.r, clr2.g, clr2.b, 255 )
	for _ = 1, intensity do
		local lx, ly = math.random( 0, tw ), math.random( 0, th )
		DrawLine( x + lx, y + ly, x + lx, y + ly + 1 )
	end
end

-- Typewriter reveal: shows the first n characters based on elapsed time.
-- startTime is a CurTime() stamp; cps = characters/sec. Returns true when done.
function TEXT.Typewriter( text, font, x, y, clr, startTime, cps, xa, ya )
	local n = min( #text, floor( ( CurTime() - startTime ) * ( cps or 30 ) ) )
	SimpleText( text:sub( 1, n ), font, x, y, clr or color_white, xa or TEXT_ALIGN_LEFT, ya or TEXT_ALIGN_TOP )
	return n >= #text
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	LEGACY GLOBAL ALIASES  (old Moat globals — kept so nothing external breaks)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function GlowColor( c1, c2, mod ) return DRAW.LerpColor( mod, c1, c2 ) end
function DrawShadowedText( shadow, text, font, x, y, clr, xa, ya ) DRAW.ShadowText( text, font, x, y, clr, xa, ya, shadow ) end
function DrawGlowingText( ... )   TEXT.Glowing( ... )   end
function DrawFadingText( ... )    TEXT.Fading( ... )    end
function DrawEnchantedText( ... ) TEXT.Enchanted( ... ) end
function DrawRainbowText( ... )   TEXT.Rainbow( ... )   end
function DrawBouncingText( ... )  TEXT.Bouncing( ... )  end
function DrawElecticText( ... )   TEXT.Electric( ... )  end
function DrawFireText( ... )      TEXT.Fire( ... )      end
function DrawSnowingText( ... )   TEXT.Snowing( ... )   end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	EXTENSION MODULES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
include( "zdev/client/draw/zd_cl_draw_anim.lua" )
include( "zdev/client/draw/zd_cl_draw_fx.lua" )
include( "zdev/client/draw/zd_cl_draw_ui.lua" )
include( "zdev/client/draw/zd_cl_draw_viz.lua" )
include( "zdev/client/draw/zd_cl_draw_demo.lua" )

zdev.log( "S", "Loaded file: '" .. _f .. "'" )
ZDEV.FILE.SetLoaded( _f )

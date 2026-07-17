local _f = 'zdev/client/draw/zd_cl_draw_ui.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')

-- Custom UI fonts via the ZDEV font API (ZDEV.FONT.Register). The title carries a
-- NATIVE drop shadow (shadow=true) so we never fake shadows by offset-drawing.
-- Faces ship in resource/fonts and are already used elsewhere in ZDEV (no generic
-- Derma fonts). Registered BEFORE the reload guard so a hot-reload keeps them.
if ZDEV.FONT and ZDEV.FONT.Register then
	ZDEV.FONT.Register( "ZDEV_UI_Title",   { font = "Rajdhani",       size = 19, weight = 700, extended = true, antialias = true, shadow = true } )
	ZDEV.FONT.Register( "ZDEV_UI_Font",    { font = "Rajdhani",       size = 18, weight = 500, extended = true, antialias = true } )
	ZDEV.FONT.Register( "ZDEV_UI_Small",   { font = "Rajdhani",       size = 15, weight = 500, extended = true, antialias = true } )
	ZDEV.FONT.Register( "ZDEV_UI_Display", { font = "Rajdhani",       size = 26, weight = 700, extended = true, antialias = true } )
	ZDEV.FONT.Register( "ZDEV_UI_LED",     { font = "Digital-7 Mono", size = 46, weight = 500, extended = true, antialias = true } )
end

if ZDEV.FILE.Loaded( _f ) then return end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	zd_cl_draw_ui.lua  —  ZDEV.DRAW.UI  (complex 2D components)

	Composable, fully-parametrised HUD/UI building blocks in the tactical style
	of Smart Vision / HUD Mk.2. Every component takes an `opts` table and falls
	back to ZDEV.DRAW.UI.THEME so a whole HUD stays visually consistent — change
	the theme once and every component follows.

	  Containers : Panel, CutCornerBox, CornerBrackets, Separator
	  Readouts   : Bar, SegmentBar, LabelValue, Badge, KeyHint
	  World      : Callout, Marker
	  Messaging  : Toast, Tooltip
	  Data       : Grid (table)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

ZDEV.DRAW    = ZDEV.DRAW or {}
ZDEV.DRAW.UI = ZDEV.DRAW.UI or {}

local DRAW = ZDEV.DRAW
local UI   = ZDEV.DRAW.UI

local surface     = surface
local SimpleText   = draw.SimpleText
local GetTextSize  = surface.GetTextSize
local SetFont      = surface.SetFont
local floor        = math.floor
local Clamp        = math.Clamp
local max, min     = math.max, math.min

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	THEME  —  single source of truth; override fields to reskin everything.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
-- Palette per docs/reference/VISUAL_STYLE_GUIDE.md — grayscale-first, near-black
-- ground, hairline grey structure, INVERSION (chip/chipText) as primary emphasis,
-- exactly one accent hue, semantic colours only for meaning.
UI.THEME = UI.THEME or {
	bg        = Color(  10,  10,  12, 220 ),   -- near-black ground (#0A0A0C)
	panel     = Color(  18,  18,  22, 235 ),   -- panel step (#121216)
	border    = Color( 255, 255, 255,  42 ),   -- dim-tier grey hairline
	line      = Color( 255, 255, 255,  28 ),   -- faintest rules/grids
	accent    = Color(   0, 200, 255, 255 ),   -- THE single accent hue
	text      = Color( 235, 240, 245, 255 ),   -- full white: active data
	textDim   = Color( 158, 162, 168, 255 ),   -- mid-tier grey: labels
	chip      = Color( 228, 232, 236, 255 ),   -- inversion chip background
	chipText  = Color(  10,  10,  12, 255 ),   -- inversion chip text
	good      = Color(  80, 220, 120, 255 ),
	warn      = Color( 240, 190,  60, 255 ),
	bad       = Color( 235,  75,  75, 255 ),
	font      = "ZDEV_UI_Font",     -- Rajdhani 18
	fontBold  = "ZDEV_UI_Title",    -- Rajdhani 19, native shadow
	fontSmall = "ZDEV_UI_Small",    -- Rajdhani 15
}

local function T() return UI.THEME end
-- opts field with theme / literal fallback
local function opt( o, k, d )
	if o and o[ k ] ~= nil then return o[ k ] end
	return d
end
local function txtSize( text, font )
	SetFont( font )
	return GetTextSize( text )
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	CORNER BRACKETS  (targeting frame — the 4 L-shaped corners only)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function UI.CornerBrackets( x, y, w, h, len, thickness, clr )
	len = len or 10
	thickness = thickness or 2
	clr = clr or T().accent
	local x2, y2 = x + w, y + h
	-- TL
	DRAW.ThickLine( x, y, x + len, y, thickness, clr )
	DRAW.ThickLine( x, y, x, y + len, thickness, clr )
	-- TR
	DRAW.ThickLine( x2, y, x2 - len, y, thickness, clr )
	DRAW.ThickLine( x2, y, x2, y + len, thickness, clr )
	-- BL
	DRAW.ThickLine( x, y2, x + len, y2, thickness, clr )
	DRAW.ThickLine( x, y2, x, y2 - len, thickness, clr )
	-- BR
	DRAW.ThickLine( x2, y2, x2 - len, y2, thickness, clr )
	DRAW.ThickLine( x2, y2, x2, y2 - len, thickness, clr )
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	CUT-CORNER BOX  (chamfered sci-fi panel). `cut` = corner size; corners is a
	bit-set of which corners to chamfer (default TL+BR for the classic look).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
-- corners flags: 1=TL 2=TR 4=BR 8=BL
function UI.CutCornerBox( x, y, w, h, cut, fillClr, outlineClr, corners, thickness )
	cut = cut or 10
	corners = corners or ( 1 + 4 ) -- TL + BR
	local x2, y2 = x + w, y + h
	local tl = bit.band( corners, 1 ) ~= 0 and cut or 0
	local tr = bit.band( corners, 2 ) ~= 0 and cut or 0
	local br = bit.band( corners, 4 ) ~= 0 and cut or 0
	local bl = bit.band( corners, 8 ) ~= 0 and cut or 0
	local pts = {
		{ x = x + tl, y = y },
		{ x = x2 - tr, y = y },
		{ x = x2, y = y + tr },
		{ x = x2, y = y2 - br },
		{ x = x2 - br, y = y2 },
		{ x = x + bl, y = y2 },
		{ x = x, y = y2 - bl },
		{ x = x, y = y + tl },
	}
	if fillClr then DRAW.Poly( pts, fillClr ) end
	if outlineClr then
		thickness = thickness or 1
		pts[ #pts + 1 ] = pts[ 1 ]
		for i = 1, #pts - 1 do
			DRAW.ThickLine( pts[ i ].x, pts[ i ].y, pts[ i + 1 ].x, pts[ i + 1 ].y, thickness, outlineClr )
		end
	end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	PANEL  —  the workhorse container.
	opts = { bg, border, accent, thickness, brackets, bracketLen, cut, corners,
	         title, titleFont, titleClr, titleH, glow }
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function UI.Panel( x, y, w, h, opts )
	local th = T()
	local bg      = opt( opts, "bg", th.panel )
	local border  = opt( opts, "border", th.border )
	local accent  = opt( opts, "accent", th.accent )
	local thick   = opt( opts, "thickness", 1 )
	local cut     = opt( opts, "cut", nil )

	-- Frosted-glass background: blur the framebuffer behind the panel (technique
	-- from HoloHUD2 BlurRect). The caller must have called ZDEV.DRAW.FX.ComputeBlur()
	-- once earlier this frame so the capture exists.
	if opt( opts, "blur", false ) then
		DRAW.FX.BlurRect( x, y, w, h )
	end

	if opt( opts, "glow", false ) then
		DRAW.FX.BoxGlow( x, y, w, h, DRAW.Alpha( accent, 90 ), opt( opts, "glowSpread", 10 ), 5 )
	end

	if cut then
		UI.CutCornerBox( x, y, w, h, cut, bg, border, opt( opts, "corners", 1 + 4 ), thick )
	else
		DRAW.Rect( x, y, w, h, bg )
		if border then DRAW.OutlinedBox( x, y, w, h, thick, border ) end
	end

	-- Holographic scanline overlay clipped to the panel (technique from HoloHUD2's
	-- scanline layer — the CRT lines that make a flat panel read as a hologram).
	if opt( opts, "scanlines", false ) then
		DRAW.PushClip( x, y, w, h )
		DRAW.FX.Scanlines( x, y, w, h, opt( opts, "scanlineSpacing", 3 ),
			opt( opts, "scanlineClr", DRAW.Alpha( accent, 16 ) ), opt( opts, "scanlineScroll", 20 ) )
		DRAW.PopClip()
	end

	-- accent stripe along the top edge
	if opt( opts, "accentBar", false ) then
		DRAW.Rect( x, y, w, opt( opts, "accentBarH", 2 ), accent )
	end

	if opt( opts, "brackets", false ) then
		UI.CornerBrackets( x, y, w, h, opt( opts, "bracketLen", 12 ), thick + 1, accent )
	end

	local title = opt( opts, "title", nil )
	if title then
		local tf   = opt( opts, "titleFont", th.fontBold )
		local tclr = opt( opts, "titleClr", th.text )
		local titleH = opt( opts, "titleH", 20 )
		DRAW.Rect( x, y, w, titleH, DRAW.Alpha( accent, 30 ) )
		if border then DRAW.Rect( x, y + titleH, w, 1, border ) end
		-- native font shadow (tf carries shadow=true) — no manual offset-draw
		SimpleText( title, tf, x + 10, y + titleH / 2 + 1, tclr, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		return y + titleH -- content-top Y for convenience
	end
	return y
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	SEPARATOR  —  horizontal rule, optionally with a centred/left label.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function UI.Separator( x, y, w, clr, label, font )
	clr = clr or T().border
	if not label then
		DRAW.Rect( x, y, w, 1, clr )
		return
	end
	font = font or T().fontSmall
	local tw = txtSize( label, font )
	local pad = 6
	local lineW = ( w - tw - pad * 2 ) / 2
	DRAW.Rect( x, y, lineW, 1, clr )
	DRAW.Rect( x + w - lineW, y, lineW, 1, clr )
	SimpleText( label, font, x + w / 2, y, T().textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	BAR  —  progress / health bar. frac 0..1.
	opts = { bg, fill, border, dir, vertical, flip, gradient, text, font, textClr,
	         loss, lossKey, lossClr, lossSpeed }
	`fill` may be a Color or a function(frac)->Color for state-based colouring.

	`dir` = "right" (default) | "left" | "up" | "down"  — the fill grow direction
	        (superset of the legacy vertical/flip flags, which still work).

	TRAILING LOSS BAR (technique from HUD Mk.2 BL_Rect): set `loss = true` and a
	stable `lossKey`. A slower "ghost" bar lags behind on decreases, revealing how
	much was just lost in `lossClr`; on increases it snaps up. `lossSpeed` = how
	fast the ghost catches up (frac/sec, default 0.6).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
-- Resolve the fill rect for a grow direction (frac 0..1) within (x,y,w,h).
local function fillRect( dir, x, y, w, h, frac )
	if dir == "left" then
		local fw = w * frac ; return x + w - fw, y, fw, h
	elseif dir == "up" then
		local fh = h * frac ; return x, y + h - fh, w, fh
	elseif dir == "down" then
		return x, y, w, h * frac
	else -- right
		return x, y, w * frac, h
	end
end

function UI.Bar( x, y, w, h, frac, opts )
	local th = T()
	frac = Clamp( frac or 0, 0, 1 )
	local bg     = opt( opts, "bg", th.bg )
	local border = opt( opts, "border", th.border )
	local fill   = opt( opts, "fill", th.accent )
	if isfunction( fill ) then fill = fill( frac ) end

	-- resolve grow direction (legacy vertical/flip flags map onto `dir`)
	local dir = opt( opts, "dir", nil )
	if not dir then
		if opt( opts, "vertical", false ) then
			dir = opt( opts, "flip", false ) and "down" or "up"
		else
			dir = opt( opts, "flip", false ) and "left" or "right"
		end
	end
	local vertical = ( dir == "up" or dir == "down" )

	DRAW.Rect( x, y, w, h, bg )

	-- trailing loss / chip bar (drawn behind the fill so the gap shows the loss)
	if opt( opts, "loss", false ) then
		local key  = opt( opts, "lossKey", nil )
		local ANIM = ZDEV.ANIM
		if key and ANIM then
			local sk = "barloss:" .. key
			local prev = ANIM._state[ sk ]
			if prev == nil then prev = frac end
			if frac >= prev then
				prev = frac
			else
				prev = max( frac, prev - opt( opts, "lossSpeed", 0.6 ) * FrameTime() )
			end
			ANIM._state[ sk ] = prev
			if prev > frac then
				local lx, ly, lw, lh = fillRect( dir, x, y, w, h, prev )
				DRAW.Rect( lx, ly, lw, lh, opt( opts, "lossClr", th.bad ) )
			end
		end
	end

	local fx, fy, fw, fh = fillRect( dir, x, y, w, h, frac )
	if opt( opts, "gradient", false ) then
		if vertical then
			DRAW.GradientV( fx, fy, fw, fh, DRAW.Brighten( fill, 1.3 ), fill )
		else
			DRAW.GradientH( fx, fy, fw, fh, fill, DRAW.Brighten( fill, 1.3 ) )
		end
	else
		DRAW.Rect( fx, fy, fw, fh, fill )
	end
	if opt( opts, "hatch", false ) then
		DRAW.HatchRect( fx, fy, fw, fh, opt( opts, "hatchSpacing", 6 ),
			opt( opts, "hatchClr", DRAW.Alpha( th.bg, 130 ) ), 1, 1, opt( opts, "hatchScroll", nil ) )
	end

	if border then DRAW.OutlinedBox( x, y, w, h, 1, border ) end

	local text = opt( opts, "text", nil )
	if text then
		SimpleText( text, opt( opts, "font", th.fontSmall ), x + w / 2, y + h / 2,
			opt( opts, "textClr", th.text ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end
end

-- Convenience state-colour function for health/ammo bars.
function UI.StateColor( frac )
	local th = T()
	if frac > 0.5 then return DRAW.LerpColor( ( frac - 0.5 ) * 2, th.warn, th.good )
	else return DRAW.LerpColor( frac * 2, th.bad, th.warn ) end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	HOLO NUMBER / TEXT  —  the glowing, RGB-split readout look from HoloHUD2 / GL4.
	An additive radial glow behind the glyphs, a red/cyan chromatic split, then the
	crisp coloured pass on top. Centred at (x,y).
	opts = { split, glow, glowSize, glowAlpha, align }
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
-- Draw `text` at (x,y) with an additive glow + red/cyan chromatic split. Helper
-- so both the plain and ghost-zero paths share the exact holographic pass.
local function holoGlyphs( text, font, x, y, clr, xa, split, glow, glowSize, glowAlpha )
	if glow then DRAW.FX.Glow( x, y, glowSize, DRAW.Alpha( clr, glowAlpha ) ) end
	render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )
		SimpleText( text, font, x - split, y, Color( 255, 0, 0, 160 ), xa, TEXT_ALIGN_CENTER )
		SimpleText( text, font, x + split, y, Color( 0, 255, 255, 160 ), xa, TEXT_ALIGN_CENTER )
	render.OverrideBlend( false )
	SimpleText( text, font, x, y, clr, xa, TEXT_ALIGN_CENTER )
end

function UI.HoloNumber( x, y, text, font, clr, opts )
	local th = T()
	clr = clr or th.accent
	text = tostring( text )
	local split     = opt( opts, "split", 2 )
	local xa        = opt( opts, "align", TEXT_ALIGN_CENTER )
	local glow      = opt( opts, "glow", true )
	local glowSize  = opt( opts, "glowSize", 46 )
	local glowAlpha = opt( opts, "glowAlpha", 70 )

	-- Signature LED readout: a fixed-width field of dim "ghost" zeros with the
	-- live value right-aligned and lit on top (the GL4 / HoloHUD2 "0 0 0 100"
	-- look). `digits` = field width; the value never draws the ghost zeros itself.
	local digits = opt( opts, "digits", nil )
	if digits then
		SetFont( font )
		local fieldW = txtSize( string.rep( "0", digits ), font )
		local gx = x
		if xa == TEXT_ALIGN_CENTER then gx = x - fieldW / 2
		elseif xa == TEXT_ALIGN_RIGHT then gx = x - fieldW end
		local vx = gx + fieldW                                   -- right edge of field
		-- dim ghost field
		SimpleText( string.rep( "0", digits ), font, gx, y,
			opt( opts, "ghostClr", DRAW.Alpha( clr, 40 ) ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		-- lit value, right-aligned into the field
		holoGlyphs( text, font, vx, y, clr, TEXT_ALIGN_RIGHT, split, glow, glowSize, glowAlpha )
		return fieldW
	end

	holoGlyphs( text, font, x, y, clr, xa, split, glow, glowSize, glowAlpha )
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	SEGMENT BAR  —  n discrete pips (ammo blocks, charges). `filled` = # lit.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function UI.SegmentBar( x, y, w, h, count, filled, opts )
	local th = T()
	count = max( 1, floor( count or 1 ) )
	local gap  = opt( opts, "gap", 2 )
	local onC  = opt( opts, "on", th.accent )
	local offC = opt( opts, "off", th.bg )
	local border = opt( opts, "border", th.border )
	local segW = ( w - gap * ( count - 1 ) ) / count
	for i = 0, count - 1 do
		local sx = x + i * ( segW + gap )
		DRAW.Rect( sx, y, segW, h, i < filled and onC or offC )
		if border then DRAW.OutlinedBox( sx, y, segW, h, 1, border ) end
	end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	TITLE CHIP  —  the INVERSION chip (light bg, dark text): the house-signature
	emphasis of the visual style guide (docs/reference/VISUAL_STYLE_GUIDE.md §3).
	Use for panel titles, active tabs, selected rows and hot values instead of
	coloured text. Returns w, h. opts = { font, fg, bg, padX, padY, minW }
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function UI.TitleChip( x, y, text, opts )
	local th = T()
	local font = opt( opts, "font", th.fontSmall )
	local padX = opt( opts, "padX", 6 )
	local padY = opt( opts, "padY", 2 )
	local tw, thh = txtSize( text, font )
	local w = max( tw + padX * 2, opt( opts, "minW", 0 ) )
	local h = thh + padY * 2
	DRAW.Rect( x, y, w, h, opt( opts, "bg", th.chip ) )
	SimpleText( text, font, x + padX, y + h / 2, opt( opts, "fg", th.chipText ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
	return w, h
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	BADGE  —  small label chip. Returns the width it occupied (for chaining).
	opts = { bg, textClr, font, padX, padY, accent }
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function UI.Badge( x, y, text, opts )
	local th = T()
	local font = opt( opts, "font", th.fontSmall )
	local padX = opt( opts, "padX", 6 )
	local padY = opt( opts, "padY", 3 )
	local tw, txtH = txtSize( text, font )
	local w = tw + padX * 2
	local h = txtH + padY * 2
	DRAW.Rect( x, y, w, h, opt( opts, "bg", DRAW.Alpha( th.accent, 40 ) ) )
	local accent = opt( opts, "accent", th.accent )
	if accent then DRAW.Rect( x, y, 2, h, accent ) end
	SimpleText( text, font, x + padX, y + h / 2, opt( opts, "textClr", th.text ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
	return w, h
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	KEY HINT  —  a keycap glyph + action label.  e.g.  [E]  Interact
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function UI.KeyHint( x, y, key, label, opts )
	local th = T()
	local font = opt( opts, "font", th.fontBold )
	local kw, kh = txtSize( key, font )
	local box = max( kh + 6, kw + 8 )
	DRAW.Rect( x, y, box, box, opt( opts, "keyBg", th.panel ) )
	DRAW.OutlinedBox( x, y, box, box, 1, opt( opts, "keyBorder", th.accent ) )
	SimpleText( key, font, x + box / 2, y + box / 2, opt( opts, "keyClr", th.text ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	if label then
		SimpleText( label, opt( opts, "labelFont", th.font ), x + box + 6, y + box / 2,
			opt( opts, "labelClr", th.textDim ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
	end
	return box
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	LABEL : VALUE  —  a HUD readout row.  Returns the row height.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function UI.LabelValue( x, y, w, label, value, opts )
	local th = T()
	local font    = opt( opts, "font", th.font )
	local lblClr  = opt( opts, "labelClr", th.textDim )
	local valClr  = opt( opts, "valueClr", th.text )
	local _, hh = txtSize( label, font )
	SimpleText( label, font, x, y, lblClr, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	SimpleText( tostring( value ), font, x + w, y, valClr, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP )
	return hh
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	CALLOUT  —  world-anchored label with a leader line.
	Anchor at (ax,ay); label box grows from (bx,by). opts = { text, sub, font,
	subFont, clr, bg, accent, dotRadius, align }
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function UI.Callout( ax, ay, bx, by, opts )
	local th = T()
	local text    = opt( opts, "text", "" )
	local sub     = opt( opts, "sub", nil )
	local font    = opt( opts, "font", th.fontBold )
	local subFont = opt( opts, "subFont", th.fontSmall )
	local clr     = opt( opts, "clr", th.text )
	local accent  = opt( opts, "accent", th.accent )
	local bg      = opt( opts, "bg", th.bg )
	local dotR    = opt( opts, "dotRadius", 3 )

	-- anchor dot + ring
	DRAW.Disc( ax, ay, dotR, accent )
	DRAW.CircleOutline( ax, ay, dotR + 3, 1, DRAW.Alpha( accent, 160 ), 20 )

	-- leader: elbow from anchor up/across to the label
	local elbowY = by + 8
	DRAW.ThickLine( ax, ay, ax, elbowY, 1, accent )
	DRAW.ThickLine( ax, elbowY, bx, elbowY, 1, accent )

	-- label sizing
	local tw, thh = txtSize( text, font )
	local sw, shh = 0, 0
	if sub then sw, shh = txtSize( sub, subFont ) end
	local padX, padY = 6, 4
	local boxW = max( tw, sw ) + padX * 2
	local boxH = thh + ( sub and ( shh + 2 ) or 0 ) + padY * 2
	local boxX = bx
	local boxY = elbowY - boxH

	DRAW.Rect( boxX, boxY, boxW, boxH, bg )
	DRAW.Rect( boxX, boxY, 2, boxH, accent )
	DRAW.OutlinedBox( boxX, boxY, boxW, boxH, 1, DRAW.Alpha( accent, 120 ) )
	SimpleText( text, font, boxX + padX, boxY + padY, clr, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	if sub then
		SimpleText( sub, subFont, boxX + padX, boxY + padY + thh + 2, th.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	MARKER  —  an entity/world marker at (x,y).
	opts = { style="bracket"|"diamond"|"dot"|"chevron", size, clr, label, sub,
	         font, dist }
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function UI.Marker( x, y, opts )
	local th = T()
	local style = opt( opts, "style", "bracket" )
	local size  = opt( opts, "size", 12 )
	local clr   = opt( opts, "clr", th.accent )

	if style == "diamond" then
		DRAW.RegularPolygon( x, y, size, 4, 45, clr )
	elseif style == "dot" then
		DRAW.Disc( x, y, size * 0.4, clr )
		DRAW.CircleOutline( x, y, size * 0.7, 1, DRAW.Alpha( clr, 160 ), 20 )
	elseif style == "chevron" then
		DRAW.Chevron( x, y - size, size, 90, 2, clr )
	else -- bracket
		UI.CornerBrackets( x - size, y - size, size * 2, size * 2, size * 0.6, 2, clr )
	end

	local label = opt( opts, "label", nil )
	if label then
		DRAW.ShadowText( label, opt( opts, "font", th.fontBold ), x, y - size - 4, clr, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM )
	end
	local sub = opt( opts, "sub", nil )
	if sub then
		DRAW.ShadowText( sub, opt( opts, "subFont", th.fontSmall ), x, y + size + 2, th.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
	end
	local dist = opt( opts, "dist", nil )
	if dist then
		DRAW.ShadowText( floor( dist ) .. "m", opt( opts, "subFont", th.fontSmall ), x, y + size + 2, th.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
	end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	TOAST / MESSAGE CARD  —  a notification card with accent stripe + optional
	icon material. `alpha` (0..1) lets the caller drive fade via ZDEV.ANIM.Fade.
	opts = { title, body, icon, accent, bg, titleFont, bodyFont, w }
	Returns the card height (for stacking).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function UI.Toast( x, y, alpha, opts )
	local th = T()
	alpha = Clamp( alpha == nil and 1 or alpha, 0, 1 )
	local w        = opt( opts, "w", 260 )
	local title    = opt( opts, "title", "" )
	local body     = opt( opts, "body", nil )
	local icon     = opt( opts, "icon", nil )
	local accent   = opt( opts, "accent", th.accent )
	local bg       = opt( opts, "bg", th.panel )
	local tFont    = opt( opts, "titleFont", th.fontBold )
	local bFont    = opt( opts, "bodyFont", th.font )

	local padX, padY = 10, 8
	local iconSize = icon and 24 or 0
	local textX = x + padX + ( icon and ( iconSize + 8 ) or 0 )
	local textW = w - ( textX - x ) - padX

	SetFont( bFont )
	local _, lineH = GetTextSize( "Ay" )
	local wrapped = body and DRAW.WrapText and DRAW.WrapText( body, bFont, textW ) or ( body and { body } or nil )
	local bodyH = wrapped and ( #wrapped * lineH ) or 0
	local _, titleH = txtSize( title, tFont )
	local h = padY * 2 + titleH + ( body and ( 2 + bodyH ) or 0 )

	local a = function( c ) return DRAW.Alpha( c, ( c.a or 255 ) * alpha ) end
	DRAW.Rect( x, y, w, h, a( bg ) )
	DRAW.Rect( x, y, 3, h, a( accent ) )
	DRAW.OutlinedBox( x, y, w, h, 1, a( DRAW.Alpha( accent, 120 ) ) )

	if icon then
		DRAW.TexturedRect( x + padX, y + padY, iconSize, iconSize, icon, a( color_white ) )
	end
	SimpleText( title, tFont, textX, y + padY, a( th.text ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	if wrapped then
		for i, line in ipairs( wrapped ) do
			SimpleText( line, bFont, textX, y + padY + titleH + 2 + ( i - 1 ) * lineH, a( th.textDim ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		end
	end
	return h
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	TOOLTIP  —  auto-sized box near a point (e.g. cursor). Clamps to screen.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function UI.Tooltip( px, py, text, opts )
	local th = T()
	local font = opt( opts, "font", th.font )
	local padX, padY = 8, 5
	local tw, thh = txtSize( text, font )
	local w, h = tw + padX * 2, thh + padY * 2
	local x = min( px + 14, ScrW() - w - 4 )
	local y = min( py + 14, ScrH() - h - 4 )
	DRAW.Rect( x, y, w, h, opt( opts, "bg", th.panel ) )
	DRAW.OutlinedBox( x, y, w, h, 1, opt( opts, "border", th.accent ) )
	SimpleText( text, font, x + padX, y + padY, opt( opts, "textClr", th.text ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	return w, h
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	GRID / TABLE  —  simple data grid with an optional header row.
	cols = { {title=, w=}, ... }   rows = { { "a", "b" }, ... }
	opts = { rowH, headerBg, rowBg, altRowBg, font, headerFont, textClr, border }
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function UI.Grid( x, y, cols, rows, opts )
	local th = T()
	local rowH   = opt( opts, "rowH", 18 )
	local font   = opt( opts, "font", th.font )
	local hFont  = opt( opts, "headerFont", th.fontBold )
	local border = opt( opts, "border", th.border )
	local textClr = opt( opts, "textClr", th.text )

	local totalW = 0
	for _, c in ipairs( cols ) do totalW = totalW + ( c.w or 60 ) end

	-- header
	DRAW.Rect( x, y, totalW, rowH, opt( opts, "headerBg", DRAW.Alpha( th.accent, 30 ) ) )
	local cx = x
	for _, c in ipairs( cols ) do
		SimpleText( c.title or "", hFont, cx + 4, y + rowH / 2, th.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		cx = cx + ( c.w or 60 )
	end

	-- rows
	local ry = y + rowH
	for ri, row in ipairs( rows ) do
		local rbg = ( ri % 2 == 0 ) and opt( opts, "altRowBg", DRAW.Alpha( th.bg, 120 ) ) or opt( opts, "rowBg", DRAW.Alpha( th.bg, 60 ) )
		DRAW.Rect( x, ry, totalW, rowH, rbg )
		cx = x
		for ci, c in ipairs( cols ) do
			local cell = row[ ci ]
			if cell ~= nil then
				SimpleText( tostring( cell ), font, cx + 4, ry + rowH / 2, textClr, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
			end
			cx = cx + ( c.w or 60 )
		end
		ry = ry + rowH
	end

	if border then DRAW.OutlinedBox( x, y, totalW, ry - y, 1, border ) end
	return ry - y -- total height
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	TEXT WRAP  —  greedy word-wrap helper (used by Toast; exposed on ZDEV.DRAW).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function DRAW.WrapText( text, font, maxW )
	SetFont( font )
	local lines, line = {}, ""
	for _, word in ipairs( string.Explode( " ", text ) ) do
		local test = line == "" and word or ( line .. " " .. word )
		if GetTextSize( test ) > maxW and line ~= "" then
			lines[ #lines + 1 ] = line
			line = word
		else
			line = test
		end
	end
	if line ~= "" then lines[ #lines + 1 ] = line end
	return lines
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUI KIT  —  components harvested from the ZDEV UI aesthetic standard (film-grade
	FUI: thin-line, restrained monochrome + one accent, letter-spaced caps).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- TEAR-SHEET METADATA BLOCK — the bracketed corner plate (PROJECT / SET / DATE …).
-- fields = { { "PROJECT", "ZDEV" }, { "SET", "HUD" }, ... }. Returns height.
function UI.TearSheet( x, y, w, fields, opts )
	local th = T()
	local cols  = opt( opts, "cols", 2 )
	local rowH  = opt( opts, "rowH", 26 )
	local pad   = opt( opts, "pad", 8 )
	local accent = opt( opts, "accent", th.accent )
	local rows  = math.ceil( #fields / cols )
	local h     = rows * rowH + pad * 2
	local cellW = ( w - pad * 2 ) / cols

	DRAW.Rect( x, y, w, h, opt( opts, "bg", DRAW.Alpha( th.bg, 210 ) ) )
	DRAW.OutlinedBox( x, y, w, h, 1, opt( opts, "border", DRAW.Alpha( accent, 120 ) ) )
	UI.CornerBrackets( x, y, w, h, 8, 1, accent )

	local lblFont = opt( opts, "labelFont", th.fontSmall )
	local valFont = opt( opts, "font", th.fontSmall )
	for i, f in ipairs( fields ) do
		local ci = ( i - 1 ) % cols
		local ri = floor( ( i - 1 ) / cols )
		local cx = x + pad + ci * cellW
		local cy = y + pad + ri * rowH
		SimpleText( DRAW.LetterSpace( tostring( f[ 1 ] ) ), lblFont, cx, cy, th.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		SimpleText( tostring( f[ 2 ] ), valFont, cx, cy + 11, th.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	end
	return h
end

-- TECH LINE — a leader/connector from (x1,y1) to (x2,y2) with a start node dot,
-- an optional right-angle elbow, and an end cap ("tick" | "arrow" | "dot" | "none").
function UI.TechLine( x1, y1, x2, y2, opts )
	local th    = T()
	local clr   = opt( opts, "clr", th.accent )
	local thick = opt( opts, "thickness", 1 )

	if opt( opts, "startNode", true ) then DRAW.Disc( x1, y1, opt( opts, "startR", 2 ), clr ) end

	if opt( opts, "elbow", true ) then
		local mx = opt( opts, "elbowX", ( x1 + x2 ) * 0.5 )
		DRAW.ThickLine( x1, y1, mx, y1, thick, clr )
		DRAW.ThickLine( mx, y1, mx, y2, thick, clr )
		DRAW.ThickLine( mx, y2, x2, y2, thick, clr )
	else
		DRAW.ThickLine( x1, y1, x2, y2, thick, clr )
	end

	local cap = opt( opts, "cap", "tick" )
	if cap == "tick" then
		DRAW.ThickLine( x2, y2 - 4, x2, y2 + 4, thick, clr )
	elseif cap == "arrow" then
		DRAW.Arrow( x2 - 7, y2, x2, y2, 5, thick, clr )
	elseif cap == "dot" then
		DRAW.Disc( x2, y2, opt( opts, "endR", 2 ), clr )
	end
end

-- RETICLE / POINTER — crosshair variants. style = "target" | "lock" | "bracket" | "dot".
function UI.Reticle( x, y, opts )
	local th    = T()
	local size  = opt( opts, "size", 20 )
	local clr   = opt( opts, "clr", th.accent )
	local thick = opt( opts, "thickness", 1 )
	local style = opt( opts, "style", "target" )
	local gap   = opt( opts, "gap", size * 0.45 )

	if style == "bracket" or style == "lock" then
		UI.CornerBrackets( x - size, y - size, size * 2, size * 2, size * 0.5, thick + ( style == "lock" and 1 or 0 ), clr )
	end
	if style ~= "bracket" then
		DRAW.Cross( x, y, size, gap, thick, clr )
	end
	if style == "target" and opt( opts, "ring", true ) then
		DRAW.CircleOutline( x, y, size * 0.55, thick, DRAW.Alpha( clr, 180 ), 32 )
	end
	if style == "dot" or style == "lock" or opt( opts, "dot", false ) then
		DRAW.Disc( x, y, 1.6, clr )
	end
end

-- SPINNER — animated segmented scan/loading ring (a track + a sweeping arc).
function UI.Spinner( x, y, radius, opts )
	local th    = T()
	local clr   = opt( opts, "clr", th.accent )
	local thick = opt( opts, "thickness", 3 )
	local sweep = opt( opts, "sweep", 90 )
	local speed = opt( opts, "speed", 200 )   -- deg/sec (RealTime based)
	DRAW.Ring( x, y, radius, thick, opt( opts, "track", DRAW.Alpha( clr, 40 ) ), 48 )
	local start = ( RealTime() * speed ) % 360
	DRAW.Arc( x, y, radius, thick, start, start - sweep, clr, 24 )   -- clockwise sweep
end

-- TOGGLE — angular switch (on/off). Returns nothing; caller owns the value.
function UI.Toggle( x, y, w, h, on, opts )
	local th  = T()
	local onC = opt( opts, "on", th.accent )
	DRAW.Rect( x, y, w, h, DRAW.Alpha( th.bg, 220 ) )
	local kw = w * 0.5
	local kx = on and ( x + w - kw ) or x
	DRAW.Rect( kx, y, kw, h, on and onC or DRAW.Alpha( th.border, 220 ) )
	DRAW.OutlinedBox( x, y, w, h, 1, DRAW.Alpha( th.accent, on and 200 or 80 ) )
	local label = opt( opts, "label", nil )
	if label then
		SimpleText( label, opt( opts, "font", th.fontSmall ), x + w + 6, y + h / 2,
			on and th.text or th.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
	end
end

zdev.log( "S", "Loaded file: '" .. _f .. "'" )
ZDEV.FILE.SetLoaded( _f )

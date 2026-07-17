local _f = 'zdev/client/draw/zd_cl_draw_fx.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	zd_cl_draw_fx.lua  —  ZDEV.DRAW.FX  (basic 2D effects)

	High-quality, optimised, self-contained overlay effects that a caller
	composes into a HUD/UI paint pass:

	  Overlays (no screen capture):  Scanlines, GridLines, Vignette, Noise,
	                                 Glow, BoxGlow, Static
	  Screen-space (capture RT):     Blur, Distort, Glitch
	  Text:                          Scramble
	  Composition helper:            Chromatic (RGB-split any draw callback)

	Every function reads ScrW()/ScrH() live and allocates nothing per-frame on
	the hot path beyond the unavoidable poly tables (see rule glua-2d-drawing
	Rule 5). Screen-space effects are confined to their rect via the caller's
	region; Blur additionally clips with ZDEV.DRAW.PushClip.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

ZDEV.DRAW    = ZDEV.DRAW or {}
ZDEV.DRAW.FX = ZDEV.DRAW.FX or {}

local DRAW = ZDEV.DRAW
local FX   = ZDEV.DRAW.FX

local surface          = surface
local SetDrawColor     = surface.SetDrawColor
local SetMaterial      = surface.SetMaterial
local DrawRect         = surface.DrawRect
local DrawTexturedRect = surface.DrawTexturedRect
local DrawTexRectUV    = surface.DrawTexturedRectUV
local render           = render
local rand             = math.random
local Rand             = math.Rand
local sin              = math.sin
local floor            = math.floor
local Clamp            = math.Clamp
local unpackClr        = DRAW.UnpackColor

-- Materials -----------------------------------------------------------------
local MAT_BLUR   = Material( "pp/blurscreen" )
local MAT_GLOW   = Material( "sprites/light_glow02_add" )
-- Framebuffer capture material for distort/glitch (UnlitGeneric over the RT).
local MAT_SCREEN = CreateMaterial( "zdev_fx_screen", "UnlitGeneric", {
	["$basetexture"] = "_rt_FullFrameFB",
	["$ignorez"]     = 1,
	["$vertexcolor"] = 1,
} )

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	SCANLINES / GRID / VIGNETTE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Horizontal CRT scanlines across a region. spacing px apart, given alpha.
-- `scroll` (optional) animates the lines downward at that px/sec.
function FX.Scanlines( x, y, w, h, spacing, clr, scroll )
	spacing = spacing or 3
	local r, g, b, a = unpackClr( clr or Color( 0, 0, 0, 90 ) )
	SetDrawColor( r, g, b, a )
	local off = scroll and ( RealTime() * scroll ) % spacing or 0
	local yy = y + off
	while yy < y + h do
		DrawRect( x, yy, w, 1 )
		yy = yy + spacing
	end
end

-- Full grid of lines over a region (distinct from ZDEV.DRAW.Grid's dashed border).
function FX.GridLines( x, y, w, h, cell, clr, thickness )
	cell = cell or 24
	thickness = thickness or 1
	local r, g, b, a = unpackClr( clr or Color( 255, 255, 255, 20 ) )
	SetDrawColor( r, g, b, a )
	for gx = 0, w, cell do DrawRect( x + gx, y, thickness, h ) end
	for gy = 0, h, cell do DrawRect( x, y + gy, w, thickness ) end
end

-- Edge vignette (darkens the borders of a region). strength 0..1, clr default black.
function FX.Vignette( x, y, w, h, strength, clr )
	strength = strength or 1
	clr = clr or Color( 0, 0, 0 )
	local a = 255 * Clamp( strength, 0, 1 )
	local band = math.min( w, h ) * 0.35
	SetDrawColor( clr.r, clr.g, clr.b, a )
	SetMaterial( Material( "vgui/gradient-d" ) ) DrawTexturedRect( x, y, w, band )              -- top
	SetMaterial( Material( "vgui/gradient-u" ) ) DrawTexturedRect( x, y + h - band, w, band )   -- bottom
	SetMaterial( Material( "vgui/gradient-r" ) ) DrawTexturedRect( x, y, band, h )              -- left
	SetMaterial( Material( "vgui/gradient-l" ) ) DrawTexturedRect( x + w - band, y, band, h )   -- right
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	NOISE / STATIC
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- TV-static speckle over a region. density = fraction of cells lit (0..1),
-- cell = pixel size of each speckle. Monochrome unless clr given.
function FX.Noise( x, y, w, h, density, cell, clr )
	cell = cell or 2
	density = density or 0.15
	local cols = floor( w / cell )
	local rows = floor( h / cell )
	local total = cols * rows
	local lit = floor( total * Clamp( density, 0, 1 ) )
	if clr then
		local r, g, b, a = unpackClr( clr )
		SetDrawColor( r, g, b, a )
		for _ = 1, lit do
			DrawRect( x + rand( 0, cols - 1 ) * cell, y + rand( 0, rows - 1 ) * cell, cell, cell )
		end
	else
		for _ = 1, lit do
			local v = rand( 40, 255 )
			SetDrawColor( v, v, v, rand( 60, 160 ) )
			DrawRect( x + rand( 0, cols - 1 ) * cell, y + rand( 0, rows - 1 ) * cell, cell, cell )
		end
	end
end
FX.Static = FX.Noise

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	GLOW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Additive radial glow sprite centred at (x,y). `size` = diameter.
function FX.Glow( x, y, size, clr )
	local r, g, b, a = unpackClr( clr or Color( 255, 255, 255, 255 ) )
	SetDrawColor( r, g, b, a )
	SetMaterial( MAT_GLOW )
	DrawTexturedRect( x - size * 0.5, y - size * 0.5, size, size )
end

-- Soft rectangular glow behind a panel: `layers` expanding translucent frames.
function FX.BoxGlow( x, y, w, h, clr, spread, layers )
	spread = spread or 12
	layers = layers or 6
	local r, g, b, a = unpackClr( clr or Color( 0, 200, 255, 120 ) )
	for i = layers, 1, -1 do
		local f = i / layers
		local pad = spread * f
		SetDrawColor( r, g, b, a / layers )
		DrawRect( x - pad, y - pad, w + pad * 2, h + pad * 2 )
	end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	SCREEN-SPACE : BLUR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Gaussian blur of the framebuffer confined to a region (behind-panel blur).
function FX.Blur( x, y, w, h, amount, passes )
	amount = amount or 6
	passes = passes or 4
	DRAW.PushClip( x, y, w, h )
	SetMaterial( MAT_BLUR )
	SetDrawColor( 255, 255, 255, 255 )
	local sw, sh = ScrW(), ScrH()
	for i = 1, passes do
		MAT_BLUR:SetFloat( "$blur", ( i / passes ) * amount )
		MAT_BLUR:Recompute()
		render.UpdateScreenEffectTexture()
		DrawTexturedRect( 0, 0, sw, sh )
	end
	DRAW.PopClip()
end

-- Two-step blur for drawing MANY blurred regions cheaply (technique from
-- HoloHUD2 render.ComputeBlur/BlurRect). Call ComputeBlur ONCE at the top of
-- your paint pass (the expensive capture), then BlurRect per panel (cheap).
function FX.ComputeBlur( amount )
	MAT_BLUR:SetFloat( "$blur", amount or 4 )
	MAT_BLUR:Recompute()
	render.UpdateScreenEffectTexture()
end

-- Draw the pre-computed blurred framebuffer within a region (screen-space UVs).
-- Must be preceded by FX.ComputeBlur() at least once this frame.
function FX.BlurRect( x, y, w, h )
	local sw, sh = ScrW(), ScrH()
	SetDrawColor( 255, 255, 255, 255 )
	SetMaterial( MAT_BLUR )
	DrawTexRectUV( x, y, w, h, x / sw, y / sh, ( x + w ) / sw, ( y + h ) / sh )
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	STENCIL SCISSOR  (mask subsequent draws to a rect — technique from HoloHUD2
	util.StartStencilScissor. Unlike render.SetScissorRect it composes with the
	alpha multiplier and can be extended to arbitrary mask shapes.)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function FX.StencilStart( x, y, w, h )
	render.SetStencilWriteMask( 0xFF )
	render.SetStencilTestMask( 0xFF )
	render.SetStencilReferenceValue( 0 )
	render.SetStencilPassOperation( STENCIL_KEEP )
	render.SetStencilZFailOperation( STENCIL_KEEP )
	render.ClearStencil()
	render.SetStencilEnable( true )
	render.SetStencilReferenceValue( 1 )
	render.SetStencilCompareFunction( STENCIL_NEVER )
	render.SetStencilFailOperation( STENCIL_REPLACE )
	SetDrawColor( 255, 255, 255, 255 )
	DrawRect( x, y, w, h )
	render.SetStencilCompareFunction( STENCIL_EQUAL )
	render.SetStencilFailOperation( STENCIL_KEEP )
end

function FX.StencilEnd()
	render.SetStencilEnable( false )
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	ENTITY HIGHLIGHT / X-RAY SILHOUETTE  (technique from Smart Vision). Stencil-
	masks the entity's model drawn with a near DepthRange (so it shows through
	walls), then fills the screen through the mask for a solid silhouette. Call
	from a 3D render hook (PostDrawTranslucentRenderables / RenderScreenspaceEffects);
	it establishes its own cam.Start3D so it is safe from either.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- True if worldPos is within `maxAngle` degrees of the player's view direction.
function FX.IsInViewCone( ply, worldPos, maxAngle )
	local viewDir = ply:EyeAngles():Forward()
	local dir = ( worldPos - ply:EyePos() )
	dir:Normalize()
	return viewDir:Dot( dir ) >= math.cos( math.rad( maxAngle or 75 ) )
end

function FX.HighlightEntity( ent, clr, drawWeapon )
	if not IsValid( ent ) then return end
	clr = clr or Color( 255, 80, 80, 200 )
	cam.Start3D()
		render.SetStencilEnable( true )
			render.SetStencilWriteMask( 1 )
			render.SetStencilTestMask( 1 )
			render.SetStencilReferenceValue( 1 )
			render.SetStencilFailOperation( STENCIL_KEEP )
			render.SetStencilZFailOperation( STENCIL_KEEP )
			render.ClearStencil()
			render.SetStencilCompareFunction( STENCIL_ALWAYS )
			render.SetStencilPassOperation( STENCIL_REPLACE )
				render.DepthRange( 0, 0.01 )   -- draw over walls
					ent:DrawModel()
					if drawWeapon and ent.GetActiveWeapon then
						local wep = ent:GetActiveWeapon()
						if IsValid( wep ) then wep:DrawModel() end
					end
				render.DepthRange( 0, 1 )
			render.SetStencilCompareFunction( STENCIL_EQUAL )
			render.SetStencilPassOperation( STENCIL_KEEP )
				cam.Start2D()
					SetDrawColor( clr.r, clr.g, clr.b, clr.a or 200 )
					DrawRect( 0, 0, ScrW(), ScrH() )
				cam.End2D()
		render.SetStencilEnable( false )
	cam.End3D()
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	SCREEN-SPACE : DISTORT  (wavy horizontal displacement of the captured screen)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Sine-wave horizontal ripple of the region. amount = max px shift; band = slice
-- height; speed = animation rate; freq = wave density.
function FX.Distort( x, y, w, h, amount, band, speed, freq )
	amount = amount or 8
	band   = band or 4
	speed  = speed or 3
	freq   = freq or 0.05
	local sw, sh = ScrW(), ScrH()
	render.UpdateScreenEffectTexture()
	SetMaterial( MAT_SCREEN )
	SetDrawColor( 255, 255, 255, 255 )
	local t = RealTime() * speed
	local yy = y
	while yy < y + h do
		local bh = math.min( band, y + h - yy )
		local dx = sin( t + yy * freq ) * amount
		local u0 = ( x + dx ) / sw
		local v0 = yy / sh
		local u1 = ( x + dx + w ) / sw
		local v1 = ( yy + bh ) / sh
		DrawTexRectUV( x, yy, w, bh, u0, v0, u1, v1 )
		yy = yy + bh
	end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	SCREEN-SPACE : GLITCH  (random slice offset + RGB chromatic split)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Datamosh-style glitch. intensity 0..1 scales slice count + displacement.
-- Captures the framebuffer once and re-draws displaced horizontal slices, then
-- overlays cheap red/cyan chromatic bands.
function FX.Glitch( x, y, w, h, intensity )
	intensity = Clamp( intensity or 0.5, 0, 1 )
	local sw, sh = ScrW(), ScrH()
	render.UpdateScreenEffectTexture()
	SetMaterial( MAT_SCREEN )

	local slices = floor( 3 + intensity * 12 )
	for _ = 1, slices do
		local sy = rand( y, y + h - 2 )
		local bh = rand( 2, math.max( 3, floor( h * 0.12 ) ) )
		bh = math.min( bh, y + h - sy )
		local dx = Rand( -1, 1 ) * intensity * 40
		-- main displaced slice
		SetDrawColor( 255, 255, 255, 255 )
		DrawTexRectUV( x, sy, w, bh, ( x + dx ) / sw, sy / sh, ( x + dx + w ) / sw, ( sy + bh ) / sh )
		-- chromatic split on the same slice
		local cs = intensity * 6
		SetDrawColor( 255, 60, 60, 120 )
		DrawTexRectUV( x, sy, w, bh, ( x + dx - cs ) / sw, sy / sh, ( x + dx - cs + w ) / sw, ( sy + bh ) / sh )
		SetDrawColor( 60, 255, 255, 120 )
		DrawTexRectUV( x, sy, w, bh, ( x + dx + cs ) / sw, sy / sh, ( x + dx + cs + w ) / sw, ( sy + bh ) / sh )
	end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	CHROMATIC ABERRATION  (composition helper for arbitrary draw callbacks)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Runs drawFn(offX, offY, tint) three times — red shifted -offset, blue shifted
-- +offset, then the full-colour pass — for an RGB-split look. drawFn should use
-- the passed tint colour and honour the offset. Cheap and content-agnostic.
function FX.Chromatic( offset, drawFn )
	offset = offset or 2
	render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )
	drawFn( -offset, 0, Color( 255, 0, 0 ) )
	drawFn(  offset, 0, Color( 0, 255, 255 ) )
	render.OverrideBlend( false )
	drawFn( 0, 0, Color( 255, 255, 255 ) )
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	TEXT : SCRAMBLE  (characters settle from random glyphs into the target text)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
local SCRAMBLE_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%&*<>/\\|=+-"
local SCRAMBLE_N = #SCRAMBLE_CHARS

-- Reveal `text` left-to-right over `duration`s starting at CurTime()==startTime.
-- Unsettled characters are shown as fast-cycling random glyphs. Returns done.
function FX.Scramble( text, font, x, y, clr, startTime, duration, xa, ya )
	duration = duration or 1
	local n = #text
	local prog = Clamp( ( CurTime() - startTime ) / duration, 0, 1 )
	local settled = floor( prog * n )
	local out = {}
	for i = 1, n do
		local ch = text:sub( i, i )
		if i <= settled or ch == " " then
			out[ i ] = ch
		else
			local idx = ( floor( CurTime() * 30 ) + i * 7 ) % SCRAMBLE_N + 1
			out[ i ] = SCRAMBLE_CHARS:sub( idx, idx )
		end
	end
	draw.SimpleText( table.concat( out ), font, x, y, clr or color_white,
		xa or TEXT_ALIGN_LEFT, ya or TEXT_ALIGN_TOP )
	return prog >= 1
end

zdev.log( "S", "Loaded file: '" .. _f .. "'" )
ZDEV.FILE.SetLoaded( _f )

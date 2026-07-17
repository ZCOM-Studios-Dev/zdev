local _f = 'zdev/client/draw/zd_cl_draw_demo.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	zd_cl_draw_demo.lua  —  live showcase / documentation for the ZDEV 2D Draw
	Library. Toggle with the console command:

	    zdev_draw_showcase        (aliases: zdev_dev_textexamples, moat_TextExamples)

	It paints one screen exercising primitives, effects, animations, UI
	components and visualisations — the canonical reference for how to call the
	library. It is inert until toggled on.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

ZDEV.DRAW          = ZDEV.DRAW or {}
ZDEV.DRAW.SHOWCASE = ZDEV.DRAW.SHOWCASE or { on = false }

-- Register the toggle BEFORE the reload guard so hot-reloads keep it (rule
-- gmod-file-load-order).
if ZDEV.CMDS and ZDEV.CMDS.Register then
	ZDEV.CMDS.Register( "zdev_draw_showcase", function()
		ZDEV.DRAW.SHOWCASE.on = not ZDEV.DRAW.SHOWCASE.on
		ZDEV.DRAW.SHOWCASE.start = CurTime()
		zdev.log( "S", "2D Draw showcase: " .. ( ZDEV.DRAW.SHOWCASE.on and "ON" or "OFF" ) )
	end, { aliases = { "zdev_dev_textexamples", "moat_TextExamples" }, help = "Toggle the ZDEV 2D Draw Library showcase overlay." } )
end

if ZDEV.FILE.Loaded( _f ) then return end

local DRAW = ZDEV.DRAW
local FX   = ZDEV.DRAW.FX
local UI   = ZDEV.DRAW.UI
local VIZ  = ZDEV.DRAW.VIZ
local ANIM = ZDEV.ANIM

-- Demo data (built once)
local barData   = { 12, 34, 22, 45, 30, 18, 41, 27 }
local lineA, lineB = {}, {}
for i = 1, 40 do
	lineA[ i ] = 50 + math.sin( i * 0.3 ) * 25
	lineB[ i ] = 50 + math.cos( i * 0.2 ) * 18
end
local radarAxes = { "SPD", "DMG", "RNG", "ACC", "CTL", "AMMO" }
local radarVals = { 0.8, 0.6, 0.5, 0.9, 0.4, 0.7 }
local heat = {}
for r = 1, 8 do heat[ r ] = {} for c = 1, 12 do heat[ r ][ c ] = math.abs( math.sin( r * 0.5 ) * math.cos( c * 0.4 ) ) end end
local dataRows = {
	{ id = "0x2F", text = "4AED:39:40:7F:A0:1C", pct = 0.98 },
	{ id = "0x60", text = "7D75:0E:2F:C2:20:B8", pct = 0.71 },
	{ id = "0x8B", text = "40E2:5B:A6:55:8B:3D", pct = 0.44 },
}

local function DrawShowcase()
	if not ZDEV.DRAW.SHOWCASE.on then return end
	local sw, sh = ScrW(), ScrH()
	local t0 = ZDEV.DRAW.SHOWCASE.start or CurTime()
	local th = UI.THEME

	-- Light backdrop + grid so the frosted-glass panels read against detail behind
	-- them (a fully opaque backdrop would leave nothing for the blur to sample).
	DRAW.Rect( 0, 0, sw, sh, Color( 5, 8, 11, 140 ) )
	FX.GridLines( 0, 0, sw, sh, 32, Color( 255, 255, 255, 10 ) )
	-- Capture the framebuffer ONCE now; every panel below frosts it cheaply via
	-- its blur=true opt -> FX.BlurRect (HoloHUD2 ComputeBlur/BlurRect split).
	FX.ComputeBlur( 6 )

	-- Clean "frosted glass" panel style: the BLUR defines the panel (per the
	-- reference), so no fake multi-outline glow and no heavy border — just a
	-- translucent tint (so the frost shows through) and a single accent edge.
	local function frost( title, extra )
		local o = {
			title = title, blur = true, scanlines = true,
			border = false, accentBar = true,
			bg = Color( 12, 17, 22, 130 ),   -- translucent so the blur reads
		}
		if extra then for k, v in pairs( extra ) do o[ k ] = v end end
		return o
	end

	local col1 = 40
	local col2 = 40 + 360
	local col3 = 40 + 720

	-- ── Column 1 : primitives ──────────────────────────────────────────────
	local cy = UI.Panel( col1, 40, 320, 300, frost( "PRIMITIVES" ) ) + 12
	DRAW.Rect( col1 + 16, cy, 40, 40, th.accent )
	DRAW.OutlinedBox( col1 + 66, cy, 40, 40, 2, th.good )
	DRAW.Disc( col1 + 136, cy + 20, 20, th.warn )
	DRAW.Ring( col1 + 196, cy + 20, 20, 4, th.bad )
	DRAW.RegularPolygon( col1 + 256, cy + 20, 20, 6, ANIM.Pulse( 30, 0, 360 ), th.accent )
	cy = cy + 56
	DRAW.GradientH( col1 + 16, cy, 290, 20, th.accent, th.bad ) ; cy = cy + 28
	DRAW.ThickLine( col1 + 16, cy + 8, col1 + 306, cy + 8, 3, th.good ) ; cy = cy + 24
	DRAW.Arrow( col1 + 16, cy + 8, col1 + 120, cy + 8, 10, 2, th.accent )
	DRAW.Cross( col1 + 200, cy + 8, 14, 4, 2, th.warn )
	DRAW.Star( col1 + 270, cy + 8, 8, 8, th.good, RealTime() * 40 ) ; cy = cy + 30
	DRAW.Circle( col1 + 40, cy + 20, 22, 14, 0, 360, 24, th.accent, th.bad )
	DRAW.Sector( col1 + 120, cy + 20, 22, 200, RealTime() * 60, th.good )

	-- ── Column 1 : text effects ────────────────────────────────────────────
	cy = UI.Panel( col1, 360, 320, 210, frost( "TEXT EFFECTS" ) ) + 14
	DRAW.ShadowText( "ShadowText", "ZDEV_UI_Display", col1 + 16, cy, th.text ) ; cy = cy + 26
	ZDEV.DRAW.TEXT.Glowing( false, "GLOWING", "ZDEV_UI_Display", col1 + 16, cy, th.accent ) ; cy = cy + 26
	ZDEV.DRAW.TEXT.Rainbow( 2, "RAINBOW", "ZDEV_UI_Display", col1 + 16, cy ) ; cy = cy + 26
	ZDEV.DRAW.TEXT.Fire( 0.5, "INFERNO", "ZDEV_UI_Display", col1 + 16, cy, Color( 255, 120, 0 ), nil, nil, true, true ) ; cy = cy + 26
	ZDEV.DRAW.TEXT.Bouncing( 3, 2, "BOUNCE", "ZDEV_UI_Display", col1 + 16, cy + 6, th.good ) ; cy = cy + 30
	FX.Scramble( "SCRAMBLE FX", "ZDEV_UI_Display", col1 + 16, cy, th.warn, t0 + 1, 2 ) ; cy = cy + 26
	ZDEV.DRAW.TEXT.Typewriter( "Typewriter reveal...", th.fontSmall, col1 + 16, cy, th.textDim, t0 + 1, 18 )

	-- ── Column 2 : UI components ────────────────────────────────────────────
	local py = UI.Panel( col2, 40, 340, 400, frost( "UI COMPONENTS", { cut = 14 } ) ) + 14
	UI.Bar( col2 + 16, py, 200, 16, ANIM.Pulse( 0.6, 0, 1 ), { fill = UI.StateColor, gradient = true, text = "HEALTH" } )
	UI.Badge( col2 + 226, py, "LIVE", { accent = th.bad } ) ; py = py + 26
	UI.SegmentBar( col2 + 16, py, 300, 14, 12, 8 ) ; py = py + 24
	UI.Separator( col2 + 16, py + 6, 300, nil, "STATUS" ) ; py = py + 20
	py = py + UI.LabelValue( col2 + 16, py, 300, "Latency", "24 ms" ) + 4
	py = py + UI.LabelValue( col2 + 16, py, 300, "Uplink", "STABLE", { valueClr = th.good } ) + 8
	UI.KeyHint( col2 + 16, py, "E", "Interact" )
	UI.KeyHint( col2 + 120, py, "F", "Flashlight" ) ; py = py + 34
	UI.CornerBrackets( col2 + 16, py, 90, 60, 12, 2, th.accent )
	UI.CutCornerBox( col2 + 120, py, 90, 60, 12, DRAW.Alpha( th.accent, 40 ), th.accent, 1 + 4, 1 )
	UI.Marker( col2 + 270, py + 30, { style = "bracket", label = "TARGET", dist = 42 } ) ; py = py + 74
	UI.Callout( col2 + 40, py + 50, col2 + 120, py + 20, { text = "SENSOR", sub = "online", accent = th.good } )

	-- ── Column 3 : effects + viz ───────────────────────────────────────────
	local vy = UI.Panel( col3, 40, 340, 250, frost( "EFFECTS" ) ) + 14
	FX.Scanlines( col3 + 16, vy, 150, 60, 3, Color( 0, 255, 255, 40 ), 20 )
	FX.Noise( col3 + 180, vy, 150, 60, 0.2, 2 )
	DRAW.OutlinedBox( col3 + 16, vy, 150, 60, 1, th.border )
	DRAW.OutlinedBox( col3 + 180, vy, 150, 60, 1, th.border ) ; vy = vy + 70
	FX.BoxGlow( col3 + 90, vy + 24, 60, 30, th.accent, 12, 6 )
	DRAW.Rect( col3 + 90, vy + 24, 60, 30, th.panel )
	DRAW.Text( "GLOW", th.fontBold, col3 + 120, vy + 39, th.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	FX.Glow( col3 + 250, vy + 30, 80, DRAW.Alpha( th.warn, 200 ) ) ; vy = vy + 80
	FX.Vignette( col3 + 16, vy, 314, 60, 1, Color( 0, 0, 0 ) )
	DRAW.Text( "VIGNETTE", th.fontBold, col3 + 173, vy + 30, th.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

	vy = UI.Panel( col3, 300, 340, 300, frost( "VISUALIZATIONS" ) ) + 14
	VIZ.BarChart( col3 + 16, vy, 150, 70, barData, { gradient = true } )
	VIZ.Radar( col3 + 260, vy + 40, radarAxes, radarVals, { radius = 44 } ) ; vy = vy + 90
	VIZ.LineGraph( col3 + 16, vy, 150, 60, { { values = lineA, clr = th.accent, fill = true }, { values = lineB, clr = th.bad } }, { grid = true, border = th.border } )
	VIZ.Gauge( col3 + 260, vy + 30, ANIM.Pulse( 0.4, 0.1, 0.95 ), { radius = 34, text = "PWR", needle = true } ) ; vy = vy + 74
	VIZ.Heatmap( col3 + 16, vy, 200, 40, heat, { border = th.border } )
	VIZ.Sparkline( col3 + 230, vy + 10, 100, 24, lineA, th.good, 1.5 )

	-- ── ANIMATION (new — harvested from HUD Mk.2 / HoloHUD2 / Smart Vision) ──
	-- A floating card that lags the player's view (ANIM.Sway parallax), whose
	-- whole composite fades in via the alpha-multiplier stack (ANIM.Reveal +
	-- DRAW.PushAlpha), with a trailing "chip" health bar, an envelope-driven glow,
	-- and letter-spaced / abbreviated-number text.
	local dx, dy = ANIM.Sway( 1, 1, ANIM.SWAY_MOVEMENT )
	local ax, ay = col2 + 4 + dx * 0.4, 470 + dy * 0.4
	local reveal = ANIM.Reveal( "showcase_card", true, 0.3, 0.4, "OutCubic" )

	DRAW.PushAlpha( reveal )
		-- envelope glow that flares while health is "low"
		local hp = 0.5 + 0.5 * math.sin( RealTime() * 0.8 )
		local glow = ANIM.Envelope( "showcase_lowhp", hp < 0.35, 0.08, 1.2, 0.15 )
		if glow > 0 then FX.BoxGlow( ax, ay, 330, 96, DRAW.Alpha( th.bad, 140 * glow ), 10, 5 ) end

		UI.Panel( ax, ay, 330, 96, frost( DRAW.LetterSpace( "SWAY / ANIM" ) ) )
		-- trailing loss/chip bar driven by the oscillating hp
		UI.Bar( ax + 12, ay + 30, 210, 16, hp, {
			fill = UI.StateColor, loss = true, lossKey = "showcase_hp",
			lossClr = DRAW.Alpha( th.bad, 200 ), text = "HULL",
		} )
		-- big HOLOGRAPHIC readout: additive glow + RGB chromatic split + leading
		-- ghost-zeros (the GL4/HoloHUD2 LED readout look). Guarded so a partial
		-- hot-reload (where zd_cl_draw_ui re-hit its load guard) degrades instead
		-- of erroring every frame — a full lua_reload restores the real helper.
		if UI.HoloNumber then
			UI.HoloNumber( ax + 306, ay + 52, math.floor( hp * 100 ), "ZDEV_UI_LED", UI.StateColor( hp ),
				{ digits = 3, align = TEXT_ALIGN_RIGHT, glowSize = 60 } )
		else
			DRAW.Text( math.floor( hp * 100 ), th.fontBold, ax + 306, ay + 44, UI.StateColor( hp ), TEXT_ALIGN_RIGHT )
		end
		-- scale hierarchy: big value above, tiny dim unit below (reference design)
		DRAW.Text( DRAW.LetterSpace( "INTEGRITY %" ), th.fontSmall, ax + 306, ay + 74, th.textDim, TEXT_ALIGN_RIGHT )
		-- rolling abbreviated number (odometer) + letter-spaced caption
		local score = ANIM.RollNumber( "showcase_score", 1.5e6 + math.sin( RealTime() * 0.5 ) * 4e5, 4 )
		DRAW.Text( "SCORE  " .. DRAW.ShortNumber( score ), th.fontBold, ax + 12, ay + 56, th.text )
		DRAW.Text( DRAW.LetterSpace( "PARALLAX HUD" ), th.fontSmall, ax + 12, ay + 76, th.textDim )
	DRAW.PopAlpha()

	-- ── FUI KIT (new components: reticles, spinner, globe, EQ, plexus, toggle,
	--    hatched bar, barcode, data-matrix, data-stream, tech-lines) ──────────
	local ky = UI.Panel( col1, 590, 700, 200, frost( "FUI KIT" ) ) + 16
	UI.Reticle( col1 + 40,  ky + 26, { style = "target" } )
	UI.Reticle( col1 + 96,  ky + 26, { style = "lock" } )
	UI.Reticle( col1 + 152, ky + 26, { style = "bracket" } )
	UI.Spinner( col1 + 214, ky + 26, 16 )
	VIZ.Globe( col1 + 292, ky + 26, 26, { spin = 22 } )
	VIZ.Equalizer( col1 + 380, ky + 26, 18, 28 )
	VIZ.Plexus( col1 + 452, ky + 2, 130, 60, 14, { animate = true } )
	UI.Toggle( col1 + 600, ky + 2, 40, 16, ANIM.Blink( 0.5 ), { label = "SYNC" } )
	UI.TechLine( col1 + 600, ky + 34, col1 + 660, ky + 52, { cap = "arrow" } )

	UI.Bar( col1 + 16, ky + 74, 300, 16, ANIM.Pulse( 0.5, 0.1, 1 ),
		{ fill = th.accent, hatch = true, hatchScroll = 10, border = DRAW.Alpha( th.accent, 120 ) } )
	VIZ.Barcode( col1 + 336, ky + 74, 150, 16, 7 )
	VIZ.DataMatrix( col1 + 506, ky + 72, 176, 18, 26, 3, { animate = true, density = 0.45 } )
	VIZ.DataStream( col1 + 16, ky + 100, 330, dataRows )

	-- signature tear-sheet metadata plate (bottom-right corner)
	UI.TearSheet( sw - 300, sh - 120, 284, {
		{ "PROJECT", "ZDEV" },   { "SET", "FUI KIT" },
		{ "MODULE", "DRAW.UI" }, { "VERSION", "A-02" },
		{ "STUDIO", "ZCOM" },    { "DATE", "2026-07-07" },
	}, { cols = 2 } )

	-- footer hint
	DRAW.Text( DRAW.LetterSpace( "ZDEV 2D DRAW LIBRARY  —  zdev_draw_showcase" ), th.fontSmall, sw / 2 - 200, sh - 16, th.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
end

hook.Add( "HUDPaint", "ZDEV_DrawShowcase", DrawShowcase )

zdev.log( "S", "Loaded file: '" .. _f .. "'" )
ZDEV.FILE.SetLoaded( _f )

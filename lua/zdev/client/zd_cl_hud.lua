--[[
	zd_cl_hud.lua
	Client HUD functions for zdev addon.
	Author: zcomstudios
	Description: Handles custom HUD elements for the zdev core.
]]
local _f = 'zdev/client/zd_cl_hud.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

ZDEV.FILE.SetLoaded( _f )

if not ZDEV.CHUD then ZDEV.CHUD = {} end
ZDEV.CHUD.Targets = ZDEV.CHUD.Targets or {}
local player = player
local ents = ents
local util = util
local math = math
local string = string
local bit = bit
local gamemode = gamemode
local hook = hook
local Vector = Vector
local VectorRand = VectorRand
local Angle = Angle
local AngleRand = AngleRand
local Entity = Entity
local Color = Color
local FrameTime = FrameTime
local RealTime = RealTime
local CurTime = CurTime
local SysTime = SysTime
local EyePos = EyePos
local EyeAngles = EyeAngles
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local tonumber = tonumber

local Lerp = Lerp
local type = type

local CurTime = CurTime
local RealTime = RealTime
local FrameTime = FrameTime
local RealFrameTime = RealFrameTime


local LP = LocalPlayer()
local lp_pos, lp_ang
local SW, SH = ScrW(), ScrH()
local SS = ScreenScale
local A_C, A_L, A_R = TEXT_ALIGN_CENTER, TEXT_ALIGN_LEFT, TEXT_ALIGN_RIGHT

local _DBUG = {}
_DBUG.SINE = {}
local tsin, tcos
local function DebugSineGraph()
	tsin = TimedSin( 0.33, 0, 12, 6 )
	tcos = TimedCos( 0.33, 0, 12, 6 )
	--draw.DrawText( tsin, "command", SW * 0.2, SH * 0.33, color_white, 0, 0 )
	--draw.DrawText( tcos, "command", SW * 0.2, SH * 0.35, color_white, 0, 0 )

	_DBUG.SINE.VAL = tsin

	--draw.RoundedBox( 0, 0, 0, 110, 110, Color(0,0,0,150) )
	--draw.RoundedBox( 0, SW *0.5 + tcos*50, SH * 0.5 + tsin*50, 10, 10, Color(0,255,0) )

	for x = 1, 100 do

		--draw.RoundedBox( 0, SW *0.5 + x*2, SH * 0.5 + tsin, 1, 1, Color(0,255,0) )

		--for y = 1, 100 do
		--	draw.RoundedBox( 0, x, y, 1, 1, Color(255,0,0) )
		--end

	end
end

local function CONV_HUD_CLR_PRI() local clr = string.ToColor( GetConVarString("zd_hud_clr_pri") ) return clr end
local function CONV_HUD_CLR_SEC() local clr = string.ToColor( GetConVarString("zd_hud_clr_sec") ) return clr end


local _HUD = {
	CLR = {
		PRI = CONV_HUD_CLR_PRI(),
		SEC = CONV_HUD_CLR_SEC(),
		BGD = Color( 0, 0, 0, 150 ),
		BRD = Color( 255, 255, 255, 200 )
	},
	VISOR = {
		OFFSET = 32, X = 0, Y = 0, W = SW, H = SH,
		MAT = Material("visor/visor_holo.png", "smooth" )
	},
	XHAIR = {
		X = SW * 0.5, Y = SH * 0.5, W = 64, H = 64,
		MAT = surface.GetTextureID( "vgui/hud/xbox_reticle" )
	},
	VITAL = {
		X = SW * 0.025, Y = SH * 0.95, W = SW * 0.15, H = SH * 0.065,
		HP = { VAL = 0, CLR = CONV_HUD_CLR_PRI(), MAT = Material("vgui/icon/icon_hps.vmt" ), W = 24, H = 24 },
		AR = { VAL = 0, CLR = CONV_HUD_CLR_PRI(), MAT = Material("vgui/icon/icon_arm.vmt" ), W = 24, H = 24 },
		ST = {},
		HU = {},
		EN = {}
	},
	ARSNL = {
		X = SW * 0.85, Y = SH * 0.925, W = SW * 0.15, H = SH * 0.065,
		WEP = {},
		PRI = { TYPE = -1, COUNT = -1, CLIP = -1 },
		SEC = { TYPE = -1, COUNT = -1, CLIP = -1 }
	},

}

--[[══════════════════════════════════════════════════════════════════════
		CROSSHAIR
══════════════════════════════════════════════════════════════════════]]
local xhair = {}
xhair.x = _HUD.XHAIR.X
xhair.y = _HUD.XHAIR.Y
local xh_hp, xh_ar
local xhcir_r0, xhcir_r1, xhcir_clr = 115, 240, Color(255,255,255,255)
local xh_ar_r0, xh_ar_r1, xh_ar_clr = 115, 240, color_white
local tr, tr_x, tr_y, tr_clr, tr_w, tr_h, tr_dist, tr_clr_a, tr_per = nil, 0,0, color_white, SS(38), SS(38)
local e_pos, e_x, e_y, e_w, e_h, e_clr, e_dist, e_clas
local t_enemy = {"manhack", "scanner", "police", "combine", "zombie", "headcrab", "turret", "ship", "camera", "mine", "guard", "antlion", "hunter", "breen" }
local t_allies = {"alyx","barney","citizen", "rebel", "odessa","kleiner", "magnusson", "eli", "mossman", "vortigaunt", "uriah", "dog" }
local function GetNPCFaction(npc)
	local class = npc:GetClass()
	for k,s in pairs( t_enemy ) do
		if string.find( class, s, 1, false) then return "enemy"	end
	end
	for k, a in pairs( t_allies ) do
		if string.find( class, a, 1, false) then return "ally" end
	end
	return "neutral"
end
local e_mats = {
	["hud/square/sqr_xs_6.png"] = {"manhack"}
}
local function PaintCrosshair( )
	LP = LocalPlayer()
	if not (LP and IsValid(LP) and LP:Alive() ) then return end
	lp_pos = LP:GetShootPos()
	xh_hp = LP:Health()
	xh_ar = LP:Armor()
	tr = LP:GetEyeTrace()
	tr_x, tr_y = tr.HitPos:ToScreen().x, tr.HitPos:ToScreen().y
	tr_dist = lp_pos:Distance( tr.HitPos )
	tr_per = math.Clamp(0,1,tr_dist/10000)
	tr_clr_a = 255 * (1-tr_per)

	_HUD.CLR.PRI = CONV_HUD_CLR_PRI()
	_HUD.CLR.SEC = CONV_HUD_CLR_SEC()
	xhcir_clr = _HUD.CLR.SEC

	for k, e in pairs( ents.FindInSphere( LP:GetShootPos(), 1024 ) ) do
		e_pos = e:WorldSpaceCenter() or e:GetPos()
		e_x, e_y = e_pos:ToScreen().x, e_pos:ToScreen().y
		e_dist = lp_pos:Distance(e_pos)
		e_w, e_h = SS(3), SS(4)
		if e:IsNPC() then
			local e_fact = GetNPCFaction(e)
			if e_fact == "enemy" then
				e_mat = "hud/micro/det_2xs_14.png"
				if ( e:GetClass() == "npc_turret_floor" ) then
					e_mat = "hud/icon/icon_turret.png"
				elseif ( e:GetClass() == "npc_turret_ceiling" ) then
					e_mat = "hud/icon/icon_turret_ceiling.png"
				elseif ( e:GetClass() == "npc_manhack" ) then
					e_mat = "hud/icon/icon_manhack.png"
				elseif ( e:GetClass() == "npc_camera_ceiling" ) then
					e_mat = "hud/icon/icon_camera_ceiling.png"
				elseif ( e:GetClass() == "npc_cscanner" ) then
					e_mat = "hud/icon/icon_scanner.png"
				end
				e_clr = Color(255,150,0,200)
				e_w, e_h = SS(8), SS(8)
				ZDEV.DRAW.TexturedRect( e_x - e_w/2, e_y - e_h/2, e_w, e_h, Material(e_mat), ColorAlpha(e_clr, 250) )
			elseif e_fact == "ally" then
				e_mat = "hud/micro/det_2xs_14.png"
				e_clr = Color(255,200,100)
				e_w, e_h = SS(3), SS(3)
				ZDEV.DRAW.TexturedRect( e_x - e_w/2, e_y - e_h/2, e_w, e_h, Material(e_mat), ColorAlpha(e_clr, 250) )

			end
		elseif e:IsPlayer() then
			e_mat = "hud/micro/det_2xs_13.png"
			e_clr = Color(100,255,100)
			e_w, e_h = SS(3), SS(3)
			ZDEV.DRAW.TexturedRect( e_x - e_w/2, e_y - e_h/2, e_w, e_h, Material(e_mat), ColorAlpha(e_clr, 250) )

		end
	end

	xhair.w, xhair.h = SS(4), SS(4)
		ZDEV.DRAW.TexturedRect( xhair.x -xhair.w/2, xhair.y - xhair.h/2, xhair.w, xhair.h, Material("hud/cross/13.png" ), ColorAlpha(tr_clr, 250) )

	xhair.w, xhair.h = surface.GetTextureSize( _HUD.XHAIR.MAT )
	surface.SetTexture( _HUD.XHAIR.MAT )
	surface.SetDrawColor( _HUD.CLR.PRI )
	surface.DrawTexturedRect( _HUD.XHAIR.X - xhair.w/2, _HUD.XHAIR.Y - xhair.h/2, xhair.w, xhair.h )
	ZDEV.DRAW.Circle(xhair.x, xhair.y, 27, 20, 0, 360, 6, ColorAlpha( xhcir_clr, 50 ),_HUD.CLR.PRI)
	ZDEV.DRAW.Circle(xhair.x, xhair.y, 17.5, 10, 0, 360, 6, ColorAlpha( xhcir_clr, 50 ),_HUD.CLR.SEC)

	--xhair.h = xhair.h * 0.1
	--xhair.w = xhair.w * 0.1
	--draw.RoundedBox( 0, xhair.x - xhair.w * 0.5, xhair.y - 0.5, xhair.w, 1, _HUD.CLR.PRI )
	---draw.RoundedBox( 0, xhair.x - 0.5, xhair.y - xhair.h*0.5, 1, xhair.h, _HUD.CLR.PRI )

	ZDEV.DRAW.Circle(tr_x + 64*(1-tr_per), tr_y, 50, 42.5, 270, 90, 2, ColorAlpha( xhcir_clr, 50 ),_HUD.CLR.PRI)
	ZDEV.DRAW.Circle(tr_x - 64*(1-tr_per), tr_y, 50, 42.5, 90, 270, 2, ColorAlpha( xhcir_clr, 50 ),_HUD.CLR.PRI)

	ZDEV.DRAW.TexturedRect( tr_x - tr_w/2, tr_y - tr_h/2, tr_w, tr_h, Material("hud/reticle/02_sqr.png" ), ColorAlpha(tr_clr, 50) )
	ZDEV.DRAW.TexturedRect( tr_x - tr_w/2, tr_y - tr_h/2, tr_w, tr_h, Material("hud/reticle/set1_2.png" ), ColorAlpha(tr_clr, 50) )
	ZDEV.DRAW.TexturedRect( tr_x - tr_w/2, tr_y - tr_h/2, tr_w, tr_h, Material("hud/reticle/set4_2.png" ), ColorAlpha(tr_clr, 50) )

	tr_w = math.Approach( tr_w, SS(38) * (1-tr_per), 0.66)
	tr_h = math.Approach( tr_h, SS(38) * (1-tr_per), 0.662)

	tr_w = SS(38) * (1-tr_per)
	tr_h = SS(38) * (1-tr_per)
	ZDEV.DRAW.TexturedRect( tr_x - tr_w/2, tr_y - tr_h/2, tr_w, tr_h, Material("hud/reticle/set4_3.png" ), ColorAlpha(tr_clr, 50) )

--[[


-- 	═══	HEALTH INDICATOR ═══════════════════════════════════════════════════════

	if xh_hp/100 < 0.2 then
		xhcir_clr = Color(255,0,0,255)
	else
		xhcir_clr = _HUD.CLR.SEC
	end
	xhcir_r0 = 240 - (LP:Health()/100) * 120
	ZDEV.DRAW.Circle(xhair.x,xhair.y,32,26,xhcir_r0, xhcir_r1,24, xhcir_clr,_HUD.CLR.SEC)


-- 	═══	ARMOR INDICATOR ════════════════════════════════════════════════════════

	if xh_ar/100 < 0.2 then
		xh_ar_clr = Color(255,0,0,255)
	else
		xh_ar_clr = _HUD.CLR.SEC
	end
	xh_ar_r0 = 300
	xh_ar_r1 = xh_ar_r0 + xh_ar/100 * 120
	ZDEV.DRAW.Circle(xhair.x,xhair.y,32,26,xh_ar_r0, xh_ar_r1,24, xh_ar_clr,_HUD.CLR.SEC)
]]
end

--[[══════════════════════════════════════════════════════════════════════
		VITALS - Health, Armor, Battery, Breath, etc.
══════════════════════════════════════════════════════════════════════]]
local hp = { x = _HUD.VITAL.X, y = _HUD.VITAL.Y }
local ar = {}
local st = {}
local function PaintVitals()
	LP = LocalPlayer()
	if not (LP and IsValid(LP) ) then return end

	_HUD.CLR.PRI = CONV_HUD_CLR_PRI()
	_HUD.CLR.SEC = CONV_HUD_CLR_SEC()

	-- NOTE Health
	_HUD.VITAL.HP.VAL = LP:Health()
	_HUD.VITAL.HP.PER = _HUD.VITAL.HP.VAL/LP:GetMaxHealth()

	hp.x = _HUD.VITAL.X
	hp.y = _HUD.VITAL.y or SH * 0.95
	hp.clr = _HUD.CLR.PRI

	ZDEV.DRAW.TexturedRect( hp.x - 35 , hp.y - 30, 294 * 0.5, 123 * 0.5, Material("hud/horiz/alltrend_388.png"), color_white )

	if _HUD.VITAL.HP.PER <= 0.33 then
		hp.clr = ColorAlpha(Color(255,0,0), 200 * TimedSin( 1.05, 1.1, 3, -1 ) )
		draw.DrawText( "000", "digital_djb_scan_glow", hp.x + 72, hp.y - 22, ColorAlpha( hp.clr, hp.clr.a ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
	end

	draw.RoundedBox( 6, hp.x - SS(12), hp.y - 36, _HUD.VITAL.W/2, _HUD.VITAL.H, Color(hp.clr.r/6, hp.clr.g/6, hp.clr.b/6,100) )

	ZDEV.DRAW.TexturedRect( hp.x - 12, hp.y - 12, _HUD.VITAL.HP.W, _HUD.VITAL.HP.H, _HUD.VITAL.HP.MAT, hp.clr )
	draw.DrawText( "HEALTH", "sadmachine",hp.x + 36, hp.y - 36, _HUD.CLR.SEC, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

	draw.DrawText( _HUD.VITAL.HP.VAL, "digital_djb_scan",hp.x + 72, hp.y - 22, hp.clr, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
	draw.DrawText( "000", "digital_djb_scan", hp.x + 72, hp.y - 22, ColorAlpha(hp.clr, 50), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )

	-- NOTE Armor
	_HUD.VITAL.AR.VAL = LP:Armor()

	if _HUD.VITAL.AR.VAL > 0 then

		_HUD.VITAL.AR.PER = _HUD.VITAL.AR.VAL/100

		ar.x = hp.x + ScreenScale( 48 )
		ar.y = hp.y
		ar.clr = _HUD.CLR.PRI
		if _HUD.VITAL.AR.PER <= 0.33 then
			ar.clr = ColorAlpha(Color(255,0,0), 200 * TimedSin( 1.05, 1.1, 3, -1 ) )
			draw.DrawText( "000", "digital_djb_scan_glow", ar.x + 72, ar.y - 22, ar.clr, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
		end

		draw.RoundedBox( 6, ar.x - SS(10), ar.y - 36, _HUD.VITAL.W/2.125, _HUD.VITAL.H, Color(ar.clr.r/6, ar.clr.g/6, ar.clr.b/6,100) )

		ZDEV.DRAW.TexturedRect( ar.x - 12, ar.y - 12, _HUD.VITAL.AR.W, _HUD.VITAL.AR.H, _HUD.VITAL.AR.MAT, ar.clr )
		draw.DrawText( "ARMOR", "sadmachine",ar.x + 36, ar.y - 36, _HUD.CLR.SEC, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		draw.DrawText( _HUD.VITAL.AR.VAL, "digital_djb_scan",  ar.x + 72, ar.y - 22, ar.clr, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
		draw.DrawText( "000", "digital_djb_scan", ar.x + 72,ar.y - 22, ColorAlpha(ar.clr, 50), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )

	end

	-- NOTE Stats

	-- !NOTE Stamina
	_HUD.VITAL.ST.VAL = LP:GetNWFloat( "ZDEV_STAT_Stamina" )
	_HUD.VITAL.ST.PER = _HUD.VITAL.ST.VAL / 1
	local i_st = math.Round(_HUD.VITAL.ST.PER * 100,0)
	st.x = hp.x + SS( 48 * 2 )
	st.y = hp.y
	st.clr = _HUD.CLR.PRI

	if _HUD.VITAL.ST.PER <= 0.33 then
		st.clr = ColorAlpha( Color(255,0,0), 200 * TimedSin( 1.05, 1.1, 3, -1) )
		draw.DrawText( "000", "digital_djb_scan", st.x + 72, st.y - 22, st.clr, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
	end

	draw.RoundedBox( 6, st.x - SS(10), st.y - 36, _HUD.VITAL.W/2.125, _HUD.VITAL.H, Color(st.clr.r/6, st.clr.g/6, st.clr.b/6,100) )

	draw.DrawText( i_st, "digital_djb_scan", st.x + 72, st.y - 22, _HUD.CLR.SEC, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
	draw.DrawText( "000", "digital_djb_scan", st.x + 72, st.y - 22, ColorAlpha(st.clr, 50), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )

	for i = 1, 15 do
		draw.RoundedBox( 0, st.x + i*4, st.y, 3, SS(3), ColorAlpha( _HUD.CLR.PRI, 50 ) )
	end
	for i = 1, i_st do
		draw.RoundedBox( 0, st.x + i*4, st.y, 3, SS(3), st.clr )
	end
end

--[[══════════════════════════════════════════════════════════════════════
		ARSENAL - Weapon & Ammunition Data
══════════════════════════════════════════════════════════════════════]]
_HUD.WEP = nil
local pri = { x = _HUD.ARSNL.X, y = _HUD.ARSNL.Y, type = "", cnt = 0, cl = 0, clr = Color(255,200,0,255), lbl = "PRIMARY", lbl_cnt = "COUNT", lbl_cl = "CLIP"}
local sec = { x = pri.x + ScreenScale(42), y = pri.y, type = "", cnt = 0, cl = 0, clr = Color(255,200,0,255) }
local b_hl2wep = false
local function PaintArsenal( )

	LP = LocalPlayer()
	if not (LP and IsValid(LP) ) then return end
 	_HUD.WEP = LP:GetActiveWeapon()
	if not IsValid(_HUD.WEP) then return end
	 if not _HUD.WEP:IsScripted() then b_hl2wep = true end

	_HUD.CLR.PRI = CONV_HUD_CLR_PRI()
	_HUD.CLR.SEC = CONV_HUD_CLR_SEC()

	_HUD.ARSNL.PRI.TYPE = _HUD.WEP:GetPrimaryAmmoType()
	_HUD.ARSNL.PRI.COUNT = LP:GetAmmoCount(_HUD.ARSNL.PRI.TYPE)
	_HUD.ARSNL.PRI.CLIP = _HUD.WEP:Clip1()

	_HUD.ARSNL.SEC.TYPE = _HUD.WEP:GetSecondaryAmmoType()
	_HUD.ARSNL.SEC.COUNT = LP:GetAmmoCount(_HUD.ARSNL.SEC.TYPE)
	_HUD.ARSNL.SEC.CLIP = _HUD.WEP:Clip2()

	pri.x, pri.y = _HUD.ARSNL.X, _HUD.ARSNL.Y or SH * 0.95
	pri.cnt = _HUD.ARSNL.PRI.COUNT
	pri.cl, pri.cl_max = _HUD.ARSNL.PRI.CLIP, _HUD.WEP:GetMaxClip1()
	pri.clr = _HUD.CLR.PRI
	if pri.cl / pri.cl_max <= 0.33 then
		pri.clr = ColorAlpha( Color(255,0,0), 200 * TimedSin( 1.05, 1.1, 3, -1 ) )
		draw.DrawText( "000", "digital_djb_scan_glow", pri.x + 72, pri.y, ColorAlpha(pri.clr, pri.clr.a/8 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
	end

	if _HUD.ARSNL.PRI.TYPE == -1 then return end

	if b_hl2wep then
		--draw.DrawText( "HL2", "sadmachine",pri.x, pri.y, _HUD.CLR.SEC, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		ZDEV.DRAW.TexturedRect( pri.x - _HUD.VITAL.AR.W/2, pri.y - _HUD.VITAL.AR.H/2 + 24, _HUD.VITAL.AR.W, _HUD.VITAL.AR.H, _HUD.VITAL.AR.MAT, pri.clr )
	end

	draw.RoundedBox( 6, pri.x - SS(11), pri.y - 14, _HUD.ARSNL.W/1.6, _HUD.ARSNL.H, Color(pri.clr.r/6, pri.clr.g/6, pri.clr.b/6,100) )
	draw.DrawText( "PRIMARY", "sadmachine",pri.x + 42, pri.y - 14, _HUD.CLR.SEC, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

	if pri.cl == -1 then
	--	draw.DrawText( "PRIMARY", "sadmachine",pri.x, pri.y - 36, _HUD.CLR.SEC, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		draw.DrawText( pri.cnt, "digital_djb_scan", pri.x + 72, pri.y, pri.clr, TEXT_ALIGN_RIGHT )
		draw.DrawText( "000", "digital_djb_scan", pri.x + 72, pri.y, ColorAlpha(pri.clr, 50), TEXT_ALIGN_RIGHT )
	else
		draw.DrawText( pri.cl, "digital_djb_scan", pri.x + 72, pri.y, pri.clr, TEXT_ALIGN_RIGHT )
		draw.DrawText( "000", "digital_djb_scan", pri.x + 72, pri.y, ColorAlpha(pri.clr, 50), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
		draw.DrawText( math.Clamp(pri.cnt,0,999), "digital2_djb_scan", pri.x + SS(46), pri.y, pri.clr, TEXT_ALIGN_RIGHT )
		draw.DrawText( "000", "digital2_djb_scan", pri.x + SS(46), pri.y, ColorAlpha(pri.clr, 50), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
	end

	if _HUD.ARSNL.SEC.TYPE ~= "none" and sec.cl and type(sec.cl) == "number" then

		sec.x, sec.y = pri.x + SS(62), pri.y or SH * 0.95
		sec.cnt = _HUD.ARSNL.SEC.COUNT
		sec.cl, sec.cl_max = _HUD.ARSNL.SEC.CLIP, _HUD.WEP:GetMaxClip2()
		sec.clr = _HUD.CLR.SEC
		if sec.cl / sec.cl_max <= 0.33 then
			sec.clr = ColorAlpha( Color(255,0,0), 200 * TimedSin( 1.05, 1.1, 3, -1 ) )
			draw.DrawText( "000", "digital_djb_scan_glow", sec.x + 72, sec.y, ColorAlpha(sec.clr, sec.clr.a/8 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
		end

		if sec.cnt > 0 then
			if b_hl2wep then
				ZDEV.DRAW.TexturedRect( sec.x - _HUD.VITAL.AR.W/2, sec.y - _HUD.VITAL.AR.H/2 + 24, _HUD.VITAL.AR.W, _HUD.VITAL.AR.H, _HUD.VITAL.AR.MAT, sec.clr )
			end
			draw.RoundedBox( 6, sec.x - SS(11), sec.y - 14, _HUD.ARSNL.W/2.125, _HUD.ARSNL.H, Color(sec.clr.r/6, sec.clr.g/6, sec.clr.b/6,100) )
			draw.DrawText( "SECONDARY", "sadmachine",sec.x + 42, sec.y - 14, _HUD.CLR.SEC, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			if sec.cl == -1 then
				draw.DrawText( sec.cnt, "digital_djb_scan", sec.x + 36, sec.y, sec.clr, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
			else
				draw.DrawText( sec.cl, "digital_djb_scan", sec.x + 36, sec.y, sec.clr, TEXT_ALIGN_RIGHT )
				draw.DrawText( sec.cnt, "digital2_djb_scan", sec.x, sec.y, sec.clr, TEXT_ALIGN_RIGHT )
			end
		end

	end

end

--[[══════════════════════════════════════════════════════════════════════
		PlLAYER INFO - Server/client data, Stats, UniqueID, etc
		--FUNCTION HUD PaintPlayerInfo
══════════════════════════════════════════════════════════════════════]]
_HUD.INFO = {SID = "",	UID = 0,	NICK = ""}
local mat_gold, mat_rank, name_rank
local function PaintPlayerInfo( )
	LP = LocalPlayer()
	if not (LP and IsValid(LP) ) then return end

	_HUD.CLR.PRI = CONV_HUD_CLR_PRI()
	_HUD.CLR.SEC = CONV_HUD_CLR_SEC()

	_HUD.INFO.SID = LP:SteamID()
	_HUD.INFO.UID = LP:UniqueID()
	_HUD.INFO.NICK = LP:Nick()
	_HUD.INFO.RANK = LP:GetNWInt("rank")
	mat_rank = ZDEV.RANK.Icon( _HUD.INFO.RANK )
	name_rank = ZDEV.RANK.Name( _HUD.INFO.RANK )
	_HUD.INFO.GOLD = LP:GetNWInt("gold")
	_HUD.INFO.EXP = LP:GetNWInt("ZDEV_Exp")

	draw.RoundedBox( 9, 0, 0, SW * 0.15, SH * 0.15, Color(0,0,0,200) )
	-- UniqueID
	draw.DrawText( _HUD.INFO.UID, "barcode", SW * 0.015, SH * 0.01, _HUD.CLR.SEC, TEXT_ALIGN_LEFT )
	-- SteamID
	draw.DrawText( _HUD.INFO.SID, "micro", SW * 0.015, SH * 0.0275, _HUD.CLR.SEC, TEXT_ALIGN_LEFT )
	-- Nickname
	draw.DrawText( _HUD.INFO.NICK, "reactor7", SW * 0.015, SH * 0.04, _HUD.CLR.PRI, TEXT_ALIGN_LEFT )
	local name_w, name_h = ZDEV.UTIL.GetTextSize( _HUD.INFO.NICK, "bios" )
	
	--Rank
	ZDEV.DRAW.TexturedRect( SW * 0.015 + name_w*1.1, SH * 0.06, 32, 32, mat_rank, color_white )
	draw.DrawText( string.upper( name_rank ), "micro", SW * 0.015, SH * 0.06, color_white, TEXT_ALIGN_LEFT )
	
	-- Level
	draw.DrawText( "Lv 1", "unica", SW * 0.475, SH * 0.04, color_white, TEXT_ALIGN_LEFT )
	-- Experiene
	draw.DrawText( _HUD.INFO.EXP, "extros", SW * 0.5, SH * 0.04, color_white, TEXT_ALIGN_CENTER )
	
	draw.DrawText( _HUD.INFO.EXP, "command", SW * 0.5, SH * 0.04, color_white, TEXT_ALIGN_CENTER )
	for i = 1, 100 do
		draw.RoundedBox( 0, 0 + 4*i, 3, 3, 3, Color(255,200,0,255) )
	end
	-- Gold

end

local sys = {
	t = { c = {0,"CurTime"}, r = {0,"RealTime"}, f = {0,"FrameTime"}, rf = {0,"RealFrameTime"} }
}
local i_sys = 0
local tr, tr_x, tr_y, tr_e, tr_e_x, tr_e_y, tr_size, tr_e_last = nil, 0, 0, nil, 0, 0, 8, nil
local e_pos, e_class, s_e, e_x, e_y, e_clr, e_dist, e_dist_max, e_size, e_a = nil, nil, nil, 0, 0, colzr_white, 0, 1024, 4, 200
local se_e, se_id, se_pos, se_x, se_y, se_ang, se_clr, se_fnt, se_a, se_size, se_mat
local xh_mat, xh_clr, xh_w, xh_h, xh_x, xh_y
local mk_mat, mk_clr, mk_w, mk_h, mk_x, mk_y
local gr_mat, gr_clr, gr_w, gr_h, gr_x, gr_y
local in_class, in_pos, in_ang, in_x, in_y, in_w, in_h, in_fnt, in_clr
local in_tbl = { kv = {}, st = {}, t = {}, nt = {}}
local b_InfoTableFilled = false
local mats = {
	xh = {
		sqr = Material("hud/crosshair/02_sqr.png"),
		sqr2 = Material("hud/cross/cross_0001.png")
	},
	sq = {
		a = Material("hud/square/sqr_lg_10.png"),
		b = Material("hud/square/sqr_lg_5.png"),
		c = Material("hud/square/sqr_lg_4.png"),
		c2 = Material("hud/square/sqr_lg_1.png"),
		xs = {
			a = Material("hud/square/sqr_xs_1.png"),
			b = Material("hud/square/sqr_xs_4.png"),
			c = Material("hud/square/sqr_xs_6.png"),
			d = Material("hud/square/sqr_xs_7.png"),
			e = Material("hud/square/sqr_xs_8.png"),
		},
		sm = {
			a = Material("hud/square/sqr_sm_2.png"),
			b = Material("hud/square/sqr_sm_3.png"),
			c = Material("hud/square/sqr_sm_4.png"),
			d = Material("hud/square/sqr_sm_5.png"),
			e = Material("hud/square/sqr_sm_6.png"),
			e = Material("hud/square/sqr_sm_7.png"),
			e = Material("hud/square/sqr_sm_8.png"),
			e = Material("hud/square/sqr_sm_9.png")
		}
	},
	mk = {
		xs = {
			a = Material("hud/square/sqr_xs_1.png"),
			b = Material("hud/square/sqr_xs_4.png"),
			c = Material("hud/square/sqr_xs_6.png"),
			d = Material("hud/square/sqr_xs_7.png"),
			e = Material("hud/square/sqr_xs_8.png")
		},
		sm = {
			a = Material("hud/square/sqr_sm_2.png"),
			b = Material("hud/square/sqr_sm_3.png"),
			c = Material("hud/square/sqr_sm_4.png"),
			d = Material("hud/square/sqr_sm_5.png"),
			e = Material("hud/square/sqr_sm_6.png"),
			e = Material("hud/square/sqr_sm_7.png"),
			e = Material("hud/square/sqr_sm_8.png"),
			e = Material("hud/square/sqr_sm_9.png")
		},
		md = {
			a = Material("hud/square/sqr_xs_1.png"),
			b = Material("hud/square/sqr_xs_4.png"),
			c = Material("hud/square/sqr_xs_6.png"),
			d = Material("hud/square/sqr_xs_7.png"),
			e = Material("hud/square/sqr_xs_8.png")
		}
	},
	gr = {
		bg = Material("hud/grid/grid_0.png"),
		s = Material("hud/grid/grd_2.png"),
		s2 = Material("hud/grid/grd_4.png"),
		m = Material("hud/grid/grd_1.png"),
		m = Material("hud/grid/grd_3.png"),
		m = Material("hud/grid/grd_5.png")
	}
}

--[[══════════════════════════════════════════════════════════════════════
		DEVELOPMENT
══════════════════════════════════════════════════════════════════════]]
local function PaintDevelopment( )
	LP = LocalPlayer()
	if not (LP and IsValid(LP) ) then return end

	local conv = {}
	conv.dev_time = GetConVar("zd_dev_hud_time"):GetBool()
	conv.dev_xhair = GetConVar("zd_dev_hud_xhair"):GetBool()
	conv.dev_grid = GetConVar("zd_dev_hud_grid"):GetBool()
	conv.dev_einf = GetConVar("zd_dev_hud_entinfo"):GetBool()
	conv.dev_ents = GetConVar("zd_dev_hud_ents"):GetBool()

	if conv.dev_time then
		sys.t.c[1] = CurTime()
		sys.t.r[1] = RealTime()
		sys.t.f[1] = FrameTime()
		sys.t.rf[1] = RealFrameTime()

		for _, t in pairs( sys.t ) do
			i_sys = i_sys + 1
			draw.DrawText( t[2] .. ":\t"..t[1], "sadmachine", SW*0.05, SH*0.33 + (i_sys*10), Color(200,200,200,150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		end
		i_sys = 0
	end

	if conv.dev_grid then
		gr_mat, gr_clr = mats.gr.bg, Color(255,255,255,255)
		gr_w, gr_h = 512, 512
		gr_x, gr_y = SW*0.5 - gr_w*0.5, SH*0.5 - gr_h*0.5
		ZDEV.DRAW.TexturedRect( gr_x, gr_y, gr_w, gr_h, gr_mat, gr_clr )
	end

	if conv.dev_xhair then
		tr = LocalPlayer():GetEyeTrace()
		tr_x, tr_y = ZDEV.UTIL.PosToScreen( tr.HitPos )
		tr_e = tr.Entity
		if tr_e_last == nil or tr_e_last ~= tr_e then
			b_InfoTableFilled = false
			tr_e_last = tr_e
		end

		tr_e_x, tr_e_y = ZDEV.UTIL.PosToScreen( tr_e:GetPos() )
		draw.RoundedBox( 0, tr_x - tr_size*0.5, tr_y - tr_size*0.5, tr_size, tr_size, Color(0,200,255) )
		
		xh_mat = mats.xh.sqr
		xh_clr = Color(100,200,255,100)
		xh_w, xh_h = 256, 256
		ZDEV.DRAW.TexturedRect( tr_x - xh_w*0.5, tr_y-xh_h*0.5, xh_w, xh_h, xh_mat, xh_clr )
		if tr_e and !tr_e:IsWorld() then
			mk_mat, mk_clr = mats.sq.a, Color(255,255,255,255)
			mk_w, mk_h = 100,100
			ZDEV.DRAW.TexturedRect( tr_e_x - mk_w*0.5, tr_e_y - mk_h*0.5, mk_w, mk_h, mk_mat, mk_clr )
		end
	end

	if LP:GetNWEntity( "LastDevSpawn" ) then
		se_e = LocalPlayer():GetNWEntity("LastDevSpawn") or LocalPlayer()
		se_id = LocalPlayer():GetNWInt( "LastDevSpawn_Index" )
		--[[
		se_pos = se_e:GetPos()
		se_x, se_y = ZDEV.UTIL.PosToScreen( se_pos )
		se_a = math.Clamp( 200, 0, 255 )
		se_clr = Color(255,255,150,se_a)
		se_fnt = "visitor"
		se_size = 16
		draw.RoundedBox( 0, se_x - se_size*0.5, se_y - se_size*0.5, se_size, se_size, ColorAlpha(se_clr, 50) )
		]]
	end

	if conv.dev_ents then
		for k, e in pairs( ents.GetAll() ) do

			e_pos = e:GetPos()
			e_dist = LP:GetShootPos():Distance(e_pos)
			e_class = e:GetClass()
			s_e = tostring(e)
			e_x, e_y = ZDEV.UTIL.PosToScreen( e_pos )

			e_a = 200 * (1-(e_dist/e_dist_max))
			draw.DrawText( s_e, "reactor7", e_x, e_y, Color(200,200,200,e_a), TEXT_ALIGN_LEFT, 1 )
			e_dist_max = 1600
			draw.RoundedBox( 0, e_x - e_size*0.5, e_y - e_size*0.5, e_size, e_size, Color(200,200,200,e_a+50) )

			if tr_e == e then

				mk_mat, mk_clr = mats.sq.sm.d, Color(0,200,255,e_a)
				mk_w, mk_h = 19,19
				if conv.dev_einf then

					in_class = e:GetClass()
					in_x, in_y = SW*0.3, SH*0.3
					in_w, in_h = 32, 32
					in_fnt, in_clr = "command", Color(255,255,255,150)
					draw.DrawText( tostring(in_class), in_fnt, in_x, in_y + in_h, in_clr, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
				
					if !b_InfoTableFilled then
						in_tbl.kv = e:GetSaveTable()
						in_tbl.st = e:GetSaveTable()
						in_tbl.t = e:GetTable()
						in_tbl.nt = e:GetNWVarTable()
						b_InfoTableFilled = true
					end
					local kv_i = table.GetKeys(in_tbl.kv)
					for i = 1, table.Count(kv_i) do
						in_h = 10*i
						local key = kv_i[i]
						local val = in_tbl.kv[ key ]
						draw.DrawText( tostring(key).."="..tostring(val), in_fnt, in_x, in_y + in_h, in_clr, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
					end
				end
			else
				mk_mat, mk_clr = mats.sq.xs.c, Color(255,255,255,e_a)
				mk_w, mk_h = 9,9
			end
			ZDEV.DRAW.TexturedRect( e_x - mk_w*0.5, e_y - mk_h*0.5, mk_w, mk_h, mk_mat, mk_clr )


		end
	end
end

--[[══════════════════════════════════════════════════════════════════════
		ENVIRONMENT EDITOR
══════════════════════════════════════════════════════════════════════]]
local function PaintEditor_Environment( )
	if !GetConVar( "zedit_env_toggle" ):GetBool() then return end

	draw.RoundedBox( 0, 0, 0, SW, 27, Color(100,100,100,255) )
	draw.DrawText( "ZDEV: ENVIRONMENT EDIT MODE", "raj", SW * 0.5 + 1, 0, Color( 10, 50, 100, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	draw.DrawText( "ZDEV: ENVIRONMENT EDIT MODE", "raj", SW * 0.5, 0, Color( 50, 200, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

	local conv_tool = GetConVar( "zedit_env_tool_mode" ):GetInt()
	local tool_name = "TOOL MODE: " .. ZDEV.EDIT.ENVM.Tool[ conv_tool ].Name
	local tool_font = "roboto-cn"

	local tool_w, tool_h = ZDEV.UTIL.GetTextSize( tool_name, tool_font )
	local tool_x, tool_y = SW * 0.05, SH * 0.25

	draw.RoundedBox( 6, tool_x - tool_w*0.1 + 2, tool_y - tool_h*0.1  + 3, tool_w * 1.2, tool_h * 1.1, Color( 0, 0, 0, 150 ) )
	draw.RoundedBox( 6, tool_x - tool_w*0.1, tool_y - tool_h*0.1, tool_w * 1.2, tool_h * 1.1, Color( 100, 100, 100, 255 ) )
	draw.DrawText( tool_name, tool_font, tool_x + tool_w*0.5, tool_y, Color(255,200,50,255), A_C, A_C )

end

local function PaintEditor_Particle( )
	if !GetConVar( "zedit_particle_toggle" ):GetBool() then return end
	
	draw.RoundedBox( 0, 0, 0, SW, 27, Color(100,100,100,255) )
	draw.DrawText( "ZDEV: PARTICLE EDIT MODE", "raj", SW * 0.5 + 1, 0, Color( 10, 50, 100, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	draw.DrawText( "ZDEV: PARTICLE EDIT MODE", "raj", SW * 0.5, 0, Color( 50, 200, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

	local p = {
		id = GetConVarString( "zedit_particle_id"),
		material = GetConVarString( "zedit_particle_mat" ),
		lifetime = GetConVar("zedit_particle_lifetime"):GetFloat(),
		dietime = GetConVar("zedit_particle_dietime"):GetFloat(),
		start_size = GetConVarNumber("zedit_particle_size_s"),
		start_alpha = GetConVarNumber("zedit_particle_alpha_s"),
		start_length = GetConVarNumber("zedit_particle_length_s"),
		end_size = GetConVarNumber("zedit_particle_size_e"),
		end_alpha = GetConVarNumber("zedit_particle_alpha_e"),
		end_length = GetConVarNumber("zedit_particle_length_e"),
		roll = GetConVarNumber("zedit_particle_roll"),
		rolldelta = GetConVarNumber("zedit_particle_rolldelta"),
		angles = GetConVarString("zedit_particle_angles"),
		ang_velocity = GetConVarString("zedit_particle_angular_velocity"),
		airres = GetConVarNumber("zedit_particle_airres"),
		bounce = GetConVar("zedit_particle_bounce"):GetFloat(),
		collide = GetConVar("zedit_particle_collide"):GetBool(),
		lighting = GetConVar("zedit_particle_lighting"):GetBool(),
		color = GetConVarNumber("zedit_particle_color"),
		color_r = GetConVarNumber("zedit_particle_color_r"),
		color_g = GetConVarNumber("zedit_particle_color_g"),
		color_b = GetConVarNumber("zedit_particle_color_b"),
		color_a = GetConVarNumber("zedit_particle_color_a"),
		gravity = GetConVarString("zedit_particle_gravity"),
		velocity = GetConVarString("zedit_particle_velocity")
	}

	for i, k in SortedPairs( table.GetKeys( p ) ) do
		local v = p[ k ]
		draw.DrawText( tostring( i ) .. ") " ..tostring(k) .. "\t = " .. tostring(v), "ConsoleText", SW * 0.5, SH * 0.66 + i*9, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
	end

end

--[[══════════════════════════════════════════════════════════════════════
		TARGET-LOCK
══════════════════════════════════════════════════════════════════════]]
local b_HasTarget = false
local tgtlock = {
	mats = {
		default = Material("hud/components/target/det_2xs_18.png"),
		highlight = Material("hud/components/target/det_2xs_28.png"),
		tracking = Material("hud/components/target/16.png"),
		target = Material("hud/components/target/sqr_04.png"),
		locked = Material("hud/components/target/sqr_03.png"),
		lost = Material("hud/components/target/sqr_05.png"),
		scan = Material("hud/components/target/sqr_01.png")
	}	
}
local scan = {}
local b_Animating = false
local mat = tgtlock.mats.default
local clr = Color(0,200,255,255)
local function PaintTargetLocking( )

	if ( not b_HasTarget ) then

	end

	for k, v in pairs( ZDEV.CHUD.Targets ) do
		local v_kv = util.TableToKeyValues(v);
		zdev.log( "D", "k:" .. tostring(k) .. " v:" .. tostring(v_kv) )
		if IsValid(ZDEV.CHUD.TargetEnt) then
			if not b_Animating then

				local w, h = 64, 64
				local x0, y0 = 0, 0
				local x1, y1 =  ZDEV.UTIL.PosToScreen( ZDEV.CHUD.TargetEnt:GetPos() )
				local x = ZDEV.TWEEN.Tween( x0, x1, 3, ZDEV.TWEEN.EaseOutElastic )
				local y = ZDEV.TWEEN.Tween( y0, y1, 3, ZDEV.TWEEN.EaseOutElastic )

				ZDEV.TWEEN.Add(x)
				ZDEV.TWEEN.Add(y)
			
				b_Animating = true
			end

			if x and y then
				local currentX = x:Update()
				local currentY = y:Update()
				zdev.log( "D", "X: " .. currentX .. " Y: " .. currentY )
				local w, h = 16, 16

				ZDEV.DRAW.TexturedRect( currentX - w/2, currentY - h/2, w, h, tgtlock.mats.target, clr )

				if not x:IsActive() and not y:IsActive() then
					zdev.log( "D", "Animation Stopped" )
					b_Animating = false
				end
			end

		end
		if v.LockTime < CurTime() then
			table.remove( ZDEV.CHUD.Targets, k )
		end
	end

end

--[[══════════════════════════════════════════════════════════════════════
		HUD-VISOR OVERLAY
══════════════════════════════════════════════════════════════════════]]
local visor_mat = {
		base = Material("visor/visor_holo.png"),
		blur = Material( "visor/visor_holo_blur.png" ),
		glow = Material( "visor/visor_holo_glow.png" ),
		damage = Material( "visor/visor_holo_glow_dmg.png" )
}
local _VISOR = {

}
local function PaintVisorOverlay( )
	local mat = visor_mat.base
	local color = Color(255,255,255,255)
    -- if not mat:IsValid() then return end
    
    local SW, SH = SW or ScrW(), SH or ScrH()
    
    -- Calculate offset based on eye angles with delay effect
    LP = LP or LocalPlayer()
    if not IsValid(LP) then return end
    
    local eyeAng = LP:EyeAngles()
    
    -- Store previous angles for smooth transition effect
    if not ZDEV.VISOR_LAST_ANG then
        ZDEV.VISOR_LAST_ANG = eyeAng
    end
    
    -- Smooth interpolation between current and previous angles
    local ft = FrameTime()
    local interp = math.Clamp(ft * 20, 0, 1) -- Adjust '10' for speed (Lower = more lag)
    ZDEV.VISOR_LAST_ANG = LerpAngle(interp, ZDEV.VISOR_LAST_ANG, eyeAng)
    
    -- Calculate UV offset based on angle difference
    local strength = 15 -- How many pixels to move per degree of difference
    local diffY = math.AngleDifference(eyeAng.y, ZDEV.VISOR_LAST_ANG.y) -- Yaw difference
    local diffP = math.AngleDifference(eyeAng.p, ZDEV.VISOR_LAST_ANG.p) -- Pitch difference

    local offsetX = diffY * strength
    local offsetY = diffP * -strength -- Invert pitch so looking up moves visor down
    
    -- Render larger than screen to create the overlay effect
    local scale = 1.25  -- Make it slightly larger than screen to hide edges when moving
    local width = SW * scale
    local height = SH * (scale * 0.85 )
    
    -- Center the visor on screen, then apply the offset
    local x = (SW - width) * 0.5 + offsetX
    local y = (SH - height) * 0.5 + offsetY

	ZDEV.DRAW.TexturedRect( x, y, width, height, visor_mat.base, Color(255,255,255,5) )
	ZDEV.DRAW.TexturedRect( x, y, width, height, visor_mat.blur, Color(255,255,255,50) )
	ZDEV.DRAW.TexturedRect( x, y, width, height, visor_mat.glow, Color(255,255,255,5) )
end
--[[▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃

	HUDPAINT Hook
▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃]]
-- ZDEV_UID: ZDEV_FUNC_B542172E | Path: ZDEV.CHUD.Paint
function ZDEV.CHUD.Paint( )
	LP = LocalPlayer()
	if not (LP and IsValid(LP) and LP:Alive() ) then return end

	_HUD.CLR.PRI = CONV_HUD_CLR_PRI()
	_HUD.CLR.SEC = CONV_HUD_CLR_SEC()

	draw.DrawText( "ZDEV 0.75.1.15", "sadmachine", SW * 0.5, SH * 0.02, Color( 100, 255, 100, 255 ), TEXT_ALIGN_CENTER )
	
	if GetConVar("zd_hud_visor"):GetBool() then
		PaintVisorOverlay( )
	end

	PaintTargetLocking( )
	DebugSineGraph()

	if GetConVar("zd_hud_vitals"):GetBool() then
		PaintVitals()
	end

	if GetConVar("zd_hud_ammo"):GetBool() then
		PaintArsenal( )
	end

	if GetConVar("zd_hud_crosshair"):GetBool() then
		PaintCrosshair()
	end

	if GetConVar("zd_hud_info"):GetBool() then
		PaintPlayerInfo( )
	end

	if LP:GetUserGroup() == "superadmin" then
		PaintDevelopment( )
	end

	if GetConVar( "zedit_env_toggle" ):GetBool() then
		PaintEditor_Environment( )
	end

	if GetConVar( "zedit_particle_toggle" ):GetBool() then
		PaintEditor_Particle( )
	end

end
hook.Add( "HUDPaint", "ZDEV.CHUD.Paint", ZDEV.CHUD.Paint )


local hide = {

--	['CHudChat'] = {cvar="zd_hud_chat", val=true},
--	['CHudCloseCaption'] = {cvar="zd_hud_ammo", val=true,
--	['CHudDamageIndicator'] = {cvar="zd_hud_ammo", val=true,
--	['CHudDeathNotice'] = {cvar="zd_hud_ammo", val=true,
--	['CHudMessage'] = {cvar="zd_hud_ammo", val=true,
	['CHudHealth'] = {cvar="zd_hud_vitals", val=true},
	['CHudBattery'] = {cvar="zd_hud_vitals", val=true},
	['CHudCrosshair'] = {cvar="zd_hud_crosshair", val=true},
	['CHudAmmo'] = {cvar="zd_hud_ammo", val=true},
	['CHudSecondaryAmmo'] = {cvar="zd_hud_ammo", val=true}
}

--[[▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃

	HUDSHOULDDRAW Hook
▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃]]
-- ZDEV_UID: ZDEV_FUNC_0D9AD868 | Path: ZDEV.CHUD.HideDefault
function ZDEV.CHUD.HideDefault( name )

	local b_hide

	for k, v in pairs( hide ) do
		local b_cvar = GetConVar(v.cvar):GetBool()
		if k == name then
			if b_cvar then
				return false
			end
		end
	end

end
hook.Add("HUDShouldDraw","ZDEV.CHUD.HideDefault",ZDEV.CHUD.HideDefault)

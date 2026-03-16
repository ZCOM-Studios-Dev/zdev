local _f = 'zdev/client/hud/zd_cl_hud_msg.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end

if not ZDEV.CHUD then ZDEV.CHUD = {} end
ZDEV.CHUD.MSGS = ZDEV.CHUD.MSGS or {}

MESSAGES = {}
MESSAGES._INDEX = {}

MARKERS = {}
MARKERS._INDEX = {}

local LP = LocalPlayer()
local lp_pos, lp_ang
local SW, SH = ScrW(), ScrH()
local SS = ScreenScale

local function CONV_HUD_CLR_PRI() local clr = string.ToColor( GetConVarString("zd_hud_clr_pri") ) return clr end
local function CONV_HUD_CLR_SEC() local clr = string.ToColor( GetConVarString("zd_hud_clr_sec") ) return clr end

local icon= {
	info = "vgui/icon/ui/Info.png",
	help = "vgui/icon/ui/Help.png",
	warn = "vgui/icon/ui/Warning.png",
	busy = "vgui/icon/ui/busy.png",
	comm = "vgui/icon/ui/Comment.png",
	flag = "vgui/icon/ui/flag.png",
	wrld = "vgui/icon/ui/world.png"
}

local _MSG = {
	CLR = {
		PRI = CONV_HUD_CLR_PRI(),
		SEC = CONV_HUD_CLR_SEC(),
		BGD = Color( 0, 0, 0, 150 ),
		BRD = Color( 255, 255, 255, 200 )
	}
}
local _HUD = {
	CLR = {
		PRI = CONV_HUD_CLR_PRI(),
		SEC = CONV_HUD_CLR_SEC(),
		BGD = Color( 0, 0, 0, 150 ),
		BRD = Color( 255, 255, 255, 200 )
	},
	XHAIR = {
		X = SW * 0.5, Y = SH * 0.5, W = 64, H = 64,
		MAT = surface.GetTextureID( "vgui/hud/xbox_reticle" )
	},
	VITAL = {
		X = SW * 0.025, Y = SH * 0.95, W = SW * 0.15, H = SH * 0.065,
		HP = { VAL = 0, CLR = CONV_HUD_CLR_PRI(), MAT = Material("vgui/icon/icon_hps.vmt" ), W = 24, H = 24 },
		AR = { VAL = 0, CLR = CONV_HUD_CLR_PRI(), MAT = Material("vgui/icon/icon_arm.vmt" ), W = 24, H = 24 }
	},
	ARSNL = {
		X = SW * 0.85, Y = SH * 0.925, W = SW * 0.15, H = SH * 0.065,
		WEP = {},
		PRI = { TYPE = -1, COUNT = -1, CLIP = -1 },
		SEC = { TYPE = -1, COUNT = -1, CLIP = -1 }
	},
	MSG = {
		[HUDMSG_INFO]		= {x=SW*0.05, y=SH*0.50, fnt="roboto-cn", icon=Material(icon.info), prefix="INFO", 	al_h=TEXT_ALIGN_LEFT, clr=Color(200,200,200), time=3 },
		[HUDMSG_HINT]		= {x=SW*0.05, y=SH*0.30, fnt="extros", icon=Material(icon.help), prefix="HINT", 	al_h=TEXT_ALIGN_LEFT, clr=Color(255,200,50), time=3 },
		[HUDMSG_WARN]		= {x=SW*0.05, y=SH*0.30, fnt="extros", icon=Material(icon.warn), prefix="WARNING",	al_h=TEXT_ALIGN_LEFT, clr=Color(255,150,0), time=3},
		[HUDMSG_ERROR]		= {x=SW*0.05, y=SH*0.30, fnt="extros", icon=Material(icon.busy), prefix="ERROR", 	al_h=TEXT_ALIGN_LEFT, clr=Color(255,100,50), time=3},
		[HUDMSG_ANNOUNCE]	= {x=SW*0.5, y=SH*0.2, 	 fnt="unica", icon=Material(icon.comm), prefix="/!\\", 	al_h=TEXT_ALIGN_CENTER, clr=Color(255,255,255), time=3},
		[HUDMSG_MARKER]		= {x=SW*0.5, y=SH*0.8, 	 fnt="bios", icon=Material(icon.flag), prefix="•", 		al_h=TEXT_ALIGN_CENTER, clr=Color(100,255,100), time=3, msgdata={ent=nil, args={}}},
		[HUDMSG_WORLD]		= {x=0, y=0,			 fnt="extros", icon=Material(icon.wrld), prefix="○",		al_h=TEXT_ALIGN_CENTER, clr=Color(50,200,255), time=3, msgdata={ pos=Vector(0,0,0),  args={}}}		
	}
}



local m_x, m_y, m_w, m_h, m_a, m_txt, m_fnt, m_clr, m_mat, m_data, m_type, m_al_h, m_al_v, m_time, m_pre_w, m_pre_h, m_txt_w, m_txt_h, m_pre_fnt, m_mat_w, m_mat_h
local m_mar, m_pad = { L = 3, T = 2, R = 3, B = 2 }, { L = 3, T = 2, R = 3, B = 2 }
local function PaintMessages( )

	LP = LocalPlayer()
	if not (LP and IsValid(LP) ) then return end

	for i, m in ipairs( MESSAGES._INDEX ) do

		m_type = m.type
		m_data = m.data

		local m_tbl = _HUD.MSG[m_type]

		m_mat, m_clr, m_fnt, m_pre, m_txt = m_tbl.icon, m_tbl.clr, m_tbl.fnt, m_tbl.prefix, m.text
		m_time = m.time
		m_pre_fnt = m_fnt
		m_x, m_y = m_tbl.x, m_tbl.y
		m_mat_w, m_mat_h = 24, 24
		m_txt_w, m_txt_h = ZDEV.UTIL.GetTextSize( m_txt, m_fnt )
		m_al_h, m_al_v = m_tbl.al_h, TEXT_ALIGN_CENTER
		m_pre_w, m_pre_h = ZDEV.UTIL.GetTextSize( m_pre, m_pre_fnt )
		m_w, m_h = m_mat_w + m_pre_w + m_txt_w, math.max( m_mat_h, m_pre_h, m_txt_h )

		if m_type == HUDMSG_MARKER and m_data.ent and IsValid(m.data.ent) then

			m_x, m_y = ZDEV.UTIL.PosToScreen( m_data.ent:GetPos() )

		elseif m_type == HUDMSG_WORLD and m_data.pos then

			m_x, m_y = ZDEV.UTIL.PosToScreen( m_data.pos )

		end

		local m_y_1 = m_y + i * ( m_h + m_mar.T )

		draw.RoundedBox( 6, m_x - m_pad.L, m_y_1 - m_pad.T, m_w + m_pad.R, m_h + m_pad.B, ColorAlpha( m_clr, 50 ) )
		ZDEV.DRAW.TexturedRect( m_x - m_mat_w*0.5 -  m_pad.R, m_y_1, m_mat_w, m_mat_h, m_mat, color_white )
		draw.DrawText( m_pre, m_pre_fnt, m_x + m_mat_w*0.5 + m_pad.L, m_y_1, m_clr, m_al_h, m_al_v )
		draw.DrawText( m_txt, m_fnt, m_x + m_pre_w + m_pad.L, m_y_1, m_clr, m_al_h, m_al_v )

	end

end

--[[▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃

	HUDPAINT Messages Hook
▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃]]
-- ZDEV_UID: ZDEV_FUNC_2E1DF3A6 | Path: ZDEV.CHUD.DrawMessages
function ZDEV.CHUD.DrawMessages( )
	LP = LocalPlayer()
	if not (LP and IsValid(LP) and LP:Alive() ) then return end

	_HUD.CLR.PRI = CONV_HUD_CLR_PRI()
	_HUD.CLR.SEC = CONV_HUD_CLR_SEC()

	if GetConVar("zd_hud_messages"):GetBool() then
		PaintMessages()
	end

end
hook.Add( "HUDPaint", "ZDEV.CHUD.DrawMessages", ZDEV.CHUD.DrawMessages )

local i_msgid = 0
net.Receive( "zdev_hud_msg_send", function( )

	local txt = net.ReadString()
	local mtyp = net.ReadUInt(3)
	local time = net.ReadFloat()
	local data = {}
	if mtyp == HUDMSG_MARKER or mtyp == HUDMSG_WORLD then
		data = net.ReadTable()
	end

	i_msgid = i_msgid + 1
	local id = i_msgid

	local msg = { id=i_msgid, type=mtyp, text=txt, time=time, data=data	}

	MESSAGES._INDEX[i_msgid] = msg

	timer.Simple( time, function() 
		MESSAGES._INDEX[ id ] = nil 
	end)

end )


local r_x, r_y, r_w, r_h, r_a, r_ent, r_ent_pos, r_mat, r_clr
local function PaintMarkers( )

	LP = LocalPlayer()
	if not (LP and IsValid(LP) ) then return end

	for i, m in pairs( MARKERS._INDEX ) do

		if m.ent and IsValid(m.ent) then

			local r_x, r_y, r_w, r_h, r_a, r_ent, r_ent_pos, r_mat, r_clr, r_pos

			r_ent = m.ent
			r_ent_pos = r_ent:WorldSpaceCenter() or r_ent:GetPos()
			r_pos = m.pos
			r_x, r_y = ZDEV.UTIL.PosToScreen( r_pos )
			r_clr = m.clr 
			r_mat = Material( m.mat )
			r_w, r_h = 16, 16

			if mat then
				ZDEV.DRAW.TexturedRect( r_x, r_y, r_w, r_h, r_mat, r_clr )
			else
				draw.RoundedBox( 0, r_x,r_y, r_w * 0.2, r_h * 0.2, r_clr )
			end
		end

	end

end

--[[▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃

	HUDPAINT Markers Hook
▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃▃]]
-- ZDEV_UID: ZDEV_FUNC_2018274D | Path: ZDEV.CHUD.DrawMarkers
function ZDEV.CHUD.DrawMarkers( )
	LP = LocalPlayer()
	if not (LP and IsValid(LP) and LP:Alive() ) then return end

	_HUD.CLR.PRI = CONV_HUD_CLR_PRI()
	_HUD.CLR.SEC = CONV_HUD_CLR_SEC()

	if GetConVar("zd_hud_messages"):GetBool() then
		PaintMarkers()
	end

end
hook.Add( "HUDPaint", "ZDEV.CHUD.DrawMarkers", ZDEV.CHUD.DrawMarkers )

net.Receive( "zdev_hud_marker_ent", function( )

	local mid = net.ReadString()
	local ent = net.ReadEntity()
	local pos = net.ReadVector()
	local mat = net.ReadString()
	local clr = net.ReadColor()
	local time = net.ReadFloat()

	if not ( ent and IsValid(ent) ) then return end

	local marker = { id=mid, ent=ent, pos=pos, mat=mat, clr=clr, time=time }
	MARKERS._INDEX[ mid ] = marker

	if time > 0 then
		timer.Simple( time, function()
			MARKERS._INDEX[ mid ] = nil
		end)
	end

	zdev.log( "I", "Added HUD-Marker (" .. tostring(mid) .. ") for Entity: " .. tostring(ent) )

end )

net.Receive( "zdev_hud_marker_ent_remove", function( )

	local mid = net.ReadString()
	local ent = net.ReadEntity()

	if not ( ent and IsValid( ent ) ) then ErrorNoHalt( "Cannot Remove HUD-Marker. Entity invalid" ) return end

	if MARKERS._INDEX[ mid ] then
		MARKERS._INDEX[ mid ] = nil
	end

	zdev.log( "I", "Removed HUD-Marker (" .. tostring(mid) .. ") for Entity: " .. tostring(ent) )

end )
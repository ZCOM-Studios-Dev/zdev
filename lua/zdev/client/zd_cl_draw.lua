local _f = 'zdev/client/zd_cl_draw.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

ZDEV.TWEEN = ZDEV.TWEEN or {}

--[[
	zd_cl_draw.lua
	Client draw functions for zdev addon.
	Author: zcomstudios
	Description: Handles custom drawing logic for the zdev HUD and UI.
]]


local DrawRect 		= DrawRect
local DrawPoly 		= surface.DrawPoly
local SetDrawColor 	= surface.SetDrawColor
local Grad 			= Material("gui/gradient_down")
local rad = math.rad
local cos = math.cos
local sin = math.sin
local abs = math.abs
local DrawPoly, SetTexture = surface.DrawPoly, surface.SetTexture
local Add 		= table.Add
local insert 	= table.insert

local LP = LocalPlayer()
local SW, SH = ScrW(), ScrH()

-- ZDEV_UID: ZDEV_FUNC_27094932 | Path: ZDEV.DRAW.TexturedRect
function ZDEV.DRAW.TexturedRect( x, y, w, h, mat, clr )
	draw.NoTexture()
	surface.SetDrawColor( clr.r, clr.g, clr.b, clr.a )
	surface.SetMaterial( mat )
	surface.DrawTexturedRect( x, y, w, h )
end

ZDEV.DRAW.MaterialBox = ZDEV.DRAW.TexturedRect

-- ZDEV_UID: ZDEV_FUNC_5D7393AE | Path: ZDEV.DRAW.UVTexturedRect
function ZDEV.DRAW.UVTexturedRect( x, y, w, h, u, v, u0, v0, mat, clr )
	draw.NoTexture()
	surface.SetMaterial( mat )
	surface.SetDrawColor( clr )
	surface.DrawTexturedRectUV( x, y, w, h, u, v, u0, v0 )
end

-- ZDEV_UID: ZDEV_FUNC_87ABA76B | Path: ZDEV.DRAW.TexturedRectRot
function ZDEV.DRAW.TexturedRectRot( x, y, w, h, ang, mat, clr )
	draw.NoTexture()
	surface.SetMaterial( mat )
	surface.SetDrawColor( clr or color_white )
	surface.DrawTexturedRectRotated( x, y, w, h, ang )
end

-- ZDEV_UID: ZDEV_FUNC_5B016BFE | Path: ZDEV.DRAW.TexturedRectRotPoint
function ZDEV.DRAW.TexturedRectRotPoint( x, y, w, h, rot, x0, y0, mat, clr )
	local c = math.cos( math.rad( rot ) )
	local s = math.sin( math.rad( rot ) )
	local newx = y0 * s - x0 * c
	local newy = y0 * c + x0 * s
	draw.NoTexture()
	surface.SetMaterial( mat )
	surface.SetDrawColor( clr )
	surface.DrawTexturedRectRotated( x + newx, y + newy, w, h, rot )
end

-- ZDEV_UID: ZDEV_FUNC_1A55F943 | Path: ZDEV.DRAW.OutlinedBox
function ZDEV.DRAW.OutlinedBox( x, y, w, h, thickness, clr )
	draw.NoTexture()
	surface.SetDrawColor( clr.r, clr.g, clr.b, clr.a)
	for i=0, thickness - 1 do
		surface.DrawOutlinedRect( x + i, y + i, w - i * 2, h - i * 2 )
	end
end

-- ZDEV_UID: ZDEV_FUNC_62D9A0EC | Path: ZDEV.DRAW.Circle
function ZDEV.DRAW.Circle(x,y,r,r2,startang,endang,iter,col,col2)
	local rstartang 	= rad(startang)
	local rendang 		= rad(endang)

	draw.NoTexture()
	surface.SetDrawColor(col.r,col.g,col.b,col.a)

	local OutR 	= abs(r-4)
	local OutR2 = abs(r2+4)

	local Step = abs(rendang-rstartang)/iter

	SetDrawColor(col.r,col.g,col.b,col.a)

	for i = 0, iter-1 do
		local Time1 = Step*i+rstartang
		local Time2 = Time1+Step

		--First layer
		local dat2 	= {
			{
				x=cos(Time2)*OutR+x,
				y=-sin(Time2)*OutR+y,
				u=0,
				v=0,
			},
			{
				x=cos(Time2)*OutR2+x,
				y=-sin(Time2)*OutR2+y,
				u=1,
				v=0,
			},
			{
				x=cos(Time1)*OutR2+x,
				y=-sin(Time1)*OutR2+y,
				u=1,
				v=1,
			},
			{
				x=cos(Time1)*OutR+x,
				y=-sin(Time1)*OutR+y,
				u=0,
				v=1,
			},
		}

		DrawPoly(dat2)
	end

	if (col2) then ZDEV.DRAW.Circle(x,y,r+1,r2-1,startang,endang,iter,col2) end
end

-- ZDEV_UID: ZDEV_FUNC_DCD5CAB5 | Path: ZDEV.DRAW.DottedCircle
function ZDEV.DRAW.DottedCircle( x, y, w, h, radius, seg, col )
  	local cir = {}
  	local ang = {}
	draw.NoTexture()
	surface.SetDrawColor(col.r,col.g,col.b,col.a)

  	table.insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
    for i = 0, seg do
      local a = math.rad( ( i / seg ) * -360 )
      table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
      table.insert( ang, math.deg(a) )
    end

    local a = math.rad( 0 ) -- This is needed for non absolute segment counts
    table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )

    for k, c in pairs( cir ) do
      if ang[k] then
        surface.DrawTexturedRectRotated( c.x, c.y, w, h, ang[k]+math.deg(360/seg))
      end
    end

end

-- ZDEV_UID: ZDEV_FUNC_57C5CA0B | Path: ZDEV.DRAW.Sector
function ZDEV.DRAW.Sector(x, y, r, ang, rot, col)

	local segments = 360
	local segmentstodraw = 360 * (ang/360)
	rot = rot* (segments/360)
	local poly = {}

	local temp = {}
	temp['x'] = x
	temp['y'] = y
	table.insert(poly, temp)

	for i = 1+rot, segmentstodraw+rot do
		local temp = {}
		temp['x'] = math.cos( (i*(360/segments) )*(math.pi/180) ) * r + x
		temp['y'] = math.sin( (i*(360/segments) )*(math.pi/180) ) * r + y

		table.insert(poly, temp)
	end
	draw.NoTexture()
	surface.SetDrawColor(col.r,col.g,col.b,col.a)
	surface.DrawPoly(poly)

end

-- ZDEV_UID: ZDEV_FUNC_3CFDFA45 | Path: ZDEV.DRAW.Diamond
function ZDEV.DRAW.Diamond(x,y,w,h,col,col2)
	local DigH = h/2

	--FirstLayer
	local dat 	= {
		{
			x=x,
			y=y+DigH,
			u=0,
			v=0.5,
		},
		{
			x=x+DigH,
			y=y,
			u=DigH/w,
			v=0,
		},
		{
			x=x+w-DigH,
			y=y,
			u=(w-DigH)/w,
			v=0,
		},
		{
			x=x+w,
			y=y+DigH,
			u=1,
			v=0.5,
		},
		{
			x=x+w-DigH,
			y=y+h,
			u=(w-DigH)/w,
			v=1,
		},
		{
			x=x+DigH,
			y=y+h,
			u=DigH/w,
			v=1,
		},
	}

	SetDrawColor(col.r,col.g,col.b,col.a)

	--Secondlayer
	if (col2) then
		draw.NoTexture()
		DrawPoly(dat)
		surface.SetMaterial(Grad)
		ZDEV.DRAW.Diamond(x+5,y+5,w-10,h-10,col2)
	else
		DrawPoly(dat)
	end
end

-- ZDEV_UID: ZDEV_FUNC_98BF9DA8 | Path: ZDEV.DRAW.Box
function ZDEV.DRAW.Box(x,y,w,h,col,col2)
	local DigH = h/3
	w = math.max(w,DigH)

	--FirstLayer
	--[[local dat 	= {
		{
			x=x,
			y=y+h,
			u=0,
			v=1,
		},
		{
			x=x,
			y=y+DigH,
			u=0,
			v=DigH/h,
		},
		{
			x=x+DigH,
			y=y,
			u=DigH/w,
			v=0,
		},
		{
			x=x+w,
			y=y,
			u=1,
			v=0,
		},
		{
			x=x+w,
			y=y+DigH*2,
			u=1,
			v=(DigH*2)/h,
		},
		{
			x=x+w-DigH,
			y=y+h,
			u=(w-DigH)/w,
			v=1,
		},
	}]]


	SetDrawColor(col.r,col.g,col.b,col.a)

	--Secondlayerwww
	--[[if (col2) then
		draw.NoTexture()
		DrawPoly(dat)
		surface.SetMaterial(Grad)
		DrawSRPBox(x+5,y+5,w-10,h-10,col2)
	else
		DrawPoly(dat)
	end]]
	--surface.DrawRect(x, y, w, h)
	draw.RoundedBox(16, x, y, w, h, col)
end

-- ZDEV_UID: ZDEV_FUNC_E367B3D9 | Path: ZDEV.DRAW.Star
function ZDEV.DRAW.Star(x,y,r1,r2,col,ang)
	ang = ang or 0
	draw.NoTexture()

	--FirstLayer
	local dat 	= {}

	for i = 1,8 do
		local Deg  	= rad(45*i+ang)
		local Deg2  = rad(90*i)
		local Dis 	= r1+r2*abs(cos(Deg2))

		local Tab 	= {
			x=x+Dis*cos(Deg),
			y=y+Dis*sin(Deg),
			u=0,
			v=0,
		}

		insert(dat,Tab)
	end

	SetDrawColor(col.r,col.g,col.b,col.a)
	DrawPoly(dat)
end

-- ZDEV_UID: ZDEV_FUNC_37E9DBAF | Path: ZDEV.DRAW.TextRotated
function ZDEV.DRAW.TextRotated( text, font, x, y, Tcol, ang)
	render.PushFilterMag( TEXFILTER.ANISOTROPIC )
	render.PushFilterMin( TEXFILTER.ANISOTROPIC )

	local m = Matrix()
	m:SetTranslation( Vector( x, y, 0 ) )
	m:SetAngles( Angle( 0, ang, 0 ) )

	cam.PushModelMatrix( m )
		DrawText(text,font,0,0,Tcol,1)
	cam.PopModelMatrix()

	render.PopFilterMag()
	render.PopFilterMin()
end

-- ZDEV_UID: ZDEV_FUNC_CF993C96 | Path: ZDEV.DRAW.TextRotatedBox
function ZDEV.DRAW.TextRotatedBox( text, font, x, y, w, h, Tcol, ang, col, col2 )
	render.PushFilterMag( TEXFILTER.ANISOTROPIC )
	render.PushFilterMin( TEXFILTER.ANISOTROPIC )

	local m = Matrix()
	m:SetAngles( Angle( 0, ang, 0 ) )
	m:SetTranslation( Vector( x, y, 0 ) )

	cam.PushModelMatrix( m )
		DrawSRPBox(0,0,w,h,col,col2)
		DrawText(text,font,w/2,h/2,Tcol,1)
	cam.PopModelMatrix()

	render.PopFilterMag()
	render.PopFilterMin()
end
local rect, mod, setcolor = surface.DrawRect, math.mod, surface.SetDrawColor

-- ZDEV_UID: ZDEV_FUNC_75729027 | Path: ZDEV.DRAW.Grid
function ZDEV.DRAW.Grid(x, y, w, h, color)

	local val=0

	setcolor(color)

	for i=0,w do
		val=val+1
		if mod(val,2)~=0 then
			rect( x+i, y, 1, 1 )
		end
	end

	for i=1,h do
		val=val+1
		if mod(val,2)~=0 then
			rect( x+w, y+i, 1, 1 )
		end
	end

	for i=1,w do
		val=val+1
		if mod(val,2)~=0 then
			rect( x+w-i, y+h, 1, 1 )
		end
	end

	for i=1,h do
		val=val+1
		if mod(val,2)~=0 then
			rect( x, y+h-i, 1, 1 )
		end
	end

end

-- ZDEV_UID: ZDEV_FUNC_940C0322 | Path: ZDEV.DRAW.CircleFilled
function ZDEV.DRAW.CircleFilled(x, y, radius, quality)
	SetTexture(0)

    local circle = {}
    local tmp = 0
    for i=1, quality do
        tmp = rad(i * 360) / quality
        circle[i] = {x = x + cos(tmp) * radius, y = y + sin(tmp) * radius}
    end
    DrawPoly(circle)
end

local color_white = color_white

-- ZDEV_UID: ZDEV_FUNC_66F4DC59 | Path: ZDEV.DRAW.Trapezoid
function ZDEV.DRAW.Trapezoid(x, y, w, h, z, color)
	SetTexture(0)
	setcolor(color or color_white)
	local Trapezoid = {}
	Trapezoid[1] = { x = (w+z)+x, y = y+h }
	Trapezoid[2] = { x = x, y = y+h }
	Trapezoid[3] = { x = x+z, y = y }
	Trapezoid[4] = { x = w+x, y = y }

	DrawPoly(Trapezoid)
end

--[[ 
	Moat's text effects for garry's mod :D
	https:--steamcommunity.com/id/moat_
]]--


local function m_AlignText( text, font, x, y, xalign, yalign )
	surface.SetFont( font )
	local textw, texth = surface.GetTextSize( text )
	if ( xalign == TEXT_ALIGN_CENTER ) then
		x = x - ( textw / 2 )
	elseif ( xalign == TEXT_ALIGN_RIGHT ) then
		x = x - textw
	end
	if ( yalign == TEXT_ALIGN_BOTTOM ) then
		y = y - texth
	end
	return x, y
end
--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-CL Draw 
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function DrawShadowedText( shadow, text, font, x, y, color, xalign, yalign )
	local xalign = xalign or TEXT_ALIGN_LEFT
	local yalign = yalign or TEXT_ALIGN_TOP
	draw.SimpleText( text, font, x + shadow, y + shadow, Color( 0, 0, 0, color.a or 255 ), xalign, yalign )
	draw.SimpleText( text, font, x, y, color, xalign, yalign )
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-CL Draw 
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function GlowColor( col1, col2, mod )
	local newr = col1.r + ( ( col2.r - col1.r ) * ( mod ) )
	local newg = col1.g + ( ( col2.g - col1.g ) * ( mod ) )
	local newb = col1.b + ( ( col2.b - col1.b ) * ( mod ) )
	return Color( newr, newg, newb )
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-CL Draw 
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function DrawEnchantedText( speed, text, font, x, y, color, glow_color, xalign, yalign )
	local xalign = xalign or TEXT_ALIGN_LEFT
	local yalign = yalign or TEXT_ALIGN_TOP
	local glow_color = glow_color or Color( 127, 0, 255 )
	local texte = string.Explode( "", text )
	local x, y = m_AlignText( text, font, x, y, xalign, yalign )
	surface.SetFont( font )
	local chars_x = 0
	for i = 1, #texte do
		local char = texte[i]
		local charw, charh = surface.GetTextSize( char )
		local color_glowing = GlowColor( glow_color, color, math.abs( math.sin( ( RealTime() - ( i * 0.08 ) ) * speed ) ) )
		draw.SimpleText( char, font, x + chars_x, y, color_glowing, xalign, yalign )
		chars_x = chars_x + charw
	end
end
--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-CL Draw 
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function DrawFadingText( speed, text, font, x, y, color, fading_color, xalign, yalign )
	local xalign = xalign or TEXT_ALIGN_LEFT
	local yalign = yalign or TEXT_ALIGN_TOP
	local color_fade = GlowColor( color, fading_color, math.abs( math.sin( ( RealTime() - 0.08 ) * speed ) ) )
	draw.SimpleText( text, font, x, y, color_fade, xalign, yalign )
end
local col1 = Color( 0, 0, 0 )
local col2 = Color( 255, 255, 255 )
local next_col = 0
--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-CL Draw 
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function DrawRainbowText( speed, text, font, x, y, xalign, yalign )
	local xalign = xalign or TEXT_ALIGN_LEFT
	local yalign = yalign or TEXT_ALIGN_TOP
	next_col = next_col + 1 / ( 100 / speed )
	if ( next_col >= 1 ) then 
		next_col = 0
		col1 = col2
		col2 = ColorRand()
	end
	draw.SimpleText( text, font, x, y, GlowColor( col1, col2, next_col ), xalign, yalign )
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-CL Draw 
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function DrawGlowingText( static, text, font, x, y, color, xalign, yalign )
	local xalign = xalign or TEXT_ALIGN_LEFT
	
	local yalign = yalign or TEXT_ALIGN_TOP
	local initial_a = 20
	local a_by_i = 5
	local alpha_glow = math.abs( math.sin( ( RealTime() - 0.1 ) * 2 ) )
	if ( static ) then alpha_glow = 1 end
	for i = 1, 2 do
		draw.SimpleTextOutlined( text, font, x, y, color, xalign, yalign, i, Color( color.r, color.g, color.b, ( initial_a - ( i * a_by_i ) ) * alpha_glow ) )
	end
	draw.SimpleText( text, font, x, y, color, xalign, yalign )
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-CL Draw 
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function DrawBouncingText( style, intesity, text, font, x, y, color, xalign, yalign )
	local xalign = xalign or TEXT_ALIGN_LEFT
	
	local yalign = yalign or TEXT_ALIGN_TOP
	local texte = string.Explode( "", text )
	surface.SetFont( font )
	local chars_x = 0
	local x, y = m_AlignText( text, font, x, y, xalign, yalign )
	for i = 1, #texte do
		local char = texte[i]
		local charw, charh = surface.GetTextSize( char )
		local y_pos = 1
		local mod = math.sin( ( RealTime() - ( i * 0.1 ) ) * ( 2 * intesity ) )
		if ( style == 1 ) then
			y_pos = y_pos - math.abs( mod )
		elseif ( style == 2 ) then
			
			y_pos = y_pos + math.abs( mod )
		else
			y_pos = y_pos - mod
		end
		draw.SimpleText( char, font, x + chars_x, y - ( 5 * y_pos ), color, xalign, yalign )
		chars_x = chars_x + charw
	end
end
local next_electic_effect = CurTime() + 0
local electric_effect_a = 0
--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-CL Draw 
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function DrawElecticText( intensity, text, font, x, y, color, xalign, yalign )
	local xalign = xalign or TEXT_ALIGN_LEFT
	
	local yalign = yalign or TEXT_ALIGN_TOP
	local charw, charh = surface.GetTextSize( text )
	draw.SimpleText( text, font, x, y, color, xalign, yalign )
	if ( electric_effect_a > 0 ) then
		
		electric_effect_a = electric_effect_a - ( 1000 * FrameTime() )
	end
	surface.SetDrawColor( 102, 255, 255, electric_effect_a )
	for i = 1, math.random( 5 ) do
		line_x = math.random( charw )
		line_y = math.random( charh )
		line_x2 = math.random( charw )
		line_y2 = math.random( charh )
		surface.DrawLine( x + line_x, y + line_y, x + line_x2, y + line_y2 )
	end
	local effect_min = 0.5 + ( 1 - intensity )
	local effect_max = 1.5 + ( 1 - intensity )
	if ( next_electic_effect <= CurTime() ) then
		next_electic_effect = CurTime() + math.Rand( effect_min, effect_max )
		
		electric_effect_a = 255
	end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-CL Draw 
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function DrawFireText( intensity, text, font, x, y, color, xalign, yalign, glow, shadow )
	local xalign = xalign or TEXT_ALIGN_LEFT
	
	local yalign = yalign or TEXT_ALIGN_TOP
	surface.SetFont( font )
	local charw, charh = surface.GetTextSize( text )
	local fire_height = charh * intensity
	for i = 1, charw do
		
		local line_y = math.random( fire_height, charh )
		local line_x = math.random( -4, 4 )
		local line_col = math.random( 255 )
		surface.SetDrawColor( 255, line_col, 0, 150 )
		surface.DrawLine( x - 1 + i, y + charh, x - 1 + i + line_x, y + line_y )
	end
	if ( glow ) then
		
		DrawGlowingText( true, text, font, x, y, color, xalign, yalign )
	end
	if ( shadow ) then
		draw.SimpleText( text, font, x + 1, y + 1, Color( 0, 0, 0 ), xalign, yalign )
	end
	draw.SimpleText( text, font, x, y, color, xalign, yalign )
end
--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-CL Draw 
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function DrawSnowingText( intensity, text, font, x, y, color, color2, xalign, yalign )
	local xalign = xalign or TEXT_ALIGN_LEFT
	
	local yalign = yalign or TEXT_ALIGN_TOP
	local color2 = color2 or Color( 255, 255, 255 )
	draw.SimpleText( text, font, x, y, color, xalign, yalign )
	surface.SetFont( font )
	local textw, texth = surface.GetTextSize( text )
	surface.SetDrawColor( color2.r, color2.g, color2.b, 255 )
	for i = 1, intensity do
		
		local line_y = math.random( 0, texth )
		local line_x = math.random( 0, textw )
		surface.DrawLine( x + line_x, y + line_y, x + line_x, y + line_y + 1 )
	end
end

local MOAT_SHOW_EFFECT_EXAMPLES = false
--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	FUNC-CL Draw 
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]
function moat_DrawEffectExamples()
	if ( not MOAT_SHOW_EFFECT_EXAMPLES ) then return end
	local font = "DermaLarge"
	draw.RoundedBox( 0, 50, 50, 700, 500, Color( 0, 0, 0, 200 ) )
	local x = 100
	local y = 100
	DrawGlowingText( false, "GLOWING TEXT", font, x, y, Color( 255, 0, 0, 255 ) )
	y = y + 50
	DrawFadingText( 1, "FADING COLORS TEXT", font, x, y, Color( 255, 0, 0 ), Color( 0, 0, 255 ) )
	y = y + 50
	DrawRainbowText( 1, "RAINBOW TEXT", font, x, y )
	y = y + 50
	DrawEnchantedText( 2, "ENCHANTED TEXT", font, x, y, Color( 255, 0, 0 ), Color( 0, 0, 255 ) )
	y = y + 50
	DrawFireText( 0.5, "INFERNO TEXT", font, x, y, Color( 255, 0, 0 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, true, true )
	y = y + 50
	DrawElecticText( 1, "ELECTRIC TEXT", font, x, y, Color( 255, 0, 0 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	y = y + 50
	DrawBouncingText( 3, 3, "BOUNCING AND WAVING TEXT", font, x, y, Color( 255, 0, 0 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	y = y + 50
	DrawSnowingText( 10, "SPARKLING/SNOWING TEXT", font, x, y, Color( 255, 0, 0 ), Color( 255, 255, 255 ) )
end
hook.Add( "HUDPaint", "moat_TextEffectsExample", moat_DrawEffectExamples )
concommand.Add( "moat_TextExamples", function() MOAT_SHOW_EFFECT_EXAMPLES = not MOAT_SHOW_EFFECT_EXAMPLES end )

-- ZDEV_UID: ZDEV_FUNC_A1B2C3D4 | Path: ZDEV.DRAW.Anim_TargetLock
function ZDEV.DRAW.Anim_TargetLock(x, y, size, entity, progress, color)
    if not IsValid(entity) then
        entity = nil
    end
    
    -- Convert entity position to screen position if entity is provided
    if entity then
        local screenPos = entity:GetPos():ToScreen()
        x = screenPos.x
        y = screenPos.y
    end

    -- Defult values if not provided

end 

-- ZDEV_UID: ZDEV_FUNC_E5F6A7B8 | Path: ZDEV.TWEEN.Tween
function ZDEV.TWEEN.Tween(startValue, endValue, duration, easeFunc)
    local tween = {
        start = startValue,
        End = endValue,
        duration = duration,
        startTime = CurTime(),
        ease = easeFunc or function(t) return t end, -- linear by default
        isActive = true
    }
    
    function tween:Update()
        if not self.isActive then return self.End end
        
        local elapsed = CurTime() - self.startTime
        local progress = math.min(elapsed / self.duration, 1)
        
        if progress >= 1 then
            self.isActive = false
            return self.End
        end
        
        local easedProgress = self.ease(progress)
        return Lerp(easedProgress, self.start, self.End)
    end
    
    function tween:IsActive()
        return self.isActive
    end
    
    function tween:Reset()
        self.startTime = CurTime()
        self.isActive = true
    end
	local tween_kv = util.TableToKeyValues( tween )
    zdev.log( "D", "TWEEN: " .. tween_kv )
    return tween
end

-- Easing functions
-- Linear interpolation
function ZDEV.TWEEN.EaseLinear(t)
    return t
end

-- Ease in quadratic
function ZDEV.TWEEN.EaseInQuad(t)
    return t * t
end

-- Ease out quadratic
function ZDEV.TWEEN.EaseOutQuad(t)
    return t * (2 - t)
end

-- Ease in-out quadratic
function ZDEV.TWEEN.EaseInOutQuad(t)
    if t < 0.5 then
        return 2 * t * t
    else
        return -1 + (4 - 2 * t) * t
    end
end

-- Ease in cubic
function ZDEV.TWEEN.EaseInCubic(t)
    return t * t * t
end

-- Ease out cubic
function ZDEV.TWEEN.EaseOutCubic(t)
    local t1 = t - 1
    return t1 * t1 * t1 + 1
end

-- Ease in-out cubic
function ZDEV.TWEEN.EaseInOutCubic(t)
    if t < 0.5 then
        return 4 * t * t * t
    else
        local t1 = 2 * t - 2
        return 0.5 * t1 * t1 * t1 + 1
    end
end

-- Ease out elastic
function ZDEV.TWEEN.EaseOutElastic(t)
    local c4 = (2 * math.pi) / 3
    if t == 0 then return 0 end
    if t == 1 then return 1 end
    return math.pow(2, -10 * t) * math.sin((t * 10 - 0.75) * c4) + 1
end

-- Ease out bounce
function ZDEV.TWEEN.EaseOutBounce(t)
    local n1 = 7.5625
    local d1 = 2.75
    
    if t < 1/d1 then
        return n1 * t * t
    elseif t < 2/d1 then
        t = t - 1.5/d1
        return n1 * t * t + 0.75
    elseif t < 2.5/d1 then
        t = t - 2.25/d1
        return n1 * t * t + 0.9375
    else
        t = t - 2.625/d1
        return n1 * t * t + 0.984375
    end
end

-- ZDEV_UID: ZDEV_FUNC_C9D8E7F6 | Path: ZDEV.TWEEN.UpdateAll
function ZDEV.TWEEN.UpdateAll()
    if not ZDEV.TWEEN._activeTweens then
        ZDEV.TWEEN._activeTweens = {}
        return
    end
    
    local i = 1
    while i <= #ZDEV.TWEEN._activeTweens do
        local tween = ZDEV.TWEEN._activeTweens[i]
        if tween:IsActive() then
            tween:Update()
            i = i + 1
        else
            table.remove(ZDEV.TWEEN._activeTweens, i)
        end
    end
end

-- ZDEV_UID: ZDEV_FUNC_B4A5C6D7 | Path: ZDEV.TWEEN.Add
function ZDEV.TWEEN.Add(tween)
    if not ZDEV.TWEEN._activeTweens then
        ZDEV.TWEEN._activeTweens = {}
    end
    
    table.insert(ZDEV.TWEEN._activeTweens, tween)
end

-- ZDEV_UID: ZDEV_FUNC_F3E2D1C0 | Path: ZDEV.TWEEN.ClearAll
function ZDEV.TWEEN.ClearAll()
    if ZDEV.TWEEN._activeTweens then
        ZDEV.TWEEN._activeTweens = {}
    end
end

-- Example usage in a DrawHUD hook:
-- local myTween = ZDEV.TWEEN.Tween(0, 100, 2, ZDEV.TWEEN.EaseOutElastic)
-- ZDEV.TWEEN.Add(myTween)
-- 
-- hook.Add("HUDPaint", "MyTweenExample", function()
--     local currentValue = myTween:Update()
--     -- Use currentValue in your drawing code
--     draw.SimpleText("Value: " .. tostring(currentValue), "Default", 100, 100, color_white)
-- end)


ZDEV.FILE.SetLoaded( _f )
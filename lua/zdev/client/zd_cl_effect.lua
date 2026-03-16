local _f = 'zdev/client/zd_cl_effect.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end

ZDEV.FILE.SetLoaded( _f )

if ZDEV.SEFX then zdev.log( "S", "Located 'ZDEV.SEFX' master-table." ) else return end

ZDEV.SEFX._INDEX = ZDEV.SEFX._INDEX or {}

local meta = FindMetaTable( type( EffectData() ) )
if !meta then return end

function meta:SetRenderColor( tbl_clr )

	local r, g, b, a
	if type( tbl_clr ) == "table" then
		r = tbl_clr.r
		g = tbl_clr.g
		b = tbl_clr.b
		a = tbl_clr.a
	end

	local color = Color( r, g, b, a )

	return color

end


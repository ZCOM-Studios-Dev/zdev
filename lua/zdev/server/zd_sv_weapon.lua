local _f = 'zdev/server/zd_sv_weapon.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end

ZDEV.WEAP = ZDEV.WEAP or {}

ZDEV.FILE.SetLoaded( _f )
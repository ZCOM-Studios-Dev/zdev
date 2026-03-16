local _f = 'zdev/shared/meta/zd_sh_meta_wep.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end
ZDEV.FILE.SetLoaded( _f )

local meta = FindMetaTable( "Weapon" )
if not meta then return end
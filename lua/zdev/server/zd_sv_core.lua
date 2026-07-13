--[[
	zd_sv_core.lua
	Server core logic for zdev addon.
	Author: zcomstudios
	Description: Contains core server-side logic for the zdev core.
]]
local _f = 'zdev/server/zd_sv_core.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

if ZDEV.CONV then
	--zdev.log( )
	MsgC( Color(0,255,0,255), "▶\t", Color(100,255,100,255), " ZDEV.CONV table found.\n" )
end


-- Sprint-stamina drain lived here. Stamina is a game mechanic, not a Core
-- platform concern — child addons (ZDEV Weapons / NPCs) implement their own
-- stamina/vitals systems. Removed the per-tick Think hook accordingly.

ZDEV.FILE.SetLoaded( _f )
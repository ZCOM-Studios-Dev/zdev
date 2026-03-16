--[[
	zd_sv_meta_wep.lua
	Server weapon meta extensions for zdev addon.
	Author: zcomstudios
	Description: Extends weapon metatables with server-side logic for zdev.
]]
local _f = 'zdev/server/meta/zd_sv_meta_wep.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

ZDEV.FILE.SetLoaded( _f )

local meta = FindMetaTable( "Weapon" )
if not meta then return end
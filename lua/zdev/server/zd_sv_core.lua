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


-- ZDEV_UID: ZDEV_FUNC_3400F54D | Path: ZDEV.GAME.Think
function ZDEV.GAME.Think()

	local plys = player.GetAll()

	for k, ply in pairs( plys ) do
		
		if IsValid(ply) and ply:Alive() then
			
			local f_stamina = ply:GetNWFloat( "ZDEV_STAT_Stamina" )
			
			--print( k, ply, f_stamina )

			if ply:KeyDown( IN_SPEED ) and f_stamina > 0 then

				ply:SetNWFloat( "ZDEV_STAT_Stamina", f_stamina - 0.0015 )
			
			else
			
				if f_stamina < 1 then
					ply:SetNWFloat( "ZDEV_STAT_Stamina", f_stamina + 0.00125 )
				end
			
			end
		end

	end

end
hook.Add( "Think", "ZDEV.GAME.Think", ZDEV.GAME.Think )


ZDEV.FILE.SetLoaded( _f )
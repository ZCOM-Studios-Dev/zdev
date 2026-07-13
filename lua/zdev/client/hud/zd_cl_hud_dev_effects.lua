local _f = 'zdev/client/hud/zd_cl_hud_dev_effects.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
--
if ZDEV.FILE.Loaded( _f ) then return end

EFFECTS = {}
EFFECTS._INDEX = {}

local LP = LocalPlayer()
local lp_pos, lp_ang
local SW, SH = ScrW(), ScrH()
local SS = ScreenScale

-- ZDEV_UID: ZDEV_FUNC_4E9ADCF4 | Path: ZDEV.CHUD.DrawEffects
function ZDEV.CHUD.DrawEffects()

end

ZDEV.FILE.SetLoaded( _f )
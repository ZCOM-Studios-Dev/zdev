local _f = 'zdev/shared/zd_sh_core.lua'
Msg("■")
MsgC(Color(200,50,255), 'ZDEV File:', color_white, _f .. '\n')
if ZDEV.FILE.Loaded(_f) then return end

if ZDEV.CONV then
	MsgC(Color(0,255,0,255), "▶\t", Color(100,255,100,255), " ZDEV.CONV table found.\n")
end

-- ZDEV_UID: ZDEV_FUNC_55E4476C | Path: ZDEV.CONV.GetAll
function ZDEV.CONV.GetAll()
	local t_conv = ZDEV.CONV
	return t_conv
end

-- ZDEV_UID: ZDEV_FUNC_412EEADC | Path: ZDEV.GAME.Init
function ZDEV.GAME.Init()
	--if CLIENT then
	--	LocalPlayer().ZData = {}
	--	LocalPlayer():InitZData()
	--end

	zdev.log("D", " Hook Called: Initialize ")

	--ZDEV.WEAP.LoadIndex()
end
hook.Add("Initialize", "ZDEV.GAME.Init", ZDEV.GAME.Init)

-- ZDEV_UID: ZDEV_FUNC_B61E1297 | Path: ZDEV.GAME.InitPostEntity
function ZDEV.GAME.InitPostEntity()
	zdev.log("D", " Hook Called: InitPostEntity ")

	--ZDEV.WEAP.RegisterWeapons()
	--if SERVER then
	--	ZDEV.WEAP.SaveIndex()
	--end
end
hook.Add("InitPostEntity", "ZDEV.GAME.InitPostEntity", ZDEV.GAME.InitPostEntity)

-- ZDEV_UID: ZDEV_FUNC_3400F54D | Path: ZDEV.GAME.Think
function ZDEV.GAME.Think()
end
hook.Add("Think", "ZDEV.GAME.Think", ZDEV.GAME.Think)

-- ZDEV_UID: ZDEV_FUNC_816A6132 | Path: ZDEV.GAME.PostGamemodeLoaded
function ZDEV.GAME.PostGamemodeLoaded()
	zdev.log("D", " Hook Called: PostGamemodeLoaded ")
end
hook.Add("PostGamemodeLoaded", "ZDEV.GAME.PostGamemodeLoaded", ZDEV.GAME.PostGamemodeLoaded)

ZDEV.FILE.SetLoaded(_f)

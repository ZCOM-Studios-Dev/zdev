local _f = 'zdev/client/zd_cl_util.lua'
Msg("■")
MsgC(Color(200,50,255), 'ZDEV File:', color_white, _f .. '\n')
--
if ZDEV.FILE.Loaded(_f) then return end

ZDEV.UTIL = ZDEV.UTIL or {}

--[[〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓
-- Content Management Functions
〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓〓]]


-- ZDEV_UID: ZDEV_FUNC_70977092 | Path: ZDEV.UTIL.GetTextSize
function ZDEV.UTIL.GetTextSize(txt, font)
	if font == nil then
		ErrorNoHalt("ZDEV.UTIL.GetTextSize Argument Error: arg1 [type:string] (name:font) is NIL\n")
	elseif txt == nil then
		ErrorNoHalt("ZDEV.UTIL.GetTextSize Argument Error: arg2 [type:string] (name:txt) is NIL\n")
	end

	surface.SetFont(font)
	local w, h = surface.GetTextSize(txt)
	return w, h
end

-- ZDEV_UID: ZDEV_FUNC_575F8B7A | Path: ZDEV.UTIL.PosToScreen
function ZDEV.UTIL.PosToScreen(pos)
	if not pos then return end
	local x, y = pos:ToScreen().x, pos:ToScreen().y
	return x, y
end

-- ZDEV_UID: ZDEV_FUNC_16B79C1B | Path: ZDEV.UTIL.EntPosToScreen
function ZDEV.UTIL.EntPosToScreen(ent)
	if ent and IsValid(ent) then
		local pos = ent:GetPos()
		local x, y = pos:ToScreen().x, pos:ToScreen().y
		return x, y
	end
end

-- ZDEV_UID: ZDEV_FUNC_D32A9CF3 | Path: ZDEV.UTIL.TraceHitPosScreen
function ZDEV.UTIL.TraceHitPosScreen(ply)
	if not (IsValid(ply) and ply:Alive()) then return end
	local tr = ply:GetEyeTrace()
	local x, y = tr.HitPos:ToScreen().x, tr.HitPos:ToScreen().y
	return x, y
end


local v_ViewMdl, v_ScreenPos, t_Att, e_Weap, e_ViewMdl
local v_Att, a_Att
-- ZDEV_UID: ZDEV_FUNC_A9C10807 | Path: ZDEV.UTIL.GetVMAttPos
function ZDEV.UTIL.GetVMAttPos(e_Ply, i_Att)
	e_Weap = e_Ply:GetActiveWeapon()
	e_ViewMdl = e_Ply:GetViewModel()

	t_Att = e_ViewMdl:GetAttachment(i_Att)
	if not t_Att then return end

	v_Att, a_Att = t_Att.Pos, t_Att.Ang

	return v_Att, a_Att

end

--[[ =============================================
	CORE CLIENT
==================================================]]--
-- ZDEV_UID: ZDEV_FUNC_35B176D0 | Path: ZDEV.UTIL.GetBonePos
function ZDEV.UTIL.GetBonePos(bone)
	local boneid

	if string.lower(bone) == "rhand" then
		boneid = "ValveBiped.Bip01_R_Hand"
	end
	if not IsValid(LocalPlayer()) then return end

	local bone = LocalPlayer():LookupBone("ValveBiped.Bip01_R_Hand")
	local bonePos, boneAng = LocalPlayer():GetBonePosition(bone)

	return bonePos

end

-- ZDEV_UID: ZDEV_FUNC_349E70C3 | Path: ZDEV.UTIL.ParticleEmitter
function ZDEV.UTIL.ParticleEmitter(data)
	local ent, pos = data.Entity or nil, data.StartPos or Vector(0, 0, 0)
	local b_3D, i_NumParticles = data.Use3D, data.NumParticles

	local emitter = ParticleEmitter(pos, b_3D) -- Particle emitter in this position
	if emt and IsValid(ent) then
		emitter:SetParent(ent)
	end

	return emitter

end

-- ZDEV_UID: ZDEV_FUNC_330C1771 | Path: ZDEV.UTIL.Particle
function ZDEV.UTIL.Particle(data)
	local c_Emitter = data.Emitter
	local m_Mat = data.Material
	local v_Pos = data.StartPos

	local c_Part = c_Emitter:Add(m_Mat, v_Pos)

	return c_Part

end

-- ZDEV_UID: ZDEV_FUNC_9B65F091 | Path: ZDEV.UTIL.TimedCos
function ZDEV.UTIL.TimedCos(freq, rate)
	return math.cos(CurTime() * freq) / rate
end

TCOS = ZDEV.UTIL.TimedCos

-- ZDEV_UID: ZDEV_FUNC_9A92A4AC | Path: ZDEV.UTIL.TimedSin
function ZDEV.UTIL.TimedSin(freq, rate)
	return math.sin(CurTime() * freq) / rate
end

TSIN = ZDEV.UTIL.TimedSin

concommand.Add("derma_setskin", function(_, _, args)
	if GetConVar("sv_allowcslua"):GetInt() == 0 then return end
	for k, v in pairs(vgui.GetWorldPanel():GetChildren()) do
		v:SetSkin(args[1])
	end
end, nil, "Sets skin for all Derma objects.")

local function deepskin(children, skin)
	for k, v in pairs(children) do
		v:SetSkin(skin)
		if #v:GetChildren() ~= 0 then deepskin(v:GetChildren(), skin) end
	end
end

concommand.Add("derma_deepsetskin", function(_, _, args)
	if GetConVar("sv_allowcslua"):GetInt() == 0 then return end
	deepskin(vgui.GetWorldPanel():GetChildren(), args[1])
end, nil, "Forces skin set for all Derma objects and their children.")

concommand.Add("derma_updateskin", function()
	if GetConVar("sv_allowcslua"):GetInt() == 0 then return end
	for k, v in pairs(derma.GetSkinTable()) do
		if v.GwenTexture then
			local tex = v.GwenTexture:GetTexture("$basetexture")
			if tex then tex:Download() end
		end
	end
	derma.RefreshSkins()
end, nil, "Updates skins for all Derma objects.")

hook.Add("ForceDermaSkin", "Windows10SkinForce", function()
	return "ZDEV" -- This will paint all Derma objects to new skin
end)


concommand.Add("zdev_targetlock", function(ply, cmd, arg)
	local ent = ply:GetEyeTrace().Entity
	if IsValid(ent) then
		debugoverlay.Sphere(ent:GetPos(), 10, 5, Color(255, 0, 0), true)
	end
	local locktime = arg[1] or 3

	if ZDEV.CHUD.Targets then
		table.insert(ZDEV.CHUD.Targets, { LockTime = CurTime() + locktime, Ent = ent, Time = CurTime(), Pos = ent:GetPos(), Status = "Locking" })
		ZDEV.CHUD.TargetEnt = ent -- This is the primary target, the one that gets the big lock-on
		zdev.log("D", "Added target " .. tostring(ent) .. " to CHUD.Targets. Total targets: " .. #ZDEV.CHUD.Targets)
	end

end)

ZDEV.FILE.SetLoaded(_f)

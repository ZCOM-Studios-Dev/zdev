-- Send client file to clients
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_hud_targeting.lua")

-- Send shared file to clients
AddCSLuaFile("shared.lua")

-- Include shared file on server
include("shared.lua")

SWEP.Weight			= 5		-- Decides whether we should switch from/to this
SWEP.AutoSwitchTo	= true	-- Auto switch to if we pick it up
SWEP.AutoSwitchFrom	= true	-- Auto switch from if you pick up a better weapon

-- ============================================================================
-- NETWORKING SETUP
-- ============================================================================
util.AddNetworkString("ZDEVHacker_ConvertTarget")
util.AddNetworkString("ZDEVHacker_CoreOverload")
util.AddNetworkString("ZDEVHacker_TargetEffect")

-- ============================================================================
-- CONVERT TARGET - Change entity disposition to friendly
-- ============================================================================
net.Receive("ZDEVHacker_ConvertTarget", function(len, ply)
    if not IsValid(ply) then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or wep:GetClass() ~= "zdev_weapon_hacker" then return end

    local targetEnt = net.ReadEntity()
    if not IsValid(targetEnt) then return end

    -- Verify target is in range
    local dist = ply:GetPos():Distance(targetEnt:GetPos())
    if dist > 2500 then return end

    -- Convert NPC to friendly
    if targetEnt:IsNPC() then
        -- Set disposition to like the player
        targetEnt:AddEntityRelationship(ply, D_LI, 99)

        -- Make it attack enemies of the player
        for _, ent in ipairs(ents.FindByClass("npc_*")) do
            if IsValid(ent) and ent ~= targetEnt then
                local disposition = ent:Disposition(ply)
                if disposition == D_HT or disposition == D_FR then
                    -- This NPC is hostile to player, make converted target attack it
                    targetEnt:AddEntityRelationship(ent, D_HT, 99)
                end
            end
        end

        -- Visual feedback
        local effectData = EffectData()
        effectData:SetOrigin(targetEnt:GetPos())
        effectData:SetEntity(targetEnt)
        util.Effect("propspawn", effectData)

        -- Notify all clients of conversion
        net.Start("ZDEVHacker_TargetEffect")
            net.WriteEntity(targetEnt)
            net.WriteString("converted")
        net.Broadcast()
    end
end)

-- ============================================================================
-- CORE OVERLOAD - Damage and explode target
-- ============================================================================
net.Receive("ZDEVHacker_CoreOverload", function(len, ply)
    if not IsValid(ply) then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or wep:GetClass() ~= "zdev_weapon_hacker" then return end

    local targetEnt = net.ReadEntity()
    if not IsValid(targetEnt) then return end

    -- Verify target is in range
    local dist = ply:GetPos():Distance(targetEnt:GetPos())
    if dist > 2500 then return end

    -- Store reference for timer
    local targetIndex = targetEnt:EntIndex()

    -- Notify clients of overload start
    net.Start("ZDEVHacker_TargetEffect")
        net.WriteEntity(targetEnt)
        net.WriteString("overload_start")
    net.Broadcast()

    -- Create damage timer (5 seconds of damage)
    local tickCount = 0
    local maxTicks = 10  -- 10 ticks over 5 seconds
    local timerName = "ZDEVHacker_Overload_" .. targetIndex

    timer.Create(timerName, 0.5, maxTicks, function()
        if not IsValid(targetEnt) then
            timer.Remove(timerName)
            return
        end

        tickCount = tickCount + 1

        -- Deal damage
        local dmg = DamageInfo()
        dmg:SetDamage(15)
        dmg:SetAttacker(ply)
        dmg:SetInflictor(wep)
        dmg:SetDamageType(DMG_SHOCK)
        targetEnt:TakeDamageInfo(dmg)

        -- Tesla zap effect
        local effectData = EffectData()
        effectData:SetOrigin(targetEnt:WorldSpaceCenter() or targetEnt:GetPos())
        effectData:SetMagnitude(1)
        effectData:SetScale(1)
        effectData:SetRadius(50)
        util.Effect("TeslaZap", effectData)

        -- Sparks
        local sparkData = EffectData()
        sparkData:SetOrigin(targetEnt:WorldSpaceCenter() or targetEnt:GetPos())
        sparkData:SetNormal(VectorRand())
        sparkData:SetMagnitude(2)
        sparkData:SetScale(1)
        util.Effect("Sparks", sparkData)

        -- Final explosion
        if tickCount >= maxTicks and IsValid(targetEnt) then
            -- Big explosion
            local explodePos = targetEnt:WorldSpaceCenter() or targetEnt:GetPos()

            local explosion = ents.Create("env_explosion")
            explosion:SetPos(explodePos)
            explosion:SetKeyValue("iMagnitude", "100")
            explosion:Spawn()
            explosion:Fire("Explode", "", 0)

            -- Kill the target
            targetEnt:TakeDamage(1000, ply, wep)

            -- Notify clients
            net.Start("ZDEVHacker_TargetEffect")
                net.WriteEntity(targetEnt)
                net.WriteString("overload_explode")
            net.Broadcast()
        end
    end)
end)

net.Receive("ZDEVHacker_TargetAction", function(len, ply)
    if not IsValid(ply) then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or wep:GetClass() ~= "zdev_weapon_hacker" then return end

    local targetEnt = net.ReadEntity()
    if not IsValid(targetEnt) then return end

    -- Verify target is in range
    local dist = ply:GetPos():Distance(targetEnt:GetPos())
    if dist > 2500 then return end

    -- Store reference for timer
    local targetIndex = targetEnt:EntIndex()

    -- Depending on the action type, (and entity classname) perform different actions
    -- For example: the 'unlock' or 'open' actions are only for doors or containers
    -- The 'switch' action is only for electrical devices like lights or turrets/buttons/cameras,etc.
    -- The 'disable' action is for turrets, tripmines, etc.
    local actionType = net.ReadString()
    local entClass = targetEnt:GetClass()

    if actionType == "unlock" then
        if entClass == "func_door" or entClass == "func_door_rotating" then
            targetEnt:Fire("Unlock", "", 0)
        elseif entClass == "prop_physics" then
            targetEnt:Fire("Unlock", "", 0)
        end
    elseif actionType == "attack" then
        if targetEnt:IsNPC() then
            targetEnt:AddEntityRelationship(ply, D_HT, 99)
        end
    elseif actionType == "switch" then
        if entClass == "light" or entClass == "gmod_turret" or entClass == "prop_dynamic" then
            targetEnt:Fire("Toggle", "", 0)
        end
    elseif actionType == "disable" then
        if entClass == "npc_turret_floor" or entClass == "npc_turret_ceiling" then
            targetEnt:Fire("Disable", "", 0)
        end
    elseif actionType == "open" then
        if entClass == "prop_physics" then
            targetEnt:Fire("Open", "", 0)
        end
    elseif actionType == "close" then
        if entClass == "prop_physics" then
            targetEnt:Fire("Close", "", 0)
        end
    elseif actionType == "destroy" then
        targetEnt:Remove()
    end
end)
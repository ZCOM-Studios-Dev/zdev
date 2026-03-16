--[[
    MetaHUD Realistic Pistol Base - Server
    
    Handles:
    - Damage calculation with falloff
    - Bullet penetration
    - Hit registration and validation
    - Networked state management
]]

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

--------------------------------------------------------------------------------
-- DAMAGE SYSTEM
--------------------------------------------------------------------------------

--[[
    Bullet callback for damage calculation
    @param attacker - Player who fired
    @param tr - Trace result
    @param dmginfo - Damage info object
]]
function SWEP:BulletCallback(attacker, tr, dmginfo)
    if not IsValid(tr.Entity) then return end
    
    local distance = tr.StartPos:Distance(tr.HitPos)
    local damage = self:GetDamageAtDistance(distance)
    
    -- Apply hitgroup multipliers
    local hitgroup = tr.HitGroup
    local multiplier = 1.0
    
    if hitgroup == HITGROUP_HEAD then
        multiplier = 2.5
    elseif hitgroup == HITGROUP_CHEST then
        multiplier = 1.0
    elseif hitgroup == HITGROUP_STOMACH then
        multiplier = 0.95
    elseif hitgroup == HITGROUP_LEFTARM or hitgroup == HITGROUP_RIGHTARM then
        multiplier = 0.75
    elseif hitgroup == HITGROUP_LEFTLEG or hitgroup == HITGROUP_RIGHTLEG then
        multiplier = 0.7
    end
    
    damage = math.floor(damage * multiplier)
    dmginfo:SetDamage(damage)
    
    -- Penetration logic
    if self.Ballistics.PenetrationPower > 0 then
        self:HandlePenetration(attacker, tr, dmginfo)
    end
end

--[[
    Handle bullet penetration through surfaces
    @param attacker - Player who fired
    @param tr - Trace result  
    @param dmginfo - Damage info object
]]
function SWEP:HandlePenetration(attacker, tr, dmginfo)
    if not tr.Hit then return end
    if tr.HitSky then return end
    
    local mat = tr.MatType
    local penPower = self.Ballistics.PenetrationPower
    
    -- Material penetration modifiers
    local matMods = {
        [MAT_WOOD]      = 0.8,
        [MAT_METAL]     = 0.3,
        [MAT_CONCRETE]  = 0.4,
        [MAT_FLESH]     = 1.0,
        [MAT_GLASS]     = 1.2,
        [MAT_PLASTIC]   = 0.9,
        [MAT_TILE]      = 0.5,
        [MAT_GRATE]     = 0.7,
    }
    
    local matMod = matMods[mat] or 0.5
    local effectivePen = penPower * matMod
    
    if effectivePen < 0.3 then return end -- Not enough power to penetrate
    
    -- Trace through surface to find exit point
    local exitTrace = util.TraceLine({
        start = tr.HitPos + tr.HitNormal * -1,
        endpos = tr.HitPos + tr.Normal * 32,
        filter = attacker,
        mask = MASK_SHOT,
    })
    
    if exitTrace.StartSolid then return end
    
    -- Fire penetrating bullet
    local remainingDamage = dmginfo:GetDamage() * effectivePen * 0.6
    if remainingDamage < 5 then return end
    
    local bullet = {
        Num     = 1,
        Src     = exitTrace.HitPos + tr.Normal * 2,
        Dir     = tr.Normal,
        Spread  = Vector(0.01, 0.01, 0),
        Tracer  = 0,
        Force   = self.Ballistics.Force * 0.5,
        Damage  = remainingDamage,
    }
    
    attacker:FireBullets(bullet)
end

--------------------------------------------------------------------------------
-- NETWORKED STATE
--------------------------------------------------------------------------------

--[[
    Set up networked variables
]]
function SWEP:SetupDataTables()
    self:NetworkVar("Bool", 0, "Reloading")
    self:NetworkVar("Bool", 1, "Ironsights")
    self:NetworkVar("Float", 0, "ReloadFinishTime")
end

--------------------------------------------------------------------------------
-- PICKUP & DROP
--------------------------------------------------------------------------------

--[[
    Called when weapon is picked up
    @param ply - Player picking up
]]
function SWEP:Equip(ply)
    -- Reset state on pickup
    self.ChamberedRound = true
    self.RecoilAccumulator = 0
    self.SpreadBloom = 0
end

--[[
    Called when weapon is dropped
]]
function SWEP:OnDrop()
    -- Preserve chamber state
end

--[[
    Validate ownership for anti-cheat
]]
function SWEP:ValidateOwnership()
    local owner = self:GetOwner()
    return IsValid(owner) and owner:IsPlayer() and owner:Alive()
end


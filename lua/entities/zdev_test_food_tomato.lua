
AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Tomato"
ENT.Author = "ZCOM Studios"
ENT.Category = "ZDEV"
ENT.Information = "A delicious tomato."
ENT.Purpose = "Players can eat this tomato to restore health."
ENT.Contact = "STEAM_0:0:0"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/tomato.mdl"

ENT.LastState = nil
ENT.State = VEGETABLE_STATE_GROWING 
ENT.IsAttachedToTree = false
ENT.AttachedTree = nil 
ENT.TimeRipe = 10
ENT.TimeSpoil = 360
ENT.SpawnTime = 0
ENT.LifeTime = 0
ENT.DieTime = ENT.TimeRipe + ENT.TimeSpoil
VEGETABLE_STATE_GROWING = 0
VEGETABLE_STATE_RIPE = 1
VEGETABLE_STATE_SPOILED = 2

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "VegetableState")
    self:NetworkVar("Entity", 0, "AttachedTree")
    self:NetworkVar("Bool",0, "IsAttachedToTree")
    self:NetworkVar("Float", 0, "LifeTime")
end

function ENT:SetVegetableState(state)
    self:SetNWInt("VegetableState", state)
    self.VegetableState = state
    zdev.log("D", "Tomato state changed from " .. tostring(self.LastState) .. " to: " .. tostring(state) )
    self.LastState = state
end

function ENT:SetLifeTime(time)
    self:SetNWFloat("LifeTime", time)
    self.LifeTime = time
end

function ENT:GetLifeTime()
    return self.LifeTime or self:GetNWFloat("LifeTime")
end

function ENT:OnSpawn()
    if self:GetIsAttachedToTree() then
        -- If attached to a tree, it's growing
        self:SetVegetableState(VEGETABLE_STATE_GROWING) -- This line was moved here
        self.SpawnTime = CurTime()
        self:SetModelScale( 0.1, 1)
        --[[timer.Simple( self.TimeRipe, function() 
            if IsValid(self) and self:GetIsAttachedToTree() then
                self:SetVegetableState(VEGETABLE_STATE_RIPE)
                zdev.log("D", "Tomato has ripened after " .. self.TimeRipe .. " seconds.")
                self:SetModelScale( 1, 1 )
                if SERVER then
                    local phys = self:GetPhysicsObject()
                    if IsValid(phys) then
                        phys:Wake()
                    end
                end
            end
        end)]]
        
    else
        -- If not attached, it's already ripe
        self:SetVegetableState(VEGETABLE_STATE_RIPE)
        self.SpawnTime = CurTime() - self.TimeRipe
        self:SetModelScale( 2, 10 )
    end

end

function ENT:Initialize()
    self:SetModel(self.Model)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    
    if SERVER then
        self:SetUseType(SIMPLE_USE)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            --phys:Wake()
        end
    end
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    -- Heal the player by 25 health points
    local healAmount = 25
    local newHealth = math.min(activator:Health() + healAmount, activator:GetMaxHealth())
    activator:SetHealth(newHealth)

    ----TODO - Add logic to randomly add "Tomato Seed" item to player's inventory

    -- Play a sound effect
    self:EmitSound("items/procurement_pickup.wav")
    zdev.log( "W", "Player " .. activator:Nick() .. " ate an tomato and healed for " .. healAmount .. " health." )
    -- Remove the tomato after use
    SafeRemoveEntity(self)
end

function ENT:Think()


end

if CLIENT then
    function ENT:Draw()

        self:DrawModel()
        render.DrawSphere(self:GetPos(), 5, 16, 16, Color(255, 0, 0, 100))
    end

end
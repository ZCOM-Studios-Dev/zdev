
AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Granite Rock"
ENT.Author = "ZCOM Studios"
ENT.Category = "ZDEV"
ENT.Information = "A mineable granite rock."
ENT.Purpose = "Strike this with a pickaxe to recover Granite."
ENT.Contact = "STEAM_0:0:0"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/props_wasteland/rockgranite04a.mdl"

ENT.ResourceModels = {"models/props_mining/rock_caves01b.mdl", "models/props_mining/rock_caves01c.mdl", "models/props_mining/rock_caves01a.mdl"}
ENT.MaxResources = 15
ENT.GatherCooldown = 30 -- Seconds between Gathers
ENT.NextGatherTime = 0
ENT.ActiveResources = {}
ENT.ActiveResourceCount = 0


function ENT:Initialize()
    self:SetModel(self.Model)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetRenderMode(RENDERMODE_TRANSALPHA)
    --self:SpawnResource(self.MaxResources)  
    if SERVER then
        self:SetUseType(SIMPLE_USE)
    end
end

function ENT:OnSpawn(pos)
    self:SetModelScale(0.1, 5)
end

function ENT:SpawnResource(count)
    if #self.ResourceModels == 0 then return end

    for i=1, count do

        local ResourceSpawnPos = self:GetPos() + Vector(math.random(-70, 70), math.random(-70, 70), math.random(120,200)) -- Randomize position around the tree   
        if CLIENT then
            debugoverlay.Axis( ResourceSpawnPos, Angle(0, 0, 0), 10, 5, Color(255, 0, 0) )
        else

            --local ResourceModel = table.Random(self.ResourceModels)
            local Resource = ents.Create( "zdev_test_food_apple" )
            if not IsValid(Resource) then return end
            Resource:SetPos(ResourceSpawnPos) -- Position above the tree
            Resource:SetParent(self)
            Resource:Spawn()
            Resource:SetAttachedTree(self)
            Resource:SetIsAttachedToTree(true)
            table.insert(self.ActiveResources, Resource)

        end

    end

    --[[
    self.ActiveResourceCount = self.ActiveResourceCount + 1
    if self.ActiveResourceCount >= self.MaxResources then
        self.NextGatherTime = CurTime() + self.GatherCooldown
    end
    ]]
end 

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
    end
end
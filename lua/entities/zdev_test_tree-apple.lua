
AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Apple Tree (Mature)"
ENT.Author = "ZCOM Studios"
ENT.Category = "ZDEV"
ENT.Information = "A mature apple tree that can be interacted with."
ENT.Purpose = "Players can harvest apples from this tree."
ENT.Contact = "STEAM_0:0:0"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/props_foliage/ac_appletree02.mdl"

ENT.FruitModels = {"models/apple01.mdl", "models/apple02.mdl"}
ENT.MaxFruits = 15
ENT.HarvestCooldown = 30 -- Seconds between harvests
ENT.NextHarvestTime = 0
ENT.ActiveFruit = {}
ENT.ActiveFruitCount = 0

function ENT:Initialize()
    self:SetModel(self.Model)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetRenderMode(RENDERMODE_TRANSALPHA)
    self:SpawnFruit(self.MaxFruits)
    if SERVER then
        self:SetUseType(SIMPLE_USE)
    end
end

function ENT:SpawnFruit(count)
    if #self.FruitModels == 0 then return end

    for i=1, count do

        local fruitSpawnPos = self:GetPos() + Vector(math.random(-70, 70), math.random(-70, 70), math.random(120,200)) -- Randomize position around the tree   
        if CLIENT then
            debugoverlay.Axis( fruitSpawnPos, Angle(0, 0, 0), 10, 5, Color(255, 0, 0) )
        else

            --local fruitModel = table.Random(self.FruitModels)
            local fruit = ents.Create( "zdev_test_food_apple" )
            if not IsValid(fruit) then return end
            fruit:SetPos(fruitSpawnPos) -- Position above the tree
            fruit:SetParent(self)
            fruit:Spawn()
            fruit:SetAttachedTree(self)
            fruit:SetIsAttachedToTree(true)
            table.insert(self.ActiveFruit, fruit)

        end

    end

    --[[
    self.ActiveFruitCount = self.ActiveFruitCount + 1
    if self.ActiveFruitCount >= self.MaxFruits then
        self.NextHarvestTime = CurTime() + self.HarvestCooldown
    end
    ]]
end 

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
    end
end
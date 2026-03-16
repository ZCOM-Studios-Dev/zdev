
AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Tomato Plant"
ENT.Author = "ZCOM Studios"
ENT.Category = "ZDEV"
ENT.Information = "A mature tomate tree that can be interacted with."
ENT.Purpose = "Players can harvest tomates from this tree."
ENT.Contact = "STEAM_0:0:0"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/crysis/fields/tomato_bush_small_a.mdl"

ENT.MaxVegetables = 5
ENT.HarvestCooldown = 30 -- Seconds between harvests
ENT.NextHarvestTime = 0
ENT.ActiveVegetable = {}
ENT.ActiveVegetableCount = 0

function ENT:Initialize()
    self:SetModel(self.Model)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetRenderMode(RENDERMODE_TRANSALPHA)
    self:SpawnVegetable(self.MaxVegetables)
    if SERVER then
        self:SetUseType(SIMPLE_USE)
    end
end

function ENT:SpawnVegetable(count)
    local mdlRenderMin, mdlRenderMax = self:GetModelRenderBounds()
    local mRMin_x, mRMin_y, mRMin_z = mdlRenderMin:Unpack();
    local mRMax_x, mRMax_y, mRMax_z = mdlRenderMax:Unpack();
    for i=1, count do

        local vegetableSpawnPos = self:GetPos() + Vector(math.random(mRMin_x, mRMax_x), math.random(mRMin_y, mRMax_y), math.random(mRMax_z*0.5,mRMax_z)) -- Randomize position around the tree   
        if CLIENT then
            debugoverlay.Axis( vegetableSpawnPos, Angle(0, 0, 0), 10, 5, Color(255, 255, 255) )
        else

            local vegetable = ents.Create( "zdev_test_food_tomato" )
            if not IsValid(vegetable) then return end
            vegetable:SetPos(vegetableSpawnPos) -- Position above the tree
            vegetable:SetParent(self)
            vegetable:Spawn()
            vegetable:SetAttachedTree(self)
            vegetable:SetIsAttachedToTree(true)
            table.insert(self.ActiveVegetable, vegetable)

        end

    end

    --[[
    self.ActiveVegetableCount = self.ActiveVegetableCount + 1
    if self.ActiveVegetableCount >= self.MaxVegetables then
        self.NextHarvestTime = CurTime() + self.HarvestCooldown
    end
    ]]
end 

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
    end
end
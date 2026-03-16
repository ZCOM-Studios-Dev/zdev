--[[
    ZDEV Crafting System - Base Workbench Entity
    Foundation workbench entity. All other workbench types derive from this.
    Players press E to open the crafting menu filtered for this workbench type.
]]

AddCSLuaFile()

ENT.Type      = "anim"
ENT.Base      = "base_gmodentity"

ENT.PrintName   = "Basic Workbench"
ENT.Author      = "ZCOM Studios"
ENT.Category    = "ZDEV Crafting"
ENT.Information = "A crafting workbench. Press E to open the crafting menu."
ENT.Spawnable   = true
ENT.AdminOnly   = false

ENT.Model            = "models/props_c17/FurnitureTable001a.mdl"
ENT.WorkbenchType    = ZDEV_WORKBENCH_BASIC or 1
ENT.InteractionRange = 200


function ENT:SetupDataTables()
    self:NetworkVar( "Bool",   0, "InUse" )
    self:NetworkVar( "Entity", 0, "ActiveUser" )

    if SERVER then
        self:SetInUse( false )
        self:SetActiveUser( NULL )
    end
end


if SERVER then

    function ENT:Initialize()
        self:SetModel( self.Model )
        self:PhysicsInit( SOLID_VPHYSICS )
        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:SetSolid( SOLID_VPHYSICS )
        self:SetUseType( SIMPLE_USE )

        local phys = self:GetPhysicsObject()
        if IsValid( phys ) then
            phys:EnableMotion( false )
            phys:Wake()
        end
    end

    function ENT:Use( activator, caller, useType, value )
        if not IsValid( caller ) or not caller:IsPlayer() then return end

        -- Send net message to open crafting menu on client
        net.Start( "ZDEV_Crafting_OpenMenu" )
            net.WriteUInt( self.WorkbenchType, 4 )
            net.WriteEntity( self )
        net.Send( caller )

        zdev.log( "I", "[Workbench] " .. caller:Nick() .. " opened " .. self.PrintName )
    end

    function ENT:SpawnFunction( ply, tr, ClassName )
        if not tr.Hit then return end

        local ent = ents.Create( ClassName )
        ent:SetPos( tr.HitPos + tr.HitNormal * 10 )
        ent:SetAngles( Angle( 0, ply:EyeAngles().y + 180, 0 ) )
        ent:Spawn()
        ent:Activate()

        return ent
    end

    function ENT:OnTakeDamage( dmg )
        return 0
    end

end


if CLIENT then

    function ENT:Draw()
        self:DrawModel()

        -- Draw 3D2D label when player is nearby
        local ply = LocalPlayer()
        if not IsValid( ply ) then return end

        local dist = self:GetPos():Distance( ply:GetPos() )
        if dist > self.InteractionRange then return end

        local pos = self:GetPos() + self:GetUp() * 40
        local ang = ( ply:EyePos() - pos ):Angle()
        ang:RotateAroundAxis( ang:Up(), -90 )
        ang:RotateAroundAxis( ang:Forward(), 90 )

        cam.Start3D2D( pos, ang, 0.08 )
            -- Background
            draw.RoundedBox( 6, -150, -20, 300, 55, Color( 0, 0, 0, 150 ) )

            -- Workbench name
            draw.SimpleText( self.PrintName, "DermaLarge", 0, 0,
                Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

            -- Use prompt
            draw.SimpleText( "[E] Use", "DermaDefault", 0, 24,
                Color( 200, 200, 200, 200 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
        cam.End3D2D()
    end

end

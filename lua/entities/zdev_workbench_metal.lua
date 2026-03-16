--[[
    ZDEV Crafting System - Metal Workbench
    Used for weapons, armor, and metalworking recipes.
]]

AddCSLuaFile()

ENT.Type      = "anim"
ENT.Base      = "zdev_workbench_base"

ENT.PrintName   = "Metal Workbench"
ENT.Author      = "ZCOM Studios"
ENT.Category    = "ZDEV Crafting"
ENT.Information = "A heavy-duty metal workbench for forging weapons and armor."
ENT.Spawnable   = true
ENT.AdminOnly   = false

ENT.Model         = "models/props_c17/FurnitureTable002a.mdl"
ENT.WorkbenchType = ZDEV_WORKBENCH_METAL or 2

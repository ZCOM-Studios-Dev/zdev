--[[
    ZDEV Crafting System - Engineering Workbench
    Specialized workbench for reverse-engineering items into blueprints.
    Players destroy items here to permanently learn their crafting recipe.
]]

AddCSLuaFile()

ENT.Type      = "anim"
ENT.Base      = "zdev_workbench_base"

ENT.PrintName   = "Engineering Workbench"
ENT.Author      = "ZCOM Studios"
ENT.Category    = "ZDEV Crafting"
ENT.Information = "Destroy items to reverse-engineer their blueprints."
ENT.Spawnable   = true
ENT.AdminOnly   = false

ENT.Model         = "models/props_combine/breenconsole.mdl"
ENT.WorkbenchType = ZDEV_WORKBENCH_ENGINEERING or 5

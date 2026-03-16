--[[
    ZDEV Crafting System - Chemistry Workbench
    Used for chemical processes, glassmaking, and compounds.
]]

AddCSLuaFile()

ENT.Type      = "anim"
ENT.Base      = "zdev_workbench_base"

ENT.PrintName   = "Chemistry Workbench"
ENT.Author      = "ZCOM Studios"
ENT.Category    = "ZDEV Crafting"
ENT.Information = "A chemistry workbench for glass, compounds, and chemical processes."
ENT.Spawnable   = true
ENT.AdminOnly   = false

ENT.Model         = "models/props_lab/crematorcase.mdl"
ENT.WorkbenchType = ZDEV_WORKBENCH_CHEMISTRY or 4

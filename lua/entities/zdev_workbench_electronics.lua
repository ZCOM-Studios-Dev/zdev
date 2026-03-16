--[[
    ZDEV Crafting System - Electronics Workbench
    Used for wiring, circuits, and electronic components.
]]

AddCSLuaFile()

ENT.Type      = "anim"
ENT.Base      = "zdev_workbench_base"

ENT.PrintName   = "Electronics Workbench"
ENT.Author      = "ZCOM Studios"
ENT.Category    = "ZDEV Crafting"
ENT.Information = "An electronics workbench for circuits and wiring."
ENT.Spawnable   = true
ENT.AdminOnly   = false

ENT.Model         = "models/props_lab/monitor01a.mdl"
ENT.WorkbenchType = ZDEV_WORKBENCH_ELECTRONICS or 3

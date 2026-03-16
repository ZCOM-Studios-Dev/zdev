--[[
╔══════════════════════════════════════╗
║	 						 	   	   ║
║	Base Resource Entity               ║
║									   ║
║ 									   ║
╚══════════════════════════════════════╝

This entity serves as a base for all resource-based entities in the ZDEV 
framework. It provides common functionality for handling resources, rendering, 
and interaction. Specific entities can derive from this base to implement their 
unique behavior while leveraging the shared resource management features.
]]

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Base Resource"
ENT.Author = "ZCOM Studios"
ENT.Category = "ZDEV Crafting"
ENT.Spawnable = false
ENT.AdminOnly = false

ENT.Models = {}

ENT.ResourceType = ZDEV_RESOURCE_NONE
ENT.ResourceAmount = 0
ENT.ResourceMax = 0
local _f = 'zdev/server/zd_sv_snpc_system.lua'
--[[■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
	ZDEV - SNPC System (Server)
----------------------------------------------------------
	Server-side SNPC management and networking
	By ZCOM Studios
	Copyright (c) 2020-2025 by ZCOM Studios, All rights reserved.
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■]]

if ZDEV.FILE.Loaded( _f ) then return end
ZDEV.FILE.SetLoaded( _f )

if not ZDEV.SNPC then ZDEV.SNPC = {} end

local SNPC = ZDEV.SNPC

-- SNPC Management
SNPC.ActiveNPCs = {}
SNPC.TestNPCs = {}
SNPC.NPCCounter = 0

-- Console variables
CreateConVar('zdev_snpc_debug', '0', FCVAR_ARCHIVE, 'Enable SNPC debug information')
CreateConVar('zdev_snpc_max_test', '10', FCVAR_ARCHIVE, 'Maximum test SNPCs per player')
CreateConVar('zdev_snpc_cleanup_time', '300', FCVAR_ARCHIVE, 'Time before test SNPCs are cleaned up (seconds)')

-- SNPC Templates Registry
SNPC.Templates = {
	['zdev_snpc_base'] = {
		class = 'zdev_snpc_base',
		name = 'Base SNPC',
		spawnable = false,
		adminOnly = false
	},
	['zdev_snpc_soldier'] = {
		class = 'zdev_snpc_soldier',
		name = 'Combat Soldier',
		spawnable = true,
		adminOnly = false
	},
	['zdev_snpc_civilian'] = {
		class = 'zdev_snpc_civilian',
		name = 'Civilian',
		spawnable = true,
		adminOnly = false
	}
}

-- Register an SNPC template
function SNPC.RegisterTemplate(class, data)
	SNPC.Templates[class] = data
	
	if ZDEV and ZDEV.LOG then
		zdev.log('N', 'Registered SNPC template: ' .. class)
	end
end

-- Get all available templates
function SNPC.GetTemplates()
	return SNPC.Templates
end

-- Spawn an SNPC
function SNPC.SpawnNPC(class, pos, ang, data)
	if not SNPC.Templates[class] then
		if ZDEV and ZDEV.LOG then
			zdev.log('E', 'Unknown SNPC class: ' .. class)
		end
		return nil
	end
	
	local template = SNPC.Templates[class]
	
	-- Check if spawnable
	if not template.spawnable then
		if ZDEV and ZDEV.LOG then
			zdev.log('E', 'SNPC class not spawnable: ' .. class)
		end
		return nil
	end
	
	-- Create the NPC
	local npc = ents.Create(class)
	if not IsValid(npc) then
		if ZDEV and ZDEV.LOG then
			zdev.log('E', 'Failed to create SNPC: ' .. class)
		end
		return nil
	end
	
	-- Set position and angle
	npc:SetPos(pos)
	npc:SetAngles(ang or Angle(0, 0, 0))
	
	-- Apply custom data if provided
	if data then
		SNPC.ApplyCustomData(npc, data)
	end
	
	-- Spawn the NPC
	npc:Spawn()
	npc:Activate()
	
	-- Track the NPC
	SNPC.NPCCounter = SNPC.NPCCounter + 1
	npc.ZDEVSnpcID = SNPC.NPCCounter
	SNPC.ActiveNPCs[SNPC.NPCCounter] = npc
	
	if ZDEV and ZDEV.LOG then
		zdev.log('S', 'Spawned SNPC: ' .. class .. ' (ID: ' .. SNPC.NPCCounter .. ')')
	end
	
	return npc
end

-- Apply custom configuration data to an NPC
function SNPC.ApplyCustomData(npc, data)
	-- Apply appearance settings
	if data.appearance then
		local app = data.appearance
		
		if app.model then npc:SetModel(app.model) end
		if app.skin then npc:SetSkin(app.skin) end
		if app.scale then npc:SetModelScale(app.scale) end
		if app.color then npc:SetColor(app.color) end
		if app.material then npc:SetMaterial(app.material) end
		
		if app.bodygroups then
			for group, value in pairs(app.bodygroups) do
				npc:SetBodygroup(group, value)
			end
		end
	end
	
	-- Apply AI settings
	if data.ai then
		local ai = data.ai
		
		if ai.health then 
			npc:SetHealth(ai.health)
			npc:SetMaxHealth(ai.health)
		end
		
		-- Override AI config if the NPC supports it
		if npc.AIConfig then
			for key, value in pairs(ai) do
				if npc.AIConfig[key] ~= nil then
					npc.AIConfig[key] = value
				end
			end
		end
	end
	
	-- Apply weapons
	if data.weapons then
		local weapons = data.weapons
		
		if weapons.primary and weapons.primary ~= '' then
			npc:Give(weapons.primary)
		end
		
		if weapons.secondary and weapons.secondary ~= '' then
			npc:Give(weapons.secondary)
		end
	end
	
	-- Apply relationships
	if data.relationships then
		for className, disposition in pairs(data.relationships) do
			npc:AddEntityRelationship(className, disposition, 99)
		end
	end
end

-- Remove an SNPC
function SNPC.RemoveNPC(npcID)
	local npc = SNPC.ActiveNPCs[npcID]
	if IsValid(npc) then
		npc:Remove()
		SNPC.ActiveNPCs[npcID] = nil
		
		if ZDEV and ZDEV.LOG then
			zdev.log('N', 'Removed SNPC ID: ' .. npcID)
		end
		
		return true
	end
	
	return false
end

-- Get SNPC by ID
function SNPC.GetNPC(npcID)
	return SNPC.ActiveNPCs[npcID]
end

-- Get all active SNPCs
function SNPC.GetAllNPCs()
	local npcs = {}
	for id, npc in pairs(SNPC.ActiveNPCs) do
		if IsValid(npc) then
			npcs[id] = npc
		else
			SNPC.ActiveNPCs[id] = nil
		end
	end
	return npcs
end

-- Clean up invalid NPCs
function SNPC.CleanupNPCs()
	local removed = 0
	for id, npc in pairs(SNPC.ActiveNPCs) do
		if not IsValid(npc) then
			SNPC.ActiveNPCs[id] = nil
			removed = removed + 1
		end
	end
	
	if removed > 0 and ZDEV and ZDEV.LOG then
		zdev.log('N', 'Cleaned up ' .. removed .. ' invalid SNPCs')
	end
end

-- Test NPC Management
function SNPC.SpawnTestNPC(player, class, pos)
	if not IsValid(player) then return false end
	
	local maxTest = GetConVar('zdev_snpc_max_test'):GetInt()
	
	-- Check player's test NPC count
	if not SNPC.TestNPCs[player] then
		SNPC.TestNPCs[player] = {}
	end
	
	local testCount = 0
	for _, npc in pairs(SNPC.TestNPCs[player]) do
		if IsValid(npc) then
			testCount = testCount + 1
		end
	end
	
	if testCount >= maxTest then
		player:ChatPrint('[ZDEV] Maximum test NPCs reached (' .. maxTest .. ')')
		return false
	end
	
	-- Spawn the test NPC
	local npc = SNPC.SpawnNPC(class, pos)
	if IsValid(npc) then
		-- Mark as test NPC
		npc.IsTestNPC = true
		npc.TestOwner = player
		npc.TestSpawnTime = CurTime()
		
		-- Add to player's test NPCs
		table.insert(SNPC.TestNPCs[player], npc)
		
		player:ChatPrint('[ZDEV] Spawned test ' .. class)
		
		-- Auto-cleanup after time limit
		local cleanupTime = GetConVar('zdev_snpc_cleanup_time'):GetFloat()
		timer.Simple(cleanupTime, function()
			if IsValid(npc) then
				npc:Remove()
				player:ChatPrint('[ZDEV] Test NPC auto-removed after ' .. cleanupTime .. ' seconds')
			end
		end)
		
		return true
	end
	
	return false
end

-- Remove all test NPCs for a player
function SNPC.RemoveTestNPCs(player)
	if not SNPC.TestNPCs[player] then return 0 end
	
	local removed = 0
	for _, npc in pairs(SNPC.TestNPCs[player]) do
		if IsValid(npc) then
			npc:Remove()
			removed = removed + 1
		end
	end
	
	SNPC.TestNPCs[player] = {}
	
	if removed > 0 then
		player:ChatPrint('[ZDEV] Removed ' .. removed .. ' test NPCs')
	end
	
	return removed
end

-- Console commands
concommand.Add('zdev_snpc_spawn', function(ply, cmd, args)
	if not IsValid(ply) or not ply:IsAdmin() then return end
	
	if #args < 1 then
		ply:ChatPrint('[ZDEV] Usage: zdev_snpc_spawn <class> [count]')
		return
	end
	
	local class = args[1]
	local count = tonumber(args[2]) or 1
	
	if not SNPC.Templates[class] then
		ply:ChatPrint('[ZDEV] Unknown SNPC class: ' .. class)
		return
	end
	
	local trace = ply:GetEyeTrace()
	if not trace.Hit then return end
	
	for i = 1, math.min(count, 10) do
		local pos = trace.HitPos + Vector(math.random(-100, 100), math.random(-100, 100), 10)
		SNPC.SpawnNPC(class, pos)
	end
	
	ply:ChatPrint('[ZDEV] Spawned ' .. count .. ' ' .. class)
end)

concommand.Add('zdev_snpc_remove_all', function(ply, cmd, args)
	if not IsValid(ply) or not ply:IsAdmin() then return end
	
	local removed = 0
	for id, npc in pairs(SNPC.ActiveNPCs) do
		if IsValid(npc) then
			npc:Remove()
			removed = removed + 1
		end
	end
	
	SNPC.ActiveNPCs = {}
	ply:ChatPrint('[ZDEV] Removed ' .. removed .. ' SNPCs')
end)

concommand.Add('zdev_snpc_list', function(ply, cmd, args)
	if not IsValid(ply) or not ply:IsAdmin() then return end
	
	ply:ChatPrint('[ZDEV] Available SNPC Templates:')
	for class, template in pairs(SNPC.Templates) do
		local status = template.spawnable and 'Spawnable' or 'Base Class'
		if template.adminOnly then status = status .. ' (Admin Only)' end
		ply:ChatPrint('  ' .. class .. ' - ' .. template.name .. ' (' .. status .. ')')
	end
end)

concommand.Add('zdev_snpc_cleanup', function(ply, cmd, args)
	if not IsValid(ply) or not ply:IsAdmin() then return end
	
	SNPC.CleanupNPCs()
	ply:ChatPrint('[ZDEV] SNPC cleanup completed')
end)

-- Cleanup test NPCs when player disconnects
hook.Add('PlayerDisconnected', 'ZDEV_SNPC_PlayerDisconnect', function(ply)
	if SNPC.TestNPCs[ply] then
		for _, npc in pairs(SNPC.TestNPCs[ply]) do
			if IsValid(npc) then
				npc:Remove()
			end
		end
		SNPC.TestNPCs[ply] = nil
	end
end)

-- Regular cleanup timer
timer.Create('ZDEV_SNPC_Cleanup', 60, 0, function()
	SNPC.CleanupNPCs()
end)

-- File monitoring for listen server communication
timer.Create('ZDEV_SNPC_FileMonitor', 0.5, 0, function()
	-- Check for spawn requests
	if file.Exists('zdev/snpc_spawn_request.json', 'DATA') then
		local jsonData = file.Read('zdev/snpc_spawn_request.json', 'DATA')
		file.Delete('zdev/snpc_spawn_request.json') -- Remove file after reading
		
		if jsonData and jsonData ~= '' then
			local success, data = pcall(util.JSONToTable, jsonData)
			if success and data and data.action == 'spawn' then
				if GetConVar('zdev_snpc_debug'):GetBool() then
					print('[ZDEV SNPC] Processing spawn request for class: ' .. (data.class or 'nil'))
				end
				
				-- Find player by SteamID
				local ply = nil
				for _, p in pairs(player.GetAll()) do
					if p:SteamID() == data.playerID then
						ply = p
						break
					end
				end
				
				if IsValid(ply) and data.class and data.pos then
					-- Validate class
					if not SNPC.Templates[data.class] or not SNPC.Templates[data.class].spawnable then
						ply:ChatPrint('[ZDEV] Invalid or non-spawnable SNPC class: ' .. data.class)
						return
					end
					
					-- Check admin permissions if required
					local template = SNPC.Templates[data.class]
					if template.adminOnly and not ply:IsAdmin() then
						ply:ChatPrint('[ZDEV] Admin only SNPC: ' .. data.class)
						return
					end
					
					local pos = Vector(data.pos.x, data.pos.y, data.pos.z)
					SNPC.SpawnTestNPC(ply, data.class, pos)
				end
			end
		end
	end
	
	-- Check for remove requests
	if file.Exists('zdev/snpc_remove_request.json', 'DATA') then
		local jsonData = file.Read('zdev/snpc_remove_request.json', 'DATA')
		file.Delete('zdev/snpc_remove_request.json') -- Remove file after reading
		
		if jsonData and jsonData ~= '' then
			local success, data = pcall(util.JSONToTable, jsonData)
			if success and data and data.action == 'remove' then
				if GetConVar('zdev_snpc_debug'):GetBool() then
					print('[ZDEV SNPC] Processing remove request from player: ' .. (data.playerID or 'nil'))
				end
				
				-- Find player by SteamID
				local ply = nil
				for _, p in pairs(player.GetAll()) do
					if p:SteamID() == data.playerID then
						ply = p
						break
					end
				end
				
				if IsValid(ply) then
					SNPC.RemoveTestNPCs(ply)
				end
			end
		end
	end
end)

-- Initialize the system
hook.Add('Initialize', 'ZDEV_SNPC_Initialize', function()
	if ZDEV and ZDEV.LOG then
		zdev.log('S', 'ZDEV SNPC System initialized')
	end
end)

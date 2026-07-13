local _f = 'zdev/server/zd_sv_util.lua'; Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

--[[
	zd_sv_util.lua
	Server utility functions for zdev addon.
	Author: zcomstudios
	Description: Provides utility functions for server-side zdev logic.
]]

ZDEV.UTIL = ZDEV.UTIL or {}

local i_stack, prefix = 0, ""
local t_files, t_dirs = {}, {}
local t_realms = {
	[SERVER] = {tag="sv", color=Color(0,200,255), label="server"},
	[CLIENT] = {tag="cl", color=Color(255,200,50), label="client"}
}
-- ZDEV_UID: ZDEV_FUNC_6990D2BF | Path: ZDEV.UTIL.ScanDir
function ZDEV.UTIL.ScanDir( root, dir )

	--zdev.log( "W", "Scanning: " .. root .. " " .. dir .. " " .. tostring(last) .. "\n" )
	local files, folders = file.Find( dir .. "--[[", root )

	for k, d in pairs( folders ) do

		if d == "server" then
			MsgC( Color(0,150,200), prefix .. d .. "\n" )
		elseif d == "client" then
			MsgC( Color(200,150,0), prefix .. d .. "\n" )
		else
			MsgC( Color(200,150,200), prefix .. d .. "\n" )
		end

		ZDEV.UTIL.ScanDir( root, dir .. "/" .. d )

	end

	for k, f in pairs( files ) do

		MsgC( Color(255,255,255), prefix .. dir .. "/" )

		if string.find( f, "sv_", 1, false) or f == "init.lua" then

			MsgC( Color(100,200,255), prefix .. "◓ " .. f .. "\n" )

		elseif string.find( f, "sh_", 1, false) or f == "shared.lua" then

			MsgC( Color(100,200,100), prefix .. "◍ " .. f .. "\n")

		elseif string.find( f, "cl_", 1, false) then

			MsgC( Color(255,200,100), prefix .. "◒ " .. f .. "\n")

		else

			MsgC( Color(255,100,255), prefix .. "? " .. f .. "\n")

		end
	end

end

function ZDEV.CMDS.DEV.EntCreate( ply, cmd, arg, args )

	local class = arg[ 1 ]
	local name = arg[ 2 ]
	local tr = ply:GetEyeTrace()

	-- Create a simple physics prop to parent the real entity to and server as a 'handle' to move it
	local e_h = ents.Create( "prop_physics" )
	e_h:SetColor( Color(0,0,0,100) )
	e_h:SetModel( "models/editor/axis_helper.mdl" )
	e_h:SetPos( tr.HitPos )
	e_h:SetOwner( ply )
	e_h.ChildEnt = nil
	e_h:Spawn()

	--[[


	local e = ents.Create( class )
	e:SetPos( e_h:GetPos() )
	e:SetParent( e_h )
	e:SetName( name )
	e:Spawn()

	e_h.ChildEnt = e

	debugoverlay.EntityTextAtPosition( e:GetPos(), 1, tostring(e), 6, Color( 100, 200, 255 ) )

	ply:SetNWEntity( "LastDevSpawn",  e )
	ply:SetNWInt( "LastDevSpawn_Index", e:EntIndex() )
]]
	zdev.log( "W", tostring(ply) .. " spawned entity " ..tostring(e) .. " using the Z-Developer menu." )

end
ZDEV.CMDS.Register( "zdev_ent_create", ZDEV.CMDS.DEV.EntCreate,
	{ aliases = { "zd_ent_create" }, flags = {FCVAR_CHEAT,FCVAR_CLIENTCMD_CAN_EXECUTE} } )


function ZDEV.CMDS.DEV.RunLua( ply, cmd )
	zdev.log( "W", "Running Lua Code " .. tostring(cmd) )
	--RunConsoleCommand( "lua_run_sv", cmd )
	ply:ConCommand( "lua_run_sv " .. cmd)
	--game.ConsoleCommand("lua_run_sv "..cmd.."\n")
end

net.Receive( "zdev_con_lua_tosv", function( )
	local ply = net.ReadEntity()
	if ply:GetUserGroup() ~= "superadmin" then return end
	local cmd = net.ReadString()
	print( tostring(ply), tostring(cmd) )
	ZDEV.CMDS.DEV.RunLua( ply, cmd )
end )

net.Receive( "zdev_dev_selclass_tosv", function()
	local class = net.ReadString()
	
end)

-- ZDEV_UID: ZDEV_FUNC_7F66A25A | Path: ZDEV.UTIL.EntityKeyValue
function ZDEV.UTIL.EntityKeyValue( ent, key, value )

	if key == "texture" and IsValid( decal ) and decal:GetClass() == "infodecal" then
		if unwantedDecals[value] then
			-- set a targetname to make the decal remain and not appear automatically:
			decal:SetName( "remove_unwanted_decals" )
		end
	end

end
hook.Add( "EntityKeyValue", "ZDEV.UTIL.EntityKeyValue", ZDEV.UTIL.EntityKeyValue)

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    Inventory Sync (Server → Client)
    Serializes the player's backpack and sends it via net message.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

function ZDEV.SyncInventory( ply )
	if not (ZDEV.Settings and ZDEV.Settings.InventoryEnabled) then return end
	if not IsValid(ply) then return end

	ply.Inv = ply.Inv or {}
	ply.Inv.Backpack = ply.Inv.Backpack or {}
	ply.Inv.Equipped = ply.Inv.Equipped or {}

	local backpack, equipped, seen = {}, {}, {}

	for _, inst in ipairs(ply.Inv.Backpack) do
		if inst and inst.Serialize then
			local s = inst:Serialize()
			table.insert(backpack, s)
			seen[s.id] = true
		end
	end

	for slot, inst in pairs(ply.Inv.Equipped) do
		if inst and inst.Serialize then
			local s = inst:Serialize()
			equipped[slot] = s
			seen[s.id] = true
		end
	end

	-- Auto-generated defs: server made them on demand, client needs the def
	-- table to instantiate them. Marker: description == our auto-gen sentinel.
	local autogen = {}
	for id in pairs(seen) do
		local def = ZDEV.Items[id]
		if def and def.weaponClass == id
				and def.description == "Auto-generated from SWEP metadata." then
			autogen[id] = {
				name          = def.name,
				width         = def.width,
				height        = def.height,
				weight        = def.weight,
				icon          = def.icon,
				category      = def.category,
				itemType      = def.itemType,
				eligibleSlots = def.eligibleSlots,
				weaponClass   = def.weaponClass,
				rarity        = def.rarity,
			}
		end
	end

	local payload = { backpack = backpack, equipped = equipped, autogen = autogen }
	local json = util.TableToJSON(payload)

	net.Start("zdev_inv_sync")
		net.WriteString(json)
	net.Send(ply)
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    Item System Console Commands
    Used by the dev menu Items tab to spawn, give, and use items.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- zd_item_spawn <item_id>
-- Spawns a prop at the player's aim position with the item ID stored on it.
function ZDEV.CMDS.DEV.ItemSpawn( ply, cmd, args )
	if not (ZDEV.Settings and ZDEV.Settings.InventoryEnabled) then return end
	if not IsValid(ply) or (not ply:IsAdmin() and not ply:IsSuperAdmin()) then return end

	local itemID = args[1]
	if not itemID or itemID == "" then
		ply:ChatPrint("[ZDEV] Usage: zd_item_spawn <item_id>")
		return
	end

	local def = ZDEV.GetItemDef(itemID)
	if not def then
		ply:ChatPrint("[ZDEV] Unknown item: " .. itemID)
		return
	end

	local tr = ply:GetEyeTrace()
	local spawnPos = tr.HitPos + tr.HitNormal * 8

	local ent = ents.Create("prop_physics")
	ent:SetModel("models/items/boxsrounds.mdl")
	ent:SetPos(spawnPos)
	ent:SetAngles(Angle(0, ply:EyeAngles().y, 0))
	ent:SetOwner(ply)
	ent:Spawn()
	ent:Activate()

	ent:SetNWString("zd_item_id", itemID)
	ent:SetNWString("zd_item_name", def.name)

	ent:SetColor(Color(255, 255, 255, 255))
	ent:GetPhysicsObject():SetMass(math.max(def.weight or 1, 1))

	zdev.log("I", tostring(ply) .. " spawned item '" .. def.name .. "' (" .. itemID .. ") at " .. tostring(spawnPos))
	ply:ChatPrint("[ZDEV] Spawned: " .. def.name)
end
ZDEV.CMDS.Register( "zdev_item_spawn", ZDEV.CMDS.DEV.ItemSpawn, { aliases = { "zd_item_spawn" } } )

-- zd_item_give <item_id>
-- Creates an item instance and adds it to the player's inventory data.
function ZDEV.CMDS.DEV.ItemGive( ply, cmd, args )
	if not (ZDEV.Settings and ZDEV.Settings.InventoryEnabled) then return end
	if not IsValid(ply) or (not ply:IsAdmin() and not ply:IsSuperAdmin()) then return end

	local itemID = args[1]
	if not itemID or itemID == "" then
		ply:ChatPrint("[ZDEV] Usage: zd_item_give <item_id>")
		return
	end

	local def = ZDEV.GetItemDef(itemID)
	if not def then
		ply:ChatPrint("[ZDEV] Unknown item: " .. itemID)
		return
	end

	-- Ensure player inventory table exists
	ply.Inv = ply.Inv or {}
	ply.Inv.Backpack = ply.Inv.Backpack or {}

	-- Check if a stackable instance already exists in the backpack
	if def.maxStack and def.maxStack > 1 then
		for _, inst in ipairs(ply.Inv.Backpack) do
			if inst:GetID() == itemID and inst:CanAddToStack(1) then
				inst:AddToStack(1)
				zdev.log("I", tostring(ply) .. " received item '" .. def.name .. "' (stacked)")
				ply:ChatPrint("[ZDEV] Received: " .. def.name .. " (x" .. inst:GetStack() .. ")")
				ZDEV.SyncInventory(ply)
				return
			end
		end
	end

	-- Create new instance
	local inst = ZD_ItemBase:FromDef(itemID)
	if not inst then
		ply:ChatPrint("[ZDEV] Failed to create item instance: " .. itemID)
		return
	end

	table.insert(ply.Inv.Backpack, inst)
	zdev.log("I", tostring(ply) .. " received item '" .. def.name .. "' (" .. itemID .. ")")
	ply:ChatPrint("[ZDEV] Received: " .. def.name)

	ZDEV.SyncInventory(ply)
end
ZDEV.CMDS.Register( "zdev_item_give", ZDEV.CMDS.DEV.ItemGive, { aliases = { "zd_item_give" } } )

-- zd_item_use <item_id>
-- Creates a temporary item instance and immediately uses it on the player.
function ZDEV.CMDS.DEV.ItemUse( ply, cmd, args )
	if not (ZDEV.Settings and ZDEV.Settings.InventoryEnabled) then return end
	if not IsValid(ply) or (not ply:IsAdmin() and not ply:IsSuperAdmin()) then return end

	local itemID = args[1]
	if not itemID or itemID == "" then
		ply:ChatPrint("[ZDEV] Usage: zd_item_use <item_id>")
		return
	end

	local def = ZDEV.GetItemDef(itemID)
	if not def then
		ply:ChatPrint("[ZDEV] Unknown item: " .. itemID)
		return
	end

	if not def.onUse then
		ply:ChatPrint("[ZDEV] Item '" .. def.name .. "' has no use action.")
		return
	end

	local inst = ZD_ItemBase:FromDef(itemID)
	if not inst then
		ply:ChatPrint("[ZDEV] Failed to create item instance: " .. itemID)
		return
	end

	inst:Use(ply)
	zdev.log("I", tostring(ply) .. " used item '" .. def.name .. "' (" .. itemID .. ")")
	ply:ChatPrint("[ZDEV] Used: " .. def.name)
end
ZDEV.CMDS.Register( "zdev_item_use", ZDEV.CMDS.DEV.ItemUse, { aliases = { "zd_item_use" } } )

ZDEV.FILE.SetLoaded( _f )

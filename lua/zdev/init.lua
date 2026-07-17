--[[
	init.lua
	Server initialization script for zdev addon.
	Author: zcomstudios
	Description: Handles server-side initialization logic for the zdev core.
]]
local _f = 'zdev/init.lua'
Msg("■")
MsgC(Color(200,50,255), 'ZDEV File:', color_white, _f .. '\n')
if ZDEV.FILE.Loaded(_f) then return end

AddCSLuaFile("zdev/shared.lua")
--[AddCSLuaFile("zdev/shared/zd_sh_advanced_nn.lua")
--AddCSLuaFile("zdev/shared/zd_sh_simple_nn.lua")
AddCSLuaFile("zdev/shared/zd_sh_core.lua")
AddCSLuaFile("zdev/shared/zd_sh_effect.lua")
AddCSLuaFile("zdev/shared/zd_sh_editor.lua")
AddCSLuaFile("zdev/shared/zd_sh_player.lua")
AddCSLuaFile("zdev/shared/zd_sh_weapon.lua")
AddCSLuaFile("zdev/shared/meta/zd_sh_meta_ent.lua")
AddCSLuaFile("zdev/shared/meta/zd_sh_meta_ply.lua")
AddCSLuaFile("zdev/shared/meta/zd_sh_meta_wep.lua")
AddCSLuaFile("zdev/shared/zd_sh_debug_console.lua")
--AddCSLuaFile("zdev/shared/sh_items.lua")
--AddCSLuaFile("zdev/shared/sh_items_defs.lua")
--AddCSLuaFile("zdev/shared/zd_sh_experience.lua")

--zdev.SendCSFilesIn("zdev/shared/")

AddCSLuaFile("zdev/cl_init.lua")

--zdev.SendCSFilesIn("zdev/client/")



AddCSLuaFile("zdev/client/zd_cl_util.lua")
AddCSLuaFile("zdev/client/zd_cl_effect.lua")
AddCSLuaFile("zdev/client/zd_cl_draw.lua")
AddCSLuaFile("zdev/client/draw/zd_cl_draw_anim.lua")
AddCSLuaFile("zdev/client/draw/zd_cl_draw_fx.lua")
AddCSLuaFile("zdev/client/draw/zd_cl_draw_ui.lua")
AddCSLuaFile("zdev/client/draw/zd_cl_draw_viz.lua")
AddCSLuaFile("zdev/client/draw/zd_cl_draw_demo.lua")
AddCSLuaFile("zdev/client/zd_cl_hud.lua")
AddCSLuaFile("zdev/client/zd_cl_render.lua")
AddCSLuaFile("zdev/client/render/zd_cl_r3d.lua")
AddCSLuaFile("zdev/client/render/zd_cl_r3d_widget.lua")
AddCSLuaFile("zdev/client/render/zd_cl_r3d_demo.lua")
AddCSLuaFile("zdev/client/render/zd_cl_mesh.lua")
AddCSLuaFile("zdev/client/render/zd_cl_mesh_demo.lua")
AddCSLuaFile("zdev/client/zd_cl_vgui.lua")
AddCSLuaFile("zdev/client/zd_cl_imgui.lua")
AddCSLuaFile("zdev/client/zd_cl_imgui_test.lua")
AddCSLuaFile("zdev/client/hud/zd_cl_hud_widgets.lua")
AddCSLuaFile("zdev/client/hud/zd_cl_hud_pickup.lua")
AddCSLuaFile("zdev/client/hud/zd_cl_hud_dev_effects.lua")
AddCSLuaFile("zdev/client/hud/zd_cl_hud_msg.lua")
AddCSLuaFile("zdev/client/hud/zd_cl_hud_elements.lua")
AddCSLuaFile("zdev/client/hud/zd_cl_hud_damage.lua")
--AddCSLuaFile("zdev/client/hud/zd_cl_hud_exp.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_menu_admin.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_menu_dev.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_menu_editor_particle.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_menu_editor_hud.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_imgui_devhub.lua")
--AddCSLuaFile("zdev/client/menu/zd_cl_menu_editor_neuralnetwork.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_menu_dev_efx.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_menu_dev_mat.lua")
--AddCSLuaFile("zdev/client/menu/zd_cl_menu_dev_part.lua")
--AddCSLuaFile("zdev/client/menu/zd_cl_menu_dev_env.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_menu_fonts.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_menu_options.lua")
--AddCSLuaFile("zdev/client/menu/zd_cl_menu_weapons.lua")
--AddCSLuaFile("zdev/client/menu/zd_cl_menu_npcs.lua")
--AddCSLuaFile("zdev/client/menu/zd_cl_menu_dev_snpc.lua")
--AddCSLuaFile("zdev/client/menu/zd_cl_menu_neuralnetwork.lua")
--AddCSLuaFile("zdev/client/menu/zd_cl_menu_test.lua")
AddCSLuaFile("zdev/client/vgui/zd_cl_tooltip.lua")
AddCSLuaFile("zdev/client/vgui/zd_cl_debug_console_panel.lua")
--AddCSLuaFile("zdev/client/vgui/zd_cl_dragoverlay.lua")
--AddCSLuaFile("zdev/client/vgui/zd_cl_invgrid.lua")
------AddCSLuaFile("zdev/client/vgui/zd_cl_equipslot.lua")
--AddCSLuaFile("zdev/client/menu/zd_cl_menu_inventory.lua")
--AddCSLuaFile("zdev/client/menu/zd_cl_menu_equipment.lua")
--AddCSLuaFile("zdev/client/menu/zd_cl_menu_inspect.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_menu_database.lua")
--AddCSLuaFile("zdev/client/menu/zd_cl_menu_player.lua")
AddCSLuaFile("zdev/client/menu/zd_cl_menu_lua_repl.lua")
AddCSLuaFile("zdev/client/zd_cl_debug_console.lua")
AddCSLuaFile("zdev/client/zd_cl_debug_console_filter.lua")
AddCSLuaFile("zdev/client/zd_cl_debug_console_appearance.lua")
AddCSLuaFile("zdev/client/zd_cl_sidekick_relay.lua")
util.AddNetworkString("zdev_reload")
util.AddNetworkString("zdev_con_lua_tosv")
util.AddNetworkString("zdev_hud_msg_send")
util.AddNetworkString("zdev_hud_marker_ent")
util.AddNetworkString("zdev_hud_marker_ent_remove")
util.AddNetworkString("zdev_hud_marker_world")
util.AddNetworkString("zdev_hud_visor_dmg")
util.AddNetworkString("zdev_admin_setdata")
util.AddNetworkString("zdev_admin_cmd")

-- Push typed visor damage to a player's HUD (hacking / jamming / shock / etc.).
-- channel: one of physical/blood/dust/fluid/electrical/digital/signal.
-- amount:  0..1 added to that channel (client-side decays it over time).
function ZDEV.SendVisorDamage( ply, channel, amount )
	if not IsValid( ply ) or not ply:IsPlayer() then return end
	net.Start( "zdev_hud_visor_dmg" )
		net.WriteString( tostring( channel ) )
		net.WriteFloat( tonumber( amount ) or 0 )
	net.Send( ply )
end
--util.AddNetworkString("zdev_inv_sync")
--util.AddNetworkString("zdev_inv_move")
--util.AddNetworkString("zdev_inv_equip_weapon")
--util.AddNetworkString("zdev_inv_unequip_weapon")
--util.AddNetworkString("zdev_weap_absorb")

--include( 'includes/modules/neural_network.lua' )
include('zdev/shared.lua')
include('zdev/shared/zd_sh_debug_console.lua')

--zdev.IncludeFilesIn("zdev/server/")



include("zdev/server/zd_sv_debug_console.lua")
include("zdev/server/zd_sv_sidekick.lua")
include("zdev/server/zd_sv_database.lua")
include("zdev/server/zd_sv_database_net.lua")
include("zdev/server/zd_sv_schema.lua")
include("zdev/server/zd_sv_playerdata.lua")
--include("zdev/server/zd_sv_experience.lua")
include("zdev/server/zd_sv_core.lua")

include("zdev/server/meta/zd_sv_meta_ply.lua")
include("zdev/server/meta/zd_sv_meta_ent.lua")
include("zdev/server/meta/zd_sv_meta_wep.lua")
include("zdev/server/zd_sv_util.lua")
include("zdev/server/zd_sv_player.lua")
include("zdev/server/zd_sv_weapon.lua")
include("zdev/server/zd_sv_weapon_sync.lua")

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ADMIN: Set Player Data (net receiver)
    Allows admins to modify any NW var on any player in real-time.
    Validates admin status, applies changes, and triggers a save.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

-- Whitelist of NW keys admins can modify (Core essentials only)
local ADMIN_EDITABLE = {
    ZDEV_Rank = "Int",
}

net.Receive("zdev_admin_setdata", function(len, admin)
    if not IsValid(admin) or not admin:IsAdmin() then return end

    local target = net.ReadEntity()
    local payload = net.ReadTable()

    if not IsValid(target) or not target:IsPlayer() then
        admin:SendHUDMessage(HUDMSG_ERROR, "Invalid target player.", 3)
        return
    end

    if not payload or type(payload) ~= "table" then return end

    local applied = 0
    for key, data in pairs(payload) do
        local allowedType = ADMIN_EDITABLE[key]
        if not allowedType then continue end

        local val = data.val
        if val == nil then continue end

        if allowedType == "Int" then
            val = math.floor(tonumber(val) or 0)
            target:SetNWInt(key, val)
        elseif allowedType == "Float" then
            val = tonumber(val) or 0
            target:SetNWFloat(key, val)
        end
        applied = applied + 1
    end

    -- Trigger a save (only if DB is connected)
    if ZDEV.MSQL and ZDEV.MSQL.Enabled and ZDEV.MSQL.Status and ZDEV.MSQL.Status.connected then
        if ZDEV.PDATA and ZDEV.PDATA.Save then
            ZDEV.PDATA.Save(target)
        end
    end

    admin:SendHUDMessage(HUDMSG_INFO, "Applied " .. applied .. " change(s) to " .. target:Nick(), 3)
    zdev.log("S", "ADMIN: " .. admin:Nick() .. " modified " .. applied .. " field(s) on " .. target:Nick())

    if ZDEV.SCHEMA and ZDEV.SCHEMA.AuditLog then
        ZDEV.SCHEMA.AuditLog(admin:SteamID64(), "admin_setdata",
            "Modified " .. applied .. " field(s) on " .. target:Nick() .. " [" .. target:SteamID64() .. "]")
    end
end)

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ADMIN: Execute Command on Player(s)
    Commands: kick, ban, kill, respawn, heal, god, noclip,
              freeze, goto, bring, strip
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local ADMIN_CMDS = {
    kick = function(admin, target, arg)
        target:Kick(arg ~= "" and arg or "Kicked by admin")
    end,
    ban = function(admin, target, arg)
        local duration = tonumber(arg) or 0
        target:Ban(duration, "Banned by " .. admin:Nick())
        target:Kick("Banned for " .. (duration > 0 and (duration .. " minutes") or "permanently"))
    end,
    kill = function(admin, target)
        target:Kill()
    end,
    respawn = function(admin, target)
        target:Spawn()
    end,
    heal = function(admin, target)
        target:SetHealth(target:GetMaxHealth())
        target:SetArmor(target.GetMaxArmor and target:GetMaxArmor() or 100)
    end,
    god = function(admin, target)
        if target:HasGodMode() then
            target:GodDisable()
        else
            target:GodEnable()
        end
    end,
    noclip = function(admin, target)
        if target:GetMoveType() == MOVETYPE_NOCLIP then
            target:SetMoveType(MOVETYPE_WALK)
        else
            target:SetMoveType(MOVETYPE_NOCLIP)
        end
    end,
    freeze = function(admin, target)
        if target:IsFlagSet(FL_FROZEN) then
            target:RemoveFlags(FL_FROZEN)
        else
            target:AddFlags(FL_FROZEN)
        end
    end,
    goto = function(admin, target)
        admin:SetPos(target:GetPos() + Vector(0, 0, 10))
    end,
    bring = function(admin, target)
        target:SetPos(admin:GetPos() + admin:GetForward() * 100 + Vector(0, 0, 10))
    end,
    strip = function(admin, target)
        target:StripWeapons()
    end,
}

net.Receive("zdev_admin_cmd", function(len, admin)
    if not IsValid(admin) or not admin:IsAdmin() then return end

    local cmd = net.ReadString()
    local targets = net.ReadTable()
    local arg = net.ReadString()

    local handler = ADMIN_CMDS[cmd]
    if not handler then
        admin:SendHUDMessage(HUDMSG_ERROR, "Unknown command: " .. cmd, 3)
        return
    end

    local count = 0
    for _, uid in ipairs(targets) do
        local target = Player(uid)
        if IsValid(target) then
            handler(admin, target, arg)
            count = count + 1
        end
    end

    admin:SendHUDMessage(HUDMSG_INFO, string.upper(cmd) .. " applied to " .. count .. " player(s)", 3)
    zdev.log("S", "ADMIN: " .. admin:Nick() .. " executed '" .. cmd .. "' on " .. count .. " player(s)")

    if ZDEV.SCHEMA and ZDEV.SCHEMA.AuditLog then
        ZDEV.SCHEMA.AuditLog(admin:SteamID64(), "admin_cmd", cmd .. " on " .. count .. " player(s)")
    end
end)

ZDEV.FILE.SetLoaded(_f)

-- ZDEV_UID: ZDEV_FUNC_EQUIP_SLOT | Path: ZDEV.VGUI.EquipSlot
local _f = 'zdev/client/vgui/zd_cl_equipslot.lua'
Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

--[[
    ZD_EquipSlot - Equipment Slot Panel
    A single slot overlaid on the player model for equipping items. Handles
    both armor regions (exact equipRegion match) and the seven weapon slots
    (eligibleSlots multi-match). Consumes ZDEV.VGUI.DragState on release.

    Context: Client
]]

local PANEL = {}

AccessorFunc(PANEL, "m_sRegion",   "Region")
AccessorFunc(PANEL, "m_sLabel",    "Label")

local SLOT_SIZE = 56

local MAT = {
    SLOT = {
        base  = Material("ui/ui_slot.png"),
        hover = Material("ui/ui_slot_hover.png"),
    }
}

function PANEL:Init()
    self:SetSize(SLOT_SIZE, SLOT_SIZE)
    self:SetMouseInputEnabled(true)
    self:SetRegion("generic")
    self:SetLabel("")
    self:SetZPos(100)
    self.m_bHovered = false
    self.m_Item     = nil      -- ZD_ItemBase instance currently equipped here
end

---------------------------------------------------------------------------
-- Eligibility
---------------------------------------------------------------------------

function PANEL:CanEquip(item)
    if not item then return false end
    local region = self:GetRegion()
    if ZDEV.Items.IsWeaponSlot(region) then
        local elig = item.GetEligibleSlots and item:GetEligibleSlots()
        return elig ~= nil and table.HasValue(elig, region)
    end
    -- Armor region: exact match
    if item.GetEquipRegion then
        return item:GetEquipRegion() == region
    end
    return region == "generic"
end

---------------------------------------------------------------------------
-- Equip / Unequip
---------------------------------------------------------------------------

function PANEL:Equip(item)
    self.m_Item = item
    if self.OnEquip then self:OnEquip(item) end
end

function PANEL:Unequip()
    local item = self.m_Item
    if not item then return nil end
    if self.OnUnequip then self:OnUnequip(item) end
    self.m_Item = nil

    if ZDEV.Items.IsWeaponSlot(self:GetRegion()) then
        net.Start("zdev_inv_unequip_weapon")
            net.WriteString(self:GetRegion())
        net.SendToServer()
    end
    return item
end

function PANEL:GetItem() return self.m_Item end

---------------------------------------------------------------------------
-- Mouse
---------------------------------------------------------------------------

function PANEL:OnCursorEntered() self.m_bHovered = true end
function PANEL:OnCursorExited()
    self.m_bHovered = false
    if ZDEV.VGUI and ZDEV.VGUI.Tooltip then ZDEV.VGUI.Tooltip:Hide() end
end

function PANEL:Think()
    if self.m_bHovered and self.m_Item and ZDEV.VGUI and ZDEV.VGUI.Tooltip then
        local mx, my = gui.MousePos()
        ZDEV.VGUI.Tooltip:Show(self.m_Item, mx, my)
    end
end

function PANEL:OnMousePressed(mc)
    if mc ~= MOUSE_RIGHT or not self.m_Item then return end
    local menu = DermaMenu()
    menu:AddOption("Unequip", function() self:Unequip() end):SetIcon("icon16/arrow_undo.png")
    menu:Open()
end

function PANEL:OnMouseReleased(mc)
    if mc ~= MOUSE_LEFT then return end
    local DS = ZDEV.VGUI.DragState
    if not DS.active then return end

    local item = DS.item
    if not self:CanEquip(item) then DS:End() return end

    -- Determine the item's Backpack index for the server message (weapons only).
    local ply = LocalPlayer()
    local backpackIndex = nil
    if ply and ply.Inv and ply.Inv.Backpack then
        for i, inst in ipairs(ply.Inv.Backpack) do
            if inst == item then backpackIndex = i break end
        end
    end

    -- Remove from source grid
    if DS.sourceGrid and DS.sourceGrid.RemoveEntry then
        DS.sourceGrid:RemoveEntry(DS.entryID)
    end

    -- Send equip message for weapon slots
    if ZDEV.Items.IsWeaponSlot(self:GetRegion()) and backpackIndex then
        net.Start("zdev_inv_equip_weapon")
            net.WriteUInt(backpackIndex, 8)
            net.WriteString(self:GetRegion())
        net.SendToServer()
    end

    self:Equip(item)
    DS:End()
end

---------------------------------------------------------------------------
-- Paint
---------------------------------------------------------------------------

function PANEL:Paint(w, h)
    surface.SetDrawColor(255, 255, 255, self.m_bHovered and 220 or 140)
    surface.SetMaterial(MAT.SLOT.base)
    surface.DrawTexturedRect(0, 0, w, h)

    if self.m_Item then
        ZDEV.Items.DrawIcon(self.m_Item, 0, 0, w, h, {})
    else
        surface.SetDrawColor(0, 0, 0, 80)
        surface.DrawRect(4, 4, w - 8, h - 8)
    end

    -- Invalid-drop tint while dragging an incompatible item
    local DS = ZDEV.VGUI.DragState
    if DS.active and self.m_bHovered and DS.item and not self:CanEquip(DS.item) then
        surface.SetDrawColor(255, 60, 60, 120)
        surface.DrawRect(0, 0, w, h)
    end

    return true
end

function PANEL:PaintOver(w, h)
    local label = self:GetLabel()
    if label == "" then label = self:GetRegion() end
    if label and label ~= "" then
        draw.SimpleText(
            string.upper(label),
            "DermaDefaultBold",
            w / 2, h + 2,
            Color(210, 210, 225, 200),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP
        )
    end
end

--- Overridable hooks
function PANEL:OnEquip(item) end
function PANEL:OnUnequip(item) end

derma.DefineControl("ZD_EquipSlot", "ZDEV Equipment Body Slot", PANEL, "DPanel")

ZDEV.FILE.SetLoaded( _f )

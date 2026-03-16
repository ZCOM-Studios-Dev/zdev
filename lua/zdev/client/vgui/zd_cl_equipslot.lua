-- ZDEV_UID: ZDEV_FUNC_EQUIP_SLOT | Path: ZDEV.VGUI.EquipSlot
local _f = 'zdev/client/vgui/zd_cl_equipslot.lua'
Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

--[[
    ZD_EquipSlot - Equipment Slot Panel
    A slot overlaid on the player model for equipping items to body regions.
    Each slot has a body region (head, chest, legs, feet, hands, backpack)
    and accepts drag-and-drop items that match its region type.
    Context: Client
]]

local PANEL = {}

AccessorFunc(PANEL, "m_sRegion", "Region")
AccessorFunc(PANEL, "m_ItemPanel", "ItemPanel")
AccessorFunc(PANEL, "m_sLabel", "Label")

local SLOT_SIZE = 56

-- Region-specific icons (fallback drawing)
local REGION_COLORS = {
    head     = Color(200, 180, 100),
    chest    = Color(100, 150, 200),
    legs     = Color(100, 200, 130),
    feet     = Color(180, 130, 200),
    hands    = Color(200, 150, 100),
    backpack = Color(160, 140, 120),
    weapon   = Color(220, 80,  80),
}
local MAT = {
    SLOT = {
        base = Material("ui/ui_slot.png"),
        hover = Material("ui/ui_slot_hover.png"),
        active = Material("ui/ui_slot_active.png"),
        selected = Material("ui/ui_slot_selected.png"),
        disabled = Material("ui/ui_slot_disabled.png")
    }
}

function PANEL:Init()
    self:SetSize(SLOT_SIZE, SLOT_SIZE)
    self:SetMouseInputEnabled(true)
    self:SetRegion("generic")
    self:SetItemPanel(false)
    self:SetLabel("")
    self:SetZPos(100) -- Render above the model panel

    self.m_bHovered = false

    -- Accept equipment drops
    self:Receiver("zd_invitem", function(pnl, items, bDropped)
        if not bDropped then
            self.m_bHovered = true
            return
        end

        local itemPanel = items[1]
        if not itemPanel or not IsValid(itemPanel) then return end

        local item = itemPanel:GetItem()
        if not item then return end

        -- Validate region compatibility
        if not self:CanEquip(item) then return end

        -- Unequip existing item first
        if self:GetItemPanel() and IsValid(self:GetItemPanel()) then
            self:Unequip()
        end

        -- Equip the new item
        self:Equip(itemPanel)
    end, {})
end

--- Check if the item can be equipped in this slot's region
function PANEL:CanEquip(item)
    if not item then return false end
    local region = self:GetRegion()
    if region == "generic" then return true end

    if item.GetEquipRegion then
        return item:GetEquipRegion() == region
    end

    -- If no region info on item, allow it
    return true
end

--- Equip an item panel into this slot
function PANEL:Equip(itemPanel)
    if not IsValid(itemPanel) then return end

    -- Remove from grid if it was in one
    local oldParent = itemPanel:GetParent()
    if oldParent and oldParent.RemoveItemPanel then
        oldParent:RemoveItemPanel(itemPanel)
    end

    self:SetItemPanel(itemPanel)
    itemPanel:SetParent(self)
    itemPanel:SetPos(0, 0)
    itemPanel:SetSize(self:GetSize())
    itemPanel:SetMouseInputEnabled(false) -- Disable drag while equipped

    -- Fire callback
    if self.OnEquip then
        self:OnEquip(itemPanel:GetItem())
    end
end

--- Unequip the current item, returning it or dropping it
function PANEL:Unequip()
    local itemPanel = self:GetItemPanel()
    if not IsValid(itemPanel) then return end

    -- Fire callback before removing
    if self.OnUnequip then
        self:OnUnequip(itemPanel:GetItem())
    end

    itemPanel:SetMouseInputEnabled(true)
    self:SetItemPanel(false)

    return itemPanel
end

function PANEL:OnCursorEntered()
    self.m_bHovered = true
end

function PANEL:OnCursorExited()
    self.m_bHovered = false
end

function PANEL:OnMousePressed(mc)
    if mc == MOUSE_RIGHT and self:GetItemPanel() then
        local menu = DermaMenu()
        menu:AddOption("Unequip", function()
            local itemPnl = self:Unequip()
            if IsValid(itemPnl) then
                itemPnl:Remove()
            end
        end):SetIcon("icon16/arrow_undo.png")
        menu:Open()
    end
end

function PANEL:Paint(w, h)
    local region = self:GetRegion()
    local baseColor = REGION_COLORS[region] or Color(120, 120, 120)
    local mat = MAT.SLOT.base

    local matColor = Color(255, 255, 255, 255)
    if self.m_bHovered then
        mat = MAT.SLOT.hover
    end

    ZDEV.DRAW.TexturedRect(0, 0, w, h, mat, matColor)

    --[[
    -- Slot background
    local alpha = self.m_bHovered and 180 or 120
    surface.SetDrawColor(ColorAlpha(baseColor, alpha))
    surface.DrawRect(0, 0, w, h)

    -- Border - brighter when hovered
    local borderAlpha = self.m_bHovered and 255 or 150
    surface.SetDrawColor(ColorAlpha(baseColor, borderAlpha))
    surface.DrawOutlinedRect(0, 0, w, h, 2)
    ]]

    -- Inner darkened area if empty
    if not self:GetItemPanel() then
        surface.SetDrawColor(0, 0, 0, 80)
        surface.DrawRect(4, 4, w - 8, h - 8)
    end

    return true
end

function PANEL:PaintOver(w, h)
    -- Draw region label below the slot
    local label = self:GetLabel()
    if label == "" then label = self:GetRegion() end
    if label and label ~= "" then
        draw.SimpleText(
            string.upper(label),
            "DermaDefault",
            w / 2, h + 2,
            Color(200, 200, 200, 180),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP
        )
    end
end

--- Callback stubs - override these in the menu
function PANEL:OnEquip(item) end
function PANEL:OnUnequip(item) end

derma.DefineControl("ZD_EquipSlot", "ZDEV Equipment Body Slot", PANEL, "DPanel")
ZDEV.FILE.SetLoaded( _f )

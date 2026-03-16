-- ZDEV_UID: ZDEV_FUNC_INV_SLOT01 | Path: ZDEV.VGUI.InvSlot
local _f = 'zdev/client/vgui/zd_cl_invslot.lua'
Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

--[[
    ZD_InvSlot - Inventory Grid Slot
    A single square on the inventory grid. Acts as a drag-and-drop receiver.
    Tracks its grid coordinates (x, y) and whether an item panel occupies it.
    Context: Client
]]

local PANEL = {}

AccessorFunc(PANEL, "m_ItemPanel", "ItemPanel")
AccessorFunc(PANEL, "m_SlotType", "SlotType")
AccessorFunc(PANEL, "m_bLocked", "Locked")

-- Slot visual states
local STATE_EMPTY    = 0
local STATE_HOVER    = 1
local STATE_OCCUPIED = 2
local STATE_INVALID  = 3

-- Default slot size in pixels
local SLOT_SIZE = 48

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
    self.m_Coords = { x = 0, y = 0 }
    self:SetSize(SLOT_SIZE, SLOT_SIZE)
    self:SetMouseInputEnabled(true)
    self:SetItemPanel(false)
    self:SetSlotType("generic") -- generic, small, weapon, etc.
    self:SetLocked(false)
    self.m_iVisualState = STATE_EMPTY

    -- Accept dropped inventory items
    self:Receiver("zd_invitem", function(pnl, items, bDropped, menuIndex, mouseX, mouseY)
        if self:GetLocked() then return end
        if not bDropped then
            -- Hover feedback
            self.m_iVisualState = STATE_HOVER
            return
        end

        local itemPanel = items[1]
        if not itemPanel or not IsValid(itemPanel) then return end

        local item = itemPanel:GetItem()
        if not item then return end

        -- Validate item type against slot type
        if not self:CanAcceptItem(item) then
            self.m_iVisualState = STATE_INVALID
            timer.Simple(0.3, function()
                if IsValid(self) then
                    self.m_iVisualState = self:GetItemPanel() and STATE_OCCUPIED or STATE_EMPTY
                end
            end)
            return
        end

        -- Check if item fits at this position in the grid
        local gridParent = self:GetParent()
        if gridParent and gridParent.CanFitItem then
            local gx, gy = self:GetCoords()
            local itmW, itmH = 1, 1
            if item.GetSize then
                itmW, itmH = item:GetSize()
            end

            if not gridParent:CanFitItem(gx, gy, itmW, itmH, itemPanel) then
                self.m_iVisualState = STATE_INVALID
                timer.Simple(0.3, function()
                    if IsValid(self) then
                        self.m_iVisualState = self:GetItemPanel() and STATE_OCCUPIED or STATE_EMPTY
                    end
                end)
                return
            end

            -- Place the item
            gridParent:PlaceItem(gx, gy, itmW, itmH, itemPanel)
        end
    end, {})
end

function PANEL:SetCoords(x, y)
    self.m_Coords.x = x
    self.m_Coords.y = y
end

function PANEL:GetCoords()
    return self.m_Coords.x, self.m_Coords.y
end

--- Check if this slot type can accept the given item
function PANEL:CanAcceptItem(item)
    local slotType = self:GetSlotType()
    if slotType == "generic" then return true end

    if item.GetType then
        local itemType = item:GetType()
        -- "small" slots only accept small items, etc.
        if slotType == "small" and itemType ~= "small" then return false end
        if slotType == "weapon" and itemType ~= "weapon" then return false end
    end

    return true
end

function PANEL:OnCursorEntered()
    if not self:GetItemPanel() then
        self.m_iVisualState = STATE_HOVER
    end
end

function PANEL:OnCursorExited()
    if self:GetItemPanel() then
        self.m_iVisualState = STATE_OCCUPIED
    else
        self.m_iVisualState = STATE_EMPTY
    end
end

function PANEL:ClearItem()
    self:SetItemPanel(false)
    self.m_iVisualState = STATE_EMPTY
end

function PANEL:Paint(w, h)
    local bgColor, borderColor, mat, matColor



    if self.m_iVisualState == STATE_HOVER then
        bgColor    = Color(80, 90, 110, 200)
        borderColor = Color(100, 200, 255, 200)
        mat = MAT.SLOT.hover
    elseif self.m_iVisualState == STATE_OCCUPIED then
        bgColor    = Color(60, 70, 80, 220)
        borderColor = Color(80, 80, 80, 200)
        mat = MAT.SLOT.active
    elseif self.m_iVisualState == STATE_INVALID then
        bgColor    = Color(120, 40, 40, 220)
        borderColor = Color(255, 60, 60, 255)
        mat = MAT.SLOT.disabled
    else
        bgColor    = Color(40, 45, 55, 200)
        borderColor = Color(70, 70, 70, 180)
        mat = MAT.SLOT.base
    end

    matColor = Color(borderColor.r, borderColor.g, borderColor.b, 100)

    ZDEV.DRAW.TexturedRect(0, 0, w, h, mat, matColor)
    
    --[[
    -- Background
    surface.SetDrawColor(bgColor)
    surface.DrawRect(0, 0, w, h)

    -- Border
    surface.SetDrawColor(borderColor)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
]]
    return true
end

derma.DefineControl("ZD_InvSlot", "ZDEV Inventory Grid Slot", PANEL, "DPanel")
ZDEV.FILE.SetLoaded( _f )

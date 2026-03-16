-- ZDEV_UID: ZDEV_FUNC_8A1B2C3D | Path: ZDEV.VGUI.CreateSlotButton
local _f = 'zdev/client/vgui/zd_cl_dslot.lua'
Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

local PANEL = {}

-- Slot states
local SLOT_STATE_NORMAL = 0
local SLOT_STATE_HOVER = 1
local SLOT_STATE_ACTIVE = 2
local SLOT_STATE_SELECTED = 3
local SLOT_STATE_DISABLED = 4

-- Image paths
local IMAGE_PATHS = {
    ["ui_slot.png"] = "materials/ui/ui_slot.png",
    ["ui_slot_hover.png"] = "materials/ui/ui_slot_hover.png", 
    ["ui_slot_active.png"] = "materials/ui/ui_slot_active.png",
    ["ui_slot_selected.png"] = "materials/ui/ui_slot_selected.png",
    ["ui_slot_disabled.png"] = "materials/ui/ui_slot_disabled.png"
}

-- Material cache
local MATERIAL_CACHE = MATERIAL_CACHE or {}

function PANEL:Init()
    self:SetSize( 64, 64 )
    self:SetMouseInputEnabled( true )
    
    -- Initialize slot state
    self.m_iState = SLOT_STATE_NORMAL
    
    -- Load materials
    for name, path in pairs(IMAGE_PATHS) do
        MATERIAL_CACHE[name] = Material(path)
    end
end

function PANEL:SetState(state)
    self.m_iState = state
end

function PANEL:GetState()
    return self.m_iState
end

function PANEL:OnCursorEntered()
    if self:GetDisabled() then return end
    self:SetState(SLOT_STATE_HOVER)
end

function PANEL:OnCursorExited()
    if self:GetDisabled() then return end
    self:SetState(SLOT_STATE_NORMAL)
end

function PANEL:OnMousePressed(mc)
    if self:GetDisabled() then return end
    self:SetState(SLOT_STATE_ACTIVE)
end

function PANEL:OnMouseReleased(mc)
    if self:GetDisabled() then return end
    self:SetState(SLOT_STATE_HOVER)
end

function PANEL:SetDisabled(bDisabled)
    if bDisabled then
        self:SetState(SLOT_STATE_DISABLED)
    else
        self:SetState(SLOT_STATE_NORMAL)
    end
    self.m_bDisabled = bDisabled
end

function PANEL:Paint(w, h)
    -- Determine which material to use based on state
    local material = nil
    
    if self:GetDisabled() then
        material = MATERIAL_CACHE["ui_slot_disabled.png"]
    elseif self.m_iState == SLOT_STATE_HOVER then
        material = MATERIAL_CACHE["ui_slot_hover.png"]
    elseif self.m_iState == SLOT_STATE_ACTIVE then
        material = MATERIAL_CACHE["ui_slot_active.png"]
    elseif self.m_iState == SLOT_STATE_SELECTED then
        material = MATERIAL_CACHE["ui_slot_selected.png"]
    else
        material = MATERIAL_CACHE["ui_slot.png"]
    end
    
    -- Draw the appropriate image
    if material then
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(material)
        surface.DrawTexturedRect(0, 0, w, h)
    else
        -- Fallback to default painting if no material
        surface.SetDrawColor(50, 50, 50, 255)
        surface.DrawRect(0, 0, w, h)
    end
    
    return true
end

-- Register the panel
derma.DefineControl("ZD_Button", "", PANEL, "DPanel")
ZDEV.FILE.SetLoaded( _f )
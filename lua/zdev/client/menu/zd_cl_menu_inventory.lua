-- ZDEV_UID: ZDEV_FUNC_MENU_INV01 | Path: ZDEV.VGUI.InventoryMenu
local _f = 'zdev/client/menu/zd_cl_menu_inventory.lua'
Msg("■") MsgC(Color(200,50,255),'ZDEV File:',color_white,_f .. '\n')
if ZDEV.FILE.Loaded( _f ) then return end

--[[
    ZDEV Inventory Menu
    Grid-based drag-and-drop backpack inventory.
    Uses ZD_InvGrid, ZD_InvSlot, and ZD_InvItem elements.

    The inventory is structured as:
      - A main backpack grid (default 8x4, can change based on equipped backpack)
      - Optional secondary container grids (pockets from pants, belt, etc.)
      - Weight/capacity indicator
      - Item info panel on hover/select

    Context: Client
]]

local SW, SH = ScrW(), ScrH()

-- Default grid dimensions
local DEFAULT_COLS = 8
local DEFAULT_ROWS = 4

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    INVENTORY DATA
    Initialize the player's inventory data structure.
    In a full implementation, this would be synced from server.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local function EnsureInventoryData()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    if not ply.Inv then
        ply.Inv = {}
    end
    if not ply.Inv.Backpack then
        ply.Inv.Backpack = {}
    end
    if not ply.Inv.Equipped then
        ply.Inv.Equipped = {}
    end
    if not ply.Inv.Weight then
        ply.Inv.Weight = 0
    end
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ITEM INFO PANEL
    Shows details about a selected or hovered item.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local function CreateInfoPanel(parent)
    local info = vgui.Create("DPanel", parent)
    info:Dock(BOTTOM)
    info:SetTall(80)
    info:DockMargin(4, 4, 4, 4)

    info.m_sName = ""
    info.m_sDesc = ""
    info.m_sWeight = ""

    info.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(25, 30, 40, 240))
        surface.SetDrawColor(60, 70, 90, 200)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        -- Item name
        draw.SimpleText(
            self.m_sName ~= "" and self.m_sName or "No item selected",
            "DermaDefaultBold", 8, 8,
            self.m_sName ~= "" and Color(220, 220, 255) or Color(120, 120, 140),
            TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP
        )

        -- Item description
        if self.m_sDesc ~= "" then
            draw.SimpleText(
                self.m_sDesc, "DermaDefault", 8, 28,
                Color(180, 180, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP
            )
        end

        -- Weight
        if self.m_sWeight ~= "" then
            draw.SimpleText(
                "Weight: " .. self.m_sWeight, "DermaDefault", w - 8, 8,
                Color(180, 180, 160), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP
            )
        end
    end

    function info:SetItemInfo(item)
        if not item then
            self.m_sName = ""
            self.m_sDesc = ""
            self.m_sWeight = ""
            return
        end
        self.m_sName = item.GetName and item:GetName() or "Unknown Item"
        self.m_sDesc = item.GetDescription and item:GetDescription() or ""
        self.m_sWeight = item.GetWeight and tostring(item:GetWeight()) or ""
    end

    return info
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    WEIGHT BAR
    Visual indicator for current weight vs capacity.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

local function CreateWeightBar(parent)
    local bar = vgui.Create("DPanel", parent)
    bar:Dock(BOTTOM)
    bar:SetTall(20)
    bar:DockMargin(4, 2, 4, 0)

    bar.m_flCurrent = 0
    bar.m_flMax = 100

    bar.Paint = function(self, w, h)
        -- Background
        draw.RoundedBox(2, 0, 0, w, h, Color(20, 25, 35, 200))

        -- Fill
        local frac = math.Clamp(self.m_flCurrent / math.max(self.m_flMax, 1), 0, 1)
        local fillW = (w - 4) * frac
        local fillColor = frac < 0.7 and Color(60, 160, 100) or (frac < 0.9 and Color(200, 160, 40) or Color(200, 60, 60))
        draw.RoundedBox(2, 2, 2, fillW, h - 4, fillColor)

        -- Text
        local txt = string.format("%.1f / %.1f", self.m_flCurrent, self.m_flMax)
        draw.SimpleText(txt, "DermaDefault", w / 2, h / 2, Color(220, 220, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    function bar:SetWeight(current, max)
        self.m_flCurrent = current or 0
        self.m_flMax = max or 100
    end

    return bar
end

--[[━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    MAIN INVENTORY MENU
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]]

function ZDEV.VGUI.InventoryMenu(ply, cmd, arg)
    EnsureInventoryData()

    local menuW = math.floor(SW * 0.45)
    local menuH = math.floor(SH * 0.55)
    local menu = ZDEV.VGUI.CreateFrame(menuW, menuH, "Inventory")

    --[[ ━━━ Header Bar ━━━ ]]
    menu.header = vgui.Create("DPanel", menu)
    menu.header:Dock(TOP)
    menu.header:SetTall(28)
    menu.header:DockMargin(2, 2, 2, 0)
    menu.header.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(20, 25, 35, 200))
        draw.SimpleText("BACKPACK", "DermaDefaultBold", 8, h / 2, Color(200, 210, 240), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- Sort button
    menu.header.btnSort = vgui.Create("DButton", menu.header)
    menu.header.btnSort:Dock(RIGHT)
    menu.header.btnSort:SetWide(60)
    menu.header.btnSort:SetText("Sort")
    menu.header.btnSort:SetTextColor(Color(180, 200, 255))
    menu.header.btnSort.Paint = function(self, w, h)
        local col = self:IsHovered() and Color(60, 70, 90) or Color(40, 50, 65)
        draw.RoundedBox(0, 0, 0, w, h, col)
    end
    menu.header.btnSort.DoClick = function()
        -- TODO: Sort items in grid
        zdev.log("I", "Inventory sort requested")
    end

    --[[ ━━━ Scroll Panel for grids ━━━ ]]
    menu.scroll = vgui.Create("DScrollPanel", menu)
    menu.scroll:Dock(FILL)
    menu.scroll:DockMargin(4, 4, 4, 0)

    --[[ ━━━ Main Backpack Grid ━━━ ]]
    menu.backpackGrid = vgui.Create("ZD_InvGrid", menu.scroll)
    menu.backpackGrid:Dock(TOP)
    menu.backpackGrid:DockMargin(0, 0, 0, 4)
    menu.backpackGrid:SetGridSize(DEFAULT_COLS, DEFAULT_ROWS)

    --[[ ━━━ Secondary Container Area ━━━ ]]
    -- This panel holds dynamically-generated pocket/container grids
    -- that appear when equipment with storage is equipped
    menu.containerArea = vgui.Create("DPanel", menu.scroll)
    menu.containerArea:Dock(TOP)
    menu.containerArea:SetTall(0) -- Hidden by default
    menu.containerArea:DockMargin(0, 0, 0, 4)
    menu.containerArea.Paint = function() end -- Transparent
    menu.containerArea.m_tContainers = {}

    --- Add a new container grid (e.g. from equipping pants with pockets)
    function menu:AddContainer(name, cols, rows, slotType)
        local container = vgui.Create("DPanel", self.containerArea)
        container:Dock(TOP)
        container:DockMargin(0, 4, 0, 0)

        -- Container label
        container.label = vgui.Create("DPanel", container)
        container.label:Dock(TOP)
        container.label:SetTall(20)
        container.label.Paint = function(s, w, h)
            draw.SimpleText(
                string.upper(name), "DermaDefault",
                4, h / 2, Color(180, 180, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER
            )
        end

        -- Container grid
        container.grid = vgui.Create("ZD_InvGrid", container)
        container.grid:Dock(TOP)
        container.grid:SetDefaultSlotType(slotType or "generic")
        container.grid:SetGridSize(cols, rows)

        -- Size the container panel to fit
        container:SetTall(20 + container.grid:GetTall() + 4)

        -- Update container area height
        self.containerArea.m_tContainers[name] = container
        self:RecalcContainerArea()

        return container.grid
    end

    --- Remove a container by name (e.g. when unequipping pants)
    function menu:RemoveContainer(name)
        local container = self.containerArea.m_tContainers[name]
        if IsValid(container) then
            container:Remove()
        end
        self.containerArea.m_tContainers[name] = nil
        self:RecalcContainerArea()
    end

    --- Recalculate the container area's total height
    function menu:RecalcContainerArea()
        local totalH = 0
        for _, cont in pairs(self.containerArea.m_tContainers) do
            if IsValid(cont) then
                totalH = totalH + cont:GetTall() + 4
            end
        end
        self.containerArea:SetTall(totalH)
    end

    --[[ ━━━ Bottom Section ━━━ ]]
    menu.weightBar = CreateWeightBar(menu)
    menu.weightBar:SetWeight(0, 100)

    menu.infoPanel = CreateInfoPanel(menu)

    --[[ ━━━ Public API ━━━ ]]

    --- Refresh the weight display
    function menu:UpdateWeight(current, max)
        self.weightBar:SetWeight(current, max)
    end

    --- Show item info in the bottom panel
    function menu:ShowItemInfo(item)
        self.infoPanel:SetItemInfo(item)
    end

    --- Get the main backpack grid
    function menu:GetBackpackGrid()
        return self.backpackGrid
    end

    ZDEV.VGUI.ActiveInventory = menu
    return menu
end

concommand.Add("zd_menu_inventory", ZDEV.VGUI.InventoryMenu)
ZDEV.VGUI.AddToMainMenu("zd_menu_inventory")

ZDEV.FILE.SetLoaded( _f )

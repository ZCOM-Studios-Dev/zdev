-- ZDEV_UID: ZDEV_FUNC_ITEMS_BASE | Path: ZDEV.Items
local _f = 'zdev/shared/sh_items.lua'
if ZDEV and ZDEV.FILE and ZDEV.FILE.Loaded( _f ) then return end

--[[
    ZDEV Item System
    Provides item definition registration and a base item class (ZD_ItemBase)
    for use with the inventory and equipment VGUI elements.

    Usage:
      -- Register a definition (shared)
      ZDEV.RegisterItem("item_medkit", {
          name = "Medkit", width = 1, height = 1,
          icon = "materials/ui/items/medkit.png",
          weight = 2, category = "consumable",
          equipRegion = nil, -- not equippable
          onUse = function(ply, inst) ply:SetHealth(math.min(ply:Health() + 25, 100)) end,
      })

      -- Create an instance (client or shared)
      local medkit = ZD_ItemBase:FromDef("item_medkit")
      grid:AddItem(medkit)

    Context: Shared
]]

---------------------------------------------------------------------------
-- Item Definition Registry
---------------------------------------------------------------------------

ZDEV.Items = ZDEV.Items or {}

function ZDEV.RegisterItem(id, data)
    assert(isstring(id), "Item ID must be a string")
    assert(data.width and data.height, "Items must define grid size (width, height)")

    ZDEV.Items[id] = {
        id           = id,
        name         = data.name or id,
        width        = data.width,
        height       = data.height,
        icon         = data.icon,        -- material path string
        maxStack     = data.maxStack or 1,
        weight       = data.weight or 0,
        category     = data.category or "misc",
        description  = data.description or "",
        itemType     = data.itemType or "generic",  -- generic, small, weapon, armor, consumable
        equipRegion  = data.equipRegion,             -- head, chest, legs, feet, hands, backpack, weapon (nil = not equippable)
        defense      = data.defense or 0,
        storageCols  = data.storageCols,             -- if equipping grants inventory storage
        storageRows  = data.storageRows,
        storageSlotType = data.storageSlotType,      -- slot type filter for granted storage
        rarity       = data.rarity or "common",      -- common, uncommon, rare, epic, legendary
        onUse        = data.onUse,                   -- function(ply, itemInstance)
        onEquip      = data.onEquip,                 -- function(ply, itemInstance)
        onUnequip    = data.onUnequip,               -- function(ply, itemInstance)
    }
end

--- Look up a registered item definition by ID
function ZDEV.GetItemDef(id)
    return ZDEV.Items[id]
end

---------------------------------------------------------------------------
-- ZD_ItemBase - Base Item Class
-- Wraps a registered definition into a method-bearing object instance.
-- Each instance can hold per-instance state (stack count, durability, etc.)
---------------------------------------------------------------------------

ZD_ItemBase = {}
ZD_ItemBase.__index = ZD_ItemBase

--- Create a new item instance from scratch
function ZD_ItemBase:new(data)
    local inst = {}
    setmetatable(inst, self)
    self.__index = self

    inst.m_sID          = data.id or "unknown"
    inst.m_sName        = data.name or "Unknown Item"
    inst.m_iWidth       = data.width or 1
    inst.m_iHeight      = data.height or 1
    inst.m_sIconPath    = data.icon
    inst.m_matIcon      = data.icon and Material(data.icon) or nil
    inst.m_iMaxStack    = data.maxStack or 1
    inst.m_iStack       = data.stack or 1
    inst.m_flWeight     = data.weight or 0
    inst.m_sCategory    = data.category or "misc"
    inst.m_sDescription = data.description or ""
    inst.m_sItemType    = data.itemType or "generic"
    inst.m_sEquipRegion = data.equipRegion
    inst.m_iDefense     = data.defense or 0
    inst.m_iStorageCols = data.storageCols
    inst.m_iStorageRows = data.storageRows
    inst.m_sStorageSlotType = data.storageSlotType
    inst.m_sRarity      = data.rarity or "common"
    inst.m_fnOnUse      = data.onUse
    inst.m_fnOnEquip    = data.onEquip
    inst.m_fnOnUnequip  = data.onUnequip

    return inst
end

--- Create an instance from a registered definition ID
function ZD_ItemBase:FromDef(id)
    local def = ZDEV.GetItemDef(id)
    if not def then
        MsgC(Color(255, 80, 80), "[ZDEV] ", color_white, "Unknown item definition: " .. tostring(id) .. "\n")
        return nil
    end
    return self:new(def)
end

---------------------------------------------------------------------------
-- Getters - Used by ZD_InvSlot, ZD_InvItem, ZD_EquipSlot, and menus
---------------------------------------------------------------------------

function ZD_ItemBase:GetID()          return self.m_sID end
function ZD_ItemBase:GetName()        return self.m_sName end
function ZD_ItemBase:GetDescription() return self.m_sDescription end
function ZD_ItemBase:GetCategory()    return self.m_sCategory end
function ZD_ItemBase:GetWeight()      return self.m_flWeight * self.m_iStack end
function ZD_ItemBase:GetBaseWeight()  return self.m_flWeight end
function ZD_ItemBase:GetRarity()      return self.m_sRarity end

--- Returns width, height in grid cells
function ZD_ItemBase:GetSize()
    return self.m_iWidth, self.m_iHeight
end

--- Returns the cached Material object for the item icon
function ZD_ItemBase:GetIcon()
    return self.m_matIcon
end

--- Returns the item type string (generic, small, weapon, armor, consumable)
function ZD_ItemBase:GetType()
    return self.m_sItemType
end

--- Returns the body region this item equips to (nil if not equippable)
function ZD_ItemBase:GetEquipRegion()
    return self.m_sEquipRegion
end

--- Returns true if this item can be equipped
function ZD_ItemBase:IsEquippable()
    return self.m_sEquipRegion ~= nil
end

--- Returns defense value (for armor pieces)
function ZD_ItemBase:GetDefense()
    return self.m_iDefense
end

---------------------------------------------------------------------------
-- Storage - Items that grant inventory containers when equipped
---------------------------------------------------------------------------

--- Returns cols, rows if this item grants storage (e.g. a backpack)
function ZD_ItemBase:GetStorageSize()
    if self.m_iStorageCols and self.m_iStorageRows then
        return self.m_iStorageCols, self.m_iStorageRows
    end
    return nil, nil
end

--- Returns the slot type filter for the granted storage
function ZD_ItemBase:GetStorageSlotType()
    return self.m_sStorageSlotType or "generic"
end

---------------------------------------------------------------------------
-- Stacking
---------------------------------------------------------------------------

function ZD_ItemBase:GetStack()    return self.m_iStack end
function ZD_ItemBase:GetMaxStack() return self.m_iMaxStack end

function ZD_ItemBase:IsStackable()
    return self.m_iMaxStack > 1
end

function ZD_ItemBase:CanAddToStack(amount)
    return (self.m_iStack + (amount or 1)) <= self.m_iMaxStack
end

--- Add to the stack. Returns the overflow (items that didn't fit).
function ZD_ItemBase:AddToStack(amount)
    amount = amount or 1
    local total = self.m_iStack + amount
    if total <= self.m_iMaxStack then
        self.m_iStack = total
        return 0
    else
        self.m_iStack = self.m_iMaxStack
        return total - self.m_iMaxStack
    end
end

--- Remove from the stack. Returns true if the stack is now empty.
function ZD_ItemBase:RemoveFromStack(amount)
    amount = amount or 1
    self.m_iStack = math.max(0, self.m_iStack - amount)
    return self.m_iStack <= 0
end

---------------------------------------------------------------------------
-- Actions - Override these in subclasses or via definition callbacks
---------------------------------------------------------------------------

--- Called when the player uses the item
function ZD_ItemBase:Use(ply)
    if self.m_fnOnUse then
        return self.m_fnOnUse(ply, self)
    end
end

--- Called when the item is equipped to a slot
function ZD_ItemBase:OnEquip(ply)
    if self.m_fnOnEquip then
        return self.m_fnOnEquip(ply, self)
    end
end

--- Called when the item is unequipped from a slot
function ZD_ItemBase:OnUnequip(ply)
    if self.m_fnOnUnequip then
        return self.m_fnOnUnequip(ply, self)
    end
end

---------------------------------------------------------------------------
-- Rarity Colors (for UI rendering)
---------------------------------------------------------------------------

local RARITY_COLORS = {
    common    = Color(180, 180, 180),
    uncommon  = Color(80,  200, 80),
    rare      = Color(60,  120, 255),
    epic      = Color(180, 60,  255),
    legendary = Color(255, 180, 40),
}

function ZD_ItemBase:GetRarityColor()
    return RARITY_COLORS[self.m_sRarity] or RARITY_COLORS.common
end

---------------------------------------------------------------------------
-- Serialization (for networking / saving)
---------------------------------------------------------------------------

--- Serialize this instance to a simple table
function ZD_ItemBase:Serialize()
    return {
        id    = self.m_sID,
        stack = self.m_iStack,
    }
end

--- Deserialize: create an instance from a saved table
function ZD_ItemBase.Deserialize(tbl)
    if not tbl or not tbl.id then return nil end
    local inst = ZD_ItemBase:FromDef(tbl.id)
    if inst and tbl.stack then
        inst.m_iStack = tbl.stack
    end
    return inst
end

---------------------------------------------------------------------------
-- Debug
---------------------------------------------------------------------------

function ZD_ItemBase:__tostring()
    return string.format("[Item: %s x%d]", self.m_sName, self.m_iStack)
end

---------------------------------------------------------------------------
-- Make ZDEV.ItemBase accessible globally
---------------------------------------------------------------------------

ZDEV.ItemBase = ZD_ItemBase

if ZDEV.FILE then ZDEV.FILE.SetLoaded( _f ) end

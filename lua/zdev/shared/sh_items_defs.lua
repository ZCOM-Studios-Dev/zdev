-- ZDEV_UID: ZDEV_FUNC_ITEMS_DEFS | Path: ZDEV.Items.Definitions
local _f = 'zdev/shared/sh_items_defs.lua'
if ZDEV and ZDEV.FILE and ZDEV.FILE.Loaded( _f ) then return end

--[[
    ZDEV Starter Item Definitions
    Registers base items for the inventory and equipment system.
    All items are registered via ZDEV.RegisterItem() and
    instantiated at runtime with ZD_ItemBase:FromDef(id).

    Context: Shared
]]

---------------------------------------------------------------------------
-- EQUIPMENT: Backpacks (grant inventory storage when equipped)
---------------------------------------------------------------------------

ZDEV.RegisterItem("equip_satchel", {
    name         = "Satchel",
    description  = "A small leather satchel. Better than pockets.",
    width = 2, height = 2,
    icon         = "icon16/briefcase.png",
    weight       = 1.5,
    category     = "equipment",
    itemType     = "armor",
    equipRegion  = "backpack",
    storageCols  = 4, storageRows = 2,
    rarity       = "common",
})

ZDEV.RegisterItem("equip_backpack", {
    name         = "Military Backpack",
    description  = "Standard-issue field backpack. Roomy.",
    width = 2, height = 3,
    icon         = "icon16/box.png",
    weight       = 3,
    category     = "equipment",
    itemType     = "armor",
    equipRegion  = "backpack",
    storageCols  = 6, storageRows = 4,
    rarity       = "uncommon",
})

ZDEV.RegisterItem("equip_duffel", {
    name         = "Heavy Duffel Bag",
    description  = "Oversized military duffel. Holds everything, weighs a ton.",
    width = 3, height = 3,
    icon         = "icon16/package.png",
    weight       = 5,
    category     = "equipment",
    itemType     = "armor",
    equipRegion  = "backpack",
    storageCols  = 8, storageRows = 5,
    rarity       = "rare",
})

---------------------------------------------------------------------------
-- EQUIPMENT: Head
---------------------------------------------------------------------------

ZDEV.RegisterItem("equip_hardhat", {
    name         = "Hard Hat",
    description  = "Basic head protection. OSHA approved.",
    width = 2, height = 2,
    icon         = "icon16/shield.png",
    weight       = 1,
    category     = "equipment",
    itemType     = "armor",
    equipRegion  = "head",
    defense      = 5,
    rarity       = "common",
})

ZDEV.RegisterItem("equip_combhelmet", {
    name         = "Combat Helmet",
    description  = "Ballistic helmet with visor mount.",
    width = 2, height = 2,
    icon         = "icon16/shield.png",
    weight       = 2,
    category     = "equipment",
    itemType     = "armor",
    equipRegion  = "head",
    defense      = 15,
    rarity       = "uncommon",
})

---------------------------------------------------------------------------
-- EQUIPMENT: Chest
---------------------------------------------------------------------------

ZDEV.RegisterItem("equip_vest_light", {
    name         = "Light Vest",
    description  = "Kevlar-lined vest. Stops small caliber rounds.",
    width = 2, height = 3,
    icon         = "icon16/shield.png",
    weight       = 4,
    category     = "equipment",
    itemType     = "armor",
    equipRegion  = "chest",
    defense      = 20,
    rarity       = "common",
})

ZDEV.RegisterItem("equip_vest_heavy", {
    name         = "Heavy Body Armor",
    description  = "Ceramic plate carrier. Slows you down but keeps you alive.",
    width = 2, height = 3,
    icon         = "icon16/shield.png",
    weight       = 8,
    category     = "equipment",
    itemType     = "armor",
    equipRegion  = "chest",
    defense      = 45,
    rarity       = "rare",
})

---------------------------------------------------------------------------
-- EQUIPMENT: Legs
---------------------------------------------------------------------------

ZDEV.RegisterItem("equip_cargo_pants", {
    name         = "Cargo Pants",
    description  = "Rugged pants with deep pockets.",
    width = 2, height = 2,
    icon         = "icon16/shield.png",
    weight       = 1.5,
    category     = "equipment",
    itemType     = "armor",
    equipRegion  = "legs",
    defense      = 5,
    storageCols  = 2, storageRows = 2,
    storageSlotType = "small",
    rarity       = "common",
})

ZDEV.RegisterItem("equip_tactical_pants", {
    name         = "Tactical Pants",
    description  = "Reinforced tactical trousers with multiple utility pockets.",
    width = 2, height = 2,
    icon         = "icon16/shield.png",
    weight       = 2,
    category     = "equipment",
    itemType     = "armor",
    equipRegion  = "legs",
    defense      = 10,
    storageCols  = 3, storageRows = 2,
    storageSlotType = "small",
    rarity       = "uncommon",
})

---------------------------------------------------------------------------
-- EQUIPMENT: Feet
---------------------------------------------------------------------------

ZDEV.RegisterItem("equip_boots", {
    name         = "Work Boots",
    description  = "Steel-toed boots. Functional.",
    width = 2, height = 1,
    icon         = "icon16/shield.png",
    weight       = 1.5,
    category     = "equipment",
    itemType     = "armor",
    equipRegion  = "feet",
    defense      = 3,
    rarity       = "common",
})

---------------------------------------------------------------------------
-- EQUIPMENT: Hands
---------------------------------------------------------------------------

ZDEV.RegisterItem("equip_gloves", {
    name         = "Tactical Gloves",
    description  = "Reinforced knuckle gloves. Good grip.",
    width = 1, height = 1,
    icon         = "icon16/shield.png",
    weight       = 0.5,
    category     = "equipment",
    itemType     = "armor",
    equipRegion  = "hands",
    defense      = 2,
    rarity       = "common",
})

---------------------------------------------------------------------------
-- CONSUMABLES
---------------------------------------------------------------------------

ZDEV.RegisterItem("item_medkit", {
    name         = "Medkit",
    description  = "Restores 25 health.",
    width = 1, height = 1,
    icon         = "icon16/heart.png",
    weight       = 1,
    category     = "consumable",
    itemType     = "small",
    maxStack     = 5,
    rarity       = "common",
    onUse        = function(ply, inst)
        if not IsValid(ply) then return end
        if SERVER then
            ply:SetHealth(math.min(ply:Health() + 25, ply:GetMaxHealth()))
        end
        inst:RemoveFromStack(1)
    end,
})

ZDEV.RegisterItem("item_medkit_large", {
    name         = "Large Medkit",
    description  = "Restores 75 health. Field surgery in a box.",
    width = 2, height = 1,
    icon         = "icon16/heart_add.png",
    weight       = 2,
    category     = "consumable",
    itemType     = "generic",
    maxStack     = 3,
    rarity       = "uncommon",
    onUse        = function(ply, inst)
        if not IsValid(ply) then return end
        if SERVER then
            ply:SetHealth(math.min(ply:Health() + 75, ply:GetMaxHealth()))
        end
        inst:RemoveFromStack(1)
    end,
})

ZDEV.RegisterItem("item_battery", {
    name         = "Suit Battery",
    description  = "Restores 15 armor points.",
    width = 1, height = 1,
    icon         = "icon16/lightning.png",
    weight       = 0.5,
    category     = "consumable",
    itemType     = "small",
    maxStack     = 10,
    rarity       = "common",
    onUse        = function(ply, inst)
        if not IsValid(ply) then return end
        if SERVER then
            ply:SetArmor(math.min(ply:Armor() + 15, 100))
        end
        inst:RemoveFromStack(1)
    end,
})

ZDEV.RegisterItem("item_ration", {
    name         = "Field Ration",
    description  = "Bland but nutritious. Restores 10 health.",
    width = 1, height = 1,
    icon         = "icon16/cake.png",
    weight       = 0.3,
    category     = "consumable",
    itemType     = "small",
    maxStack     = 10,
    rarity       = "common",
    onUse        = function(ply, inst)
        if not IsValid(ply) then return end
        if SERVER then
            ply:SetHealth(math.min(ply:Health() + 10, ply:GetMaxHealth()))
        end
        inst:RemoveFromStack(1)
    end,
})

---------------------------------------------------------------------------
-- AMMO
---------------------------------------------------------------------------

ZDEV.RegisterItem("item_ammo_pistol", {
    name         = "Pistol Ammo",
    description  = "Box of 9mm rounds.",
    width = 1, height = 1,
    icon         = "icon16/bullet_orange.png",
    weight       = 0.5,
    category     = "ammo",
    itemType     = "small",
    maxStack     = 5,
    rarity       = "common",
    onUse        = function(ply, inst)
        if not IsValid(ply) then return end
        if SERVER then
            ply:GiveAmmo(20, "Pistol")
        end
        inst:RemoveFromStack(1)
    end,
})

ZDEV.RegisterItem("item_ammo_smg", {
    name         = "SMG Ammo",
    description  = "Magazine of SMG1 rounds.",
    width = 1, height = 1,
    icon         = "icon16/bullet_yellow.png",
    weight       = 0.8,
    category     = "ammo",
    itemType     = "small",
    maxStack     = 5,
    rarity       = "common",
    onUse        = function(ply, inst)
        if not IsValid(ply) then return end
        if SERVER then
            ply:GiveAmmo(45, "SMG1")
        end
        inst:RemoveFromStack(1)
    end,
})

ZDEV.RegisterItem("item_ammo_rifle", {
    name         = "Rifle Ammo",
    description  = "Heavy caliber rounds for AR2 platforms.",
    width = 1, height = 1,
    icon         = "icon16/bullet_red.png",
    weight       = 1,
    category     = "ammo",
    itemType     = "small",
    maxStack     = 5,
    rarity       = "common",
    onUse        = function(ply, inst)
        if not IsValid(ply) then return end
        if SERVER then
            ply:GiveAmmo(30, "AR2")
        end
        inst:RemoveFromStack(1)
    end,
})

ZDEV.RegisterItem("item_ammo_shotgun", {
    name         = "Shotgun Shells",
    description  = "Box of 12-gauge buckshot.",
    width = 1, height = 1,
    icon         = "icon16/bullet_black.png",
    weight       = 1.2,
    category     = "ammo",
    itemType     = "small",
    maxStack     = 4,
    rarity       = "common",
    onUse        = function(ply, inst)
        if not IsValid(ply) then return end
        if SERVER then
            ply:GiveAmmo(12, "Buckshot")
        end
        inst:RemoveFromStack(1)
    end,
})

---------------------------------------------------------------------------
-- WEAPONS (equippable to weapon slot)
---------------------------------------------------------------------------

ZDEV.RegisterItem("weapon_crowbar", {
    name         = "Crowbar",
    description  = "The right tool for the wrong job.",
    width = 1, height = 3,
    icon         = "icon16/wrench.png",
    weight       = 2,
    category     = "weapon",
    itemType     = "weapon",
    equipRegion  = "weapon",
    rarity       = "common",
    onEquip      = function(ply, inst)
        if SERVER and IsValid(ply) then
            ply:Give("weapon_crowbar")
        end
    end,
    onUnequip    = function(ply, inst)
        if SERVER and IsValid(ply) then
            ply:StripWeapon("weapon_crowbar")
        end
    end,
})

ZDEV.RegisterItem("weapon_pistol", {
    name         = "9mm Pistol",
    description  = "Standard sidearm. Reliable.",
    width = 2, height = 1,
    icon         = "icon16/gun.png",
    weight       = 1.5,
    category     = "weapon",
    itemType     = "weapon",
    equipRegion  = "weapon",
    rarity       = "common",
    onEquip      = function(ply, inst)
        if SERVER and IsValid(ply) then
            ply:Give("weapon_pistol")
        end
    end,
    onUnequip    = function(ply, inst)
        if SERVER and IsValid(ply) then
            ply:StripWeapon("weapon_pistol")
        end
    end,
})

ZDEV.RegisterItem("weapon_357", {
    name         = ".357 Magnum",
    description  = "High-caliber revolver. Loud and effective.",
    width = 2, height = 1,
    icon         = "icon16/gun.png",
    weight       = 2,
    category     = "weapon",
    itemType     = "weapon",
    equipRegion  = "weapon",
    rarity       = "uncommon",
    onEquip      = function(ply, inst)
        if SERVER and IsValid(ply) then
            ply:Give("weapon_357")
        end
    end,
    onUnequip    = function(ply, inst)
        if SERVER and IsValid(ply) then
            ply:StripWeapon("weapon_357")
        end
    end,
})

ZDEV.RegisterItem("weapon_smg1", {
    name         = "MP7 Submachine Gun",
    description  = "Compact PDW. High rate of fire with grenade launcher.",
    width = 3, height = 1,
    icon         = "icon16/gun.png",
    weight       = 3,
    category     = "weapon",
    itemType     = "weapon",
    equipRegion  = "weapon",
    rarity       = "uncommon",
    onEquip      = function(ply, inst)
        if SERVER and IsValid(ply) then
            ply:Give("weapon_smg1")
        end
    end,
    onUnequip    = function(ply, inst)
        if SERVER and IsValid(ply) then
            ply:StripWeapon("weapon_smg1")
        end
    end,
})

---------------------------------------------------------------------------
-- TOOLS / MISC
---------------------------------------------------------------------------

ZDEV.RegisterItem("item_flashlight", {
    name         = "Flashlight",
    description  = "Handheld torch. Cuts through the dark.",
    width = 1, height = 1,
    icon         = "icon16/lightbulb.png",
    weight       = 0.5,
    category     = "tool",
    itemType     = "small",
    rarity       = "common",
})

ZDEV.RegisterItem("item_lockpick", {
    name         = "Lockpick Set",
    description  = "Precision picks for persuading locked doors.",
    width = 1, height = 1,
    icon         = "icon16/key.png",
    weight       = 0.3,
    category     = "tool",
    itemType     = "small",
    rarity       = "uncommon",
})

ZDEV.RegisterItem("item_radio", {
    name         = "Handheld Radio",
    description  = "Short-range communication device.",
    width = 1, height = 2,
    icon         = "icon16/transmit.png",
    weight       = 0.8,
    category     = "tool",
    itemType     = "generic",
    rarity       = "common",
})

ZDEV.RegisterItem("item_repair_kit", {
    name         = "Repair Kit",
    description  = "Tools and tape for patching up armor. Restores 20 armor.",
    width = 2, height = 1,
    icon         = "icon16/wrench_orange.png",
    weight       = 1.5,
    category     = "consumable",
    itemType     = "generic",
    maxStack     = 3,
    rarity       = "uncommon",
    onUse        = function(ply, inst)
        if not IsValid(ply) then return end
        if SERVER then
            ply:SetArmor(math.min(ply:Armor() + 20, 100))
        end
        inst:RemoveFromStack(1)
    end,
})

ZDEV.RegisterItem("item_scrap_metal", {
    name         = "Scrap Metal",
    description  = "Salvaged metal parts. Used for crafting.",
    width = 1, height = 1,
    icon         = "icon16/cog.png",
    weight       = 1,
    category     = "material",
    itemType     = "small",
    maxStack     = 20,
    rarity       = "common",
})

ZDEV.RegisterItem("item_circuit_board", {
    name         = "Circuit Board",
    description  = "Salvaged electronics. Useful for advanced crafting.",
    width = 1, height = 1,
    icon         = "icon16/plugin.png",
    weight       = 0.3,
    category     = "material",
    itemType     = "small",
    maxStack     = 10,
    rarity       = "uncommon",
})

---------------------------------------------------------------------------
-- RARE / LEGENDARY
---------------------------------------------------------------------------

ZDEV.RegisterItem("equip_exo_helmet", {
    name         = "Exosuit Helmet",
    description  = "Powered helmet with integrated HUD and comms.",
    width = 2, height = 2,
    icon         = "icon16/shield.png",
    weight       = 2.5,
    category     = "equipment",
    itemType     = "armor",
    equipRegion  = "head",
    defense      = 30,
    rarity       = "epic",
})

ZDEV.RegisterItem("equip_exo_vest", {
    name         = "Exosuit Chestplate",
    description  = "Powered armor core. Absorbs extreme punishment.",
    width = 2, height = 3,
    icon         = "icon16/shield.png",
    weight       = 10,
    category     = "equipment",
    itemType     = "armor",
    equipRegion  = "chest",
    defense      = 60,
    rarity       = "legendary",
})

ZDEV.RegisterItem("weapon_ar2", {
    name         = "Pulse Rifle",
    description  = "Combine Overwatch standard-issue. Dark energy secondary fire.",
    width = 3, height = 2,
    icon         = "icon16/gun.png",
    weight       = 4,
    category     = "weapon",
    itemType     = "weapon",
    equipRegion  = "weapon",
    rarity       = "epic",
    onEquip      = function(ply, inst)
        if SERVER and IsValid(ply) then
            ply:Give("weapon_ar2")
        end
    end,
    onUnequip    = function(ply, inst)
        if SERVER and IsValid(ply) then
            ply:StripWeapon("weapon_ar2")
        end
    end,
})

if ZDEV.FILE then ZDEV.FILE.SetLoaded( _f ) end

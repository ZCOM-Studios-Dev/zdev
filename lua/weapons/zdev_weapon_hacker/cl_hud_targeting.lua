--[[
    ZDEV Hacker SWEP - HUD Targeting System
    
    Sci-Fi HUD overlay with smart targeting, lock-on system, 
    signal strength analysis, and target information display.
]]

-- ============================================================================
-- LOCALIZED FUNCTIONS FOR PERFORMANCE
-- ============================================================================
local RealTime = RealTime
local IsValid = IsValid
local LocalPlayer = LocalPlayer
local ScrW, ScrH = ScrW, ScrH
local math_sin, math_cos = math.sin, math.cos
local math_Clamp = math.Clamp
local string_format = string.format
local surface = surface
local draw = draw
local util = util

-- ============================================================================
-- HUD MATERIALS
-- Include all the files in the materials folder
-- ============================================================================
local hudMats = {
    -- Components subdirectory
    components = {
        vect_01a = "zdev/hud/components/vect_01a.png",
        vec_circle_3 = "zdev/hud/components/vec_circle_3.png",
        vec_circle_2 = "zdev/hud/components/vec_circle_2.png",
        vec_circle_1 = "zdev/hud/components/vec_circle_1.png",
        vect_02a = "zdev/hud/components/vect_02a.png",
        vec_circle_0 = "zdev/hud/components/vec_circle_0.png",
        vect_03a = "zdev/hud/components/vect_03a.png",
        frame_hexagon_01 = "zdev/hud/components/frame_hexagon_01.png",
        hud_icon_x_thin = "zdev/hud/components/hud_icon_x_thin.png",
        hud_icon_x_thin_outline = "zdev/hud/components/hud_icon_x_thin_outline.png",
        hud_icon_x_regular = "zdev/hud/components/hud_icon_x_regular.png",
        hud_icon_x_thick = "zdev/hud/components/hud_icon_x_thick.png",
        hud_icon_x_thick_outline = "zdev/hud/components/hud_icon_x_thick_outline.png",
        hud_icon_triangle_128_outline_4 = "zdev/hud/components/hud_icon_triangle_128_outline-4.png",
        hud_icon_triangle_128_outline_2 = "zdev/hud/components/hud_icon_triangle_128_outline-2.png",
        hud_icon_triangle_64_outline_4 = "zdev/hud/components/hud_icon_triangle_64_outline-4.png",
        hud_icon_triangle_64_outline_2 = "zdev/hud/components/hud_icon_triangle_64_outline-2.png",
        hud_icon_triangle_32_outline_2 = "zdev/hud/components/hud_icon_triangle_32_outline-2.png",
        hud_icon_triangle_32_outline_4 = "zdev/hud/components/hud_icon_triangle_32_outline-4.png",
        hud_icon_square_128_outline_4 = "zdev/hud/components/hud_icon_square_128_outline-4.png",
        hud_icon_square_96_outline_4 = "zdev/hud/components/hud_icon_square_96_outline-4.png",
        hud_icon_square_64_outline_4 = "zdev/hud/components/hud_icon_square_64_outline-4.png",
        hud_icon_square_32_outline_2 = "zdev/hud/components/hud_icon_square_32_outline-2.png",
        hud_icon_square_32_outline_2_alt = "zdev/hud/components/hud_icon_square_32_outline-2 (1).png",
        hud_icon_square_64_outline_2 = "zdev/hud/components/hud_icon_square_64_outline-2.png",
        hud_icon_square_96_outline_2 = "zdev/hud/components/hud_icon_square_96_outline-2.png",
        hud_icon_square_128_outline_2 = "zdev/hud/components/hud_icon_square_128_outline-2.png",
    },

    -- Icon subdirectory
    icon = {
        battery = "zdev/hud/icon/icon_battery.png",
        arm = "zdev/hud/icon/icon_arm.png",
        oxygen = "zdev/hud/icon/icon_oxygen.png",
        energy = "zdev/hud/icon/icon_energy.png",
        health = "zdev/hud/icon/icon_health.png",
        armor = "zdev/hud/icon/icon_armor.png",
        turret = "zdev/hud/icon/icon_turret.png",
        scanner = "zdev/hud/icon/icon_scanner.png",
        camera = "zdev/hud/icon/icon_camera.png",
        manhack = "zdev/hud/icon/icon_manhack.png"
    },

    -- Target subdirectory
    target = {
        arrow_1 = "zdev/hud/target/arrow_1.png",
        arrow_2 = "zdev/hud/target/arrow_2.png",
        cir_01 = "zdev/hud/target/cir_01.png",
        cir_02 = "zdev/hud/target/cir_02.png",
        cir_03 = "zdev/hud/target/cir_03.png",
        cir_04 = "zdev/hud/target/cir_04.png",
        cir_05 = "zdev/hud/target/cir_05.png",
        cir_06 = "zdev/hud/target/cir_06.png",
        cir_07 = "zdev/hud/target/cir_07.png",
        cir_08 = "zdev/hud/target/cir_08.png",
        cir_09 = "zdev/hud/target/cir_09.png",
        sqr_01 = "zdev/hud/target/sqr_01.png",
        sqr_03 = "zdev/hud/target/sqr_03.png",
        sqr_04 = "zdev/hud/target/sqr_04.png",
        sqr_05 = "zdev/hud/target/sqr_05.png",
        sqr_09 = "zdev/hud/target/sqr_09.png",
        sqr_10 = "zdev/hud/target/sqr_10.png",
        hex_01 = "zdev/hud/target/hex_01.png",
        hex_01a = "zdev/hud/target/hex_01a.png",
        hex_02 = "zdev/hud/target/hex_02.png",
        terminal = "zdev/hud/target/terminal.png",
        det_2xs_18 = "zdev/hud/target/det_2xs_18.png",
        det_2xs_19 = "zdev/hud/target/det_2xs_19.png",
        det_2xs_25 = "zdev/hud/target/det_2xs_25.png",
        det_2xs_26 = "zdev/hud/target/det_2xs_26.png",
        det_2xs_28 = "zdev/hud/target/det_2xs_28.png",
        det_2xs_08 = "zdev/hud/target/det_2xs_08.png",
        det_2xs_11 = "zdev/hud/target/det_2xs_11.png",
        det_2xs_13 = "zdev/hud/target/det_2xs_13.png",
        det_2xs_14 = "zdev/hud/target/det_2xs_14.png",
        det_2xs_15 = "zdev/hud/target/det_2xs_15.png",
        det_2xs_16 = "zdev/hud/target/det_2xs_16.png",
        det_2xs_17 = "zdev/hud/target/det_2xs_17.png",
        img_1 = "zdev/hud/target/1.png",
        img_11 = "zdev/hud/target/11.png",
        img_12 = "zdev/hud/target/12.png",
        img_13 = "zdev/hud/target/13.png",
        img_14 = "zdev/hud/target/14.png",
        img_16 = "zdev/hud/target/16.png",
        img_18 = "zdev/hud/target/18.png",
        img_19 = "zdev/hud/target/19.png",
        img_2 = "zdev/hud/target/2.png",
        img_3 = "zdev/hud/target/3.png",
        img_7 = "zdev/hud/target/7.png",
    },

    -- Reticle subdirectory
    reticle = {
        cross_01a = "zdev/hud/reticle/cross_01a.png",
        circle_center_x_01 = "zdev/hud/reticle/circle_center-x_01.png",
        double_square_01 = "zdev/hud/reticle/double-square_01.png",
        quarter_circle_01 = "zdev/hud/reticle/quarter-circle_01.png",
        circle_med_01 = "zdev/hud/reticle/circle-med_01.png",
        cross_med_01 = "zdev/hud/reticle/cross-med_01.png",
    }
}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================
local Config = {
    -- Targeting
    MaxRange = 2000,
    LockOnFOV = 15,         -- Degrees from crosshair to consider for lock
    ScanFOV = 75,           -- Full scan cone
    LockOnTime = 0.5,       -- Time to acquire lock
    LockBreakRange = 2500,  -- Distance where lock breaks
    
    -- Signal
    MaxSignalDist = 1500,
    MinSignal = 5,
    MaxSignal = 100,
    ObstacleSignalPenalty = 25,
    
    -- Colors (cyberpunk theme matching weapon)
    ColorPrimary = Color(0, 255, 255, 255),     -- Cyan
    ColorSecondary = Color(0, 255, 100, 255),   -- Green
    ColorWarning = Color(255, 200, 0, 255),     -- Yellow/Orange
    ColorDanger = Color(255, 50, 50, 255),      -- Red
    ColorBackground = Color(0, 12, 18, 180),
    ColorGrid = Color(0, 80, 100, 40),
}

-- ============================================================================
-- ELECTRONIC TARGET CLASS DEFINITIONS
-- ============================================================================
local ElectronicTargets = {
    -- HL2 NPCs
    ["npc_manhack"] = { name = "MANHACK", os = "CombineOS 2.7", browser = "N/A", threat = "LOW" },
    ["npc_rollermine"] = { name = "ROLLERMINE", os = "CombineOS 3.1", browser = "N/A", threat = "MEDIUM" },
    ["npc_turret_floor"] = { name = "FLOOR TURRET", os = "AperturOS 4.2", browser = "N/A", threat = "HIGH" },
    ["npc_turret_ceiling"] = { name = "CEILING TURRET", os = "AperturOS 4.2", browser = "N/A", threat = "HIGH" },
    ["npc_clawscanner"] = { name = "SCANNER", os = "CombineOS 2.3", browser = "ScanView 1.0", threat = "LOW" },
    ["npc_cscanner"] = { name = "CITY SCANNER", os = "CombineOS 2.5", browser = "CityScan 1.2", threat = "LOW" },
    ["npc_combine_camera"] = { name = "SECURITY CAM", os = "CombineOS 1.8", browser = "N/A", threat = "NONE" },
    ["npc_turret_ground"] = { name = "GROUND TURRET", os = "MilitaryOS 5.0", browser = "N/A", threat = "HIGH" },
    ["npc_strider"] = { name = "STRIDER", os = "CombineOS 6.0", browser = "WarNet 2.0", threat = "EXTREME" },
    ["npc_hunter"] = { name = "HUNTER", os = "CombineOS 5.5", browser = "HuntNet 1.5", threat = "HIGH" },
    ["npc_combinegunship"] = { name = "GUNSHIP", os = "CombineOS 6.2", browser = "AirNet 3.0", threat = "EXTREME" },
    
    -- Combine soldiers (cybernetic)
    ["npc_combine_s"] = { name = "COMBINE UNIT", os = "BioSynth 3.0", browser = "TacNet 2.1", threat = "MEDIUM" },
    ["npc_metropolice"] = { name = "METROCOP", os = "CivControl 2.0", browser = "PatrolNet 1.0", threat = "LOW" },
    
    -- Mines and explosives
    ["combine_mine"] = { name = "HOPPER MINE", os = "CombineOS 1.5", browser = "N/A", threat = "HIGH" },
    ["npc_tripmine"] = { name = "TRIPMINE", os = "ExplosiveOS 1.0", browser = "N/A", threat = "HIGH" },
    
    -- Vehicles
    ["prop_vehicle_apc"] = { name = "APC", os = "CombineOS 4.8", browser = "TacNet 3.0", threat = "EXTREME" },
    
    -- Generic electronic props
    ["prop_physics"] = { name = "DEVICE", os = "Unknown", browser = "N/A", threat = "UNKNOWN" },
    ["prop_door_rotating"] = { name = "DOOR", os = "CombineOS 1.0", browser = "N/A", threat = "NONE" },
    ["func_door"] = { name = "DOOR", os = "CombineOS 1.0", browser = "N/A", threat = "NONE" },
    ["gmod_turret"] = { name = "TURRET", os = "MilitaryOS 4.5", browser = "N/A", threat = "HIGH" },
    ["gmod_camera"] = { name = "SECURITY CAM", os = "SurveilOS 1.0", browser = "N/A", threat = "NONE" },
    ["zdev_objective_terminal"] = { name = "TERMINAL", os = "ZetaOS 1.0", browser = "WebX 1.0", threat = "LOW" },
    -- Lights/lamps
    ["gmod_light"] = { name = "LIGHT", os = "LightOS 1.0", browser = "N/A", threat = "NONE" },
    ["gmod_lamp"] = { name = "LAMP", os = "LightOS 1.0", browser = "N/A", threat = "NONE" },
    ["light"] = { name = "LIGHT", os = "LightOS 1.0", browser = "N/A", threat = "NONE" },
    ["light_dynamic"] = { name = "LIGHT", os = "LightOS 1.0", browser = "N/A", threat = "NONE" },
    ["light_environment"] = { name = "LIGHT", os = "LightOS 1.0", browser = "N/A", threat = "NONE" },
    ["light_spot"] = { name = "LIGHT", os = "LightOS 1.0", browser = "N/A", threat = "NONE" },
    ["zdev_ent_light_point"] = { name = "LIGHT", os = "LightOS 1.0", browser = "N/A", threat = "NONE" },
}

-- ============================================================================
-- FAKE DATA GENERATORS
-- ============================================================================
local function GenerateIP(ent)
    if not ent.HackerIP then
        local hash = ent:EntIndex() * 17 + 42
        ent.HackerIP = string_format("%d.%d.%d.%d",
            10 + (hash % 245),
            (hash * 3) % 256,
            (hash * 7) % 256,
            1 + (hash * 11) % 254
        )
    end
    return ent.HackerIP
end

local function GenerateMAC(ent)
    if not ent.HackerMAC then
        local hex = "0123456789ABCDEF"
        local hash = ent:EntIndex() * 31
        local mac = ""
        for i = 1, 6 do
            if i > 1 then mac = mac .. ":" end
            local b1 = ((hash * i) % 16) + 1
            local b2 = ((hash * i * 3) % 16) + 1
            mac = mac .. hex[b1] .. hex[b2]
        end
        ent.HackerMAC = mac
    end
    return ent.HackerMAC
end

local function GeneratePort(ent)
    if not ent.HackerPort then
        ent.HackerPort = 1000 + (ent:EntIndex() * 137) % 64535
    end
    return ent.HackerPort
end

-- ============================================================================
-- TARGET DETECTION SYSTEM
-- ============================================================================
local TargetCache = {}
local LastScanTime = 0
local ScanInterval = 0.1  -- Scan every 100ms

local function ScanForTargets(ply, wep)
    local rt = RealTime()
    if rt - LastScanTime < ScanInterval then
        return TargetCache
    end
    LastScanTime = rt
    
    TargetCache = {}
    
    local eyePos = ply:EyePos()
    local eyeAng = ply:EyeAngles()
    local forward = eyeAng:Forward()
    local scrCenter = Vector(ScrW() * 0.5, ScrH() * 0.5, 0)
    
    -- Find all potential targets
    for _, ent in ipairs(ents.GetAll()) do
        if not                                                                                                                                                                                                                                                                                       IsValid(ent) then continue end
        if ent == ply then continue end
        
        local class = ent:GetClass()
        local targetInfo = ElectronicTargets[class]
        
        -- Also check for generic NPCs
        if not targetInfo and ent:IsNPC() then
            targetInfo = { name = "UNKNOWN NPC", os = "Unknown", browser = "N/A", threat = "UNKNOWN" }
        end
        
        if not targetInfo then continue end

        local entPos = ent:GetPos()
        if ent:IsNPC() or ent:IsPlayer() then
            entPos = ent:EyePos() or ent:GetPos()
        else
            entPos = ent:WorldSpaceCenter() or ent:GetPos()
        end

        local dist = eyePos:Distance(entPos)
        if dist > Config.MaxRange then continue end

        -- Check if in scan FOV
        local toTarget = (entPos - eyePos):GetNormalized()
        local dot = forward:Dot(toTarget)
        local angleDiff = math.deg(math.acos(math_Clamp(dot, -1, 1)))

        if angleDiff > Config.ScanFOV then continue end

        -- Calculate screen position
        local screenPos = entPos:ToScreen()
        if not screenPos.visible then continue end

        -- Calculate distance from screen center (for smart targeting)
        local screenDist = math.sqrt((screenPos.x - scrCenter.x)^2 + (screenPos.y - scrCenter.y)^2)

        -- Check for obstacles (signal interference)
        local tr = util.TraceLine({
            start = eyePos,
            endpos = entPos,
            filter = ply,
            mask = MASK_SOLID_BRUSHONLY
        })

        local hasObstacle = tr.Hit and tr.Entity ~= ent

        -- Calculate signal strength
        local signalBase = 1 - (dist / Config.MaxSignalDist)
        local signal = math_Clamp(signalBase * Config.MaxSignal, Config.MinSignal, Config.MaxSignal)
        if hasObstacle then
            signal = math.max(Config.MinSignal, signal - Config.ObstacleSignalPenalty)
        end

        table.insert(TargetCache, {
            entity = ent,
            class = class,
            info = targetInfo,
            pos = entPos,
            screenPos = screenPos,
            screenDist = screenDist,
            distance = dist,
            angleDiff = angleDiff,
            signal = signal,
            hasObstacle = hasObstacle,
            ip = GenerateIP(ent),
            mac = GenerateMAC(ent),
            port = GeneratePort(ent),
        })
    end

    -- Sort by screen distance (closest to center first)
    table.sort(TargetCache, function(a, b)
        return a.screenDist < b.screenDist
    end)

    return TargetCache
end

-- ============================================================================
-- LOCK-ON SYSTEM
-- ============================================================================
local LockedTarget = nil
local LockProgress = 0
local LockAcquireStart = 0
local IsLocking = false

local function UpdateLockOn(wep, targets)
    local rt = RealTime()
    local ply = LocalPlayer()

    -- Check if we have a locked target
    if LockedTarget then
        if not IsValid(LockedTarget.entity) then
            LockedTarget = nil
            wep.LockedTarget = nil
            return
        end

        -- Update locked target data
        local ent = LockedTarget.entity
        local entPos = ent:WorldSpaceCenter() or ent:GetPos()
        local dist = ply:EyePos():Distance(entPos)

        -- Check if lock should break
        if dist > Config.LockBreakRange then
            LockedTarget = nil
            wep.LockedTarget = nil
            surface.PlaySound("buttons/button10.wav")
            return
        end

        -- Update position data
        LockedTarget.pos = entPos
        LockedTarget.distance = dist
        LockedTarget.screenPos = entPos:ToScreen()

        -- Recalculate signal
        local tr = util.TraceLine({
            start = ply:EyePos(),
            endpos = entPos,
            filter = ply,
            mask = MASK_SOLID_BRUSHONLY
        })
        LockedTarget.hasObstacle = tr.Hit and tr.Entity ~= ent

        local signalBase = 1 - (dist / Config.MaxSignalDist)
        LockedTarget.signal = math_Clamp(signalBase * Config.MaxSignal, Config.MinSignal, Config.MaxSignal)
        if LockedTarget.hasObstacle then
            LockedTarget.signal = math.max(Config.MinSignal, LockedTarget.signal - Config.ObstacleSignalPenalty)
        end
    end

    wep.LockedTarget = LockedTarget
end

-- ============================================================================
-- AIM ASSIST (Lock-on centering)
-- ============================================================================
local function ApplyAimAssist(ply, wep)
    if not LockedTarget then return end
    if not IsValid(LockedTarget.entity) then return end
    if not wep:GetOwner():KeyDown(IN_ATTACK2) then return end -- Only when holding RMB

    local ent = LockedTarget.entity
    local targetPos = ent:WorldSpaceCenter() or ent:GetPos()
    local eyePos = ply:EyePos()
    local currentAng = ply:EyeAngles()

    -- Calculate angle to target
    local toTarget = (targetPos - eyePos):GetNormalized()
    local targetAng = toTarget:Angle()

    -- Smooth interpolation
    local lerpSpeed = 0.08
    local newAng = Angle(
        Lerp(lerpSpeed, currentAng.p, targetAng.p),
        Lerp(lerpSpeed, currentAng.y, targetAng.y),
        0
    )

    -- Apply the new angle
    ply:SetEyeAngles(newAng)
end

-- ============================================================================
-- HUD DRAWING UTILITIES
-- ============================================================================

local function DrawScanLine(x, y, w, h, rt)
    local scanY = (rt * 80) % h
    surface.SetDrawColor(0, 255, 255, 30)
    surface.DrawRect(x, y + scanY, w, 2)
end

local function DrawCornerBrackets(x, y, w, h, size, color)
    surface.SetDrawColor(color)
    -- Top left
    surface.DrawLine(x, y, x + size, y)
    surface.DrawLine(x, y, x, y + size)
    -- Top right
    surface.DrawLine(x + w, y, x + w - size, y)
    surface.DrawLine(x + w, y, x + w, y + size)
    -- Bottom left
    surface.DrawLine(x, y + h, x + size, y + h)
    surface.DrawLine(x, y + h, x, y + h - size)
    -- Bottom right
    surface.DrawLine(x + w, y + h, x + w - size, y + h)
    surface.DrawLine(x + w, y + h, x + w, y + h - size)
end

local function DrawSignalBars(x, y, signal, maxBars)
    maxBars = maxBars or 5
    local barW, barH = 4, 12
    local spacing = 2
    local filledBars = math.ceil((signal / Config.MaxSignal) * maxBars)

    for i = 1, maxBars do
        local barX = x + (i - 1) * (barW + spacing)
        local height = barH * (i / maxBars)
        local barY = y + (barH - height)

        if i <= filledBars then
            local signalColor
            if signal >= 70 then
                signalColor = Config.ColorSecondary
            elseif signal >= 40 then
                signalColor = Config.ColorWarning
            else
                signalColor = Config.ColorDanger
            end
            surface.SetDrawColor(signalColor)
            surface.DrawRect(barX, barY, barW, height)
        else
            surface.SetDrawColor(60, 60, 60, 150)
            surface.DrawRect(barX, barY, barW, height)
        end
    end
end

local function DrawThreatIndicator(x, y, threat)
    local color
    if threat == "EXTREME" then
        color = Color(255, 0, 0)
    elseif threat == "HIGH" then
        color = Color(255, 100, 0)
    elseif threat == "MEDIUM" then
        color = Config.ColorWarning
    elseif threat == "LOW" then
        color = Config.ColorSecondary
    else
        color = Color(100, 100, 100)
    end

    draw.SimpleText("⚠ " .. threat, "DermaDefault", x, y, color, TEXT_ALIGN_LEFT)
end

-- ============================================================================
-- TARGET RETICLE DRAWING
-- ============================================================================
local function DrawTargetReticle(target, isLocked, rt)
    local sp = target.screenPos
    if not sp or not sp.visible then return end

    local x, y = sp.x, sp.y
    local size = isLocked and 40 or 30
    local pulse = math_sin(rt * (isLocked and 8 or 4)) * 5
    size = size + pulse

    local color = isLocked and Config.ColorSecondary or Config.ColorPrimary
    local alpha = isLocked and 255 or 180

    -- Animated rotation for locked targets
    local rotation = isLocked and (rt * 60) or 0

    surface.SetDrawColor(color.r, color.g, color.b, alpha)

    -- Draw rotating corner brackets
    local half = size / 2
    local cornerLen = size * 0.3

    if isLocked then
        -- Rotating locked reticle
        local rad = math.rad(rotation)

        for i = 0, 3 do
            local angle = (i * 90) + rotation
            local rad2 = math.rad(angle)
            local c, s = math_cos(rad2), math_sin(rad2)

            surface.SetDrawColor(color.r, color.g, color.b, alpha)
            -- Small tick marks
            local tickLen = 8
            surface.DrawLine(
                x + c * (half - 5), y + s * (half - 5),
                x + c * (half + tickLen), y + s * (half + tickLen)
            )
        end

        -- Center crosshair
        surface.DrawLine(x - 10, y, x - 4, y)
        surface.DrawLine(x + 4, y, x + 10, y)
        surface.DrawLine(x, y - 10, x, y - 4)
        surface.DrawLine(x, y + 4, x, y + 10)

        -- Lock indicator circle
        local circleSegs = 24
        for i = 0, circleSegs do
            local a1 = (i / circleSegs) * math.pi * 2 + rad
            local a2 = ((i + 1) / circleSegs) * math.pi * 2 + rad
            local r = half - 3
            surface.DrawLine(
                x + math_cos(a1) * r, y + math_sin(a1) * r,
                x + math_cos(a2) * r, y + math_sin(a2) * r
            )
        end
    else
        -- Standard scanning reticle
        DrawCornerBrackets(x - half, y - half, size, size, cornerLen, color)

        local size2 = size * 0.5
        local half2 = size2 / 2
        DrawMaterial(x - half2, y - half2, size2, size2, Material( hudMats.target.det_2xs_28), color)
        -- Center dot
        surface.DrawRect(x - 1, y - 1, 3, 3)
    end

    -- Distance indicator
    local distText = string_format("%.0fm", target.distance * 0.0254) -- Convert to meters
    draw.SimpleText(distText, "DermaDefault", x, y + half + 5, color, TEXT_ALIGN_CENTER)
end

-- ============================================================================
-- TARGET INFO PANEL
-- ============================================================================
local function DrawTargetInfoPanel(target, isLocked, rt)
    local scrW, scrH = ScrW(), ScrH()
    local panelW, panelH = 280, 180
    local panelX = scrW - panelW - 20
    local panelY = scrH * 0.3

    -- Panel background
    surface.SetDrawColor(Config.ColorBackground)
    surface.DrawRect(panelX, panelY, panelW, panelH)

    -- Grid overlay
    surface.SetDrawColor(Config.ColorGrid)
    for i = 0, panelW, 20 do
        surface.DrawLine(panelX + i, panelY, panelX + i, panelY + panelH)
    end
    for i = 0, panelH, 20 do
        surface.DrawLine(panelX, panelY + i, panelX + panelW, panelY + i)
    end

    -- Scanline effect
    DrawScanLine(panelX, panelY, panelW, panelH, rt)

    -- Border
    local borderColor = isLocked and Config.ColorSecondary or Config.ColorPrimary
    local borderAlpha = 150 + math_sin(rt * 4) * 50
    surface.SetDrawColor(borderColor.r, borderColor.g, borderColor.b, borderAlpha)
    surface.DrawOutlinedRect(panelX, panelY, panelW, panelH, 2)

    -- Corner decorations
    DrawCornerBrackets(panelX, panelY, panelW - 1, panelH - 1, 12, borderColor)

    -- Header
    local headerY = panelY + 5
    local lockStatus = isLocked and "◉ LOCKED" or "◎ SCANNING"
    local headerColor = isLocked and Config.ColorSecondary or Config.ColorPrimary
    draw.SimpleText("◢ TARGET ANALYSIS", "DermaDefaultBold", panelX + 10, headerY, headerColor)
    draw.SimpleText(lockStatus, "DermaDefault", panelX + panelW - 10, headerY, headerColor, TEXT_ALIGN_RIGHT)

    -- Divider line
    surface.SetDrawColor(borderColor.r, borderColor.g, borderColor.b, 100)
    surface.DrawLine(panelX + 5, headerY + 18, panelX + panelW - 5, headerY + 18)

    local infoY = headerY + 25
    local lineH = 18
    local info = target.info

    -- Target name with threat
    draw.SimpleText("NAME:", "DermaDefault", panelX + 10, infoY, Config.ColorPrimary)
    draw.SimpleText(info.name, "DermaDefaultBold", panelX + 70, infoY, Color(255, 255, 255))
    infoY = infoY + lineH

    -- IP Address
    draw.SimpleText("IP:", "DermaDefault", panelX + 10, infoY, Config.ColorPrimary)
    draw.SimpleText(target.ip .. ":" .. target.port, "DermaDefault", panelX + 70, infoY, Color(200, 200, 200))
    infoY = infoY + lineH

    -- MAC Address
    draw.SimpleText("MAC:", "DermaDefault", panelX + 10, infoY, Config.ColorPrimary)
    draw.SimpleText(target.mac, "DermaDefault", panelX + 70, infoY, Color(200, 200, 200))
    infoY = infoY + lineH

    -- OS
    draw.SimpleText("OS:", "DermaDefault", panelX + 10, infoY, Config.ColorPrimary)
    draw.SimpleText(info.os, "DermaDefault", panelX + 70, infoY, Color(200, 200, 200))
    infoY = infoY + lineH

    -- Browser
    draw.SimpleText("AGENT:", "DermaDefault", panelX + 10, infoY, Config.ColorPrimary)
    draw.SimpleText(info.browser, "DermaDefault", panelX + 70, infoY, Color(200, 200, 200))
    infoY = infoY + lineH

    -- Threat level
    draw.SimpleText("THREAT:", "DermaDefault", panelX + 10, infoY, Config.ColorPrimary)
    DrawThreatIndicator(panelX + 70, infoY, info.threat)
    infoY = infoY + lineH

    -- Signal strength bar at bottom
    local signalY = panelY + panelH - 25
    draw.SimpleText("SIGNAL:", "DermaDefault", panelX + 10, signalY, Config.ColorPrimary)
    DrawSignalBars(panelX + 70, signalY, target.signal, 8)

    local signalPct = string_format("%d%%", math.floor(target.signal))
    draw.SimpleText(signalPct, "DermaDefault", panelX + 140, signalY,
        target.hasObstacle and Config.ColorWarning or Config.ColorSecondary)

    if target.hasObstacle then
        draw.SimpleText("⚠ INTERFERENCE", "DermaDefault", panelX + 180, signalY, Config.ColorWarning)
    end
end

-- ============================================================================
-- SCAN OVERLAY (Edge frame & ambient effects)
-- ============================================================================
local function DrawScanOverlay(rt)
    local scrW, scrH = ScrW(), ScrH()

    -- Edge vignette / frame
    local frameSize = 60
    local frameAlpha = 30 + math_sin(rt * 2) * 10

    -- Top frame gradient
    for i = 0, frameSize do
        local alpha = frameAlpha * (1 - i / frameSize)
        surface.SetDrawColor(0, 20, 30, alpha)
        surface.DrawLine(0, i, scrW, i)
    end
    -- Bottom frame gradient
    for i = 0, frameSize do
        local alpha = frameAlpha * (1 - i / frameSize)
        surface.SetDrawColor(0, 20, 30, alpha)
        surface.DrawLine(0, scrH - i, scrW, scrH - i)
    end
    -- Left frame gradient
    for i = 0, frameSize do
        local alpha = frameAlpha * (1 - i / frameSize)
        surface.SetDrawColor(0, 20, 30, alpha)
        surface.DrawLine(i, 0, i, scrH)
    end
    -- Right frame gradient
    for i = 0, frameSize do
        local alpha = frameAlpha * (1 - i / frameSize)
        surface.SetDrawColor(0, 20, 30, alpha)
        surface.DrawLine(scrW - i, 0, scrW - i, scrH)
    end

    -- Corner brackets on screen edges
    local cornerSize = 40
    local cornerColor = Color(0, 255, 255, 100 + math_sin(rt * 3) * 50)
    DrawCornerBrackets(20, 20, scrW - 41, scrH - 41, cornerSize, cornerColor)

    -- NOTE: Top-left status panel removed - now rendered on viewmodel screen via ZDEV_DrawHackerScreenHUD

    -- Center crosshair enhancement
    local cx, cy = scrW / 2, scrH / 2
    local crossSize = 20
    local crossGap = 5
    local crossColor = Color(0, 255, 255, 150)

    surface.SetDrawColor(crossColor)
    -- Horizontal lines
    surface.DrawLine(cx - crossSize, cy, cx - crossGap, cy)
    surface.DrawLine(cx + crossGap, cy, cx + crossSize, cy)
    -- Vertical lines
    surface.DrawLine(cx, cy - crossSize, cx, cy - crossGap)
    surface.DrawLine(cx, cy + crossGap, cx, cy + crossSize)

    -- Small center dot
    surface.SetDrawColor(0, 255, 255, 200)
    surface.DrawRect(cx - 1, cy - 1, 3, 3)
end

-- ============================================================================
-- TARGET COMMAND VISUAL EFFECTS
-- ============================================================================

-- Effect state tracking (global for network receive)
local ActiveOverloadEffects = {} -- EntIndex -> startTime
local ConvertedEntities = {}     -- EntIndex -> true

-- Draw scan animation over target
local function DrawScanEffect(target, progress, rt)
    if not target or not target.screenPos or not target.screenPos.visible then return end

    local x, y = target.screenPos.x, target.screenPos.y
    local size = 60

    -- Rotating scan circle
    local rotation = rt * 360

    -- Scan lines radiating outward
    surface.SetDrawColor(0, 255, 255, 150 + math_sin(rt * 10) * 100)
    for i = 0, 7 do
        local angle = math.rad((i * 45) + rotation)
        local innerR = size * 0.3
        local outerR = size * 0.6 + (progress * size * 0.4)
        surface.DrawLine(
            x + math_cos(angle) * innerR, y + math_sin(angle) * innerR,
            x + math_cos(angle) * outerR, y + math_sin(angle) * outerR
        )
    end

    -- Progress arc
    local segments = 32
    local endSeg = math.floor(progress * segments)
    for seg = 0, endSeg do
        local a1 = (seg / segments) * math.pi * 2 - math.pi / 2
        local a2 = ((seg + 1) / segments) * math.pi * 2 - math.pi / 2
        local r = size * 0.8
        surface.DrawLine(
            x + math_cos(a1) * r, y + math_sin(a1) * r,
            x + math_cos(a2) * r, y + math_sin(a2) * r
        )
    end

    -- Scanning text
    draw.SimpleText("SCANNING...", "DermaDefaultBold", x, y - size - 10,
        Color(0, 255, 255, 200 + math_sin(rt * 8) * 55), TEXT_ALIGN_CENTER)
    draw.SimpleText(math.floor(progress * 100) .. "%", "DermaDefault", x, y + size + 5,
        Color(0, 255, 255, 255), TEXT_ALIGN_CENTER)
end

-- Draw "HACKED" glitch effect over target
local function DrawHackedEffect(target, rt, intensity)
    if not target or not target.screenPos or not target.screenPos.visible then return end

    local x, y = target.screenPos.x, target.screenPos.y

    -- Glitch offset
    local glitchX = math.random(-5, 5) * intensity
    local glitchY = math.random(-3, 3) * intensity

    -- Pulsing red/green effect
    local pulseColor
    if math.random() > 0.5 then
        pulseColor = Color(0, 255, 100, 200 * intensity)
    else
        pulseColor = Color(255, 50, 50, 200 * intensity)
    end

    -- Main "HACKED" text with glitch
    draw.SimpleText("▓▓ HACKED ▓▓", "DermaDefaultBold", x + glitchX, y + glitchY, pulseColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Glitch bars
    if math.random() > 0.7 then
        local barY = y + math.random(-40, 40)
        local barH = math.random(2, 6)
        surface.SetDrawColor(pulseColor)
        surface.DrawRect(x - 50, barY, 100, barH)
    end
end

-- Draw overload effect (damage/explosion warning)
local function DrawOverloadEffect(target, rt, elapsed)
    if not target or not target.screenPos or not target.screenPos.visible then return end

    local x, y = target.screenPos.x, target.screenPos.y
    local timeLeft = 5.0 - elapsed

    -- Flashing warning
    local flash = math_sin(rt * 15) > 0
    local warningColor = flash and Color(255, 50, 50, 255) or Color(255, 200, 0, 255)

    -- Warning triangle
    draw.SimpleText("⚠", "DermaDefaultBold", x, y - 50, warningColor, TEXT_ALIGN_CENTER)
    draw.SimpleText("CORE OVERLOAD", "DermaDefaultBold", x, y - 35, warningColor, TEXT_ALIGN_CENTER)
    draw.SimpleText(string_format("%.1fs", math.max(0, timeLeft)), "DermaDefault", x, y + 40, warningColor, TEXT_ALIGN_CENTER)

    -- Glitch distortion
    if math.random() > 0.6 then
        local distY = y + math.random(-30, 30)
        surface.SetDrawColor(255, 100, 0, 150)
        surface.DrawRect(x - 40 + math.random(-10, 10), distY, 80, math.random(2, 5))
    end

    -- Electrical arcs (visual only)
    if math.random() > 0.7 then
        surface.SetDrawColor(100, 200, 255, 200)
        local arcX1 = x + math.random(-30, 30)
        local arcY1 = y + math.random(-30, 30)
        local arcX2 = x + math.random(-30, 30)
        local arcY2 = y + math.random(-30, 30)
        surface.DrawLine(arcX1, arcY1, arcX2, arcY2)
    end
end

-- Draw converted ally indicator
local function DrawConvertedIndicator(target, rt)
    if not target or not target.screenPos or not target.screenPos.visible then return end

    local x, y = target.screenPos.x, target.screenPos.y

    -- Friendly indicator
    local pulse = 150 + math_sin(rt * 3) * 50
    draw.SimpleText("◈ ALLY", "DermaDefaultBold", x, y - 45, Color(0, 255, 100, pulse), TEXT_ALIGN_CENTER)

    -- Green highlight box
    surface.SetDrawColor(0, 255, 100, 50 + math_sin(rt * 2) * 30)
    surface.DrawOutlinedRect(x - 25, y - 25, 50, 50, 2)
end

-- ============================================================================
-- MAIN HUD DRAW FUNCTION
-- ============================================================================
local function DrawHackerHUD(wep)
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if not IsValid(wep) then return end

    local rt = RealTime()

    -- Scan for targets
    local targets = ScanForTargets(ply, wep)

    -- Update lock-on system
    UpdateLockOn(wep, targets)

    -- Apply aim assist if locked
    ApplyAimAssist(ply, wep)

    -- Draw scan overlay
    DrawScanOverlay(rt)

    -- Draw reticles for all visible targets
    for i, target in ipairs(targets) do
        local isLocked = LockedTarget and LockedTarget.entity == target.entity
        local entIdx = IsValid(target.entity) and target.entity:EntIndex() or -1

        DrawTargetReticle(target, isLocked, rt)

        -- Only draw lines to non-locked nearby targets
        if not isLocked and i <= 5 then
            local sp = target.screenPos
            if sp and sp.visible then
                local alpha = math.max(50, 150 - (i * 25))
                surface.SetDrawColor(0, 255, 255, alpha * 0.3)
                local cx, cy = ScrW() / 2, ScrH() / 2
                surface.DrawLine(cx, cy, sp.x, sp.y)
            end
        end

        -- Draw converted ally indicator
        if ConvertedEntities[entIdx] then
            DrawConvertedIndicator(target, rt)
        end

        -- Draw overload effect
        if ActiveOverloadEffects[entIdx] then
            local elapsed = rt - ActiveOverloadEffects[entIdx]
            if elapsed < 5.5 then
                DrawOverloadEffect(target, rt, elapsed)
            else
                ActiveOverloadEffects[entIdx] = nil
            end
        end
    end

    -- Draw target command effects for locked target
    if LockedTarget and IsValid(LockedTarget.entity) then
        local entIdx = LockedTarget.entity:EntIndex()

        -- Check if we're running a scan animation
        if wep.ActiveAnimation == "target_scan" and wep.TargetCommandEntity == LockedTarget.entity then
            local progress = wep:GetAnimationProgress()
            DrawScanEffect(LockedTarget, progress, rt)
        end

        -- Check for hacked effect (triggered after exploit)
        if wep.TargetHackedTime and wep.TargetHackedEntity == LockedTarget.entity then
            local elapsed = rt - wep.TargetHackedTime
            if elapsed < 3.0 then
                local intensity = 1.0 - (elapsed / 3.0)
                DrawHackedEffect(LockedTarget, rt, intensity)
            else
                wep.TargetHackedTime = nil
                wep.TargetHackedEntity = nil
            end
        end

        -- Converted indicator for locked target
        if ConvertedEntities[entIdx] then
            DrawConvertedIndicator(LockedTarget, rt)
        end

        -- Overload effect for locked target
        if ActiveOverloadEffects[entIdx] then
            local elapsed = rt - ActiveOverloadEffects[entIdx]
            if elapsed < 5.5 then
                DrawOverloadEffect(LockedTarget, rt, elapsed)
            else
                ActiveOverloadEffects[entIdx] = nil
            end
        end
    end

    -- Draw target info panel for primary target
    local primaryTarget = LockedTarget or targets[1]
    if primaryTarget then
        local isLocked = LockedTarget ~= nil
        DrawTargetInfoPanel(primaryTarget, isLocked, rt)
    end

    -- Lock-on progress indicator
    if IsLocking and not LockedTarget then
        local cx, cy = ScrW() / 2, ScrH() / 2
        local progress = (rt - LockAcquireStart) / Config.LockOnTime
        progress = math_Clamp(progress, 0, 1)

        local radius = 50
        local segments = 32
        local endSeg = math.floor(progress * segments)

        surface.SetDrawColor(Config.ColorWarning)
        for seg = 0, endSeg do
            local a1 = (seg / segments) * math.pi * 2 - math.pi / 2
            local a2 = ((seg + 1) / segments) * math.pi * 2 - math.pi / 2
            surface.DrawLine(
                cx + math_cos(a1) * radius, cy + math_sin(a1) * radius,
                cx + math_cos(a2) * radius, cy + math_sin(a2) * radius
            )
        end

        draw.SimpleText("ACQUIRING LOCK...", "DermaDefault", cx, cy + radius + 10,
            Config.ColorWarning, TEXT_ALIGN_CENTER)
        draw.SimpleText(math.floor(progress * 100) .. "%", "DermaDefaultBold", cx, cy,
            Config.ColorWarning, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

-- ============================================================================
-- INPUT HANDLING FOR LOCK-ON
-- ============================================================================
local function HandleLockInput(wep)
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if not IsValid(wep) then return end

    local rt = RealTime()

    -- Middle mouse to toggle lock
    if input.IsMouseDown(MOUSE_MIDDLE) then
        if not IsLocking and not LockedTarget then
            -- Start lock acquisition
            local targets = ScanForTargets(ply, wep)
            if targets[1] and targets[1].angleDiff <= Config.LockOnFOV then
                IsLocking = true
                LockAcquireStart = rt
                surface.PlaySound("buttons/button17.wav")
            end
        end
    else
        if IsLocking then
            local elapsed = rt - LockAcquireStart
            if elapsed >= Config.LockOnTime then
                -- Lock acquired
                local targets = ScanForTargets(ply, wep)
                if targets[1] and targets[1].angleDiff <= Config.LockOnFOV then
                    LockedTarget = targets[1]
                    surface.PlaySound("buttons/button9.wav")
                end
            end
            IsLocking = false
        end
    end

    -- Right click + Middle click to break lock
    if LockedTarget and input.IsKeyDown(KEY_X) then
        LockedTarget = nil
        wep.LockedTarget = nil
        surface.PlaySound("buttons/button10.wav")
    end
end

-- ============================================================================
-- VIEWMODEL SCREEN HUD (Renders on the weapon's quad screen)
-- ============================================================================
-- This function renders key HUD elements onto the viewmodel screen (270x170)
-- Called from shared.lua quad_screen draw_func

local function DrawScreenHUD(weapon, w, h, rt)
    -- Get target count from cache
    local targetsCount = #TargetCache

    -- Top status bar area (top edge of screen)
    local statusY = 2
    local barH = 28

    -- Background for status bar
    surface.SetDrawColor(0, 15, 20, 200)
    surface.DrawRect(0, 0, w, barH)

    -- Bottom border line
    surface.SetDrawColor(0, 255, 255, 150)
    surface.DrawLine(0, barH, w, barH)

    -- Lock status indicator (left side)
    local lockStatus = LockedTarget and "◉ LOCKED" or "◎ SCAN"
    local lockColor = LockedTarget and Config.ColorSecondary or Config.ColorPrimary
    draw.SimpleText(lockStatus, "DefaultSmall", 5, statusY, lockColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    -- Target count (center)
    draw.SimpleText("TGT: " .. targetsCount, "DefaultSmall", w / 2, statusY, Config.ColorSecondary, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    -- Signal indicator (right side) - only show if we have a target
    local primaryTarget = LockedTarget or TargetCache[1]
    if primaryTarget then
        local signal = primaryTarget.signal or 0
        local signalPct = string_format("%d%%", math.floor(signal))

        -- Draw small signal bars
        local sbarX = w - 60
        local sbarY = statusY + 2
        local sbarW, sbarH = 3, 10
        local sSpacing = 1
        local sMaxBars = 5
        local sFilledBars = math.ceil((signal / Config.MaxSignal) * sMaxBars)

        for i = 1, sMaxBars do
            local bX = sbarX + (i - 1) * (sbarW + sSpacing)
            local sHeight = sbarH * (i / sMaxBars)
            local bY = sbarY + (sbarH - sHeight)

            if i <= sFilledBars then
                local signalColor
                if signal >= 70 then
                    signalColor = Config.ColorSecondary
                elseif signal >= 40 then
                    signalColor = Config.ColorWarning
                else
                    signalColor = Config.ColorDanger
                end
                surface.SetDrawColor(signalColor)
            else
                surface.SetDrawColor(40, 60, 70, 150)
            end
            surface.DrawRect(bX, bY, sbarW, sHeight)
        end

        -- Signal percentage
        draw.SimpleText(signalPct, "DefaultSmall", w - 5, statusY, Config.ColorSecondary, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

        -- Target name on second line
        if primaryTarget.info then
            local targetName = primaryTarget.info.name or "UNKNOWN"
            local nameColor = LockedTarget and Config.ColorSecondary or Config.ColorPrimary
            draw.SimpleText(targetName, "DefaultSmall", 5, statusY + 12, nameColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

            -- Threat level on right side of second line
            local threat = primaryTarget.info.threat or "UNKNOWN"
            local threatColor = Config.ColorPrimary
            if threat == "HIGH" or threat == "EXTREME" then
                threatColor = Config.ColorDanger
            elseif threat == "MEDIUM" then
                threatColor = Config.ColorWarning
            elseif threat == "LOW" or threat == "NONE" then
                threatColor = Config.ColorSecondary
            end
            draw.SimpleText(threat, "DefaultSmall", w - 5, statusY + 12, threatColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        end
    else
        -- No target
        draw.SimpleText("NO TARGET", "DefaultSmall", w - 5, statusY, Color(100, 100, 100), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    end

    -- Animated pulse indicator
    local pulseAlpha = 150 + math_sin(rt * 5) * 100
    local pulseX = w / 2 + 30
    draw.SimpleText("●", "DefaultSmall", pulseX, statusY, Color(0, 255, 100, pulseAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

-- Expose the function globally so the quad screen can call it
ZDEV_DrawHackerScreenHUD = DrawScreenHUD

-- ============================================================================
-- HOOK INTEGRATION
-- ============================================================================
hook.Add("HUDPaint", "ZDEVHackerHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end
    if wep:GetClass() ~= "zdev_weapon_hacker" then return end

    -- Handle input
    HandleLockInput(wep)

    -- Draw the HUD
    DrawHackerHUD(wep)
end)

-- ============================================================================
-- TARGET COMMAND VISUAL EFFECTS
-- ============================================================================

-- Effect state tracking
local ActiveScanEffects = {}   -- EntIndex -> endTime
local ActiveHackedEffects = {} -- EntIndex -> endTime
local ActiveOverloadEffects = {} -- EntIndex -> startTime
local ConvertedEntities = {}   -- EntIndex -> true

-- Draw scan animation over target
local function DrawScanEffect(target, progress, rt)
    if not target or not target.screenPos or not target.screenPos.visible then return end

    local x, y = target.screenPos.x, target.screenPos.y
    local size = 60

    -- Rotating scan circle
    local rotation = rt * 360

    -- Scan lines radiating outward
    surface.SetDrawColor(0, 255, 255, 150 + math_sin(rt * 10) * 100)
    for i = 0, 7 do
        local angle = math.rad((i * 45) + rotation)
        local innerR = size * 0.3
        local outerR = size * 0.6 + (progress * size * 0.4)
        surface.DrawLine(
            x + math_cos(angle) * innerR, y + math_sin(angle) * innerR,
            x + math_cos(angle) * outerR, y + math_sin(angle) * outerR
        )
    end

    -- Progress arc
    local segments = 32
    local endSeg = math.floor(progress * segments)
    for i = 0, endSeg do
        local a1 = (i / segments) * math.pi * 2 - math.pi / 2
        local a2 = ((i + 1) / segments) * math.pi * 2 - math.pi / 2
        local r = size * 0.8
        surface.DrawLine(
            x + math_cos(a1) * r, y + math_sin(a1) * r,
            x + math_cos(a2) * r, y + math_sin(a2) * r
        )
    end

    -- Scanning text
    draw.SimpleText("SCANNING...", "DermaDefaultBold", x, y - size - 10,
        Color(0, 255, 255, 200 + math_sin(rt * 8) * 55), TEXT_ALIGN_CENTER)
    draw.SimpleText(math.floor(progress * 100) .. "%", "DermaDefault", x, y + size + 5,
        Color(0, 255, 255, 255), TEXT_ALIGN_CENTER)
end

-- Draw "HACKED" glitch effect over target
local function DrawHackedEffect(target, rt, intensity)
    if not target or not target.screenPos or not target.screenPos.visible then return end

    local x, y = target.screenPos.x, target.screenPos.y

    -- Glitch offset
    local glitchX = math.random(-5, 5) * intensity
    local glitchY = math.random(-3, 3) * intensity

    -- Pulsing red/green effect
    local pulseColor
    if math.random() > 0.5 then
        pulseColor = Color(0, 255, 100, 200 * intensity)
    else
        pulseColor = Color(255, 50, 50, 200 * intensity)
    end

    -- Main "HACKED" text with glitch
    draw.SimpleText("▓▓ HACKED ▓▓", "DermaDefaultBold", x + glitchX, y + glitchY, pulseColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Glitch bars
    if math.random() > 0.7 then
        local barY = y + math.random(-40, 40)
        local barH = math.random(2, 6)
        surface.SetDrawColor(pulseColor)
        surface.DrawRect(x - 50, barY, 100, barH)
    end
end

-- Draw overload effect (damage/explosion warning)
local function DrawOverloadEffect(target, rt, elapsed)
    if not target or not target.screenPos or not target.screenPos.visible then return end

    local x, y = target.screenPos.x, target.screenPos.y
    local timeLeft = 5.0 - elapsed

    -- Flashing warning
    local flash = math_sin(rt * 15) > 0
    local warningColor = flash and Color(255, 50, 50, 255) or Color(255, 200, 0, 255)

    -- Warning triangle
    draw.SimpleText("⚠", "DermaDefaultBold", x, y - 50, warningColor, TEXT_ALIGN_CENTER)
    draw.SimpleText("CORE OVERLOAD", "DermaDefaultBold", x, y - 35, warningColor, TEXT_ALIGN_CENTER)
    draw.SimpleText(string_format("%.1fs", math.max(0, timeLeft)), "DermaDefault", x, y + 40, warningColor, TEXT_ALIGN_CENTER)

    -- Glitch distortion
    if math.random() > 0.6 then
        local distY = y + math.random(-30, 30)
        surface.SetDrawColor(255, 100, 0, 150)
        surface.DrawRect(x - 40 + math.random(-10, 10), distY, 80, math.random(2, 5))
    end

    -- Electrical arcs (visual only)
    if math.random() > 0.7 then
        surface.SetDrawColor(100, 200, 255, 200)
        local arcX1 = x + math.random(-30, 30)
        local arcY1 = y + math.random(-30, 30)
        local arcX2 = x + math.random(-30, 30)
        local arcY2 = y + math.random(-30, 30)
        surface.DrawLine(arcX1, arcY1, arcX2, arcY2)
    end
end

-- Draw converted ally indicator
local function DrawConvertedIndicator(target, rt)
    if not target or not target.screenPos or not target.screenPos.visible then return end

    local x, y = target.screenPos.x, target.screenPos.y

    -- Friendly indicator
    local pulse = 150 + math_sin(rt * 3) * 50
    draw.SimpleText("◈ ALLY", "DermaDefaultBold", x, y - 45, Color(0, 255, 100, pulse), TEXT_ALIGN_CENTER)

    -- Green highlight box
    surface.SetDrawColor(0, 255, 100, 50 + math_sin(rt * 2) * 30)
    surface.DrawOutlinedRect(x - 25, y - 25, 50, 50, 2)
end

-- ============================================================================
-- NETWORK RECEIVE FOR SERVER EFFECTS
-- ============================================================================
net.Receive("ZDEVHacker_TargetEffect", function()
    local targetEnt = net.ReadEntity()
    local effectType = net.ReadString()

    if not IsValid(targetEnt) then return end
    local entIdx = targetEnt:EntIndex()
    local rt = RealTime()

    if effectType == "converted" then
        ConvertedEntities[entIdx] = true
        surface.PlaySound("buttons/button4.wav")

    elseif effectType == "overload_start" then
        ActiveOverloadEffects[entIdx] = rt
        surface.PlaySound("ambient/energy/zap1.wav")

    elseif effectType == "overload_explode" then
        ActiveOverloadEffects[entIdx] = nil
        surface.PlaySound("ambient/explosions/explode_4.wav")
    end
end)

-- ============================================================================
-- CLEANUP ON WEAPON SWITCH
-- ============================================================================
hook.Add("PlayerSwitchWeapon", "ZDEVHackerHUDCleanup", function(ply, oldWep, newWep)
    if ply ~= LocalPlayer() then return end

    if IsValid(oldWep) and oldWep:GetClass() == "zdev_weapon_hacker" then
        -- Clear targeting data
        LockedTarget = nil
        IsLocking = false
        LockProgress = 0
        TargetCache = {}
    end
end)



local crosshair = {
    gap = 10,
    length = 20,
    thickness = 2,
    reticle = {
        default = {
            mat = Material( hudMats.reticle.quarter_circle_01 ),
            size = 64,
            color = Color(255, 255, 255, 255),
        },
        targeted = {
            mat = Material( hudMats.reticle.double_square_01 ),
            size = 64,
            color = Color(255, 150, 0, 255),
        },
        locked = {
            mat = Material( hudMats.reticle.cross_med_01 ),
            size = 64,
            color = Color(0, 255, 0, 255),
        },
        scanning = {
            mat = Material( hudMats.reticle.circle_center_x_01 ),
            size = 64,
            color = Color(255, 200, 0, 255),
        },
    }
}
-- Example: Custom crosshair
function SWEP:DoDrawCrosshair(x, y)

    -- [[ Manually drawn crosshair example ]]
	-- Draw custom crosshair
	local gap = 20
	local length = 10
	local thickness = 1
--Top line
	surface.SetDrawColor(255, 255, 255, 255)
	surface.DrawRect(x - thickness/2, y - gap - length, thickness, length)
--Bottom line
	surface.DrawRect(x - thickness/2, y + gap, thickness, length)
--Left line
	surface.DrawRect(x - gap - length, y - thickness/2, length, thickness)
--Right line
	surface.DrawRect(x + gap, y - thickness/2, length, thickness)

    local size = crosshair.reticle.default.size
    local half = size / 2
    local color = crosshair.reticle.default.color
    local mat = crosshair.reticle.default.mat

    DrawMaterial(x - half, y - half, size, size, mat, color)

	return true -- Suppress default crosshair
end
-- Print initialization
print("[ZDEV Hacker] HUD Targeting System Loaded")

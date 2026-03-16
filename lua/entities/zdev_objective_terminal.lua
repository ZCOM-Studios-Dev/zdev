
AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Objective Terminal"
ENT.Author = "ZCOM Studios"
ENT.Category = "ZDEV"
ENT.Information = "A hackable data terminal inspired by Splinter Cell Double Agent multiplayer."
ENT.Purpose = "Players hack this terminal to download data while others defend it."
ENT.Contact = "STEAM_0:0:0"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/props_combine/breenconsole.mdl"

-- Terminal States
ENT.STATE_INACTIVE = 0
ENT.STATE_HACKING = 1
ENT.STATE_COMPLETED = 2
ENT.STATE_FAILED = 3

-- Configuration
ENT.HackTime = 20 -- Time in seconds to complete hack
ENT.HackRange = 120 -- Range player must stay within
ENT.InterruptOnDamage = true -- Stop hacking if player takes damage
ENT.TeamBased = true -- Enable team-based hacking

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "State")
    self:NetworkVar("Float", 0, "HackProgress")
    self:NetworkVar("Entity", 0, "Hacker")
    self:NetworkVar("Int", 1, "TeamID")
    self:NetworkVar("String", 0, "TerminalName")

    if SERVER then
        self:SetState(self.STATE_INACTIVE)
        self:SetHackProgress(0)
        self:SetHacker(NULL)
        self:SetTeamID(0)
        self:SetTerminalName("DATA TERMINAL")
    end
end

function ENT:Initialize()
    if SERVER then
        self:SetModel(self.Model)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:EnableMotion(false)
            phys:Sleep()
        end

        self.LastThink = CurTime()
        self.HackStartTime = 0
        self.LastAlertTime = 0
        self.AlertInterval = 2 -- Beep every 2 seconds while hacking
    end

    if CLIENT then
        self.ScreenGlow = 0
        self.ScreenGlowTarget = 0
        self.LastBeep = 0
    end
end

if SERVER then
    function ENT:Use(activator, caller)
        if not IsValid(caller) or not caller:IsPlayer() then return end

        local state = self:GetState()

        -- Can only start hacking if inactive
        if state == self.STATE_INACTIVE then
            self:StartHacking(caller)
        -- Can cancel own hack
        elseif state == self.STATE_HACKING and self:GetHacker() == caller then
            self:StopHacking(false)
        end
    end

    function ENT:StartHacking(player)
        if not IsValid(player) then return end

        self:SetState(self.STATE_HACKING)
        self:SetHacker(player)
        self:SetHackProgress(0)
        self:SetTeamID(player:Team())
        self.HackStartTime = CurTime()
        self.LastAlertTime = CurTime()

        -- Play alert sound
        self:EmitSound("buttons/button15.wav", 75, 100)
        self:EmitSound("ambient/alarms/warningbell1.wav", 70, 150)

        -- Hook to detect damage
        if self.InterruptOnDamage then
            hook.Add("EntityTakeDamage", self, function(ent, dmg)
                if ent == player and self:GetState() == self.STATE_HACKING then
                    self:StopHacking(false)
                end
            end)
        end

        -- Notify nearby players
        self:AlertNearbyPlayers(player)
    end

    function ENT:StopHacking(success)
        local hacker = self:GetHacker()

        if success then
            self:SetState(self.STATE_COMPLETED)
            self:EmitSound("buttons/button9.wav", 75, 120)

            if IsValid(hacker) then
                hacker:ChatPrint("[TERMINAL] Data download complete!")
            end

            -- Call hook for gamemode integration
            hook.Run("ZDEVTerminalHacked", self, hacker, self:GetTeamID())
        else
            self:SetState(self.STATE_INACTIVE)
            self:SetHackProgress(0)
            self:EmitSound("buttons/button10.wav", 75, 80)

            if IsValid(hacker) then
                hacker:ChatPrint("[TERMINAL] Hack interrupted!")
            end
        end

        self:SetHacker(NULL)
        hook.Remove("EntityTakeDamage", self)
    end

    function ENT:AlertNearbyPlayers(hacker)
        local teamID = self:GetTeamID()

        for _, ply in ipairs(player.GetAll()) do
            if ply ~= hacker then
                if self.TeamBased and ply:Team() ~= teamID then
                    -- Enemy team - alert them
                    ply:ChatPrint("[ALERT] Terminal being hacked by " .. hacker:Nick() .. "!")
                    ply:EmitSound("buttons/blip1.wav", 75, 100)
                elseif not self.TeamBased then
                    -- Free-for-all - alert everyone
                    ply:ChatPrint("[ALERT] " .. hacker:Nick() .. " is hacking a terminal!")
                    ply:EmitSound("buttons/blip1.wav", 75, 100)
                end
            end
        end
    end

    function ENT:Think()
        local state = self:GetState()

        if state == self.STATE_HACKING then
            local hacker = self:GetHacker()

            -- Check if hacker is still valid
            if not IsValid(hacker) or not hacker:Alive() then
                self:StopHacking(false)
                return
            end

            -- Check proximity
            local dist = self:GetPos():Distance(hacker:GetPos())
            if dist > self.HackRange then
                self:StopHacking(false)
                return
            end

            -- Update progress
            local elapsed = CurTime() - self.HackStartTime
            local progress = math.min(elapsed / self.HackTime, 1)
            self:SetHackProgress(progress)

            -- Periodic alert beeps
            if CurTime() - self.LastAlertTime > self.AlertInterval then
                self:EmitSound("buttons/blip2.wav", 65, 100 + (progress * 50))
                self.LastAlertTime = CurTime()
            end

            -- Check if complete
            if progress >= 1 then
                self:StopHacking(true)
                return
            end
        end

        self:NextThink(CurTime() + 0.1)
        return true
    end

    function ENT:OnTakeDamage(dmg)
        -- Terminal can't be damaged
        return 0
    end

    -- Reset terminal (for gamemodes)
    function ENT:Reset()
        self:SetState(self.STATE_INACTIVE)
        self:SetHackProgress(0)
        self:SetHacker(NULL)
        hook.Remove("EntityTakeDamage", self)
    end
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()

        local state = self:GetState()
        local pos = self:GetPos() + self:GetUp() * 60 + self:GetForward() * 10
        local ang = self:GetAngles()
        ang:RotateAroundAxis(ang:Up(), 90)
        ang:RotateAroundAxis(ang:Forward(), 90)

        -- Smooth screen glow
        if state == self.STATE_HACKING then
            self.ScreenGlowTarget = 1
        elseif state == self.STATE_COMPLETED then
            self.ScreenGlowTarget = 0.5
        else
            self.ScreenGlowTarget = 0
        end

        self.ScreenGlow = Lerp(FrameTime() * 5, self.ScreenGlow, self.ScreenGlowTarget)

        -- Draw 3D2D interface
        cam.Start3D2D(pos, ang, 0.025)
            self:DrawInterface()
        cam.End3D2D()

        -- Draw effect lights
        if state == self.STATE_HACKING then
            local pulse = math.sin(CurTime() * 5) * 0.5 + 0.5
            local dlight = DynamicLight(self:EntIndex())
            if dlight then
                dlight.pos = self:GetPos() + self:GetUp() * 30
                dlight.r = 255
                dlight.g = 100 + pulse * 155
                dlight.b = 0
                dlight.brightness = 2
                dlight.size = 128
                dlight.decay = 512
                dlight.dietime = CurTime() + 1
            end
        elseif state == self.STATE_COMPLETED then
            local dlight = DynamicLight(self:EntIndex())
            if dlight then
                dlight.pos = self:GetPos() + self:GetUp() * 30
                dlight.r = 0
                dlight.g = 255
                dlight.b = 0
                dlight.brightness = 2
                dlight.size = 128
                dlight.decay = 512
                dlight.dietime = CurTime() + 1
            end
        end
    end

    function ENT:DrawInterface()
        local state = self:GetState()
        local progress = self:GetHackProgress()
        local w, h = 400, 300

        -- Background
        surface.SetDrawColor(0, 0, 0, 200)
        surface.DrawRect(-w / 2, -h / 2, w, h)

        -- Border
        local borderColor = Color(50, 50, 50)
        if state == self.STATE_HACKING then
            borderColor = Color(255, 150, 0)
        elseif state == self.STATE_COMPLETED then
            borderColor = Color(0, 255, 0)
        end

        surface.SetDrawColor(borderColor)
        surface.DrawOutlinedRect(-w / 2, -h / 2, w, h, 2)

        -- Title
        draw.SimpleText(self:GetTerminalName(), "DermaLarge", 0, -h / 2 + 30, Color(200, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- State display
        local stateText = ""
        local stateColor = Color(150, 150, 150)

        if state == self.STATE_INACTIVE then
            stateText = "[ READY ]"
            stateColor = Color(100, 150, 255)
        elseif state == self.STATE_HACKING then
            stateText = "[ DOWNLOADING... ]"
            stateColor = Color(255, 150, 0)

            local hacker = self:GetHacker()
            if IsValid(hacker) then
                draw.SimpleText("OPERATIVE: " .. hacker:Nick(), "DermaDefault", 0, -h / 2 + 80, Color(255, 200, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        elseif state == self.STATE_COMPLETED then
            stateText = "[ COMPLETE ]"
            stateColor = Color(0, 255, 0)
        end

        draw.SimpleText(stateText, "DermaDefaultBold", 0, -h / 2 + 60, stateColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Progress bar (only when hacking or completed)
        if state == self.STATE_HACKING or state == self.STATE_COMPLETED then
            local barW, barH = 300, 40
            local barX, barY = -barW / 2, 0

            -- Background
            surface.SetDrawColor(20, 20, 20, 200)
            surface.DrawRect(barX, barY, barW, barH)

            -- Border
            surface.SetDrawColor(borderColor)
            surface.DrawOutlinedRect(barX, barY, barW, barH, 2)

            -- Fill
            local fillW = barW * progress
            surface.SetDrawColor(borderColor.r, borderColor.g, borderColor.b, 150)
            surface.DrawRect(barX, barY, fillW, barH)

            -- Progress text
            local percentText = string.format("%d%%", math.floor(progress * 100))
            draw.SimpleText(percentText, "DermaLarge", 0, barY + barH / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            -- Time remaining
            if state == self.STATE_HACKING then
                local timeLeft = self.HackTime * (1 - progress)
                local timeText = string.format("%.1fs", timeLeft)
                draw.SimpleText(timeText, "DermaDefault", 0, barY + barH + 20, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end

        -- Instructions
        if state == self.STATE_INACTIVE then
            draw.SimpleText("Press USE to begin hack", "DermaDefault", 0, h / 2 - 40, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif state == self.STATE_HACKING then
            draw.SimpleText("Stay within range...", "DermaDefault", 0, h / 2 - 60, Color(255, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Press USE to cancel", "DermaDefault", 0, h / 2 - 40, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    function ENT:Think()
        -- Client-side beeping
        local state = self:GetState()
        if state == self.STATE_HACKING then
            local progress = self:GetHackProgress()
            local beepInterval = 1 - (progress * 0.7) -- Speed up beeps as progress increases

            if CurTime() - self.LastBeep > beepInterval then
                self:EmitSound("buttons/lightswitch2.wav", 60, 100 + (progress * 100))
                self.LastBeep = CurTime()
            end
        end
    end
end


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
        self.LastBeep = 0
    end
end

if SERVER then
    util.AddNetworkString("zdev_terminal_action")

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

    -- Click-to-interact coming from the imgui panel. The server stays
    -- authoritative: validate the entity/class, throttle per player, and
    -- enforce the same proximity rule as Use(). The actions are idempotent so
    -- they can safely co-exist with a same-frame SIMPLE_USE press.
    --   action 1 = "BEGIN HACK", action 2 = "CANCEL"
    net.Receive("zdev_terminal_action", function(_, ply)
        if not IsValid(ply) then return end

        local ent = net.ReadEntity()
        local action = net.ReadUInt(2)

        if not IsValid(ent) or ent:GetClass() ~= "zdev_objective_terminal" then return end

        ply.ZDEVTermNext = ply.ZDEVTermNext or 0
        if CurTime() < ply.ZDEVTermNext then return end
        ply.ZDEVTermNext = CurTime() + 0.15

        if ent:GetPos():Distance(ply:GetPos()) > ent.HackRange then return end

        if action == 1 then
            if ent:GetState() == ent.STATE_INACTIVE then
                ent:StartHacking(ply)
            end
        elseif action == 2 then
            if ent:GetState() == ent.STATE_HACKING and ent:GetHacker() == ply then
                ent:StopHacking(false)
            end
        end
    end)
end

if CLIENT then
    -- Shared interactive 3D2D library. Prefer the singleton populated by the
    -- render module; fall back to a direct include if entities load first.
    local imgui = (ZDEV and ZDEV.IMGUI) or include("zdev/client/zd_cl_imgui.lua")

    -- Base placement on the model's +Y (front-panel) face. imgui.Entity3D2D
    -- treats these as LOCAL to the prop, so the panel rides the model.
    ENT.ScreenOffset   = Vector(-2, 1.795, 45) -- +Y = out the front face, +Z = up the face
    ENT.ScreenScale    = 0.035
    ENT.ScreenHideDist = 100              -- stop drawing/processing past this range
    ENT.ScreenFadeDist = 20000              -- start fading out here

    -- Live alignment rig. Set "zdev_term_edit 1" (and "developer 1" for imgui's
    -- built-in hover/dot overlay) to dial the panel onto the real model, then
    -- bake the numbers you like into the ENT.Screen* defaults above.
    local cv_edit  = CreateClientConVar("zdev_term_edit",  "0", true, false, "ZDEV: live-tune objective terminal screen placement")
    local cv_x     = CreateClientConVar("zdev_term_x",     "0", true, false)
    local cv_y     = CreateClientConVar("zdev_term_y",     "0", true, false)
    local cv_z     = CreateClientConVar("zdev_term_z",     "0", true, false)
    local cv_pitch = CreateClientConVar("zdev_term_pitch", "0", true, false)
    local cv_yaw   = CreateClientConVar("zdev_term_yaw",   "0", true, false)
    local cv_roll  = CreateClientConVar("zdev_term_roll",  "0", true, false)
    local cv_scale = CreateClientConVar("zdev_term_scale", "0", true, false)


    -- ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
    -- imgui Render Utility Functions
    


    -- Build the LOCAL angle whose Up() (imgui's outward plane normal) points
    -- along the model's +Y, with screen-up mapped to +Z so text stays upright.
    --   start:  Forward=+X, Right=-Y, Up=+Z
    --   yaw180: Forward=-X
    --   roll90 about Forward: Right=-Z, Up=+Y  (normal now faces +Y)
    function ENT:GetScreenTransform()
        local ang = Angle(0, 0, 0)
        ang:RotateAroundAxis(ang:Up(), 0)
        ang:RotateAroundAxis(ang:Forward(), 41.85)
        ang:RotateAroundAxis(ang:Right(), 0)

        local pos   = self.ScreenOffset
        local scale = self.ScreenScale

        if cv_edit:GetBool() then
            pos = pos + Vector(cv_x:GetFloat(), cv_y:GetFloat(), cv_z:GetFloat())
            ang:RotateAroundAxis(ang:Right(),   cv_pitch:GetFloat())
            ang:RotateAroundAxis(ang:Up(),      cv_yaw:GetFloat())
            ang:RotateAroundAxis(ang:Forward(), cv_roll:GetFloat())
            local s = cv_scale:GetFloat()
            if s > 0 then scale = s end
        end

        return pos, ang, scale
    end

    -- net throttle for the click-to-interact buttons (per terminal instance)
    local function sendAction(ent, action)
        ent._nextAction = ent._nextAction or 0
        if CurTime() < ent._nextAction then return end
        ent._nextAction = CurTime() + 0.2
        net.Start("zdev_terminal_action")
            net.WriteEntity(ent)
            net.WriteUInt(action, 2)
        net.SendToServer()
    end
    ENT.SendAction = sendAction

    function ENT:Draw()
        self:DrawModel()

        local lpos, lang, scale = self:GetScreenTransform()

        -- Entity3D2D handles LocalToWorld, ignores this prop in the cursor
        -- trace, and returns false when behind/too far away.
        if imgui.Entity3D2D(self, lpos, lang, scale, self.ScreenHideDist, self.ScreenFadeDist) then
            -- Always close the context even if DrawInterface errors: the imgui
            -- instance is now shared, so a leaked context would shut down every
            -- panel (terminal + signs + 3D2D panels), not just this one.
            local ok, err = pcall(self.DrawInterface, self, imgui)
            imgui.End3D2D()
            if not ok and not self._loggedDrawError then
                self._loggedDrawError = true
                ErrorNoHalt("[zdev_objective_terminal] DrawInterface error: " .. tostring(err) .. "\n")
            end
        end

        self:DrawStatusLight()
    end

    -- Pulsing dynamic light tied to terminal state.
    function ENT:DrawStatusLight()
        local state = self:GetState()
        if state ~= self.STATE_HACKING and state ~= self.STATE_COMPLETED then return end

        local dlight = DynamicLight(self:EntIndex())
        if not dlight then return end

        dlight.pos = self:GetPos() + self:GetUp() * 30
        dlight.brightness = 2
        dlight.size = 128
        dlight.decay = 512
        dlight.dietime = CurTime() + 1

        if state == self.STATE_HACKING then
            local pulse = math.sin(CurTime() * 5) * 0.5 + 0.5
            dlight.r, dlight.g, dlight.b = 255, 100 + pulse * 155, 0
        else
            dlight.r, dlight.g, dlight.b = 0, 255, 0
        end
    end

    -- Shared progress bar, centered on the panel.
    function ENT:DrawProgressBar(borderColor, progress)
        local barW, barH = 300, 40
        local barX, barY = -barW / 2, -10

        surface.SetDrawColor(20, 20, 20, 200)
        surface.DrawRect(barX, barY, barW, barH)

        surface.SetDrawColor(borderColor.r, borderColor.g, borderColor.b, 150)
        surface.DrawRect(barX, barY, barW * progress, barH)

        surface.SetDrawColor(borderColor)
        surface.DrawOutlinedRect(barX, barY, barW, barH, 2)

        draw.SimpleText(string.format("%d%%", math.floor(progress * 100)), "DermaLarge", 0, barY + barH / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        if self:GetState() == self.STATE_HACKING then
            local timeLeft = self.HackTime * (1 - progress)
            draw.SimpleText(string.format("%.1fs", timeLeft), "DermaDefault", 0, barY + barH + 18, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end


    local screen_panel_square_1 = Material( "hud/complex/set06/v5_INTERFACE_14.png")
    local grid_1 = Material( "hud/grid/dot_lg_04.png")

    local clr_bg2 = Color(0,150,255,25)
    
    -- Drawn INSIDE an active imgui.Entity3D2D context: surface.* draws in panel
    -- space and imgui.* widgets are hit-tested against the player's aim ray.
    function ENT:DrawInterface(imgui)
        local state = self:GetState()
        local progress = self:GetHackProgress()
        local w, h = 400, 300

        -- Keep the panel visible even when the prop origin leaves the frustum.
        imgui.ExpandRenderBoundsFromRect(-w / 2, -h / 2, w, h)

        local borderColor = Color(50, 50, 50)
        if state == self.STATE_HACKING then
            borderColor = Color(255, 150, 0)
        elseif state == self.STATE_COMPLETED then
            borderColor = Color(0, 255, 0)
        end

        -- Background + border
        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawRect(-w / 2, -h / 2, w, h)

        -- Background texture
        ZDEV.DRAW.TexturedRect( -w / 2, -h /  2, w, h, grid_1, Color(0,200,255,math.Rand(5,15)) )

        -- Secondary background rectangle with flickering alpha value
        draw.RoundedBox(0 , -w/2, -h/2, w, h, Color(clr_bg2.r, clr_bg2.g, clr_bg2.b, 15 +  math.Rand(5, 10) ))

        surface.SetDrawColor(borderColor)
        surface.DrawOutlinedRect(-w / 2, -h / 2, w, h, 2)

        -- Title
        draw.SimpleText(self:GetTerminalName(), "digital7_scan", 0, -h / 2 + 30, Color(200, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        if state == self.STATE_INACTIVE then
            draw.SimpleText("[ READY ]", "DermaDefaultBold", 0, -h / 2 + 64, Color(100, 150, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            -- Clickable: aim at it and press USE/ATTACK to begin the hack.
            local bw, bh = 220, 56
            if imgui.xTextButton("BEGIN HACK", "!Roboto@30", -bw / 2, 16, bw, bh, 2,
                    Color(120, 220, 120), Color(80, 255, 80), Color(0, 180, 0)) then
                self:SendAction(1)
            end

            draw.SimpleText("Aim at the panel and click", "DermaDefault", 0, h / 2 - 36, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        elseif state == self.STATE_HACKING then
            draw.SimpleText("[ DOWNLOADING... ]", "DermaDefaultBold", 0, -h / 2 + 64, Color(255, 150, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            local hacker = self:GetHacker()
            if IsValid(hacker) then
                draw.SimpleText("OPERATIVE: " .. hacker:Nick(), "DermaDefault", 0, -h / 2 + 90, Color(255, 200, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            self:DrawProgressBar(borderColor, progress)

            -- Only the active hacker gets a clickable cancel control.
            if hacker == LocalPlayer() then
                local bw, bh = 180, 44
                if imgui.xTextButton("CANCEL", "!Roboto@26", -bw / 2, h / 2 - 64, bw, bh, 2,
                        Color(255, 150, 150), Color(255, 90, 90), Color(200, 0, 0)) then
                    self:SendAction(2)
                end
            else
                draw.SimpleText("Stay within range...", "DermaDefault", 0, h / 2 - 36, Color(255, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

        elseif state == self.STATE_COMPLETED then
            draw.SimpleText("[ COMPLETE ]", "DermaDefaultBold", 0, -h / 2 + 64, Color(0, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            self:DrawProgressBar(borderColor, 1)
        end

        -- Crosshair showing exactly where the player is pointing on the panel.
        imgui.xCursor()
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

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "sci_pointshop_entity_base_ui"

ENT.PrintName = "Radar Screen"
ENT.Category = "Pointshop Entities"
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.IconPath = "entities/sci_pointshop_base_radar_screen.png"
ENT.IconOffset = Vector(-45, 0, 0)

-- Physical model
ENT.BaseModel = "models/hunter/plates/plate1x1.mdl"
ENT.BaseMaterial = "hunter/myplastic"
ENT.BaseColor = Color(80, 80, 80, 255)

-- Radar settings
ENT.RadarRange = 22500
ENT.RadarSweepSpeed = 90
ENT.PingLifetime = 3

-- Screen positioning
ENT.RadarScreenOffset = Vector(0, 0, 2)
ENT.RadarScreenSize = 256
ENT.RadarScreenScale = 0.15
ENT.Decaytime = -1

-- Don't need attachments for this entity.
ENT.Attachments = {}

-- Allegiance / detection sound settings
ENT.HostileDetectSound = "buttons/bell1.wav"
ENT.HostileDetectSoundPitch = 50
ENT.HostileDetectSoundLevel = 60

ENT.MaxHealth = 125
ENT.HealthRegen = 3 -- health regenerated per second
ENT.CustomMass = 50

ENT.CableOffset = Vector(0, 0, 0)

-- Power: this entity is a consumer, drawing from whatever
-- mainframe it's wired to. It only actually runs when BOTH the
-- player has switched it on (the existing Powered toggle) AND
-- the mainframe is supplying it enough power.
ENT.PowerRole = "consumer"
ENT.PowerRequired = 50

ENT.CollideSounds = {
    "physics/glass/glass_sheet_step1.wav",
    "physics/glass/glass_sheet_step2.wav",
    "physics/glass/glass_sheet_step3.wav",
    "physics/glass/glass_sheet_step4.wav"
}

if SERVER then

---------------------------------------------------------
-- Networking strings
---------------------------------------------------------

	util.AddNetworkString("SCI_Radar_OpenMenu")
	util.AddNetworkString("SCI_Radar_TogglePower")
	util.AddNetworkString("SCI_Radar_SetAllegiance")
	util.AddNetworkString("SCI_Radar_AllegianceSync")

    ---------------------------------------------------------
    -- Setup
    ---------------------------------------------------------

    function ENT:Initialize()

		if self.BaseClass and self.BaseClass.Initialize then
			self.BaseClass.Initialize(self)
		end

        self:SetUseType(SIMPLE_USE)

        -- Powered state, replicated to clients automatically. This
        -- is the player's manual on/off toggle -- separate from
        -- HasPower (whether a mainframe is actually supplying
        -- power). The radar only really runs when both are true.
        self:SetNWBool("Powered", true)

        -- Whether a linked mainframe is currently supplying this
        -- entity's power requirement. Set by SetPowered(), called
        -- by the mainframe each power tick.
        self.HasPower = false
        self:SetNWBool("HasPower", false)

        -- Allegiance table, keyed by SteamID64.
        -- Not networked directly (arbitrary player set), instead
        -- pushed to clients manually via net messages.
        self.Allegiance = self.Allegiance or {}

        self.Attachments = self.Attachments or {}

        self.RadarAngle = 0
        self.LastThinkTime = CurTime()

        -- The base's Use() now always opens the shared button
        -- menu instead of calling this entity's own Use()
        -- directly, so the radar's power/allegiance panel is
        -- opened via a "Configure" button instead. Picking this
        -- entity up with +use doesn't make sense, so the default
        -- "Pick up" button the base adds is removed.
        self:RemoveMenuButton("pickup")
        self:AddMenuButton("configure", "Configure", function(ent, activator)
            ent:OpenConfigureMenu(activator)
        end)

        self:NextThink(CurTime())
    end

    ---------------------------------------------------------
    -- Send the full allegiance table to one player (or
    -- broadcast to everyone if no player is given).
    ---------------------------------------------------------

    function ENT:SyncAllegiance(target)

        net.Start("SCI_Radar_AllegianceSync")
            net.WriteEntity(self)

            local list = {}

            for steamID, allegiance in pairs(self.Allegiance) do
                list[#list + 1] = { steamID, allegiance }
            end

            net.WriteUInt(#list, 16)

            for _, entry in ipairs(list) do
                net.WriteString(entry[1])
                net.WriteBool(entry[2] == "ally")
            end

        if IsValid(target) then
            net.Send(target)
        else
            net.Broadcast()
        end
    end

    ---------------------------------------------------------
    -- Send a fresh sync to anyone who is close enough to
    -- have this radar's screen relevant to them, whenever
    -- they spawn/reconnect. Simplest reliable approach: sync
    -- to a player the moment they open the menu, and
    -- broadcast whenever the table changes.
    ---------------------------------------------------------

    function ENT:OpenConfigureMenu(activator)

        if not IsValid(activator) or not activator:IsPlayer() then return end

        -- Make sure the player has an up to date view of the
        -- allegiance table before they open the menu.
        self:SyncAllegiance(activator)

        net.Start("SCI_Radar_OpenMenu")
            net.WriteEntity(self)
            net.WriteBool(self:GetNWBool("Powered", true))

            local steamID = activator:SteamID64()
            local current = self.Allegiance[steamID] or "hostile"

            net.WriteBool(current == "ally")
        net.Send(activator)
    end

    ---------------------------------------------------------
    -- Handle the "on/off" button.
    ---------------------------------------------------------

    net.Receive("SCI_Radar_TogglePower", function(len, ply)

        local ent = net.ReadEntity()

        if not IsValid(ent) or not ent.SetNWBool then return end
        if not IsValid(ply) then return end

        -- Only let players who can actually use the entity
        -- toggle it (basic sanity check against arbitrary
        -- net spam targeting unrelated entities).
        if ply:GetPos():DistToSqr(ent:GetPos()) > (512 * 512) then return end

        ent:SetNWBool("Powered", not ent:GetNWBool("Powered", true))
    end)

    ---------------------------------------------------------
    -- Handle the "ally/hostile" button.
    ---------------------------------------------------------

    net.Receive("SCI_Radar_SetAllegiance", function(len, ply)

        local ent = net.ReadEntity()
        local wantsAlly = net.ReadBool()

        if not IsValid(ent) or not ent.Allegiance then return end
        if not IsValid(ply) then return end

        if ply:GetPos():DistToSqr(ent:GetPos()) > (512 * 512) then return end

        local steamID = ply:SteamID64()

        ent.Allegiance[steamID] = wantsAlly and "ally" or "hostile"

        -- Everyone needs to know about this change, since any
        -- radar within range will care about this player's
        -- allegiance when drawing / deciding to play a sound.
        ent:SyncAllegiance(nil)
    end)

    ---------------------------------------------------------
    -- Power interface, called by a linked mainframe.
    ---------------------------------------------------------

    -- The mainframe calls this every power tick to decide how
    -- much of its budget to reserve for this entity. A radar
    -- that's been manually switched off (the player's on/off
    -- toggle, separate from HasPower) shouldn't hold onto any
    -- power at all, so it reports zero draw while off instead of
    -- always requesting the full PowerRequired -- otherwise a
    -- switched-off radar still occupies power a mainframe could
    -- give to something else.
    function ENT:GetPowerRequired()
        if not self:GetNWBool("Powered", true) then return 0 end
        return self.PowerRequired or 50
    end

    -- Called by the mainframe once per power tick with whether
    -- this entity is currently receiving enough power. Only
    -- reacts (sound, chat feedback) on an actual state change.
    function ENT:SetPowered(hasPower)
        hasPower = hasPower and true or false

        if hasPower == self.HasPower then return end

        self.HasPower = hasPower
        self:SetNWBool("HasPower", hasPower)

        if not hasPower then
            self:EmitSound("buttons/button10.wav", 60, 70)
        end
    end

    ---------------------------------------------------------
    -- Look up a player's allegiance. Defaults to "hostile"
    -- for anyone who hasn't declared themselves.
    ---------------------------------------------------------

    function ENT:GetAllegiance(ply)

        if not IsValid(ply) or not ply:IsPlayer() then return "hostile" end

        return self.Allegiance[ply:SteamID64()] or "hostile"
    end

    ---------------------------------------------------------
    -- Get a yaw-only forward basis (mirrors the client's
    -- version) so server-side detection uses the same
    -- orientation logic regardless of the prop's tilt.
    ---------------------------------------------------------

    function ENT:GetFlatAngle()
        local ang = self:GetAngles()
        return Angle(0, ang.y, 0)
    end

    ---------------------------------------------------------
    -- Server-side sweep check. This exists purely to detect
    -- hostile players crossing the sweep so the entity can
    -- emit a sound everyone nearby can hear - it does not
    -- drive any visuals (the client already does that on its
    -- own for pings/drawing).
    ---------------------------------------------------------

    function ENT:CheckHostileSweep(oldAngle, newAngle)

        local radarPos = self:GetPos()

        for _, ply in ipairs(player.GetAll()) do

            if not IsValid(ply) or not ply:Alive() then
                continue
            end

            if self:GetAllegiance(ply) == "ally" then
                continue
            end

            local offset = ply:GetPos() - radarPos
            local distance = offset:Length()

            if distance > self.RadarRange then
                continue
            end

            -- Mirrors WorldToRadar's (x, y) computation (that
            -- function only exists client-side) so the sound
            -- fires on the same bearing convention the client
            -- draws the sweep line and pings with: x is measured
            -- against -right, y against forward, then atan2(x, y)
            -- to match the sweep's sin/cos parameterization.
            local radarAngle = self:GetFlatAngle()

            local forward = radarAngle:Forward()
            local right = radarAngle:Right()

            local x = -offset:Dot(right)
            local y = offset:Dot(forward)

            local targetAngle =
                math.deg(math.atan2(x, y)) % 360

            local previous = oldAngle % 360
            local current = newAngle % 360

            local crossed = false

            if current >= previous then
                crossed =
                    targetAngle >= previous and
                    targetAngle <= current
            else
                crossed =
                    targetAngle >= previous or
                    targetAngle <= current
            end

            if crossed then
                self:EmitSound(
                    self.HostileDetectSound,
                    self.HostileDetectSoundLevel,
                    self.HostileDetectSoundPitch,
                    1,
                    CHAN_STATIC
                )
            end
        end
    end

    ---------------------------------------------------------
    -- Server think - only runs the sweep while powered.
    ---------------------------------------------------------

    function ENT:Think()

        if not self:GetNWBool("Powered", true) or not self.HasPower then
            self:NextThink(CurTime())
            return true
        end

        local currentTime = CurTime()

        local delta = currentTime - (self.LastThinkTime or currentTime)
        self.LastThinkTime = currentTime

        local oldAngle = self.RadarAngle or 0

        self.RadarAngle =
            (oldAngle + self.RadarSweepSpeed * delta) % 360

        self:CheckHostileSweep(oldAngle, self.RadarAngle)

        self:NextThink(CurTime())

        return true
    end

    -- The base's OnRemove (decay/regen timer cleanup) was never
    -- being called before, since this entity didn't define its
    -- own server-side OnRemove at all. Also unlinks from any
    -- mainframe this radar was wired to.
    function ENT:OnRemove()
        if self.BaseClass and self.BaseClass.OnRemove then
            self.BaseClass.OnRemove(self)
        end

        self:UnlinkMainframe()
    end

end

if CLIENT then

    surface.CreateFont("EryRadarText", {
        font = "Tahoma",
        size = 18,
        weight = 600,
    })

    surface.CreateFont("EryRadarNameText", {
        font = "Tahoma",
        size = 14,
        weight = 600,
    })

    function ENT:Initialize()
        self.Pings = {}
        self.RadarAngle = 0
        self.LastSweepAngle = 0

        -- Local cache of allegiance, synced from the server.
        -- Keyed by SteamID64, value is "ally" or "hostile".
        self.Allegiance = {}

        self.Attachments = self.Attachments or {}
    end

    ---------------------------------------------------------
    -- Allegiance sync from the server.
    ---------------------------------------------------------

    net.Receive("SCI_Radar_AllegianceSync", function(len)

        local ent = net.ReadEntity()

        if not IsValid(ent) or not ent.Allegiance then return end

        local count = net.ReadUInt(16)

        local newTable = {}

        for i = 1, count do
            local steamID = net.ReadString()
            local isAlly = net.ReadBool()

            newTable[steamID] = isAlly and "ally" or "hostile"
        end

        ent.Allegiance = newTable
    end)

    ---------------------------------------------------------
    -- Look up a player's cached allegiance client-side.
    ---------------------------------------------------------

    function ENT:GetAllegiance(ply)

        if not IsValid(ply) or not ply:IsPlayer() then return "hostile" end

        return self.Allegiance[ply:SteamID64()] or "hostile"
    end

    ---------------------------------------------------------
    -- Menu shown to the player on Use.
    ---------------------------------------------------------

    net.Receive("SCI_Radar_OpenMenu", function(len)

        local ent = net.ReadEntity()
        local powered = net.ReadBool()
        local isAlly = net.ReadBool()

        if not IsValid(ent) then return end

        if IsValid(ent.MenuPanel) then
            ent.MenuPanel:Remove()
        end

        local frame = vgui.Create("DFrame")
        frame:SetTitle(ent.PrintName or "Radar")
        frame:SetSize(260, 160)
        frame:Center()
        frame:MakePopup()
        frame:SetDeleteOnClose(true)

        ent.MenuPanel = frame

        ---------------------------------------------------
        -- Power toggle button
        ---------------------------------------------------

        local powerButton = vgui.Create("DButton", frame)
        powerButton:SetPos(20, 40)
        powerButton:SetSize(220, 40)
        powerButton:SetText(powered and "Turn Off" or "Turn On")

        powerButton.DoClick = function()

            net.Start("SCI_Radar_TogglePower")
                net.WriteEntity(ent)
            net.SendToServer()

            powered = not powered

            powerButton:SetText(powered and "Turn Off" or "Turn On")
        end

        ---------------------------------------------------
        -- Allegiance toggle button
        ---------------------------------------------------

        local allegianceButton = vgui.Create("DButton", frame)
        allegianceButton:SetPos(20, 90)
        allegianceButton:SetSize(220, 40)
        allegianceButton:SetText(
            isAlly and "Declare yourself as Hostile"
                or "Declare yourself as Ally"
        )

        allegianceButton.DoClick = function()

            isAlly = not isAlly

            net.Start("SCI_Radar_SetAllegiance")
                net.WriteEntity(ent)
                net.WriteBool(isAlly)
            net.SendToServer()

            allegianceButton:SetText(
                isAlly and "Declare yourself as Hostile"
                    or "Declare yourself as Ally"
            )
        end
    end)

    ---------------------------------------------------------
    -- Add a radar ping
    ---------------------------------------------------------

    function ENT:AddRadarPing(ply)
        if not IsValid(ply) then return end

        self.Pings[#self.Pings + 1] = {
            Entity = ply,
            Position = ply:GetPos(),
            Time = CurTime(),
            Allegiance = self:GetAllegiance(ply)
        }
    end

    ---------------------------------------------------------
    -- Get a yaw-only forward/right basis, ignoring the
    -- prop's pitch and roll so the radar always reads flat
    -- relative to the world, regardless of orientation.
    ---------------------------------------------------------

    function ENT:GetFlatAngle()
        local ang = self:GetAngles()
        return Angle(0, ang.y, 0)
    end

    function ENT:GetFlatForward()
        return self:GetFlatAngle():Forward()
    end

    function ENT:GetFlatRight()
        return self:GetFlatAngle():Right()
    end

    ---------------------------------------------------------
    -- Check whether the sweep crossed a player
    ---------------------------------------------------------

    function ENT:CheckRadarSweep(oldAngle, newAngle)

        local radarPos = self:GetPos()

        for _, ply in ipairs(player.GetAll()) do

            if not IsValid(ply) or not ply:Alive() then
                continue
            end

            -- Don't detect players outside the radar's range.
            local offset = ply:GetPos() - radarPos
            local distance = offset:Length()

            if distance > self.RadarRange then
                continue
            end

            -- Derive the target's bearing from the exact same
            -- x/y that WorldToRadar produces for its on-screen
            -- position, using atan2 with the arguments in the
            -- same (x, y) order as the sweep line's sin/cos
            -- parameterization (sweepX = sin, sweepY = cos).
            -- Re-deriving this from offset:Angle() independently
            -- risks picking a different (mirrored) convention
            -- than the dot is actually drawn with -- which is
            -- exactly what caused the sweep and the pings to
            -- disagree about which side a target was on.
            local x, y = self:WorldToRadar(ply:GetPos())

            local targetAngle =
                math.deg(math.atan2(x, y)) % 360

            local previous = oldAngle % 360
            local current = newAngle % 360

            local crossed = false

            if current >= previous then
                crossed =
                    targetAngle >= previous and
                    targetAngle <= current
            else
                crossed =
                    targetAngle >= previous or
                    targetAngle <= current
            end

            if crossed then
                self:AddRadarPing(ply)
            end
        end
    end

    ---------------------------------------------------------
    -- Radar animation
    ---------------------------------------------------------

    function ENT:Think()

        local currentTime = CurTime()

        if not self.LastThinkTime then
            self.LastThinkTime = currentTime
            self.LastSweepAngle = 0
        end

        local delta = currentTime - self.LastThinkTime
        self.LastThinkTime = currentTime

        -- Only sweep and detect while powered. The sweep angle
        -- (and any existing pings) simply freeze while off.
        if self:GetNWBool("Powered", true) and self:GetNWBool("HasPower", false) then

            local oldAngle = self.RadarAngle

            self.RadarAngle =
                (self.RadarAngle + self.RadarSweepSpeed * delta) % 360

            self:CheckRadarSweep(oldAngle, self.RadarAngle)
        end

        -- Remove expired pings.
        for i = #self.Pings, 1, -1 do
            local ping = self.Pings[i]

            if currentTime - ping.Time >= self.PingLifetime then
                table.remove(self.Pings, i)
            end
        end

        self:SetNextClientThink(CurTime())

        return true
    end

    ---------------------------------------------------------
    -- Convert a world position into radar-screen coordinates
    ---------------------------------------------------------

	function ENT:WorldToRadar(pos)
		local offset = pos - self:GetPos()

		local forward = self:GetFlatForward()
		local right = self:GetFlatRight()

		local x = -offset:Dot(right)
		local y = offset:Dot(forward)

		local range = self.RadarRange

		local radarX = x / range
		local radarY = y / range

		return radarX, radarY
	end

    ---------------------------------------------------------
    -- Draw the radar screen
    ---------------------------------------------------------

    function ENT:DrawRadarScreen()

		local pos =
			self:GetPos() +
			self:GetUp() * self.RadarScreenOffset.z

		local ang = self:GetAngles()

		-- Make the radar screen lie flat on the top surface.
		ang:RotateAroundAxis(ang:Up(), 90)

		local size = self.RadarScreenSize
		local scale = self.RadarScreenScale or 0.05

		cam.Start3D2D(pos, ang, scale)

            -------------------------------------------------
            -- Background
            -------------------------------------------------

            surface.SetDrawColor(5, 20, 5, 245)
            surface.DrawRect(
                -size / 2,
                -size / 2,
                size,
                size
            )

            -------------------------------------------------
            -- Radar circles
            -------------------------------------------------

            surface.SetDrawColor(20, 100, 20, 120)

            for radius = 0.25, 1, 0.25 do

                local r = size * 0.48 * radius

                draw.NoTexture()

                surface.DrawCircle(
                    0,
                    0,
                    r,
                    20,
                    100,
                    20,
                    120
                )
            end

            -------------------------------------------------
            -- Crosshair
            -------------------------------------------------

            surface.SetDrawColor(20, 100, 20, 100)

            surface.DrawRect(
                -1,
                -size * 0.48,
                2,
                size * 0.96
            )

            surface.DrawRect(
                -size * 0.48,
                -1,
                size * 0.96,
                2
            )

            local manuallyOn = self:GetNWBool("Powered", true)
            local hasPower = self:GetNWBool("HasPower", false)
            local powered = manuallyOn and hasPower

            -------------------------------------------------
            -- Radar sweep (only drawn while powered)
            -------------------------------------------------

            if powered then

                local sweepRad = math.rad(self.RadarAngle)

                local sweepX =
                    math.sin(sweepRad) * size * 0.48

                local sweepY =
                    math.cos(sweepRad) * size * 0.48

                surface.SetDrawColor(80, 255, 80, 180)

                surface.DrawLine(
                    0,
                    0,
                    sweepX,
                    sweepY
                )
            end

            -------------------------------------------------
            -- Player pings
            -------------------------------------------------

            for _, ping in ipairs(self.Pings) do

                if not IsValid(ping.Entity) then
                    continue
                end

                local age = CurTime() - ping.Time

                if age >= self.PingLifetime then
                    continue
                end

                local x, y =
                    self:WorldToRadar(ping.Position)

                local screenX =
                    x * size * 0.48

                local screenY =
                    y * size * 0.48

                -- Fade during the last second.
                local alpha = 255

                if age > self.PingLifetime - 1 then
                    alpha =
                        255 *
                        (self.PingLifetime - age)
                end

                -- Don't draw outside the radar.
                if math.sqrt(x * x + y * y) <= 1 then

                    local isAlly = ping.Allegiance == "ally"

                    local r, g, b

                    if isAlly then
                        r, g, b = 80, 255, 80
                    else
                        r, g, b = 255, 60, 60
                    end

                    surface.SetDrawColor(r, g, b, alpha)

                    draw.NoTexture()

                    surface.DrawCircle(
                        screenX,
                        screenY,
                        5,
                        r,
                        g,
                        b,
                        alpha
                    )

                    -- Only allies have their names shown.
                    if isAlly then

                        draw.SimpleText(
                            ping.Entity:Nick(),
                            "EryRadarNameText",
                            screenX,
                            screenY + 10,
                            Color(r, g, b, alpha),
                            TEXT_ALIGN_CENTER,
                            TEXT_ALIGN_TOP
                        )
                    end
                end
            end

            -------------------------------------------------
            -- Center marker
            -------------------------------------------------

            surface.SetDrawColor(100, 255, 100, 255)

            draw.NoTexture()

            surface.DrawCircle(
                0,
                0,
                3,
                100,
                255,
                100,
                255
            )

            -------------------------------------------------
            -- Text
            -------------------------------------------------

            local statusText = "SCANNING..."
            if not manuallyOn then
                statusText = "OFFLINE"
            elseif not hasPower then
                statusText = "NO POWER"
            end

            draw.SimpleText(
                statusText,
                "EryRadarText",
                0,
                size * 0.40,
                Color(100, 255, 100, 220),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )

        cam.End3D2D()
    end

    ---------------------------------------------------------
    -- Entity drawing
    ---------------------------------------------------------

    function ENT:Draw()

        self:DrawModel()

        local attachDist = (self.AttachmentDrawDistance or 500)^2
        if self:GetPos():DistToSqr(LocalPlayer():GetPos()) <= attachDist then
            ERY_MACHINE:DrawAttachments(self, self.Attachments)
        end

        local distance =
            (self:GetPos() - LocalPlayer():GetPos()):Length()

        if distance <= 1000 then
            self:DrawRadarScreen()
        end

        -- Icon, name, and healthbar, drawn last so the radar
        -- screen (which sits on the model) doesn't get drawn
        -- over top of it, and so the label still shows up.
        self:DrawLabel()
    end

    function ENT:OnRemove()

        if IsValid(self.MenuPanel) then
            self.MenuPanel:Remove()
        end

        ERY_MACHINE:CleanupAttachments(self)
    end

end
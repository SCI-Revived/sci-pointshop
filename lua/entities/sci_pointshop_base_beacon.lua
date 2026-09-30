AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "sci_pointshop_entity_base_ui"

ENT.PrintName = "Beacon"
ENT.Author = "Paloma"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "Pointshop Entities"

ENT.IconPath = "entities/sci_pointshop_base_beacon.png"
ENT.IconOffset = Vector(0, 20, 70)

ENT.BaseModel = "models/props_c17/oildrum001.mdl"
ENT.BaseMaterial = "models/effects/intro_tearshape"
ENT.BaseColor = Color(80, 80, 80, 255)
ENT.BoneScale = Vector(1, 1, 1)

ENT.AttachmentDrawDistance = 7500
ENT.LabelDrawDistance = 300
ENT.Decaytime = -1

ENT.MaxHealth = 500
ENT.HealthRegen = 1

-- Power: this entity is a consumer, drawing from whatever
-- mainframe it's wired to. Pulses only apply their effect when
-- BOTH the player has switched the beacon on (Active) AND the
-- mainframe is supplying it enough power.
ENT.PowerRole = "consumer"
ENT.PowerRequired = 125
ENT.CustomMass = 250

ENT.CableOffset = Vector(0, 0, 7)

if SERVER then
    util.AddNetworkString("ery_beacon_open")
    util.AddNetworkString("ery_beacon_set")
    util.AddNetworkString("ery_beacon_toggle")
    util.AddNetworkString("ery_beacon_set_allegiance")
    util.AddNetworkString("ery_beacon_clear_allies")
end

ENT.Attachments = {
    {
		ID = 1,
        Model = "models/props_combine/combine_mine01.mdl",
        Pos = Vector(0, 0, 25),
        Angle = Angle(0, 0, 180),
        Color = Color(255, 255, 255),
        Material = "",
        Scale = 1,
		AxisScale = Vector(1.25, 1.25, 1.5),
		Parent = 0
    },

    {
		ID = 2,
        Model = "models/props_wasteland/light_spotlight02_lamp.mdl",
        Pos = Vector(0, 0, 23),
        Angle = Angle(90, 0, 0),
        Color = Color(0, 255, 0),
        Material = "",
        Scale = 1,
		AxisScale = Vector(0.5, 1.5, 1.5),
		Parent = 0
    },

    {
		ID = 3,
        Model = "models/props_wasteland/lighthouse_fresnel_light_base.mdl",
        Pos = Vector(0, 0, 2.5),
        Angle = Angle(0, 0, 0),
        Color = Color(0, 255, 0),
        Material = "",
        Scale = 1,
		AxisScale = Vector(0.25, 0.25, 0.25),
		Parent = 0
    },

    {
		ID = 4,
        Model = "models/props_lab/labpart.mdl",
        Pos = Vector(0, -0.5, -10),
        Angle = Angle(0, 0, 90),
        Color = Color(0, 255, 0),
        Material = "",
        Scale = 1,
		AxisScale = Vector(0.9, 0.9, 0.9),
		Parent = 1
    },
}

-- Beacon effects

local BeaconEffects = {
    Healing = {
        display = "Health Regeneration",

        apply = function(target, multiplier, level)
            if not IsValid(target) then return end

            if isfunction(target.ApplyEffect) then
                target:ApplyEffect("Healing", multiplier, 1 * level, 1)
            end
        end
    },

    Endurance = {
        display = "Damage Resistance",

        apply = function(target, multiplier, level)
            if not IsValid(target) then return end

            if isfunction(target.ApplyEffect) then
                target:ApplyEffect("Endurance", multiplier, 10 * level)
            end
        end
    },

    Energized = {
        display = "Armor Regeneration",

        apply = function(target, multiplier, level)
            if not IsValid(target) then return end

            if isfunction(target.ApplyEffect) then
                target:ApplyEffect("Energized", multiplier, 1 * level, 1)
            end
        end
    },

    Tenacity = {
        display = "Debuff Resistance",

        apply = function(target, multiplier, level)
            if not IsValid(target) then return end

            if isfunction(target.ApplyEffect) then
                target:ApplyEffect("Tenacity", multiplier, 33 * level + 1)
            end
        end
    },

    DamageUp = {
        display = "Damage Boost",

        apply = function(target, multiplier, level)
            if not IsValid(target) then return end

            if isfunction(target.ApplyEffect) then
                target:ApplyEffect("DamageUp", multiplier, 15 * level + 1)
            end
        end
    },
}

local BeaconEffectNames = {}

for effectName, _ in pairs(BeaconEffects) do
    table.insert(BeaconEffectNames, effectName)
end

table.sort(BeaconEffectNames)

ENT.BeaconEffect = "Healing"
ENT.BeaconIntensity = 1
ENT.Active = false

ENT.CollideSounds = {
    "physics/metal/metal_barrel_impact_hard1.wav",
    "physics/metal/metal_barrel_impact_hard2.wav",
    "physics/metal/metal_barrel_impact_hard3.wav",
    "physics/metal/metal_barrel_impact_hard5.wav",
    "physics/metal/metal_barrel_impact_hard6.wav",
    "physics/metal/metal_barrel_impact_hard7.wav"
}

-- Server

if SERVER then

    local PulseInterval = 5

    local EffectMultiplier = 7

    local IntensitySettings = {
        [1] = {
            range = 2000,
            mult = 1
        },

        [2] = {
            range = 1000,
            mult = 2
        },

        [3] = {
            range = 500,
            mult = 3
        }
    }

    function ENT:Initialize()

        -- Model, material, color, bone scale, physics, mass,
        -- decay timer, and health/regen are all handled by
        -- sci_pointshop_entity_base_ui. Only beacon-specific state is set
        -- up here.
        self.BaseClass.Initialize(self)

        self:SetNW2String(
            "BeaconEffect",
            self.BeaconEffect
        )

        self:SetNW2Int(
            "BeaconIntensity",
            self.BeaconIntensity
        )

        self:SetNW2Bool(
            "Active",
            self.Active
        )

        -- Whether a linked mainframe is currently supplying this
        -- entity's power requirement. Set by SetPowered(), called
        -- by the mainframe each power tick. The beacon only
        -- actually pulses when both Active and HasPower are true.
        self.HasPower = false
        self:SetNW2Bool("HasPower", false)

        self.NextPulse = CurTime() + PulseInterval

        -- Per-player allegiance table, keyed by SteamID64 so it
        -- survives reconnects. true = friendly (receives the
        -- beacon's effect), anything else (including unset) =
        -- hostile (ignored). Not networked -- server-authoritative
        -- data, no client needs it.
        self.Allegiance = {}

        -- The base's Use() now always opens the shared button
        -- menu instead of calling this entity's own Use()
        -- directly, so the beacon's effect/intensity/toggle panel
        -- is opened via a "Configure" button instead. Picking
        -- this entity up with +use doesn't make sense, so the
        -- default "Pick up" button the base adds is removed.
        self:RemoveMenuButton("pickup")
        self:AddMenuButton("configure", "Configure", function(ent, activator)
            ent:OpenConfigureMenu(activator)
        end)
    end

    function ENT:OpenConfigureMenu(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return end

        local isFriendly = self:IsFriendly(ply)

        net.Start("ery_beacon_open")
            net.WriteEntity(self)
            net.WriteString(
                self.BeaconEffect
                or BeaconEffectNames[1]
            )
            net.WriteUInt(
                self.BeaconIntensity or 1,
                4
            )
            net.WriteBool(
                self.Active or false
            )
            net.WriteBool(isFriendly)
        net.Send(ply)
    end

    function ENT:SetAllegiance(ply, friendly)
        if not IsValid(ply) or not ply:IsPlayer() then return end

        self.Allegiance[ply:SteamID64()] = friendly and true or nil

        ply:ChatPrint(
            "[Beacon] You are now marked as "
            .. (friendly and "FRIENDLY" or "HOSTILE")
            .. " to this beacon."
        )
    end

    function ENT:IsFriendly(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return false end
        return self.Allegiance[ply:SteamID64()] == true
    end

    -- Wipes every recorded allegiance, so nobody receives the
    -- beacon's effect until they declare themselves friendly again.
    function ENT:ClearAllegiance()
        self.Allegiance = {}
    end

    function ENT:ToggleActive()

        self.Active = not self.Active

        self:SetNW2Bool(
            "Active",
            self.Active
        )

        if self.Active then

            self:EmitSound(
                "ambient/machines/air_conditioner_cycle.wav",
                80,
                100
            )

            local timerName =
                "BeaconLoop_" .. self:EntIndex()

            timer.Create(
                timerName,
                2.7,
                0,
                function()

                    if not IsValid(self) or not self.Active then
                        timer.Remove(timerName)
                        return
                    end

                    self:EmitSound(
                        "ery_sound/erymachines/machinerydrone02.wav",
                        60,
                        100
                    )
                end
            )

        else

            self:EmitSound(
                "ambient/machines/spindown.wav",
                80,
                100
            )

            timer.Remove(
                "BeaconLoop_" .. self:EntIndex()
            )
        end
    end

    function ENT:SetConfig(effectName, intensity)

        if not BeaconEffects[effectName] then
            return
        end

        intensity = math.Clamp(
            math.floor(intensity or 1),
            1,
            3
        )

        self.BeaconEffect = effectName
        self.BeaconIntensity = intensity

        self:SetNW2String(
            "BeaconEffect",
            self.BeaconEffect
        )

        self:SetNW2Int(
            "BeaconIntensity",
            self.BeaconIntensity
        )
    end

    ---------------------------------------------------------
    -- Power interface, called by a linked mainframe.
    ---------------------------------------------------------

    -- The mainframe calls this every power tick to decide how
    -- much of its budget to reserve for this entity. A beacon
    -- that's been manually switched off (Active, the player's
    -- toggle -- separate from HasPower) shouldn't hold onto any
    -- power at all, so it reports zero draw while off instead of
    -- always requesting the full PowerRequired -- otherwise a
    -- switched-off beacon still occupies power a mainframe could
    -- give to something else.
    function ENT:GetPowerRequired()
        if not self.Active then return 0 end
        return self.PowerRequired or 75
    end

    -- Called by the mainframe once per power tick with whether
    -- this entity is currently receiving enough power. Only
    -- reacts (sound) on an actual state change. Doesn't touch
    -- Active -- the player's manual toggle and the loop sound
    -- stay as they are; only the pulse effect itself is gated on
    -- power (see Think()).
    function ENT:SetPowered(hasPower)
        hasPower = hasPower and true or false

        if hasPower == self.HasPower then return end

        self.HasPower = hasPower
        self:SetNW2Bool("HasPower", hasPower)

        if not hasPower and self.Active then
            self:EmitSound("buttons/button10.wav", 60, 70)
        end
    end

    net.Receive("ery_beacon_set", function(_, ply)

        local beacon = net.ReadEntity()

        if not IsValid(beacon) then return end
        if beacon:GetClass() ~= "sci_pointshop_base_beacon" then return end
        if not IsValid(ply) then return end

        local effectName = net.ReadString()
        local intensity = net.ReadUInt(4)

        beacon:SetConfig(
            effectName,
            intensity
        )

        ply:ChatPrint(
            "[Beacon] Settings updated."
        )
    end)

    net.Receive("ery_beacon_toggle", function(_, ply)

        local beacon = net.ReadEntity()

        if not IsValid(beacon) then return end
        if beacon:GetClass() ~= "sci_pointshop_base_beacon" then return end

        beacon:ToggleActive()
    end)

    net.Receive("ery_beacon_set_allegiance", function(_, ply)

        local beacon = net.ReadEntity()
        local friendly = net.ReadBool()

        if not IsValid(beacon) then return end
        if beacon:GetClass() ~= "sci_pointshop_base_beacon" then return end
        if not IsValid(ply) then return end

        beacon:SetAllegiance(ply, friendly)
    end)

    net.Receive("ery_beacon_clear_allies", function(_, ply)

        local beacon = net.ReadEntity()

        if not IsValid(beacon) then return end
        if beacon:GetClass() ~= "sci_pointshop_base_beacon" then return end
        if not IsValid(ply) then return end

        beacon:ClearAllegiance()
        ply:ChatPrint("[Beacon] Allegiance list cleared -- no one is friendly now.")
    end)

    function ENT:Think()

        local currentTime = CurTime()

        if self.Active
            and self.HasPower
            and currentTime >= (self.NextPulse or 0) then

            self.NextPulse =
                currentTime + PulseInterval

            local intensityData =
                IntensitySettings[self.BeaconIntensity]
                or IntensitySettings[1]

            local range =
                intensityData.range or 600

            local multiplier =
                intensityData.mult or 1

            local effect =
                BeaconEffects[self.BeaconEffect]

            if effect and effect.apply then

                local nearbyPlayers =
                    ents.FindInSphere(
                        self:GetPos(),
                        range
                    )

                for _, target in ipairs(nearbyPlayers) do

                    if IsValid(target)
                        and target:IsPlayer()
                        and target:Alive()
                        and self:IsFriendly(target) then

                        effect.apply(
                            target,
                            EffectMultiplier,
                            multiplier
                        )
                    end
                end
            end
        end

        self:NextThink(
            currentTime + 0.25
        )

        return true
    end

    function ENT:OnRemove()

        self.Active = false

        self:SetNW2Bool(
            "Active",
            false
        )

        timer.Remove(
            "BeaconLoop_" .. self:EntIndex()
        )

        self:UnlinkMainframe()

        -- Still run the base's own cleanup (decay/regen timers).
        self.BaseClass.OnRemove(self)
    end
end

-- Client

if CLIENT then

    net.Receive("ery_beacon_open", function()

        local beacon = net.ReadEntity()

        if not IsValid(beacon) then return end

        local currentEffect =
            net.ReadString()
            or BeaconEffectNames[1]

        local currentIntensity =
            net.ReadUInt(4)
            or 1

        local isActive =
            net.ReadBool()

        local isFriendly =
            net.ReadBool()

        local frame = vgui.Create("DFrame")

        frame:SetTitle(
            beacon.PrintName or "Beacon"
        )

        frame:SetSize(320, 270)
        frame:Center()
        frame:MakePopup()

        -- Effect label

        local effectLabel =
            vgui.Create("DLabel", frame)

        effectLabel:SetText(
            "Select effect:"
        )

        effectLabel:SetPos(8, 32)
        effectLabel:SizeToContents()

        -- Effect selector

        local effectCombo =
            vgui.Create("DComboBox", frame)

        effectCombo:SetPos(8, 54)

        effectCombo:SetSize(
            frame:GetWide() - 16,
            22
        )

        for _, effectName in ipairs(BeaconEffectNames) do

            local effect =
                BeaconEffects[effectName]

            if effect then
                effectCombo:AddChoice(
                    effect.display,
                    effectName
                )
            end
        end

        for index, effectName in ipairs(BeaconEffectNames) do

            if effectName == currentEffect then
                effectCombo:ChooseOptionID(index)
                break
            end
        end

        -- Intensity label

        local intensityLabel =
            vgui.Create("DLabel", frame)

        intensityLabel:SetText(
            "Intensity (1 = far/weak, 3 = near/strong):"
        )

        intensityLabel:SetPos(8, 84)
        intensityLabel:SizeToContents()

        -- Intensity slider

        local intensitySlider =
            vgui.Create("DNumSlider", frame)

        intensitySlider:SetPos(8, 110)

        intensitySlider:SetSize(
            frame:GetWide() - 16,
            24
        )

        intensitySlider:SetMin(1)
        intensitySlider:SetMax(3)
        intensitySlider:SetDecimals(0)
        intensitySlider:SetValue(currentIntensity)

        -- Apply button

        local applyButton =
            vgui.Create("DButton", frame)

        applyButton:SetPos(8, 140)

        applyButton:SetSize(
            (frame:GetWide() - 24) / 2,
            28
        )

        applyButton:SetText(
            "Apply Settings"
        )

        applyButton.DoClick = function()

            local _, selectedEffect =
                effectCombo:GetSelected()

            selectedEffect =
                selectedEffect
                or BeaconEffectNames[1]

            local intensity =
                math.Clamp(
                    math.floor(
                        intensitySlider:GetValue()
                    ),
                    1,
                    3
                )

            net.Start("ery_beacon_set")
                net.WriteEntity(beacon)
                net.WriteString(selectedEffect)
                net.WriteUInt(intensity, 4)
            net.SendToServer()

            frame:Close()
        end

        -- Toggle button

        local toggleButton =
            vgui.Create("DButton", frame)

        toggleButton:SetPos(
            16 + (frame:GetWide() - 24) / 2,
            140
        )

        toggleButton:SetSize(
            (frame:GetWide() - 24) / 2,
            28
        )

        toggleButton:SetText(
            isActive
            and "Turn OFF"
            or "Turn ON"
        )

        toggleButton.DoClick = function()

            net.Start("ery_beacon_toggle")
                net.WriteEntity(beacon)
            net.SendToServer()

            frame:Close()
        end

        -- Allegiance: only players marked friendly receive the
        -- beacon's effect.

        local statusLabel =
            vgui.Create("DLabel", frame)

        statusLabel:SetText(
            "This beacon is currently "
            .. (isFriendly
                and "treating you as FRIENDLY."
                or "treating you as HOSTILE (no effect).")
        )

        statusLabel:SetPos(8, 180)
        statusLabel:SetSize(frame:GetWide() - 16, 20)

        local allegianceButton =
            vgui.Create("DButton", frame)

        allegianceButton:SetPos(8, 204)
        allegianceButton:SetSize(frame:GetWide() - 16, 26)

        allegianceButton:SetText(
            isFriendly
            and "Declare myself HOSTILE"
            or "Declare myself FRIENDLY"
        )

        allegianceButton.DoClick = function()

            net.Start("ery_beacon_set_allegiance")
                net.WriteEntity(beacon)
                net.WriteBool(not isFriendly)
            net.SendToServer()

            frame:Close()
        end

        local clearAlliesButton =
            vgui.Create("DButton", frame)

        clearAlliesButton:SetPos(8, 234)
        clearAlliesButton:SetSize(frame:GetWide() - 16, 26)

        clearAlliesButton:SetText(
            "Clear ally list (make everyone hostile)"
        )

        clearAlliesButton.DoClick = function()

            net.Start("ery_beacon_clear_allies")
                net.WriteEntity(beacon)
            net.SendToServer()

            frame:Close()
        end
    end)

    -- Draws the beacon-specific status text (effect, intensity,
    -- active state). Kept separate from ENT:Draw() and from the
    -- base's DrawLabel() so it only appears when the base's own
    -- label is also showing (same eye-trace/distance gate),
    -- without duplicating that gating logic here.
    function ENT:DrawBeaconStatus()
        local effect =
            self:GetNW2String(
                "BeaconEffect",
                "Healing"
            )

        local intensity =
            self:GetNW2Int(
                "BeaconIntensity",
                1
            )

        local active =
            self:GetNW2Bool(
                "Active",
                false
            )

        local hasPower =
            self:GetNW2Bool(
                "HasPower",
                false
            )

        -- Positioned below the base's healthbar (icon 0..~64,
        -- name at 80, healthbar at 130-144, text at ~148).
        local statusY = 180

        draw.SimpleText(
            "Effect: " .. effect,
            "EryMatWorld",
            0,
            statusY,
            Color(200, 200, 255),
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_TOP
        )

        draw.SimpleText(
            "Intensity: " .. tostring(intensity),
            "EryMatWorld",
            0,
            statusY + 30,
            Color(200, 255, 200),
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_TOP
        )

        draw.SimpleText(
            "Active: " .. (
                active
                and "Yes"
                or "No"
            ),
            "EryMatWorld",
            0,
            statusY + 60,
            active
                and Color(100, 255, 100)
                or Color(255, 100, 100),
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_TOP
        )

        draw.SimpleText(
            "Power: " .. (
                hasPower
                and "Connected"
                or "No Power"
            ),
            "EryMatWorld",
            0,
            statusY + 90,
            hasPower
                and Color(100, 255, 100)
                or Color(255, 100, 100),
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_TOP
        )
    end

    -- Overrides the base's DrawLabel() only to append the
    -- beacon-specific status text after the shared icon, name,
    -- and healthbar are drawn. Relies on the base's return value
    -- to know whether the label is actually visible right now,
    -- rather than re-checking eye trace/distance here.
    function ENT:DrawLabel()
        local wasDrawn = self.BaseClass.DrawLabel(self)
        if not wasDrawn then return end

        local ply = LocalPlayer()
        local pos = self:LocalToWorld(self.IconOffset or Vector(0, 0, 60))
        local ang = ply:EyeAngles()
        ang:RotateAroundAxis(ang:Right(), 90)
        ang:RotateAroundAxis(ang:Up(), -90)

        cam.Start3D2D(pos, ang, 0.1)
            self:DrawBeaconStatus()
        cam.End3D2D()
    end

    -- Beacon head attachment only spins while the player has it
    -- switched on AND the mainframe is actually supplying power --
    -- same gate the server uses for the pulse effect (see
    -- SetPowered/Think on the server). Reads the networked
    -- Active/HasPower bools directly so no extra networking is
    -- needed here.
    local SpinSpeed = 90 -- degrees per second

    ---------------------------------------------------------
    -- Active-state visual effects, both built with the legacy
    -- ParticleEmitter/CLuaEmitter API (client-only, sprite-based --
    -- NOT the newer .pcf CreateParticleSystem system, which doesn't
    -- know these material paths):
    --   1. A green ring wave pulsing outward every RingInterval
    --      seconds, growing to roughly the beacon's real AoE
    --      radius right as it fades, so it reads as "this is the
    --      area being affected".
    --   2. A small green glow sitting above the model as a
    --      "core", refreshed every think while active.
    -- One CLuaEmitter is created per beacon instance (lazily, on
    -- first use) and reused for both effects for as long as the
    -- entity exists -- emitters are cheap to hold onto and
    -- expensive to recreate every pulse. It's explicitly
    -- :Finish()'d in OnRemove so nothing lingers after the
    -- entity is gone.
    ---------------------------------------------------------

    local RingInterval = 5       -- seconds between ring pulses
    local RingLifetime = 2       -- how long each ring particle lives
    local RingStartSize = 12     -- world units, size at spawn
    -- particle/particle_ring_wave_addnofog is a flat ring-shaped
    -- additive sprite -- grows via SetStartSize/SetEndSize below to
    -- visually communicate the beacon's AoE.
    local RingMaterial = "particle/particle_ring_wave_addnofog"

    local GlowMaterial = "particle/fire"
    local GlowSize = 56           -- world units
    local GlowInterval = 0.15     -- seconds between glow particle spawns
    local GlowDieTime = 0.15       -- lifetime of each glow particle -- shorter
                                   -- than GlowInterval on purpose, so each
                                   -- one fully dies before the next spawns,
                                   -- giving the flicker instead of a smooth
                                   -- continuous glow.

    -- Maps BeaconIntensity to the visual radius the ring should
    -- grow to by the end of its life, so the effect actually
    -- communicates the beacon's real AoE rather than an arbitrary
    -- fixed size. Mirrors the server's IntensitySettings ranges.
    local RingEndSizeByIntensity = {
        [1] = 2000,
        [2] = 1000,
        [3] = 500,
    }

    function ENT:GetEryEmitter()
        if not IsValid(self.__eryEmitter) then
            self.__eryEmitter = ParticleEmitter(self:GetPos(), false)
        end
        return self.__eryEmitter
    end

    -- Shared spawn point for both effects: the entity's true local
    -- "up" direction (self:GetUp(), not a fixed world +Z) times how
    -- far its model's bounding box actually extends upward
    -- (OBBMaxs().z), so the point sits right on top of the model's
    -- physical top face regardless of the entity's current angles --
    -- e.g. if it's tipped over or placed on a slope, "up" rotates
    -- with it instead of staying vertical in world space.
    function ENT:GetEffectSpawnPos()
        local topOffset = self:OBBMaxs().z + 10
        return self:GetPos() + self:GetUp() * topOffset
    end

    function ENT:SpawnRingWave()
        if not IsValid(self) then return end

        local emitter = self:GetEryEmitter()
        if not emitter then return end

        local pos = self:GetEffectSpawnPos()
        local particle = emitter:Add(RingMaterial, pos)
        if not particle then return end

        local intensity = self:GetNW2Int("BeaconIntensity", 1)
        local endSize = RingEndSizeByIntensity[intensity] or RingEndSizeByIntensity[1]

        particle:SetDieTime(RingLifetime)
        particle:SetLifeTime(0)

        -- Flat against the entity's top face, facing outward along
        -- its up vector.
        particle:SetAngles(self:GetAngles() + Angle(90, 0, 0))
        particle:SetRoll(0)

        particle:SetStartSize(RingStartSize)
        particle:SetEndSize(endSize)

        particle:SetStartAlpha(180)
        particle:SetEndAlpha(0)

        particle:SetColor(80, 255, 120)

        particle:SetVelocity(vector_origin)
        particle:SetGravity(vector_origin)
        particle:SetAirResistance(0)
    end

    -- Spawns a single glow particle at the shared effect spawn point.
    -- Called on its own GlowInterval timer (not every think) with a
    -- DieTime shorter than that interval, so each particle fully fades
    -- out before the next one spawns -- that gap is what reads as a
    -- flicker instead of a continuous glow.
    function ENT:SpawnGlowFlicker()
        if not IsValid(self) then return end

        local emitter = self:GetEryEmitter()
        if not emitter then return end

        local pos = self:GetEffectSpawnPos()
        local particle = emitter:Add(GlowMaterial, pos)
        if not particle then return end

        particle:SetDieTime(GlowDieTime)
        particle:SetLifeTime(0)

        particle:SetStartSize(GlowSize)
        particle:SetEndSize(GlowSize)

        particle:SetStartAlpha(220)
        particle:SetEndAlpha(0)

        particle:SetColor(80, 255, 120)

        particle:SetVelocity(vector_origin)
        particle:SetGravity(vector_origin)
        particle:SetAirResistance(0)
    end

    function ENT:Think()
        -- self.Attachments is already a private per-instance copy by
        -- this point -- sci_pointshop_entity_base_ui's client
        -- Initialize() deep-copies ENT.Attachments into self.Attachments
        -- before any entity thinks or draws, so mutating Angle below is
        -- safe and only affects this beacon.
        local attach = self.Attachments and self.Attachments[1]
        if not attach then return end

        local spinning =
            self:GetNW2Bool("Active", false)
            and self:GetNW2Bool("HasPower", false)

        if spinning then
            attach.Angle.y = (attach.Angle.y + FrameTime() * SpinSpeed) % 360
        elseif attach.Angle.y ~= 0 then
            -- Not spinning: ease back to resting angle instead of
            -- snapping, so powering off mid-spin doesn't look abrupt.
            local remaining = 360 - attach.Angle.y
            local step = FrameTime() * SpinSpeed

            if step >= remaining then
                attach.Angle.y = 0
            else
                attach.Angle.y = attach.Angle.y + step
                if attach.Angle.y >= 360 then
                    attach.Angle.y = 0
                end
            end
        end

        if spinning then
            self.__eryNextRing = self.__eryNextRing or 0
            self.__eryNextGlow = self.__eryNextGlow or 0

            if CurTime() >= self.__eryNextRing then
                self.__eryNextRing = CurTime() + RingInterval
                self:SpawnRingWave()
            end

            if CurTime() >= self.__eryNextGlow then
                self.__eryNextGlow = CurTime() + GlowInterval
                self:SpawnGlowFlicker()
            end
        else
            self.__eryNextRing = nil
            self.__eryNextGlow = nil
        end
    end

    -- Releases this beacon's particle emitter. CLuaEmitter:Finish()
    -- doesn't force-kill particles that are still alive -- it just
    -- stops accepting new ones and lets the engine clean the emitter
    -- up once its existing particles finish dying out on their own,
    -- which is what we want: any in-flight ring wave still plays out
    -- fully instead of popping out of existence.
    function ENT:CleanupEryEmitter()
        if IsValid(self.__eryEmitter) then
            self.__eryEmitter:Finish()
        end
        self.__eryEmitter = nil
    end

    function ENT:OnRemove()
        self:CleanupEryEmitter()

        -- Still run the base's own cleanup (removes the clientside
        -- attachment models via ERY_MACHINE:CleanupAttachments).
        self.BaseClass.OnRemove(self)
    end
end
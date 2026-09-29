AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "sci_pointshop_entity_base_ui"

ENT.PrintName = "Sentry Turret"
ENT.Author = "Paloma"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "Pointshop Entities"

ENT.IconPath = "entities/sci_pointshop_base_turret.png"
ENT.IconOffset = Vector(0, 0, 77)

-- Temporary placeholder body model. The minigun attachment (ID 1
-- below) is the visual "head" that aims at targets; this base
-- model does not rotate.
ENT.BaseModel = "models/props_wasteland/gaspump001a.mdl"
ENT.BaseMaterial = "models/effects/intro_tearshape"
ENT.BaseColor = Color(255, 255, 255, 255)
ENT.BoneScale = Vector(1, 1, 1)

ENT.AttachmentDrawDistance = 7500
ENT.LabelDrawDistance = 300
ENT.Decaytime = -1

ENT.MaxHealth = 500
ENT.HealthRegen = 1

-- Power: consumer, same contract as the beacon -- GetPowerRequired()
-- reports 0 while switched off, SetPowered() is called by the
-- mainframe each tick. The turret only scans/fires while both
-- Active (player toggle) and HasPower are true.
ENT.PowerRole = "consumer"
ENT.PowerRequired = 100
ENT.CustomMass = 250

ENT.CableOffset = Vector(0, 0, 35)

-- Player-controlled on/off toggle, same role as the beacon's
-- Active. Declared at file scope (not just set in Initialize) so
-- it has a real default before Initialize() networks it -- an
-- un-set self.Active would network as nil instead of false.
ENT.Active = false

ENT.CollideSounds = {
    "physics/metal/metal_barrel_impact_hard1.wav",
    "physics/metal/metal_barrel_impact_hard2.wav",
    "physics/metal/metal_barrel_impact_hard3.wav",
    "physics/metal/metal_barrel_impact_hard5.wav",
    "physics/metal/metal_barrel_impact_hard6.wav",
    "physics/metal/metal_barrel_impact_hard7.wav"
}

if SERVER then
    util.AddNetworkString("ery_turret_open")
    util.AddNetworkString("ery_turret_toggle")
    util.AddNetworkString("ery_turret_set_allegiance")
    util.AddNetworkString("ery_turret_clear_allies")
    util.AddNetworkString("ery_turret_fired")
end

ENT.Attachments = {
    {
        ID = 1,
        -- The "turret" point: this is what visually aims at
        -- targets. Purely cosmetic -- FireBullets() is done from
        -- the entity's own aim data computed in Think(), not from
        -- this attachment's transform.
        Model = "models/hunter/blocks/cube025x025x025.mdl",
        Pos = Vector(0, 0, 50),
        Angle = Angle(0, 0, 0),
        Color = Color(255, 255, 255),
        Material = "models/effects/intro_tearshape",
        Scale = 1,
        AxisScale = Vector(1, 1, 1),
        Parent = 0
    },

    {
        ID = 2,
        Model = "models/weapons/w_m134_minigun.mdl",
        Pos = Vector(-18, 1.5, 0),
        Angle = Angle(-10, 0, 0),
        Color = Color(255, 255, 255),
        Material = "",
        Scale = 1,
        AxisScale = Vector(1, 1, 1),
        Parent = 1
    },

    {
        ID = 3,
        Model = "models/mechanics/robotics/e4.mdl",
        Pos = Vector(-8, -8, 18),
        Angle = Angle(70, 0, 20),
        Color = Color(70, 70, 70),
        Material = "metal5",
        Scale = 1,
        AxisScale = Vector(0.135, 0.25, 0.25),
        Parent = 0
    },

    {
        ID = 4,
        Model = "models/mechanics/robotics/e4.mdl",
        Pos = Vector(-8, 8, 18),
        Angle = Angle(-70, 0, 160),
        Color = Color(70, 70, 70),
        Material = "metal5",
        Scale = 1,
        AxisScale = Vector(0.135, 0.25, 0.25),
        Parent = 0
    },

	{
		ID = 5,
		Model = "models/mechanics/robotics/e4.mdl",
		Pos = Vector(8, -8, 18),
		Angle = Angle(110, 0, 20),
		Color = Color(70, 70, 70),
		Material = "metal5",
		Scale = 1,
		AxisScale = Vector(0.135, 0.25, 0.25),
		Parent = 0
	},

	{
		ID = 6,
		Model = "models/mechanics/robotics/e4.mdl",
		Pos = Vector(8, 8, 18),
		Angle = Angle(-110, 0, 160),
		Color = Color(70, 70, 70),
		Material = "metal5",
		Scale = 1,
		AxisScale = Vector(0.135, 0.25, 0.25),
		Parent = 0
	},

    {
        ID = 7,
        Model = "models/props_lab/powerbox03a.mdl",
        Pos = Vector(-14.5, -14.5, 1.4),
        Angle = Angle(-45, 90, 90),
        Color = Color(70, 70, 70),
        Material = "metal5",
        Scale = 1,
        AxisScale = Vector(0.7, 1.1, 1.1),
        Parent = 0
    },

    {
        ID = 8,
        Model = "models/props_lab/powerbox03a.mdl",
        Pos = Vector(14.5, -14.5, 1.4),
        Angle = Angle(45, 90, 90),
        Color = Color(70, 70, 70),
        Material = "metal5",
        Scale = 1,
        AxisScale = Vector(0.7, 1.1, 1.1),
        Parent = 0
    },

    {
        ID = 9,
        Model = "models/props_lab/powerbox03a.mdl",
        Pos = Vector(14.5, 14.5, 1.4),
        Angle = Angle(135, 90, 90),
        Color = Color(70, 70, 70),
        Material = "metal5",
        Scale = 1,
        AxisScale = Vector(0.7, 1.1, 1.1),
        Parent = 0
    },

    {
        ID = 10,
        Model = "models/props_lab/powerbox03a.mdl",
        Pos = Vector(-14.5, 14.5, 1.4),
        Angle = Angle(-135, 90, 90),
        Color = Color(70, 70, 70),
        Material = "metal5",
        Scale = 1,
        AxisScale = Vector(0.7, 1.1, 1.1),
        Parent = 0
    },

    {
        ID = 11,
        Model = "models/props_lab/rotato.mdl",
        Pos = Vector(0, 0, 30.5),
        Angle = Angle(-15, 0, 90),
        Color = Color(70, 70, 70),
        Material = "metal5",
        Scale = 1,
        AxisScale = Vector(0.8, 2, 0.8),
        Parent = 0
    },

    {
        ID = 12,
        Model = "models/props/de_nuke/ventilationduct02large.mdl",
        Pos = Vector(0, 0, 32.5),
        Angle = Angle(90, 0, 0),
        Color = Color(70, 70, 70),
        Material = "metal5",
        Scale = 1,
        AxisScale = Vector(0.1, 0.2, 0.2),
        Parent = 0
    },

    {
        ID = 13,
        Model = "models/props_wasteland/panel_leverhandle001a.mdl",
        Pos = Vector(0.6, 0, 39.8),
        Angle = Angle(180, 0, 0),
        Color = Color(70, 70, 70),
        Material = "metal5",
        Scale = 1,
        AxisScale = Vector(0.7, 1.1, 0.4),
        Parent = 0
    },

    {
        ID = 14,
        Model = "models/props_vents/vent_small_corner002.mdl",
        Pos = Vector(-0.1, 0, -15.5),
        Angle = Angle(180, 0, 0),
        Color = Color(70, 70, 70),
        Material = "metal5",
        Scale = 1,
        AxisScale = Vector(0.2, 0.52, 1.7),
        -- Parented to 18 (a yaw-only tracker), not 1 directly --
        -- ID 1's Angle carries both the head's pitch and yaw as it
        -- aims/sweeps/droops in Think(), and this piece should
        -- only turn with the yaw, never tilt with the pitch. See
        -- ID 18 below.
        Parent = 18
    },

    {
        ID = 15,
        Model = "models/props/cs_office/projector.mdl",
        Pos = Vector(-3, 0, -1.75),
        Angle = Angle(0, 90, 0),
        Color = Color(125, 125, 125),
        Material = "",
        Scale = 1,
        AxisScale = Vector(0.7, 0.7, 0.7),
        Parent = 1
    },

    {
        ID = 16,
        Model = "models/props/cs_office/computer_monitor_p2.mdl",
        Pos = Vector(-8, 0, -17.75),
        Angle = Angle(0, 0, 0),
        Color = Color(70, 70, 70),
        Material = "metal5",
        Scale = 1,
        AxisScale = Vector(0.75, 0.75, 0.9),
        Parent = 1
    },

    {
        ID = 17,
        Model = "models/Items/BoxSRounds.mdl",
        Pos = Vector(-7, -2, -16.75),
        Angle = Angle(0, 0, 0),
        Color = Color(255, 255, 255),
        Material = "",
        Scale = 1,
        AxisScale = Vector(0.55, 0.67, 0.55),
        Parent = 1
    },

    {
        ID = 18,
        -- Invisible yaw-only pivot for ID 14 (the vent piece under
        -- the head). Parented to the entity root like ID 1 is, but
        -- its Angle is kept in sync with only ID 1's yaw each
        -- frame in Think() below -- never ID 1's pitch -- so
        -- children parented here turn left/right with the head
        -- without tilting up/down with it. No model, so it never
        -- draws anything itself.
        Model = "",
        Pos = Vector(0, 0, 50),
        Angle = Angle(0, 0, 0),
        Color = Color(255, 255, 255),
        Material = "",
        Scale = 1,
        AxisScale = Vector(1, 1, 1),
        Parent = 0
    },
}

-- Server

if SERVER then

    local ScanInterval = 0.2       -- how often we look for a target
    local SpotDelay = 1            -- seconds between spotting a target and opening fire
    local FireDelay = 0.02         -- seconds between shots once firing
    local FOV = 90                 -- degrees, full cone width
    local Range = 3000             -- units

    local Damage = 8
    local BulletsPerShot = 1
    local Spread = 0.035           -- FireBullets cone, keeps it from being a laser
    local FireSound = "BlackVulcan.Single"
    local SpotSound = "npc/scanner/combat_scan2.wav"

    function ENT:GetTurretEyePos()
        local turretAttach = self.Attachments and self.Attachments[1]
        local muzzleAttach = self.Attachments and self.Attachments[2]

        if not turretAttach or not muzzleAttach then
            -- Should never happen given ENT.Attachments above, but
            -- fall back to something reasonable rather than erroring.
            return self:GetPos() + Vector(0, 0, 70) + self:GetForward() * 20
        end

        local selfPos, selfAng = self:GetPos(), self:GetAngles()

        -- Attachment 1, local to the entity, using its resting
        -- Angle -- the server never animates this, so there is no
        -- "live" value to read here.
        local restAngle1 = turretAttach.Angle or angle_zero

        local pos1 = selfPos
            + selfAng:Forward() * turretAttach.Pos.x
            + selfAng:Right()   * turretAttach.Pos.y
            + selfAng:Up()      * turretAttach.Pos.z

        local ang1 = Angle(selfAng.p, selfAng.y, selfAng.r)
        ang1:RotateAroundAxis(ang1:Up(), restAngle1.y)
        ang1:RotateAroundAxis(ang1:Right(), restAngle1.p)

        -- Attachment 2 (the minigun), local to attachment 1.
        local pos2 = pos1
            + ang1:Forward() * muzzleAttach.Pos.x
            + ang1:Right()   * muzzleAttach.Pos.y
            + ang1:Up()      * muzzleAttach.Pos.z

        local ang2 = Angle(ang1.p, ang1.y, ang1.r)
        ang2:RotateAroundAxis(ang2:Up(), muzzleAttach.Angle.y)
        ang2:RotateAroundAxis(ang2:Right(), muzzleAttach.Angle.p)

        -- Same muzzle-tip nudge the client uses for the flash/beam,
        -- so the visible tracer and the actual bullet origin agree.
        return pos2 + ang2:Forward() * 33 + ang2:Up() * 2 + ang2:Right() * -1.5
    end

    -- Points spanning the target's whole hitbox, not just one
    -- fixed "chest height" offset. The old code used a single
    -- world point (target:GetPos() + Vector(0,0,40)) for range,
    -- FOV, and the visibility trace alike -- which meant a player
    -- was only ever "seen" through that one point. Since a
    -- standing hitbox is roughly 0-72 units tall and a crouching
    -- one roughly 0-36, a player could duck or lean so that exact
    -- point sat behind cover while their head or shoulders were
    -- still plainly exposed, and the turret would treat them as
    -- fully hidden. Sampling feet/knees/chest/head instead means
    -- any part of the box being genuinely visible is enough.
    -- OBBMins/OBBMaxs are used (rather than a hardcoded height)
    -- so this still works correctly while crouched, prone, or on
    -- any playermodel with a nonstandard hull.
    local HitboxFractions = { 0.05, 0.35, 0.65, 0.95 }

    function ENT:GetTargetHitboxPoints(target)
        local mins, maxs = target:OBBMins(), target:OBBMaxs()
        local origin = target:GetPos()
        local height = maxs.z - mins.z

        local points = {}
        for _, frac in ipairs(HitboxFractions) do
            points[#points + 1] = origin + Vector(0, 0, mins.z + height * frac)
        end

        return points
    end

    -- Checks range + FOV + line-of-sight against every point on
    -- the target's hitbox (see GetTargetHitboxPoints) instead of
    -- a single fixed point, so the target only counts as hidden
    -- if their *entire* box is out of range, outside the cone, or
    -- blocked. Returns the point that was actually visible (for
    -- aiming) plus its distance, or nil if no point qualified.
    function ENT:FindVisiblePointOn(target, eyePos, forward, halfFOVCos)
        local bestPoint, bestDist = nil, math.huge

        for _, point in ipairs(self:GetTargetHitboxPoints(target)) do
            local toPoint = point - eyePos
            local dist = toPoint:Length()

            if dist <= Range and dist < bestDist then

                local dir = toPoint / dist

                if dir:Dot(forward) >= halfFOVCos then

                    local trace = util.TraceLine({
                        start = eyePos,
                        endpos = point,
                        filter = self,
                        mask = MASK_SHOT
                    })

                    if not trace.Hit or trace.Entity == target then
                        bestPoint = point
                        bestDist = dist
                    end
                end
            end
        end

        return bestPoint, bestDist
    end

    -- NOTE: the muzzle flash and shell casing used to be placed
    -- here server-side via a GetMuzzleAttachmentTransform() helper
    -- that walked entity -> ID 1 -> ID 2 using the attachment
    -- table's *resting* Pos/Angle. That was the root cause of the
    -- muzzle effect never turning with the turret head: the live
    -- aim LerpAngle that actually rotates ID 1 toward the target
    -- is only ever written into attach.Angle on the client (see
    -- the client Think() below), so a transform built from the
    -- resting value was frozen at the turret's neutral pose no
    -- matter which way it was actually aimed. Both effects are
    -- now triggered from the client via "ery_turret_fired" (see
    -- ENT:PlayMuzzleFlash below and the client net.Receive),
    -- using the same live, Lerped transform the visual model and
    -- aim beam already track.

    function ENT:Initialize()

        -- Model, material, color, bone scale, physics, mass,
        -- decay timer, and health/regen are all handled by
        -- sci_pointshop_entity_base_ui. Only turret-specific state
        -- is set up here.
        self.BaseClass.Initialize(self)

        self:SetNW2Bool("Active", self.Active)

        -- Mirrors the beacon's HasPower contract: set by
        -- SetPowered(), called by the mainframe each power tick.
        self.HasPower = false
        self:SetNW2Bool("HasPower", false)

        -- Current target (server-only, not networked -- the
        -- client doesn't need to know who's being shot at, only
        -- whether the turret is actively firing, for the aim
        -- visual).
        self.Target = nil
        self.TargetSpottedAt = 0
        self.NextFireTime = 0
        self.NextScanTime = 0

        -- Whether the turret has a target locked (past FindTarget,
        -- whether or not the spot delay has elapsed yet) and
        -- whether it's past that delay and actually shooting.
        -- Both networked so the client can drive the minigun
        -- attachment's aim/spin purely visually: Spotted alone
        -- means "snap toward them, wait to fire," Firing means
        -- "actually shooting."
        self.Spotted = false
        self:SetNW2Bool("Spotted", false)

        self.Firing = false
        self:SetNW2Bool("Firing", false)

        -- Per-player allegiance table, keyed by SteamID64 so it
        -- survives reconnects. true = friendly (never targeted),
        -- anything else (including unset) = hostile. Not
        -- networked -- this is server-authoritative targeting
        -- data, no client needs it.
        self.Allegiance = {}

        self:RemoveMenuButton("pickup")
        self:AddMenuButton("configure", "Configure", function(ent, activator)
            ent:OpenConfigureMenu(activator)
        end)
    end

    function ENT:OpenConfigureMenu(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return end

        local steamID = ply:SteamID64()
        local isFriendly = self.Allegiance[steamID] == true

        net.Start("ery_turret_open")
            net.WriteEntity(self)
            net.WriteBool(self.Active or false)
            net.WriteBool(isFriendly)
        net.Send(ply)
    end

    function ENT:SetAllegiance(ply, friendly)
        if not IsValid(ply) or not ply:IsPlayer() then return end

        local steamID = ply:SteamID64()
        self.Allegiance[steamID] = friendly and true or nil

        -- Drop whatever we're doing with this player immediately
        -- if they just declared friendly, rather than waiting for
        -- the next scan to notice.
        if friendly and self.Target == ply then
            self:ClearTarget()
        end

        ply:ChatPrint(
            "[Sentry Turret] You are now marked as "
            .. (friendly and "FRIENDLY" or "HOSTILE")
            .. " to this turret."
        )
    end

    function ENT:IsFriendly(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return true end
        return self.Allegiance[ply:SteamID64()] == true
    end

    -- Wipes every recorded allegiance, so every player (including
    -- whoever previously declared themselves friendly) reverts to
    -- the default hostile state and can be targeted again. Doesn't
    -- immediately clear the turret's *current* target -- the next
    -- scan will pick that up on its own like any other allegiance
    -- change.
    function ENT:ClearAllegiance()
        self.Allegiance = {}
    end

    function ENT:ToggleActive()

        self.Active = not self.Active

        self:SetNW2Bool("Active", self.Active)

        if not self.Active then
            self:ClearTarget()
        end
    end

    ---------------------------------------------------------
    -- Power interface, called by a linked mainframe. Same
    -- contract as the beacon: report 0 draw while switched off so
    -- an idle turret doesn't hold power another entity could use.
    ---------------------------------------------------------

    function ENT:GetPowerRequired()
        if not self.Active then return 0 end
        return self.PowerRequired or 100
    end

    function ENT:SetPowered(hasPower)
        hasPower = hasPower and true or false

        if hasPower == self.HasPower then return end

        self.HasPower = hasPower
        self:SetNW2Bool("HasPower", hasPower)

        if not hasPower then
            self:ClearTarget()
        end
    end

    net.Receive("ery_turret_toggle", function(_, ply)

        local turret = net.ReadEntity()

        if not IsValid(turret) then return end
        if turret:GetClass() ~= "sci_pointshop_base_turret" then return end

        turret:ToggleActive()
    end)

    net.Receive("ery_turret_set_allegiance", function(_, ply)

        local turret = net.ReadEntity()
        local friendly = net.ReadBool()

        if not IsValid(turret) then return end
        if turret:GetClass() ~= "sci_pointshop_base_turret" then return end
        if not IsValid(ply) then return end

        turret:SetAllegiance(ply, friendly)
    end)

    -- Wipes the whole allegiance list so everyone (including
    -- previously-friendly players) becomes hostile again. Available
    -- to all players.
    net.Receive("ery_turret_clear_allies", function(_, ply)

        local turret = net.ReadEntity()

        if not IsValid(turret) then return end
        if turret:GetClass() ~= "sci_pointshop_base_turret" then return end
        if not IsValid(ply) then return end

        turret:ClearAllegiance()
        ply:ChatPrint("[Sentry Turret] Allegiance list cleared -- everyone is now HOSTILE.")
    end)

    ---------------------------------------------------------
    -- Targeting / firing
    ---------------------------------------------------------

    function ENT:ClearTarget()
        self.Target = nil
        self.TargetSpottedAt = 0

        if self.Spotted then
            self.Spotted = false
            self:SetNW2Bool("Spotted", false)
        end

        if self.Firing then
            self.Firing = false
            self:SetNW2Bool("Firing", false)
        end
    end

    -- Nearest hostile, visible, alive player within Range and
    -- within the forward-facing FOV cone. Friendly-declared
    -- players are fully skipped, never merely deprioritized.
    function ENT:FindTarget()

        local eyePos = self:GetTurretEyePos()
        local forward = self:GetForward()
        local halfFOVCos = math.cos(math.rad(FOV * 0.5))

        local best, bestDist = nil, math.huge

        for _, target in ipairs(player.GetAll()) do

            if IsValid(target)
                and target:Alive()
                and not self:IsFriendly(target) then

                -- Considers the target's whole hitbox (feet through
                -- head), not one fixed chest-height point -- see
                -- FindVisiblePointOn above for why.
                local _, dist = self:FindVisiblePointOn(target, eyePos, forward, halfFOVCos)

                if dist and dist < bestDist then
                    best = target
                    bestDist = dist
                end
            end
        end

        return best
    end

    -- Tells every nearby client to play the muzzle flash and
    -- eject a shell casing. This used to be done server-side with
    -- a static-angle EffectData built from
    -- GetMuzzleAttachmentTransform(), but that helper only ever
    -- reads the attachment table's *resting* Pos/Angle -- the
    -- live aim LerpAngle that actually turns the minigun toward
    -- its target only ever gets written into attach.Angle on the
    -- client (see the client Think() below). So the old effect
    -- was placed at a transform that never turned with the
    -- attachment; it just sat at the turret's neutral pose.
    -- Handing this off to the client lets it use the exact same
    -- live, Lerped attachment transform the visual model and aim
    -- beam already use, so the flash/shell genuinely track
    -- wherever the attachment is currently pointed.
    function ENT:PlayMuzzleFlash(dir)
        net.Start("ery_turret_fired")
            net.WriteEntity(self)
            net.WriteVector(dir)
        net.SendPVS(self:GetPos())
    end

    function ENT:FireAt(target)

        local eyePos = self:GetTurretEyePos()
        local forward = self:GetForward()
        local halfFOVCos = math.cos(math.rad(FOV * 0.5))

        -- Aim at whichever point on the target's hitbox is
        -- actually visible right now (e.g. their head, if that's
        -- all that's peeking out from cover) rather than a fixed
        -- chest-height point that might itself be blocked even
        -- though part of the target is exposed. Falls back to the
        -- old fixed point only in the edge case where Think()'s
        -- own check passed a frame ago but nothing qualifies here
        -- (e.g. the target ducked back to safety in between).
        local aimPos = self:FindVisiblePointOn(target, eyePos, forward, halfFOVCos)
            or (target:GetPos() + Vector(0, 0, 40))

        local dir = (aimPos - eyePos):GetNormalized()

        self:PlayMuzzleFlash(dir)

        local bullet = {}
        bullet.Num = BulletsPerShot
        bullet.Src = eyePos
        bullet.Dir = dir
        bullet.Spread = Vector(Spread, Spread, 0)
        bullet.Tracer = 1
        bullet.TracerName = "Tracer"
        bullet.Force = 1
        bullet.Damage = Damage
        bullet.Attacker = self
        bullet.Callback = function(attacker, tr, dmginfo)
            dmginfo:SetInflictor(self)
        end

        self:FireBullets(bullet)
        self:EmitSound(FireSound)
    end

    function ENT:Think()

        local currentTime = CurTime()

        if self.Active and self.HasPower then

            if currentTime >= self.NextScanTime then

                self.NextScanTime = currentTime + ScanInterval

                -- Drop the current target if it's no longer valid,
                -- alive, friendly, in range, in the FOV cone, or
                -- visible -- re-running the same checks FindTarget
                -- uses keeps a locked target from sticking around
                -- after it breaks line of sight or the player
                -- flips to friendly.
                if IsValid(self.Target) then

                    local stillValid =
                        self.Target:Alive()
                        and not self:IsFriendly(self.Target)

                    if stillValid then

                        -- Same whole-hitbox check as FindTarget --
                        -- a target only counts as lost once every
                        -- point on their box is out of range,
                        -- outside the FOV cone, or blocked, not
                        -- just the moment one fixed chest-height
                        -- point ducks behind cover.
                        local eyePos = self:GetTurretEyePos()
                        local forward = self:GetForward()
                        local halfFOVCos = math.cos(math.rad(FOV * 0.5))

                        local visiblePoint = self:FindVisiblePointOn(
                            self.Target, eyePos, forward, halfFOVCos
                        )

                        if not visiblePoint then
                            stillValid = false
                        end
                    end

                    if not stillValid then
                        self:ClearTarget()
                    end
                end

                if not IsValid(self.Target) then

                    local found = self:FindTarget()

                    if found then
                        self.Target = found
                        self.TargetSpottedAt = currentTime
                        self.Spotted = true
                        self:SetNW2Bool("Spotted", true)
                        self.Firing = false
                        self:SetNW2Bool("Firing", false)
                        self:EmitSound("npc/scanner/combat_scan"..math.random(1,4)..".wav", 70, 100)
                    end
                end
            end

            if IsValid(self.Target) then

                if not self.Firing then

                    -- Spot delay: give the player a beat (plus the
                    -- sound cue fired above, once, at spot time) to
                    -- react before the turret opens up.
                    if currentTime >= self.TargetSpottedAt + SpotDelay then
                        self.Firing = true
                        self:SetNW2Bool("Firing", true)
                        self.NextFireTime = currentTime
                    end

                elseif currentTime >= self.NextFireTime then

                    self.NextFireTime = currentTime + FireDelay
                    self:FireAt(self.Target)
                end
            end

        elseif self.Target then
            self:ClearTarget()
        end

        self:NextThink(currentTime + 0.05)

        return true
    end

    function ENT:OnRemove()

        self.Active = false
        self:SetNW2Bool("Active", false)

        self:UnlinkMainframe()

        -- Still run the base's own cleanup (decay/regen timers).
        self.BaseClass.OnRemove(self)
    end
end

-- Client

if CLIENT then

    net.Receive("ery_turret_open", function()

        local turret = net.ReadEntity()

        if not IsValid(turret) then return end

        local isActive = net.ReadBool()
        local isFriendly = net.ReadBool()

        local rowHeight = 30
        local rowY = 64
        local buttonWide = 8

        local frame = vgui.Create("DFrame")

        frame:SetTitle(turret.PrintName or "Sentry Turret")
        frame:SetSize(280, 106 + rowHeight * 3)
        frame:Center()
        frame:MakePopup()

        local statusLabel = vgui.Create("DLabel", frame)
        statusLabel:SetPos(8, 32)
        statusLabel:SetSize(frame:GetWide() - 16, 20)
        statusLabel:SetText(
            "This turret is currently "
            .. (isFriendly and "treating you as FRIENDLY." or "treating you as HOSTILE.")
        )
        statusLabel:SetWrap(true)
        statusLabel:SetAutoStretchVertical(true)

        local allegianceButton = vgui.Create("DButton", frame)
        allegianceButton:SetPos(8, rowY)
        allegianceButton:SetSize(frame:GetWide() - 16, rowHeight - 4)
        allegianceButton:SetText(
            isFriendly
                and "Declare myself HOSTILE"
                or "Declare myself FRIENDLY"
        )

        allegianceButton.DoClick = function()

            net.Start("ery_turret_set_allegiance")
                net.WriteEntity(turret)
                net.WriteBool(not isFriendly)
            net.SendToServer()

            frame:Close()
        end
        rowY = rowY + rowHeight

        local toggleButton = vgui.Create("DButton", frame)
        toggleButton:SetPos(8, rowY)
        toggleButton:SetSize(frame:GetWide() - 16, rowHeight - 4)
        toggleButton:SetText(isActive and "Turn OFF" or "Turn ON")

        toggleButton.DoClick = function()

            net.Start("ery_turret_toggle")
                net.WriteEntity(turret)
            net.SendToServer()

            frame:Close()
        end
        rowY = rowY + rowHeight

        -- Wipes the turret's whole allegiance list, so every
        -- player who previously declared friendly (and everyone
        -- else) goes back to being targetable.
        local clearAlliesButton = vgui.Create("DButton", frame)
        clearAlliesButton:SetPos(8, rowY)
        clearAlliesButton:SetSize(frame:GetWide() - 16, rowHeight - 4)
        clearAlliesButton:SetText("Clear ally list (make everyone hostile)")

        clearAlliesButton.DoClick = function()

            net.Start("ery_turret_clear_allies")
                net.WriteEntity(turret)
            net.SendToServer()

            frame:Close()
        end
        rowY = rowY + rowHeight

        local closeButton = vgui.Create("DButton", frame)
        closeButton:SetPos(8, rowY)
        closeButton:SetSize(frame:GetWide() - 16, rowHeight - 4)
        closeButton:SetText("Close")

        closeButton.DoClick = function()
            frame:Close()
        end
    end)

    -- Aims the minigun attachment at whatever the turret is
    -- currently firing at. Purely visual -- the server computes
    -- its own firing direction independently in FireAt(). We infer
    -- "who to aim at" client-side the same way the beacon infers
    -- "am I spinning": by reading small networked state (here,
    -- just Firing) rather than being told explicitly, so we don't
    -- need to network a target entity or aim angle every tick.
    --
    -- Since we aren't told *who*, while Firing we aim at the
    -- nearest enemy player in front of the turret using the same
    -- FOV/range the server uses -- close enough for a visual, and
    -- avoids syncing target identity over the network every frame.
    local FOV = 90
    local Range = 3000
    local TurnSpeed = 12 -- how snappily the visual aim tracks, in Angle:Slerp fraction per think

    -- Idle sweep: while there's no active target (not Firing),
    -- the turret head slowly pans left/right on its own instead
    -- of sitting dead still. Only ID 1 (the turret pivot
    -- attachment) is touched -- never the entity's real angles --
    -- same as the aim-tracking code above. Pitch stays at 0
    -- (level) the whole time -- earlier this had a constant
    -- downward pitch offset, which was why both the visual model
    -- and the aim beam looked tilted into the ground while idle.
    --
    -- IdleSweepYawRange is derived from FOV (the same 90-degree
    -- full cone width the server actually scans/fires within),
    -- not a separately hand-picked number -- it was previously
    -- fixed at 35, understating the turret's real +/-45 degree
    -- coverage by 10 degrees on each side and making the idle
    -- sweep look narrower than what the turret can actually see
    -- and shoot.
    local IdleSweepYawRange = FOV * 0.5   -- degrees left/right from center, matches FOV's half-angle
    local IdleSweepPeriod = 6      -- seconds for a full left-right-left cycle

    local IdleSoundMin = 4         -- seconds between idle "searching" blips
    local IdleSoundMax = 9
    local IdleSounds = {
        "npc/combine_gunship/ping_search.wav",
        "npc/combine_gunship/gunship_ping_search.wav",
    }

    -- Returns the idle sweep angle for this instant, keyed off
    -- CurTime() plus a per-entity offset (EntIndex) so multiple
    -- turrets in the same map don't all sweep in lockstep.
    local function GetIdleSweepAngle(self)
        local t = CurTime() + self:EntIndex() * 1.7
        local phase = (t % IdleSweepPeriod) / IdleSweepPeriod
        -- Triangle wave from -1 to 1 and back, so the sweep eases
        -- into each end rather than snapping back to center.
        local wave = math.sin(phase * math.pi * 2)

        return Angle(0, wave * IdleSweepYawRange, 0)
    end

    local function FindVisualTarget(self)

        local pos = self:GetPos() + Vector(0, 0, 40)
        local forward = self:GetForward()
        local halfFOVCos = math.cos(math.rad(FOV * 0.5))

        local best, bestDist = nil, math.huge

        for _, target in ipairs(player.GetAll()) do

            if IsValid(target) and target:Alive() then

                local targetPos = target:GetPos() + Vector(0, 0, 40)
                local toTarget = targetPos - pos
                local dist = toTarget:Length()

                if dist <= Range and dist < bestDist then

                    local dir = toTarget / dist

                    if dir:Dot(forward) >= halfFOVCos then
                        best = target
                        bestDist = dist
                    end
                end
            end
        end

        return best
    end

    local function WorldDirToLocalAimAngle(entity, worldDir)

        local forward = entity:GetForward()
        local right = entity:GetRight()
        local up = entity:GetUp()

        worldDir = worldDir:GetNormalized()

        local vx = worldDir:Dot(forward)
        local vy = -worldDir:Dot(right)
        local vz = worldDir:Dot(up)

        local yaw = math.deg(math.asin(math.Clamp(vy, -1, 1)))
        local cosYaw = math.cos(math.rad(yaw))

        local pitch
        if math.abs(cosYaw) < 1e-6 then
            pitch = math.deg(math.atan2(vz, vx))
        else
            pitch = math.deg(math.atan2(vz / cosYaw, vx / cosYaw))
        end

        return Angle(pitch, yaw, 0)
    end

    -- Straight-line beam showing the turret's current aim.
    -- Rather than re-deriving a world rotation from the
    -- attachments' local Angle values (which requires matching
    -- ERY_MACHINE:DrawAttachments' own pitch/yaw composition
    -- exactly -- getting that sign convention wrong is what made
    -- the beam previously point at the ground while idle and well
    -- below the target while firing), this reuses the exact same
    -- world-space direction Think() below already computed for
    -- the visual aim. Only the muzzle's approximate world
    -- *position* comes from the attachment chain, since a small
    -- position offset doesn't suffer from the same rotation-sign
    -- ambiguity.
    local BeamMaterial = Material("cable/redlaser")
    local BeamLength = 3000
    local BeamWidth = 1.5

    -- Full world transform of attachment ID 2 (the minigun),
    -- built by walking entity -> ID 1 -> ID 2 the same way the
    -- server's GetMuzzleAttachmentTransform does, but using ID
    -- 1's *live* Angle -- the one Think() below actually Lerps
    -- toward the target/idle sweep -- instead of its resting
    -- value. This is what the old GetMuzzleWorldPos was missing:
    -- it only ever applied the entity's own (unaimed) axes, so
    -- anything built from it stayed fixed to the turret's base
    -- orientation instead of turning with the head. Returns the
    -- muzzle tip position plus a forward/right/up basis, used by
    -- the muzzle flash and the aim beam below.
    local function GetMuzzleWorldTransform(self)
        local turretAttach = self.Attachments and self.Attachments[1]
        local muzzleAttach = self.Attachments and self.Attachments[2]
        if not turretAttach or not muzzleAttach then
            local pos = self:GetPos()
            local ang = self:GetAngles()
            return pos, ang:Forward(), ang:Right(), ang:Up()
        end

        local selfPos, selfAng = self:GetPos(), self:GetAngles()

        -- ID 1, local to the entity, using its live (aimed) Angle.
        local pos1 = selfPos + selfAng:Forward() * turretAttach.Pos.x
            + selfAng:Right() * turretAttach.Pos.y
            + selfAng:Up() * turretAttach.Pos.z

        local ang1 = Angle(selfAng.p, selfAng.y, selfAng.r)
        ang1:RotateAroundAxis(ang1:Up(), turretAttach.Angle.y)
        ang1:RotateAroundAxis(ang1:Right(), turretAttach.Angle.p)

        -- ID 2, local to ID 1.
        local pos2 = pos1 + ang1:Forward() * muzzleAttach.Pos.x
            + ang1:Right() * muzzleAttach.Pos.y
            + ang1:Up() * muzzleAttach.Pos.z

        local ang2 = Angle(ang1.p, ang1.y, ang1.r)
        ang2:RotateAroundAxis(ang2:Up(), muzzleAttach.Angle.y)
        ang2:RotateAroundAxis(ang2:Right(), muzzleAttach.Angle.p)

        local muzzleTip = pos2 + ang2:Forward() * 33 + ang2:Up() * 2 + ang2:Right() * -1.5

        return muzzleTip, ang2:Forward(), ang2:Right(), ang2:Up()
    end

    -- Shell-casing ejection was removed here -- the clientside
    -- physics-prop approach didn't work out in practice, so this
    -- now only plays the muzzle flash.
    net.Receive("ery_turret_fired", function()
        local turret = net.ReadEntity()
        local dir = net.ReadVector()

        if not IsValid(turret) then return end

        local pos = GetMuzzleWorldTransform(turret)
        local ang = dir:Angle()

        -- Muzzle flash: this is a one-shot puff-and-light effect
        -- (not a looping attachment-following one), so "turning
        -- with the attachment" means firing it fresh off the
        -- live transform above every time a shot goes off, rather
        -- than a single stale angle computed once server-side
        -- from the attachment's resting pose.
        local effectdata = EffectData()
        effectdata:SetOrigin(pos)
        effectdata:SetAngles(ang)
        effectdata:SetEntity(turret)
        effectdata:SetScale(1)
        util.Effect("MuzzleEffect", effectdata, true, true)
    end)

    local function DrawAimBeam(self)
        if not self.CurrentAimWorldDir then return end

        local startPos = select(1, GetMuzzleWorldTransform(self))
        local endPos = startPos + self.CurrentAimWorldDir * BeamLength

        local trace = util.TraceLine({
            start = startPos,
            endpos = endPos,
            filter = self,
            mask = MASK_SHOT
        })

        render.SetMaterial(BeamMaterial)
        render.DrawBeam(startPos, trace.HitPos, BeamWidth, 0, 1, Color(255, 40, 40, 180))
    end

    function ENT:Think()

        local attach = self.Attachments and self.Attachments[1]
        if not attach then return end

        local firing = self:GetNW2Bool("Firing", false)
        local spotted = self:GetNW2Bool("Spotted", false)
        local active = self:GetNW2Bool("Active", false)
        local hasPower = self:GetNW2Bool("HasPower", false)
        local tracking = spotted or firing
        local idle = active and hasPower and not tracking

        if tracking then

            local target = FindVisualTarget(self)

            if IsValid(target) then

                local aimPos = target:GetPos() + Vector(0, 0, 40)
                local myPos = self:GetPos() + Vector(0, 0, 40)
                local worldDir = (aimPos - myPos):GetNormalized()

                local localAng = WorldDirToLocalAimAngle(self, aimPos - myPos)

                if not self.WasTracking then
                    -- Rising edge: the turret just spotted this
                    -- target this frame (Spotted just went true, or
                    -- Firing came in without a prior Spotted frame
                    -- e.g. due to a missed net update). Snap the
                    -- head straight to the target immediately
                    -- instead of easing in, so detection reads as
                    -- instant even though the 1-second spot delay
                    -- still applies before it's allowed to fire.
                    attach.Angle = localAng
                else
                    attach.Angle = LerpAngle(
                        FrameTime() * TurnSpeed,
                        attach.Angle,
                        localAng
                    )
                end

                -- Same world-space direction the model aim above
                -- is tracking, reused by DrawAimBeam so the beam
                -- always matches what's actually being aimed at.
                self.CurrentAimWorldDir = worldDir
            end

            self.WasTracking = true
            self.NextIdleSoundTime = nil

        elseif idle then

            self.WasTracking = false

            -- No active target but powered and switched on: sweep
            -- the head left/right instead of sitting still, and
            -- occasionally chirp a "searching" blip. Only the
            -- attachment's local Angle is touched here -- the
            -- entity's own angles never move.
            attach.Angle = LerpAngle(
                FrameTime() * TurnSpeed * 0.35,
                attach.Angle,
                GetIdleSweepAngle(self)
            )

            -- Beam follows the same level sweep, in world space:
            -- entity forward rotated by the attachment's current
            -- (idle) yaw, with pitch forced to 0 so it stays
            -- horizontal instead of drooping into the ground.
            local sweepDir = self:GetForward()
            sweepDir:Rotate(Angle(0, attach.Angle.y, 0))
            self.CurrentAimWorldDir = sweepDir

            if not self.NextIdleSoundTime or CurTime() >= self.NextIdleSoundTime then
                self.NextIdleSoundTime = CurTime() + math.Rand(IdleSoundMin, IdleSoundMax)
                self:EmitSound(IdleSounds[math.random(#IdleSounds)], 70, math.random(95, 105))
            end

        else

            self.WasTracking = false

            -- Off or unpowered: droop the head down 30 degrees as
            -- a visual "power is off" signal (positive pitch looks
            -- down -- see the note above on IdleSweepYawRange about
            -- this sign convention), instead of easing back to a
            -- level resting angle. No idle sound, no beam.
            attach.Angle = LerpAngle(
                FrameTime() * TurnSpeed,
                attach.Angle,
                Angle(-30, 0, 0)
            )

            self.NextIdleSoundTime = nil
            self.CurrentAimWorldDir = nil
        end

        -- Keep ID 18 (the yaw-only pivot for ID 14) tracking ID
        -- 1's yaw, now that ID 1's Angle is finalized for this
        -- frame regardless of which branch above ran. Pitch and
        -- roll are intentionally left at 0 so anything parented to
        -- 18 -- ID 14 -- only ever turns horizontally, never
        -- tilting with the head's aim/droop pitch.
        local yawAttach = self.Attachments and self.Attachments[18]
        if yawAttach then
            yawAttach.Angle = Angle(0, attach.Angle.y, 0)
        end
    end

    -- The base entity's Draw() already calls DrawModel(),
    -- ERY_MACHINE:DrawAttachments(), and DrawLabel() in that
    -- order; overriding here just to add the aim beam on top,
    -- same pattern the base's own doc comment describes for
    -- subclasses that want extra visuals.
    function ENT:Draw()
        self.BaseClass.Draw(self)

        local active = self:GetNW2Bool("Active", false)
        local hasPower = self:GetNW2Bool("HasPower", false)

        if active and hasPower then
            DrawAimBeam(self)
        end
    end
end
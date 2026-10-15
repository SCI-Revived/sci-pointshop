AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "sci_pointshop_entity_base_ui"

ENT.PrintName = "Sentinel"
ENT.Author = "Paloma"
ENT.Spawnable = false
ENT.AdminOnly = true
ENT.Category = "Pointshop Entities"

ENT.IconPath = "entities/sci_pointshop_base_ewr_sentinel.png"
ENT.IconOffset = Vector(120, 0, -15)

-- Placeholder model: swap freely.
ENT.BaseModel = "models/hunter/blocks/cube4x4x4.mdl"
ENT.BaseMaterial = "models/effects/intro_tearshape" --models/effects/intro_tearshape
ENT.BaseColor = Color(80, 90, 100, 255)
ENT.BoneScale = Vector(1, 1, 1)

-- ENT.Attachments is built in the "Turret rig" section below.
ENT.AttachmentDrawDistance = 32000
ENT.LabelDrawDistance = 300
ENT.Decaytime = -1

ENT.CableOffset = Vector(0, 0, -80)

ENT.MaxHealth = 1500
ENT.HealthRegen = 5
ENT.CustomMass = 400

ENT.SpawnOffset = Vector(0, 0, 100) -- world-space offset applied 0.1s after spawning

ENT.CollideSounds = {
	"physics/metal/metal_box_impact_bullet1.wav",
	"physics/metal/metal_box_impact_bullet2.wav",
	"physics/metal/metal_box_impact_bullet3.wav",
}

---------------------------------------------------------
-- Sentinel settings
---------------------------------------------------------

-- Targeting (unchanged in spirit from the interceptor)
ENT.DetectionRadius = 12000
ENT.MinTargetDistance = 300     -- dead zone around the gun
ENT.MinTargetSpeed = 50       -- ignore anything slower than this
ENT.ScanInterval = 0.25         -- how often to look for / re-rank targets

ENT.DetectionSphereColor = Color(255, 160, 40, 15)
ENT.DetectionSphereColorWire = Color(255, 160, 40, 200)

ENT.DeadZoneSphereColor = Color(255, 60, 60, 20)
ENT.DeadZoneSphereColorWire = Color(255, 60, 60, 200)

ENT.SphereDrawDistance = 26000

-- Whether the range grid (detection + dead zone spheres) is shown when
-- looking at the sentinel. Toggled from the Use menu at runtime.
ENT.ShowRangeGrid = true

ENT.TargetClassPrefix = "gb5_"
ENT.TARGET_PRIORITY_PLAYER = 1
ENT.TARGET_PRIORITY_PREFIXED = 2

-- Gun
ENT.MuzzleOffset = Vector(0, 0, 40)  -- local to the entity; only a fallback, rounds normally leave from the MuzzleAttachmentIDs slots below
ENT.FireSound = "apc_fire"
ENT.FireDelay = 0.05               -- seconds between shots (60 / 3400 RPM)
ENT.BurstSize = 40                   -- rounds per burst
ENT.BurstDelay = 2                   -- seconds from the end of one burst to the start of the next
ENT.MagazineSize = 120                -- 3 bursts per magazine
ENT.ReloadDuration = 6               -- seconds
ENT.Spread = 0.5                    -- degrees, random cone half-angle
ENT.MaxShotsPerThink = 4             -- catch-up cap if the server tickrate is below the fire rate

-- Projectile (passed to simfphys.FirePhysProjectile)
-- simfphys_projectile moves `MuzzleVelocity` units per *nominal* tick
-- (66.666/s) and defaults to 200, i.e. ~13333 u/s. This must match what
-- the projectile really does, or every lead calculation is off.
ENT.ProjectileSpeed = 11500          -- units/second; used for lead calculation
ENT.ProjectileDamage = 25
ENT.ProjectileForce = 1
ENT.ProjectileSize = 7
ENT.ProjectileBlastRadius = 200
ENT.ProjectileBlastDamage = 25
ENT.ProjectileDeflectAng = 0
ENT.ProjectileBlastEffect = "simfphys_tankweapon_explosion_micro"

-- The projectile's own drop, mirroring simfphys_projectile:Think():
-- gravity ramps from 0 up to 666.7 u/s^2 over 0.5 s, then stays constant.
ENT.ProjectileGravity = 666.7
ENT.ProjectileGravityRamp = 0.5

-- Lead calculation
-- Known gravity is applied to falling physics entities (bombs etc.)
-- and to airborne players.
ENT.GravityCompensation = true
-- Estimate target acceleration from velocity history (helps vs. turning
-- aircraft/vehicles). On-foot players on the ground use constant velocity.
ENT.UseTargetAcceleration = true
ENT.AccelSmoothTime = 0.35           -- seconds, smoothing of the estimate
ENT.MaxTargetAccel = 1500            -- units/s^2 clamp
ENT.TrackSampleInterval = 0.05       -- seconds between velocity samples
ENT.MaxLeadTime = 3                  -- seconds, safety clamp on flight time

ENT.Active = true

ENT.PowerRole = "consumer"
ENT.PowerRequired = 125

---------------------------------------------------------
-- Turret rig (9K22 Tunguska-style mockup)
--
-- Shared on purpose: the client draws ENT.Attachments, and the
-- server reads the very same table to find where each round
-- leaves from, so muzzle positions live in exactly one place.
--
-- Attachment chain (built below with Add(), which hands out the
-- IDs, so Parent links are variables rather than magic numbers):
--
--   entity ......... the base plate; never moves
--    |- HULL ........ fixed anchor on the plate (tracks, deck, glacis)
--    `- YAW ......... yaw pivot (Angle.y is driven toward the target)
--        |- ring, turret body, search radar (turn with the yaw)
--        `- PITCH .... pitch pivot (Angle.p is driven toward the
--            |                      target, clamped to Min/MaxElevation)
--            |- tracking radar
--            |- per side: breech housing, barrel shroud, missile pod
--            `- per side, twin barrels: barrel, muzzle brake and an
--               invisible MUZZLE slot at the tip, fired in the order
--               listed in MuzzleAttachmentIDs
--
-- Both gun mounts share the one pitch pivot, as on the real
-- vehicle: the whole turret yaws, and the guns, pods and tracking
-- radar elevate together.
--
-- Conventions inherited from ERY_MACHINE:DrawAttachments: Pos is
-- +X forward, +Y RIGHT (it multiplies Right() by Pos.y) and +Z up;
-- and its RotateAroundAxis composition makes a positive Angle.p
-- tilt the nose UP, the opposite of native Source angles -- so
-- Angle.p is simply the elevation.
--
-- Rules the code relies on, if you rearrange things:
--   * the pitch pivot sits ON the yaw axis (Pos.x = Pos.y = 0)
--   * muzzle slots are direct children of the pitch pivot
--   * a parent is always added before its children
---------------------------------------------------------

ENT.TurretMinElevation = -5        -- degrees
ENT.TurretMaxElevation = 85
ENT.TurretIdleElevation = 5        -- where the guns rest with no target
ENT.TurretYawSpeed = 200           -- degrees/second (client visual only)
ENT.TurretPitchSpeed = 100

-- If the guns ever tilt DOWN toward a target above them, flip this
-- to -1 (see the conventions note above).
ENT.TurretPitchSign = 1

-- Placeholder geometry (units). Everything is a cube shaped with
-- AxisScale, so Dim() takes real sizes: length (forward), width
-- (left-right), height. Swap models/colors freely.
local PLATE_TOP = -80.5            -- top face of the base plate, relative to the entity origin
local BLOCK = "models/hunter/blocks/cube025x025x025.mdl"
local BLOCK_SIZE = 11.875          -- edge length of BLOCK

local TRACK_H = 24                 -- track height
local DECK_H = 12                  -- hull deck thickness
local HULL_TOP = TRACK_H + DECK_H  -- top of the hull, above the plate
local RING_H = 4                   -- turret ring thickness
local BODY_H = 34                  -- turret body height
local PIVOT_HEIGHT = HULL_TOP + RING_H + BODY_H / 2  -- yaw axis -> pitch axis (turret mid-height)

local GUN_SIDE = 42                -- centre line of each gun mount, left/right of the axis
local BARREL_SPACING = 11          -- vertical gap between the twin barrels
local BARREL_LEN = 100
local BARREL_START = 16            -- front of the breech housing; the shroud and barrels start here
local POD_SIDE = 57                -- centre line of each missile pod

local HULL_COLOR = Color(105, 115, 80)
local DARK_COLOR = Color(45, 45, 48)
local GUN_COLOR = Color(70, 72, 76)
local PART_MATERIAL = "metal5"

local function Dim(length, width, height)
	return Vector(length / BLOCK_SIZE, width / BLOCK_SIZE, height / BLOCK_SIZE)
end

ENT.Attachments = {}

-- Appends def to the table and returns its ID (= its array position,
-- which is what DrawAttachments and the server's slot lookup use).
local function Add(def)
	local list = ENT.Attachments

	def.ID = #list + 1
	def.Parent = def.Parent or 0
	list[def.ID] = def

	return def.ID
end

-- Visible cube. pos is relative to the parent attachment.
local function Part(parent, pos, dim, color, ang)
	return Add({
		Model = BLOCK,
		Pos = pos,
		Angle = ang or Angle(0, 0, 0),
		Color = color,
		Material = PART_MATERIAL,
		AxisScale = dim,
		Parent = parent,
	})
end

-- Invisible pivot / marker. An empty Model is a pure pivot.
local function Pivot(parent, pos)
	return Add({
		Model = "",
		Pos = pos,
		Angle = Angle(0, 0, 0),
		Parent = parent,
	})
end

-- Fixed hull: parented to a static anchor on the plate, never
-- to the yaw, so it stays put while the turret turns.
local HULL = Pivot(0, Vector(0, 0, PLATE_TOP))

for _, side in ipairs({ 1, -1 }) do
	Part(HULL, Vector(0, side * 40, TRACK_H / 2), Dim(168, 22, TRACK_H), DARK_COLOR)
end

Part(HULL, Vector(0, 0, TRACK_H + DECK_H / 2), Dim(164, 102, DECK_H), HULL_COLOR)
Part(HULL, Vector(84, 0, TRACK_H + 2), Dim(30, 102, 16), HULL_COLOR, Angle(-30, 0, 0)) -- sloped nose

-- Yaw pivot. Angle.y is animated on the client (see ENT:Think below).
local YAW = Pivot(0, Vector(0, 0, PLATE_TOP))

Part(YAW, Vector(0, 0, HULL_TOP + RING_H / 2), Dim(74, 74, RING_H), DARK_COLOR)                    -- turret ring
Part(YAW, Vector(-6, 0, HULL_TOP + RING_H + BODY_H / 2), Dim(88, 66, BODY_H), HULL_COLOR)          -- turret body
Part(YAW, Vector(-34, 0, HULL_TOP + RING_H + BODY_H + 9), Dim(7, 7, 18), DARK_COLOR)               -- search radar mast
Part(YAW, Vector(-34, 0, HULL_TOP + RING_H + BODY_H + 32), Dim(4, 50, 28), HULL_COLOR, Angle(12, 0, 0)) -- search radar panel

-- Pitch pivot. Must sit on the yaw axis (Pos.x and Pos.y = 0):
-- ENT:GetTurretAim relies on it. Angle.p is animated on the client.
local PITCH = Pivot(YAW, Vector(0, 0, PIVOT_HEIGHT))

-- Tracking radar, front centre between the gun mounts.
Part(PITCH, Vector(20, 0, 27), Dim(26, 20, 16), DARK_COLOR)
Part(PITCH, Vector(35, 0, 29), Dim(4, 26, 22), GUN_COLOR, Angle(8, 0, 0))

-- Gun mounts + missile pods, one of each per side (+Y is right).
-- muzzles[level][side]: level 1 = upper barrel, 2 = lower.
local muzzles = { {}, {} }

for _, side in ipairs({ 1, -1 }) do
	local y = side * GUN_SIDE

	Part(PITCH, Vector(0, y, 0), Dim(32, 16, 26), HULL_COLOR)       -- breech housing
	Part(PITCH, Vector(BARREL_START + 18, y, 0), Dim(36, 12, 19), GUN_COLOR) -- barrel shroud

	for level, z in ipairs({ BARREL_SPACING / 2, -BARREL_SPACING / 2 }) do
		Part(PITCH, Vector(BARREL_START + BARREL_LEN / 2, y, z), Dim(BARREL_LEN, 6, 6), GUN_COLOR)
		Part(PITCH, Vector(BARREL_START + BARREL_LEN - 4, y, z), Dim(10, 9, 9), DARK_COLOR) -- muzzle brake

		-- Where rounds leave from: just past the muzzle brake.
		muzzles[level][side] = Pivot(PITCH, Vector(BARREL_START + BARREL_LEN + 4, y, z))
	end

	Part(PITCH, Vector(14, side * POD_SIDE, 4), Dim(48, 14, 24), HULL_COLOR)   -- missile pod
	Part(PITCH, Vector(37, side * POD_SIDE, 4), Dim(3, 12, 20), DARK_COLOR)    -- pod tube openings
end

ENT.YawAttachmentID = YAW
ENT.PitchAttachmentID = PITCH

-- Firing order, one round from the next slot each shot, cycling:
-- right-upper, left-upper, right-lower, left-lower. Drop entries to
-- fire from fewer barrels; every slot must be a child of PITCH.
ENT.MuzzleAttachmentIDs = {
	muzzles[1][1], muzzles[1][-1],
	muzzles[2][1], muzzles[2][-1],
}

-- Same composition ERY_MACHINE:DrawAttachments uses to place a child
-- relative to its parent -- kept identical on purpose, so poses
-- computed here match what the client actually draws.
local function ChildTransform(parentPos, parentAng, pos, ang)
	local worldPos = parentPos
		+ parentAng:Forward() * pos.x
		+ parentAng:Right()   * pos.y
		+ parentAng:Up()      * pos.z

	local worldAng = Angle(parentAng.p, parentAng.y, parentAng.r)
	worldAng:RotateAroundAxis(parentAng:Up(), ang.y)
	worldAng:RotateAroundAxis(parentAng:Right(), ang.p)
	worldAng:RotateAroundAxis(parentAng:Forward(), ang.r)

	return worldPos, worldAng
end

if SERVER then
	util.AddNetworkString("ery_sentinel_open")
	util.AddNetworkString("ery_sentinel_set_allegiance")
	util.AddNetworkString("ery_sentinel_clear_allies")
	util.AddNetworkString("ery_sentinel_toggle")

	---------------------------------------------------------
	-- Setup
	---------------------------------------------------------

	function ENT:Initialize()
		self.BaseClass.Initialize(self)

		self:SetUseType(SIMPLE_USE)

		self:SetNW2Bool("Active", self.Active)
		self:SetNW2Bool("ShowRangeGrid", self.ShowRangeGrid ~= false)

		self.HasPower = false
		self:SetNWBool("HasPower", false)

		-- idle -> firing -> reloading -> idle
		self.State = "idle"
		self:SetNWString("SentinelState", "idle")

		self.NextScanTime = 0
		self.NextFireTime = 0
		self.NextBurstTime = 0
		self.BurstShotsFired = 0
		self.ReloadEndTime = 0

		-- Next muzzle slot to fire from (index into MuzzleAttachmentIDs).
		self.MuzzleIndex = 1

		self.CurrentTarget = NULL
		self:SetNWEntity("CurrentTarget", NULL)

		self:ReloadMagazine()

		self.Allegiance = {}

		self:AddMenuButton("configure", "Configure", function(ent, activator)
			ent:OpenConfigureMenu(activator)
		end)

		self:RefreshToggleButton()
		self:RefreshRangeGridButton()
	end

	function ENT:SetState(state)
		if self.State == state then return end
		self.State = state
		self:SetNWString("SentinelState", state)
	end

	function ENT:SetTarget(ent)
		ent = IsValid(ent) and ent or NULL

		if self.CurrentTarget ~= ent then
			self.CurrentTarget = ent
			self:SetNWEntity("CurrentTarget", ent)
		end
	end

	-- Ends the current burst (whether it was completed or cut short by
	-- losing the target) and starts the delay before the next one.
	function ENT:EndBurst()
		self.BurstShotsFired = 0
		self.NextBurstTime = CurTime() + (self.BurstDelay or 2)
	end

	function ENT:ClearTarget()
		self:SetTarget(NULL)

		if (self.BurstShotsFired or 0) > 0 then
			self:EndBurst()
		end

		if self.State == "firing" then
			self:SetState("idle")
		end
	end

	function ENT:RefreshToggleButton()
		self:RemoveMenuButton("toggle_active")
		self:AddMenuButton(
			"toggle_active",
			self.Active and "Turn OFF" or "Turn ON",
			function(ent, activator)
				ent:ToggleActive()
			end
		)
	end

	function ENT:ToggleActive()
		self.Active = not self.Active
		self:SetNW2Bool("Active", self.Active)
		self:RefreshToggleButton()

		if not self.Active then
			self:ClearTarget()
		end
	end

	function ENT:RefreshRangeGridButton()
		self:RemoveMenuButton("toggle_range_grid")
		self:AddMenuButton(
			"toggle_range_grid",
			self:GetNW2Bool("ShowRangeGrid", true) and "Range Grid: ON" or "Range Grid: OFF",
			function(ent, activator)
				ent:ToggleRangeGrid()
			end
		)
	end

	function ENT:ToggleRangeGrid()
		self:SetNW2Bool("ShowRangeGrid", not self:GetNW2Bool("ShowRangeGrid", true))
		self:RefreshRangeGridButton()
	end

	net.Receive("ery_sentinel_toggle", function(_, ply)
		local sentinel = net.ReadEntity()

		if not IsValid(sentinel) then return end
		if sentinel:GetClass() ~= "sci_pointshop_base_ewr_sentinel" then return end

		sentinel:ToggleActive()
	end)

	function ENT:OpenConfigureMenu(ply)
		if not IsValid(ply) or not ply:IsPlayer() then return end

		local steamID = ply:SteamID64()
		local isFriendly = self.Allegiance[steamID] == true

		net.Start("ery_sentinel_open")
			net.WriteEntity(self)
			net.WriteBool(isFriendly)
		net.Send(ply)
	end

	function ENT:SetAllegiance(ply, friendly)
		if not IsValid(ply) or not ply:IsPlayer() then return end

		local steamID = ply:SteamID64()
		self.Allegiance[steamID] = friendly and true or nil

		if friendly then
			local target = self.CurrentTarget

			if target == ply
				or (IsValid(target) and self:GetEntityOwner(target) == ply) then
				self:ClearTarget()
			end
		end

		ply:ChatPrint(
			"[Sentinel] You are now marked as "
			.. (friendly and "FRIENDLY" or "HOSTILE")
			.. " to this sentinel."
		)
	end

	function ENT:IsFriendly(ply)
		if not IsValid(ply) or not ply:IsPlayer() then return true end
		return self.Allegiance[ply:SteamID64()] == true
	end

	function ENT:ClearAllegiance()
		self.Allegiance = {}
	end

	net.Receive("ery_sentinel_set_allegiance", function(_, ply)
		local sentinel = net.ReadEntity()
		local friendly = net.ReadBool()

		if not IsValid(sentinel) then return end
		if sentinel:GetClass() ~= "sci_pointshop_base_ewr_sentinel" then return end
		if not IsValid(ply) then return end

		sentinel:SetAllegiance(ply, friendly)
	end)

	net.Receive("ery_sentinel_clear_allies", function(_, ply)
		local sentinel = net.ReadEntity()

		if not IsValid(sentinel) then return end
		if sentinel:GetClass() ~= "sci_pointshop_base_ewr_sentinel" then return end
		if not IsValid(ply) then return end

		sentinel:ClearAllegiance()
		ply:ChatPrint("[Sentinel] Allegiance list cleared -- everyone is now HOSTILE.")
	end)

	---------------------------------------------------------
	-- Power interface, called by a linked mainframe.
	---------------------------------------------------------

	function ENT:GetPowerRequired()
		if not self.Active then return 0 end
		return self.PowerRequired or 150
	end

	function ENT:SetPowered(hasPower)
		hasPower = hasPower and true or false

		if hasPower == self.HasPower then return end

		self.HasPower = hasPower
		self:SetNWBool("HasPower", hasPower)

		if not hasPower then
			self:ClearTarget()
		end
	end

	---------------------------------------------------------
	-- Detection
	---------------------------------------------------------

	-- Best-effort owner lookup for a non-player entity. Tries the
	-- common conventions in order: CPPI, the engine owner, the
	-- creator, then a few networked/plain "Owner" fields.
	function ENT:GetEntityOwner(ent)
		if ent.CPPIGetOwner then
			local owner = ent:CPPIGetOwner()
			if IsValid(owner) then return owner end
		end

		local owner = ent:GetOwner()
		if IsValid(owner) then return owner end

		if ent.GetCreator then
			owner = ent:GetCreator()
			if IsValid(owner) then return owner end
		end

		owner = ent:GetNWEntity("Owner", NULL)
		if IsValid(owner) then return owner end

		owner = ent.Owner
		if isentity(owner) and IsValid(owner) then return owner end

		return NULL
	end

	-- Players seated in a vehicle report their own GetPos()/
	-- GetVelocity() unreliably, so for a seated player every
	-- position/range/speed/LOS check (and the lead calculation)
	-- uses the vehicle instead. The player entity itself remains
	-- the target. LVS is checked first since its vehicles don't
	-- use GMod's native vehicle system.
	function ENT:GetTrackedVehicle(ent)
		if not ent:IsPlayer() then return NULL end

		if ent.lvsGetVehicle then
			local lvsVeh = ent:lvsGetVehicle()
			if IsValid(lvsVeh) then return lvsVeh end
		end

		local veh = ent:GetVehicle()
		if IsValid(veh) then
			-- Seats are usually parented to the actual vehicle; use the
			-- root so position/centre/velocity are those of the vehicle.
			local parent = veh:GetParent()
			while IsValid(parent) do
				veh = parent
				parent = veh:GetParent()
			end

			return veh
		end

		return NULL
	end

	function ENT:GetTrackPos(ent)
		local veh = self:GetTrackedVehicle(ent)
		if IsValid(veh) then return veh:GetPos() end
		return ent:GetPos()
	end

	function ENT:GetTrackVelocity(ent)
		local veh = self:GetTrackedVehicle(ent)
		if IsValid(veh) then return veh:GetVelocity() end
		return ent:GetVelocity()
	end

	-- Point to aim at: the centre of the target (a player's GetPos() is
	-- at their feet, a vehicle's origin is not necessarily its middle).
	function ENT:GetTrackCenter(ent)
		local veh = self:GetTrackedVehicle(ent)
		if IsValid(veh) then return veh:WorldSpaceCenter() end
		return ent:WorldSpaceCenter()
	end

	-- Acceleration we know about without measuring: gravity on falling
	-- physics entities and on airborne on-foot players.
	function ENT:GetKnownAcceleration(target)
		if target:IsPlayer() then
			if IsValid(self:GetTrackedVehicle(target)) then return vector_origin end

			if target:GetMoveType() == MOVETYPE_WALK
				and not target:IsOnGround()
				and target:WaterLevel() < 2 then
				return physenv.GetGravity()
			end

			return vector_origin
		end

		if self.GravityCompensation then
			local phys = target:GetPhysicsObject()
			if IsValid(phys) and phys:IsGravityEnabled() then
				return physenv.GetGravity()
			end
		end

		return vector_origin
	end

	-- Samples the target's velocity and keeps a smoothed estimate of its
	-- unexplained acceleration (turning, thrust, drag...). Called every
	-- Think while a target is held, so the estimate is already warm when
	-- a burst starts.
	function ENT:UpdateTracking(target, now)
		local vel = self:GetTrackVelocity(target)
		local tr = self.Track

		if not tr or tr.ent ~= target or (now - tr.time) > 0.5 then
			self.Track = { ent = target, vel = vel, time = now, accel = Vector(0, 0, 0) }
			return
		end

		local dt = now - tr.time
		if dt < (self.TrackSampleInterval or 0.05) then return end

		local raw = (vel - tr.vel) / dt - self:GetKnownAcceleration(target)
		local alpha = 1 - math.exp(-dt / (self.AccelSmoothTime or 0.35))
		local accel = tr.accel + (raw - tr.accel) * alpha

		local maxAccel = self.MaxTargetAccel or 1500
		if accel:LengthSqr() > maxAccel * maxAccel then
			accel = accel:GetNormalized() * maxAccel
		end

		tr.accel = accel
		tr.vel = vel
		tr.time = now
	end

	function ENT:GetTrackAcceleration(target)
		local known = self:GetKnownAcceleration(target)

		if not self.UseTargetAcceleration then return known end

		-- On-foot players change velocity too abruptly to extrapolate.
		if target:IsPlayer() and not IsValid(self:GetTrackedVehicle(target)) then
			return known
		end

		local tr = self.Track
		if not tr or tr.ent ~= target then return known end

		return known + tr.accel
	end

	-- Whether ent is the *kind* of thing the sentinel will shoot at,
	-- independent of speed/range/LOS: a TargetClassPrefix entity, or
	-- a player who hasn't declared themselves friendly.
	function ENT:IsTargetableClass(ent)
		if ent:IsPlayer() then
			return not self:IsFriendly(ent)
		end

		local prefix = self.TargetClassPrefix or "gb5_"
		if string.sub(ent:GetClass(), 1, #prefix) ~= prefix then
			return false
		end

		-- Prefixed entities owned by a friendly player are ignored.
		-- Unowned entities remain targetable.
		local owner = self:GetEntityOwner(ent)
		if IsValid(owner) and owner:IsPlayer() and self:IsFriendly(owner) then
			return false
		end

		return true
	end

	-- A legal target is above this entity, between MinTargetDistance
	-- and DetectionRadius away, at or above MinTargetSpeed, in line
	-- of sight (brushes only), and targetable by class/allegiance.
	function ENT:IsValidTarget(ent, myPos)
		if not IsValid(ent) then return false end
		if ent == self then return false end

		-- Vehicles are never targeted directly; their occupants are.
		if ent:IsVehicle() then return false end

		-- Dead / spectating players are never targets. A player killed
		-- by the sentinel keeps the velocity from the blast, so without
		-- this they still pass the speed check as a "moving target".
		if ent:IsPlayer() then
			if not ent:Alive() or ent:Health() <= 0 then return false end
			if ent:GetObserverMode() ~= OBS_MODE_NONE then return false end
		end

		if not self:IsTargetableClass(ent) then return false end

		local entPos = self:GetTrackPos(ent)

		if entPos.z <= myPos.z then return false end

		local distSqr = entPos:DistToSqr(myPos)

		if distSqr > (self.DetectionRadius or 8000)^2 then
			return false
		end

		if distSqr < (self.MinTargetDistance or 300)^2 then
			return false
		end

		if self:GetTrackVelocity(ent):Length() < (self.MinTargetSpeed or 1000) then
			return false
		end

		local tr = util.TraceLine({
			start = myPos,
			endpos = entPos,
			filter = self,
			mask = MASK_SOLID_BRUSHONLY,
		})

		if tr.Hit and tr.Fraction < 1 then return false end

		return true
	end

	-- Hostile players outrank TargetClassPrefix entities.
	function ENT:GetTargetPriority(ent)
		if ent:IsPlayer() then
			return self.TARGET_PRIORITY_PLAYER or 1
		end
		return self.TARGET_PRIORITY_PREFIXED or 2
	end

	-- Picks the entity to shoot at: highest priority tier first, then
	-- closest. `current` (the entity already being engaged) is kept as
	-- long as it is still valid and nothing of a strictly higher
	-- priority tier has appeared, so the gun doesn't flick between
	-- two similar targets every scan.
	function ENT:FindBestTarget(current)
		local myPos = self:GetPos()

		local best, bestPriority, bestDistSqr

		for _, ent in ipairs(ents.FindInSphere(myPos, self.DetectionRadius or 8000)) do
			if self:IsValidTarget(ent, myPos) then
				local priority = self:GetTargetPriority(ent)
				local distSqr = self:GetTrackPos(ent):DistToSqr(myPos)

				if not best
					or priority < bestPriority
					or (priority == bestPriority and distSqr < bestDistSqr) then
					best, bestPriority, bestDistSqr = ent, priority, distSqr
				end
			end
		end

		if IsValid(current) and self:IsValidTarget(current, myPos) then
			if not best or bestPriority >= self:GetTargetPriority(current) then
				return current
			end
		end

		return best or NULL
	end

	---------------------------------------------------------
	-- Firing
	---------------------------------------------------------

	function ENT:ReloadMagazine()
		self.AmmoLeft = self.MagazineSize or 60
		self:SetNWInt("AmmoLeft", self.AmmoLeft)

		-- A fresh magazine starts a fresh burst, ready immediately.
		self.BurstShotsFired = 0
		self.NextBurstTime = 0
	end

	function ENT:StartReload()
		self:ClearTarget()
		self:SetState("reloading")
		self.ReloadEndTime = CurTime() + (self.ReloadDuration or 4)
	end

	-- Fallback only: used when MuzzleAttachmentIDs has no usable slot.
	function ENT:GetMuzzlePos()
		return self:LocalToWorld(self.MuzzleOffset or Vector(0, 0, 40))
	end

	-- World position of the pitch pivot. It sits on the yaw axis, so
	-- this is the one fixed point the turret's aim is solved from.
	function ENT:GetPivotWorldPos()
		local yawAttach = self.Attachments[self.YawAttachmentID]
		local pitchAttach = self.Attachments[self.PitchAttachmentID]

		local yawPos, yawAng = ChildTransform(
			self:GetPos(), self:GetAngles(),
			yawAttach.Pos or vector_origin, angle_zero
		)

		return (ChildTransform(yawPos, yawAng, pitchAttach.Pos or vector_origin, angle_zero))
	end

	-- Yaw and pitch (in the units the attachments' Angle uses) that
	-- point the turret at targetPos. Yaw is unlimited; pitch is
	-- clamped to Min/MaxElevation. The client animates the turret
	-- toward this (networked by UpdateAim) and the server places each
	-- round's muzzle with it, so the two always agree.
	function ENT:GetTurretAim(targetPos)
		local selfAng = self:GetAngles()
		local toTarget = targetPos - self:GetPivotWorldPos()

		-- Split into the entity's own frame: forward, LEFT (the direction
		-- native positive yaw turns toward) and up.
		local fwd = toTarget:Dot(selfAng:Forward())
		local left = -toTarget:Dot(selfAng:Right())
		local up = toTarget:Dot(selfAng:Up())

		local yaw = math.deg(math.atan2(left, fwd))
		local elevation = math.deg(math.atan2(up, math.sqrt(fwd * fwd + left * left)))

		elevation = math.Clamp(
			elevation,
			self.TurretMinElevation or 0,
			self.TurretMaxElevation or 85
		)

		return yaw, elevation * (self.TurretPitchSign or 1)
	end

	-- World position of a muzzle slot for a turret posed at (yaw,
	-- pitch). Walks the same chain the client draws (entity -> yaw
	-- pivot -> pitch pivot -> slot) using the shared ENT.Attachments
	-- offsets, so nothing is duplicated.
	function ENT:GetTurretSlotPose(slotID, yaw, pitch)
		local yawAttach = self.Attachments[self.YawAttachmentID]
		local pitchAttach = self.Attachments[self.PitchAttachmentID]
		local slotAttach = self.Attachments[slotID]

		local yawPos, yawAng = ChildTransform(
			self:GetPos(), self:GetAngles(),
			yawAttach.Pos or vector_origin, Angle(0, yaw, 0)
		)

		local pitchPos, pitchAng = ChildTransform(
			yawPos, yawAng,
			pitchAttach.Pos or vector_origin, Angle(pitch, 0, 0)
		)

		local slotPos = ChildTransform(
			pitchPos, pitchAng,
			slotAttach.Pos or vector_origin, slotAttach.Angle or angle_zero
		)

		return slotPos, pitchAng
	end

	-- Points the turret at the *lead* point (where the rounds will
	-- actually meet the target), stores the pose for FireAt and
	-- networks it for the client to animate toward. Networked only
	-- when it has moved a meaningful amount, so a steady target
	-- doesn't cost a packet every tick.
	function ENT:UpdateAim(target)
		local lead = self:GetAimPoint(target, self:GetPivotWorldPos())
		local yaw, pitch = self:GetTurretAim(lead)

		self.AimYaw, self.AimPitch = yaw, pitch

		if not self.NetAimYaw
			or math.abs(math.AngleDifference(yaw, self.NetAimYaw)) > 0.1
			or math.abs(pitch - self.NetAimPitch) > 0.1 then
			self.NetAimYaw, self.NetAimPitch = yaw, pitch
			self:SetNWFloat("AimYaw", yaw)
			self:SetNWFloat("AimPitch", pitch)
		end
	end

	-- How far (units) the projectile has fallen below its straight-line
	-- path after t seconds of flight. Mirrors the projectile's gravity:
	-- acceleration ramps linearly 0 -> g over `ramp` seconds, then holds.
	function ENT:GetProjectileDrop(t)
		-- The projectile moves *before* applying gravity each tick, so
		-- its drop lags the continuous curve by about one tick.
		t = t - engine.TickInterval()
		if t <= 0 then return 0 end

		local g = self.ProjectileGravity or 666.7
		local ramp = self.ProjectileGravityRamp or 0.5

		if t <= ramp then
			return g * t * t * t / (6 * ramp)
		end

		local s = t - ramp
		return g * ramp * ramp / 6 + g * ramp * 0.5 * s + 0.5 * g * s * s
	end

	-- Where to point the gun so a projectile launched from muzzlePos
	-- meets the target. The projectile flies a straight line at
	-- ProjectileSpeed and additionally drops by GetProjectileDrop(t), so
	-- we need a flight time t satisfying
	--     |P(t) - muzzle + (0,0,drop(t))| = speed * t
	-- where P(t) is the target's predicted position (velocity plus
	-- estimated acceleration). Solved by fixed-point iteration, which
	-- converges quickly while the target is slower than the projectile.
	function ENT:GetAimPoint(target, muzzlePos)
		local speed = self.ProjectileSpeed or 13333

		local pos = self:GetTrackCenter(target)
		local vel = self:GetTrackVelocity(target)
		local accel = self:GetTrackAcceleration(target)
		local maxT = self.MaxLeadTime or 3

		local t = pos:Distance(muzzlePos) / speed

		for _ = 1, 8 do
			local aimPos = pos + vel * t + accel * (0.5 * t * t)
			aimPos.z = aimPos.z + self:GetProjectileDrop(t)

			local newT = math.min(aimPos:Distance(muzzlePos) / speed, maxT)
			local converged = math.abs(newT - t) < 0.0002
			t = newT

			if converged then break end
		end

		local aimPos = pos + vel * t + accel * (0.5 * t * t)
		aimPos.z = aimPos.z + self:GetProjectileDrop(t)

		return aimPos
	end

	-- Fires a single projectile at target. Returns true if it was fired.
	function ENT:FireAt(target)
		if not IsValid(target) then return false end

		if not (simfphys and simfphys.FirePhysProjectile) then
			if not self.WarnedNoSimfphys then
				self.WarnedNoSimfphys = true
				print("[Sentinel] simfphys.FirePhysProjectile not found -- is simfphys installed?")
			end
			return false
		end

		-- Each round leaves from the next barrel in turn (see
		-- MuzzleAttachmentIDs), at that barrel's position for the pose
		-- the turret is aiming in -- not from one shared point. Lead is
		-- then solved from that exact muzzle, so every barrel's rounds
		-- converge on the target.
		local slots = self.MuzzleAttachmentIDs
		local slotID = slots and slots[self.MuzzleIndex or 1]
		local origin

		if slotID and self.Attachments[slotID] then
			if not self.AimYaw then self:UpdateAim(target) end
			origin = self:GetTurretSlotPose(slotID, self.AimYaw, self.AimPitch)
		else
			origin = self:GetMuzzlePos()
		end

		local aimPos = self:GetAimPoint(target, origin)

		-- Random spread: a small cone around the lead direction.
		local aimAngles = (aimPos - origin):GetNormalized():Angle()
		local spread = self.Spread or 0
		aimAngles.pitch = aimAngles.pitch + math.Rand(-spread, spread)
		aimAngles.yaw = aimAngles.yaw + math.Rand(-spread, spread)

		self:EmitSound(self.FireSound or "apc_fire")

		simfphys.FirePhysProjectile({
			filter = { self },
			shootOrigin = origin,
			shootDirection = aimAngles:Forward(),
			attacker = self,
			attackingent = self,
			Damage = self.ProjectileDamage or 100,
			Force = self.ProjectileForce or 50,
			Size = self.ProjectileSize or 3,
			BlastRadius = self.ProjectileBlastRadius or 50,
			BlastDamage = self.ProjectileBlastDamage or 50,
			DeflectAng = self.ProjectileDeflectAng or 40,
			BlastEffect = self.ProjectileBlastEffect or "simfphys_tankweapon_explosion_micro",
			-- units per nominal tick; ignored by versions that don't read it
			-- (the projectile then uses its default of 200 = 13333 u/s).
			MuzzleVelocity = (self.ProjectileSpeed or 13333) / 66.666,
		})

		-- Only a round that actually left advances the cycle.
		if slots and #slots > 0 then
			self.MuzzleIndex = ((self.MuzzleIndex or 1) % #slots) + 1
		end

		return true
	end

	-- Fires as many rounds of the current burst as are due this tick,
	-- then ends the burst / starts a reload when appropriate.
	function ENT:FireBurstStep(target, now)
		local delay = self.FireDelay or 0.0176
		local burstSize = self.BurstSize or 20

		-- The first round of a burst goes out immediately.
		if (self.BurstShotsFired or 0) == 0 then
			self.NextFireTime = now
		end

		local fired = 0

		while fired < (self.MaxShotsPerThink or 4) and now >= self.NextFireTime do
			if not self:FireAt(target) then
				self.NextFireTime = now + delay
				break
			end

			-- Accumulate so the average rate matches FireDelay despite
			-- tick quantisation.
			self.NextFireTime = self.NextFireTime + delay

			fired = fired + 1
			self.BurstShotsFired = self.BurstShotsFired + 1
			self.AmmoLeft = (self.AmmoLeft or 0) - 1

			if self.AmmoLeft <= 0 or self.BurstShotsFired >= burstSize then
				break
			end
		end

		if fired > 0 then
			self:SetNWInt("AmmoLeft", self.AmmoLeft)
		end

		if self.AmmoLeft <= 0 then
			self:StartReload() -- also ends the burst via ClearTarget
		elseif self.BurstShotsFired >= burstSize then
			self:EndBurst()
		end
	end

	---------------------------------------------------------
	-- Think: scan while idle, shoot while a target is held, reload
	-- when the magazine runs dry. Runs every tick while engaged so
	-- the fire rate and lead stay accurate.
	---------------------------------------------------------

	function ENT:Think()
		local currentTime = CurTime()
		local engaged = false

		if self.Active and self.HasPower then
			if self.State == "reloading" then
				if currentTime >= (self.ReloadEndTime or 0) then
					self:ReloadMagazine()
					self:SetState("idle")
				end
			else
				local myPos = self:GetPos()
				local target = self.CurrentTarget

				-- Drop the current target the moment it stops being valid.
				if IsValid(target) and not self:IsValidTarget(target, myPos) then
					self:ClearTarget()
					target = NULL
				end

				if currentTime >= (self.NextScanTime or 0) then
					self.NextScanTime = currentTime + (self.ScanInterval or 0.25)

					target = self:FindBestTarget(target)
					self:SetTarget(target)
				end

				if IsValid(target) then
					engaged = true
					self:SetState("firing")

					-- Keep tracking even between bursts so the
					-- acceleration estimate is ready when firing resumes.
					self:UpdateTracking(target, currentTime)
					self:UpdateAim(target)

					if currentTime >= (self.NextBurstTime or 0) then
						self:FireBurstStep(target, currentTime)

						if self.State == "reloading" then
							engaged = false
						end
					end
				elseif self.State == "firing" then
					self:SetState("idle")
				end
			end
		end

		self:NextThink(engaged and currentTime or (currentTime + 0.1))
		return true
	end

	function ENT:OnRemove()
		self.BaseClass.OnRemove(self)

		self:UnlinkMainframe()
	end
end

if CLIENT then
	function ENT:Initialize()
		-- Own copy per entity: the turret animation below writes into
		-- the attachment entries, and the class table is shared by every
		-- sentinel, so without this they would all move as one.
		self.Attachments = table.Copy(self.Attachments or {})
	end

	-- Animates the turret rig, purely visually, from networked state:
	-- the server says whether there is a target ("CurrentTarget") and
	-- the yaw/pitch to point at ("AimYaw"/"AimPitch", already solved
	-- for lead). Angles are replaced with new Angle objects rather
	-- than edited in place.
	function ENT:Think()
		local attachments = self.Attachments
		if not attachments then return end

		local yawAttach = attachments[self.YawAttachmentID]
		local pitchAttach = attachments[self.PitchAttachmentID]
		if not yawAttach or not pitchAttach then return end

		local dt = FrameTime()

		-- No target (idle, or reloading): hold the current heading and
		-- settle to the rest elevation.
		local currentYaw = yawAttach.Angle.y
		local currentPitch = pitchAttach.Angle.p

		local targetYaw = currentYaw
		local targetPitch = (self.TurretIdleElevation or 0) * (self.TurretPitchSign or 1)

		if IsValid(self:GetNWEntity("CurrentTarget", NULL)) then
			targetYaw = self:GetNWFloat("AimYaw", targetYaw)
			targetPitch = self:GetNWFloat("AimPitch", targetPitch)
		end

		local yaw = math.ApproachAngle(currentYaw, targetYaw, (self.TurretYawSpeed or 200) * dt)
		local pitch = math.ApproachAngle(currentPitch, targetPitch, (self.TurretPitchSpeed or 100) * dt)

		yawAttach.Angle = Angle(0, math.NormalizeAngle(yaw), 0)
		pitchAttach.Angle = Angle(pitch, 0, 0)
	end

	---------------------------------------------------------
	-- Configure menu (allegiance), mirroring the sentry turret's
	-- panel: allegiance status + button, plus "clear allies".
	---------------------------------------------------------

	net.Receive("ery_sentinel_open", function()
		local sentinel = net.ReadEntity()

		if not IsValid(sentinel) then return end

		local isFriendly = net.ReadBool()

		local rowHeight = 30
		local rowY = 64

		local frame = vgui.Create("DFrame")

		frame:SetTitle(sentinel.PrintName or "Sentinel")
		frame:SetSize(280, 96 + rowHeight * 2)
		frame:Center()
		frame:MakePopup()

		local statusLabel = vgui.Create("DLabel", frame)
		statusLabel:SetPos(8, 32)
		statusLabel:SetSize(frame:GetWide() - 16, 20)
		statusLabel:SetText(
			"This sentinel is currently "
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
			net.Start("ery_sentinel_set_allegiance")
				net.WriteEntity(sentinel)
				net.WriteBool(not isFriendly)
			net.SendToServer()

			frame:Close()
		end
		rowY = rowY + rowHeight

		-- Wipes the whole allegiance list, so everyone goes back to
		-- being targetable.
		local clearAlliesButton = vgui.Create("DButton", frame)
		clearAlliesButton:SetPos(8, rowY)
		clearAlliesButton:SetSize(frame:GetWide() - 16, rowHeight - 4)
		clearAlliesButton:SetText("Clear ally list (make everyone hostile)")

		clearAlliesButton.DoClick = function()
			net.Start("ery_sentinel_clear_allies")
				net.WriteEntity(sentinel)
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

	function ENT:DrawDetectionDome()
		local color = self.DetectionSphereColor or Color(255, 160, 40, 15)

		render.SetColorMaterial()
		render.DrawSphere(
			self:GetPos(),
			self.DetectionRadius or 8000,
			24,
			24,
			color,
			false
		)

		local colorWire = self.DetectionSphereColorWire or Color(255, 160, 40, 200)

		render.SetColorMaterial()
		render.DrawWireframeSphere(
			self:GetPos(),
			self.DetectionRadius or 8000,
			24,
			24,
			colorWire,
			false
		)

		local deadRadius = self.MinTargetDistance or 300

		if deadRadius > 0 then
			local deadColor = self.DeadZoneSphereColor or Color(255, 60, 60, 20)
			local deadColorWire = self.DeadZoneSphereColorWire or Color(255, 60, 60, 200)

			render.SetColorMaterial()
			render.DrawSphere(
				self:GetPos(),
				deadRadius,
				24,
				24,
				deadColor,
				false
			)

			render.SetColorMaterial()
			render.DrawWireframeSphere(
				self:GetPos(),
				deadRadius,
				24,
				24,
				deadColorWire,
				false
			)
		end
	end

	function ENT:IsLookingAtForDome()
		local ply = LocalPlayer()
		if not IsValid(ply) then return false end

		local maxDist = self.SphereDrawDistance or 9000
		if self:GetPos():DistToSqr(ply:GetPos()) > (maxDist * maxDist) then
			return false
		end

		local tr = util.TraceLine({
			start = ply:EyePos(),
			endpos = ply:EyePos() + ply:EyeAngles():Forward() * maxDist,
			filter = ply,
		})

		return tr.Entity == self
	end

	function ENT:Draw()
		self:DrawModel()

		local attachDist = (self.AttachmentDrawDistance or 500)^2
		if self:GetPos():DistToSqr(LocalPlayer():GetPos()) <= attachDist then
			ERY_MACHINE:DrawAttachments(self, self.Attachments)
		end

		self:DrawLabel() -- base class label only

		if self:GetNW2Bool("ShowRangeGrid", true) and self:IsLookingAtForDome() then
			self:DrawDetectionDome()
		end
	end

	function ENT:OnRemove()
		ERY_MACHINE:CleanupAttachments(self)
	end
end
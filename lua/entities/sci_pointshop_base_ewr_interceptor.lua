AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "sci_pointshop_entity_base_ui"

ENT.PrintName = "Interceptor"
ENT.Author = "Paloma"
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.Category = "Pointshop Entities"

ENT.IconPath = "entities/sci_pointshop_base_ewr_interceptor.png"
ENT.IconOffset = Vector(120, 0, -15)

-- The fixed base plate (never moves). Placeholder model: swap freely, but
-- keep PLATE_TOP in the launcher rig section below in step with its top face.
ENT.BaseModel = "models/hunter/blocks/cube4x4x4.mdl"
ENT.BaseMaterial = "models/effects/intro_tearshape"
ENT.BaseColor = Color(80, 90, 100, 255)
ENT.BoneScale = Vector(1, 1, 1)

ENT.AttachmentDrawDistance = 16000
ENT.LabelDrawDistance = 300
ENT.Decaytime = -1

ENT.CableOffset = Vector(0, 0, -80)

ENT.MaxHealth = 1250
ENT.HealthRegen = 5
ENT.CustomMass = 400

ENT.SpawnOffset = Vector(0, 0, 100) -- world-space offset applied 0.1s after spawning

ENT.CollideSounds = {
	"physics/metal/metal_box_impact_bullet1.wav",
	"physics/metal/metal_box_impact_bullet2.wav",
	"physics/metal/metal_box_impact_bullet3.wav",
}

---------------------------------------------------------
-- Interceptor settings
---------------------------------------------------------

ENT.DetectionRadius = 8000

ENT.MinTargetDistance = 1250

ENT.MinTargetSpeed = 1000

ENT.MissileClass = "sci_pointshop_base_ewr_interceptor_missile"

ENT.DetectionSphereColor = Color(255, 160, 40, 15) --15
ENT.DetectionSphereColorWire = Color(255, 160, 40, 200) --200

ENT.DeadZoneSphereColor = Color(255, 60, 60, 20) --20
ENT.DeadZoneSphereColorWire = Color(255, 60, 60, 200) --200

ENT.SphereDrawDistance = 16000

ENT.ScanInterval = 0.25

ENT.MissilesLoaded = 4

ENT.VolleyFireDelay = 0.25

-- Highest number of distinct targets a single volley will engage
-- (one target per missile, at most). Smart targeting never
-- benefits from tracking more targets than there are missiles to
-- split among them.
ENT.MaxTargetsPerVolley = 4

ENT.TargetAcquisitionDelay = 0.75

ENT.CooldownDuration = 6

ENT.LaunchOffset = Vector(0, 0, 40)

ENT.MissileProximityFuse = 400

ENT.MissileSpread = 15

ENT.Active = true

ENT.PowerRole = "consumer"
ENT.PowerRequired = 150

ENT.TargetClassPrefix = "gb5_"

ENT.TARGET_PRIORITY_PLAYER = 1
ENT.TARGET_PRIORITY_PREFIXED = 2

---------------------------------------------------------
-- Launcher rig
--
-- Shared on purpose: the client draws ENT.Attachments, and the
-- server reads the very same table to find where each missile
-- leaves from, so slot positions live in exactly one place.
--
-- Attachment chain (IDs are array positions in the table below):
--
--   entity ......... the base plate; never moves
--    `- 1 .......... yaw pivot    (Angle.y is driven toward the target)
--        |- 2, 3, 4 .. turntable + support arms (turn with the yaw)
--        `- 5 ........ pitch pivot (Angle.p is driven toward the
--            |                       target, clamped to Min/MaxElevation)
--            |- 6 ....... cradle tray
--            `- 7 - 10 ... missiles, launched 7 first ... 10 last
--
-- Conventions inherited from ERY_MACHINE:DrawAttachments: Pos is
-- +X forward, +Y RIGHT (it multiplies Right() by Pos.y) and +Z up;
-- and its RotateAroundAxis composition makes a positive Angle.p
-- tilt the nose UP, the opposite of native Source angles -- so
-- Angle.p is simply the elevation.
---------------------------------------------------------

ENT.YawAttachmentID = 1
ENT.PitchAttachmentID = 5

-- Launch order: the first entry is the first missile fired (the
-- rightmost one, seen from behind the launcher), the last entry is
-- the leftmost. Keep the length equal to MissilesLoaded.
ENT.MissileAttachmentIDs = { 7, 8, 9, 10 }

ENT.LauncherMinElevation = 0        -- degrees
ENT.LauncherMaxElevation = 45
ENT.LauncherIdleElevation = 0       -- where the launcher rests with no target
ENT.LauncherYawSpeed = 180          -- degrees/second (client visual only)
ENT.LauncherPitchSpeed = 90

-- If the launcher ever tilts DOWN toward a target above it, flip
-- this to -1 (see the conventions note above).
ENT.LauncherPitchSign = 1

-- Placeholder geometry, tune to taste / to your real models.
local PLATE_TOP = -80.5           -- top face of the base plate, relative to the entity origin
local PIVOT_HEIGHT = 38         -- yaw axis -> pitch axis
local MISSILE_SPACING = 40      -- centre to centre, side by side
local MISSILE_HEIGHT = 12        -- missile axis above the pitch pivot
local BLOCK = "models/hunter/blocks/cube025x025x025.mdl" -- ~12 unit cube, shaped with AxisScale

ENT.Attachments = {
	{
		-- Yaw pivot. Invisible: an empty Model is a pure pivot.
		-- Angle.y is animated on the client (see ENT:Think below).
		ID = 1,
		Model = "",
		Pos = Vector(0, 0, PLATE_TOP),
		Angle = Angle(0, 0, 0),
		Parent = 0
	},

	{
		-- Turntable
		ID = 2,
		Model = "models/props_junk/terracotta01.mdl",
		Pos = Vector(7.5, 0, 1),
		Angle = Angle(0, 0, 180),
		Color = Color(255, 255, 255),
		Material = "metal4",
		AxisScale = Vector(9.5, 9.5, 1.0),
		Parent = 1
	},

	{
		-- Support arm, right
		ID = 3,
		Model = BLOCK,
		Pos = Vector(0, 35, 23),
		Angle = Angle(0, 0, 0),
		Color = Color(70, 70, 70),
		Material = "models/effects/intro_tearshape",
		AxisScale = Vector(0.8, 0.5, 2.85),
		Parent = 1
	},

	{
		-- Support arm, left
		ID = 4,
		Model = "models/props_wasteland/panel_leverHandle001a.mdl",
		Pos = Vector(-8, 0, 30),
		Angle = Angle(0, 0, 180),
		Color = Color(70, 70, 70),
		Material = "metal5",
		AxisScale = Vector(5, 10.5, 3),
		Parent = 1
	},

	{
		-- Pitch pivot. Invisible. Must sit on the yaw axis (Pos.x and
		-- Pos.y = 0): ENT:GetLauncherAim relies on it. Angle.p is
		-- animated on the client (see ENT:Think below).
		ID = 5,
		Pos = Vector(27.5, 0, PIVOT_HEIGHT),
		Angle = Angle(0, 0, 0),
		Parent = 1
	},

	{
		ID = 6,
		Model = "models/props_combine/combine_train02a.mdl",
		Pos = Vector(-50.5, 14, -30),
		Angle = Angle(0, 90, 90),
		Color = Color(70, 70, 70),
		Material = "metal5",
		AxisScale = Vector(0.35, 0.225, 0.175),
		Parent = 2
	},

	-- Missiles, right to left (+Y is right). Hidden is driven by the
	-- networked MissilesLeft in ENT:Think below. If the model faces
	-- the wrong way, correct it with Angle here -- launches use the
	-- pitch pivot's heading, not this Angle.
	{
		ID = 7,
		Model = "models/military2/missile/missile_barak.mdl",
		Pos = Vector(50.5, MISSILE_SPACING * 1.5, MISSILE_HEIGHT),
		Angle = Angle(0, 0, 45),
		Color = Color(255, 255, 255),
		Material = "",
        AxisScale = Vector(1.5, 1, 1),
		Hidden = false,
		Parent = 5
	},

	{
		ID = 8,
		Model = "models/military2/missile/missile_barak.mdl",
		Pos = Vector(50.5, MISSILE_SPACING * 0.85, MISSILE_HEIGHT),
		Angle = Angle(0, 0, 45),
		Color = Color(255, 255, 255),
		Material = "",
        AxisScale = Vector(1.5, 1, 1),
		Hidden = false,
		Parent = 5
	},

	{
		ID = 9,
		Model = "models/military2/missile/missile_barak.mdl",
		Pos = Vector(50.5, -MISSILE_SPACING * 0.85, MISSILE_HEIGHT),
		Angle = Angle(0, 0, 45),
		Color = Color(255, 255, 255),
		Material = "",
        AxisScale = Vector(1.5, 1, 1),
		Hidden = false,
		Parent = 5
	},

	{
		ID = 10,
		Model = "models/military2/missile/missile_barak.mdl",
		Pos = Vector(50.5, -MISSILE_SPACING * 1.5, MISSILE_HEIGHT),
		Angle = Angle(0, 0, 45),
		Color = Color(255, 255, 255),
		Material = "",
        AxisScale = Vector(1.5, 1, 1),
		Hidden = false,
		Parent = 5
	},

    {
        ID = 11,
        Model = "models/props_phx/misc/potato_launcher_cap.mdl",
        Pos = Vector(0, 0, -95),
        Angle = Angle(0, 0, 0),
        Color = Color(150, 150, 150),
        Material = "metal2a",
        Scale = 1,
        AxisScale = Vector(12, 12, 3.5),
        Parent = 0
    },

    {
        ID = 12,
        Model = "models/xqm/pistontype1big.mdl",
        Pos = Vector(0, 0, -60),
        Angle = Angle(0, 0, 180),
        Color = Color(150, 150, 150),
        Material = "metal2a",
        Scale = 1,
        AxisScale = Vector(2, 2, 0.8),
        Parent = 0
    },

	{
		ID = 13,
		Model = "models/props_combine/combine_train02a.mdl",
		Pos = Vector(-50.5, -14, -30),
		Angle = Angle(0, 90, -90),
		Color = Color(70, 70, 70),
		Material = "metal5",
		AxisScale = Vector(0.35, 0.225, 0.175),
		Parent = 2
	},

	{
		ID = 14,
		Model = "models/props_interiors/attic_beam001b.mdl",
		Pos = Vector(35, 0, -12),
		Angle = Angle(90, 0, 90),
		Color = Color(70, 70, 70),
		Material = "metal5",
		AxisScale = Vector(0.35, 0.15, 0.55),
		Parent = 5
	},

	{
		ID = 15,
		Model = "models/xqm/CoasterTrack/track_guide.mdl",
		Pos = Vector(50, 60, 7),
		Angle = Angle(0, 0, 180),
		Color = Color(70, 70, 70),
		Material = "metal5",
		AxisScale = Vector(7.5, 0.155, 0.5),
		Parent = 5
	},

	{
		ID = 16,
		Model = "models/xqm/CoasterTrack/track_guide.mdl",
		Pos = Vector(50, -60, 7),
		Angle = Angle(0, 0, 180),
		Color = Color(70, 70, 70),
		Material = "metal5",
		AxisScale = Vector(7.5, 0.155, 0.5),
		Parent = 5
	},

	{
		ID = 17,
		Model = "models/xqm/CoasterTrack/track_guide.mdl",
		Pos = Vector(50, 33.75, 7),
		Angle = Angle(0, 0, 180),
		Color = Color(70, 70, 70),
		Material = "metal5",
		AxisScale = Vector(7.5, 0.155, 0.5),
		Parent = 5
	},

	{
		ID = 18,
		Model = "models/xqm/CoasterTrack/track_guide.mdl",
		Pos = Vector(50, -33.75, 7),
		Angle = Angle(0, 0, 180),
		Color = Color(70, 70, 70),
		Material = "metal5",
		AxisScale = Vector(7.5, 0.155, 0.5),
		Parent = 5
	},
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

-- Moved out of the SERVER block: the client launcher needs the very
-- same tracked position the server aims with.
-- Players seated in a vehicle report their own GetPos()/
-- GetVelocity() unreliably for targeting purposes -- their
-- position can lag the vehicle, and GetVelocity() on a
-- passenger frequently reads near-zero even while the vehicle
-- is moving well above MinTargetSpeed. So for a seated player
-- every position/range/speed/LOS check is done against the
-- vehicle they're riding instead; the player entity itself
-- remains the actual target (LockOn/FireMissileAt still aim at
-- the player, and the missile's own homing tracks the
-- player/vehicle in flight same as any other target).
--
-- Checks LVS (Lambda's Vehicle Simulator) first, since LVS
-- vehicles don't use GMod's native vehicle system at all --
-- ply:GetVehicle() returns NULL for a player sitting in one,
-- even though they're visibly riding it. ply:lvsGetVehicle()
-- is LVS's own accessor (shared realm, safe to call whether or
-- not the player is actually in an LVS seat) and returns the
-- LVS vehicle entity itself, which -- being a normal physics
-- entity -- has ordinary GetPos()/GetVelocity(). Falls back to
-- the native ply:GetVehicle() for vanilla/other addon vehicles
-- that DO use the native system.
function ENT:GetTrackedVehicle(ent)
	if not ent:IsPlayer() then return NULL end

	if ent.lvsGetVehicle then
		local lvsVeh = ent:lvsGetVehicle()
		if IsValid(lvsVeh) then return lvsVeh end
	end

	local veh = ent:GetVehicle()
	if IsValid(veh) then return veh end

	return NULL
end

function ENT:GetTrackPos(ent)
	local veh = self:GetTrackedVehicle(ent)
	if IsValid(veh) then return veh:GetPos() end
	return ent:GetPos()
end

-- Yaw and pitch (in the units the attachments' Angle uses) that
-- point the launcher at targetPos. Yaw is unlimited; pitch is
-- clamped to Min/MaxElevation, so a target above the cone is simply
-- aimed at the steepest allowed angle. The client animates the
-- launcher with this and the server places and aims each launch with
-- it, so the two always agree.
--
-- Solved from a single fixed point, which is only valid because the
-- pitch pivot sits on the yaw axis (see attachment 5).
function ENT:GetLauncherAim(targetPos)
	local yawAttach = self.Attachments[self.YawAttachmentID]
	local pitchAttach = self.Attachments[self.PitchAttachmentID]
	if not yawAttach or not pitchAttach then return 0, 0 end

	local selfAng = self:GetAngles()

	local yawPos, yawAng = ChildTransform(self:GetPos(), selfAng, yawAttach.Pos or vector_origin, angle_zero)
	local pivotPos = ChildTransform(yawPos, yawAng, pitchAttach.Pos or vector_origin, angle_zero)

	local toTarget = targetPos - pivotPos

	-- Split into the entity's own frame: forward, LEFT (the direction
	-- native positive yaw turns toward) and up.
	local fwd = toTarget:Dot(selfAng:Forward())
	local left = -toTarget:Dot(selfAng:Right())
	local up = toTarget:Dot(selfAng:Up())

	local yaw = math.deg(math.atan2(left, fwd))
	local elevation = math.deg(math.atan2(up, math.sqrt(fwd * fwd + left * left)))

	elevation = math.Clamp(
		elevation,
		self.LauncherMinElevation or 0,
		self.LauncherMaxElevation or 45
	)

	return yaw, elevation * (self.LauncherPitchSign or 1)
end

if SERVER then
	util.AddNetworkString("ery_interceptor_open")
	util.AddNetworkString("ery_interceptor_set_allegiance")
	util.AddNetworkString("ery_interceptor_clear_allies")
	util.AddNetworkString("ery_interceptor_toggle")

	---------------------------------------------------------
	-- Setup
	---------------------------------------------------------

	function ENT:Initialize()
		self.BaseClass.Initialize(self)

		self:SetUseType(SIMPLE_USE)

		self:SetNW2Bool("Active", self.Active)

		self.HasPower = false
		self:SetNWBool("HasPower", false)

		self.State = "idle"
		self:SetNWString("InterceptorState", "idle")

		self.NextScanTime = 0
		self.CooldownEndTime = 0
		self.TrackingEndTime = 0
		self.TrackedSet = nil

		self.CurrentTarget = NULL
		self:SetNWEntity("CurrentTarget", NULL)
		self.CurrentTargets = {}

		-- Launcher visual state: who the rig should point at, and how
		-- many missiles are still on the rails (see ReloadMissiles).
		self:SetAimTarget(NULL)
		self:ReloadMissiles()

		self.Allegiance = {}

		self:AddMenuButton("configure", "Configure", function(ent, activator)
			ent:OpenConfigureMenu(activator)
		end)

		self:RefreshToggleButton()
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
			-- Switching off mid-scan/mid-cooldown halts future
			-- action immediately, same as losing power -- a
			-- volley already in flight is not recalled.
			self.CurrentTarget = NULL
			self:SetNWEntity("CurrentTarget", NULL)
			self.CurrentTargets = {}
			self:SetAimTarget(NULL)

			-- Unlike cooldown (which is fine resuming wherever its
			-- countdown lands), leaving state at "tracking" here
			-- would mean powering back on later fires instantly off
			-- a stale acquisition window instead of giving fresh
			-- targets their intended delay -- so drop back to idle
			-- outright.
			if self.State == "tracking" then
				self.State = "idle"
				self:SetNWString("InterceptorState", "idle")
				self.TrackedSet = nil
			end
		end
	end

	net.Receive("ery_interceptor_toggle", function(_, ply)
		local interceptor = net.ReadEntity()

		if not IsValid(interceptor) then return end
		if interceptor:GetClass() ~= "sci_pointshop_base_ewr_interceptor" then return end

		interceptor:ToggleActive()
	end)

	function ENT:OpenConfigureMenu(ply)
		if not IsValid(ply) or not ply:IsPlayer() then return end

		local steamID = ply:SteamID64()
		local isFriendly = self.Allegiance[steamID] == true

		net.Start("ery_interceptor_open")
			net.WriteEntity(self)
			net.WriteBool(isFriendly)
		net.Send(ply)
	end

	function ENT:SetAllegiance(ply, friendly)
		if not IsValid(ply) or not ply:IsPlayer() then return end

		local steamID = ply:SteamID64()
		self.Allegiance[steamID] = friendly and true or nil

		if friendly then
			if self.CurrentTargets then
				for i = #self.CurrentTargets, 1, -1 do
					local t = self.CurrentTargets[i]
					if t == ply or (IsValid(t) and self:GetEntityOwner(t) == ply) then
						table.remove(self.CurrentTargets, i)
					end
				end
			end

			if self.CurrentTarget == ply
				or (IsValid(self.CurrentTarget) and self:GetEntityOwner(self.CurrentTarget) == ply) then
				self.CurrentTarget = (self.CurrentTargets and self.CurrentTargets[1]) or NULL
				self:SetNWEntity("CurrentTarget", self.CurrentTarget)
			end

			local aim = self:GetNWEntity("AimTarget", NULL)
			if aim == ply or (IsValid(aim) and self:GetEntityOwner(aim) == ply) then
				self:SetAimTarget(self.CurrentTargets and self.CurrentTargets[1])
			end
		end

		ply:ChatPrint(
			"[Interceptor] You are now marked as "
			.. (friendly and "FRIENDLY" or "HOSTILE")
			.. " to this interceptor."
		)
	end

	function ENT:IsFriendly(ply)
		if not IsValid(ply) or not ply:IsPlayer() then return true end
		return self.Allegiance[ply:SteamID64()] == true
	end

	function ENT:ClearAllegiance()
		self.Allegiance = {}
	end

	net.Receive("ery_interceptor_set_allegiance", function(_, ply)
		local interceptor = net.ReadEntity()
		local friendly = net.ReadBool()

		if not IsValid(interceptor) then return end
		if interceptor:GetClass() ~= "sci_pointshop_base_ewr_interceptor" then return end
		if not IsValid(ply) then return end

		interceptor:SetAllegiance(ply, friendly)
	end)

	net.Receive("ery_interceptor_clear_allies", function(_, ply)
		local interceptor = net.ReadEntity()

		if not IsValid(interceptor) then return end
		if interceptor:GetClass() ~= "sci_pointshop_base_ewr_interceptor" then return end
		if not IsValid(ply) then return end

		interceptor:ClearAllegiance()
		ply:ChatPrint("[Interceptor] Allegiance list cleared -- everyone is now HOSTILE.")
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
			-- Losing power mid-scan/mid-cooldown just halts future
			-- action; a volley already in flight (missiles already
			-- spawned) is not recalled, same spirit as the EWR
			-- screen not erasing entries it already has on power
			-- loss.
			self.CurrentTarget = NULL
			self:SetNWEntity("CurrentTarget", NULL)
			self.CurrentTargets = {}
			self:SetAimTarget(NULL)

			-- See ToggleActive's equivalent comment -- avoid an
			-- instant fire off a stale acquisition window when
			-- power returns.
			if self.State == "tracking" then
				self.State = "idle"
				self:SetNWString("InterceptorState", "idle")
				self.TrackedSet = nil
			end
		end
	end

	---------------------------------------------------------
	-- Detection
	---------------------------------------------------------

	-- Best-effort owner lookup for a non-player entity. Tries the
	-- common conventions in order: CPPI (Prop Protection / FPP /
	-- similar), the engine owner, the creator, then a few
	-- networked/plain "Owner" fields. If your gb5_ entities store
	-- their owner some other way, add it here.
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

	-- Whether ent is even the *kind* of thing the interceptor is
	-- willing to consider, independent of speed/range/LOS: either
	-- a "gb_"-prefixed entity (checked by classname prefix, not
	-- exact match, so subclasses/variants are covered too), or a
	-- player who hasn't declared themselves friendly. Every
	-- player is hostile by default; declaring friendly is done by
	-- +using the interceptor (see OpenConfigureMenu/SetAllegiance
	-- above), same as the sentry turret.
	function ENT:IsTargetableClass(ent)
		if ent:IsPlayer() then
			return not self:IsFriendly(ent)
		end

		local prefix = self.TargetClassPrefix or "gb_"
		if string.sub(ent:GetClass(), 1, #prefix) ~= prefix then
			return false
		end

		-- Prefixed entities owned by a friendly player are ignored.
		-- Unowned entities (no resolvable owner) remain targetable.
		local owner = self:GetEntityOwner(ent)
		if IsValid(owner) and owner:IsPlayer() and self:IsFriendly(owner) then
			return false
		end

		return true
	end

	-- GetTrackedVehicle / GetTrackPos live in the shared launcher-rig
	-- section near the top of this file (the client aims with them too).

	function ENT:GetTrackVelocity(ent)
		local veh = self:GetTrackedVehicle(ent)
		if IsValid(veh) then return veh:GetVelocity() end
		return ent:GetVelocity()
	end

	-- Returns true if ent is a legal target: above this entity
	-- (dome, never below), at least MinTargetDistance and no more
	-- than DetectionRadius away, at or above
	-- MinTargetSpeed, not our own missile class, in line of
	-- sight, and either a "gb_"-prefixed entity or a hostile
	-- player (see IsTargetableClass/allegiance below). Position,
	-- speed, and LOS are all checked against the vehicle for a
	-- seated player (see GetTrackPos/GetTrackVelocity), so a
	-- player riding in a fast-moving vehicle is targeted just like
	-- one flying/moving under their own power.
	function ENT:IsValidTarget(ent, myPos)
		if not IsValid(ent) then return false end
		if ent == self then return false end
		if ent:GetClass() == self.MissileClass then return false end

		-- Vehicles themselves are never a target class -- a driver/
		-- passenger inside one is targeted via the player entity
		-- (tracked against the vehicle by GetTrackPos/
		-- GetTrackVelocity above), not the vehicle entity itself.
		if ent:IsVehicle() then return false end

		if not self:IsTargetableClass(ent) then return false end

		local entPos = self:GetTrackPos(ent)

		if entPos.z <= myPos.z then return false end

		local distSqr = entPos:DistToSqr(myPos)

		if distSqr > (self.DetectionRadius or 4000)^2 then
			return false
		end

		-- Inner bound: too close to the interceptor (dead zone).
		-- Strictly less-than, so a target sitting at exactly
		-- MinTargetDistance is still legal ("at least" 750).
		if distSqr < (self.MinTargetDistance or 750)^2 then
			return false
		end

		local vel = self:GetTrackVelocity(ent)
		if vel:Length() < (self.MinTargetSpeed or 2500) then return false end

		local tr = util.TraceLine({
			start = myPos,
			endpos = entPos,
			filter = self,
			mask = MASK_SOLID_BRUSHONLY,
		})

		if tr.Hit and tr.Fraction < 1 then return false end

		return true
	end

	-- Priority tier for a candidate: hostile players always rank
	-- above TargetClassPrefix entities (see TARGET_PRIORITY_*
	-- constants). Assumes ent has already passed
	-- IsTargetableClass, so anything not a player is by
	-- elimination a prefixed entity.
	function ENT:GetTargetPriority(ent)
		if ent:IsPlayer() then
			return self.TARGET_PRIORITY_PLAYER or 1
		end
		return self.TARGET_PRIORITY_PREFIXED or 2
	end

	-- Sweeps DetectionRadius via a spatial query (cheap broad-phase
	-- vs. iterating every entity in the map), filters down to valid
	-- targets, then ranks them: hostile players outrank "gb5_"
	-- entities, and ties within a tier are broken by distance
	-- (closest first -- this also means the closest player always
	-- comes before any other player). Returns an ordered list,
	-- capped at MaxTargetsPerVolley entries, or an empty list if
	-- nothing qualifies.
	function ENT:FindTargets()
		local myPos = self:GetPos()
		local nearby = ents.FindInSphere(myPos, self.DetectionRadius or 4000)

		local candidates = {}

		for _, ent in ipairs(nearby) do
			if self:IsValidTarget(ent, myPos) then
				candidates[#candidates + 1] = {
					ent = ent,
					priority = self:GetTargetPriority(ent),
					distSqr = self:GetTrackPos(ent):DistToSqr(myPos),
				}
			end
		end

		table.sort(candidates, function(a, b)
			if a.priority ~= b.priority then
				return a.priority < b.priority
			end
			return a.distSqr < b.distSqr
		end)

		local maxTargets = self.MaxTargetsPerVolley or 4
		local targets = {}

		for i = 1, math.min(#candidates, maxTargets) do
			targets[#targets + 1] = candidates[i].ent
		end

		return targets
	end

	function ENT:BuildTargetSet(targets)
		local set = {}
		for _, target in ipairs(targets) do
			set[target] = true
		end
		return set
	end

	-- Splits MissilesLoaded across an ordered (highest-priority
	-- first) list of targets, one missile per target minimum, with
	-- every "extra" missile beyond one-per-target going to the
	-- highest priority targets first:
	--   1 target  -> all missiles at it (e.g. 4)
	--   2 targets -> split as evenly as possible, extras to the
	--                front (e.g. 2/2)
	--   3 targets -> extras to the front (e.g. 2/1/1)
	--   4 targets -> exactly 1 each (e.g. 1/1/1/1)
	-- Returns a list of {ent = target, count = missileCount}
	-- entries, in the same priority order as targets.
	function ENT:AllocateMissiles(targets)
		local total = self.MissilesLoaded or 4
		local n = #targets

		local allocation = {}
		if n == 0 then return allocation end

		local base = math.floor(total / n)
		local extra = total % n

		for i, target in ipairs(targets) do
			local count = base + (i <= extra and 1 or 0)
			if count > 0 then
				allocation[#allocation + 1] = { ent = target, count = count }
			end
		end

		return allocation
	end

	---------------------------------------------------------
	-- Firing
	---------------------------------------------------------

	-- Who the launcher rig should point at. Networked for the client
	-- to animate; cleared whenever there is nothing to engage.
	function ENT:SetAimTarget(ent)
		ent = IsValid(ent) and ent or NULL

		if self:GetNWEntity("AimTarget", NULL) ~= ent then
			self:SetNWEntity("AimTarget", ent)
		end
	end

	-- Puts every missile back on the rails at once. Called when the
	-- cooldown ends (and on spawn). MissilesFired counts launches, so
	-- the next volley starts again from the rightmost slot.
	function ENT:ReloadMissiles()
		self.MissilesFired = 0
		self:SetNWInt("MissilesLeft", self.MissilesLoaded or 4)
	end

	-- World position of a missile slot, plus the launcher's heading,
	-- for a launcher posed at (yaw, pitch). Walks the same chain the
	-- client draws (entity -> yaw pivot -> pitch pivot -> slot) using
	-- the shared ENT.Attachments offsets, so nothing is duplicated.
	-- The chain is fixed by design: keep attachment 1 -> 5 -> slot.
	function ENT:GetLauncherSlotPose(slotID, yaw, pitch)
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

	-- Spawns and launches a single missile at target. It leaves from
	-- the next loaded slot (right to left), pointing along the launcher
	-- as it is posed for this target -- i.e. clamped to the launcher's
	-- elevation limits, so a steep target is climbed toward by homing
	-- rather than launched straight at. Falls back to LaunchOffset if
	-- there are more shots than slots.
	function ENT:FireMissileAt(target)
		if not IsValid(target) then return end

		self:SetAimTarget(target)

		-- Tracked position (the vehicle's, if target is a seated
		-- player) so the initial launch heading points at where the
		-- target actually is; homing (SetLockOn) takes over from
		-- there same as always.
		local aimPos = self:GetTrackPos(target)

		local slotID = self.MissileAttachmentIDs[(self.MissilesFired or 0) + 1]
		local launchPos, aimAngles

		if slotID and self.Attachments[slotID] then
			local yaw, pitch = self:GetLauncherAim(aimPos)
			local launcherAng
			launchPos, launcherAng = self:GetLauncherSlotPose(slotID, yaw, pitch)
			aimAngles = launcherAng:Forward():Angle()
		else
			launchPos = self:LocalToWorld(self.LaunchOffset or Vector(0, 0, 40))
			aimAngles = (aimPos - launchPos):GetNormalized():Angle()
		end

		-- Small random spread so a volley doesn't leave the tube
		-- in a perfectly identical line -- applied once to the
		-- launch angle only, not an ongoing in-flight wobble, so
		-- a homing missile still corrects back onto the target.
		local spread = self.MissileSpread or 3
		aimAngles.pitch = aimAngles.pitch + math.Rand(-spread, spread)
		aimAngles.yaw = aimAngles.yaw + math.Rand(-spread, spread)

		local missile = ents.Create(self.MissileClass)
		if not IsValid(missile) then return end

		missile:SetPos(launchPos)
		missile:SetAngles(aimAngles)
		missile:Spawn()
		missile:Activate()

		missile:SetAttacker(self)
		missile:SetInflictor(self)
		missile:SetLockOn(target)
		missile:SetProximityFuse(self.MissileProximityFuse or 200)

		-- Only a missile that actually left counts, so a skipped shot
		-- (target lost) does not empty a rail.
		self.MissilesFired = (self.MissilesFired or 0) + 1
		self:SetNWInt("MissilesLeft", math.max(0, (self.MissilesLoaded or 4) - self.MissilesFired))
	end

	-- Flattens a {ent, count} allocation (see AllocateMissiles) into
	-- a flat, ordered shot list -- one entry per individual missile
	-- -- grouped by target rather than interleaved, so e.g. a 2/1/1
	-- split fires both shots at the top-priority target before
	-- moving to the next, rather than round-robining across
	-- targets.
	local function BuildShotList(allocation)
		local shots = {}
		for _, entry in ipairs(allocation) do
			for _ = 1, entry.count do
				shots[#shots + 1] = entry.ent
			end
		end
		return shots
	end

	-- Fires the volley one missile at a time with a short delay
	-- between each, smart-split across up to MaxTargetsPerVolley
	-- targets per AllocateMissiles (1 target gets the whole
	-- MissilesLoaded, 2 splits evenly, 3+ favors the highest-
	-- priority target(s) with any extras -- see AllocateMissiles).
	-- Every individual shot re-checks that its specific target is
	-- still valid; a target lost partway through (killed, went
	-- out of range/LOS, declared friendly) is simply skipped rather
	-- than aborting the rest of the volley, since the other
	-- targets' shots are unaffected by it. Always ends in cooldown
	-- once every shot has been attempted, whether every shot
	-- actually fired or not.
	function ENT:StartVolley(targets)
		self.State = "firing"
		self:SetNWString("InterceptorState", "firing")

		-- CurrentTarget/its NWEntity stay as the single highest-
		-- priority target for backward-compatible networked state;
		-- CurrentTargets (not networked) is the real multi-target
		-- list StartVolley fires against.
		local primary = targets[1] or NULL
		self.CurrentTarget = primary
		self:SetNWEntity("CurrentTarget", primary)
		self.CurrentTargets = targets

		local allocation = self:AllocateMissiles(targets)
		local shots = BuildShotList(allocation)

		local shotIndex = 0

		local function FireNext()
			if not IsValid(self) then return end

			-- Power can drop mid-volley, or the player can switch
			-- the interceptor off; stop launching further shots if
			-- so (already-launched missiles fly on their own
			-- regardless, same as SetPowered(false)/ToggleActive
			-- above).
			if not self.HasPower or not self.Active then
				self:EnterCooldown()
				return
			end

			shotIndex = shotIndex + 1
			local shotTarget = shots[shotIndex]

			if not shotTarget then
				self:EnterCooldown()
				return
			end

			local myPos = self:GetPos()
			if self:IsValidTarget(shotTarget, myPos) then
				self:FireMissileAt(shotTarget)
			end
			-- An invalid target's shot is simply skipped (no
			-- missile spawned for it) -- the volley continues on to
			-- the remaining shots rather than stopping early, since
			-- unlike the old single-target volley, other targets'
			-- shots don't depend on this one still being valid.

			if shotIndex >= #shots then
				self:EnterCooldown()
				return
			end

			timer.Simple(self.VolleyFireDelay or 0.15, FireNext)
		end

		FireNext()
	end

	function ENT:EnterCooldown()
		if not IsValid(self) then return end

		self.State = "cooldown"
		self:SetNWString("InterceptorState", "cooldown")

		self.CurrentTarget = NULL
		self:SetNWEntity("CurrentTarget", NULL)
		self.CurrentTargets = {}
		self:SetAimTarget(NULL)

		self.CooldownEndTime = CurTime() + (self.CooldownDuration or 10)
	end

	---------------------------------------------------------
	-- Think: state machine tick. Scanning happens in both "idle"
	-- and "tracking", throttled by ScanInterval rather than running
	-- every think.
	---------------------------------------------------------

	function ENT:Think()
		local currentTime = CurTime()

		if self.Active and self.HasPower then
			if self.State == "cooldown" then
				if currentTime >= (self.CooldownEndTime or 0) then
					self.State = "idle"
					self:SetNWString("InterceptorState", "idle")
					self:ReloadMissiles()
				end
			elseif self.State == "idle" then
				if currentTime >= (self.NextScanTime or 0) then
					self.NextScanTime = currentTime + (self.ScanInterval or 0.25)

					local targets = self:FindTargets()
					if #targets > 0 then
						-- First target(s) of a new wave: don't fire
						-- immediately -- hold for
						-- TargetAcquisitionDelay so anything else
						-- that shows up in that window gets folded
						-- into the same volley/missile split,
						-- rather than triggering its own separate
						-- volley. The set of targets seen on this
						-- opening scan seeds TrackedSet, so the very
						-- next tracking-state scan has something to
						-- compare against for "is this new?".
						self.State = "tracking"
						self:SetNWString("InterceptorState", "tracking")
						self.TrackingEndTime = currentTime + (self.TargetAcquisitionDelay or 1)
						self.TrackedSet = self:BuildTargetSet(targets)
						self:SetAimTarget(targets[1])
					end
				end
			elseif self.State == "tracking" then
				if currentTime >= (self.NextScanTime or 0) then
					self.NextScanTime = currentTime + (self.ScanInterval or 0.25)

					-- Re-scan and compare against everything seen
					-- on previous scans of this same tracking
					-- window (TrackedSet, keyed by entity so a
					-- same-count swap -- one target lost, a
					-- different one gained -- still counts as
					-- "new"). Finding even one not-previously-seen
					-- target pushes TrackingEndTime back out by the
					-- full delay, so the window keeps extending for
					-- as long as new targets keep showing up,
					-- capped only by MaxTargetsPerVolley/the missile
					-- count actually available at launch.
					local targets = self:FindTargets()
					-- Start slewing the launcher onto the top-priority
					-- target during the acquisition window, so it is
					-- already pointing there when the volley opens.
					if #targets > 0 then
						self:SetAimTarget(targets[1])
					end

					local sawNewTarget = false

					for _, target in ipairs(targets) do
						if not self.TrackedSet[target] then
							sawNewTarget = true
							self.TrackedSet[target] = true
						end
					end

					if sawNewTarget then
						self.TrackingEndTime = currentTime + (self.TargetAcquisitionDelay or 1)
					end
				end

				if currentTime >= (self.TrackingEndTime or 0) then
					local targets = self:FindTargets()
					if #targets > 0 then
						self:StartVolley(targets)
					else
						-- Whatever was spotted is gone (killed, out
						-- of range/LOS, declared friendly) by the
						-- time the delay expired -- nothing to fire
						-- at, so go back to idle and resume normal
						-- scanning instead of launching blind.
						self.State = "idle"
						self:SetNWString("InterceptorState", "idle")
						self:SetAimTarget(NULL)
					end
					self.TrackedSet = nil
				end
			end
			-- "firing" state runs its own timer chain (FireNext)
			-- and needs no per-think handling here.
		end

		self:NextThink(currentTime + 0.1)
		return true
	end

	function ENT:OnRemove()
		self.BaseClass.OnRemove(self)

		self:UnlinkMainframe()
	end
end

if CLIENT then
	function ENT:Initialize()
		self.Attachments = self.Attachments or {}
	end

	-- Animates the launcher rig, purely visually, from networked state:
	-- the server only says who to aim at ("AimTarget") and how many
	-- missiles are left ("MissilesLeft"). Angles are replaced with new
	-- Angle objects rather than edited in place so nothing can leak
	-- between entities that share the class table.
	function ENT:Think()
		local attachments = self.Attachments
		if not attachments then return end

		local yawAttach = attachments[self.YawAttachmentID]
		local pitchAttach = attachments[self.PitchAttachmentID]
		if not yawAttach or not pitchAttach then return end

		local dt = FrameTime()

		-- No target: hold the current heading and settle to the rest elevation.
		local targetYaw = yawAttach.Angle.y
		local targetPitch = (self.LauncherIdleElevation or 0) * (self.LauncherPitchSign or 1)

		local target = self:GetNWEntity("AimTarget", NULL)
		if IsValid(target) then
			targetYaw, targetPitch = self:GetLauncherAim(self:GetTrackPos(target))
		end

		local yaw = math.ApproachAngle(yawAttach.Angle.y, targetYaw, (self.LauncherYawSpeed or 180) * dt)
		local pitch = math.ApproachAngle(pitchAttach.Angle.p, targetPitch, (self.LauncherPitchSpeed or 90) * dt)

		yawAttach.Angle = Angle(0, math.NormalizeAngle(yaw), 0)
		pitchAttach.Angle = Angle(pitch, 0, 0)

		-- Missiles vanish in launch order (right to left); everything
		-- comes back together when the server reloads.
		local loaded = self.MissilesLoaded or 4
		local fired = loaded - self:GetNWInt("MissilesLeft", loaded)

		for order, id in ipairs(self.MissileAttachmentIDs) do
			local attach = attachments[id]
			if attach then
				attach.Hidden = order <= fired
			end
		end
	end

	---------------------------------------------------------
	-- Configure menu (allegiance), mirroring the sentry turret's
	-- panel. The interceptor has no player-facing on/off toggle
	-- (that's purely a HasPower/mainframe matter here), so this
	-- is just the allegiance status + button, plus the
	-- "clear allies" button (available to everyone).
	---------------------------------------------------------

	net.Receive("ery_interceptor_open", function()
		local interceptor = net.ReadEntity()

		if not IsValid(interceptor) then return end

		local isFriendly = net.ReadBool()

		local rowHeight = 30
		local rowY = 64

		local frame = vgui.Create("DFrame")

		frame:SetTitle(interceptor.PrintName or "Interceptor")
		frame:SetSize(280, 96 + rowHeight * 2)
		frame:Center()
		frame:MakePopup()

		local statusLabel = vgui.Create("DLabel", frame)
		statusLabel:SetPos(8, 32)
		statusLabel:SetSize(frame:GetWide() - 16, 20)
		statusLabel:SetText(
			"This interceptor is currently "
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
			net.Start("ery_interceptor_set_allegiance")
				net.WriteEntity(interceptor)
				net.WriteBool(not isFriendly)
			net.SendToServer()

			frame:Close()
		end
		rowY = rowY + rowHeight

		-- Wipes the interceptor's whole allegiance list, so every
		-- player who previously declared friendly (and everyone
		-- else) goes back to being targetable.
		local clearAlliesButton = vgui.Create("DButton", frame)
		clearAlliesButton:SetPos(8, rowY)
		clearAlliesButton:SetSize(frame:GetWide() - 16, rowHeight - 4)
		clearAlliesButton:SetText("Clear ally list (make everyone hostile)")

		clearAlliesButton.DoClick = function()
			net.Start("ery_interceptor_clear_allies")
				net.WriteEntity(interceptor)
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

		local deadRadius = self.MinTargetDistance or 750

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

	function ENT:DrawInterceptorStatus()
		local active = self:GetNW2Bool("Active", true)
		local hasPower = self:GetNWBool("HasPower", false)
		local state = self:GetNWString("InterceptorState", "idle")

		local statusY = 180

		draw.SimpleText(
			active and "Status: ON" or "Status: OFF",
			"EryMatWorld",
			0,
			statusY,
			active
				and Color(100, 255, 100)
				or Color(255, 100, 100),
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_TOP
		)

		draw.SimpleText(
			"Power: " .. (hasPower and "Connected" or "No Power"),
			"EryMatWorld",
			0,
			statusY + 30,
			hasPower
				and Color(100, 255, 100)
				or Color(255, 100, 100),
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_TOP
		)

		local stateText, stateColor

		if not active then
			stateText = "MODE: STANDBY"
			stateColor = Color(255, 100, 100)
		elseif not hasPower then
			stateText = "MODE: OFFLINE"
			stateColor = Color(255, 100, 100)
		elseif state == "firing" then
			stateText = "MODE: FIRING"
			stateColor = Color(255, 180, 60)
		elseif state == "tracking" then
			stateText = "MODE: TRACKING"
			stateColor = Color(255, 240, 120)
		elseif state == "cooldown" then
			stateText = "MODE: COOLDOWN"
			stateColor = Color(255, 220, 100)
		else
			stateText = "MODE: SCANNING"
			stateColor = Color(100, 255, 100)
		end

		draw.SimpleText(
			stateText,
			"EryMatWorld",
			0,
			statusY + 60,
			stateColor,
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_TOP
		)
	end

	function ENT:DrawLabel()
		local wasDrawn = self.BaseClass.DrawLabel(self)
		if not wasDrawn then return end

		local ply = LocalPlayer()
		local pos = self:LocalToWorld(self.IconOffset or Vector(0, 0, 40))
		local ang = ply:EyeAngles()
		ang:RotateAroundAxis(ang:Right(), 90)
		ang:RotateAroundAxis(ang:Up(), -90)

		cam.Start3D2D(pos, ang, 0.1)
			self:DrawInterceptorStatus()
		cam.End3D2D()

		return wasDrawn
	end

	function ENT:Draw()
		self:DrawModel()

		local attachDist = (self.AttachmentDrawDistance or 500)^2
		if self:GetPos():DistToSqr(LocalPlayer():GetPos()) <= attachDist then
			ERY_MACHINE:DrawAttachments(self, self.Attachments)
		end

		self:DrawLabel()

		if self:IsLookingAtForDome() then
			self:DrawDetectionDome()
		end
	end

	function ENT:OnRemove()
		ERY_MACHINE:CleanupAttachments(self)
	end
end
AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "sci_pointshop_entity_base_ui"

ENT.PrintName = "Auto-Repair Station"
ENT.Category = "Pointshop Entities"
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.IconPath = "entities/sci_pointshop_base_repair.png"
ENT.IconOffset = Vector(0, 30, 60)

-- Physical model
ENT.BaseModel = "models/hunter/blocks/cube1x1x1.mdl"
ENT.BaseMaterial = "models/effects/intro_tearshape"
ENT.BaseColor = Color(255, 255, 255, 255)

ENT.AttachmentDrawDistance = 7500

ENT.MaxHealth = 200
ENT.HealthRegen = 5
ENT.CustomMass = 75
ENT.Decaytime = -1

ENT.Attachments = {

    {
        ID = 1,
        Model = "models/props_lab/powerbox01a.mdl",
        Pos = Vector(0, 0, 0),
        Angle = Angle(0, 0, 0),
        Color = Color(216, 165, 39),
        Material = "metal5",
        Scale = 1,
        AxisScale = Vector(1.5, 1.25, 0.9),
        Parent = 0
    },

    {
        ID = 2,
        Model = "models/props_silo/processor.mdl",
        Pos = Vector(0, 0, 20),
        Angle = Angle(0, 0, 0),
        Color = Color(70, 70, 70),
        Material = "metal5",
        Scale = 1,
        AxisScale = Vector(0.5, 0.5, 0.5),
        Parent = 0
    },

    {
        ID = 3,
        Model = "models/Items/car_battery01.mdl",
        Pos = Vector(0, 0, -20),
        Angle = Angle(0, 0, 0),
        Color = Color(70, 70, 70),
        Material = "metal5",
        Scale = 1,
        AxisScale = Vector(4.5, 3, 0.5),
        Parent = 0
    },

    {
        ID = 4,
        Model = "models/props_phx/construct/glass/glass_curve360x2.mdl",
        Pos = Vector(0, 0, 35.5),
        Angle = Angle(0, 0, 0),
        Color = Color(216, 165, 39),
        Material = "metal5",
        Scale = 1,
        AxisScale = Vector(0.265, 0.265, 0.275),
        Parent = 0
    },

    {
        ID = 5,
        Model = "models/props_c17/tools_wrench01a.mdl",
        Pos = Vector(13.5, 1, 40.75),
        Angle = Angle(-90, -135, -180),
        Color = Color(200, 200, 200),
        Material = "metal5",
        Scale = 1,
        AxisScale = Vector(0.9, 0.9, 0.9),
        Parent = 0
    },

    {
        ID = 6,
        Model = "models/gantry_crane/crane_controlbox.mdl",
        Pos = Vector(17, 0, -12),
        Angle = Angle(0, -90, 0),
        Color = Color(150, 150, 150),
        Material = "",
        Scale = 1,
        AxisScale = Vector(0.4, 0.5, 0.75),
        Parent = 0
    },
}

ENT.CollideSounds = {
	"physics/metal/metal_box_impact_bullet1.wav",
	"physics/metal/metal_box_impact_bullet2.wav",
	"physics/metal/metal_box_impact_bullet3.wav",
}

---------------------------------------------------------
-- Repair settings
---------------------------------------------------------

-- How often the station pulses a repair over its radius.
ENT.RepairInterval = 10

-- How far the repair pulse reaches.
ENT.RepairRadius = 1500

-- Flat HP restored per pulse, on top of the percentage below.
ENT.RepairFlatAmount = 300

-- Fraction of a prop's OWN max health restored per pulse,
-- added to RepairFlatAmount. E.g. a prop with 1000 max HP
-- gets 0.03 * 1000 + 300 = 330 HP back per pulse.
ENT.RepairPercentOfMax = 0.05

-- Color of the reach sphere drawn while looking at the station.
-- Bright, fairly opaque green so the repair radius actually
-- reads at a glance instead of blending into the world.
ENT.RepairSphereColor = Color(40, 255, 40, 20)
ENT.RepairSphereColorWire = Color(40, 255, 40, 255)

-- How far away (in units) the player can be and still have the
-- reach sphere drawn while looking at the station. Kept separate
-- from the base's own LabelDrawDistance (which gates the
-- name/healthbar/status text) since the sphere should stay
-- visible from much further out than that text would be legible.
ENT.SphereDrawDistance = 6000

---------------------------------------------------------
-- Power: this entity is a consumer, drawing from whatever
-- mainframe it's wired to. It only actually pulses when BOTH
-- the player has switched it on (the Powered toggle) AND the
-- mainframe is supplying it enough power AND the repair timer
-- has elapsed -- exactly like the radar screen only sweeping
-- while powered.
---------------------------------------------------------

ENT.PowerRole = "consumer"
ENT.PowerRequired = 200

if SERVER then

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
		-- power). The station only pulses when both are true.
		self:SetNWBool("Powered", true)

		-- Whether a linked mainframe is currently supplying this
		-- entity's power requirement. Set by SetPowered(), called
		-- by the mainframe each power tick.
		self.HasPower = false
		self:SetNWBool("HasPower", false)

		self.Attachments = self.Attachments or {}

		-- Countdown to the next repair pulse. Starts at the full
		-- interval so a freshly placed station doesn't pulse
		-- instantly on the tick it gets power.
		self.RepairCountdown = self.RepairInterval or 10

		-- Picking this entity up doesn't make sense while it's
		-- servicing an area, so the base's default "Pick up"
		-- button is swapped out for an on/off toggle instead.
		-- "Wire to mainframe" (added by the base) stays as-is.
		self:RemoveMenuButton("pickup")
		self:RefreshToggleButton()

		self:NextThink(CurTime())
	end

	---------------------------------------------------------
	-- Re-adds the "Turn On / Off" menu button with a label that
	-- reflects the station's CURRENT Powered state (AddMenuButton
	-- only takes a static string, so the label is refreshed by
	-- re-adding the button any time Powered changes, rather than
	-- computed live when the menu opens).
	---------------------------------------------------------

	function ENT:RefreshToggleButton()
		local isPowered = self:GetNWBool("Powered", true)

		self:RemoveMenuButton("toggle_power")
		self:AddMenuButton(
			"toggle_power",
			isPowered and "Turn OFF" or "Turn ON",
			function(ent, activator)
				ent:SetNWBool("Powered", not ent:GetNWBool("Powered", true))
				ent:RefreshToggleButton()
			end
		)
	end

	---------------------------------------------------------
	-- Power interface, called by a linked mainframe.
	---------------------------------------------------------

	-- A station that's been manually switched off shouldn't hold
	-- onto any power at all, so it reports zero draw while off
	-- instead of always requesting the full PowerRequired --
	-- otherwise a switched-off station still occupies power a
	-- mainframe could give to something else. Mirrors the radar
	-- screen's GetPowerRequired() exactly.
	function ENT:GetPowerRequired()
		if not self:GetNWBool("Powered", true) then return 0 end
		return self.PowerRequired or 75
	end

	-- Called by the mainframe once per power tick with whether
	-- this entity is currently receiving enough power. Only
	-- reacts (sound feedback) on an actual state change.
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
	-- Overlap handling: every active station pulses on its own
	-- schedule, but each repaired target is stamped with the time
	-- it was last healed by ANY station (LastStationRepair), and
	-- DoRepairPulse skips targets healed within the cooldown window.
	-- That way, props sitting in the overlap of several stations
	-- only get one repair per interval, while props covered by just
	-- one station in a chain or partial overlap still get repaired.
	---------------------------------------------------------

	-- Base classes whose entities get the smaller pointshop-base
	-- repair formula instead of the prop_physics one.
	ENT.PointshopBaseClasses = {
		["sci_pointshop_entity_base_ui"] = true,
		["sci_pointshop_entity_base_noui"] = true,
	}

	-- Flat HP restored per pulse to pointshop base entities, on
	-- top of the percentage below.
	ENT.BaseEntityRepairFlatAmount = 50

	-- Fraction of a pointshop base entity's own max health
	-- restored per pulse, added to BaseEntityRepairFlatAmount.
	ENT.BaseEntityRepairPercentOfMax = 0.03

	-- Walks an entity's class up its Base chain to see whether it
	-- (or something it's based on) is one of the pointshop base
	-- classes above. Checking GetClass() alone would miss e.g. a
	-- station or screen entity, since those set ENT.Base to one of
	-- these but report their own class from GetClass().
	function ENT:IsPointshopBaseEntity(ent)
		local class = ent:GetClass()
		local seen = {}

		while class and not seen[class] do
			if self.PointshopBaseClasses[class] then return true end
			seen[class] = true

			local tbl = scripted_ents.GetStored(class)
			tbl = tbl and tbl.t
			class = tbl and tbl.Base
		end

		return false
	end

	---------------------------------------------------------
	-- Runs one repair pulse: finds every prop_physics, and every
	-- entity based on sci_pointshop_entity_base_ui or
	-- sci_pointshop_entity_base_noui, within RepairRadius and, for
	-- any that are damaged, restores health.
	--
	-- prop_physics has no native health of its own, so those use
	-- the same spdGetHealth/spdAddHealth API the repair torch
	-- uses, restoring RepairPercentOfMax * theirMaxHealth +
	-- RepairFlatAmount.
	--
	-- Pointshop base entities (UI and no-UI variants) track health
	-- natively via :Health()/:SetHealth()/:GetMaxHealth(), kept in
	-- sync with the EryHealth/EryMaxHealth NWInts that their own
	-- label/healthbar code reads -- so those are healed and
	-- restamped the same way the base's own HealthRegen timer
	-- does, rather than going through the spd API. These use the
	-- separate BaseEntityRepairPercentOfMax/BaseEntityRepairFlatAmount
	-- formula (3% of max HP + 50 HP by default).
	--
	-- Either way, healing is clamped so it never exceeds the
	-- target's own max health.
	---------------------------------------------------------

	function ENT:DoRepairPulse()

		local pulsePos = self:GetPos()
		local radius = self.RepairRadius or 5000
		local radiusSqr = radius * radius

		local healedAny = false

		-- A target healed by any station within this window is skipped,
		-- so overlapping stations don't double-repair. Slightly under
		-- the full interval so normal timing jitter never blocks a
		-- station's legitimate next pulse.
		local now = CurTime()
		local cooldown = (self.RepairInterval or 10) * 0.9

		for _, ent in ipairs(ents.FindInSphere(pulsePos, radius)) do

			if not IsValid(ent) or ent == self then continue end

			-- ents.FindInSphere already limits to the radius, but
			-- FindInSphere's sphere test operates on bounding
			-- boxes/origins depending on engine version -- keep an
			-- explicit distance check too so nothing right at the
			-- edge of a large prop/entity gets a false include.
			if pulsePos:DistToSqr(ent:GetPos()) > radiusSqr then
				continue
			end

			-- Already repaired by another (or this) station this interval.
			if ent.LastStationRepair and now - ent.LastStationRepair < cooldown then
				continue
			end

			local class = ent:GetClass()

			if class == "prop_physics" then

				local health = spdGetHealth and spdGetHealth(ent)
				if health == nil then continue end

				local maxHealth = (spdGetMaxHealth and spdGetMaxHealth(ent))
					or ent.SPDMaxHealth
					or health

				if health >= maxHealth then continue end

				local healAmount =
					(maxHealth * (self.RepairPercentOfMax or 0.03)) +
					(self.RepairFlatAmount or 300)

				local newHealth = math.min(health + healAmount, maxHealth)

				spdAddHealth(ent, newHealth - health)
				ent.LastStationRepair = now

				healedAny = true

			elseif self:IsPointshopBaseEntity(ent) then

				local health = ent:Health()
				local maxHealth = ent:GetMaxHealth()

				if maxHealth <= 0 or health >= maxHealth then continue end

				local healAmount =
					(maxHealth * (self.BaseEntityRepairPercentOfMax or 0.03)) +
					(self.BaseEntityRepairFlatAmount or 50)

				local newHealth = math.Round(math.min(health + healAmount, maxHealth))
				if newHealth == health then continue end

				ent:SetHealth(newHealth)
				ent:SetNWInt("EryHealth", newHealth)
				ent.LastStationRepair = now

				healedAny = true

			end
		end

		if healedAny then
			self:EmitSound("ambient/machines/pneumatic_drill_"..math.random(1,4)..".wav", 75, 100)
		end
	end

	---------------------------------------------------------
	-- Server think -- only counts down and pulses while
	-- switched on AND powered, mirroring the radar screen's
	-- gated Think().
	---------------------------------------------------------

	function ENT:Think()

		if not self:GetNWBool("Powered", true) or not self.HasPower then
			-- Keep the timestamp fresh while off/unpowered so the first
			-- tick after coming back doesn't see the entire downtime as
			-- one giant delta and fire a burst of catch-up pulses.
			self.LastThinkTime = CurTime()
			self:NextThink(CurTime())
			return true
		end

		local currentTime = CurTime()

		local delta = currentTime - (self.LastThinkTime or currentTime)
		self.LastThinkTime = currentTime

		self.RepairCountdown = (self.RepairCountdown or self.RepairInterval or 10) - delta

		if self.RepairCountdown <= 0 then
			self:DoRepairPulse()
			-- Clamped so a long frame hitch can never leave the
			-- countdown negative and trigger back-to-back pulses.
			self.RepairCountdown = math.max(self.RepairCountdown + (self.RepairInterval or 10), 0)
		end

		self:NextThink(CurTime())

		return true
	end

	-- The base's OnRemove (decay/regen timer cleanup) also needs
	-- to run here, plus unlinking from any mainframe this station
	-- was wired to -- same pattern as the radar screen.
	function ENT:OnRemove()
		if self.BaseClass and self.BaseClass.OnRemove then
			self.BaseClass.OnRemove(self)
		end

		self:UnlinkMainframe()
	end

end

if CLIENT then

	function ENT:Initialize()
		self.Attachments = self.Attachments or {}
	end

	---------------------------------------------------------
	-- Draws the repair station's on/off + power status text,
	-- shown right under the base's icon/name/healthbar. Kept
	-- separate from ENT:Draw() and only invoked from DrawLabel()
	-- below, so it only appears when the base's own label is
	-- also showing (same eye-trace/distance gate), without
	-- duplicating that gating logic here.
	---------------------------------------------------------

	function ENT:DrawStationStatus()
		local powered = self:GetNWBool("Powered", true)
		local hasPower = self:GetNWBool("HasPower", false)

		-- Positioned below the base's healthbar (icon 0..~64,
		-- name at 80, healthbar at 130-144, text at ~148).
		local statusY = 180

		draw.SimpleText(
			powered and "Status: ON" or "Status: OFF",
			"EryMatWorld",
			0,
			statusY,
			powered
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
			statusY + 30,
			hasPower
				and Color(100, 255, 100)
				or Color(255, 100, 100),
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_TOP
		)
	end

	-- Overrides the base's DrawLabel() only to append the
	-- station-specific status text after the shared icon, name,
	-- and healthbar are drawn. Relies on the base's return value
	-- to know whether the label is actually visible right now,
	-- rather than re-checking eye trace/distance here.
	function ENT:DrawLabel()
		local wasDrawn = self.BaseClass.DrawLabel(self)
		if not wasDrawn then return end

		local ply = LocalPlayer()
		local pos = self:LocalToWorld(self.IconOffset or Vector(0, 0, 20))
		local ang = ply:EyeAngles()
		ang:RotateAroundAxis(ang:Right(), 90)
		ang:RotateAroundAxis(ang:Up(), -90)

		cam.Start3D2D(pos, ang, 0.1)
			self:DrawStationStatus()
		cam.End3D2D()

		return wasDrawn
	end

	function ENT:DrawReachSphere()
		local color = self.RepairSphereColor or Color(40, 255, 90, 90)

		render.SetColorMaterial()
		render.DrawSphere(
			self:GetPos(),
			self.RepairRadius or 5000,
			24,
			24,
			color,
			false
		)

		local color2 = self.RepairSphereColorWire or Color(40, 255, 90, 90)

		render.SetColorMaterial()
		render.DrawWireframeSphere(
			self:GetPos(),
			self.RepairRadius or 5000,
			24,
			24,
			color2,
			false
		)

	end

	---------------------------------------------------------
	-- Whether the local player is currently looking at this
	-- station, for sphere-visibility purposes only. Deliberately
	-- separate from the base's own DrawLabel() eye-trace check --
	-- that one is implicitly capped by LabelDrawDistance (short,
	-- so name/healthbar/status text stays legible), while the
	-- reach sphere should stay visible from much further out
	-- (SphereDrawDistance), since a wireframe sphere reads fine
	-- at range even when the text wouldn't.
	---------------------------------------------------------

	function ENT:IsLookingAtForSphere()
		local ply = LocalPlayer()
		if not IsValid(ply) then return false end

		local maxDist = self.SphereDrawDistance or 3000
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

		-- DrawLabel() handles the name/healthbar/status text using
		-- the base's own (shorter-range) eye-trace/distance check.
		self:DrawLabel()

		-- The reach sphere uses its own longer-range check so it
		-- stays visible while looking at the station from further
		-- away than the label text would still be readable.
		if self:IsLookingAtForSphere() then
			self:DrawReachSphere()
		end
	end

	function ENT:OnRemove()
		ERY_MACHINE:CleanupAttachments(self)
	end

end
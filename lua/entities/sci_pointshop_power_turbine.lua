AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "sci_pointshop_entity_base_ui"

ENT.PrintName = "Wind Turbine"
ENT.Author = "Paloma"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "Pointshop Entities"

ENT.IconPath = "entities/sci_pointshop_power_turbine.png"
ENT.IconOffset = Vector(92, 0, -250)

-- Temporary placeholder model until a proper turbine model exists.
ENT.BaseModel = "models/props_wasteland/medbridge_strut01.mdl"
ENT.BaseMaterial = "models/effects/intro_tearshape"
ENT.BaseColor = Color(255, 255, 255, 255)
ENT.BoneScale = Vector(1, 1, 1)

ENT.AttachmentDrawDistance = 16000
ENT.LabelDrawDistance = 300
ENT.Decaytime = -1

ENT.MaxHealth = 2000
ENT.HealthRegen = 5

ENT.SpawnOffset = Vector(0, 0, 300) -- world-space offset applied 0.1s after spawning

-- How much power this turbine outputs while unobstructed.
ENT.PowerOutput = 200

-- Tells a mainframe which list to add this entity to when
-- linked via the plug.
ENT.PowerRole = "generator"

ENT.CustomMass = 1000

-- Local-space offset for where a mainframe's permanent cable
-- beam should originate from on this turbine, rather than the
-- entity's raw origin (see sci_pointshop_base_mainframe.lua's
-- DrawTranslucent, which converts this to world space via
-- LocalToWorld each frame).
ENT.CableOffset = Vector(0, -90, -280)

-- How far in front of the turbine must be clear for it to
-- generate power.
ENT.ObstructionCheckDistance = 500

-- How often (seconds) the obstruction trace re-runs. Doesn't
-- need to be every tick -- obstacles blocking a stationary
-- turbine don't appear/disappear fast enough to need that, and
-- tracing every think would be wasteful.
ENT.ObstructionCheckInterval = 5

-- How many degrees the turbine's up vector may tilt away from
-- world-up (straight up) before it's considered knocked over
-- and stops generating, even if the path ahead is clear. Some
-- leniency is allowed since a turbine resting on slightly
-- uneven ground shouldn't count as tipped over.
ENT.MaxTiltAngle = 15

ENT.CollideSounds = {
    "physics/wood/wood_crate_impact_hard1.wav",
    "physics/wood/wood_crate_impact_hard2.wav",
    "physics/wood/wood_crate_impact_hard3.wav",
    "physics/wood/wood_crate_impact_hard4.wav",
    "physics/wood/wood_crate_impact_hard5.wav",
}

ENT.Attachments = {
    {
		ID = 1,
        Model = "models/props/cs_militia/crate_extralargemill.mdl",
        Pos = Vector(16, 0, -320),
        Angle = Angle(0, 0, 0),
        Color = Color(255, 255, 255),
        Material = "",
        Scale = 1,
		AxisScale = Vector(1.2, 1.2, 0.5),
		Parent = 0
    },

    {
		ID = 2,
        Model = "models/props_citizen_tech/windmill_blade004b.mdl",
        Pos = Vector(57, -5, -220),
        Angle = Angle(87.5, 90, 0),
        Color = Color(255, 255, 255),
        Material = "",
        Scale = 1,
		AxisScale = Vector(1.9, 1.5, 1),
		Parent = 0
    },

    {
		ID = 3,
        Model = "models/props_citizen_tech/windmill_blade004b.mdl",
        Pos = Vector(-25, 5, -220),
        Angle = Angle(-87.5, -90, 0),
        Color = Color(255, 255, 255),
        Material = "",
        Scale = 1,
		AxisScale = Vector(1.9, 1.5, 1),
		Parent = 0
    },

    {
		ID = 4,
        Model = "models/props_citizen_tech/windmill_blade004b.mdl",
        Pos = Vector(5, 45, -220),
        Angle = Angle(180, 180, 87.5),
        Color = Color(255, 255, 255),
        Material = "",
        Scale = 1,
		AxisScale = Vector(1.9, 1.5, 1),
		Parent = 0
    },

    {
		ID = 5,
        Model = "models/props_citizen_tech/windmill_blade004b.mdl",
        Pos = Vector(5, -45, -220),
        Angle = Angle(0, 180, 87.5),
        Color = Color(255, 255, 255),
        Material = "",
        Scale = 1,
		AxisScale = Vector(1.9, 1.5, 1),
		Parent = 0
    },

    {
		ID = 6,
        Model = "models/props_docks/dock01_pole01a_256.mdl",
        Pos = Vector(50, 32.5, -135),
        Angle = Angle(5, 0, -5),
        Color = Color(255, 255, 255),
        Material = "",
        Scale = 1,
		AxisScale = Vector(1, 1, 1.1),
		Parent = 0
    },

    {
		ID = 7,
        Model = "models/props_docks/dock01_pole01a_256.mdl",
        Pos = Vector(-18, 32.5, -135),
        Angle = Angle(-5, 0, -5),
        Color = Color(255, 255, 255),
        Material = "",
        Scale = 1,
		AxisScale = Vector(1, 1, 1.1),
		Parent = 0
    },

    {
		ID = 8,
        Model = "models/props_docks/dock01_pole01a_256.mdl",
        Pos = Vector(-18, -32.5, -135),
        Angle = Angle(-5, 0, 5),
        Color = Color(255, 255, 255),
        Material = "",
        Scale = 1,
		AxisScale = Vector(1, 1, 1.1),
		Parent = 0
    },

    {
		ID = 9,
        Model = "models/props_docks/dock01_pole01a_256.mdl",
        Pos = Vector(50, -32.5, -135),
        Angle = Angle(5, 0, 5),
        Color = Color(255, 255, 255),
        Material = "",
        Scale = 1,
		AxisScale = Vector(1, 1, 1.1),
		Parent = 0
    },

    {
		ID = 10,
        Model = "models/props_c17/substation_transformer01a.mdl",
        Pos = Vector(20, 0, -222.5),
        Angle = Angle(0, 0, 0),
        Color = Color(255, 255, 255),
        Material = "",
        Scale = 1,
		AxisScale = Vector(0.45, 0.45, 0.45),
		Parent = 0
    },

    {
		ID = 11,
        Model = "models/props_silo/signalbox_01.mdl",
        Pos = Vector(0, -74, -320),
        Angle = Angle(0, 90, 0),
        Color = Color(255, 255, 255),
        Material = "",
        Scale = 1,
		AxisScale = Vector(1, 1, 1),
		Parent = 0
    },

    {
		ID = 12,
        Model = "models/props_lab/powerbox01a.mdl",
        Pos = Vector(0, 74, -290),
        Angle = Angle(0, -90, 0),
        Color = Color(255, 255, 255),
        Material = "",
        Scale = 1,
		AxisScale = Vector(1.2, 1.2, 1.2),
		Parent = 0
    },

    {
		ID = 13,
        Model = "models/props/de_inferno/cart_wheel.mdl",
        Pos = Vector(-27, 0, 5),
        Angle = Angle(-90, 90, 0),
        Color = Color(255, 255, 255),
        Material = "",
        Scale = 1,
		AxisScale = Vector(2.25, 2.25, 2.25),
		Parent = 0
    },

    {
		ID = 14,
        Model = "models/props_c17/gaspipes006a.mdl",
        Pos = Vector(37, 0, -72.5),
        Angle = Angle(0, 180, 0),
        Color = Color(255, 255, 255),
        Material = "",
        Scale = 1,
		AxisScale = Vector(4.5, 4.5, 4.5),
		Parent = 0
    },

    {
		ID = 15,
        Model = "models/hunter/blocks/cube025x025x025.mdl",
        Pos = Vector(65, 0, 41),
        Angle = Angle(0, 0, 0),
        Color = Color(255, 255, 255),
        Material = "models/effects/intro_tearshape",
        Scale = 1,
		AxisScale = Vector(1, 1, 1),
		Parent = 0
    },

    {
		ID = 21,
        Model = "models/props_citizen_tech/windmill_blade004a.mdl",
        Pos = Vector(0, 0, 5),
        Angle = Angle(0, 0, 0),
        Color = Color(255, 255, 255),
        Material = "",
        Scale = 1,
		AxisScale = Vector(1.2, 1.2, 1.2),
		Parent = 15
    },

    {
		ID = 16,
        Model = "models/props_junk/wood_pallet001a.mdl",
        Pos = Vector(50, 0, -135),
        Angle = Angle(-85, 90, 0),
        Color = Color(255, 255, 255),
        Material = "",
        Scale = 1,
		AxisScale = Vector(0.9, 0.9, 0.8),
		Parent = 0
    },

    {
		ID = 17,
        Model = "models/props_junk/wood_pallet001a.mdl",
        Pos = Vector(-20, 0, -135),
        Angle = Angle(85, 90, 0),
        Color = Color(150, 150, 150),
        Material = "",
        Scale = 1,
		AxisScale = Vector(0.9, 0.9, 0.8),
		Parent = 0
    },

    {
		ID = 18,
        Model = "models/props_junk/wood_pallet001a.mdl",
        Pos = Vector(16, 35, -135),
        Angle = Angle(0, 0, 85),
        Color = Color(150, 150, 150),
        Material = "",
        Scale = 1,
		AxisScale = Vector(0.9, 0.9, 0.8),
		Parent = 0
    },

    {
		ID = 19,
        Model = "models/props_junk/wood_pallet001a.mdl",
        Pos = Vector(16, 35, -135),
        Angle = Angle(0, 0, 85),
        Color = Color(150, 150, 150),
        Material = "",
        Scale = 1,
		AxisScale = Vector(0.9, 0.9, 0.8),
		Parent = 0
    },

    {
		ID = 20,
        Model = "models/props_junk/wood_pallet001a.mdl",
        Pos = Vector(16, -35, -135),
        Angle = Angle(0, 0, -85),
        Color = Color(150, 150, 150),
        Material = "",
        Scale = 1,
		AxisScale = Vector(0.9, 0.9, 0.8),
		Parent = 0
    },
}

if SERVER then

	function ENT:Initialize()
		-- Model, material, physics, decay, health, and the
		-- interaction menu (including "Wire to mainframe") are
		-- all handled by the base.
		self.BaseClass.Initialize(self)

		self.Obstructed = true
		self.Tilted = false
		self.Online = false

		-- Manual on/off toggle, independent from whether the
		-- turbine is actually clear of obstructions. Both must be
		-- true for the turbine to be Online -- see
		-- UpdateOnlineState(). Same independent-gate pattern as
		-- the fuel generator's ManuallyEnabled/FuelSeconds.
		self.ManuallyEnabled = true

		self:SetNWBool("Obstructed", true)
		self:SetNWBool("Tilted", false)
		self:SetNWBool("Online", false)
		self:SetNWBool("ManuallyEnabled", true)

		self:AddMenuButton("toggle_power", "Turn off", function(ent, activator)
			ent:SetManuallyEnabled(not ent.ManuallyEnabled)
		end)

		self.NextObstructionCheck = CurTime()
	end

	-- Flips the manual on/off toggle and updates the menu button
	-- label to reflect the new state, then re-evaluates online
	-- state immediately (rather than waiting for the next
	-- obstruction check) so turning it off stops the running
	-- sound loop and zeroes GetPowerOutput() right away.
	function ENT:SetManuallyEnabled(enabled)
		self.ManuallyEnabled = enabled
		self:SetNWBool("ManuallyEnabled", enabled)

		self:AddMenuButton("toggle_power", enabled and "Turn off" or "Turn on", function(ent, activator)
			ent:SetManuallyEnabled(not ent.ManuallyEnabled)
		end)

		self:UpdateOnlineState()
	end

	-- Traces forward from the turbine out to
	-- ObstructionCheckDistance and reports whether anything is in
	-- the way. World geometry and other entities both count as
	-- obstructions; the turbine itself (and anything it's
	-- currently touching/carrying, e.g. a plug) is filtered out
	-- so it can't block its own trace.
	function ENT:CheckObstruction()
		local startPos = self:GetPos() + (self.ObstructionTraceOffset or Vector(0, 0, 20))
		local forward = self:GetForward()
		local endPos = startPos + forward * (self.ObstructionCheckDistance or 500)

		local tr = util.TraceLine({
			start = startPos,
			endpos = endPos,
			filter = self,
			mask = MASK_SOLID
		})

		return tr.Hit
	end

	-- Compares the turbine's up vector against world-up (straight
	-- up) and reports whether it's tilted past MaxTiltAngle. Uses
	-- the dot product of the two (normalized) vectors rather than
	-- comparing Euler angles directly, since dot-product-to-angle
	-- gives the true angular difference between the two directions
	-- regardless of which axis the turbine tipped over on, whereas
	-- pitch/roll would need to be combined carefully to avoid
	-- under- or over-counting a diagonal tilt.
	function ENT:CheckTilt()
		local cosTilt = self:GetUp():Dot(Vector(0, 0, 1))
		-- Clamp to avoid a NaN from float drift pushing the dot
		-- product slightly outside [-1, 1] before acos.
		cosTilt = math.Clamp(cosTilt, -1, 1)

		local tiltAngle = math.deg(math.acos(cosTilt))
		return tiltAngle > (self.MaxTiltAngle or 15)
	end

	-- Turns the turbine on/off based on whether it's currently
	-- unobstructed, upright, AND manually enabled -- all three
	-- gates must be true, same pattern the fuel generator uses for
	-- fuel vs. manual toggle. Starts/stops the running sound loop
	-- to match.
	function ENT:UpdateOnlineState()
		local shouldBeOnline = (not self.Obstructed) and (not self.Tilted) and self.ManuallyEnabled

		if shouldBeOnline == self.Online then return end

		self.Online = shouldBeOnline
		self:SetNWBool("Online", self.Online)

		if self.Online then
			self:EmitSound("ambient/machines/hydraulic_1.wav", 70, 100)
			self:StartLoopSound()
		else
			self:EmitSound("ambient/machines/sputter1.wav", 70, 95)
			self:StopLoopSound()
		end
	end

	-- turbine_lp.wav is a true looping sound (loop points baked
	-- into the wav itself), so it only needs to be started once
	-- via a CSoundPatch rather than re-fired with EmitSound every
	-- few seconds -- EmitSound is for one-shot/repeated sounds,
	-- not seamless loops, and re-triggering it periodically causes
	-- an audible restart each time instead of a continuous hum.
	function ENT:StartLoopSound()
		self:StopLoopSound()

		self.LoopSound = CreateSound(self, "ambient/machines/machine2.wav")
		self.LoopSound:PlayEx(0.55, 100)
	end

	-- A CSoundPatch doesn't stop itself -- it has to be told to,
	-- both when turning off and (critically) when the entity is
	-- removed, or the loop keeps playing from empty space forever.
	function ENT:StopLoopSound()
		if self.LoopSound then
			self.LoopSound:Stop()
			self.LoopSound = nil
		end
	end

	-- Called by a mainframe this turbine is linked to, to find
	-- out how much power it's currently contributing. Returns 0
	-- if obstructed, tipped over, or manually disabled.
	function ENT:GetPowerOutput()
		if not self.Online then return 0 end
		return self.PowerOutput or 0
	end

	function ENT:Think()
		local currentTime = CurTime()

		if currentTime >= (self.NextObstructionCheck or 0) then
			self.NextObstructionCheck = currentTime + (self.ObstructionCheckInterval or 0.5)

			local obstructed = self:CheckObstruction()
			local tilted = self:CheckTilt()

			local stateChanged = false

			if obstructed ~= self.Obstructed then
				self.Obstructed = obstructed
				self:SetNWBool("Obstructed", obstructed)
				stateChanged = true
			end

			if tilted ~= self.Tilted then
				self.Tilted = tilted
				self:SetNWBool("Tilted", tilted)
				stateChanged = true
			end

			if stateChanged then
				self:UpdateOnlineState()
			end
		end

		self:NextThink(currentTime + 0.1)
		return true
	end

	function ENT:OnRemove()
		self.BaseClass.OnRemove(self)

		self:UnlinkMainframe()

		self:StopLoopSound()
	end
end

if CLIENT then

	-- Draws the turbine's obstruction/online status underneath
	-- the shared icon/name/healthbar from the base. Calls into
	-- the base's DrawLabel() rather than re-implementing it, only
	-- adding a second small 3D2D block for the extra status, same
	-- pattern used by the fuel generator.
	function ENT:DrawLabel()
		local wasDrawn = self.BaseClass.DrawLabel(self)
		if not wasDrawn then return end

		local ply = LocalPlayer()
		local pos = self:LocalToWorld(self.IconOffset or Vector(0, 0, 40))
		local ang = ply:EyeAngles()
		ang:RotateAroundAxis(ang:Right(), 90)
		ang:RotateAroundAxis(ang:Up(), -90)

		cam.Start3D2D(pos, ang, 0.1)
			self:DrawTurbineStatus()
		cam.End3D2D()
	end

	function ENT:DrawTurbineStatus()
		local online = self:GetNWBool("Online", false)
		local manuallyEnabled = self:GetNWBool("ManuallyEnabled", true)

		local statusY = 178

		-- Three distinct states rather than a flat on/off: running,
		-- deliberately paused (clear and upright but switched off),
		-- or blocked entirely (obstructed and/or tipped over) -- so
		-- a player glancing at it knows which one applies without
		-- opening the menu. The specific cause (obstruction vs.
		-- tilt) isn't broken out here -- that's covered on the wiki.
		local statusText, statusColor
		if online then
			statusText, statusColor = "Status: Online", Color(100, 255, 100)
		elseif not manuallyEnabled then
			statusText, statusColor = "Status: Paused", Color(255, 200, 80)
		else
			statusText, statusColor = "Status: Offline", Color(255, 100, 100)
		end

		draw.SimpleText(
			statusText,
			"EryMatWorld",
			0,
			statusY,
			statusColor,
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_TOP
		)

		if online then
			draw.SimpleText(
				"Output: " .. (self.PowerOutput or 0) .. " power",
				"EryMatWorld",
				0,
				statusY + 30,
				Color(255, 220, 120),
				TEXT_ALIGN_CENTER,
				TEXT_ALIGN_TOP
			)
		end
	end

	-- Blade hub attachment (ID 15) only spins while the turbine is
	-- actually Online -- same networked bool that gates power
	-- output server-side, so no extra networking is needed here.
	-- Unlike the beacon (which gates on two separate bools,
	-- Active and HasPower), the turbine only has the one combined
	-- Online state to check.
	local SpinSpeed = 120 -- degrees per second

	function ENT:Think()
		-- self.Attachments is already a private per-instance copy
		-- by this point -- sci_pointshop_entity_base_ui's client
		-- Initialize() deep-copies ENT.Attachments into
		-- self.Attachments before any entity thinks or draws, so
		-- mutating Angle below is safe and only affects this
		-- turbine.
		local attach = self.Attachments and self.Attachments[15]
		if not attach then return end

		local spinning = self:GetNWBool("Online", false)

		if spinning then
			attach.Angle.r = (attach.Angle.r + FrameTime() * SpinSpeed) % 360
		elseif attach.Angle.r ~= 0 then
			-- Not spinning: ease back to resting angle instead of
			-- snapping, so the blades powering off mid-spin
			-- doesn't look abrupt.
			local remaining = 360 - attach.Angle.r
			local step = FrameTime() * SpinSpeed

			if step >= remaining then
				attach.Angle.r = 0
			else
				attach.Angle.r = attach.Angle.r + step
				if attach.Angle.r >= 360 then
					attach.Angle.r = 0
				end
			end
		end
	end
end

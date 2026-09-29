AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "sci_pointshop_entity_base_ui"

ENT.PrintName = "Fuel Generator"
ENT.Author = "Paloma"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "Pointshop Entities"

ENT.IconPath = "entities/sci_pointshop_fuelgenerator.png"
ENT.IconOffset = Vector(0, 0, 104)

ENT.BaseModel = "models/props_mining/diesel_generator.mdl"
ENT.BaseMaterial = ""
ENT.BaseColor = Color(255, 255, 255, 255)
ENT.BoneScale = Vector(1, 1, 1)

ENT.AttachmentDrawDistance = 1000
ENT.LabelDrawDistance = 300
ENT.Decaytime = -1

ENT.MaxHealth = 750
ENT.HealthRegen = 2

-- How much power this generator outputs while it has fuel.
ENT.PowerOutput = 250

-- Tells a mainframe which list to add this entity to when
-- linked via the plug.
ENT.PowerRole = "generator"

ENT.CustomMass = 500

ENT.CableOffset = Vector(14, -7, 54)

ENT.CollideSounds = {
    "physics/metal/metal_sheet_impact_hard6.wav",
    "physics/metal/metal_sheet_impact_hard7.wav",
    "physics/metal/metal_sheet_impact_hard8.wav"
}

if SERVER then

	function ENT:Initialize()
		-- Model, material, physics, decay, health, and the
		-- interaction menu (including "Wire to mainframe") are
		-- all handled by the base.
		self.BaseClass.Initialize(self)

		self.FuelSeconds = 0
		self.Online = false

		-- Manual on/off toggle, independent from whether the
		-- generator actually has fuel. Both must be true for the
		-- generator to be Online -- see UpdateOnlineState(). This
		-- lets a player pause fuel consumption without having to
		-- unlink it from the mainframe or wait it out.
		self.ManuallyEnabled = true

		self:SetNWInt("FuelSeconds", 0)
		self:SetNWBool("Online", false)
		self:SetNWBool("ManuallyEnabled", true)

		self:AddMenuButton("toggle_power", "Turn off", function(ent, activator)
			ent:SetManuallyEnabled(not ent.ManuallyEnabled)
		end)

		self.NextFuelTick = CurTime() + 1
	end

	-- Flips the manual on/off toggle and updates the menu button
	-- label to reflect the new state, then re-evaluates online
	-- state immediately (rather than waiting for the next fuel
	-- tick) so turning it off stops the running sound loop and
	-- zeroes GetPowerOutput() right away.
	function ENT:SetManuallyEnabled(enabled)
		self.ManuallyEnabled = enabled
		self:SetNWBool("ManuallyEnabled", enabled)

		self:AddMenuButton("toggle_power", enabled and "Turn off" or "Turn on", function(ent, activator)
			ent:SetManuallyEnabled(not ent.ManuallyEnabled)
		end)

		self:UpdateOnlineState()
	end

	-- Called by sci_pointshop_fuel when a fuel can is touched
	-- against this generator. Always accepts (no cap on stacked
	-- fuel), returns true so the fuel can knows to consume
	-- itself.
	function ENT:AddFuel(seconds)
		seconds = seconds or 0
		if seconds <= 0 then return false end

		self.FuelSeconds = (self.FuelSeconds or 0) + seconds
		self:SetNWInt("FuelSeconds", math.Round(self.FuelSeconds))

		self:UpdateOnlineState()

		self:EmitSound("player/footsteps/wade"..math.random(1,8)..".wav", 70, 100)

		return true
	end

	-- Turns the generator on/off based on whether it currently
	-- has fuel AND is manually enabled -- both gates must be true,
	-- same independent-gate pattern used by the radar/beacon's
	-- power vs. manual toggle. Starts/stops the running sound
	-- loop to match.
	function ENT:UpdateOnlineState()
		local shouldBeOnline = (self.FuelSeconds or 0) > 0 and self.ManuallyEnabled

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

	-- machine2.wav is a true looping sound (loop points baked into
	-- the wav itself), so it only needs to be started once via a
	-- CSoundPatch rather than re-fired with EmitSound every few
	-- seconds -- EmitSound is for one-shot/repeated sounds, not
	-- seamless loops, and re-triggering it periodically causes an
	-- audible restart each time instead of a continuous hum.
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

	-- Called by a mainframe this generator is linked to, to find
	-- out how much power it's currently contributing. Returns 0
	-- if out of fuel.
	function ENT:GetPowerOutput()
		if not self.Online then return 0 end
		return self.PowerOutput or 0
	end

	function ENT:Think()
		local currentTime = CurTime()

		if currentTime >= (self.NextFuelTick or 0) then
			self.NextFuelTick = currentTime + 1

			-- Only burn fuel while actually online -- gating on
			-- FuelSeconds alone would keep consuming even while
			-- manually paused, which defeats the point of the
			-- toggle.
			if self.Online and (self.FuelSeconds or 0) > 0 then
				self.FuelSeconds = math.max(self.FuelSeconds - 1, 0)
				self:SetNWInt("FuelSeconds", math.Round(self.FuelSeconds))

				if self.FuelSeconds <= 0 then
					self:UpdateOnlineState()
				end
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

	-- Draws the generator's fuel/online status underneath the
	-- shared icon/name/healthbar from the base. Calls into the
	-- base's DrawLabel() rather than re-implementing it, only
	-- adding a second small 3D2D block for the extra status,
	-- same pattern used by the beacon.
	function ENT:DrawLabel()
		local wasDrawn = self.BaseClass.DrawLabel(self)
		if not wasDrawn then return end

		local ply = LocalPlayer()
		local pos = self:LocalToWorld(self.IconOffset or Vector(0, 0, 40))
		local ang = ply:EyeAngles()
		ang:RotateAroundAxis(ang:Right(), 90)
		ang:RotateAroundAxis(ang:Up(), -90)

		cam.Start3D2D(pos, ang, 0.1)
			self:DrawGeneratorStatus()
		cam.End3D2D()
	end

	function ENT:DrawGeneratorStatus()
		local fuelSeconds = self:GetNWInt("FuelSeconds", 0)
		local online = self:GetNWBool("Online", false)
		local manuallyEnabled = self:GetNWBool("ManuallyEnabled", true)

		local minutes = math.floor(fuelSeconds / 60)
		local seconds = fuelSeconds % 60

		local statusY = 178

		draw.SimpleText(
			"Fuel: " .. string.format("%d:%02d", minutes, seconds),
			"EryMatWorld",
			0,
			statusY,
			Color(200, 200, 255),
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_TOP
		)

		-- Three distinct states rather than a flat on/off: running,
		-- deliberately paused (has fuel but switched off), or out
		-- of fuel entirely -- so a player glancing at it knows
		-- which one applies without opening the menu.
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
			statusY + 30,
			statusColor,
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_TOP
		)

		if online then
			draw.SimpleText(
				"Output: " .. (self.PowerOutput or 0) .. " power",
				"EryMatWorld",
				0,
				statusY + 60,
				Color(255, 220, 120),
				TEXT_ALIGN_CENTER,
				TEXT_ALIGN_TOP
			)
		end
	end
end
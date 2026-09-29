AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "sci_pointshop_entity_base_ui"

ENT.PrintName = "Radioisotope Generator"
ENT.Author = "Paloma"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "Pointshop Entities"

ENT.IconPath = "entities/sci_pointshop_power_rtg.png"
ENT.IconOffset = Vector(0, 0, 60)

-- Temporary placeholder model until a proper RTG model exists.
ENT.BaseModel = "models/hunter/blocks/cube1x1x1.mdl"
ENT.BaseMaterial = "models/effects/intro_tearshape"
ENT.BaseColor = Color(255, 255, 255, 255)
ENT.BoneScale = Vector(1, 1, 1)

ENT.AttachmentDrawDistance = 5000
ENT.LabelDrawDistance = 300
ENT.Decaytime = -1

ENT.MaxHealth = 500
ENT.HealthRegen = 3

-- How much power this RTG outputs while switched on. Unlike the
-- turbine, there's no environmental gate to satisfy -- output
-- only depends on the manual toggle below.
ENT.PowerOutput = 125

-- Tells a mainframe which list to add this entity to when
-- linked via the plug.
ENT.PowerRole = "generator"

ENT.CustomMass = 200

-- Local-space offset for where a mainframe's permanent cable
-- beam should originate from on this entity (see
-- sci_pointshop_base_mainframe.lua's DrawTranslucent, which
-- converts this to world space via LocalToWorld each frame).
ENT.CableOffset = Vector(21, 0, -8.5)

ENT.CollideSounds = {
	"physics/metal/metal_sheet_impact_hard6.wav",
	"physics/metal/metal_sheet_impact_hard7.wav",
	"physics/metal/metal_sheet_impact_hard8.wav",
}

ENT.Attachments = {
    {
		ID = 1,
        Model = "models/props_combine/weaponstripper.mdl",
        Pos = Vector(32, 0, -20),
        Angle = Angle(90, 0, 0),
        Color = Color(160, 145, 140),
        Material = "phoenix_storms/mat/mat_phx_metallic2",
        Scale = 1,
		AxisScale = Vector(0.2, 0.5, 0.5),
		Parent = 0
    },

    {
		ID = 2,
        Model = "models/props_combine/weaponstripper.mdl",
        Pos = Vector(-32, 0, -22),
        Angle = Angle(-90, 0, 0),
        Color = Color(160, 145, 140),
        Material = "phoenix_storms/mat/mat_phx_metallic2",
        Scale = 1,
		AxisScale = Vector(0.2, 0.5, 0.5),
		Parent = 0
    },

    {
		ID = 3,
        Model = "models/props_vents/vent_small_corner002.mdl",
        Pos = Vector(27.5, 18.5, -21),
        Angle = Angle(-90, 0, 0),
        Color = Color(160, 145, 140),
        Material = "",
        Scale = 1,
		AxisScale = Vector(1.21, 4.5, 4.5),
		Parent = 0
    },

    {
		ID = 4,
        Model = "models/props_vents/vent_small_corner002.mdl",
        Pos = Vector(-27.5, 18.5, -21),
        Angle = Angle(90, 0, 0),
        Color = Color(160, 145, 140),
        Material = "",
        Scale = 1,
		AxisScale = Vector(1.21, 4.5, 4.5),
		Parent = 0
    },

    {
		ID = 5,
        Model = "models/props_vents/vent_small_corner002.mdl",
        Pos = Vector(-27.5, -18.5, -21),
        Angle = Angle(90, 180, 0),
        Color = Color(160, 145, 140),
        Material = "",
        Scale = 1,
		AxisScale = Vector(1.21, 4.5, 4.5),
		Parent = 0
    },

    {
		ID = 6,
        Model = "models/props_vents/vent_small_corner002.mdl",
        Pos = Vector(27.5, -18.5, -21),
        Angle = Angle(-90, 180, 0),
        Color = Color(160, 145, 140),
        Material = "",
        Scale = 1,
		AxisScale = Vector(1.21, 4.5, 4.5),
		Parent = 0
    },

    {
		ID = 7,
        Model = "models/props_lab/rotato.mdl",
        Pos = Vector(0, 0, 15),
        Angle = Angle(-14, 0, -90),
        Color = Color(255, 255, 255),
        Material = "",
        Scale = 1,
		AxisScale = Vector(3.5, 8.5, 3.5),
		Parent = 0
    },

    {
		ID = 8,
        Model = "models/props_c17/pottery_large01a.mdl",
        Pos = Vector(0, 0, -19),
        Angle = Angle(0, 0, 0),
        Color = Color(160, 145, 140),
        Material = "phoenix_storms/mat/mat_phx_metallic2",
        Scale = 1,
		AxisScale = Vector(1.1, 1.1, 0.475),
		Parent = 0
    },

    {
		ID = 9,
        Model = "models/hunter/plates/plate1x2.mdl",
        Pos = Vector(0, 0, 16),
        Angle = Angle(45, 0, 90),
        Color = Color(255, 255, 255),
        Material = "phoenix_storms/trains/track_beamtop",
        Scale = 1,
		AxisScale = Vector(0.775, 0.325, 0.1),
		Parent = 0
    },

    {
		ID = 10,
        Model = "models/hunter/plates/plate1x2.mdl",
        Pos = Vector(0, 0, 16),
        Angle = Angle(90, 0, 90),
        Color = Color(255, 255, 255),
        Material = "phoenix_storms/trains/track_beamtop",
        Scale = 1,
		AxisScale = Vector(0.775, 0.325, 0.1),
		Parent = 0
    },

    {
		ID = 11,
        Model = "models/hunter/plates/plate1x2.mdl",
        Pos = Vector(0, 0, 16),
        Angle = Angle(135, 0, 90),
        Color = Color(255, 255, 255),
        Material = "phoenix_storms/trains/track_beamtop",
        Scale = 1,
		AxisScale = Vector(0.775, 0.325, 0.1),
		Parent = 0
    },

    {
		ID = 12,
        Model = "models/props/de_nuke/nuclearcontrolbox.mdl",
        Pos = Vector(21, 0, -8.5),
        Angle = Angle(0, 0, 0),
        Color = Color(255, 255, 255),
        Material = "",
        Scale = 1,
		AxisScale = Vector(0.8, 0.8, 0.8),
		Parent = 0
    },

}

if SERVER then

	function ENT:Initialize()
		-- Model, material, physics, decay, health, and the
		-- interaction menu (including "Wire to mainframe") are
		-- all handled by the base.
		self.BaseClass.Initialize(self)

		-- No Obstructed/Tilted gates -- an RTG's decay heat doesn't
		-- care about line of sight or orientation, so Online only
		-- tracks the manual toggle. Kept as its own bool (rather
		-- than just reading ManuallyEnabled directly wherever
		-- Online is checked) so the client-side status/attachment
		-- code and GetPowerOutput() can stay identical in shape to
		-- the turbine's, in case a future gate is ever added here.
		self.Online = false

		-- Manual on/off toggle. Same independent-gate pattern as
		-- the turbine's ManuallyEnabled/Obstructed/Tilted trio,
		-- just with no other gates to AND against.
		self.ManuallyEnabled = true

		self:SetNWBool("Online", false)
		self:SetNWBool("ManuallyEnabled", true)

		self:AddMenuButton("toggle_power", "Turn off", function(ent, activator)
			ent:SetManuallyEnabled(not ent.ManuallyEnabled)
		end)

		self:UpdateOnlineState()
	end

	-- Flips the manual on/off toggle and updates the menu button
	-- label to reflect the new state, then re-evaluates online
	-- state immediately so turning it off stops the running sound
	-- loop and zeroes GetPowerOutput() right away.
	function ENT:SetManuallyEnabled(enabled)
		self.ManuallyEnabled = enabled
		self:SetNWBool("ManuallyEnabled", enabled)

		self:AddMenuButton("toggle_power", enabled and "Turn off" or "Turn on", function(ent, activator)
			ent:SetManuallyEnabled(not ent.ManuallyEnabled)
		end)

		self:UpdateOnlineState()
	end

	-- Turns the RTG on/off based solely on the manual toggle.
	-- Starts/stops the running sound loop to match.
	function ENT:UpdateOnlineState()
		local shouldBeOnline = self.ManuallyEnabled

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

	-- See sci_pointshop_power_turbine.lua's StartLoopSound: a true
	-- looping wav only needs to be started once via a CSoundPatch,
	-- not re-fired with EmitSound.
	function ENT:StartLoopSound()
		self:StopLoopSound()

		self.LoopSound = CreateSound(self, "ambient/machines/machine2.wav")
		self.LoopSound:PlayEx(0.4, 100)
	end

	function ENT:StopLoopSound()
		if self.LoopSound then
			self.LoopSound:Stop()
			self.LoopSound = nil
		end
	end

	-- Called by a mainframe this RTG is linked to, to find out how
	-- much power it's currently contributing. Returns 0 if
	-- manually disabled, otherwise its fixed output regardless of
	-- placement or orientation.
	function ENT:GetPowerOutput()
		if not self.Online then return 0 end
		return self.PowerOutput or 0
	end

	function ENT:OnRemove()
		self.BaseClass.OnRemove(self)

		self:UnlinkMainframe()

		self:StopLoopSound()
	end
end

if CLIENT then

	-- Draws the RTG's on/off status underneath the shared
	-- icon/name/healthbar from the base, same pattern as the
	-- turbine's DrawLabel.
	function ENT:DrawLabel()
		local wasDrawn = self.BaseClass.DrawLabel(self)
		if not wasDrawn then return end

		local ply = LocalPlayer()
		local pos = self:LocalToWorld(self.IconOffset or Vector(0, 0, 40))
		local ang = ply:EyeAngles()
		ang:RotateAroundAxis(ang:Right(), 90)
		ang:RotateAroundAxis(ang:Up(), -90)

		cam.Start3D2D(pos, ang, 0.1)
			self:DrawRTGStatus()
		cam.End3D2D()
	end

	function ENT:DrawRTGStatus()
		local online = self:GetNWBool("Online", false)

		local statusY = 178

		-- Only two states here -- no obstruction/tilt to report,
		-- so it's either running or deliberately switched off.
		local statusText, statusColor
		if online then
			statusText, statusColor = "Status: Online", Color(100, 255, 100)
		else
			statusText, statusColor = "Status: Paused", Color(255, 200, 80)
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
end

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "sci_pointshop_entity_base_ui"

ENT.PrintName = "Base Mainframe"
ENT.Author = "Paloma"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "Pointshop Entities"

ENT.IconPath = "entities/sci_pointshop_base_mainframe.png"
ENT.IconOffset = Vector(0, 0, 125)

ENT.BaseModel = "models/props_lab/servers.mdl"
ENT.BaseMaterial = ""
ENT.BaseColor = Color(255, 255, 255, 255)
ENT.BoneScale = Vector(1, 1, 1)

ENT.AttachmentDrawDistance = 1000
ENT.LabelDrawDistance = 300
ENT.Decaytime = -1

ENT.MaxHealth = 1000
ENT.HealthRegen = 2

ENT.CustomMass = 150

ENT.CollideSounds = {
    "physics/metal/metal_computer_impact_soft1.wav",
    "physics/metal/metal_computer_impact_soft2.wav",
    "physics/metal/metal_computer_impact_soft3.wav"
}

-- A mainframe doesn't generate or consume power itself -- it's
-- neither role, so it's simply never linked to another mainframe.
ENT.PowerRole = "mainframe"

-- Screen (like the radar's) is only rendered up close.
ENT.ScreenDrawDistance = 700
ENT.MainframeScreenOffset = Vector(18, 0, 55)
ENT.MainframeScreenScale = 0.175
ENT.MainframeScreenSize = { w = 320, h = 260 }

-- Permanent cable beams to every linked entity, drawn client-side
-- once a plug completes a link (see sci_pointshop_plug.lua's
-- Touch()). Networked via a fixed set of Entity NetworkVar slots
-- rather than a table, since NetworkVar slots must be declared
-- up front. 32 is comfortably above any realistic wiring count;
-- extra links beyond that simply don't get a drawn cable (the
-- power system itself has no such limit).
ENT.MaxCableSlots = 32
ENT.CableMaterial = "cable/cable2"
ENT.CableWidth = 1.5

-- The mainframe's model is opaque, but DrawTranslucent still
-- needs to fire every frame to draw the permanent cable beams.
-- RENDERGROUP_BOTH ensures it runs in addition to Draw(), same
-- reasoning as sci_pointshop_plug.lua.
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
	for i = 1, self.MaxCableSlots do
		self:NetworkVar("Entity", i - 1, "CableSlot" .. i)
	end
end

if SERVER then

	function ENT:Initialize()
		-- Model, material, physics, decay, health, and the
		-- interaction menu (including "Wire to mainframe", which
		-- doesn't apply to a mainframe itself) are handled by the
		-- base.
		self.BaseClass.Initialize(self)

		-- A mainframe can't wire itself to another mainframe.
		self:RemoveMenuButton("wire_to_mainframe")

		self.LinkedGenerators = {}
		self.LinkedConsumers = {}

		self.AvailablePower = 0
		self.UsedPower = 0

		self:SetNWInt("AvailablePower", 0)
		self:SetNWInt("UsedPower", 0)
		self:SetNWInt("GeneratorCount", 0)
		self:SetNWInt("ConsumerCount", 0)

		self.NextPowerTick = CurTime() + 1
	end

	-- Called by a sci_pointshop_plug's Touch() when it's tapped
	-- against this mainframe. Adds ent to the generator or
	-- consumer list based on its PowerRole (defaults to consumer
	-- if unset, so any powered entity works even if it forgot to
	-- declare a role). Safe to call again to "move" an entity
	-- between roles or re-link it -- it's removed from both lists
	-- first.
	function ENT:LinkEntity(ent)
		if not IsValid(ent) then return end
		if ent == self then return end

		self:UnlinkEntity(ent)

		if ent.PowerRole == "generator" then
			table.insert(self.LinkedGenerators, ent)
		else
			table.insert(self.LinkedConsumers, ent)
		end

		self:UpdateNetworkedCounts()
		self:UpdateNetworkedNames()
		self:UpdateCableSlots()
	end

	-- Removes ent from whichever list it's in, if any. Called by
	-- ENT:UnlinkMainframe() on the linked entity (e.g. when it
	-- wires to a different mainframe, or is removed), and
	-- internally before re-adding on a fresh link.
	function ENT:UnlinkEntity(ent)
		local changed = false

		for i, existing in ipairs(self.LinkedGenerators) do
			if existing == ent then
				table.remove(self.LinkedGenerators, i)
				changed = true
				break
			end
		end

		for i, existing in ipairs(self.LinkedConsumers) do
			if existing == ent then
				table.remove(self.LinkedConsumers, i)
				changed = true

				-- The consumer is leaving -- make sure it doesn't
				-- stay stuck thinking it has power.
				if ent.SetPowered then
					ent:SetPowered(false)
				end
				break
			end
		end

		if changed then
			self:UpdateNetworkedCounts()
			self:UpdateNetworkedNames()
			self:UpdateCableSlots()
		end
	end

	-- Refills the fixed CableSlot NetworkVars from the current
	-- generator+consumer lists so the client can draw a permanent
	-- beam to each one. Called whenever the linked lists actually
	-- change (link, unlink, prune) -- not on every power tick,
	-- same as UpdateNetworkedNames.
	function ENT:UpdateCableSlots()
		local slot = 1

		for _, ent in ipairs(self.LinkedGenerators) do
			if slot > self.MaxCableSlots then break end
			if IsValid(ent) then
				self["SetCableSlot" .. slot](self, ent)
				slot = slot + 1
			end
		end

		for _, ent in ipairs(self.LinkedConsumers) do
			if slot > self.MaxCableSlots then break end
			if IsValid(ent) then
				self["SetCableSlot" .. slot](self, ent)
				slot = slot + 1
			end
		end

		-- Clear any remaining slots so stale entities from a
		-- previous, longer list don't keep drawing cables.
		for i = slot, self.MaxCableSlots do
			self["SetCableSlot" .. i](self, NULL)
		end
	end

	-- Cheap: just the two counters, safe to call every power tick.
	function ENT:UpdateNetworkedCounts()
		self:SetNWInt("GeneratorCount", #self.LinkedGenerators)
		self:SetNWInt("ConsumerCount", #self.LinkedConsumers)
	end

	-- More expensive: rebuilds the delimited name-list strings the
	-- screen displays. NWString can't carry a table directly, so
	-- names are joined with newlines and split again on the
	-- client. Only called when the linked lists actually change
	-- (link, unlink, or a prune of an invalid entity), not on
	-- every power tick.
	function ENT:UpdateNetworkedNames()
		local generatorNames = {}
		for _, ent in ipairs(self.LinkedGenerators) do
			if IsValid(ent) then
				table.insert(generatorNames, ent.PrintName or ent:GetClass())
			end
		end

		local consumerNames = {}
		for _, ent in ipairs(self.LinkedConsumers) do
			if IsValid(ent) then
				table.insert(consumerNames, ent.PrintName or ent:GetClass())
			end
		end

		self:SetNW2String("GeneratorNames", table.concat(generatorNames, "\n"))
		self:SetNW2String("ConsumerNames", table.concat(consumerNames, "\n"))
	end

	-- Sums power from all linked generators, then distributes it
	-- to linked consumers in link order until it runs out. Prunes
	-- any invalid (removed) entities from both lists as it goes,
	-- and refreshes the name list if a prune actually happened.
	function ENT:UpdatePower()
		local total = 0
		local listChanged = false

		for i = #self.LinkedGenerators, 1, -1 do
			local generator = self.LinkedGenerators[i]

			if not IsValid(generator) then
				table.remove(self.LinkedGenerators, i)
				listChanged = true
			elseif generator.GetPowerOutput then
				total = total + (generator:GetPowerOutput() or 0)
			end
		end

		self.AvailablePower = total
		self:SetNWInt("AvailablePower", math.Round(total))

		local remaining = total
		local used = 0

		for i = #self.LinkedConsumers, 1, -1 do
			local consumer = self.LinkedConsumers[i]

			if not IsValid(consumer) then
				table.remove(self.LinkedConsumers, i)
				listChanged = true
			else
				local required = 0
				if consumer.GetPowerRequired then
					required = consumer:GetPowerRequired() or 0
				end

				local canPower = required <= remaining

				if canPower then
					remaining = remaining - required
					used = used + required
				end

				if consumer.SetPowered then
					consumer:SetPowered(canPower)
				end
			end
		end

		self.UsedPower = used
		self:SetNWInt("UsedPower", math.Round(used))

		self:UpdateNetworkedCounts()

		if listChanged then
			self:UpdateNetworkedNames()
			self:UpdateCableSlots()
		end
	end

	function ENT:Think()
		local currentTime = CurTime()

		if currentTime >= (self.NextPowerTick or 0) then
			self.NextPowerTick = currentTime + 1
			self:UpdatePower()
		end

		self:NextThink(currentTime + 0.1)
		return true
	end

	function ENT:OnRemove()
		self.BaseClass.OnRemove(self)

		-- Cleanly detach everything wired to this mainframe rather
		-- than leaving generators/consumers pointing at a dead
		-- entity.
		for _, generator in ipairs(self.LinkedGenerators) do
			if IsValid(generator) then
				generator.LinkedMainframe = nil
			end
		end

		for _, consumer in ipairs(self.LinkedConsumers) do
			if IsValid(consumer) then
				consumer.LinkedMainframe = nil
				if consumer.SetPowered then
					consumer:SetPowered(false)
				end
			end
		end
	end
end

if CLIENT then

	surface.CreateFont("EryMainframeTitle", {
		font = "Tahoma",
		size = 20,
		weight = 700,
	})

	surface.CreateFont("EryMainframeText", {
		font = "Tahoma",
		size = 16,
		weight = 600,
	})

	surface.CreateFont("EryMainframeSmall", {
		font = "Tahoma",
		size = 13,
		weight = 500,
	})

	-- Splits a "\n"-joined NWString back into a list of names.
	-- Returns an empty table for an empty/missing string, rather
	-- than a table with one empty-string entry.
	local function SplitNames(str)
		if not str or str == "" then return {} end
		return string.Explode("\n", str)
	end

	-- Draws the generator/consumer list + power readout, always
	-- visible up close, similar to the radar screen. Kept
	-- separate from DrawLabel() since this doesn't need the
	-- player to be looking at the entity, just nearby.
	function ENT:DrawScreen()
		local availablePower = self:GetNWInt("AvailablePower", 0)
		local usedPower = self:GetNWInt("UsedPower", 0)

		local generatorNames = SplitNames(self:GetNW2String("GeneratorNames", ""))
		local consumerNames = SplitNames(self:GetNW2String("ConsumerNames", ""))

		-- Anchor to the entity's own coordinate frame (not world
		-- space) so the panel sits on the front face and turns
		-- with the prop instead of staying fixed in world
		-- orientation. LocalToWorld handles both the offset and
		-- the base rotation in one step.
		local offset = self.MainframeScreenOffset or Vector(0, 0, 55)
		local pos = self:LocalToWorld(offset)

		local ang = self:LocalToWorldAngles(Angle(0, 0, 0))
		ang:RotateAroundAxis(ang:Up(), 90)
		ang:RotateAroundAxis(ang:Forward(), 90)

		local size = self.MainframeScreenSize or { w = 320, h = 260 }
		local halfW, halfH = size.w / 2, size.h / 2
		local scale = self.MainframeScreenScale or 0.05

		cam.Start3D2D(pos, ang, scale)
			surface.SetDrawColor(10, 10, 15, 230)
			surface.DrawRect(-halfW, -halfH, size.w, size.h)

			surface.SetDrawColor(80, 160, 255, 255)
			surface.DrawOutlinedRect(-halfW, -halfH, size.w, size.h, 2)

			draw.SimpleText("MAINFRAME", "EryMainframeTitle", 0, -halfH + 10, Color(120, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

			draw.SimpleText(
				"Used Power: " .. usedPower .. " / " .. availablePower,
				"EryMainframeText",
				0,
				-halfH + 38,
				usedPower > availablePower and Color(255, 120, 120) or color_white,
				TEXT_ALIGN_CENTER,
				TEXT_ALIGN_TOP
			)

			-- Two columns: generators on the left, consumers on the
			-- right, each listed by name up to a capped row count so
			-- a long list doesn't overflow the panel.
			local colY = -halfH + 68
			local leftX = -halfW + 12
			local rightX = 12
			local rowHeight = 15
			local maxRows = 10

			draw.SimpleText("GENERATORS", "EryMainframeSmall", leftX, colY, Color(255, 220, 120), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			draw.SimpleText("CONSUMERS", "EryMainframeSmall", rightX, colY, Color(180, 220, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

			for i, name in ipairs(generatorNames) do
				if i > maxRows then
					draw.SimpleText("+" .. (#generatorNames - maxRows) .. " more", "EryMainframeSmall", leftX, colY + 18 + (maxRows * rowHeight), Color(150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
					break
				end
				draw.SimpleText(name, "EryMainframeSmall", leftX, colY + 18 + ((i - 1) * rowHeight), color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			end

			for i, name in ipairs(consumerNames) do
				if i > maxRows then
					draw.SimpleText("+" .. (#consumerNames - maxRows) .. " more", "EryMainframeSmall", rightX, colY + 18 + (maxRows * rowHeight), Color(150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
					break
				end
				draw.SimpleText(name, "EryMainframeSmall", rightX, colY + 18 + ((i - 1) * rowHeight), color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			end

			if #generatorNames == 0 then
				draw.SimpleText("(none)", "EryMainframeSmall", leftX, colY + 18, Color(120, 120, 120), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			end

			if #consumerNames == 0 then
				draw.SimpleText("(none)", "EryMainframeSmall", rightX, colY + 18, Color(120, 120, 120), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			end
		cam.End3D2D()
	end

	function ENT:Draw()
		self:DrawModel()

		local attachDist = (self.AttachmentDrawDistance or 500)^2
		if self:GetPos():DistToSqr(LocalPlayer():GetPos()) <= attachDist then
			ERY_MACHINE:DrawAttachments(self, self.Attachments)
		end

		local screenDist = (self.ScreenDrawDistance or 700)^2
		if self:GetPos():DistToSqr(LocalPlayer():GetPos()) <= screenDist then
			self:DrawScreen()
		end

		self:DrawLabel()
	end

	-- Permanent cable beams from every linked generator/consumer
	-- to this mainframe -- the plug that originally carried the
	-- connection is gone by this point (removed in Touch()), so
	-- these are drawn here instead, straight from each entity's
	-- current position, every frame. Model itself is opaque and
	-- already handled in Draw(); this is purely for the beams,
	-- same reasoning as the plug's own DrawTranslucent.
	function ENT:DrawTranslucent()
		local mat = Material(self.CableMaterial)
		local width = self.CableWidth or 1.5

		render.SetMaterial(mat)

		for i = 1, self.MaxCableSlots do
			local ent = self["GetCableSlot" .. i](self)
			if IsValid(ent) then
				-- Entities like the turbine define a local-space
				-- CableOffset so the beam originates from a
				-- specific point on the model (e.g. a connector
				-- box) instead of the entity's raw origin.
				-- LocalToWorld folds in both the entity's position
				-- and its current rotation, so the point tracks the
				-- model correctly even as it turns.
				local startPos = ent.CableOffset and ent:LocalToWorld(ent.CableOffset) or ent:GetPos()
				render.DrawBeam(startPos, self:GetPos(), width, 0, 1, color_white)
			end
		end
	end
end
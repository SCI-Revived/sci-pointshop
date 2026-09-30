AddCSLuaFile()
AddCSLuaFile("autorun/ery_machine_base_helpers.lua")
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.Author = "Paloma"
ENT.PrintName = "Pointshop Entity Base (UI)"
ENT.Category = "Pointshop Entities"
ENT.Spawnable = false
ENT.AdminOnly = false

ENT.IconPath = "entities/ery_mat_mechanism_advanced.png"
ENT.IconOffset = Vector(0, 0, 20)

ENT.Attachments = {}
ENT.CollideSounds = {
			"common/warning.wav"
}

ENT.AttachmentDrawDistance = 1000
ENT.LabelDrawDistance = 300

ENT.Decaytime = 300

ENT.MaxHealth = 500
ENT.HealthRegen = 1 -- health regenerated per second
ENT.CustomMass = 200

ENT.SpawnOffset = Vector(0, 0, 0) -- world-space offset applied 0.1s after spawning

if SERVER then
	util.AddNetworkString("ery_entity_menu_open")
	util.AddNetworkString("ery_entity_menu_action")

	function ENT:Initialize()
		self:SetModel(self.BaseModel or "models/hunter/blocks/cube025x025x025.mdl")
		self:SetMaterial(self.BaseMaterial or "hunter/myplastic")
		self:SetColor(self.BaseColor or Color(255, 255, 255, 255))
		self:ManipulateBoneScale(0, self.BoneScale or Vector(1, 1, 1))
		self.CollideSounds = self.CollideSounds or self:GetTable().CollideSounds
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)

		self:SetMaxHealth(self.MaxHealth or 500)
		self:SetHealth(self.MaxHealth or 500)
		self:SetNWInt("EryHealth", self:Health())
		self:SetNWInt("EryMaxHealth", self:GetMaxHealth())

		-- Interaction menu (opened on E / Use). Subclasses add
		-- their own entries with self:AddMenuButton(id, label,
		-- callback) -- typically from their own Initialize,
		-- after calling self.BaseClass.Initialize(self). Every
		-- entity gets "Wire to mainframe" for free.
		self.MenuButtons = {}
		self.MenuButtonOrder = {}

		self:AddMenuButton("wire_to_mainframe", "Wire to mainframe", function(ent, activator)
			ent:WireToMainframe(activator)
		end)

		-- Backward compatibility: entities that don't define
		-- their own OnUse still get a "Pick up" button, matching
		-- the base's old default Use() behavior. Entities that do
		-- define OnUse get it wired in as a button instead of it
		-- firing directly, since Use() now always opens the menu.
		if self.OnUse then
			self:AddMenuButton("use", "Use", function(ent, activator)
				ent:OnUse(activator)
			end)
		else
			self:AddMenuButton("pickup", "Pick up", function(ent, activator)

				if IsValid(ent) then
					local phys = ent:GetPhysicsObject()
					if IsValid(phys) then
						phys:EnableMotion(true)
						phys:Wake()
					end
				end
				activator:PickupObject(ent)
			end)
		end

		local phys = self:GetPhysicsObject()
		timer.Simple(0.01, function()
			if IsValid(phys) then
				phys:SetMass(self.CustomMass or 5)
				phys:Wake()
			end
		end)

		-- Teleport by SpawnOffset shortly after spawning
		if self.SpawnOffset and self.SpawnOffset ~= vector_origin then
			timer.Simple(0.1, function()
				if not IsValid(self) then return end

				self:SetPos(self:GetPos() + self.SpawnOffset)

				local p = self:GetPhysicsObject()
				if IsValid(p) then
					p:Wake()
				end
			end)
		end

		if self.Decaytime and self.Decaytime > 0 then
			timer.Create("DecayTimer_" .. self:EntIndex(), self.Decaytime, 1, function()
				if IsValid(self) then self:Remove() end
			end)
		end

		if (self.HealthRegen or 0) > 0 then
			timer.Create("HealthRegenTimer_" .. self:EntIndex(), 1, 0, function()
				if not IsValid(self) then return end
				local maxHP = self.MaxHealth or self:GetMaxHealth()
				local newHP = math.Round(math.min(self:Health() + self.HealthRegen, maxHP))
				if newHP ~= self:Health() then
					self:SetHealth(newHP)
					self:SetNWInt("EryHealth", newHP)
				end
			end)
		end
	end

	-- Registers a button in this entity's interaction menu (the
	-- one opened by pressing E). Subclasses call this from their
	-- own Initialize(), after self.BaseClass.Initialize(self)
	-- has run, so "Wire to mainframe" always appears first.
	-- id: short unique string, used to dispatch the click server-side.
	-- label: text shown on the button.
	-- callback(ent, activator): called on click. ent is this
	-- entity, activator is the player who clicked it.
	function ENT:AddMenuButton(id, label, callback)
		self.MenuButtons = self.MenuButtons or {}
		self.MenuButtonOrder = self.MenuButtonOrder or {}

		if not self.MenuButtons[id] then
			table.insert(self.MenuButtonOrder, id)
		end

		self.MenuButtons[id] = {
			label = label,
			callback = callback
		}
	end

	-- Removes a previously registered button, e.g. if a subclass
	-- wants to swap "Wire to mainframe" out for something else.
	function ENT:RemoveMenuButton(id)
		if not self.MenuButtons then return end
		self.MenuButtons[id] = nil

		for i, existingId in ipairs(self.MenuButtonOrder or {}) do
			if existingId == id then
				table.remove(self.MenuButtonOrder, i)
				break
			end
		end
	end

	function ENT:Use(ply)
		if not IsValid(ply) or not ply:IsPlayer() then return end

		local order = self.MenuButtonOrder or {}
		local buttons = self.MenuButtons or {}

		net.Start("ery_entity_menu_open")
			net.WriteEntity(self)
			net.WriteUInt(#order, 8)
			for _, id in ipairs(order) do
				local btn = buttons[id]
				net.WriteString(id)
				net.WriteString(btn and btn.label or id)
			end
		net.Send(ply)
	end

	-- Detaches this entity from its currently linked mainframe,
	-- if any, notifying the mainframe so it can drop this entity
	-- from its own list. Safe to call even if nothing is linked.
	function ENT:UnlinkMainframe()
		if IsValid(self.LinkedMainframe) and self.LinkedMainframe.UnlinkEntity then
			self.LinkedMainframe:UnlinkEntity(self)
		end
		self.LinkedMainframe = nil
	end

	-- Spawns a sci_pointshop_plug tethered to this entity and has
	-- the activating player pick it up (physgun-style hold via
	-- PickupObject), the same way the base's default "Pick up"
	-- button grabs an entity. An earlier version tried to parent
	-- the plug to the player's hand bone via FollowBone, which
	-- was unreliable across playermodels -- spawning it unfrozen
	-- and letting the engine's own pickup/hold logic take it is
	-- simpler and doesn't need any bone lookup at all. Any
	-- connection this entity already had is dropped first, and
	-- any plug the player was already holding is removed.
	function ENT:WireToMainframe(ply)
		if not IsValid(ply) or not ply:IsPlayer() then return end

		self:UnlinkMainframe()

		if IsValid(ply.ERYActivePlug) then
			ply.ERYActivePlug:Remove()
		end

		local plug = ents.Create("sci_pointshop_plug")
		if not IsValid(plug) then return end

		plug:SetPos(self:GetPos() + Vector(0, 0, 20))
		plug:Spawn()
		plug:Activate()

		plug.Owner = ply
		if plug.SetSourceEntity then
			plug:SetSourceEntity(self)
		end

		ply.ERYActivePlug = plug

		-- Unfrozen and physically simulated -- Touch() still
		-- fires normally against a mainframe while held.
		local phys = plug:GetPhysicsObject()
		if IsValid(phys) then
			phys:EnableMotion(true)
			phys:Wake()
		end

		ply:PickupObject(plug)

		ply:ChatPrint("[" .. (self.PrintName or "Entity") .. "] Plug ready! Press it against a mainframe to wire this up.")
	end

	net.Receive("ery_entity_menu_action", function(_, ply)
		local ent = net.ReadEntity()
		local id = net.ReadString()

		if not IsValid(ent) or not IsValid(ply) then return end
		if not ent.MenuButtons then return end

		local btn = ent.MenuButtons[id]
		if not btn or not btn.callback then return end

		btn.callback(ent, ply)
	end)

	function ENT:OnTakeDamage(dmginfo)
		local dmg = dmginfo:GetDamage()
		if dmg <= 0 then return end

		local newHP = math.Round(math.max(self:Health() - dmg, 0))
		self:SetHealth(newHP)
		self:SetNWInt("EryHealth", newHP)

		if newHP <= 0 then
			self:OnDestroyed(dmginfo)
		end
	end

	function ENT:OnDestroyed(dmginfo)
		local effectPos = self:GetPos()
		local effectdata = EffectData()
		effectdata:SetOrigin(effectPos)
		effectdata:SetEntity(self)
		util.Effect("ElectricSpark", effectdata)

		self:Remove()
	end

	function ENT:OnRemove()
		timer.Remove("DecayTimer_" .. self:EntIndex())
		timer.Remove("HealthRegenTimer_" .. self:EntIndex())
	end

	function ENT:PhysicsCollide(data, phys)
		if data.DeltaTime > 0.2 and data.Speed > 50 then
		local sounds = self.CollideSounds or {
			"player/footsteps/gravel1.wav",
			"player/footsteps/gravel2.wav",
			"player/footsteps/gravel3.wav",
			"player/footsteps/gravel4.wav"
		}
		self:EmitSound(sounds[math.random(#sounds)], 90, math.random(90, 110))

		end
	end
end

if CLIENT then
	surface.CreateFont("EryMatWorld", {
		font = "Tahoma",
		size = 36,
		weight = 500,
	})

	-- Shared interaction menu, opened by pressing E on any
	-- ery_material_base entity. Subclasses don't need to build
	-- their own DFrame for simple button lists -- they register
	-- buttons server-side via self:AddMenuButton(...) and this
	-- renders them generically.
	local function OpenEntityMenu(ent, buttonList)
		if not IsValid(ent) then return end
		if IsValid(ERY_MENU_FRAME) then ERY_MENU_FRAME:Remove() end

		local rowHeight = 30
		local frame = vgui.Create("DFrame")
		ERY_MENU_FRAME = frame

		frame:SetTitle(ent.PrintName or "Entity")
		frame:SetSize(240, 40 + (#buttonList * rowHeight) + 8)
		frame:Center()
		frame:MakePopup()

		for i, entry in ipairs(buttonList) do
			local button = vgui.Create("DButton", frame)
			button:SetPos(8, 32 + ((i - 1) * rowHeight))
			button:SetSize(frame:GetWide() - 16, rowHeight - 4)
			button:SetText(entry.label)

			button.DoClick = function()
				net.Start("ery_entity_menu_action")
					net.WriteEntity(ent)
					net.WriteString(entry.id)
				net.SendToServer()

				if IsValid(frame) then frame:Close() end
			end
		end
	end

	net.Receive("ery_entity_menu_open", function()
		local ent = net.ReadEntity()
		local count = net.ReadUInt(8)

		local buttonList = {}
		for i = 1, count do
			local id = net.ReadString()
			local label = net.ReadString()
			table.insert(buttonList, { id = id, label = label })
		end

		OpenEntityMenu(ent, buttonList)
	end)

	function ENT:Initialize()
		-- ENT.Attachments is set once per entity CLASS (file scope),
		-- so without copying here, every instance of a given entity
		-- would read/write the exact same table -- animating one
		-- instance's attachments (Pos, Angle, Color, etc. in Think)
		-- would visibly affect every other instance of that class.
		-- table.FullCopy (not table.Copy) is required since Pos/
		-- Angle/Color are nested tables/userdata; a shallow copy
		-- would still share those by reference.
		self.Attachments = table.FullCopy(self.Attachments or {})
	end

	function ENT:Draw()
		self:DrawModel()
		local attachDist = (self.AttachmentDrawDistance or 500)^2
		if self:GetPos():DistToSqr(LocalPlayer():GetPos()) <= attachDist then
			ERY_MACHINE:DrawAttachments(self, self.Attachments)
		end

		self:DrawLabel()
	end

	-- Draws the floating icon, name, and healthbar shown when
	-- the player is looking at this entity. Split out from
	-- Draw() so subclasses that add their own visuals (e.g. a
	-- radar screen) can call DrawModel() and any extra drawing
	-- in between, then call this last, without duplicating the
	-- label/healthbar code or drawing the model twice.
	-- Returns true if the label was actually drawn (i.e. the
	-- player is looking at the entity and within range), so
	-- subclasses can gate their own additions on the same
	-- condition without re-checking eye trace/distance
	-- themselves.
	function ENT:DrawLabel()
		local ply = LocalPlayer()
		if not IsValid(ply) then return false end

		local trace = ply:GetEyeTrace()
		if trace.Entity ~= self then return false end

		-- LocalToWorld (instead of a plain world-space add) makes
		-- this offset rotate with the entity, as if the icon/label
		-- were parented to it -- if the prop spins, the label
		-- orbits around it instead of staying fixed to world axes.
		local pos = self:LocalToWorld(self.IconOffset or Vector(0, 0, 20))
		local labelDist = (self.LabelDrawDistance or 300)^2
		if pos:DistToSqr(ply:GetPos()) > labelDist then return false end



		local ang = ply:EyeAngles()
		ang:RotateAroundAxis(ang:Right(), 90)
		ang:RotateAroundAxis(ang:Up(), -90)

		cam.Start3D2D(pos, ang, 0.1)
			local icon = self.IconPath or "entities/ery_mat_mechanism_advanced.png"
			surface.SetDrawColor(self.IconColor or Color (255, 255, 255, 255))
			surface.SetMaterial(Material(icon, "smooth"))
			surface.DrawTexturedRect(-64, -64, 128, 128)

			draw.SimpleText(self.PrintName or "Resource", "EryMatWorld", 0, 80, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

			local hp = math.Round(self:GetNWInt("EryHealth", self.MaxHealth or 500))
			local maxHP = math.Round(self:GetNWInt("EryMaxHealth", self.MaxHealth or 500))
			local frac = maxHP > 0 and math.Clamp(hp / maxHP, 0, 1) or 0

			local barW, barH = 160, 14
			local barX, barY = -barW / 2, 130

			surface.SetDrawColor(30, 30, 30, 220)
			surface.DrawRect(barX - 2, barY - 2, barW + 4, barH + 4)

			surface.SetDrawColor(60, 60, 60, 255)
			surface.DrawRect(barX, barY, barW, barH)

			local fillColor = Color(255 * (1 - frac), 255 * frac, 0, 255)
			surface.SetDrawColor(fillColor)
			surface.DrawRect(barX, barY, barW * frac, barH)

			draw.SimpleText(hp .. " / " .. maxHP, "EryMatWorld", 0, barY + barH + 4, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		cam.End3D2D()

		return true
	end

	function ENT:OnRemove()
		ERY_MACHINE:CleanupAttachments(self)
	end
end
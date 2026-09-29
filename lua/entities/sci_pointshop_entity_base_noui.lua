AddCSLuaFile()
AddCSLuaFile("autorun/ery_machine_base_helpers.lua")
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.Author = "Paloma"
ENT.PrintName = "Pointshop Entity Base (No UI)"
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

ENT.Decaytime = -1
ENT.CustomMass = 200

if SERVER then
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

		local phys = self:GetPhysicsObject()
		timer.Simple(0.01, function()
			if IsValid(phys) then
				phys:SetMass(self.CustomMass or 5)
				phys:Wake()
			end
		end)

		if self.Decaytime and self.Decaytime > 0 then
			timer.Create("DecayTimer_" .. self:EntIndex(), self.Decaytime, 1, function()
				if IsValid(self) then self:Remove() end
			end)
		end
	end

	function ENT:Use(ply)
		if self.OnUse then
			self:OnUse(ply)
		else
			ply:PickupObject(self)
		end
	end

	function ENT:OnRemove()
		timer.Remove("DecayTimer_" .. self:EntIndex())
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

	function ENT:Initialize()
		self.Attachments = self.Attachments or {}
	end

	function ENT:Draw()
		self:DrawModel()
		local attachDist = (self.AttachmentDrawDistance or 500)^2
		if self:GetPos():DistToSqr(LocalPlayer():GetPos()) <= attachDist then
			ERY_MACHINE:DrawAttachments(self, self.Attachments)
		end

		self:DrawLabel()
	end

	function ENT:DrawLabel()
		local ply = LocalPlayer()
		if not IsValid(ply) then return false end

		local trace = ply:GetEyeTrace()
		if trace.Entity ~= self then return false end

		local pos = self:GetPos() + (self.IconOffset or Vector(0, 0, 20))
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
		cam.End3D2D()

		return true
	end

	function ENT:OnRemove()
		ERY_MACHINE:CleanupAttachments(self)
	end
end
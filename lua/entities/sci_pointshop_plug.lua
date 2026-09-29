AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "sci_pointshop_entity_base_noui"

ENT.PrintName = "Power Plug"
ENT.Author = "Paloma"
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.Category = "Pointshop Entities"

ENT.BaseModel = "models/props_lab/tpplug.mdl"
ENT.BaseMaterial = ""
ENT.BaseColor = Color(255, 255, 255, 255)
ENT.BoneScale = Vector(1, 1, 1)

ENT.Decaytime = -1

-- Visual-only cable rendered client-side between the source
-- entity (whatever this plug was pulled from) and the plug
-- itself, while it's being carried.
ENT.CableMaterial = "cable/cable2"
ENT.CableWidth = 1.5

-- The plug's model is opaque, but we still need DrawTranslucent
-- to fire every frame to draw the cable beam. RENDERGROUP_BOTH
-- ensures DrawTranslucent runs in addition to Draw.
ENT.RenderGroup = RENDERGROUP_BOTH

ENT.CustomMass = 5

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "SourceEntity")
end

ENT.CollideSounds = {
    "physics/plastic/plastic_box_break1.wav",
    "physics/plastic/plastic_box_break2.wav"
}

if SERVER then

	function ENT:Initialize()
		-- Model, material, physics, decay are handled by the
		-- base. The plug doesn't need health/menu/damage, hence
		-- basing off the no-UI variant.
		self.BaseClass.Initialize(self)

		self:SetUseType(SIMPLE_USE)

		-- Not meant to be picked up with the physgun or +use --
		-- it's already "held" via FollowBone by whoever pulled it.
		self:SetNotSolid(false)
	end

	-- self:SetSourceEntity(ent) / self:GetSourceEntity() are the
	-- entity this plug was pulled from (generator, consumer, or
	-- anything else using sci_pointshop_entity_base_ui), set by
	-- that entity's WireToMainframe() right after spawning this.
	-- Networked so the client can draw the cable to it.
	-- ENT.Owner: the player carrying the plug (server-only, not
	-- needed on the client).

	function ENT:Think()
		-- If either end of the link has gone away, the plug is
		-- meaningless -- clean it up rather than leaving a dead
		-- plug stuck in a player's hand.
		if not IsValid(self:GetSourceEntity()) or not IsValid(self.Owner) then
			self:Remove()
			return
		end

		self:NextThink(CurTime() + 0.5)
		return true
	end

	function ENT:Touch(otherEnt)
		-- Touch() can fire multiple times for the same overlap
		-- (multiple physics sub-steps, re-triggering while still
		-- inside the mainframe's bounding box before Remove() is
		-- actually processed, etc). Latch on the first valid touch
		-- so the link logic below -- and the chat message, sound,
		-- and effect that come with it -- only ever runs once.
		if self.HasLinked then return end

		if not IsValid(otherEnt) then return end
		if otherEnt:GetClass() ~= "sci_pointshop_base_mainframe" then return end

		local source = self:GetSourceEntity()
		if not IsValid(source) then return end

		self.HasLinked = true

		-- Defensive: LinkEntity may not exist yet if the mainframe
		-- entity hasn't been implemented. Once it is, this call
		-- completes the Generator -> Mainframe / Mainframe ->
		-- Consumer link.
		if otherEnt.LinkEntity then
			otherEnt:LinkEntity(source)
		end

		source.LinkedMainframe = otherEnt

		if IsValid(self.Owner) then
			self.Owner:ChatPrint(
				"[" .. (source.PrintName or "Entity") .. "] Wired to "
				.. (otherEnt.PrintName or "Mainframe") .. "."
			)

			if self.Owner.ERYActivePlug == self then
				self.Owner.ERYActivePlug = nil
			end
		end

		local effectdata = EffectData()
		effectdata:SetOrigin(self:GetPos())
		util.Effect("cball_explode", effectdata, true, true)

		self:EmitSound("buttons/button14.wav", 60, 120)

		self:Remove()
	end

	function ENT:OnRemove()
		self.BaseClass.OnRemove(self)

		if IsValid(self.Owner) and self.Owner.ERYActivePlug == self then
			self.Owner.ERYActivePlug = nil
		end
	end
end

if CLIENT then

	function ENT:Draw()
		self:DrawModel()
	end

	-- Draws the decorative cable from the source entity to this
	-- plug every frame while it exists. The model itself is
	-- already drawn in Draw() (opaque pass) -- RENDERGROUP_BOTH
	-- means this still fires too, purely for the beam. The
	-- actual power link is established server-side in Touch().
	function ENT:DrawTranslucent()
		local source = self:GetSourceEntity()
		if not IsValid(source) then return end

		render.SetMaterial(Material(self.CableMaterial))
		render.DrawBeam(
			source:GetPos(),
			self:GetPos(),
			self.CableWidth or 1.5,
			0,
			1,
			color_white
		)
	end
end
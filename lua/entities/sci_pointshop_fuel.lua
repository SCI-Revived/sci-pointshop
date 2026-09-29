AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "sci_pointshop_entity_base_ui"

ENT.PrintName = "Fuel Can"
ENT.Author = "Paloma"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "Pointshop Entities"

ENT.IconPath = "entities/sci_pointshop_fuel.png"
ENT.IconOffset = Vector(0, 0, 32)

ENT.BaseModel = "models/props_junk/gascan001a.mdl"
ENT.BaseMaterial = ""
ENT.BaseColor = Color(255, 255, 255, 255)
ENT.BoneScale = Vector(1, 1, 1)

ENT.AttachmentDrawDistance = 1000
ENT.LabelDrawDistance = 300
ENT.Decaytime = 600

ENT.MaxHealth = 50
ENT.HealthRegen = 0

ENT.FuelSeconds = 600 -- 10 minutes

ENT.CustomMass = 25

ENT.CollideSounds = {
    "player/footsteps/slosh1.wav",
    "player/footsteps/slosh2.wav",
    "player/footsteps/slosh3.wav",
    "player/footsteps/slosh4.wav"
}

if SERVER then

    function ENT:Initialize()
        self.BaseClass.Initialize(self)

        self:RemoveMenuButton("wire_to_mainframe")
    end

    function ENT:Touch(otherEnt)
        if self.HasRefueled then return end

        if not IsValid(otherEnt) then return end
        if otherEnt:GetClass() ~= "sci_pointshop_fuelgenerator" then return end

        if not otherEnt.AddFuel then return end

        local accepted = otherEnt:AddFuel(self.FuelSeconds or 600)
        if not accepted then return end

        self.HasRefueled = true

        local effectdata = EffectData()
        effectdata:SetOrigin(self:GetPos())
        util.Effect("StunstickImpact", effectdata, true, true)

        self:EmitSound(
            "physics/metal/metal_canister_impact_hard1.wav",
            65,
            110
        )

        self:Remove()
    end

	function ENT:Use(ply)
		if self.OnUse then
			self:OnUse(ply)
		else
			ply:PickupObject(self)
		end
	end

    function ENT:OnDestroyed(dmginfo)
        local position = self:GetPos()

        -- Explosion effect
        local effectdata = EffectData()
        effectdata:SetOrigin(position)
        util.Effect("Explosion", effectdata, true, true)

        self:EmitSound(
            "ambient/explosions/explode_9.wav",
            90,
            100
        )

        -- Spawn 3 fire pools
        for i = 1, 3 do
            local firePool = ents.Create("sci_pointshop_fire_pool")

            if IsValid(firePool) then
                local offset = Vector(
                    math.Rand(-30, 30),
                    math.Rand(-30, 30),
                    5
                )

                firePool:SetPos(position + offset)
                firePool:Spawn()
            end
        end

        self:Remove()
    end

end
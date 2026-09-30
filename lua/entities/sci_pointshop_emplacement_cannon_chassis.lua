AddCSLuaFile()

ENT.Base = "sci_pointshop_entity_base_ui"
ENT.Type = "anim"
ENT.PrintName = "Cannon Chassis"
ENT.Category = "Pointshop Entities"
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.BaseModel = "models/hunter/blocks/cube075x075x075.mdl"
ENT.BaseMaterial = "models/effects/intro_tearshape"
ENT.BoneScale = Vector(1, 1, 1)
ENT.IconPath = "entities/sci_pointshop_emplacement_cannon_chassis.png"
ENT.IconOffset = Vector(0, 0, 55)
ENT.CustomMass = 200

-- The UI base defaults to a 300s decay timer; the cannon must persist
ENT.Decaytime = -1

-- Health (handled entirely by the UI base: NW sync, damage, regen timer)
ENT.MaxHealth = 500
ENT.HealthRegen = 1

ENT.CollideSounds = {
    "physics/metal/weapon_impact_hard1.wav",
    "physics/metal/weapon_impact_hard2.wav",
    "physics/metal/weapon_impact_hard3.wav"
}

local WOOD = Color(156, 102, 75)
local WHITE = Color(255, 255, 255)
local BEAMS = "models/props/CS_militia/roofbeams01"
local PLASTER = "models/props_buildings/plasterwall021a"

-- NOTE: the new helper reads "Pos" (the old helper used "Position")
ENT.Attachments = {
    -- Cleats
    { Model = "models/props_docks/dock01_cleat01a.mdl", Pos = Vector(15, 22, -5), Angle = Angle(0, 0, 0), Color = WOOD, Material = "", Scale = 1.5 },
    { Model = "models/props_docks/dock01_cleat01a.mdl", Pos = Vector(15, -22, -5), Angle = Angle(0, 0, 0), Color = WOOD, Material = "", Scale = 1.5 },

    -- Axle / undercarriage
    { Model = "models/hunter/blocks/cube075x1x025.mdl", Pos = Vector(0, 0, -5), Angle = Angle(0, 90, 0), Color = WHITE, Material = BEAMS, Scale = 1 },
    { Model = "models/props_phx/trains/double_wheels_base.mdl", Pos = Vector(5, 0, -2), Angle = Angle(180, 0, 0), Color = WHITE, Material = BEAMS, Scale = 0.3 },
    { Model = "models/hunter/misc/roundthing3.mdl", Pos = Vector(0, 15, -5), Angle = Angle(0, 90, 90), Color = WHITE, Material = BEAMS, Scale = 0.3 },
    { Model = "models/hunter/misc/roundthing3.mdl", Pos = Vector(0, -15, -5), Angle = Angle(0, 90, -90), Color = WHITE, Material = BEAMS, Scale = 0.3 },

    -- Wheels
    { Model = "models/mechanics/wheels/wheel_rounded_36s.mdl", Pos = Vector(20, -31.5, -5), Angle = Angle(0, 0, 90), Color = WOOD, Material = PLASTER, Scale = 0.55 },
    { Model = "models/mechanics/wheels/wheel_rounded_36s.mdl", Pos = Vector(-20, -31.5, -5), Angle = Angle(0, 0, 90), Color = WOOD, Material = PLASTER, Scale = 0.55 },
    { Model = "models/mechanics/wheels/wheel_rounded_36s.mdl", Pos = Vector(20, 31.5, -5), Angle = Angle(0, 0, 90), Color = WOOD, Material = PLASTER, Scale = 0.55 },
    { Model = "models/mechanics/wheels/wheel_rounded_36s.mdl", Pos = Vector(-20, 31.5, -5), Angle = Angle(0, 0, 90), Color = WOOD, Material = PLASTER, Scale = 0.55 },

    -- Suitcase (ammo box)
    { Model = "models/props_c17/SuitCase001a.mdl", Pos = Vector(-20, 0, -3), Angle = Angle(90, 90, 0), Color = WOOD, Material = PLASTER, Scale = 1 }
}

ENT.AttachmentDrawDistance = 10000
ENT.LabelDrawDistance = 150

ENT.SpawnOffset = Vector(0, 0, 25) -- world-space offset applied 0.1s after spawning

ENT.CannonBarrelClass = "sci_pointshop_emplacement_cannon"
ENT.BarrelOffset = Vector(15, 0, 10)

if SERVER then
    function ENT:Initialize()
        -- UI base handles model, material, bone scale, physics, mass, use menu,
        -- health (+ networking) and the regen timer
        self.BaseClass.Initialize(self)

        self:SpawnBarrel()
        constraint.Keepupright(self, Angle(0, 0, 0), 0, 500)
    end

    function ENT:Use(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return end

        -- Make sure the chassis is free to move before grabbing it
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:EnableMotion(true)
            phys:Wake()
        end

        ply:PickupObject(self)
    end

    function ENT:SpawnBarrel()
        if IsValid(self.CannonBarrel) then return end

        local barrel = ents.Create(self.CannonBarrelClass)
        if not IsValid(barrel) then return end

        local pos = self:GetPos()
            + self:GetUp() * self.BarrelOffset.z
            + self:GetForward() * self.BarrelOffset.x
            + self:GetRight() * self.BarrelOffset.y

        barrel:SetPos(pos)
        barrel:SetAngles(self:GetAngles())
        barrel:Spawn()
        barrel:SetParent(self)

        barrel.Chassis = self
        self.CannonBarrel = barrel
    end

    ---------------------------------------------------------------------
    -- Health
    -- The UI base's OnTakeDamage handles damage + NW sync and calls
    -- OnDestroyed when health hits 0.
    ---------------------------------------------------------------------
    function ENT:OnDestroyed(dmginfo)
        self:Destroy()
    end

    function ENT:Destroy()
        if self._destroyed then return end
        self._destroyed = true

        local fx = EffectData()
        fx:SetOrigin(self:GetPos())
        util.Effect("Explosion", fx)

        -- OnRemove takes the barrel with it
        self:Remove()
    end

    function ENT:PhysicsCollide(data, phys)
        if data.DeltaTime > 0.2 and data.Speed > 50 then
            local sounds = self.CollideSounds or {
                "player/footsteps/gravel1.wav",
                "player/footsteps/gravel2.wav",
                "player/footsteps/gravel3.wav",
                "player/footsteps/gravel4.wav"
            }
            self:EmitSound(sounds[math.random(#sounds)], 90, math.random(50, 75))
        end
    end

    function ENT:OnRemove()
        -- UI base cancels the decay and health regen timers
        if self.BaseClass and self.BaseClass.OnRemove then
            self.BaseClass.OnRemove(self)
        end

        if self._removing then return end
        self._removing = true

        -- Erase the barrel
        local barrel = self.CannonBarrel
        if IsValid(barrel) and not barrel._removing then
            barrel:Remove()
        end
    end
end
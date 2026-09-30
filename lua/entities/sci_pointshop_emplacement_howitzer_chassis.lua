AddCSLuaFile()

ENT.Base = "sci_pointshop_entity_base_ui"
ENT.Type = "anim"
ENT.PrintName = "Howitzer Chassis"
ENT.Category = "Pointshop Entities"
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.BaseModel = "models/hunter/blocks/cube3x3x05.mdl"
ENT.BaseMaterial = "models/effects/intro_tearshape"
ENT.BoneScale = Vector(1, 1, 1)
ENT.IconPath = "entities/sci_pointshop_emplacement_howitzer_chassis.png"
ENT.IconOffset = Vector(0, 0, 55)
ENT.CustomMass = 200

-- The UI base defaults to a 300s decay timer; the cannon must persist
ENT.Decaytime = -1

-- Health (handled entirely by the UI base: NW sync, damage, regen timer)
ENT.MaxHealth = 20000
ENT.HealthRegen = 10000

ENT.CollideSounds = {
    "physics/metal/weapon_impact_hard1.wav",
    "physics/metal/weapon_impact_hard2.wav",
    "physics/metal/weapon_impact_hard3.wav"
}

ENT.Attachments = {
    { Model = "models/props_phx/gears/bevel90_24.mdl", Pos = Vector(0, 0, -10), Angle = Angle(0, 180, 0), Color = Color(80, 90, 30), Material = "metal5", AxisScale = Vector(2.5, 2.5, 2) },

    { Model = "models/mechanics/robotics/claw2.mdl", Pos = Vector(65, -50, -5), Angle = Angle(0, 110, 0), Color = Color(80, 90, 30), Material = "metal5", AxisScale = Vector(0.7, 1.75, 2) },
    { Model = "models/mechanics/robotics/claw2.mdl", Pos = Vector(-55, -55, 12), Angle = Angle(-5, 90, -90), Color = Color(80, 90, 30), Material = "metal5", AxisScale = Vector(0.7, 1.5, 2) },

    { Model = "models/mechanics/robotics/claw2.mdl", Pos = Vector(65, 50, -5), Angle = Angle(0, 110, 180), Color = Color(80, 90, 30), Material = "metal5", AxisScale = Vector(0.7, 1.75, 2) },
    { Model = "models/mechanics/robotics/claw2.mdl", Pos = Vector(-55, 55, 12), Angle = Angle(5, 90, -90), Color = Color(80, 90, 30), Material = "metal5", AxisScale = Vector(0.7, 1.5, 2) },

    { Model = "models/props_lab/rotato.mdl", Pos = Vector(0, 0, 10), Angle = Angle(0, 0, 0), Color = Color(80, 90, 30), Material = "metal5", AxisScale = Vector(7.5, 12.5, 7.5) },
}

ENT.AttachmentDrawDistance = 10000
ENT.LabelDrawDistance = 150

ENT.SpawnOffset = Vector(0, 0, 25) -- world-space offset applied 0.1s after spawning

ENT.CannonBarrelClass = "sci_pointshop_emplacement_howitzer"
ENT.BarrelOffset = Vector(15, -10, -40)
ENT.BarrelAngleOffset = Angle(0, 180, 0) -- (pitch, yaw, roll) applied relative to the chassis angles

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

        -- Apply the offset in the chassis' local space so it follows its orientation
        local _, ang = LocalToWorld(vector_origin, self.BarrelAngleOffset, self:GetPos(), self:GetAngles())
        barrel:SetAngles(ang)
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
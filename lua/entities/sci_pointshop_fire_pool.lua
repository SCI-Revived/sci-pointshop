AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "sci_pointshop_entity_base_noui"

ENT.PrintName = "Fire Pool"
ENT.Author = "Paloma"
ENT.Category = "Pointshop Entities"
ENT.Spawnable = false
ENT.AdminOnly = false

ENT.BaseModel = "models/props_junk/garbage_bag001a.mdl"
ENT.BaseMaterial = "models/effects/intro_tearshape"
ENT.BaseColor = Color(255, 170, 0, 15)
ENT.BoneScale = Vector(0.1, 0.1, 0.1)

ENT.AttachmentDrawDistance = 1
ENT.LabelDrawDistance = 1
ENT.IconPath = "entities/ery_mat_trappedsoul.png"

ENT.CollideSounds = {
    "ambient/fire/mtov_flame2.wav"
}

ENT.Attachments = {}

if SERVER then

    function ENT.Initialize(self)
        self.FireSound = CreateSound(self, "ambient/fire/firebig.wav")
        self.FireSound:Play()

        self:SetModel(
            self.BaseModel or "models/hunter/blocks/cube025x025x025.mdl"
        )
        self:SetMaterial(
            self.BaseMaterial or "hunter/myplastic"
        )
        self:SetColor(
            self.BaseColor or Color(255, 255, 255, 255)
        )

        self:ManipulateBoneScale(
            0,
            self.BoneScale or Vector(1, 1, 1)
        )

        self.CollideSounds =
            self.CollideSounds or self:GetTable().CollideSounds

        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

        local physObj = self:GetPhysicsObject()

        timer.Simple(0.01, function()
            if IsValid(physObj) then
                physObj:SetMass(5)
                physObj:Wake()
            end
        end)

        -- Fire pools last for 10 seconds.
        timer.Simple(10, function()
            if IsValid(self) then
                self:Remove()
            end
        end)
    end

    function ENT.CanTool(...)
        return false
    end

    function ENT.PhysgunPickup(...)
        return false
    end

    function ENT.PhysicsCollide(self, collisionData, ...)
        if collisionData.DeltaTime > 0.2
            and collisionData.Speed > 50 then

            local collideSounds =
                self.CollideSounds
                or {"ambient/fire/mtov_flame2.wav"}

            self:EmitSound(
                collideSounds[math.random(#collideSounds)],
                90,
                math.random(90, 110)
            )
        end
    end

    function ENT.Think(self)
        if CurTime() >= (self.NextBurn or 0) then
            self.NextBurn = CurTime() + 0.5

            local origin = self:GetPos()
            local burnRadius = 140

            for _, entity in ipairs(ents.FindInSphere(origin, burnRadius)) do
                if IsValid(entity)
                    and entity ~= self
                    and entity:GetPos():DistToSqr(origin) <= burnRadius * burnRadius then

                    if entity:IsWorld() then
                        continue
                    end

                    local damageInfo = DamageInfo()
                    damageInfo:SetDamage(2)
                    damageInfo:SetDamageType(DMG_BURN)
                    damageInfo:SetAttacker(self)
                    damageInfo:SetInflictor(self)

                    entity:TakeDamageInfo(damageInfo)

                    if not entity:IsOnFire() and entity.Ignite then
                        entity:Ignite(0.51)
                    end
                end
            end
        end

        self:NextThink(CurTime())
        return true
    end

end

if CLIENT then

    function ENT.Think(self)
        if CurTime() >= (self.NextParticle or 0) then
            self.NextParticle = CurTime() + 0.02

            if not self.Emitter then
                self.Emitter = ParticleEmitter(self:GetPos(), false)
            end

            for particleIndex = 1, 2, 1 do
                local particlePos =
                    self:GetPos()
                    + Vector(
                        math.Rand(-75, 75),
                        math.Rand(-75, 75),
                        3
                    )

                local isFlame = particleIndex <= 1
                local particle

                if isFlame then
                    particle = self.Emitter:Add(
                        "particles/flamelet" .. math.random(1, 5),
                        particlePos
                    )
                else
                    particle = self.Emitter:Add(
                        "particle/smokesprites_000" .. math.random(1, 9),
                        particlePos
                    )
                end

                if not particle then
                    continue
                end

                local velocity =
                    Vector(
                        math.Rand(-50, 50),
                        math.Rand(-50, 50),
                        math.Rand(-5, 25)
                    ) * 2

                particle:SetVelocity(velocity)
                particle:SetDieTime(math.Rand(3, 4.5))
                particle:SetStartAlpha(math.Rand(220, 255))
                particle:SetEndAlpha(0)
                particle:SetStartSize(math.Rand(15, 25))
                particle:SetEndSize(math.Rand(10, 20))
                particle:SetRoll(math.Rand(0, 360))
                particle:SetRollDelta(math.Rand(-0.3, 0.3))

                if isFlame then
                    particle:SetColor(
                        255,
                        math.random(150, 255),
                        100
                    )
                    particle:SetGravity(Vector(0, 0, 15))
                else
                    particle:SetColor(50, 50, 50)
                    particle:SetGravity(Vector(0, 0, 90))
                end

                particle:SetAirResistance(100)
                particle:SetCollide(false)
            end
        end

        return true
    end

end

function ENT.OnRemove(self)
    if self.FireSound then
        self.FireSound:Stop()
        self.FireSound = nil
    end

    if self.Emitter then
        self.Emitter:Finish()
        self.Emitter = nil
    end
end
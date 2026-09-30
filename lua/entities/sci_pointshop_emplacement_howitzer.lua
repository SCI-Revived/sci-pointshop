AddCSLuaFile()

ENT.Base = "sci_pointshop_entity_base_ui"
ENT.Type = "anim"
ENT.PrintName = "Howitzer Barrel"
ENT.Category = "Pointshop Entities"
ENT.Spawnable = false
ENT.AdminOnly = false

ENT.BaseModel = "models/thedoctor/howitzer/howitzer.mdl"
ENT.BaseMaterial = ""
ENT.BoneScale = Vector(1, 1, 1)
ENT.IconOffset = Vector(-70, 0, 160)
ENT.IconPath = "entities/sci_pointshop_emplacement_howitzer_chassis.png"

ENT.AttachmentDrawDistance = 10000
ENT.LabelDrawDistance = 250

ENT.ControlWeaponClass = "ery_control_emplacement"
ENT.ControlDistance = 75

-- Where the operator stands, relative to the barrel's origin, using the
-- barrel's yaw only (so the spot doesn't swing around as the barrel pitches).
-- x = forward (negative = behind), y = right (positive = right), z = up.
-- Flip the sign of y if the spot ends up on the wrong side.
ENT.OperatorOffset = Vector(20, -50, 70)

-- Where shells are dropped to be loaded, relative to the barrel (full pitch
-- and yaw, so it follows the breech as the barrel elevates). Negative x is
-- the rear/breech end.
ENT.BreechLoadOffset = Vector(70, 0, 90)
ENT.BreechLoadRadius = 50

-- Where fired shells spawn, relative to the barrel (full pitch and yaw).
ENT.MuzzleOffset = Vector(-330, -12, 105)

-- How fast the barrel elevates/depresses, in degrees per second
ENT.PitchSpeed = 12

-- The UI base defaults to a 300s decay timer; the cannon must persist
ENT.Decaytime = -1

-- Health (values read by the UI base's client-side bar and by Regenerate below)
ENT.MaxHealth = 1000
ENT.HealthRegen = 1

ENT.CollideSounds = {
    "physics/metal/metal_canister_impact_soft1.wav",
    "physics/metal/metal_canister_impact_soft2.wav",
    "physics/metal/metal_canister_impact_soft3.wav"
}

local METAL = "models/props_canal/metalwall005b"
local GREY = Color(135, 135, 135)

-- NOTE: the new helper reads "Pos" (the old helper used "Position")
ENT.Attachments = {

}

-- Deprecated table from the Erythurgy version of the cannon.
ENT.AmmoConversion = {
    ery_ent_mortarshell       = "ery_ns_mortarshell",
    ery_ent_mortarshellap     = "ery_ns_mortarshellap",
    ery_ent_mortarshellfire   = "ery_ns_mortarshellfire",
    ery_ent_mortarshellpoison = "ery_ns_mortarshellpoison"
}

local GB_PREFIX = "gb5_"

-- Muzzle velocity (units/s) for GBombs at full propellant force (level 5)
ENT.GBombLaunchSpeed = 7500

-- Seconds after firing before a GBomb that hasn't exploded is force-detonated
ENT.FiredFuseTime = 30

-- Minimum speed (units/s) for a fired GBomb to detonate on impact, and a short
-- grace period after firing so it doesn't blow up on the muzzle/cannon itself
ENT.FiredImpactMinSpeed = 5
ENT.FiredImpactGrace = 0.75

-- Entity classes that can NOT be loaded into the cannon (checked against the
-- loose entity's class, before any conversion). Add classes as [class] = true.
ENT.ExcludedAmmo = {
	["gb5_cp_annie"] = true,
	["gb5_cp_anniebase"] = true,
	["gb5_nuclear_davy_launcher"] = true,
	["gb5_nuclear_davy_tripod"] = true,
	["gb5_cp_howitzer_can"] = true,
	["gb5_nuclear_c_tritium"] = true,
	["gb5_proj_icbm_wh"] = true,
	["gb5_nuclear_initiator"] = true,
	["gb5_nuclear_c_b1"] = true,
	["gb5_nuclear_c_h1"] = true,
	["gb5_nuclear_c_plutonium"] = true,
	["gb5_nuclear_c_uranium"] = true,
	["gb5_m_clustermine"] = true,
	["gb5_m_clustermine_2"] = true,
	["gb5_m_clustermine_fraper_ad"] = true,
	["gb5_m_schrapnel_mine"] = true,
	["gb5_misc_tower_01"] = true,
	["gb5_misc_tower_02"] = true,
	["gb5_proj_icbm"] = true,
	["gb5_proj_icbm_big"] = true,
	["gb5_proj_v2_small"] = true,
	["gb5_nuclear_clusternuke"] = true,
	["gb5_nuclear_fatman"] = true,
	["gb5_nuclear_trinity"] = true,
	["gb5_nuclear_ivymike"] = true,
	["gb5_radbarrel"] = true,
	["gb5_nuclear_tsarbomba"] = true,
	["gb5_proj_pho-torp"] = true,
}

local function IsGBombClass(class)
    return isstring(class) and string.sub(class, 1, #GB_PREFIX) == GB_PREFIX
end

-- Returns the class to fire for a loose entity class, or nil if not loadable.
-- GBombs5 entities (gb5_*) are loaded as-is.
function ENT:GetAmmoClass(class)
    if self.ExcludedAmmo and self.ExcludedAmmo[class] then
        return nil
    end
    if self.AmmoConversion[class] then
        return self.AmmoConversion[class]
    end
    if IsGBombClass(class) then
        return class
    end
    return nil
end

-- World position the operator should stand at (yaw-only basis, so it
-- stays put while the barrel pitches up and down)
function ENT:GetOperatorPos()
    local off = self.OperatorOffset
    local yawAng = Angle(0, self:GetAngles().y, 0)
    return self:GetPos()
        + yawAng:Forward() * off.x
        + yawAng:Right() * off.y
        + yawAng:Up() * off.z
end

-- World position of the breech, where shells are dropped to load
function ENT:GetBreechLoadPos()
    local off = self.BreechLoadOffset
    return self:GetPos()
        + self:GetForward() * off.x
        + self:GetRight() * off.y
        + self:GetUp() * off.z
end

-- World position where fired shells spawn
function ENT:GetMuzzlePos()
    local off = self.MuzzleOffset
    return self:GetPos()
        + self:GetForward() * off.x
        + self:GetRight() * off.y
        + self:GetUp() * off.z
end

local THINK_INTERVAL = 0.05

if SERVER then
    -- Intentionally does not call the base Initialize: the barrel is parented
    -- to the chassis and has no physics object of its own. That means the
    -- health values the UI base would normally set up have to be set here.
    function ENT:Initialize()
        self:SetModel(self.BaseModel)
        self:SetMaterial(self.BaseMaterial)
        self:ManipulateBoneScale(0, self.BoneScale)
        self:SetUseType(SIMPLE_USE)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

        self:SetMaxHealth(self.MaxHealth)
        self:SetHealth(self.MaxHealth)
        self:SetNWInt("EryHealth", self:Health())
        self:SetNWInt("EryMaxHealth", self:GetMaxHealth())
        self.NextRegen = CurTime() + 1

        self.LaunchForceLevel = 5
        self:SetNWInt("LaunchForceLevel", self.LaunchForceLevel or 5)

        self.NextThinkTime = CurTime()
        self.ControlledBy = nil
        self.LoadedAmmoClass = nil
        self:SetNWString("LoadedAmmoClass", "")
    end

    -- The UI base's Use() opens the button menu, which this entity never
    -- builds (it skips the base Initialize). Go straight to OnUse instead.
    function ENT:Use(activator)
        self:OnUse(activator)
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

        -- OnRemove takes the chassis with it
        self:Remove()
    end

    -- The base regen timer is only created by the base Initialize, so the
    -- barrel regenerates from Think and keeps the NW value in sync itself.
    function ENT:Regenerate()
        local regen = self.HealthRegen or 0
        if regen <= 0 then return end

        local now = CurTime()
        if now < (self.NextRegen or 0) then return end
        self.NextRegen = now + 1

        local maxHP = self:GetMaxHealth()
        if self:Health() < maxHP then
            local newHP = math.min(self:Health() + regen, maxHP)
            self:SetHealth(newHP)
            self:SetNWInt("EryHealth", newHP)
        end
    end

    function ENT:OnRemove()
        if self.BaseClass and self.BaseClass.OnRemove then
            self.BaseClass.OnRemove(self)
        end

        if self._removing then return end
        self._removing = true

        -- Release the operator
        if IsValid(self.ControlledBy) then
            self.ControlledBy:StripWeapon(self.ControlWeaponClass)
            self.ControlledBy._EryMountedCannon = nil
            self.ControlledBy = nil
        end

        -- Erase the chassis
        local chassis = self.Chassis
        if IsValid(chassis) and not chassis._removing then
            chassis:Remove()
        end
    end

    ---------------------------------------------------------------------
    -- Control
    ---------------------------------------------------------------------
    function ENT:OnUse(activator)
        if not IsValid(activator) or not activator:IsPlayer() then return end

        -- Using it again while controlling releases the cannon
        if self.ControlledBy == activator then
            activator:StripWeapon(self.ControlWeaponClass)
            activator._EryMountedCannon = nil
            self.ControlledBy = nil
            return
        end

        -- Someone else is already controlling it
        if IsValid(self.ControlledBy) then return end

        activator:Give(self.ControlWeaponClass)
        activator:SelectWeapon(self.ControlWeaponClass)
        self.ControlledBy = activator
        activator._EryMountedCannon = self
    end

    function ENT:Think()
        self:Regenerate()

        if not IsValid(self.ControlledBy) then
            self.ControlledBy = nil
            self:NextThink(CurTime() + THINK_INTERVAL)
        else
            local ply = self.ControlledBy
            local weapon = ply:GetActiveWeapon()
            local operatorPos = self:GetOperatorPos()
            local distSqr = operatorPos:DistToSqr(ply:GetPos())

            -- Release control if weapon was swapped or player walked away
            if not IsValid(weapon)
                or weapon:GetClass() ~= self.ControlWeaponClass
                or distSqr > self.ControlDistance ^ 2 then

                ply:StripWeapon(self.ControlWeaponClass)
                self.ControlledBy = nil
                ply._EryMountedCannon = nil
                self:NextThink(CurTime() + THINK_INTERVAL)
                return true
            end

            -- Aim: pitch follows the player (clamped), yaw stays fixed
            local eyeAng = ply:EyeAngles()
            local curAng = self:GetAngles()
            local targetPitch = -math.Clamp(eyeAng.p, -80, 10)
            local maxStep = self.PitchSpeed * THINK_INTERVAL
            local diff = math.AngleDifference(targetPitch, curAng.p)
            local newPitch = curAng.p + math.Clamp(diff, -maxStep, maxStep)
            self:SetAngles(Angle(newPitch, curAng.y, 0))
        end

        -- Auto-load a shell dropped at the breech (rear of the barrel)
        if not self.LoadedAmmoClass then
            local loadPos = self:GetBreechLoadPos()
            for _, ent in ipairs(ents.FindInSphere(loadPos, self.BreechLoadRadius)) do
                if not IsValid(ent) then continue end
                if ent.EryCannonFired then continue end -- already fired, can't be reloaded

                local converted = self:GetAmmoClass(ent:GetClass())
                if converted then
                    self.LoadedAmmoClass = converted
                    self:SetNWString("LoadedAmmoClass", converted)
                    ent:EmitSound("items/ammo_pickup.wav", 75, 100)
                    self:EmitSound("physics/metal/metal_barrel_impact_soft" .. math.random(1, 4) .. ".wav", 75, math.random(95, 105))
                    ent:Remove()
                    break
                end
            end
        end

        self:NextThink(CurTime() + THINK_INTERVAL)
        return true
    end

    -- Cycles force level: 5 -> 1 -> 2 -> 3 -> 4 -> 5
    function ENT:CycleLaunchForce()
        local nextLevel = { [5] = 1, [1] = 2, [2] = 3, [3] = 4, [4] = 5 }
        self.LaunchForceLevel = nextLevel[self.LaunchForceLevel or 5] or 5
        self:SetNWInt("LaunchForceLevel", self.LaunchForceLevel)
        self:EmitSound("weapons/slam/mine_mode.wav", 75, math.random(60, 80))
    end

    function ENT:FireShell()
        -- Nothing loaded: dry-fire click
        if not self.LoadedAmmoClass then
            self:EmitSound("physics/metal/metal_grenade_impact_soft" .. math.random(1, 3) .. ".wav", 75, math.random(50, 75))
            return
        end

        local shell = ents.Create(self.LoadedAmmoClass)
        if not IsValid(shell) then return end

        local muzzlePos = self:GetMuzzlePos()

        shell:SetPos(muzzlePos)
        shell:SetAngles(self:GetAngles())
        shell:SetOwner(self.ControlledBy or self)
        shell:Spawn()
        shell:Activate()

        -- GBombs5: arm immediately. Arm() only sets Armed after a
        -- timer.Simple(ArmDelay), so zero the delay first and also flag the
        -- bomb as armed right now so impacts on the very first ticks count.
        -- Arm() still runs so Timed bombs get their fuse started.
        if IsGBombClass(self.LoadedAmmoClass) and isfunction(shell.Arm) then
            local st = shell:GetTable()
            if not st.Exploded and not st.Armed and not st.Used then
                if shell.ActivationSound then
                    shell:EmitSound(shell.ActivationSound)
                end
                shell.ArmDelay = 0
                shell:Arm()
                st.Armed = true
                st.Arming = false
            end
        end

        -- Detonate on physics impact. A callback is used (rather than
        -- overriding PhysicsCollide) so the bomb's own collision logic stays
        -- intact. The explosion is deferred via EnqueueExplosion (same as the
        -- gb5 base) because bombs can spawn physics entities in Explode().
        if IsGBombClass(self.LoadedAmmoClass) and isfunction(shell.Explode) then
            local cannon = self
            local fireTime = CurTime()

            shell:AddCallback("PhysicsCollide", function(ent, data)
                if not IsValid(ent) or ent.Exploded or ent.EryImpactQueued then return end
                if CurTime() - fireTime < cannon.FiredImpactGrace then return end
                if data.Speed < cannon.FiredImpactMinSpeed then return end

                -- Ignore the cannon itself, its chassis, and the blast-safe helper
                local hit = data.HitEntity
                if IsValid(hit) then
                    if hit == cannon or hit == cannon.Chassis then return end
                    if hit:GetClass() == "ery_ns_explosionsafe" then return end
                end

                ent.EryImpactQueued = true

                if isfunction(ent.EnqueueExplosion) then
                    ent:EnqueueExplosion()
                else
                    timer.Simple(0, function()
                        if not IsValid(ent) or ent.Exploded then return end
                        ent.Exploded = true
                        ent:Explode()
                    end)
                end
            end)
        end

        -- Flag the shell as fired so the auto-loader won't pick it up again,
        -- and force a detonation after FiredFuseTime if it's still around.
        -- Mirrors the gb5 base: set Exploded first, then call Explode()
        -- (Explode() bails out unless Exploded is true, and removes the bomb).
        shell.EryCannonFired = true

        if IsGBombClass(self.LoadedAmmoClass) and isfunction(shell.Explode) then
            timer.Simple(self.FiredFuseTime, function()
                if not IsValid(shell) then return end
                if shell.Exploded then return end

                shell.Exploded = true
                shell:Explode()

                -- Explode() should remove the bomb itself, but make sure
                -- it's really gone
                if IsValid(shell) then
                    shell:Remove()
                end
            end)
        end

        local safe = ents.Create("ery_ns_explosionsafe")
        safe:SetPos(muzzlePos)
        safe:Spawn()

        -- Recoil / shockwave
        local blast = ents.Create("env_physexplosion")
        if IsValid(blast) then
            blast:SetPos(self:GetPos())
            blast:SetKeyValue("magnitude", 150)
            blast:SetKeyValue("radius", 500)
            blast:SetKeyValue("spawnflags", 3)
            blast:Spawn()
            blast:Fire("Explode", "", 0)
            blast:Fire("Kill", "", 0.1)
        end

        local fx = EffectData()
        fx:SetOrigin(muzzlePos)
        util.Effect("Explosion", fx)

        local phys = shell:GetPhysicsObject()
        if IsValid(phys) then
            local level = self.LaunchForceLevel or 5

            if IsGBombClass(self.LoadedAmmoClass) then
                -- GBombs are heavy, so a single-tick force barely moves them.
                -- Set the velocity directly so speed doesn't depend on mass
                -- (and impact fuses see a real collision speed).
                phys:EnableMotion(true)
                phys:EnableGravity(true)
                phys:Wake()
                phys:SetVelocityInstantaneous(-self:GetForward() * self.GBombLaunchSpeed * (level / 5))
            else
                phys:ApplyForceCenter((self:GetForward() * 20000) * (level / 5))
            end
        end

        self:EmitSound("ambient/explosions/explode_9.wav", 120, math.random(90, 150))

        -- Concussion for nearby players
        for _, ent in ipairs(ents.FindInSphere(self:GetPos(), 250)) do
            if ent:IsPlayer() and ent:Alive() then
                ent:ViewPunch(Angle(math.random(-5, 5), math.random(-5, 5), 0))
                ent:ApplyEffect("Concussion", 1)
                ent:ApplyEffect("Slowed", 1, 75)
            end
        end

        self.LoadedAmmoClass = nil
        self:SetNWString("LoadedAmmoClass", "")
    end

    -- Ejects the loaded shell back out as its loose item form
    function ENT:EmptyShell()
        if not self.LoadedAmmoClass then return end

        local looseClass
        for itemClass, firedClass in pairs(self.AmmoConversion) do
            if firedClass == self.LoadedAmmoClass then
                looseClass = itemClass
                break
            end
        end
        -- GBombs5 entities are loaded as-is, so they eject as themselves
        if not looseClass and IsGBombClass(self.LoadedAmmoClass) then
            looseClass = self.LoadedAmmoClass
        end
        if not looseClass then return end

        local dropPos = self:GetPos() + self:GetForward() * -60 + self:GetUp() * 30

        local item = ents.Create(looseClass)
        if not IsValid(item) then return end

        item:SetPos(dropPos)
        item:SetAngles(self:GetAngles())
        item:Spawn()

        self:EmitSound("physics/metal/metal_grenade_impact_soft" .. math.random(1, 3) .. ".wav", 75, math.random(50, 75))

        self.LoadedAmmoClass = nil
        self:SetNWString("LoadedAmmoClass", "")
    end

    function ENT:CanTool() return false end
    function ENT:PhysgunPickup() return false end
end

if CLIENT then
    -- The base Draw() handles DrawModel + attachments, then calls this.
    -- Draws the base icon / name / health bar (only while looking at the
    -- barrel), then the cannon readout, which stays visible within range so
    -- the operator can see it while aiming elsewhere.
    function ENT:DrawLabel()
        local ply = LocalPlayer()
        if not IsValid(ply) then return false end

        -- Icon, name and health bar from the UI base
        self.BaseClass.DrawLabel(self)

        local labelPos = self:GetPos() + self:GetUp() * 90 + self:GetForward() * -40 + self:GetRight() * -80
        if labelPos:DistToSqr(ply:GetPos()) > (self.LabelDrawDistance or 300) ^ 2 then return false end

        local labelAng = Angle(0, ply:EyeAngles().y - 90, 90)

        local ammoClass = self:GetNWString("LoadedAmmoClass", "")
        local ammoName = "None"
        if ammoClass ~= "" then
            local stored = scripted_ents.GetStored(ammoClass)
            if stored and stored.t and stored.t.PrintName then
                ammoName = stored.t.PrintName
            else
                ammoName = ammoClass
            end
        end

        local ang = self:GetAngles()
        local pitch = math.Round(ang.p, 1)
        local yaw = math.Round(ang.y, 1)
        local force = self:GetNWInt("LaunchForceLevel", 5)

        cam.Start3D2D(labelPos, labelAng, 0.1)
            draw.SimpleText("Ammo: " .. ammoName, "EryMatWorld", 150, -30, color_white, TEXT_ALIGN_CENTER)
            draw.SimpleText("Propellant Force: " .. force, "EryMatWorld", 150, 0, color_white, TEXT_ALIGN_CENTER)
            draw.SimpleText("Pitch: " .. pitch, "EryMatWorld", -150, -30, color_white, TEXT_ALIGN_CENTER)
            draw.SimpleText("Yaw: " .. yaw, "EryMatWorld", -150, 0, color_white, TEXT_ALIGN_CENTER)
        cam.End3D2D()

        return true
    end
end
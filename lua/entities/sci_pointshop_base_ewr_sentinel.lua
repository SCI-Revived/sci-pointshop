AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "sci_pointshop_entity_base_ui"

ENT.PrintName = "Sentinel"
ENT.Author = "Paloma"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "Pointshop Entities"

ENT.IconPath = "entities/sci_pointshop_base_ewr_sentinel.png"
ENT.IconOffset = Vector(120, 0, -15)

-- Placeholder model: swap freely.
ENT.BaseModel = "models/hunter/blocks/cube4x4x4.mdl"
ENT.BaseMaterial = "models/effects/intro_tearshape"
ENT.BaseColor = Color(80, 90, 100, 255)
ENT.BoneScale = Vector(1, 1, 1)

-- Intentionally empty: this entity has no attachments, but the
-- base class may still expect the table to exist.
ENT.Attachments = {}

ENT.LabelDrawDistance = 300
ENT.Decaytime = -1

ENT.CableOffset = Vector(0, 0, -80)

ENT.MaxHealth = 1250
ENT.HealthRegen = 5
ENT.CustomMass = 400

ENT.SpawnOffset = Vector(0, 0, 100) -- world-space offset applied 0.1s after spawning

ENT.CollideSounds = {
	"physics/metal/metal_box_impact_bullet1.wav",
	"physics/metal/metal_box_impact_bullet2.wav",
	"physics/metal/metal_box_impact_bullet3.wav",
}

---------------------------------------------------------
-- Sentinel settings
---------------------------------------------------------

-- Targeting (unchanged in spirit from the interceptor)
ENT.DetectionRadius = 12000
ENT.MinTargetDistance = 300     -- dead zone around the gun
ENT.MinTargetSpeed = 50       -- ignore anything slower than this
ENT.ScanInterval = 0.25         -- how often to look for / re-rank targets

ENT.DetectionSphereColor = Color(255, 160, 40, 15)
ENT.DetectionSphereColorWire = Color(255, 160, 40, 200)

ENT.DeadZoneSphereColor = Color(255, 60, 60, 20)
ENT.DeadZoneSphereColorWire = Color(255, 60, 60, 200)

ENT.SphereDrawDistance = 26000

ENT.TargetClassPrefix = "gb5_"
ENT.TARGET_PRIORITY_PLAYER = 1
ENT.TARGET_PRIORITY_PREFIXED = 2

-- Gun
ENT.MuzzleOffset = Vector(0, 0, 40)  -- local to the entity
ENT.FireSound = "apc_fire"
ENT.FireDelay = 0.1                  -- seconds between shots
ENT.MagazineSize = 75
ENT.ReloadDuration = 4               -- seconds
ENT.Spread = 0.35                     -- degrees, random cone half-angle

-- Projectile (passed to simfphys.FirePhysProjectile)
ENT.ProjectileSpeed = 11000          -- units/second; used for lead calculation
ENT.ProjectileDamage = 50
ENT.ProjectileForce = 1
ENT.ProjectileSize = 7
ENT.ProjectileBlastRadius = 200
ENT.ProjectileBlastDamage = 50
ENT.ProjectileDeflectAng = 0
ENT.ProjectileBlastEffect = "simfphys_tankweapon_explosion_micro"

-- Also compensate for gravity when leading non-player targets
-- (bombs and other falling physics entities).
ENT.GravityCompensation = true

ENT.Active = true

ENT.PowerRole = "consumer"
ENT.PowerRequired = 150

if SERVER then
	util.AddNetworkString("ery_sentinel_open")
	util.AddNetworkString("ery_sentinel_set_allegiance")
	util.AddNetworkString("ery_sentinel_clear_allies")
	util.AddNetworkString("ery_sentinel_toggle")

	---------------------------------------------------------
	-- Setup
	---------------------------------------------------------

	function ENT:Initialize()
		self.BaseClass.Initialize(self)

		self:SetUseType(SIMPLE_USE)

		self:SetNW2Bool("Active", self.Active)

		self.HasPower = false
		self:SetNWBool("HasPower", false)

		-- idle -> firing -> reloading -> idle
		self.State = "idle"
		self:SetNWString("SentinelState", "idle")

		self.NextScanTime = 0
		self.NextFireTime = 0
		self.ReloadEndTime = 0

		self.CurrentTarget = NULL
		self:SetNWEntity("CurrentTarget", NULL)

		self:ReloadMagazine()

		self.Allegiance = {}

		self:AddMenuButton("configure", "Configure", function(ent, activator)
			ent:OpenConfigureMenu(activator)
		end)

		self:RefreshToggleButton()
	end

	function ENT:SetState(state)
		if self.State == state then return end
		self.State = state
		self:SetNWString("SentinelState", state)
	end

	function ENT:SetTarget(ent)
		ent = IsValid(ent) and ent or NULL

		if self.CurrentTarget ~= ent then
			self.CurrentTarget = ent
			self:SetNWEntity("CurrentTarget", ent)
		end
	end

	function ENT:ClearTarget()
		self:SetTarget(NULL)

		if self.State == "firing" then
			self:SetState("idle")
		end
	end

	function ENT:RefreshToggleButton()
		self:RemoveMenuButton("toggle_active")
		self:AddMenuButton(
			"toggle_active",
			self.Active and "Turn OFF" or "Turn ON",
			function(ent, activator)
				ent:ToggleActive()
			end
		)
	end

	function ENT:ToggleActive()
		self.Active = not self.Active
		self:SetNW2Bool("Active", self.Active)
		self:RefreshToggleButton()

		if not self.Active then
			self:ClearTarget()
		end
	end

	net.Receive("ery_sentinel_toggle", function(_, ply)
		local sentinel = net.ReadEntity()

		if not IsValid(sentinel) then return end
		if sentinel:GetClass() ~= "sci_pointshop_base_ewr_sentinel" then return end

		sentinel:ToggleActive()
	end)

	function ENT:OpenConfigureMenu(ply)
		if not IsValid(ply) or not ply:IsPlayer() then return end

		local steamID = ply:SteamID64()
		local isFriendly = self.Allegiance[steamID] == true

		net.Start("ery_sentinel_open")
			net.WriteEntity(self)
			net.WriteBool(isFriendly)
		net.Send(ply)
	end

	function ENT:SetAllegiance(ply, friendly)
		if not IsValid(ply) or not ply:IsPlayer() then return end

		local steamID = ply:SteamID64()
		self.Allegiance[steamID] = friendly and true or nil

		if friendly then
			local target = self.CurrentTarget

			if target == ply
				or (IsValid(target) and self:GetEntityOwner(target) == ply) then
				self:ClearTarget()
			end
		end

		ply:ChatPrint(
			"[Sentinel] You are now marked as "
			.. (friendly and "FRIENDLY" or "HOSTILE")
			.. " to this sentinel."
		)
	end

	function ENT:IsFriendly(ply)
		if not IsValid(ply) or not ply:IsPlayer() then return true end
		return self.Allegiance[ply:SteamID64()] == true
	end

	function ENT:ClearAllegiance()
		self.Allegiance = {}
	end

	net.Receive("ery_sentinel_set_allegiance", function(_, ply)
		local sentinel = net.ReadEntity()
		local friendly = net.ReadBool()

		if not IsValid(sentinel) then return end
		if sentinel:GetClass() ~= "sci_pointshop_base_ewr_sentinel" then return end
		if not IsValid(ply) then return end

		sentinel:SetAllegiance(ply, friendly)
	end)

	net.Receive("ery_sentinel_clear_allies", function(_, ply)
		local sentinel = net.ReadEntity()

		if not IsValid(sentinel) then return end
		if sentinel:GetClass() ~= "sci_pointshop_base_ewr_sentinel" then return end
		if not IsValid(ply) then return end

		sentinel:ClearAllegiance()
		ply:ChatPrint("[Sentinel] Allegiance list cleared -- everyone is now HOSTILE.")
	end)

	---------------------------------------------------------
	-- Power interface, called by a linked mainframe.
	---------------------------------------------------------

	function ENT:GetPowerRequired()
		if not self.Active then return 0 end
		return self.PowerRequired or 150
	end

	function ENT:SetPowered(hasPower)
		hasPower = hasPower and true or false

		if hasPower == self.HasPower then return end

		self.HasPower = hasPower
		self:SetNWBool("HasPower", hasPower)

		if not hasPower then
			self:ClearTarget()
		end
	end

	---------------------------------------------------------
	-- Detection
	---------------------------------------------------------

	-- Best-effort owner lookup for a non-player entity. Tries the
	-- common conventions in order: CPPI, the engine owner, the
	-- creator, then a few networked/plain "Owner" fields.
	function ENT:GetEntityOwner(ent)
		if ent.CPPIGetOwner then
			local owner = ent:CPPIGetOwner()
			if IsValid(owner) then return owner end
		end

		local owner = ent:GetOwner()
		if IsValid(owner) then return owner end

		if ent.GetCreator then
			owner = ent:GetCreator()
			if IsValid(owner) then return owner end
		end

		owner = ent:GetNWEntity("Owner", NULL)
		if IsValid(owner) then return owner end

		owner = ent.Owner
		if isentity(owner) and IsValid(owner) then return owner end

		return NULL
	end

	-- Players seated in a vehicle report their own GetPos()/
	-- GetVelocity() unreliably, so for a seated player every
	-- position/range/speed/LOS check (and the lead calculation)
	-- uses the vehicle instead. The player entity itself remains
	-- the target. LVS is checked first since its vehicles don't
	-- use GMod's native vehicle system.
	function ENT:GetTrackedVehicle(ent)
		if not ent:IsPlayer() then return NULL end

		if ent.lvsGetVehicle then
			local lvsVeh = ent:lvsGetVehicle()
			if IsValid(lvsVeh) then return lvsVeh end
		end

		local veh = ent:GetVehicle()
		if IsValid(veh) then return veh end

		return NULL
	end

	function ENT:GetTrackPos(ent)
		local veh = self:GetTrackedVehicle(ent)
		if IsValid(veh) then return veh:GetPos() end
		return ent:GetPos()
	end

	function ENT:GetTrackVelocity(ent)
		local veh = self:GetTrackedVehicle(ent)
		if IsValid(veh) then return veh:GetVelocity() end
		return ent:GetVelocity()
	end

	-- Whether ent is the *kind* of thing the sentinel will shoot at,
	-- independent of speed/range/LOS: a TargetClassPrefix entity, or
	-- a player who hasn't declared themselves friendly.
	function ENT:IsTargetableClass(ent)
		if ent:IsPlayer() then
			return not self:IsFriendly(ent)
		end

		local prefix = self.TargetClassPrefix or "gb5_"
		if string.sub(ent:GetClass(), 1, #prefix) ~= prefix then
			return false
		end

		-- Prefixed entities owned by a friendly player are ignored.
		-- Unowned entities remain targetable.
		local owner = self:GetEntityOwner(ent)
		if IsValid(owner) and owner:IsPlayer() and self:IsFriendly(owner) then
			return false
		end

		return true
	end

	-- A legal target is above this entity, between MinTargetDistance
	-- and DetectionRadius away, at or above MinTargetSpeed, in line
	-- of sight (brushes only), and targetable by class/allegiance.
	function ENT:IsValidTarget(ent, myPos)
		if not IsValid(ent) then return false end
		if ent == self then return false end

		-- Vehicles are never targeted directly; their occupants are.
		if ent:IsVehicle() then return false end

		if not self:IsTargetableClass(ent) then return false end

		local entPos = self:GetTrackPos(ent)

		if entPos.z <= myPos.z then return false end

		local distSqr = entPos:DistToSqr(myPos)

		if distSqr > (self.DetectionRadius or 8000)^2 then
			return false
		end

		if distSqr < (self.MinTargetDistance or 300)^2 then
			return false
		end

		if self:GetTrackVelocity(ent):Length() < (self.MinTargetSpeed or 1000) then
			return false
		end

		local tr = util.TraceLine({
			start = myPos,
			endpos = entPos,
			filter = self,
			mask = MASK_SOLID_BRUSHONLY,
		})

		if tr.Hit and tr.Fraction < 1 then return false end

		return true
	end

	-- Hostile players outrank TargetClassPrefix entities.
	function ENT:GetTargetPriority(ent)
		if ent:IsPlayer() then
			return self.TARGET_PRIORITY_PLAYER or 1
		end
		return self.TARGET_PRIORITY_PREFIXED or 2
	end

	-- Picks the entity to shoot at: highest priority tier first, then
	-- closest. `current` (the entity already being engaged) is kept as
	-- long as it is still valid and nothing of a strictly higher
	-- priority tier has appeared, so the gun doesn't flick between
	-- two similar targets every scan.
	function ENT:FindBestTarget(current)
		local myPos = self:GetPos()

		local best, bestPriority, bestDistSqr

		for _, ent in ipairs(ents.FindInSphere(myPos, self.DetectionRadius or 8000)) do
			if self:IsValidTarget(ent, myPos) then
				local priority = self:GetTargetPriority(ent)
				local distSqr = self:GetTrackPos(ent):DistToSqr(myPos)

				if not best
					or priority < bestPriority
					or (priority == bestPriority and distSqr < bestDistSqr) then
					best, bestPriority, bestDistSqr = ent, priority, distSqr
				end
			end
		end

		if IsValid(current) and self:IsValidTarget(current, myPos) then
			if not best or bestPriority >= self:GetTargetPriority(current) then
				return current
			end
		end

		return best or NULL
	end

	---------------------------------------------------------
	-- Firing
	---------------------------------------------------------

	function ENT:ReloadMagazine()
		self.AmmoLeft = self.MagazineSize or 40
		self:SetNWInt("AmmoLeft", self.AmmoLeft)
	end

	function ENT:StartReload()
		self:ClearTarget()
		self:SetState("reloading")
		self.ReloadEndTime = CurTime() + (self.ReloadDuration or 4)
	end

	function ENT:GetMuzzlePos()
		return self:LocalToWorld(self.MuzzleOffset or Vector(0, 0, 40))
	end

	-- Where to point the gun so a projectile launched from muzzlePos
	-- at ProjectileSpeed meets the target, assuming it keeps its
	-- current velocity. Solves |D + V*t| = s*t for the smallest
	-- positive t. Falls back to aiming straight at the target when
	-- there is no solution (e.g. it is faster than the projectile and
	-- running away).
	function ENT:GetAimPoint(target, muzzlePos)
		local speed = (self.ProjectileSpeed or 10000) + math.random(-1000, 1000)

		local pos = self:GetTrackPos(target)
		local vel = self:GetTrackVelocity(target)
		local d = pos - muzzlePos

		local a = vel:Dot(vel) - speed * speed
		local b = 2 * d:Dot(vel)
		local c = d:Dot(d)

		local t

		if math.abs(a) < 1e-6 then
			if math.abs(b) > 1e-6 then
				t = -c / b
			end
		else
			local disc = b * b - 4 * a * c

			if disc >= 0 then
				local root = math.sqrt(disc)
				local t1 = (-b - root) / (2 * a)
				local t2 = (-b + root) / (2 * a)

				if t1 > 0 and t2 > 0 then
					t = math.min(t1, t2)
				elseif t1 > 0 then
					t = t1
				elseif t2 > 0 then
					t = t2
				end
			end
		end

		if not t or t <= 0 then
			t = d:Length() / speed
		end

		local aimPos = pos + vel * t

		-- Falling things (bombs etc.) are still accelerating down.
		if self.GravityCompensation and not target:IsPlayer() then
			local phys = target:GetPhysicsObject()
			if IsValid(phys) and phys:IsGravityEnabled() then
				aimPos = aimPos + physenv.GetGravity() * 0.5 * t * t
			end
		end

		return aimPos
	end

	-- Fires a single projectile at target. Returns true if it was fired.
	function ENT:FireAt(target)
		if not IsValid(target) then return false end

		if not (simfphys and simfphys.FirePhysProjectile) then
			if not self.WarnedNoSimfphys then
				self.WarnedNoSimfphys = true
				print("[Sentinel] simfphys.FirePhysProjectile not found -- is simfphys installed?")
			end
			return false
		end

		local origin = self:GetMuzzlePos()
		local aimPos = self:GetAimPoint(target, origin)

		-- Random spread: a small cone around the lead direction.
		local aimAngles = (aimPos - origin):GetNormalized():Angle()
		local spread = self.Spread or 0
		aimAngles.pitch = aimAngles.pitch + math.Rand(-spread, spread)
		aimAngles.yaw = aimAngles.yaw + math.Rand(-spread, spread)

		self:EmitSound(self.FireSound or "apc_fire")

		simfphys.FirePhysProjectile({
			filter = { self },
			shootOrigin = origin,
			shootDirection = aimAngles:Forward(),
			attacker = self,
			attackingent = self,
			Damage = self.ProjectileDamage or 100,
			Force = self.ProjectileForce or 50,
			Size = self.ProjectileSize or 3,
			BlastRadius = self.ProjectileBlastRadius or 50,
			BlastDamage = self.ProjectileBlastDamage or 50,
			DeflectAng = self.ProjectileDeflectAng or 40,
			BlastEffect = self.ProjectileBlastEffect or "simfphys_tankweapon_explosion_micro",
		})

		return true
	end

	---------------------------------------------------------
	-- Think: scan while idle, shoot while a target is held, reload
	-- when the magazine runs dry. Runs every tick while engaged so
	-- the fire rate and lead stay accurate.
	---------------------------------------------------------

	function ENT:Think()
		local currentTime = CurTime()
		local engaged = false

		if self.Active and self.HasPower then
			if self.State == "reloading" then
				if currentTime >= (self.ReloadEndTime or 0) then
					self:ReloadMagazine()
					self:SetState("idle")
				end
			else
				local myPos = self:GetPos()
				local target = self.CurrentTarget

				-- Drop the current target the moment it stops being valid.
				if IsValid(target) and not self:IsValidTarget(target, myPos) then
					self:ClearTarget()
					target = NULL
				end

				if currentTime >= (self.NextScanTime or 0) then
					self.NextScanTime = currentTime + (self.ScanInterval or 0.25)

					target = self:FindBestTarget(target)
					self:SetTarget(target)
				end

				if IsValid(target) then
					engaged = true
					self:SetState("firing")

					if currentTime >= (self.NextFireTime or 0) then
						-- Accumulate so the average rate matches
						-- FireDelay despite tick quantisation.
						local delay = self.FireDelay or 0.1
						local nextFire = (self.NextFireTime or 0) + delay
						if nextFire < currentTime then nextFire = currentTime + delay end
						self.NextFireTime = nextFire

						if self:FireAt(target) then
							self.AmmoLeft = (self.AmmoLeft or 0) - 1
							self:SetNWInt("AmmoLeft", self.AmmoLeft)

							if self.AmmoLeft <= 0 then
								self:StartReload()
								engaged = false
							end
						end
					end
				elseif self.State == "firing" then
					self:SetState("idle")
				end
			end
		end

		self:NextThink(engaged and currentTime or (currentTime + 0.1))
		return true
	end

	function ENT:OnRemove()
		self.BaseClass.OnRemove(self)

		self:UnlinkMainframe()
	end
end

if CLIENT then
	function ENT:Initialize()
		self.Attachments = self.Attachments or {}
	end

	---------------------------------------------------------
	-- Configure menu (allegiance), mirroring the sentry turret's
	-- panel: allegiance status + button, plus "clear allies".
	---------------------------------------------------------

	net.Receive("ery_sentinel_open", function()
		local sentinel = net.ReadEntity()

		if not IsValid(sentinel) then return end

		local isFriendly = net.ReadBool()

		local rowHeight = 30
		local rowY = 64

		local frame = vgui.Create("DFrame")

		frame:SetTitle(sentinel.PrintName or "Sentinel")
		frame:SetSize(280, 96 + rowHeight * 2)
		frame:Center()
		frame:MakePopup()

		local statusLabel = vgui.Create("DLabel", frame)
		statusLabel:SetPos(8, 32)
		statusLabel:SetSize(frame:GetWide() - 16, 20)
		statusLabel:SetText(
			"This sentinel is currently "
			.. (isFriendly and "treating you as FRIENDLY." or "treating you as HOSTILE.")
		)
		statusLabel:SetWrap(true)
		statusLabel:SetAutoStretchVertical(true)

		local allegianceButton = vgui.Create("DButton", frame)
		allegianceButton:SetPos(8, rowY)
		allegianceButton:SetSize(frame:GetWide() - 16, rowHeight - 4)
		allegianceButton:SetText(
			isFriendly
				and "Declare myself HOSTILE"
				or "Declare myself FRIENDLY"
		)

		allegianceButton.DoClick = function()
			net.Start("ery_sentinel_set_allegiance")
				net.WriteEntity(sentinel)
				net.WriteBool(not isFriendly)
			net.SendToServer()

			frame:Close()
		end
		rowY = rowY + rowHeight

		-- Wipes the whole allegiance list, so everyone goes back to
		-- being targetable.
		local clearAlliesButton = vgui.Create("DButton", frame)
		clearAlliesButton:SetPos(8, rowY)
		clearAlliesButton:SetSize(frame:GetWide() - 16, rowHeight - 4)
		clearAlliesButton:SetText("Clear ally list (make everyone hostile)")

		clearAlliesButton.DoClick = function()
			net.Start("ery_sentinel_clear_allies")
				net.WriteEntity(sentinel)
			net.SendToServer()

			frame:Close()
		end
		rowY = rowY + rowHeight

		local closeButton = vgui.Create("DButton", frame)
		closeButton:SetPos(8, rowY)
		closeButton:SetSize(frame:GetWide() - 16, rowHeight - 4)
		closeButton:SetText("Close")

		closeButton.DoClick = function()
			frame:Close()
		end
	end)

	function ENT:DrawDetectionDome()
		local color = self.DetectionSphereColor or Color(255, 160, 40, 15)

		render.SetColorMaterial()
		render.DrawSphere(
			self:GetPos(),
			self.DetectionRadius or 8000,
			24,
			24,
			color,
			false
		)

		local colorWire = self.DetectionSphereColorWire or Color(255, 160, 40, 200)

		render.SetColorMaterial()
		render.DrawWireframeSphere(
			self:GetPos(),
			self.DetectionRadius or 8000,
			24,
			24,
			colorWire,
			false
		)

		local deadRadius = self.MinTargetDistance or 300

		if deadRadius > 0 then
			local deadColor = self.DeadZoneSphereColor or Color(255, 60, 60, 20)
			local deadColorWire = self.DeadZoneSphereColorWire or Color(255, 60, 60, 200)

			render.SetColorMaterial()
			render.DrawSphere(
				self:GetPos(),
				deadRadius,
				24,
				24,
				deadColor,
				false
			)

			render.SetColorMaterial()
			render.DrawWireframeSphere(
				self:GetPos(),
				deadRadius,
				24,
				24,
				deadColorWire,
				false
			)
		end
	end

	function ENT:IsLookingAtForDome()
		local ply = LocalPlayer()
		if not IsValid(ply) then return false end

		local maxDist = self.SphereDrawDistance or 9000
		if self:GetPos():DistToSqr(ply:GetPos()) > (maxDist * maxDist) then
			return false
		end

		local tr = util.TraceLine({
			start = ply:EyePos(),
			endpos = ply:EyePos() + ply:EyeAngles():Forward() * maxDist,
			filter = ply,
		})

		return tr.Entity == self
	end

	function ENT:Draw()
		self:DrawModel()
		self:DrawLabel() -- base class label only

		if self:IsLookingAtForDome() then
			self:DrawDetectionDome()
		end
	end
end
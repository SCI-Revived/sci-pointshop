AddCSLuaFile()

ENT.Type            = "anim"

-- Visual-only model scale per local axis (X = forward/length). Does not affect physics.
ENT.AxisScale      = Vector( 1.5, 1, 1 )

--[[
	sam_missile

	Based on lvs stinger_missile.lua, generalized so a SAM site (or anything else)
	can hand it ANY entity as a lock-on target, not just LVS vehicles.
	Also adds proximity detonation, so it doesn't need a direct physics hit
	to go off -- it'll detonate once it gets within ProximityFuse units of
	the locked target.
]]

function ENT:SetupDataTables()
	self:NetworkVar( "Bool",0, "Disabled" )
	self:NetworkVar( "Bool",1, "CleanMissile" )
	self:NetworkVar( "Bool",2, "DirtyMissile" )
	self:NetworkVar( "Entity",0, "Attacker" )
	self:NetworkVar( "Entity",1, "Inflictor" )
	self:NetworkVar( "Entity",2, "LockOn" )
	self:NetworkVar( "Float",0, "StartVelocity" )
	self:NetworkVar( "Float",1, "ProximityFuse" ) -- distance at which the missile self-detonates near its target
end

if SERVER then
	function ENT:SpawnFunction( ply, tr, ClassName )

		if not tr.Hit then return end

		local ent = ents.Create( ClassName )
		ent:SetPos( tr.HitPos + tr.HitNormal * 20 )
		ent:Spawn()
		ent:Activate()

		return ent

	end

	-- If the target is a player sitting in an LVS vehicle, the player's own
	-- velocity reads as 0 (they're seated, not actually moving themselves).
	-- In that case we want to track/lead using the vehicle's velocity instead.
	-- Returns the entity whose velocity should be used for leading purposes.
	local function GetVelocitySource( ent )
		if IsValid( ent ) and ent:IsPlayer() and isfunction( ent.lvsGetVehicle ) then
			local veh = ent:lvsGetVehicle()

			if IsValid( veh ) then
				return veh
			end
		end

		return ent
	end

	-- Solve for true time-to-intercept given relative position/velocity and
	-- missile speed, instead of naively dividing straight-line range by speed.
	--
	-- A plain `distance / speed` lead time is only correct when the target is
	-- roughly ahead of the missile. If a large part of the separation is off
	-- the target's direction of travel (e.g. the target is directly above the
	-- missile), that whole distance still gets counted toward leadTime, even
	-- though closing that vertical gap does nothing to close the target's
	-- horizontal motion. This inflates leadTime and overleads the shot.
	--
	-- Instead we solve the classic intercept quadratic:
	--   |relPos + relVel * t| = speed * t
	-- for the smallest positive t, which accounts for the actual relative
	-- geometry (all 3 axes) rather than scalar range.
	local function SolveInterceptTime( relPos, relVel, speed )
		local a = relVel:Dot( relVel ) - speed * speed
		local b = 2 * relPos:Dot( relVel )
		local c = relPos:Dot( relPos )

		-- Degenerate case: target speed == missile speed along closing axis.
		if math.abs( a ) < 1e-6 then
			if math.abs( b ) < 1e-6 then return nil end
			local t = -c / b
			if t > 0 then return t end
			return nil
		end

		local disc = b * b - 4 * a * c
		if disc < 0 then return nil end -- no real solution, e.g. target is outrunning the missile

		local sqrtDisc = math.sqrt( disc )
		local t1 = (-b - sqrtDisc) / (2 * a)
		local t2 = (-b + sqrtDisc) / (2 * a)

		-- We want the smallest positive root.
		local tMin, tMax = math.min( t1, t2 ), math.max( t1, t2 )

		if tMin > 0 then return tMin end
		if tMax > 0 then return tMax end

		return nil
	end

	function ENT:BlindFire()
		if self:GetDisabled() then return end

		local pObj = self:GetPhysicsObject()

		if IsValid( pObj ) then
			pObj:SetVelocityInstantaneous( self:GetForward() * ((self:GetStartVelocity() + 3000) * 1.5) )
		end
	end

-- Missile guidance settings.
-- Adjust these to change how aggressively the missile leads and spirals.

ENT.LeadTimeMultiplier = 1
ENT.MaxLeadTime = 1.0

-- Caps how far the predicted aim point can be pushed ahead of the target's
-- current position, as a fraction of the missile's current range to the
-- target. A flat time cap (MaxLeadTime alone) hands out the same lead
-- distance budget at close range and steep angles as it does for a clean
-- head-on shot at long range, which overleads badly up close / overhead.
-- This scales the budget down as range shrinks, independent of the time cap.
ENT.MaxLeadFraction = 0.6

ENT.SpiralRadius = 100
ENT.SpiralSpeed = 6
ENT.SpiralMinRadius = 15
ENT.SpiralDistance = 1500


function ENT:FollowTarget( followent )
	-- ============================================================
	-- MISSILE PERFORMANCE
	-- ============================================================

	local speed = (self:GetStartVelocity() + (self:GetDirtyMissile() and 3000 or 2500)) * 1.1

	-- Lower values = less maneuverable / easier to evade.
	local turnrate = (self:GetCleanMissile() or self:GetDirtyMissile()) and 100 or 65

	-- Lower values = slower response to changes in target direction.
	local steerStrength = 150

	-- How quickly unwanted angular velocity is removed.
	-- Lower = softer/slower correction.
	local angularDamping = 0.65


	-- ============================================================
	-- TARGET POSITION
	-- ============================================================

	local TargetPos = followent:LocalToWorld( followent:OBBCenter() )

	if isfunction( followent.GetMissileOffset ) then
		local Value = followent:GetMissileOffset()

		if isvector( Value ) then
			TargetPos = followent:LocalToWorld( Value )
		end
	end


	-- ============================================================
	-- LEADING
	-- ============================================================

	local targetVelocity = GetVelocitySource( followent ):GetVelocity()
	local relPos = TargetPos - self:GetPos()
	local distance = relPos:Length()

	-- Solve true intercept time from the relative geometry, rather than a
	-- naive distance/speed estimate (which overleads badly when a large
	-- part of the range is off-axis from the target's velocity, e.g. the
	-- target is above the missile).
	local leadTime = SolveInterceptTime( relPos, targetVelocity, speed )

	if not leadTime then
		-- No real intercept solution (target outrunning missile, etc).
		-- Fall back to the simple range/speed estimate.
		leadTime = distance / math.max( speed, 1 )
	end

	-- Leading is 5x stronger during the missile's first second of life,
	-- to help it correct onto an intercept course right out of the launcher.
	local age = CurTime() - (self.SpawnTime or CurTime())
	local leadMultiplier = self.LeadTimeMultiplier * (age < 1 and 5 or 1)

	-- Apply our configurable lead multiplier.
	leadTime = leadTime * leadMultiplier

	-- Prevent excessive prediction (flat time cap).
	leadTime = math.Clamp( leadTime, 0, self.MaxLeadTime )

	-- Also cap the lead *distance* as a fraction of current range. Without
	-- this, a target that's close but at a steep angle (e.g. overhead) gets
	-- the same lead time budget as a head-on shot far away, which pushes the
	-- predicted point way past where the target actually ends up. This scales
	-- the allowed lead distance down automatically as range shrinks.
	local targetSpeed = targetVelocity:Length()

	if targetSpeed > 1 then
		local maxLeadDistance = distance * self.MaxLeadFraction
		local maxLeadTimeByDistance = maxLeadDistance / targetSpeed

		leadTime = math.min( leadTime, maxLeadTimeByDistance )
	end

	-- Predict where the target will be.
	local predictedPos = TargetPos + targetVelocity * leadTime


	-- ============================================================
	-- SPIRAL FLIGHT
	-- ============================================================

	local toTarget = predictedPos - self:GetPos()
	local distanceToTarget = toTarget:Length()

	local targetDir

	if distanceToTarget > 1 then
		targetDir = toTarget:GetNormalized()
	else
		targetDir = self:GetForward()
	end

	-- Find two vectors perpendicular to the target direction.
	--
	-- These form the plane in which the missile will spiral.
	local reference = Vector(0, 0, 1)

	if math.abs( targetDir:Dot(reference) ) > 0.95 then
		reference = Vector(0, 1, 0)
	end

	local spiralRight = targetDir:Cross( reference ):GetNormalized()
	local spiralUp = spiralRight:Cross( targetDir ):GetNormalized()


	-- ============================================================
	-- SPIRAL RADIUS
	-- ============================================================

	-- The spiral is larger when the missile is far away and
	-- gradually tightens as it approaches the target.
	local radiusFraction = math.Clamp(
		distanceToTarget / self.SpiralDistance,
		0,
		1
	)

	local spiralRadius = Lerp(
		radiusFraction,
		self.SpiralMinRadius,
		self.SpiralRadius
	)


	-- ============================================================
	-- SPIRAL ROTATION
	-- ============================================================

	local spiralAngle = CurTime() * self.SpiralSpeed

	local spiralOffset =
		spiralRight * math.cos( spiralAngle ) * spiralRadius +
		spiralUp * math.sin( spiralAngle ) * spiralRadius

	-- Final point the missile attempts to steer toward.
	local pos = predictedPos + spiralOffset


	-- ============================================================
	-- STEERING
	-- ============================================================

	local pObj = self:GetPhysicsObject()

	if not IsValid( pObj ) then return end
	if self:GetDisabled() then return end

	local targetdir = (pos - self:GetPos()):GetNormalized()

	-- Convert desired direction into local missile angles.
	local AF = self:WorldToLocalAngles( targetdir:Angle() )

	-- Convert angular error into steering force.
	AF.p = AF.p * steerStrength
	AF.y = AF.y * steerStrength
	AF.r = AF.r * steerStrength

	-- Limit maximum angular velocity.
	AF.p = math.Clamp( AF.p, -turnrate, turnrate )
	AF.y = math.Clamp( AF.y, -turnrate, turnrate )
	AF.r = math.Clamp( AF.r, -turnrate, turnrate )


	-- ============================================================
	-- ANGULAR DAMPING
	-- ============================================================

	local AVel = pObj:GetAngleVelocity()

	-- Rather than instantly replacing the missile's angular
	-- velocity, gradually move it toward the desired velocity.
	local desiredAngularVelocity = Vector(
		AF.r,
		AF.p,
		AF.y
	)

	local newAngularVelocity = LerpVector(
		angularDamping,
		AVel,
		desiredAngularVelocity
	)

	pObj:AddAngleVelocity(
		newAngularVelocity - AVel
	)


	-- ============================================================
	-- FORWARD VELOCITY
	-- ============================================================

	-- Keep the missile moving at its intended speed.
	-- The direction comes from the missile's physical orientation.
	pObj:SetVelocityInstantaneous(
		self:GetForward() * speed
	)
end

	function ENT:Initialize()
		self:SetModel( "models/military2/missile/missile_barak.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetRenderMode( RENDERMODE_TRANSALPHA )
		self:PhysWake()
		local pObj = self:GetPhysicsObject()

		if IsValid( pObj ) then
			pObj:EnableGravity( false )
			pObj:SetMass( 50 )
		end

		if self:GetProximityFuse() <= 0 then
			self:SetProximityFuse( 400 )
		end

		self.SpawnTime = CurTime()

		-- Since the SAM platform can't lead on its own, it always fires straight
		-- at the target. Compensate here by snapping the missile's launch angle
		-- to the ideal intercept heading immediately.
		self:SnapToLeadAngle()
	end

	function ENT:SnapToLeadAngle()
		local Target = self:GetLockOn()
		if not IsValid( Target ) then return end

		local TargetPos = Target:LocalToWorld( Target:OBBCenter() )

		if isfunction( Target.GetMissileOffset ) then
			local Value = Target:GetMissileOffset()
			if isvector( Value ) then
				TargetPos = Target:LocalToWorld( Value )
			end
		end

		local targetVelocity = GetVelocitySource( Target ):GetVelocity()
		local relPos = TargetPos - self:GetPos()
		local distance = relPos:Length()

		local speed = (self:GetStartVelocity() + (self:GetDirtyMissile() and 3000 or 2500)) * 1.1

		local leadTime = SolveInterceptTime( relPos, targetVelocity, speed )
		if not leadTime then
			leadTime = distance / math.max( speed, 1 )
		end

		leadTime = math.Clamp( leadTime * self.LeadTimeMultiplier, 0, self.MaxLeadTime )

		-- Same distance-fraction cap as FollowTarget, so the initial snap
		-- angle doesn't overlead for close/steep-angle shots either.
		local targetSpeed = targetVelocity:Length()

		if targetSpeed > 1 then
			local maxLeadDistance = distance * self.MaxLeadFraction
			local maxLeadTimeByDistance = maxLeadDistance / targetSpeed

			leadTime = math.min( leadTime, maxLeadTimeByDistance )
		end

		local predictedPos = TargetPos + targetVelocity * leadTime
		local toTarget = predictedPos - self:GetPos()

		if toTarget:LengthSqr() > 1 then
			local leadAngle = toTarget:GetNormalized():Angle()

			self:SetAngles( leadAngle )

			local pObj = self:GetPhysicsObject()
			if IsValid( pObj ) then
				pObj:SetAngles( leadAngle )
			end
		end
	end

	function ENT:Think()
		local curtime = CurTime()
		self:NextThink( curtime )

		local Target = self:GetLockOn()
		if IsValid( Target ) then
			self:FollowTarget( Target )

			-- Proximity detonation: go off once we're close enough to the target,
			-- rather than requiring an actual physics collision.
			if not self:GetDisabled() and not self.Explode then
				local TargetPos = Target:LocalToWorld( Target:OBBCenter() )
				local dist = self:GetPos():Distance( TargetPos )

				if dist <= self:GetProximityFuse() then
					-- GB5 bomb entities expose EnqueueExplosion(), which schedules
					-- their explosion on the next tick without requiring an impact.
					local targetClass = Target:GetClass():lower()
					if string.StartWith( targetClass, "gb5_" ) and isfunction( Target.EnqueueExplosion ) then
						Target:EnqueueExplosion()
					end

					self.Explode = true
					self.ExplodeTarget = Target
				end
			end
		else
			-- No target: keep flying straight along the missile's current heading
			-- instead of just coasting, so it doesn't lose propulsion and drift
			-- (e.g. slow down from air drag) once it loses lock.
			local pObj = self:GetPhysicsObject()
			if IsValid( pObj ) then
				if not self.UnguidedDir then
					-- Lock in a direction the first time we go targetless: prefer
					-- our existing velocity's direction, falling back to facing.
					local velocity = pObj:GetVelocity()
					if velocity:LengthSqr() > 1 then
						self.UnguidedDir = velocity:GetNormalized()
					else
						self.UnguidedDir = self:GetForward()
					end
				end

				if not self.UnguidedSpeed then
					-- Lock in a fixed cruise speed ONCE (one-time 50% boost, same as
					-- before), and remember it. We deliberately do NOT re-read the
					-- physics object's live velocity magnitude on later ticks: doing
					-- so turns any tiny reduction (a graze, a physics sub-step, float
					-- error) into the new "locked in" speed permanently, letting the
					-- missile bleed off speed tick by tick until it's just drifting.
					self.UnguidedSpeed = math.max( pObj:GetVelocity():Length(), self:GetStartVelocity() + 3000 ) * 1.5
				end

				-- Keep re-applying thrust every think along the locked direction,
				-- at the fixed locked speed, so drag/friction/collisions can never
				-- bleed the missile down -- it always holds this exact velocity.
				pObj:SetVelocityInstantaneous( self.UnguidedDir * self.UnguidedSpeed )
			end
		end

		if self.MarkForRemove then
			self:Detonate()
		end

		if self.Explode then
			local Inflictor = self:GetInflictor()
			local Attacker = self:GetAttacker()

			util.BlastDamage( IsValid( Inflictor ) and Inflictor or Entity(0), IsValid( Attacker ) and Attacker or Entity(0), self:GetPos(),1000,500)

			self:Detonate()
		end

		if (self.SpawnTime + 5) < curtime then
			self:Detonate()
		end

		return true
	end

	-- Optional bonus damage cases kept from the original stinger for compatibility;
	-- harmless no-ops against anything that isn't an LVS/simfphys entity.
	local IsThisSimfphys = {
		["gmod_sent_vehicle_fphysics_base"] = true,
		["gmod_sent_vehicle_fphysics_wheel"] = true,
	}

	function ENT:PhysicsCollide( data )
		if self:GetDisabled() then
			self.MarkForRemove = true
		else
			local HitEnt = data.HitEntity

			if IsValid( HitEnt ) and not self.Explode then
				local Class = HitEnt:GetClass():lower()

				if IsThisSimfphys[ Class ] then
					local Pos = self:GetPos()

					if Class == "gmod_sent_vehicle_fphysics_wheel" then
						HitEnt = HitEnt:GetBaseEnt()
					end

					local effectdata = EffectData()
						effectdata:SetOrigin( Pos )
						effectdata:SetNormal( -self:GetForward() )
					util.Effect( "manhacksparks", effectdata, true, true )

					local dmginfo = DamageInfo()
						dmginfo:SetDamage( 1000 )
						dmginfo:SetAttacker( IsValid( self:GetAttacker() ) and self:GetAttacker() or self )
						dmginfo:SetDamageType( DMG_DIRECT )
						dmginfo:SetInflictor( self )
						dmginfo:SetDamagePosition( Pos )
					HitEnt:TakeDamageInfo( dmginfo )

					sound.Play( "Missile.ShotDown", Pos, 140)
				end

				if HitEnt.LFS or HitEnt.IdentifiesAsLFS then
					local Pos = self:GetPos()

					local effectdata = EffectData()
						effectdata:SetOrigin( Pos )
						effectdata:SetNormal( -self:GetForward() )
					util.Effect( "manhacksparks", effectdata, true, true )

					local dmginfo = DamageInfo()
						dmginfo:SetDamage( 1000 )
						dmginfo:SetAttacker( IsValid( self:GetAttacker() ) and self:GetAttacker() or self )
						dmginfo:SetDamageType( DMG_DIRECT )
						dmginfo:SetInflictor( self )
						dmginfo:SetDamagePosition( Pos )
					HitEnt:TakeDamageInfo( dmginfo )

					sound.Play( "Missile.ShotDown", Pos, 140)
				end

				-- Direct hit on ANY entity (e.g. the SAM's locked target itself) also detonates.
				if HitEnt == self:GetLockOn() then
					local hitClass = HitEnt:GetClass():lower()
					if string.StartWith( hitClass, "gb5_" ) and isfunction( HitEnt.EnqueueExplosion ) then
						HitEnt:EnqueueExplosion()
					end

					self.Explode = true
				end
			end

			-- A direct physics collision with anything solid still counts as impact detonation
			-- (matches original stinger behavior of exploding on any collide).
			self.Explode = true
		end
	end

	function ENT:BreakMissile()
		if not self:GetDisabled() then
			self:SetDisabled( true )

			local pObj = self:GetPhysicsObject()

			if IsValid( pObj ) then
				pObj:EnableGravity( true )
				self:PhysWake()
				self:EmitSound("gbombs_5/explosions/medium_bomb/ex".. math.random(2,8) ..".mp3", 100, 100, 1)
			end
		end
	end

	function ENT:Detonate()
		local pos = self:GetPos()

		-- Always use the 100lb_air particle effect,
		-- regardless of where the missile detonates.
		ParticleEffect(
			"100lb_air",
			pos,
			angle_zero,
			nil
		)

		self:EmitSound(
			"gbombs_5/explosions/medium_bomb/ex" .. math.random(2,8) .. ".mp3",
			100,
			100,
			1
		)

		self:Remove()
	end

	function ENT:OnTakeDamage( dmginfo )
		if dmginfo:GetDamageType() ~= DMG_AIRBOAT then return end

		if self:GetAttacker() == dmginfo:GetAttacker() then return end

		self:BreakMissile()
	end
else
	function ENT:Initialize()
		-- Render-only non-uniform scale (physics untouched)
		local mat = Matrix()
		mat:Scale( self.AxisScale )
		self:EnableMatrix( "RenderMultiply", mat )

		-- Enlarge render bounds so the stretched model isn't culled early
		local mins, maxs = self:GetModelRenderBounds()
		self:SetRenderBounds( mins * self.AxisScale, maxs * self.AxisScale )

		self.snd = CreateSound(self, "gbombs_5/launch/srb_launch.wav")
		self.snd:Play()

		local effectdata = EffectData()
			effectdata:SetOrigin( self:GetPos() )
			effectdata:SetEntity( self )
		util.Effect( "lfs_javelin_missile_trail", effectdata )
	end

	function ENT:Draw()
		self:DrawModel()
	end

	function ENT:SoundStop()
		if self.snd then
			self.snd:Stop()
		end
	end

	function ENT:Think()
		if self:GetDisabled() then
			self:SoundStop()
		end

		return true
	end

	function ENT:OnRemove()
		self:SoundStop()
	end
end
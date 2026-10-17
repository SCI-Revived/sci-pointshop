AddCSLuaFile()

ENT.Type            = "anim"

-- missile detonates when it gets this close to its lock-on target
local PROXIMITY_FUSE_DISTANCE = 200

function ENT:SetupDataTables()
	self:NetworkVar( "Bool",0, "Disabled" )
	self:NetworkVar( "Bool",1, "CleanMissile" )
	self:NetworkVar( "Bool",2, "DirtyMissile" )
	self:NetworkVar( "Entity",0, "Attacker" )
	self:NetworkVar( "Entity",1, "Inflictor" )
	self:NetworkVar( "Entity",2, "LockOn" )
	self:NetworkVar( "Float",0, "StartVelocity" )
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

	function ENT:BlindFire()
		if self:GetDisabled() then return end
		
		local pObj = self:GetPhysicsObject()
		
		if IsValid( pObj ) then
			pObj:SetVelocityInstantaneous( self:GetForward() * (self:GetStartVelocity() + 3000) )
		end
	end
	
	function ENT:FollowTarget( followent )
		local speed = (self:GetStartVelocity() + (self:GetDirtyMissile() and 3000 or 2500)) * 1.4
		local turnrate = ((self:GetCleanMissile() or self:GetDirtyMissile()) and 250 or 150) * 0.35
		
		local TargetPos = followent:LocalToWorld( followent:OBBCenter() )
		
		if isfunction( followent.GetMissileOffset ) then
			local Value = followent:GetMissileOffset()
			if isvector( Value ) then
				TargetPos = followent:LocalToWorld( Value )
			end
		end
		
		-- iterative intercept prediction: how long will the missile take to reach
		-- where the target will be by then?
		local tVel = followent:GetVelocity()
		local mPos = self:GetPos()
		local t = 0

		for i = 1, 4 do
			t = (TargetPos + tVel * t - mPos):Length() / speed
		end

		t = math.min( t, 6 )

		-- extrapolation is least trustworthy vertically (planes level out or pull up),
		-- so only apply part of any downward lead
		local lead = tVel * t
		if lead.z < 0 then
			lead.z = lead.z * 0.5
		end

		local pos = TargetPos + lead

		-- don't lead through the world (e.g. a plane diving into the ground)
		local tr = util.TraceLine( {
			start = TargetPos,
			endpos = pos,
			mask = MASK_SOLID_BRUSHONLY,
		} )

		if tr.Hit then
			-- stop slightly short of the surface so we aim at the plane, not the dirt
			pos = tr.HitPos + tr.HitNormal * 50
		end
		
		local pObj = self:GetPhysicsObject()
		
		if IsValid( pObj ) then
			if not self:GetDisabled() then
				local targetdir = (pos - self:GetPos()):GetNormalized()
				
				local AF = self:WorldToLocalAngles( targetdir:Angle() )
				AF.p = math.Clamp( AF.p * 400,-turnrate,turnrate )
				AF.y = math.Clamp( AF.y * 400,-turnrate,turnrate )
				AF.r = math.Clamp( AF.r * 400,-turnrate,turnrate )
				
				local AVel = pObj:GetAngleVelocity()
				pObj:AddAngleVelocity( Vector(AF.r,AF.p,AF.y) - AVel ) 
				
				pObj:SetVelocityInstantaneous( self:GetForward() * speed )
			end
		end
	end

	function ENT:Initialize()	
		self:SetModel( "models/weapons/w_missile_launch.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetRenderMode( RENDERMODE_TRANSALPHA )
		self:PhysWake()
		local pObj = self:GetPhysicsObject()
		
		if IsValid( pObj ) then
			pObj:EnableGravity( false ) 
			pObj:SetMass( 1 ) 
		end
		
		self.SpawnTime = CurTime()
	end

	function ENT:BlastDamage()
		local Inflictor = self:GetInflictor()
		local Attacker = self:GetAttacker()

		util.BlastDamage( IsValid( Inflictor ) and Inflictor or Entity(0), IsValid( Attacker ) and Attacker or Entity(0), self:GetPos(),1000,1000)
	end

	-- true if the missile is within the proximity fuse distance of its target
	function ENT:IsInProximityOf( Target )
		local MissilePos = self:GetPos()

		-- nearest point on the target's collision bounds, so big targets
		-- trigger the fuse by their surface rather than their center
		local NearestPoint = Target:NearestPoint( MissilePos )

		return MissilePos:DistToSqr( NearestPoint ) <= (PROXIMITY_FUSE_DISTANCE * PROXIMITY_FUSE_DISTANCE)
	end

	function ENT:Think()	
		local curtime = CurTime()
		self:NextThink( curtime )
		
		local Target = self:GetLockOn()
		if IsValid( Target ) then
			self:FollowTarget( Target )

			-- proximity fuse
			if not self:GetDisabled() and self:IsInProximityOf( Target ) then
				self.Explode = true
			end
		else
			self:BlindFire()
		end
		
		if self.MarkForRemove then
			self:Detonate()
			return true
		end

		-- lifetime expired: detonate with full damage (unless the missile was shot down)
		if (self.SpawnTime + 8.5) < curtime then
			if not self:GetDisabled() then
				self.Explode = true
			else
				self:Detonate()
				return true
			end
		end
		
		if self.Explode then
			self:BlastDamage()
			self:Detonate()
		end
		
		return true
	end

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
			end
			
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
				self:EmitSound( "Missile.ShotDown" )
			end
		end
	end

	function ENT:Detonate()
		local effectdata = EffectData()
			effectdata:SetOrigin( self:GetPos() )
		util.Effect( "lvs_explosion_small", effectdata )

		self:Remove()
	end

	function ENT:OnTakeDamage( dmginfo )	
		if dmginfo:GetDamageType() ~= DMG_AIRBOAT then return end
		
		if self:GetAttacker() == dmginfo:GetAttacker() then return end
		
		self:BreakMissile()
	end
else
	function ENT:Initialize()	
		self.snd = CreateSound(self, "weapons/flaregun/burn.wav")
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
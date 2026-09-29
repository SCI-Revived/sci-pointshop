AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "sci_pointshop_entity_base_ui"

ENT.PrintName = "EWR Screen"
ENT.Author = "Paloma"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "Pointshop Entities"

ENT.IconPath = "entities/sci_pointshop_base_ewr_screen.png"
ENT.IconOffset = Vector(-45, 0, 0)

-- Physical model: a flat plate the 3D2D screen is drawn on top of,
-- same pairing as the radar/mainframe screens.
ENT.BaseModel = "models/hunter/plates/plate1x1.mdl"
ENT.BaseMaterial = ""
ENT.BaseColor = Color(40, 40, 40, 255)
ENT.BoneScale = Vector(1, 1, 1)

ENT.AttachmentDrawDistance = 1000
ENT.LabelDrawDistance = 300
ENT.Decaytime = -1

ENT.MaxHealth = 125
ENT.HealthRegen = 3
ENT.CustomMass = 60

ENT.CollideSounds = {
	"physics/metal/metal_box_impact_bullet1.wav",
	"physics/metal/metal_box_impact_bullet2.wav",
	"physics/metal/metal_box_impact_bullet3.wav",
}

---------------------------------------------------------
-- EWR settings
---------------------------------------------------------

-- Classname prefix this screen watches for.
ENT.WatchedPrefix = "gb5_"

-- Maximum number of spawn entries kept/shown at once. Oldest
-- entries are dropped first once this is exceeded.
ENT.MaxEntries = 15

-- Screen panel geometry/placement, same conventions as the
-- mainframe's MainframeScreenOffset/Scale/Size.
ENT.ScreenDrawDistance = 1200
ENT.EWRScreenOffset = Vector(0, 0, 2.6)
ENT.EWRScreenScale = 0.12
ENT.EWRScreenSize = { w = 420, h = 340 }

---------------------------------------------------------
-- Power: this entity is a consumer, drawing from whatever
-- mainframe it's wired to, exactly like the repair station and
-- the radar screen -- it only tracks/displays spawns while it
-- actually has power.
---------------------------------------------------------

ENT.PowerRole = "consumer"
ENT.PowerRequired = 50

if SERVER then

	util.AddNetworkString("ery_ewr_screen_update")

	---------------------------------------------------------
	-- Setup
	---------------------------------------------------------

	function ENT:Initialize()

		if self.BaseClass and self.BaseClass.Initialize then
			self.BaseClass.Initialize(self)
		end

		self:SetUseType(SIMPLE_USE)

		-- Whether a linked mainframe is currently supplying this
		-- entity's power requirement. Set by SetPowered(), called
		-- by the mainframe each power tick. Mirrors the repair
		-- station's HasPower field exactly.
		self.HasPower = false
		self:SetNWBool("HasPower", false)

		-- Ring buffer of tracked spawns, newest first. Each entry:
		-- { time = CurTime() at spawn, owner = string, name =
		-- string, pos = Vector }. Kept server-side; only the
		-- rendered strings are sent to clients (see
		-- BuildEntryLines/SendEntriesTo below).
		self.EWREntries = {}

		self:RegisterEWRHook()
	end

	---------------------------------------------------------
	-- Power interface, called by a linked mainframe. Matches the
	-- repair station's GetPowerRequired/SetPowered pattern.
	---------------------------------------------------------

	function ENT:GetPowerRequired()
		return self.PowerRequired or 50
	end

	function ENT:SetPowered(hasPower)
		hasPower = hasPower and true or false

		if hasPower == self.HasPower then return end

		self.HasPower = hasPower
		self:SetNWBool("HasPower", hasPower)

		if not hasPower then
			self:EmitSound("buttons/button10.wav", 60, 70)
		end
	end

	---------------------------------------------------------
	-- Attempts to resolve who spawned an entity across the
	-- various ownership conventions in use (native GetCreator,
	-- CPPI, or a raw owner field some addons set directly).
	-- Falls back to "Unknown" rather than erroring if none apply.
	---------------------------------------------------------

	function ENT:ResolveSpawner(ent)
		local ply

		if ent.GetCreator then
			local ok, creator = pcall(ent.GetCreator, ent)
			if ok and IsValid(creator) and creator:IsPlayer() then
				ply = creator
			end
		end

		if not ply and ent.CPPIGetOwner then
			local ok, owner = pcall(ent.CPPIGetOwner, ent)
			if ok and IsValid(owner) and owner:IsPlayer() then
				ply = owner
			end
		end

		if not ply and IsValid(ent.SID83Owner) and ent.SID83Owner:IsPlayer() then
			ply = ent.SID83Owner
		end

		if IsValid(ply) then
			return ply:Nick()
		end

		return "Unknown"
	end

	---------------------------------------------------------
	-- Global hook, shared by every EWR screen in the map -- each
	-- instance registers its own uniquely-named hook (keyed by
	-- EntIndex) so removing one screen doesn't clobber another's,
	-- same pattern as the base's per-entity DecayTimer/HealthRegen
	-- timer names.
	---------------------------------------------------------

	function ENT:RegisterEWRHook()
		local hookName = "EWRScreen_OnEntityCreated_" .. self:EntIndex()

		hook.Add("OnEntityCreated", hookName, function(ent)
			if not IsValid(self) then
				hook.Remove("OnEntityCreated", hookName)
				return
			end

			-- OnEntityCreated fires before the entity has finished
			-- spawning/parenting in some cases -- defer one tick so
			-- GetClass(), GetPos(), and ownership are all reliably
			-- populated before we read them.
			timer.Simple(0, function()
				if not IsValid(self) or not IsValid(ent) then return end
				self:MaybeTrackEntity(ent)
			end)
		end)
	end

	---------------------------------------------------------
	-- Checks a freshly spawned entity against the watched prefix
	-- and, if it matches, records a new entry and pushes the
	-- refreshed list to clients. Only tracks while powered, same
	-- gating as the repair station's pulse -- an unpowered screen
	-- shouldn't silently keep collecting data it can't display.
	---------------------------------------------------------

	function ENT:MaybeTrackEntity(ent)
		if not self.HasPower then return end

		local class = ent:GetClass()
		local prefix = self.WatchedPrefix or "gb5_"
		if not class or class:sub(1, #prefix) ~= prefix then return end

		local entry = {
			time = CurTime(),
			owner = self:ResolveSpawner(ent),
			name = ent.PrintName or class,
			pos = ent:GetPos(),
		}

		table.insert(self.EWREntries, 1, entry)

		local maxEntries = self.MaxEntries or 15
		for i = #self.EWREntries, maxEntries + 1, -1 do
			table.remove(self.EWREntries, i)
		end

		self:SendEntriesToAll()
	end

	---------------------------------------------------------
	-- Serializes the current entry list into a single delimited
	-- string and sends it to everyone who can currently see this
	-- entity, same NWString-avoidance reasoning as the mainframe's
	-- UpdateNetworkedNames -- a table can't go directly into a
	-- NWVar, and this only needs to fire on an actual change
	-- (a new spawn), not every tick.
	--
	-- Field delimiter is "\1", entry delimiter is "\2" -- both
	-- control characters a player nickname or entity name won't
	-- realistically contain, so unlike "|" or "," this doesn't
	-- risk splitting on data the string could legitimately hold.
	---------------------------------------------------------

	-- Builds the same delimited payload SendEntriesToAll sends, so
	-- it can be reused both for the broadcast-on-change case and
	-- the send-to-one-player-on-sync-poll case below.
	function ENT:SerializeEntries()
		local parts = {}

		for _, entry in ipairs(self.EWREntries) do
			local pos = entry.pos or vector_origin
			table.insert(parts, table.concat({
				entry.time,
				entry.owner,
				entry.name,
				math.Round(pos.x),
				math.Round(pos.y),
				math.Round(pos.z),
			}, "\1"))
		end

		return table.concat(parts, "\2")
	end

	function ENT:SendEntriesTo(target)
		local serialized = self:SerializeEntries()

		net.Start("ery_ewr_screen_update")
			net.WriteEntity(self)
			net.WriteUInt(#serialized, 16)
			net.WriteData(serialized, #serialized)
		net.Send(target)
	end

	-- Broadcasts to every connected player -- called whenever the
	-- entry list actually changes (a new tracked spawn). This is
	-- NOT a PVS-filtered send: net.Send requires a player or a
	-- table of players, and the entity itself is neither, which
	-- is what caused the "Trying to net.Send a message to a
	-- non-player!" warning. Broadcasting is fine here since the
	-- payload is small and this only fires on actual spawn
	-- events; the Think poll below already handles catching up
	-- players near the screen who missed a broadcast.
	function ENT:SendEntriesToAll()
		local serialized = self:SerializeEntries()

		net.Start("ery_ewr_screen_update")
			net.WriteEntity(self)
			net.WriteUInt(#serialized, 16)
			net.WriteData(serialized, #serialized)
		net.Broadcast()
	end

	-- A player who wasn't near the screen yet when the last
	-- broadcast went out (walked up later, or joined late) has an
	-- empty EWREntries client-side until the next spawn triggers
	-- one. A lightweight poll catches them up without needing any
	-- PVS/transmit hooks: once a second, send the current list to
	-- anyone within a generous radius who hasn't been sent to
	-- since their last position update. Cheap since it only runs
	-- while the screen actually has entries to show.
	function ENT:Think()
		local currentTime = CurTime()

		if #self.EWREntries > 0 and currentTime >= (self.NextEWRSyncCheck or 0) then
			self.NextEWRSyncCheck = currentTime + 2

			for _, ply in ipairs(player.GetAll()) do
				if IsValid(ply) and self:GetPos():DistToSqr(ply:GetPos()) <= (1500 * 1500) then
					self:SendEntriesTo(ply)
				end
			end
		end

		self:NextThink(currentTime + 0.1)
		return true
	end

	function ENT:OnRemove()
		if self.BaseClass and self.BaseClass.OnRemove then
			self.BaseClass.OnRemove(self)
		end

		hook.Remove("OnEntityCreated", "EWRScreen_OnEntityCreated_" .. self:EntIndex())

		self:UnlinkMainframe()
	end

end

if CLIENT then

	surface.CreateFont("EryEWRTitle", {
		font = "Tahoma",
		size = 20,
		weight = 700,
	})

	surface.CreateFont("EryEWRLine", {
		font = "Consolas",
		size = 13,
		weight = 500,
	})

	function ENT:Initialize()
		self.Attachments = self.Attachments or {}

		-- Raw entries received from the server, refreshed only on
		-- net message, not every frame: { time, owner, name, x, y,
		-- z }. "time" is CurTime() on the SERVER at the moment of
		-- spawn -- since client and server CurTime() are kept in
		-- sync by the engine, "CurTime() - entry.time" done
		-- client-side each frame gives a live, ever-increasing age
		-- without needing the server to re-send anything every
		-- second.
		self.EWREntries = self.EWREntries or {}
	end

	net.Receive("ery_ewr_screen_update", function()
		local ent = net.ReadEntity()
		local len = net.ReadUInt(16)
		local serialized = net.ReadData(len)

		if not IsValid(ent) or not ent.EWREntries then return end

		local entries = {}

		if serialized ~= "" then
			for _, raw in ipairs(string.Explode("\2", serialized)) do
				local fields = string.Explode("\1", raw)
				if #fields >= 6 then
					table.insert(entries, {
						time = tonumber(fields[1]) or CurTime(),
						owner = fields[2],
						name = fields[3],
						x = tonumber(fields[4]) or 0,
						y = tonumber(fields[5]) or 0,
						z = tonumber(fields[6]) or 0,
					})
				end
			end
		end

		ent.EWREntries = entries
	end)

	---------------------------------------------------------
	-- Formats a single entry the way the spec's example shows:
	-- "[30s] NoobSlayer spawned (Howitzer Shell) at 258, 12, -259"
	---------------------------------------------------------

	local function FormatEntry(entry)
		local age = math.max(0, math.floor(CurTime() - entry.time))
		return string.format(
			"[%ds] %s spawned (%s) at %d, %d, %d",
			age,
			entry.owner,
			entry.name,
			entry.x, entry.y, entry.z
		)
	end

	---------------------------------------------------------
	-- Draws the black 3D2D screen layered on top of the plate
	-- model. Anchored to the entity's own coordinate frame so it
	-- sits flush with the plate's face and turns with it, same
	-- LocalToWorld approach as the mainframe's DrawScreen.
	---------------------------------------------------------

	function ENT:DrawScreen()
		local offset = self.EWRScreenOffset or Vector(0, 0, 1)

		local pos =
			self:GetPos() +
			self:GetUp() * offset.z

		local ang = self:GetAngles()
		ang:RotateAroundAxis(ang:Up(), 90)

		local size = self.EWRScreenSize or { w = 420, h = 340 }
		local halfW, halfH = size.w / 2, size.h / 2
		local scale = self.EWRScreenScale or 0.12

		cam.Start3D2D(pos, ang, scale)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.DrawRect(-halfW, -halfH, size.w, size.h)

			surface.SetDrawColor(60, 255, 90, 255)
			surface.DrawOutlinedRect(-halfW, -halfH, size.w, size.h, 2)

			draw.SimpleText("EWR", "EryEWRTitle", -halfW + 10, -halfH + 8, Color(60, 255, 90), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

			local hasPower = self:GetNWBool("HasPower", false)
			draw.SimpleText(
				hasPower and "ONLINE" or "NO POWER",
				"EryEWRTitle",
				halfW - 10,
				-halfH + 8,
				hasPower and Color(60, 255, 90) or Color(255, 80, 80),
				TEXT_ALIGN_RIGHT,
				TEXT_ALIGN_TOP
			)

			local rowY = -halfH + 36
			local rowHeight = 17

			if not hasPower then
				draw.SimpleText("-- awaiting power --", "EryEWRLine", -halfW + 10, rowY, Color(120, 120, 120), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			elseif #self.EWREntries == 0 then
				draw.SimpleText("-- no contacts --", "EryEWRLine", -halfW + 10, rowY, Color(120, 120, 120), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			else
				for i, entry in ipairs(self.EWREntries) do
					draw.SimpleText(FormatEntry(entry), "EryEWRLine", -halfW + 10, rowY + ((i - 1) * rowHeight), Color(140, 255, 160), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				end
			end
		cam.End3D2D()
	end

	function ENT:Draw()
		self:DrawModel()

		local attachDist = (self.AttachmentDrawDistance or 500)^2
		if self:GetPos():DistToSqr(LocalPlayer():GetPos()) <= attachDist then
			ERY_MACHINE:DrawAttachments(self, self.Attachments)
		end

		local screenDist = (self.ScreenDrawDistance or 1200)^2
		if self:GetPos():DistToSqr(LocalPlayer():GetPos()) <= screenDist then
			self:DrawScreen()
		end

		self:DrawLabel()
	end

	function ENT:OnRemove()
		ERY_MACHINE:CleanupAttachments(self)
	end

end
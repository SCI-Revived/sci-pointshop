AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "sci_pointshop_entity_base_ui"

ENT.PrintName = "DIY Nuclear Bomb Kit"
ENT.Author = "Paloma"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "Pointshop Entities"

ENT.IconPath = "entities/sci_pointshop_power_rtg.png"
ENT.IconOffset = Vector(65, -10, 60)

ENT.CableOffset = Vector(10, 0, 0)

ENT.BaseModel = "models/props_lab/workspace004.mdl"
ENT.BaseMaterial = ""
ENT.BaseColor = Color(255, 255, 255, 255)
ENT.BoneScale = Vector(1, 1, 1)

ENT.AttachmentDrawDistance = 1000
ENT.LabelDrawDistance = 300
ENT.Decaytime = -1

ENT.MaxHealth = 250
ENT.HealthRegen = 1
ENT.CustomMass = 80

ENT.CollideSounds = {
	"physics/metal/metal_box_impact_bullet1.wav",
	"physics/metal/metal_box_impact_bullet2.wav",
	"physics/metal/metal_box_impact_bullet3.wav",
}

---------------------------------------------------------
-- Nuke kit settings
---------------------------------------------------------

-- Total powered run time needed to finish fabrication (seconds).
ENT.FabricationTime = 30 * 60

-- Possible fabrication results. One is picked at random the
-- first time the device is switched on, and stays hidden
-- (server-side only) until fabrication completes.
ENT.NukeClasses = {
	"gb5_nuclear_antimatter",
	"gb5_nuclear_clusternuke",
	"gb5_nuclear_fatman",
	"gb5_nuclear_trinity",
	"gb5_nuclear_ivymike",
	"gb5_nuclear_littleboy",
	"gb5_nuclear_tsarbomba",
}

-- Where the finished bomb appears, relative to the device.
ENT.NukeSpawnOffset = Vector(0, 0, 40)

-- Screen panel geometry (same conventions as the EWR screen).
ENT.ScreenDrawDistance = 1200
ENT.NukeScreenOffset = Vector(25, 10, 52)
ENT.NukeScreenScale = 0.12
ENT.NukeScreenSize = { w = 420, h = 340 }

---------------------------------------------------------
-- Power: consumer, needs a full 500 from the mainframe.
---------------------------------------------------------

ENT.PowerRole = "consumer"
ENT.PowerRequired = 500

local NUKE_CLASSNAME = "sci_pointshop_base_nukedevice"

if SERVER then

	util.AddNetworkString("ery_nuke_state")
	util.AddNetworkString("ery_nuke_alert")

	local ALERT_STARTED = 1
	local ALERT_COMPLETE = 2
	local ALERT_DESTROYED = 3

	local function SendAlert(kind, text)
		PrintMessage(HUD_PRINTTALK, text)

		net.Start("ery_nuke_alert")
			net.WriteUInt(kind, 3)
			net.WriteString(text)
		net.Broadcast()
	end

	---------------------------------------------------------
	-- Setup
	---------------------------------------------------------

	function ENT:Initialize()
		self.BaseClass.Initialize(self)

		self.HasPower = false
		self:SetNWBool("HasPower", false)

		self.Started = false      -- has ever been switched on
		self.IsOn = false         -- player toggle
		self.Running = false      -- IsOn AND powered (clock ticking)
		self.Complete = false
		self.Remaining = self.FabricationTime
		self.RunStart = 0
		self.NukeClass = nil      -- hidden until completion
		self.NextResync = 0

		self:SetNWBool("NukeStarted", false)
		self:SetNWBool("NukeOn", false)
		self:SetNWBool("NukeComplete", false)
		self:SetNWString("NukeResult", "")

		self:AddMenuButton("toggle", "Turn ON", function(ent, activator)
			ent:ToggleDevice(activator)
		end)
	end

	---------------------------------------------------------
	-- Power interface (called by the mainframe)
	---------------------------------------------------------

	function ENT:GetPowerRequired()
		return self.PowerRequired or 500
	end

	function ENT:SetPowered(hasPower)
		hasPower = hasPower and true or false
		if hasPower == self.HasPower then return end

		self.HasPower = hasPower
		self:SetNWBool("HasPower", hasPower)

		if not hasPower and self.IsOn and not self.Complete then
			self:EmitSound("buttons/button10.wav", 70, 70)
		end

		self:RefreshRunState()
	end

	---------------------------------------------------------
	-- Countdown bookkeeping. Remaining is the banked time at the
	-- moment the clock last started/stopped; while running, the
	-- live value is Remaining - (CurTime() - RunStart).
	---------------------------------------------------------

	function ENT:GetRemaining()
		if self.Running then
			return math.max(0, self.Remaining - (CurTime() - self.RunStart))
		end
		return self.Remaining
	end

	function ENT:RefreshRunState()
		local should = self.Started and self.IsOn and self.HasPower and not self.Complete

		if should ~= self.Running then
			if self.Running then
				self.Remaining = self:GetRemaining() -- bank elapsed time
			end

			self.Running = should

			if should then
				self.RunStart = CurTime()
			end
		end

		if self.Started and not self.Complete then
			self:SendState()
		end
	end

	-- Sends this device's countdown to clients (everyone, or one
	-- player). Clients extrapolate between messages.
	function ENT:SendState(target)
		net.Start("ery_nuke_state")
			net.WriteUInt(self:EntIndex(), 16)
			net.WriteBool(true)
			net.WriteBool(self.Running)
			net.WriteFloat(self:GetRemaining())

			-- Whole-number coordinates; refreshed on every resync so
			-- a moved device is tracked.
			local pos = self:GetPos()
			net.WriteInt(math.Round(pos.x), 20)
			net.WriteInt(math.Round(pos.y), 20)
			net.WriteInt(math.Round(pos.z), 20)
		if IsValid(target) then net.Send(target) else net.Broadcast() end
	end

	function ENT:SendStateRemoved()
		net.Start("ery_nuke_state")
			net.WriteUInt(self:EntIndex(), 16)
			net.WriteBool(false)
		net.Broadcast()
	end

	---------------------------------------------------------
	-- Menu / toggle
	---------------------------------------------------------

	function ENT:UpdateToggleButton()
		if self.Complete then
			self:RemoveMenuButton("toggle")
			return
		end
		self:AddMenuButton("toggle", self.IsOn and "Turn OFF" or "Turn ON", function(ent, activator)
			ent:ToggleDevice(activator)
		end)
	end

	function ENT:ToggleDevice(ply)
		if self.Complete then return end

		if not self.IsOn then
			if not self.HasPower then
				if IsValid(ply) then
					ply:ChatPrint("[" .. self.PrintName .. "] Insufficient power. Wire it to a mainframe supplying " .. self:GetPowerRequired() .. " power.")
				end
				self:EmitSound("buttons/button10.wav", 70, 90)
				return
			end

			self.IsOn = true

			if not self.Started then
				self:StartFabrication(ply)
			end

			self:EmitSound("buttons/button3.wav", 70, 100)
		else
			self.IsOn = false
			self:EmitSound("buttons/button19.wav", 70, 90)
		end

		self:SetNWBool("NukeOn", self.IsOn)
		self:RefreshRunState()
		self:UpdateToggleButton()
	end

	function ENT:StartFabrication(ply)
		self.Started = true
		self.Starter = ply
		self.NukeClass = table.Random(self.NukeClasses)
		self.Remaining = self.FabricationTime

		self:SetNWBool("NukeStarted", true)

		local who = IsValid(ply) and ply:Nick() or "Someone"
		SendAlert(ALERT_STARTED, "WARNING: " .. who .. " has started fabricating a nuclear device! Detonation-grade assembly completes in " .. math.floor(self.FabricationTime / 60) .. " minutes.")
	end

	---------------------------------------------------------
	-- Completion: spawn the hidden bomb.
	---------------------------------------------------------

	function ENT:CompleteFabrication()
		self:RefreshRunState() -- bank time
		self.Complete = true
		self.Running = false
		self.IsOn = false
		self.Remaining = 0

		self:SetNWBool("NukeOn", false)
		self:SetNWBool("NukeComplete", true)

		local resultName = "FABRICATION FAILED"
		local bomb = ents.Create(self.NukeClass or "")

		if IsValid(bomb) then
			bomb:SetPos(self:GetPos() + self.NukeSpawnOffset)
			bomb:SetAngles(Angle(0, self:GetAngles().y, 0))
			bomb:Spawn()
			bomb:Activate()

			if IsValid(self.Starter) then
				bomb:SetCreator(self.Starter)
				bomb.Owner = self.Starter
			end

			resultName = bomb.PrintName or self.NukeClass
		else
			ErrorNoHalt("[" .. NUKE_CLASSNAME .. "] Could not create '" .. tostring(self.NukeClass) .. "' (is GB5 installed?)\n")
		end

		self:SetNWString("NukeResult", resultName)
		self:SendStateRemoved()

		SendAlert(ALERT_COMPLETE, "ALERT: The nuclear device is complete: " .. resultName .. "!")

		-- The kit has served its purpose; the bomb replaces it.
		-- (OnRemove won't send a "destroyed" alert since Complete is set.)
		self:Remove()
	end

	function ENT:Think()
		local now = CurTime()

		if self.Running and self:GetRemaining() <= 0 then
			self:CompleteFabrication()
		elseif self.Started and not self.Complete and now >= self.NextResync then
			-- Periodic resync so clients never drift and late
			-- clients stay accurate.
			self.NextResync = now + 5
			self:SendState()
		end

		self:NextThink(now + 0.25)
		return true
	end

	function ENT:OnRemove()
		if self.BaseClass and self.BaseClass.OnRemove then
			self.BaseClass.OnRemove(self)
		end

		self:UnlinkMainframe()

		if self.Started and not self.Complete then
			self:SendStateRemoved()
			SendAlert(ALERT_DESTROYED, "The nuclear device fabrication has been destroyed.")
		end
	end

	-- Catch players who join mid-countdown.
	hook.Add("PlayerInitialSpawn", "ERY_NukeDevice_LateJoinSync", function(ply)
		timer.Simple(5, function()
			if not IsValid(ply) then return end
			for _, ent in ipairs(ents.FindByClass(NUKE_CLASSNAME)) do
				if ent.Started and not ent.Complete then
					ent:SendState(ply)
				end
			end
		end)
	end)

end

if CLIENT then

	ERY_NUKE_STATES = ERY_NUKE_STATES or {}
	ERY_NUKE_ALERT = ERY_NUKE_ALERT or nil

	local matNuke = Material("entities/sci_pointshop_power_rtg.png", "smooth")

	local COL_YELLOW = Color(255, 200, 0)
	local COL_RED = Color(255, 60, 40)

	surface.CreateFont("EryNukeHUDTimer", { font = "Consolas", size = 54, weight = 800 })
	surface.CreateFont("EryNukeHUDTitle", { font = "Tahoma", size = 20, weight = 800 })
	surface.CreateFont("EryNukeHUDSmall", { font = "Tahoma", size = 16, weight = 600 })
	surface.CreateFont("EryNukeAlert", { font = "Tahoma", size = 26, weight = 800 })
	surface.CreateFont("EryNukeScreenTitle", { font = "Tahoma", size = 20, weight = 700 })
	surface.CreateFont("EryNukeScreenBig", { font = "Consolas", size = 56, weight = 800 })
	surface.CreateFont("EryNukeScreenLine", { font = "Consolas", size = 16, weight = 600 })

	---------------------------------------------------------
	-- Net
	---------------------------------------------------------

	net.Receive("ery_nuke_state", function()
		local idx = net.ReadUInt(16)
		local active = net.ReadBool()

		if not active then
			ERY_NUKE_STATES[idx] = nil
			return
		end

		local running = net.ReadBool()
		local remaining = net.ReadFloat()
		local x = net.ReadInt(20)
		local y = net.ReadInt(20)
		local z = net.ReadInt(20)

		ERY_NUKE_STATES[idx] = {
			running = running,
			remaining = remaining,
			x = x, y = y, z = z,
			recv = CurTime(),
		}
	end)

	-- Plays the nuclear siren for 41 seconds when a fabrication
	-- begins. Uses CreateSound so it can be cut off on schedule;
	-- a new start restarts it rather than stacking.
	local function PlayStartSiren()
		local lp = LocalPlayer()
		if not IsValid(lp) then return end

		if ERY_NUKE_START_SIREN then
			ERY_NUKE_START_SIREN:Stop()
		end

		ERY_NUKE_START_SIREN = CreateSound(lp, "gbombs_5/sirens/nuclear_siren.wav")
		ERY_NUKE_START_SIREN:Play()

		timer.Create("ERY_NukeStartSiren", 41, 1, function()
			if ERY_NUKE_START_SIREN then
				ERY_NUKE_START_SIREN:Stop()
				ERY_NUKE_START_SIREN = nil
			end
		end)
	end

	net.Receive("ery_nuke_alert", function()
		local kind = net.ReadUInt(3)
		local text = net.ReadString()

		ERY_NUKE_ALERT = { kind = kind, text = text, start = CurTime() }

		if kind == 1 then
			PlayStartSiren()
		end
	end)

	---------------------------------------------------------
	-- Helpers
	---------------------------------------------------------

	local function StateRemaining(st)
		if st.running then
			return math.max(0, st.remaining - (CurTime() - st.recv))
		end
		return st.remaining
	end

	local function FormatTime(s)
		s = math.max(0, math.ceil(s))
		return string.format("%02d:%02d", math.floor(s / 60), s % 60)
	end

	-- Black and yellow diagonal warning stripes, clipped to the rect.
	local function DrawHazardStripes(x, y, w, h)
		render.SetScissorRect(x, y, x + w, y + h, true)

		surface.SetDrawColor(255, 200, 0, 255)
		surface.DrawRect(x, y, w, h)

		surface.SetDrawColor(0, 0, 0, 255)
		local sw = 16
		for i = -h, w, sw * 2 do
			surface.DrawPoly({
				{ x = x + i + h,      y = y },
				{ x = x + i + sw + h, y = y },
				{ x = x + i + sw,     y = y + h },
				{ x = x + i,          y = y + h },
			})
		end

		render.SetScissorRect(0, 0, 0, 0, false)
	end

	---------------------------------------------------------
	-- Global HUD: countdown top-middle for every player
	---------------------------------------------------------

	hook.Add("HUDPaint", "ERY_NukeDevice_HUD", function()
		local now = CurTime()

		-- Gather every active fabrication, dropping stale entries,
		-- and sort soonest-to-finish first.
		local list = {}
		for idx, st in pairs(ERY_NUKE_STATES) do
			if now - st.recv > 20 then
				ERY_NUKE_STATES[idx] = nil
			else
				st.remainingNow = StateRemaining(st)
				table.insert(list, st)
			end
		end

		table.sort(list, function(a, b)
			if a.remainingNow ~= b.remainingNow then
				return a.remainingNow < b.remainingNow
			end
			return a.recv < b.recv
		end)

		-- Siren: only during the final 60s of a countdown that is
		-- actually running, for ANY active device. Uses CreateSound
		-- so it can be stopped (this wav loops).
		local wantSiren = false
		for _, st in ipairs(list) do
			if st.running and st.remainingNow <= 60 then
				wantSiren = true
				break
			end
		end

		if wantSiren then
			if not ERY_NUKE_SIREN then
				local lp = LocalPlayer()
				if IsValid(lp) then
					ERY_NUKE_SIREN = CreateSound(lp, "ambient/alarms/siren.wav")
				end
			end

			if ERY_NUKE_SIREN and not ERY_NUKE_SIREN:IsPlaying() then
				ERY_NUKE_SIREN:Play()
			end
		elseif ERY_NUKE_SIREN then
			ERY_NUKE_SIREN:Stop()
			ERY_NUKE_SIREN = nil
		end

		local cx = ScrW() / 2
		local panelY = 16

		-- One panel per active device (capped so the screen doesn't
		-- fill up), each with its own timer, status and location.
		local MAX_PANELS = 4
		local pw, ph = 470, 124

		for i = 1, math.min(#list, MAX_PANELS) do
			local st = list[i]
			local remaining = st.remainingNow
			local x = cx - pw / 2

			-- Solid black background, thin hazard strip on top,
			-- yellow outline.
			surface.SetDrawColor(0, 0, 0, 245)
			surface.DrawRect(x, panelY, pw, ph)
			DrawHazardStripes(x, panelY, pw, 8)
			surface.SetDrawColor(255, 200, 0, 255)
			surface.DrawOutlinedRect(x, panelY, pw, ph, 2)

			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(matNuke)
			surface.DrawTexturedRect(x + 14, panelY + 26, 64, 64)

			local tx = x + 96
			draw.SimpleText("NUCLEAR DEVICE FABRICATION", "EryNukeHUDTitle", tx, panelY + 14, COL_YELLOW, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

			local urgent = st.running and remaining < 60
			local timerCol = urgent and (math.sin(now * 8) > 0 and COL_RED or COL_YELLOW) or COL_YELLOW
			draw.SimpleText(FormatTime(remaining), "EryNukeHUDTimer", tx, panelY + 36, timerCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

			if st.running then
				draw.SimpleText("ASSEMBLY IN PROGRESS", "EryNukeHUDSmall", tx + 190, panelY + 62, COL_YELLOW, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			elseif math.sin(now * 5) > -0.3 then
				draw.SimpleText("PAUSED", "EryNukeHUDSmall", tx + 190, panelY + 62, COL_RED, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			end

			draw.SimpleText(
				string.format("LOCATION: %d, %d, %d", st.x or 0, st.y or 0, st.z or 0),
				"EryNukeHUDSmall", tx, panelY + 98, COL_YELLOW, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP
			)

			panelY = panelY + ph + 6
		end

		-- Overflow note if more devices exist than panels shown.
		if #list > MAX_PANELS then
			local oh = 26
			local x = cx - pw / 2
			surface.SetDrawColor(0, 0, 0, 245)
			surface.DrawRect(x, panelY, pw, oh)
			surface.SetDrawColor(255, 200, 0, 255)
			surface.DrawOutlinedRect(x, panelY, pw, oh, 2)
			draw.SimpleText("+" .. (#list - MAX_PANELS) .. " MORE DEVICES IN PROGRESS", "EryNukeHUDSmall", cx, panelY + oh / 2, COL_YELLOW, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			panelY = panelY + oh + 6
		end

		-- Event banner (started / complete / destroyed)
		local alert = ERY_NUKE_ALERT
		if alert then
			local age = now - alert.start
			if age > 10 then
				ERY_NUKE_ALERT = nil
			else
				local alpha = math.Clamp((10 - age) / 2, 0, 1)
				local flash = math.sin(now * 10) > 0
				local w, h = math.min(ScrW() - 40, 900), 56
				local x = cx - w / 2

				surface.SetAlphaMultiplier(alpha)
				surface.SetDrawColor(0, 0, 0, 245)
				surface.DrawRect(x, panelY, w, h)
				DrawHazardStripes(x, panelY, w, 6)
				DrawHazardStripes(x, panelY + h - 6, w, 6)
				surface.SetDrawColor(255, 200, 0, 255)
				surface.DrawOutlinedRect(x, panelY, w, h, 2)
				draw.SimpleText(alert.text, "EryNukeAlert", cx, panelY + h / 2, (flash and alert.kind ~= 3) and COL_RED or COL_YELLOW, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				surface.SetAlphaMultiplier(1)
			end
		end
	end)

	---------------------------------------------------------
	-- Entity
	---------------------------------------------------------

	function ENT:Initialize()
		if self.BaseClass and self.BaseClass.Initialize then
			self.BaseClass.Initialize(self)
		end
		self.Attachments = self.Attachments or {}
	end

	function ENT:DrawScreen()
		local offset = self.NukeScreenOffset or Vector(0, 0, 1)
		local pos = self:GetPos() + self:GetUp() * offset.z + self:GetRight() * offset.y + self:GetForward() * offset.x 

		local ang = self:GetAngles()
		ang:RotateAroundAxis(ang:Forward(), 90)

		local size = self.NukeScreenSize or { w = 420, h = 340 }
		local halfW, halfH = size.w / 2, size.h / 2
		local scale = self.NukeScreenScale or 0.12

		local hasPower = self:GetNWBool("HasPower", false)
		local started = self:GetNWBool("NukeStarted", false)
		local isOn = self:GetNWBool("NukeOn", false)
		local complete = self:GetNWBool("NukeComplete", false)
		local now = CurTime()

		cam.Start3D2D(pos, ang, scale)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.DrawRect(-halfW, -halfH, size.w, size.h)
			DrawHazardStripes(-halfW, -halfH, size.w, 10)
			DrawHazardStripes(-halfW, halfH - 10, size.w, 10)

			draw.SimpleText("DIY NUCLEAR KIT", "EryNukeScreenTitle", -halfW + 10, -halfH + 18, COL_YELLOW, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			draw.SimpleText(
				hasPower and "POWERED" or "NO POWER",
				"EryNukeScreenTitle", halfW - 10, -halfH + 18,
				hasPower and COL_YELLOW or COL_RED, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP
			)

			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(matNuke)
			surface.DrawTexturedRect(-40, -halfH + 50, 80, 80)

			local status, statusCol
			local st = ERY_NUKE_STATES[self:EntIndex()]
			local remaining = st and StateRemaining(st)

			if complete then
				status, statusCol = "FABRICATION COMPLETE", COL_YELLOW
			elseif not hasPower then
				status, statusCol = "AWAITING " .. (self.PowerRequired or 500) .. " POWER", Color(120, 120, 120)
			elseif not started then
				status, statusCol = "STANDBY - PRESS E TO ACTIVATE", COL_YELLOW
			elseif isOn then
				status, statusCol = "FABRICATING", COL_YELLOW
			else
				status, statusCol = "PAUSED", COL_RED
			end

			draw.SimpleText(status, "EryNukeScreenTitle", 0, 20, statusCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

			if complete then
				draw.SimpleText(self:GetNWString("NukeResult", "???"), "EryNukeScreenTitle", 0, 70, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			elseif started then
				draw.SimpleText(remaining and FormatTime(remaining) or "--:--", "EryNukeScreenBig", 0, 52, COL_YELLOW, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

				-- Progress bar
				local frac = remaining and math.Clamp(1 - remaining / (self.FabricationTime or 1800), 0, 1) or 0
				local barW, barH = size.w - 40, 16
				surface.SetDrawColor(40, 40, 40, 255)
				surface.DrawRect(-barW / 2, 125, barW, barH)
				surface.SetDrawColor(255, 200, 0, 255)
				surface.DrawRect(-barW / 2, 125, barW * frac, barH)

				-- Hidden result: flickering question marks
				local q = ""
				for i = 1, 14 do
					q = q .. (math.random() > 0.5 and "?" or "#")
				end
				draw.SimpleText("OUTPUT: " .. (isOn and hasPower and q or "????????????"), "EryNukeScreenLine", 0, 155, Color(160, 130, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			end
		cam.End3D2D()
	end

	function ENT:Draw()
		self:DrawModel()

		local lp = LocalPlayer()
		local distSqr = self:GetPos():DistToSqr(lp:GetPos())

		if distSqr <= (self.AttachmentDrawDistance or 500)^2 then
			ERY_MACHINE:DrawAttachments(self, self.Attachments)
		end

		if distSqr <= (self.ScreenDrawDistance or 1200)^2 then
			self:DrawScreen()
		end

		self:DrawLabel()
	end

	function ENT:OnRemove()
		ERY_MACHINE:CleanupAttachments(self)
	end

end
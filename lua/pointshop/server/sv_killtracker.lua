--[[
Kill Tracker & Reward Modifiers


Headshot: last hit was to the head hitgroup
Payback: victim was the one who last killed the attacker
Avenger: victim recently killed someone else
Afterlife: attacker is dead at the moment of the kill
Longshot: +10 pts per 1000 units beyond a 5000 unit minimum
Point blank: kill within X units
Assist: someone else damaged the victim recently but a different player got the finishing blow
Double/Triple/Multikill : N kills by the same attacker within a 3 second window

Armor Kill: victim was in a vehicle when killed (+ArmorKillBonus). Applies whether or not the attacker was in a vehicle
Vehicle Penalty: attacker was in a vehicle and the victim was NOT; the kill total is scaled to VehicleKillMultiplier (40%)

All bonuses stack additively on top of the 100 point base kill reward.
The one exception is the Vehicle Penalty, which scales the entire pre-passive total and is applied right before the Payday / Double Down multipliers.
]]

PS = PS or {}
PS.KillTracker = PS.KillTracker or {}

local KT = PS.KillTracker

-- Used for Payback
KT.LastKilledBy = KT.LastKilledBy or {}

-- Used for avenger
KT.LastKillTime = KT.LastKillTime or {}

KT.DamageLog = KT.DamageLog or {}

KT.KillTimestamps = KT.KillTimestamps or {}

KT.LastAttackerEnt = KT.LastAttackerEnt or {}

-- Vehicle state captured at damage time, since a player may already have been ejected from their vehicle by the time PlayerDeath fires.
KT.VictimInVehicle = KT.VictimInVehicle or {}
KT.AttackerInVehicle = KT.AttackerInVehicle or {}

-- Helpers
local function SID(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return nil end
	local ok, sid = pcall(function() return ply:SteamID64() end)
	if ok then return sid end
	return nil
end

local function Now()
	return CurTime()
end

-- Records a damage instance so it can later be checked for assist credit.
local function LogDamage(victim, attacker, dmginfo)
	local vsid = SID(victim)
	local asid = SID(attacker)
	if not vsid or not asid then return end

	KT.DamageLog[vsid] = KT.DamageLog[vsid] or {}
	table.insert(KT.DamageLog[vsid], {
		attacker = asid,
		time = Now(),
	})

	local log = KT.DamageLog[vsid]
	for i = #log, 1, -1 do
		if Now() - log[i].time > PS.Config.AssistWindow then
			table.remove(log, i)
		end
	end
end

local function FindAssister(victim_sid, killer_sid)
	local log = KT.DamageLog[victim_sid]
	if not log then return nil end

	for i = #log, 1, -1 do
		local entry = log[i]
		if entry.attacker ~= killer_sid and (Now() - entry.time) <= PS.Config.AssistWindow then
			return entry.attacker
		end
	end
	return nil
end

local function RegisterKillAndCountRecent(attacker_sid)
	KT.KillTimestamps[attacker_sid] = KT.KillTimestamps[attacker_sid] or {}
	local timestamps = KT.KillTimestamps[attacker_sid]

	table.insert(timestamps, Now())

	for i = #timestamps, 1, -1 do
		if Now() - timestamps[i] > PS.Config.MultiKillWindow then
			table.remove(timestamps, i)
		end
	end

	return #timestamps
end

-- Multiplier that should be applied to a positive point gain (kill/assist) for this player, based on their active bonuses.
-- Payday (+PaydayBonus%) and Double Down (x DoubleDownMultiplier) stack multiplicatively if a player somehow has both (impossible normally but... just in case).
local function GetGainMultiplier(ply)
	if not IsValid(ply) or not ply.HavePassive then return 1 end

	local mult = 1
	if ply:HavePassive("sci_passive_payday") then
		mult = mult * (1 + PS.Config.PaydayBonus)
	end
	if ply:HavePassive("sci_passive_doubledown") then
		mult = mult * PS.Config.DoubleDownMultiplier
	end
	return mult
end

-- Damage Hook 

hook.Add("EntityTakeDamage", "PS_KillTracker_TrackDamage", function(target, dmginfo)
	if not IsValid(target) or not target:IsPlayer() then return end

	local attacker = dmginfo:GetAttacker()

	-- Updated on every hit (any damage source) so it always reflects the state at the lethal hit
	KT.VictimInVehicle[target] = target:InVehicle()

	if IsValid(attacker) and attacker:IsPlayer() and attacker ~= target then
		KT.LastAttackerEnt[target] = attacker
		KT.AttackerInVehicle[target] = attacker:InVehicle()
		LogDamage(target, attacker, dmginfo)
	end
end)


-- Deathhook
hook.Add("PlayerDeath", "PS_KillTracker_HandleKill", function(victim, inflictor, attacker)
	if not IsValid(victim) then return end

	local vsid = SID(victim)

	local killer = nil
	if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
		killer = attacker
	elseif IsValid(KT.LastAttackerEnt[victim]) and KT.LastAttackerEnt[victim]:IsPlayer() then
		killer = KT.LastAttackerEnt[victim]
	end

	PS.KillTracker.ApplyDeathPenalty(victim)

	-- Snapshot vehicle state before the tracking tables are cleared
	local vehicle_state = {
		victim_in_vehicle = KT.VictimInVehicle[victim] or victim:InVehicle(),
		killer_in_vehicle = IsValid(killer) and (KT.AttackerInVehicle[victim] or killer:InVehicle()) or false,
	}
	KT.VictimInVehicle[victim] = nil
	KT.AttackerInVehicle[victim] = nil
	KT.LastAttackerEnt[victim] = nil

	if not killer or killer == victim then
		return
	end

	local ksid = SID(killer)
	if not ksid or not vsid then return end

	PS.KillTracker.ProcessKill(killer, victim, ksid, vsid, vehicle_state)
end)

-- Death Penalty: lose x% of net worth, clamped between PS.Config.DeathLossMin and PS.Config.DeathLossMax, never going below 0 net worth.

--Double Down doubles the computed loss (still clamped to never exceed current net worth) before any negation is considered. "Lose 2x points on death" applies to what would have been lost.
--Life Insurance negates the loss entirely, guaranteed.
--Lucky Five has a 25% chance to negate the loss entirely. If a player somehow has both Life Insurance and Lucky Five (again, impossible under normal means), Life Insurance's guaranteed negation takes precedence (no point rolling the dice when the outcome is already guaranteed).
function PS.KillTracker.ApplyDeathPenalty(victim)
	if not IsValid(victim) then return 0 end

	local net_worth = PS.Core.GetPoints(victim)
	if net_worth <= 0 then return 0 end

	local loss = math.floor(net_worth * PS.Config.DeathLossPercent)
	loss = math.max(PS.Config.DeathLossMin, loss)
	loss = math.min(PS.Config.DeathLossMax, loss)

	local has_double_down = victim:HavePassive("sci_passive_doubledown")
	if has_double_down then
		loss = math.floor(loss * PS.Config.DoubleDownMultiplier)
	end

	loss = math.min(loss, net_worth)

	local has_life_insurance = victim:HavePassive("sci_passive_lifeinsurance")
	local has_lucky_five = victim:HavePassive("sci_passive_luckyfive")

	local negated = false
	if has_life_insurance then
		negated = true
	elseif has_lucky_five then
		negated = math.random() < PS.Config.LuckyFiveChance
	end

	if negated then
		if victim.ChatPrint then
			local reason = has_life_insurance and "Life Insurance" or "Lucky Five"
			victim:ChatPrint(string.format("[Pointshop] %s saved you from losing %s points!", reason, PS.FormatNumber(loss)))
		end
		return 0
	end

	local removed = PS.Core.TakePoints(victim, loss, "death_penalty")
	return removed
end

-- Kill reward processing
function PS.KillTracker.ProcessKill(killer, victim, ksid, vsid, vehicle_state)
	local breakdown = {} -- list of { label = string, amount = number }
	local total = PS.Config.KillReward
	table.insert(breakdown, { label = "Kill", amount = PS.Config.KillReward })

	local now = Now()

	-- Falls back to a live check if ProcessKill is called from elsewhere without a snapshot
	vehicle_state = vehicle_state or {
		victim_in_vehicle = IsValid(victim) and victim:InVehicle() or false,
		killer_in_vehicle = IsValid(killer) and killer:InVehicle() or false,
	}
	local victim_in_vehicle = vehicle_state.victim_in_vehicle
	local killer_in_vehicle = vehicle_state.killer_in_vehicle

	-- Headshot
	local was_headshot = IsValid(victim) and victim:LastHitGroup() == HITGROUP_HEAD
	if was_headshot then
		total = total + PS.Config.HeadshotBonus
		table.insert(breakdown, { label = "Headshot", amount = PS.Config.HeadshotBonus })
	end

	-- Payback
	local payback_entry = KT.LastKilledBy[ksid] -- who last killed the killer, and when
	local is_payback = false
	if payback_entry and payback_entry.attacker_sid == vsid and (now - payback_entry.time) <= PS.Config.RevengeWindow then
		is_payback = true
		total = total + PS.Config.PaybackBonus
		table.insert(breakdown, { label = "Payback", amount = PS.Config.PaybackBonus })
	end

	-- Avenger
	local victim_last_kill_time = KT.LastKillTime[vsid]
	if not is_payback and victim_last_kill_time and (now - victim_last_kill_time) <= PS.Config.RevengeWindow then
		total = total + PS.Config.AvengerBonus
		table.insert(breakdown, { label = "Avenger", amount = PS.Config.AvengerBonus })
	end

	-- Afterlife
	if not killer:Alive() then
		total = total + PS.Config.AfterlifeBonus
		table.insert(breakdown, { label = "Afterlife", amount = PS.Config.AfterlifeBonus })
	end

	-- Longshot & Point Blank
	local dist = 0
	if IsValid(killer) and IsValid(victim) then
		dist = killer:GetPos():Distance(victim:GetPos())
	end

	if dist <= PS.Config.PointBlankRange then
		total = total + PS.Config.PointBlankBonus
		table.insert(breakdown, { label = "Point Blank", amount = PS.Config.PointBlankBonus })
	elseif dist >= PS.Config.LongshotThreshold and not (IsValid(killer) and killer:InVehicle()) then
		local extra_units = dist - PS.Config.LongshotThreshold
		local increments = math.floor(extra_units / PS.Config.LongshotUnit)
		if increments > 0 then
			local bonus = increments * PS.Config.LongshotPerUnit
			total = total + bonus
			table.insert(breakdown, { label = "Longshot", amount = bonus })
		end
	end

	-- Armor Kill (victim was in a vehicle; attacker's vehicle state doesn't matter)
	if victim_in_vehicle then
		local armor_bonus = PS.Config.ArmorKillBonus or 250
		total = total + armor_bonus
		table.insert(breakdown, { label = "Armor Kill", amount = armor_bonus })
	end

	-- Assist
	local assister_sid = FindAssister(vsid, ksid)
	if assister_sid then
		local assister_ply = player.GetBySteamID64(assister_sid)

		if IsValid(assister_ply) then
			local assist_breakdown = { { label = "Assist", amount = PS.Config.AssistBonus } }
			local assist_mult = GetGainMultiplier(assister_ply)
			if assist_mult ~= 1 then
				local bonus_extra = math.floor(PS.Config.AssistBonus * assist_mult) - PS.Config.AssistBonus
				if bonus_extra ~= 0 then
					table.insert(assist_breakdown, { label = PS.KillTracker.GetPassiveBonusLabel(assister_ply), amount = bonus_extra })
				end
			end

			local assist_total = 0
			for _, entry in ipairs(assist_breakdown) do
				assist_total = assist_total + entry.amount
			end

			PS.Core.AddPoints(assister_ply, assist_total, "assist")
			PS.KillTracker.SendKillFeed(assister_ply, assist_breakdown, assist_total, victim)
		end
	end

	-- Multikills
	local recent_kill_count = RegisterKillAndCountRecent(ksid)
	if recent_kill_count == 2 then
		total = total + PS.Config.DoubleKillBonus
		table.insert(breakdown, { label = "Double Kill", amount = PS.Config.DoubleKillBonus })
	elseif recent_kill_count == 3 then
		total = total + PS.Config.TripleKillBonus
		table.insert(breakdown, { label = "Triple Kill!", amount = PS.Config.TripleKillBonus })
	elseif recent_kill_count >= 4 then
		total = total + PS.Config.MultiKillBonus
		table.insert(breakdown, { label = "MULTIKILL!", amount = PS.Config.MultiKillBonus })
	end

	-- Vehicle penalty (attacker in a vehicle, victim on foot): scale the whole total.
	-- Mutually exclusive with Armor Kill, since that requires the victim to be in a vehicle.
	if killer_in_vehicle and not victim_in_vehicle then
		local pre_penalty_total = total
		total = math.floor(total * (PS.Config.VehicleKillMultiplier or 0.4))
		local penalty = total - pre_penalty_total
		if penalty ~= 0 then
			table.insert(breakdown, { label = "Infantry Kill", amount = penalty })
		end
	end

	-- Point multipliers
	local kill_mult = GetGainMultiplier(killer)
	if kill_mult ~= 1 then
		local pre_multiplier_total = total
		total = math.floor(total * kill_mult)
		local bonus_extra = total - pre_multiplier_total
		if bonus_extra ~= 0 then
			table.insert(breakdown, { label = PS.KillTracker.GetPassiveBonusLabel(killer), amount = bonus_extra })
		end
	end

	-- Notify & give points
	PS.Core.AddPoints(killer, total, "kill")
	PS.KillTracker.SendKillFeed(killer, breakdown, total, victim)

	KT.LastKilledBy[vsid] = { attacker_sid = ksid, time = now }
	KT.LastKillTime[ksid] = now

	KT.DamageLog[vsid] = nil
end

function PS.KillTracker.GetPassiveBonusLabel(ply)
	local has_payday = ply:HavePassive("sci_passive_payday")
	local has_double_down = ply:HavePassive("sci_passive_doubledown")

	if has_payday and has_double_down then
		return "Payday + Double Down"
	elseif has_double_down then
		return "Double Down"
	elseif has_payday then
		return "Payday"
	end
	return "Bonus"
end

function PS.KillTracker.SendKillFeed(ply, breakdown, total, victim)
	if not IsValid(ply) then return end

	net.Start("PS_KillFeed")
		net.WriteInt(total, 32)
		net.WriteString(IsValid(victim) and victim:Nick() or "Unknown")
		net.WriteUInt(#breakdown, 8)
		for _, entry in ipairs(breakdown) do
			net.WriteString(entry.label)
			net.WriteInt(entry.amount, 32)
		end
	net.Send(ply)
end

hook.Add("PlayerDisconnected", "PS_KillTracker_Cleanup", function(ply)
	local sid = SID(ply)
	if sid then
		KT.LastKilledBy[sid] = nil
		KT.LastKillTime[sid] = nil
		KT.DamageLog[sid] = nil
		KT.KillTimestamps[sid] = nil
	end
	KT.LastAttackerEnt[ply] = nil
	KT.VictimInVehicle[ply] = nil
	KT.AttackerInVehicle[ply] = nil
end)
PS = PS or {}
PS.Commands = PS.Commands or {}

-- Superadmin console commands for managing player points.
--
--   pointshop_givepoints (player) (amount)
--   pointshop_takepoints (player) (amount)
--   pointshop_setpoints  (player) (amount)
--   pointshop_getpoints  (player)
--
-- (player) can be a full/partial name, a SteamID, or a SteamID64.
-- Names containing spaces should be wrapped in quotes, e.g.
--   pointshop_givepoints "John Smith" 500
-- Can be run from the server console or by an in-game superadmin.


-- Helpers

local function Reply(caller, msg)
	msg = "[PointShop] " .. msg

	if IsValid(caller) then
		-- Only one print: HUD_PRINTTALK also echoes to the console, so using
		-- both (or TALK alone) would show the message multiple times.
		caller:PrintMessage(HUD_PRINTCONSOLE, msg)
	else
		print(msg)
	end
end

-- Server console (invalid caller) is always allowed; players must be superadmin.
local function IsAllowed(caller)
	if not IsValid(caller) then return true end

	return caller:IsSuperAdmin()
end

-- Finds a single player by SteamID / SteamID64 / exact name / partial name.
-- Returns the player, or nil plus an error message.
local function FindPlayer(query)
	query = string.Trim(query or "")

	if query == "" then
		return nil, "No player specified."
	end

	local lowered = string.lower(query)
	local partial = {}

	for _, ply in ipairs(player.GetAll()) do
		if ply:SteamID() == query
			or ply:SteamID64() == query
			or string.lower(ply:Nick()) == lowered then
			return ply
		end

		if string.find(string.lower(ply:Nick()), lowered, 1, true) then
			partial[#partial + 1] = ply
		end
	end

	if #partial == 1 then
		return partial[1]
	end

	if #partial > 1 then
		local names = {}

		for _, ply in ipairs(partial) do
			names[#names + 1] = ply:Nick()
		end

		return nil, "Multiple players match '" .. query .. "': " .. table.concat(names, ", ")
	end

	return nil, "No player found matching '" .. query .. "'."
end

-- Splits args into (player query, amount). The last argument is the amount, and
-- everything before it is joined as the player query, so unquoted names with
-- spaces still work.
local function ParseTargetAndAmount(args)
	if #args < 2 then
		return nil, nil, "Usage: (player) (amount)"
	end

	local amount = tonumber(args[#args])

	if not amount then
		return nil, nil, "'" .. tostring(args[#args]) .. "' is not a valid amount."
	end

	amount = math.floor(amount)

	local query = table.concat(args, " ", 1, #args - 1)

	return query, amount
end

local function Describe(ply)
	return ply:Nick() .. " (" .. ply:SteamID() .. ")"
end


-- Commands

concommand.Add("pointshop_givepoints", function(caller, cmd, args)
	if not IsAllowed(caller) then
		Reply(caller, "You must be a superadmin to use this command.")
		return
	end

	local query, amount, err = ParseTargetAndAmount(args)

	if err then
		Reply(caller, err .. "  (" .. cmd .. " (player) (amount))")
		return
	end

	if amount <= 0 then
		Reply(caller, "Amount must be greater than 0. Use pointshop_takepoints to remove points.")
		return
	end

	local target, ferr = FindPlayer(query)

	if not target then
		Reply(caller, ferr)
		return
	end

	local before = PS.Core.GetPoints(target)
	local after = PS.Core.AddPoints(target, amount, "admin_give")

	Reply(caller, string.format(
		"Gave %s %d points (%d -> %d).",
		Describe(target), after - before, before, after
	))
end)

concommand.Add("pointshop_takepoints", function(caller, cmd, args)
	if not IsAllowed(caller) then
		Reply(caller, "You must be a superadmin to use this command.")
		return
	end

	local query, amount, err = ParseTargetAndAmount(args)

	if err then
		Reply(caller, err .. "  (" .. cmd .. " (player) (amount))")
		return
	end

	if amount <= 0 then
		Reply(caller, "Amount must be greater than 0. Use pointshop_givepoints to add points.")
		return
	end

	local target, ferr = FindPlayer(query)

	if not target then
		Reply(caller, ferr)
		return
	end

	local before = PS.Core.GetPoints(target)
	local removed, after = PS.Core.TakePoints(target, amount, "admin_take")

	Reply(caller, string.format(
		"Took %d points from %s (%d -> %d).",
		removed, Describe(target), before, after
	))
end)

concommand.Add("pointshop_setpoints", function(caller, cmd, args)
	if not IsAllowed(caller) then
		Reply(caller, "You must be a superadmin to use this command.")
		return
	end

	local query, amount, err = ParseTargetAndAmount(args)

	if err then
		Reply(caller, err .. "  (" .. cmd .. " (player) (amount))")
		return
	end

	if amount < 0 then
		Reply(caller, "Amount cannot be negative.")
		return
	end

	local target, ferr = FindPlayer(query)

	if not target then
		Reply(caller, ferr)
		return
	end

	local before = PS.Core.GetPoints(target)
	local after = PS.Core.SetPoints(target, amount, "admin_set")

	local note = ""

	if after ~= amount then
		note = " (clamped to max of " .. PS.Config.MaxPoints .. ")"
	end

	Reply(caller, string.format(
		"Set %s's points to %d%s (was %d).",
		Describe(target), after, note, before
	))
end)

concommand.Add("pointshop_getpoints", function(caller, cmd, args)
	if not IsAllowed(caller) then
		Reply(caller, "You must be a superadmin to use this command.")
		return
	end

	if #args < 1 then
		Reply(caller, "Usage: " .. cmd .. " (player)")
		return
	end

	local target, ferr = FindPlayer(table.concat(args, " "))

	if not target then
		Reply(caller, ferr)
		return
	end

	Reply(caller, string.format(
		"%s has %d points.",
		Describe(target), PS.Core.GetPoints(target)
	))
end)

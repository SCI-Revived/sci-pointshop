-- Vehicle spawn cooldown (LVS + simfphys)
-- Install at: garrysmod/lua/autorun/server/sv_vehicle_cooldown.lua

local COOLDOWN = 60          -- seconds between vehicle spawns
local ADMIN_BYPASS = false   -- set true to let admins ignore the cooldown

local BLOCKED_BASES = {
    ["lvs_base"] = true,
    ["gmod_sent_vehicle_fphysics_base"] = true,
}

local cache = {}      -- class -> true/false
local nextSpawn = {}  -- SteamID64 -> CurTime() when they may spawn again

-- Walk the entity's base chain to see if it derives from a blocked base
local function IsLimitedClass(class)
    if not class then return false end
    if cache[class] ~= nil then return cache[class] end

    local result = false
    local current = class
    local depth = 0

    while current and depth < 16 do
        if BLOCKED_BASES[current] then
            result = true
            break
        end
        local stored = scripted_ents.GetStored(current)
        local t = stored and stored.t
        current = t and t.Base
        depth = depth + 1
    end

    cache[class] = result
    return result
end

local function Bypasses(ply)
    -- Players in buildmode are never affected by the cooldown
    if ply.buildmode then return true end
    return ADMIN_BYPASS and ply:IsAdmin()
end

-- Block the spawn if still on cooldown
local function CheckCooldown(ply, class)
    if not IsLimitedClass(class) or Bypasses(ply) then return end

    local remaining = (nextSpawn[ply:SteamID64()] or 0) - CurTime()
    if remaining > 0 then
        ply:ChatPrint(string.format("[Vehicles] You must wait %d more second(s) before spawning another LVS/Simfphys entity.", math.ceil(remaining)))
        return false
    end
end

-- Start the cooldown once a vehicle was actually spawned
local function StartCooldown(ply, ent)
    if not IsValid(ply) or not IsValid(ent) then return end
    if not IsLimitedClass(ent:GetClass()) or Bypasses(ply) then return end

    nextSpawn[ply:SteamID64()] = CurTime() + COOLDOWN
end

hook.Add("PlayerSpawnSENT", "VehCooldown_CheckSENT", function(ply, class)
    return CheckCooldown(ply, class)
end)

hook.Add("PlayerSpawnVehicle", "VehCooldown_CheckVehicle", function(ply, model, class)
    return CheckCooldown(ply, class)
end)

hook.Add("PlayerSpawnedSENT", "VehCooldown_StartSENT", StartCooldown)
hook.Add("PlayerSpawnedVehicle", "VehCooldown_StartVehicle", StartCooldown)

-- simfphys spawns through its own function and skips the normal spawn hooks,
-- so wrap simfphys.SpawnVehicle directly.
local function WrapSimfphys()
    if not simfphys or not isfunction(simfphys.SpawnVehicle) then return false end
    if simfphys._VehCooldownWrapped then return true end

    local original = simfphys.SpawnVehicle

    simfphys.SpawnVehicle = function(ply, ...)
        if IsValid(ply) and ply:IsPlayer() and not Bypasses(ply) then
            local remaining = (nextSpawn[ply:SteamID64()] or 0) - CurTime()
            if remaining > 0 then
                ply:ChatPrint(string.format("[Vehicles] You must wait %d more second(s) before spawning another vehicle.", math.ceil(remaining)))
                return NULL
            end
        end

        local ent = original(ply, ...)

        if IsValid(ent) and IsValid(ply) and ply:IsPlayer() and not Bypasses(ply) then
            nextSpawn[ply:SteamID64()] = CurTime() + COOLDOWN
        end

        return ent
    end

    simfphys._VehCooldownWrapped = true
    return true
end

-- simfphys may load after this file, so retry until it's available
if not WrapSimfphys() then
    hook.Add("InitPostEntity", "VehCooldown_WrapSimfphys", function()
        if WrapSimfphys() then return end
        timer.Create("VehCooldown_WrapRetry", 1, 30, function()
            if WrapSimfphys() then timer.Remove("VehCooldown_WrapRetry") end
        end)
    end)
end

-- Clean up on disconnect
hook.Add("PlayerDisconnected", "VehCooldown_Cleanup", function(ply)
    nextSpawn[ply:SteamID64()] = nil
end)

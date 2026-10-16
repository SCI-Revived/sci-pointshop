-- LVS Instakill Occupants (v2: HP polling, does not depend on damage events)
-- Place in: garrysmod/addons/<youraddon>/lua/autorun/server/sv_lvs_instakill.lua
-- When an LVS vehicle's HP reaches 0, everyone inside dies instantly
-- and the last real attacker is credited with the kills.

if CLIENT then return end

CreateConVar("lvs_instakill_occupants", 1, FCVAR_ARCHIVE, "Kill everyone inside an LVS vehicle when it is destroyed.", 0, 1)
CreateConVar("lvs_instakill_attacker_memory", 15, FCVAR_ARCHIVE, "Seconds the last real attacker is remembered (for crash/fire/world damage credit).", 0, 120)
CreateConVar("lvs_instakill_debug", 0, FCVAR_ARCHIVE, "Print debug info when occupants are killed.", 0, 1)

local function GetOccupants(veh)
    local out, seen = {}, {}

    local function add(ply)
        if IsValid(ply) and ply:IsPlayer() and ply:Alive() and not seen[ply] then
            seen[ply] = true
            out[#out + 1] = ply
        end
    end

    if isfunction(veh.GetEveryone) then
        for _, ply in pairs(veh:GetEveryone()) do add(ply) end
    end
    if isfunction(veh.GetDriver) then add(veh:GetDriver()) end
    if isfunction(veh.GetPassengers) then
        for _, ply in pairs(veh:GetPassengers()) do add(ply) end
    end

    return out
end

-- Remember who last damaged each LVS vehicle (never blocks or alters damage)
hook.Add("EntityTakeDamage", "LVS_InstaKill_Track", function(ent, dmginfo)
    if not ent.LVS then return end

    local attacker = dmginfo:GetAttacker()
    if IsValid(attacker) and attacker ~= ent and not attacker:IsWorld() then
        ent.LVS_IK_Attacker = attacker
        local inf = dmginfo:GetInflictor()
        ent.LVS_IK_Inflictor = IsValid(inf) and inf or attacker
        ent.LVS_IK_Time = CurTime()
    end
end)

local function KillOccupants(veh)
    local attacker = NULL
    local inflictor = NULL

    local memory = GetConVar("lvs_instakill_attacker_memory"):GetFloat()
    if IsValid(veh.LVS_IK_Attacker) and (CurTime() - (veh.LVS_IK_Time or 0)) <= memory then
        attacker = veh.LVS_IK_Attacker
        inflictor = veh.LVS_IK_Inflictor
    elseif IsValid(veh.FinalAttacker) then
        -- LVS's own record, if present
        attacker = veh.FinalAttacker
        inflictor = veh.FinalInflictor
    end

    if not IsValid(attacker) then attacker = game.GetWorld() end
    if not IsValid(inflictor) then inflictor = attacker end

    for _, ply in ipairs(veh.LVS_IK_Occupants or {}) do
        if IsValid(ply) and ply:Alive() then
            if GetConVar("lvs_instakill_debug"):GetBool() then
                print("[LVS Instakill] Killing " .. ply:Nick() .. " | attacker: " .. tostring(attacker))
            end

            -- Make sure they are out of the seat so the damage is not swallowed
            if ply:InVehicle() then ply:ExitVehicle() end

            local info = DamageInfo()
            info:SetDamage(ply:Health() + ply:Armor() + 10000)
            info:SetDamageType(bit.bor(DMG_BLAST, DMG_ALWAYSGIB))
            info:SetAttacker(attacker)
            info:SetInflictor(inflictor)
            info:SetDamagePosition(ply:GetPos())
            info:SetReportedPosition(ply:GetPos())
            info:SetDamageForce(Vector(0, 0, 1))
            ply:TakeDamageInfo(info)

            -- Fallback if something (godmode hook, etc.) blocked the damage
            if ply:Alive() and not ply:HasGodMode() then
                ply:Kill()
            end
        end
    end

    veh.LVS_IK_Occupants = nil
end

-- Poll every 0.05s. While HP > 0 we keep a fresh occupant snapshot; once HP <= 0, kill them.
timer.Create("LVS_InstaKill_Poll", 0.05, 0, function()
    local enabled = GetConVar("lvs_instakill_occupants"):GetBool()

    for _, ent in ipairs(ents.GetAll()) do
        if not ent.LVS or not isfunction(ent.GetHP) then continue end
        if ent.LVS_IK_Done then continue end

        if ent:GetHP() > 0 then
            if enabled then ent.LVS_IK_Occupants = GetOccupants(ent) end
        elseif enabled then
            ent.LVS_IK_Done = true

            -- Include anyone still seated right now, in case the snapshot missed them
            local snap = ent.LVS_IK_Occupants or {}
            for _, ply in ipairs(GetOccupants(ent)) do
                if not table.HasValue(snap, ply) then snap[#snap + 1] = ply end
            end
            ent.LVS_IK_Occupants = snap

            KillOccupants(ent)
        end
    end
end)
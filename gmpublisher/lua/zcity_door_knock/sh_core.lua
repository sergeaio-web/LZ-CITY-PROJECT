ZCityDoorKnock = ZCityDoorKnock or {}
local DK = ZCityDoorKnock

DK.Version = "1.4.3"
DK.AnimationName = "interact"
DK.AnimationMarker = "ZCITY_DOOR_KNOCK_LEFT_V14"
DK.SoundPath = "zcity_door_knock/knock.wav"
DK.DefaultSoundDuration = 1.15
DK.DefaultSoundPitch = 85
DK.SoundDelay = 0.13
DK.AnimationTail = 0.16
DK.KnockFractions = {0.14, 0.38, 0.62, 0.86}
DK.DefaultDistance = 42
DK.HardMaxDistance = 46

DK.DoorClasses = {
    ["prop_door"] = true,
    ["prop_door_rotating"] = true,
    ["func_door"] = true,
    ["func_door_rotating"] = true
}

function DK.IsDoor(ent)
    if not IsValid(ent) then return false end

    if isfunction(hgIsDoor) and hgIsDoor(ent) then
        return true
    end

    local class = string.lower(ent:GetClass() or "")
    if DK.DoorClasses[class] then return true end

    return string.find(class, "door", 1, true) ~= nil
end

function DK.IsHintDoor(ent)
    if not IsValid(ent) then return false end
    local class = ent:GetClass()
    return class == "prop_door_rotating" or class == "func_door_rotating"
end

function DK.GetCharacter(ply)
    if hg and isfunction(hg.GetCurrentCharacter) then
        local character = hg.GetCurrentCharacter(ply)
        if IsValid(character) then return character end
    end

    return ply
end

function DK.CanKnock(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    if ply:InVehicle() or ply:GetMoveType() == MOVETYPE_NOCLIP then return false end
    if IsValid(ply.FakeRagdoll) then return false end

    local character = DK.GetCharacter(ply)
    if IsValid(character) and character:IsRagdoll() then return false end

    local organism = ply.organism
    if organism then
        if organism.canmove == false or organism.otrub then return false end
        if organism.larmamputated then return false end
    end

    return true
end

local function traceFilter(ply, character)
    return function(ent)
        if ent == ply then return false end
        if IsValid(character) and ent == character then return false end
        return true
    end
end

function DK.TraceDoor(ply, distance)
    if not IsValid(ply) then return nil end

    distance = math.Clamp(tonumber(distance) or DK.DefaultDistance, 1, DK.HardMaxDistance)

    local startPos = ply:EyePos()
    local character = DK.GetCharacter(ply)
    local tr = util.TraceLine({
        start = startPos,
        endpos = startPos + ply:GetAimVector() * distance,
        filter = traceFilter(ply, character),
        mask = MASK_SHOT
    })

    if not tr.Hit or not DK.IsDoor(tr.Entity) then return nil end
    if startPos:DistToSqr(tr.HitPos) > distance * distance then return nil end

    return tr
end

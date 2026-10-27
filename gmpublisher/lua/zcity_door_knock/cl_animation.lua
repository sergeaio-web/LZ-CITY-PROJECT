local DK = ZCityDoorKnock

local function removeLegacyRightHandBridge()
    if not hg or not isfunction(hg.ZCityDoorKnockOriginalDoZManip) then return end

    hg.DoZManip = hg.ZCityDoorKnockOriginalDoZManip
    hg.ZCityDoorKnockOriginalDoZManip = nil
end

local function smoothStep(value)
    value = math.Clamp(value, 0, 1)
    return value * value * (3 - 2 * value)
end

local function knockPulseSeconds(elapsed, center, width)
    local value = 1 - math.abs(elapsed - center) / width
    return smoothStep(value)
end

local function isOurMarker(ply)
    local data = ply.zmanipaddtbl
    return data and data[4] == DK.AnimationMarker
end

local function drawKnockHand(_, ply, vm, normalizedTime)
    local data = ply.zmanipaddtbl
    if not data or data[4] ~= DK.AnimationMarker then return end

    local door = data[1]
    local hitPos = data[2]
    local hitNormal = data[3]
    local soundDuration = tonumber(data[5]) or DK.DefaultSoundDuration
    local soundDelay = tonumber(data[6]) or DK.SoundDelay

    if not IsValid(door) or not isvector(hitPos) or not isvector(hitNormal) then return end

    local handBone = vm:LookupBone("ValveBiped.Bip01_L_Hand")
    if not handBone then return end

    local handMatrix = vm:GetBoneMatrix(handBone)
    if not handMatrix then return end

    local totalDuration = math.max(0.01, tonumber(ply.zmaniptime) or (soundDelay + soundDuration + DK.AnimationTail))
    local elapsed = normalizedTime * totalDuration

    local reachIn = smoothStep(elapsed / 0.16)
    local reachOutStart = math.max(0.18, totalDuration - 0.20)
    local reachOut = 1 - smoothStep((elapsed - reachOutStart) / 0.20)
    local reach = math.min(reachIn, reachOut)

    local pulse = 0
    local pulseWidth = math.Clamp(soundDuration * 0.075, 0.055, 0.11)
    for _, fraction in ipairs(DK.KnockFractions) do
        local center = soundDelay + soundDuration * fraction
        pulse = math.max(pulse, knockPulseSeconds(elapsed, center, pulseWidth))
    end

    local handPos = handMatrix:GetTranslation()
    local targetPos = hitPos + hitNormal * (4.8 - pulse * 3.5)
    local distanceFactor = 1 - math.min(1, handPos:DistToSqr(targetPos) / (58 * 58))
    local blend = math.Clamp(reach * distanceFactor * 1.45, 0, 0.93)

    handMatrix:SetTranslation(LerpVector(blend, handPos, targetPos))

    local targetAngles = (-hitNormal):Angle()
    targetAngles:RotateAroundAxis(targetAngles:Right(), 90)
    handMatrix:SetAngles(LerpAngle(blend * 0.55, handMatrix:GetAngles(), targetAngles))

    if hg and isfunction(hg.bone_apply_matrix) then
        hg.bone_apply_matrix(vm, handBone, handMatrix)
    else
        vm:SetBoneMatrix(handBone, handMatrix)
    end
end

local function resetBoneCache(ent)
    if not IsValid(ent) then return end
    ent:InvalidateBoneCache()
    ent:SetupBones()
end

local function cleanupPlayer(ply)
    if not IsValid(ply) then return end

    local character = DK.GetCharacter(ply)
    local trackedWeapon = ply.ZCityDoorKnockWeapon

    if IsValid(trackedWeapon) and trackedWeapon == ply:GetActiveWeapon() then
        trackedWeapon.lhandik = ply.ZCityDoorKnockOldLHIK == true
    end

    if IsValid(ply.zmodel) then
        ply.zmodel.OldAngPunch = nil
    end

    if isOurMarker(ply) then
        ply.zmanipaddtbl = nil
        ply.zmanipdrawFunc = nil
        ply.zmanipother = nil
        ply.zmanipanim = nil
    end

    ply.ZCityDoorKnockActive = nil
    ply.ZCityDoorKnockWeapon = nil
    ply.ZCityDoorKnockOldLHIK = nil

    for index = 0, 3 do
        timer.Simple(index * 0.03, function()
            if not IsValid(ply) then return end
            resetBoneCache(character)
            if character ~= ply then resetBoneCache(ply) end
            resetBoneCache(ply.zmodel)
        end)
    end
end

local function registerAnimationPatch()
    removeLegacyRightHandBridge()
    if not hg or not istable(hg.ZManipAnims) then return false end

    local interact = hg.ZManipAnims[DK.AnimationName]
    if not istable(interact) then return false end
    if interact.ZCityDoorKnockOriginalDraw then
        interact.drawFunc = interact.ZCityDoorKnockOriginalDraw
    else
        interact.ZCityDoorKnockOriginalDraw = interact.drawFunc
    end

    local originalDraw = interact.ZCityDoorKnockOriginalDraw
    interact.drawFunc = function(ent, ply, vm, time)
        if isfunction(originalDraw) then
            originalDraw(ent, ply, vm, time)
        end
        drawKnockHand(ent, ply, vm, time)
    end
    interact.ZCityDoorKnockWrappedV143 = true

    return true
end

local function getDoorInstructions()
    local use = input.LookupBinding("+use") or "E"
    local reload = input.LookupBinding("+reload") or "R"
    local walk = input.LookupBinding("+walk") or "ALT"
    local speed = input.LookupBinding("+speed") or "SHIFT"

    return "<font=ZCity_Tiny>" .. string.upper(use) .. " open normally</font>\n" ..
        "<font=ZCity_Tiny>" .. string.upper(reload) .. " knock</font>\n" ..
        "<font=ZCity_Tiny>" .. string.upper(walk) .. " + " .. string.upper(use) .. " open slower</font>\n" ..
        "<font=ZCity_Tiny>" .. string.upper(speed) .. " + " .. string.upper(use) .. " open faster</font>\n"
end

local function updateDoorHint(ent)
    if not DK.IsHintDoor(ent) then return end
    if not markup or not isfunction(markup.Parse) then return end

    local instructions = getDoorInstructions()
    if ent.HowToUseInstructions == instructions and ent.ZCityDoorKnockHintVersion == DK.Version then return end

    ent.HowToUseInstructions = instructions
    ent.HudHintMarkup = markup.Parse(
        "<font=ZCity_Tiny>Door</font>\n<font=ZCity_SuperTiny><colour=125,125,125>" .. instructions .. "</colour></font>",
        450
    )
    ent.ZCityDoorKnockHintVersion = DK.Version
end

local function updateAllDoorHints()
    for _, ent in ipairs(ents.FindByClass("prop_door_rotating")) do
        updateDoorHint(ent)
    end

    for _, ent in ipairs(ents.FindByClass("func_door_rotating")) do
        updateDoorHint(ent)
    end
end

hook.Add("Think", "ZCityDoorKnock_CleanupBones", function()
    for _, ply in ipairs(player.GetAll()) do
        local active = isOurMarker(ply) and ply.zmanipstart ~= nil

        if active and not ply.ZCityDoorKnockActive then
            ply.ZCityDoorKnockActive = true
            local weapon = ply:GetActiveWeapon()
            if IsValid(weapon) then
                ply.ZCityDoorKnockWeapon = weapon
                ply.ZCityDoorKnockOldLHIK = weapon.lhandik == true
            end
        elseif not active and ply.ZCityDoorKnockActive then
            cleanupPlayer(ply)
        end
    end
end)

hook.Add("EntityRemoved", "ZCityDoorKnock_CleanupRemovedPlayer", function(ent)
    if not ent:IsPlayer() then return end
    ent.ZCityDoorKnockActive = nil
    ent.ZCityDoorKnockWeapon = nil
    ent.ZCityDoorKnockOldLHIK = nil
end)

hook.Add("OnEntityCreated", "ZCityDoorKnock_DoorHintCreated", function(ent)
    if not DK.IsHintDoor(ent) then return end

    timer.Simple(0, function()
        if IsValid(ent) then updateDoorHint(ent) end
    end)

    timer.Simple(0.25, function()
        if IsValid(ent) then updateDoorHint(ent) end
    end)
end)

hook.Add("HomigradRun", "ZCityDoorKnock_RegisterAnimation", function()
    timer.Simple(0, registerAnimationPatch)
    timer.Simple(0.25, updateAllDoorHints)
end)

hook.Add("InitPostEntity", "ZCityDoorKnock_RegisterAnimationInit", function()
    timer.Simple(0, registerAnimationPatch)
    timer.Simple(0.25, updateAllDoorHints)
end)

timer.Create("ZCityDoorKnock_RegisterRetry", 0.25, 120, function()
    if registerAnimationPatch() then
        timer.Remove("ZCityDoorKnock_RegisterRetry")
    end
end)

timer.Create("ZCityDoorKnock_UpdateDoorHints", 2, 0, updateAllDoorHints)

local DK = ZCityDoorKnock

local cvDistance = CreateConVar(
    "zcity_doorknock_distance",
    tostring(DK.DefaultDistance),
    {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY},
    "Maximum trace distance for knocking.",
    24,
    DK.HardMaxDistance
)

local cvCooldown = CreateConVar(
    "zcity_doorknock_cooldown",
    "1.45",
    {FCVAR_ARCHIVE, FCVAR_NOTIFY},
    "Delay between door knocks for one player.",
    0.75,
    6
)

local cvAISound = CreateConVar(
    "zcity_doorknock_ai_sound",
    "1",
    {FCVAR_ARCHIVE, FCVAR_NOTIFY},
    "Allow NPCs and NextBots to hear door knocking.",
    0,
    1
)

local cvVolume = CreateConVar(
    "zcity_doorknock_volume",
    "0.82",
    {FCVAR_ARCHIVE, FCVAR_NOTIFY},
    "Volume of the custom knocking sound.",
    0,
    1
)

local cvPitch = CreateConVar(
    "zcity_doorknock_pitch",
    tostring(DK.DefaultSoundPitch),
    {FCVAR_ARCHIVE, FCVAR_NOTIFY},
    "Playback pitch of the custom knock sound.",
    60,
    100
)

local downloadablePath = "sound/" .. DK.SoundPath
if file.Exists(downloadablePath, "GAME") then
    resource.AddFile(downloadablePath)
end

local function getSoundDuration()
    local duration = SoundDuration(DK.SoundPath)
    if not isnumber(duration) or duration <= 0 then
        duration = DK.DefaultSoundDuration
    end

    return math.Clamp(duration, 0.55, 4.0)
end

local function outputConsole(ply, text)
    if IsValid(ply) then
        ply:PrintMessage(HUD_PRINTCONSOLE, text .. "\n")
    else
        ServerLog(text .. "\n")
    end
end

local function tryKnock(ply)
    if not DK.CanKnock(ply) then return false end

    local now = CurTime()
    if (ply.ZCityDoorKnockNext or 0) > now then return false end

    local tr = DK.TraceDoor(ply, cvDistance:GetFloat())
    if not tr then return false end

    local door = tr.Entity
    local hitPos = tr.HitPos
    local hitNormal = tr.HitNormal
    local soundDuration = getSoundDuration()
    local soundPitch = math.Clamp(cvPitch:GetInt(), 60, 100)
    local playbackDuration = soundDuration * (100 / soundPitch)
    local animationDuration = DK.SoundDelay + soundDuration + DK.AnimationTail
    local occupiedDuration = math.max(animationDuration, DK.SoundDelay + playbackDuration)

    ply.ZCityDoorKnockNext = now + math.max(cvCooldown:GetFloat(), occupiedDuration)

    if hg and isfunction(hg.RunZManipAnim) then
        hg.RunZManipAnim(
            ply,
            DK.AnimationName,
            false,
            animationDuration,
            {door, hitPos, hitNormal, DK.AnimationMarker, soundDuration, DK.SoundDelay}
        )
    end

    timer.Simple(DK.SoundDelay, function()
        if not IsValid(door) then return end
        sound.Play(DK.SoundPath, hitPos, 74, soundPitch, cvVolume:GetFloat())
    end)

    if cvAISound:GetBool() and hg and isfunction(hg.EmitAISound) then
        timer.Simple(DK.SoundDelay + playbackDuration * 0.5, function()
            if not IsValid(door) then return end
            hg.EmitAISound(hitPos, 280, math.max(0.8, playbackDuration), SOUND_PLAYER or 8)
        end)
    end

    return true
end

hook.Add("KeyPress", "ZCityDoorKnock_KeyPress", function(ply, key)
    if key ~= IN_RELOAD then return end
    tryKnock(ply)
end)

concommand.Add("zcity_doorknock_pitch_debug", function(ply)
    local pitch = math.Clamp(cvPitch:GetInt(), 60, 100)
    local speed = pitch / 100
    local durationScale = 100 / pitch
    outputConsole(ply, string.format(
        "[ZCity Door Knock] pitch=%d speed=%.2fx duration=%.2fx",
        pitch,
        speed,
        durationScale
    ))
end)

concommand.Add("zcity_doorknock_debug", function(ply)
    if not IsValid(ply) then
        outputConsole(ply, "[ZCity Door Knock] Run this command as a player.")
        return
    end

    local eyeTrace = ply:GetEyeTrace()
    local ent = eyeTrace.Entity
    local class = IsValid(ent) and ent:GetClass() or "invalid"
    local distance = math.Round(ply:EyePos():Distance(eyeTrace.HitPos), 1)
    local configuredDistance = cvDistance:GetFloat()
    local effectiveDistance = math.min(configuredDistance, DK.HardMaxDistance)
    local directTrace = DK.TraceDoor(ply, configuredDistance)
    local soundExists = file.Exists("sound/" .. DK.SoundPath, "GAME")
    local soundDuration = getSoundDuration()
    local soundPitch = math.Clamp(cvPitch:GetInt(), 60, 100)
    local playbackDuration = soundDuration * (100 / soundPitch)
    local zManipReady = hg and isfunction(hg.RunZManipAnim) or false

    outputConsole(ply, string.format(
        "[ZCity Door Knock %s] class=%s eyeDistance=%.1f effective=%.1f directHit=%s sound=%s duration=%.2f pitch=%d played=%.2f zManip=%s",
        DK.Version,
        class,
        distance,
        effectiveDistance,
        tostring(directTrace ~= nil),
        tostring(soundExists),
        soundDuration,
        soundPitch,
        playbackDuration,
        tostring(zManipReady)
    ))
end)

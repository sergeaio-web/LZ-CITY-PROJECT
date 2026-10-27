local FLAG = "zb_noclip_meaty_custom"
local SEE_DOT   = 0.6     -- европейский взгляд
local SEE_RANGE = 2200

local TELEPORT_COOLDOWN = 35
local TELEPORT_WARMUP   = 25 -- 15 minutes

local function IsSlasherTeleport(ply)
    return IsValid(ply) and ply:GetNWBool(FLAG, false)
end

hook.Add("EntityEmitSound", "HGTeleport_Silent", function(data)
    local ent = data.Entity
    if IsValid(ent) and ent:IsPlayer() and IsSlasherTeleport(ent) then
        return false
    end
end)

if SERVER then
    local function FindPlayer(search)
        search = string.lower(search)
        for _, ply in player.Iterator() do
            if string.lower(ply:Nick()) == search then return ply end
        end
        for _, ply in player.Iterator() do
            if string.find(string.lower(ply:Nick()), search, 1, true) then return ply end
        end
    end

    local function BlackoutObserversOf(target, pos, fadeTime, holdTime)
        pos = pos or target:EyePos()
        fadeTime = fadeTime or 0.7
        holdTime = holdTime or 0.4
        for _, observer in player.Iterator() do
            if observer == target then continue end
            if not observer:Alive() then continue end
            if IsSlasherTeleport(observer) then continue end

            local obsPos = observer:EyePos()
            local toPos  = pos - obsPos
            local dist   = toPos:Length()
            if dist > SEE_RANGE or dist < 1 then continue end

            toPos:Normalize()
            if observer:EyeAngles():Forward():Dot(toPos) < SEE_DOT then continue end

            local tr = util.TraceLine({
                start  = obsPos,
                endpos = pos,
                filter = { observer, target },
                mask   = MASK_SHOT,
            })
            if tr.Fraction >= 0.95 or tr.Entity == target then
                observer:ScreenFade(SCREENFADE.IN, Color(0, 0, 0), fadeTime, holdTime) -- sv_fear.lua нормальная темка
            end
        end
    end

    local function EnableNoclip(ply)
        if not IsValid(ply) then return end

        BlackoutObserversOf(ply, ply:EyePos())

        ply:SetNWBool(FLAG, true)

        ply.hgtele_oldCollision = ply:GetCollisionGroup()
        ply:GodEnable()
        
        ply.noSound = true
        ply:DrawShadow(false)
        ply:SetRenderMode(RENDERMODE_TRANSALPHA)
        ply:SetColor(Color(255, 255, 255, 0))

local wep = ply:GetActiveWeapon()
if IsValid(wep) then
    wep:SetNoDraw(true)
    wep:DrawShadow(false)

end
    end

    local function DisableNoclip(ply)
        if not IsValid(ply) then return end

        BlackoutObserversOf(ply, ply:EyePos(), 0.4, 1.2)

        
        ply:GodDisable()
        ply:SetCollisionGroup(ply.hgtele_oldCollision or COLLISION_GROUP_PLAYER)
        ply.noSound                = false
        
        ply.hgtele_oldCollision = nil

local wep = ply:GetActiveWeapon()
if IsValid(wep) then
    wep:DrawShadow(true)
end

        timer.Simple(0.5, function()
            if not IsValid(ply) then return end
            ply:SetNWBool(FLAG, false)
            ply:DrawShadow(true)
            ply:SetRenderMode(RENDERMODE_NORMAL)
            ply:SetColor(Color(255, 255, 255, 255))
        end)
    end

    concommand.Add("hg_teleport_toggle", function(adminPly, cmd, args)
        if IsValid(adminPly) and not adminPly:IsAdmin() then return end

        local state = tonumber(args[1])
        local name  = args[2]
        if name and args[3] then name = table.concat(args, " ", 2) end

        if state == nil or not name then
            local m = "Usage: zb_noclip_meaty <0|1> <player name>"
            if IsValid(adminPly) then adminPly:ChatPrint(m) else print(m) end
            return
        end

        state = math.Clamp(math.floor(state), 0, 1)

        local target = FindPlayer(name)
        if not IsValid(target) then
            local m = "Player not found: " .. name
            if IsValid(adminPly) then adminPly:ChatPrint(m) else print(m) end
            return
        end

        if state == 1 then EnableNoclip(target) else DisableNoclip(target) end

        local who = IsValid(adminPly) and adminPly:Nick() or "Console"
        print("[zb_noclip_meaty] " .. who .. " set horror noclip=" .. state .. " on " .. target:Nick())
    end)

    concommand.Add("hg_teleport", function(ply)
    if not IsValid(ply) then return end
    if ply.PlayerClassName ~= "Slasher" then return end

    local ct = CurTime()



    if not IsSlasherTeleport(ply) then
        if ct < (ply.TeleportUnlockTime or 0) then
            ply:ChatPrint("Teleport on starting cooldown")
            return
        end

        if ct < (ply.NextTeleportUse or 0) then
            ply:ChatPrint("on cooldown.")
            return
        end

        EnableNoclip(ply)
    else
        DisableNoclip(ply)
    ply.NextTeleportUse = ct + TELEPORT_COOLDOWN

    timer.Simple(TELEPORT_COOLDOWN, function()
        if not IsValid(ply) then return end
        if ply.PlayerClassName ~= "Slasher" then return end

        ply:ChatPrint("Teleport ready.")
    end)
end
end)

hook.Add("PlayerSwitchWeapon", "HGTeleport_NoWeapons", function(ply)
    if IsSlasherTeleport(ply) then
        return true
    end
end)


hook.Add("StartCommand", "HGTeleport_BlockAttack", function(ply, cmd)
    if not IsSlasherTeleport(ply) then return end

    cmd:RemoveKey(IN_ATTACK)
    cmd:RemoveKey(IN_ATTACK2)
end)

    hook.Add("EntityTakeDamage", "HGTeleport_NoDamage", function(ent, dmg)
        if IsSlasherTeleport(ent) then return true end
    end)

    hook.Add("PlayerFootstep", "HGTeleport_Silent", function(ply)
        if IsSlasherTeleport(ply) then return true end
    end)

    hook.Add("PlayerDeath", "HGTeleport_Cleanup", function(victim)
        if IsSlasherTeleport(victim) then DisableNoclip(victim) end
    end)
    hook.Add("PlayerDisconnected", "HGTeleport_Cleanup", function(ply)
        if IsSlasherTeleport(ply) then DisableNoclip(ply) end
    end)

hook.Add("Think", "HGTeleport_ForceVictimVisible", function()
    for _, ply in player.Iterator() do
        if IsSlasherTeleport(ply) and ply.PlayerClassName ~= "Slasher" then
            DisableNoclip(ply)
        end
    end
end)
end
 
if CLIENT then
    hook.Add("PrePlayerDraw", "HGTeleport_Hide", function(ply)
        if IsSlasherTeleport(ply) then
            return true
        end
    end)

    local function ApplyHide(ent, hide)
        if not IsValid(ent) then return end
        if hide then
            if ent:GetMaterial() ~= "NULL" then
                ent.zb_noclip_oldMat = ent:GetMaterial()
                ent:SetMaterial("NULL")
                ent:SetNoDraw(true)
                ent:DrawShadow(false)
            end
            ent.NotSeen = true
            ent.zb_noclip_wasHidden = true
        elseif ent.zb_noclip_wasHidden then
            ent:SetMaterial(ent.zb_noclip_oldMat or "")
            ent:SetNoDraw(false)
            ent:DrawShadow(true)
            ent.NotSeen = nil
            ent.zb_noclip_oldMat = nil
            ent.zb_noclip_wasHidden = false
        end
    end




    hook.Add("PreDrawOpaqueRenderables", "HGTeleport_HideRagdolls", function()
        for _, ply in player.Iterator() do
            local hide = IsSlasherTeleport(ply)

            ApplyHide(ply.FakeRagdoll, hide)
            ApplyHide(ply.OldRagdoll, hide)

            local char = ply.GetCurrentCharacter and hg.GetCurrentCharacter(ply)
            if IsValid(char) and char ~= ply then
                ApplyHide(char, hide)
            end

            if IsValid(ply) then
                if hide then
                    ply.NotSeen = true
                    ply.hgtele_plyNotSeen = true
                elseif ply.hgtele_plyNotSeen then
                    ply.NotSeen = nil
                    ply.hgtele_plyNotSeen = false
                end
            end
        end
    end)

    timer.Simple(0, function()
        if _G.DrawAccesories and not _G.hgtele_DrawAccWrapped then
            local realDrawAcc = _G.DrawAccesories
            _G.DrawAccesories = function(ply, ent, accessories, accessData, islply, force, setup)
                local owner = ply
                if IsValid(owner) and owner.IsRagdoll and owner:IsRagdoll() and hg.RagdollOwner then
                    owner = hg.RagdollOwner(owner) or owner
                end

                if (IsValid(ply) and IsSlasherTeleport(ply))
                    or (IsValid(owner) and owner:IsPlayer() and IsSlasherTeleport(owner)) then
                    return
                end

                return realDrawAcc(ply, ent, accessories, accessData, islply, force, setup)
            end
            _G.hgtele_DrawAccWrapped = true
        end
    end)
end
-- designed and realized by alagri & omnissiah respectively
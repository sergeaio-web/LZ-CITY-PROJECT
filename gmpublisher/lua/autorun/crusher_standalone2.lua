--   give_supercrusher  <player name>
--   remove_supercrusher <player name>
--   zb_crusher_hints
--   zb_crusher_hints_toggle
if SERVER then AddCSLuaFile() end

local SUPERCRUSHER_SUBROLE    = "traitor_strangler"
local CRUSHER_REACH      = 85
local CRUSHER_NECK_REACH = 90
local SUPERCRUSHER_HP_MUL     = 1
local SUPERCRUSHER_BASE_HP    = 100

local function IsCrusher(ply)
    return ply.SubRole == "traitor_strangler"
        or ply.SubRole == "traitor_strangler_soe"
end

local function GetCrusherTrace(ply, dist)
    local trace = hg.eyeTrace(ply, dist)
    if not trace then return nil end
    local aim_ent, other_ply = trace.Entity
    if IsValid(aim_ent) then
        if aim_ent:IsPlayer() then
            other_ply = aim_ent
        elseif aim_ent:IsRagdoll() and IsValid(aim_ent.ply) then
            other_ply = aim_ent.ply
        end
    end
    return aim_ent, other_ply, trace
end

local function CanGrabTarget(aim_ent, other_ply)
    if aim_ent:IsPlayer() then
        return aim_ent:Alive()
    elseif aim_ent:IsRagdoll() then
        return IsValid(other_ply) and other_ply:Alive()
    end
    return false
end

local function StartGrabbingHead(ply, other_ply)
    ply.Ability_HeadGrab = { Victim = other_ply, Progress = 0, Grabbed = false }
    other_ply.BeingVictimOfHeadGrab = true
    if SERVER then
        other_ply:ViewPunch(Angle(0, -5, -5))
        net.Start("HMCD_BeingVictimOfHeadGrab")
        net.WriteBool(true)
        net.Send(other_ply)
        net.Start("HMCD_GrabbingHead")
        net.WriteBool(true)
        net.WriteEntity(ply)
        net.WriteEntity(other_ply)
        net.SendPVS(ply:GetShootPos())
    end
end

local function StopGrabbingHead(ply)
   

if not ply.Ability_HeadGrab then return end

    local victim = ply.Ability_HeadGrab.Victim

    if SERVER and IsValid(victim) and victim:Alive() then
        victim.BeingVictimOfHeadGrab = false

        if victim.organism then
            victim.organism.choking = false
        end

     
        -- stand victim back up
        timer.Simple(0, function()
            if not IsValid(victim) or not victim:Alive() then return end

            local rag = hg.GetCurrentCharacter(victim)

            if IsValid(rag) and rag ~= victim then
                if hg.UnRagdollPlayer then
                    hg.UnRagdollPlayer(victim)
                end
            end
        end)
    end

    if SERVER then
        if IsValid(victim) then
            net.Start("HMCD_BeingVictimOfHeadGrab")
            net.WriteBool(false)
            net.Send(victim)
        end
        net.Start("HMCD_GrabbingHead")
        net.WriteBool(false)
        net.WriteEntity(ply)
        net.SendPVS(ply:GetShootPos())
        hg.SetCarryEnt2(ply)
    end


    ply.Ability_HeadGrab = nil
end


local function ContinueGrabbingHead(ply)
    local grab_data = ply.Ability_HeadGrab
    if not grab_data then return end
    local victim = grab_data.Victim
    if not IsValid(victim) or not victim:Alive() then
        StopGrabbingHead(ply)
        return 
    end
    if grab_data.Grabbed then return end

    local aim_ent, other_ply = GetCrusherTrace(ply, CRUSHER_REACH)
    if not IsValid(aim_ent) or not CanGrabTarget(aim_ent, other_ply) or other_ply ~= victim then
        StopGrabbingHead(ply)
        return
    end

    grab_data.Progress = grab_data.Progress + FrameTime() * 400
    if grab_data.Progress < 100 then return end

    if CLIENT then
        grab_data.Progress = 100
        return
    end

    grab_data.Grabbed = true
    grab_data.GrabbedAt = CurTime()
    if SERVER then
        net.Start("HMCD_GrabConfirmed")
        net.WriteBool(true)
        net.WriteEntity(victim)
        net.Send(ply)

        local already_rag = IsValid(hg.GetCurrentCharacter(victim)) and hg.GetCurrentCharacter(victim) ~= victim
        if not already_rag then hg.LightStunPlayer(victim) end

        local attempts = 0
        local function TryCarry()
            if not IsValid(ply) or not IsValid(victim) then return end
            if not ply.Ability_HeadGrab or not ply.Ability_HeadGrab.Grabbed then return end

            local rag = hg.GetCurrentCharacter(victim)
            local bon = IsValid(rag) and rag ~= victim and rag:LookupBone("ValveBiped.Bip01_Head1")
            local phys = bon and rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(bon))

            if IsValid(rag) and rag ~= victim and bon and IsValid(phys) then
                local dist = 25
                hg.SetCarryEnt2(
                    ply, rag, bon, phys:GetMass(),
                    Vector(-2, 0, 0),
                    ply:GetAimVector() * dist
                    + ply:EyeAngles():Up() * 5
                    + ply:EyeAngles():Right() * -5
                    + ply:GetShootPos(),
                    ply:EyeAngles() + Angle(-90, 90, 0)
                )
                return
            end

            attempts = attempts + 1
            if attempts < 20 then
                timer.Simple(0, TryCarry)
            else
                StopGrabbingHead(ply)
            end
        end
        timer.Simple(0, TryCarry)
    end
end

local function CrushVictimHead(ply)
    local grab_data = ply.Ability_HeadGrab
    if not grab_data or not grab_data.Grabbed then return end
    local victim = grab_data.Victim
    if not IsValid(victim) or not victim:Alive() then
        StopGrabbingHead(ply)
        return
    end
    if SERVER then
        if victim.noHead then victim:Kill() else hg.ExplodeHead(victim) end
    end
    ply.CrusherInjectReload = CurTime() + 0.15
end

local function NeckTraceToVictim(ply, victim, dist)
    dist = dist or CRUSHER_NECK_REACH
    if IsValid(victim) then
        local ragdoll = victim.FakeRagdoll or victim:GetNWEntity("RagdollDeath", victim.FakeRagdoll)
        if not IsValid(ragdoll) then ragdoll = victim end
        local bone_id = ragdoll:LookupBone("ValveBiped.Bip01_Spine2")
        if bone_id then
            local bone_matrix = ragdoll:GetBoneMatrix(bone_id)
            if bone_matrix then
                local pos        = bone_matrix:GetTranslation()
                local offset_dir = pos - ply:GetShootPos()
                offset_dir:Normalize()
                local aim_ent, other_ply, trace = GetCrusherTrace(ply, dist)
                if IsValid(aim_ent) then return aim_ent, other_ply, trace end
            end
        end
    end
    return GetCrusherTrace(ply, dist)
end

local function CanCrusherBreakNeck(ply, aim_ent)
    if aim_ent:IsRagdoll() then
        local bone_id = aim_ent:LookupBone("ValveBiped.Bip01_Head1")
        if bone_id then
            local bone_matrix = aim_ent:GetBoneMatrix(bone_id)
            if bone_matrix then
                local pos          = bone_matrix:GetTranslation()
                local ang          = bone_matrix:GetAngles()
                local other_normal = -ang:Right()
                local ply_normal   = pos - ply:GetShootPos()
                local dist_z       = math.abs(pos.z - ply:GetShootPos().z)

                if dist_z < 50 then
                    ply_normal:Normalize()
                    local ang_diff = -(math.deg(math.acos(ply_normal:DotProduct(other_normal))) - 180)
                    if ang_diff < 100 then
                        return true
                    end
                end
            end
        end
    elseif aim_ent:IsPlayer() then
        local other_angle = aim_ent:EyeAngles()[2]
        local ply_angle   = (aim_ent:GetPos() - ply:GetPos()):Angle()[2]
        local ang_diff    = math.abs(math.AngleDifference(other_angle, ply_angle))
        if ang_diff < 100 then
            return true
        end
    end

    return false
end

local function BreakOtherNeck(ply, other_ply, aim_ent)
    if not IsValid(other_ply) or not other_ply:Alive() then return end

    other_ply:Kill()
    other_ply:ViewPunch(Angle(0, 0, -10))

    ply.CrusherInjectReload = CurTime() + 0.15

    if IsValid(aim_ent) then
        if aim_ent.organism then aim_ent.organism.spine3 = 1 end
        aim_ent:EmitSound("neck_snap_01.wav", 60, 100, 1, CHAN_AUTO)
    else
        other_ply:EmitSound("neck_snap_01.wav", 60, 100, 1, CHAN_AUTO)
    end

    timer.Simple(0.1, function()
        local ent = other_ply:GetNWEntity("RagdollDeath")
        if not IsValid(ent) then return end

        ent:RemoveInternalConstraint(ent:TranslateBoneToPhysBone(ent:LookupBone("ValveBiped.Bip01_Head1")))

        local spine  = ent:TranslateBoneToPhysBone(ent:LookupBone("ValveBiped.Bip01_Spine2"))
        local head   = ent:TranslateBoneToPhysBone(ent:LookupBone("ValveBiped.Bip01_Head1"))
        local pspine = ent:GetPhysicsObjectNum(spine)
        local phead  = ent:GetPhysicsObjectNum(head)
        if not IsValid(pspine) or not IsValid(phead) then return end

        local lpos, lang = WorldToLocal(
            phead:GetPos() + phead:GetAngles():Forward() * -2 + phead:GetAngles():Up() * -1.5,
            angle_zero,
            pspine:GetPos(), pspine:GetAngles()
        )

        phead:SetPos(pspine:GetPos() + pspine:GetAngles():Forward() * 12.9 + pspine:GetAngles():Right() * -1)

        constraint.AdvBallsocket(ent, ent, spine, head, lpos, nil, 0, 0, -55, -90, -50, 55, 35, 50, 0, 0, 0, 0, 0)
    end)
end

local function StartBreakingNeck(ply, other_ply)
    ply.Ability_NeckBreak = { Victim = other_ply, Progress = 0 }
    other_ply.BeingVictimOfNeckBreak = true
    if SERVER then
        other_ply:ViewPunch(Angle(0, -10, -10))
        net.Start("HMCD_BeingVictimOfNeckBreak")
        net.WriteBool(true)
        net.Send(other_ply)
        net.Start("HMCD_BreakingOtherNeck")
        net.WriteBool(true)
        net.WriteEntity(ply)
        net.WriteEntity(other_ply)
        net.SendPVS(ply:GetShootPos())
    end
end

local function StopBreakingNeck(ply)
    if ply.Ability_NeckBreak and IsValid(ply.Ability_NeckBreak.Victim) then
        ply.Ability_NeckBreak.Victim.BeingVictimOfNeckBreak = false
        if SERVER then
            net.Start("HMCD_BeingVictimOfNeckBreak")
            net.WriteBool(false)
            net.Send(ply.Ability_NeckBreak.Victim)
            net.Start("HMCD_BreakingOtherNeck")
            net.WriteBool(false)
            net.WriteEntity(ply)
            net.SendPVS(ply:GetShootPos())
        end
    end
    ply.Ability_NeckBreak = nil
end

local function ContinueBreakingNeck(ply)
    local break_data = ply.Ability_NeckBreak
    if not break_data then return end
    local victim = break_data.Victim

    if not IsValid(victim) or not victim:Alive() then
        StopBreakingNeck(ply)
        return
    end

    if ply.Ability_HeadGrab and ply.Ability_HeadGrab.Victim == victim then -- много хочешь
        StopBreakingNeck(ply)
        return
    end

    local aim_ent, other_ply = NeckTraceToVictim(ply, victim)

    if IsValid(aim_ent) and (aim_ent:IsPlayer() or aim_ent:IsRagdoll())
        and CanCrusherBreakNeck(ply, aim_ent) and other_ply == victim then
        break_data.Progress = break_data.Progress + FrameTime() * 300
        if break_data.Progress >= 100 then
            if SERVER then BreakOtherNeck(ply, victim, aim_ent) end
            StopBreakingNeck(ply)
        end
    else
        StopBreakingNeck(ply)
    end
end

local NoDisarmWeapons = {
    ["weapon_hands_sh"] = true,
}

local function DisarmOther(ply, other_ply)
    if not IsValid(other_ply) or not other_ply:Alive() then return end
    local weapon = other_ply:GetActiveWeapon()
    if IsValid(weapon) and not weapon.NoDrop and not NoDisarmWeapons[weapon:GetClass()] then
        other_ply:DropWeapon(weapon)
    end
end

if SERVER then
    util.AddNetworkString("HMCD_BeingVictimOfHeadGrab")
    util.AddNetworkString("HMCD_GrabbingHead")
    util.AddNetworkString("HMCD_GrabConfirmed")
    util.AddNetworkString("HMCD_Strangler_CrushRequest")
    util.AddNetworkString("Crusher_SetSubRole")
    util.AddNetworkString("HMCD_BeingVictimOfNeckBreak")
    util.AddNetworkString("HMCD_BreakingOtherNeck")
    util.AddNetworkString("HMCD_Crusher_NeckBreakRequest")
    util.AddNetworkString("HMCD_Crusher_NeckBreakStop")

    net.Receive("HMCD_Strangler_CrushRequest", function(len, ply)
        if not IsValid(ply) or not ply:Alive() then return end
        if not IsCrusher(ply) then return end
        if not (ply.Ability_HeadGrab and ply.Ability_HeadGrab.Grabbed) then return end
        local victim = ply.Ability_HeadGrab.Victim
        if IsValid(victim) and victim:Alive() then
            CrushVictimHead(ply)
        else
            StopGrabbingHead(ply)
        end
    end)

    net.Receive("HMCD_Crusher_NeckBreakRequest", function(len, ply)
        if not IsValid(ply) or not ply:Alive() then return end
        if not IsCrusher(ply) then return end
        if ply.Ability_NeckBreak then return end

        local victim = net.ReadEntity()
        if not IsValid(victim) or not victim:IsPlayer() or not victim:Alive() then return end


        if ply.Ability_HeadGrab and ply.Ability_HeadGrab.Victim == victim then return end -- много хочешь x2

        local aim_ent = NeckTraceToVictim(ply, victim, CRUSHER_NECK_REACH)
        if not IsValid(aim_ent) or not CanCrusherBreakNeck(ply, aim_ent) then return end

        StartBreakingNeck(ply, victim)
    end)

    net.Receive("HMCD_Crusher_NeckBreakStop", function(len, ply)
        if not IsValid(ply) then return end
        StopBreakingNeck(ply)
    end)

    local boneToLimbFunc = {
        ["ValveBiped.Bip01_Head1"]      = function(org, ent) if not ent.noHead then hg.ExplodeHead(ent) end end,
        ["ValveBiped.Bip01_Pelvis"]     = function(org, ent) org.spine1 = 1 end,
        ["ValveBiped.Bip01_Spine2"]     = function(org, ent) org.spine2 = 1 end,
        ["ValveBiped.Bip01_R_UpperArm"] = function(org, ent) if not org["rarm" .. "amputated"] then hg.organism
                    .AmputateLimb(org, "rarm") end end,
        ["ValveBiped.Bip01_R_Forearm"]  = function(org, ent) if not org["rarm" .. "amputated"] then hg.organism
                    .AmputateLimb(org, "rarm") end end,
        ["ValveBiped.Bip01_R_Hand"]     = function(org, ent) if not org["rarm" .. "amputated"] then hg.organism
                    .AmputateLimb(org, "rarm") end end,
        ["ValveBiped.Bip01_L_UpperArm"] = function(org, ent) if not org["larm" .. "amputated"] then hg.organism
                    .AmputateLimb(org, "larm") end end,
        ["ValveBiped.Bip01_L_Forearm"]  = function(org, ent) if not org["larm" .. "amputated"] then hg.organism
                    .AmputateLimb(org, "larm") end end,
        ["ValveBiped.Bip01_L_Hand"]     = function(org, ent) if not org["larm" .. "amputated"] then hg.organism
                    .AmputateLimb(org, "larm") end end,
        ["ValveBiped.Bip01_R_Thigh"]    = function(org, ent) if not org["rleg" .. "amputated"] then hg.organism
                    .AmputateLimb(org, "rleg") end end,
        ["ValveBiped.Bip01_R_Calf"]     = function(org, ent) if not org["rleg" .. "amputated"] then hg.organism
                    .AmputateLimb(org, "rleg") end end,
        ["ValveBiped.Bip01_R_Foot"]     = function(org, ent) if not org["rleg" .. "amputated"] then hg.organism
                    .AmputateLimb(org, "rleg") end end,
        ["ValveBiped.Bip01_L_Thigh"]    = function(org, ent) if not org["lleg" .. "amputated"] then hg.organism
                    .AmputateLimb(org, "lleg") end end,
        ["ValveBiped.Bip01_L_Calf"]     = function(org, ent) if not org["lleg" .. "amputated"] then hg.organism
                    .AmputateLimb(org, "lleg") end end,
        ["ValveBiped.Bip01_L_Foot"]     = function(org, ent) if not org["lleg" .. "amputated"] then hg.organism
                    .AmputateLimb(org, "lleg") end end,
    }

    local function ApplyStompLimbDamage(ply)
        if not IsValid(ply) or not ply:Alive() then return end

        local ang        = ply:EyeAngles()
        local inDuck     = ply:KeyDown(IN_DUCK) or ply:Crouching()

        ang[1]           = inDuck and 0 or math.max(ang[1], 10)

        local reportPos  = ply:GetPos() + ply:OBBCenter() + ply:GetUp() * (-5)
        local traceStart = inDuck and reportPos or ply:EyePos()
        local rad        = Vector(5, 5, 5)

        local tr         = util.TraceHull({
            start  = traceStart,
            endpos = traceStart + ang:Forward() * 90,
            filter = { ply, hg.GetCurrentCharacter(ply) },
            mins   = -rad,
            maxs   = rad,
        })

        local ragdoll, hit_bonename

        if tr.Hit and IsValid(tr.Entity) and tr.Entity:IsRagdoll() then
            ragdoll      = tr.Entity
            hit_bonename = ragdoll:GetBoneName(ragdoll:TranslatePhysBoneToBone(tr.PhysicsBone or 0))
        else
            local feet   = ply:GetPos() + Vector(0, 0, 5)
            local best_d = 120 ^ 2
            for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 120)) do
                if not ent:IsRagdoll() then continue end
                if not IsValid(ent.ply) or not ent.ply:Alive() then continue end
                for i = 0, ent:GetPhysicsObjectCount() - 1 do
                    local phys = ent:GetPhysicsObjectNum(i)
                    if not IsValid(phys) then continue end
                    local d = phys:GetPos():DistToSqr(feet)
                    if d < best_d then
                        best_d       = d
                        ragdoll      = ent
                        hit_bonename = ent:GetBoneName(ent:TranslatePhysBoneToBone(i))
                    end
                end
            end
        end

        if not IsValid(ragdoll) then return end
        local victim = ragdoll.ply
        if not IsValid(victim) or not victim:Alive() or not victim.organism then return end

        local limbFunc = boneToLimbFunc[hit_bonename] or boneToLimbFunc["ValveBiped.Bip01_R_Calf"]
        limbFunc(victim.organism, victim)
    end

hook.Add("PlayerDeath","SuperCrusher_ForceRelease",function(ply)
    if ply.Ability_HeadGrab then
        StopGrabbingHead(ply)
    end
end)

    hook.Add("PlayerPostThink", "SuperCrusher_Abilities", function(ply)
       


	 -- Cleanup stuck victims
    if ply.BeingVictimOfHeadGrab then
        local grabbed = false

        for _, v in player.Iterator() do
            if v.Ability_HeadGrab and v.Ability_HeadGrab.Victim == ply then
                grabbed = true
                break
            end
        end

        if not grabbed then
            

            ply.BeingVictimOfHeadGrab = false

            if ply.organism then
                ply.organism.choking = false
            end
        end
    end

    if not ply:Alive() then return end
    if not IsCrusher(ply) then return end

	if not ply:Alive() then return end
        if not IsCrusher(ply) then return end

        if ply.Ability_NeckBreak then ContinueBreakingNeck(ply) end

        if ply:KeyPressed(IN_RELOAD) and ply.Ability_HeadGrab then
            StopGrabbingHead(ply)
            return
        end

        -- харассмент
        if ply:KeyDown(IN_WALK) then
            if ply:KeyDown(IN_USE) then
                if ply:KeyPressed(IN_USE) then
		if ply:GetNWBool("zb_noclip_meaty", false) then
        	return
    		end
                    StopGrabbingHead(ply)
                    local aim_ent, other_ply = GetCrusherTrace(ply, CRUSHER_REACH)
                    if IsValid(aim_ent) and other_ply and CanGrabTarget(aim_ent, other_ply) then
                        StartGrabbingHead(ply, other_ply)
                        DisarmOther(ply, other_ply)
                    end
                elseif ply.Ability_HeadGrab then
                    ContinueGrabbingHead(ply)
                end
            else
                if ply.Ability_HeadGrab and not ply.Ability_HeadGrab.Grabbed then
                    StopGrabbingHead(ply)
                end
            end
        else
            if ply.Ability_HeadGrab and not ply.Ability_HeadGrab.Grabbed then
                StopGrabbingHead(ply)
            end
        end

        local grab_data = ply.Ability_HeadGrab
        if grab_data and grab_data.Grabbed then
            local victim    = grab_data.Victim

            local graceOver = (grab_data.GrabbedAt or 0) + 0.5 < CurTime()
            local carryent  = ply:GetNetVar("carryent2")

            local stillHeld = IsValid(victim)
            if stillHeld and graceOver and not IsValid(carryent) then
                stillHeld = false
            end

            if stillHeld and graceOver and victim:Alive() then
                local dist = ply:GetShootPos():Distance(victim:GetPos())
                if dist > CRUSHER_REACH * 3 then stillHeld = false end
            end

            if not stillHeld then
                StopGrabbingHead(ply)
            else
                if victim:Alive() and victim.organism then
                    victim.organism.choking = true
                    if zb then
                        local dmgInfo = DamageInfo()
                        dmgInfo:SetAttacker(ply)
                        hook.Run("HomigradDamage", victim, dmgInfo, HITGROUP_HEAD,
                            hg.GetCurrentCharacter(victim),
                            FrameTime() * ((zb.MaximumHarm or 10) / 50))
                    end
                    if victim.organism.otrub then
                        ply:Notify("They seem unresponsive.", 60, "choked" .. victim:EntIndex())
                    end
                end
            end
        end

        local kicking = (ply.InLegKick or 0) > CurTime()
        if kicking and not ply.CrusherStompScheduled then
            ply.CrusherStompScheduled = true
            if ply:EyeAngles()[1] >= 20 then
                timer.Simple(0.33, function()
                    ApplyStompLimbDamage(ply)
                end)
            end
        elseif not kicking then
            ply.CrusherStompScheduled = false
        end
    end)

    hook.Add("HG_MovementCalc_2", "SuperCrusher_Abilities", function(mul, ply)
        if ply.BeingVictimOfHeadGrab then mul[1] = mul[1] * 0.2 end
    end)

    -- к мертвецам либо хорошо, либо никак
    hook.Add("StartCommand", "Crusher_SA_InjectReload", function(ply, cmd)
        if ply.CrusherInjectReload then
            if ply.CrusherInjectReload > CurTime() then
                cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_RELOAD))
            else
                ply.CrusherInjectReload = nil
            end
        end
    end)

    hook.Add("Should Fake Up", "SuperCrusher_FakeUp", function(ply)
        if ply.BeingVictimOfHeadGrab then return false end
    end)

    hook.Add("PlayerDisconnected", "SuperCrusher_Abilities", function(ply)
        StopGrabbingHead(ply)
        StopBreakingNeck(ply)
    end)

    local function OrgIsProtectedCrusher(org)
        return org and IsValid(org.owner) and org.owner.CrusherNoLimbLoss == true
    end

    -- тщетная попытка защиты конечностей
    if hg and hg.organism and hg.organism.AmputateLimb and not hg.organism._CrusherAmputateWrapped then
        local realAmputate = hg.organism.AmputateLimb
        hg.organism.AmputateLimb = function(org, ...)
            if OrgIsProtectedCrusher(org) then return end
            return realAmputate(org, ...)
        end
        hg.organism._CrusherAmputateWrapped = true
    end


    if hg and hg.organism and hg.organism.input_list and not hg.organism._CrusherInputWrapped then
        for _, fname in ipairs({ "larmup", "rarmup", "llegup", "rlegup", "spine1", "spine2", "spine3" }) do
            local real = hg.organism.input_list[fname]
            if real then
                hg.organism.input_list[fname] = function(org, ...)
                    if OrgIsProtectedCrusher(org) then return end
                    return real(org, ...)
                end
            end
        end
        hg.organism._CrusherInputWrapped = true
    end


    hook.Add("HomigradDamage", "SuperCrusher_HPScale", function(victim, dmgInfo, hitgroup, ragdoll, amount)
        if not IsValid(victim) or not victim.CrusherNoLimbLoss then return end
        if IsValid(dmgInfo) or dmgInfo then
            -- dmgInfo
            if isfunction(dmgInfo.SetDamage) and isfunction(dmgInfo.GetDamage) then
                dmgInfo:SetDamage(dmgInfo:GetDamage() / SUPERCRUSHER_HP_MUL)
            end
        end
    end)

    -- а чё бы нет
    hook.Add("EntityTakeDamage", "SuperCrusher_HPScale", function(ent, dmgInfo)
        if not IsValid(ent) or not ent:IsPlayer() then return end
        if not ent.CrusherNoLimbLoss then return end
        dmgInfo:ScaleDamage(1 / SUPERCRUSHER_HP_MUL)
    end)

    local function FindPlayer(search)
        search = string.lower(search)
        for _, v in player.Iterator() do
            if string.find(string.lower(v:Nick()), search, 1, true) then return v end
        end
    end

    concommand.Add("give_supercrusher", function(adminPly, cmd, args)
        if IsValid(adminPly) and not adminPly:IsAdmin() then
            adminPly:ChatPrint("You don't have permission to use this command.")
            return
        end
        if not args[1] then
            local m = "Usage: give_supercrusher <player name>"
            if IsValid(adminPly) then adminPly:ChatPrint(m) else print(m) end
            return
        end
        local target = FindPlayer(args[1])
        if not IsValid(target) then
            local m = "Player not found: " .. args[1]
            if IsValid(adminPly) then adminPly:ChatPrint(m) else print(m) end
            return
        end
        target.SubRole = SUPERCRUSHER_SUBROLE
        
        -- 		             ⢀⣀
        --  ⣠⣴⣾⣶⣶⣤⣄⣄⣤⣶⣾⣿⣿⣿⣿⣿⣶⣤⢀⣀
        -- ⡈⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⢸⣿⣿⣶⡄
        -- ⡇⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢸⣯⣕⣶⡇
        -- ⢰⣿⡟⠙⠿⠿⠿⣿⣹⣿⠟⠛⠛⠋⠁⠈⠻⣿⣿⣧⠹⣿⣿⠁
        -- ⠘⣟⣤⠠ ⠤ ⡘⣿⣿⡷⠄⡀⢐⡒⠻⠻⣿⣿⣿⡇⠿⣫⢤
        -- ⠃⣿⣿⣜⣋⣀⠜⡪⣸⣿⣧⣼⣇⣩⣠⣬⣁⣾⣿⣿⣿⣰⡇⣠⡀
        --  ⣿⣿⣿⣿⣿⣿⡇⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡆⣨
        -- ⣶⡘⣿⣿⣿⣿⣿⡇⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢏⣼⣿⣵⠏
        -- ⠘⣷⡸⣿⣿⣿⣿⣇⠻⠿⠛⢹⣿⣿⣿⣿⣿⣿⢃⣾⣿⠿⠏
        --  ⠸⡇⣿⣿⡿⠛ ⠁   ⠉⠛⢿⣿⣿⣿⢸⣿⣿⢠⡆
        --   ⣇⢿⣿⠁   ⢀⣀⣀⣀ ⢿⣿⡟⣸⣿⣿⢸⡇
        --   ⢻⡜⣿⣴⣿⣿⣯⣛⣛⣿⣿⣿⣶⣬⣿⢣⣿⡿⠃⣠⡇
        --   ⢻⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⣿⠟ ⣸⣿⣇
        --    ⣆⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢃⢂⣼⣿⣿⣿
        --    ⢿⣧⠹⣿⣿⣿⣷⣿⣿⣿⣿⣿⡟⣱⢃⣾⣿⣿⣿⣿⣄⡀
        --    ⠸⠿⠷⠔⠭⠭⠭⠭⠭⠥⠶⠶⠾⠇⠾⠿⠿⠿⠿⠿⠿⠿
        target:SetMaxHealth(SUPERCRUSHER_BASE_HP * SUPERCRUSHER_HP_MUL)
        target:SetHealth(SUPERCRUSHER_BASE_HP * SUPERCRUSHER_HP_MUL)

        if target.organism then
            target.organism.superfighter = true
        end

        net.Start("Crusher_SetSubRole")
        net.WriteString(SUPERCRUSHER_SUBROLE)
        net.Send(target)
        local who = IsValid(adminPly) and adminPly:Nick() or "Console"
        print(who .. " Slasher is " .. target:Nick())
        if IsValid(adminPly) then adminPly:ChatPrint("Slasher is " .. target:Nick()) end
        target:ChatPrint("Controls: [WALK KEY + E grabs victims, R releases them.] bind a key to crusher_crush to destroy the head of anyone held, bind hg_teleport to go invisible, also you can't loot or pickup certain weapons/items")
    end)

    concommand.Add("remove_supercrusher", function(adminPly, cmd, args)
        if IsValid(adminPly) and not adminPly:IsAdmin() then
            adminPly:ChatPrint("You don't have permission to use this command.")
            return
        end
        if not args[1] then
            local m = "Usage: remove_supercrusher <player name>"
            if IsValid(adminPly) then adminPly:ChatPrint(m) else print(m) end
            return
        end
        local target = FindPlayer(args[1])
        if not IsValid(target) then
            local m = "Player not found: " .. args[1]
            if IsValid(adminPly) then adminPly:ChatPrint(m) else print(m) end
            return
        end
        StopGrabbingHead(target)
        StopBreakingNeck(target)
        target.SubRole = nil
        
        if target.organism then target.organism.superfighter = nil end
        target:SetMaxHealth(SUPERCRUSHER_BASE_HP)
        if target:Health() > SUPERCRUSHER_BASE_HP then target:SetHealth(SUPERCRUSHER_BASE_HP) end
        net.Start("Crusher_SetSubRole")
        net.WriteString("")
        net.Send(target)
        local who = IsValid(adminPly) and adminPly:Nick() or "Console"
        print(who .. " removed Crusher from " .. target:Nick())
        if IsValid(adminPly) then adminPly:ChatPrint("Removed Crusher from " .. target:Nick()) end
    end)

    local function ClearCrusher(target, restoreHealth)
        if not IsValid(target) then return end
        StopGrabbingHead(target)
        StopBreakingNeck(target)
        target.SubRole = nil
        
        if target.organism then target.organism.superfighter = nil end
        if restoreHealth then
            target:SetMaxHealth(SUPERCRUSHER_BASE_HP)
            if target:Health() > SUPERCRUSHER_BASE_HP then target:SetHealth(SUPERCRUSHER_BASE_HP) end
        end
        net.Start("Crusher_SetSubRole")
        net.WriteString("")
        net.Send(target)
    end

   hook.Add("PlayerDeath", "SuperCrusher_ClearOnDeath", function(victim)

    victim.BeingVictimOfHeadGrab = false

    if victim.organism then
        victim.organism.choking = false
    end

    if IsValid(victim) and IsCrusher(victim) then
        ClearCrusher(victim, false)
        -- print("[Crusher] " .. victim:Nick() .. " died — crusher role cleared.")
    end
end)


    -- а чё бы нет x2
    hook.Add("PlayerSilentDeath", "SuperCrusher_ClearOnDeath", function(victim)
        if IsValid(victim) and IsCrusher(victim) then
            ClearCrusher(victim, false)
        end
    end)
end

if CLIENT then
    surface.CreateFont("Crusher_HintFont", {
        font      = "Bahnschrift",
        size      = 22,
        weight    = 500,
        antialias = true,
        shadow    = true,
    })

    local cv_hints = CreateClientConVar("zb_crusher_hints", "1", true, false, "Show Crusher ability hint HUD")

    concommand.Add("zb_crusher_hints_toggle", function()
        local newState = not cv_hints:GetBool()
        RunConsoleCommand("zb_crusher_hints", newState and "1" or "0")
        -- chat.AddText(Color(210, 40, 40), "[Crusher] ", color_white, "hints " .. (newState and "shown" or "hidden"))
    end)

    net.Receive("Crusher_SetSubRole", function()
        local role = net.ReadString()
        LocalPlayer().SubRole = (role ~= "" and role or nil)
    end)

    net.Receive("HMCD_BeingVictimOfHeadGrab", function()
        local status = net.ReadBool()
        LocalPlayer().BeingVictimOfHeadGrab = status
        BeingVictimOfHeadGrabResetTime = status and (CurTime() + 5) or nil
    end)

    net.Receive("HMCD_GrabbingHead", function()
        local status       = net.ReadBool()
        local attacker_ply = net.ReadEntity()

        local victim
        if status then victim = net.ReadEntity() end

        if not IsValid(attacker_ply) then return end

        if attacker_ply == LocalPlayer() then
            if status then
                if not LocalPlayer().Ability_HeadGrab then
                    StartGrabbingHead(LocalPlayer(), victim)
                else
                    LocalPlayer().Ability_HeadGrab.Victim = victim
                end
            else
                StopGrabbingHead(LocalPlayer())
            end
        else
            if IsValid(victim) then
                victim.BeingVictimOfHeadGrab = status and true or false
            end
        end
    end)

    net.Receive("HMCD_GrabConfirmed", function()
        local status = net.ReadBool()
        local victim = net.ReadEntity()
        local lp = LocalPlayer()
        if status then
            if not lp.Ability_HeadGrab then
                lp.Ability_HeadGrab = { Victim = victim, Progress = 100, Grabbed = false }
            end
            lp.Ability_HeadGrab.Victim    = IsValid(victim) and victim or lp.Ability_HeadGrab.Victim
            lp.Ability_HeadGrab.Grabbed   = true
            lp.Ability_HeadGrab.Progress  = 100
            lp.Ability_HeadGrab.GrabbedAt = CurTime()
        else
            if lp.Ability_HeadGrab then
                lp.Ability_HeadGrab.Grabbed = false
            end
        end
    end)


    hook.Add("Think", "SuperCrusher_Client", function()
        local ply = LocalPlayer()

        if BeingVictimOfHeadGrabResetTime and BeingVictimOfHeadGrabResetTime <= CurTime() then
            BeingVictimOfHeadGrabResetTime = nil
            ply.BeingVictimOfHeadGrab = false
        end

        if ply.Ability_HeadGrab then ContinueGrabbingHead(ply) end
    end)

    concommand.Add("crusher_crush", function(ply, cmd, args)
        if not IsValid(ply) or not ply:Alive() then return end
        if not IsCrusher(ply) then return end
        if ply.Ability_HeadGrab and ply.Ability_HeadGrab.Grabbed then
            net.Start("HMCD_Strangler_CrushRequest")
            net.SendToServer()
        end
    end)

    concommand.Add("+crusher_neckbreak", function(ply)
        if not IsValid(ply) or not ply:Alive() then return end
        if not IsCrusher(ply) then return end
        if ply.Ability_NeckBreak then return end -- already breaking
        local holding = ply.Ability_HeadGrab and ply.Ability_HeadGrab.Grabbed
        if holding then return end               -- can't break neck while head‑grabbing

        local aim_ent, other_ply = NeckTraceToVictim(ply, nil, CRUSHER_NECK_REACH)
        if IsValid(aim_ent) and other_ply and other_ply:IsPlayer() and other_ply:Alive() then
            net.Start("HMCD_Crusher_NeckBreakRequest")
            net.WriteEntity(other_ply)
            net.SendToServer()
        end
    end)

    concommand.Add("-crusher_neckbreak", function(ply)
        if not IsValid(ply) then return end
        if ply.Ability_NeckBreak then
            net.Start("HMCD_Crusher_NeckBreakStop")
            net.SendToServer()
        end
    end)



    hook.Add("hg_AdjustMouseSensitivity", "SuperCrusher_Client", function()
        if LocalPlayer().BeingVictimOfHeadGrab then return 0.15 end
    end)

    local col_bg     = Color(0, 0, 0, 140)
    local col_key    = Color(210, 40, 40, 255)
    local col_text   = Color(210, 210, 210, 255)
    local col_bar_bg = Color(20, 0, 0, 180)
    local col_bar_fg = Color(180, 30, 30, 230)

    local function DrawHint(x, y, key, desc)
        if not pcall(surface.SetFont, "ZCity_Fixed_Tiny") then
            surface.SetFont("Crusher_HintFont")
        end
        local kw, kh   = surface.GetTextSize(key or "")
        local tw       = surface.GetTextSize(desc or "")
        kw             = kw or 0
        kh             = kh or 16
        tw             = tw or 0
        local pad, gap = 5, 8
        local w        = pad + kw + gap + tw + pad
        local h        = kh + pad
        draw.RoundedBox(3, x, y, w, h, col_bg)
        surface.SetTextColor(col_key)
        surface.SetTextPos(x + pad, y + pad / 2)
        surface.DrawText(key)
        surface.SetTextColor(col_text)
        surface.SetTextPos(x + pad + kw + gap, y + pad / 2)
        surface.DrawText(desc)
        return h + 3
    end

    local function ZoomKeyLabel()
        local b = input.LookupBinding("hg_kick") or "hg_kick"
        b = b:lower()
        if b == "mouse1" then
            return "LMB"
        elseif b == "mouse2" then
            return "RMB"
        elseif b == "mouse3" then
            return "MMB"
        else
            return b:upper()
        end
    end

    hook.Add("HUDPaint", "Crusher_SA_HUD", function()
        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:Alive() then return end
        if not IsCrusher(ply) then return end
        if not cv_hints:GetBool() then return end

        local grab_data = ply.Ability_HeadGrab
        local neck_data = ply.Ability_NeckBreak
        local x = ScrW() * 0.02
        local y = ScrH() * 0.72
        local crush_key = input.LookupBinding("crusher_crush") or "crusher_crush"
        local neck_key = input.LookupBinding("+crusher_neckbreak") or "+crusher_neckbreak"

        if neck_data then
            local bar_w    = ScrW() * 0.13
            local bar_h    = 7
            local progress = math.Clamp((neck_data.Progress or 0) / 100, 0, 1)
            draw.RoundedBox(3, x, y, bar_w, bar_h, col_bar_bg)
            if progress > 0 then
                draw.RoundedBox(3, x, y, bar_w * progress, bar_h, col_bar_fg)
            end
            surface.SetDrawColor(col_key)
            surface.DrawOutlinedRect(x, y, bar_w, bar_h, 1)
            y = y + bar_h + 5
            y = y + DrawHint(x, y, "Hold ", neck_key, "breaking neck...")
            return
        end

        if not grab_data then
            y = y + DrawHint(x, y, "ALT + E", "grab alive player (hold)")
            y = y + DrawHint(x, y, neck_key, "break neck (hold, from behind)")
            y = y + DrawHint(x, y, ZoomKeyLabel(), "stomp limb (look down + kick)")
        elseif not grab_data.Grabbed then
            local bar_w    = ScrW() * 0.13
            local bar_h    = 7
            local progress = math.Clamp(grab_data.Progress / 100, 0, 1)
            draw.RoundedBox(3, x, y, bar_w, bar_h, col_bar_bg)
            if progress > 0 then
                draw.RoundedBox(3, x, y, bar_w * progress, bar_h, col_bar_fg)
            end
            surface.SetDrawColor(col_key)
            surface.DrawOutlinedRect(x, y, bar_w, bar_h, 1)
            y = y + bar_h + 5
            y = y + DrawHint(x, y, "Hold ALT + E", "grabbing...")
            y = y + DrawHint(x, y, "Release E", "cancel")
        else
            y = y + DrawHint(x, y, crush_key, "crush head")
            -- y = y + DrawHint(x, y, "]", "break neck")
            y = y + DrawHint(x, y, "R", "release")
        end
    end)
end
-- designed and realized by alagri & omnissiah respectively

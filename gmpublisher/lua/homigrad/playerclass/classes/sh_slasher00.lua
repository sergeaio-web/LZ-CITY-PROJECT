local CLASS = player.RegClass("Slasher")
if SERVER then
    hook.Add("EntityTakeDamage", "SlasherOneDamageHandler", function(target, dmgInfo)
        if target:IsPlayer() and target.PlayerClassName == "Slasher" then
            local org = target.organism
            if not org then return end
            if org.otrub then
                dmgInfo:SetDamage(0)
                return true
            end
            
            local dmg = dmgInfo:GetDamage()
            dmgInfo:SetDamage(dmg * 0.1)
        end
    end)
end
    local oldBreakNeck = hg.BreakNeck
    hg.BreakNeck = function(ent)
        if IsValid(ent) then
            local ply = ent:IsPlayer() and ent or (ent:IsRagdoll() and hg.RagdollOwner(ent))
            if IsValid(ply) and ply.PlayerClassName == "Slasher" then
                return -- Plot armor prevents neck snap
            end
        end
        return oldBreakNeck(ent)
    end
    local meta = FindMetaTable("Player")
    local oldAddHeadcrab = meta.AddHeadcrab
    function meta:AddHeadcrab(headcrab)
        if self.PlayerClassName == "Slasher" then
            return
        end
        return oldAddHeadcrab(self, headcrab)
    end
    hook.Add("Org Think", "SlasherProtection", function(owner, org, timeValue)
    if owner.PlayerClassName ~= "Slasher" then return end

    if org.pain and org.pain >= 50 then
        org.pain = 0
        org.painadd = 0
        org.avgpain = 0
    end

    if org.pelvis and org.pelvis >= 0.01 then
        org.pelvis = 0.00
    end

    if org.heart and org.heart >= 0.01 then
        org.heart = 0.00
    end

    if org.immobilization and org.immobilization >= 0.01 then
        org.immobilization = 0.00
    end

    if org.lungsfunction == false then
        org.lungsfunction = true
    end

    if org.assimilated and org.assimilated >= 0.01 then
        org.assimilated = 0.00
    end

    if org.jawdislocation and org.jawdislocation == true then
        org.jawdislocation = false
    end

    if org.shock and org.shock >= 25 then
        org.shock = 0
        org.shockadd = 0
    end

    -- NO BLEEDING
    if org.bleed and org.bleed > 0 then
        org.bleed = 0
    end

    org.arteria = 0
    org.internalBleed = 0

    if org.arterialwounds and #org.arterialwounds > 0 then
        org.arterialwounds = {}
        owner:SetNetVar("arterialwounds", {})
    end

    if org.brain and org.brain > 0 then
        org.brain = 0
    end

    local bones_to_reset = {"spine1", "spine2", "spine3", "lleg", "rleg", "larm", "rarm"}
    for _, bone in ipairs(bones_to_reset) do
        if org[bone] and org[bone] >= 1 then
            org[bone] = 0
        end
    end

    if org.pneumothorax and org.pneumothorax > 0 then
        org.pneumothorax = 0
    end

    if org.lungsL and org.lungsL[2] and org.lungsL[2] > 0 then
        org.lungsL[2] = 0
    end

    if org.lungsR and org.lungsR[2] and org.lungsR[2] > 0 then
        org.lungsR[2] = 0
    end

    if org.headcrabon then
        org.headcrabon = nil
        owner:SetNetVar("headcrab", false)
    end
end)
    
    hook.Add("EntityTakeDamage", "SlasherNoHeadcrab", function(target, dmgInfo)
        if target:IsPlayer() and target.PlayerClassName == "Slasher" then
            local attacker = dmgInfo:GetAttacker()
            if attacker and attacker:IsNPC() and string.find(attacker:GetClass(), "headcrab") then
                dmgInfo:SetDamage(0)
                return true
            end
        end
    end)
if CLIENT then
    hook.Add("Think", "SlasherClearBlood", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        if ply.PlayerClassName ~= "Slasher" then return end
        local org = ply.new_organism or ply.organism
        if not org then return end
        if org.bleed and org.bleed < 0.01 then
            ply.wounds = {}
            ply.arterialwounds = {}
        end
    end)
end
return CLASS
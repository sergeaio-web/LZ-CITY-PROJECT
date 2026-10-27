MODE.name = "ButcherMode"
MODE.PrintName = "Билли Бутчер"
 
MODE.OverideSpawnPos = true
MODE.LootSpawn = false
MODE.ForBigMaps = false
MODE.Chance = 0.03
 
local survivorConsumables = {
    "weapon_bigconsumable",
    "weapon_smallconsumable",
    "weapon_bandage_sh",
    "weapon_hg_smokenade_tpik",
    "weapon_medkit_sh",
}

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
    return 1, true
end
 
util.AddNetworkString("butcher_start")
util.AddNetworkString("butcher_roundend")
 
function MODE:Intermission()
    game.CleanUpMap()
 
	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		ply:SetupTeam(ply:Team())
	end
 
    net.Start("butcher_start")
    net.Broadcast()
end
 
function MODE:CheckAlivePlayers()
    local survivorPlayers = {}
    local butcherPlayers = {}
 
    for _, ply in ipairs(team.GetPlayers(0)) do
        if ply:Alive() and not ply:GetNetVar("handcuffed", false) then
            table.insert(survivorPlayers, ply)
        end
    end
 
    for _, ply in ipairs(team.GetPlayers(1)) do
        if ply:Alive() and not ply:GetNetVar("handcuffed", false) then
            table.insert(butcherPlayers, ply)
        end
    end
 
    return {survivorPlayers, butcherPlayers}
end

function MODE:ShouldRoundEnd()
    if CurTime() - zb.ROUND_START >= 240 then
        return true, team.GetPlayers(0)
    end

    local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())
    return endround, winner
end
 
function MODE:EndRound()
    timer.Simple(2, function()
        net.Start("butcher_roundend")
        net.Broadcast()
    end)
end
 
function MODE:RoundStart()
end
 
function MODE:GiveEquipment()
    local players = player.GetAll()
    table.Shuffle(players)
 
    local numPlayers = #players
    local numButcher = 1
    local numSurvivors = numPlayers - numButcher
 
    for i = 1, numSurvivors do
        local ply = players[i]
        if ply:Team() == TEAM_SPECTATOR then continue end
    
        ply:SetupTeam(0)
        ply:SetPlayerClass("Survivor")
        zb.GiveRole(ply, "Survivor", Color(0, 190, 0))
    
        ply:Give("weapon_hands_sh")
		ply:SetNetVar("CurPluv", "")
        ply:Give(survivorConsumables[math.random(#survivorConsumables)])
    end
    
    for i = numSurvivors + 1, numPlayers do
        local ply = players[i]
        if ply:Team() == TEAM_SPECTATOR then continue end
 
        ply:SetupTeam(1)
        ply:SetPlayerClass("Butcher")
        zb.GiveRole(ply, "Billy Butcher", Color(190, 100, 0))
 
        ply:SetMaxHealth(2000)
        ply:SetHealth(2000)
        ply:SetArmor(2000)

        local hands = ply:Give("weapon_hands_sh")
        ply:SelectWeapon(hands)
        
        ply:Give("weapon_hg_crowbar")
        
        ply:SetNetVar("CurPluv", "")
    end
end

-- Zabezpieczenie: hook wykona się TYLKO gdy aktywnym trybem jest ButcherMode
hook.Add("EntityTakeDamage", "ButcherPunchAndDurability", function(target, dmginfo)
    if not zb or zb.CurMode ~= "ButcherMode" then return end

    local attacker = dmginfo:GetAttacker()
    
    if IsValid(target) and target:IsPlayer() and target:Team() == 1 then
        dmginfo:ScaleDamage(0.15)
        return
    end

    if IsValid(attacker) and attacker:IsPlayer() and attacker:Team() == 1 then
        local activeWeapon = attacker:GetActiveWeapon()
        if IsValid(activeWeapon) then
            local wClass = activeWeapon:GetClass()
            if wClass == "weapon_hands_sh" or wClass == "weapon_hg_crowbar" then
                dmginfo:SetDamage(150)

                if IsValid(target) then
                    local pushDir = attacker:GetAimVector()
                    pushDir.z = math.max(pushDir.z, 0.2)
                    
                    if target:IsPlayer() then
                        target:SetVelocity(pushDir * 1200 + Vector(0, 0, 300))
                    elseif target:IsNPC() or target:IsRagdoll() then
                        local phys = target:GetPhysicsObject()
                        if IsValid(phys) then
                            phys:SetVelocity(pushDir * 1200 + Vector(0, 0, 300))
                        end
                    end
                end
            end
        end
    end
end)
 
function MODE:GetTeamSpawn()
	return zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_T")), zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_CT"))
end
 
function MODE:RoundThink()
end
 
function MODE:CanLaunch()
    local activePlayers = 0
 
    for _, ply in player.Iterator() do
        if ply:Team() ~= TEAM_SPECTATOR then
            activePlayers = activePlayers + 1
        end
    end
    
    if activePlayers < 2 then
        return false
    end
 
    return true
end
 
return MODE
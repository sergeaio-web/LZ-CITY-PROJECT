MODE.name = "SlovoPocana"
MODE.PrintName = "Слово Пацана"

MODE.ForBigMaps = false
MODE.ROUND_TIME = 280

MODE.Chance = 0.02

MODE.OverideSpawnPos = true
MODE.LootSpawn = false

function MODE:CanLaunch()
	return true
	--[[local points = zb.GetMapPoints( "HMCD_TDM_T" )
	local points2 = zb.GetMapPoints( "HMCD_TDM_CT" )
    return (#points > 0) and (#points2 > 0)--]]
end

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
	return 1, true--returning true so guilt bans
end

util.AddNetworkString("SP_start")
function MODE:Intermission()
	game.CleanUpMap()


	
	for i, ply in player.Iterator() do
		ply:SetupTeam(ply:Team())
	end

	net.Start("SP_start")
	net.Broadcast()
end

function MODE:CheckAlivePlayers()
	return zb:CheckAliveTeams(true)
end

function MODE:ShouldRoundEnd()
	local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())

	return endround or boringround
end

function MODE:BoringRoundFunction()		
	timer.Simple(2, function()
		//PrintMessage(HUD_PRINTTALK, "IT IS A GANG SHOOTOUT FFS...")
	end)
end

local policeSpawned = false

function MODE:RoundStart()
    policeSpawned = false 
end

local guysWeapons = {
"weapon_bat",
"weapon_hg_bottle",
"weapon_brick",
"weapon_chair_leg",
"weapon_hg_crowbar",
"weapon_hammer",
"weapon_pan",
"weapon_leadpipe",
"weapon_table_leg"
}
 
local guysConsumables = {
    "weapon_bigconsumable",
    "weapon_smallconsumable",
    "weapon_bandage_sh"
}





function MODE:GetPlySpawn(ply)
end

function MODE:GiveEquipment()

	timer.Simple(0.1,function()
		local teamArmorCount = { [0] = 0, [1] = 0 } 

		for _, ply in player.Iterator() do
			if not ply:Alive() then continue end
			ply:SetSuppressPickupNotices(true)
			ply.noSound = true

			if ply:Team() == 0 then
				ply:SetPlayerClass("RAZEZD")
				zb.GiveRole(ply, "Razezdovsky", Color(0,255,0))
				ply:SetNetVar("CurPluv", "pluvred")
			local wep = ply:Give(guysWeapons[math.random(#guysWeapons)])
            local wep = ply:Give(guysConsumables[math.random(#guysConsumables)])
			else
				ply:SetPlayerClass("OKTYABRSKIE")
				zb.GiveRole(ply, "OKTYABRSKY", Color(255,255,0))
				ply:SetNetVar("CurPluv", "pluvgreen")
			local wep = ply:Give(guysWeapons[math.random(#guysWeapons)])
            local wep = ply:Give(guysConsumables[math.random(#guysConsumables)])                
			end

			



			local hands = ply:Give("weapon_hands_sh")
			--ply:SelectWeapon("weapon_hands_sh")

			timer.Simple(0.1,function()
				ply.noSound = false
			end)

			ply:SetSuppressPickupNotices(false)
		end
	end)
end

function MODE:RoundThink()
  


end

function MODE:GetTeamSpawn()
	return zb.TranslatePointsToVectors(zb.GetMapPoints( "HMCD_TDM_T" )), zb.TranslatePointsToVectors(zb.GetMapPoints( "HMCD_TDM_CT" ))
end

function MODE:CanSpawn()
end

util.AddNetworkString("SP_roundend")
function MODE:EndRound()
	timer.Simple(2,function()
		net.Start("SP_roundend")
		net.Broadcast()
	end)

	local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())
	for k,ply in player.Iterator() do
		if ply:Team() == winner then
			ply:GiveExp(math.random(15,30))
			ply:GiveSkill(math.Rand(0.1,0.15))
			--print("give",ply)
		else
			--print("take",ply)
			ply:GiveSkill(-math.Rand(0.05,0.1))
		end
	end
end

function MODE:PlayerDeath(ply)
end
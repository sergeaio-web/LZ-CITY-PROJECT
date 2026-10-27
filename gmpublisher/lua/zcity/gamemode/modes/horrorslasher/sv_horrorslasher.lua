MODE.name = "Horror Slasher"
MODE.PrintName = "Хоррор"
local MODE = MODE
MODE.OverideSpawnPos = true
MODE.LootSpawn = true
MODE.LootOnTime = true
MODE.LootDivTime = 12700
MODE.ForBigMaps = true
MODE.Chance = 0.2
MODE.randomSpawns = true
MODE.GuiltDisabled = true

MODE.noBoxes = true

local killerWeapons = {
"weapon_brick",
"weapon_morphine",
"weapon_bat",
"weapon_hg_jam",
"weapon_hammer",
"weapon_slasher_hatchet",
"weapon_victim_talkie",

}
 
local killerConsumables = {
    "weapon_medkit_sh",
    "weapon_hands_sh",

}
 
local ACConsumables = {
    "weapon_slasher_axe",
    "weapon_slasher_pitchfork",
    "weapon_hg_spear_pro",

}


 
local ACCWeapons = {
"weapon_slasher_axe",
"weapon_hg_spear_pro",
"weapon_slasher_machete",
}
 
local ACWeapons = {
"weapon_beartrap_homigrad",
"weapon_hg_bow",
"weapon_slasher_hatchet",
}

local TELEPORT_WARMUP = 15 -- seconds
local TELEPORT_COOLDOWN = 20 -- seconds

MODE.LootTable = {
	{38, {
		{3,"weapon_tourniquet"},
		{7,"weapon_bandage_sh"},
		{4,"weapon_ducttape"},
		{2,"weapon_hg_smokenade_tpik"},
		{0.3,"weapon_doublebarrel"},
		
		{3,"weapon_victim_talkie"},
		{15,"weapon_painkillers"},
		{3,"weapon_bigbandage_sh"},
		{1,"weapon_medkit_sh"},
		{1,"weapon_matches"},

		{0.27, "ent_armor_helmet2"},
	
		{7,"weapon_hammer"},
		{5,"weapon_morphine"},
		{2,"weapon_victim_talkie"},

		{4,"weapon_bat"},
		{4,"weapon_leadpipe"},
		{1.5,"weapon_hg_jam"},

		{2,"weapon_hg_crowbar"},
		{4,"weapon_slasher_hatchet"},
		{3.4,"weapon_hg_axe"},
		{3,"weapon_hg_machete"},
		{1,"weapon_hg_sledgehammer"},
	}},
	{24, {
		{1.2,"weapon_winchester"},
		{0.9,"weapon_Police_radio"},
		{5,"weapon_ducttape"},
		{0.9,"weapon_doublebarrel_short"},
		{0.6,"weapon_revolver2"},
		{5.2,"weapon_bigbandage_sh"},
		{0.9,"weapon_m1911"},
		{3,"weapon_medkit_sh"},
		{0.2,"weapon_remington870"},
		{2,"weapon_hg_crowbar"},
		{1.3,"weapon_doublebarrel"},
		{3.4,"weapon_hg_axe"},
		{3,"weapon_hg_machete"},
		{5,"weapon_painkillers"},

	}},
	{14, {
		{0.6,"weapon_Police_radio"},
		{1.0,"weapon_taser"},
		{1.5,"weapon_hg_grenade_tpik"},
		{1.3,"weapon_revolver357"},
	}},
}
 

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
    return 1, true
end
 
local swatSpawned = false
local swatcalled = false
local swatCallTime = 0

util.AddNetworkString("Slasher_start")
util.AddNetworkString("Slasher_roundend")
util.AddNetworkString("Slasher_CallPolice")
util.AddNetworkString("Slasher_CallShorty")

net.Receive("Slasher_CallPolice", function(_, ply)
    if swatcalled then return end

    swatcalled = true
    swatCallTime = CurTime()

    SetGlobalBool("SlasherPoliceCalled", true)

ply:EmitSound("slasher/copcall.wav", 75, 100)

    
end)

net.Receive("Slasher_CallShorty", function(_, ply)
    sound.Play(
        "slasher/shortycall.mp3",
        ply:GetPos(),
        75,
        100,
        1
    )
end)

function MODE:Intermission()
    game.CleanUpMap()

    for i, ply in player.Iterator() do
        if ply:Team() == TEAM_SPECTATOR then continue end
        ply:SetupTeam(ply:Team())
    end
net.Start("Slasher_start")
    net.Broadcast()
end

	
 

function MODE:CheckAlivePlayers()
    local acPlayers = {}
    local SlasherPlayers = {}
 
    for _, ply in ipairs(team.GetPlayers(0)) do
        if ply:Alive() and not ply:GetNetVar("handcuffed", false) then
            table.insert(SlasherPlayers, ply)
        end
    end
 
    for _, ply in ipairs(team.GetPlayers(1)) do
        if ply:Alive() and not ply:GetNetVar("handcuffed", false) then
            table.insert(acPlayers, ply)
        end
    end
 
    return {acPlayers, SlasherPlayers}
end
 
 
function MODE:EndRound()




    timer.Simple(2,function()
        net.Start("Slasher_roundend")
        net.Broadcast()
    end)
end
 
 
function MODE:ShouldRoundEnd()
    local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())
    return endround
end
 

function MODE:RoundStart()

swatSpawned = false
swatcalled = false
swatCallTime = 0
 SetGlobalBool("SlasherPoliceCalled", false)

end
 
 
function MODE:GiveEquipment()



    local players = player.GetAll()
    table.Shuffle(players)
 
    local numPlayers = #players
    local numac = 1
    local numkillers = numPlayers - numac
    local tommyPlayer = nil


timer.Simple(0.1, function()
        local spawns = ents.FindByClass("info_player_start")
        table.Add(spawns, ents.FindByClass("info_player_terrorist"))
        table.Add(spawns, ents.FindByClass("info_player_counterterrorist"))

        for _, ply in player.Iterator() do
            if ply:Alive() then
                if #spawns > 0 then 
                    local spawnEnt = spawns[math.random(#spawns)]
                    ply:SetPos(spawnEnt:GetPos()) 
                end
end
end


-- 35% chance Tommy exists this round
if math.random(100) <= 35 then
    local candidates = {}

    for i = 1, numkillers do
        local ply = players[i]

        if IsValid(ply) and ply:Team() ~= TEAM_SPECTATOR then
            table.insert(candidates, ply)
        end
    end

    if #candidates > 0 then
        tommyPlayer = table.Random(candidates)
    end
end

for i = 1, numkillers do
    local ply = players[i]

    if ply:Team() == TEAM_SPECTATOR then continue end

    ply:SetupTeam(0)


    if ply == tommyPlayer then
        ply:SetPlayerClass("tommyjarvis")
	zb.GiveRole(ply, "tommyjarvis", Color(190, 0, 0))
	ply:SetNWBool("IsTommy", true)
	ply.slasherRole = "tommyjarvis"
        ply:Give("weapon_hands_sh")
	ply:Give("weapon_bigbandage_sh")
	ply:Give("weapon_morphine")
	ply:Give("weapon_matches")
	ply:Give("weapon_hg_jam")
	ply:Give("weapon_mannitol")
        ply:Give("weapon_medkit_sh")
        ply:Give("weapon_buck200knife")
        ply:Give("weapon_doublebarrel_short")
	ply:Give("weapon_victim_talkie")
	ply:SelectWeapon("weapon_doublebarrel_short")
	local inv = ply:GetNetVar("Inventory")
	inv["Weapons"]["hg_flashlight"] = true


        ply:GiveAmmo(20, "12/70 gauge", true)

        continue
    end

            

        ply:SetPlayerClass("slashervictim")
    
    	ply:SetNWBool("IsTommy", false)
        zb.GiveRole(ply, "victim", Color(190, 0, 0))
    	ply.slasherRole = "slashervictim"
        ply:Give("weapon_hands_sh")
	local inv = ply:GetNetVar("Inventory")
	inv["Weapons"]["hg_flashlight"] = true
 
        
 
		ply:SetNetVar("CurPluv", "pluvmajima")
 
        ply:Give(killerConsumables[math.random(#killerConsumables)])
    
        
    
        local killerWeapon = killerWeapons[math.random(#killerWeapons)]
        local wep = ply:Give(killerWeapon)
        
        ply:GiveAmmo(13, 55, true)
                end
    
 
    for i = numkillers + 1, numPlayers do
        local ply = players[i]
        if ply:Team() == TEAM_SPECTATOR then continue end
 
        ply:SetupTeam(1)
        ply:SetPlayerClass("Slasher")
        local mdl = string.lower(ply:GetModel())

if mdl == "models/player/leather.mdl" then
    zb.GiveRole(ply, "Leatherface", Color(0,0,190))
ply:Give("weapon_slasher_chainsaw")
ply:SelectWeapon("weapon_slasher_chainsaw")
ply.SlasherType = "Leatherface"
ply:SetNWString("SlasherType", "Leatherface")

elseif mdl == "models/players/mj_dbd_myers_2018.mdl" then
    zb.GiveRole(ply, "Michael", Color(0,0,190))
ply:SelectWeapon("weapon_slasher_kitchenknife")
ply.SlasherType = "Michael"
ply:Give("weapon_slasher_kitchenknife")
ply:SetNWString("SlasherType", "Michael")

elseif mdl == "models/panman/arc_future.mdl" then
    zb.GiveRole(ply, "Ghost", Color(0,0,190))
ply.SlasherType = "Ghost"
ply:SetNWString("SlasherType", "Ghost")
ply:Give("weapon_hammer")
ply:Give("weapon_slasher_hatchet")

elseif mdl == "models/models/konnie/jason4/jason4.mdl" then
    zb.GiveRole(ply, "Jason", Color(0,0,190))
ply:Give(ACCWeapons[math.random(#ACCWeapons)])
local hands = ply:Give("weapon_slasherhands_sh")
ply.SlasherType = "Jason"
ply:SetNWString("SlasherType", "Jason")

elseif mdl == "models/models/konnie/jasonpart2/jasonpart2.mdl" then
    zb.GiveRole(ply, "Jason", Color(0,0,190))
ply:Give(ACConsumables[math.random(#ACConsumables)])

ply.SlasherType = "Jason"
ply:SetNWString("SlasherType", "Jason")

elseif mdl == "models/models/konnie/jasonpart3/jasonpart3.mdl" then
    zb.GiveRole(ply, "Jason", Color(0,0,190))
ply:Give(ACCWeapons[math.random(#ACCWeapons)])
ply:Give(ACWeapons[math.random(#ACWeapons)])

ply.SlasherType = "Jason"
ply:SetNWString("SlasherType", "Jason")

else
    zb.GiveRole(ply, "Slasher", Color(0,0,190))
end

	ply:SetNWBool("IsTommy", false)
	ply.slasherRole = "slasher"

	ply.TeleportUnlockTime = CurTime() + TELEPORT_WARMUP

timer.Simple(TELEPORT_WARMUP, function()
    if not IsValid(ply) then return end
    if ply.slasherRole ~= "slasher" then return end

    ply:ChatPrint("teleport ready.")
end)

 	ply:GiveAmmo(1, "arrow", true)
        local inv = ply:GetNetVar("Inventory")
        inv["Weapons"]["hg_sling"] = true
        ply:SetNetVar("Inventory", inv)
	
        local hands = ply:Give("weapon_slasherhands_sh")
	
 
        ply:SetNetVar("CurPluv", "pluvberet")
 

 
 
       
 
        ply:SelectWeapon("weapon_hg_tonfa")
    end

end)
end
 
function MODE:GetTeamSpawn()
	return zb.TranslatePointsToVectors(zb.GetMapPoints( "HMCD_TDM_T" )), zb.TranslatePointsToVectors(zb.GetMapPoints( "HMCD_TDM_CT" ))
end
 


function MODE:RoundThink()

if not swatSpawned and swatcalled and (CurTime() - swatCallTime) >= 20 then


        local candidates = {}
        local useDeadPlayers = true
        for _, ply in player.Iterator() do
            if not ply:Alive() and ply:Team() != TEAM_SPECTATOR then 
                table.insert(candidates, ply) 
            end
        end
        if #candidates == 0 then
    return
end
        local swatCount = math.min(4, #candidates)
        if swatCount == 0 then 
            swatSpawned = true 
            return 
        end
        for _, ply in player.Iterator() do
            ply:EmitSound("activeshooter/swat.mp3", 0, 100, 1, CHAN_AUTO)
        end
        local ram_index = math.random(1, swatCount)
        local spawns = ents.FindByClass("info_player_counterterrorist")
        if #spawns == 0 then spawns = ents.FindByClass("info_player_start") end

        for i = 1, swatCount do
            local ply = candidates[i]
            if useDeadPlayers then
                ply:Spawn()
            else
                ply:StripWeapons()
            end
            ply:SetTeam(0)
            if #spawns > 0 then 
                local spawnEnt = spawns[math.random(#spawns)]
                ply:SetPos(spawnEnt:GetPos()) 
            end

            ply:SetPlayerClass("police")
            zb.GiveRole(ply, "Police Officer", Color(0, 0, 150))
            
            local gun1 = ply:Give("weapon_revolver357")
            local gun2 = ply:Give("weapon_m1911")
            ply:GiveAmmo(gun1:GetMaxClip1() * 4, gun1:GetPrimaryAmmoType(), true)
            ply:GiveAmmo(gun2:GetMaxClip1() * 5, gun2:GetPrimaryAmmoType(), true)
            
            ply:Give("weapon_bigbandage_sh")
            ply:Give("weapon_tourniquet")
            ply:Give("weapon_medkit_sh")
            
            ply:Give("weapon_melee")
            if i == ram_index then
                ply:Give("weapon_ram")
            end

            hg.AddArmor(ply, "ent_armor_vest2")
            
            
            ply:Give("weapon_hands_sh")
            ply:SelectWeapon("weapon_revolver357")
        end

        swatSpawned = true

end
end

function MODE:CanLaunch()
    local activePlayers = 0
 
    for _, ply in player.Iterator() do
        if ply:Team() ~= TEAM_SPECTATOR then
            activePlayers = activePlayers + 1
        end
    end
    
    if activePlayers < 5 then
        return false
    end
 
    return true
 
end
 
return MODE
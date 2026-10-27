local MODE = MODE or {}

MODE.name = "BATTLESVSU"
MODE.PrintName = "Сельские против Городских"
MODE.ForBigMaps = false
MODE.ROUND_TIME = 360
MODE.Chance = 0.02
MODE.OverrideSpawnPos = true
MODE.LootSpawn = false

util.AddNetworkString("BATTLESVSU_start")
util.AddNetworkString("BATTLESVSU_roundend")

function MODE:CanLaunch()
    return true
end

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
    return 1, true
end

local weaponMeleeBase = "weapon_hands_sh" 

-- Списки предметов
local villageWeapons = {
    "weapon_hg_bottle",  
    "weapon_pocketknife",      
    "weapon_chair_leg", 
    "weapon_pan",
    "weapon_hg_crowbar",
    "weapon_hg_can",
    "weapon_hg_spear",
    "weapon_hg_glassshard"
}

local urbanWeapons = {
    "weapon_pocketknife",
    "weapon_hg_bottle",
    "weapon_brick",
    "weapon_bat",
    "weapon_leadpipe",
    "weapon_hammer",
    "weapon_hg_spear",
    "weapon_hg_glassshard" 
}

function MODE:Intermission()
    game.CleanUpMap()
    
    local players = player.GetAll()
    -- Рандомим игроков
    for i = #players, 2, -1 do
        local j = math.random(i)
        players[i], players[j] = players[j], players[i]
    end

    -- Списки для отслеживания участников каждой команды
    local villageTeamPlayers = {}
    local urbanTeamPlayers = {}

    -- Этап 1: Распределяем команды, чистим лут, выдаем кулаки и случайное оружие
    for i, ply in ipairs(players) do
        if not IsValid(ply) then continue end
        
        local assignedTeam = (i % 2 == 0) and TEAM_VILLAGE or TEAM_URBAN
        ply:SetTeam(assignedTeam)
        
        -- Полностью очищаем старый лут
        ply:StripWeapons()
        ply:StripAmmo()
        
        -- Выдаем базовую рукопашку (кулаки)
        ply:Give(weaponMeleeBase)
        
        if assignedTeam == TEAM_VILLAGE then
            -- Выдаем одно случайное сельское оружие
            local randomWeapon = villageWeapons[math.random(#villageWeapons)]
            ply:Give(randomWeapon)
            -- Запоминаем игрока
            table.insert(villageTeamPlayers, ply)
        else
            -- Выдаем одно случайное городское оружие
            local randomWeapon = urbanWeapons[math.random(#urbanWeapons)]
            ply:Give(randomWeapon)
            -- Запоминаем игрока
            table.insert(urbanTeamPlayers, ply)
        end
        
        if ply.SetupTeam then ply:SetupTeam(assignedTeam) end
    end

    net.Start("BATTLESVSU_start")
    net.Broadcast()
end

function MODE:CheckAlivePlayers()
    if zb and zb.CheckAliveTeams then return zb:CheckAliveTeams(true) end
end

function MODE:ShouldRoundEnd()
    if zb and zb.CheckWinner then
        local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())
        if endround then
            net.Start("BATTLESVSU_roundend")
            net.Broadcast()
            return true
        end
    end
    return false
end

function MODE:BoringRoundFunction() end

-- ПЕРЕНЕСЛИ СЮДА: Логика распределения по точкам в момент фактического старта раунда
function MODE:RoundStart() 
    local spawnEntities = {
        "info_player_start", "info_player_deathmatch", 
        "info_player_terrorist", "info_player_counterterrorist"
    }
    local availableSpawns = {}
    for _, entClass in ipairs(spawnEntities) do
        for _, ent in ipairs(ents.FindByClass(entClass)) do
            table.insert(availableSpawns, ent)
        end
    end

    -- Перемешиваем точки спавна для случайности
    for i = #availableSpawns, 2, -1 do
        local j = math.random(i)
        availableSpawns[i], availableSpawns[j] = availableSpawns[j], availableSpawns[i]
    end

    local settledPlayers = {}

    -- Раскидываем игроков на безопасное расстояние
    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) or not ply:Alive() or ply:Team() == TEAM_SPECTATOR then continue end
        local assignedTeam = ply:Team()

        if #availableSpawns > 0 then
            local chosenSpawn = nil
            
            -- Ищем точку подальше от врагов
            for index, spawnEnt in ipairs(availableSpawns) do
                if not IsValid(spawnEnt) then continue end
                local spawnPos = spawnEnt:GetPos()
                local tooClose = false
                
                -- Проверяем расстояние до уже расселенных врагов
                for _, otherPly in ipairs(settledPlayers) do
                    if IsValid(otherPly) and otherPly:Team() ~= assignedTeam then
                        if otherPly:GetPos():DistToSqr(spawnPos) < 640000 then -- 800^2 единиц
                            tooClose = true
                            break
                        end
                    end
                end
                
                if not tooClose then
                    chosenSpawn = spawnEnt
                    table.remove(availableSpawns, index)
                    break
                end
            end
            
            -- Если идеальной точки нет, берем первую свободную
            if not chosenSpawn then
                chosenSpawn = table.remove(availableSpawns, 1)
            end
            
            -- Принудительно ставим игрока в кадре старта раунда
            if IsValid(chosenSpawn) then
                ply:SetPos(chosenSpawn:GetPos())
                ply:SetEyeAngles(chosenSpawn:GetAngles())
                table.insert(settledPlayers, ply)
            end
        end
    end
end

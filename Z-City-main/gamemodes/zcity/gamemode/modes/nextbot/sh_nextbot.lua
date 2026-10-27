local MODE = MODE

-- Оригинальная система режимов Z-City.
-- Не наследуемся от другого игрового режима.

MODE.name = "nextbot"
MODE.PrintName = "Нексбот"
MODE.Description = "Выживите 8 минут, спасаясь от выбранного нексбота."

MODE.Chance = 0.04
MODE.ForBigMaps = false

MODE.randomSpawns = true
MODE.LootSpawn = false
MODE.Lootables = {}

MODE.start_time = 15
MODE.ROUND_TIME = 480
MODE.end_time = 8

if SERVER then
    resource.AddWorkshop("2501837429") -- [DrGBase] SCP-096:SL Nextbot
    resource.AddWorkshop("3783971634") -- SCP-173 [Z-CITY SUPPORT]
	resource.AddWorkshop("477900229") -- gman
end

function MODE:CanLaunch()
    return true
end
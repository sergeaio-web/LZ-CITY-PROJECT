-- ============================================================
-- SONIC — новая роль предателя для Z-City Homicide
-- Файл: gamemodes/zcity/gamemode/modes/homicide/sh_zsonic.lua
-- ============================================================

local MODE = MODE

if not MODE then return end

local ROLE_ID = "traitor_sonic"

local SPEED_MULTIPLIER = 1.05
local HEALTH_MULTIPLIER = 0.98
local DAMAGE_MULTIPLIER = 0.95
local STAMINA_MAX = 300

local ABILITY_DURATION = 30
local ABILITY_COOLDOWN = 120

local ABILITY_NET = "HMCD_Sonic_UltraRun"

-- ============================================================
-- РЕГИСТРАЦИЯ РОЛИ
-- ============================================================

MODE.SubRoles = MODE.SubRoles or {}

MODE.SubRoles[ROLE_ID] = {
    Name = "Соник",

    Description = [[
Повышенная скорость передвижения.
Ускоренные атаки и перезарядка.
Большой запас выносливости.

Способность «Ультра бег»:
получите эффект Fury-16 на 30 секунд.
Перезарядка способности — 2 минуты.

Недостатки:
здоровье уменьшено на 2%.
Урон кулаками и ногами уменьшен на 5%.
]],

    Objective = "Используй скорость, чтобы найти и устранить всех.",

    SpawnFunction = function(ply)
        if not IsValid(ply) then return end

        -- Основное оружие и снаряжение.
        local revolver = ply:Give("weapon_revolver357")

        ply:Give("weapon_buck200knife")
        ply:Give("weapon_medkit_sh")
        ply:Give("weapon_adrenaline")
        ply:Give("weapon_traitor_suit")
        ply:Give("weapon_traitor_poison3")
        ply:Give("weapon_hg_molotov_tpik")

        -- Три дополнительных магазина для револьвера.
        if IsValid(revolver) then
            local ammoType = revolver:GetPrimaryAmmoType()
            local clipSize = revolver:GetMaxClip1()

            if ammoType and ammoType >= 0 and clipSize > 0 then
                ply:GiveAmmo(clipSize * 3, ammoType, true)
            end
        end

        -- Уменьшение здоровья на 2%.
        local maxHealth = ply:GetMaxHealth()

        if maxHealth <= 0 then
            maxHealth = ply:Health()
        end

        if maxHealth > 0 then
            local sonicHealth = math.max(
                1,
                math.floor(maxHealth * HEALTH_MULTIPLIER)
            )

            ply:SetMaxHealth(sonicHealth)
            ply:SetHealth(math.min(ply:Health(), sonicHealth))
        end

        -- Увеличенная выносливость.
        if ply.organism and ply.organism.stamina then
            ply.organism.stamina.max = STAMINA_MAX
        end

        -- Пассивные параметры роли.
        ply.HMCD_Sonic = true
        ply.HMCD_SonicAbilityReady = 0
        ply.HMCD_SonicAbilityActiveUntil = 0
    end
}

-- Добавляем Соника в существующий выбор ролей.
MODE.RoleChooseRoundTypes = MODE.RoleChooseRoundTypes or {}

for _, roundType in ipairs({ "standard", "soe" }) do
    MODE.RoleChooseRoundTypes[roundType] =
        MODE.RoleChooseRoundTypes[roundType] or {}

    local roundData = MODE.RoleChooseRoundTypes[roundType]

    roundData.Traitor = roundData.Traitor or {}
    roundData.Traitor[ROLE_ID] = true
end

-- ============================================================
-- ОБЩИЕ ПРОВЕРКИ
-- ============================================================

local function IsSonic(ply)
    return IsValid(ply)
        and ply:IsPlayer()
        and (
            ply.SubRole == ROLE_ID
            or ply.HMCD_Sonic == true
        )
end

-- ============================================================
-- СЕРВЕРНАЯ ЧАСТЬ
-- ============================================================

if SERVER then
    AddCSLuaFile()

    util.AddNetworkString(ABILITY_NET)

    -- Активировать «Ультра бег».
    net.Receive(ABILITY_NET, function(_, ply)
        if not IsSonic(ply) then return end
        if not ply:Alive() then return end
        if not ply.organism then return end
        if ply.organism.otrub then return end

        local now = CurTime()

        if (ply.HMCD_SonicAbilityReady or 0) > now then
            return
        end

        -- Сохраняем прежний уровень норадреналина,
        -- чтобы вернуть его по окончании способности.
        ply.HMCD_SonicPreviousNoradrenaline =
            ply.organism.noradrenaline or 0

        -- Fury-16 / Uber Norepinephrine.
        ply.organism.noradrenaline = math.max(
            ply.organism.noradrenaline or 0,
            1.25
        )

        ply.HMCD_SonicAbilityActiveUntil = now + ABILITY_DURATION
        ply.HMCD_SonicAbilityReady = now + ABILITY_COOLDOWN

        ply:EmitSound("items/medshot4.wav", 65, 115, 0.7)
    end)

    -- Завершение способности и очистка состояния роли.
    hook.Add("Think", "HMCD_Sonic_AbilityThink", function()
        for _, ply in ipairs(player.GetAll()) do
            if not IsValid(ply) then continue end

            local activeUntil = ply.HMCD_SonicAbilityActiveUntil or 0

            if activeUntil > 0 and CurTime() >= activeUntil then
                if ply.organism then
                    ply.organism.noradrenaline =
                        ply.HMCD_SonicPreviousNoradrenaline or 0
                end

                ply.HMCD_SonicAbilityActiveUntil = 0
                ply.HMCD_SonicPreviousNoradrenaline = nil
            end

            -- Если игрок умер во время действия способности,
            -- не оставляем временный эффект активным.
            if IsSonic(ply) and not ply:Alive() and activeUntil > 0 then
                if ply.organism then
                    ply.organism.noradrenaline =
                        ply.HMCD_SonicPreviousNoradrenaline or 0
                end

                ply.HMCD_SonicAbilityActiveUntil = 0
                ply.HMCD_SonicPreviousNoradrenaline = nil
            end
        end
    end)

    -- Скорость передвижения +5%.
    -- При удержании ALT бонус скорости отключается.
    hook.Add("SetupMove", "HMCD_Sonic_Speed", function(ply, mv)
        if not IsSonic(ply) then return end
        if not ply:Alive() then return end
        if ply:KeyDown(IN_WALK) then return end

        mv:SetMaxSpeed(mv:GetMaxSpeed() * SPEED_MULTIPLIER)
        mv:SetMaxClientSpeed(mv:GetMaxClientSpeed() * SPEED_MULTIPLIER)
    end)

    -- Урон кулаками и ногами -5%.
    -- Ограничиваемся рукопашным уроном, не затрагивая огнестрел.
    hook.Add("EntityTakeDamage", "HMCD_Sonic_MeleeDamage", function(
        target,
        dmg
    )
        local attacker = dmg:GetAttacker()

        if not IsSonic(attacker) then return end

        local activeWeapon = attacker:GetActiveWeapon()
        if not IsValid(activeWeapon) then return end

        local class = activeWeapon:GetClass()
        local damageType = dmg:GetDamageType()

        local isHands = class == "weapon_hands_sh"
        local isMeleeDamage =
            bit.band(damageType, DMG_CLUB) ~= 0
            or bit.band(damageType, DMG_SLASH) ~= 0

        if isHands and isMeleeDamage then
            dmg:SetDamage(dmg:GetDamage() * DAMAGE_MULTIPLIER)
        end
    end)

    -- Сброс временных данных при отключении игрока.
    hook.Add("PlayerDisconnected", "HMCD_Sonic_Disconnect", function(ply)
        ply.HMCD_Sonic = nil
        ply.HMCD_SonicAbilityActiveUntil = nil
        ply.HMCD_SonicAbilityReady = nil
        ply.HMCD_SonicPreviousNoradrenaline = nil
    end)
end

-- ============================================================
-- КЛИЕНТ: ПУНКТ В Q-МЕНЮ / РАДИАЛЬНОМ МЕНЮ
-- ============================================================

if CLIENT then
    local function ActivateSonicAbility()
        if not IsValid(LocalPlayer()) then return end

        net.Start(ABILITY_NET)
        net.SendToServer()
    end

    hook.Add("radialOptions", "HMCD_Sonic_RadialOption", function()
        local ply = LocalPlayer()

        if not IsValid(ply) then return end
        if not ply:Alive() then return end
        if not IsSonic(ply) then return end

        hg.radialOptions = hg.radialOptions or {}

        local tbl = {
            ActivateSonicAbility,
            "Ультра бег"
        }

        hg.radialOptions[#hg.radialOptions + 1] = tbl
    end)
end
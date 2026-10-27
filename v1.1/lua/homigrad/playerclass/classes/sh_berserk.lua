local CLASS = player.RegClass("berserk")
-- 1. Подавляем стандартный смех и фразы (из базовой логики)
CLASS.CanUseDefaultPhrase = false 
CLASS.CanEmitRNDSound = false
CLASS.CanUseGestures = true

-- =============================================================
-- ТАБЛИЦЫ ЗВУКОВ
-- =============================================================
local Snd = {
    agony = {"brawl/berserk/tagilla_agony_01.wav", "brawl/berserk/tagilla_agony_02.wav", "brawl/berserk/tagilla_agony_03.wav", "brawl/berserk/tagilla_agony_04.wav"},
    badwork = {"brawl/berserk/tagilla_badwork_01.wav", "brawl/berserk/tagilla_badwork_02.wav"},
    breath = {
        ok = "brawl/berserk/tagilla_breath_ok_01.wav",
        sprint = "brawl/berserk/tagilla_breath_sprint_01.wav",
        hurt = "brawl/berserk/tagilla_breath_hurt_01.wav",
        death = "brawl/berserk/tagilla_breath_death_01.wav"
    },
    broke_hand = {"brawl/berserk/tagilla_broke_hand_01.wav"},
    broke_leg = {"brawl/berserk/tagilla_broke_leg_01.wav"},
    death = {"brawl/berserk/tagilla_death_01.wav", "brawl/berserk/tagilla_death_02.wav", "brawl/berserk/tagilla_death_03.wav", "brawl/berserk/tagilla_death_04.wav", "brawl/berserk/tagilla_death_05.wav", "brawl/berserk/tagilla_death_06.wav", "brawl/berserk/tagilla_death_07.wav", "brawl/berserk/tagilla_death_08.wav"},
    enemy_spot = {"brawl/berserk/tagilla_enemy_01.wav", "brawl/berserk/tagilla_enemy_02.wav", "brawl/berserk/tagilla_enemy_03.wav", "brawl/berserk/tagilla_fight_start_01.wav", "brawl/berserk/tagilla_fight_start_02.wav", "brawl/berserk/tagilla_fight_start_03.wav", "brawl/berserk/tagilla_fight_start_04.wav", "brawl/berserk/tagilla_fight_start_05.wav", "brawl/berserk/tagilla_fight_start_06.wav", "brawl/berserk/tagilla_fight_start_07.wav", "brawl/berserk/tagilla_fight_start_08.wav"},
    enemy_down = {"brawl/berserk/tagilla_enemy_down_01.wav", "brawl/berserk/tagilla_enemy_down_02.wav", "brawl/berserk/tagilla_enemy_down_03.wav"},
    goodwork = {"brawl/berserk/tagilla_goodwork_01.wav", "brawl/berserk/tagilla_goodwork_02.wav"},
    fight = {"brawl/berserk/tagilla_fight_07.wav", "brawl/berserk/tagilla_fight_08.wav", "brawl/berserk/tagilla_fight_09.wav", "brawl/berserk/tagilla_fight_10.wav", "brawl/berserk/tagilla_fight_11.wav", "brawl/berserk/tagilla_fight_12.wav", "brawl/berserk/tagilla_fight_13.wav", "brawl/berserk/tagilla_fight_14.wav", "brawl/berserk/tagilla_fight_15.wav", "brawl/berserk/tagilla_fight_16.wav", "brawl/berserk/tagilla_fight_17.wav", "brawl/berserk/tagilla_fight_18.wav", "brawl/berserk/tagilla_fight_19.wav", "brawl/berserk/tagilla_fight_20.wav", "brawl/berserk/tagilla_fight_21.wav", "brawl/berserk/tagilla_fight_22.wav", "brawl/berserk/tagilla_fight_23.wav", "brawl/berserk/tagilla_fight_24.wav", "brawl/berserk/tagilla_fight_25.wav", "brawl/berserk/tagilla_fight_26.wav", "brawl/berserk/tagilla_fight_27.wav", "brawl/berserk/tagilla_fight_28.wav", "brawl/berserk/tagilla_fight_29.wav", "brawl/berserk/tagilla_fight_30.wav", "brawl/berserk/tagilla_enemy_hit_01.wav", "brawl/berserk/tagilla_enemy_hit_02.wav"},
    
    -- Все звуки урона теперь в одной таблице для рандомного воспроизведения
    hurt = {
        "brawl/berserk/tagilla_hurt_light_01.wav",
        "brawl/berserk/tagilla_hurt_medium_02.wav", 
        "brawl/berserk/tagilla_hurt_medium_03.wav", 
        "brawl/berserk/tagilla_hurt_medium_04.wav", 
        "brawl/berserk/tagilla_hurt_medium_05.wav", 
        "brawl/berserk/tagilla_hurt_medium_06.wav", 
        "brawl/berserk/tagilla_hurt__medium_01.wav", 
        "brawl/berserk/tagilla_hurt__medium_07.wav", 
        "brawl/berserk/tagilla_hurt__medium_08.wav", 
        "brawl/berserk/tagilla_hurt__medium_09.wav", 
        "brawl/berserk/tagilla_hurt__medium_10.wav", 
        "brawl/berserk/tagilla_hurt__medium_11.wav",
        "brawl/berserk/tagilla_hurt_hard_07.wav", 
        "brawl/berserk/tagilla_hurt_hard_08.wav", 
        "brawl/berserk/tagilla_hurt_hard_09.wav", 
        "brawl/berserk/tagilla_hurt_hard_10.wav",
        "brawl/berserk/tagilla_hurt_neardeath_01.wav", 
        "brawl/berserk/tagilla_hurt_neardeath_02.wav"
    },
    lost_visual = {"brawl/berserk/tagilla_lost_visual_n_01.wav", "brawl/berserk/tagilla_lost_visual_n_02.wav", "brawl/berserk/tagilla_lost_visual_n_03.wav"}
}

-- =============================================================
-- УТИЛИТЫ И ПРОВЕРКИ
-- =============================================================
local function CanSpeak(ply)
    if not IsValid(ply) or not ply:Alive() then return false end
    if ply.PlayerClassName ~= "berserk" then return false end
    
    local org = ply.organism
    if not org then return false end
    
    -- Блокируем реплики, если персонаж в отрубе или рэгдолле (fake)
    if org.otrub or org.fake or ply.FakeRagdoll then return false end
    
    return true
end

-- Обновленная функция с системой приоритетов (0 - обычный, 1 - обнаружение, 2 - добивание/перелом)
local function PlayVoiceLine(ply, soundTbl, cooldownKey, cooldownTime, priority)
    priority = priority or 0
    if not CanSpeak(ply) then return end
    
    -- Проверка глобального кулдауна на звук, если передан
    if cooldownKey and (ply[cooldownKey] or 0) > CurTime() then return end

    -- Если звук уже играет, перебиваем только если приоритет нового звука ВЫШЕ
    local isPlaying = (ply.BskNextVoice or 0) > CurTime()
    if isPlaying and priority <= (ply.BskSoundPriority or 0) then return end

    local snd = table.Random(soundTbl)
    
    -- Принудительно глушим предыдущий звук перед проигрыванием нового
    if ply.BskLastSnd then
        ply:StopSound(ply.BskLastSnd)
    end
    
    -- Громкость 70 = слышно примерно за 10-15 метров четко
    ply:EmitSound(snd, 80, ply.VoicePitch or 100, 1, CHAN_VOICE)
    
    ply.BskLastSnd = snd
    -- Накладываем блокировку на остальные звуки на время длительности текущего
    ply.BskNextVoice = CurTime() + SoundDuration(snd) + 0.2
    ply.BskSoundPriority = priority
    
    if cooldownKey and cooldownTime then
        ply[cooldownKey] = CurTime() + cooldownTime
    end
end

-- Очистка звука дыхания (предотвращение утечек)
local function StopBreath(ply)
    if ply.BskBreathPatch then
        ply.BskBreathPatch:Stop()
        ply.BskBreathPatch = nil
    end
    ply.BskCurrentBreathType = nil
end

-- =============================================================
-- ИНИЦИАЛИЗАЦИЯ И ОЧИСТКА КЛАССА
-- =============================================================
function CLASS.On(self)
    if CLIENT then return end
    ApplyAppearance(self)
    self:SetNWString("PlayerName", "Berserk")
    
    self.BskCombatState = false
    self.BskLastEnemySeen = 0
    self.BskHandBroke = false
    self.BskLegBroke = false
    StopBreath(self)
end

function CLASS.Off(self)
    if CLIENT then return end
    StopBreath(self)
end

function CLASS.Guilt(self, Victim)
    if CLIENT then return end
    return 1
end

if SERVER then
    -- Уборка мусора при дисконнекте
    hook.Add("PlayerDisconnected", "Berserk_Cleanup", function(ply)
        StopBreath(ply)
    end)
    
    -- Остановка дыхания при смерти
    hook.Add("PostPlayerDeath", "Berserk_DeathStop", function(ply)
        StopBreath(ply)
    end)

    -- =============================================================
    -- ЛОГИКА ДЫХАНИЯ, ПЕРЕЛОМОВ И СКАНЕР ВРАГОВ (1 раз в сек)
    -- =============================================================
    hook.Add("PlayerTick", "Berserk_MainLogic", function(ply, mv)
        if ply.PlayerClassName ~= "berserk" then return end
        if (ply.BskNextTick or 0) > CurTime() then return end
        ply.BskNextTick = CurTime() + 1
        
        local org = ply.organism
        if not org then return end

        -------------------------------------------------
        -- 0. ПРОВЕРКА ПЕРЕЛОМОВ (Приоритет 2)
        -------------------------------------------------
        if CanSpeak(ply) then
            if not ply.BskHandBroke and (org.larmdislocation or org.rarmdislocation) then
                PlayVoiceLine(ply, Snd.broke_hand, nil, nil, 2)
                ply.BskHandBroke = true
            elseif ply.BskHandBroke and not (org.larmdislocation or org.rarmdislocation) then
                ply.BskHandBroke = false
            end
            
            if not ply.BskLegBroke and (org.llegdislocation or org.rlegdislocation) then
                PlayVoiceLine(ply, Snd.broke_leg, nil, nil, 2)
                ply.BskLegBroke = true
            elseif ply.BskLegBroke and not (org.llegdislocation or org.rlegdislocation) then
                ply.BskLegBroke = false
            end
        end

        -------------------------------------------------
        -- 1. СИСТЕМА ДЫХАНИЯ
        -------------------------------------------------
        if org.otrub or not ply:Alive() then
            StopBreath(ply)
        else
            local desiredBreath = "ok"
            local hp = ply:Health()
            
            if org.critical or hp <= 20 then
                desiredBreath = "death"
            elseif hp < 70 or org.pain > 40 then
                desiredBreath = "hurt"
            elseif ply:IsSprinting() and ply:GetVelocity():LengthSqr() > 40000 then
                desiredBreath = "sprint"
            end

            if ply.BskCurrentBreathType ~= desiredBreath then
                StopBreath(ply)
                local patch = CreateSound(ply, Snd.breath[desiredBreath])
                if patch then
                    patch:SetSoundLevel(75)
                    patch:PlayEx(1, ply.VoicePitch or 100)
                    ply.BskBreathPatch = patch
                    ply.BskCurrentBreathType = desiredBreath
                end
            end
        end

        -------------------------------------------------
        -- 2. СКАНЕР ВРАГОВ И СОСТОЯНИЕ БОЯ
        -------------------------------------------------
        if CanSpeak(ply) then
            local enemySpotted = false
            local myPos = ply:EyePos()
            
            for _, ent in ipairs(ents.FindInSphere(myPos, 600)) do
                if ent:IsPlayer() and ent:Alive() and ent ~= ply and ent.PlayerClassName ~= "berserk" then
                    local tr = util.TraceLine({
                        start = myPos,
                        endpos = ent:EyePos(),
                        filter = ply,
                        mask = MASK_OPAQUE
                    })
                    
                    if tr.Entity == ent or not tr.Hit then
                        enemySpotted = true
                        break
                    end
                end
            end

            if enemySpotted then
                ply.BskLastEnemySeen = CurTime()
                
                if not ply.BskCombatState then
                    ply.BskCombatState = true
                    -- Обнаружение перебивает все обычные звуки (Приоритет 1)
                    PlayVoiceLine(ply, Snd.enemy_spot, "BskSpotCD", 10, 1) 
                end
            else
                if ply.BskCombatState and CurTime() - ply.BskLastEnemySeen > 10 then
                    ply.BskCombatState = false
                    PlayVoiceLine(ply, Snd.lost_visual, "BskLostCD", 10)
                end
            end

            -------------------------------------------------
            -- 3. РАНДОМНЫЕ ВЫКРИКИ В БОЮ
            -------------------------------------------------
            if ply.BskCombatState then
                if (ply.BskNextFightShout or 0) < CurTime() then
                    PlayVoiceLine(ply, Snd.fight)
                    ply.BskNextFightShout = CurTime() + math.random(10, 60) 
                end
            end
        end
    end)

    -- =============================================================
    -- ВХОДЯЩИЙ УРОН (НОВЫЕ ХУКИ ДЛЯ ДЕТЕКТА)
    -- =============================================================
    
    -- Хук для ТУПОГО УРОНА (DMG_CLUB, DMG_GENERIC и т.д.)
    hook.Add("PreHomigradDamage", "Berserk_HurtLogic_Blunt", function(ent, dmgInfo, hitgroup, entTarget, harm, hitBoxs, inputHole)
        if not IsValid(ent) or not ent:IsPlayer() then return end
        if ent.PlayerClassName ~= "berserk" then return end
        
        local damage = dmgInfo:GetDamage()
        if damage < 5 then return end
        
        -- Вызов PlayVoiceLine, он сам внутри проверит CanSpeak и проставит кулдаун
        local cooldown = math.Clamp(damage / 25, 2, 4)
        PlayVoiceLine(ent, Snd.hurt, "BskHurtCD", cooldown, 0)
    end)

    -- Хук для УРОНА ОТ ПУЛЬ/ПОРЕЗОВ 
    hook.Add("PreHomigradDamageBulletBleedAdd", "Berserk_HurtLogic_Bullet", function(ent, org, dmgInfo, hitgroup, harm, hitBoxs, inputHole, hook_info)
        if not IsValid(ent) or not ent:IsPlayer() then return end
        if ent.PlayerClassName ~= "berserk" then return end
        
        local damage = dmgInfo:GetDamage()
        if damage < 5 then return end
        
        -- Вызов PlayVoiceLine, он сам внутри проверит CanSpeak и проставит кулдаун
        local cooldown = math.Clamp(damage / 25, 2, 4)
        PlayVoiceLine(ent, Snd.hurt, "BskHurtCD", cooldown, 0)
    end)

    -- =============================================================
    -- ИСХОДЯЩИЙ УРОН (УБИЙСТВА И ПОПАДАНИЯ)
    -- =============================================================
    hook.Add("HomigradDamage", "Berserk_AttackLogic", function(ply, dmgInfo, hitgroup, ent)
        local attacker, victim = dmgInfo:GetAttacker(), ply
        if !attacker or !IsValid(attacker) or (IsValid(attacker) and !attacker:IsPlayer()) then
            attacker = ply:GetPhysicsAttacker()
        end

        if not IsValid(attacker) or not attacker:IsPlayer() then return end
        if not IsValid(victim) or not victim:IsPlayer() then return end
        if attacker == victim then return end
        if attacker.PlayerClassName ~= "berserk" then return end

        local dmgCache = dmgInfo:GetDamage()

        timer.Simple(0, function()
            if not IsValid(attacker) or not CanSpeak(attacker) then return end

            if IsValid(victim) and not victim:Alive() then
                -- ПРОТИВНИК УБИТ (ДОБИВАЮЩИЙ УДАР)
                if dmgCache < 15 and math.random(1, 2) == 1 then
                    PlayVoiceLine(attacker, Snd.goodwork, nil, nil, 2)
                else
                    PlayVoiceLine(attacker, Snd.enemy_down, nil, nil, 2)
                end
                
                attacker.BskCombatState = true
                attacker.BskLastEnemySeen = CurTime()
            elseif IsValid(victim) and victim:Alive() then
                -- ОБЫЧНОЕ ПОПАДАНИЕ (Противник выжил)
                if (attacker.BskHitCD or 0) < CurTime() then
                    PlayVoiceLine(attacker, Snd.fight)
                    attacker.BskHitCD = CurTime() + 5
                end
            end
        end)
    end)

    -- =============================================================
    -- АГОНИЯ И БЛОКИРОВКА СМЕХА ИЗ СТОРОННИХ СКРИПТОВ
    -- =============================================================
    hook.Add("Org Think", "Berserk_AgonyLogic", function(owner, org, timeValue)
        if owner.PlayerClassName ~= "berserk" then return end
        
        -- ЖЕСТКАЯ БЛОКИРОВКА СМЕХА ИЗ sv_phrases.lua
        owner.lastBerserkLaughSoundCD = CurTime() + 9999

        if not IsValid(owner) or not owner:IsPlayer() or not owner:Alive() then return end
        if org.otrub or org.fake or owner.FakeRagdoll then return end
        
        if org.critical and (owner.BskAgonyCD or 0) < CurTime() then
            if math.random(1, 10) == 1 then
                local snd = table.Random(Snd.agony)
                owner:EmitSound(snd, 70)
                owner.BskAgonyCD = CurTime() + 15
            end
        end
    end)

    -- =============================================================
    -- СМЕРТЬ
    -- =============================================================
    hook.Add("PlayerDeath", "Berserk_DeathLogic", function(victim, inflictor, attacker)
        if victim.PlayerClassName ~= "berserk" then return end
        StopBreath(victim)
        
        local snd = table.Random(Snd.death)
        local rag = (hg and hg.GetCurrentCharacter(victim)) or victim
        
        if IsValid(rag) then
            rag:EmitSound(snd, 75, victim.VoicePitch or 100)
        end
    end)
end
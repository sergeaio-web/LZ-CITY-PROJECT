-- ============================================================================
--  Роль трейтора: ПАЛАЧ (traitor_executioner)
--  Положить в: gamemodes/zcity/gamemode/modes/homicide/sh_zexecutioner.lua
--
--  Имя файла начинается с "sh_z" специально: файлы режима грузятся по алфавиту,
--  и этот должен загрузиться ПОСЛЕ sh_homicide.lua (где создаётся MODE.SubRoles).
-- ============================================================================
local MODE = MODE

local ROLE_ID = "traitor_executioner"

--\\ Настройки роли (меняй цифры здесь)
MODE.ExecutionerConfig = {
	MeleeDamageMul    = 1.05, -- плюс: урон ближнего боя +5%
	SpeedMul          = 1.01, -- плюс: скорость +1%
	StaminaExhaustMul = 1.6,  -- минус: стамина тратится в 1.6 раза быстрее

	AbilityDuration   = 15,   -- «Убийство»: длительность эффекта Fury-13, сек
	AbilityCooldown   = 60,   -- «Убийство»: перезарядка (отсчёт после конца эффекта), сек
	FuryPower         = 2,    -- сила эффекта: столько же, сколько даёт сам Fury-13 (org.berserk + 2)
}
--//

local cfg = MODE.ExecutionerConfig

--\\ Роль
MODE.SubRoles[ROLE_ID] = {
	Name = "Палач",
	Description = [[Плюсы:
+ Урон ближнего боя увеличен на 5%
+ Скорость увеличена на 1%

Минусы:
- Стамина быстро кончается

Способности:
Убийство (зажми Q): на 15 секунд даёт эффект Fury-13.
Есть перезарядка.]],
	Objective = "Ты — Палач. Сближайся и убивай, а в решающий момент зажми Q и выбери «Убийство».",
	SpawnFunction = function(ply)
		if not IsValid(ply) then return end

		-- Штык. Если такого оружия нет на сервере — выдаём SOG, чтобы роль не осталась без ножа.
		local blade = ply:Give("weapon_bayonet")
		if not IsValid(blade) then
			ply:Give("weapon_sogknife")
		end

		local pistol = ply:Give("weapon_m45")
		if IsValid(pistol) then
			ply:GiveAmmo(pistol:GetMaxClip1() * 1, pistol:GetPrimaryAmmoType(), true)
		end

		ply:Give("weapon_hg_shuriken")
		ply:Give("weapon_traitor_suit")
		ply:Give("weapon_traitor_poison3")
		ply:Give("weapon_medkit_sh")

		local inv = ply:GetNetVar("Inventory", {})
		if inv["Weapons"] then
			inv["Weapons"]["hg_flashlight"] = true
			ply:SetNetVar("Inventory", inv)
		end

		-- сброс состояния способности на новый раунд
		ply.ExecutionerReadyTime = nil
		ply.ExecutionerFuryEnd = nil

		net.Start("HMCD_Executioner_Sync")
			net.WriteFloat(0)
			net.WriteFloat(0)
		net.Send(ply)
	end,
}

for _, round_type in ipairs({"standard", "soe"}) do
	local round = MODE.RoleChooseRoundTypes and MODE.RoleChooseRoundTypes[round_type]

	if round and round.Traitor then
		round.Traitor[ROLE_ID] = true
	end
end
--//

--\\ Общая проверка «этот игрок сейчас Палач в Homicide»
local function IsExecutioner(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	if ply.SubRole ~= ROLE_ID then return false end
	if zb and (zb.CROUND_MAIN or zb.CROUND) ~= MODE.name then return false end

	return ply:Alive()
end

MODE.IsExecutioner = IsExecutioner
--//

--\\ Плюс: скорость +1%
hook.Add("HG_MovementCalc_2", "HMCD_Executioner_Speed", function(mul, ply, cmd)
	if IsExecutioner(ply) then
		mul[1] = mul[1] * cfg.SpeedMul
	end
end)
--//

if SERVER then
	util.AddNetworkString("HMCD_Executioner_Ability") -- клиент -> сервер: «активировать Убийство»
	util.AddNetworkString("HMCD_Executioner_Sync")    -- сервер -> клиент: сколько осталось эффекта/перезарядки

	local function Sync(ply, ready_in, fury_left)
		net.Start("HMCD_Executioner_Sync")
			net.WriteFloat(ready_in)
			net.WriteFloat(fury_left)
		net.Send(ply)
	end

	--\\ Плюс: урон ближнего боя +5%
	hook.Add("PreHomigradDamage", "HMCD_Executioner_Melee", function(ply, dmgInfo, hitgroup, ent)
		local attacker = dmgInfo:GetAttacker()
		if not IsExecutioner(attacker) then return end
		if not dmgInfo:IsDamageType(DMG_SLASH + DMG_CLUB) then return end

		local inflictor = dmgInfo:GetInflictor()
		if not IsValid(inflictor) or not inflictor:IsWeapon() then return end
		if not weapons.IsBasedOn(inflictor:GetClass(), "weapon_melee") then return end

		dmgInfo:ScaleDamage(cfg.MeleeDamageMul)
	end)
	--//

	--\\ Способность «Убийство» = эффект Fury-13 на 15 секунд
	local function ActivateKill(ply)
		if not IsExecutioner(ply) then return end

		local org = ply.organism
		if not org or org.otrub then return end

		local now = CurTime()
		if (ply.ExecutionerReadyTime or 0) > now then return end

		ply.ExecutionerFuryEnd = now + cfg.AbilityDuration
		ply.ExecutionerReadyTime = now + cfg.AbilityDuration + cfg.AbilityCooldown

		-- Тот же эффект, что даёт Fury-13 (berserk), только на 15 секунд.
		org.berserk = cfg.FuryPower

		ply:EmitSound("snd_jack_hmcd_needleprick.wav", 60, math.random(75, 90))
		ply:ChatPrint("Убийство активировано: " .. cfg.AbilityDuration .. " сек.")

		Sync(ply, cfg.AbilityDuration + cfg.AbilityCooldown, cfg.AbilityDuration)
	end

	net.Receive("HMCD_Executioner_Ability", function(len, ply)
		ActivateKill(ply)
	end)

	hook.Add("Org Think", "HMCD_Executioner_Think", function(owner, org, timeValue)
		if not IsValid(owner) or not owner:IsPlayer() then return end

		-- Минус: стамина быстро кончается (sv_stamina.lua умножает расход на owner.StaminaExhaustMul)
		if IsExecutioner(owner) then
			owner.StaminaExhaustMul = cfg.StaminaExhaustMul
			owner.ExecutionerStaminaSet = true
		elseif owner.ExecutionerStaminaSet then
			owner.StaminaExhaustMul = nil
			owner.ExecutionerStaminaSet = nil
		end

		-- Эффект «Убийства»: держим berserk и плавно гасим его ровно за 15 секунд
		local fury_end = owner.ExecutionerFuryEnd

		if fury_end then
			local left = fury_end - CurTime()

			if left <= 0 or not IsExecutioner(owner) then
				org.berserk = 0
				owner.ExecutionerFuryEnd = nil
			else
				org.berserk = cfg.FuryPower * (left / cfg.AbilityDuration)
			end
		end
	end)
	--//
end

if CLIENT then
	net.Receive("HMCD_Executioner_Sync", function()
		local ready_in = net.ReadFloat()
		local fury_left = net.ReadFloat()
		local ply = LocalPlayer()

		ply.ExecutionerReadyTime = ready_in > 0 and (CurTime() + ready_in) or nil
		ply.ExecutionerFuryEnd = fury_left > 0 and (CurTime() + fury_left) or nil
	end)

	-- Пункт «Убийство» в Q-menu (виден только Палачу)
	hook.Add("radialOptions", "HMCD_Executioner", function()
		local ply = LocalPlayer()
		if not IsExecutioner(ply) then return end

		local org = ply.organism or {}
		if org.otrub then return end

		local now = CurTime()
		local fury_end = ply.ExecutionerFuryEnd or 0
		local ready_time = ply.ExecutionerReadyTime or 0

		local text = "Убийство"
		if fury_end > now then
			text = "Убийство\nАктивно: " .. math.ceil(fury_end - now) .. " с"
		elseif ready_time > now then
			text = "Убийство\nПерезарядка: " .. math.ceil(ready_time - now) .. " с"
		end

		hg.radialOptions[#hg.radialOptions + 1] = {
			function(mouse_click)
				if mouse_click ~= 1 then return end -- только ЛКМ

				if (LocalPlayer().ExecutionerReadyTime or 0) <= CurTime() then
					net.Start("HMCD_Executioner_Ability")
					net.SendToServer()
				end
			end,
			text
		}
	end)
end
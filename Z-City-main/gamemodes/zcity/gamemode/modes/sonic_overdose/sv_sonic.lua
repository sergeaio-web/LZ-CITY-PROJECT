local MODE = MODE

-- Добавляем Fury-16 в лут после наследования от Superfighters.
function MODE:AfterBaseInheritance()
	self.LootTable = table.Copy(self.LootTable or {})

	for _, lootGroup in ipairs(self.LootTable) do
		if istable(lootGroup) and istable(lootGroup[2]) then
			table.insert(lootGroup[2], {4, "weapon_fury16"})
		end
	end
end

function MODE:RoundStart()
	-- Сначала запускаем стандартную инициализацию Superfighters:
	-- руки, рация, sling, recoil, superfighter и роль.
	if self.BaseClass and self.BaseClass.RoundStart then
		self.BaseClass.RoundStart(self)
	end

	for _, ply in player.Iterator() do
		if not IsValid(ply) or not ply:Alive() then
			continue
		end

		-- Кулаки должны быть выданы обязательно.
		local hands = ply:GetWeapon("weapon_hands_sh")

		if not IsValid(hands) then
			hands = ply:Give("weapon_hands_sh")
		end

		if IsValid(hands) then
			ply:SelectWeapon("weapon_hands_sh")
		end

		if ply.organism then
			-- Эффект Uber Norepinephrine / Fury-16.
			-- Сам предмет игроку не выдаётся.
			ply.organism.noradrenaline = math.max(
				ply.organism.noradrenaline or 0,
				1.25
			)

			-- Оставляем улучшения Superfighters.
			ply.organism.superfighter = true
			ply.organism.recoilmul = 0.2
		end

		ply.sonicOverdose = true
	end
end
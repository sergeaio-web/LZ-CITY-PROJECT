local MODE = MODE

MODE.LootTable = table.Copy(MODE.LootTable or {})

if istable(MODE.LootTable) then
	for _, lootGroup in ipairs(MODE.LootTable) do
		if istable(lootGroup) and #lootGroup >= 2 and istable(lootGroup[2]) then
			lootGroup[2][#lootGroup[2] + 1] = {5, "weapon_fury13"}
		end
	end
end

function MODE:RoundStart()
	for _, ply in player.Iterator() do
		if not IsValid(ply) or not ply:Alive() then
			continue
		end

		ply:SetSuppressPickupNotices(true)
		ply.noSound = true

		local hands = ply:Give("weapon_hands_sh")
		ply:SelectWeapon(hands)

		local inv = ply:GetNetVar("Inventory") or {}
		inv["Weapons"] = inv["Weapons"] or {}
		inv["Weapons"]["hg_sling"] = true
		ply:SetNetVar("Inventory", inv)

		ply:Give("weapon_walkie_talkie")

		if ply.organism then
			ply.organism.recoilmul = 0.25
			ply.organism.superfighter = true

			-- эффект Fury-13 начинает действовать сразу
			ply.organism.berserk = (ply.organism.berserk or 0) + 2
		end

		timer.Simple(0.1, function()
			if IsValid(ply) then
				ply.noSound = false
			end
		end)

		ply:SetSuppressPickupNotices(false)

		zb.GiveRole(ply, "Передоз", Color(190, 15, 15))
	end
end

function MODE:GiveWeapons()
end

function MODE:GiveEquipment()
end
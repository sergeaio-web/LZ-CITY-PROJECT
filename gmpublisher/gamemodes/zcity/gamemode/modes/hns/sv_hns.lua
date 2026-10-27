local MODE = MODE

MODE.HiderColor = Color(190, 120, 0)
MODE.SeekerColor = Color(0, 120, 190)
MODE.SWATColor = Color(30, 30, 100)

util.AddNetworkString("hns_start")

local function shuffle(tbl)
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
end

local function getPointVectors(pointGroup)
	return zb.TranslatePointsToVectors(zb.GetMapPoints(pointGroup))
end

local function getDamageAttacker(dmginfo)
	local attacker = dmginfo:GetAttacker()
	if IsValid(attacker) and attacker:IsPlayer() then
		return attacker
	end

	local inflictor = dmginfo:GetInflictor()
	if IsValid(inflictor) then
		if inflictor:IsPlayer() then
			return inflictor
		end

		local owner = inflictor:GetOwner()
		if IsValid(owner) and owner:IsPlayer() then
			return owner
		end
	end

	if IsValid(attacker) then
		local owner = attacker:GetOwner()
		if IsValid(owner) and owner:IsPlayer() then
			return owner
		end
	end
end

function MODE:CreateTimer(name, delay, repetitions, func)
	self.saved.Timers = self.saved.Timers or {}

	if timer.Exists(name) then
		timer.Remove(name)
	end

	timer.Create(name, delay, repetitions, func)
	self.saved.Timers[name] = true
end

function MODE:ClearTimers()
	if not self.saved or not self.saved.Timers then return end

	for name in pairs(self.saved.Timers) do
		timer.Remove(name)
	end

	self.saved.Timers = {}
end

function MODE:SyncSWATGlobals()
	SetGlobalFloat("ZB_HNS_SWAT_TIME", self.saved.SWATDeadline or 0)
	SetGlobalBool("ZB_HNS_SWAT_PENDING", (self.saved.SWATCountdownStarted or false) and not (self.saved.SWATDeployed or false))
	SetGlobalBool("ZB_HNS_SWAT_READY", (self.saved.SWATReady or false) and not (self.saved.SWATDeployed or false))
	SetGlobalBool("ZB_HNS_SWAT_DEPLOYED", self.saved.SWATDeployed or false)
end

function MODE:ResetSWATState()
	self.saved.SWATCountdownStarted = false
	self.saved.SWATReady = false
	self.saved.SWATDeployed = false
	self.saved.SWATDeadline = 0

	self:SyncSWATGlobals()
end

function MODE:GetFallbackSpawnVectors()
	local randomPoints = getPointVectors("RandomSpawns")
	if #randomPoints > 0 then
		return randomPoints
	end

	local randomSpawn = zb:GetRandomSpawn()
	return randomSpawn and {randomSpawn} or {}
end

function MODE:GetSpawnVectors(pointGroup)
	local points = getPointVectors(pointGroup)
	if #points > 0 then
		return points
	end

	return self:GetFallbackSpawnVectors()
end

function MODE:GetTeamSpawn()
	return self:GetSpawnVectors("HNS_HIDER"), self:GetSpawnVectors("HNS_SEEKER")
end

function MODE:GetRoundPlayers()
	local players = {}

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end

		players[#players + 1] = ply
	end

	return players
end

function MODE:GetAlivePlayersForTeam(team_)
	local players = {}

	for _, ply in player.Iterator() do
		if ply:Team() ~= team_ then continue end
		if not ply:Alive() then continue end
		if ply.organism and ply.organism.incapacitated then continue end

		players[#players + 1] = ply
	end

	return players
end

function MODE:GetAliveHiders()
	return self:GetAlivePlayersForTeam(self.HiderTeam)
end

function MODE:GetAliveSeekers()
	return self:GetAlivePlayersForTeam(self.SeekerTeam)
end

function MODE:GetAliveSWAT()
	return self:GetAlivePlayersForTeam(self.SWATTeam)
end

function MODE:GetAliveHunters()
	local hunters = self:GetAliveSeekers()

	for _, ply in ipairs(self:GetAliveSWAT()) do
		hunters[#hunters + 1] = ply
	end

	return hunters
end

function MODE:GetDeadPlayersForSWAT()
	local players = {}

	for _, ply in player.Iterator() do
		if ply:Alive() then continue end
		if ply:Team() == TEAM_SPECTATOR then continue end
		if ply.afkTime2 and ply.afkTime2 > 60 then continue end

		players[#players + 1] = ply
	end

	return players
end

function MODE:GetSeekerCount(playerCount)
	if playerCount > 8 then
		return 2
	end

	return 1
end

function MODE:AssignTeams()
	local players = self:GetRoundPlayers()
	shuffle(players)

	local seekerCount = math.min(self:GetSeekerCount(#players), math.max(#players - 1, 1))

	for index, ply in ipairs(players) do
		ply:SetTeam(index <= seekerCount and self.SeekerTeam or self.HiderTeam)
	end
end

function MODE:CanLaunch()
	return #self:GetRoundPlayers() > 1
end

function MODE:Intermission()
	game.CleanUpMap()

	self:ClearTimers()
	self:ResetSWATState()
	self.saved.Winner = nil

	self:AssignTeams()

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end

		ply:SetupTeam(ply:Team())
	end

	net.Start("hns_start")
	net.Broadcast()
end

local function preparePlayer(ply)
	ply:SetSuppressPickupNotices(true)
	ply.noSound = true
	ply:StripWeapons()
	ply:StripAmmo()
	ply.armors = {}
	ply:SyncArmor()
end

local function finishPreparingPlayer(ply)
	timer.Simple(0.1, function()
		if not IsValid(ply) then return end

		ply.noSound = false
		ply:SetSuppressPickupNotices(false)
	end)
end

local function setRoundRoleFlags(ply, isPolice)
	ply.isPolice = isPolice or false
	ply.isTraitor = false
	ply.isGunner = false
end

local function giveHands(ply)
	local hands = ply:Give("weapon_hands_sh")
	if IsValid(hands) then
		ply:SelectWeapon("weapon_hands_sh")
		ply:SetActiveWeapon(hands)

		timer.Simple(0, function()
			if not IsValid(ply) then return end
			if not IsValid(ply:GetWeapon("weapon_hands_sh")) then return end

			ply:SelectWeapon("weapon_hands_sh")
		end)
	end

	return hands
end

function MODE:EquipHider(ply)
	preparePlayer(ply)
	setRoundRoleFlags(ply, false)

	ply:SetPlayerClass("default")
	giveHands(ply)
	zb.GiveRole(ply, "Hider", self.HiderColor)

	finishPreparingPlayer(ply)
end

function MODE:EquipSeeker(ply)
	preparePlayer(ply)
	setRoundRoleFlags(ply, false)

	ply:SetPlayerClass("default")

	local shotgun = ply:Give("weapon_remington870")
	if IsValid(shotgun) then
		ply:GiveAmmo(100, shotgun:GetPrimaryAmmoType(), true)
	end

	for i = 1, 3 do
		ply:Give("weapon_hg_pipebomb_tpik")
	end

	hg.AddArmor(ply, {"vest4"})
	giveHands(ply)

	zb.GiveRole(ply, "Seeker", self.SeekerColor)

	finishPreparingPlayer(ply)
end

function MODE:EquipFallbackSWAT(ply)
	preparePlayer(ply)
	setRoundRoleFlags(ply, true)

	ply:SetPlayerClass("swat")

	local primary = ply:Give("weapon_m4a1")
	if IsValid(primary) then
		ply:GiveAmmo(primary:GetMaxClip1() * 3, primary:GetPrimaryAmmoType(), true)
	end

	local pistol = ply:Give("weapon_glock17")
	if IsValid(pistol) then
		ply:GiveAmmo(pistol:GetMaxClip1() * 3, pistol:GetPrimaryAmmoType(), true)
	end

	ply:Give("weapon_melee")
	ply:Give("weapon_handcuffs")
	ply:Give("weapon_handcuffs_key")
	ply:Give("weapon_hg_flashbang_tpik")

	hg.AddArmor(ply, {"helmet6", "vest8"})
	giveHands(ply)
	zb.GiveRole(ply, "SWAT Operative", self.SWATColor)

	finishPreparingPlayer(ply)
end

function MODE:GiveEquipment()
	timer.Simple(0.1, function()
		local round = CurrentRound()
		if not round or round.name ~= MODE.name then return end

		for _, ply in player.Iterator() do
			if not ply:Alive() then continue end
			if ply:Team() == TEAM_SPECTATOR then continue end

			if ply:Team() == self.HiderTeam then
				self:EquipHider(ply)
			elseif ply:Team() == self.SeekerTeam then
				self:EquipSeeker(ply)
			end
		end
	end)
end

function MODE:CheckAlivePlayers()
	return {self:GetAliveHiders(), self:GetAliveHunters()}
end

function MODE:StartSWATCountdown()
	if self.saved.SWATCountdownStarted or self.saved.SWATDeployed then return end
	if #self:GetAliveSeekers() == 0 or #self:GetAliveHiders() == 0 then return end

	self.saved.SWATCountdownStarted = true
	self.saved.SWATReady = false
	self.saved.SWATDeadline = CurTime() + self.SWATDelay

	self:SyncSWATGlobals()
	PrintMessage(HUD_PRINTTALK, "SWAT countdown started.")

	self:CreateTimer("ZB_HNS_SWATCountdown", self.SWATDelay, 1, function()
		if zb.ROUND_STATE ~= 1 then return end
		local round = CurrentRound()
		if not MODE or not round or round.name ~= MODE.name then return end

		MODE.saved.SWATReady = true
		MODE:SyncSWATGlobals()

		if MODE:DeploySWAT() <= 0 then
			PrintMessage(HUD_PRINTTALK, "SWAT ждет мертвых игроков.")
		end
	end)
end

function MODE:DeploySWAT()
	if self.saved.SWATDeployed or not self.saved.SWATReady then return 0 end
	if #self:GetAliveSeekers() == 0 or #self:GetAliveHiders() == 0 then return 0 end

	local deadPlayers = self:GetDeadPlayersForSWAT()
	if #deadPlayers <= 0 then return 0 end

	shuffle(deadPlayers)

	local swatMode = zb.modes["hmcd"]
	local spawnVectors = self:GetSpawnVectors("HNS_SWAT")
	local basePos = (#spawnVectors > 0 and table.Random(spawnVectors)) or zb:GetRandomSpawn() or vector_origin
	local spawned = 0

	for index = 1, math.min(#deadPlayers, 5) do
		local ply = deadPlayers[index]
		if not IsValid(ply) then continue end

		setRoundRoleFlags(ply, true)
		ply:SetTeam(self.SWATTeam)
		ply:Spawn()
		ply:SetTeam(self.SWATTeam)
		hg.CreateInv(ply)

		if spawned == 0 then
			ply:SetPos(basePos)
		else
			hg.tpPlayer(basePos, ply, math.Clamp(ply:EntIndex() % 24 + 1, 1, 24), 0)
		end

		if swatMode and swatMode.EquipSWAT then
			swatMode:EquipSWAT(ply, spawned + 1)
		else
			self:EquipFallbackSWAT(ply)
		end

		spawned = spawned + 1
	end

	if spawned > 0 then
		self.saved.SWATDeployed = true
		self:SyncSWATGlobals()

		PrintMessage(HUD_PRINTTALK, "Команда SWAT прибыла!")
		EmitSound("snd_jack_hmcd_heli2.mp3", vector_origin, 0, CHAN_AUTO, 1, 125, 0, 100)
	end

	return spawned
end

function MODE:ShouldRoundEnd()
	if #self:GetAliveSeekers() == 0 then
		self.saved.Winner = self.HiderTeam
		return true
	end

	if #self:GetAliveHiders() == 0 then
		self.saved.Winner = self.SeekerTeam
		return true
	end

	return false
end

function MODE:RoundStart()
end

function MODE:RoundThink()
	if self.saved.SWATReady and not self.saved.SWATDeployed then
		self:DeploySWAT()
	end
end

function MODE:EntityTakeDamage(ent, dmginfo)
	if not IsValid(ent) or not ent:IsPlayer() then return end

	local attacker = getDamageAttacker(dmginfo)
	if not IsValid(attacker) or attacker == ent then return end
	if not self:IsModeParticipant(attacker) or not self:IsModeParticipant(ent) then return end

	if self:IsAlliedTeam(attacker:Team(), ent:Team()) then
		dmginfo:ScaleDamage(0)
		return true
	end

	if self:IsPreparationActive() then
		dmginfo:ScaleDamage(0)
		return true
	end

	if attacker:Team() == self.SeekerTeam and ent:Team() == self.HiderTeam and dmginfo:GetDamage() > 0 then
		self:StartSWATCountdown()
	end
end

function MODE:CanSpawn()
end

function MODE:PlayerDeath(ply)
	if self.saved.SWATReady and not self.saved.SWATDeployed then
		self:DeploySWAT()
	end
end

function MODE:EndRound()
	local winner = self.saved.Winner
	local winnerText = "Ничья."

	if winner == self.HiderTeam then
		winnerText = "Прячущиеся выиграли."
	elseif winner == self.SeekerTeam then
		winnerText = "Искатели победили."
	end

	self:ClearTimers()
	self:ResetSWATState()

	PrintMessage(HUD_PRINTTALK, winnerText)

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end

		local won = false
		if winner == self.HiderTeam then
			won = ply:Team() == self.HiderTeam
		elseif winner == self.SeekerTeam then
			won = self:IsHunterTeam(ply:Team())
		end

		if won then
			ply:GiveExp(math.random(15, 30))
			ply:GiveSkill(math.Rand(0.1, 0.15))
		else
			ply:GiveSkill(-math.Rand(0.05, 0.1))
		end
	end
end

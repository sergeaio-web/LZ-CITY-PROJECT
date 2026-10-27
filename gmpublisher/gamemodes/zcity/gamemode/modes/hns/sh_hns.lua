local MODE = MODE

MODE.name = "hns"
MODE.PrintName = "Прятки"
MODE.LootSpawn = false
MODE.GuiltDisabled = true
MODE.ForBigMaps = false
MODE.OverrideSpawn = true
MODE.Chance = 0.03
MODE.ROUND_TIME = 300
MODE.start_time = 0

MODE.PrepareTime = 20
MODE.SWATDelay = 60

MODE.HiderTeam = 0
MODE.SeekerTeam = 1
MODE.SWATTeam = 2

zb = zb or {}
zb.Points = zb.Points or {}

zb.Points.HNS_HIDER = zb.Points.HNS_HIDER or {}
zb.Points.HNS_HIDER.Color = Color(190, 120, 0)
zb.Points.HNS_HIDER.Name = "HNS_HIDER"

zb.Points.HNS_SEEKER = zb.Points.HNS_SEEKER or {}
zb.Points.HNS_SEEKER.Color = Color(0, 90, 190)
zb.Points.HNS_SEEKER.Name = "HNS_SEEKER"

zb.Points.HNS_SWAT = zb.Points.HNS_SWAT or {}
zb.Points.HNS_SWAT.Color = Color(30, 30, 100)
zb.Points.HNS_SWAT.Name = "HNS_SWAT"

function MODE:IsModeParticipant(ply)
	if not IsValid(ply) then return false end

	local team_ = ply:Team()

	return team_ == self.HiderTeam or team_ == self.SeekerTeam or team_ == self.SWATTeam
end

function MODE:IsPreparationActive()
	return (zb.ROUND_START or 0) + self.PrepareTime > CurTime()
end

function MODE:IsHunterTeam(team_)
	return team_ == self.SeekerTeam or team_ == self.SWATTeam
end

function MODE:IsAlliedTeam(teamA, teamB)
	if teamA == teamB then return true end

	return self:IsHunterTeam(teamA) and self:IsHunterTeam(teamB)
end

function MODE:HG_MovementCalc_2(mul, ply, cmd, mv)
	if not self:IsPreparationActive() or not cmd or not self:IsModeParticipant(ply) then return end

	cmd:RemoveKey(IN_ATTACK)
	cmd:RemoveKey(IN_ATTACK2)

	if mv then
		mv:RemoveKey(IN_ATTACK)
		mv:RemoveKey(IN_ATTACK2)
	end

	local hands = IsValid(ply) and ply:GetWeapon("weapon_hands_sh")
	if IsValid(hands) then
		cmd:SelectWeapon(hands)

		if SERVER then
			ply:SelectWeapon("weapon_hands_sh")
		end
	end
end

function MODE:PlayerCanLegAttack(ply)
	if self:IsPreparationActive() and self:IsModeParticipant(ply) then
		return false
	end
end

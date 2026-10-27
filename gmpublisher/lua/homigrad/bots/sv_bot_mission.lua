--[[
	Tarkov AI - Missions (roles and each bot's own game plan)

	Without this an idle bot only wanders at random and reacts to what hits
	it. A mission gives it something to DO between fights, according to its
	ROLE:

	- attacker  goes for the enemy, straight and fast (running when far);
	- hunter    closes in by stages: moves up, holds and watches, moves up
	            again, instead of walking into the open;
	- defender  holds ground around its objective (or where it spawned),
	            moving between nearby spots, watching the likely approach;
	- survivor  hides: picks the spot farthest from everyone and holds it;
	- support   stays with the nearest friendly player or bot.
	Anything else (scavengers, wanderers) keeps the normal wander / loot.

	Who is the ENEMY comes from the game mode (sv_bot_modes.lua: teams or an
	adapter), plus anybody who attacked the bot or was reported to it
	(sv_bot_judgement.lua) - so a traitor is hunted by those who were told.
	Outside a mode with teams, nobody is an enemy until somebody gives a
	reason, so the roles that need an enemy simply wander.

	Where the role comes from: the mode adapter's Role(bot) if it has one,
	else the bot's character (sv_bot_personality.lua):
	rusher/hothead -> attacker, hunter -> hunter, veteran -> defender,
	coward -> survivor. A mode adapter may also hand out an Objective
	{ pos, kind = "go" | "hold", watch }.

	Each bot's plan changes with experience. Dying makes it more careful and
	less aggressive, a kill does the opposite; an attacker that has died
	three times starts playing like a hunter. The numbers live on the
	character, so they carry over respawns.

	Runs from the idle state through an extension point (after orders and
	loot, before random wandering). Fighting, alert, healing and holds keep
	their own priority. Respects hg_bot_mission 0.
]]

hg.bots = hg.bots or {}
hg.bots.List = hg.bots.List or {}

local hg_bot_mission         = CreateConVar("hg_bot_mission",         "1",   {FCVAR_ARCHIVE}, "Idle bots follow a mission by role (attack, hunt, defend, hide, support) instead of wandering at random", 0, 1)
local hg_bot_mission_know    = CreateConVar("hg_bot_mission_know",    "1",   {FCVAR_ARCHIVE}, "Bots going after an enemy roughly know where they are (blurred by distance); 0 = only what they have heard or seen", 0, 1)
local hg_bot_mission_error   = CreateConVar("hg_bot_mission_error",   "600", {FCVAR_ARCHIVE}, "How far off a bot's guess about the enemy's position can be", 0, 3000)
local hg_bot_mission_rethink = CreateConVar("hg_bot_mission_rethink", "20",  {FCVAR_ARCHIVE}, "Seconds between a bot's re-planning", 3, 120)
local hg_bot_mission_learn   = CreateConVar("hg_bot_mission_learn",   "1",   {FCVAR_ARCHIVE}, "Bots change their style with experience (deaths make them careful, kills bold)", 0, 1)

--\\ Roles
	local ROLE_BY_ARCHETYPE = {
		rusher = "attacker", hothead = "attacker", hunter = "hunter",
		veteran = "defender", coward = "survivor",
	}

	function hg.bots.GetRole(bot)
		local role = hg.bots.ModeRole and hg.bots.ModeRole(bot)

		if role then return role end

		local p = hg.bots.GetPersonality and hg.bots.GetPersonality(bot)

		if not p then return nil end

		role = ROLE_BY_ARCHETYPE[p.id]

		-- Learned the hard way.
		if role == "attacker" and (p.deaths or 0) >= 3 then role = "hunter" end

		return role
	end
--//

--\\ Who is the enemy
	local function IsEnemy(bot, ent)
		if not IsValid(ent) or ent == bot or not ent:IsPlayer() or not ent:Alive() then return false end

		local mode = hg.bots.ModeHostile and hg.bots.ModeHostile(ent, bot)

		if mode ~= nil then return mode end

		if ent.IsHomigradBot then
			return hg.bots.SameFaction and not hg.bots.SameFaction(ent, bot) or false
		end

		local mem = bot.Bot.Memory

		return (mem.Grudge and mem.Grudge[ent]) or (mem.Informed and (mem.Informed[ent] or 0) > CurTime()) or false
	end

	local function NearestEnemy(bot)
		local best, bestD2
		local pos = bot:GetPos()

		for _, ply in ipairs(player.GetAll()) do
			if IsEnemy(bot, ply) then
				local d2 = pos:DistToSqr(ply:GetPos())

				if not bestD2 or d2 < bestD2 then best, bestD2 = ply, d2 end
			end
		end

		return best, bestD2 and math.sqrt(bestD2) or nil
	end

	local function NearestFriend(bot)
		local best, bestD2
		local pos = bot:GetPos()

		for _, ply in ipairs(player.GetAll()) do
			if ply ~= bot and ply:Alive() then
				local same = hg.bots.ModeSameSide and hg.bots.ModeSameSide(ply, bot)

				if same == nil and not ply.IsHomigradBot then
					-- No mode opinion: humans a guard bot protects (factions).
					same = hg.bots.GetFaction and hg.bots.GetFaction(bot) == "guard"
				end

				if same then
					local d2 = pos:DistToSqr(ply:GetPos())

					if not bestD2 or d2 < bestD2 then best, bestD2 = ply, d2 end
				end
			end
		end

		return best, bestD2 and math.sqrt(bestD2) or nil
	end
--//

--\\ Planning
	local function Snap(pos, radius)
		return hg.bots.SnapToNavmesh and hg.bots.SnapToNavmesh(pos, radius or 300) or nil
	end

	--- A walk (and what to do on arrival): { kind = "goto", pos, run, watch, hold }.
	local function GoTo(pos, run, watch, hold)
		return { kind = "goto", pos = pos, run = run, watch = watch, hold = hold }
	end

	local function PlanHunt(bot, data, role, p)
		local enemy, dist = NearestEnemy(bot)

		if not enemy then return nil end

		local mem = data.Memory
		local guess

		if hg_bot_mission_know:GetBool() then
			local err = hg_bot_mission_error:GetFloat() * math.Clamp(dist / 2500, 0.15, 1)

			guess = enemy:GetPos() + Vector(math.Rand(-err, err), math.Rand(-err, err), 0)
		else
			guess = mem.TargetSeenPos or mem.SuspicionPos
		end

		if not guess then return nil end

		local dest = Snap(guess)

		if not dest then return nil end

		local pos = bot:GetPos()
		local careful = role == "hunter" or p.caution > 0.65

		if careful then
			-- Advance by stages: stop short, hold and watch, then go on.
			local back = pos - guess

			back.z = 0

			if back:LengthSqr() < 1 then back = Vector(1, 0, 0) end

			back:Normalize()

			local standoff = math.max(350, dist - 500)
			local stop = Snap(guess + back * standoff) or dest

			return GoTo(stop, false, guess, math.Rand(8, 16) * (0.6 + p.caution * 0.8))
		end

		return GoTo(dest, dist > 900, nil, 0)
	end

	local function PlanDefend(bot, data, anchor, objective)
		local spot

		for _ = 1, 4 do
			local off = Vector(math.Rand(-250, 250), math.Rand(-250, 250), 0)

			spot = Snap(anchor + off, 200)

			if spot then break end
		end

		spot = spot or Snap(anchor)

		if not spot then return nil end

		-- Watch where the enemy would come from, else out of the doorway.
		local enemy = NearestEnemy(bot)
		local watch = (objective and objective.watch)
			or (enemy and enemy:GetPos())
			or (spot + Angle(0, math.Rand(0, 360), 0):Forward() * 500)

		return GoTo(spot, false, watch, math.Rand(20, 40))
	end

	local function PlanHide(bot, data)
		local best, bestScore

		local others = {}

		for _, ply in ipairs(player.GetAll()) do
			if ply ~= bot and ply:Alive() then others[#others + 1] = ply:GetPos() end
		end

		for _ = 1, 6 do
			local cand = hg.bots.GetRandomWanderPoint and hg.bots.GetRandomWanderPoint(bot)

			if cand then
				local nearest = math.huge

				for _, op in ipairs(others) do nearest = math.min(nearest, cand:DistToSqr(op)) end

				if not bestScore or nearest > bestScore then best, bestScore = cand, nearest end
			end
		end

		if not best then return nil end

		return GoTo(best, false, nil, math.Rand(25, 50))
	end

	local function PlanSupport(bot)
		local friend, dist = NearestFriend(bot)

		if not friend or dist < 350 then return nil end

		local dest = Snap(friend:GetPos())

		if not dest then return nil end

		return GoTo(dest, dist > 900, nil, 0)
	end

	local function Plan(bot, data)
		local role = hg.bots.GetRole(bot)

		if not role then return nil end

		local p = hg.bots.GetPersonality and hg.bots.GetPersonality(bot) or { caution = 0.5, aggression = 0.5, nerve = 0.5 }
		local objective = hg.bots.ModeObjective and hg.bots.ModeObjective(bot, role)
		local now = CurTime()
		local plan

		-- Not while the mode says nobody fights (preparation, round over).
		if hg.bots.ModeCanFight and hg.bots.ModeCanFight() == false and role ~= "survivor" then return nil end

		if objective and objective.pos and (objective.kind == "go" or (not objective.kind and (role == "attacker" or role == "hunter"))) then
			local dest = Snap(objective.pos)

			plan = dest and GoTo(dest, true, objective.watch, 0)
		elseif role == "attacker" or role == "hunter" then
			plan = PlanHunt(bot, data, role, p)
		elseif role == "defender" then
			local anchor = (objective and objective.pos) or data.HomePos or bot:GetPos()

			plan = PlanDefend(bot, data, anchor, objective)
		elseif role == "survivor" then
			plan = PlanHide(bot, data)
		elseif role == "support" then
			plan = PlanSupport(bot)
		end

		if plan then
			plan.role = role
			plan.rethink = now + hg_bot_mission_rethink:GetFloat()
			plan.goalSet = false
		end

		return plan
	end
--//

--\\ Doing it
	local function Run(bot, data)
		if not hg_bot_mission:GetBool() then return false end

		local now = CurTime()

		if now < (data.MissionBackoff or 0) then return false end

		local st = data.MissionPlan

		if not st or now >= st.rethink then
			st = Plan(bot, data)
			data.MissionPlan = st

			if not st then
				data.MissionBackoff = now + math.Rand(3, 6)

				return false
			end
		end

		if not st.goalSet then
			if not hg.bots.SetGoal(bot, st.pos) then
				data.MissionPlan = nil
				data.MissionBackoff = now + 3

				return false
			end

			st.goalSet = true
		end

		data.Running = st.run and true or false
		data.LookPos = nil

		if hg.bots.FollowPath(bot, data) then
			-- Arrived.
			data.MissionPlan = nil

			if (st.hold or 0) > 0 and hg.bots.HoldPosition then
				hg.bots.HoldPosition(bot, st.pos, st.watch)
				data.HoldDuration = st.hold

				return true
			end

			data.MissionBackoff = now + 1

			return false
		end

		-- Eyes on the likely threat while the last stretch is walked.
		if st.watch and bot:GetPos():DistToSqr(st.pos) < 500 * 500 then
			data.LookPos = st.watch + Vector(0, 0, 45)
		end

		return true
	end

	local function Install()
		local orig = hg.bots._LootReactionOrig

		if not orig then
			if not hg.bots.CheckLootReaction then return false end

			orig = hg.bots.CheckLootReaction
			hg.bots._LootReactionOrig = orig
		end

		-- Loot first, then the mission, then random wandering.
		hg.bots.CheckLootReaction = function(bot, data)
			if orig(bot, data) then return true end

			return Run(bot, data)
		end

		return true
	end

	timer.Simple(0, function()
		if not Install() then hook.Add("InitPostEntity", "HG_Bots_MissionInstall", Install) end
	end)
--//

--\\ Experience
	hook.Add("PlayerDeath", "HG_Bots_MissionLearn", function(victim, inflictor, attacker)
		if not hg_bot_mission_learn:GetBool() then return end

		local killer = hg.bots.ResolveShooter and hg.bots.ResolveShooter(attacker) or attacker

		if IsValid(victim) and victim.IsHomigradBot and victim.hgPersonality then
			local p = victim.hgPersonality

			p.deaths = (p.deaths or 0) + 1
			p.caution = math.Clamp(p.caution + 0.06, 0, 1)
			p.aggression = math.Clamp(p.aggression - 0.04, 0, 1)
		end

		if IsValid(killer) and killer ~= victim and killer.IsHomigradBot and killer.hgPersonality then
			local p = killer.hgPersonality

			p.kills = (p.kills or 0) + 1
			p.aggression = math.Clamp(p.aggression + 0.05, 0, 1)
			p.nerve = math.Clamp(p.nerve + 0.03, 0, 1)
		end
	end)
--//

concommand.Add("hg_bot_mission_report", function(ply)
	if IsValid(ply) and not ply:IsAdmin() then return end

	for bot in pairs(hg.bots.List) do
		local data = IsValid(bot) and bot.Bot

		if data then
			local p = bot.hgPersonality or {}
			local st = data.MissionPlan

			print(("[hg.bots] %-16s %-9s role %-9s mission %-6s state %-7s deaths %d kills %d  aggr %.2f caut %.2f"):format(
				bot:Nick(), tostring(p.id), tostring(hg.bots.GetRole(bot)),
				st and st.kind or "-", tostring(data.State), p.deaths or 0, p.kills or 0,
				p.aggression or 0, p.caution or 0))
		end
	end
end, nil, "Print every bot's role, mission and what it has learned")

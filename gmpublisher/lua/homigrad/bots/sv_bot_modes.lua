--[[
	Tarkov AI - Game mode rules

	Until now nothing in the AI knew a round or a game mode existed: who is
	an enemy came from factions and trust mode only, so bots ignored teams,
	roles and the round state. This file is the one place that asks the mode.

	A mode is described by an ADAPTER, a plain table in hg.bots.ModeAdapters
	(order independent: any file may do hg.bots.ModeAdapters.myid = {...}):

		priority   number, the highest matching adapter wins (default 0)
		Detect()   true while this mode is the running one
		CanFight() false = no shooting right now (preparation, round over)
		Hostile(ply, bot)  true = enemy, false = on the same side, nil = no opinion
		SameSide(a, b)     for two bots (and for who warns whom); nil = no opinion
		Role(bot)  "attacker" | "hunter" | "defender" | "survivor" | "support" | nil
		Objective(bot, role)  { pos = Vector, kind = "go" | "hold", watch = Vector } or nil

	Anything an adapter leaves out falls through to the generic rule below:
	if the alive players are split into two or more TEAMS, different team =
	enemy, same team = never attack (hg_bot_mode_teams 0 turns that off).

	It plugs into the existing code without editing it:
	- humans: judgement asks hook "HG_BotModeHostile" (sv_bot_judgement.lua);
	- bot vs bot: hg.bots.SameFaction / FactionHostile are wrapped, so teams
	  decide who fights whom and who shares contacts (squad, warnings).

	Use hg_bot_mode_dump to print what the running mode exposes (round
	name, teams, role-looking fields on players): that is what an adapter
	for a specific mode is written from.
]]

hg.bots = hg.bots or {}
hg.bots.List = hg.bots.List or {}
hg.bots.ModeAdapters = hg.bots.ModeAdapters or {}

local hg_bot_mode_teams = CreateConVar("hg_bot_mode_teams", "1", {FCVAR_ARCHIVE}, "Generic rule: when players are split into teams, other teams are enemies and one's own team is never attacked", 0, 1)

local TEAM_UNASSIGNED_, TEAM_SPECTATOR_ = 1001, 1002

--\\ Round info
	--- Name of the running round / mode as Z-City reports it, or nil.
	function hg.bots.CurrentRoundName()
		local round

		if isfunction(CurrentRound) then
			local ok, r = pcall(CurrentRound)

			if ok then round = r end
		end

		if istable(round) then
			return round.name or round.PrintName or round.Name, round
		end

		if istable(zb) and isstring(zb.CROUND) then return zb.CROUND, nil end

		return nil, nil
	end
--//

--\\ Generic team rule
	local teamCache, teamCacheAt = false, 0

	local function TeamsActive()
		if not hg_bot_mode_teams:GetBool() then return false end

		local now = CurTime()

		if now - teamCacheAt < 1 then return teamCache end

		teamCacheAt = now

		local seen, count = {}, 0

		for _, ply in ipairs(player.GetAll()) do
			if ply:Alive() then
				local t = ply:Team()

				if t ~= TEAM_UNASSIGNED_ and t ~= TEAM_SPECTATOR_ and not seen[t] then
					seen[t] = true
					count = count + 1
				end
			end
		end

		teamCache = count >= 2

		return teamCache
	end

	hg.bots.ModeAdapters._generic = hg.bots.ModeAdapters._generic or {
		priority = -100,
		Detect = function() return true end,
		Hostile = function(ply, bot)
			if not TeamsActive() then return nil end

			return ply:Team() ~= bot:Team()
		end,
		SameSide = function(a, b)
			if not TeamsActive() then return nil end

			return a:Team() == b:Team()
		end,
	}
--//

--\\ Asking the running mode
	local current, currentAt = nil, 0

	--- The adapter of the running mode (cached for a second).
	function hg.bots.CurrentMode()
		local now = CurTime()

		if current and now - currentAt < 1 then return current end

		currentAt = now

		local best, bestPriority

		for id, ad in pairs(hg.bots.ModeAdapters) do
			local ok, match = pcall(ad.Detect or function() return false end)

			if ok and match and (not bestPriority or (ad.priority or 0) > bestPriority) then
				best, bestPriority = ad, ad.priority or 0
			end
		end

		current = best

		return current
	end

	-- Adapters in priority order, so a specific one can say "no opinion"
	-- and the generic rule still answers.
	local function Ordered()
		local list = {}

		for _, ad in pairs(hg.bots.ModeAdapters) do list[#list + 1] = ad end

		table.sort(list, function(a, b) return (a.priority or 0) > (b.priority or 0) end)

		return list
	end

	local function Ask(method, ...)
		for _, ad in ipairs(Ordered()) do
			if ad[method] then
				local ok, detected = pcall(ad.Detect or function() return false end)

				if ok and detected then
					local ok2, answer = pcall(ad[method], ...)

					if ok2 and answer ~= nil then return answer end
				end
			end
		end

		return nil
	end

	function hg.bots.ModeCanFight() return Ask("CanFight") end

	--- true = enemy, false = friend (or nobody may shoot right now), nil = no opinion.
	function hg.bots.ModeHostile(ply, bot)
		if Ask("CanFight") == false then return false end

		return Ask("Hostile", ply, bot)
	end

	function hg.bots.ModeSameSide(a, b) return Ask("SameSide", a, b) end

	function hg.bots.ModeRole(bot) return Ask("Role", bot) end

	function hg.bots.ModeObjective(bot, role) return Ask("Objective", bot, role) end

	hook.Add("HG_BotModeHostile", "HG_Bots_ModeRules", function(ply, bot)
		return hg.bots.ModeHostile(ply, bot)
	end)
--//

--\\ Bot against bot: teams decide
	local function Install()
		local origSame = hg.bots._SameFactionOrig
		local origHostile = hg.bots._FactionHostileOrig

		if not origSame then
			if not (hg.bots.SameFaction and hg.bots.FactionHostile) then return false end

			origSame, origHostile = hg.bots.SameFaction, hg.bots.FactionHostile
			hg.bots._SameFactionOrig, hg.bots._FactionHostileOrig = origSame, origHostile
		end

		hg.bots.SameFaction = function(a, b)
			if IsValid(a) and IsValid(b) and a.IsHomigradBot and b.IsHomigradBot then
				local v = hg.bots.ModeSameSide(a, b)

				if v ~= nil then return v end
			end

			return origSame(a, b)
		end

		hg.bots.FactionHostile = function(ent, bot)
			if IsValid(ent) and IsValid(bot) and ent ~= bot and ent.IsHomigradBot and bot.IsHomigradBot then
				local v = hg.bots.ModeSameSide(ent, bot)

				if v ~= nil then return not v end
			end

			return origHostile(ent, bot)
		end

		return true
	end

	timer.Simple(0, function()
		if not Install() then hook.Add("InitPostEntity", "HG_Bots_ModesInstall", Install) end
	end)
--//

--\\ What does the running mode expose?
	concommand.Add("hg_bot_mode_dump", function(ply)
		if IsValid(ply) and not ply:IsAdmin() then return end

		local function out(s)
			print(s)

			if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, s) end
		end

		local function simple(t, indent)
			local lines, fns = {}, {}

			for k, v in pairs(t) do
				local ty = type(v)

				if ty == "string" or ty == "number" or ty == "boolean" then
					lines[#lines + 1] = ("%s%s = %s"):format(indent, tostring(k), tostring(v))
				elseif ty == "function" then
					fns[#fns + 1] = tostring(k)
				end
			end

			table.sort(lines)
			table.sort(fns)

			for _, l in ipairs(lines) do out(l) end

			if #fns > 0 then out(indent .. "functions: " .. table.concat(fns, ", ")) end
		end

		local name, round = hg.bots.CurrentRoundName()
		local ad = hg.bots.CurrentMode()

		out("[hg.bots] --- mode dump ---")
		out(("round name: %s   adapter in use: %s   can fight: %s   teams active: %s"):format(
			tostring(name), ad == hg.bots.ModeAdapters._generic and "generic" or "custom",
			tostring(hg.bots.ModeCanFight()), tostring(TeamsActive())))

		if round then
			out("CurrentRound() fields:")
			simple(round, "  ")
		end

		if istable(zb) then
			out("zb fields:")
			simple(zb, "  ")
		end

		out("players:")

		local WORDS = { "role", "team", "side", "class", "murder", "mode", "faction", "rank" }

		for _, p in ipairs(player.GetAll()) do
			out(("  %s  bot=%s  alive=%s  Team()=%d"):format(p:Nick(), tostring(p:IsBot()), tostring(p:Alive()), p:Team()))

			local tbl = p:GetTable()
			local found = {}

			for k, v in pairs(tbl) do
				local ty = type(v)

				if ty == "string" or ty == "number" or ty == "boolean" then
					local lk = string.lower(tostring(k))

					for _, w in ipairs(WORDS) do
						if string.find(lk, w, 1, true) then
							found[#found + 1] = ("%s = %s"):format(tostring(k), tostring(v))

							break
						end
					end
				end
			end

			table.sort(found)

			if #found > 0 then out("      " .. table.concat(found, ", ")) end
		end
	end, nil, "Print what the running game mode exposes (for writing a mode adapter)")
--//

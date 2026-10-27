--[[
	Tarkov AI - Judgement ("don't shoot without a reason")

	A bot decides, per player, whether it may open fire. It does when ANY of
	these is true:

	- THIS bot was attacked by the player (hit, or a bullet passed close
	  enough to count as being shot at - perception's ReportThreat, which
	  gives the bot a personal grudge). Missing is not a free pass: the
	  bot reacts and fights back;
	- the bot has been TOLD (or saw it itself) that the player is a traitor
	  who attacked a bot. Word does not travel by magic: a bot that gets
	  attacked tells the friendly bots near it a second or two later, and
	  only if it is still alive to say it. Bots that saw the attack know at
	  once. A bot nobody told leaves the player alone (hg_bot_judge_tell 0
	  turns the word-of-mouth off: only the ones that saw or were hit know);
	- the player held a gun on the bot for hg_bot_judge_aim seconds (10 by
	  default: until then it only watches, weapon ready, and warns once);
	- a game mode says so: hook "HG_BotModeHostile" (true = enemy,
	  false = never);
	- the player stood armed inside hg_bot_judge_intrude for
	  hg_bot_judge_patience seconds (0 = off, the default);
	- a small share of bots are simply trigger-happy (bloodlust, see
	  sv_bot_personality.lua), hg_bot_judge_psycho scales how many.

	Speech (sv_bot_speech.lua) can calm a bot down (hg.bots.Truce) or push it
	over the edge (hg.bots.Provoke). A truce never overrides a grudge.

	Wraps hg.bots.IsHostile and hg.bots.MarkHostile (once each; originals
	kept in hg.bots._IsHostileOrig / _MarkHostileOrig). Only human players
	are judged: NPCs, other bots and factions behave as before. The shared
	"hostile to every bot" list of trust mode is deliberately ignored here:
	that list is exactly the telepathy this file removes.
]]

hg.bots = hg.bots or {}
hg.bots.List = hg.bots.List or {}

local hg_bot_judgement      = CreateConVar("hg_bot_judgement",      "1",    {FCVAR_ARCHIVE}, "Bots only attack players who give a reason instead of everybody on sight", 0, 1)
local hg_bot_judge_aim      = CreateConVar("hg_bot_judge_aim",      "10",   {FCVAR_ARCHIVE}, "Seconds a player must hold a gun on a bot before it starts shooting", 0.1, 10)
local hg_bot_judge_intrude  = CreateConVar("hg_bot_judge_intrude",  "300",  {FCVAR_ARCHIVE}, "An armed player closer than this for long enough counts as a threat (see patience)", 50, 3000)
local hg_bot_judge_patience = CreateConVar("hg_bot_judge_patience", "0",    {FCVAR_ARCHIVE}, "Seconds an armed stranger may stay inside that distance (0 = never a reason by itself)", 0, 300)
local hg_bot_judge_hold     = CreateConVar("hg_bot_judge_hold",     "30",   {FCVAR_ARCHIVE}, "Seconds a bot stays hostile after a threat decision before it re-evaluates", 2, 300)
local hg_bot_judge_psycho   = CreateConVar("hg_bot_judge_psycho",   "0.15", {FCVAR_ARCHIVE}, "Share of trigger-happy bots (scaled by each bot's bloodlust, 0 = nobody shoots unprovoked)", 0, 1)
local hg_bot_judge_tell     = CreateConVar("hg_bot_judge_tell",     "1",    {FCVAR_ARCHIVE}, "A bot that was attacked warns the friendly bots near it (only if still alive to do it)", 0, 1)
local hg_bot_judge_radius   = CreateConVar("hg_bot_judge_radius",   "1500", {FCVAR_ARCHIVE}, "How far a warning carries", 100, 8000)
local hg_bot_judge_memory   = CreateConVar("hg_bot_judge_memory",   "600",  {FCVAR_ARCHIVE}, "Seconds a bot remembers it was told about a traitor", 10, 36000)
local hg_bot_judge_autoconf = CreateConVar("hg_bot_judge_autoconfig", "1",  {FCVAR_ARCHIVE}, "Keep perception's own aim/shooter rules (hg_bot_aim_threat_time, hg_bot_shooter_window) in line with this file", 0, 1)

local function Armed(ply)
	local wep = ply:GetActiveWeapon()

	return IsValid(wep) and (wep.ishgweapon or wep.ismelee2) and true or false
end

local function Say(bot, category)
	if hg.bots.Say then pcall(hg.bots.Say, bot, category) end
end

--\\ Per bot + player record
	local function Rec(bot, ply)
		local data = bot.Bot

		data.Judge = data.Judge or {}

		local rec = data.Judge[ply]

		if not rec then
			local p = hg.bots.GetPersonality and hg.bots.GetPersonality(bot)
			local bloodlust = p and p.bloodlust or 1

			rec = {
				at = 0, aim = 0, near = 0, holdUntil = 0, truceUntil = 0, hostile = false,
				-- Decided once per pair, so a bot doesn't flip its mind every scan.
				nature = math.random() < (bloodlust ^ 2) * hg_bot_judge_psycho:GetFloat(),
			}

			data.Judge[ply] = rec
		end

		return rec
	end

	--- Calm this bot down about this player for a while (speech: "don't
	-- shoot"). Never overrides a grudge or being told about a traitor.
	function hg.bots.Truce(bot, ply, seconds)
		if not IsValid(bot) or not bot.Bot or not IsValid(ply) then return end

		local rec = Rec(bot, ply)

		rec.truceUntil = CurTime() + (seconds or 30)
		rec.aim, rec.near, rec.holdUntil, rec.warned = 0, 0, 0, nil
	end

	--- Push this bot over the edge: it opens fire on this player.
	function hg.bots.Provoke(bot, ply, seconds)
		if not IsValid(bot) or not bot.Bot or not IsValid(ply) then return end

		local rec = Rec(bot, ply)

		rec.truceUntil = 0
		rec.holdUntil = CurTime() + (seconds or hg_bot_judge_hold:GetFloat())
	end
--//

--\\ Word of mouth
	local Tell

	local function Inform(other, ply)
		local mem = other.Bot.Memory

		mem.Informed = mem.Informed or {}

		local now = CurTime()

		if (mem.Informed[ply] or 0) > now then return end

		mem.Informed[ply] = now + hg_bot_judge_memory:GetFloat()

		-- Go and look at where it happened.
		if hg.bots.Alert then hg.bots.Alert(other, ply:GetPos(), "report") end

		Say(other, "roger")

		-- And pass it on.
		Tell(other, ply)
	end

	local function CanTell(a, b)
		return IsValid(b) and b ~= a and b:Alive() and b.Bot and b.Bot.Enabled and hg.bots.IsFriendly and hg.bots.IsFriendly(a, b)
	end

	--- source is hostile to ply (it was attacked, or it was told): tell the
	-- friends who can see ply right now at once, the rest a moment later.
	Tell = function(source, ply)
		if not hg_bot_judge_tell:GetBool() then return end

		local data = IsValid(source) and source.Bot

		if not data or not IsValid(ply) then return end

		local mem = data.Memory

		mem.Told = mem.Told or {}

		local now = CurTime()

		if (mem.Told[ply] or 0) > now - 30 then return end

		mem.Told[ply] = now

		-- Seen with their own eyes.
		for other in pairs(hg.bots.List) do
			if CanTell(source, other) and hg.bots.CanSee and hg.bots.CanSee(other, ply) then Inform(other, ply) end
		end

		-- Said over the radio: only if the speaker is alive to say it.
		timer.Simple(math.Rand(1.5, 3), function()
			if not IsValid(source) or not source:Alive() or not IsValid(ply) then return end

			local r2 = hg_bot_judge_radius:GetFloat() ^ 2
			local pos = source:GetPos()

			for other in pairs(hg.bots.List) do
				if CanTell(source, other) and pos:DistToSqr(other:GetPos()) < r2 then Inform(other, ply) end
			end
		end)
	end

	--- A bot dying to a player is seen by whoever has eyes on the killer.
	hook.Add("PlayerDeath", "HG_Bots_JudgeKill", function(victim, inflictor, attacker)
		if not hg_bot_judgement:GetBool() then return end
		if not IsValid(victim) or not victim.IsHomigradBot then return end

		local killer = hg.bots.ResolveShooter and hg.bots.ResolveShooter(attacker) or attacker

		if not IsValid(killer) or not killer:IsPlayer() or killer.IsHomigradBot then return end

		for other in pairs(hg.bots.List) do
			if CanTell(victim, other) and hg.bots.CanSee and hg.bots.CanSee(other, killer) then
				Inform(other, killer)
			end
		end
	end)
--//

--\\ The decision
	local function Judge(ply, bot)
		local data = bot.Bot
		local mem = data.Memory
		local now = CurTime()
		local rec = Rec(bot, ply)

		-- Called for every scan of every bot: answer from the cache.
		if now - rec.at < 0.25 then return rec.hostile end

		local dt = rec.at == 0 and 0.25 or math.min(now - rec.at, 1)

		rec.at = now

		local verdict
		local aimNeeded = hg_bot_judge_aim:GetFloat()

		-- A game mode with an opinion outranks everything.
		local mode = hook.Run("HG_BotModeHostile", ply, bot)

		if mode ~= nil then
			verdict = mode and true or false
		elseif mem.Grudge and mem.Grudge[ply] then
			verdict = true -- it was attacked (hit or shot at), never forgotten
		elseif mem.Informed and (mem.Informed[ply] or 0) > now then
			verdict = true -- somebody told it
		elseif now < rec.truceUntil then
			verdict = false
		elseif now < rec.holdUntil or rec.nature then
			verdict = true
		elseif ply:Alive() and Armed(ply) then
			local to = bot:WorldSpaceCenter() - ply:EyePos()
			local dist = to:Length()

			-- Gun held on the bot.
			if dist > 1 and dist < 1800 and ply:GetAimVector():Dot(to / dist) > 0.93 then
				rec.aim = rec.aim + dt

				-- Halfway there: one warning, weapon ready (perception's wary state does the rest).
				if not rec.warned and rec.aim >= aimNeeded * 0.4 then
					rec.warned = true
					Say(bot, "attention")
				end
			else
				rec.aim = math.max(rec.aim - dt * 2, 0)

				if rec.aim <= 0 then rec.warned = nil end
			end

			local patience = hg_bot_judge_patience:GetFloat()

			if patience > 0 then
				local p = hg.bots.GetPersonality and hg.bots.GetPersonality(bot)

				patience = patience * (1 - (p and p.bloodlust or 0.5) * 0.6)

				if dist < hg_bot_judge_intrude:GetFloat() then
					rec.near = rec.near + dt
				else
					rec.near = math.max(rec.near - dt * 2, 0)
				end
			else
				rec.near = 0
			end

			if rec.aim >= aimNeeded or (patience > 0 and rec.near >= patience) then
				rec.holdUntil = now + hg_bot_judge_hold:GetFloat()
				verdict = true
			end
		else
			rec.aim = 0
			rec.warned = nil
			rec.near = math.max(rec.near - dt * 2, 0)
		end

		verdict = verdict and true or false

		-- Calmed down: stop hunting somebody the bot no longer has a reason for.
		if rec.hostile and not verdict and mem.Target == ply then
			mem.Target = nil
			mem.TargetPos = nil
			mem.TargetSeenPos = nil
			mem.TargetVel = nil
			mem.ContactHold = nil
		end

		rec.hostile = verdict

		return verdict
	end
--//

--\\ Installing
	local function Install()
		local origHostile = hg.bots._IsHostileOrig
		local origMark = hg.bots._MarkHostileOrig

		if not origHostile then
			if not (hg.bots.IsHostile and hg.bots.MarkHostile) then return false end

			origHostile, origMark = hg.bots.IsHostile, hg.bots.MarkHostile
			hg.bots._IsHostileOrig, hg.bots._MarkHostileOrig = origHostile, origMark
		end

		hg.bots.IsHostile = function(ply, bot)
			local verdict = origHostile(ply, bot)

			if not verdict then return false end
			if not hg_bot_judgement:GetBool() then return true end

			-- Only humans are judged; NPCs, bots and factions keep their rules.
			if not IsValid(ply) or not ply:IsPlayer() or ply.IsHomigradBot then return verdict end
			if not IsValid(bot) or not bot.Bot or not bot.Bot.Memory then return verdict end

			return Judge(ply, bot)
		end

		-- Whoever is marked hostile personally (hit, shot at, saw it) warns the others.
		hg.bots.MarkHostile = function(ply, bot, mult)
			origMark(ply, bot, mult)

			if hg_bot_judgement:GetBool() and IsValid(bot) and bot.Bot and IsValid(ply) and ply:IsPlayer() and not ply.IsHomigradBot then
				Tell(bot, ply)
			end
		end

		return true
	end

	timer.Simple(0, function()
		if not Install() then hook.Add("InitPostEntity", "HG_Bots_JudgementInstall", Install) end
	end)

	--- Perception has its own aim and shooter rules that mark a player hostile
	-- (personally, by grudge) long before ours would. Line them up: aiming
	-- counts after hg_bot_judge_aim seconds, and merely firing a gun somewhere
	-- in sight is not an attack - hitting a bot or shooting past it is.
	local function Sync()
		if not hg_bot_judge_autoconf:GetBool() or not hg_bot_judgement:GetBool() then return end

		local aim = GetConVar("hg_bot_aim_threat_time")

		if aim and math.abs(aim:GetFloat() - hg_bot_judge_aim:GetFloat()) > 0.01 then
			RunConsoleCommand("hg_bot_aim_threat_time", tostring(math.min(hg_bot_judge_aim:GetFloat(), 10)))
		end

		local window = GetConVar("hg_bot_shooter_window")

		if window and window:GetFloat() > 0 then RunConsoleCommand("hg_bot_shooter_window", "0") end
	end

	timer.Simple(1, Sync)
	cvars.AddChangeCallback("hg_bot_judge_aim", function() timer.Simple(0, Sync) end, "HG_Bots_JudgeSync")
--//

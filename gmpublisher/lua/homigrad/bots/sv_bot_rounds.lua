--[[
	Tarkov AI - Rounds (die for good, come back with the next round)

	A bot that dies stays dead until the round ends. The core used to kick
	it the moment it died, which also threw its slot away; now it is
	simply kept (dead, in the server) and brought back when the NEXT round
	or mode starts. Coming back is an ordinary Z-City spawn: its team,
	equipment and rules come from the running mode, and the mode adapter
	(sv_bot_modes.lua) decides who it fights. The addon itself gives it no
	gear (sv_bot_nokit.lua).

	How a new round is noticed (any one is enough, debounced 3 s):
	- the mode name changed (CurrentRound());
	- the map was cleaned up (PostCleanupMap - what round systems do);
	- zb.ROUND_STATE became the value in hg_bot_round_state_start
	  (-1 = not used; find the value with hg_bot_mode_dump);
	- most of the humans who had died are alive again
	  (hg_bot_round_autodetect; with one human this means "you respawned");
	- somebody (an adapter, a console) calls hg.bots.RoundStart(reason) or
	  hg_bot_round_start.
	On a new round the hook "HG_BotRoundStart"(reason) runs, and every dead
	bot that Z-City did not already bring back is spawned (a few per
	second, not all at once).

	hg_bot_roundlock 0 returns to the old behaviour: dead bots are kicked.
	Wraps hg.bots.Remove (kept in hg.bots._RemoveOrig; hg.bots.RemoveForce
	is the real one) - anything that means "remove it for good", such as
	hg.bots.RemoveAll, still does.
]]

hg.bots = hg.bots or {}
hg.bots.List = hg.bots.List or {}

local hg_bot_roundlock      = CreateConVar("hg_bot_roundlock",      "1",  {FCVAR_ARCHIVE}, "A dead bot stays dead (not kicked) until the next round/mode starts, then spawns again by that mode's rules", 0, 1)
local hg_bot_round_delay    = CreateConVar("hg_bot_round_delay",    "3",  {FCVAR_ARCHIVE}, "Seconds after a round starts before dead bots are spawned (gives Z-City time to do it itself)", 0, 60)
local hg_bot_round_auto     = CreateConVar("hg_bot_round_autodetect", "1", {FCVAR_ARCHIVE}, "Treat 'most dead humans are alive again' as a new round", 0, 1)
local hg_bot_round_state    = CreateConVar("hg_bot_round_state_start", "-1", {FCVAR_ARCHIVE}, "Value of zb.ROUND_STATE that means a round has just started (-1 = don't use)", -1, 100)
local hg_bot_round_debug    = CreateConVar("hg_bot_round_debug",    "0",  {FCVAR_ARCHIVE}, "Print round starts and respawns", 0, 1)

local lastStart = -100
local deadHumans = {}

local function Log(fmt, ...)
	if hg_bot_round_debug:GetBool() then print("[hg.bots] " .. fmt:format(...)) end
end

--\\ Bringing them back
	local function Revive(bot)
		if not IsValid(bot) or bot:Alive() then return end

		Log("spawning %s for the new round", bot:Nick())

		bot:Spawn() -- PlayerSpawn: Z-City's own spawn logic, then the core's AutoInit
	end

	--- A new round has begun.
	function hg.bots.RoundStart(reason)
		local now = CurTime()

		if now - lastStart < 3 then return end

		lastStart = now
		deadHumans = {}

		Log("round start (%s)", tostring(reason))

		hook.Run("HG_BotRoundStart", reason)

		timer.Simple(hg_bot_round_delay:GetFloat(), function()
			local i = 0

			for bot in pairs(hg.bots.List) do
				if IsValid(bot) and bot:IsBot() and not bot:Alive() then
					i = i + 1

					timer.Simple(i * 0.15, function() Revive(bot) end)
				end
			end
		end)
	end
--//

--\\ Keeping the dead
	local function Install()
		local orig = hg.bots._RemoveOrig

		if not orig then
			if not hg.bots.Remove then return false end

			orig = hg.bots.Remove
			hg.bots._RemoveOrig = orig
		end

		hg.bots.RemoveForce = orig

		-- The core's think loop calls this for every dead bot, every tick.
		hg.bots.Remove = function(bot)
			if hg_bot_roundlock:GetBool() and IsValid(bot) and bot:IsBot() and bot.IsHomigradBot and not bot:Alive() then return end

			return orig(bot)
		end

		-- "Remove all" means all, dead ones too.
		hg.bots.RemoveAll = function()
			for bot in pairs(hg.bots.List) do orig(bot) end
		end

		return true
	end

	timer.Simple(0, function()
		if not Install() then hook.Add("InitPostEntity", "HG_Bots_RoundsInstall", Install) end
	end)
--//

--\\ Noticing a new round
	local lastName, lastState

	timer.Create("HG_Bots_RoundWatch", 1, 0, function()
		local name = hg.bots.CurrentRoundName and hg.bots.CurrentRoundName()

		if lastName ~= nil and name ~= lastName then hg.bots.RoundStart("mode changed to " .. tostring(name)) end

		lastName = name

		if istable(zb) and zb.ROUND_STATE ~= nil then
			local want = hg_bot_round_state:GetInt()

			if lastState ~= nil and zb.ROUND_STATE ~= lastState and want >= 0 and zb.ROUND_STATE == want then
				hg.bots.RoundStart("round state " .. tostring(want))
			end

			lastState = zb.ROUND_STATE
		end
	end)

	hook.Add("PostCleanupMap", "HG_Bots_RoundCleanup", function() hg.bots.RoundStart("map cleanup") end)

	-- Humans: remember who died, notice when most of them are back.
	hook.Add("PlayerDeath", "HG_Bots_RoundHumanDeath", function(victim)
		if IsValid(victim) and not victim:IsBot() then deadHumans[victim] = true end
	end)

	hook.Add("PlayerSpawn", "HG_Bots_RoundHumanSpawn", function(ply)
		if not hg_bot_round_auto:GetBool() or not IsValid(ply) or ply:IsBot() then return end
		if not deadHumans[ply] then return end

		deadHumans[ply] = nil

		-- Count the ones still dead among those who died; 60% back = a new round.
		local dead, total = 0, 0

		for p in pairs(deadHumans) do
			if IsValid(p) and not p:Alive() then dead = dead + 1 end
		end

		for _, p in ipairs(player.GetHumans()) do total = total + 1 end

		if total > 0 and dead <= total * 0.4 and CurTime() - lastStart > 15 then
			hg.bots.RoundStart("humans respawned")
		end
	end)

	hook.Add("PlayerDisconnected", "HG_Bots_RoundCleanupHuman", function(ply) deadHumans[ply] = nil end)
--//

concommand.Add("hg_bot_round_start", function(ply)
	if IsValid(ply) and not ply:IsAdmin() then return end

	lastStart = -100
	hg.bots.RoundStart("console")
end, nil, "Tell the bots a new round has started: dead bots spawn again")

concommand.Add("hg_bot_round_status", function(ply)
	local alive, dead = 0, 0

	for bot in pairs(hg.bots.List) do
		if IsValid(bot) then
			if bot:Alive() then alive = alive + 1 else dead = dead + 1 end
		end
	end

	print(("[hg.bots] rounds: lock %s, bots alive %d, dead and waiting %d, mode %s, last round start %.0fs ago"):format(
		hg_bot_roundlock:GetBool() and "on" or "off", alive, dead,
		tostring(hg.bots.CurrentRoundName and hg.bots.CurrentRoundName()), CurTime() - lastStart))
end, nil, "How many bots are alive and how many wait for the next round")

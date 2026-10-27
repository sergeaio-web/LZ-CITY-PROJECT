--[[
	Tarkov AI - Fill the server

	Keeps the number of bots equal to the number of free player slots:

	    bots wanted = maxplayers - reserve - humans - bots that aren't ours

	A bot is a real fake client and takes a real slot, so "as many bots as
	the server has places" has one catch: a full server turns humans away.
	Two things deal with it:
	- hg_bot_fill_reserve slots are always kept free (default 1), so the
	  next human can connect;
	- when a human joins, the surplus bot is removed at once, and when a
	  human leaves, a new one is spawned.

	Bots are spawned one at a time, out of every player's sight, with the
	director's kit roll when the director file is loaded. They count
	toward the total together with director bots, so the two don't add up
	past the slot count (the director simply finds no free slot).

	On by default: hg_bot_fill 0 turns it off. With many bots the server
	pays for every one of them - if it gets heavy, raise hg_bot_think_rate
	and lower hg_bot_astar_max_nodes / hg_bot_path_budget, or cap this with
	hg_bot_fill_max.
]]

hg.bots = hg.bots or {}
hg.bots.List = hg.bots.List or {}

local hg_bot_fill          = CreateConVar("hg_bot_fill",          "1",   {FCVAR_ARCHIVE}, "Keep the server full of bots: one per free player slot", 0, 1)
local hg_bot_fill_reserve  = CreateConVar("hg_bot_fill_reserve",  "1",   {FCVAR_ARCHIVE}, "Player slots always kept free so humans can still join", 0, 16)
local hg_bot_fill_max      = CreateConVar("hg_bot_fill_max",      "0",   {FCVAR_ARCHIVE}, "Hard cap on bots from filling (0 = as many as there are free slots)", 0, 128)
local hg_bot_fill_rate     = CreateConVar("hg_bot_fill_rate",     "1.5", {FCVAR_ARCHIVE}, "Seconds between spawning two filler bots", 0.2, 30)
local hg_bot_fill_min_dist = CreateConVar("hg_bot_fill_min_dist", "800", {FCVAR_ARCHIVE}, "Closest a filler bot may spawn to a human", 100, 6000)
local hg_bot_fill_replace  = CreateConVar("hg_bot_fill_replace",  "0",   {FCVAR_ARCHIVE}, "Spawn a replacement when a bot dies (0 = dead bots stay dead; the server is only topped up on map start / hg_bot_fill_reset / when slots free up)", 0, 1)
local hg_bot_fill_kit      = CreateConVar("hg_bot_fill_kit",      "0",   {FCVAR_ARCHIVE}, "Give filler bots a random kit (weapons, armour). Off: they spawn with whatever Z-City itself gives them", 0, 1)

local failedUntil = 0
local areaCache, areaCacheAt = nil, 0
local lost = 0 -- bots that died since the last top-up reset

--\\ How many
	local function CountBots()
		local n = 0

		for bot in pairs(hg.bots.List) do
			if IsValid(bot) then n = n + 1 end
		end

		return n
	end

	--- Bots we want alive right now.
	function hg.bots.FillWanted()
		local humans = #player.GetHumans()
		local foreign = math.max(#player.GetBots() - CountBots(), 0) -- fake clients that aren't ours
		local want = game.MaxPlayers() - hg_bot_fill_reserve:GetInt() - humans - foreign

		want = math.max(want, 0)

		local cap = hg_bot_fill_max:GetInt()

		if cap > 0 then want = math.min(want, cap) end

		if not hg_bot_fill_replace:GetBool() then want = math.max(want - lost, 0) end

		return want
	end
--//

--\\ Where
	local function SeenByAnyone(spot, humans)
		for _, ply in ipairs(humans) do
			local tr = util.TraceLine({
				start = ply:EyePos(),
				endpos = spot + Vector(0, 0, 40),
				mask = MASK_VISIBLE,
				filter = ply,
			})

			if not tr.Hit then return true end
		end

		return false
	end

	local function Usable(spot, humans, minDist)
		local minSqr = minDist * minDist

		for _, ply in ipairs(humans) do
			if ply:GetPos():DistToSqr(spot) < minSqr then return false end
		end

		if SeenByAnyone(spot, humans) then return false end

		local hull = util.TraceHull({
			start = spot + Vector(0, 0, 8),
			endpos = spot + Vector(0, 0, 8),
			mins = Vector(-16, -16, 0),
			maxs = Vector(16, 16, 72),
			mask = MASK_PLAYERSOLID,
		})

		return not hull.Hit
	end

	local function FindSpot()
		local humans = {}

		for _, ply in ipairs(player.GetHumans()) do
			if ply:Alive() then humans[#humans + 1] = ply end
		end

		local minDist = hg_bot_fill_min_dist:GetFloat()

		if navmesh.IsLoaded() then
			-- The area list is big and static: refresh it now and then.
			if not areaCache or CurTime() - areaCacheAt > 60 then
				areaCache = navmesh.GetAllNavAreas()
				areaCacheAt = CurTime()
			end

			if #areaCache > 0 then
				for _ = 1, 30 do
					local area = areaCache[math.random(#areaCache)]

					if IsValid(area) and not area:IsUnderwater() then
						local spot = area:GetRandomPoint()

						if Usable(spot, humans, minDist) then return spot end
					end
				end
			end

			return nil
		end

		-- No navmesh: a ring around a random human, traced onto the floor.
		if #humans == 0 then return nil end

		local origin = humans[math.random(#humans)]:GetPos()

		for _ = 1, 40 do
			local ang = math.Rand(0, math.pi * 2)
			local dist = math.Rand(minDist, minDist * 3)
			local probe = origin + Vector(math.cos(ang) * dist, math.sin(ang) * dist, 0)
			local down = util.TraceLine({
				start = probe + Vector(0, 0, 200),
				endpos = probe - Vector(0, 0, 600),
				mask = MASK_SOLID_BRUSHONLY,
			})

			if down.Hit and not down.StartSolid and Usable(down.HitPos, humans, minDist) then return down.HitPos end
		end

		return nil
	end
--//

--\\ Spawning and removing
	hg.bots.FindHiddenSpot = FindSpot -- the respawn uses it too

	local function SpawnOne()
		local spot = FindSpot()

		if not spot then
			failedUntil = CurTime() + 3

			return false
		end

		local ang = Angle(0, math.Rand(0, 360), 0)
		local kit = hg_bot_fill_kit:GetBool() and hg.bots.DirectorKit and hg.bots.DirectorKit("buildup")
		local pos = spot + Vector(0, 0, 8)
		local bot = (kit and hg.bots.SpawnWithKit and hg.bots.SpawnWithKit(pos, ang, kit)) or hg.bots.Spawn(pos, ang)

		if not IsValid(bot) then
			failedUntil = CurTime() + 5 -- usually: no free slot / bots blocked

			return false
		end

		return true
	end

	--- Drops the bot that matters least: not fighting, farthest from humans.
	local function RemoveOne()
		local worst, worstScore

		for bot in pairs(hg.bots.List) do
			local data = IsValid(bot) and bot.Bot

			if data then
				local score = (data.State == "idle" and 1e6 or 0)
				local nearest = math.huge

				for _, ply in ipairs(player.GetHumans()) do
					nearest = math.min(nearest, ply:GetPos():DistToSqr(bot:GetPos()))
				end

				score = score + math.min(nearest, 1e6)

				if not bot:Alive() then score = 1e12 end -- a dead bot is the first to go

				if not worstScore or score > worstScore then worst, worstScore = bot, score end
			end
		end

		if IsValid(worst) then (hg.bots.RemoveForce or hg.bots.Remove)(worst) end
	end

	local function Rebalance(removeOnly)
		if not hg_bot_fill:GetBool() then return end

		local have, want = CountBots(), hg.bots.FillWanted()

		if have > want then
			RemoveOne()
		elseif have < want and not removeOnly and CurTime() >= failedUntil then
			SpawnOne()
		end
	end

	-- A human is joining: make room immediately, don't wait for the timer.
	hook.Add("PlayerInitialSpawn", "HG_Bots_FillMakeRoom", function(ply)
		if ply:IsBot() then return end

		timer.Simple(0, function()
			for _ = 1, 4 do Rebalance(true) end
		end)
	end)

	-- Can't sit on the timer's pace while the server is over its slot count.
	timer.Create("HG_Bots_Fill", hg_bot_fill_rate:GetFloat(), 0, function()
		Rebalance(false)
	end)

	cvars.AddChangeCallback("hg_bot_fill_rate", function(_, _, new)
		timer.Adjust("HG_Bots_Fill", math.max(tonumber(new) or 1.5, 0.2), 0, function() Rebalance(false) end)
	end, "HG_Bots_FillRate")
--//

-- Dead bots are not replaced (unless hg_bot_fill_replace 1): count them.
hook.Add("PlayerDeath", "HG_Bots_FillCountDead", function(victim)
	-- With the round lock on, a dead bot keeps its slot until the next round,
	-- so it is not a hole to fill. Only count it when dead bots are kicked.
	local lock = GetConVar("hg_bot_roundlock")

	if (not lock or not lock:GetBool()) and IsValid(victim) and (victim.IsHomigradBot or victim:IsBot()) then lost = lost + 1 end
end)

local function Reset() lost = 0 end

hook.Add("InitPostEntity", "HG_Bots_FillReset", Reset)
hook.Add("HG_BotRoundStart", "HG_Bots_FillRound", Reset)
hook.Add("PostCleanupMap", "HG_Bots_FillResetCleanup", Reset)

concommand.Add("hg_bot_fill_reset", function(ply)
	if IsValid(ply) and not ply:IsAdmin() then return end

	Reset()
	print("[hg.bots] fill: dead bots forgotten, the server will be topped up again")
end, nil, "Forget the bots that died and top the server up to the free-slot count again")

concommand.Add("hg_bot_fill_status", function(ply)
	local line = ("[hg.bots] fill: %s, %d bots, wants %d (slots %d/%d, humans %d, reserve %d, died so far %d)"):format(
		hg_bot_fill:GetBool() and "on" or "off", CountBots(), hg.bots.FillWanted(),
		player.GetCount(), game.MaxPlayers(), #player.GetHumans(), hg_bot_fill_reserve:GetInt(), lost)

	print(line)

	if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, line) end
end, nil, "How many bots the slot filler wants")

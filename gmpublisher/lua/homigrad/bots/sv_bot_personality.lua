--[[
	Tarkov AI - Personality

	Every bot gets a character that stays with it for its whole time on the
	server (it survives respawns: it lives on the player entity, not in
	bot.Bot, which is rebuilt on every spawn).

	Four traits, 0..1:
	- aggression: how hard it presses (push tactic, melee pressure)
	- caution:    how much it prefers holding angles / careful approaches
	- nerve:      how well it keeps its head (flees later, ignores morale hits)
	- bloodlust:  how readily it shoots somebody who has done nothing
	              (consumed by sv_bot_judgement.lua)

	Characters are archetypes with a random spread inside each, so two
	"rushers" are alike but never identical.

	Nothing here replaces an existing decision. The morale file already
	feeds the tactic roll, melee aggression and the flee roll, so those
	three functions are wrapped (once - the originals are kept in
	hg.bots._PersonalityOrig, so a Lua refresh doesn't stack wrappers):
	the character only fills in where morale has no opinion, nudges
	numbers, or vetoes a push by someone with no nerve. Squad roles still
	win over everything, because GetTactic asks the squad first.
]]

hg.bots = hg.bots or {}
hg.bots.List = hg.bots.List or {}

local hg_bot_personality = CreateConVar("hg_bot_personality", "1", {FCVAR_ARCHIVE}, "Every bot has its own character (rusher, hunter, coward...) that biases tactics, aggression and when it runs", 0, 1)

--\\ Archetypes
	local ARCHETYPES = {
		{ id = "rusher",    weight = 2, aggression = {0.75, 1.0}, caution = {0.0, 0.3}, nerve = {0.5, 0.9}, bloodlust = {0.5, 0.9}  },
		{ id = "hunter",    weight = 2, aggression = {0.4, 0.7},  caution = {0.5, 0.8}, nerve = {0.6, 0.9}, bloodlust = {0.3, 0.6}  },
		{ id = "veteran",   weight = 1, aggression = {0.5, 0.8},  caution = {0.4, 0.7}, nerve = {0.8, 1.0}, bloodlust = {0.2, 0.5}  },
		{ id = "coward",    weight = 2, aggression = {0.0, 0.3},  caution = {0.7, 1.0}, nerve = {0.0, 0.3}, bloodlust = {0.0, 0.2}  },
		{ id = "scavenger", weight = 2, aggression = {0.1, 0.4},  caution = {0.5, 0.8}, nerve = {0.2, 0.5}, bloodlust = {0.0, 0.25} },
		{ id = "hothead",   weight = 1, aggression = {0.8, 1.0},  caution = {0.0, 0.2}, nerve = {0.1, 0.4}, bloodlust = {0.8, 1.0}  },
		{ id = "peaceful",  weight = 1, aggression = {0.1, 0.4},  caution = {0.4, 0.7}, nerve = {0.3, 0.7}, bloodlust = {0.0, 0.1}  },
	}

	local BY_ID = {}

	for _, a in ipairs(ARCHETYPES) do BY_ID[a.id] = a end

	local function Spread(range)
		return math.Rand(range[1], range[2])
	end

	local function Build(arch)
		return {
			id = arch.id,
			aggression = Spread(arch.aggression),
			caution = Spread(arch.caution),
			nerve = Spread(arch.nerve),
			bloodlust = Spread(arch.bloodlust),
		}
	end

	local function Roll()
		local total = 0

		for _, a in ipairs(ARCHETYPES) do total = total + a.weight end

		local r = math.Rand(0, total)

		for _, a in ipairs(ARCHETYPES) do
			r = r - a.weight

			if r <= 0 then return a end
		end

		return ARCHETYPES[1]
	end

	--- The bot's character, created on first request.
	function hg.bots.GetPersonality(bot)
		if not IsValid(bot) or not bot.IsHomigradBot then return nil end

		if not bot.hgPersonality then
			bot.hgPersonality = Build(Roll())
			bot:SetNWString("hg_bot_character", bot.hgPersonality.id) -- for the client menu / name tags
		end

		return bot.hgPersonality
	end

	--- Force an archetype (admin tools, game modes: a boss is a veteran).
	function hg.bots.SetPersonality(bot, id)
		local arch = BY_ID[id]

		if not IsValid(bot) or not arch then return false end

		bot.hgPersonality = Build(arch)
		bot:SetNWString("hg_bot_character", id)

		return true
	end

	hg.bots.Archetypes = BY_ID
--//

--\\ Plugging into the existing decisions
	local function Install()
		local orig = hg.bots._PersonalityOrig

		if not orig then
			if not (hg.bots.MoraleTactic and hg.bots.MoraleAggression and hg.bots.MoraleFleeBias) then return false end

			orig = {
				tactic = hg.bots.MoraleTactic,
				aggression = hg.bots.MoraleAggression,
				flee = hg.bots.MoraleFleeBias,
			}

			hg.bots._PersonalityOrig = orig
		end

		--- Tactic: morale's verdict first; the character fills the gaps.
		hg.bots.MoraleTactic = function(bot, target)
			local t = orig.tactic(bot, target)

			if not hg_bot_personality:GetBool() then return t end

			local p = hg.bots.GetPersonality(bot)

			if not p then return t end

			-- No nerve: even an angry push is half-hearted.
			if t == "push" and p.nerve < 0.25 and math.random() < 0.5 then return "careful" end

			if t then return t end

			local r = math.random()

			if r < p.aggression * 0.55 * (1 - p.caution) then return "push" end

			if r > 1 - p.caution * 0.6 then return math.random() < 0.6 and "wait" or "careful" end

			return nil
		end

		hg.bots.MoraleAggression = function(bot, target)
			local mult = orig.aggression(bot, target)

			if not hg_bot_personality:GetBool() then return mult end

			local p = hg.bots.GetPersonality(bot)

			if not p then return mult end

			return math.Clamp(mult * (0.7 + p.aggression * 0.6), 0.4, 2.2)
		end

		hg.bots.MoraleFleeBias = function(bot)
			local bias = orig.flee(bot)

			if not hg_bot_personality:GetBool() then return bias end

			local p = hg.bots.GetPersonality(bot)

			if not p then return bias end

			return math.Clamp(bias + (p.caution - 0.5) * 0.3 - (p.nerve - 0.5) * 0.3, -0.6, 0.7)
		end

		return true
	end

	-- Everything is loaded by the next tick, whatever order the files ran in.
	timer.Simple(0, function()
		if not Install() then hook.Add("InitPostEntity", "HG_Bots_PersonalityInstall", Install) end
	end)
--//

concommand.Add("hg_bot_personality_report", function(ply)
	if IsValid(ply) and not ply:IsAdmin() then return end

	for bot in pairs(hg.bots.List) do
		local p = IsValid(bot) and hg.bots.GetPersonality(bot)

		if p then
			print(("[hg.bots] %-16s %-10s aggression %.2f  caution %.2f  nerve %.2f  bloodlust %.2f"):format(
				bot:Nick(), p.id, p.aggression, p.caution, p.nerve, p.bloodlust))
		end
	end
end, nil, "Print every bot's character")

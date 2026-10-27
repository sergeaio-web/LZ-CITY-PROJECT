--[[
	Tarkov AI - Speech

	Bots react to what a player SAYS. The text comes from two places:
	- the speech bridge (hg_speech_bridge.py -> cl_bot_speech.lua -> net),
	  i.e. the player's own voice, recognised on their PC;
	- optionally the text chat (hg_bot_speech_chat), which is also the easy
	  way to test without a microphone. Console: hg_bot_say <text>.

	What a bot does depends on who it is:
	- PEACE   ("don't shoot", "I'm a friend"): a bot that has no personal
	  reason against the player calms down for a while - more readily the
	  less bloodthirsty it is. A bot that was attacked, or was told about a
	  traitor, does not listen.
	- THREAT  ("hands up", "drop your weapon"): bots with little nerve
	  freeze in place and stop being a danger; bots with nerve and a short
	  temper take it as a challenge and open fire; the rest get wary.
	- HOLD / FOLLOW / COME / STOP: orders. Only guard bots obey
	  (hg_bot_speech_obey_all 1 makes everybody). To a bot that does not
	  obey, "stand still" is simply a threat.

	Only bots that can hear: within hg_bot_speech_range, half of that
	through walls. Phrases are matched as whole words, Russian and English,
	case-insensitive. Add more in hg.bots.SpeechPhrases, or react to
	anything yourself with hook "HG_BotHeard"(ply, text, intent, hearers).
]]

hg.bots = hg.bots or {}
hg.bots.List = hg.bots.List or {}

util.AddNetworkString("hg_bot_speech")

local hg_bot_speech          = CreateConVar("hg_bot_speech",          "1",   {FCVAR_ARCHIVE}, "Bots react to what players say", 0, 1)
local hg_bot_speech_chat     = CreateConVar("hg_bot_speech_chat",     "1",   {FCVAR_ARCHIVE}, "Typed chat counts as speech too", 0, 1)
local hg_bot_speech_range    = CreateConVar("hg_bot_speech_range",    "700", {FCVAR_ARCHIVE}, "How far a bot hears a player speak (half through walls)", 100, 4000)
local hg_bot_speech_obey_all = CreateConVar("hg_bot_speech_obey_all", "0",   {FCVAR_ARCHIVE}, "Every bot obeys spoken orders, not only guards", 0, 1)
local hg_bot_speech_debug    = CreateConVar("hg_bot_speech_debug",    "0",   {FCVAR_ARCHIVE}, "Print what was heard and who reacted", 0, 1)

--\\ Phrases (whole words, lower case, "e" for "yo")
	hg.bots.SpeechPhrases = hg.bots.SpeechPhrases or {
		peace = {
			"не стреляй", "не стреляйте", "я свой", "я друг", "я не враг", "мир", "дружба", "спокойно",
			"не бойся", "без паники", "я с миром", "опусти оружие", "убери оружие",
			"don't shoot", "dont shoot", "hold fire", "i'm a friend", "im a friend", "friendly",
			"peace", "easy", "calm down", "relax", "no problem", "put your weapon down",
		},
		threat = {
			"руки вверх", "бросай оружие", "брось оружие", "на землю", "не двигайся", "не шевелись", "сдавайся",
			"hands up", "drop your weapon", "drop it", "get down", "freeze", "don't move", "dont move", "surrender",
		},
		hold = {
			"стой", "стоять", "стоять на месте", "жди", "подожди", "держи позицию", "держать позицию",
			"hold", "stay", "wait", "hold position", "stand still",
		},
		follow = {
			"за мной", "иди за мной", "следуй за мной", "следуй", "пошли",
			"follow me", "follow", "come with me", "with me",
		},
		come = {
			"сюда", "иди сюда", "ко мне", "подойди", "ко мне бегом",
			"come here", "over here", "to me", "get over here",
		},
		stop = {
			"отбой", "свободны", "вольно", "разойдись", "отставить", "забудь",
			"at ease", "dismissed", "cancel", "never mind", "stand down",
		},
	}

	-- Order of checking: a sentence that fits two is the stronger one.
	local ORDER = { "threat", "peace", "follow", "come", "stop", "hold" }

	--- Lower-case incl. Cyrillic, punctuation to spaces, "e" for "yo".
	local function Normalize(s)
		local ok, out = pcall(function()
			local parts = {}

			for _, c in utf8.codes(utf8.force(s)) do
				if c >= 0x410 and c <= 0x42F then
					c = c + 0x20
				elseif c == 0x401 or c == 0x451 then
					c = 0x435 -- yo -> e
				elseif c < 128 then
					c = string.byte(string.lower(string.char(c)))
				end

				parts[#parts + 1] = utf8.char(c)
			end

			return table.concat(parts)
		end)

		s = ok and out or string.lower(s)
		s = string.gsub(s, "[%p%c]", " ")
		s = string.gsub(s, "%s+", " ")

		return " " .. string.Trim(s) .. " "
	end

	local function Classify(text)
		local norm = Normalize(text)

		for _, intent in ipairs(ORDER) do
			for _, phrase in ipairs(hg.bots.SpeechPhrases[intent] or {}) do
				if string.find(norm, " " .. Normalize(phrase):sub(2), 1, true) then
					return intent
				end
			end
		end

		return nil
	end

	hg.bots.ClassifySpeech = Classify
--//

--\\ Reacting
	local function Hear(bot, ply, range)
		local d2 = bot:GetPos():DistToSqr(ply:GetPos())

		if d2 > range * range then return false end

		-- Through a wall it is half as far.
		if d2 > (range * 0.5) ^ 2 and hg.bots.CanSee and not hg.bots.CanSee(bot, ply) then return false end

		return true
	end

	local function Say(bot, category)
		if hg.bots.Say then pcall(hg.bots.Say, bot, category) end
	end

	local function Obeys(bot)
		return hg_bot_speech_obey_all:GetBool() or (hg.bots.GetFaction and hg.bots.GetFaction(bot) == "guard")
	end

	local function React(bot, ply, intent)
		local data = bot.Bot
		local mem = data.Memory
		local p = hg.bots.GetPersonality and hg.bots.GetPersonality(bot) or { nerve = 0.5, bloodlust = 0.5 }
		local now = CurTime()

		-- Orders to someone who doesn't take them are just a raised voice.
		if (intent == "hold" or intent == "follow" or intent == "come" or intent == "stop") and not Obeys(bot) then
			if intent ~= "hold" then return "ignored" end

			intent = "threat"
		end

		if intent == "peace" then
			local remembers = (mem.Grudge and mem.Grudge[ply]) or (mem.Informed and (mem.Informed[ply] or 0) > now)

			if remembers then return "doesn't believe it" end
			if math.random() > 1 - p.bloodlust * 0.5 then return "doesn't care" end

			if hg.bots.Truce then hg.bots.Truce(bot, ply, 45) end

			Say(bot, "roger")

			return "calmed down"
		end

		if intent == "threat" then
			if p.nerve < 0.5 then
				if hg.bots.Truce then hg.bots.Truce(bot, ply, 15) end

				-- Freezes where it stands.
				if hg.bots.GiveOrder then hg.bots.GiveOrder(bot, "hold", bot:GetPos()) end

				Say(bot, "needhelp")

				return "froze"
			end

			if p.bloodlust > 0.4 and math.random() < p.bloodlust then
				if hg.bots.Provoke then hg.bots.Provoke(bot, ply) end

				return "took it as a challenge"
			end

			if hg.bots.Alert then hg.bots.Alert(bot, ply:GetPos(), "report") end

			return "got wary"
		end

		if not hg.bots.GiveOrder then return "no orders available" end

		if intent == "hold" then
			hg.bots.GiveOrder(bot, "hold", bot:GetPos())
		elseif intent == "follow" then
			hg.bots.GiveOrder(bot, "follow", nil, ply)
		elseif intent == "come" then
			hg.bots.GiveOrder(bot, "move", ply:GetPos())
		elseif intent == "stop" then
			hg.bots.GiveOrder(bot, "stop")
		end

		Say(bot, "roger")

		return "obeyed"
	end

	--- A player said something. Returns the intent found (or nil).
	function hg.bots.HearSpeech(ply, text)
		if not hg_bot_speech:GetBool() then return nil end
		if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return nil end

		text = string.sub(tostring(text or ""), 1, 200)

		local intent = Classify(text)
		local hearers = {}
		local range = hg_bot_speech_range:GetFloat()

		for bot in pairs(hg.bots.List) do
			if IsValid(bot) and bot:Alive() and bot.Bot and bot.Bot.Enabled and not IsValid(bot.FakeRagdoll) and Hear(bot, ply, range) then
				hearers[#hearers + 1] = bot
			end
		end

		hook.Run("HG_BotHeard", ply, text, intent, hearers)

		if hg_bot_speech_debug:GetBool() then
			print(("[hg.bots] heard %s: \"%s\" -> %s, %d bots in earshot"):format(ply:Nick(), text, tostring(intent), #hearers))
		end

		if not intent then return nil end

		for _, bot in ipairs(hearers) do
			local result = React(bot, ply, intent)

			if hg_bot_speech_debug:GetBool() then print(("    %s: %s"):format(bot:Nick(), tostring(result))) end
		end

		return intent
	end
--//

--\\ Where the text comes from
	local lastAt = {}

	local function Throttled(ply)
		local now = CurTime()

		if now - (lastAt[ply] or 0) < 0.7 then return true end

		lastAt[ply] = now

		return false
	end

	net.Receive("hg_bot_speech", function(_, ply)
		if not IsValid(ply) or Throttled(ply) then return end

		hg.bots.HearSpeech(ply, net.ReadString())
	end)

	hook.Add("PlayerSay", "HG_Bots_SpeechChat", function(ply, text)
		if hg_bot_speech_chat:GetBool() and not Throttled(ply) then hg.bots.HearSpeech(ply, text) end
	end)

	concommand.Add("hg_bot_say", function(ply, _, args, raw)
		if IsValid(ply) and not Throttled(ply) then hg.bots.HearSpeech(ply, raw) end
	end, nil, "Say something to the bots without a microphone: hg_bot_say hands up")

	hook.Add("PlayerDisconnected", "HG_Bots_SpeechCleanup", function(ply) lastAt[ply] = nil end)
--//

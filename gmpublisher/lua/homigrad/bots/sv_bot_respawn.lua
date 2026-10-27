--[[
	Tarkov AI - Respawn

	The core removes (kicks) a bot the moment it dies: its think loop calls
	hg.bots.Remove on anything not alive, and Remove kicks the fake client.
	That is why bots "left the server" after getting killed.

	This wraps hg.bots.Remove (once; the original is kept in
	hg.bots._RemoveOrig): for a dead bot it schedules a respawn instead of
	the kick. The bot keeps its slot, its name and its character. After the
	respawn it is moved to a spot out of the humans' sight and given a fresh
	kit (the same kit roll the director uses), when those parts are loaded.

	Everything that really means "remove it" - hg.bots.RemoveAll, the
	slot filler making room, anything calling hg.bots.RemoveForce - still
	removes it for good. hg_bot_respawn 0 restores the old behaviour.
]]

hg.bots = hg.bots or {}
hg.bots.List = hg.bots.List or {}

local hg_bot_respawn       = CreateConVar("hg_bot_respawn",       "1", {FCVAR_ARCHIVE}, "Dead bots respawn instead of being kicked from the server", 0, 1)
local hg_bot_respawn_delay = CreateConVar("hg_bot_respawn_delay", "6", {FCVAR_ARCHIVE}, "Seconds a dead bot waits before respawning", 0, 300)

local function Respawn(bot)
	bot.hgRespawnAt = nil

	if not IsValid(bot) or bot:Alive() or not hg_bot_respawn:GetBool() then return end

	bot:Spawn() -- PlayerSpawn -> the core's AutoInit gives it a fresh brain

	timer.Simple(0.3, function()
		if not IsValid(bot) or not bot:Alive() then return end

		-- Back into the world somewhere nobody is looking.
		local spot = hg.bots.FindHiddenSpot and hg.bots.FindHiddenSpot()

		if spot then
			bot:SetPos(spot + Vector(0, 0, 8))
			bot:SetEyeAngles(Angle(0, math.Rand(0, 360), 0))

			if bot.Bot then bot.Bot.HomePos = bot:GetPos() end
		end

		-- A fresh kit, like a new bot would get.
		local kit = hg.bots.DirectorKit and hg.bots.DirectorKit("buildup")

		if kit and hg.bots.ApplyLoadout then pcall(hg.bots.ApplyLoadout, bot, kit) end
	end)
end

local function Schedule(bot)
	if bot.hgRespawnAt then return end -- the think loop asks every tick

	bot.hgRespawnAt = CurTime() + hg_bot_respawn_delay:GetFloat()

	timer.Simple(hg_bot_respawn_delay:GetFloat(), function() Respawn(bot) end)
end

local function Install()
	local orig = hg.bots._RemoveOrig

	if not orig then
		if not hg.bots.Remove then return false end

		orig = hg.bots.Remove
		hg.bots._RemoveOrig = orig
	end

	hg.bots.RemoveForce = orig

	hg.bots.Remove = function(bot)
		if hg_bot_respawn:GetBool() and IsValid(bot) and bot:IsBot() and bot.IsHomigradBot and not bot:Alive() then
			Schedule(bot)

			return
		end

		return orig(bot)
	end

	-- "Remove all" means all, dead ones too.
	hg.bots.RemoveAll = function()
		for bot in pairs(hg.bots.List) do orig(bot) end
	end

	return true
end

timer.Simple(0, function()
	if not Install() then hook.Add("InitPostEntity", "HG_Bots_RespawnInstall", Install) end
end)

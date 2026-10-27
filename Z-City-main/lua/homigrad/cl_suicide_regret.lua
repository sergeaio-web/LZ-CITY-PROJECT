-- LZ-city: экран «последних секунд»
-- Пока игрок в состоянии ply.suiciding: экран темнеет, красные слова появляются
-- в случайных местах, висят, трясутся и исчезают; между ними вспыхивают
-- снимки моментов, которые игрок реально видел в игре («жизнь перед глазами»).
-- Файл подхватывается автоматически (cl_ префикс, папка lua/homigrad).

if SERVER then return end

local enabled = CreateClientConVar("lz_regret_fx", "1", true, false, "Эффект последних секунд (1/0)")
local soundOn = CreateClientConVar("lz_regret_sound", "1", true, false, "Звук эффекта (1/0)")

-- ================= НАСТРОЙКИ =================
local PHRASES = {
	"ТЫ УВЕРЕН ЧТО ХОЧЕШЬ ЭТО СДЕЛАТЬ",
	"Я БЛЯТЬ НЕ УМРУ ЖЕ?",
	"СТОП",
	"ЭТО НЕ ИГРА?",
	"ПОДОЖДИ",
	"ЕЩЁ НЕ ПОЗДНО",
	"Я НЕ ХОЧУ",
	"ЧТО Я НАДЕЛАЛ",
	"ПОЖАЛУЙСТА НЕТ",
	"МОЖНО ВСЁ ВЕРНУТЬ?",
	"Я ЖЕ ТОЛЬКО НАЧАЛ ЖИТЬ",
	"ГДЕ ВСЕ?",
	"МНЕ СТРАШНО",
	"ПОЧЕМУ Я НЕ ПОГОВОРИЛ",
	"ХОЧУ НАЗАД",
	"ЭТО НАВСЕГДА",
	"КТО-НИБУДЬ",
	"Я ПЕРЕДУМАЛ",
	"ДАЙТЕ ШАНС",
	"НЕТ НЕТ НЕТ",
}

local CFG = {
	darkMax      = 235,  -- макс. затемнение (0-255)
	darkSpeed    = 80,   -- скорость затемнения, ед/сек
	wordsDelay   = 1.2,  -- через сколько сек после начала пойдут слова
	wordEvery    = {0.25, 0.5}, -- интервал между словами (мин, макс)
	maxWords     = 8,    -- макс. слов на экране одновременно
	wordEnter    = 0.45, -- время «влёта»
	wordStay     = {0.9, 1.8},  -- висит спокойно
	wordShake    = {1.2, 2.2},  -- трясётся
	wordFade     = 0.6,  -- плавное исчезновение
	shakePower   = {2, 5},      -- сила тряски, px
	fontScale    = 7,    -- размер слов (ScreenScale), меньше = мельче

	snapEvery    = 20,   -- как часто запоминать кадр жизни, сек
	snapCount    = 5,    -- сколько кадров хранить (каждый ~8 МБ видеопамяти)
	snapDelay    = 2.5,  -- когда начнут вспыхивать снимки
	snapInterval = 2.4,  -- интервал между снимками, сек
	snapMax      = 4,    -- сколько всего снимков за один эффект
	snapSize     = 0.3,  -- ширина снимка (доля ширины экрана)
	snapLife     = {1.8, 2.6},   -- общее время жизни снимка (вместе с выездом)
	snapSlide    = 0.55, -- сколько сек снимок «выкатывается»
	snapDevelop  = 0.9,  -- сколько сек фото проявляется из белого
	flashPower   = 90,   -- яркость вспышки при появлении снимка (0-255)
	flashTime    = 0.3,  -- длительность вспышки, сек

	-- звук (используются звуки самой игры и стандартные звуки HL2)
	heartVol     = 1.0,  -- громкость сердцебиения (0-1)
	heartEvery   = {0.95, 0.4}, -- интервал между ударами: в начале -> к концу (сек)
	heartRamp    = 10,   -- за сколько сек сердце разгоняется до конечного темпа
	tinnitusVol  = 0.5,  -- громкость звона в ушах (0-1)
	clickSound   = "npc/turret_floor/click1.wav",  -- щелчок «камеры» при снимке
	whooshSound  = "weapons/slam/throw.wav",       -- шорох, когда фото выкатывается
}
-- ==============================================

local RED = Color(255, 26, 43)

surface.CreateFont("LZ_RegretWord", {
	font = "Arial",
	size = ScreenScale(CFG.fontScale),
	weight = 900,
	extended = true, -- кириллица
})

-- общее состояние эффекта (объявлено заранее, его видит и захват кадров)
local active, startT, dark, testUntil = false, 0, 0, 0

-- ---------- кадры из жизни игрока ----------
-- Каждая ячейка кольцевого буфера = текстура размером с экран.
-- Копируем экран прямо в неё (так же, как раньше, но без обрезки),
-- на HUD потом рисуем уменьшенной.
local debugOn = CreateClientConVar("lz_regret_debug", "0", false, false, "Отладка эффекта (1/0)")

local snapRT, snapMat, snapWritten = {}, {}, {}
local snapW, snapH = 0, 0

local function EnsureSnaps()
	local w, h = ScrW(), ScrH()
	if snapW == w and snapH == h then return end
	snapW, snapH = w, h
	snapWritten = {}
	for i = 1, CFG.snapCount do
		local name = "lz_regret_snap_" .. w .. "x" .. h .. "_" .. i
		snapRT[i] = GetRenderTarget(name, w, h)
		snapMat[i] = CreateMaterial(name .. "_mat", "UnlitGeneric", {
			["$basetexture"] = snapRT[i]:GetName(),
			["$ignorez"] = 1,
			["$vertexcolor"] = 1,
			["$vertexalpha"] = 1,
		})
	end
end

local snapNext, snapWrite, forceSnap = CurTime() + 5, 1, false

-- Снимок делается только пока человек реально играет:
-- жив, не в меню/паузе, окно игры в фокусе, не наблюдатель и не в «последних секундах».
local function CanSnapshot(ply)
	if not IsValid(ply) or not ply:Alive() then return false end
	if ply.suiciding or active or dark > 0 then return false end
	if not enabled:GetBool() then return false end
	if gui.IsGameUIVisible() or (system.HasFocus and not system.HasFocus()) then return false end
	if ply:GetObserverMode() ~= OBS_MODE_NONE then return false end
	return true
end

hook.Add("PreDrawHUD", "LZ_RegretCapture", function()
	local ply = LocalPlayer()
	if not CanSnapshot(ply) then return end
	if not forceSnap and CurTime() < snapNext then return end
	forceSnap = false
	snapNext = CurTime() + CFG.snapEvery

	EnsureSnaps()
	render.CopyRenderTargetToTexture(snapRT[snapWrite])
	snapWritten[snapWrite] = true
	if debugOn:GetBool() then print("[LZ regret] кадр записан в ячейку " .. snapWrite) end
	snapWrite = snapWrite % CFG.snapCount + 1
end)

concommand.Add("lz_regret_snap", function()
	forceSnap = true
	timer.Simple(0.2, function()
		local n = 0
		for _ in pairs(snapWritten) do n = n + 1 end
		print("[LZ regret] сохранено кадров: " .. n .. " из " .. CFG.snapCount)
	end)
end)

-- ---------- состояние эффекта ----------
concommand.Add("lz_regret_test", function() testUntil = CurTime() + 12 end) -- прогнать эффект на 12 сек без суицида
local words, snaps = {}, {}
local bag = {}
local nextWord, nextSnap = 0, 0
local flashT = -10
local snapSpawned = 0
local nextBeat = 0
local regretStation, regretLoading

local function NextPhrase()
	if #bag == 0 then
		for i = 1, #PHRASES do bag[i] = PHRASES[i] end
		table.Shuffle(bag)
	end
	return table.remove(bag)
end

local function SpawnWord(now)
	local sw, sh = ScrW(), ScrH()
	words[#words + 1] = {
		text  = NextPhrase(),
		x     = math.Rand(0.15, 0.85) * sw,
		y     = math.Rand(0.1, 0.9) * sh,
		dx    = math.Rand(-sw * 0.2, sw * 0.2),
		dy    = math.Rand(-sh * 0.2, sh * 0.2),
		rot   = math.Rand(-12, 12),
		born  = now,
		stay  = math.Rand(CFG.wordStay[1], CFG.wordStay[2]),
		shake = math.Rand(CFG.wordShake[1], CFG.wordShake[2]),
		jit   = math.Rand(CFG.shakePower[1], CFG.shakePower[2]),
	}
end

local function SpawnSnap(now)
	local have = {}
	for i = 1, CFG.snapCount do
		if snapWritten[i] then have[#have + 1] = i end
	end
	if #have == 0 or snapSpawned >= CFG.snapMax then return end
	snapSpawned = snapSpawned + 1
	local sw, sh = ScrW(), ScrH()
	local x = math.Rand(0.2, 0.8) * sw
	snaps[#snaps + 1] = {
		idx  = have[math.random(#have)],
		x    = x,
		y    = math.Rand(0.25, 0.65) * sh,
		x0   = x + math.Rand(-sw * 0.05, sw * 0.05), -- откуда выезжает (за нижним краем)
		y0   = sh * 1.25,
		rot  = math.Rand(-14, 14),
		born = now,
		life = math.Rand(CFG.snapLife[1], CFG.snapLife[2]),
	}
	flashT = now -- вспышка
	if soundOn:GetBool() then
		surface.PlaySound(CFG.clickSound)
		timer.Simple(0.08, function() surface.PlaySound(CFG.whooshSound) end)
	end
end

local function DrawWord(w, now)
	local t = now - w.born
	local tEnter = CFG.wordEnter
	local tShakeStart = tEnter + w.stay
	local tFadeStart = tShakeStart + w.shake
	if t > tFadeStart + CFG.wordFade then return true end

	local alpha, ox, oy = 255, 0, 0
	if t < tEnter then
		local k = t / tEnter
		k = 1 - (1 - k) * (1 - k)
		alpha = 255 * k
		ox, oy = w.dx * (1 - k), w.dy * (1 - k)
	elseif t >= tShakeStart and t < tFadeStart then
		ox, oy = math.Rand(-w.jit, w.jit), math.Rand(-w.jit, w.jit)
	elseif t >= tFadeStart then
		alpha = 255 * (1 - (t - tFadeStart) / CFG.wordFade)
	end

	-- без cam.PushModelMatrix: повёрнутый текст в HUD обрезается
	local x, y = w.x + ox, w.y + oy
	draw.SimpleText(w.text, "LZ_RegretWord", x + 2, y + 2, Color(0, 0, 0, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText(w.text, "LZ_RegretWord", x, y, Color(RED.r, RED.g, RED.b, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	return false
end

local function DrawSnap(s, now)
	local t = now - s.born
	if t > s.life then return true end

	-- выкатывается снизу (быстро, с замедлением к концу)
	local k = math.min(t / CFG.snapSlide, 1)
	k = 1 - (1 - k) * (1 - k) * (1 - k)
	local x = Lerp(k, s.x0, s.x)
	local y = Lerp(k, s.y0, s.y)
	local rot = Lerp(k, s.rot * 0.2, s.rot)

	-- проявление: из белого в обычный цвет
	local dev = math.Clamp((t - 0.15) / CFG.snapDevelop, 0, 1)

	-- исчезновение в конце, с рваным миганием
	local a = 255
	local tail = 0.35
	if t > s.life - tail then
		a = 255 * math.max(0, (s.life - t) / tail)
		if math.floor(t * 18) % 3 == 0 then a = a * 0.4 end
	end

	local w = ScrW() * CFG.snapSize
	local h = w * (ScrH() / ScrW())
	local pad = w * 0.04
	local m = Matrix()
	m:Translate(Vector(x, y, 0))
	m:Rotate(Angle(0, rot, 0))
	cam.PushModelMatrix(m)
		surface.SetDrawColor(225, 225, 225, a)
		surface.DrawRect(-w / 2 - pad, -h / 2 - pad, w + pad * 2, h + pad * 4)
		surface.SetMaterial(snapMat[s.idx])
		surface.SetDrawColor(200, 185, 170, a)
		surface.DrawTexturedRect(-w / 2, -h / 2, w, h)
		if dev < 1 then
			surface.SetDrawColor(235, 235, 235, a * (1 - dev))
			surface.DrawRect(-w / 2, -h / 2, w, h)
		end
	cam.PopModelMatrix()
	return false
end

hook.Add("HUDPaint", "LZ_RegretPaint", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local now = CurTime()
	local want = enabled:GetBool() and ply:Alive() and (ply.suiciding or now < testUntil) and true or false

	if want and not active then
		active, startT = true, now
		words, snaps = {}, {}
		nextWord = now + CFG.wordsDelay
		nextSnap = now + CFG.snapDelay
		nextBeat = now + 0.3
		snapNext = now + CFG.snapEvery
		snapSpawned = 0
	elseif not want and active then
		active = false
		snapNext = now + CFG.snapEvery
	end

	dark = math.Approach(dark, active and CFG.darkMax or 0, FrameTime() * (active and CFG.darkSpeed or 400))

	-- звон в ушах: нарастает вместе с затемнением, гаснет вместе с ним
	if soundOn:GetBool() and (active or dark > 0) then
		if not IsValid(regretStation) and not regretLoading then
			regretLoading = true
			sound.PlayFile("sound/zcitysnd/real_sonar/tinnitus" .. math.random(3) .. ".mp3", "noblock noplay", function(station)
				regretLoading = false
				if IsValid(station) then
					station:SetVolume(0)
					station:EnableLooping(true)
					station:Play()
					regretStation = station
				end
			end)
		end
		if IsValid(regretStation) then
			regretStation:SetVolume(CFG.tinnitusVol * dark / CFG.darkMax)
		end
	elseif IsValid(regretStation) then
		regretStation:Stop()
		regretStation = nil
	end

	if dark > 0 then
		surface.SetDrawColor(0, 0, 0, dark)
		surface.DrawRect(0, 0, ScrW(), ScrH())
	end

	-- вспышка при появлении снимка
	local ft = now - flashT
	if ft >= 0 and ft < CFG.flashTime then
		local f = 1 - ft / CFG.flashTime
		surface.SetDrawColor(255, 255, 255, CFG.flashPower * f * f)
		surface.DrawRect(0, 0, ScrW(), ScrH())
	end

	if active then
		-- сердцебиение: с каждым ударом чаще и громче
		if soundOn:GetBool() and now >= nextBeat then
			local prog = math.Clamp((now - startT) / CFG.heartRamp, 0, 1)
			sound.Play("heartbeat/heartbeat_single.wav", ply:EyePos(), 75, Lerp(prog, 60, 85), CFG.heartVol * Lerp(prog, 0.5, 1))
			nextBeat = now + Lerp(prog, CFG.heartEvery[1], CFG.heartEvery[2])
		end
		if now >= nextWord and #words < CFG.maxWords then
			SpawnWord(now)
			nextWord = now + math.Rand(CFG.wordEvery[1], CFG.wordEvery[2])
		end
		if now >= nextSnap then
			SpawnSnap(now)
			nextSnap = now + CFG.snapInterval
		end
	end

	for i = #snaps, 1, -1 do
		if DrawSnap(snaps[i], now) then table.remove(snaps, i) end
	end
	for i = #words, 1, -1 do
		if DrawWord(words[i], now) then table.remove(words, i) end
	end
end)

--made by mrrp :3

local maxLength = GetConVar("zchat_maxmessagelength")

local NoDrop = CreateClientConVar("zchat_dropcharacters", 1, true, false, "Play the character dropping animation when erasing text", 0, 1)
local ShowTextBoxInactive = CreateClientConVar("zchat_showtextboxinactive", 1, true, false, "Showing your text in textbox while chat is turned off", 0, 1)

local function CallbackBind(self, callback)
	return function(_, ...)
		return callback(self, ...)
	end
end

local function PaintMarkupOverride(text, font, x, y, color, alignX, alignY, alpha)
	alpha = alpha or 255

	-- тёмные цвета (ники, системные сообщения) осветляем, чтобы текст читался
	local r, g, b = color.r, color.g, color.b
	local lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255

	if lum < 0.55 then
		local mix = (0.55 - lum) * 1.2

		r = r + (255 - r) * mix
		g = g + (255 - g) * mix
		b = b + (255 - b) * mix
	end

	surface.SetFont(font)

	-- двойная тень
	surface.SetTextColor(0, 0, 0, alpha)
	surface.SetTextPos(x + 1, y + 1)
	surface.DrawText(text)
	surface.SetTextPos(x + 2, y + 2)
	surface.DrawText(text)

	surface.SetTextColor(r, g, b, alpha)
	surface.SetTextPos(x, y)
	surface.DrawText(text)
end

local function clamp(v, min, max)
	if v < min then return min end
	if v > max then return max end
	return v
end

local function easeOutBack(t)
	local c1 = 1.70158
	local c3 = c1 + 1
	return 1 + c3 * (t - 1)^3 + c1 * (t - 1)^2
end

local function randomSide()
	local sides = {
		{ x = -180, y = math.random(-120, 120) },
		{ x = 180,  y = math.random(-120, 120) },
		{ x = math.random(-120, 120), y = -180 },
		{ x = math.random(-120, 120), y = 180 }
	}
	return sides[math.random(#sides)]
end

local function utf8LastChar(str)
	if not str or str == "" then return "" end
	local len = utf8.len(str)
	if len <= 0 then return "" end
	return utf8.sub(str, len, len)
end

local function utf8RemoveLastChar(str)
	if not str or str == "" then return "" end
	local len = utf8.len(str)
	if len <= 0 then return "" end
	return utf8.sub(str, 1, len - 1)
end

local PANEL = {}

function PANEL:Init()
	self.text = ""
	self.alpha = 0
	self.fadeDelay = 15
	self.fadeDuration = 5
	self.yAnimDuration = 1
	self.yAnim = 5

	-- лёгкая тряска после появления сообщения
	self.messageShakeStart = 0
	self.messageShakeDuration = 0.35
	self.messageShakePower = 1.2
end

function PANEL:SetMarkup(text)
	self.text = text

	self.markup = hg.markup.Parse(self.text, self:GetWide())
	self.markup.onDrawText = PaintMarkupOverride

	self:SetTall(self.markup:GetHeight())

	self.messageShakeStart = CurTime()

	timer.Simple(self.fadeDelay, function()
		if not IsValid(self) then
			return
		end

		self:CreateAnimation(self.fadeDuration, {
			index = 3,
			target = {alpha = 0}
		})
	end)

	self:CreateAnimation(self.yAnimDuration, {
		index = 4,
		target = {yAnim = 0},
		easing = "outQuint"
	})

	self:CreateAnimation(0.5, {
		index = 3,
		target = {alpha = 255},
	})
end

function PANEL:PerformLayout(width, height)
	if not self.text or self.text == "" then
		return
	end

	self.markup = hg.markup.Parse(self.text, width)
	self.markup.onDrawText = PaintMarkupOverride

	self:SetTall(self.markup:GetHeight())
end

function PANEL:Paint(width, height)
	if not self.markup then
		return
	end

	if not IsValid(hg.chat) then
		return
	end

	local newAlpha
	if hg.chat:GetActive() then
		newAlpha = math.max(hg.chat.alpha, self.alpha)
	else
		newAlpha = self.alpha -- без приглушения realAlpha: сообщения при закрытом чате яркие
	end

	newAlpha = math.Clamp(newAlpha, 0, 255)

	-- слабая тряска в первые 0.35 сек
	local shakeX = 0
	local shakeY = 0

	local shakeProgress = (CurTime() - self.messageShakeStart) / self.messageShakeDuration

	if shakeProgress >= 0 and shakeProgress < 1 then
		local strength = (1 - shakeProgress) * self.messageShakePower
		shakeX = math.sin(CurTime() * 35) * strength
		shakeY = math.cos(CurTime() * 31) * strength
	end

	DisableClipping(true)
		local chatboxX, chatboxY = hg.chat:GetPos()
		local chatboxWide, chatboxTall = hg.chat:GetSize()
		render.SetScissorRect(chatboxX, chatboxY, chatboxX + chatboxWide, chatboxY + chatboxTall, true)

		self.markup:draw(shakeX, self.yAnim + shakeY, nil, nil, newAlpha)

		render.SetScissorRect(0, 0, 0, 0, false)
	DisableClipping(false)
end

vgui.Register("zChatMessage", PANEL, "Panel")

PANEL = {}

DEFINE_BASECLASS("DTextEntry")

function PANEL:Init()
	self:SetFont("zChatFont")
	self:SetUpdateOnType(true)
	self:SetHistoryEnabled(true)

	self.History = hg.chat.messageHistory
	self.droppedCharacters = {}
	self.animatedCharacters = {}

	self.prevText = ""

	self:SetTextColor(color_white)
	self:SetPaintBackground(false)
	self.m_bLoseFocusOnClickAway = false
end

function PANEL:AllowInput(newCharacter)
	local text = self:GetText()
	local maxLen = maxLength:GetInt()

	if (string.len(text .. newCharacter) > maxLen) then
		surface.PlaySound("common/talk.wav")
		return true
	end
end

function PANEL:Think()
	local text = self:GetText()
	local maxLen = maxLength:GetInt()

	if (text:utf8len() > maxLen) then
		local newText = text:utf8sub(0, maxLen)
		self:SetText(newText)
		self:SetCaretPos(newText:utf8len())
	end
end

local gradient_l = Material("vgui/gradient-l")

function PANEL:Paint(w, h)
	-- графитовое поле ввода + пастельно-розовая линия снизу
	surface.SetDrawColor(58, 60, 68, 210)
	surface.DrawRect(0, 0, w, h)

	surface.SetDrawColor(255, 183, 206, 170)
	surface.DrawRect(0, h - 2, w, 2)

	-- Анимация вводимых букв
	for i = #self.animatedCharacters, 1, -1 do
		local v = self.animatedCharacters[i]
		v.elapsed = v.elapsed + FrameTime()

		if v.elapsed >= v.duration then
			table.remove(self.animatedCharacters, i)
		else
			local progress = v.elapsed / v.duration
			local eased = easeOutBack(progress)

			v.x = v.startX + (v.targetX - v.startX) * eased
			v.y = v.startY + (v.targetY - v.startY) * eased
			v.alpha = 255 * (1 - progress * 0.3)

			local shakeX = math.sin(CurTime() * 25) * 5
			local shakeY = math.cos(CurTime() * 22) * 4

			DisableClipping(true)
				surface.SetTextColor(200, 200, 255, v.alpha)
				surface.SetTextPos(v.x + shakeX, v.y + shakeY)
				surface.SetFont("zChatFont")
				surface.DrawText(v.text)
			DisableClipping(false)
		end
	end

	for k, v in ipairs(self.droppedCharacters) do
		local text = v.text

		v.velocityY = v.velocityY + (5 * FrameTime())
		v.y = v.y + v.velocityY
		v.x = v.x + v.velocityX
		v.alpha = v.alpha - FrameTime() * 750

		DisableClipping(true)
			surface.SetTextColor(150, 150, 150, v.alpha)
			surface.SetTextPos(v.x, v.y)
			surface.SetFont("zChatFont")
			surface.DrawText(text)
		DisableClipping(false)

		if v.alpha <= 0 then
			table.remove(self.droppedCharacters, k)
		end
	end

	if ShowTextBoxInactive:GetBool() and !hg.chat:GetActive() and self.prevText != "" then
		DisableClipping(true)
			surface.SetTextColor(150, 150, 150, 55)
			surface.SetTextPos(0, 0)
			surface.SetFont("zChatFont")
			surface.DrawText(self.prevText)
		DisableClipping(false)
	end

	BaseClass.Paint(self, w, h)
end

function PANEL:OnValueChange(text)
	local prevText = self.prevText or ""

	local len1, len2 = utf8.len(prevText), utf8.len(text)

	if len2 > len1 then
		local newChar = utf8LastChar(text)
		local leftText = utf8RemoveLastChar(text)

		local side = randomSide()

		surface.SetFont("zChatFont")
		local leftWidth = surface.GetTextSize(leftText or "")
		local targetX = 5 + leftWidth
		local targetY = 8

		self.animatedCharacters[#self.animatedCharacters + 1] = {
			text = newChar,
			startX = targetX + side.x,
			startY = targetY + side.y,
			targetX = targetX,
			targetY = targetY,
			x = targetX + side.x,
			y = targetY + side.y,
			elapsed = 0,
			duration = 0.3,
			alpha = 255
		}
	end

	if len1 > len2 then
		local removedCount = len1 - len2
		local droppedText = utf8.sub(prevText, len2 + 1, len1)
		local droppedChars = string.Explode(utf8.charpattern, droppedText)

		for _, v in ipairs(droppedChars) do
			local data = {}
			data.text = v
			data.x = 5
			data.y = 8
			data.velocityX = math.Rand(-0.1, 0.1)
			data.velocityY = -1
			data.alpha = 255
			table.insert(self.droppedCharacters, data)
		end
	end

	self.prevText = text
end

vgui.Register("zChatboxEntry", PANEL, "DTextEntry")

PANEL = {}

AccessorFunc(PANEL, "bActive", "Active", FORCE_BOOL)
AccessorFunc(PANEL, "realAlpha", "RealAlpha", FORCE_BOOL)

function PANEL:Init()
	hg.chat = self

	self.entries = {}
	self.messageHistory = {}

	self.alpha = 255
	self.realAlpha = 255

	self:SetSize(ScrW() * 0.3, ScrH() * 0.2)
	self:SetPos(ScrW() * 0.02, ScrH() * 0.67)

	local entryPanel = self:Add("Panel")
	entryPanel:SetZPos(1)
	entryPanel:Dock(BOTTOM)
	entryPanel:DockMargin(4, 0, 4, 4)

	self.entry = entryPanel:Add("zChatboxEntry")
	self.entry:Dock(FILL)
	self.entry.OnEnter = CallbackBind(self, self.OnMessageSent)

	self.history = self:Add("DScrollPanel")
	self.history:Dock(FILL)
	self.history:DockMargin(4, 2, 4, 4)


	self:SetActive(false)
end

local gradient_d = Material("vgui/gradient-d")
local gray = Color(255, 200, 220, 170) -- пастельно-розовый текст подсказок
local black = Color(0, 0, 0, 200)

function PANEL:Paint(w, h)
	-- Страховка: при потере сознания (cl_main.lua) realAlpha ставится в 0 и должен вернуться в 255.
	-- Если анимация возврата не отработала, сообщения не рисуются при закрытом чате.
	local org = LocalPlayer().organism
	if self.realAlpha < 255 and not (org and org.otrub) and not timer.Exists("otrubhuy") then
		self.realAlpha = 255
	end

	-- графитовая подложка
	surface.SetDrawColor(40, 42, 48, 215)
	surface.DrawRect(0, 0, w, h)

	-- мягкий пастельно-розовый градиент снизу (слегка "дышит")
	surface.SetDrawColor(255, 183, 206, 30 + math.sin(CurTime() * 1.5) * 8)
	surface.SetMaterial(gradient_d)
	surface.DrawTexturedRect(0, h * 0.5, w, h * 0.5)
	draw.NoTexture()

	-- тонкая пастельно-розовая линия сверху и лёгкая рамка
	surface.SetDrawColor(255, 183, 206, 200)
	surface.DrawRect(0, 0, w, 2)
	surface.SetDrawColor(255, 183, 206, 60)
	surface.DrawOutlinedRect(0, 0, w, h, 1)

	surface.SetAlphaMultiplier(1)
		-- Пока чат закрыт, но на экране есть свежие сообщения: графитовая подложка с розовой линией
		if not self.bActive then
			local maxAlpha = 0

			for _, entry in ipairs(self.entries) do
				if IsValid(entry) and entry.alpha > maxAlpha then
					maxAlpha = entry.alpha
				end
			end

			if maxAlpha > 5 then
				local k = maxAlpha / 255

				surface.SetDrawColor(40, 42, 48, 170 * k)
				surface.DrawRect(0, 0, w, h)
				surface.SetDrawColor(255, 183, 206, 150 * k)
				surface.DrawRect(0, 0, w, 2)
			end
		end

		self.history:PaintManual()
		local bar = self.history:GetVBar()
		bar:SetAlpha(self:GetAlpha())
	surface.SetAlphaMultiplier(self:GetAlpha() / 255)

	DisableClipping(true)
		draw.SimpleText("Hold left ALT and press ENTER to whisper", "zChatFontSmall", 5, h * 1.01 + 1, black)
		draw.SimpleText("Hold left ALT and press ENTER to whisper", "zChatFontSmall", 4, h * 1.01, gray)

		if LocalPlayer().organism and LocalPlayer().organism.otrub then
			draw.SimpleText("Your messages are currently not visible to anyone.", "zChatFontSmall", ScrW() * 0.3 + 1, h * 1.01 + 1, black, TEXT_ALIGN_RIGHT)
			draw.SimpleText("Your messages are currently not visible to anyone.", "zChatFontSmall", ScrW() * 0.3, h * 1.01, gray, TEXT_ALIGN_RIGHT)
		end
	DisableClipping(false)

	if self.bActive then
		self:SetAlpha(self.alpha - (255 - self.realAlpha))
	end
end

function PANEL:SetActive(bActive, bRemovePrev)
	if (bActive) then
		self:SetAlpha(255)
		self:MakePopup()
		self.entry:RequestFocus()
		input.SetCursorPos(self:LocalToScreen(10, self:GetTall() + 10))
		hook.Run("StartChat")
	else
		-- 1 вместо 0: при alpha = 0 Paint у панели может не вызываться, а именно в нём
		-- рисуются сообщения при закрытом чате (визуально разницы нет: 1/255 невидимо)
		self:SetAlpha(1)
		self:SetMouseInputEnabled(false)
		self:SetKeyboardInputEnabled(false)

		if bRemovePrev then
			self.entry:SetText("")
			self.entry.prevText = ""
		end

		gui.EnableScreenClicker(false)
		hook.Run("FinishChat")
	end

	self.bActive = bActive

	local bar = self.history:GetVBar()
	bar:SetScroll(bar.CanvasSize)
end

function PANEL:AnimateAlpha(newAlpha)
	self:CreateAnimation(1, {
		index = 1,
		target = {alpha = newAlpha},
	})
end

function PANEL:AnimateRealAlpha(newAlpha)
	self:CreateAnimation(1, {
		index = 2,
		target = {realAlpha = newAlpha},
	})
end

function PANEL:SetRealAlpha(alpha)
	self.realAlpha = alpha
end

function PANEL:OnMessageSent()
	local text = self.entry:GetText()

	if (text:find("%S")) then
		local lastEntry = hg.chat.messageHistory[#hg.chat.messageHistory]

		if (lastEntry ~= text) then
			if (#hg.chat.messageHistory >= 20) then
				table.remove(hg.chat.messageHistory, 1)
			end

			hg.chat.messageHistory[#hg.chat.messageHistory + 1] = text
		end

		net.Start("zChatMessage")
			net.WriteString(text)
		net.SendToServer()
	end

	self:SetActive(false, true)
end

function PANEL:AddLine(elements)
	local buffer = {
		"<font=zChatFont>"
	}

	buffer = hook.Run("ModifyMessageBuffer", buffer, CHAT_SPEAKER) or buffer

	for _, v in ipairs(elements) do
		if (type(v) == "IMaterial") then
			local texture = v:GetName()

			if (texture) then
				buffer[#buffer + 1] = string.format("<img=%s,%dx%d> ", texture, v:Width(), v:Height())
			end
		elseif (istable(v) and v.r and v.g and v.b) then
			buffer[#buffer + 1] = string.format("<color=%d,%d,%d>", v.r, v.g, v.b)
		elseif (type(v) == "Player") then
			local color = v:GetPlayerColor():ToColor()

			buffer[#buffer + 1] = string.format(
				"<color=%d,%d,%d>%s",
				color.r,
				color.g,
				color.b,
				v:GetName():gsub("<", "&lt;"):gsub(">", "&gt;")
			)
		else
			buffer[#buffer + 1] = tostring(v):gsub("<", "&lt;"):gsub(">", "&gt;")
		end
	end

	local panel = self.history:Add("zChatMessage")
	panel:Dock(TOP)
	panel:InvalidateParent(true)
	panel:SetMarkup(table.concat(buffer))

	if (#self.entries >= 100) then
		local oldPanel = table.remove(self.entries, 1)

		if (IsValid(oldPanel)) then
			oldPanel:Remove()
		end
	end

	local bar = self.history:GetVBar()
	local bScroll = !self:GetActive() or bar.Scroll == bar.CanvasSize

	if bScroll then
		bar:SetScroll(bar.CanvasSize)
	end

	self.entries[#self.entries + 1] = panel
	return panel
end

function PANEL:AddMessage(...)
	self:AddLine({...})
	chat.PlaySound()
end

vgui.Register("zChatbox", PANEL, "EditablePanel")
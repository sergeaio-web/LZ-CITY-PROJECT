-- ВРЕМЕННЫЙ отладчик чата. Положить в: lua/autorun/client/zchat_debug.lua
-- После проверки файл можно удалить. Ничего не меняет, только пишет в консоль (~).

local function Dump(tag)
	local chat = hg and hg.chat

	if not IsValid(chat) then
		print("[zchat-debug] " .. tag .. ": hg.chat НЕ СУЩЕСТВУЕТ")
		return
	end

	local last = chat.entries and chat.entries[#chat.entries]

	print(string.format(
		"[zchat-debug] %s | active=%s panelAlpha=%s alpha=%s realAlpha=%s visible=%s entries=%d chatPaintCalls=%s",
		tag,
		tostring(chat:GetActive()),
		tostring(chat:GetAlpha()),
		tostring(chat.alpha),
		tostring(chat.realAlpha),
		tostring(chat:IsVisible()),
		chat.entries and #chat.entries or -1,
		tostring(chat._dbgPaint)
	))

	if IsValid(last) then
		print(string.format(
			"[zchat-debug]   последнее сообщение: alpha=%s wide=%s tall=%s visible=%s markup=%s msgPaintCalls=%s",
			tostring(last.alpha),
			tostring(last:GetWide()),
			tostring(last:GetTall()),
			tostring(last:IsVisible()),
			tostring(last.markup ~= nil),
			tostring(last._dbgPaint)
		))
	else
		print("[zchat-debug]   сообщений в списке нет")
	end
end

local function Wrap(panel)
	if not IsValid(panel) or panel._dbgWrapped then return end

	panel._dbgWrapped = true
	panel._dbgPaint = 0

	local old = panel.Paint

	panel.Paint = function(self, ...)
		self._dbgPaint = (self._dbgPaint or 0) + 1
		return old(self, ...)
	end
end

hook.Add("OnPlayerChat", "zchat_debug", function(ply, text)
	timer.Simple(0.3, function()
		local chat = hg and hg.chat
		if not IsValid(chat) then return Dump("через 0.3с") end

		Wrap(chat)
		Wrap(chat.entries and chat.entries[#chat.entries])

		Dump("через 0.3с")

		-- через секунду счётчики Paint покажут, рисуется ли панель, пока чат закрыт
		timer.Simple(1, function()
			Dump("через 1.3с")
		end)
	end)
end)

concommand.Add("zchat_debug", function()
	Dump("вручную")
end)

print("[zchat-debug] загружен. Отправь сообщение, потом пришли строки [zchat-debug] из консоли.")
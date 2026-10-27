local MODE = MODE

local roles = {
	[0] = {
		name = "Прячитесь",
		objective = "Пора прятаться, а то умру!.",
		color = Color(190, 120, 0)
	},
	[1] = {
		name = "Искатель",
		objective = "Пора найти и вышибить мозг этим уродам!",
		color = Color(0, 120, 190)
	},
	[2] = {
		name = "SWAT Оперативник",
		objective = "Поддержите искателей и прикончите оставшихся прячущихся.",
		color = Color(30, 30, 100)
	},
}

net.Receive("hns_start", function()
	zb.RemoveFade()
end)

function MODE:RenderScreenspaceEffects()
	if zb.ROUND_START + 7.5 < CurTime() then return end

	local fade = math.Clamp(zb.ROUND_START + 7.5 - CurTime(), 0, 1)

	surface.SetDrawColor(0, 0, 0, 255 * fade)
	surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end

local function drawTopStatus()
	if GetGlobalBool("ZB_HNS_SWAT_PENDING", false) then
		local deadline = GetGlobalFloat("ZB_HNS_SWAT_TIME", 0)
		local ready = GetGlobalBool("ZB_HNS_SWAT_READY", false)
		local color = ready and Color(255, 180, 60) or Color(70, 160, 255)
		local text

		if deadline > CurTime() then
			text = "SWAT Прибудет: " .. string.FormattedTime(deadline - CurTime(), "%02i:%02i")
		else
			text = "SWAT ждет мертвых игроков"
		end

		draw.SimpleText(text, "ZB_HomicideMedium", sw * 0.5, sh * 0.05, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	if zb.ROUND_START + MODE.PrepareTime > CurTime() then
		local timeLeft = string.FormattedTime(zb.ROUND_START + MODE.PrepareTime - CurTime(), "%02i:%02i")

		draw.SimpleText("Искатели прибудут: " .. timeLeft, "ZB_HomicideMedium", sw * 0.5, sh * 0.09, Color(255, 90, 90), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

function MODE:HUDPaint()
	drawTopStatus()

	if zb.ROUND_START + 8.5 < CurTime() then return end

	local localPlayer = LocalPlayer()
	if not IsValid(localPlayer) or not localPlayer:Alive() then return end

	local role = roles[localPlayer:Team()]
	if not role then return end

	zb.RemoveFade()

	local fade = math.Clamp(zb.ROUND_START + 8 - CurTime(), 0, 1)
	local roleColor = Color(role.color.r, role.color.g, role.color.b, 255 * fade)

	draw.SimpleText("Прятки", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("Вы: " .. role.name, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, roleColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText(role.objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, roleColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	if hg.PluvTown.Active then
		surface.SetMaterial(hg.PluvTown.PluvMadness)
		surface.SetDrawColor(255, 255, 255, math.random(175, 255) * fade / 2)
		surface.DrawTexturedRect(sw * 0.25, sh * 0.44 - ScreenScale(15), sw / 2, ScreenScale(30))

		draw.SimpleText("SOMEWHERE IN PLUVTOWN", "ZB_ScrappersLarge", sw / 2, sh * 0.44 - ScreenScale(2), Color(0, 0, 0, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

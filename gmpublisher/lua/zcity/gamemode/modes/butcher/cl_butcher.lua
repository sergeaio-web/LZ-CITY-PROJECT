MODE.name = "ButcherMode"
 
local MODE = MODE
 
net.Receive("butcher_start", function()
    if ACSound then
        ACSound:Stop()
        ACSound = nil
    end
 
    sound.PlayFile("sound/butcher.wav", "noplay", function(station)
        if IsValid(station) then
            station:SetVolume(3) 
            station:Play()
            ACSound = station
        end
    end)
 
    zb.RemoveFade()
end)
 
local teams = {
	[0] = {
		objective = "Выживи 240 секунд!",
		name = "Выживший",
		color1 = Color(40, 120, 190),
		color2 = Color(0, 120, 190)
	},
	[1] = {
		objective = "Пора разъебать фанатов суперов!...",
		name = "Билли Бутчер",
		color1 = Color(190, 100, 0),
		color2 = Color(190, 100, 0)
	},
}
 
function MODE:RenderScreenspaceEffects()
    if zb.ROUND_START + 7.5 < CurTime() then return end
    local fade = math.Clamp(zb.ROUND_START + 7.5 - CurTime(), 0, 1)
 
    surface.SetDrawColor(0, 0, 0, 255 * fade)
    surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end
 
function MODE:HUDPaint()
    -- Timer calculation (240 seconds total)
    local timeLeft = math.max(0, math.floor(240 - (CurTime() - zb.ROUND_START)))
    local minutes = math.floor(timeLeft / 60)
    local seconds = timeLeft % 60
    local timeFormatted = string.format("%02d:%02d", minutes, seconds)
    
    -- Draw Timer at the top center
    draw.SimpleText(timeFormatted, "ZB_HomicideMediumLarge", ScrW() * 0.5, 40, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    if zb.ROUND_START + 8.5 < CurTime() then return end
	if not lply:Alive() then return end
	
    zb.RemoveFade()
    local fade = math.Clamp(zb.ROUND_START + 8 - CurTime(), 0, 1)
	local team_ = lply:Team()
    
    draw.SimpleText("Homicide | Билли Бутчер", "ZB_HomicideMediumLarge", ScrW() * 0.5, ScrW() * 0.1, Color(255, 120, 50, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    local Rolename = teams[team_].name
    local ColorRole = teams[team_].color1
    ColorRole.a = 255 * fade
    draw.SimpleText("Вы: " .. Rolename, "ZB_HomicideMediumLarge", ScrW() * 0.5, ScrH() * 0.5, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
 
    local Objective = teams[team_].objective
    local ColorObj = teams[team_].color2
    ColorObj.a = 255 * fade
    draw.SimpleText(Objective, "ZB_HomicideMedium", ScrW() * 0.5, ScrH() * 0.9, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end
 
local CreateEndMenu
 
net.Receive("butcher_roundend", function()
    CreateEndMenu()
end)
 
local colGray = Color(85, 85, 85, 255)
local colRed = Color(160, 70, 10)
local colRedUp = Color(190, 90, 30)
local col = Color(255, 255, 255, 255)
local colSpect1 = Color(75, 75, 75, 255)
local colSpect2 = Color(255, 255, 255)
 
if IsValid(hmcdEndMenu) then
    hmcdEndMenu:Remove()
    hmcdEndMenu = nil
end
 
CreateEndMenu = function()
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end
    
	hmcdEndMenu = vgui.Create("ZFrame")
    surface.PlaySound("ambient/alarms/warningbell1.wav")
 
	local sizeX, sizeY = ScrW() / 2.5, ScrH() / 1.2
	local posX, posY = ScrW() / 1.3 - sizeX / 2, ScrH() / 2 - sizeY / 2
 
	hmcdEndMenu:SetPos(posX, posY)
	hmcdEndMenu:SetSize(sizeX, sizeY)
	hmcdEndMenu:MakePopup()
	hmcdEndMenu:SetKeyboardInputEnabled(false)
	hmcdEndMenu:ShowCloseButton(false)
 
	local closebutton = vgui.Create("DButton", hmcdEndMenu)
	closebutton:SetPos(5, 5)
	closebutton:SetSize(ScrW() / 20, ScrH() / 30)
	closebutton:SetText("")
	
	closebutton.DoClick = function()
		if IsValid(hmcdEndMenu) then
			hmcdEndMenu:Close()
			hmcdEndMenu = nil
		end
	end
 
	closebutton.Paint = function(self, w, h)
		surface.SetDrawColor(122, 122, 122, 255)
        surface.DrawOutlinedRect(0, 0, w, h, 2.5)
		surface.SetFont("ZB_InterfaceMedium")
		surface.SetTextColor(col.r, col.g, col.b, col.a)
		local lengthX, _ = surface.GetTextSize("Close")
		surface.SetTextPos(lengthX - lengthX / 1.1, 4)
		surface.DrawText("Close")
	end
 
    hmcdEndMenu.Paint = function(self, w, h)
		BlurBackground(self)
		surface.SetFont("ZB_InterfaceMediumLarge")
		surface.SetTextColor(col.r, col.g, col.b, col.a)
		local lengthX, _ = surface.GetTextSize("Players:")
		surface.SetTextPos(w / 2 - lengthX / 2, 20)
		surface.DrawText("Players:")
		surface.SetDrawColor(255, 100, 0, 128)
        surface.DrawOutlinedRect(0, 0, w, h, 2.5)
	end

	local DScrollPanel = vgui.Create("DScrollPanel", hmcdEndMenu)
	DScrollPanel:SetPos(10, 80)
	DScrollPanel:SetSize(sizeX - 20, sizeY - 90)
	function DScrollPanel:Paint(w, h)
		BlurBackground(self)
		surface.SetDrawColor(255, 100, 0, 128)
        surface.DrawOutlinedRect(0, 0, w, h, 2.5)
	end
 
	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		local but = vgui.Create("DButton", DScrollPanel)
		but:SetSize(100, 50)
		but:Dock(TOP)
		but:DockMargin(8, 6, 8, -1)
		but:SetText("")
		but.Paint = function(self, w, h)
            local col1 = (ply:Alive() and colRed) or colGray
            local col2 = (ply:Alive() and colRedUp) or colSpect1
			surface.SetDrawColor(col1.r, col1.g, col1.b, col1.a)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(col2.r, col2.g, col2.b, col2.a)
			surface.DrawRect(0, h / 2, w, h / 2)
 
            local pCol = ply:GetPlayerColor():ToColor()
			surface.SetFont("ZB_InterfaceMediumLarge")
			local lengthX, lengthY = surface.GetTextSize(ply:GetPlayerName() or "Disconnected...")
			
			surface.SetTextColor(0, 0, 0, 255)
			surface.SetTextPos(w / 2 + 1, h / 2 - lengthY / 2 + 1)
			surface.DrawText(ply:GetPlayerName() or "Disconnected...")
 
			surface.SetTextColor(pCol.r, pCol.g, pCol.b, pCol.a)
			surface.SetTextPos(w / 2, h / 2 - lengthY / 2)
			surface.DrawText(ply:GetPlayerName() or "Disconnected...")
 
			surface.SetFont("ZB_InterfaceMediumLarge")
			surface.SetTextColor(colSpect2.r, colSpect2.g, colSpect2.b, colSpect2.a)
			local textName = (ply:Name() .. (not ply:Alive() and " - died" or ""))
			surface.SetTextPos(15, h / 2 - lengthY / 2)
			surface.DrawText(textName)
		end
 
		function but:DoClick()
			if ply:IsBot() then chat.AddText(Color(255, 0, 0), "No, you can't view bots.") return end
			gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
		end
 
		DScrollPanel:AddItem(but)
	end
 
	return true
end
 
function MODE:RoundStart()
    if IsValid(hmcdEndMenu) then
        hmcdEndMenu:Remove()
        hmcdEndMenu = nil
    end
end
local MODE = MODE or {}
local sw, sh = ScrW(), ScrH()

function MODE:PreDrawHUD()
    if not zb.ROUND_START then return end
    if zb.ROUND_START + 7.5 < CurTime() then return end
    
    local fade = math.Clamp(zb.ROUND_START + 7.5 - CurTime(), 0, 1)
    surface.SetDrawColor(0, 0, 0, 255 * fade)
    surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end

function MODE:HUDPaint()
    if not zb.ROUND_START then return end
    if zb.ROUND_START + 8.5 < CurTime() then return end
     
    local lply = LocalPlayer()
    if not IsValid(lply) or not lply:Alive() then return end
    
    if zb.RemoveFade then zb.RemoveFade() end
    
    local fade = math.Clamp(zb.ROUND_START + 8 - CurTime(), 0, 1)
    local team_ = lply:Team()
    
    if not teams[team_] then return end

    draw.SimpleText("LZbattle| Сельские против Городских", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    local Rolename = teams[team_].name
    local ColorRole = Color(teams[team_].color1.r, teams[team_].color1.g, teams[team_].color1.b, 255 * fade)
    draw.SimpleText("Вы: " .. Rolename, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
 
    local Objective = teams[team_].objective
    local ColorObj = Color(teams[team_].color2.r, teams[team_].color2.g, teams[team_].color2.b, 255 * fade)
    draw.SimpleText(Objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
 
    if hg and hg.PluvTown and hg.PluvTown.Active then
        surface.SetMaterial(hg.PluvTown.PluvMadness)
        surface.SetDrawColor(255, 255, 255, math.random(175, 255) * fade / 2)
        surface.DrawTexturedRect(sw * 0.25, sh * 0.44 - ScreenScale(15), sw / 2, ScreenScale(30))
 
        draw.SimpleText("SOMEWHERE IN PLUVTOWN", "ZB_ScrappersLarge", sw / 2, sh * 0.44 - ScreenScale(2), Color(0, 0, 0, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

  -- Принимаем сигнал о начале раунда BATTLESVSU и включаем музыку
net.Receive("BATTLESVSU_start", function()
   surface.PlaySound("music1.mp3")
end)

local CreateEndMenu

-- Ловим конец раунда BATTLESVSU
net.Receive("BATTLESVSU_roundend", function()
    if CreateEndMenu then CreateEndMenu() end
    chat.AddText(Color(255, 0, 0), "Разъебали всех, съёбуемся.")
end)
 
local colGray = Color(85, 85, 85, 255)
local colRed = Color(130, 10, 10)
local colRedUp = Color(160, 30, 30)
local colSpect1 = Color(75, 75, 75, 255)
local colSpect2 = Color(255, 255, 255)
local col = Color(255, 255, 255, 255)
 
local BlurBackground = hg and hg.DrawBlur or function() end
 
if IsValid(hmcdEndMenu) then
    hmcdEndMenu:Remove()
    hmcdEndMenu = nil
end
 
CreateEndMenu = function()
    if IsValid(hmcdEndMenu) then hmcdEndMenu:Remove() end
    
    surface.PlaySound("ambient/alarms/warningbell1.wav")
 
    local sizeX, sizeY = ScrW() / 2.5, ScrH() / 1.2
    local posX, posY = ScrW() / 1.3 - sizeX / 2, ScrH() / 2 - sizeY / 2
 
    hmcdEndMenu = vgui.Create("ZFrame")
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
        local lengthX, lengthY = surface.GetTextSize("Close")
        surface.SetTextPos(w/2 - lengthX/2, h/2 - lengthY/2)
        surface.DrawText("Close")
    end
 
    hmcdEndMenu.Paint = function(self, w, h)
        BlurBackground(self)
        surface.SetFont("ZB_InterfaceMediumLarge")
        surface.SetTextColor(col.r, col.g, col.b, col.a)
        local lengthX, lengthY = surface.GetTextSize("Players:")
        surface.SetTextPos(w / 2 - lengthX / 2, 20)
        surface.DrawText("Players:")
        surface.SetDrawColor(255, 0, 0, 255)
        surface.DrawOutlinedRect(0, 0, w, h, 2.5)
    end

    local DScrollPanel = vgui.Create("DScrollPanel", hmcdEndMenu)
    DScrollPanel:SetPos(10, 80)
    DScrollPanel:SetSize(sizeX - 20, sizeY - 90)
    function DScrollPanel:Paint(w, h)
        BlurBackground(self)
        surface.SetDrawColor(255, 0, 0, 128)
        surface.DrawOutlinedRect(0, 0, w, h, 2.5)
    end
 
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_SPECTATOR then continue end
        
        local but = vgui.Create("DButton", DScrollPanel)
        but:SetSize(100, 50)
        but:Dock(TOP)
        but:DockMargin(8, 6, 8, -1)
        but:SetText("")
        
        but.Paint = function(self, w, h)
            if not IsValid(ply) then return end
            local col1 = (ply:Alive() and colRed) or colGray
            local col2 = (ply:Alive() and colRedUp) or colSpect1
            
            surface.SetDrawColor(col1.r, col1.g, col1.b, col1.a)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(col2.r, col2.g, col2.b, col2.a)
            surface.DrawRect(0, h / 2, w, h / 2)
 
            local pCol = ply:GetPlayerColor():ToColor()
            surface.SetFont("ZB_InterfaceMediumLarge")
            local pName = ply:Nick() or "He quited..."
            local lengthX, lengthY = surface.GetTextSize(pName)
            
            surface.SetTextColor(0, 0, 0, 255)
            surface.SetTextPos(w / 2 + 1, h / 2 - lengthY / 2 + 1)
            surface.DrawText(pName)
 
            surface.SetTextColor(pCol.r, pCol.g, pCol.b, pCol.a)
            surface.SetTextPos(w / 2, h / 2 - lengthY / 2)
            surface.DrawText(pName)
 
            surface.SetFont("ZB_InterfaceMediumLarge")
            surface.SetTextColor(colSpect2.r, colSpect2.g, colSpect2.b, colSpect2.a)
            local statusText = ply:Name() .. (not ply:Alive() and " - died" or "")
            surface.SetTextPos(15, h / 2 - lengthY / 2)
            surface.DrawText(statusText)
 
            local fragsText = tostring(ply:Frags())
            local fX, fY = surface.GetTextSize(fragsText)
            surface.SetTextPos(w - fX - 15, h / 2 - fY / 2)
            surface.DrawText(fragsText)
        end
 
        function but:DoClick()
            if not IsValid(ply) or ply:IsBot() then chat.AddText(Color(255, 0, 0), "no, you can't") return end
            gui.OpenURL("https://steamcommunity.com" .. ply:SteamID64())
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

MODE.name = "brawl"
local MODE = MODE
local MusicVolume = GetConVar("snd_musicvolume")
local BrawlIntroUntil = 0
local BRAWL_LoopStation
local BRAWL_MeleeMenu
local BRAWL_EndPanel

local ScreenMessageTitle = ""
local ScreenMessageSub = ""
local ScreenMessageUntil = 0

local function StopBrawlMusic(fade)
    if IsValid(BRAWL_LoopStation) then
        if fade then
            local station = BRAWL_LoopStation
            BRAWL_LoopStation = nil
            local vol = station:GetVolume()
            local id = "BrawlMusicFadeOut_" .. tostring(station)
            
            timer.Create(id, 0.1, 25, function()
                if not IsValid(station) then timer.Remove(id) return end
                vol = vol - 0.04
                if vol <= 0 then
                    station:Stop()
                    timer.Remove(id)
                else
                    station:SetVolume(vol)
                end
            end)
        else
            BRAWL_LoopStation:Stop()
            BRAWL_LoopStation = nil
        end
    end
end

local function FormatClock(seconds)
    seconds = math.max(0, math.floor(seconds))
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02i:%02i", mins, secs)
end

surface.CreateFont("Brawl_HUD_Title", { font = "Bahnschrift", size = ScreenScale(11), weight = 700, antialias = true, extended = true })
surface.CreateFont("Brawl_HUD_Main", { font = "Bahnschrift", size = ScreenScale(8), weight = 650, antialias = true, extended = true })
surface.CreateFont("Brawl_HUD_Small", { font = "Bahnschrift", size = ScreenScale(6), weight = 550, antialias = true, extended = true })

local function GetWeaponNiceName(class)
    local wep = weapons.GetStored(class)
    if wep and wep.PrintName and wep.PrintName ~= "" then return wep.PrintName end
    return class
end

local function OpenMeleeMenu(options, pickTime)
    if IsValid(BRAWL_MeleeMenu) then BRAWL_MeleeMenu:Remove() end

    local endTime = CurTime() + (pickTime or 10)

    BRAWL_MeleeMenu = vgui.Create("DFrame")
    BRAWL_MeleeMenu:SetSize(ScrW() * 0.23, ScrH() * 0.28)
    BRAWL_MeleeMenu:Center()
    BRAWL_MeleeMenu:SetTitle("")
    BRAWL_MeleeMenu:MakePopup()
    BRAWL_MeleeMenu:ShowCloseButton(false)

    BRAWL_MeleeMenu.Think = function(self)
        if CurTime() >= endTime then self:Close() end
    end

    BRAWL_MeleeMenu.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(25, 25, 25, 245))
        draw.RoundedBoxEx(8, 0, 0, w, 35, Color(200, 100, 30, 255), true, true, false, false)
        local timeLeft = math.max(0, math.ceil(endTime - CurTime()))
        draw.SimpleText(MODE:L("weapon_pick", timeLeft), "Brawl_HUD_Main", w * 0.5, 17.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local pad = 45
    for _, class in ipairs(options) do
        local btn = vgui.Create("DButton", BRAWL_MeleeMenu)
        btn:Dock(TOP)
        btn:DockMargin(10, pad == 45 and 45 or 8, 10, 0)
        btn:SetTall(46)
        btn:SetText("")

        local title = GetWeaponNiceName(class)
        local sub = class

        btn.Paint = function(self, w, h)
            local hovered = self:IsHovered()
            local bgColor = hovered and Color(220, 120, 40, 255) or Color(45, 45, 45, 240)
            local subColor = hovered and Color(255, 240, 220) or Color(180, 180, 180)

            draw.RoundedBox(6, 0, 0, w, h, bgColor)
            draw.SimpleText(title, "Brawl_HUD_Main", 15, h * 0.35, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(sub, "Brawl_HUD_Small", 15, h * 0.70, subColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        btn.DoClick = function()
            net.Start("brawl_pick_melee")
                net.WriteString(class)
            net.SendToServer()
            if IsValid(BRAWL_MeleeMenu) then BRAWL_MeleeMenu:Close() end
        end
        pad = 0
    end
end

local function OpenEndPanel(isDraw, winnerName)
    if IsValid(BRAWL_EndPanel) then BRAWL_EndPanel:Remove() end

    BRAWL_EndPanel = vgui.Create("DFrame")
    BRAWL_EndPanel:SetSize(ScrW() * 0.3, ScrH() * 0.45)
    BRAWL_EndPanel:Center()
    BRAWL_EndPanel:SetTitle("")
    BRAWL_EndPanel:MakePopup()
    BRAWL_EndPanel:ShowCloseButton(true)

    local playersList = {}
    for _, ply in player.Iterator() do
        if ply:Team() ~= TEAM_SPECTATOR or ply:GetNWInt("BrawlKills", 0) > 0 then
            table.insert(playersList, ply)
        end
    end

    table.sort(playersList, function(a, b)
        return a:GetNWInt("BrawlKills", 0) > b:GetNWInt("BrawlKills", 0)
    end)

    local mvp = playersList[1]
    local mvpName = (IsValid(mvp) and mvp:GetNWInt("BrawlKills", 0) > 0) and mvp:Nick() or MODE:L("nobody")

    BRAWL_EndPanel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(25, 25, 25, 245))
        draw.RoundedBoxEx(8, 0, 0, w, 40, Color(200, 100, 30, 255), true, true, false, false)

        draw.SimpleText(MODE:L("brawl_over"), "Brawl_HUD_Title", w * 0.5, 20, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        if isDraw then
            draw.SimpleText(MODE:L("draw"), "Brawl_HUD_Main", w * 0.5, 60, Color(255, 220, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        else
            draw.SimpleText(MODE:L("winner", winnerName), "Brawl_HUD_Main", w * 0.5, 60, Color(255, 220, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        draw.SimpleText(MODE:L("mvp_hud", mvpName), "Brawl_HUD_Main", w * 0.5, 90, Color(255, 170, 60), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(MODE:L("killboard"), "Brawl_HUD_Small", w * 0.5, 120, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local scroll = vgui.Create("DScrollPanel", BRAWL_EndPanel)
    scroll:SetPos(15, 140)
    scroll:SetSize(BRAWL_EndPanel:GetWide() - 30, BRAWL_EndPanel:GetTall() - 155)

    for i, ply in ipairs(playersList) do
        local pnl = scroll:Add("DPanel")
        pnl:Dock(TOP)
        pnl:DockMargin(0, 0, 0, 5)
        pnl:SetTall(30)
        
        local kills = ply:GetNWInt("BrawlKills", 0)
        local pName = IsValid(ply) and ply:Nick() or MODE:L("unknown")
        
        pnl.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40, 220))
            draw.SimpleText(i .. ". " .. pName, "Brawl_HUD_Small", 10, h/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(kills .. " Kills", "Brawl_HUD_Small", w - 10, h/2, Color(255, 100, 100), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end
end

net.Receive("brawl_roundend", function()
    local isDraw = net.ReadBool()
    local winner = net.ReadString()
    StopBrawlMusic(true)
    OpenEndPanel(isDraw, winner)
end)

net.Receive("brawl_start", function()
    BrawlIntroUntil = CurTime() + 7
    if IsValid(BRAWL_EndPanel) then BRAWL_EndPanel:Remove() end
    if IsValid(BRAWL_MeleeMenu) then BRAWL_MeleeMenu:Remove() end

    StopBrawlMusic(false)

    local path = "sound/" .. (MODE.RoundMusic or "brawl/round_loop.ogg")
    sound.PlayFile(path, "noblock noplay", function(station)
        if not IsValid(station) then return end
        BRAWL_LoopStation = station
        station:SetVolume((MusicVolume and MusicVolume:GetFloat()) or 1)
        station:Play()
    end)
end)

net.Receive("brawl_melee_options", function()
    local count = net.ReadUInt(3)
    local options = {}
    for i = 1, count do options[#options + 1] = net.ReadString() end
    local pickTime = net.ReadUInt(8) 
    OpenMeleeMenu(options, pickTime)
end)

net.Receive("brawl_screen_text", function()
    ScreenMessageTitle = net.ReadString()
    ScreenMessageSub = net.ReadString()
    ScreenMessageUntil = CurTime() + net.ReadFloat()
end)

net.Receive("brawl_berserk_notice", function()
    local holder = net.ReadEntity()
    local holderName = IsValid(holder) and holder:Nick() or MODE:L("unknown")
    
    local titleText = ""
    if IsValid(LocalPlayer()) and holder == LocalPlayer() then
        titleText = MODE:L("berserk_you")
    else
        titleText = MODE:L("berserk_other", holderName)
    end

    ScreenMessageTitle = titleText
    ScreenMessageSub = MODE:L("berserk_sub")
    ScreenMessageUntil = CurTime() + 6
end)

net.Receive("brawl_berserk_died", function()
    local deadNick = net.ReadString()

    ScreenMessageTitle = MODE:L("berserk_dead_title")
    ScreenMessageSub = MODE:L("berserk_dead_sub", deadNick)
    ScreenMessageUntil = CurTime() + 5
end)

function MODE:HUDPaint()
    local lply = LocalPlayer()
    if not IsValid(lply) then return end

    if IsValid(BRAWL_LoopStation) then
        local baseVolume = (MusicVolume and MusicVolume:GetFloat()) or 1
        local isBerserk = lply:GetNWBool("BrawlActiveBerserk", false)
        
        BRAWL_LoopStation:SetVolume(isBerserk and 0 or baseVolume)
    end

    local sw, sh = ScrW(), ScrH()
    local lives = lply:GetNWInt("BrawlLivesLeft", 0)
    local kills = lply:GetNWInt("BrawlKills", 0)
    local alive = GetGlobalInt("BrawlAliveCount", 0)
    local roleDesc = lply:GetNWString("BrawlRoleDesc", MODE:L("role_survivor"))
    
    local roundEnd = GetGlobalFloat("BrawlRoundEnd", 0)
    local isEnded = GetGlobalBool("BrawlEnded", false)
    local timeLeft = 0
    local timerText = MODE:L("waiting")
    
    if roundEnd > 0 then
        if not isEnded then timeLeft = math.max(0, roundEnd - CurTime()) end
        timerText = MODE:L("time_left", FormatClock(timeLeft))
    end

    local hudW = sw * 0.23
    local hudX = sw * 0.02
    local hudY = sh * 0.04
    local mainHudH = sh * 0.165 
    local gap = sh * 0.01 
    
    draw.RoundedBox(8, hudX, hudY, hudW, mainHudH, Color(20, 20, 20, 230))
    draw.RoundedBoxEx(8, hudX, hudY, hudW, sh * 0.006, Color(255, 170, 60, 255), true, true, false, false) 

    local textX = hudX + sw * 0.015
    draw.SimpleText("Brawl", "Brawl_HUD_Title", textX, hudY + sh * 0.015, Color(255, 215, 120), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(MODE:L("lives", lives), "Brawl_HUD_Main", textX, hudY + sh * 0.055, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(MODE:L("kills", kills), "Brawl_HUD_Main", textX, hudY + sh * 0.082, Color(255, 100, 100), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(MODE:L("survivors", alive), "Brawl_HUD_Main", textX, hudY + sh * 0.109, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(timerText, "Brawl_HUD_Main", textX, hudY + sh * 0.136, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local secY = hudY + mainHudH + gap
    local secH = sh * 0.055
    draw.RoundedBox(8, hudX, secY, hudW, secH, Color(20, 20, 20, 210))
    draw.SimpleText(roleDesc, "Brawl_HUD_Small", hudX + (hudW / 2), secY + (secH / 2), Color(240, 240, 240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    if not lply:Alive() and lives > 0 then
        local respawnAt = lply:GetNWFloat("BrawlRespawnAt", 0)
        local respawnLeft = math.max(0, respawnAt - CurTime())

        if respawnLeft > 0 then
            local rW, rH = sw * 0.18, sh * 0.05
            local rX, rY = (sw / 2) - (rW / 2), sh * 0.04
            
            draw.RoundedBox(8, rX, rY, rW, rH, Color(20, 20, 20, 230))
            draw.SimpleText(MODE:L("respawn_in", respawnLeft), "Brawl_HUD_Main", rX + rW * 0.5, rY + rH * 0.5, Color(255, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    if CurTime() < BrawlIntroUntil then
        local fade = math.Clamp(BrawlIntroUntil - CurTime(), 0, 1)
        local alpha = 255 * fade

        draw.SimpleText("ZBattle | Brawl", "Brawl_HUD_Title", sw * 0.5 + 2, sh * 0.11 + 2, Color(0, 0, 0, 150 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(MODE:L("ffa_desc"), "Brawl_HUD_Main", sw * 0.5 + 2, sh * 0.15 + 2, Color(0, 0, 0, 150 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        draw.SimpleText("ZBattle | Brawl", "Brawl_HUD_Title", sw * 0.5, sh * 0.11, Color(255, 210, 120, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(MODE:L("ffa_desc"), "Brawl_HUD_Main", sw * 0.5, sh * 0.15, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(roleDesc, "Brawl_HUD_Small", sw * 0.5, sh * 0.19, Color(220, 220, 220, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    if CurTime() < ScreenMessageUntil then
        local msgFade = math.Clamp(ScreenMessageUntil - CurTime(), 0, 1)
        local msgAlpha = 255 * msgFade
        
        draw.SimpleText(ScreenMessageTitle, "Brawl_HUD_Title", sw * 0.5 + 2, sh * 0.25 + 2, Color(0, 0, 0, 150 * msgFade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(ScreenMessageTitle, "Brawl_HUD_Title", sw * 0.5, sh * 0.25, Color(255, 70, 70, msgAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        draw.SimpleText(ScreenMessageSub, "Brawl_HUD_Main", sw * 0.5 + 2, sh * 0.29 + 2, Color(0, 0, 0, 150 * msgFade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(ScreenMessageSub, "Brawl_HUD_Main", sw * 0.5, sh * 0.29, Color(255, 255, 255, msgAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

local espTargets = {}

hook.Add("PreDrawHalos", "Brawl_WallhackESP", function()
    local round = CurrentRound and CurrentRound() or nil
    if not round or round.name ~= "brawl" then return end
    if GetGlobalBool("BrawlEnded", false) then return end

    local lply = LocalPlayer()
    if not IsValid(lply) or not lply:Alive() then return end

    local isBerserk = lply:GetNWBool("BrawlActiveBerserk", false)
    local is1v1 = GetGlobalInt("BrawlAliveCount", 0) == 2

    if isBerserk or is1v1 then
        table.Empty(espTargets)
        for _, ply in player.Iterator() do
            if ply ~= lply and ply:Alive() and ply:Team() ~= TEAM_SPECTATOR then
                espTargets[#espTargets + 1] = ply
            end
        end

        if #espTargets > 0 then
            local haloColor = isBerserk and Color(255, 50, 50) or Color(255, 170, 60)
            halo.Add(espTargets, haloColor, 2, 2, 1, true, true)
        end
    end
end)

function MODE:RoundStart()
    if IsValid(BRAWL_EndPanel) then BRAWL_EndPanel:Remove() end
    if IsValid(BRAWL_MeleeMenu) then BRAWL_MeleeMenu:Remove() end
    StopBrawlMusic(false)
end
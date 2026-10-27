local PANEL = {}

local current_panel

local red_select = Color(200, 142, 155) -- LZ-City: пастельно-розовый
local tab_color = Color(200, 142, 155) -- LZ-City: пастельно-розовый
local tab_white = Color(245, 242, 243)

DISCORD_URL = "https://discord.gg/863KVzU73t"

surface.CreateFont("ZC_MM_Title", {
    font = "Bahnschrift",
    size = ScreenScale(40),
    weight = 800,
    antialias = true
})

local Pluv = Material("pluv/pluvkid.jpg")

local splashText = {
    "Я ЕБАШУ СОЛЬ ПО УТРАМ",
    "БЛЯТЬ НЕ ЗВОНИТЕ СЮДА",
    "МИЛКИ ВЕРНИ 11 ТЫСЯЧ",
    "БАЦЬКО НАШ БАНДЕРА",
    "ГАНДОНЫ ЕСТЬ?",
    "ВАСЬ",
    "Слушай я ТВОЙ РОТ ЕБАЛ ГАНДОН",
    "СУКА БЛЯТЬ",
    "МАМА Я АДМИН",
    "ГОЛДА НЕ СМЕШНОЙ МЕМ",
    "ТВОЙ РОТ ЕБУТ ПО УТРАМ",
    "БЛЯ МЕНЯ В ЖОПУ ЕБАЛИ",
    "СУКА Я БОГ",
    "ТВАЯ МАМУЛЯ ПУКАЕТ КЕПЧУКОМ",
    "СУКА Я САТАНА ЕБУЧЕГО ГИТЛЕРА"
}

local clr_gray = Color(245, 242, 243, 70)
local clr_verygray = Color(41, 41, 41, 245) -- #292929
local clr_gradient = Color(200, 142, 155, 16)

local function AddRulesLabel(parent, text, font, color, margin)
    local label = vgui.Create("DLabel", parent)

    label:Dock(TOP)
    label:DockMargin(
        margin or ScreenScale(12),
        ScreenScale(4),
        margin or ScreenScale(12),
        ScreenScale(4)
    )

    label:SetFont(font or "ZCity_setiings_fine")
    label:SetTextColor(color or Color(245, 242, 243))
    label:SetText(text)
    label:SetWrap(true)
    label:SetAutoStretchVertical(true)
    label:SetContentAlignment(7)

    return label
end

/*
    Движущиеся клеточки для фона правил.

    Сетка двигается по диагонали.
    Скорость можно изменить через gridSpeed.
*/
local function DrawMovingRulesGrid(w, h)
    surface.SetDrawColor(41, 41, 41, 245)
    surface.DrawRect(0, 0, w, h)

    local cellSize = ScreenScale(32)
    local gridSpeed = ScreenScale(12)

    local time = RealTime()

    local offsetX = (time * gridSpeed) % cellSize
    local offsetY = (time * gridSpeed * 0.65) % cellSize

    surface.SetDrawColor(82, 70, 74, 105)

    -- Вертикальные линии
    for x = -cellSize, w + cellSize, cellSize do
        surface.DrawRect(
            math.floor(x + offsetX),
            0,
            ScreenScale(1),
            h
        )
    end

    -- Горизонтальные линии
    for y = -cellSize, h + cellSize, cellSize do
        surface.DrawRect(
            0,
            math.floor(y + offsetY),
            w,
            ScreenScale(1)
        )
    end

    -- Лёгкая розовая подсветка поверх сетки
    surface.SetDrawColor(200, 142, 155, 24)
    surface.DrawRect(0, 0, ScreenScale(2), h)
end

function hg.DrawRulesMenu(parent)
    if not IsValid(parent) then return end

    parent:SetAlpha(0)

    parent.Paint = function(self, w, h)
        DrawMovingRulesGrid(w, h)
    end

    parent:AlphaTo(255, 0.25, 0)

    local title = vgui.Create("DLabel", parent)

    title:Dock(TOP)
    title:DockMargin(
        ScreenScale(35),
        ScreenScale(25),
        ScreenScale(35),
        ScreenScale(8)
    )

    title:SetFont("ZCity_setiings_category")
    title:SetText("Правила")
    title:SetTextColor(tab_color)
    title:SetContentAlignment(5)
    title:SizeToContents()

    local subtitle = vgui.Create("DLabel", parent)

    subtitle:Dock(TOP)
    subtitle:DockMargin(
        ScreenScale(35),
        0,
        ScreenScale(35),
        ScreenScale(16)
    )

    subtitle:SetFont("ZCity_Tiny")
    subtitle:SetText("Пожалуйста, ознакомьтесь с правилами сервера")
    subtitle:SetTextColor(Color(200, 142, 155))
    subtitle:SetContentAlignment(5)
    subtitle:SizeToContents()

    local scroll = vgui.Create("DScrollPanel", parent)

    scroll:Dock(FILL)
    scroll:DockMargin(
        ScreenScale(35),
        0,
        ScreenScale(35),
        ScreenScale(25)
    )

    local bar = scroll:GetVBar()

    bar:SetWide(ScreenScale(6))
    bar:SetHideButtons(true)

    bar.Paint = function(self, w, h)
        surface.SetDrawColor(32, 32, 32, 190)
        surface.DrawRect(0, 0, w, h)
    end

    bar.btnGrip.Paint = function(self, w, h)
        surface.SetDrawColor(
            self:IsHovered()
                and Color(220, 166, 176)
                or Color(160, 105, 116)
        )

        surface.DrawRect(0, 0, w, h)
    end

    local content = scroll:GetCanvas()

    content:DockPadding(
        0,
        0,
        0,
        ScreenScale(20)
    )

    local rules = {
        {
            title = "1. Общие правила",

            text = [[
1.1. Уважайте других игроков и администрацию сервера.

1.2. Оскорбление родителей является наказанием

1.3. Запрещено использовать читы, дудос сервера

1.4. Запрещено намеренно использовать ошибки и баги сервера.

]]
        },

        {
            title = "2. Правила игрового процесса",

            text = [[
2.1. Соблюдайте правила выбранного игрового режима.

2.2. Убивать без причины нельзя (максимум можно 3 раза).

2.3. Не используйте информацию, полученную вне игры.

2.4. Запрещено намеренно портить раунд союзникам или другим игрокам.

2.5. Не злоупотребляйте голосовым и текстовым чатом.
]]
        },

        {
            title = "3. Запрещено",

            text = [[
3.1. RDM — убийство игрока без игровой причины.

3.2. Mass RDM — массовые убийства без причины.

3.3. Prop abuse — использование объектов карты для получения нечестного преимущества.

3.4. Намеренная задержка окончания раунда.
]]
        },

        {
            title = "4. Администрация",

            text = [[
4.1. Незнание правил не освобождает от ответственности.

4.2. Администрация может наказать игрока за нарушение правил.

4.3. Запрещено спорить с администрацией во время игрового процесса.

4.4. Если вы считаете наказание ошибочным, обратитесь к администрации после раунда
]]
        },

        {
            title = "5. Важно",

            text = [[
Играя на сервере, вы соглашаетесь с этими правилами.
]]
        }
    }

    for _, rule in ipairs(rules) do
        AddRulesLabel(
            content,
            rule.title,
            "ZCity_setiings_category",
            tab_color,
            ScreenScale(15)
        )

        AddRulesLabel(content, rule.text)
    end
end

local Selects = {
    {
        Title = "Отключиться",

        Func = function(luaMenu)
            RunConsoleCommand("disconnect")
        end
    },

    {
        Title = "Главное меню",

        Func = function(luaMenu)
            gui.ActivateGameUI()
            luaMenu:Close()
        end
    },

    {
        Title = "Дискорд",

        Func = function(luaMenu)
            luaMenu:Close()
            gui.OpenURL(DISCORD_URL)
        end
    },

    {
        Title = "Правила",

        Func = function(luaMenu, parent)
            hg.DrawRulesMenu(parent)
        end
    },

    {
        Title = "Роли убийцы",
        GamemodeOnly = true,

        CreatedFunc = function(self, parent, luaMenu)
            local soe = vgui.Create("DLabel", self)

            soe:SetText("SOE")
            soe:SetMouseInputEnabled(true)
            soe:SetFont("ZCity_Small")
            soe:SetTall(ScreenScale(15))
            soe:Dock(BOTTOM)
            soe:DockMargin(ScreenScale(20), ScreenScale(10), 0, 0)
            soe:SetTextColor(color_white)
            soe:SizeToContents()

            soe.RColor = Color(225, 225, 225, 0)
            soe.WColor = Color(225, 225, 225, 255)
            soe.x = soe:GetX()

            function soe:DoClick()
                luaMenu:Close()
                hg.SelectPlayerRole(nil, "soe")
            end

            local parentButton = self

            function soe:Think()
                self.HoverLerp = parentButton.HoverLerp

                self.HoverLerp2 = LerpFT(
                    0.2,
                    self.HoverLerp2 or 0,
                    self:IsHovered() and 1 or 0
                )

                self:SetTextColor(
                    self.RColor:Lerp(
                        self.WColor:Lerp(red_select, self.HoverLerp2),
                        self.HoverLerp
                    )
                )

                self:SetX(
                    self.x +
                    ScreenScaleH(40) +
                    self.HoverLerp * ScreenScaleH(50)
                )
            end

            local standard = vgui.Create("DLabel", soe)

            standard:SetText("STD")
            standard:SetMouseInputEnabled(true)
            standard:SetFont("ZCity_Small")
            standard:SetTall(ScreenScale(15))
            standard:Dock(BOTTOM)
            standard:DockMargin(0, ScreenScale(2), 0, 0)
            standard:SetTextColor(color_white)
            standard:SizeToContents()

            standard.RColor = Color(225, 225, 225, 0)
            standard.WColor = Color(225, 225, 225, 255)
            standard.x = standard:GetX()

            function standard:DoClick()
                luaMenu:Close()
                hg.SelectPlayerRole(nil, "standard")
            end

            function standard:Think()
                self.HoverLerp = parentButton.HoverLerp

                self.HoverLerp2 = LerpFT(
                    0.2,
                    self.HoverLerp2 or 0,
                    self:IsHovered() and 1 or 0
                )

                self:SetTextColor(
                    self.RColor:Lerp(
                        self.WColor:Lerp(red_select, self.HoverLerp2),
                        self.HoverLerp
                    )
                )

                self:SetX(self.x + ScreenScaleH(35))
            end
        end,

        Func = function(luaMenu)
        end
    },

    {
        Title = "Достижения",

        Func = function(luaMenu, parent)
            hg.DrawAchievmentsMenu(parent)
        end
    },

    {
        Title = "Настройки",

        Func = function(luaMenu, parent)
            hg.DrawSettings(parent)
        end
    },

    {
        Title = "Одежда",

        Func = function(luaMenu, parent)
            hg.CreateApperanceMenu(parent)
        end
    },

    {
        Title = "Вернуться",

        Func = function(luaMenu)
            luaMenu:Close()
        end
    }
}

function PANEL:InitializeMarkup()
    local mapname = game.GetMap()
    local prefix = string.find(mapname, "_")

    if prefix then
        mapname = string.sub(mapname, prefix + 1)
    end

    local gm =
        splashText[math.random(#splashText)]
        .. " | "
        .. string.NiceName(mapname)

    local title =
        "<font=ZC_MM_Title>" ..
        "<colour=200,142,155>LZ</colour>" ..
        "<colour=245,242,243> - City</colour>" ..
        "</font>\n" ..
        "<font=ZCity_Tiny>" ..
        "<colour=170,160,163>" ..
        gm ..
        "</colour>" ..
        "</font>"

    if hg.PluvTown.Active then
        self.SelectedPluv = table.Random(hg.PluvTown.PluvMats)
    end

    return markup.Parse(title)
end

-- ===== Музыка в ESC-меню (случайный плейлист) =====
local MENU_MUSIC_VOLUME = 0.5

local MenuMusicTracks = {
    { path = "sound/lmz/menu_music.mp3",         name = "Menu Theme" },
    { path = "sound/lmz/intro.mp3",              name = "Intro" },
    { path = "sound/lmz/field_of_memories.mp3",  name = "Field of Memories" },
    { path = "sound/lmz/defense_waves.mp3",      name = "Defense Waves" },
}

local MenuMusicStation
local MenuMusicLoading = false
local MenuMusicWanted = false
local MenuMusicStarted = false -- трек реально начинал играть (нужно для автопереключения)
local MenuMusicPos = 0
local MenuMusicLoadId = 0
local MenuMusicIndex = 0       -- 0 = трек ещё не выбран
local MenuMusicHistory = {}    -- прошлые треки для кнопки «назад»

print("[LMZ] Плейлист меню загружен, треков: " .. #MenuMusicTracks)

local function MenuMusicEnabled()
    return cookie.GetString("lmz_menu_music", "1") == "1"
end

-- Пауза (а не Stop), чтобы музыка продолжилась с того же места
local function PauseMenuMusic()
    MenuMusicWanted = false

    if IsValid(MenuMusicStation) then
        MenuMusicPos = MenuMusicStation:GetTime()
        MenuMusicStation:Pause()
    end
end

local function LoadMenuTrack(startPos)
    local track = MenuMusicTracks[MenuMusicIndex]
    if not track then return end

    -- каждый запрос загрузки получает свой номер: если игрок быстро жмёт
    -- кнопки, старые загрузки будут проигнорированы
    MenuMusicLoadId = MenuMusicLoadId + 1
    local loadId = MenuMusicLoadId

    if IsValid(MenuMusicStation) then
        MenuMusicStation:Stop()
    end

    MenuMusicStation = nil
    MenuMusicStarted = false
    MenuMusicLoading = true

    sound.PlayFile(track.path, "noblock noplay", function(station, errCode, errStr)
        if loadId ~= MenuMusicLoadId then
            if IsValid(station) then station:Stop() end
            return
        end

        MenuMusicLoading = false

        if not IsValid(station) then
            print("[LMZ] Не удалось запустить музыку меню:", track.path, errCode, errStr)
            return
        end

        station:SetVolume(MENU_MUSIC_VOLUME)

        if startPos and startPos > 0 then
            station:SetTime(startPos)
        end

        MenuMusicStation = station

        -- если меню успели закрыть, пока файл грузился — остаёмся на паузе
        if MenuMusicWanted then
            MenuMusicStarted = true
            station:Play()
        end
    end)
end

-- Случайный трек, не равный текущему
local function PickRandomTrack()
    local count = #MenuMusicTracks

    if count <= 1 then return 1 end

    local index

    repeat
        index = math.random(count)
    until index ~= MenuMusicIndex

    return index
end

local function PlayMenuTrack(index, pushHistory)
    if pushHistory and MenuMusicIndex > 0 then
        MenuMusicHistory[#MenuMusicHistory + 1] = MenuMusicIndex

        if #MenuMusicHistory > 20 then
            table.remove(MenuMusicHistory, 1)
        end
    end

    MenuMusicIndex = index
    MenuMusicPos = 0
    MenuMusicWanted = true

    LoadMenuTrack(0)
end

local function PlayRandomMenuTrack()
    PlayMenuTrack(PickRandomTrack(), true)
end

-- «Назад» возвращает к предыдущему треку, а если истории нет — к случайному
local function PlayPreviousMenuTrack()
    local previous = table.remove(MenuMusicHistory)

    PlayMenuTrack(previous or PickRandomTrack(), false)
end

-- Продолжить с места паузы (кнопка «Музыка: ВКЛ»)
local function StartMenuMusic()
    MenuMusicWanted = true

    if MenuMusicIndex == 0 then
        PlayRandomMenuTrack()
        return
    end

    -- трек уже загружен: просто продолжаем
    if IsValid(MenuMusicStation) then
        MenuMusicStarted = true
        MenuMusicStation:Play()
        return
    end

    if MenuMusicLoading then return end

    LoadMenuTrack(MenuMusicPos)
end

-- Когда трек доиграл до конца — включаем другой случайный
timer.Create("LMZ_MenuMusicAutoNext", 0.5, 0, function()
    if not MenuMusicWanted or MenuMusicLoading or not MenuMusicStarted then return end
    if not IsValid(MenuMusicStation) then return end

    if MenuMusicStation:GetState() == GMOD_CHANNEL_STOPPED then
        PlayRandomMenuTrack()
    end
end)

-- Треугольник для кнопок «назад» / «вперёд» (dir = -1 или 1)
local function DrawMusicArrow(x, y, size, dir, color)
    local h = size / 2

    surface.SetDrawColor(color.r, color.g, color.b, color.a or 255)
    draw.NoTexture()

    if dir > 0 then
        surface.DrawPoly({
            { x = x - h, y = y - h },
            { x = x + h, y = y },
            { x = x - h, y = y + h },
        })
    else
        surface.DrawPoly({
            { x = x + h, y = y - h },
            { x = x + h, y = y + h },
            { x = x - h, y = y },
        })
    end
end

function PANEL:Init()
    self:SetAlpha(0)
    self:SetSize(ScrW(), ScrH())
    self:Center()
    self:SetTitle("")
    self:SetDraggable(false)
    self:SetBorder(false)
    self:SetColorBG(clr_verygray)
    self:ShowCloseButton(false)

    current_panel = nil

    self.Title, self.TitleShadow = self:InitializeMarkup()

    timer.Simple(0, function()
        if IsValid(self) and self.First then
            self:First()
        end
    end)

    self.lDock = vgui.Create("DPanel", self)

    local lDock = self.lDock

    lDock:Dock(LEFT)
    lDock:SetSize(ScrW() / 4)

    lDock:DockMargin(
        ScreenScale(0),
        ScreenScaleH(90),
        ScreenScale(10),
        ScreenScaleH(90)
    )

    lDock.Paint = function(this, w, h)
        if hg.PluvTown.Active then
            surface.SetDrawColor(color_white)
            surface.SetMaterial(self.SelectedPluv or Pluv)

            surface.DrawTexturedRect(
                0,
                ScreenScale(27),
                ScreenScale(35),
                ScreenScale(27)
            )
        end

        self.Title:Draw(
            ScreenScale(15),
            ScreenScale(50),
            TEXT_ALIGN_LEFT,
            TEXT_ALIGN_CENTER,
            255,
            TEXT_ALIGN_LEFT
        )
    end

    self.Buttons = {}

    for _, data in ipairs(Selects) do
        if data.GamemodeOnly
        and engine.ActiveGamemode() ~= "zcity" then
            continue
        end

        self:AddSelect(lDock, data.Title, data)
    end

    local bottomDock = vgui.Create("DPanel", self)

    bottomDock:SetPos(
        ScreenScale(1),
        ScrH() - ScrH() / 10
    )

    bottomDock:SetSize(
        ScreenScale(190),
        ScreenScaleH(40)
    )

    bottomDock.Paint = function()
    end

    self.panelparrent = vgui.Create("DPanel", self)

    self.panelparrent:SetPos(
        bottomDock:GetWide() + bottomDock:GetX(),
        0
    )

    self.panelparrent:SetSize(
        ScrW() - bottomDock:GetWide(),
        ScrH()
    )

    self.panelparrent.Paint = function()
    end

    local git = vgui.Create("DLabel", bottomDock)

    git:Dock(BOTTOM)
    git:DockMargin(ScreenScale(10), 0, 0, 0)
    git:SetFont("ZCity_Tiny")
    git:SetTextColor(clr_gray)

    git:SetText(
        "GitHub: github.com/sergeaio-web/lmz-city"
        .. hg.GitHub_ReposOwner
        .. "/"
        .. hg.GitHub_ReposName
    )

    git:SetContentAlignment(4)
    git:SetMouseInputEnabled(true)
    git:SizeToContents()

    function git:DoClick()
        gui.OpenURL(
            "https://github.com/sergeaio-web/lmz-city"
            .. hg.GitHub_ReposOwner
            .. "/"
            .. hg.GitHub_ReposName
        )
    end

    local version = vgui.Create("DLabel", bottomDock)

    version:Dock(BOTTOM)
    version:DockMargin(ScreenScale(10), 0, 0, 0)
    version:SetFont("ZCity_Tiny")
    version:SetTextColor(clr_gray)
    version:SetText(hg.Version)
    version:SetContentAlignment(4)
    version:SizeToContents()

    local authors = vgui.Create("DLabel", bottomDock)

    authors:Dock(BOTTOM)
    authors:DockMargin(ScreenScale(10), 0, 0, 0)
    authors:SetFont("ZCity_Tiny")
    authors:SetTextColor(clr_gray)

    authors:SetText(
        "Авторы: L M Z, Человек Яйца"
    )

    authors:SetContentAlignment(4)
    authors:SizeToContents()

    -- Кнопка музыки (слева внизу)
    local btnW, btnH = ScreenScale(62), ScreenScaleH(14)

    local musicBtn = vgui.Create("DButton", self)
    musicBtn:SetSize(btnW, btnH)
    musicBtn:SetPos(
        ScreenScale(11),
        ScrH() - ScrH() / 10 - btnH - ScreenScaleH(6)
    )
    musicBtn:SetText("")
    musicBtn:SetCursor("hand")

    musicBtn.Paint = function(this, w, h)
        local on = MenuMusicEnabled()
        local hov = this:IsHovered()

        surface.SetDrawColor(0, 0, 0, hov and 140 or 90)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(red_select.r, red_select.g, red_select.b, hov and 255 or 140)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        draw.SimpleText(
            on and "Музыка: ВКЛ" or "Музыка: ВЫКЛ",
            "ZCity_Tiny",
            w / 2,
            h / 2,
            on and tab_white or clr_gray,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end

    musicBtn.DoClick = function()
        if MenuMusicEnabled() then
            cookie.Set("lmz_menu_music", "0")
            PauseMenuMusic()
        else
            cookie.Set("lmz_menu_music", "1")
            StartMenuMusic()
        end
    end

    -- Кнопки переключения треков: назад / вперёд (в pcall, чтобы ошибка
    -- в плеере не ломала всё меню — текст ошибки попадёт в консоль)
    local ok, err = pcall(function()
        local gap = ScreenScale(2)
        local rowY = musicBtn:GetY()

        local function CreateTrackButton(x, dir)
            local btn = vgui.Create("DButton", self)
            btn:SetSize(btnH, btnH)
            btn:SetPos(x, rowY)
            btn:SetText("")
            btn:SetCursor("hand")

            btn.Paint = function(this, w, h)
                local hov = this:IsHovered()

                surface.SetDrawColor(0, 0, 0, hov and 140 or 90)
                surface.DrawRect(0, 0, w, h)

                surface.SetDrawColor(red_select.r, red_select.g, red_select.b, hov and 255 or 140)
                surface.DrawOutlinedRect(0, 0, w, h, 1)

                DrawMusicArrow(w / 2, h / 2, h * 0.38, dir, hov and tab_white or clr_gray)
            end

            btn.DoClick = function()
                cookie.Set("lmz_menu_music", "1")

                if dir > 0 then
                    PlayRandomMenuTrack()
                else
                    PlayPreviousMenuTrack()
                end
            end

            return btn
        end

        local prevX = musicBtn:GetX() + btnW + gap
        local nextX = prevX + btnH + gap

        CreateTrackButton(prevX, -1)
        CreateTrackButton(nextX, 1)

        -- Название текущего трека
        local nameLabel = vgui.Create("DPanel", self)
        nameLabel:SetPos(nextX + btnH + gap * 3, rowY)
        nameLabel:SetSize(ScreenScale(95), btnH)
        nameLabel:SetMouseInputEnabled(false)

        nameLabel.Paint = function(this, w, h)
            local track = MenuMusicTracks[MenuMusicIndex]
            if not track then return end

            draw.SimpleText(
                track.name,
                "ZCity_Tiny",
                0,
                h / 2,
                tab_white,
                TEXT_ALIGN_LEFT,
                TEXT_ALIGN_CENTER
            )
        end
    end)

    if not ok then
        print("[LMZ] Ошибка в кнопках плеера меню:", err)
    end

    -- при каждом открытии меню — случайный трек
    if MenuMusicEnabled() then
        PlayRandomMenuTrack()
    end
end

function PANEL:OnRemove()
    PauseMenuMusic()
end

function PANEL:First()
    self:AlphaTo(255, 0.1, 0, nil)
end

local gradient_d = surface.GetTextureID("vgui/gradient-d")
local gradient_l = surface.GetTextureID("vgui/gradient-l")

function PANEL:Paint(w, h)
    draw.RoundedBox(
        0,
        0,
        0,
        w,
        h,
        self.ColorBG
    )

    hg.DrawBlur(self, 5)

    surface.SetDrawColor(self.ColorBG)
    surface.SetTexture(gradient_l)
    surface.DrawTexturedRect(0, 0, w, h)

    surface.SetDrawColor(clr_gradient)
    surface.SetTexture(gradient_d)
    surface.DrawTexturedRect(0, 0, w, h)
end

function PANEL:AddSelect(parent, title, data)
    local id = #self.Buttons + 1

    self.Buttons[id] = vgui.Create("DLabel", parent)

    local button = self.Buttons[id]

    button:SetText("")
    button:SetMouseInputEnabled(true)
    button:SetFont("ZCity_Small")
    button:SetTall(ScreenScale(15))

    button:Dock(BOTTOM)

    button:DockMargin(
        ScreenScale(15),
        ScreenScale(1.5),
        0,
        0
    )

    button.Func = data.Func
    button.HoveredFunc = data.HoveredFunc

    button.RColor = tab_color
    button.WhiteColor = tab_white

    -- Свой узор и скорость для каждой вкладки
    button.Pattern = id % 5
    button.AnimationSpeed = 1.5 + id * 0.08
    button.AnimationOffset = id * 0.75

    local luaMenu = self

    if data.CreatedFunc then
        data.CreatedFunc(button, self, luaMenu)
    end

    function button:GetCharacterGlow(index, count)
        local time = RealTime() * self.AnimationSpeed
        local phase = time + self.AnimationOffset
        local position = index / math.max(count, 1)

        local glow = 0

        if self.Pattern == 1 then
            -- Волна слева направо
            glow = math.sin(phase - position * 8) * 0.5 + 0.5

        elseif self.Pattern == 2 then
            -- Волна от центра к краям
            local distance = math.abs(position - 0.5)
            glow = math.sin(phase - distance * 12) * 0.5 + 0.5

        elseif self.Pattern == 3 then
            -- Перекрёстный узор
            local waveA = math.sin(phase - position * 12)
            local waveB = math.sin(phase + position * 12)

            glow = math.abs(waveA + waveB) / 2

        elseif self.Pattern == 4 then
            -- Шахматный узор
            local checker = (index % 2 == 0)
                and 0
                or math.pi

            glow = math.sin(
                phase * 1.2 + checker
            ) * 0.5 + 0.5

        elseif self.Pattern == 5 then
            -- Две волны навстречу
            local leftWave = math.sin(
                phase - position * 18
            )

            local rightWave = math.sin(
                phase + position * 18
            )

            glow = (
                leftWave +
                rightWave +
                2
            ) / 4
        end

        glow = math.Clamp(glow, 0, 1)

        -- Плавное сглаживание
        glow = glow * glow * (3 - 2 * glow)

        if self:IsHovered() then
            glow = math.Clamp(glow + 0.18, 0, 1)
        end

        return glow
    end

    function button:DoClick()
        local panelName = string.lower(title)

        if current_panel == panelName then
            for i = 1, 3 do
                surface.PlaySound("shitty/tap_release.wav")
            end

            luaMenu.panelparrent:AlphaTo(
                0,
                0.2,
                0,
                function()
                    if IsValid(luaMenu.panelparrent) then
                        luaMenu.panelparrent:Remove()
                    end

                    luaMenu.panelparrent = vgui.Create(
                        "DPanel",
                        luaMenu
                    )

                    luaMenu.panelparrent:SetPos(
                        some_coordinates_x,
                        0
                    )

                    luaMenu.panelparrent:SetSize(
                        some_size_x,
                        some_size_y
                    )

                    luaMenu.panelparrent.Paint = function()
                    end

                    current_panel = nil
                end
            )

            return
        end

        some_size_x = luaMenu.panelparrent:GetWide()
        some_size_y = luaMenu.panelparrent:GetTall()
        some_coordinates_x = luaMenu.panelparrent:GetX()

        luaMenu.panelparrent:AlphaTo(
            0,
            0.2,
            0,
            function()
                if IsValid(luaMenu.panelparrent) then
                    luaMenu.panelparrent:Remove()
                end

                luaMenu.panelparrent = vgui.Create(
                    "DPanel",
                    luaMenu
                )

                luaMenu.panelparrent:SetPos(
                    some_coordinates_x,
                    0
                )

                luaMenu.panelparrent:SetSize(
                    some_size_x,
                    some_size_y
                )

                luaMenu.panelparrent.Paint = function()
                end

                if button.Func then
                    button.Func(
                        luaMenu,
                        luaMenu.panelparrent
                    )
                end

                current_panel = panelName
            end
        )

        for i = 1, 3 do
            surface.PlaySound("shitty/tap_depress.wav")
        end
    end

    button.Paint = function(self, w, h)
        local text = title

        if self:IsHovered() then
            text = string.upper(text)
        end

        if current_panel == string.lower(title)
        and title ~= "Роли убийцы" then
            text = "[ " .. string.upper(title) .. " ]"
        end

        local length = utf8.len(text) or #text
        local x = 0

        surface.SetFont("ZCity_Small")

        for i = 1, length do
            local char = utf8.sub(text, i, i)
            local charWidth = surface.GetTextSize(char)

            local glow = self:GetCharacterGlow(
                i,
                length
            )

            local charColor = self.RColor:Lerp(
                self.WhiteColor,
                glow
            )

            draw.SimpleText(
                char,
                "ZCity_Small",
                x,
                h / 2,
                charColor,
                TEXT_ALIGN_LEFT,
                TEXT_ALIGN_CENTER
            )

            x = x + charWidth
        end
    end

    button.Think = function(self)
        local hovered = self:IsHovered()

        if not hovered and IsValid(self:GetChild(0)) then
            hovered = self:GetChild(0):IsHovered()
        end

        self.HoverLerp = LerpFT(
            0.2,
            self.HoverLerp or 0,
            hovered and 1 or 0
        )

        self:InvalidateLayout(true)
    end
end

function PANEL:Close()
    PauseMenuMusic()

    self:AlphaTo(
        0,
        0.1,
        0,
        function()
            self:Remove()
        end
    )

    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)
end

vgui.Register("ZMainMenu", PANEL, "ZFrame")

hook.Add("OnPauseMenuShow", "OpenMainMenu", function()
    local run = hook.Run("OnShowZCityPause")

    if run ~= nil then
        return run
    end

    if MainMenu and IsValid(MainMenu) then
        MainMenu:Close()
        MainMenu = nil

        return false
    end

    MainMenu = vgui.Create("ZMainMenu")
    MainMenu:MakePopup()

    return false
end)


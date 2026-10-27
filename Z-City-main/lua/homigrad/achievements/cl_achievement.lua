if SERVER then return end

hg.achievements = hg.achievements or {}
hg.achievements.achievements_data =
    hg.achievements.achievements_data or {}

hg.achievements.achievements_data.player_achievements =
    hg.achievements.achievements_data.player_achievements or {}

hg.achievements.achievements_data.created_achevements = {}

hg.achievements.MenuPanel =
    hg.achievements.MenuPanel or nil

local curent_panel_ach

concommand.Add("hg_achievements", function()
    print("use esc menu")
end)

BlurBackground = BlurBackground or hg.DrawBlur

local gradient_u = Material("vgui/gradient-u")
local gradient_d = Material("vgui/gradient-d")
local gradient_r = Material("vgui/gradient-r")
local gradient_l = Material("vgui/gradient-l")

local achievementTheme = {
    background = Color(41, 41, 41, 255),       -- #292929
    backgroundSoft = Color(34, 34, 34, 248),

    white = Color(246, 242, 243, 255),
    whiteSoft = Color(211, 197, 201, 235),

    pink = Color(200, 142, 155, 255),          -- #C88E9B
    pinkSoft = Color(160, 103, 117, 180),
    pinkDark = Color(65, 43, 47, 240),

    card = Color(47, 43, 44, 245),
    cardHover = Color(67, 48, 52, 248),
    cardSelected = Color(83, 55, 60, 250),

    border = Color(126, 87, 96, 220),
    borderBright = Color(200, 142, 155, 255),

    description = Color(207, 191, 195, 235)
}

local function LerpColor(progress, first, second)
    return first:Lerp(
        second,
        math.Clamp(progress, 0, 1)
    )
end

local function DrawAchievementBackground(w, h)
    -- Основной графитовый фон LZ-City (#292929)
    surface.SetDrawColor(
        achievementTheme.background.r,
        achievementTheme.background.g,
        achievementTheme.background.b,
        achievementTheme.background.a
    )
    surface.DrawRect(0, 0, w, h)

    -- Символы падают вертикальными потоками, как в Matrix.
    -- Цвета адаптированы к графитовому и пастельно-розовому стилю LZ-City.
    local characters = {
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J",
        "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T",
        "U", "V", "W", "X", "Y", "Z", "+", "-", "=", "/", "\\"
    }

    local cellW = math.max(10, ScreenScale(9))
    local cellH = math.max(12, ScreenScale(10))
    local columnCount = math.ceil(w / cellW) + 1
    local time = RealTime()

    surface.SetFont("ZCity_Tiny")

    for column = 0, columnCount do
        -- Разная длина хвостов и скорость делают потоки неодинаковыми.
        local trailLength = 8 + ((column * 7) % 12)
        local speed = cellH * (0.75 + ((column * 3) % 9) * 0.18)
        local cycleHeight = h + trailLength * cellH
        local phase = (column * 97) % cycleHeight
        local headY = (time * speed + phase) % cycleHeight
            - trailLength * cellH

        -- Меняем символы с ограниченной частотой, а не каждый кадр.
        local characterTick = math.floor(time * (4 + (column % 5)))

        for trail = 0, trailLength do
            local y = headY - trail * cellH

            if y >= -cellH and y <= h + cellH then
                local characterIndex = (
                    characterTick + column * 3 + trail * 7
                ) % #characters + 1

                local character = characters[characterIndex]
                local brightness = 1 - trail / trailLength

                -- Самая нижняя / ведущая буква светлее, хвост затухает.
                local color = achievementTheme.pink:Lerp(
                    achievementTheme.white,
                    brightness
                )

                local alpha = 14 + brightness * 190

                draw.SimpleText(
                    character,
                    "ZCity_Tiny",
                    column * cellW,
                    y,
                    Color(color.r, color.g, color.b, alpha),
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
            end
        end
    end
end


local function DrawAnimatedText(
    text,
    font,
    x,
    y,
    alignX,
    alignY,
    seed,
    selected
)
    text = tostring(text or "")

    surface.SetFont(font)

    local totalWidth = surface.GetTextSize(text)
    local startX = x

    if alignX == TEXT_ALIGN_CENTER then
        startX = x - totalWidth / 2
    elseif alignX == TEXT_ALIGN_RIGHT then
        startX = x - totalWidth
    end

    local cursorX = startX
    local time = RealTime()

    for index = 1, #text do
        local character = text:sub(index, index)
        local characterWidth = surface.GetTextSize(character)

        local wave = math.sin(
            time * 2.2
            + seed
            + index * 0.42
        ) * 0.5 + 0.5

        wave = wave * wave * (3 - 2 * wave)

        if selected then
            wave = math.Clamp(wave + 0.18, 0, 1)
        end

        local textColor = LerpColor(
            wave,
            achievementTheme.pink,
            achievementTheme.white
        )

        local characterY = y

        if selected then
            characterY = y - math.sin(
                time * 3
                + seed
                + index * 0.3
            ) * ScreenScale(0.3)
        end

        draw.SimpleText(
            character,
            font,
            cursorX,
            characterY,
            textColor,
            TEXT_ALIGN_LEFT,
            alignY
        )

        cursorX = cursorX + characterWidth
    end
end

local function PaintAchievementCard(
    self,
    w,
    h,
    achievement,
    localAchievements
)
    local selected = curent_panel_ach == achievement
    local target = self:IsHovered() and 1 or 0

    if selected then
        target = 1
    end

    self.HoverLerp = Lerp(
        FrameTime() * 8,
        self.HoverLerp or 0,
        target
    )

    local progress = self.HoverLerp

    local cardColor

    if selected then
        cardColor = achievementTheme.card:Lerp(
            achievementTheme.cardSelected,
            progress
        )
    else
        cardColor = achievementTheme.card:Lerp(
            achievementTheme.cardHover,
            progress
        )
    end

    surface.SetDrawColor(
        cardColor.r,
        cardColor.g,
        cardColor.b,
        cardColor.a
    )

    surface.DrawRect(0, 0, w, h)

    local borderColor = achievementTheme.border:Lerp(
        achievementTheme.borderBright,
        progress
    )

    surface.SetDrawColor(
        borderColor.r,
        borderColor.g,
        borderColor.b,
        borderColor.a
    )

    surface.DrawOutlinedRect(0, 0, w, h, 1)

    surface.SetDrawColor(
        achievementTheme.pink.r,
        achievementTheme.pink.g,
        achievementTheme.pink.b,
        70 + progress * 130
    )

    surface.DrawRect(
        0,
        h - ScreenScale(2),
        w,
        ScreenScale(2)
    )

    local value =
        localAchievements[achievement.key]
        and localAchievements[achievement.key].value
        or achievement.start_value

    local title = achievement.name or ""

    if achievement.showpercent then
        title = title
            .. " | "
            .. math.Round(
                value / achievement.needed_value * 100,
                1
            )
            .. "%"
    end

    DrawAnimatedText(
        title,
        "HomigradFont",
        ScreenScale(3),
        h / 2,
        TEXT_ALIGN_LEFT,
        TEXT_ALIGN_CENTER,
        self.AnimationSeed or 1,
        selected
    )

    if selected and achievement.description then
        DrawAnimatedText(
            achievement.description,
            "ZCity_Tiny",
            ScreenScale(3),
            h - ScreenScale(3),
            TEXT_ALIGN_LEFT,
            TEXT_ALIGN_BOTTOM,
            (self.AnimationSeed or 1) + 10,
            true
        )
    end

    local shineWidth = ScreenScale(28)

    local shineX = (
        RealTime() * ScreenScale(75)
        + (self.ShineOffset or 0)
    ) % (w + shineWidth) - shineWidth

    surface.SetDrawColor(
        255,
        220,
        240,
        12 + progress * 20
    )

    surface.DrawRect(
        shineX,
        0,
        shineWidth,
        h
    )
end

local function PaintButton(self, w, h)
    local progress = self:IsHovered() and 1 or 0

    local color = achievementTheme.card:Lerp(
        achievementTheme.cardHover,
        progress
    )

    surface.SetDrawColor(
        color.r,
        color.g,
        color.b,
        color.a
    )

    surface.DrawRect(0, 0, w, h)

    surface.SetDrawColor(
        achievementTheme.pink.r,
        achievementTheme.pink.g,
        achievementTheme.pink.b,
        80 + progress * 100
    )

    surface.DrawRect(
        0,
        h - ScreenScale(2),
        w,
        ScreenScale(2)
    )
end

local function createButton(frame, ach, text, func)
    local button = vgui.Create(
        "DButton",
        frame
    )

    ach.img = isstring(ach.img)
        and Material(ach.img)
        or ach.img

    local localach =
        hg.achievements.GetLocalAchievements()
        or {}

    local desc = markup.Parse(
        "<font=HomigradFontMedium>"
        .. ach.description
        .. "<font>",
        500
    )

    function button:Paint(w, h)
        PaintButton(self, w, h)

        local value =
            localach[ach.key]
            and localach[ach.key].value
            or ach.start_value

        local title = ach.name

        if ach.showpercent then
            title = title
                .. " | "
                .. math.Round(
                    value / ach.needed_value * 100,
                    1
                )
                .. "%"
        end

        DrawAnimatedText(
            title,
            "HomigradFont",
            w / 2,
            h / 2,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER,
            self.AnimationSeed or 1,
            self:IsHovered()
        )

        if self:IsHovered() then
            desc:Draw(
                w / 2,
                h - ScreenScale(4),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_BOTTOM
            )
        end
    end

    button:SetText("")
    button:SetSize(
        0,
        ScreenScale(22)
    )

    button:Dock(TOP)
    button:DockMargin(
        0,
        0,
        0,
        ScreenScale(2.5)
    )

    button.AnimationSeed = math.random(1, 10000)
    button.ShineOffset = math.random(0, 1000)

    button.DoClick = function(self)
        if func then
            func(self)
        end
    end

    return button
end

local function createButton_2(
    frame,
    ach,
    text,
    func,
    y
)
    local button = vgui.Create(
        "DButton",
        frame
    )

    ach.img = isstring(ach.img)
        and Material(ach.img)
        or ach.img

    button:SetText("")

    -- Исходное расположение сохраняется.
    button:SetSize(
        frame:GetWide(),
        ScreenScale(22)
    )

    button:SetPos(0, y)

    button.AnimationSeed = math.random(1, 10000)
    button.ShineOffset = math.random(0, 1000)

    button.Paint = function(self, w, h)
        local localach =
            hg.achievements.GetLocalAchievements()
            or {}

        PaintAchievementCard(
            self,
            w,
            h,
            ach,
            localach
        )
    end

    button.DoClick = function(self)
        curent_panel_ach = ach

        if func then
            func(self)
        end

        for i = 1, 3 do
            surface.PlaySound(
                "shitty/tap_depress.wav"
            )
        end
    end

    return button
end

local function PaintFrame(self, w, h)
    BlurBackground(self)

    surface.SetDrawColor(
        achievementTheme.backgroundSoft.r,
        achievementTheme.backgroundSoft.g,
        achievementTheme.backgroundSoft.b,
        achievementTheme.backgroundSoft.a
    )

    surface.DrawRect(0, 0, w, h)

    surface.SetDrawColor(
        achievementTheme.borderBright.r,
        achievementTheme.borderBright.g,
        achievementTheme.borderBright.b,
        150
    )

    surface.DrawOutlinedRect(
        0,
        0,
        w,
        h,
        1
    )
end

function hg.DrawAchievmentsMenu(ParentPanel)
    hg.achievements.LoadAchievements()

    if not IsValid(ParentPanel) then return end

    if IsValid(hg.achievements.MenuPanel) then
        hg.achievements.MenuPanel:Remove()
        hg.achievements.MenuPanel = nil
    end

    curent_panel_ach = nil

    ParentPanel:SetAlpha(0)

    -- Меняется только фон содержимого вкладки.
    ParentPanel.Paint = function(self, w, h)
        DrawAchievementBackground(w, h)
    end

    hg.DrawBlur(ParentPanel, 5)
    ParentPanel:AlphaTo(255, 0.15, 0)

    local frame = vgui.Create(
        "DPanel",
        ParentPanel
    )

    -- Исходное расположение и размеры сохранены.
    frame:SetSize(
        ParentPanel:GetWide() / 2.5,
        ScreenScale(22) * 8.25
            + ScreenScale(2.5)
    )

    frame:SetPos(
        5,
        ParentPanel:GetTall() / 2
            - frame:GetTall() / 2
    )

    frame.Paint = function(self, w, h)
        PaintFrame(self, w, h)
    end

    hg.achievements.MenuPanel = frame

    local scroll = vgui.Create(
        "DScrollPanel",
        frame
    )

    scroll:SetSize(
        frame:GetWide(),
        frame:GetTall()
    )

    scroll:SetPos(0, 0)

    frame.scroll = scroll

    local sbar = scroll:GetVBar()

    sbar:SetWide(0)
    sbar:SetHideButtons(true)

    function sbar:Paint(w, h)
        surface.SetDrawColor(
            achievementTheme.background.r,
            achievementTheme.background.g,
            achievementTheme.background.b,
            170
        )

        surface.DrawRect(0, 0, w, h)
    end

    function sbar.btnGrip:Paint(w, h)
        local progress = self:IsHovered() and 1 or 0

        local color = achievementTheme.border:Lerp(
            achievementTheme.borderBright,
            progress
        )

        draw.RoundedBox(
            0,
            0,
            0,
            w,
            h,
            color
        )
    end

    function frame:UpdateValues()
        local achievementScroll = self.scroll

        achievementScroll:Clear()

        local y = 0

        -- Используем pairs, как в оригинале.
        for _, ach in pairs(
            hg.achievements.achievements_data.created_achevements
        ) do
            local button = createButton_2(
                achievementScroll,
                ach,
                ach.name,
                function()
                end,
                y
            )

            y = button:GetTall() + y + 3

            -- Сохраняем исходную логику добавления элементов.
            achievementScroll:AddItem(button)

            curent_panel_ach = ach
        end
    end

    local y = 0

    -- Исходное расположение списка сохраняется.
    for _, ach in pairs(
        hg.achievements.achievements_data.created_achevements
    ) do
        local button = createButton_2(
            scroll,
            ach,
            ach.name,
            function()
            end,
            y
        )

        y = button:GetTall() + y + 3

        scroll:AddItem(button)

        curent_panel_ach = ach
    end

    local frame2 = vgui.Create(
        "DPanel",
        ParentPanel
    )

    -- Исходные размеры и позиция сохраняются.
    frame2:SetSize(
        ParentPanel:GetWide() / 2,
        ScreenScale(22) * 8.25
            + ScreenScale(2.5)
    )

    frame2:Center()

    frame2:SetPos(
        frame:GetX() + frame:GetWide(),
        frame:GetY()
    )

    frame2.Paint = function(self, w, h)
        surface.SetDrawColor(
            achievementTheme.backgroundSoft.r,
            achievementTheme.backgroundSoft.g,
            achievementTheme.backgroundSoft.b,
            achievementTheme.backgroundSoft.a
        )

        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(
            achievementTheme.pinkSoft.r,
            achievementTheme.pinkSoft.g,
            achievementTheme.pinkSoft.b,
            45
        )

        surface.DrawRect(
            0,
            h - h / 6,
            w,
            h / 6
        )

        surface.SetDrawColor(
            achievementTheme.pink.r,
            achievementTheme.pink.g,
            achievementTheme.pink.b,
            180
        )

        surface.DrawRect(
            0,
            h - ScreenScale(2),
            w,
            ScreenScale(2)
        )

        if not curent_panel_ach then
            draw.SimpleText(
                "Выберите достижение",
                "ZCity_setiings_category",
                w / 2,
                h / 2,
                achievementTheme.whiteSoft,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )

            return
        end

        self.HoverLerp = Lerp(
            FrameTime() * 5,
            self.HoverLerp or 0,
            1
        )

        local imageSize = math.min(
            w * 0.2,
            h * 0.2
        )

        local imageX = w / 2 - imageSize / 2
        local imageY = h / 2 - imageSize

        local pulse = math.sin(
            RealTime() * 2.5
        ) * 0.5 + 0.5

        surface.SetDrawColor(
            achievementTheme.pink.r,
            achievementTheme.pink.g,
            achievementTheme.pink.b,
            35 + pulse * 35
        )

        surface.DrawOutlinedRect(
            imageX - ScreenScale(5),
            imageY - ScreenScale(5),
            imageSize + ScreenScale(10),
            imageSize + ScreenScale(10),
            ScreenScale(2)
        )

        if curent_panel_ach.img then
            surface.SetDrawColor(
                255,
                255,
                255,
                255
            )

            surface.SetMaterial(
                curent_panel_ach.img
            )

            surface.DrawTexturedRect(
                imageX,
                imageY,
                imageSize,
                imageSize
            )
        end

        DrawAnimatedText(
            curent_panel_ach.name or "",
            "ZCity_Small",
            w / 2,
            h - h / 6,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER,
            100,
            true
        )

        local description =
            tostring(
                curent_panel_ach.description or ""
            )

        description = description:gsub(
            "\\n",
            "\n"
        )

        local lines = string.Explode(
            "\n",
            description
        )

        local lineHeight = ScreenScale(8)
        local descriptionY = h - h / 12

        for lineIndex, line in ipairs(lines) do
            DrawAnimatedText(
                line,
                "ZCity_Tiny",
                w / 2,
                descriptionY
                    + (lineIndex - 1) * lineHeight,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER,
                150 + lineIndex,
                true
            )
        end
    end
end

local time_wait = 0

function hg.achievements.LoadAchievements()
    if time_wait > CurTime() then return end

    time_wait = CurTime() + 2

    net.Start("req_ach")
    net.SendToServer()
end

function hg.achievements.GetLocalAchievements()
    local player = LocalPlayer()

    if not IsValid(player) then
        return {}
    end

    return hg.achievements.achievements_data
        .player_achievements[
            tostring(player:SteamID())
        ]
        or {}
end

net.Receive("req_ach", function()
    hg.achievements.achievements_data.created_achevements =
        net.ReadTable()

    local player = LocalPlayer()

    if IsValid(player) then
        hg.achievements.achievements_data
            .player_achievements[
                tostring(player:SteamID())
            ] = net.ReadTable()
    else
        net.ReadTable()
    end

    if IsValid(hg.achievements.MenuPanel)
    and hg.achievements.MenuPanel.UpdateValues then
        hg.achievements.MenuPanel:UpdateValues()
    end
end)

hg.achievements.NewAchievements =
    hg.achievements.NewAchievements or {}

local AchTable =
    hg.achievements.NewAchievements

net.Receive("hg_NewAchievement", function()
    local achievement = {
        time = CurTime() + 7.5,
        name = net.ReadString(),
        img = net.ReadString()
    }

    table.insert(
        AchTable,
        1,
        achievement
    )

    surface.PlaySound(
        "homigrad/vgui/achievement_earned.wav"
    )
end)

local notificationTheme = {
    background = Color(41, 41, 41, 245),
    backgroundHover = Color(70, 51, 56, 250),
    pink = Color(200, 142, 155, 255),
    white = Color(246, 242, 243, 255),
    border = Color(200, 142, 155, 255)
}


hook.Add(
    "HUDPaint",
    "hg_NewAchievement",
    function()
        local frameTime = FrameTime() * 8
        local now = CurTime()

        for index = #AchTable, 1, -1 do
            local achievement = AchTable[index]

            if not achievement then
                continue
            end

            achievement.img =
                isstring(achievement.img)
                and Material(achievement.img)
                or achievement.img

            local title =
                "Achievement! "
                .. tostring(achievement.name or "")

            surface.SetFont("HomigradFontMedium")

            local textWidth =
                surface.GetTextSize(title)

            local width =
                ScrW() * 0.1
                + textWidth
                + ScreenScale(20)

            local height = ScreenScale(28)

            local target = math.Clamp(
                achievement.time - now,
                0,
                1
            )

            achievement.Lerp = Lerp(
                frameTime,
                achievement.Lerp or 0,
                target
            )

            local y =
                ScrH()
                - height * achievement.Lerp

            local wave = math.sin(
                RealTime() * 3 + index
            ) * 0.5 + 0.5

            local background =
                notificationTheme.background:Lerp(
                    notificationTheme.backgroundHover,
                    wave
                )

            draw.RoundedBox(
                0,
                2,
                y + 2,
                width - 4,
                height - 4,
                background
            )

            surface.SetDrawColor(
                notificationTheme.border.r,
                notificationTheme.border.g,
                notificationTheme.border.b,
                220
            )

            surface.DrawOutlinedRect(
                0,
                y,
                width,
                height,
                2
            )

            surface.SetDrawColor(
                notificationTheme.pink.r,
                notificationTheme.pink.g,
                notificationTheme.pink.b,
                90
            )

            surface.DrawRect(
                0,
                y,
                width,
                ScreenScale(2)
            )

            DrawAnimatedText(
                title,
                "HomigradFontMedium",
                ScreenScale(12),
                y + height / 2,
                TEXT_ALIGN_LEFT,
                TEXT_ALIGN_CENTER,
                index * 10,
                true
            )

            if achievement.img then
                surface.SetDrawColor(
                    255,
                    255,
                    255,
                    255
                )

                surface.SetMaterial(
                    achievement.img
                )

                surface.DrawTexturedRect(
                    2,
                    y + 2,
                    height - 4,
                    height - 4
                )
            end

            if achievement.time < now then
                table.remove(
                    AchTable,
                    index
                )
            end
        end
    end
)
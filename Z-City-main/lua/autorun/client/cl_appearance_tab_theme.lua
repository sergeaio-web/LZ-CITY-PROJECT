if SERVER then return end

hg = hg or {}

local THEME = {
    background = Color(41, 41, 41, 255),
    backgroundSecondary = Color(48, 48, 48, 245),

    -- Тонкие геометрические линии по краям
    grid = Color(200, 142, 155, 48),
    accent = Color(200, 142, 155, 255),
    accentSoft = Color(160, 105, 116, 125),

    panel = Color(45, 43, 44, 240),
    panelHover = Color(65, 52, 55, 250),

    text = Color(245, 242, 243, 255),
    textSoft = Color(205, 190, 193, 220),

    input = Color(32, 32, 32, 250),
    border = Color(125, 90, 96, 220),

    scrollbar = Color(35, 35, 35, 240),
    scrollbarGrip = Color(150, 105, 115, 255),
    scrollbarGripHover = Color(200, 142, 155, 255)
}

local appearanceGlow = Material("sprites/light_glow02_add")

local appearanceStyledPanels = setmetatable({}, {
    __mode = "k"
})

local appearanceStyledButtons = setmetatable({}, {
    __mode = "k"
})

local function DrawCrossPattern(w, h)
    -- Больше никаких плюсиков и плотной сетки:
    -- только тонкие угловые линии по краям интерфейса.
    local margin = ScreenScale(20)
    local length = ScreenScale(34)
    local thickness = math.max(1, ScreenScale(1))

    surface.SetDrawColor(
        THEME.grid.r,
        THEME.grid.g,
        THEME.grid.b,
        THEME.grid.a
    )

    -- Верхний левый угол
    surface.DrawRect(margin, margin, length, thickness)
    surface.DrawRect(margin, margin, thickness, length)

    -- Верхний правый угол
    surface.DrawRect(w - margin - length, margin, length, thickness)
    surface.DrawRect(w - margin - thickness, margin, thickness, length)

    -- Нижний левый угол
    surface.DrawRect(margin, h - margin - thickness, length, thickness)
    surface.DrawRect(margin, h - margin - length, thickness, length)

    -- Нижний правый угол
    surface.DrawRect(w - margin - length, h - margin - thickness, length, thickness)
    surface.DrawRect(w - margin - thickness, h - margin - length, thickness, length)

    -- Очень тонкие линии вдоль левого и правого краёв.
    surface.SetDrawColor(
        THEME.accent.r,
        THEME.accent.g,
        THEME.accent.b,
        24
    )

    surface.DrawRect(0, 0, thickness, h)
    surface.DrawRect(w - thickness, 0, thickness, h)
end


local function PaintAppearanceBackground(self, w, h)
    -- Спокойный графитовый фон.
    surface.SetDrawColor(
        THEME.background.r,
        THEME.background.g,
        THEME.background.b,
        THEME.background.a
    )

    surface.DrawRect(0, 0, w, h)

    -- Мягкое пастельно-розовое свечение позади модели персонажа.
    if appearanceGlow and not appearanceGlow:IsError() then
        local glowSize = math.min(h * 0.96, w * 0.68)
        local glowX = w * 0.10
        local glowY = (h - glowSize) * 0.5

        surface.SetMaterial(appearanceGlow)
        surface.SetDrawColor(
            THEME.accent.r,
            THEME.accent.g,
            THEME.accent.b,
            22
        )

        surface.DrawTexturedRect(
            glowX,
            glowY,
            glowSize,
            glowSize
        )
    end

    -- Минималистичные угловые отметки вместо плюсиков.
    DrawCrossPattern(w, h)

    -- Лёгкое затемнение, чтобы модель и элементы меню оставались главным.
    surface.SetDrawColor(0, 0, 0, 18)
    surface.DrawRect(0, 0, w, h)
end


local function LerpColor(progress, first, second)
    return first:Lerp(second, math.Clamp(progress, 0, 1))
end

local function PaintAppearanceButton(self, w, h)
    local target = self:IsHovered() and 1 or 0

    self.AppearanceHover = Lerp(
        FrameTime() * 8,
        self.AppearanceHover or 0,
        target
    )

    local progress = self.AppearanceHover

    local background = LerpColor(
        progress,
        THEME.panel,
        THEME.panelHover
    )

    draw.RoundedBox(
        4,
        0,
        0,
        w,
        h,
        background
    )

    local border = LerpColor(
        progress,
        THEME.border,
        THEME.accent
    )

    surface.SetDrawColor(
        border.r,
        border.g,
        border.b,
        border.a
    )

    surface.DrawOutlinedRect(0, 0, w, h, 1)

    surface.SetDrawColor(
        THEME.accent.r,
        THEME.accent.g,
        THEME.accent.b,
        70 + progress * 130
    )

    surface.DrawRect(
        0,
        h - ScreenScale(1),
        w,
        ScreenScale(1)
    )

    if self.SetTextColor then
        self:SetTextColor(
            LerpColor(
                0.6 + progress * 0.4,
                THEME.textSoft,
                THEME.text
            )
        )
    end
end

local function PaintAppearanceTextEntry(self, w, h)
    local progress = self:IsHovered() and 1 or 0

    surface.SetDrawColor(
        THEME.input.r,
        THEME.input.g,
        THEME.input.b,
        THEME.input.a
    )

    surface.DrawRect(0, 0, w, h)

    local border = LerpColor(
        progress,
        THEME.border,
        THEME.accent
    )

    surface.SetDrawColor(
        border.r,
        border.g,
        border.b,
        border.a
    )

    surface.DrawOutlinedRect(0, 0, w, h, 1)

    self:DrawTextEntryText(
        THEME.text,
        THEME.accent,
        THEME.text
    )
end

local function StyleScrollBar(scroll)
    if not IsValid(scroll) then return end

    local bar = scroll:GetVBar()

    if not IsValid(bar) then return end

    bar:SetWide(ScreenScale(5))
    bar:SetHideButtons(true)

    bar.Paint = function(self, w, h)
        surface.SetDrawColor(
            THEME.scrollbar.r,
            THEME.scrollbar.g,
            THEME.scrollbar.b,
            THEME.scrollbar.a
        )

        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(
            THEME.border.r,
            THEME.border.g,
            THEME.border.b,
            120
        )

        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    if IsValid(bar.btnGrip) then
        bar.btnGrip.Paint = function(self, w, h)
            local gripColor = self:IsHovered()
                and THEME.scrollbarGripHover
                or THEME.scrollbarGrip

            draw.RoundedBox(
                4,
                1,
                1,
                w - 2,
                h - 2,
                gripColor
            )

            surface.SetDrawColor(
                THEME.accent.r,
                THEME.accent.g,
                THEME.accent.b,
                140
            )

            surface.DrawOutlinedRect(1, 1, w - 2, h - 2, 1)
        end
    end
end

local function StylePanel(panel)
    if not IsValid(panel) then return end
    if appearanceStyledPanels[panel] then return end

    appearanceStyledPanels[panel] = true

    local className = panel:GetClass()

    if className == "DScrollPanel" then
        StyleScrollBar(panel)
    end

    if className == "DTextEntry" then
        panel.Paint = function(self, w, h)
            PaintAppearanceTextEntry(self, w, h)
        end

        panel:SetTextColor(THEME.text)
    end

    if className == "DButton"
    or className == "DComboBox" then
        if not appearanceStyledButtons[panel] then
            appearanceStyledButtons[panel] = true

            panel.Paint = function(self, w, h)
                PaintAppearanceButton(self, w, h)
            end

            if panel.SetTextColor then
                panel:SetTextColor(THEME.text)
            end
        end
    end

    if className == "DPanel"
    and panel:GetParent()
    and panel:GetParent():GetClass() == "DModelPanel" then
        panel.Paint = function(self, w, h)
            PaintAppearanceButton(self, w, h)
        end
    end
end

local function StyleAppearanceChildren(parent)
    if not IsValid(parent) then return end

    StylePanel(parent)

    for _, child in ipairs(parent:GetChildren()) do
        StyleAppearanceChildren(child)
    end
end

local function StyleAppearanceMenu()
    if not IsValid(zpan) then return false end

    local appearanceMenu = zpan

    appearanceMenu.Paint = function(self, w, h)
        PaintAppearanceBackground(self, w, h)
    end

    StyleAppearanceChildren(appearanceMenu)

    return true
end

local function StartAppearanceStyling()
    local timerName = "HG_StyleAppearanceMenu"

    timer.Remove(timerName)

    timer.Create(timerName, 0.2, 50, function()
        if not IsValid(zpan) then return end

        StyleAppearanceMenu()
    end)
end

local appearanceCreatorWrapped = false

local function HookAppearanceCreator()
    if not isfunction(hg.CreateApperanceMenu) then
        return false
    end

    if appearanceCreatorWrapped then
        return true
    end

    local oldCreateAppearanceMenu = hg.CreateApperanceMenu

    local function CreateStyledAppearanceMenu(...)
        local result = oldCreateAppearanceMenu(...)

        StartAppearanceStyling()

        return result
    end

    hg.CreateApperanceMenu = CreateStyledAppearanceMenu
    appearanceCreatorWrapped = true

    return true
end

timer.Create(
    "HG_WaitForAppearanceCreator",
    1,
    0,
    function()
        if HookAppearanceCreator() then
            timer.Remove("HG_WaitForAppearanceCreator")
        end
    end
)

hook.Add(
    "Think",
    "HG_RefreshAppearanceTabTheme",
    function()
        if not IsValid(zpan) then return end

        if zpan.AppearanceThemeNextUpdate
        and zpan.AppearanceThemeNextUpdate > RealTime() then
            return
        end

        zpan.AppearanceThemeNextUpdate = RealTime() + 0.5

        StyleAppearanceMenu()
    end
)
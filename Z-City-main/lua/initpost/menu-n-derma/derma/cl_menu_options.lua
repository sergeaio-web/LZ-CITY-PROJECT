hg.settings = hg.settings or {}
hg.settings.tbl = hg.settings.tbl or {}

function hg.settings:AddOpt(
    strCategory,
    strConVar,
    strTitle,
    bDecimals,
    bString,
    category
)
    self.tbl[strCategory] = self.tbl[strCategory] or {}

    self.tbl[strCategory][strConVar] = {
        strCategory,
        strConVar,
        strTitle,
        bDecimals or false,
        bString or false,
        category
    }
end

local hg_firstperson_death = CreateClientConVar(
    "hg_firstperson_death",
    "0",
    true,
    false,
    "Toggle first-person death camera view",
    0,
    1
)

local hg_font = CreateClientConVar(
    "hg_font",
    "Bahnschrift",
    true,
    false,
    "change every UI text font",
    0,
    1
)

local hg_attachment_draw_distance = CreateClientConVar(
    "hg_attachment_draw_distance",
    0,
    true,
    nil,
    "distance to draw attachments",
    0,
    4096
)

xbars = 17
ybars = 30

gradient_l = Material("vgui/gradient-l")

local blur = Material("pp/blurscreen")
local blur2 = Material("effects/shaders/zb_blur")

local sw, sh = ScrW(), ScrH()

local font = function()
    local usefont = "Bahnschrift"

    if hg_font:GetString() ~= "" then
        usefont = hg_font:GetString()
    end

    return usefont
end

surface.CreateFont("ZCity_setiings_tiny", {
    font = font(),
    size = ScreenScale(7),
    weight = 100
})

surface.CreateFont("ZCity_setiings_fine", {
    font = font(),
    size = ScreenScale(10),
    weight = 100
})

surface.CreateFont("ZCity_setiings_category", {
    font = font(),
    size = ScreenScale(15),
    weight = 100
})

hg.settings:AddOpt(
    "Gameplay",
    "hg_old_notificate",
    "Old Notifications"
)

hg.settings:AddOpt(
    "Gameplay",
    "hg_cheats",
    "Enable Cheats"
)

hg.settings:AddOpt(
    "Gameplay",
    "hg_showthoughts",
    "Show thoughts"
)

hg.settings:AddOpt(
    "Gameplay",
    "hg_hints",
    "Show hints"
)

hg.settings:AddOpt(
    "Gameplay",
    "hg_gary",
    "Center weapon in fake"
)

hg.settings:AddOpt(
    "Gameplay",
    "hg_deathfadeout",
    "Death fade out"
)

if not game.IsDedicated() then
    hg.settings:AddOpt(
        "Server-side settings",
        "hg_toughnpcs",
        "Tough npcs"
    )

    hg.settings:AddOpt(
        "Server-side settings",
        "hg_thirdperson",
        "Thirdperson (WIP)"
    )

    hg.settings:AddOpt(
        "Server-side settings",
        "hg_legacycam",
        "Legacy camera"
    )

    hg.settings:AddOpt(
        "Server-side settings",
        "hg_ragdollcombat",
        "Ragdoll combat mode"
    )

    hg.settings:AddOpt(
        "Server-side settings",
        "hg_movement_stamina_debuff",
        "Movement stamina debuff"
    )

    hg.settings:AddOpt(
        "Server-side settings",
        "hg_furcity",
        "Furcity"
    )

    hg.settings:AddOpt(
        "Server-side settings",
        "hg_appearance_access_for_all",
        "Appearance full access for all",
        nil,
        nil,
        "bool"
    )

    hg.settings:AddOpt(
        "Server-side settings",
        "hg_healanims",
        "Heal & food animations"
    )

    hg.settings:AddOpt(
        "Server-side settings",
        "hg_aimtoshoot",
        "Toggle DarkRP-like shooting system: 0 - disabled; 1 - hipfire only; 2 - aiming only",
        nil,
        nil,
        "int"
    )

    hg.settings:AddOpt(
        "Server-side settings",
        "hg_slings",
        "Sling system"
    )

    hg.settings:AddOpt(
        "Server-side settings",
        "hg_allow_gopro",
        "Allow GoPro-like first-person camera"
    )

    hg.settings:AddOpt(
        "Server-side settings",
        "hg_allow_gopro_pos",
        "Allow editing GoPro camera position"
    )

    hg.settings:AddOpt(
        "Server-side settings",
        "hg_giveammomul",
        "Multiply given ammo for weapon spawned from spawnmenu"
    )

    hg.settings:AddOpt(
        "Server-side settings",
        "hg_ixanims",
        "Toggle Helix-like animations on NPC models for players. Experimental"
    )

    hg.settings:AddOpt(
        "Server-side settings",
        "hg_coolhands",
        "Give cool hands instead of default hands on spawn"
    )

    hg.settings:AddOpt(
        "Server-side settings",
        "hg_loadcontent",
        "Toggle loading content to clients using resource.AddWorkshop"
    )

    hg.settings:AddOpt(
        "Server-side settings",
        "homicide_traitoramount",
        "Homicide: Traitor Amount",
        nil,
        nil,
        "int"
    )
end

hg.settings:AddOpt(
    "Debug",
    "hg_show_hitposmuzzle",
    "Show weapon hitpos"
)

hg.settings:AddOpt(
    "Debug",
    "hg_setzoompos",
    "Edit weapon zoompos, check console for results"
)

hg.settings:AddOpt(
    "Debug",
    "hg_show_hitbox",
    "Show hitboxes"
)

hg.settings:AddOpt(
    "Optimization",
    "hg_potatopc",
    "Potato PC Mode"
)

hg.settings:AddOpt(
    "Optimization",
    "hg_anims_draw_distance",
    "Animations Draw Distance",
    true,
    nil,
    "int"
)

hg.settings:AddOpt(
    "Optimization",
    "hg_anim_fps",
    "Animations FPS",
    nil,
    nil,
    "int"
)

hg.settings:AddOpt(
    "Optimization",
    "hg_attachment_draw_distance",
    "Attachment Draw Distance",
    true,
    nil,
    "int"
)

hg.settings:AddOpt(
    "Optimization",
    "hg_maxsmoketrails",
    "Maximum Smoke Trails",
    nil,
    nil,
    "int"
)

hg.settings:AddOpt(
    "Optimization",
    "hg_tpik_distance",
    "TPIK Render Distance",
    true,
    nil,
    "int"
)

hg.settings:AddOpt(
    "Blood",
    "hg_blood_draw_distance",
    "Blood Draw Distance"
)

hg.settings:AddOpt(
    "Blood",
    "hg_blood_fps",
    "Blood FPS"
)

hg.settings:AddOpt(
    "Blood",
    "hg_blood_sprites",
    "Blood Sprites (DISABLED FOR EVERYONE)"
)

hg.settings:AddOpt(
    "Blood",
    "hg_old_blood",
    "Old blood"
)

hg.settings:AddOpt(
    "UI",
    "hg_font",
    "Set Custom Font",
    false,
    true
)

hg.settings:AddOpt(
    "Weapons",
    "hg_weaponshotblur_enable",
    "Shooting Blur"
)

hg.settings:AddOpt(
    "Weapons",
    "hg_dynamic_mags",
    "Dynamic Ammo Inspect"
)

hg.settings:AddOpt(
    "Weapons",
    "hg_zoomsensitivity",
    "Scope sensitivity"
)

hg.settings:AddOpt(
    "Weapons",
    "hg_highpitchgunfire",
    "Toggle high pitched gunfire sounds inside buildings"
)

hg.settings:AddOpt(
    "View",
    "hg_firstperson_death",
    "First-Person Death"
)

hg.settings:AddOpt(
    "View",
    "hg_fov",
    "Field Of View"
)

hg.settings:AddOpt(
    "View",
    "hg_newspectate",
    "Smooth Spectator Camera"
)

hg.settings:AddOpt(
    "View",
    "hg_cshs_fake",
    "C'sHS Ragdoll Camera"
)

hg.settings:AddOpt(
    "View",
    "hg_gun_cam",
    "Gun Camera (ADMIN ONLY)"
)

hg.settings:AddOpt(
    "View",
    "hg_nofovzoom",
    "Disable/Enable FOV Zoom"
)

hg.settings:AddOpt(
    "View",
    "hg_realismcam",
    "Realism camera (shitty)"
)

hg.settings:AddOpt(
    "View",
    "hg_gopro",
    "GoPro camera"
)

hg.settings:AddOpt(
    "View",
    "hg_newfakecam",
    "New fake camera"
)

hg.settings:AddOpt(
    "View",
    "hg_leancam_mul",
    "Lean camera mul",
    true,
    nil,
    "int"
)

hg.settings:AddOpt(
    "View",
    "hg_gun_cam",
    "Gun camera (WIP Admin only)"
)

hg.settings:AddOpt(
    "Sound",
    "hg_dmusic",
    "Dynamic Music"
)

hg.settings:AddOpt(
    "Sound",
    "hg_quietshots",
    "Enable/Disable Quietshoot Sounds"
)

local settingsTheme = {
    -- Основной графитовый фон
    background = Color(41, 41, 41, 255),
    backgroundSoft = Color(48, 48, 48, 245),

    -- Текст
    white = Color(245, 242, 243, 255),
    softGrayPink = Color(209, 192, 196, 235),

    -- Пастельно-розовые акценты LZ-City
    pink = Color(200, 142, 155, 255),
    pinkSoft = Color(135, 91, 98, 180),
    pinkDark = Color(57, 40, 44, 235),

    -- Категории настроек
    category = Color(48, 45, 46, 245),
    categoryHover = Color(65, 51, 54, 250),

    -- Карточки настроек
    panel = Color(45, 43, 44, 245),
    panelHover = Color(60, 48, 51, 250),

    -- Рамки
    border = Color(112, 80, 86, 220),
    borderBright = Color(200, 142, 155, 255),

    -- Поля ввода и ползунки
    input = Color(32, 32, 32, 250),
    sliderBackground = Color(35, 35, 35, 245)
}

local function LerpColor(progress, first, second)
    return first:Lerp(
        second,
        math.Clamp(progress, 0, 1)
    )
end

local function GetAnimatedWave(seed, index, speed)
    local value = math.sin(
        RealTime() * speed
        + seed
        + index * 0.4
    ) * 0.5 + 0.5

    return value * value * (3 - 2 * value)
end

local function DrawAnimatedText(
    text,
    textFont,
    x,
    y,
    alignX,
    alignY,
    seed
)
    text = tostring(text or "")

    surface.SetFont(textFont)

    local totalWidth = surface.GetTextSize(text)
    local startX = x

    if alignX == TEXT_ALIGN_CENTER then
        startX = x - totalWidth / 2
    elseif alignX == TEXT_ALIGN_RIGHT then
        startX = x - totalWidth
    end

    local cursorX = startX

    for index = 1, #text do
        local character = text:sub(index, index)
        local characterWidth = surface.GetTextSize(character)

        local wave = GetAnimatedWave(
            seed,
            index,
            1.8
        )

        local textColor = LerpColor(
            wave,
            settingsTheme.white,
            settingsTheme.softGrayPink
        )

        local characterY =
            y
            + math.sin(
                RealTime() * 1.8
                + seed
                + index
            ) * ScreenScale(0.2)

        draw.SimpleText(
            character,
            textFont,
            cursorX,
            characterY,
            textColor,
            TEXT_ALIGN_LEFT,
            alignY
        )

        cursorX = cursorX + characterWidth
    end
end

local function DrawSettingsDigits(w, h)
    local characters = {
        "0", "1", "2", "3", "4",
        "5", "6", "7", "8", "9",
        "A", "B", "C", "D", "E",
        "F", "G", "X", "Z"
    }

    local columnWidth = ScreenScale(48)
    local rowHeight = ScreenScale(34)
    local speed = ScreenScale(42)
    local time = RealTime()

    surface.SetFont("ZCity_setiings_tiny")

    for column = 0, math.ceil(w / columnWidth) + 1 do
        local columnOffset = (column * 71) % 160

        local offsetY = (
            time * speed
            + columnOffset
        ) % (h + rowHeight * 3)

        for row = -3, math.ceil(h / rowHeight) + 3 do
            local characterIndex =
                ((column * 5 + row * 3) % #characters) + 1

            local character = characters[characterIndex]

            local wave = math.sin(
                time * 2
                + column * 0.45
                + row * 0.25
            ) * 0.5 + 0.5

            local color = settingsTheme.pink:Lerp(
                settingsTheme.white,
                wave * 0.25
            )

            draw.SimpleText(
                character,
                "ZCity_setiings_tiny",
                column * columnWidth,
                row * rowHeight + offsetY,
                Color(
                    color.r,
                    color.g,
                    color.b,
                    15 + wave * 30
                ),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
        end
    end
end

local function DrawSettingsBackground(w, h)
    surface.SetDrawColor(
        settingsTheme.background.r,
        settingsTheme.background.g,
        settingsTheme.background.b,
        settingsTheme.background.a
    )

    surface.DrawRect(0, 0, w, h)

    DrawSettingsDigits(w, h)

    local lineSize = ScreenScale(58)
    local lineOffset = (
        RealTime() * ScreenScale(18)
    ) % lineSize

    surface.SetDrawColor(
        settingsTheme.pinkSoft.r,
        settingsTheme.pinkSoft.g,
        settingsTheme.pinkSoft.b,
        32
    )

    for y = -lineSize, h + lineSize, lineSize do
        surface.DrawRect(
            0,
            math.floor(y + lineOffset),
            w,
            ScreenScale(1)
        )
    end

    surface.SetDrawColor(
        settingsTheme.borderBright.r,
        settingsTheme.borderBright.g,
        settingsTheme.borderBright.b,
        95
    )

    surface.DrawRect(0, 0, ScreenScale(2), h)

    surface.DrawRect(
        w - ScreenScale(2),
        0,
        ScreenScale(2),
        h
    )
end

local function DrawSettingPanel(
    self,
    w,
    h,
    title,
    helpText,
    titleSeed
)
    local target = self:IsHovered() and 1 or 0

    self.SettingsHover = Lerp(
        FrameTime() * 8,
        self.SettingsHover or 0,
        target
    )

    local progress = self.SettingsHover

    local background = LerpColor(
        progress,
        settingsTheme.panel,
        settingsTheme.panelHover
    )

    surface.SetDrawColor(
        background.r,
        background.g,
        background.b,
        background.a
    )

    surface.DrawRect(0, 0, w, h)

    local border = LerpColor(
        progress,
        settingsTheme.border,
        settingsTheme.borderBright
    )

    surface.SetDrawColor(
        border.r,
        border.g,
        border.b,
        border.a
    )

    surface.DrawOutlinedRect(0, 0, w, h, 1)

    surface.SetDrawColor(
        settingsTheme.pink.r,
        settingsTheme.pink.g,
        settingsTheme.pink.b,
        75 + progress * 120
    )

    surface.DrawRect(
        0,
        h - ScreenScale(2),
        w,
        ScreenScale(2)
    )

    DrawAnimatedText(
        title,
        "ZCity_setiings_fine",
        ScreenScale(15),
        h / 2 - ScreenScale(4),
        TEXT_ALIGN_LEFT,
        TEXT_ALIGN_CENTER,
        titleSeed
    )

    DrawAnimatedText(
        helpText,
        "ZCity_setiings_tiny",
        ScreenScale(15),
        h / 2 + ScreenScale(6),
        TEXT_ALIGN_LEFT,
        TEXT_ALIGN_CENTER,
        titleSeed + 10
    )
end

local function SetConVarValue(convar, value)
    if not convar then return end

    local name = convar.GetName
        and convar:GetName()

    if not name or name == "" then
        return
    end

    if isbool(value) then
        RunConsoleCommand(
            name,
            value and "1" or "0"
        )

        return
    end

    RunConsoleCommand(
        name,
        tostring(value)
    )
end

function hg.CreateCategory(ctgName, ParentPanel, yPos)
    local panel = vgui.Create(
        "DPanel",
        ParentPanel
    )

    panel:SetSize(
        ParentPanel:GetWide() / 1.05,
        ParentPanel:GetTall() * 0.07
    )

    panel:SetPos(
        ParentPanel:GetWide() / 2
            - panel:GetWide() / 2,
        yPos
    )

    panel.CategorySeed = math.random(1, 10000)

    panel.Paint = function(self, w, h)
        local target = self:IsHovered() and 1 or 0

        self.CategoryHover = Lerp(
            FrameTime() * 6,
            self.CategoryHover or 0,
            target
        )

        local progress = self.CategoryHover

        local background = LerpColor(
            progress,
            settingsTheme.category,
            settingsTheme.categoryHover
        )

        surface.SetDrawColor(
            background.r,
            background.g,
            background.b,
            background.a
        )

        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(
            settingsTheme.borderBright.r,
            settingsTheme.borderBright.g,
            settingsTheme.borderBright.b,
            80 + progress * 100
        )

        surface.DrawRect(
            0,
            h - ScreenScale(4),
            w,
            ScreenScale(4)
        )

        DrawAnimatedText(
            ctgName,
            "ZCity_setiings_category",
            w / 2,
            h / 2,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER,
            self.CategorySeed
        )
    end

    return panel
end

function hg.GetConVarType(convar)
    local stringValue = convar:GetString()
    local floatValue = convar:GetFloat()
    local intValue = convar:GetInt()
    local boolValue = convar:GetBool()

    if (
        stringValue == "0"
        and not boolValue
    )
    or (
        stringValue == "1"
        and boolValue
    ) then
        return "bool"
    end

    if tonumber(stringValue)
    and math.floor(stringValue) == floatValue
    and intValue == floatValue then
        return "int"
    end

    return "string"
end

local function StyleToggle(
    toggle,
    convar,
    initialValue
)
    local animProgress = initialValue and 1 or 0
    local targetProgress = animProgress

    toggle.Paint = function(self, w, h)
        if convar then
            targetProgress = convar:GetBool()
                and 1
                or 0
        end

        animProgress = Lerp(
            FrameTime() * 8,
            animProgress,
            targetProgress
        )

        surface.SetDrawColor(
            settingsTheme.input.r,
            settingsTheme.input.g,
            settingsTheme.input.b,
            settingsTheme.input.a
        )

        draw.RoundedBox(
            0,
            0,
            0,
            w,
            h,
            settingsTheme.input
        )

       local toggleColor = Color(
    Lerp(
        animProgress,
        70,
        settingsTheme.pink.r
    ),
    Lerp(
        animProgress,
        70,
        settingsTheme.pink.g
    ),
    Lerp(
        animProgress,
        70,
        settingsTheme.pink.b
    ),
    255
)

        local knobSize = math.max(
            ScreenScale(5),
            h - ScreenScale(10)
        )

        local knobX = Lerp(
            animProgress,
            ScreenScale(5),
            w - knobSize - ScreenScale(5)
        )

        draw.RoundedBox(
            0,
            knobX,
            h / 2 - knobSize / 2,
            knobSize,
            knobSize,
            toggleColor
        )

        surface.SetDrawColor(
            settingsTheme.borderBright.r,
            settingsTheme.borderBright.g,
            settingsTheme.borderBright.b,
            85 + animProgress * 120
        )

        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    toggle.DoClick = function()
        if not convar then return end

        local newValue = not convar:GetBool()

        SetConVarValue(convar, newValue)

        surface.PlaySound(
            "glide/headlights_on.wav"
        )

        targetProgress = newValue and 1 or 0
    end
end

function hg.CreateButton(
    buttonData,
    convarName,
    ParentPanel,
    yPos
)
    local convar = GetConVar(convarName)

    if not convar then
        return
    end

    local panel = vgui.Create(
        "DPanel",
        ParentPanel
    )

    panel:SetSize(
        ParentPanel:GetWide() / 1.05,
        ParentPanel:GetTall() / 15
    )

    panel:SetPos(
        ParentPanel:GetWide() / 2
            - panel:GetWide() / 2,
        yPos
    )

    local title = buttonData[3]
    local helpText = convar:GetHelpText() or ""
    local textWidth, textHeight

    surface.SetFont(
        "ZCity_setiings_fine"
    )

    textWidth, textHeight =
        surface.GetTextSize(title)

    local convarType =
        buttonData[6]
        or hg.GetConVarType(convar)

    panel.SettingSeed = math.random(1, 10000)

    panel.Paint = function(self, w, h)
        DrawSettingPanel(
            self,
            w,
            h,
            title,
            helpText,
            self.SettingSeed
        )
    end

    if convarType == "bool" then
        local toggle = vgui.Create(
            "DButton",
            panel
        )

        toggle:SetSize(
            panel:GetWide() / 18,
            panel:GetTall() / 2
        )

        toggle:SetPos(
            panel:GetWide()
                - toggle:GetWide() * 1.4
                - panel:GetWide() / 20,
            panel:GetTall() / 2
                - toggle:GetTall() / 2
        )

        toggle:SetText("")

        StyleToggle(
            toggle,
            convar,
            convar:GetBool()
        )

    elseif convarType == "int" then
        local slider = vgui.Create(
            "DNumSlider",
            panel
        )

        slider:SetSize(280, 30)

        slider:SetPos(
            panel:GetWide() - 300,
            panel:GetTall() / 2 - 15
        )

        slider:SetText("")

        local minimum = convar:GetMin() or 0
        local maximum = convar:GetMax() or 100
        local decimals = buttonData[4]
            and 2
            or 0

        slider:SetMin(minimum)
        slider:SetMax(maximum)
        slider:SetDecimals(decimals)

        slider:SetValue(
            decimals > 0
                and convar:GetFloat()
                or convar:GetInt()
        )

        slider.Paint = function(self, w, h)
            local progress = self:IsHovered()
                and 1
                or 0

            surface.SetDrawColor(
                settingsTheme.sliderBackground.r,
                settingsTheme.sliderBackground.g,
                settingsTheme.sliderBackground.b,
                settingsTheme.sliderBackground.a
            )

            surface.DrawRect(
                0,
                h / 2 - ScreenScale(1),
                w,
                ScreenScale(2)
            )

            surface.SetDrawColor(
                settingsTheme.borderBright.r,
                settingsTheme.borderBright.g,
                settingsTheme.borderBright.b,
                110 + progress * 100
            )

            surface.DrawRect(
                0,
                h / 2 - ScreenScale(1),
                w,
                ScreenScale(2)
            )
        end

        function slider:OnValueChanged(value)
            if not convar then return end

            SetConVarValue(
                convar,
                decimals > 0
                    and math.Round(value, decimals)
                    or math.Round(value)
            )
        end

        local valueLabel = vgui.Create(
            "DLabel",
            panel
        )

        valueLabel:SetPos(
            panel:GetWide() - 350,
            panel:GetTall() / 2 - 8
        )

        valueLabel:SetSize(50, 20)
        valueLabel:SetFont(
            "ZCity_setiings_tiny"
        )

        valueLabel:SetTextColor(
            settingsTheme.softGrayPink
        )

        valueLabel:SetText(
            convar:GetInt()
        )

        valueLabel.Think = function(self)
            if not convar then return end

            self:SetText(
                decimals > 0
                    and convar:GetFloat()
                    or convar:GetInt()
            )
        end

        valueLabel.Paint = function(self, w, h)
            DrawAnimatedText(
                self:GetText(),
                "ZCity_setiings_tiny",
                0,
                h / 2,
                TEXT_ALIGN_LEFT,
                TEXT_ALIGN_CENTER,
                panel.SettingSeed + 25
            )
        end

    elseif convarType == "string" then
        local textEntry = vgui.Create(
            "DTextEntry",
            panel
        )

        textEntry:SetSize(
            panel:GetWide() / 8,
            panel:GetTall() / 2
        )

        textEntry:SetPos(
            panel:GetWide()
                - panel:GetWide() / 8
                - 20,
            panel:GetTall() / 2
                - textEntry:GetTall() / 2
        )

        textEntry:SetText(
            convar:GetString()
        )

        textEntry:SetUpdateOnType(true)
        textEntry:SetFont(
            "ZCity_Tiny"
        )

        textEntry.Paint = function(self, w, h)
            local progress = self:IsHovered()
                and 1
                or 0

            surface.SetDrawColor(
                settingsTheme.input.r,
                settingsTheme.input.g,
                settingsTheme.input.b,
                settingsTheme.input.a
            )

            surface.DrawRect(0, 0, w, h)

            local border = LerpColor(
                progress,
                settingsTheme.border,
                settingsTheme.borderBright
            )

            surface.SetDrawColor(
                border.r,
                border.g,
                border.b,
                border.a
            )

            surface.DrawOutlinedRect(0, 0, w, h, 1)

            self:DrawTextEntryText(
                settingsTheme.white,
                settingsTheme.pink,
                settingsTheme.white
            )
        end

        function textEntry:OnValueChange(value)
            if not convar then return end

            SetConVarValue(
                convar,
                value
            )
        end
    end

    return panel
end

function hg.DrawSettings(ParentPanel)
    if not IsValid(ParentPanel) then
        return
    end

    ParentPanel:SetAlpha(0)

    -- Меняется только фон содержимого вкладки «Настройки».
    ParentPanel.Paint = function(self, w, h)
        DrawSettingsBackground(w, h)
    end

    hg.DrawBlur(ParentPanel, 5)

    ParentPanel:AlphaTo(
        255,
        0.15,
        0
    )

    local settingsScroll = vgui.Create(
        "DScrollPanel",
        ParentPanel
    )

    settingsScroll:SetSize(
        ParentPanel:GetWide(),
        ParentPanel:GetTall()
    )

    settingsScroll:SetPos(0, 0)

    settingsScroll.Paint = function()
    end

    local settingsBar =
        settingsScroll:GetVBar()

    settingsBar:SetWide(
        ScreenScale(5)
    )

    settingsBar:SetHideButtons(true)

    settingsBar.Paint = function(self, w, h)
        surface.SetDrawColor(
            settingsTheme.backgroundSoft.r,
            settingsTheme.backgroundSoft.g,
            settingsTheme.backgroundSoft.b,
            220
        )

        surface.DrawRect(0, 0, w, h)
    end

    settingsBar.btnGrip.Paint = function(self, w, h)
        local progress = self:IsHovered()
            and 1
            or 0

        local color = LerpColor(
            progress,
            settingsTheme.border,
            settingsTheme.borderBright
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

    local yOffset =
        settingsScroll:GetTall() / 100

    for categoryName, categoryTable in pairs(
        hg.settings.tbl
    ) do
        local category = hg.CreateCategory(
            categoryName,
            settingsScroll,
            yOffset
        )

        yOffset =
            yOffset
            + category:GetTall()
            + 12

        for convarName, settingData in pairs(
            categoryTable
        ) do
            local settingPanel = hg.CreateButton(
                settingData,
                convarName,
                settingsScroll,
                yOffset
            )

            if not settingPanel then
                continue
            end

            yOffset =
                yOffset
                + settingPanel:GetTall()
                + 12
        end
    end

    local endPanel = vgui.Create(
        "DPanel",
        settingsScroll
    )

    endPanel:SetSize(0, 0)

    endPanel:SetPos(
        0,
        yOffset + 12
    )

    endPanel.Paint = function()
    end
end
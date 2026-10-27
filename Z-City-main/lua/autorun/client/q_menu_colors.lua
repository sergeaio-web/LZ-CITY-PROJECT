if CLIENT then
    -- === ПЕРЕОПРЕДЕЛЯЕМ ЦВЕТА Q-MENU ===
    -- Эти значения отменяют/заменяют стандартные цвета из cl_hud.lua

    -- Основные цвета
    local qmenu_bg = Color(20, 20, 24, 180)       -- фон/тёмный
    local qmenu_bg_select = Color(50, 80, 140, 200) -- выделенный сектор
    local qmenu_text = Color(255, 255, 255, 255)  -- белый текст
    local qmenu_text_hover = Color(120, 220, 255, 255) -- текст при наведении
    local qmenu_center = Color(12, 12, 16, 220)   -- центр круга
    local qmenu_outline = Color(255, 255, 255, 40) -- обводка/свет

    -- Переопределяет цвета прямо в момент отрисовки
    hook.Add("HUDPaint", "CustomQMenuColors", function()
        if not IsValid(MENUPANELHUYHUY) then return end

        -- В этом проекте цвета берутся из глобальных переменных внутри cl_hud.lua.
        -- Меняем их здесь, чтобы не трогать логику меню.
        colBlack = qmenu_bg
        colOption = qmenu_bg_select
        colWhite = qmenu_text
        colWhiteTransparent = qmenu_text_hover
        colTransparent = Color(0, 0, 0, 0)

        -- Для стилей с подсветкой и центральной точкой
        if menuPanel then
            -- Ничего не делаем, просто даём возможность кастомизировать глобальные переменные
        end
    end)

    -- === ВАЖНО: это дополнение не меняет саму механику. ===
    -- Оно только меняет цвета, которые используются в Q-menu.
end
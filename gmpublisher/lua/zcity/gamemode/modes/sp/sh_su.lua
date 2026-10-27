local MODE = MODE or {}
zb = zb or {}

-- Регистрация системного имени мода
MODE.name = "BATTLESVSU"
MODE.PrintName = "Сельские против Городских"

-- Конфигурация команд для HUD
TEAM_VILLAGE = 1
TEAM_URBAN   = 2

teams = teams or {}
teams[TEAM_VILLAGE] = {
    name = "Сельские",
    objective = "Защитите свою территорию и избейте этих мразей!",
    color1 = Color(220, 130, 20),
    color2 = Color(255, 200, 50)
}

teams[TEAM_URBAN] = {
    name = "Городские",
    objective = "Покажите этим деревенщинам, кто правит улицами сука!",
    color1 = Color(0, 162, 255),
    color2 = Color(100, 200, 255)
}

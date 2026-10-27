MODE.name = "brawl"
local MODE = MODE
zb = zb or {}
MODE.RoundMusic = "brawl/round_loop.mp3"

-- Таблица локализации
MODE.Lang = {
    en = {
        role_survivor = "Survive. Be the last standing.",
        role_berserk = "Berserker",
        role_cop = "STOP HIM! (Cop)",
        role_vigilante = "VIGILANTE!",

        screen_cop_title = "STOP HIM! (Cop)",
        screen_cop_sub = "He's out of control! Kill this motherfucker!",
        screen_vigilante_title = "VIGILANTE! Serve justice!",
        screen_vigilante_sub = "The law is dead. You have a shotgun, blow his fucking head off!",

        cuffed = "(%s) was cuffed and neutralized! What a pussy!",
        mvp_chat = "[BRAWL] Round MVP: %s racked up %d kills!",
        out_of_round = "You're out of the round.",

        weapon_pick = "Choose your weapon (%d sec)",
        nobody = "Nobody",
        brawl_over = "Bloodbath Over",
        draw = "Draw",
        winner = "Winner: %s",
        mvp_hud = "Round MVP: %s",
        killboard = "Killboard",
        unknown = "Unknown",

        berserk_you = "YOU ARE THE BERSERK! RIP AND TEAR!",
        berserk_other = "%s became the BERSERK!",
        berserk_sub = "Kill this maniac before he slaughters everyone!",

        berserk_dead_title = "THE BERSERK IS DEAD!",
        berserk_dead_sub = "(%s) is dead. Back to normal.",

        waiting = "Waiting...",
        time_left = "Time left: %s",
        lives = "Lives: %d",
        kills = "Kills: %d",
        survivors = "Survivors left: %d",
        respawn_in = "Respawning in: %.1f",
        ffa_desc = "Melee Free-For-All. Trust no one."
    },
    ru = {
        role_survivor = "Останься последним выжившим.",
        role_berserk = "Берсерк",
        role_cop = "ОСТАНОВИ ЕГО! (Полицейский)",
        role_vigilante = "САМОСУД!",

        screen_cop_title = "ОСТАНОВИ ЕГО! (Полицейский)",
        screen_cop_sub = "Он вышел из-под контроля! Ебашь его нахуй!",
        screen_vigilante_title = "САМОСУД! Верши правосудие!",
        screen_vigilante_sub = "Закона больше нет. У тебя есть дробовик, ебашь его нахуй!",

        cuffed = "(%s) был скован наручниками и обезврежен!",
        mvp_chat = "[BRAWL] MVP Раунда: %s сделал %d убийств(а)!",
        out_of_round = "Ты выбыл из раунда.",

        weapon_pick = "Выбор оружия (%d сек)",
        nobody = "Нет",
        brawl_over = "Brawl завершён",
        draw = "Ничья",
        winner = "Победитель: %s",
        mvp_hud = "MVP Раунда: %s",
        killboard = "Таблица Убийств",
        unknown = "Неизвестно",

        berserk_you = "ТЫ СТАЛ БЕРСЕРКОМ!",
        berserk_other = "%s стал БЕРСЕРКОМ!",
        berserk_sub = "Убейте безумца, пока он не убил всех!",

        berserk_dead_title = "БЕРСЕРК БЫЛ УБИТ!",
        berserk_dead_sub = "(%s) мертв. Обычный режим.",

        waiting = "Ожидание...",
        time_left = "До конца: %s",
        lives = "Жизни: %d",
        kills = "Убийства: %d",
        survivors = "Выживших сейчас: %d",
        respawn_in = "Респавн через: %.1f",
        ffa_desc = "FFA с холодным оружием"
    }
}

-- Умная функция перевода с поддержкой форматирования строк
function MODE:L(key, ...)
    local lang = (CLIENT and GetConVar("gmod_language") and GetConVar("gmod_language"):GetString()) or "en"
    local tbl = self.Lang[lang] or self.Lang.en
    local str = tbl[key] or self.Lang.en[key] or key
    
    if select("#", ...) > 0 then
        return string.format(str, ...)
    end
    return str
end
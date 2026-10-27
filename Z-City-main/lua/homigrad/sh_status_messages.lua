local allowedchars = {
	"АХ",
	"АГХХ",
	"гхх",
	"ШХХ",
	"АХХХ",
}

local audible_pain = {
	"AAAAAГХ.. БЛЯТЬ.. КАК БОЛИТ.",
	"Я БОЛЬШЕ ТАК НЕ МОГУ!",
    "ОСТАНОВИТЕ ЭТО, ОСТАНОВИТЕ, ОСТАНОВИТЕ!",
    "ПОЧЕМУ ЭТО НЕ ОСТАНАВЛИВАЕТСЯ",
    "ВЫРУБИ МЕНЯ  ПОЖАЛУЙСТА",
    "Зачем я родился, чтобы это чувствовать, зачем...",
    "Я бы сделал всё, чтобы это остановилось... ВСЁ.",
    "Это не жизнь, это пытка",
    "Мне всё равно, просто ОСТАНОВИТЕ БОЛЬ",
    "Ничто не имеет значения, КРОМЕ ТОГО, ЧТОБЫ ОСТАНОВИТЬ ЭТО...",
    "Каждая секунда — вечность БОЛИ",
    "СМЕРТЬ БЫ БЫЛА ПОЩАДОЙ СЕЙЧАС...",
    "Только один момент без боли..",
	"ХОТЕЛОСЬ БЫ У МЕНЯ БЫЛИ ОБЕЗБОЛИВАЮЩИЕ. БЛЯТЬ.",
}

local sharp_pain = {
	"AAAГХ",
	"AAAХ",
	"AAaaГХ",
	"AAaaAХ",
	"AAaaAAAХГ",
	"AAaaAГ",
	"AAaAaaХ",
	"AAAAAaaХ",
	"AAaaAХХХ",
	"AAaAA",
	"AAAAAa",
	"AAAAaAAAaaaaГХХХ",
	"AAAaaAa",
	"AaaAAaгхп",
	"aaAaaAaфф",
	"aaаахх",
	"AAAaaПХХХ",
	"AAAaaAAХХ",
	"AAAaaAAAAAaGHHHH",
	"AAAaaAAAAAaGHAAAHHH",
	"AAAaaAAAAAaGHHAAAAAAHH",
	"AAAaaAAAAAaGHHHH",
	"AAAaaAAAaaAAAaGHHHH",
	"AAAaaAAAaaAAAaAAAAAAAGHHHH",
	"AAAaaAAAAAaGHHHH",
	"AAAaaAAAAAAAAAHHH",
	"AAAaaAAAAAaGHAaaaHH",
	"AAAaaAAAAAaAaaaaaAAAAHH",
	"AAAaaAAAAAaAAAAAAAADGHHHH",
	"AAAaaAAAaaAAAaAAAAAAAAAAAAGGGGGGAGHHHH",
	"AAAaaAAAaaAAAaAAAAAAAAAAAAAAAAAAH",
}

hg.sharp_pain = sharp_pain

local random_phrase = {
	"Здесь как-то прохладно...",
	"Всё кажется слишком тихим...",
	"Дыхание сейчас странно приятно.",
	"Что если эта тишина продлится вечно?",
	"Почему ничего не происходит?",
	"Я слышу собственное сердцебиение...",
	"Тишина почти оглушает.",
	"Время ощущается... как-то по-другому.",
	"Кто-нибудь здесь вообще есть?",
	"Как давно я тут стою?",
	"Воздух на вкус затхлый.",
	"Не помню, как я сюда попал.",
	"Ничего никогда не меняется, не так ли?",
	"Я как будто не в себе сейчас.",
	"Мои мысли так громки в этой тишине.",
	"Когда стало так темно?",
	"Мне кажется, за мной наблюдают.",
	"Всё на своих местах, как прежде.",
	"Кто-нибудь знает, что я здесь?",
	"Стены будто стали ближе.",
	"О чём я только что думал?",
	"Время здесь движется странно.",
	"Не помню, когда что-то в последний раз менялось.",
	"Тишина начинает казаться живой.",
}

local fear_hurt_ironic = {
	"Бьюсь об заклад, в этом есть урок... если выживу.",
	"Моему будущему биографу это не понравиться.",
	"Ну вот и дурацкий способ погибнуть.",
	"По крайней мере, моя жизнь не была скучной.",
	"Запомни никогда так не делать.",
	"Это не самый худший день, чтобы умереть.",
	"Всё в порядке. Всё нормально.",
	"По крайней мере я умру, зная, что был прав.",
	"Наверное, я получаю то, что заслужил.",
	"Ну что ж, я просил приключений.",
	"Наверное, на моих похоронах будут смеяться.",
	"По крайней мере это будет хорошая история... если кто-то переживёт, чтобы услышать.",
	"Я пережил худшее... наверное.",
}

local fear_phrases = {
	"Всё не так уж плохо... разве нет?",
	"Я не хочу так умирать.",
	"Неужели это конец?",
	"Это плохо.",
	"Неужели так всё заканчивается?",
	"Я не хочу так умирать.",
	"Хочу найти выход.",
	"Я о многом жалею.",
	"Это не может быть концом.",
	"Не могу поверить, что это со мной происходит.",
	"Надо было отнестись серьёзнее.",
	"А что если я не выживу..?",
	"Это хуже, чем я думал.",
	"Это так несправедливо.",
	"Я не могу сдаться сейчас.",
	"Я и не думал, что всё будет так.",
	"Надо было прислушаться к инстинктам.",
	"Дыши. Просто дыши.",
	"Холодные руки. Спокойные руки.",
}

local is_aimed_at_phrases = {
    "О Боже. Это оно.",
    "Не двигайся.",
    "Неужели так я и умру?",
    "Надо было бежать. Почему я не побежал?",
    "Пожалуйста, не нажимай на курок. Пожалуйста.",
    "Вижу палец на курке.",
    "Я не хочу умирать. Не так.",
    "Если я попрошусь на коленях, не станет ли хуже?",
    "Не может быть, что это реально. Не может.",
    "Кто-нибудь помогите. Пожалуйста. Кто-нибудь.",
    "Я не хочу умирать в таком месте.",
    "Не хочу, чтобы моя последняя мысль была о страхе.",
    "Я не хочу умирать.",
}

local near_death_poetic = {
	"Пытаюсь встать... но не могу...",
	"Дыхание — как мелкие глотки пустоты...",
	"Не понимаю, открыты у меня глаза или нет...",
	"Последнее, что я почувствую — кровь и медь во рту.",
	"Всё эхом отзывается в голове.",
	"Не помню, как вообще стоять.",
	"Всё отзвучивает внутри моего черепа.",
	"Моргание кажется бесконечным.",
	"Пальцы не хотят сжиматься вокруг ничего.",
	"Лёгкие не хотят наполняться.",
	"Сейчас смыслы сожалений потеряли значение.",
}

local near_death_positive = {
	"Я не хочу умирать.",
	"Я должен выжить.",
	"Ещё есть шанс.",
	"Я не позволю страху победить.",
	"Ещё один шанс.",
	"Я не умру здесь.",
	"Ладно... продумай это.",
	"Сиди тихо. Движение только хуже.",
	"Дыши медленно. Паника не поможет.",
	"Ещё не всё кончено.",
	"Боль — всего лишь сигнал. Игнорируй её.",
	"Если это и конец... по крайней мере будет быстро.",
	"Я переживал и худшее. Наверное.",
	"Это не то, как я себе это представлял.",
}

local broken_limb = {
	"БЛЯТЬ. БЛЯТЬ. ОН ОПРЕДЕЛЁННО СЛОМАН!",
	"Я ЧУВСТВУЮ КАК ОСКОЛКИ КОСТИ ДВИГАЮТСЯ!",
	"ОНО ЧЁРТОВО СЛОМАНО. ДАВАЙ..",
	"Болит просто от мысли об этом. Точно сломано.",
	"Думаю, здесь не должно так гнуться.",
	"Ох блять. Оно сломано.",
	"Я не вижу открытого перелома, но чувствую, что что-то сломано",
}

local dislocated_limb = {
	"Да, так сгибаться не должно.",
	"Надо вернуть кость на место.",
	"Нет... надо подтолкнуть её назад.",
	"Тут так болит, нужно проверить.",
	"Моя конечность не на месте.",
}

local hungry_a_bit = {
    "Мгх, я голоден...",
    "Немного еды было бы неплохо...",
    "Я голоден...",
    "Надо бы что-нибудь съесть.",
}

local very_hungry = {
    "Мой живот... Ухх...",
    "Если я не поем, станет ещё хуже...",
    "Живот... Чёрт... Меня тошнит",
}

local after_unconscious = {
    "Что случилось? Болит...",
	"Где я? Почему болит...",
	"Я думал, что умру...",
	"Моя голова... Что произошло?",
	"Неужели я сейчас чуть не умер?",
	"Было ощущение, будто я умирал.",
	"Небеса меня не забрали?",
	"Ох блять... голова раскалывается...",
	"Ох, будет трудно встать сейчас... но надо...",
	"Я не узнаю это место... или узнаю?",
	"Я никогда больше не хочу этого испытывать!",
}

local slight_braindamage_phraselist = {
	"Я не понимаю...",
	"Это не имеет смысла...",
	"Где я?",
	"Э? Что это..?",
	"Я не знаю, что происходит...",
	"Алло?",
	"Уххх оййй... эээ...",
}

local braindamage_phraselist = {
	"Бббеее.. уэеа мгх?!",
	"Бммеее... мехк...",
	"Мм--ххх. Ммм?",
	"Гхмгх вххх...",
	"Аггг... мг?",
	"Хггхх... Д-Дммх.",
	"Лмммпф, мп-хф!",
	"Хееллльхппхп...",
	"Нгхх... Гмх?",
	"Ггг... Бгх..",
	"Бхррахйн.",
}

local cold_phraselist = {
	"Становится очень холодно..",
	"Слишком холодно для меня.",
	"Я дрожу, чёрт возьми, блин.",
	"Очень зябко здесь..",
	"Надо что-нибудь, чтобы согреться...",
	"Мне довольно холодно...",
	"Я от этого холода болею, чёрт.",
}

local freezing_phraselist = {
	"Я.. не чую своё т- тело..",
	"Я не чувствую.. свои ноги...",
	"Я блядски мёрзну..",
	"Я-её.. кажется, лицо немеет..",
	"Холод..",
	"Я.. не чувствую ничего..",
}

local numb_phraselist = {
	"Больше не.. холодно..",
	"Почему... теперь тепло..?",
	"Кажется, я в порядке... наверное...",
	"Наконец-то тепло...",
	"Я снова тёплый... Как-то так...",
	"Я только что замерзал... Откуда эта жара..?",
}

local hot_phraselist = {
	"Я так потею..",
	"Эта жара меня убивает..",
	"На одежде весь пот, блядь.",
	"Мой пот ужасно воняет. Надо охладиться...",
	"Здесь слишком жарко, чёрт.",
	"Я сильно перегреваюсь...",
	"Почему тут так жарко?",
}

local heatstroke_phraselist = {
	"МНЕ НУЖНА ВОДА!!",
	"Пожалуйста... Воды...",
	"Мне дурно... Фуух-",
	"ГОЛОВА!- Болит..",
	"Голова раскалывается..",
}

local heatvomit_phraselist = {
	"От этой жары... меня сейчас стошнит-",
	"Уггхх... Я вот-вот вырву-",
	"Блять.. Оуугхх.. Мне плохо-"
}

local hg_showthoughts = ConVarExists("hg_showthoughts") and GetConVar("hg_showthoughts") or CreateClientConVar("hg_showthoughts", "1", true, true, "Переключает мысли вашего персонажа", 0, 1)

function string.Random(length)
	local length = tonumber(length)

    if length < 1 then return end

    local result = {}

    for i = 1, length do
        result[i] = allowedchars[math.random(#allowedchars)]
    end

    return table.concat(result)
end

function hg.nothing_happening(ply)
	if not IsValid(ply) then return end

	return ply.organism and ply.organism.fear < -0.6
end

function hg.fearful(ply)
	if not IsValid(ply) then return end

	return ply.organism and ply.organism.fear > 0.5
end

function hg.likely_to_phrase(ply)
	local org = ply.organism

	local pain = org.pain
	local brain = org.brain
	local blood = org.blood
	local fear = org.fear
	local temperature = org.temperature
	local broken_dislocated = org.just_damaged_bone and ((org.just_damaged_bone - CurTime()) < -3)

	return (broken_dislocated) and 5
		or (pain > 65) and 5
		or (temperature < 31 and 0.5)
		or (temperature > 38 and 0.5)
		or (blood < 3000 and 0.3)
		or (fear > 0.5 and 0.7)
		or (brain > 0.1 and brain * 5)
		or (fear < -0.5 and 0.05)
		or -0.1
end

function IsAimedAt(ply)
    return ply.aimed_at or 0
end

local function get_status_message(ply)
	if not IsValid(ply) then
		if CLIENT then
			ply = lply
		else
			return
		end
	end

	local nomessage = hook.Run("HG_CanThoughts", ply) --ply.PlayerClassName == "Gordon" || ply.PlayerClassName == "Combine"
	if nomessage ~= nil and nomessage == false then return "" end

    if ply:GetInfoNum("hg_showthoughts", 1) == 0 then return "" end

	local org = ply.organism
	
	if not org or not org.brain then return "" end

	local pain = org.pain
	local brain = org.brain
	local temperature = org.temperature
	local blood = org.blood
	local hungry = org.hungry
	local broken_dislocated = org.just_damaged_bone and ((org.just_damaged_bone + 3 - CurTime()) < -3)
	local fear = org.fear
	local adrenaline = org.adrenaline

	if broken_dislocated and org.just_damaged_bone then
		org.just_damaged_bone = nil
	end
	
	local broken_notify = (org.rarm == 1) or (org.larm == 1) or (org.rleg == 1) or (org.lleg == 1)
	local dislocated_notify = (org.rarm == 0.5) or (org.larm == 0.5) or (org.rleg == 0.5) or (org.lleg == 0.5)
	local after_unconscious_notify = org.after_otrub

	if not isnumber(pain) then return "" end

	local str = ""

	local most_wanted_phraselist
	
	if temperature < 35 then
		most_wanted_phraselist = temperature > 31 and cold_phraselist or (temperature < 28 and numb_phraselist or freezing_phraselist)
	elseif temperature > 38 then
		most_wanted_phraselist = temperature < 40 and hot_phraselist or heatstroke_phraselist
	end

	if not most_wanted_phraselist and hungry and hungry > 25 and math.random(3) == 1 then
		most_wanted_phraselist = hungry > 45 and very_hungry or hungry_a_bit
	end

	if (blood < 3100) or (pain > 75) or (broken_dislocated) or (broken_notify) or (dislocated_notify) then
		if pain > 75 and (broken_dislocated) then
			most_wanted_phraselist = math.random(2) == 1 and audible_pain or (broken_notify and broken_limb or dislocated_limb)
		elseif pain > 75 then
			most_wanted_phraselist = audible_pain
		elseif broken_dislocated then
			most_wanted_phraselist = (broken_notify and broken_limb or dislocated_limb)
		end

		if pain > 100 then
			most_wanted_phraselist = sharp_pain
		end

		if not most_wanted_phraselist then
			if (broken_dislocated_notify) and (blood < 3100) then
				most_wanted_phraselist = blood < 2900 and (near_death_poetic) or (math.random(2) == 1 and (broken_notify and broken_limb or dislocated_limb) or near_death_poetic)
			--elseif(broken_dislocated_notify)then
				--most_wanted_phraselist = (broken_notify and broken_limb or dislocated_limb)
			elseif(blood < 3100)then
				if adrenaline > 1.3 and fear < 0.5 then
					most_wanted_phraselist = near_death_positive
				else
					most_wanted_phraselist = near_death_poetic
				end
			end
		end
	elseif after_unconscious_notify then
		most_wanted_phraselist = after_unconscious
	elseif hg.nothing_happening(ply) then
		most_wanted_phraselist = random_phrase

		if hungry and hungry > 25 and math.random(5) == 1 then
			most_wanted_phraselist = hungry > 45 and very_hungry or hungry_a_bit
		end
	elseif hg.fearful(ply) then
		most_wanted_phraselist = ((IsAimedAt(ply) > 0.9) and is_aimed_at_phrases or (math.random(10) == 1 and fear_hurt_ironic or fear_phrases))
	end

	if brain > 0.1 then
		most_wanted_phraselist = brain < 0.2 and slight_braindamage_phraselist or braindamage_phraselist
	end
	
	if most_wanted_phraselist then
		str = most_wanted_phraselist[math.random(#most_wanted_phraselist)]

		return str
	else
		return ""
	end
end

local allowedlist_types = {
	heatvomit = heatvomit_phraselist,
}

function hg.get_phraselist(ply, type)
	if not IsValid(ply) then
		if CLIENT then
			ply = lply
		else
			return
		end
	end
	
	local nomessage = ply.PlayerClassName == "Gordon" || ply.PlayerClassName == "Combine"

	if nomessage then return "" end
    if ply:GetInfoNum("hg_showthoughts", 1) == 0 then return "" end

	local org = ply.organism	
	if not org or not org.brain then return "" end

	if not isstring(type) or not allowedlist_types[type] then return "" end

	local needed_list = allowedlist_types[type]

	local str = needed_list[math.random(#needed_list)]
	return str
end

function hg.get_status_message(ply)
	local txt = get_status_message(ply)

	return txt
end
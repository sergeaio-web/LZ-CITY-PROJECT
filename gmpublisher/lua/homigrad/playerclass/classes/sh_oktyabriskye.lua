local CLASS = player.RegClass("OKTYABRSKIE")
 
function CLASS.Off(self)
    if CLIENT then return end
end

local russianNames = {
    "Александр", "Алексей", "Андрей", "Антон", "Артём",
    "Борис", "Вадим", "Валентин", "Валерий", "Василий",
    "Виктор", "Виталий", "Владимир", "Владислав", "Вячеслав",
    "Геннадий", "Георгий", "Глеб", "Григорий", "Даниил",
    "Денис", "Дмитрий", "Евгений", "Егор", "Иван",
    "Игорь", "Илья", "Кирилл", "Константин", "Лев",
    "Максим", "Михаил", "Никита", "Николай", "Олег",
    "Павел", "Пётр", "Роман", "Сергей", "Станислав",
    "Тимофей", "Тимур", "Фёдор", "Юрий", "Ярослав"
}
 local russianSurnames = {
    "Иванов", "Петров", "Сидоров", "Смирнов", "Кузнецов",
    "Попов", "Васильев", "Фёдоров", "Морозов", "Волков",
    "Алексеев", "Лебедев", "Семёнов", "Егоров", "Павлов",
    "Козлов", "Степанов", "Николаев", "Орлов", "Андреев",
    "Макаров", "Никитин", "Захаров", "Соколов", "Соловьёв",
    "Павлов", "Белов", "Медведев", "Толстой", "Осипов",
    "Тихонов", "Афанасьев", "Филимонов", "Константинов", "Борисов",
    "Григорьев", "Романов", "Воробьёв", "Сергеев", "Шаров"
}

--я бооог, чат гпт мне генерирует массив с именами я не должен писать имена сааам

local models = {
    "models/player/Group01/male_04.mdl",
    "models/player/Group01/male_02.mdl",
    "models/player/Group01/male_05.mdl",
	"models/player/Group01/male_06.mdl",
	"models/player/Group01/male_08.mdl",
    "models/player/Group01/male_09.mdl"
}

 
 
function CLASS.On(self)
    if CLIENT then return end
    ApplyAppearance(self,nil,nil,nil,true)
    local Appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()
    self:SetNWString("PlayerName", russianNames[math.random(#russianNames)] .. " " .. russianSurnames[math.random(#russianSurnames)] )
    self:SetModel(models[math.random(#models)])
    Appearance.AAttachments = "none"
    self:SetNetVar("Accessories", "none")
    self:SetBodygroup(0,9)
 
    self:SetSubMaterial()
    Appearance.AColthes = ""
    self:SetPlayerColor(Color(255,255,0):ToVector())
    
    
    
    self.CurAppearance = Appearance
end
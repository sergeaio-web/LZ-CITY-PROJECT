local CLASS = player.RegClass("ukr")

function CLASS.Off(self)
    if CLIENT then return end
    self:SetNetVar("HideArmorRender", false)
end

local ukrnames = {
    "Яків", "Федiр", "Добромисл", "Тімох", "Еміль",
    "Цвітан", "Світослав", "Явір", "Євлампій", "Георгій",
    "Світовид", "Світлогор", "Турбрід", "Юліан", "Юрій",
    "Микола"
}

local models = {
    "models/dejtriyev/mm14/ukrainian_soldier.mdl",
}

local function SetupRandomBodygroups(ply)
    -- Helmet (0-1)
    ply:SetBodygroup(3, math.random(0, 0))
    
    -- Headset (0-1)
    ply:SetBodygroup(4, math.random(0, 1))
    
    -- Vest (0-1)
    ply:SetBodygroup(5, math.random(0, 0))
    
    -- Hands (0-1)
    ply:SetBodygroup(6, math.random(0, 1))
    
    -- Heads Mask (0-1)
    ply:SetBodygroup(7, math.random(0, 1))
    
    -- band R (1/1)
    ply:SetBodygroup(8, 1)
    
    -- band L (1/1)
    ply:SetBodygroup(9, 1)
    
    -- torsopatches L (1-2)
    ply:SetBodygroup(10, math.random(0, 2))
    
    -- torsopatches R (1-2)
    ply:SetBodygroup(11, math.random(0, 1))
end

local function SetupRandomSkin(ply)
    local skinCount = 7
    local randomSkin = math.random(1, skinCount)
    ply:SetSkin(randomSkin)
end

function CLASS.On(self)
    if CLIENT then return end
    ApplyAppearance(self,nil,nil,nil,true)
    local Appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()
    Appearance.AAttachments = ""
    Appearance.AColthes = ""
    self:SetNWString("PlayerName","")
    self:SetPlayerColor(Color(90,75,0):ToVector())
    self:SetModel(table.Random(models))
	
	SetupRandomSkin(self)
	SetupRandomBodygroups(self)

    self:SetNetVar("Accessories", Appearance.AAttachments or "none")

    self:SetSubMaterial()
    self:SetNWString("PlayerName",ukrnames[ math.random(#ukrnames) ])
    self.CurAppearance = Appearance
    
    self:SetNetVar("HideArmorRender", true)
end
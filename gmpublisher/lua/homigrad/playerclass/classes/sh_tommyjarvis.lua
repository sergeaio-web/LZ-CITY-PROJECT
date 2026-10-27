
local CLASS = player.RegClass("tommyjarvis")

function CLASS.Off(self)
    if CLIENT then return end
end

 

local models = {
    "models/konnie/f13tommy/f13tommy.mdl",

}


function CLASS.On(self)
    if CLIENT then return end
    ApplyAppearance(self,nil,nil,nil,true)
    local Appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()
    self:SetNWString("PlayerName","Tommy Jarvis")
    self:SetPlayerColor(Color(300,0,0):ToVector())
    self:SetModel(models[math.random(#models)])
    Appearance.AAttachments = "none"
    self:SetNetVar("Accessories", Appearance.AAttachments or "none")
    self:SetBodygroup(2, 0)
 	
    self:SetSubMaterial()
    Appearance.AColthes = ""
    
    self.MeleeDamageMul = 1.4
    
    self.CurAppearance = Appearance

end
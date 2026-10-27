local CLASS = player.RegClass("Survivor")
 
function CLASS.Off(self)
    if CLIENT then return end
end

local models = {
    "models/player/Group02/male_02.mdl",
    "models/player/Group02/male_04.mdl",
    "models/player/Group02/male_06.mdl",
	"models/player/Group03/male_07.mdl",
	"models/player/Group03/male_09.mdl",
}
function CLASS.On(self)
    if CLIENT then return end
    ApplyAppearance(self, nil, nil, nil, true)
    local Appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()
    self:SetNWString("PlayerName", "")
    self:SetPlayerColor(Color(255, 255, 255):ToVector())
    self:SetModel(models[math.random(#models)])
    Appearance.AAttachments = "none"
    self:SetNetVar("Accessories", Appearance.AAttachments or "none")
    self:SetBodygroup(0, 0)
 
    self:SetSubMaterial()
    Appearance.AColthes = ""
    
    self.CurAppearance = Appearance
end
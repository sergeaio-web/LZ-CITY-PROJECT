local CLASS = player.RegClass("Butcher")
 
function CLASS.Off(self)
    if CLIENT then return end
end

local models = "models/theboys/butcher.mdl"
 
function CLASS.On(self)
    if CLIENT then return end
    ApplyAppearance(self, nil, nil, nil, true)
    local Appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()
    self:SetNWString("PlayerName", "Billy Butcher")
    self:SetModel(models)
    Appearance.AAttachments = "none"
    self:SetNetVar("Accessories", Appearance.AAttachments or "none")
    self:SetBodygroup(0, 0)
 
    self:SetSubMaterial()
    Appearance.AColthes = ""
    
    self.CurAppearance = Appearance
end
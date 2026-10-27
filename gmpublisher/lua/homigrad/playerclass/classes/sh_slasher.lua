
local CLASS = player.RegClass("Slasher")

function CLASS.Off(self)
    if CLIENT then return end
end

 

local killers = {
    Leatherface = {
        "models/player/leather.mdl"
    },

    Michael = {
        "models/players/mj_dbd_myers_2018.mdl"
    },

    Ghost = {
        "models/panman/arc_future.mdl"
    },

    Jason = {
        "models/models/konnie/jason4/jason4.mdl",
        "models/models/konnie/jasonpart2/jasonpart2.mdl",
        "models/models/konnie/jasonpart3/jasonpart3.mdl"
    }
}

local killerNames = {
    "Leatherface",
    "Michael",
    "Ghost",
    "Jason"
}


function CLASS.On(self)
    if CLIENT then return end

    ApplyAppearance(self,nil,nil,nil,true)

    local Appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()
	self:SetNWString("PlayerName","")
    self:SetPlayerColor(Color(255,0,0):ToVector())

    
local killer = killerNames[math.random(#killerNames)]

local modelList = killers[killer]
local model = modelList[math.random(#modelList)]

self:SetModel(model)

    Appearance.AAttachments = "none"
    self:SetNetVar("Accessories", Appearance.AAttachments or "none")
    self:SetBodygroup(0,9)

    self:SetSubMaterial()
    Appearance.AColthes = ""

    self.CurAppearance = Appearance

    timer.Simple(0, function()
        if not IsValid(self) then return end
        game.ConsoleCommand('give_supercrusher "' .. self:Nick() .. '"\n')
    end)
end

hook.Add("CanPlayerEnterVehicle", "ZombVehicle", function(ply, ent)
	if ply.PlayerClassName == "Slasher" then
		return false
	end
end)

hook.Add("ZB_CanLootInventory", "ZombCanLoot", function(ply, ent, canloot)
		if ply.PlayerClassName == "Slasher" then
			return ply, ent, false
		end
	end)

hook.Add("PlayerCanPickupWeapon", "SlasherCantPickup", function(ply, ent)
    if not IsValid(ply) or ply.PlayerClassName ~= "Slasher" then return end

    local class = ent:GetClass()

    if class ~= "weapon_hands_sh"
    and class ~= "weapon_slasher_axe"
    and class ~= "weapon_hg_spear_pro"
    and class ~= "weapon_hammer"
    and class ~= "weapon_hg_crowbar"
    and class ~= "weapon_hg_axe"
    and class ~= "weapon_hg_machete"
    and class ~= "weapon_leadpipe"
    and class ~= "weapon_buck200knife"
    and class ~= "weapon_slasher_chainsaw"
    and class ~= "weapon_slasher_kitchenknife"
    and class ~= "hg_sling"
    and class ~= "weapon_slasherhands_sh"
    and class ~= "weapon_hands_sh"
    and class ~= "weapon_tourniquet"
    and class ~= "weapon_hg_snowball"
    and class ~= "weapon_hg_bottle"
    and class ~= "weapon_hg_bottlebroken"
    and class ~= "weapon_hg_shovel"
    and class ~= "weapon_pan"
    and class ~= "weapon_hg_mug"
    and class ~= "weapon_hg_extinguisher"
    and class ~= "weapon_ram"
    and class ~= "weapon_hg_tonfa"
    and class ~= "weapon_hg_shuriken"
    and class ~= "weapon_smallconsumable"
    and class ~= "weapon_bigconsumable"
    and class ~= "ent_ammo_arrow"
    and class ~= "ent_ammo_nails"
    and class ~= "weapon_matches"
    and class ~= "weapon_ducttape"
    and class ~= "weapon_hg_tonfa"
    and class ~= "weapon_hg_glassshard"
    and class ~= "weapon_hg_sledgehammer"
    and class ~= "weapon_slasher_machete"
    and class ~= "weapon_bat"
    and class ~= "weapon_slasher_pitchfork"
    and class ~= "weapon_beartrap_homigrad"
    and class ~= "weapon_slasher_hatchet"
    and class ~= "weapon_hg_bow"
    and class ~= "weapon_victim_talkie"
    and class ~= "weapon_walkie_talkie"
    and class ~= "weapon_brick" then
        return false
    end
end)
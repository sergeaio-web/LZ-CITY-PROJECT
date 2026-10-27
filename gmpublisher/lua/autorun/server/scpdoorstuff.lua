hook.Add("EntityKeyValue", "SCPCBDCDoorStuff", function(ent, key, value)

	if ent:GetClass() == "func_button" and key == "OnPressed" then
		local values = string.Split(value, ",")
		timer.Simple(0, function()
			for k, v in ipairs(ents.FindByName(values[1])) do
				v.SCPCBDCIsOpenedBy = ent
				if !istable(v.SCPCBDCIsOpenedByMult) then
					v.SCPCBDCIsOpenedByMult = {}
				end
				v.SCPCBDCIsOpenedByMult[ent] = true
			end
			for k, v in ipairs(ents.FindByName(string.Replace(values[1], "toggle", ""))) do
				v.SCPCBDCIsOpenedBy = ent
				if !istable(v.SCPCBDCIsOpenedByMult) then
					v.SCPCBDCIsOpenedByMult = {}
				end
				v.SCPCBDCIsOpenedByMult[ent] = true	
			end
			for k, v in ipairs(ents.FindByName(string.Replace(values[1], "button", ""))) do
				v.SCPCBDCIsOpenedBy = ent
				if !istable(v.SCPCBDCIsOpenedByMult) then
					v.SCPCBDCIsOpenedByMult = {}
				end
				v.SCPCBDCIsOpenedByMult[ent] = true			
			end			
		end)
	end 

end)
/*
	Creates console variables and commands.
*/
local PR = CBW_PowerCards

//*** Enable/disable PowerCard system
PR.CV_Enabled = CV_RegisterVar{
	name = "powercards_enabled",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = {["Off"] = 0, ["On"] = 1, ["Force"] = 2}
}

//*** Toggle debug functionality
PR.CV_Debug = CV_RegisterVar{
	name = 'powercards_debug',
	defaultvalue = 0,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}

//*** Adjust item spawn rate
PR.CV_RespawnTime = CV_RegisterVar{
	name = "powercards_rate",
	defaultvalue = 15,
	flags = CV_NETVAR,
	PossibleValue = {MIN = 10, MAX = 999}
}

//*** Adjust item probabilities
COM_AddCommand("powercards_chance",function(player,item,chance)
	//Nil prompt
	if item == nil
		if player == consoleplayer
			//Show how it's done
			print("powercards_chance <item name or #> <probability>")
			//List all item probabilities
			for n,t in pairs(PR.Item)
				print("#"..n.." "..t.name..": "..t.chance)
			end
		end
		return
	end
	for n,t in pairs(PR.Item)
		//See if item argument matches an existing item name or number
		if string.lower(item) == string.lower(t.name) or item == tostring(n)
			//Nil prompt
			if chance == nil or tonumber(chance) == nil
				//Show item properties
				if player == consoleplayer
					print("#"..n.." "..t.name..": "..t.chance)
				end
				return
			end
			//Set item to new probability
			t.chance = max(tonumber(chance), -1)
			//Announce the new setting
			print("Item #"..n.." "..t.name.." probability has been set to "..t.chance)
			return
		end
	end
	//If we got this far, then something went wrong.
	if player == consoleplayer
		print('Could not find item with name/number "'..item..'"')
	end
end,COM_ADMIN)
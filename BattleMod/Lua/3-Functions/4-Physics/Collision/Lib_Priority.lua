local B = CBW_Battle
local PFunc = B.PriorityFunction
local S = B.SkinVars

B.InitPriority = function(player)
	player.battle_atk = 0 //Current attack priority
	player.battle_def = 0 //Current defense priority. If higher than enemy attack priority, player will not take damage. If equal, player will be "uncurled".
	player.battle_sfunc = nil //Index for a function returning whether a character has hit a "sweetspot" or "sourspot". Function allows arg1(player.mo) and arg2(otherplayer.mo). If true, battle_satk and battle_sdef override battle_atk and battle_def.
	player.battle_satk = 0 //Sweetspot/sourspot attack priority
	player.battle_sdef = 0 //Sweetspot/sourspot defense priority
	player.battle_hurttxt = nil //Attack text to display in message feed
	player.battle_extra = nil //Extra hit type param
end

B.SetPriority = function(player,atk,def,sfunc,satk,sdef,txt,extra)
	if atk != nil then player.battle_atk = atk end
	if def != nil then player.battle_def = def end
	if sfunc != nil then player.battle_sfunc = sfunc else player.battle_sfunc = nil end
	if satk != nil then player.battle_satk = satk end
	if sdef != nil then player.battle_sdef = sdef end
	if txt != nil then player.battle_hurttxt = txt end
	if extra != nil and type(extra)=="string" then
		player.battle_extra = extra
	end
end

//This function takes precedent over all other priority scripts
B.SuperPriority = function(player)
	if player
	and player.isjettysyn
	and not B.Overtime
	and not player.battlespawning
		B.SetPriority(player,1,0,nil,1,0)
	return true end
	return false
end



//Do frame priority
B.DoPriority = function(player)
	player.battle_atk = 0
	player.battle_def = 0
	player.battle_sfunc = nil
	player.battle_satk = 0
	player.battle_sdef = 0
	player.battle_hurttxt = nil
	player.battle_extra = nil
	local func = S[player.skinvars].func_priority
	local func2 = S[player.skinvars].func_priority_ext
	if not(func) then func = S[-1].func_priority end
	if not(func2) then func2 = S[-1].func_priority_ext end
	if not(B.SuperPriority(player))
		if func then
			func(player)
		end
		if func2 then
			func2(player)
		end
	end
end

//Add sweetspot/sourspot priority
B.DoSPriority = function(player,othermo)
	local func = player.battle_sfunc
	//Keep in mind that 'func' is string in this instance, NOT a function
	if not(func and PFunc[func]) then return end
	
	if PFunc[func](player.mo,othermo) then
		player.battle_atk = player.battle_satk
		player.battle_def = player.battle_sdef
	end
end
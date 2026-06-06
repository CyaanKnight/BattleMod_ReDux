local PR = CBW_PowerCards

//Item adding functions
local check = function(input, element_type, default)
	if type(input) != element_type 
		return default
	else
		return input
	end
end

local dofalse = do return false end
PR.AddItem = function(item)
	local _index = #PR.Item+1
	
	//General variables
	item.index = _index
	item.name = check($, "string", "Item"..tostring(_index))
	item.chance = check($, "number", 1)
	item.health = check($, "number", 1)
	item.flags = check($, "number", 0)
	item.state = check($, "number", S_POWERCARD_BLANK)
	item.mobj = check($, "number", MT_POWERCARD)
	item.mapthing = check($,"number",-1)

	//Add mapthing spawner
	if item.mapthing != -1
		PR.AddTypeSpawner(item.mapthing, _index)
	end

	//Functions
	item.func_spawn 	= check($, "function", dofalse)
	item.func_idle 		= check($, "function", dofalse)
	item.func_hold	 	= check($, "function", dofalse)
	item.func_touch 	= check($, "function", dofalse)
	item.func_drop 		= check($, "function", dofalse)
	item.func_expire	= check($, "function", dofalse)
	table.insert(PR.Item,item)
	PR.Item_Chances[_index] = item.chance
	print("\x84".."Added item"..#PR.Item..": "..tostring(item.name))
	return #PR.Item
end

//Check each tic for items in queue
addHook("PostThinkFrame",do
	local count = 0
	local Qu = CBW_PowerCardQueue
	while Qu and #Qu
		PR.AddItem(Qu[1])
		table.remove(Qu,1)
		count = $+1
	end
	if count > 0
		print("\x83".."Added "..count.." power cards")
	end
end)
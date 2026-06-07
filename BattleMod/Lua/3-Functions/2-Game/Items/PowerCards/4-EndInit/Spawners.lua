/*
	Handles spawners.
	See also: IObj_Spawn.lua
*/

local PR = CBW_PowerCards
local variance = FRACUNIT*3/10

--*** General Functions
PR.ResetAll = do
	if not(server) then return end
	if not(server.PR_Initialized) then return end
	local cv_time = PR.CV_RespawnTime.value*TICRATE
	local min_time = FixedMul(cv_time*FRACUNIT,FRACUNIT-variance)/FRACUNIT
	local max_time = FixedMul(cv_time*FRACUNIT,FRACUNIT+variance)/FRACUNIT
	server.PR_Timer = P_RandomRange(min_time, max_time)
	server.PR_SpawnPoints = {}
	server.PR_MobjsSpawned = {}
	server.PR_LocalSpawns = {}
	server.PR_SpawnNumber = 1
end

local shuffle = function(set)
	local sh = {}
	local size = #set
	for n = 1,size
		while sh[n] == nil
			local r = P_RandomRange(1,size)
			sh[n] = set[r]
			set[r] = nil
		end
	end		
	PR.DPrint("Shuffled "..size.." indices")
	return sh
end

PR.ResetTimer = do
	server.PR_Timer = PR.CV_RespawnTime.value*TICRATE
	PR.DPrint("Timer reset to "..PR.CV_RespawnTime.value.." seconds")
end


--*** Spawnpoint access/cycling
PR.GetNextSpawnPoint = do
	local n = server.PR_SpawnNumber
	if n < #server.PR_SpawnPoints
		server.PR_SpawnNumber = $+1
	else
		server.PR_SpawnNumber = 1
	end
	return server.PR_SpawnPoints[n]
end


--*** Random
PR.GetProbabilities = function(whitelist,blacklist)
	PR.DPrint("Getting probabilities: whitelist "..tostring(whitelist)..", blacklist "..tostring(blacklist))
	local t = {}
	for n,item in ipairs(PR.Item)
		if (not(whitelist) or item.flags&whitelist)
		and not(blacklist and item.flags&blacklist)
			for i = 1,server.PR_Item_Chances[item.index]
				table.insert(t,n)
			end
		end
	end	
	PR.DPrint("Got "..#t.." probabilities")
	return t
end

PR.GetRandomType = function(whitelist,blacklist)
	local p = PR.GetProbabilities(whitelist,blacklist)
	if #p == 0 return nil end
	local n = P_RandomRange(1,#p)
	return p[n]
end

--*** Spawning
PR.SpawnOccupied = function(mapthing)
	-- return (mapthing.mobj and mapthing.mobj.valid and not(mapthing.mobj.state == S_NULL))
	-- return PR.MobjsSpawned[#mapthing] and PR.MobjsSpawned[#mapthing].valid and PR.MobjsSpawned[#mapthing].state ~= NULL

	for key, data in ipairs(server.PR_MobjsSpawned) do
		if data.mapthing == mapthing
		and data.mobj
		and data.mobj.valid
		and data.mobj.state ~= S_NULL then
			return true
		end
	end

	return false
end

--*** Registering spawnpoints
local mapthing_table = function(...)
	local id = {}
	//Specified mapthing search
	for mapthing in mapthings.iterate
		for _,i in ipairs({...})
			if mapthing.type == i
				table.insert(id,mapthing)
			end
		end
	end
	return id
end

PR.AddTypeSpawner = function(mobjtype,item)
	local thingnum = mobjinfo[mobjtype].doomednum
	item = $ or 0
	local t = {
		mobjtype = mobjtype,
		thingnum = thingnum,
		item = item
	}
	table.insert(server.PR_MapThing,t)
end

PR.MapLoadHook = function()
	if titlemapinaction then return end
	PR.Initialize()

	for mapthing in mapthings.iterate
		//Get spawner type
		local item = nil
		for n,t in ipairs(server.PR_MapThing)
			if t.thingnum == mapthing.type
				item = t.item
				break
			end
		end
		if item == nil //Not a valid spawnpoint
			continue
		elseif PR.Item[item] //Specified items
			if mapthing.options&MTF_EXTRA //Local timer
			and server.PR_Item_Chances[item] != -1
				table.insert(server.PR_LocalSpawns,{mapthing,0})
			else //Global timer
				for n = 1, server.PR_Item_Chances[item]
					table.insert(server.PR_SpawnPoints,mapthing)
				end
			end
			//Store Item type as mapthing.angle
			mapthing.angle = item
		else //Random items
			if mapthing.options&MTF_EXTRA //Local timer
				table.insert(server.PR_LocalSpawns,{mapthing,0})
			else //Global timer
				table.insert(server.PR_SpawnPoints,mapthing)
			end
			//Item type is "random"
			mapthing.angle = 0
		end
-- 		print("spawn thing #"..#mapthing..", type "..mapthing.type)
	end
end


PR.GetSpawnPoints = do
	if titlemapinaction then return end
	if #server.PR_SpawnPoints != 0 then
		server.PR_SpawnPoints = shuffle($)
		return //Already have IDs? Don't need to generate more.
	end
	local n = 1
	PR.DPrint("Getting spawnpoints for power rings")
	//Main spawns
	local id = server.PR_SpawnPoints
	//Secondary spawns
	if #id == 0
		PR.DPrint("No primary spawnpoints found, searching match emerald spawns")
		id = mapthing_table(321)
	end
	//Tertiary spawns
	if #id == 0
		PR.DPrint("No match emerald spawns found, searching for multiplayer starts")
		id = mapthing_table(0)
	end
	//Last resort
	if #id == 0
		PR.DPrint("No multiplayer starts found, searching for player 1 starts")
		id = mapthing_table(1)
	end
	server.PR_SpawnPoints = shuffle(id) //Shuffle
	server.PR_SpawnNumber = 1 //Set Position
	PR.ResetTimer() //Reset timer
end

--*** Ticframe
PR.TicFrame = do
	if gamestate ~= GS_LEVEL then return end
	if titlemapinaction then return end
	PR.Initialize()
	local B = CBW_Battle
	local A = B.Arena
	if #server.PR_SpawnPoints == 0
	or B.SuddenDeath
	or not(((PR.CV_Enabled.value==1) and B.PowerCardsGametype()) or PR.CV_Enabled.value==2)
	return end
	//Local timers
	for n,t in ipairs(server.PR_LocalSpawns)
		local mapthing = t[1]
		local time = t[2]
		if PR.SpawnOccupied(mapthing)
			time = PR.CV_RespawnTime.value*TICRATE
		else
			if time == 0
				PR.SpawnItem(mapthing.angle, mapthing)
				time = PR.CV_RespawnTime.value*TICRATE
			else
				time = $-1
			end
		end
		t[2] = time
	end

	if server.PR_MobjsSpawned == nil then
		server.PR_MobjsSpawned = {}
	end

	for key = #server.PR_MobjsSpawned, 1, -1 do
		local data = server.PR_MobjsSpawned[key]

		if not (data.mobj and data.mobj.valid and data.mobj.state ~= S_NULL) then
			table.remove(server.PR_MobjsSpawned, key)
		end
	end

	//Global timer
	if B.PreRoundWait() return end
	server.PR_Timer = $-1
	if server.PR_Timer <= 0
		PR.ResetTimer()
		PR.SpawnItem()
	end
end

local vars = {
	"PR_SpawnPoints",
	"PR_Item_Chances",
	"PR_MobjsSpawned",
	"PR_MapThing",
	"PR_LocalSpawns"
}


--*** Initialize variables
PR.Initialize = do
	if not(server) then return end
	if server.PR_Initialized then return end
	server.PR_Timer = PR.CV_RespawnTime.value*TICRATE
	server.PR_SpawnNumber = 1
	for i = 1, #vars do
		server[vars[i]] = {}
	end
	for i = 1, #PR.Item do
		local card = PR.Item[i]
		if (server.PR_Item_Chances[card.index]==nil) then
			server.PR_Item_Chances[card.index] = card.chance
		end
		PR.AddTypeSpawner(card.mapthing, card._index)
	end
	PR.ResetAll()

	PR.AddTypeSpawner(MT_POWERCARDSPAWN_RANDOM)
	server.PR_Initialized = true
end

local test = {1, 2, 3}
COM_AddCommand("testtable", function()
	test = {}
	for i = 1, P_RandomRange(1, 10) do
		test[i] = i
	end
end)

PR.NetVars_Sync = function(network)
	--Power Cards
	--test = network($)
	--server.PR_Timer      = network($)
	--server.PR_Timer		 = network($)
	--server.PR_SpawnPoints	 = network($)
	--server.PR_SpawnNumber	 = network($)
	--PR.Item_Chances  = network($)
	--PR.MobjsSpawned  = network($)
end


-- addHook("ThinkFrame", do
-- 	local function tablelen(tabl)
-- 		local int = 0
-- 		for _, _ in pairs(tabl) do
-- 			int = $ + 1
-- 		end
-- 		return int
-- 	end
-- 	print("After:")
-- 	print("    "..#test)
-- 	print("    "..server.PR_Timer)
-- 	print("    "..#server.PR_SpawnPoints)
-- 	print("    "..server.PR_SpawnNumber)
-- 	print("    "..tablelen(PR.Item_Chances))
-- end)
/*
	Power Rings, page 6
	Handles debug info.
*/

local PR = CBW_PowerCards

//Print function
PR.DPrint = function(string,type)
	if PR.CV_Debug.value == 1
		if type == 'warning'
			string = '\x82'..'WARNING:\x81 '..$
		elseif type == 'error'
			string = '\x85'..'ERROR:\x81 '..$
		else
			string = '\x81'..$
		end
		print(string)
	end
end

//Spawn item
COM_AddCommand("powercards_spawn", function(player, type)
	if not(PR.CV_Debug.value) then return end
	PR.SpawnItem(tonumber(type))
end, COM_ADMIN)

//HUD
PR.DebugHUD = function(v, player, cam)
	local debug = PR.CV_Debug.value
	if not(debug) then return end
	local xoffset = 320
	local yoffset = 1
	local flags = V_HUDTRANS|V_SNAPTOTOP|V_SNAPTORIGHT|V_PERPLAYER
	local align = "small-right"
	local nextline = 4
	//Double the scale for smaller screens (illegible otherwise)
	if v.height() < 400 then 
		align = "right"
		nextline = 8
	end
	local addspace = function()
		yoffset = $+nextline
	end
	local addline = function(string,string2)
		string = "\x86"+tostring($)+": \x80"+tostring(string2)
		v.drawString(xoffset,yoffset,string,flags,align)
		yoffset = $+nextline
	end
	local addheader = function(string)
		yoffset = $+nextline
		string = "\x82"+string
		v.drawString(xoffset,yoffset,string,flags,align)
		yoffset = $+nextline
	end
	local subheader = function(string)
		string = "\x88"+string
		v.drawString(xoffset,yoffset,string,flags,align)
		yoffset = $+nextline
	end
	//****
	//Execute drawing
	//****
	addspace()//Added spacing, in case of Arena HUD
	addspace()
	addheader("Power Rings")
	addline("Item Types",#PR.Item)
	addspace()
	subheader("Settings")
	addline("Enabled",PR.CV_Enabled.value)
	addline("Respawn Time",PR.CV_RespawnTime.value)
-- 	for _,item in pairs(PR.Item)
-- 		addline(item.name, item.cv_frequency.value)
-- 	end
	addspace()
	subheader("Game")
	addline("Spawn Points",#PR.SpawnPoints)
	addline("Spawn #",PR.SpawnNumber)
	addline("Timer",PR.Timer/TICRATE)
	
	addspace()
	if player.gotpowercard and player.gotpowercard.valid
		local mo = player.gotpowercard
		local item = PR.Item[mo.item]
		subheader("Player Item")
		addline("name",item.name)
		addline("state",item.state)
		addline("chance",item.chance)
		addline("health",item.health)
		addline("flags",item.flags)
		addline("mapthing",item.mapthing)
-- 		addline("func_spawn",item.func_spawn)
-- 		addline("func_idle",item.func_idle)
-- 		addline("func_hold",item.func_hold)
-- 		addline("func_touch",item.func_touch)
-- 		addline("func_drop",item.func_drop)
-- 		addline("func_expire",item.func_expire)
	end
end

hud.add(PR.DebugHUD, player)
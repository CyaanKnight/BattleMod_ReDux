local PR = CBW_PowerCards
local claimsfx = sfx_lvpass

//* Player Touch
PR.NewOwner = function(mo,target)
	//Disassociate from previous card owner
	if mo.target and mo.target.valid
		PR.LoseOwner(mo,false)
	end
	local player = target.player
	
	//Properties
	mo.active = true
	mo.dropped = false
	mo.fuse = -1

	//Create new connection
	mo.target = target
	player.gotpowercard = mo
	player.tossdelay = max($,15)
	
	//Unset momentum
	mo.flags = ($|MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT)&~MF_BOUNCE
	mo.momx = 0
	mo.momy = 0
	mo.momz = 0
	
	//Do item function
	if PR.Item[mo.item].func_touch(mo,player)
		return
	end
	
	//FX
	S_StartSound(mo,claimsfx)
end

addHook("TouchSpecial",function(mo,pmo)
	if not(CBW_Battle) return end
	local player = pmo.player
	if mo.target != pmo and player.gotpowercard == nil and player.tossdelay <= 0
		PR.NewOwner(mo,pmo)
	end
	return true
end,MT_POWERCARD)
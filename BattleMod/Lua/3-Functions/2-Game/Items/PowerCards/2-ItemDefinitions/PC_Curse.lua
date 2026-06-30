local PR = CBW_PowerCards
local heatdeath_time = 10*TICRATE
local spinspeed = FixedAngle(15<<FRACBITS)
local lerpamt = FU >> 3

local doGhost = function(mo, frequency, color)
	if leveltime % frequency then
		return
	end
	
	local ghost = P_SpawnGhostMobj(mo)
	ghost.colorized = true
	ghost.color = color
	ghost.destscale = mo.scale + FU/3
end

local doParticle = function(mo, frequency, type)
	if leveltime % frequency then
		return
	end
	
	local range = mo.radius >> FRACBITS
	local hrange = mo.height >> FRACBITS
	local x, y = P_RandomRange(-range, range) * mo.scale, P_RandomRange(-range, range) * mo.scale
	local z = P_RandomRange(0 - hrange / 3, hrange) * mo.scale
	local particle = P_SpawnMobjFromMobj(mo, x, y, z, type)
	
	return particle
end

local overlayVars = function(mo, player)
	mo.skin = player.mo.skin
	mo.angle = player.drawangle
	mo.tics = -1
	
	mo.sprite = player.mo.sprite
	mo.sprite2 = player.mo.sprite2
	mo.frame = player.mo.frame
	
	mo.blendmode = AST_ADD
	mo.renderflags = $|RF_FULLBRIGHT
	mo.color = SKINCOLOR_PITCHORANGE
	mo.colorized = true
	
	mo.dispoffset = 5
	mo.flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY
	
	mo.scale = player.mo.scale - FU/15 + FixedMul(cos((leveltime % 30) * FixedAngle(12*FU)), FU/5)
end

local doHeatOverlay = function(mo)
	mo.pr_heatoverlay = $ or P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_THOK)
	
	local p = mo.player
	local mask = mo.pr_heatoverlay
	
	if mask and mask.valid then
		P_MoveOrigin(mask, mo.x ,mo.y, mo.z)
		overlayVars(mask, p)
	end
end

local SpawnFunc = function(mo)
	mo.turnradius = 0
	mo.turnangle = 0
	mo.frequency = 10
	mo.cardholders = {prev = 0, curr = 0}
end

local TouchFunc = function(mo,player)
	mo.turnradius = 0
	mo.turnangle = 0
	
	local holders = mo.cardholders
	holders[1] = holders[2]
	holders[2] = player
end

local HoldFunc = function(mo, player)
	--print(tostring(mo.cardholders[2]))
	player.mo.pr_heatnoguard = true
	
	local pmo = player.mo
	if mo.health > 1 then
		mo.health = $ - 1
		mo.turnangle = $ + 1
		
		if mo.health % 35 == 0 then
			mo.frequency = $ - 1
		end
		
		if mo.turnradius < 105*FU then
			mo.turnradius = $ + FU
		end
		
		doHeatOverlay(pmo)
		doGhost(mo, 3, SKINCOLOR_RED)
		
		local smoke = doParticle(pmo, mo.frequency, MT_SMOKE)
		if smoke and smoke.valid then
			smoke.colorized = true
			smoke.color = (G_GametypeHasTeams() and player.skincolor) or SKINCOLOR_BLACK
			smoke.momz = P_RandomRange(3, 6) * FU
			smoke.scale = pmo.scale + FU/3
		end
			
		local x, y = pmo.x + FixedMul(cos((mo.turnangle % 36) * ANG10), mo.turnradius),
					 pmo.y + FixedMul(sin((mo.turnangle % 36) * ANG10), mo.turnradius)
		
		P_MoveOrigin(mo, x, y, mo.z)
		
		--this part taken from IObj_Ticframe
		local distz = mo.target.z-mo.z
		if P_MobjFlip(mo.target) == -1
			distz = $ + FixedMul(mo.target.height,mo.target.scale) - FixedMul(mo.height,mo.scale)
		end
		mo.momz = FixedMul(lerpamt,distz)
		
		mo.angle = $ + spinspeed
		return true
	else
		if type(mo.cardholders[1]) == "userdata" then
			if mo.cardholders[1].ctfteam != mo.cardholders[2].ctfteam then
				P_AddPlayerScore(mo.cardholders[1], 100)	--award score to the previous player that held the card
			end
		end
		
		P_DamageMobj(pmo, mo)
		S_StartSound(pmo, sfx_brakrx)
		local boom = P_SpawnMobjFromMobj(pmo, 0, 0, 0, MT_EXPLODE)
		boom.state = S_TNTBARREL_EXPL1
		PR.FailureDeath(mo, player)
		return true
	end
end

local UnsetFunc = function(mo, player)
	local valid = player and player.mo and player.mo.pr_heatoverlay and player.mo.pr_heatoverlay.valid
	
	if valid then
		P_RemoveMobj(player.mo.pr_heatoverlay)
		player.mo.pr_heatoverlay = nil
	end
	
	player.mo.pr_heatnoguard = nil
	mo.turnradius = 0
	mo.turnangle = 0
end

table.insert(CBW_PowerCardQueue,{
	name 		= "Curse",
	chance		= 5,
	health		= heatdeath_time,
	flags		= PCF_NOTOSS,
	state		= S_POWERCARD_CURSE,
	mapthing	= MT_POWERCARDSPAWN_CURSE,
	func_spawn	= SpawnFunc,
	func_idle 	= nil,
	func_hold	= HoldFunc,
	func_touch	= TouchFunc,
	func_drop 	= UnsetFunc,
	func_expire	= UnsetFunc, 
})

--haaaaaaaaack
addHook("PreThinkFrame", function()
	local B = CBW_Battle
	if not (B) then
		return
	end
	
	for player in players.iterate do
		local check = player and player.mo and player.mo.pr_heatnoguard
		local buttoncheck = B.ButtonCheck(player, player.battleconfig_guard)
		if check and buttoncheck == 1 and player.canguard then
			player.cmd.buttons = $ & ~player.battleconfig_guard --no parrying with this card
		end
	end
end)

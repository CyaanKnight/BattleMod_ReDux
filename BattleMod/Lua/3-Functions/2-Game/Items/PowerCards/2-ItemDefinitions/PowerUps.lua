/*
	Power Rings, page 4
	Handles power ring event activations and status effects.
	
	TODO:
		Transfer all variables and functions to their respective item libraries.
		Transfer general purpose functions to a "general" library.
*/

local holdsfx = sfx_s3ka4

local PR = CBW_PowerCards

local hyper_time = 20*TICRATE

local exploding_time = TICRATE*3/2

local electrocuted_time = TICRATE*2

local randxy = function(range,x,y)
	return	x+P_RandomRange(-range/2,range/2)*FRACUNIT,
			y+P_RandomRange(-range/2,range/2)*FRACUNIT
end

local DoParticle = function(mo,time,particle,sound)
	if time%3 return end
	mo = mo.mo or $
	local range = mo.radius>>16
	local x = P_RandomRange(-range,range)*mo.scale
	local y = P_RandomRange(-range,range)*mo.scale
	local z = P_RandomRange(0,(mo.height - mobjinfo[particle].height)>>16) * mo.scale
	local p = P_SpawnMobjFromMobj(mo,x,y,z,particle)
	if sound
		S_StartSound(p,sound)
	end
	return p
end

local DoParticleExplosion = function(player)
	local mo = player.mo
	local type = MT_BOXSPARKLE
	local width = FRACUNIT*128
	local z = mo.z+FixedMul(mo.height-mobjinfo[type].height,mo.scale>>2)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,type,0,nil,true)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,type,ANGLE_22h,nil,true)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,type,ANGLE_45,nil,true)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,type,ANGLE_67h,nil,true)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,type,ANGLE_112h,nil,true)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,type,ANGLE_135,nil,true)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,type,ANGLE_157h,nil,true)
end

local DoLightning = function(mo,rate)
	if not(rate) rate = 1 end
	if leveltime%rate return false end
	local range = 16
	local x,y,z = mo.x,mo.y,mo.z
	local t = {MT_SUPERSPARK,MT_THUNDERCOIN_SPARK}//,MT_BOXSPARKLE,MT_NIGHTSPARKLE}
	local count = 1
	local flip = P_MobjFlip(mo)
	while ( (flip == 1 and z < mo.ceilingz) or (flip == -1 and z > mo.floorz) )
	and count < 64
		x,y = randxy(range,x,y)
		local type = t[P_RandomRange(1,#t)]
		z = $+mobjinfo[type].height*flip
		local p = P_SpawnMobj(x,y,z,type)
		p.fuse = 3
		count = $+1
	end
	return true
end

//General item functions
PR.HealCard = function(mo,player)
	mo.health = PR.Item[mo.item].health
end

PR.HealCardSFX = function(mo,player)
	mo.health = PR.Item[mo.item].health
	S_StartSound(mo,holdsfx)
end

PR.FirstPerson = function(player)
	return player == consoleplayer and CV_FindVar("chasecam").value == 0
end

//Charming returns!
PR.DoCharmed=function(player,charmtime)
	local skin = skins[player.mo.skin]
	//Register debuff and remove powerups
	if charmtime != nil then
		S_StartSound(pmo,sfx_kc59)
		player.charmedtime = charmtime
		player.actioncooldown = player.charmedtime
		player.charmed = true
		P_SwitchShield(player,0)
		player.powers[pw_sneakers] = min($,2)
		player.gotflagdebuff = true
	end
	//Apply debuff
	if player.charmedtime and player.charmed then
		if player.pflags&PF_JUMPED then
			player.pflags = $|PF_THOKKED
		end
		player.charability = 0
		player.normalspeed = skin.normalspeed*1/4
-- 		player.thrustfactor = skin.thrustfactor-1
		//Do aesthetic
		if not(player.charmedtime&6)
			player.mo.color = SKINCOLOR_CARBON
		else
			player.mo.color = player.skincolor
		end
	end
	//Unregister debuff and apply normal stats
	if not(player.charmedtime) and player.charmed then
		player.charmed = false
		S_StartSound(player.mo,sfx_kc5a)
		player.charability = skin.ability
		player.normalspeed = skin.normalspeed
-- 		player.thrustfactor = skin.thrustfactor
		player.mo.color = player.skincolor
		player.gotflagdebuff = false
	end
end


//Player Spawn/Init
local InitVars = function(player)
	player.pr_exploding = 0
	player.pr_electrocuted = 0
	player.gotpowercard = nil
end

addHook("PlayerSpawn",InitVars)
//Player Thinker
addHook("PlayerThink",function(player)
	if not(CBW_Battle) return end
	if player.powerrings_init == nil
		player.powerrings_init = true
		InitVars(player)
	end
	if player.spectator or player.playerstate != PST_LIVE return end
	local mo = player.mo
	local skin = skins[mo.skin]

	if player.gotpowercard and player.gotpowercard.valid
	and player.cmd.buttons&BT_TOSSFLAG and player.tossdelay <= 0
		player.justtossedflag = true
		player.shieldswap_cooldown = max($,15)
		PR.TossItem(player.gotpowercard)
	end

	--Hyper Card failsafe
	if mo.hyper_card and not(player.gotpowercard and player.gotpowercard.valid and PR.Item[player.gotpowercard.item].name == "Hyper") then
		player.thrustfactor = skin.thrustfactor
		player.jumpfactor = skin.jumpfactor
		player.gotflagdebuff = 0 //Let the previous stats get overwritten by CTF if necessary
		mo.hyper_card = nil
	end

	//Disabled
	PR.DoCharmed(player)
	
	//Exploding
	if player.pr_exploding > 0
		player.pr_exploding = $-1
		DoParticle(player,player.pr_exploding,MT_SONIC3KBOSSEXPLODE,sfx_s3kb4)
	end

	//Electrocuted
	if player.pr_electrocuted > 0
		//Timer
		player.pr_electrocuted = $-1
		//Lightning
		if player.pr_electrocuted > electrocuted_time - TICRATE/3
			DoLightning(mo,2)
		end
		//Coloration
		if player.pr_electrocuted > 0
			mo.colorized = true
			local t = {player.skincolor,SKINCOLOR_YELLOW,SKINCOLOR_BLACK,SKINCOLOR_WHITE}
			mo.color = t[P_RandomRange(1,#t)]
		else
			mo.color = player.skincolor
			mo.colorized = false
		end
		//Particles
		local p = DoParticle(player,player.pr_electrocuted,MT_THUNDERCOIN_SPARK)
			or DoParticle(player,player.pr_electrocuted-2,MT_SUPERSPARK)
		if p
			p.fuse = P_RandomRange(1,10)
			local s = P_RandomRange(0,10) * mo.scale
			local h = P_RandomRange(-10,10) * FRACUNIT
			local a = R_PointToAngle2(mo.x,mo.y,p.x,p.y)
			P_Thrust(p,a,s)
			P_SetObjectMomZ(p,h,true)
		end
		//Sound control
		if player.pr_electrocuted == 0 and S_SoundPlaying(player.mo,sfx_ssbshk)
			S_StopSound(player.mo)
		end
	end
end)
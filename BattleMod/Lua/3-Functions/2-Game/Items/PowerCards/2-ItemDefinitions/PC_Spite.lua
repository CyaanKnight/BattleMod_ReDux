local PR = CBW_PowerCards
local timer = TICRATE*3 + 10
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

local DoSpite = function(mo, player, pre) //Do spite
	if not(pre)
		S_StartSound(nil,sfx_litng2)
		P_StartQuake(FRACUNIT*20, 10)
	end
	local hitlist = {}
	//Search foes
	for foe in players.iterate
		if foe != player //Don't snipe ourselves!
		and foe.playerstate == PST_LIVE and not(foe.spectator or foe.exiting)
		and not(gametyperules&GTR_TEAMS and foe.ctfteam == player.ctfteam) //Don't snipe teammates
		and foe.rank == 1 //Only snipe the leader
			table.insert(hitlist, foe)
		end
	end
	if #hitlist == 0
		//No one found? The user must already be in first. In that case, we'll search for 2nd place.
		for foe in players.iterate
			if foe != player
			and foe.playerstate == PST_LIVE and not(foe.spectator or foe.exiting)
			and not(gametyperules&GTR_TEAMS and foe.ctfteam == player.ctfteam)
			and foe.rank == 2 //Second place
				table.insert(hitlist, foe)
			end
		end
	end
	if #hitlist == 0
		//Exit script if no one is found.
		return
	end
	
	//Apply effect to foes
	for _,foe in ipairs(hitlist)
		if pre
			DoLightning(foe.mo)
			S_StartSound(foe.mo,sfx_elctrc)
			continue
		end
		//Empty all resources
		foe.shieldstock = {}
		P_RemoveShield(foe)
		if foe.rings
-- 				P_PlayerRingBurst(foe)
-- 				P_PlayRinglossSound(foe.mo)
			foe.rings = 0
		end
		P_PlayerFlagBurst(foe)
		//Send foe into tumble state
-- 			P_DoPlayerPain(foe)
		CBW_Battle.ZLaunch(foe.mo,FRACUNIT*10,false)
		CBW_Battle.DoPlayerTumble(foe, 45, foe.mo.angle+ANGLE_180, foe.mo.scale*3, false)
-- 			foe.powers[pw_flashing] = TICRATE*2
		//Give points to the owner
		P_AddPlayerScore(player,100)
		//FX
		S_StartSound(foe.mo,sfx_ssbshk)
		foe.pr_electrocuted = electrocuted_time
		
	end
end

local HoldFunc = function(mo,player)
	if mo.health > 1
		mo.health = $-1
		if mo.health == TICRATE*3 //Thunder FX
			S_StartSound(nil,sfx_athun1)
		end
		if mo.health == TICRATE
			P_StartQuake(FRACUNIT*2, TICRATE)
		end
		//Lightning FX
		if P_RandomChance(FRACUNIT*(TICRATE*3-mo.health)/(TICRATE*16))
			DoLightning(mo)
			DoSpite(mo,player,true)
			S_StartSound(mo,sfx_elctrc)
			local p = DoParticle(mo,0,MT_SUPERSPARK)
			p.fuse = P_RandomRange(1,10)
			local s = P_RandomRange(0,10) * mo.scale
			local h = P_RandomRange(-10,10) * FRACUNIT
			local a = R_PointToAngle2(mo.x,mo.y,p.x,p.y)
			P_Thrust(p,a,s)
			P_SetObjectMomZ(p,h,true)
		end
	else
		//Do FX
		DoLightning(mo)
		DoLightning(mo)
		DoLightning(mo)
		//Do spiting!
		DoSpite(mo,player)
		//Destroy object
		PR.RewardDeath(mo,player)
		return true
	end
end

table.insert(CBW_PowerCardQueue, {
	name 		= "Spite",
	chance		= 4,
	health		= timer,
	flags		= PCF_HUDWARNING|PCF_EVENT,
	state		= S_POWERCARD_SPITE,
	mapthing	= MT_POWERCARDSPAWN_SPITE,
	func_spawn	= nil,
	func_idle 	= nil,
	func_hold	= HoldFunc,
	func_touch	= PR.HealCardSFX,
	func_drop 	= nil,
	func_expire	= nil,
})
local PR = CBW_PowerCards
local exploding_time = TICRATE*3/2

local DoMeltdown = function(mo,player,pre)
	//Search foes
	for foe in players.iterate
		if foe != player //Don't damage ourselves!
		and foe.playerstate == PST_LIVE and not(foe.spectator or foe.exiting)
		and not(gametyperules&GTR_TEAMS and foe.ctfteam == player.ctfteam) //Don't damage teammates
		and P_CheckSight(foe.mo,player.mo)
		and R_PointToDist2(foe.mo.x,foe.mo.y,player.mo.x,player.mo.y) < player.mo.scale * 2560
			if pre
				if not(foe.mo.meltdownlock and foe.mo.meltdownlock.valid)
					foe.mo.meltdownlock = P_SpawnMobjFromMobj(foe.mo,0,0,0,MT_CYBRAKDEMON_TARGET_RETICULE)
					foe.mo.meltdownlock.target = player.mo
					foe.mo.meltdownlock.tracer = foe.mo
					foe.mo.meltdownlock.fuse = mo.health
				end
			else
				P_DamageMobj(foe.mo,mo,player.mo)
				foe.pr_exploding = exploding_time
			end
		end
	end
end

local HoldFunc = function(mo,player) //Countdown
	if mo.health > 1
		mo.health = $-1
		if mo.health%TICRATE == 0 and mo.health != 0 
			S_StartSound(nil,sfx_gbeep)
			P_SpawnParaloop(mo.x, mo.y, mo.z+mo.height/3, mo.scale*128, 32, MT_BOXSPARKLE, ANGLE_90, nil, true)
		end
		if mo.health == TICRATE //Earthquake FX
			P_StartQuake(FRACUNIT*3, TICRATE)
		end
		if mo.health%2
			DoMeltdown(mo,player,true)
		end
	else
		//Deal damage to all nearby opponents
		S_StartSound(nil,sfx_bkpoof)
		P_StartQuake(FRACUNIT*20, 10)
		DoMeltdown(mo,player)
		//Destroy item
		PR.RewardDeath(mo,player)
		return true
	end
end

table.insert(CBW_PowerCardQueue, {
	name 		= "Meltdown",
	chance		= 4,
	health		= TICRATE*6,
	flags		= PCF_HUDWARNING|PCF_EVENT,
	state		= S_POWERCARD_MELTDOWN,
	mapthing	= MT_POWERCARDSPAWN_MELTDOWN,
	func_spawn	= nil,
	func_idle 	= nil,
	func_hold	= HoldFunc,
	func_touch	= PR.HealCardSFX,
	func_drop 	= nil,
	func_expire	= nil,
})
local PR = CBW_PowerCards

local frequency = 6
local ammo = 12*frequency

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

//Missile launcher
local HoldFunc = function(mo,player)

	//Visual
	local smoke = DoParticle(player,P_RandomRange(1,100),MT_SMOKE)
	if smoke and smoke.valid
		CBW_Battle.ZLaunch(smoke,FRACUNIT*P_RandomRange(1,3),true)
		smoke.colorized = true
		if G_GametypeHasTeams()
			smoke.color = player.skincolor
		else
			smoke.color = SKINCOLOR_RED
		end
	end

	//Mechanics
	if mo.health > 1
		//Item is currently draining
		if mo.health % frequency
			mo.health = $-1
		elseif CBW_Battle.PlayerButtonPressed(player, player.battleconfig_special, false, true)
		and not(player.pflags&PF_THOKKED or player.actionstate or player.powers[pw_carry])
-- 			if player.rings
			mo.health = $-1
			//Fire!
			local p = P_SPMAngle(player.mo,MT_REDRING,player.mo.angle,0)
			if p and p.valid
				CBW_Battle.AutoAim(player.mo,player.mo.angle,ANGLE_90,-1,false,p,FixedMul(mobjinfo[MT_REDRING].speed,p.scale),MF_ENEMY|MF_MONITOR|MF_BOSS)
				p.blockable = 1
				p.block_stun = 30
-- 					p.block_sound = sfx_ssbbmp
				p.block_hthrust = 12
				p.block_vthrust = 10
			end
			//Cost rings
			player.rings = $-1
			//Apply recoil
			player.mo.momx = $/2
			player.mo.momy = $/2
			//Uncurl, face forward
			player.drawangle = player.mo.angle
			if P_IsObjectOnGround(player.mo)
				P_Thrust(player.mo,player.mo.angle+ANGLE_180,player.mo.scale*6)
				player.mo.state = S_PLAY_WALK
				player.pflags = $&~(PF_SPINNING|PF_STARTDASH)
			else
				P_Thrust(player.mo,player.mo.angle+ANGLE_180,player.mo.scale*5)
				CBW_Battle.ZLaunch(player.mo,FRACUNIT*2,true)
				player.mo.state = S_PLAY_WALK
				player.pflags = $&~(PF_JUMPED|PF_SPINNING)
			end
-- 			end
		end
	else
		//Destroy item
		PR.DiscardDeath(mo,player)
		return true
	end
end

-- function(mo, player) //Fire rings
-- 		S_StartSound(player.mo,sfx_brakrl)
-- 		player.pr_missilelauncher = missilelauncher_time
-- 		DoParticleExplosion(player)
-- 	end

table.insert(CBW_PowerCardQueue, {
	name 		= "Ringslinger",
	chance		= 5,
	health		= ammo,
	flags		= PCF_RUNNERDEBUFF|PCF_NOTOSS,
	state		= S_POWERCARD_RINGSLINGER,
	mapthing	= MT_POWERCARDSPAWN_RINGSLINGER,
	func_spawn	= nil,
	func_idle 	= nil,
	func_hold	= HoldFunc,
	func_touch	= nil,
	func_drop 	= nil,
	func_expire	= nil,
})

//Does this need its own hook??
mobjinfo[MT_REDRING].blockable = 1
mobjinfo[MT_REDRING].block_stun = 3
mobjinfo[MT_REDRING].block_hthrust = 6
mobjinfo[MT_REDRING].block_vthrust = 2
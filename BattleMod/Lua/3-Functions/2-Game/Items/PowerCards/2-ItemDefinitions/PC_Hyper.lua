/*
	Hyper powerup
	Preps a stat boost to the player's speed, cooldown, and ability2.
*/
local PR = CBW_PowerCards

local DoColorGhost = function(player,time,color)
	if time%3 return end
	local ghost = P_SpawnGhostMobj(player.mo)
	ghost.colorized = true
	ghost.color = color
	if PR.FirstPerson(player)
		ghost.flags2 = $|MF2_DONTDRAW
	end
end

local function UnsetFunc(mo,player)
	if player and player.mo
		local skin = skins[player.mo.skin]
		player.thrustfactor = skin.thrustfactor
		player.jumpfactor = skin.jumpfactor
		player.gotflagdebuff = false //Let the previous stats get overwritten by CTF if necessary
		player.mo.hyper_card = nil
	end
end

local shotstates = {
	[S_PLAY_FIRE] = true,
	[S_PLAY_FIRE_FINISH] = true,
	[S_FANG_AIRSHOT] = true,
	[S_FANG_AIRSHOT_FINISH] = true,
	[S_FANG_BCESHOT] = true,
	[S_FANG_BCESHOT_FINISH] = true
}

//Hyper
local HoldFunc = function(mo,player)
	if mo.health > 1
		player.mo.hyper_card = true
		local skin = skins[player.mo.skin]
		//Timer
		mo.health = $-1 - player.actioncooldown/4 //Using actions reduces hyper time
		//Status effect
	-- 		player.normalspeed = FixedMul(skin.normalspeed,FRACUNIT*4/3)
		player.thrustfactor = skin.thrustfactor*2
		player.jumpfactor = FixedMul(skin.jumpfactor,FRACUNIT*3/2)
		player.actioncooldown = 0
		//Spindash boost
		if player.pflags&PF_STARTDASH
			player.dashspeed = player.maxdash
		end
		player.exhaustmeter = FRACUNIT
		//Piko Wave charge
		if CBW_Battle.GetSkinVarsFlags(player)&SKINVARS_ROSY
			player.melee_charge = FRACUNIT
			if (player.pflags & PF_NOJUMPDAMAGE) and not (player.actionstate) then
				if (player.mo.state == S_PLAY_JUMP) or (player.mo.state == S_PLAY_FALL) then
					player.mo.state = S_PLAY_ROLL
				end
				player.pflags = $ & ~(PF_NOJUMPDAMAGE)
			end
		end
		//Popgun enhancements
		if CBW_Battle.GetSkinVarsFlags(player)&SKINVARS_GUNSLINGER
			if player.airgun == true then
				player.airgun = false
				player.pflags = ($|PF_JUMPED) & ~PF_THOKKED
			end
			player.weapondelay = 0
			if shotstates[player.mo.state] then
				player.mo.tics = 1
			end
		end
		--Humming Top?
		if CBW_Battle.GetSkinVarsFlags(player)&SKINVARS_HUMMINGTOP then
			player.mo.recurl_actionable = true
		end
		//Visual
		if not(player.isjettysyn)
			DoColorGhost(player,mo.health,SKINCOLOR_GREEN)
		end
	else
		UnsetFunc(mo, player)
		PR.DiscardDeath(mo,player)
		return true
	end
end

local TouchFunc = function(mo,player)
	S_StartSound(player.mo,sfx_s25f)
end

local function UnsetFunc(mo,player)
	if player and player.mo
		local skin = skins[player.mo.skin]
		player.thrustfactor = skin.thrustfactor
		player.jumpfactor = skin.jumpfactor
		player.gotflagdebuff = false //Let the previous stats get overwritten by CTF if necessary
		player.mo.hyper_card = nil
	end
end

table.insert(CBW_PowerCardQueue,{
		name 		= "Hyper",
		chance		= 10,
		health 		= TICRATE*12,
		flags		= 0,
		state		= S_POWERCARD_HYPER,
		mapthing	= MT_POWERCARDSPAWN_HYPER,
		func_spawn	= nil,
		func_idle 	= nil,
		func_hold	= HoldFunc,
		func_touch	= TouchFunc,
		func_drop 	= UnsetFunc,
		func_expire	= UnsetFunc,
})
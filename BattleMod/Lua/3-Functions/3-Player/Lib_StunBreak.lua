local B = CBW_Battle
local CV = B.Console

B.StunBreakVFXThinker = function(mo)
	mo.color = B.Choose(SKINCOLOR_WHITE,SKINCOLOR_YELLOW,SKINCOLOR_ROSY,SKINCOLOR_GREEN,SKINCOLOR_ORANGE,SKINCOLOR_BLUE,SKINCOLOR_PURPLE)
end

B.StunBreak = function(player, doguard)
	if not (player and player.valid and player.mo and player.mo.valid)
	or player.isjettysyn
	or not (CV.Guard.value)
		-- easy checks
		player.tech_timer = 0
		return
	end
	local mo = player.mo
	
	-- check if we CAN stun break!
	local break_tics
	local break_cost
	local canBreak = false
	
	local break_type
	if player.canstunbreak then
		-- support for custom stunbreak conditions
		canBreak = (player.canstunbreak > 0) -- allows prevention of stunbreak by setting this to a negative value
		break_tics = player.customstunbreaktics
		if break_tics == nil then break_tics = 0 end
		break_cost = player.customstunbreakcost
		if break_cost == nil then break_cost = 0 end
	elseif (player.tumble)
		-- let us break out of non-parried tumbles
		canBreak = not player.tumble_nostunbreak
		break_tics = player.tumble_stunbreaktics or 7
		break_cost = player.tumble_stunbreakcost or 15
		
		-- store the type of stun break
		break_type = 2
	else
		-- let us break out of the pain state
		canBreak = (P_PlayerInPain(player) and mo.state == S_PLAY_PAIN)
		break_tics = 27
		break_cost = 25
		
		-- store the type of stun break
		break_type = 1
	end
	player.stunbreakcosttext = break_cost -- yet another little hack
	if not (canBreak) then player.tech_timer = 0 return end
	
	-- little hack to reset the tech timer if the tech type changes
	if (player.tech_type != break_type) then player.tech_timer = 0 end
	player.tech_type = break_type
	
	-- increase timer to break out
	player.tech_timer = $+1
	
	//Do the stun break
	if (player.tech_timer >= break_tics)
	and (doguard)	-- pressing the guard button (lets us buffer since it'll be 2 for holding)
	and (player.rings >= break_cost)
		player.canstunbreak = 0
		player.tailsthrown = nil
		local angle = (player.battleconfig_dodgecamera and not(player.pflags & PF_ANALOGMODE)) and mo.angle or B.GetInputAngle(player)

		player.tech_timer = 0
		
		//State and flags
		if (player.tumble)
			player.tumble = nil
			player.lockmove = false
			S_StopSoundByID(mo, sfx_kc38)
		end
		B.ResetPlayerProperties(player,false,false)
		mo.state = S_PLAY_ROLL
		mo.temproll = 19
		player.exhaustmeter = min($, player.ledgemeter)
		//player.powers[pw_invulnerability] = mo.temproll
		player.powers[pw_flashing] = mo.temproll
		player.airdodge = 0
		
		//Launch
		local techmomz = 7*FRACUNIT/B.WaterFactor(mo)
		P_SetObjectMomZ(mo, techmomz, false)
		P_InstaThrust(mo,angle,FRACUNIT*12)
		player.drawangle = angle
		
		//SFX
		S_StartSound(mo,sfx_cdfm66,player)
		S_StartSound(mo, sfx_nbmper)
		S_StartSoundAtVolume(mo, sfx_kc31, 200)
		
		//Pay rings, cooldown
		player.actioncooldown = max($, TICRATE)
		player.rings = $ - break_cost
		
		//Visual effects
		local sb = P_SpawnMobjFromMobj(mo,0,0,0,MT_STUNBREAK)
		sb.scale = mo.scale * 4/3
		sb.destscale = mo.scale * 3
		sb.momz = mo.momz * 3/4
		local sh = P_SpawnMobjFromMobj(mo,0,0,0,MT_BATTLESHIELD)
		sh.target = mo
		
		//Screenshake
		if player == consoleplayer
			P_StartQuake(12 * FRACUNIT, 4)
		end

		local knuckle_busted = (mo and mo.valid and mo.tracer and mo.tracer.valid and mo.tracer.player and mo.tracer.player.kgrab and mo.tracer.player.kgrab.valid and mo.tracer.player.kgrab == mo)

		//Troll tails players
		if player.powers[pw_carry] == CR_PLAYER and player.mo.tracer and player.mo.tracer.player then
			local tails = player.mo.tracer
			player.mo.tracer = nil
			player.powers[pw_carry] = 0
			P_SetObjectMomZ(tails, mo.scale*10)
			B.DoPlayerTumble(tails.player, 45, mo.angle, mo.scale*3, true, true) --prevent stunbreak
		end
		if knuckle_busted then
			local knuckles = player.mo.tracer
			player.mo.tracer = nil
			P_SetObjectMomZ(knuckles, mo.scale*10)
			B.DoPlayerTumble(knuckles.player, 45, mo.angle, mo.scale*3, true, true) --prevent stunbreak
		end
	end
end
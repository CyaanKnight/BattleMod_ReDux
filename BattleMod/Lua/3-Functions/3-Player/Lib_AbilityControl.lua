local B = CBW_Battle
local S = B.SkinVars
local CV = B.Console

B.CarryState = function(tails,passenger)
	B.DebugPrint("Latching "..passenger.name.." onto "..tails.name,DF_PLAYER)
	B.ResetPlayerProperties(passenger,false,false)
	passenger.mo.tracer = tails.mo
	passenger.powers[pw_carry] = CR_PLAYER
	passenger.carried_time = 0
	-- 	tails.carry_id = passenger.mo
	S_StartSound(passenger.mo,sfx_s3k4a)
end

B.TailsCatchPlayer = function(player1,player2)
	if P_MobjFlip(player1.mo) ~= P_MobjFlip(player2.mo) then return end
	local flip = P_MobjFlip(player1.mo)
	--Determine who's who
	local tails,passenger
	if player1.mo.z*flip < player2.mo.z*flip then
		tails = player2
		passenger = player1
	else
		tails = player1
		passenger = player2
	end
	
	--Get Z distance
	local zdist
	if flip == 1 then
		zdist = abs(tails.mo.z-(passenger.mo.z+passenger.mo.height))
	else
		zdist = abs(passenger.mo.z-(tails.mo.z+tails.mo.height))
	end
	
	--Apply gates
	if tails.panim ~= PA_ABILITY
		or not(tails.pflags&PF_CANCARRY)
		or zdist > FixedDiv(passenger.mo.height,passenger.mo.scale)/2
	-- 	or passenger.carried_time < 15
		or passenger.powers[pw_carry]
		or passenger.mo.momz*flip > 0
		or passenger.exhaustmeter <= 0
		or passenger.powers[pw_tailsfly]
		or passenger.mo.state == S_PLAY_FLY_TIRED
	then
		return
	end
	--Assign carry states
	B.CarryState(tails,passenger)
end

B.glide = function(player)
	if not (player and player.mo and player.mo.valid) then return end
	local mo = player.mo
	if (mo.state == S_PLAY_GLIDE or mo.state == S_PLAY_SWIM) and player.glidetime and not P_IsObjectOnGround(mo) then
		if player.glidetime > 16 then --Downward force when gliding very slowly
			if (player.speed < 12 * FRACUNIT) then
				P_SetObjectMomZ(mo, FRACUNIT * -3/4, true)
			elseif (player.speed < 24 * FRACUNIT) then
				P_SetObjectMomZ(mo, FRACUNIT * -1/2, true)
			end
		end
		--Angle adjustment
		if (mo.state == S_PLAY_SWIM) then
			B.legacykill(player, 1)
		elseif player.battleconfig_glidestrafe then
			player.drawangle = player.mo.angle
		end
	end
end

B.pogo = function(player)
	if not (player and player.mo and player.mo.valid) then return end
	local mo = player.mo
	if player.pflags & PF_BOUNCING then
		if not (player.pflags & PF_JUMPDOWN) then
			P_ResetPlayer(player)
			if P_IsObjectOnGround(mo) then
				mo.state = S_PLAY_WALK
			elseif (player.charflags & SF_MULTIABILITY) then
				player.pflags = $ | P_GetJumpFlags(player)
				mo.state = S_PLAY_JUMP
			else
				player.pflags = $ | PF_THOKKED
				mo.state = S_PLAY_FALL
			end
		end
	end
end

B.homingthok = function(p)
	if p.homing and p.target and p.target.valid and p.target.player and p.target.player.valid and p.target.player.intangible then
		p.homing = 0--Air dodging can "shake off" a player that is homing on to you
	else
		p.homing = min($,10)
	end
end

B.legacykill = function(player, time)
	if (player.pflags & PF_DIRECTIONCHAR and not player.waslegacy) then return end

	if time then
		player.waslegacy = time
	end
	if player.waslegacy then
		player.pflags = $ | PF_DIRECTIONCHAR
		player.waslegacy = max(1,$-1)
	end
	if player.waslegacy and player.waslegacy==1 and not time then
		player.waslegacy = nil
		player.pflags = $ & ~PF_DIRECTIONCHAR
	end
end

B.analogkill = function(player, time)
	if not (player.pflags & PF_ANALOGMODE or player.wasanalog) then return end

	if time then
		player.wasanalog = time
	end
	if player.wasanalog then
		player.pflags = $ & ~PF_ANALOGMODE
		player.wasanalog = max(1,$-1)
	end
	if player.wasanalog and player.wasanalog==1 and not time then
		player.wasanalog = nil
		player.pflags = $ | PF_ANALOGMODE
	end
end

B.popgun = function(player)
	if P_PlayerInPain(player) and player.charability2 == CA2_GUNSLINGER then
		player.weapondelay = TICRATE/5
	end
end

B.weight = function(player)
	if not(player.mo) then return end
	
	local w
	if S[player.skinvars].weight then
		w = S[player.skinvars].weight
	else
		w = S[-1].weight
	end
	
	player.mo.weight = FRACUNIT*w/100
end

B.exhaust = function(player)
	if not (player and player.mo and player.mo.valid) then return end
	local mo = player.mo
	
	--Do func_exhaust
	local defaultfunc = S[-1].func_exhaust
	local func = S[player.skinvars].func_exhaust
	local override = nil
	if not func then
		func = defaultfunc
	end
	if func then
		override = func(player)
	end
	
	--Common exhaust states
	local warningtic = FRACUNIT/3
	if player.powers[pw_carry] == CR_MACESPIN and player.mo.tracer then
		local maxtime = 4*TICRATE
		player.exhaustmeter = max(0,$-FRACUNIT/maxtime)
		if player.exhaustmeter <= 0 then
			--player.exhaustmeter = FRACUNIT
			player.powers[pw_carry] = CR_NONE
			player.mo.tracer = nil
			player.powers[pw_flashing] = TICRATE/4
		end
	end
	if player.powers[pw_tailsfly] then
		local maxtime = 5*TICRATE
		local spd = FixedMul(player.speed,player.mo.scale)
		local nspd = FixedMul(player.normalspeed,player.mo.scale)
		
		if mo.momz * P_MobjFlip(mo) > 5*FRACUNIT
			or spd > nspd*2
		then
			maxtime = 2*TICRATE
		elseif mo.momz * P_MobjFlip(mo) > 3*FRACUNIT
			or spd > nspd*(3/2)
		then
			maxtime = 3*TICRATE
		end
		player.exhaustmeter = max(0,$-FRACUNIT/maxtime)
		
		if player.exhaustmeter <= 0 then
			--player.exhaustmeter = FRACUNIT
			if P_MobjFlip(mo) == 1 then
				mo.momz = min($, 5*FRACUNIT)
			else
				mo.momz = max($, -5*FRACUNIT)
			end
			player.powers[pw_tailsfly] = 0
		end
	end
	if (P_IsObjectOnGround(mo) or mo.eflags & MFE_JUSTHITFLOOR)
		and (
			(player.airdodge and player.airdodge > 0)
			or player.landlag
		)
		and not (
			mo.player.resistrecoil
		)
	then
		local ang = R_PointToAngle2(0,0,-player.mo.momx,-player.mo.momy)
		B.DoPlayerFlinch(player, player.landlag or 12, ang, -player.speed/2,false)
		S_StartSound(mo,sfx_s3k4c)
		player.landlag = nil
	end
	if player.charability == CA_GLIDEANDCLIMB then
		if player.climbing == 5 then
			if player.exhaustmeter and (player.exhaustmeter > warningtic) then
				player.exhaustmeter = max(warningtic,$-FRACUNIT/4)
			else
				player.exhaustmeter = max(0,$-FRACUNIT/4)
			end
		end
		if (mo.state == S_PLAY_GLIDE or mo.state == S_PLAY_SWIM) and not P_IsObjectOnGround(mo) then
			local maxtime = 5*TICRATE
			player.exhaustmeter = max(0,$-FRACUNIT/maxtime)
			if player.exhaustmeter <= 0 then
				--player.exhaustmeter = FRACUNIT
				mo.state = S_PLAY_FALL
				player.pflags = $ & ~PF_GLIDING & ~PF_JUMPED | PF_THOKKED
				player.glidetime = 0
			end
		elseif player.climbing then
			local maxtime = 5*TICRATE
			player.exhaustmeter = max(0,$-FRACUNIT/maxtime)
			if player.exhaustmeter <= 0 then
				--player.exhaustmeter = FRACUNIT
				player.climbing = 0
				player.pflags = $|PF_JUMPED|PF_THOKKED
				mo.state = S_PLAY_ROLL
			end
		end
	end
	if player.prevfloat == nil then
		player.prevfloat = false
	end
	if player.charability == CA_FLOAT and player.secondjump and (player.pflags & PF_THOKKED) and not (player.pflags & PF_JUMPED) and not (player.pflags & PF_SPINNING) then
		if not player.prevfloat then
			player.exhaustmeter = max(0,$-FRACUNIT/20)
		end
		player.prevfloat = true
		local maxtime = 3*TICRATE
		player.exhaustmeter = max(0,$-FRACUNIT/maxtime)
		if player.exhaustmeter <= 0 then
			--player.exhaustmeter = FRACUNIT
			player.secondjump = 0
			mo.state = S_PLAY_FALL
			player.pflags = $ & ~PF_JUMPED | PF_THOKKED
		end

	else
		player.prevfloat = false
	end
	
	if (player.mo.state == S_PLAY_LEDGE_GRAB or player.mo.state == S_PLAY_LEDGE_RELEASE) then
		local maxtime = 5*TICRATE
		player.ledgemeter = max(0,$-FRACUNIT/maxtime)
		if not(player.exhaustmeter) then player.exhaustmeter = 1 end
		if player.ledgemeter <= 0 then
			player.climbing = 0
			player.pflags = $|PF_JUMPED|PF_THOKKED
			mo.state = S_PLAY_LEDGE_RELEASE
			player.exhaustmeter = 0
		end
		if player.ledgemeter == nil then player.ledgemeter = FRACUNIT end
		player.ledgemeter = min($,player.exhaustmeter+(FRACUNIT/2))
    	player.exhaustmeter = min($,player.ledgemeter)
	end
	
	--Refill meter
	if (P_IsObjectOnGround(mo) or P_PlayerInPain(player)) and not player.actionstate and not override then
		player.exhaustmeter = (G_GametypeUsesLives() and B.ArenaGametype()) and FRACUNIT or FRACUNIT*2
		player.ledgemeter = FRACUNIT
	end
	
	--Exhaust warning
	if player.exhaustmeter < warningtic and player.exhaustmeter != 0 then
		local sweatheight = mo.height * 3/2
		if not(leveltime&7) then
			S_StartSound(mo, sfx_s3kbb, player)
			local sweat = P_SpawnMobjFromMobj(mo, 0, 0, sweatheight * P_MobjFlip(mo), MT_THOK) --we got a local sweat in our area
			sweat.spritexoffset = $ - (mo.radius*2)
			sweat.state = S_SWEAT
			sweat.target = mo
			B.InstaFlip(sweat)
			player.sweatobj = sweat
		end
		if player.sweatobj and player.sweatobj.valid then
			P_MoveOrigin(player.sweatobj, player.mo.x, player.mo.y, player.mo.z + sweatheight)
		end
	end
end

B.flashingnerf = function(player)
	if player.powers[pw_flashing] < (3 * TICRATE - 1) then
		if B.BattleGametype() then player.powers[pw_flashing] = min($, 2*TICRATE) end
	elseif not(P_PlayerInPain(player) or player.playerstate) then
		player.powers[pw_flashing] = $-1
	end
end

B.hammerthrustfactor = function(player)
	if not (player.mo and player.charability2 == CA2_MELEE) then return end
	local skin = skins[player.mo.skin]
	if not (P_IsObjectOnGround(player.mo) or player.gotflagdebuff) then
		player.thrustfactor = skin.thrustfactor+3
		player.hammerthrust = true
	elseif player.hammerthrust then
		player.thrustfactor = skin.thrustfactor
		player.hammerthrust = false
	end
end

B.tailsthrow = function(player)
	if not player.tailsthrown then return end
	local tails = player.tailsthrown.mo

	player.landlag = max(0,$-1)
	player.canstunbreak = max($,2)
	player.customstunbreaktics = TICRATE
	if player.customstunbreakcost == nil then
		player.customstunbreakcost = 35
	end
	player.actionallowed = false
	local doguard = B.ButtonCheck(player,player.battleconfig_guard)
	B.StunBreak(player, doguard) --this shouldn't have been necessary

	local mo = player.mo
	if (not mo) or (P_IsObjectOnGround(mo)) then
		player.tailsthrown = 0
		return
	end

	if player.lastmoveblock
		and player.lastmoveblock == leveltime
		and (B.MyTeam(mo,player.tailsthrown) == false)
	then
		local vfx = P_SpawnMobjFromMobj(mo, 0, 0, mo.height/2, MT_SPINDUST)
		local audiosource = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_THOK)
		audiosource.tics = TICRATE*2
		audiosource.flags2 = $ | MF2_DONTDRAW
		if vfx.valid then
			vfx.scale = mo.scale * 6/5
			vfx.destscale = vfx.scale * 3
			vfx.colorized = true
			vfx.color = SKINCOLOR_WHITE
			vfx.state = S_BCEBOOM
		end
		S_StartSound(audiosource, sfx_s3k9b)
		P_StartQuake(14 * FRACUNIT, 5)
		P_DamageMobj(mo, tails, tails)
		--P_DamageMobj(mo, nil, player.pushed_creditplr.mo) --THIS SIGSEGV'S THE GAME WHAT
		if not(player.playerstate) then
			P_Thrust(mo, mo.angle, -mo.scale*12)
			player.drawangle = mo.angle
		end
		local omg = TICRATE/5
		mo.hitstun_tics = omg
		P_FlashPal(player, PAL_INVERT, omg)
		player.tailsthrown = 0
	end

	local radius = mo.radius/FRACUNIT
	local r = do
		return P_RandomRange(-radius,radius)*FRACUNIT
	end
	local s = P_SpawnMobjFromMobj(mo,r(),r(),0,MT_SPARK)
	s.scale = $*3/4
	if P_RandomRange(0,1) then
		s.color = (tails and tails.valid and tails.color != SKINCOLOR_ORANGE) and tails.color or SKINCOLOR_SKY
		s.colorized = true
	end
end

B.sneakertrail = function(player)
	if player.powers[pw_sneakers] and player.mo and player.speed > 30*player.mo.scale and leveltime%3 then
		local speedtrail = P_SpawnGhostMobj(player.mo)
		if speedtrail.tracer then
			speedtrail.tracer.colorized = true
			speedtrail.tracer.color = player.mo.color
			speedtrail.tracer.fuse = 3
			speedtrail.tracer.blendmode = AST_ADD
		end
		speedtrail.colorized = true
		speedtrail.color = player.mo.color
		speedtrail.fuse = 3
		speedtrail.blendmode = AST_ADD
    end
end

B.invinciblespark = function(player)
	local mo = player.mo
	if not(mo and mo.valid) then
		return
	end
	if player.powers[pw_invulnerability] then
		if player.powers[pw_invulnerability] == 20*TICRATE-1 and not (player.invbarrier and player.invbarrier.valid) then
			player.invbarrier = P_SpawnMobjFromMobj(mo, 0,0,20*mo.scale, MT_INVINCIBLE_LIGHT)
			player.invbarrier.frame = ($ & ~FF_TRANSMASK) | FF_TRANS80
			player.invbarrier.blendmode = AST_ADD
			player.invbarrier.target = mo
			player.invbarrier.scale = mo.scale-(mo.scale/4)
			player.invbarrier.colorized = true
			player.invbarrier.color = SKINCOLOR_BONE
		end
		if player.invbarrier and player.invbarrier.valid then
			P_SetOrigin(player.invbarrier, mo.x, mo.y, mo.z+20*mo.scale)
		end
		if not S_SoundPlaying(mo, sfx_huprsa) then
			if player ~= displayplayer and not splitscreen then
				S_StartSound(mo, sfx_huprsa)
			end
		end
	elseif player.invbarrier and player.invbarrier.valid then
		P_RemoveMobj(player.invbarrier)
		mo.renderflags = $&~RF_FULLBRIGHT
		S_StopSound(mo, sfx_huprsa)
		return
	end
end

B.semisuper = function(player)
	local mo = player.mo
	if not(mo and mo.valid) then
		return
	end
	
	if player.powers[pw_sneakers] and player.powers[pw_invulnerability] and S[player.skinvars].supersprites then
		mo.semisuper = true
		mo.eflags = $|MFE_FORCESUPER
	elseif mo.semisuper then
		mo.eflags = $ &~ MFE_FORCESUPER
		mo.semisuper = false
	end
end

B.CharAbilityControl = function(player)
	B.ArmaCharge(player)
	B.glide(player)
	B.homingthok(player)
	B.popgun(player)
	B.pogo(player)
	B.legacykill(player)
	B.analogkill(player)
	B.weight(player)
	B.exhaust(player)
	B.flashingnerf(player)
	B.hammerthrustfactor(player)
	B.tailsthrow(player)
	B.sneakertrail(player)
	B.invinciblespark(player)
	B.semisuper(player)
end

B.MidAirAbilityAllowed = function(player)
	if player.gotcrystal or player.gotflag then 
		return false
	else
		return true
	end
end

B.StunBreakAllowed = function(player)
	if not (player and player.valid and player.mo and player.mo.valid)
	or player.isjettysyn
	or not (CV.Guard.value)
	then
		return false --same as in lib_stunbreak.lua
	end
	if player.canstunbreak then
		return player.canstunbreak > 0
	end
	if not player.actionallowed
	and not player.landlag
	and P_PlayerInPain(player)
	and (player.mo.state == S_PLAY_PAIN or player.mo.state == S_PLAY_STUN)
	then
		return true
	end
	return false
end


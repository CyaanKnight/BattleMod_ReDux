local B = CBW_Battle

B.BattleHitboxSpawn = function(player, hor_dist, vert_pos, h_tics, p_state, spot_only, orbit)
	local mo = player.mo
	local hitbox = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_BATTLEHITBOX)
	
	hitbox.target = mo
	hitbox.angle = player.drawangle
	hitbox.horz_dist = hor_dist
	hitbox.vert_pos = vert_pos
	hitbox.h_tics = h_tics or 2
	hitbox.tics = h_tics
	hitbox.p_state = p_state
	hitbox.spot_only = spot_only
	hitbox.orbit = orbit or 0
	hitbox.spin_angle = player.drawangle

	player.battlehitbox = true

	return hitbox
end

local function CantDoStuff(player)
	return P_PlayerInPain(player) or player.playerstate == 
		PST_DEAD or player.powers[pw_carry] != CR_NONE or 
		player.mo.state == S_PLAY_GASP or player.pflags & PF_SLIDING
		or player.exiting or player.guard or player.airdodge or player.tumble or
		player.battle_hurttxt == "attack"
end

B.BattleHitboxThink = function(mo)
	if not mo.target or not mo.target.valid then
		P_RemoveMobj(mo)return 
	end
	
	if CantDoStuff(mo.target.player) then
		P_RemoveMobj(mo)return 
	end	

	local player = mo.target.player
	
	local p_angle = player.drawangle
	local p_postion = mo.horz_dist
	local grav_pos = mo.vert_pos*P_MobjFlip(mo.target)
	local grav_add = (5*mo.target.scale)*P_MobjFlip(mo.target)
	//local grav_mod = 1

	// keep tics set untell the player leaves the attacking state
	if mo.p_state and mo.target.state == mo.p_state then
		mo.tics = mo.h_tics
	end

	// do orbits
	if mo.orbit > 0 or mo.orbit < 0 then
		p_angle = mo.spin_angle
		mo.angle = mo.spin_angle+ANGLE_90
		mo.spin_angle = $-(ANGLE_45*mo.orbit)
		p_postion = $+28
	else
		mo.angle = player.drawangle
	end

	if P_MobjFlip(mo.target) == -1 then
		
		if mo.target.height <= P_GetPlayerSpinHeight(player) then
			grav_add = $/-2
		else
			grav_add = $+(mo.height)
		end

		mo.flags2 = $|MF2_OBJECTFLIP
	else
		mo.flags2 = $&~ MF2_OBJECTFLIP
	end

	local mod = 1
		
	local xpos = mo.target.x + (FixedMul(p_postion, cos(p_angle))*mod )
	local ypos = mo.target.y + (FixedMul(p_postion, sin(p_angle))*mod )
		
	P_MoveOrigin( mo, xpos, ypos, ((mo.target.z+grav_add)+grav_pos) )
end

B.BattleHitboxCollision = function(boxhit, mobj)
	if not(B) then
	return end
	
	if not boxhit.target or not mobj then
	return end

	local plr = boxhit.target.player

	if boxhit.target == mobj then
	return end

	// only collide with players and bashabules
	if mobj.type != MT_PLAYER and not mobj.battleobject then
	return end

	if plr.powers[pw_nocontrol] or boxhit.target.pushtics then
	return end

	if B.CheckHeightCollision(mobj,boxhit) == false then
	return end

	//player colision
	if mobj.type == MT_PLAYER and mobj.player and mobj.health and mobj.pushtics <= 0 and
	(CV_FindVar("friendlyfire").value or mobj.player.ctfteam != mobj.player.ctfteam or not (gametyperules & GTR_TEAMS) or
	not (gametyperules & GTR_FRIENDLY)) then
		
		local attacker_speed = abs(FixedHypot(boxhit.target.momx, boxhit.target.momy))
		
		// dash a bit if attacking from a standstill
		if abs(attacker_speed) < 10*boxhit.target.scale then
			P_InstaThrust(boxhit.target,plr.drawangle,10*boxhit.target.scale)
		end
		
		// dont want hitbox to collide if its not the sweetspot
		if boxhit.spot_only then
			local PFunc = B.PriorityFunction
			local func = plr.battle_sfunc

			if not PFunc[func](plr.mo,mobj) then
			return end
		end

		local touched = B.PlayerTouch(boxhit.target, mobj) 
		if mobj.player.guard or boxhit.target.state == S_PLAY_PAIN or touched then
			P_MovePlayer(mobj.player)
			P_MovePlayer(plr)
			return
		end
	end

	// battle object
	if mobj.battleobject then
		local attacker_speed = abs(FixedHypot(boxhit.target.momx, boxhit.target.momy))
		
		// dash a bit if attacking from a standstill
		if abs(attacker_speed) < 10*boxhit.target.scale then
			P_InstaThrust(boxhit.target,plr.drawangle,10*boxhit.target.scale)
		end
		
		B.BashableCollision(mobj, boxhit.target)

		if abs(attacker_speed) < 10*boxhit.target.scale then
			P_Thrust(boxhit.target,plr.drawangle,-10*boxhit.target.scale)
		end		

		return
	end
end

// tell players when hitbox is removed so they can make a new one again
B.BattleHitboxRemoved = function(mo)
	if not mo.target or not mo.target.valid then
		return 
	end
	
	local player = mo.target.player

	player.battlehitbox = false

	if player.playerstate == PST_DEAD then
		return 
	end
end

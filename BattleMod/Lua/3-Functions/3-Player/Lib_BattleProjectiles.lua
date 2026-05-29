local B = CBW_Battle
local CV = B.Console

B.FireTrailRingDrain = function(target, inflictor, source, damage, damagetype)
	if not (inflictor and inflictor.valid) return end
	if inflictor.type ~= MT_SPINFIRE then return end

	local player = target.player
	if (player.powers[pw_shield] & SH_PROTECTFIRE) then return false end
	if (player.powers[pw_flashing]) then return false end

	local ringdrain = 1

	if player.rings > 1 then
		player.rings = $ - 1
		if not S_SoundPlaying(target, sfx_fire) then	
			S_StartSound(target, sfx_antiri, player)
			S_StartSound(target, sfx_fire)
		end
	end

	if player.rings <= ringdrain then
		return true
	end
	P_RemoveMobj(inflictor)
	return false 
end
B.FireTrailThinker = function(mo)
	if mo.fuse < TICRATE then
		mo.frame = $ | TR_TRANS50
		mo.destscale = mo.fuse*FRACUNIT/TICRATE
	end
	if mo.changed then
		return
	end
	if (mo.target and mo.target.valid and mo.target.player) then
		local player = mo.target.player
		mo.ctfteam = player.ctfteam
		mo.state = S_TEAMFIRE1
		mo.fuse = TICRATE * 4
		mo.color = player.skincolor
		mo.changed = true
	end
end

local spawnheart = function(mo, launchang, anglemod, grow, zspd)
	local range = 3
	local x = mo.x + P_RandomRange(-range,range)*mo.scale
	local y = mo.y + P_RandomRange(-range,range)*mo.scale
	local z = mo.z
	if P_MobjFlip(mo) == -1
		z = $ + mo.height
	end
	local momz = P_RandomRange(zspd + 0, zspd + 2)*FRACUNIT
	local hfriction = P_RandomRange(80,90)
	local hrt = P_SpawnXYZMissile(mo.target, mo, MT_PIKOWAVEHEART, x,y,z)
	if hrt and hrt.valid
		hrt.friction = hfriction //Horz friction
		hrt.momz = momz * P_MobjFlip(mo)
		
		local thrust = hrt.scale*2
		local angle = FixedAngle(P_RandomRange(0,359)<<FRACBITS)
		P_InstaThrust(hrt,angle,thrust)
		
		local thrust2 = mo.scale * 13
		P_Thrust(hrt,launchang + anglemod,thrust2)
		hrt.scale = mo.scale / 2
		hrt.fuse = TICRATE
		hrt.grow = grow
		
		if (mo.time%4)
			hrt.state = S_PIKOWAVE3
		end
		hrt.colorized = true
		hrt.color = mo.teamcolor
		
		return true
	end
	
	return false
end

B.PikoWaveThinker = function(mo)
	if not(mo.target and mo.target.valid)
		P_RemoveMobj(mo)
		return
	end
	if mo.state != S_PIKOWAVE1
		mo.momx = 0
		mo.momy = 0
		mo.momz = 0
		return
	end
	
	if mo.time == nil
		mo.time = 1
	end
	mo.time = $+1
	
	local launchang = R_PointToAngle2(0,0,mo.momx,mo.momy)
	
	//Spawn projectiles
	if not(mo.time%3)
		S_StartSound(mo,sfx_hoop2)
		spawnheart(mo, launchang, 0, true, 9)
	else
		spawnheart(mo, launchang, -ANG30, false, 7)
		spawnheart(mo, launchang, ANG30, false, 7)
	end
	
	//Speeds up over time
	local friction = 103
	mo.momx = $*friction/100
	mo.momy = $*friction/100
	
	mo.angle = $ + ANG10
end

B.PlayerHeartCollision = function(mo,heart,owner)
	//Relegate this hook to interactions with players and heart projectiles
	if not(mo and mo.valid) then return end
	if not(mo.player) then return end
	if not(heart and heart.valid and (heart.type == MT_LHRT or heart.type == MT_PIKOWAVEHEART)) then return end
	if not(heart.flags&MF_MISSILE) then return end //heart is dead
	if not(owner and owner.type == MT_PLAYER) then return end
	//Player vs tagged
	if mo.player.pflags&PF_TAGIT and not(owner.player.pflags&PF_TAGIT) then return false end
	//Players
	/*if B.PlayerCanBeDamaged(mo.player) and not(B.MyTeam(owner.player,mo.player))
		then
		if G_TagGametype()
			return true
		elseif mo.player.battle_def
			P_InstaThrust(mo,R_PointToAngle2(0,0,heart.momx,heart.momy),heart.scale*10)
			S_StartSound(mo,sfx_s3k7b)
			B.PlayerCreditPusher(mo.player,owner)
			return false
		else
			return true
		end
	end*/
	if B.MyTeam(mo.player,owner.player) and not B.SuddenDeath
		then//Do pink shield
		B.AddPinkShield(mo.player,owner.player)
		return 
	end
	return nil
end

B.PlayerCorkDamage = function(pmo,mo,source)
	if not(mo and mo.valid
		and mo.blockable != nil
		and mo.flags&MF_MISSILE)
		return
	end
	if pmo.player and source and source.valid and source.player and not(B.MyTeam(source.player,pmo.player)) and not P_PlayerInPain(pmo.player)
		local vulnerable = B.PlayerCanBeDamaged(pmo.player)
		B.PlayerCreditPusher(pmo.player,source)
		
		local hthrust = mo.block_hthrust
		local vthrust = mo.block_vthrust
		local blockstun = mo.block_stun
		local thrusttype = mo.block_thrusttype or P_InstaThrust
		local sound = sfx_s3k7b
		if mo.block_sound
			sound = mo.block_sound
		end

		local func = pmo.player.battle_sfunc and B.PriorityFunction[pmo.player.battle_sfunc] or 0
		local blocked = pmo.player.battle_def >= mo.blockable
		local sweetspot_blocked = func and func(pmo, mo) and pmo.player.battle_sdef >= mo.blockable
		
		if vulnerable and (blocked or sweetspot_blocked) then
			B.ResetPlayerProperties(pmo.player,false,false)
			
			if P_IsObjectOnGround(pmo) then
				thrusttype(pmo,mo.angle,mo.scale*hthrust)
				pmo.state = S_PLAY_SKID
			else
				pmo.momz = $/2
				B.ZLaunch(pmo, mo.scale*vthrust, true)
				thrusttype(pmo,mo.angle,mo.scale*hthrust / 2)
			end
			
			S_StartSound(pmo,sound)
				
			//Do flinch, uncurl
			local angle = R_PointToAngle2(0,0,pmo.momx,pmo.momy)
			local recoilthrust = FixedHypot(pmo.momx,pmo.momy)
			B.DoPlayerFlinch(pmo.player, blockstun, angle, recoilthrust)
			P_RemoveMobj(mo)
			return false
			
		elseif not(vulnerable) then
			if P_IsObjectOnGround(pmo) then
				P_Thrust(pmo,mo.angle,mo.scale*hthrust / 2)
			else
				pmo.momz = $ * 3/4
				B.ZLaunch(pmo, mo.scale*vthrust/2, true)
				P_Thrust(pmo,mo.angle,mo.scale*hthrust / 4)
			end
			S_StartSound(pmo,sound)
			return false
		end
		
		return true
	end
end

B.PlayerRoboMissileCollision = function(pmo,missile,source)
	//Missiles only
	if not(missile and missile.valid and missile.robomissile_init and missile.flags&MF_MISSILE) then return end
	//Enemy player collisions only
	if not(pmo.player and source and source.valid and source.player and not(B.MyTeam(source.player,pmo.player))) then return false end
	//The game already handles standard missile damage.
	//We just need to make an exception case
	if pmo.player.battle_def != 0
		local spd = FixedDiv(
			FixedHypot(missile.momx,missile.momy)/2,
			pmo.weight
		)
-- 		local angle = R_PointToAngle2(missile.x,missile.y,pmo.x,pmo.y)
-- 		P_Thrust(pmo,angle,spd)
		if not(P_IsObjectOnGround(pmo)) then
			P_SetObjectMomZ(pmo,FRACUNIT*8,0)
		end
		//Do uncurling, skidding
		B.DoPlayerFlinch(pmo.player, spd*2/FRACUNIT, R_PointToAngle2(0,0,missile.momx,missile.momy),spd,true)
		P_KillMobj(missile)
	return false end
end

addHook("ShouldDamage", function(targ, inf, src, dmg)
  if    G_GametypeHasTeams() and 
        targ and targ.valid and targ.player and 
        src and src.valid and src.player and
        targ.player.ctfteam == src.player.ctfteam 
  then 
    return false 
  end
end, MT_PLAYER)
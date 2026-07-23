local B = CBW_Battle
local CV = B.Console
local CP = B.ControlPoint

B.GetInteractionType = function(smo,tmo)
	//0 = No interaction. 1 = Bump. 2 = ??? 3 = Full damage code
	if not(smo and smo.valid and smo.health and tmo and tmo.valid and tmo.health)
		then 
		return 0 //Invalid interaction
	end
	if (smo.player and (smo.player.spectator or smo.player.battlespawning))
		or (tmo.player and (tmo.player.spectator or tmo.player.battlespawning))
		then
		return 0 //Still invalid
	end
	if (smo.player and smo.player.powers[pw_carry] == CR_PLAYER and smo.tracer == tmo)
	or (tmo.player and tmo.player.powers[pw_carry] == CR_PLAYER and tmo.tracer == smo)
		then
		return 0 //Possibly valid, but colliding with eachother would cancel out their action
	end
	if not(smo.player or tmo.player) then //Two inanimate objects
		return 3
	end
	if not(smo.player and tmo.player) //One of us is inanimate
		//Lot of bullshit here, sorry
		then 
		if not(smo.pushed and tmo.pushed) then return 1 end
		local myteam = true
		if tmo.pushed.player and not(smo.pushed.player) then
			if tmo.target == nil then
				myteam = false
			else
				myteam = B.MyTeam(tmo.target.player,smo.player)
				if(myteam) then tmo.battle_atk = 0 myteam = false end
			end
		elseif smo.pushed.player and not(tmo.pushed.player) then
			if smo.target == nil then
				myteam = false
			else
				myteam = B.MyTeam(smo.target.player,tmo.player)
				if(myteam) then smo.battle_atk = 0 myteam = false end
			end
		end
		if myteam then
			return 1
		else
			return 3
		end
	end
	//Collision FriendlyFire
	if CV.Collision.value and CV.FindVar("friendlyfire").value return 3 end
	//Egg Robo Tag
	if gametype == GT_EGGROBOTAG return 1 end
	//Battle Tag
	if gametype == GT_BATTLETAG
		/*if not B.MyTeam(smo.player, tmo.player) and tmo.player.pflags & PF_TAGIT
				and not (smo.player.pflags & PF_TAGIT)
			return 3
		else
			return 1
		end*/
		if B.MyTeam(smo.player, tmo.player)
			return 0
		else
			return 3
		end
	end
	//Battle gametype
	if B.BattleGametype() and not(B.MyTeam(smo.player,tmo.player)) then return 3 end
	//Tag with collision
	if G_TagGametype() and CV.Collision.value return 1 end
	//Ringslinger with collision
	if G_RingSlingerGametype() and CV.Collision.value and not(B.MyTeam(smo.player,tmo.player)) return 3 end
	//Platforming with collision
	if CV.Collision.value return 1 end
	//Default
	return 0
end

B.CheckHeightCollision = function(mo,othermo)
	if mo.z+mo.height < othermo.z then return false end
	if mo.z > othermo.z+othermo.height then return false end
	return true
end

B.GetCollideRelativeAngle = function(mo,collide,drawangle)
-- 	if not (mo and mo.valid and mo.health and collide and collide.valid and collide.health)
-- 		then return nil
-- 	end
	local collideangle
	if mo.player and drawangle then
		collideangle = mo.player.drawangle - R_PointToAngle2(mo.x-mo.momx,mo.y-mo.momy,collide.x-collide.momx,collide.y-collide.momy)
	else
		collideangle = mo.angle - R_PointToAngle2(mo.x-mo.momx,mo.y-mo.momy,collide.x-collide.momx,collide.y-collide.momy)
	end
	//Pretty sure this is redundant
	if collideangle >= 180*ANG1 then
		collideangle = $- 360*ANG1
	elseif collideangle <= -180*ANG1 then
		collideangle = $+360*ANG1
	end
	return collideangle
end

B.GetZCollideAngle = function(mo,collide)
-- 	if not(mo and mo.valid and mo.health and collide and collide.valid and collide.health)
-- 		then
-- 		print("\x82 Error:\x80 An object in GetZCollideAngle() does not exist!")
-- 		return 0
-- 	end
	local h = mo.height/2 --* P_MobjFlip(mo)
	local ch = collide.height/2 --* P_MobjFlip(collide)
	local m = -mo.momz * P_MobjFlip(mo)
	local cm = -collide.momz * P_MobjFlip(collide)
	local x = mo.x - mo.momx
	local y = mo.y - mo.momy
	local z = mo.z + h + m
	local cx = collide.x - collide.momx
	local cy = collide.y - collide.momy
	local cz = collide.z + ch + cm
	local zdist = z-cz
	local xydist = FixedHypot(x-cx,y-cy)
	local collideangle = R_PointToAngle2(0,0,xydist,zdist)
	return collideangle * P_MobjFlip(mo)
end

local function damage(target, inflictor, source, damage, extra)
	local shove = false
	
	if target and target.valid and target.player then
		if extra == "shove_special" then
			if target.player.battle_def >= 1 then
				shove = true
			end
		elseif extra == "shove"
			shove = true
		end
	end

	if shove then
		B.DoPlayerShove(target.player, inflictor, source)
	else
		P_DamageMobj(target, inflictor, source, damage)
	end
end

B.DoPlayerCollisionDamage = function(smo,tmo)
	local s = 1
	local t = 2
	local mo = {smo,tmo}
	local atk = {}
	local def = {}
	local bias = {}
	local extra = {}
	local power = {false,false}
	local tagit = {false,false}
	local invuln = {true,true} //Default, for nonplayer objects
	for n = 1,2
		if mo[n].player then
			atk[n] = mo[n].player.battle_atk
			def[n] = mo[n].player.battle_def
			extra[n] = mo[n].player.battle_extra
		else
			atk[n] = mo[n].battle_atk
			def[n] = mo[n].battle_def
			extra[n] = mo[n].battle_extra
		end
		if atk[n] == nil then atk[n] = 0 end
		if def[n] == nil then def[n] = 0 end
	end
	
	
	bias[s] = def[s]-atk[t] // 0 == uncurl. -1 == take damage
	bias[t] = def[t]-atk[s]
	for n = 1,2
		if mo[n].player then
			power[n] = (mo[n].player.powers[pw_super] or mo[n].player.powers[pw_invulnerability])
			tagit[n] = (mo[n].player.pflags&PF_TAGIT or mo[n].player.battletagIT)
			invuln[n] = (mo[n].player.powers[pw_flashing])
		elseif mo[n].sentient then
			invuln[n] = false
		end
	end
	local ssrc = smo
	local tsrc = tmo
	if not(smo.player) then ssrc = smo.target end
	if not(tmo.player) then tsrc = tmo.target end
	if power[s] and not(power[t] or invuln[t]) then
		damage(tmo,smo,ssrc,0,extra[s])
		return 1
	elseif power[t] and not(power[s] or invuln[s]) then
		damage(smo,tmo,tsrc,0,extra[t])
		return -1
	else
		//adding this in because it was missing it seems
		if tagit[s] and not (tagit[t] or invuln[t])
			damage(tmo, smo, ssrc, 0, extra[s])
			return 1
		elseif tagit[t] and not (tagit[s] or invuln[s])
			damage(smo, tmo, tsrc, 0, extra[t])
			return -1
		end
		local ret = 0
		if bias[s] < 0 and not(invuln[s] or power[s]) then
			damage(smo,tmo,tsrc,0, extra[t])
			ret = -1
		end
		if bias[t] < 0 and not(invuln[t] or power[t]) then
			damage(tmo,smo,ssrc,0, extra[s])
			if ret == -1
				ret = 2
			else
				ret = 1
			end
		end
		return ret
	end
	return 0
	// 0: nobody was hurt
	// 1: t was hurt by s
	//-1: s was hurt by t
	// 2: both hurt
end

B.UpdateRecoilState = function(mo)
	if not(mo and mo.valid and mo.health and mo.player) then return nil //Object invalid
	elseif mo.player.powers[pw_nocontrol] > 0 and mo.recoilangle != nil and mo.recoilthrust != nil then
		if P_PlayerInPain(mo.player) then
			mo.recoilangle = nil
			mo.recoilthrust = nil
			return false
		end
		if P_IsObjectOnGround(mo) then //Grounded
			if not(mo.player.charability == CA_GLIDEANDCLIMB) then
				if not(mo.recoilanim_override) then
					mo.state = S_PLAY_SKID
					mo.player.panim = 0
					mo.frame = 0
				end
			else
				if not(mo.recoilanim_override) then
					mo.state = S_PLAY_GLIDE_LANDING
				end
				mo.player.powers[pw_nocontrol] = $-1
			end
			if mo.player.skidtime == 0 and mo.recoilthrust > mo.scale*5 then
				S_StartSound(mo, sfx_skid)
			end
			mo.player.powers[pw_nocontrol] = min($,TICRATE/2)
			mo.player.skidtime = mo.player.powers[pw_nocontrol]
			//Apply recoil thrust
			P_InstaThrust(mo,mo.recoilangle,mo.recoilthrust)
			//Add friction
			mo.recoilthrust = ($+FixedMul($,FixedMul(mo.friction,mo.movefactor)))/2
		else //Aerial
			//Keep our variables up with current trajectory
			mo.recoilthrust = FixedHypot(mo.momx,mo.momy)
			mo.recoilangle = R_PointToAngle2(0,0,mo.momx,mo.momy)
			if not(mo.recoilanim_override) then
				mo.player.panim = PA_FALL
				mo.state = S_PLAY_FALL
			end
		end
		mo.player.drawangle = mo.recoilangle+ANGLE_180
		return true
	else //Not in disadvantage state, reset variables
		mo.air_recoilanim_override = nil
		mo.recoilangle = nil
		mo.recoilthrust = nil
		return false
	end
end

B.PlayerTouch = function(smo,tmo)
	if not(smo and smo.valid and tmo and tmo.valid and smo.player and tmo.player)
	or not(smo.health and tmo.health)
	or (smo.player.exiting or tmo.player.exiting)
	or (smo.player.battlespawning or tmo.player.battlespawning)
	or B.PreRoundWait()
	then return true end
	if not(B.GetInteractionType(smo,tmo)) then
		B.TailsCatchPlayer(smo.player,tmo.player)
		if not (smo.cantouchteam or tmo.cantouchteam) then
			return true //Don't bother trying to collide if nothing's going to come of it
		end
	end
	if (smo.player.tailsthrown and smo.player.tailsthrown == tmo.player)
	or (tmo.player.tailsthrown and tmo.player.tailsthrown == smo.player)
	then
		return true
	end

	smo.pushed = tmo //'mo.pushed' will be referenced in ThinkFrame
	tmo.pushed = smo
	smo.flags = $&~MF_SPECIAL
	tmo.flags = $&~MF_SPECIAL
	if not (smo.cantouchteam or tmo.cantouchteam)
		tmo.player.pflags = $&~PF_CANCARRY
		smo.player.pflags = $&~PF_CANCARRY
	end
	return true
end

B.UpdateCollisionHistory = function(pmo)
	//Needs comments
	//Initialize
	if pmo.pushtics == nil then pmo.pushtics = 0 end
	//If we've recently been pushed
	if pmo.pushed or pmo.pushed_last then
		//Update the timer
		if pmo.pushtics == 0 then
			pmo.pushtics = 1
		else
			pmo.pushtics = $+1
			//After a certain time, clean the slate
			if pmo.pushtics > CV.CollisionTimer.value then
				pmo.pushed_last = nil
				pmo.pushed = nil
				pmo.pushtics = 0
			end
		end
	else
		//No pusher, no need for pushtics
		if pmo.pushtics then
			pmo.pushtics = 0 //!! If this is reset just off of pushed being nil, and pushed is reset per frame, then when is this not 1 or 0??
		end
	end
	//Update other player object's pushed stats
	if pmo.pushed and pmo.pushed.valid and pmo.pushed.pushed == pmo and not(pmo.pushtics) then
		pmo.pushed.flags = $|MF_SPECIAL
		pmo.pushed.pushed_last = pmo
		pmo.pushed.pushed = nil
	end
	pmo.flags = $|MF_SPECIAL //Reallow collisions
	if pmo.pushed then
		pmo.pushed_last = pmo.pushed //History
		pmo.pushed = nil //Done with this
	end
	local player = pmo.player
	if player.pushed_creditplr != nil
		if player.pushed_creditplr.valid and P_IsObjectOnGround(pmo) and not(player.powers[pw_nocontrol] or player.powers[pw_flashing] or player.tumble) then
			player.pushed_creditplr = nil
		end
	end
end

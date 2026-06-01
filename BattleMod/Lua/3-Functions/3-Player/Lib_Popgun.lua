//Original scripts by TehRealSalt, modified by CobaltBW

local B = CBW_Battle
local S = B.SkinVars

local refiretime = 20

B.NewGunLook = function(player, player_angle, mo)
	if player_angle == nil then
		player_angle = player.mo.angle
	end
	local twod = (twodlevel or player.mo.flags2 & MF2_TWOD)
	local ringdist, span
	if not(twod)
		ringdist = RING_DIST*2
		span = ANG30
	else
		ringdist = RING_DIST
		span = ANG20
	end

	local maxdist = FixedMul(ringdist, player.mo.scale)
	local closestdist = 0
	local closestmo = nil
	local nonenemiesdisregard = MF_SPRING
	searchBlockmap("objects",function(pmo,mo)
		if (mo.flags & MF_NOCLIPTHING) return end
		if (mo.health <= 0) return end -- dead

		if not(mo.player)
		and (!((mo.flags & (MF_ENEMY|MF_BOSS|MF_MONITOR)
		and (mo.flags & MF_SHOOTABLE)) or (mo.flags & MF_SPRING)) == !(mo.flags2 & MF2_INVERTAIMABLE)) -- allows if it has the flags desired XOR it has the invert aimable flag
			return -- not a valid target
		end
		//CTF monitor 
		if mo.type == MT_RING_REDBOX and not(G_GametypeHasTeams() and player.ctfteam == 1) then return end
		if mo.type == MT_RING_BLUEBOX and not(G_GametypeHasTeams() and player.ctfteam == 2) then return end

		if (mo == pmo) return end
		if (mo.flags2 & MF2_FRET) return end
		if (mo.flags & nonenemiesdisregard) return end
-- 		if (mo.type == MT_PLAYER) return end -- Don't chase after other players!
		if (mo.type == MT_TARGETDUMMY) return end //We won't be relying on this for player detection
		if (mo.player and (B.MyTeam(player,mo.player) or mo.player.spectator)) then return end //Disallow targeting teammates
		if (mo.player and mo.player.intangible) then return end//Disallow targeting air dodge

		//Do angle/distance checks
		local zdist = (pmo.z + pmo.height/2) - (mo.z + mo.height/2)
		local dist = P_AproxDistance(pmo.x-mo.x, pmo.y-mo.y)
		//CBW: 	Made the angle checks their own locals, for readability purposes
		//		I also unsigned the angle checks, which appears to correct failed OutOfBounds checks above the player.
		local xyz_angle = abs(R_PointToAngle2(0, 0, dist, zdist))
		local xy_angle = abs(R_PointToAngle2(
				pmo.x + P_ReturnThrustX(pmo, player_angle, pmo.radius),
				pmo.y + P_ReturnThrustY(pmo, player_angle, pmo.radius),
				mo.x, mo.y
			) - player_angle)
			
			
		dist = P_AproxDistance(dist, zdist)
		if (dist > maxdist)
			return -- out of range
		end
-- 		print("\x82!!!VERT","# Span check: "..xyz_angle/ANG1,"# Limit: "..span*2/ANG1,"#Within Range: "..tostring(abs(xyz_angle) <= span))
		if (xyz_angle > span)
			return -- Don't home outside of desired angle!
		end


		if (twod
		and abs(pmo.y-mo.y) > pmo.radius)
			return -- not in your 2d plane
		end

		if ((closestmo and closestmo.valid) and (dist > closestdist))
			return
		end
-- 		print("\x82!!!HORZ","# Span check: "..xy_angle/ANG1,"# Limit: "..span*2/ANG1,"#Within Range: "..tostring(abs(xy_angle) <= span))
		if (xy_angle > span)
			return -- behind back
		end

		if not (P_CheckSight(pmo, mo))
			return -- out of sight
		end

		closestmo = mo
		closestdist = dist
	end,player.mo,player.mo.x-maxdist,player.mo.x+maxdist,player.mo.y-maxdist,player.mo.y+maxdist)
	return closestmo
end

local function zpos(posmo, item)
	return (posmo.z + (posmo.height - mobjinfo[item].height)/2)
end

local buffer = 1


local function newGunslinger(player)
	local mo = player.mo
	local skin = S[mo.skin] or S[-1]
	local onground = P_IsObjectOnGround(mo)
	local canstand = true

	local sliding = skin.special == B.Action.Slide
		and player.actionstate == 2

	if mo._slinger_reticle
	and not mo._slinger_reticle.valid then
		mo._slinger_reticle = nil
	end

	//State: ready to gunsling
	if not ((player.pflags&(PF_SLIDING|PF_THOKKED)and not(player.pflags&PF_BOUNCING)) or (player.exiting) or (P_PlayerInPain(player)))
	and not (player.weapondelay)
	and not (player.panim == PA_ABILITY2)
	and not (player.airgun)
	and (player.pflags&(PF_JUMPED|PF_BOUNCING) or ((mo._slinger_stick and mo._slinger_stick.valid) and not(player.pflags&PF_JUMPED)) or sliding) then
		-- Same code as vanilla, but without the clause for speed.
		-- You naturally lose your speed via friction.
		-- v10 EDIT: Now Fang automatically looks towards lockons
		-- v10 EDIT 2: i gave fang autoaim if he holds lol


		local targetangle = mo.angle

		local sticky

		local lockon = nil

		if player.gunheld >= 12 then

			local prev_lock = mo._slinger_stick
	
			local directionchar_look = B.NewGunLook(player, player.mo.angle)

			local cam_look = B.NewGunLook(player, player.realangleturn<<16)

			local directionchar = {
				col = SKINCOLOR_RED,
				distance = directionchar_look and 
							directionchar_look.valid and 
							R_PointToDist2(mo.x, mo.y, directionchar_look.x, directionchar_look.y),

				angle    = directionchar_look and 
							directionchar_look.valid and 
							R_PointToAngle2(mo.x, mo.y, directionchar_look.x, directionchar_look.y)
			}

			local cam = {
				col = SKINCOLOR_RED,
				distance = cam_look and 
							cam_look.valid and 
							R_PointToDist2(mo.x, mo.y, cam_look.x, cam_look.y),

				angle    = cam_look and 
							cam_look.valid and 
							R_PointToAngle2(mo.x, mo.y, cam_look.x, cam_look.y)
			}

			local prev = {
				distance = prev_lock and 
							prev_lock.valid and 
							R_PointToDist2(mo.x, mo.y, prev_lock.x, prev_lock.y),

				angle 	 = prev_lock and 
							prev_lock.valid and 
							R_PointToAngle2(mo.x, mo.y, prev_lock.x, prev_lock.y),

				col 	 = SKINCOLOR_SHAMROCK
			}

			local prev_check = prev.angle and B.NewGunLook(player, prev.angle)

			if (player.pflags & PF_ANALOGMODE) then

				if prev_lock and prev_lock.valid and (prev_check and prev_check.valid) then
					
					--B.DrawAimLine(player, prev.angle, SKINCOLOR_YELLOW)


					if directionchar_look and directionchar_look.valid then
						if (cam_look and cam_look.valid and (cam.distance < directionchar.distance)) then --Is our camera closer to a different object?
							--Aim at it, but only if the buffer is over
							if not(mo._slinger_buffer) then
								lockon = cam_look
								sticky = true
								cam.col = SKINCOLOR_SHAMROCK
							else
								mo._slinger_buffer = $-1
								lockon = prev_lock
								cam.col = SKINCOLOR_RED
							end
						elseif (prev_lock == directionchar_look) then --New Object is the old one?
							--Just aim to it, regardless of the buffer
							lockon = prev_lock
							--mo._slinger_buffer = buffer
							directionchar.col = SKINCOLOR_SHAMROCK
						else
							if not(mo._slinger_buffer) then
								lockon = directionchar_look
								directionchar.col = SKINCOLOR_SHAMROCK
								sticky = true
							else
								lockon = prev_lock
								mo._slinger_buffer = $-1
								directionchar.col = SKINCOLOR_RED
							end
						end
					else
						lockon = prev_lock
						--mo._slinger_buffer = buffer
					end
				else --No locked object?
					lockon = directionchar_look
					directionchar.color = SKINCOLOR_SHAMROCK
					sticky = true
				end
				--B.DrawAimLine(player, player.mo.angle, directionchar.col)
				--B.DrawAimLine(player, player.realangleturn<<16, cam.col)
			else
				--Non-Automatic mode aiming
				local prev_check = B.NewGunLook(player, prev.angle)
				if prev_lock and prev_lock.valid and (prev_check and prev_check.valid) then

					--direction_char look *is* cam_look if we're not in automatic
					if directionchar_look and directionchar_look.valid
						if (prev_lock == directionchar_look) then --New Object is the old one?
							--Just aim to it, regardless of the buffer
							lockon = prev_lock
							--mo._slinger_buffer = buffer
							directionchar.col = SKINCOLOR_SHAMROCK
						else
							--Aim at it, but only if the buffer is over
							if not(mo._slinger_buffer) then
								lockon = directionchar_look
								directionchar.col = SKINCOLOR_SHAMROCK
								sticky = true
							else
								lockon = prev_lock
								mo._slinger_buffer = $-1
								directionchar.col = SKINCOLOR_RED
							end
						end
					else
						lockon = prev_lock
					end
				else --No locked object?
					lockon = directionchar_look
					directionchar.color = SKINCOLOR_SHAMROCK
					sticky = true
				end
			end

			

			

			if (lockon and lockon.valid) then

				targetangle = R_PointToAngle2(mo.x, mo.y, lockon.x, lockon.y)

				player.drawangle = targetangle
				-- P_SpawnLockOn(player, lockon, mobjinfo[MT_LOCKON].spawnstate)

				-- yknow, i COULD do this better, but nah, lets go the easiest (and stupidest) way.
				if not mo._slinger_reticle
				or mo._slinger_reticle.target ~= lockon then
					if mo._slinger_reticle then
						S_StopSoundByID(mo, sfx_cdfm42)
						S_StopSoundByID(mo, sfx_cdfm40)
						S_StopSoundByID(mo, sfx_cdfm13)
						S_StopSoundByID(mo, sfx_fn_trg)
						P_RemoveMobj(mo._slinger_reticle)
					end
					mo._slinger_reticle = P_SpawnMobjFromMobj(lockon, 0,0,0, MT_FANGRETICLE)
					mo._slinger_reticle.state = S_INVISIBLE
					mo._slinger_reticle.alpha = 0
					mo._slinger_reticle.scale = lockon.destscale * 2

					if sticky then
						mo._slinger_buffer = buffer
						mo._slinger_stick = lockon
					end

					for _, mobj in ipairs({mo, lockon}) do -- cheap i know
						S_StartSoundAtVolume(mobj, sfx_cdfm42, 60)
						S_StartSoundAtVolume(mobj, sfx_cdfm40, 30)
						S_StartSoundAtVolume(mobj, sfx_cdfm13, 80)
						S_StartSoundAtVolume(mobj, sfx_fn_trg, 100)
					end
				end

				local reticle = mo._slinger_reticle

				local move = P_MoveOrigin

				if reticle.point.state == S_INVISIBLE then
					move = P_SetOrigin
				end

				reticle.fuse = 2
				move(reticle, lockon.x, lockon.y, lockon.z)
				reticle.target = lockon
				reticle.color = ColorOpposite(mo.color)
				reticle.pointcolor = mo.color
				reticle.scale = ease.linear(FU/3, $, lockon.destscale)
				reticle.alpha = min(FU, $ + FU / 4)
				if reticle.state ~= S_FANGRETICLE_CIRCLE then
					reticle.state = S_FANGRETICLE_CIRCLE
				end
			else
				mo._slinger_stick = nil
			end
		else
			mo._slinger_stick = nil
			mo._slinger_buffer = nil
		end

		if player.cmd.buttons & BT_SPIN and not(player.pflags&PF_BOUNCING) then
			player.gunheld = $ + 1
		else
			player.gunheld = 0
		end
		//Trigger firing action
		if not (player.cmd.buttons & BT_SPIN)
		and (player.buttonhistory&BT_SPIN)
		or (player.pflags&PF_BOUNCING and player.cmd.buttons&BT_SPIN and not(player.buttonhistory&BT_SPIN))
			local bullet = nil

			if sliding then
				player.actiontime = $+1
				if player.actiontime >= 8 then
				    player.actionstate = 0
				    player.actiontime = 0
				    B.ApplyCooldown(player, TICRATE*3)
				    player.pflags = $ & ~PF_SPINNING
				end
			end

			mo.state = S_PLAY_FIRE
			player.panim = PA_ABILITY2
			player.weapondelay = refiretime
			player.shotangle = mo.angle
			mo.momx = $ * 3/4
			mo.momy = $ * 3/4
			S_StartSoundAtVolume(mo,sfx_s1c4,150)
			
			if player == consoleplayer
				P_StartQuake(4*FRACUNIT,1)
			end
			
			if (lockon and lockon.valid)
				mo.angle = R_PointToAngle2(mo.x,mo.y,lockon.x,lockon.y)
				player.shotangle = mo.angle
				bullet = P_SpawnPointMissile(
					mo,
					lockon.x, lockon.y, zpos(lockon, player.revitem),
					player.revitem,
					mo.x, mo.y, zpos(mo, player.revitem)
				)
			else
				bullet = P_SpawnPointMissile(
					mo,
					mo.x + P_ReturnThrustX(nil, mo.angle, FRACUNIT),
					mo.y + P_ReturnThrustY(nil, mo.angle, FRACUNIT),
					zpos(mo, player.revitem),
					player.revitem,
					mo.x, mo.y, zpos(mo, player.revitem)
				)
				//if bullet and bullet.valid then
				//	bullet.flags = $ & ~MF_NOGRAVITY
				//end
			end

			if (bullet and bullet.valid)
				-- bullet.flags = $1 & ~MF_NOGRAVITY
				local speed = max(60 * mo.scale, FixedHypot(mo.momx - player.cmomx, mo.momy - player.cmomy) * 3 / 4)
				local angle = R_PointToAngle2(0, 0, bullet.momx, bullet.momy)
				local aiming = R_PointToAngle2(0, 0, FixedHypot(bullet.momx, bullet.momy), bullet.momz)

				bullet.momx = P_ReturnThrustX(nil, angle, FixedMul(speed, cos(aiming)))
				bullet.momy = P_ReturnThrustY(nil, angle, FixedMul(speed, cos(aiming)))
				if (lockon and lockon.valid) then
				    bullet.momz = FixedMul(speed, sin(aiming))
			    else
				    bullet.momz = 0
			    end
			end
			
			player.drawangle = targetangle
			//Air function
			if not(P_IsObjectOnGround(mo))
			and not(player.pflags&PF_BOUNCING)
				B.ResetPlayerProperties(player,false,true)
				P_Thrust(mo,mo.angle+ANGLE_180,mo.scale*10)
				P_SetObjectMomZ(mo,FRACUNIT*5,true)
				mo.momx = $/2
				mo.momy = $/2
				mo.momz = $/2
				mo.state = S_FANG_AIRSHOT
				player.airgun = true
			//Tailbounce function
			elseif (player.pflags&PF_BOUNCING)
				mo.momx = $/2
				mo.momy = $/2
				mo.state = S_FANG_BCESHOT
				player.airgun = true
			else
				P_Thrust(mo,targetangle+ANGLE_180,mo.scale*3)
			end
		end
	else
		player.gunheld = 0
	end
	//Running and gunning
	local spd = FixedHypot(player.rmomx,player.rmomy)
	local dir = R_PointToAngle2(0,0,player.rmomx,player.rmomy)
	local thres = mo.scale*4
	if (player.panim == PA_ABILITY2) and spd > thres and P_IsObjectOnGround(player.mo)
		//spd = max(thres,$-FRACUNIT)
		//mo.momx = player.cmomx+P_ReturnThrustX(nil,dir,spd)
		//mo.momy = player.cmomy+P_ReturnThrustY(nil,dir,spd)
-- 		mo.frame= min(6,$)
-- 		print(mo.sprite2)
-- 		if mo.frame == 3 then
-- 	 		mo.tics = $+1
-- 		end
		//Do "skidding" effects
		if player.weapondelay%3 == 1 then
			S_StartSound(mo,sfx_s3k7e,player)
			local r = mo.radius/mo.scale
			P_SpawnMobj(
				P_RandomRange(-r,r)*mo.scale+mo.x,
				P_RandomRange(-r,r)*mo.scale+mo.y,
				mo.z,
				MT_DUST
			)
		end
	end
	//Running and jumping
	if player.panim == PA_ABILITY2 and P_IsObjectOnGround(mo) and player.cmd.buttons&BT_JUMP and not(player.buttonhistory&BT_JUMP)
		mo.state = S_PLAY_WALK
	end
	
    //Air gunning
	if not(P_IsObjectOnGround(mo)) and player.airgun == true and player.weapondelay
	and not(player.pflags & PF_BOUNCING)
	    if mo.state == S_PLAY_FALL
	        mo.state = S_FANG_AIRSHOT_FINISH
		elseif mo.state == S_FANG_AIRSHOT_FINISH then
		    mo.tics = player.weapondelay
		end
	end
	
	if P_IsObjectOnGround(mo) and player.airgun == true
		player.airgun = false
		if (player.weapondelay) then
			mo.state = S_PLAY_FIRE_FINISH
			mo.tics = player.weapondelay
		end
	end
	
    //Tailbounce gunning
	if (player.pflags&PF_BOUNCING) and player.airgun == true and player.weapondelay
	    if mo.state == S_PLAY_BOUNCE then
	        mo.state = S_FANG_BCESHOT_FINISH
	    elseif mo.state == S_FANG_BCESHOT_FINISH then
		    mo.tics = player.weapondelay
		end
	end
	
	//Drawangle locked during firing states
	local shotstates = {
        [S_PLAY_FIRE] = true,
        [S_PLAY_FIRE_FINISH] = true,
        [S_FANG_AIRSHOT] = true,
        [S_FANG_AIRSHOT_FINISH] = true,
        [S_FANG_BCESHOT] = true,
        [S_FANG_BCESHOT_FINISH] = true
    }
	if player.shotangle then
        if player.weapondelay and shotstates[mo.state] then
            player.drawangle = player.shotangle
	    else
            player.shotangle = nil
        end
    end
end

local ground_to_air = {
	[S_PLAY_FIRE] = S_FANG_AIRSHOT,
	[S_PLAY_FIRE_FINISH] = S_FANG_AIRSHOT_FINISH
}

local air_to_ground = {
	[S_FANG_AIRSHOT] = S_PLAY_FIRE,
	[S_FANG_AIRSHOT_FINISH] = S_PLAY_FIRE_FINISH
}

B.CustomGunslinger = function(player)
	if not(player.mo) return end
	if not(B.GetSkinVarsFlags(player)&SKINVARS_GUNSLINGER) return end

	//Disallow native CA2_GUNSLINGER functionality
	if player.charability2 == CA2_GUNSLINGER
		player.charability2 = CA2_NONE 
	end
	//Player is damaged
	
	if P_PlayerInPain(player)
		player.airgun = false
		player.gunheld = 0
	return end

	local skin = S[player.mo.skin] or S[-1]
	local sliding = skin.special == B.Action.Slide
		and player.actionstate == 2

	//Unable to use gun during certain states
	if player.powers[pw_nocontrol]
	or player.powers[pw_carry]
	or (player.actionstate and not sliding)
	or (player.pflags&PF_SPINNING and not sliding)
		player.airgun = false
		player.gunheld = 0
	return end
	//Get inputs
	if (player.gunheld == nil)
		player.gunheld = 0
	end
	
    //Airgun resets on tailbounce landing
    if player.airgun and player.mo.state == S_PLAY_BOUNCE_LANDING then
        player.airgun = false
    end
	
	if P_IsObjectOnGround(player.mo) then
		if air_to_ground[player.mo.state] then
			local frame = player.mo.frame
			player.mo.state = air_to_ground[$]
			player.mo.frame = frame
		end
	else
		if ground_to_air[player.mo.state] then
			local frame = player.mo.frame
			player.mo.state = ground_to_air[$]
			player.mo.frame = frame
		end
	end

	
	//Do Gunslinger
	newGunslinger(player)
end

B.PreGunslinging = function(player)
	if not(player.mo
	and B.GetSkinVarsFlags(player,SKINVARS_GUNSLINGER)
	and player.panim == PA_ABILITY2)
	return end
	if player.pflags&PF_AUTOBRAKE then
		player.cmd.forwardmove = max(-1,min(1,$))
		player.cmd.sidemove = max(-1,min(1,$))
	else
		player.cmd.forwardmove = 0
		player.cmd.sidemove = 0
	end
-- 	player.cmd.buttons = $&~BT_JUMP
end

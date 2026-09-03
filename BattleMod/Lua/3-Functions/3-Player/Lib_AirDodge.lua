local B = CBW_Battle
local CV = B.Console

local intangible_time = TICRATE*4/5
local dodge_endlag = TICRATE
local dodge_momz = 5
local dodge_thrust = 15

B.AirDodge = function(player)
	if not (CV.airtoggle.value and player and player.valid and player.mo and player.mo.valid)
		return
	end
	local mo = player.mo
	
	local intangible_time_real = intangible_time
	local safe_dodge = player.safedodge and player.safedodge > 0
	local unsafe_dodge = player.safedodge and player.safedodge < 0
	if not (safe_dodge) then
		intangible_time_real = intangible_time/2
		--if unsafe_dodge is true, intangible_time won't do anything
	end
	
	if B.ButtonCheck(player, player.battleconfig_guard) == 1
		and (CV.Guard.value)
		and player.canguard
		and player.mo.state != S_PLAY_PAIN
		and player.mo.state != S_PLAY_STUN
		and player.airdodge == 0
		and player.playerstate == PST_LIVE
		and not player.exiting
		and not player.actionstate
		and not player.climbing
		and not player.armachargeup
		and not player.isjettysyn
		and not player.revenge
		and not player.powers[pw_nocontrol]
		and not player.powers[pw_carry]
		and not P_IsObjectOnGround(mo)
		and not mo.temproll
		
		local dodgecam = player.battleconfig_dodgecamera
		local deadzone = (R_PointToDist2(0, 0, player.cmd.forwardmove, player.cmd.sidemove) <= 10)
		local automatic = (player.pflags & PF_ANALOGMODE)

		local angle = mo.angle

		local angle = player.thinkmoveangle
		
		if (dodgecam or deadzone) and ((automatic and player.airdodge) or not(automatic)) then
			angle = player.mo.angle
		end
		
		player.airdodge_speedreset = true
		player.airdodge = 1
		player.airdodge_spin = ANGLE_90 + ANG10
		if not(player.dodgecooldown)
			player.safedodge = 1
			player.dodgecooldown = CV.dodgetime.value*TICRATE*3/2
		else
			player.safedodge = 0
			if player.dodgecooldown > CV.dodgetime.value*TICRATE then
				player.safedodge = -1
			end
			//player.dodgecooldown = min($+CV.dodgetime.value*TICRATE,CV.dodgetime.value*TICRATE*3/2)
		end
		
		//State and flags
		B.ResetPlayerProperties(player,false,false)
		mo.state = S_PLAY_FALL
		player.airgun = false
		
		if (player.powers[pw_shield] & SH_NOSTACK) == SH_WHIRLWIND
			player.pflags = $ | PF_SHIELDABILITY
		end
		
		//Release carried player
		for otherplayer in players.iterate
			local partner = otherplayer.mo
			if not(
				partner and partner.valid
				and partner.tracer == mo
				and otherplayer.powers[pw_carry] == CR_PLAYER
			)
				continue
			end
			partner.tracer = nil
			otherplayer.powers[pw_carry] = 0
			B.ResetPlayerProperties(otherplayer, true, false)
		end
		
		//Launch
		local dodge_momz_real = dodge_momz*mo.scale/B.WaterFactor(mo)
		local dodge_thrust_real = mo.scale*dodge_thrust
		if player.gotflagdebuff
			player.safedodge = -1
			dodge_thrust_real = $ * 3/4
			dodge_momz_real = $ / 2
		end
		
		local diff = dodge_momz_real - (mo.momz*P_MobjFlip(mo))
		if (diff > 0)
			mo.momz = dodge_momz_real*P_MobjFlip(mo)
		else
			mo.momz = (dodge_momz_real - diff/2)*P_MobjFlip(mo)
		end
		
		mo.momx = $ / 7
		mo.momy = $ / 7
		//if not neutral
			P_Thrust(mo,angle,dodge_thrust_real)
		//end
		player.drawangle = mo.angle
		
		//SFX
		S_StartSound(mo, sfx_s3k47)
		if player.safedodge and player.safedodge > 0 then
			S_StartSoundAtVolume(mo, sfx_nbmper, 125)
		elseif player.safedodge and player.safedodge < 0 then
			S_StartSoundAtVolume(mo, sfx_s3kd7s, 125)
		end
		
		//Sparkle
		local sparkle = P_SpawnMobj(mo.x,mo.y,mo.z,MT_SUPERSPARK)
		sparkle.scale = mo.scale
		sparkle.destscale = 0
		if AST_ADD
			sparkle.blendmode = AST_ADD
		end
		sparkle.momx = mo.momx / 2
		sparkle.momy = mo.momy / 2
		sparkle.momz = mo.momz * 2/3
	end
	
	//Airdodge is in progress
	if player.airdodge != 0
		B.analogkill(player, 2)
		if player.isjettysyn
			or player.powers[pw_carry]
			or P_PlayerInPain(player)
			or P_IsObjectOnGround(mo)
			
			player.airdodge = 0
			player.pflags = $ & ~PF_FULLSTASIS

		elseif player.airdodge > 0
			player.airdodge = $ + 1
			if not safe_dodge then
				player.pflags = $ | PF_FULLSTASIS
			end
			if player.airdodge <= intangible_time_real
				if (player.airdodge % 4) == 3 and not unsafe_dodge
					mo.colorized = true
					mo.color = SKINCOLOR_WHITE
					if player.followmobj then
						player.followmobj.colorized = mo.colorized
						player.followmobj.color = mo.color
					end
					mo.airdodgecolor = true
					if safe_dodge then
						local g = P_SpawnGhostMobj(mo)
						if AST_ADD
							g.blendmode = AST_ADD
						end
					end
				elseif ((player.airdodge % 4) != 1) and not unsafe_dodge
					mo.colorized = true
					mo.color = SKINCOLOR_SILVER
					if player.followmobj then
						player.followmobj.colorized = mo.colorized
						player.followmobj.color = mo.color
					end
					mo.airdodgecolor = true
				else
					mo.colorized = false
					mo.color = player.skincolor
					if player.followmobj then
						player.followmobj.colorized = mo.colorized
						player.followmobj.color = mo.color
					end
					mo.airdodgecolor = false
				end
			else
				mo.colorized = false
				mo.color = player.skincolor
				if player.followmobj then
					player.followmobj.colorized = mo.colorized
					player.followmobj.color = mo.color
				end
				mo.airdodgecolor = false
			end
			if player.airdodge > dodge_endlag
				player.airdodge = -1
				player.lockmove = false
				player.drawangle = mo.angle
			else
				player.airdodge_spin = $ + ANGLE_90 + ANG15 - (ANG1*3 * player.airdodge)
				player.drawangle = mo.angle + player.airdodge_spin
			end
		end
	elseif mo.airdodgecolor
		mo.colorized = false
		mo.color = player.skincolor
		if player.followmobj then
			player.followmobj.colorized = mo.colorized
			player.followmobj.color = mo.color
		end
		mo.airdodgecolor = false
	end
	
	local skin = skins[player.mo.skin]
	if (player.airdodge > 0 and player.airdodge <= intangible_time_real)
		player.intangible = (not unsafe_dodge)
		player.thrustfactor = skin.thrustfactor+5
		player.normalspeed = skin.normalspeed/2
	else
		if (player.airdodge_speedreset) then
			player.intangible = false
			player.thrustfactor = skin.thrustfactor
			player.normalspeed = skin.normalspeed
			player.airdodge_speedreset = false
		end
	end
end
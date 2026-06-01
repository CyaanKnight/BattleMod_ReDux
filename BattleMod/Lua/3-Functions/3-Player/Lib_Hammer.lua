local B = CBW_Battle

local st_idle = 0
local st_hold = 1
local st_release = 2
local st_jump = 3

local sideangle = ANG30 - ANG10

local air_special = 9
local piko_special = 11 
local piko_cooldown = TICRATE * 2
local pikowave_duration = TICRATE
local ALLOWCHARGEHAMMER = false

local function heartcolor(msl, player, bluecolor, redcolor)
	msl.colorized = true
	if G_GametypeHasTeams() then
		return player.ctfteam == 2 and (bluecolor or SKINCOLOR_SKY) or (redcolor or SKINCOLOR_ROSY)
	else
		return player.mo.color
	end
end

local function twin(player, twirl)
	local pflags = player.pflags
	player.panim = PA_ABILITY
	player.mo.state = (twirl and S_AMY_PIKOTWIRL) or S_PLAY_TWINSPIN
	player.frame = 0
	player.pflags = $|PF_THOKKED|PF_NOJUMPDAMAGE
	S_StartSound(player.mo,sfx_s3k42)

	//pw_strong is a new power that we use now ~JoJo
	player.powers[pw_strong] = STR_TWINSPIN
	player.mo.melee_hammertwirl = true

	//Extra projectiles
	player.melee_charge = 0
	local powerjump = not (pflags&PF_NOJUMPDAMAGE)
	if true --not(pflags&PF_NOJUMPDAMAGE)
		local mo = player.mo
		local speed = powerjump and (mo.scale * 40) or (mo.scale * 20)
		if twirl then
			for n = -2,2 do
				local msl = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_LHRT)
				if msl and msl.valid
					msl.target = mo
					msl.extravalue2 = FRACUNIT*95/100
					if powerjump then
						msl.fuse = 30
						msl.scale = 1
						msl.destscale = FRACUNIT*3/2
						msl.scalespeed = FRACUNIT/2
						msl.blockable = 2
						msl.cusval = 1
					else
						msl.fuse = 15
						msl.blockable = 1
					end
					msl.flags = $ | MF_NOGRAVITY
					local xyangle = (player.battleconfig_hammerstrafe and mo.angle or player.drawangle)+n*(ANG1*3)*5
					local zangle = 0
					B.InstaThrustZAim(msl,xyangle,zangle,speed,false)		
					msl.momx = $ + mo.momx
					msl.momy = $ + mo.momy
					msl.momz = 0
					msl.color = heartcolor(msl, player)
				end
			end
		else
			for n = -2,2 do
				local msl = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_LHRT)
				if msl and msl.valid
					msl.target = mo
					msl.extravalue2 = FRACUNIT*95/100
					if powerjump then
						msl.fuse = 30
						msl.scale = 1
						msl.destscale = FRACUNIT*3/2
						msl.scalespeed = FRACUNIT/2
						msl.blockable = 2
						msl.cusval = 1
					else
						msl.fuse = 15
						msl.blockable = 1
					end
					msl.flags = $ | MF_NOGRAVITY
					local xyangle = player.battleconfig_hammerstrafe and mo.angle or player.drawangle
					local zangle = n*ANG1*5
					B.InstaThrustZAim(msl,xyangle,zangle,speed,false)		
					msl.momx = $ + mo.momx
					msl.momy = $ + mo.momy
					msl.momz = $ + mo.momz
					msl.color = heartcolor(msl, player)
				end
			end
		end
		S_StartSound(mo, sfx_hoop1)
	end

	//Angle adjustment
	if player.battleconfig_hammerstrafe then
		player.drawangle = player.mo.angle
	end
end

B.TwinSpinJump = function(player) //Double jump function
	if not(B.GetSkinVarsFlags(player)&SKINVARS_ROSY)
	or player.pflags&PF_THOKKED
	or not(player.pflags&PF_JUMPED)
	or player.gotflagdebuff
		return
	end

	if (player.buttonhistory&BT_JUMP) or (player.pflags & PF_JUMPDOWN) then
		return true
	end
	
	local mo = player.mo
	
	local jumpthrust = FRACUNIT*39/4
	--B.ZLaunch(mo,jumpthrust,false)
	
	--S_StartSound(mo,sfx_cdfm02)
	--S_StopSoundByID(mo,sfx_jump)
	
	twin(player, true)
	player.pflags = $|PF_JUMPED|PF_STARTJUMP
	return true
end

B.TwinSpin = function(player)
	if not(B.GetSkinVarsFlags(player)&SKINVARS_ROSY)
	or player.pflags&PF_THOKKED
	or not(player.pflags&PF_JUMPED)
		return
	end

	if player.buttonhistory&BT_SPIN then
		return true
	end
	
	twin(player)
	return true
end

//Wave spawning
B.SpawnWave = function(player,angle_offset,mute)
	local mo = player.mo
	local wave = P_SPMAngle(mo,MT_PIKOWAVE,player.drawangle + angle_offset)
	if wave and wave.valid
		wave.teamcolor = heartcolor(wave, player, SKINCOLOR_SAPPHIRE, SKINCOLOR_RUBY)
		wave.mute = mute
		if not(wave.mute)
			S_StartSound(wave,sfx_nbmper)
		end
		wave.color = SKINCOLOR_GOLD
		wave.fuse = pikowave_duration
		wave.scale = mo.scale
	end
end

B.hammerjump = function(player,power)
	local h = power and 6 or 2
	local v = power and 13 or 10
		
	if ((player.cmd.buttons & BT_SPIN) and not(player.cmd.buttons & BT_JUMP)) then
		h = $*8
		--v = $*2/3 --i just realized that not holding jump already makes the jump weaker, so this is unnecessary xd ~lu
	end

	local mo = player.mo
	//P_DoJump(player,false)
	B.ZLaunch(mo,FRACUNIT*v,true)
	P_Thrust(mo,player.drawangle,h*mo.scale)
	S_StartSound(mo,sfx_cdfm37)
	S_StartSoundAtVolume(mo,sfx_s3ka0,power and 255 or 100)
	if not power
		player.pflags = ($ | PF_JUMPED | PF_STARTJUMP | PF_NOJUMPDAMAGE ) &~(PF_THOKKED)
	else
--		P_SpawnParaloop(mo.x, mo.y, z, mo.scale<<6,16,MT_LHRT,ANGLE_90,nil,0)
		player.pflags = ($ | PF_JUMPED | PF_STARTJUMP ) &~(PF_THOKKED|PF_NOJUMPDAMAGE)
		player.actionstate = 0
		B.ApplyCooldown(player, piko_cooldown)
	end
	mo.state = power and S_PLAY_ROLL or S_PLAY_JUMP
	player.panim = power and PA_ROLL or PA_JUMP
end

local doGroundHearts = function(player)
	local mo = player.mo
	local speed = mo.scale * 8
	local spread = FRACUNIT * 4
	speed = $ + player.speed
	if player.actionstate == air_special then
		speed = $ + player.speed
		spread = $ + (FRACUNIT * 3/2)
	end
	local angle = player.drawangle
	local zangle = player.actionstate == air_special and ANG1*5 or 1
	for n = -2,2 do
		local xmom = FixedMul(n * spread, cos(angle+ANGLE_90))
		local ymom = FixedMul(n * spread, sin(angle+ANGLE_90))
		local zmom = n%2==0 and spread or spread*3/2
		local msl = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_LHRT)
		if msl and msl.valid then
			msl.target = mo
			msl.extravalue2 = FRACUNIT*95/100
			B.InstaThrustZAim(msl,angle,zangle,speed,false)
			msl.momx = $ + xmom + mo.momx
			msl.momy = $ + ymom + mo.momy
			P_SetObjectMomZ(msl, zmom)
			msl.color = heartcolor(msl, player)
			local dest = msl.scale
			msl.scale = 1
			if player.actionstate == air_special then
				msl.fuse = 30
				msl.destscale = dest*3/2
				msl.scalespeed = FRACUNIT/2
				msl.blockable = 2
			else
				msl.fuse = 15
				msl.destscale = dest
				msl.scalespeed = FRACUNIT
			end
			msl.cusval = player.actionstate
			msl.cantouchteam = true
		end
	end
	mo.cusval = 1
end

//Hammer ticframe control
B.HammerControl = function(player)
	//Initialize variables
	if player.melee_state == nil player.melee_state = 0 end
	if player.melee_charge == nil player.melee_charge = 0 end

	local mo = player.mo
	if not(mo and mo.valid and B.GetSkinVarsFlags(player)&SKINVARS_ROSY)
		player.melee_state = 0
		player.melee_charge = 0
		return
	end

	// hitboxes
	local frameIndex = (mo.frame & FF_FRAMEMASK)
	if not player.battlehitbox and frameIndex == 2 and 
	( mo.state == S_PLAY_TWINSPIN or mo.state == S_PLAY_MELEE or mo.state == S_AMY_PIKOTWIRL) then
		local orbit = 0
		local tics = TICRATE/5
		local s_state = S_UNKNOWN
		if mo.state == S_AMY_PIKOTWIRL then
			orbit = 1
			tics = 2
			s_state = S_AMY_PIKOTWIRL
		end
		local hitbox = B.BattleHitboxSpawn(player, 25*player.mo.scale, 1*player.mo.scale, tics, s_state, true, orbit)
	end
		
	--Hammer twirl airstall
	if (mo.state == S_AMY_PIKOTWIRL) and not(player.gotflagdebuff) then
		mo.momz = 0
	elseif (mo.state ~= S_PLAY_TWINSPIN)
		if mo.melee_hammertwirl then
			if (player.powers[pw_strong] & STR_TWINSPIN)
				player.powers[pw_strong] = $ & ~STR_TWINSPIN
			end
			if mo.state == S_PLAY_MELEE_LANDING then
				doGroundHearts(player)
			end
			mo.melee_hammertwirl = nil
		end
	end

	--Piko Wave failsafe
	if player.actionstate == piko_special then
		if not(P_IsObjectOnGround(mo)) and (mo.state ~= S_PLAY_MELEE) and (mo.state ~= S_PLAY_MELEE_FINISH) and (mo.state ~= S_PLAY_MELEE_LANDING) then
			player.actionstate = 0
			B.ApplyCooldown(player, piko_cooldown)
		end
	end
	
	//Angle adjustment
	if player.battleconfig_hammerstrafe
	and ((player.melee_state and P_IsObjectOnGround(mo)) or mo.state == S_PLAY_TWINSPIN)
	and not (mo.eflags & MFE_JUSTHITFLOOR)
		player.drawangle = mo.angle
	end
	
	player.charability2 = CA2_MELEE
	if P_PlayerInPain(player) or player.powers[pw_nocontrol] or player.playerstate != PST_LIVE
		player.melee_state = st_idle
		return
	end

	if (player.melee_state == st_hold and B.NearGround(mo)) --failsafe because ice physics are weird!!
		mo.state = S_PLAY_MELEE
		mo.frame = 0
	end 

	--watch out!! charged attack!
	local watchout1 = player.melee_state == st_release
	local watchout2 = (mo.state == S_PLAY_ROLL and not (player.pflags & PF_NOJUMPDAMAGE)) and not (
		(player.pflags & PF_SPINNING) or (player.pflags & PF_THOKKED) --dude this is so hacky
	)
	if (player.melee_charge >= FRACUNIT) and (watchout1 or watchout2) and not(leveltime%3) then
		local ghost = P_SpawnGhostMobj(mo)
		if ghost and ghost.valid then
			ghost.colorized = true
			ghost.fuse = 10
		end
		if watchout1 then
			B.DrawAimLine(player, player.battleconfig_hammerstrafe and mo.angle or player.drawangle)
		end
		if not P_IsObjectOnGround(mo) then
			player.charflags = $ & ~SF_NOSKID
		end
	end

	if not(P_IsObjectOnGround(mo))
		if (mo.state != S_PLAY_MELEE and mo.state != S_PLAY_MELEE_FINISH)
			player.melee_state = st_idle
			return
		end
		if (player.melee_state == st_hold)
			player.melee_state = st_idle
			mo.state = S_PLAY_FALL
		end
		-- strong for the melee swing
		if (mo.state == S_PLAY_MELEE or mo.state == S_PLAY_MELEE_FINISH)
			player.powers[pw_strong] = STR_MELEE
		end
	elseif player.melee_state == st_hold
		player.powers[pw_strong] = 0
	end -- ~JoJo
	
	if player.melee_state == st_hold
		if ALLOWCHARGEHAMMER == false or not(player.cmd.buttons&BT_SPIN)
			S_StartSound(mo,sfx_s3k42)
			if player.melee_charge >= FRACUNIT
				B.ZLaunch(mo, FRACUNIT*4, true)
			else
				B.ZLaunch(mo, FRACUNIT*3, true)
			end
			P_Thrust(mo, player.drawangle, 9*mo.scale)
			player.melee_state = st_release
			mo.state = S_PLAY_MELEE
		elseif player.melee_charge >= FRACUNIT
			if not(player.gotflagdebuff) then
				B.DrawAimLine(player, player.drawangle)
			end
		end
	end
	
	if player.melee_state != st_idle and mo.state != S_PLAY_MELEE and P_IsObjectOnGround(mo)
		player.buttonhistory = $ | BT_JUMP | BT_SPIN
		local spin = player.melee_charge >= FRACUNIT
		local inputs = (player.cmd.buttons & BT_JUMP) or (player.cmd.buttons & BT_SPIN)
		if (inputs or spin) and not (player.actionstate == air_special or player.actionstate == air_special+1 or player.gotflagdebuff) then
			if spin and not inputs then
				player.actionstate = 0
				B.ApplyCooldown(player, piko_cooldown)
				B.SpawnWave(player, 0, false)
			else
				B.hammerjump(player, spin)
			end
		else
			doGroundHearts(player)
		end
		player.melee_state = st_idle
	end
end

B.PostHammerControl = function(player)
	local mo = player.mo

	if not(mo and mo.valid and B.GetSkinVarsFlags(player)&SKINVARS_ROSY)
		return
	end

	-- fix piko wave while in a rising platform...
	if player.actionstate == piko_special and mo.state == S_PLAY_MELEE_LANDING then
		player.actionstate = 0
		B.ApplyCooldown(player, piko_cooldown)
		B.SpawnWave(player, 0, false)
	elseif mo.state == S_PLAY_MELEE_LANDING then
		-- nvm fix regular hearts too. rising platforms i swear 
		if not (mo.cusval) then
			doGroundHearts(player)
			mo.momz = 0 --i tried to add mo.pmomz to the B.ZLaunch's, trust me i tried
			mo.tics = $ + (TICRATE/5)
		end
	else 
		mo.cusval = 0
	end
end

B.hammerchargevfx = function(mo)
	S_StartSound(mo,sfx_hamrc)
	local z = mo.z
	if P_MobjFlip(mo) == -1
		z = $+mo.height-mobjinfo[MT_SUPERSPARK].height
	end
	//P_SpawnParaloop(mo.x, mo.y, z, mo.scale<<6,8,MT_SPARK,ANGLE_90,nil,1)
	local offset_angle = mo.angle + ANGLE_180
	local offset_dist = mo.radius*3
	local range = 8
	local offset_x = P_ReturnThrustX(nil,offset_angle,offset_dist) + P_RandomRange(-range,range)*FRACUNIT
	local offset_y = P_ReturnThrustY(nil,offset_angle,offset_dist) + P_RandomRange(-range,range)*FRACUNIT
	local offset_z = mo.height/2 + P_RandomRange(-range,range)*FRACUNIT * P_MobjFlip(mo)
	offset_x = FixedMul($, mo.scale)
	offset_y = FixedMul($, mo.scale)
	offset_z = FixedMul($, mo.scale)
	local spark = P_SpawnMobj(
		mo.x+offset_x,
		mo.y+offset_y,
		mo.z+offset_z - (mo.scale*10),
		MT_SUPERSPARK
	)
	spark.scale = mo.scale * 5/3
	spark.destscale = 0
	spark.color = SKINCOLOR_ROSY
	spark.colorized = true
	P_SpawnParaloop(mo.x, mo.y, z, mo.scale<<8,16,MT_NIGHTSPARKLE,ANGLE_90,nil,1)
end

B.ChargeHammer = function(player)	
	local mo = player.mo
	
	if not(B.GetSkinVarsFlags(player)&SKINVARS_ROSY)
	or player.melee_state > 1
	or player.actionstate
	or not(P_IsObjectOnGround(mo))
	or not(player.melee_state or not(player.pflags&PF_USEDOWN))
	return end
	
	//Angle adjustment
	if (player.battleconfig_hammerstrafe) and not (mo.eflags & MFE_JUSTHITFLOOR)
		player.drawangle = mo.angle
	end

	//Start Charge
	if player.melee_state == st_idle
		player.melee_state = st_hold
		player.melee_charge = 0
	end
	
	//Jump cancel
	if player.melee_state == st_hold and player.cmd.buttons&BT_JUMP
		S_StartSound(mo,sfx_s3k42)
		B.ZLaunch(mo, FRACUNIT*3, true)
--		P_Thrust(mo, mo.angle, 9*mo.scale)
		player.melee_state = st_jump
	end	
	
	//Do "skidding" effects
	if leveltime%3 == 1 and player.speed > 3*mo.scale then
		S_StartSound(mo,sfx_s3k7e,player)
		local r = mo.radius/FRACUNIT
		local dust = P_SpawnMobj(
			P_RandomRange(-r,r)*FRACUNIT+mo.x,
			P_RandomRange(-r,r)*FRACUNIT+mo.y,
			mo.z,
			MT_DUST
		)
		if dust and dust.valid then dust.scale = mo.scale end
	end
	
	//Hold Charge
	if (player.melee_charge < FRACUNIT) and ALLOWCHARGEHAMMER == true then
		//Add Charge
		local chargetime = 18
		player.melee_charge = $+FRACUNIT/chargetime
		if not(player.gotflagdebuff) then
			local offset_angle = mo.angle + ANGLE_180
			local offset_dist = mo.radius*3
			local range = 8
			local offset_x = P_ReturnThrustX(nil,offset_angle,offset_dist) + P_RandomRange(-range,range)*FRACUNIT
			local offset_y = P_ReturnThrustY(nil,offset_angle,offset_dist) + P_RandomRange(-range,range)*FRACUNIT
			local offset_z = mo.height/2 + P_RandomRange(-range,range)*FRACUNIT * P_MobjFlip(mo)
			offset_x = FixedMul($, mo.scale)
			offset_y = FixedMul($, mo.scale)
			offset_z = FixedMul($, mo.scale)
			if not(leveltime&3)
				//Do Sparkle
				local spark = P_SpawnMobj(
					mo.x+offset_x,
					mo.y+offset_y,
					mo.z+offset_z,
					MT_SPARK
				)
				spark.scale = mo.scale
			end
			//Get Charged FX
			if player.melee_charge >= FRACUNIT and not(player.gotflagdebuff)
				player.melee_charge = FRACUNIT
				B.hammerchargevfx(mo)
			end
		end
	end
	//Visual
	mo.state = S_PLAY_MELEE
	mo.frame = 0
	player.charability2 = CA2_NONE //Make Amy vulnerable during holding frames
	return true
end

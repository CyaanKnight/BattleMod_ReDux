local B = CBW_Battle
local S = B.SkinVars
local CV = CBW_Battle.Console
local speedlimit = 48

B.GetLaunchFactor = function(value)
	return value*B.Console.LaunchFactor.value/10
end


//Handle "battle" collision interactions
B.DoPlayerInteract = function(smo,tmo)
	//Preround
	if B.PreRoundWait() or B.TagPreTimer > 0 return end
	
	if tmo == nil then return end
	//We'll be repeating a lot of functions in this script, so let's make use of some arrays
	local s = 1
	local t = 2
	local mo = {}
	mo[s] = smo
	mo[t] = tmo
 	B.DebugPrint("smo.type "..smo.type,2)

	//Make sure this is a valid collision
	local function validcheck(n1,n2)
		if not(mo[n1] and mo[n1].valid and mo[n1].health)
		or mo[n1].pushed == nil
		or mo[n1].pushed_last == mo[n2]
			return false
		else
			return true
		end
	end
	
	if not(validcheck(s,t))
	or not(validcheck(t,s))
		B.DebugPrint("Attempted DoPlayerInteract event with an invalid object.",DF_COLLISION)
		return false
	end
 	B.DebugPrint("DoPlayerInteract event between object types "..smo.type.." and "..tmo.type,DF_COLLISION)
	
	//Update pushed history
	mo[s].pushed_last = mo[t]
	mo[t].pushed_last = mo[s]
	
	//Store player for ease of access
	local plr = {}
	plr[s] = mo[s].player
	plr[t] = mo[t].player
	
	//Airdodge check
	if (plr[s] and plr[s].intangible) or (plr[t] and plr[t].intangible)
		return false
	end
	
	//Prevpain for vfx reasons
	local prevpain = {}
	for n = 1,2
		if plr[n] then
			prevpain[n] = (plr[n].powers[pw_nocontrol] > 0
				or plr[n].panim == PA_PAIN
				or mo[n].health < 1)
		else
			prevpain[n] = false
		end
	end
	
	//This will tell us if both parties are player objects
	local pvp = (plr[s]) and (plr[t])
	
	//Update the attack and defense properties of each character
	local function updateplr(n1,n2)
		if not(plr[n1]) then return end
		if pvp then
			plr[n1].pushed_creditplr = plr[n2]
		end
		B.DoPriority(plr[n1])
		B.DoSPriority(plr[n1],mo[n2])
	end
	
	updateplr(s,t)
	updateplr(t,s)
	
	//Get current attack and defensive priorities
	local atk = {}
	local def = {}
	for n = 1,2
		if plr[n] then
			atk[n] = plr[n].battle_atk
			def[n] = plr[n].battle_def
		else
			if mo[n].battle_atk then
				atk[n] = mo[n].battle_atk			
			else
				atk[n] = 0
			end
			if mo[n].battle_def then
				def[n] = mo[n].battle_def
			else
				def[n] = 0
			end
		end
	end
	
	//Get type of collision (friendly, competitive, hostile?)
	local collisiontype = B.GetInteractionType(mo[s],mo[t])
	
	
	local bubble = {} //Player is using bubble shield bounce
	local homing = {} //Player is using a homing attack
	local spd = {} //Current horizontal speed
	local zspd = {} //Current vertical speed
	local ground = {}
	for n = 1,2
		bubble = (plr[n] and plr[n].pflags&PF_SHIELDABILITY and plr[n].powers[pw_shield] == SH_BUBBLEWRAP)
		if bubble then plr[n].pflags = $&~(PF_SHIELDABILITY|PF_THOKKED) end
		homing[n] = plr[n] and plr[n].pflags&PF_THOKKED
			and ((plr[n].powers[pw_shield] == SH_ATTRACTION and plr[n].pflags&PF_SHIELDABILITY) or plr[n].charability == CA_HOMINGTHOK)
		spd[n] = FixedHypot(mo[n].momx,mo[n].momy)
		zspd[n] = abs(mo[n].momz)
		ground[n] = P_IsObjectOnGround(mo[n])
		//Negate current momentum according to launch factor
		--P_InstaThrust(mo[n],R_PointToAngle2(0,0,mo[n].momx,mo[n].momy),B.GetLaunchFactor(spd[n]))
		--mo[n].momz = B.GetLaunchFactor($)
	end
	
	
	//Get object weight
	local weight = {}
	for n = 1,2
		local w = nil
		//if not(homing[n])
			if mo[n].weight == nil then
				mo[n].weight = FRACUNIT
			end
			w = mo[n].weight
		//else
		//	w = FRACUNIT/10
		//end
		weight[n] = max(1,FixedMul(w,mo[n].scale))
	end
	
	//Now for the knitty-gritty collision physics
	local angle = {}
	local thrust = {}
	local thrust2 = {}
	local momz = {}
	local collideangle = {}
	local zcollideangle = {}
	local function calc(n1,n2)
		//Get absolute angle, for... some reason?
		angle[n1] = R_PointToAngle2(mo[n2].x-mo[n2].momx,mo[n2].y-mo[n2].momy,mo[n1].x-mo[n1].momx,mo[n1].y-mo[n1].momy)
		//Thrust to inherit from other party
		thrust[n1] = 
			FixedMul(
				spd[n2]/2, //Objects with same weight will send each other half their respective speed amounts
				FixedDiv(weight[n2],weight[n1]) //Thrust amount is proportional to weight differential
			)
		//Counter-thrust from our own transferred momentum
		thrust2[n1] =
			FixedMul(
				spd[n1],
				max(0,min(FRACUNIT,weight[n2]*2-weight[n1]))//Factor weight into the counter-thrust amount, but stay within 0-100%.
			)
		//Apply launch factor from server settings
		thrust[n1] = B.GetLaunchFactor($)
		thrust2[n1] = B.GetLaunchFactor($)
		momz[n1] = mo[n1].momz
		//Get collision angle
		collideangle[n1] = B.GetCollideRelativeAngle(mo[n1],mo[n2])		
		zcollideangle[n1] = B.GetZCollideAngle(mo[n1],mo[n2])
	end

	calc(s,t)
	calc(t,s)
	//Debug stuff
	B.DebugPrint("COLLISION PROPERTIES",DF_COLLISION)
	for n = 1,2
		B.DebugPrint("* object "..n.." *",DF_COLLISION)
		B.DebugPrint("weight "..weight[n]*100/FRACUNIT.."%",DF_COLLISION)		
		B.DebugPrint("angle "..angle[n]/ANG1,DF_COLLISION)
		B.DebugPrint("spd "..spd[n]/FRACUNIT,DF_COLLISION)
		B.DebugPrint("zspd "..zspd[n]/FRACUNIT,DF_COLLISION)
		B.DebugPrint("thrust "..thrust[n]/FRACUNIT,DF_COLLISION)
		B.DebugPrint("thrust2 "..thrust2[n]/FRACUNIT,DF_COLLISION)
		B.DebugPrint("momz "..momz[n]/FRACUNIT,DF_COLLISION)
		B.DebugPrint("collideangle "..collideangle[n]/ANG1,DF_COLLISION)
		B.DebugPrint("zcollideangle "..zcollideangle[n]/ANG1,DF_COLLISION)
		B.DebugPrint("attack "..atk[n],DF_COLLISION)
		B.DebugPrint("defense "..def[n],DF_COLLISION)
	end
	B.DebugPrint("--------------------",DF_COLLISION)
	local hurt = 0
	local deflect
	--[[
	for n = 1,2 do
		if plr[n] and plr[n].gotcrystal and B.HomingDeflect(plr[3 - n], mo[n]) then
			deflect = true
			break
		end
	end]]
	//Collision info
	if pvp and G_TagGametype() and leveltime > CV.FindVar("hidetime").value*TICRATE then //! Get hidetime
		local function tagginghand(n1,n2)
			if plr[n2].pflags&PF_TAGIT and not(plr[n1].pflags&PF_TAGIT) and B.PlayerCanBeDamaged(plr[n1]) then
				B.DebugPrint("Spawning tagging hand missile",DF_COLLISION)
				local m = P_SpawnMissile(mo[n2],mo[n1],MT_TAGGINGHAND)
				if m and m.valid then
					m.fuse = 2
				end
			end
		end
		
		tagginghand(s,t)
		tagginghand(t,s)
		
	elseif collisiontype > 1 and not deflect then //Standard Battle rules
		//Do collision damage
		hurt = B.DoPlayerCollisionDamage(mo[s],mo[t])
		// 0: nobody was hurt
		// 1: t was hurt by s
		//-1: s was hurt by t
		// 2: both hurt
	end
	local pain = {}
	for n = 1,2
		if plr[n] then
			pain[n] = (plr[n].powers[pw_nocontrol] > 0
				or plr[n].panim == PA_PAIN
				or mo[n].health < 1)
		else
			pain[n] = false
		end
	end
	
	//Custom character collision functions
	local team_interaction = (mo[s].cantouchteam or mo[t].cantouchteam) and B.MyTeam(plr[s], plr[t])

	//PRECOLLIDE
	local defaultfunc = S[-1].func_precollide
	if plr[s]
		local func = S[plr[s].skinvars].func_precollide
		if not func
			func = defaultfunc
		end
		if func and not (team_interaction and mo[t].cantouchteam)
			func(s,t,plr,mo,atk,def,weight,hurt,pain,ground,angle,thrust,thrust2,collisiontype)
		end
	end
	if plr[t]
		local func = S[plr[t].skinvars].func_precollide
		if not func
			func = defaultfunc
		end
		if func and not (team_interaction and mo[s].cantouchteam)
			func(t,s,plr,mo,atk,def,weight,hurt,pain,ground,angle,thrust,thrust2,collisiontype)
		end
	end
	
	
	//COLLIDE
	local op1 = false
	local op2 = false
	local defaultfunc = S[-1].func_collide
	
	if plr[s]
		local func = S[plr[s].skinvars].func_collide
		if not func
			func = defaultfunc
		end
		if func and not (team_interaction and mo[t].cantouchteam)
			op1 = func(s,t,plr,mo,atk,def,weight,hurt,pain,ground,angle,thrust,thrust2,collisiontype)
		end
	end
	if plr[t]
		local func = S[plr[t].skinvars].func_collide
		if not func
			func = defaultfunc
		end
		if func and not (team_interaction and mo[s].cantouchteam)
			op2 = func(t,s,plr,mo,atk,def,weight,hurt,pain,ground,angle,thrust,thrust2,collisiontype)
		end
	end
	local override_physics = (op1 or op2) or team_interaction
	
	if not override_physics
		local function applythrust(n1,n2)
			if plr[n1] and plr[n1].climbing return end
				local smomxy = FixedHypot(mo[n1].momx,mo[n1].momy)
				local tmomxy = FixedHypot(mo[n2].momx,mo[n2].momy)
				if smomxy < 0 then
					smomxy = ($*-1)
				end
				if tmomxy < 0 then
					tmomxy = ($*-1)
				end
				local smomxyz = FixedHypot(mo[n1].momz,smomxy)
				local tmomxyz = FixedHypot(mo[n2].momz,tmomxy)
			--Apply XY-Thrust
			if mo[n1].health then
				if not(homing[n1])
					if plr[n1] and P_PlayerInPain(plr[n1])
						mo[n1].momx = 0
						mo[n1].momy = 0
					end
					if smomxyz > tmomxyz
						P_Thrust(mo[n1],angle[n1],thrust[n1]/2)
					else
						P_Thrust(mo[n1],angle[n1],thrust[n1])
					end
					if not pain[n1] 
						P_Thrust(mo[n1],angle[n2]+ANGLE_180,min(speedlimit*mo[n1].scale,thrust2[n1]))
					end

				else
					thrust[n1] = $/2
					P_InstaThrust(mo[n1],angle[n1],thrust[n1])
				end
			end
			
			--Apply Z-Thrust
			if not(pain[n1]) then 
				if not(homing[n1]) then
					mo[n1].momz = -1*$+max(
						-speedlimit/2*mo[n1].scale,
						min(
							speedlimit/2*mo[n1].scale,
							FixedMul(
								B.GetLaunchFactor(momz[n2]),
								FixedDiv(
									weight[n2],
									weight[n1]
								)
							)
						)
					) --can i make this less messy???
				else
					mo[n1].momz = mo[n2].scale*12
				end
			end
		end
		applythrust(s,t)
		applythrust(t,s)
		
		//Do recoil state
		if collisiontype > 1 then
			local function dorecoil(n1,n2)
				if plr[n1] and not(plr[n1].climbing or pain[n1] or plr[n1].playerstate != PST_LIVE) and (atk[n2] >= def[n1])
					then
					B.DoPlayerFlinch(plr[n1],((thrust[n1] * 2)/(mo[n1].scale * 5)*4), angle[n1], thrust[n1])
				end
			end
			
			dorecoil(s,t)
			dorecoil(t,s)
		end
	end
	
	//POSTCOLLIDE
	local op1 = false
	local op2 = false
	local defaultfunc = S[-1].func_postcollide
	if plr[s]
		local func = S[plr[s].skinvars].func_postcollide
		if not func
			func = defaultfunc
		end
		if func and not (team_interaction and mo[t].cantouchteam)
			op1 = func(s,t,plr,mo,atk,def,weight,hurt,pain,ground,angle,thrust,thrust2,collisiontype)
		end
	end
	if plr[t]
		local func = S[plr[t].skinvars].func_postcollide
		if not func
			func = defaultfunc
		end
		if func and not (team_interaction and mo[s].cantouchteam)
			op2 = func(t,s,plr,mo,atk,def,weight,hurt,pain,ground,angle,thrust,thrust2,collisiontype)
		end
	end
	local override_fx = (op1 or op2)
	if override_fx or team_interaction
		return
	end
	
	//Do Sound, VFX
	local defend = max(def[s],def[t])
	local attack = max(atk[s],atk[t])
	local shake = false
	if (smo and smo.player and smo.player == displayplayer)
	or (tmo and tmo.player and tmo.player == displayplayer)
		shake = true
	end
	
	local hitfx = function(n1,n2)
		//n2 hurt by n1
		if mo[n2].type == MT_SPARRINGDUMMY
			S_StartSound(mo[n2],sfx_s3k6e)
		elseif mo[n2].battleobject
			S_StartSoundAtVolume(mo[n2],sfx_s3kaa, 120)
		end
		local sc = 2
		local impact = 0
		if not plr[n1] or atk[n1] == 1 //1atk hit
			S_StartSoundAtVolume(mo[n1],sfx_s3k49, 220)
			S_StartSound(mo[n2],sfx_s3k96)
			if shake
				P_StartQuake(9 * FRACUNIT, 2)
			end
		elseif atk[n1] == 2 //2atk
			sc = 4
			impact = 3
			S_StartSoundAtVolume(mo[n1],sfx_s3k49, 200)
			S_StartSound(mo[n2],sfx_s3k5f)
			if shake
				P_StartQuake(12 * FRACUNIT, impact)
			end
		elseif atk[n1] >= 3 //3atk or more
			sc = 6
			impact = 5
			S_StartSoundAtVolume(mo[n1],sfx_s3k49, 200)
			S_StartSound(mo[n2],sfx_s3k9b)
			B.ApplyHitstun(mo[n1], impact)
			if shake
				P_FlashPal(displayplayer, PAL_INVERT, impact)
				P_StartQuake(14 * FRACUNIT, impact)
			end
		end
		B.ApplyHitstun(mo[n2], impact*3)
		local vfx = P_SpawnMobjFromMobj(mo[n2], 0, 0, mo[n2].height/2, MT_SPINDUST)
		local hitcolors = {SKINCOLOR_SUPERSILVER1,SKINCOLOR_SUPERGOLD1,SKINCOLOR_SUPERRED1}
		if vfx.valid
			vfx.scale = mo[n2].scale * sc/5
			vfx.destscale = vfx.scale * 3
			vfx.colorized = true
			vfx.color = hitcolors[1+impact/2]
			vfx.state = S_BCEBOOM
		end
	end
	
	local hitbash1 = (atk[s] > 0 and mo[t].battleobject)
	local hitbash2 = (atk[t] > 0 and mo[s].battleobject)
	
	if (hitbash1 or hitbash2) or (hurt != 0 and ((pain[s] and not prevpain[s]) or (pain[t] and not prevpain[t]))) //Someone got hurt
		if ((hurt == 1 or hurt == 2) and not prevpain[t]) or hitbash1
			hitfx(s,t)
		end
		if ((hurt == -1 or hurt == 2) and not prevpain[s]) or hitbash2
			hitfx(t,s)
		end
	else//Nobody got hurt
		if attack == 1
			S_StartSound(mo[s],sfx_s3k49)
			if shake
				P_StartQuake(5 * FRACUNIT, 2)
			end
		elseif attack == 2
			S_StartSound(mo[s],sfx_s3k49)
			S_StartSoundAtVolume(mo[s],sfx_s3k61, 70)
			if shake
				P_StartQuake(7 * FRACUNIT, 3)
			end
		elseif attack >= 3
			S_StartSound(mo[s],sfx_s3k49)
			S_StartSoundAtVolume(mo[s],sfx_s3k61, 140)
			if shake
				P_StartQuake(9 * FRACUNIT, 4)
			end
		else
			S_StartSoundAtVolume(mo[s],sfx_s3k5d, 200)
			if shake
				P_StartQuake(3 * FRACUNIT, 1)
			end
		end
	end
	
	if smo.player then
		smo.player.homing = 0
		smo.player.skidtime = 0
		if P_IsObjectOnGround(smo) and smo.state == S_PLAY_GLIDE then
			smo.state = S_PLAY_GLIDE_LANDING
		end
	end 
	if tmo.player then
		tmo.player.homing = 0
		tmo.player.skidtime = 0
		if P_IsObjectOnGround(tmo) and tmo.state == S_PLAY_GLIDE then
			tmo.state = S_PLAY_GLIDE_LANDING
		end
	end
	//Player interactions completed
	return true
end
local B = CBW_Battle



local applyflip = function(mo1, mo2)
	if mo1.eflags & MFE_VERTICALFLIP then
		mo2.eflags = $|MFE_VERTICALFLIP
	else
		mo2.eflags = $ & ~MFE_VERTICALFLIP
	end
	
	if mo1.flags2 & MF2_OBJECTFLIP then
		mo2.flags2 = $|MF2_OBJECTFLIP
	else
		mo2.flags2 = $ & ~MF2_OBJECTFLIP
	end
end


local overlayZ = function(mo, overlaytype, flip)
	if flip then
		return mo.z+FixedMul(mobjinfo[overlaytype].height, mo.scale)+(mo.height)
	else
		return mo.z
	end
end

local auraMobj = MT_RINGSPARKAURA
local ringspark_sfx = sfx_rngspk
local sliceprep_sfx = sfx_dshclw
local skinname = "metalsonic" --For frame colorization

//Charge time thresholds
local threshold1 = 6
local threshold2 = threshold1+26
local state_charging = 1
local state_energyblast = 2
local state_ringsparkprep = 3 --Preparing Ring Spark
local state_ringspark = 4 --Ring Sparking
local state_dashslicerprep = 5
local state_dashslicer = 6
local state_dashslicerend = 7
local cooldown_dash = TICRATE * 5/2
local cooldown_blast = TICRATE * 5/4
local cooldown_slice = TICRATE * 2
local cooldown_cancel = TICRATE
local cooldown_ringspark = TICRATE * 2 --2 Second cooldown
local cooldown_multiblast = TICRATE * 4
local preptime_ringspark = 17 --Ring spark prep takes 17 tics
local forcetime_ringspark = TICRATE/2 --Ring spark is forced to be active for at least half a second
local speed_ringspark = FRACUNIT * 18 --Limited speed
local sideangle = ANG15/4 //Horizontal spread
local vertwidth = ANG15/2 //Vertical spread
local blastcount1 = 3
local blastcount2 = 5
local blastbuffer = 15 --Time between each auto-shot
local dashslice_buildup = TICRATE/3

local resetdashmode = function(p)
	p.dashmode = 0
	p.normalspeed = skins[p.skin].normalspeed
	p.jumpfactor = skins[p.skin].jumpfactor
end

local spawnslashes = function(player, mo)
	--Effects
	local x,y,z,dist,angoff
	dist = mo.radius
	angoff = P_RandomRange(90,270)*ANG1
	x = mo.x+P_ReturnThrustX(nil,mo.angle+angoff,dist)
	y = mo.y+P_ReturnThrustY(nil,mo.angle+angoff,dist)
	z = mo.z--overlayZ(mo, MT_DUST, (mo.flags2 & MF2_OBJECTFLIP))
	P_SpawnMobj(x,y,z,MT_DUST)
	
	--Slashes
	local dist = 46*mo.scale
	local x,y,z,s
	local angoff = -ANGLE_90
	z = mo.z--overlayZ(mo, MT_SLASH, (mo.flags2 & MF2_OBJECTFLIP))
	if player.actiontime&1 then
		x = mo.x+P_ReturnThrustX(nil,mo.angle+angoff,dist)
		y = mo.y+P_ReturnThrustY(nil,mo.angle+angoff,dist)
		s = S_SLASH3
	else
		x = mo.x+P_ReturnThrustX(nil,mo.angle-angoff,dist)
		y = mo.y+P_ReturnThrustY(nil,mo.angle-angoff,dist)
		s = S_SLASH1
		S_StartSound(mo,sfx_rail1)
	end
	local missile = P_SpawnXYZMissile(mo,mo,MT_SLASH,x,y,z)
	if missile and missile.valid then
		--applyflip(mo, missile)
		missile.state = s
		missile.scale = FixedMul($*2, mo.scale)
	end
end

B.Action.EnergyAttack_Priority = function(player)
	if player.actionstate == state_charging then
		B.SetPriority(player,1,1,nil,1,1,"energy charge aura")
	end
	if player.actionstate == state_dashslicer then
		B.SetPriority(player,3,3,nil,3,3,"dash slicer")
	end
	
	if player.actionstate == state_ringsparkprep then
		--Vulnerable, but can't just be bump cancelled
		if player.tumble or P_PlayerInPain(player) or player.powers[pw_carry] then
			player.actionstate = 0
		else
			player.actionsuper = true
		end
	end
	
	if player.actionstate == state_ringspark then
		--Bump blockable projectiles
		if player.tumble or P_PlayerInPain(player) or player.powers[pw_carry] then
			player.actionstate = 0
		else
			player.actionsuper = true
			B.SetPriority(player,2,3,nil,2,3,"ring spark field") --Hatin'
		end
	end
end


local doBlast = function(mo, player) --abstraction
	S_StartSound(mo,sfx_s3k54)
	local set = blastcount1
	local decay = 1
	local vset = 2
	local vwidth = vertwidth/2
	/*if player.actiontime >= threshold2 then
		set = blastcount2
		decay = 0
		vset = 4
		vwidth = vertwidth
	end*/ --None of that thank you
	local angle = mo.angle
	//Projectiles
	for i = 1,set
		if i > 1 and i&1 then angle = mo.angle-sideangle*(i>>1) end
		if i > 1 and not(i&1) then angle = mo.angle+sideangle*(i>>1) end
		local m = (vset)
		if i > 1 and decay then m = 0 end
		for n = 0, m
			local blast = P_SPMAngle(mo,MT_ENERGYBLAST,angle,0)
			if blast and blast.valid then
				if G_GametypeHasTeams() then
					blast.colorized = true
					blast.color = mo.color
				end
				blast.scale = (mo.scale/2)
				local speed = FixedMul(blast.info.speed,mo.scale)
				local xyangle = R_PointToAngle2(0,0,blast.momx,blast.momy)
				local zangle
				if m == 0 then zangle = 0
				else zangle = B.FixedLerp(-vwidth,vwidth,FRACUNIT*n/m)
				end
				B.InstaThrustZAim(blast,xyangle,zangle,speed,0)
			end
		end
	end
	P_InstaThrust(mo,mo.angle+ANGLE_180,6*mo.scale)
end

local blendtable = {AST_MODULATE, AST_COPY} --blendmodes to alternate

local boolToBin = function(bool) --abstraction part 2
	if bool then 
		return 1
	else
		return 0
	end
end

local resetVars = function(player)
	player.energyattack_chargebuffer = 0
	player.energyattack_counter = 0
	player.energyattack_charged = 0
	player.energyattack_chargemeter = 0
end


local chargestall = function(mo, player)
	mo.state = S_PLAY_SPRING
	player.pflags = $&~PF_JUMPED
	player.secondjump = 0
	mo.momz = 0
	player.actiontime = $-1
end

local chargefall = function(player)
	player.mo.frame = 0
	player.mo.state = S_PLAY_FALL
	player.mo.sprite = SPR_PLAY
	player.actiontime = 0
	player.actionstate = 0
end

local deadzone = 20

local sliceAngle = function(p, fm, sm, camang, start) --tysm SMS Alfredo
	local mo = p.mo
	if not p.mo then return end
	local angle = mo.angle
	
	-- influence our teleport angle with movement in simple
	-- but not backwards! that would be confusing with the rising back input
	if p.pflags & PF_ANALOGMODE
	and not (mo.flags2 & MF2_TWOD or twodlevel)
	and (start or fm or sm)
		angle = camang
		if (abs(fm) >= deadzone or abs(sm) >= deadzone) then
			angle = $ + R_PointToAngle2(0,0,
			abs(fm)*FRACUNIT, -sm*FRACUNIT)
		else
			angle = camang
		end
	end
	return angle
end

local drainSpark = function(player)
	P_GivePlayerRings(player, -1)
	S_StopSoundByID(player.mo, sfx_antiri)
	S_StartSound(player.mo, sfx_antiri, player)
	player.energyattack_ringsparktimer = $+1
end

local stallOrFall = function(mo, player, cooldown)
	if player.energyattack_chargebuffer > 1 then
		chargestall(mo, player)
	else
		chargefall(player)
		resetVars(player)
		if cooldown then
			B.ApplyCooldown(player,cooldown)
		end
	end
end
		

---Metal Energy Aura-
B.MetalAura = function(mo,target, override)
	if not(target and target.valid and target.player and target.player.actionstate == state_charging
		and target.player.playerstate == PST_LIVE) and not(override)
		P_RemoveMobj(mo)
	return end
	mo.scale = target.scale
	mo.colorized = true --colorize
	mo.color = target.color
	mo.blendmode = blendtable[boolToBin((leveltime % 2 == 0))+1] --Blink blendmode
	if P_MobjFlip(target) == 1
		mo.eflags = $&~MFE_VERTICALFLIP
		P_MoveOrigin(mo,target.x,target.y,target.z+target.height/4)
	else
		mo.eflags = $|MFE_VERTICALFLIP
		P_MoveOrigin(mo,target.x,target.y,target.z+target.height*3/4)
	end
	mo.flags2 = $ & ~(MF2_DONTDRAW)
end

B.SparkAura = function(mo,target, override)
	if not(target and target.valid and target.player and target.player.actionstate == state_ringspark
		and target.player.playerstate == PST_LIVE) and not(override)
		target.state = S_METALSONIC_RINGSPARK3
		P_RemoveMobj(mo)
	return end
	mo.scale = target.scale
	if G_GametypeHasTeams then
		mo.colorized = true --colorize
		mo.color = target.color
	end
	applyflip(target, mo)
	P_MoveOrigin(mo, target.x, target.y, overlayZ(target, mo.type, (target.flags2 & MF2_OBJECTFLIP)))
	--if target.player.actiontime > 999 then
	mo.flags2 = $ & ~(MF2_DONTDRAW)
	--end
end

B.Auras = {}

function B.AuraThinker()
	for i = 1, #B.Auras do
		local aura = B.Auras[i]
		if aura.valid then
			B.SparkAura(aura, aura.target)
		end
	end
end

---Metal Sonic "gather" spheres-
B.EnergyGather = function(mo,target,xyangle,zangle)
	if not(target and target.valid and target.player and target.player.actionstate == state_charging) then
		P_RemoveMobj(mo)
	return end
	local dist = mo.scale*4*16*mo.fuse
	local xydist = P_ReturnThrustX(nil,zangle,dist)
	local zdist = P_ReturnThrustY(nil,zangle,dist)
	local x = target.x+P_ReturnThrustX(nil,xyangle,xydist)
	local y = target.y+P_ReturnThrustY(nil,xyangle,xydist)
	local z = target.z+zdist+target.height/2
	P_SetOrigin(mo,x,y,z)
end

B.Action.EnergyAttack = function(mo,doaction,throwring,tossflag)
	local player = mo.player
	
	--print(cam_simplespeed)
	
	if P_PlayerInPain(player)
		player.actionstate = 0
	end
		
	//Action info
	if not player.actionstate then --Only display charge text if we're not doing anything
		player.actiontext = "Energy Charge"
	end
	
	if (mo.energyattack_sparkaura and mo.energyattack_sparkaura.valid) then
		applyflip(mo, mo.energyattack_sparkaura) --Flip if needed
		mo.energyattack_sparkaura.scale = mo.scale
		P_MoveOrigin(mo.energyattack_sparkaura, mo.x, mo.y, overlayZ(mo, mo.energyattack_sparkaura.type, (mo.flags2 & MF2_OBJECTFLIP)))
	end
	
	player.energyattack_chargemeter = max(0, ($ or 1))
	
	if (player.actionstate == state_energyblast) or (player.actionstate == state_charging) then
		player.energyattack_chargemeter = $-1
	end
	
	if player.actionstate ~= state_ringspark then--If we're not Ring Sparking 
		player.actionrings = 10 --Everything costs 5 rings
		player.energyattack_ringsparktimer = 0
	end

	--print(player.playerstate == PST_LIVE)

	if (player.actionstate ~= state_ringspark) then
		if (mo.energyattack_sparkaura and mo.energyattack_sparkaura.valid) then
			mo.state = S_METALSONIC_RINGSPARK3
		end
	end

	if player.actionstate ~= state_dashslicer then
		player.energyattack_sliceangle = nil
	end
	
	player.actiontime = $+1 --Timer
	player.energyattack_chargebuffer = max(0, ($ or 1))
	player.energyattack_chargebuffer = $-1
	--print(player.energyattack_chargebuffer)
	if player.energyattack_chargemeter < FRACUNIT and player.actionstate == state_charging then
		player.action2text = "Charge "..100-(100*player.energyattack_chargemeter/FRACUNIT).."%"
	end
	
	if not(B.CanDoAction(player) or player.actionstate >= state_dashslicer) then
		if B.GetSVSprite(player) then
			B.ResetPlayerProperties(player,false,false)
			resetVars(player)
			return 
		end
		return 
	end
	
	//Action triggers
	local attackready = (player.actiontime >= threshold1 and player.actionstate == state_charging)
	local charging = not(slashtrigger) and (player.actionstate ~= state_dashslicerprep) and player.energyattack_chargemeter and ((B.PlayerButtonPressed(player,player.battleconfig_special,true) or not(attackready)) and player.actionstate == state_charging)
	local sparktrigger = attackready and B.PlayerButtonPressed(player,BT_SPIN,false) 
	local blasttrigger = (player.actionstate ~= state_energyblast) and not(sparktrigger) and ((attackready and doaction == 0) or (player.energyattack_chargemeter <= 0 and doaction == 2))
	local chargehold = (attackready and B.PlayerButtonPressed(player,player.battleconfig_special,true))
	local slashtrigger = not(sparktrigger) and attackready and doaction == 2 and B.PlayerButtonPressed(player,BT_JUMP,false)
	local charged = (player.energyattack_chargemeter <= 0) 
	local canceltrigger =
		not(blasttrigger or sparktrigger or slashtrigger)
		and player.actionstate == state_charging
		and doaction == 2
		and B.PlayerButtonPressed(player,player.battleconfig_guard,false)
	local chargetrigger = (player.actionstate == 0 and doaction == 1)
	
	//Intercepted while charging
	if (player.actionstate == state_charging or player.actionstate == state_energyblast) and player.powers[pw_nocontrol] then
		player.actionstate = 0
		B.ApplyCooldown(player,cooldown_cancel)
		resetVars(player)
		return
	end

	if not(charging or chargetrigger or ((player.actionstate == state_energyblast) and player.actiontime < 100))  then
		S_StopSoundByID(mo, sfx_bechrg)
	end
	
	//Start charging blast
	if chargetrigger
		B.PayRings(player,player.actionrings)
		S_StartSound(mo, sfx_bechrg)
		player.actionstate = state_charging
		player.actiontime = 0
		player.energyattack_chargemeter = FRACUNIT
		if player.dashmode >= TICRATE*3 then
			player.actiontime = threshold1
		end
		resetdashmode(player)
		player.pflags = $&~(PF_SPINNING|PF_SHIELDABILITY)
		player.canguard = false
		S_StartSound(mo,sfx_s3k7a)
		local aura = P_SpawnMobj(mo.x,mo.y,mo.z,MT_ENERGYAURA)
		if aura and aura.valid then
			aura.flags2 = $|MF2_DONTDRAW
			aura.target = mo
			aura.spriteyoffset = -16*FRACUNIT
		end
	end
	
	//Charging Blast
	if charging then
		//Do aim sights
		player.actiontext = "Energy Blast  ".."\x82"..player.actionrings.."\x80" --Tell the player they can release for a blast
		B.DrawAimLine(player,mo.angle)
		if player.actiontime > threshold2
			--B.DrawAimLine(player,mo.angle+sideangle*(blastcount2>>1))
			--B.DrawAimLine(player,mo.angle-sideangle*(blastcount2>>1))
			player.actiontext = "(HOLD) Triple Blast  ".."\x83"..(player.actionrings/2).." Each".."\x80"
		end
		player.canguard = false
		player.pflags = $|PF_JUMPSTASIS
		player.energyattack_chargemeter = max(0,$-(FRACUNIT/TICRATE/2))
		
		--Gather spheres
		local gather = P_SpawnMobj(mo.x,mo.y,mo.z+mo.height/2,MT_ENERGYGATHER)
		if gather and gather.valid then
			gather.target = mo
			gather.fuse = 35
			gather.extravalue1 = P_RandomRange(0,359)*ANG1
			gather.extravalue2 = P_RandomRange(0,359)*ANG1
			gather.scale = mo.scale/4
		end

		//Speed Cap
		local speed = FixedHypot(mo.momx,mo.momy)
		if speed > mo.scale then
			local dir = R_PointToAngle2(0,0,mo.momx,mo.momy)
			P_InstaThrust(mo,dir,FixedMul(speed,mo.friction))
		end
		//Blast Powerup
		if chargehold then
			if not(player.actiontime&3)
				then
				S_StartSound(mo,sfx_s3k5c)
-- 				P_SpawnThokMobj(player)
			end
			if player.actiontime == threshold2 then
			S_StartSound(mo,sfx_s1c3)
				for l = 0,8
					P_SpawnParaloop(mo.x,mo.y,mo.z+mo.height/2,256*mo.scale,16,MT_NIGHTSPARKLE,mo.angle+45*l*ANG1,nil,1)
				end
			end
			/*
			if player.actiontime >= threshold2 then
				local thok = P_SpawnMobj(mo.x+P_RandomRange(-mo.radius/FRACUNIT,mo.radius/FRACUNIT)*FRACUNIT,mo.y+P_RandomRange(-mo.radius/FRACUNIT,mo.radius/FRACUNIT)*FRACUNIT,mo.z,MT_THOK)
				if thok and thok.valid then
					thok.scale = $/16
					P_SetObjectMomZ(thok,FRACUNIT*16*8)
					thok.momx = mo.momx
					thok.momy = mo.momy
					thok.color = SKINCOLOR_WHITE
				end
			end
			*/
		end
	end
	
	//Unable to charge
	if canceltrigger then
		B.ResetPlayerProperties(player,false,false)
		resetVars(player)
		player.actiontime = -1
		S_StartSound(mo,sfx_s3k7d)
		B.ApplyCooldown(player,cooldown_cancel)
	end
	
	//Release blast
	if (blasttrigger) then
		doBlast(mo, player) --blast
		player.energyattack_chargebuffer = blastbuffer --set buffer
		if charged then
			player.energyattack_charged = true --make it known
			B.PayRings(player,player.actionrings/2)
			--player.energyattack_chargemeter = FRACUNIT
		else
			stallOrFall(mo, player, cooldown_blast)
		end
		player.actiontime = 0
		player.actionstate = state_energyblast
	end
	
	//Update states
	if (player.actionstate == state_charging) then
		mo.state = S_PLAY_WALK
-- 		player.dashmode = TICRATE*3
		B.DrawSVSprite(player,1)
		player.drawangle = mo.angle
		player.pflags = ($|PF_JUMPED)&~PF_NOJUMPDAMAGE
		P_SetObjectMomZ(mo,FRACUNIT/2,false) //Rise slowly
	elseif (player.actiontime == -1) then
		player.actiontime = 0
	end
	
	//Charge release state
	if player.actionstate == state_energyblast then
		player.energyattack_counter = $ or 0 --make counter if non-existent
		if player.energyattack_charged then
			local val = (player.actionrings/2)
			player.actiontext = "Energy Blast  ".."\x82"..val.."\x80"
			player.action2text = "Blasts Left: "..2-player.energyattack_counter
			if (doaction == 2) then --if we're charged
				--print("charged and holding down")
				if player.energyattack_counter < 2 then --if we have not blasted 3 times
					B.DrawAimLine(player,mo.angle) --aim lines my beloved
					--print("counter less than two")
					chargestall(mo, player)
					if (player.energyattack_chargebuffer < 1) then --If the buffer has passed and we're still holding down the button
						--print("buffer zero")
						player.energyattack_counter = $+1 --Increase blast count
						doBlast(mo, player) --blast
						B.PayRings(player,player.actionrings/2) --Charge
						player.energyattack_chargebuffer = blastbuffer --set buffer
					else
						if player.energyattack_chargebuffer < blastbuffer/2 then --"My cat vomitting on the floor at 3am"
							mo.state = S_PLAY_WALK
							B.DrawSVSprite(player,1)
						end
					end
					player.actionstate = state_energyblast --Blast
				else
					if player.rings < player.actionrings/2 then
						stallOrFall(mo, player, cooldown_multiblast)
					else
						stallOrFall(mo, player, cooldown_blast)
					end
					--resetVars(player)
				end
			else
				stallOrFall(mo, player, cooldown_blast)
				--resetVars(player)
			end
		else
			stallOrFall(mo, player, cooldown_blast)
		end
	end
	
	--Ring Spark
	if sparktrigger and player.actiontime > 1 then
		if player.rings then
			player.actiontime = 0
			player.actionstate = state_ringsparkprep --We're rolling!
			S_StartSound(mo, ringspark_sfx)
		else
			S_StartSound(nil, sfx_s3k8c, player)
		end
	end
	
	if player.actionstate == state_ringsparkprep then
	
		player.airdodge = -1
		
		player.canguard = false
		
		if mo.state != S_METALSONIC_RINGSPARK1 then
			mo.state = S_METALSONIC_RINGSPARK1
		end
			
		player.exhaustmeter = FRACUNIT
		
		player.pflags = $&~(PF_STARTDASH|PF_SPINNING|PF_JUMPED) --his ass is NOT spindashing
		player.secondjump = 2 --No Floating allowed
		if (player.actiontime > preptime_ringspark) then--If it's been 17 tics
			player.actiontime = 0
			player.actionstate = state_ringspark --Ring Sparkin' time
		end
	end
	
	if player.actionstate == state_ringspark then
	
		if player.exhaustmeter > 1 then
		
			if player.actiontime <= forcetime_ringspark then
				player.airdodge = -1
				player.canguard = false
			end
	
			if mo.state != S_METALSONIC_RINGSPARK2 then
				mo.state = S_METALSONIC_RINGSPARK2
			end

			if not(mo.energyattack_sparkaura and mo.energyattack_sparkaura.valid) then
				mo.energyattack_sparkaura = P_SpawnMobj(mo.x,mo.y,overlayZ(mo, auraMobj, (mo.flags2 & MF2_OBJECTFLIP)), auraMobj) --Spawn One
				mo.energyattack_sparkaura.flags2 = $|MF2_DONTDRAW
				table.insert(B.Auras, mo.energyattack_sparkaura)
				mo.energyattack_sparkaura.target = mo
			end
			
			if player.rings and ((player.doaction == 2 or (player.pflags & PF_SPINDOWN)) or player.actiontime <= forcetime_ringspark) then --If we have rings, and are holding either the action button or spin
				--P_MoveOrigin(mo.energyattack_sparkaura, mo.x,mo.y,overlayZ(mo, mo.energyattack_sparkaura.type, (mo.flags2 & MF2_OBJECTFLIP)))
				if not mo.energyattack_sparkaura.sfx then
					S_StartSound(mo, sfx_s3k40)
					mo.energyattack_sparkaura.sfx = true
				end
				player.actiontext = "Ring Spark Field" --Show the player we're ring sparking
				
				--SearchForAndDestroyMonitors(player)
				
				player.actionrings = 0 --They can tell rings are being drained
				
				player.energyattack_ringsparktimer = $ or 0 --State the timer if non-existant
				
				if player.energyattack_ringsparktimer < 15 then --If we just started
					player.normalspeed = speed_ringspark --Slow
					if (leveltime % 12) == 0 then --Drain rings
						drainSpark(player)
					end
				else --if it's been a bit
					player.normalspeed = speed_ringspark+(speed_ringspark/2) --A bit faster
					if (leveltime % 8) == 0 then --Drain Faster
						drainSpark(player)
					end
				end
			
				if P_RandomRange(0, 2) == 2
					S_StartSound(mo, sfx_s3k5c) --Play static sound
				end
				
				
				if not P_IsObjectOnGround(mo) then
					player.normalspeed = 0
					player.drawangle = $ or player.energyattack_drawangle
				end
				player.dashmode = 0 --Normal
				player.jumpfactor = 0 --No Jumping
				player.pflags = $ & ~(PF_SPINNING|PF_STARTDASH) --No Spinning
				player.skidtime = 0 --No skidding
				player.powers[pw_strong] = $|STR_ANIM|STR_ATTACK --We can attack enemies
			else --If we let go, reset
				player.actionstate = 0
				player.actiontime = 0
				resetdashmode(player)
				B.ApplyCooldown(player,cooldown_ringspark)
				resetVars(player)
			end
		else
			player.actionstate = 0
			player.actiontime = 0
			resetdashmode(player)
			B.ApplyCooldown(player,cooldown_ringspark)
			resetVars(player)
		end
	end
	
	--All I have done is remapped dash slicer to jump, and make it drain 5 rings when used for a total of 10 rings
	if slashtrigger then
		--Next state
		player.exhaustmeter = FRACUNIT
		player.actionstate = state_dashslicerprep
		if player.actiontime >= threshold2
			player.energyattack_longerdash = true
		end
		player.actiontime = 0
		S_StartSound(mo, sliceprep_sfx)
		if player.pflags & PF_ANALOGMODE then
			mo.angle = player.thinkmoveangle
		end
		P_InstaThrust(mo, mo.angle, player.speed-(player.speed/3))
		player.energyattack_stasis = mo.z
	end
	
	if (player.actionstate == state_dashslicerprep) then
		if mo.state != S_PLAY_DASH then
			mo.state = S_PLAY_DASH
		end
		local pos = player.energyattack_stasis
		P_SetOrigin(mo, mo.x, mo.y, pos)
		if player.actiontime >= dashslice_buildup then
			S_StopSoundByID(mo, sliceprep_sfx)
			player.actionstate = state_dashslicer
			S_StartSound(mo,sfx_cdfm01)
			player.actiontime = 0
		end
	end

	--Slash-dashing
	if player.actionstate == state_dashslicer then
		player.powers[pw_nocontrol] = max($,2)
		--player.pflags = $|PF_FULLSTASIS
		mo.state = S_PLAY_DASH
		mo.frame = 0
		mo.sprite2 = SPR2_DASH
		mo.momz = 1
		--player.energyattack_sliceangle = $ or mo.angle
		--player.energyattack_sliceangle = $ - ease.linear(player.realsidemove*FRACUNIT/50, 0, ANG10)
		--player.drawangle = player.energyattack_sliceangle
		--player.realangleturn = (mo.angle/(UINT16_MAX+1))
		local move = sliceAngle(player, player.realforwardmove, player.realsidemove, player.realangleturn<<16)
		mo.energyattack_move = move
		player.drawangle = move
		local r = mo.radius/FRACUNIT/2
		local x = mo.x+P_RandomRange(-r,r)*FRACUNIT
		local y = mo.y+P_RandomRange(-r,r)*FRACUNIT
		local z = mo.z+P_RandomRange(0,mo.height/FRACUNIT)*FRACUNIT
		local spark = P_SpawnMobj(x,y,z,MT_SUPERSPARK)
		if spark and spark.valid
			spark.scale = mo.scale
		end
		P_SpawnGhostMobj(mo)
		--print(player.actiontime)
		local spd = FixedMul((min(10, 3+player.actiontime) * FRACUNIT)/B.WaterFactor(mo),mo.scale)
		if twodlevel or mo.flags2&MF2_TWOD then
			spd = $*3/4
		end
		mo.momx = $ * 5/6
		mo.momy = $ * 5/6
		P_Thrust(mo, move, spd)
		player.pflags = $|PF_SPINNING
		
		if player.actiontime >= 10
			spawnslashes(player,mo)
		end
		
		local duration = 17
		if player.energyattack_longerdash then
			duration = $ + 4
		end
		
		if not(player.actiontime >= duration) then return end
		--Next state
		B.ApplyCooldown(player,cooldown_slice)
		resetVars(player)
		if (player.realbuttons & BT_JUMP)
			mo.momx = $ * 2/3
			mo.momy = $ * 2/3
			mo.energyattack_move = $ or mo.angle
			P_Thrust(mo, mo.energyattack_move, 25*mo.scale/B.WaterFactor(mo))
			mo.energyattack_move = nil
			B.ZLaunch(mo,FRACUNIT*24,0)
			player.actionstate = state_dashslicerend
			player.actiontime = 0
			player.pflags = $|(PF_SPINNING|PF_JUMPED)
			mo.state = S_PLAY_ROLL
			S_StartSound(mo,sfx_s3ka0)
			S_StartSound(mo,sfx_cdfm14)
		else
			mo.momx = $ / 3
			mo.momy = $ / 3
			mo.state = S_PLAY_FALL
			player.pflags = $&~(PF_SPINNING|PF_JUMPED|PF_THOKKED)
			player.actionstate = 0
			player.secondjump = 0
			S_StartSound(mo,sfx_s3k82)
		end
	end
	
	--Dash slicer jump
	if player.actionstate == state_dashslicerend then
		player.lockaim = true
		player.lockmove = true
		if not(player.pflags&(PF_SPINNING|PF_JUMPED)) then
			mo.state = S_PLAY_WALK
		else
			mo.state = S_PLAY_ROLL
		end
		player.powers[pw_nocontrol] = max($,2)
		B.ControlThrust(mo,FRACUNIT*90/100)
		if not(player.actiontime >= 12) then return end
		--Back to neutral
		player.actionstate = 0
		mo.state = S_PLAY_SPRING
		local flags = PF_SPINNING|PF_JUMPED|PF_THOKKED --For simultaneous removal
		player.pflags = $&~(flags)
		player.secondjump = 0
	end
end
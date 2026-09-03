local B = CBW_Battle

local state_dodgeroll = 1
local state_fret = 2
local state_bombjump = 10
local dodgeroll_time = 10
local dodgeroll_endlag = 20
local rollspeed = 48
local dropspeed = 20
local cooldown = TICRATE*2

B.Action.DodgeRoll = function(mo,doaction)
	local player = mo.player	
	//Safeguard
-- 	if player.actionstate != state_dodgeroll and not(mo.flags&MF_SPECIAL)
-- 		mo.flags = $&~MF_NOCLIPTHING
-- 	end
	if not(B.CanDoAction(player))
		player.actionstate = 0
-- 		mo.flags = $&~MF_NOCLIPTHING
	end
	
	local water = B.WaterFactor(mo)
	local twod = 1
	if twodlevel or mo.flags2&MF2_TWOD
		twod = 2
	end
	
	player.actionrings = 10
	player.actiontext = "Dodge Roll"
	if player.pflags&PF_BOUNCING
		player.actiontext = "Spring Drop"
	end
	local bouncing = player.pflags&PF_BOUNCING
	player.actiontime = $+1
	
	//Triggers
	local dodgeroll_trigger = doaction == 1 and not(bouncing)
	local springdrop_trigger = doaction == 1 and bouncing
	
	//Perform dodge roll
	if dodgeroll_trigger
		B.PayRings(player)
		B.ApplyCooldown(player,cooldown)
		player.actionstate = state_dodgeroll
		if player.powers[pw_flashing] < dodgeroll_time
			player.powers[pw_flashing] = dodgeroll_time
		end
		//Get angle
-- 		local input =
-- 		mo.flags = $|MF_NOCLIPTHING
		player.actiontime = 0
		//Do effects
		S_StartSound(mo,sfx_zoom)
		for n = 0,3
			local dust = P_SpawnMobjFromMobj(mo,0,0,0,MT_SPINDUST)
			local angle = (180+P_RandomRange(-60,60))*ANG1+mo.angle
			local speed = mo.scale*P_RandomRange(5,10)
			P_InstaThrust(dust,angle,speed)
		end
	end
	//Perform spring drop
	if springdrop_trigger
		B.PayRings(player)
		B.ApplyCooldown(player,cooldown)
		mo.momx = $/2
		mo.momy = $/2
		P_SetObjectMomZ(mo,-dropspeed*FRACUNIT,false)
		//Effects
		S_StartSound(mo,sfx_zoom)
		P_SpawnParaloop(mo.x,mo.y,mo.z,mo.scale*128,16,MT_DUST,ANGLE_90,nil,true)
	end
	//Dodge roll state
	if player.actionstate == state_dodgeroll
		local angle = ((player.pflags & PF_ANALOGMODE) and player.thinkmoveangle) or mo.angle
		player.lockaim = true
		player.lockmove = true
		mo.state = S_PLAY_ROLL
		mo.frame = (player.actiontime/2)%4
		P_InstaThrust(mo,angle,rollspeed*mo.scale/twod/water)
		P_SetObjectMomZ(mo,0,false)
		//End dodge roll
		if player.actiontime > dodgeroll_time
			mo.momx = $/2
			mo.momy = $/2
-- 			mo.flags = $&~MF_NOCLIPTHING
			//Do fret
			player.actionstate = state_fret
			player.actiontime = 0
			if not(P_IsObjectOnGround(mo))
				player.pflags = ($|PF_THOKKED)&~(PF_JUMPED|PF_SPINNING)
			else
				S_StartSound(mo,sfx_skid)
			end
		end
	end
	//Fret state
	if player.actionstate == state_fret
		if player.actiontime < dodgeroll_endlag //Do animation
			player.lockaim = true
			player.lockmove = true
			mo.state = S_PLAY_FALL
			mo.sprite2 = SPR2_EDGE
			mo.frame = (player.actiontime&7)/2
			if P_IsObjectOnGround(mo) and player.speed > FRACUNIT*4 and player.actiontime%3 == 0
				P_SpawnMobjFromMobj(mo,0,0,0,MT_DUST)
			end
		else //Return to normal
			player.actionstate = 0
		end
	end
end
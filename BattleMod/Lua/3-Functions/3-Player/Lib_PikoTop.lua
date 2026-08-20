
local B = CBW_Battle

local CANCEL_THRESHOLD = 18 -- Time Amy is required to spin

local LAUNCH_THRESHOLD = TICRATE*2 -- Time Amy is required to spin before she launches with priority
local LCANCEL_THRESHOLD = TICRATE -- Time Amy is required to spin after launch

local TIRE_THRESHOLD = TICRATE*5 -- Time Amy can spin until she becomes vulnerable

local PIKOTOP_END = TIRE_THRESHOLD+(15)

local SOUNDBUFFER = 5

local instathrust = FRACUNIT*14
local thrust = FRACUNIT*3
local friction = FRACUNIT*10/10
local zfriction = FRACUNIT*9/10
local limit = FRACUNIT*36

local DoThrust = function(mo)
	P_Thrust(mo,mo.angle,thrust)
	B.ControlThrust(mo,friction,limit,zfriction,nil)
	if not P_IsObjectOnGround(mo)
		B.ZLaunch(mo, mo.scale/20, true)
	end
end

freeslot("SPR2_TWRZ")
freeslot("sfx_pktp","sfx_pktq")

states[freeslot("S_AMY_PIKOTWIRL_FAST")] = {
    sprite = SPR_PLAY, 
    frame = SPR2_TWRZ|FF_ANIMATE|A, 
    tics = -1,
    nextstate = S_PLAY_JUMP, 
    var1 = 7,
    var2 = 1
}

-- Requirement
local function param(player)
	return player and (player.playerstate ~= PST_DEAD) and not(player.powers[pw_carry]) and
		   player.mo and player.mo.valid and (player.mo.skin == "amy")
end

local function setstate(mo, state)
	if mo.state == state then return end
	mo.state = state
end

local function PikoTop(player)

	local p = player
	local mo = player.mo
	local skin = skins[player.mo.skin]

	local spin_press     = B.PlayerButtonPressed(p,BT_SPIN,false,true)
	local spin_held  	 = B.PlayerButtonPressed(p,BT_SPIN,true,true)
	local jump_held      = B.PlayerButtonPressed(p,BT_JUMP,true,false)
	local twirling   	 = (mo.pikotop_state~=nil)
	local cancel     	 = false
	local reset 		 = false
	local launch     	 = false
	local topspin    	 = false
	local started    	 = false
	local dizzy      	 = false
	local jumpoverride 	 = false
	local grounded   	 = P_IsObjectOnGround(mo)
	
	p.charability2 = 0
	
	if mo.pikotop_timer ~= nil then
		if mo.pikotop_timer >= LAUNCH_THRESHOLD then
			if mo.pikotop_timer == LAUNCH_THRESHOLD then
				launch = true
				topspin = true
			else
				launch = false
				topspin = true
			end
		end
		
		if launch or topspin then
			if mo.pikotop_timer >= LAUNCH_THRESHOLD+LCANCEL_THRESHOLD
				cancel = true
			end
		elseif mo.pikotop_timer >= CANCEL_THRESHOLD then
			cancel = true
		end
		
		if mo.pikotop_timer >= TIRE_THRESHOLD then
			topspin = false
			cancel = false
			if mo.pikotop_timer == TIRE_THRESHOLD then
				dizzy = true
			end
		end
		
		if dizzy and mo.pikotop_timer >= PIKOTOP_END then
			cancel = true
			dizzy = false
		end

		if not(grounded) then
			p.pflags = $|PF_THOKKED
		end
			
		
	else
		started = true
	end

	local thokked = (p.pflags & PF_THOKKED)
	
	if spin_press and started and (grounded or not(grounded or thokked)) then
	
		local state = S_AMY_PIKOTWIRL
		
		if topspin then
			state = S_AMY_PIKOTWIRL_FAST
		end
		
		setstate(mo, state)
		mo.pikotop_state = state

		mo.momz = P_MobjFlip(mo)

		B.ZLaunch(mo, mo.scale*5, false)

		twirling = (mo.pikotop_state~=nil)

	end

	if twirling then

		p.powers[pw_noautobrake] = max($, 2)

		if grounded then
			p.jumpstasistimer = 2
		end

		mo.pikotop_timer = ($==nil and 1) or $+1

		mo.pikotop_soundbuffer = ($==nil and 1) or $+1

		if mo.pikotop_soundbuffer == SOUNDBUFFER then
			if mo.pikotop_sound then
				mo.pikotop_sound = nil
			else
				mo.pikotop_sound = true
			end
			mo.pikotop_soundbuffer = nil
		end

		if (spin_held or not(cancel)) then
		
			setstate(mo, mo.pikotop_state)
		
			p.skidtime = 0
	
			-- Launch
			if launch then
				--P_SetObjectMomZ(mo, FixedMul(mo.scale, LAUNCH_HOP))
				--P_InstaThrust(mo, mo.angle, FixedMul(mo.scale, LAUNCH_THRUST))
				S_StartSound(mo, sfx_nbmper)
			end
			
			if topspin then

				DoThrust(mo)

				mo.pikotop_state = S_AMY_PIKOTWIRL_FAST
				
				if not(mo.pikotop_timer%3) then
					local ghost = B.SpawnGhostForMobj(player.mo)
					if ghost and ghost.valid then
						ghost.frame = 0
						ghost.sprite = SPR_THOK
						ghost.skin = mo.skin
						ghost.sprite2 = mo.sprite2
						ghost.sprite = SPR_PLAY
						ghost.frame = mo.frame
						ghost.colorized = true
						ghost.fuse = 10
						ghost.blendmode = AST_ADD
					end
				end
				
				if mo.pikotop_soundbuffer == nil then
					S_StartSoundAtVolume(mo, (mo.pikotop_sound and sfx_pktp) or sfx_pktq, 185)
					if mo.pikotop_sound then
						S_StartSound(mo,sfx_s3k42)
					end
				end

				if mo.pikotop_timer&7 == 4 then
					--S_StartSound(mo,sfx_s3k42)
				end

				/*if (mo.pikotop_timer&7 == 0) then
					S_StartSound(mo, sfx_pkt0)
				elseif (mo.pikotop_timer&7 == 2)
					S_StartSound(mo, sfx_pkt1)
				elseif (mo.pikotop_timer&7 == 2)
					S_StartSound(mo, sfx_pkt2)
				end*/
			else
				if mo.pikotop_timer&7 == 4 then
					S_StartSound(mo,sfx_s3k42)
				end
			end
			
			if dizzy then
				reset = true
				B.DoPlayerTumble(p, 28, p.mo.angle, 0, true, true)
			end
		end
	end
	
	
	if cancel then
		if twirling then
			if not(spin_held) or dizzy then
				reset = true
			end
		else
			reset = true
		end
	end

	if not(twirling) and (mo.pikotop_state) then
		reset = true
	end

	if reset then

		if twirling then
			mo.state = S_PLAY_SPRING
		end
		mo.pikotop_timer = nil
		mo.pikotop_state = nil
		mo.pikotop_soundbuffer = nil
		mo.pikotop_sound = nil
		
		if not(skin.flags & SF_NOSKID) then
			p.charflags = $ & ~SF_NOSKID
		end
	end
	
end

addHook("PlayerThink", PikoTop)
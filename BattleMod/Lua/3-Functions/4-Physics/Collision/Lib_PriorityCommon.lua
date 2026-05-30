local B = CBW_Battle

B.Priority_Core = function(player)
	local pflags = player.pflags
-- 	local shieldability = pflags&PF_SHIELDABILITY
	local spinjump = (pflags&PF_JUMPED and not(pflags&PF_NOJUMPDAMAGE))
	local spinning = pflags&PF_SPINNING
	local stomping = (player.mo and player.mo.valid
	and (skins[player.mo.skin].flags&SF_STOMPDAMAGE) and not P_PlayerInPain(player))
	
	local t = "attack"
	local atk = 0
	local def = 0
	
	//Spin attack and Stomp Damage
	if stomping and not spinning
		if (player.mo.momz * P_MobjFlip(player.mo) < 0)
			B.SetPriority(player,0,0,"stomp",1,1,"stomp attack")
		end
		return
	end
	if spinjump
		atk = 1
		def = 1
		t = "jumping spin attack"
	elseif spinning then
		atk = 1
		def = 1
		t = "spin attack"
	end
	
	B.SetPriority(player,atk,def,"can_damage",1,1,t)	
end

B.Priority_Ability = function(player)
	local grounded = P_IsObjectOnGround(player.mo)
	local pflags = player.pflags
	local abil1 = player.charability
	local abil2 = player.charability2
	local anim1 = (player.panim == PA_ABILITY)
	local anim2 = (player.panim == PA_ABILITY2)
	local thokked = pflags&PF_THOKKED
	local shieldability = pflags&PF_SHIELDABILITY
	local shield =  player.powers[pw_shield]&SH_NOSTACK
	
	local spinjump = (pflags&PF_JUMPED and not(pflags&PF_NOJUMPDAMAGE))
	local spinning = pflags&PF_SPINNING
	
	local super = (player.powers[pw_super])
	local invstar = (player.powers[pw_invulnerability])
	local homing = (player.homing)
	local bubble = (shield==SH_BUBBLEWRAP)
	local flame = (shield==SH_FLAMEAURA)
	local elemental = (shield==SH_ELEMENTAL)
	local attr = (shield==SH_ATTRACT)
	
	local sonicthokked = (abil1 == CA_THOK and thokked)
	local sonichopped = (player.mo.hummingtop_state == 2)
	local knuckles = (abil1 == CA_GLIDEANDCLIMB)
	local flying = (abil1 ==CA_FLY and player.panim == PA_ABILITY)
	local gliding = pflags&PF_GLIDING
	local twinspin = (abil1 == CA_TWINSPIN and anim1)
	local pikotwirl = (abil1 == CA_TWINSPIN and (player.mo.state == S_AMY_PIKOTWIRL))
	local melee = (abil2 ==CA2_MELEE and anim2)
	local tailbounce = pflags&PF_BOUNCING
	local dashing = player.dashmode > 3*TICRATE and not(player.pflags&PF_STARTDASH)
	local prepdash = player.dashmode > 3*TICRATE and player.pflags&PF_STARTDASH
	local guard = (player.guard == -1)
	local tumble = player.tumble
	
	if super
		B.SetPriority(player,99,99,nil,99,99,"super aura")
	elseif invstar
		B.SetPriority(player,99,99,nil,99,99,"invincibility aura")
		
	elseif homing
		if attr and shieldability
			B.SetPriority(player,1,1,nil,1,1,"attraction shot")
		else
			B.SetPriority(player,1,1,nil,1,1,"homing attack")
		end
		
	elseif shieldability
		if bubble
			B.SetPriority(player,1,1,"stomp",3,1,"bubble bounce")
		elseif flame
			B.SetPriority(player,1,1,nil,1,1,"flame dash")
		elseif elemental
			B.SetPriority(player,1,1,"stomp",2,1,"elemental drop")
		end
	else
		//Sonic
		if spinjump and sonicthokked then
			B.SetPriority(player,1,1,nil,1,1,"speed thok")
		end
		if sonichopped then
			B.SetPriority(player,1,0,"amy_twirl",1,1,"humming top")
		end
		//Tails
		if flying then
			B.SetPriority(player,0,0,"tails_fly",2,2,"tail spin")
		end
		//Knuckles
		if gliding then
			B.SetPriority(player,1,0,"knuckles_glide",2,1,"gliding fists")
		end
		if player.kgrab and player.kgrab.valid then
			B.SetPriority(player,0,0,nil,0,0,"knuckle buster")
		end
//		if knuckles and grounded and player.rings >= 10 then
//			B.SetPriority(player,0,0,"knuckles_glide",0,1,"tough guy stance")
//		end
		//Amy
		if twinspin then 
			B.SetPriority(player,1,1,"amy_twinspin",1,2,"aerial hammer strike")
		elseif pikotwirl then
			B.SetPriority(player,1,0,"amy_twirl",2,1,"piko twirl")
		end
		if melee then
			if player.melee_state == 1//st_hold
				B.SetPriority(player,0,0,nil,0,0,"hammer charge")
			else
				B.SetPriority(player,1,0,"amy_melee",1,2,"hammer strike")
			end
		end
		//Fang
		if tailbounce then
			player.powers[pw_strong] = STR_BOUNCE
			B.SetPriority(player,0,0,"fang_tailbounce",2,3,"tail bounce")
		end
		//Metal
		if dashing then
			B.SetPriority(player,3,1,nil,3,1,"dash attack")
		elseif prepdash then
			B.SetPriority(player,1,1,nil,1,1,"charged dash attack")
		end
		if tumble then 
			B.SetPriority(player,0,0,nil,0,0,nil)
		end
		if P_PlayerInPain(player) then 
			B.SetPriority(player,0,0,nil,0,0,nil)
		end
	end
end

B.Priority_FullCommon = function(player)
	B.Priority_Core(player)
	B.Priority_Ability(player)
end

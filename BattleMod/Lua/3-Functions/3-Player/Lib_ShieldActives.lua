local B = CBW_Battle
local FORCE_PARRY_ACTIVE_FRAMES = 11
local FORCE_PARRY_TOTAL_FRAMES = 42

B.teamSound = function(source, player, soundteam, soundenemy, vol, selfisenemy)
	for otherplayer in players.iterate do
		if player and otherplayer and B.MyTeam(player, otherplayer)
			and not (selfisenemy and source and source.player and source.player == player)
		then
			S_StartSoundAtVolume(source, soundteam, vol, otherplayer)
		else
			S_StartSoundAtVolume(source, soundenemy, vol, otherplayer)
		end
	end
end

B.ArmaCharge = function(player)
	if not player.valid or not player.mo or not player.mo.valid or not player.armachargeup then
		player.armachargeup = nil
		return
	end
	
	local mo = player.mo
	
	if (player.actionstate
		or player.playerstate ~= PST_LIVE
		or P_PlayerInPain(player)
		or (player.powers[pw_shield] & SH_NOSTACK) ~= SH_ARMAGEDDON)
		or player.tumble
	then
		
		player.armachargeup = nil
		player.pflags = $ & ~PF_FULLSTASIS
		return
	end
	
	mo.state = S_PLAY_ROLL
	player.pflags = $ | PF_THOKKED | PF_SHIELDABILITY | PF_FULLSTASIS | PF_JUMPED & ~PF_NOJUMPDAMAGE
	
	player.armachargeup = $ + 1
	--Speed Cap
	local speed = FixedHypot(mo.momx,mo.momy)
	if speed > mo.scale then
		local dir = R_PointToAngle2(0,0,mo.momx,mo.momy)
		P_InstaThrust(mo,dir,FixedMul(speed,mo.friction))
	end
	P_SetObjectMomZ(mo,0,false)
	
	if player.armachargeup == 14 then
		B.teamSound(mo, player, sfx_gbeep, sfx_s3kc4s, 200, true)
		B.teamSound(nil, player, sfx_gbeep, sfx_s3kc4s, 80, true)
	end
	
	if player.armachargeup >= 27 then
		B.SetPriority(player,3,1,nil,3,1,"armageddon explosion")
		player.armachargeup = nil
		player.pflags = $ & ~PF_FULLSTASIS
		player.pflags = $ & ~(PF_JUMPED|PF_THOKKED)
		
		mo.state = S_PLAY_FALL
		local shake = 14
		local shaketics = 5
		P_StartQuake(shake * FRACUNIT, shaketics)
		S_StartSoundAtVolume(nil, sfx_s3kb4, 170)
		P_BlackOw(player)
	end
end

local ElementalStomp = function(player)
	local mo = player.mo
	mo.state = S_PLAY_ROLL
	mo.momx = $ * 3/5
	mo.momy = $ * 3/5
	P_SetObjectMomZ(mo, -25*FRACUNIT)
	S_StartSound(mo,sfx_s3k43)
	player.pflags = ($|PF_THOKKED|PF_SHIELDABILITY) &~ PF_SPINNING
end
local ArmageddonExplosion = function(player)
	local mo = player.mo
	player.armachargeup = 1
	player.dashmode = 0
	player.pflags = $ | PF_SHIELDABILITY | PF_FULLSTASIS | PF_JUMPED & ~PF_NOJUMPDAMAGE
	mo.state = S_PLAY_ROLL

	B.teamSound(mo, player, sfx_gbeep, sfx_s3kc4s, 200, true)
	B.teamSound(nil, player, sfx_gbeep, sfx_s3kc4s, 100, true)
end
local WhirlwindJump = function(player)
	P_DoJumpShield(player)
	player.pflags = ($|PF_THOKKED|PF_SHIELDABILITY)
end
local FlameDash = function(player)
	local mo = player.mo
	mo.state = S_PLAY_ROLL
	P_Thrust(mo, mo.angle, 30*mo.scale)
	S_StartSound(mo,sfx_s3k43)
	player.pflags = ($|PF_THOKKED|PF_SHIELDABILITY) & ~PF_NOJUMPDAMAGE
end
local BubbleBounce = function(player)
	local mo = player.mo
	mo.momx = $/3
	mo.momy = $/3
	S_StartSound(mo,sfx_s3k44)
	mo.state = S_PLAY_ROLL
	player.pflags = ($|PF_THOKKED|PF_SHIELDABILITY) & ~PF_NOJUMPDAMAGE
	P_SetObjectMomZ(mo, -24*FRACUNIT)
end
local ThunderJump = function(player)
	local mo = player.mo
	mo.state = S_PLAY_ROLL
	P_DoJumpShield(player)
	S_StartSound(mo,sfx_s3k45)
	player.pflags = ($|PF_THOKKED|PF_SHIELDABILITY) & ~PF_NOJUMPDAMAGE
end
local ForceStop = function(player)
	local mo = player.mo
	P_InstaThrust(mo, 0, 0*FRACUNIT)
	
	player.weapondelay = 25
	P_SetObjectMomZ(mo, 0*FRACUNIT)
	S_StartSound(mo,sfx_ngskid)
	player.pflags = $|PF_THOKKED|PF_SHIELDABILITY
end
local AttractionShot = function(player)
	local mo = player.mo
	local lockonshield = P_LookForEnemies(player, false, false)
	mo.tracer = lockonshield
	mo.target = lockonshield
	if lockonshield and lockonshield.valid then
		player.pflags = ($|PF_THOKKED|PF_JUMPED|PF_SHIELDABILITY) & ~(PF_NOJUMPDAMAGE)
		mo.state = S_PLAY_ROLL
		mo.angle = R_PointToAngle2(mo.x, mo.y, lockonshield.x, lockonshield.y)
		S_StartSound(mo, sfx_s3k40)
		player.homing = 1*TICRATE/2
	else
		player.pflags = ($|PF_THOKKED|PF_SHIELDABILITY)
		S_StartSound(mo, sfx_s3ka6)
		player.homing = 2
	end
end

B.CanShieldActive = function(player)
	if not P_PlayerInPain(player)
		and not player.gotflagdebuff
		and not player.gotpowercard
		and not (player.tossdelay == 2*TICRATE - 1)
		and not player.isjettysyn
		and not player.revenge
		and not player.exiting
		and not player.actionstate
		and not player.powers[pw_nocontrol]
		and not (player.pflags&PF_SHIELDABILITY)
		and not (player.mo and player.mo.valid and player.mo.dropdash_prep)
	then
		return true
	end
	return false
end

B.ShieldActions = {
    [SH_ELEMENTAL] = ElementalStomp,
    [SH_ARMAGEDDON] = ArmageddonExplosion,
    [SH_WHIRLWIND] = WhirlwindJump,
    [SH_FORCE] = ForceStop,
    [SH_ATTRACT] = AttractionShot,
    [SH_FLAMEAURA] = FlameDash,
    [SH_BUBBLEWRAP] = BubbleBounce,
    [SH_THUNDERCOIN] = ThunderJump
}

B.DoShieldActive = function(player)
    local shieldType = player.powers[pw_shield] & SH_NOSTACK
    
    -- Special case for Force Shield since it uses different masking
    if (player.powers[pw_shield] & ~(SH_FORCEHP|SH_STACK)) == SH_FORCE then
        shieldType = SH_FORCE
    end
    
    local action = B.ShieldActions[shieldType]
    if action then
        action(player)
    end
end

local shieldbutton = BT_TOSSFLAG
local cooldown = 15
B.ShieldTossflagButton = function(player)
	if not(player and player.valid and player.mo and player.mo.valid) then
		return
	end
		
	player.shieldswap_cooldown = max(0, $ - 1)

	if B.ButtonCheck(player,shieldbutton) != 1 then
		return
	elseif not B.CanShieldActive(player) then
		S_StartSound(nil, sfx_s3k8c, player)
		return
	end

	local temp = player.powers[pw_shield]&SH_NOSTACK
	local power = player.shieldstock[1]
	
	if temp ~= SH_PITY and
		(
			(player.pflags&PF_JUMPED)
			and not player.powers[pw_carry]
			and not (player.pflags&PF_THOKKED and not (player.secondjump == UINT8_MAX and temp == SH_BUBBLEWRAP))
			and not player.noshieldactive
		)
	then
		B.DoShieldActive(player)
		player.shieldswap_cooldown = cooldown
	
	else --Shield swap
		if temp and temp == power then
			player.shieldstock = B.CycleTable($)
		end

		if not player.shieldswap_cooldown
			and temp
			and power
			and temp ~= power
		then
			player.shieldswap_cooldown = cooldown
			
			player.powers[pw_shield] = 0
			P_RemoveShield(player)
			
			B.UpdateShieldStock(player,-1)
			P_SwitchShield(player, power)
			
			player.shieldstock[#player.shieldstock+1] = temp
			
			S_StartSound(player.mo, sfx_shswap)
		else
			S_StartSound(nil, sfx_s3k8c, player)
		end
	end
end
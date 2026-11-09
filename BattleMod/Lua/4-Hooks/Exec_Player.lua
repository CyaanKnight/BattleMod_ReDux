--[[
/*Note: See Exec_System.lua for player functions in hooks:
	PreThinkFrame
	ThinkFrame
	PostThinkFrame
*/
--]]

local B = CBW_Battle
local A = B.Arena
local CV = B.Console
local F = B.CTF

local RH = B._RunHook
-- Unlike MobjDamage, this runs EXCLUSIVELY for when the player gets hurt. Return true to override behavior.
B._DefineHook("PlayerDamage", CBW_HookHandlers.True)
--Handle player spawning
addHook("PlayerSpawn",function(player) 
	--player.gotflag = GF_BLUEFLAG
	--Init vars
	B.InitPlayer(player) 
	B.InitPriority(player)
	--Do music
	if not(B.OvertimeMusic(player)) then
		B.PinchMusic(player)
	end
	--Conditional spawn settings
	B.SpawnWithShield(player)
	A.StartRings(player)
	B.RestoreColors(player)
	B.ResetPlayerProperties(player)
	B.PlayerBattleSpawnStart(player)
end)

// get the mass of springs so we can nerf powersprining while flag/diamond holding
local function GetMassOfSpring(mo, spring)
	if not mo.valid
	or not spring.valid
	or mo.z > spring.z + spring.height
	or spring.z > mo.z + mo.height
		return
	end
	
	if spring.flags&MF_SPRING then
		local dont_spring = false
		if mo.player and mo.player.valid then
			mo.powerspringnerf = (spring.info.mass/FRACUNIT)*spring.scale
			if mo.eflags&MFE_SPRUNG then
				dont_spring = true
			end
		end
		// assume we have an object that can interact with springs
		if not dont_spring and mo.target and mo.target.valid and mo.target.player 
		and mo.info.mass > 0 and (mo.flags & (MF_SOLID|MF_NOCLIPHEIGHT)) then
			mo.target.powerspringnerf = (spring.info.mass/FRACUNIT)*spring.scale
		end
	end
end
local last_n = 0
local function patchSprings()
    for n = last_n+1, #mobjinfo-1 do
        local mt = n-1
        local info = mobjinfo[mt]
        
        if info.flags & MF_SPRING == 0
            continue
        end

        addHook("MobjCollide", GetMassOfSpring, mt)
        addHook("MobjMoveCollide", GetMassOfSpring, mt)
    end
    
    last_n = #mobjinfo-1
end
addHook("AddonLoaded", patchSprings)
patchSprings()

--Handle player vs player collision
addHook("TouchSpecial", B.PlayerTouch,MT_PLAYER)

B.AbilityHandlers = {
    [CA_FLOAT] = B.HandleFloat,
    [CA_THOK] = B.UncappedThok,
    [CA_BOUNCE] = B.FastBounce
}

--Control ability usage
addHook("AbilitySpecial",function(player)
	local mo = player.mo
	if not mo and mo.valid then return true end
	if not(B.MidAirAbilityAllowed(player)) then return true end

	local handler = B.AbilityHandlers[player.charability]

	if (player.charability == CA_JUMPTHOK) and (B.GetSkinVarsFlags(player) & SKINVARS_HUMMINGTOP) then
		return B.HummingTop_AbilitySpecial(player)
	end

    if handler then
        return handler(player, mo)
    end
end)

B.EmergencyWhirlWindJump = function(player)
	if (player.powers[pw_shield]&SH_NOSTACK == SH_WHIRLWIND and B.ButtonCheck(player,BT_JUMP) == 1) then
		return (player.mo and player.mo.state == S_PLAY_LEDGE_GRAB)
	end
end

addHook("ShieldSpecial", function(player)
	if B.CanShieldActive(player) == false or B.EmergencyWhirlWindJump(player) then
		return true
	end

	local shieldType = player.powers[pw_shield] & SH_NOSTACK
	if (player.powers[pw_shield] & ~(SH_FORCEHP|SH_STACK)) == SH_FORCE then
        shieldType = SH_FORCE
    end

	if B.ShieldActions[shieldType] then
		if not (player.battleconfig_nospinshield or (B.GetSkinVarsFlags(player)&SKINVARS_NOSPINSHIELD)) then
			B.DoShieldActive(player)
		end
		return true
	end
end)

addHook("JumpSpecial",function(player)
	if (player.powers[pw_carry]) or player.battlespawning then return end
	if B.TwinSpinJump(player) then return true end
	if B.RingSparkCheck(player) then return true end
	if B.Fang_SlideJump(player) then return true end
end)

addHook("SpinSpecial",function(player)
	if B.Exiting then return true end
	B.ChargeHammer(player)
	if (player.powers[pw_carry]) then return end
	if B.TwinSpin(player) then return true end
	if B.RingSparkCheck(player) then return true end
end)

addHook("JumpSpinSpecial", function(player)
	if B.Exiting then return true end
	if player.powers[pw_super] and player.charability == CA_THOK and player.actionstate then
		return true
	end
end)

--aaaaaaaaaaa
addHook("PlayerThink", function(player)
	B.GlideSound(player)
	B.AutoSpectator(player)
	B.DiminishingMomentum(player)

	--Perform Actions
	B.MasterActionScript(player,B.ButtonCheck(player,player.battleconfig_special),0)
	
	-- Spring checks (Should this be dropped in `Exec_Springs.lua`?)
	if player.mo and player.mo.valid then
		player.suicide_watch = true // is this joke too dark?
		// powerspring nerf
		if player.springnerfdelay and player.mo.powerspringnerf then
			if P_MobjFlip(player.mo) > 0 and player.mo.momz > player.mo.powerspringnerf then
				player.mo.momz = $-(player.mo.powerspringnerf/6)
			elseif P_MobjFlip(player.mo) < 0 and player.mo.momz-player.mo.scale < player.mo.powerspringnerf then
				player.mo.momz = $+(player.mo.powerspringnerf/6)
			end
			player.mo.powerspringnerf = 0
			player.springnerfdelay = 0
		end
		
		if player.mo.eflags&MFE_SPRUNG and not (player.pflags&PF_BOUNCING) then
			if player.gotflagdebuff and player.mo.powerspringnerf and not player.springnerfdelay then
				if (player.mo.eflags & MFE_UNDERWATER) then
					player.mo.powerspringnerf = $*7/6
				end
				player.springnerfdelay = 1 // we need to delay it so it will effect custom chars
			end
			B.ResetPlayerProperties(player)
			if P_IsObjectOnGround(player.mo) and not (player.pflags&PF_SPINNING) then
				player.mo.state = S_PLAY_WALK
			end
		end
	end
	player.pflags = (player.lockjumpframe or player.melee_state) and ($ | PF_JUMPSTASIS) or ($ & ~PF_JUMPSTASIS)
end)

--Player against Player damage
addHook("ShouldDamage", function(target,inflictor,source,damage,other)
	if gamestate ~= GS_LEVEL then return end -- won't work outside a level
	if (target.player and target.player.intangible and (source or inflictor)) then
	return false end
	if not(inflictor and inflictor.valid and inflictor.player and inflictor ~= target) then
	return end
	if not(target.player and not(B.MyTeam(target.player,source.player))) then
	return end
	if not(B.PlayerCanBeDamaged(target.player) or inflictor.flags2&MF2_SUPERFIRE) then
	return end
	if B.TagGametype() and not B.TagDamageControl(target, inflictor, source)
		return false
	end
	return true
end,MT_PLAYER)

--Remove targetdummy false positives
addHook("ShouldDamage", function(target,inflictor)
	if inflictor and inflictor.valid and inflictor.type == MT_TARGETDUMMY then return false end
end,MT_PLAYER)

--Armaggeddon blast
addHook("ShouldDamage", function(target,inflictor,source,damage,other)
	B.DamageTargetDummy(target,inflictor,source,damage,other)
	return false
end,MT_TARGETDUMMY)

--Damage triggered
addHook("MobjDamage",function(target,inflictor,source, damage,damagetype)
	if not(target.player) then return end
	target.player.suicide_watch = false // we can confierm the death was not by suicide
	-- Don't take damage while in a zoom tube
	if target.player.powers[pw_carry] == CR_ZOOMTUBE then return true end
	-- Don't take damage during setup phase
	if target.player.nodamage and target.player.nodamage>0 then return true end
	-- Burst flag if damaged
	--if target and target.player and not(target.player.guardtics > 0 or (target.player.guard and target.player.guard == 1)) then
    --   	F.PlayerFlagBurst(target.player, 0)
    --end
	--Do guarding
	if B.GuardTrigger(target, inflictor, source, damage, damagetype) then return true end
	if RH("PlayerDamage", nil, target.player, inflictor, source, damage, damagetype) then return true end

	--Handle damage dealt/received by revenge jettysyns
	A.RevengeDamage(target,inflictor,source)
	--Establish enemy player as the last pusher (for hazard kills)
	B.PlayerCreditPusher(target.player,inflictor)
	B.PlayerCreditPusher(target.player,source)

	local damager = nil
	
	if inflictor and inflictor.valid
		if inflictor.hit_sound and target and target.valid
			if type(inflictor.hit_sound) == "function" then
				inflictor.hit_sound(target,inflictor,source,damage,damagetype)
			else
				S_StartSound(target, inflictor.hit_sound)
			end
		end
		
		if inflictor.spawnfire and source.player and source.player.playerstate == PST_LIVE and (source.player.powers[pw_shield] & SH_NOSTACK) == SH_ELEMENTAL
			S_StartSound(inflictor, sfx_s22e)
			S_StartSoundAtVolume(inflictor, sfx_s3k82, 180)
			local m = 20
			for n = 0, m
				local fire = P_SPMAngle(inflictor,MT_SPINFIRE,0,0)
				if fire and fire.valid
					fire.flags = $ & ~MF_NOGRAVITY
					B.InstaThrustZAim(fire,(360/m)*n*ANG1,ANGLE_45*P_MobjFlip(inflictor),inflictor.scale * 7)
					fire.fuse = 4 * TICRATE
					fire.target = source
				end
			end
		end
		if inflictor.player then
			damager = inflictor.player
		end
	elseif source and source.player then
		damager = source.player
	end
	
	local player = target.player
	if player and player.valid then
		if (player.powers[pw_shield] & SH_NOSTACK) == SH_ARMAGEDDON then --no more arma revenge boom
			player.powers[pw_shield] = SH_PITY
		end
		if player.wanted and damager and not (G_GametypeUsesLives() or B.CPGametype()) then --extra score for damaging wanted players
			P_AddPlayerScore(damager, 50)
			local sparkle = P_SpawnMobjFromMobj(target,0,0,0,MT_SPARK)
			sparkle.scale = $*2
			sparkle.colorized = true
			sparkle.color = SKINCOLOR_BONE
		end
	end
	
	//have runners damaged by taggers switch teams
	if B.TagGametype()
		B.TagTeamSwitch(target, inflictor, source)
	end
end,MT_PLAYER)

addHook("MobjDamage",function(target,inflictor,source, damage,damagetype)
	if not target and target.valid return else S_StopSound(target, sfx_s3k87) end
	if target.player return end
	
	if inflictor.hit_sound and target and target.valid
		if type(inflictor.hit_sound) == "function" then
			inflictor.hit_sound(target,inflictor,source,damage,damagetype)
		else
			S_StartSound(target, inflictor.hit_sound)
		end
	end
end)

--Player death
addHook("MobjDeath",function(target,inflictor,source,damagetype)
	local killer
	local player = target.player
	local suicideflagdrop = false

	-- Drop flag if player has one
	--if target and target.player then
	--	if not source and not inflictor and damagetype == 0 and player.suicide_watch then
	--		suicideflagdrop = true
	--	end
    --   	F.PlayerFlagBurst(target.player, 0, suicideflagdrop)
    --end
	
	--Standard kill
	if inflictor and inflictor.player
		killer = inflictor.player
	elseif source and source.player
		killer = source.player
	end
	
	--Player was pushed into a death hazard
	if player and (damagetype == DMG_DEATHPIT or damagetype == DMG_CRUSHED)
		and player.pushed_creditplr and player.pushed_creditplr.valid and not(B.MyTeam(player,player.pushed_creditplr))
		then
		killer = player.pushed_creditplr
		P_AddPlayerScore(player.pushed_creditplr,50)
		B.DebugPrint(player.pushed_creditplr.name.." received 50 points for sending "..player.name.." to their demise")
	end

	if player.spectator then return end // dont give the penalty to spectators

	--Player ran out of lives in Survival mode
	if player.lives == 1 and B.BattleGametype() and G_GametypeUsesLives()
		B.PrintGameFeed(player," ran out of lives!")
		A.GameOvers = $+1
		player._gameovered = true
		S_StartSound(nil, sfx_s3k66, player)
	end

	--Death time and StartRings penalties
	B.DeathtimePenalty(player)
	B.StartRingsPenalty(player, killer)

	--Award rings and lifeshards for kills
	if not (target.player and target.player.revenge)
		A.KillReward(killer, target)
	end
	
	if (target.player and target.player.squashstretch)
		target.spritexscale = FRACUNIT
		target.spriteyscale = FRACUNIT
	end
	--Have runners who died after second pre-round switch teams
	if B.TagGametype() and B.TagPreRound > 1 and target.player != nil
		B.TagTeamSwitch(target, inflictor, source)
		B.TagConverter(target.player)
	end
end, MT_PLAYER)

--Disallow revenge jettysyns and spawning players from collecting items
addHook("TouchSpecial",function(special,pmo)
	if not(pmo.player) then return end --player check
	if B.PreRoundWait() then return true end --in preround phase
	if pmo.player.battlespawning then return true end --player is spawning
	if special.player then return end --player collisions are excluded here
	if (pmo.player.revenge or pmo.player.isjettysyn) then return true end --player is jettysyn
end,MT_NULL)

-- Bounce off walls during tumble
addHook("MobjMoveBlocked", function(mo)
    if mo.player.tumble then
        if P_IsObjectOnGround(mo) then mo.z = $ + P_MobjFlip(mo) end
        P_BounceMove(mo)
    end
	if mo.player then
		mo.player.lastmoveblock = leveltime
	end

	return B.Sonic_HTopMoveBlocked(mo)

end, MT_PLAYER)

-- When touching the large bubbles, *breathe*
addHook("MobjDeath", function(bubble, inflictor, source)
	if source and source.valid and source.player and source.player.valid then
		local player = source.player
		if player.airdodge > 0 then
			player.airdodge = TICRATE
		end
		player.airdodge_spin = 0
		B.ResetPlayerProperties(player)
		-- TODO: Should we move the state change into B.ResetPlayerProperties?
		player.mo.state = S_PLAY_GASP
	end
end, MT_EXTRALARGEBUBBLE)

-- CTF: remove stuff on quit
--addHook("PlayerQuit", F.PlayerFlagBurst)

addHook("ViewpointSwitch", function(...)
    if gamestate ~= GS_LEVEL then return end
    if B.TagGametype() then
		return B.TagViewpoints(...)
	else
    	return B.SurvivalViewpoints(...)
	end
end)

addHook("MobjLineCollide", function(mo, line)
	return B.Sonic_HTopLineCollide(mo, line)
end, MT_PLAYER)

addHook("MobjRemoved", B.InstaShield_Removed, MT_SONIC_INSTASHIELD)

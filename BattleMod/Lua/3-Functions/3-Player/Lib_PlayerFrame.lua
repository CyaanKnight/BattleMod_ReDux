local B = CBW_Battle
local A = B.Arena
local CV = B.Console

B.PlayerPreThinkFrame = function(player)
	--Initiate support mobj
	B.SpawnTargetDummy(player)
	
	--History
	if player.versusvars == nil then
		player.buttonhistory = player.cmd.buttons
		B.InitPlayer(player)
		player.versusvars = true
	end
	
	--Spectator functions
	B.PreAutoSpectator(player)
	B.SpectatorControl(player)

	--Arena death functions
	A.ForceRespawn(player)
	A.GameOverControl(player)
	
	--Dead control unlock
	if player.playerstate ~= PST_LIVE then
		player.lockaim = false
		player.lockmove = false
	end
	
	--Spawning, end of round
	if player.playerstate == PST_LIVE then
		--Battle spawn animation
		local spawning = B.PlayerBattleSpawning(player) 
		--Pre Round Setup
		if not(spawning) and B.PreRoundWait() then
			B.PlayerSetupPhase(player)
		end
		--Post round invuln
		if B.Exiting then
			player.nodamage = TICRATE
		end
	end
	
	--Control inputs
	B.PreGunslinging(player)
	B.InputControl(player)
end

B.PlayerThinkFrame = function(player)
	local pmo = player.mo

	--// rev: Time for which the player has been in the game.
	--//  This resets when the player spectates/the map changes(see MapChange in Exec_system)
	if player.spectator then 
		player.ingametime = 0
	else
		player.ingametime = $+1
	end

	--// rev: Tick autobalancing timer, and perform autobalance if required
	if CV.Autobalance.value and player.autobalancing then
		--// if dead, do the team change instantenously
		if player.autobalancing > 3*TICRATE or player.playerstate == PST_DEAD then
			player.autobalancing = nil
			local team = player.ctfteam == 1 and " blue" or " red"
			COM_BufInsertText(server, "serverchangeteam "+#player+team)
			player.ctfteam = player.ctfteam == 1 and 2 or 1
			player.playerstate = PST_REBORN
		elseif player.autobalancing <= 3*TICRATE then
			player.autobalancing = $+1
		end
	elseif not CV.Autobalance.value or player.spectator then
		player.autobalancing = nil
	end

	if CV.RingLimit and B.BattleGametype() then
		player.rings = min($, CV.RingLimit.value)
	end

	--gotta put this before the sanity checks...
	if player.spentrings then
		player.spentrings = max(0,$-1)
	end
	
	--Sanity checks
	if player.versusvars == nil then return end

	--Stop Game Over fade out
	if player._gameovered then
		if (player.playerstate == PST_DEAD) then
			S_StopFadingMusic(player)
		end
		player._gameovered = nil
	end

	if not(pmo and pmo.valid) or player.playerstate ~= PST_LIVE then return end
	if maptol&(TOL_NIGHTS|TOL_XMAS) then return end
	
	if (pmo and pmo.valid) and ((not player.squashstretch) or player.playerstate ~= PST_LIVE) then
		pmo.spritexscale = FRACUNIT
		pmo.spriteyscale = FRACUNIT
		player.squashstretch = nil
	end

	-- Other timers
	if (player.nodamage and player.nodamage>0) then
		player.nodamage = $-1
	end
	if pmo.cantouchteam and pmo.cantouchteam>0 then
		pmo.cantouchteam = $-1
	end
	if pmo.temproll and pmo.temproll>0 then
		pmo.temproll = $-1
		if not(pmo.temproll) then
			pmo.state = S_PLAY_SPRING
		end
	end
	if player.homing or (player.shadow and player.shadow.battlehoming) then
		player.lasthoming = leveltime
	end

	local knuckle_busted_flag = (pmo and pmo.valid and pmo.kgrabbed and pmo.kgrabbed.valid)
	local knuckle_busted = (pmo and pmo.valid and pmo.tracer and pmo.tracer.valid and pmo.tracer.player and pmo.tracer.player.kgrab and pmo.tracer.player.kgrab.valid and pmo.tracer.player.kgrab == pmo)


	-- Aerial timers
	if P_IsObjectOnGround(pmo) then
		player.noshieldactive = 0
		if not(knuckle_busted) then
			player.canstunbreak = (player.canstunbreak and player.canstunbreak<-1) and $ or 0
		end
	else
		if not(knuckle_busted) then
			player.canstunbreak = ($ and $>0) and $-1 or 0
		end
		player.noshieldactive = ($ and $>0) and $-1 or 0
	end

	--Knuckle buster failsafe
	if pmo._knucklebuster_noclip and not(knuckle_busted_flag) then
		pmo.flags = $ & ~MF_NOCLIPTHING
		pmo.kgrabbed = nil
		pmo._knucklebuster_noclip = nil
	end

	--Shield Stock usage
	B.ShieldStock(player)
	B.ShieldMax(player) --Regulate shield capacity
	
	--Lock-aim
	if player.lockaim then
		player.lockaim = false
		player.drawangle = player.mo.angle
	end
	if player.lockmove then
		player.lockmove = false
	end

	if player.hidefollowmobj == nil then
		player.hidefollowmobj = 0
	end

	if player.hidefollowmobj > 0 then

		player.hidefollowmobj = $-1

		if player.followmobj and player.followmobj.valid then
			if player.hidefollowmobj == 0 then
				player.followmobj.flags2 = $ & ~MF2_DONTDRAW
			else
				player.followmobj.flags2 = $|MF2_DONTDRAW
			end
		end

	end
	
	--Skinvars
	B.GetSkinVars(player)
	
	--Tumble state
	B.Tumble(player)
	
	--Ability control
	B.GuardControl(player)--Check if guard is allowed
	B.CharAbilityControl(player)--Exhaust and ability behavior
	
	--Update timers/stats
	B.GotFlagStats(player)
	player.charmedtime = max(0,$-1)
	player.dodgecooldown = max(0,$-1)
	if player.actioncooldown > 0 then
		if player.lastcooldown == nil or player.lastcooldown < player.actioncooldown then
			player.lastcooldown = player.actioncooldown
		end
		player.actioncooldown = max(0,$-1)
		if player.actioncooldown == 0 then
			player.lastcooldown = nil
			S_StartSound(nil, sfx_cddone, player)
		end
	end

	if B.SkinVars[player.skinvars].special then
		if player.actionrings then
			player.lastactionrings = player.actionrings
		end
		if player.actiontext then
			player.lastactiontext = player.actiontext
		end
	else
		player.lastactionrings = nil
		player.lastactiontext = nil
	end
	B.DoBackdraft(player)

	if player.skidtime and player.powers[pw_nocontrol] and leveltime % 3 == 1 then
		S_StartSound(pmo, sfx_s3k7e)
	end
	

	--Special thinkers
	A.JettySynThinker(player)
	A.RingSpill(player)
	B.PlayerMovementControl(player)
	
	--Perform Actions
	B.MasterActionScript(player,B.ButtonCheck(player,player.battleconfig_special),1)
	
	--Air dodge, Stun Break, Guard
	local doguard = B.ButtonCheck(player,player.battleconfig_guard)
	B.StunBreak(player,doguard)
	B.AirDodge(player,doguard)
	B.Guard(player,doguard)
	
	--Abilities
	B.HammerControl(player)
	B.CustomGunslinger(player)
	B.ShieldTossflagButton(player)
	
	--PvP Collision
	B.DoPriority(player)
	B.DoPlayerInteract(pmo,pmo.pushed)
	B.UpdateRecoilState(pmo)
	B.UpdateCollisionHistory(pmo)

	--Pass Indicator for MacGuffins
	if B.RubyGametype() or B.DiamondGametype() then
		if player.gotcrystal and (player.cmd.buttons & BT_TOSSFLAG) and (player.mo and player.mo.valid) then 
			B.MacGuffinPass(player)
		end
	end
end

B.PlayerPostThinkFrame = function(player)
	player.buttonhistory = player.cmd.buttons
	
	B.PostHammerControl(player)
	
	-- Lock jump timer
	if player.lockjumpframe then
		player.lockjumpframe = $ - 1
	end

	-- Manage ringhudflash
	if (player.prevrings < player.rings) then
		player.ringhudflash = 3
	elseif (player.prevrings > player.rings) then
		player.ringhudflash = -3
	else
		if (player.ringhudflash > 0) then
			player.ringhudflash = max(0, $ - 1)
		elseif (player.ringhudflash < 0) then
			player.ringhudflash = min(0, $ + 1)
		end
	end
	player.prevrings = player.rings

	local mo = player.mo
	
	-- Hitstun effects
	if mo and mo.hitstun_tics then
		mo.hitstun_tics = max(0, $-1)
		mo.flags = $|MF_NOTHINK
		if mo.hitstun_tics then --and mo.hitstun_disrupt
			mo.spritexoffset = P_RandomRange(8, -8) * FRACUNIT
			mo.spriteyoffset = P_RandomRange(2, 2) * FRACUNIT
			if player.followmobj then
				player.followmobj.spritexoffset = mo.spritexoffset
				player.followmobj.spriteyoffset = mo.spriteyoffset
			end
		elseif not(mo.hitstun_tics) then
			mo.spritexoffset = 0
			mo.spriteyoffset = 0
			if player.followmobj then
				player.followmobj.spritexoffset = 0
				player.followmobj.spriteyoffset = 0
			end
			--mo.hitstun_disrupt = false
			mo.flags = $ &~ MF_NOTHINK
		end
		return true
	end

	-- Dust devils interactions
	if (player.powers[pw_carry] & CR_DUSTDEVIL)
	and (player.actionstate and not (player.actionsuper))
	and not player.isjettysyn
	then
		B.ResetPlayerProperties(player)
	end
end

B.ApplyHitstun = function(mo, tics)
	mo.hitstun_tics = $ and max($, tics) or tics
end
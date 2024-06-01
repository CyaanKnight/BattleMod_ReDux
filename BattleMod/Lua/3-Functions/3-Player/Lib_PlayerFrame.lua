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

	-- If not in pain but flashing, set it to 3*TICRATE - 1. 
	--[[ DETAILS:
		This is to fix the invincibility bug. The invincibility bug happens when marine deflects a cork
		too close to an opponent. When this happens, marine hits the opponent and the deflected
		projectile (e.g. a cork) simultaneously hits the opponent, causing them to have their
		[pw_flashing] set to 3*TICRATE, but the 2nd collision (assuming it was e.g. a cork) 
		"bumps" the player out of their pain state, causing them to go into e.g. a falling state.
		As a result, the player stays with their [pw_flashing] stuck on 3*TICRATE, causing them to be invulnerable.

		One solution to this would be to tell battle's bump code to prevent players from being 
		pushed out of their pain state, as this can lead to the invincibility bug.
	]]
	--[[
	if  player.powers[pw_flashing] == (3*TICRATE) and not (P_PlayerInPain(player) or player.playerstate) then
		player.powers[pw_flashing] =  (3*TICRATE)-1 -- let's allow vanilla srb2 to do the ticking down itself
	end
	]] --hey dude this is already fixed in B.flashingnerf lmao ~lu
	
	--Sanity checks
	if player.versusvars == nil then return end
	if not(pmo and pmo.valid) or player.playerstate ~= PST_LIVE then return end
	if maptol&(TOL_NIGHTS|TOL_XMAS) then return end
	
	if (pmo and pmo.valid) and ((not player.squashstretch) or player.playerstate ~= PST_LIVE) then
		pmo.spritexscale = FRACUNIT
		pmo.spriteyscale = FRACUNIT
		player.squashstretch = nil
	end

	-- Other
	if (pmo and P_IsObjectOnGround(pmo)) then
		player.noshieldactive = 0
	elseif (player.noshieldactive and player.noshieldactive>0) then
		player.noshieldactive = $-1
	end
	if (pmo and pmo.cantouchteam and pmo.cantouchteam>0) then
		pmo.cantouchteam = $-1
	end
	if (player.nodamage and player.nodamage>0) then
		player.nodamage = $-1
	end
	if (pmo and P_IsObjectOnGround(pmo)) then
		player.canstunbreak = (player.canstunbreak and player.canstunbreak<-1) and $ or 0
	elseif (player.canstunbreak and player.canstunbreak>0) then
		player.canstunbreak = $-1
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
	if player.spentrings then
		player.spentrings = max(0,$-1)
	end
	--player.actioncooldown = max(0,$-1)
	B.DoBackdraft(player)
	

	--Special thinkers
	A.JettySynThinker(player)
	A.RingSpill(player)
	B.PlayerMovementControl(player)
	
	--Perform Actions
	local doaction = B.ButtonCheck(player,player.battleconfig_special)
	B.MasterActionScript(player,doaction)
	
	--Air dodge, Stun Break, Guard
	local doguard = B.ButtonCheck(player,player.battleconfig_guard)
	B.StunBreak(player,doguard)
	B.AirDodge(player,doguard)
	B.Guard(player,doguard)
	
	--Abilities
	B.HammerControl(player)
	B.CustomGunslinger(player)
	B.ShieldTossFlagButton(player)
	
	--PvP Collision
	B.DoPriority(player)
	B.DoPlayerInteract(pmo,pmo.pushed)
	B.UpdateRecoilState(pmo)
	B.UpdateCollisionHistory(pmo)
end

B.PlayerPostThinkFrame = function(player)
	player.buttonhistory = player.cmd.buttons
	
	--Lock jump timer
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
	
	if mo and mo.hitstun_tics
		mo.hitstun_tics = max(0, $-1)
		mo.flags = $|MF_NOTHINK
		if mo.hitstun_tics --and mo.hitstun_disrupt
			mo.spritexoffset = P_RandomRange(8, -8) * FRACUNIT
			mo.spriteyoffset = P_RandomRange(2, 2) * FRACUNIT
			if player.followmobj then
				player.followmobj.spritexoffset = mo.spritexoffset
				player.followmobj.spriteyoffset = mo.spriteyoffset
			end
		elseif not(mo.hitstun_tics)
			mo.spritexoffset = 0
			mo.spriteyoffset = 0
			if player.followmobj then
				player.followmobj.spritexoffset = 0
				player.followmobj.spriteyoffset = 0
			end
			mo.hitstun_disrupt = false
			mo.flags = $ &~ MF_NOTHINK
		end
		return true
	end
end
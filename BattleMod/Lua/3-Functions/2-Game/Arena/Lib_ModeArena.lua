local B = CBW_Battle
local CV = B.Console
local A = B.Arena
local R = B.Ruby
A.Fighters = {}
A.RedFighters = {}
A.BlueFighters = {}
A.Survivors = {}
A.RedSurvivors = {}
A.BlueSurvivors = {}
A.Placements = {}
A.SpawnLives = 3
A.GameOvers = 0
R.CapAnimTime = TICRATE*3+(TICRATE/2) --Time the Ruby capture animation takes
R.RubyFade = 0 --Value for the ruby's fade transition
R.RubyWinTimeout = R.CapAnimTime

local lossmusic = "CHFAIL"
local winmusic = "CHPASS"

A.GameOverControl = function(player)
	if not(B.BattleGametype()) then return end
	if player.playerstate == PST_DEAD and player.lives == 0 then
		if B.Exiting == false
			--if player.deadtimer == gameovertics and not(B.Pinch or B.SuddenDeath)
			--	P_RestoreMusic(player)
			--end
		else
			player.deadtimer = 2
		end
	end
end

A.StartRings = function(player)
	if not(B.BattleGametype()) then return end
	player.xtralife = 9 //Prevent players from gaining extra lives in the format
	if B.SuddenDeath then return end
	if not(A.CheckRevenge(player)) then
		local penalty = player.ringpenalty or 0
		player.rings = CV.StartRings.value - penalty
	else
		player.rings = 0
	end
end

A.RingSpill = function(player)
	//Rings spill far in Arena gametypes
	if B.ArenaGametype() then player.losstime = 30*TICRATE end
end

A.RingLoss = function(mo)
	//Rings disappear quickly in Arena gametypes
	if B.ArenaGametype() then mo.fuse = min($,35) end
end

A.UpdateSpawnLives = function()
	if not(B.BattleGametype()) then return end
	local cv_stock = CV.SurvivalStock.value
	if B.PreRoundWait() 
		A.SpawnLives = cv_stock
		for player in players.iterate
			player.lives = cv_stock
		end
	return end
	for player in players.iterate
		A.SpawnLives = min($,player.lives)
		if player.spectator then player.lives = cv_stock end
	end
end

A.ResetLives = function()
	for player in players.iterate
		player.revenge = false
		player.respawnpenalty = 0
		player.lifeshards = 0
		player.ringpenalty = 0
	end
	if not(gametyperules&GTR_LIVES) or not(B.BattleGametype()) then return end
	local L = CV.SurvivalStock.value
	for player in players.iterate
		player.lives = L
		player.revenge = false
		player.isjettysyn = false
	end
	A.SpawnLives = L
	A.GameOvers = 0
end

A.ResetScore = function()
	if not(gametyperules&GTR_LIVES and B.ArenaGametype()) then return end
	for player in players.iterate()
		if not(player.spectator) and player.lives and not(player.revenge) then
			player.preservescore = A.GameOvers+player.lives
		elseif player.preservescore == nil
			player.preservescore = 0
		end
		player.score = 0
	end
	bluescore = 0
	redscore = 0
end

A.UpdateScore = function()
	//Score function for Survival
	if not(gametyperules&GTR_LIVES and B.ArenaGametype()) then return end
	for player in players.iterate
		//Player is contending
		if player.preservescore != nil then
			player.score = player.preservescore
		end
	end
	
	//Team Survival
	if G_GametypeHasTeams() then
		redscore = 0
		bluescore = 0
		for player in players.iterate
			if player.ctfteam == 1 and not(player.revenge)
				redscore = $+player.lives
			end
			if player.ctfteam == 2 and not(player.revenge)
				bluescore = $+player.lives
			end
		end
	end
end

A.ForceRespawn = function(player)
	if B.ArenaGametype()// and G_GametypeUsesLives()
	and not(player.playerstate == PST_LIVE) and player.lives > 0 and not(player.revenge)
	and leveltime&1
		then
		if player.extradeadtimer then
			player.extradeadtimer = $-1
		else
			player.cmd.buttons = $|BT_JUMP
		end
	end
end

A.GetRanks = function(force)
	if B.CPGametype() and G_GametypeHasTeams() then
		return A.TeamGetRanks(force)
	end
	local criteria = B.CPGametype() and "captureamount" or "preservescore"
	local p = A.Fighters
	A.Placements = {}
	//Rank players
	for n = 1, #p
		local player = p[n]
		if not(player and player.valid) then continue end
		player.rank = 1
		//Compare with other player's scores
		for m = 1, #p
			local otherplayer = p[m]
			if not(p[m].valid) then continue end //sigh
			local p1score = player[criteria] or 0
			local p2score = otherplayer[criteria] or 0
			if G_GametypeUsesLives() then
				p1score = ($*10)+(player.lifeshards or 0)
				p2score = ($*10)+(otherplayer.lifeshards or 0)
			end
			if p1score < p2score then
				player.rank = $+1
			end
		end
		//Sort players on the "placement" list
		for n = player.rank,#p
			if A.Placements[n] == nil
				A.Placements[n] = player
				break
			end
		end
		if player.rank == 1 and (A.Bounty or force) and player[criteria]
			player.wanted = true
		else
			player.wanted = false
		end
	end
end

A.TeamGetRanks = function(force)
	local criteria = B.CPGametype() and "captureamount" or "preservescore"
	local b = A.BlueFighters
	local r = A.RedFighters
	//Rank players
	for n = 1, #b
		local bplayer = b[n]
		if not(bplayer and bplayer.valid) then continue end
		bplayer.brank = 1
		//Compare with other player's scores
		for m = 1, #b
			local botherplayer = b[m]
			if not(b[m].valid) then continue end //sigh
			if bplayer[criteria] < botherplayer[criteria] then
				bplayer.brank = $+1
			end
		end
		if bplayer.brank == 1 and (A.Bounty or force) and bplayer[criteria]
			bplayer.wanted = true
		else
			bplayer.wanted = false
		end
	end
	for n = 1, #r
		local rplayer = r[n]
		if not(rplayer and rplayer.valid) then continue end
		rplayer.rrank = 1
		//Compare with other player's scores
		for m = 1, #r
			local rotherplayer = r[m]
			if not(r[m].valid) then continue end //sigh
			if rplayer[criteria] < rotherplayer[criteria] then
				rplayer.rrank = $+1
			end
		end
		if rplayer.rrank == 1 and (A.Bounty or force) and rplayer[criteria]
			rplayer.wanted = true
		else
			rplayer.wanted = false
		end
	end
end


A.ForceWin = function()
	local doexit = false
	local extended = (not splitscreen) and not(G_GametypeHasTeams() and redscore == bluescore)
	local player_scores = {}
	for player in players.iterate do
		table.insert(player_scores, player.score)
		if (extended) then
			if player.powers[pw_sneakers] then player.powers[pw_sneakers] = $+1 end
			if player.powers[pw_invulnerability] then player.powers[pw_invulnerability] = $+1 end
			if player.powers[pw_super] and leveltime%TICRATE==1 then player.rings = $+1 end
		else
			if not(player.win or player.loss) then
				S_StopMusic(player)
			end
		end
		if player.exiting then continue end
		doexit = true
	end
	table.sort(player_scores, function(a, b)
		return (a > b)
	end)
	if doexit == true and not(B.Exiting) then
		B.DebugPrint("Game set conditions triggered.")
		A.GetRanks(true)
		S_StartSound(nil,sfx_lvpass)
		S_StartSound(nil,sfx_nxbump)
		B.Exiting = true
		B.Timeout = (extended) and 5*TICRATE or 1
		local winner
		local playercount = -1

		for player in players.iterate do
			playercount = $+1
		end

		for player in players.iterate do
			if player.win or player.loss then
				continue
			end
			S_StopMusic(player)
			COM_BufInsertText(player,"cecho  ") //Override ctf messages
			if not(extended) then continue end
			if (player.spectator)
			or (player.ctfteam == 1 and redscore > bluescore)
			or (player.ctfteam == 2 and bluescore > redscore)
			or (player.wanted)
			or (#player_scores and player_scores[#player_scores/2] and player.score >= player_scores[#player_scores/2] and not G_GametypeHasTeams())
			then
				S_ChangeMusic(winmusic, false, player)
				player.win = true
			else
				S_ChangeMusic(lossmusic, false, player)
				player.loss = true
			end

			if not(winner) and (playercount == 0) or (not(G_GametypeHasTeams()) and (player.wanted or (#player_scores and player_scores[#player_scores/2] and player.score >= player_scores[#player_scores/2]))) then
				winner = player
			end

		end
	end
end

local function stretchx(player)
	if not (player.mo and player.mo.valid) then return end
	local stretchx = ease.linear(player.mo.spriteyscale-(player.mo.spriteyscale/4), 0, FRACUNIT/4)
	player.mo.spriteyscale = $-stretchx
	if player.followmobj and player.followmobj.valid then
		player.followmobj.spriteyscale = $-stretchx
	end
	--mo.spriteyoffset = $+stretchx*mo.spriteyscale
end

local function resetstretch(mo)
	if not (mo and mo.valid) then return end
	mo.spriteyscale = FRACUNIT
	--mo.spriteyoffset = 0
	mo.spritexscale = FRACUNIT
end

local function stretchy(player)
	if not (player.mo and player.mo.valid) then return end
	local stretchy = ease.outquad(player.mo.spritexscale/2, 0, FRACUNIT/2)
	player.mo.spritexscale = $-stretchy
	player.mo.spriteyscale = $+stretchy
	if player.followmobj and player.followmobj.valid then
		player.followmobj.spritexscale = $-stretchy
		player.followmobj.spriteyscale = $+stretchy
	end
	--mo.spriteyoffset = $-(stretchy*mo.spritexscale)
end

local function rubyDelShield(player)
	P_RemoveShield(player)
	player.shieldstock = {}
	if player.mo and player.mo.valid then
		if not(player.mo.rubyrun_shielddespawn) then
			local nega = P_SpawnMobjFromMobj(player.mo,0,0,0,MT_NEGASHIELD)
			nega.target = player.mo
			player.mo.rubyrun_shielddespawn = true
		end
	end
end

local function rubyMovement(player, timeout)
	if not(player.mo and player.mo.valid) then
		return
	end

	rubyDelShield(player)

	if (timeout == nil) then return end
	local divisor = 10

	player.mo.momx = $-($/divisor)
	player.mo.momy = $-($/divisor)

	player.mo.flags = $|MF_NOCLIPHEIGHT|MF_NOCLIP

	if timeout == R.CapAnimTime then
		player.mo.momz = player.mo.scale
	end

	player.mo.momz = (P_MobjFlip(player.mo)==-1 and min($-(player.mo.scale/2), 0)) or max($+(player.mo.scale/2), 0)


	local invtime = ((timeout-R.CapAnimTime)/2)

	if player.ruby_capped then
		--if B.Timeout <= R.CapAnimTime-(R.CapAnimTime/3) then
			player.drawangle = $+(ANG1*invtime)
		--end

		player.mo.momx = $/2
		player.mo.momy = $/2

		player.pflags = $ & ~(PF_SPINNING)
		if player.mo.state != S_PLAY_FALL then
			player.mo.state = S_PLAY_FALL
		end
	end

	if (player.mo.state == S_PLAY_STND) or (player.mo.state == S_PLAY_WAIT) then
		player.mo.state = S_PLAY_FALL
	end

	player.squashstretch = 1
end

local function rubyAnim(timeout)
	local one_andathird = (TICRATE + (TICRATE/5))
	local one_andtwothirds = (TICRATE + (TICRATE/3))

	if (timeout == nil) then return end

	if timeout == one_andtwothirds then
		S_StartSound(nil, sfx_cdfm56)
	elseif timeout < one_andtwothirds and timeout > one_andathird then
		for player in players.iterate do
			stretchx(player)
		end
	elseif timeout == one_andathird then
		R.RubyFade = 0
		for player in players.iterate do
			resetstretch(player.mo)
			resetstretch(player.followmobj)
		end
	elseif timeout < one_andathird then
		if (R.RubyFade < 10) then
			R.RubyFade = $+1
		end
		for player in players.iterate do
			stretchy(player)
		end
	end
end

A.Exiting = function()
	if B.Exiting then
		B.Timeout = max(0,$-1)

		for player in players.iterate do
			player.pflags = $|PF_GODMODE
			if player.actiontext and player.textflash_flashing then
				player.actiontext = B.TextFlash($, true, player)
			end
		end

		if gametype == GT_RUBYRUN
			R.RubyWinTimeout = $-1
			for player in players.iterate do
				player.slipping = false
				player.actionstate = 0
				player.actiontime = 0
				rubyMovement(player, R.RubyWinTimeout)
			end
			rubyAnim(R.RubyWinTimeout)
		end

		if B.Timeout then
			for player in players.iterate do
				if not player.spectator then
					player.powers[pw_nocontrol] = max($, 2)
				end
				if player.powers[pw_underwater] then
					player.powers[pw_underwater] = max(30*TICRATE,$)
				end
				player.nodamage = TICRATE
			end
		else
			for player in players.iterate do
				if player.loss and player.mo and player.mo.valid 
				and player.mo.state != S_PLAY_LOSS and P_IsObjectOnGround(player.mo)
				then
					player.mo.state = S_PLAY_LOSS
				end
				if player.exiting then continue end
				P_DoPlayerExit(player)
			end
		end
	end
end

local tiebreaker_t = function()
	print("\x82".."Tiebreaker!")
end

A.UpdateGame = function()
	if not(B.BattleGametype()) then return end
	A.Exiting()
	local survival = G_GametypeUsesLives() and B.ArenaGametype()
	local playercount = 0
	A.Survivors = {}
	A.Fighters = {}
	A.RedSurvivors = {}
	A.BlueSurvivors = {}
	A.BlueFighters = {}
	A.RedFighters = {}
	for player in players.iterate() do
		playercount = $+1
		if not(player.spectator)
			A.Fighters[#A.Fighters+1] = player //Player is participating
			if player.ctfteam == 2 then
				A.BlueFighters[#A.BlueFighters+1] = player
			end
			if player.ctfteam == 1 then
				A.RedFighters[#A.RedFighters+1] = player
			end
			if(player.lives) and not(player.revenge) then A.Survivors[#A.Survivors+1] = player //Player is still alive
			else //Handle revenge
				if not(player.lives) and CV.Revenge.value then
					player.lives = 1
					player.revenge = true
					player.lifeshards = 0
				end
			continue end //Gate for team survivors
			if player.ctfteam == 1 then A.RedSurvivors[#A.RedSurvivors+1] = player
			elseif player.ctfteam == 2 then A.BlueSurvivors[#A.BlueSurvivors+1] = player
			end
		end
	end



	//Update score
	B.UpdateScore()
	A.UpdateScore()

	if gametype == GT_RUBYRUN then
		if R.player_respawntime and R.player_respawntime > 1 then
			R.player_respawntime = $-1
		end
		--this is so hacky, but there doesn't seem to be a global spawntimer so
		
		if (R.RubyFade and (R.RubyFade >= 1)) and (R.player_respawntime and (R.player_respawntime > 25) and (R.player_respawntime < 48)) then
			R.RubyFade = $-1
		end
	end
	
	//End of round conditions
	local timelimit = 60*TICRATE*CV.FindVar("timelimit").value
	local timeleft = timelimit-leveltime
	local pointlimit = CV.FindVar("pointlimit").value
	if timelimit and gametyperules&GTR_FIXGAMESET then
		timeleft = $-(60*TICRATE)
	end
	//Find out the highest score and how many people/teams are holding it
	local count = 0
	local highscore = 0
	if not(G_GametypeHasTeams()) //FFA scorecheck
		for player in players.iterate
			if player.score > highscore
				highscore = player.score
				count = 1
			elseif player.score == highscore
				count = $+1
			end
		end
	else //Team scorecheck
		highscore = max(redscore,bluescore)
		if redscore == bluescore
			count = 2
		else
			count = 1
		end
	end

	local cvar_overtime = CV.FindVar("overtime").value
	local cvar_timelimit = CV.FindVar("timelimit").value
	local overtime = ((cvar_overtime) and cvar_timelimit*60-leveltime/TICRATE <= 0)

	if B.Timeout and not(B.Exiting) then

		B.Timeout = $-1

		if gametype == GT_RUBYRUN and not(overtime) then
			for player in players.iterate do
				rubyMovement(player, B.Timeout)
			end
			rubyAnim(B.Timeout)
		end

		for player in players.iterate do
			player.exiting = max($, B.Timeout+2)
		end
		
		if (B.Timeout == 0) then
			for player in players.iterate do
				player.exiting = 0
				if player.spectator or player.playerstate != PST_LIVE
					continue
				end
--				P_SetOrigin(player.mo, player.starpostx * FRACUNIT, player.starposty * FRACUNIT, player.starpostz * FRACUNIT)
				player.playerstate = PST_REBORN
				player.mo.angle = player.starpostangle
-- 				player.mo.scale = player.starpostscale
-- 				B.InitPlayer(player)
				R.player_respawntime = 48
				B.PlayerBattleSpawnStart(player)
			end
			if gametype == GT_RUBYRUN and not(overtime) then
				S_StartSound(nil, sfx_ruby4)
			end
		end
	end


	//Score win conditions (non-survival)
	if not(survival)
	and (
		(pointlimit and highscore >= pointlimit) --//Score condition met
		or (count == 1 and timelimit and timeleft <= 0) --//Time condition met with one person/team in the lead
		)
	then
		A.ForceWin()
	return end --Exit function

	//Time out
	if timelimit and timeleft == 0 then
		B.DebugPrint("End of round check!",DF_GAMETYPE)
		//Get FFA victor conditions
		if not(G_GametypeHasTeams())
			//Game must have exactly one player with the highest score in order to force end the game
			if count == 1 and not(survival)
				A.ForceWin()
			else //Sudden death?
				if survival
					A.SpawnLives = 0
					for player in players.iterate
						if player.revenge
						or player.spectator
						or player.lives == 0
						then continue end
						
						local extralives = player.lives-1
						player.preservescore = $-extralives
						player.score = player.preservescore
						player.lives = 1
						if player.playerstate == PST_LIVE
							local nega = P_SpawnMobjFromMobj(player.mo,0,0,0,MT_NEGASHIELD)
							nega.target = player.mo
							player.shieldstock = {}
							player.rings = 0
        					player.powers[pw_shield] = SH_PITY --turn any shield into pity, it's gonna be removed anyway
							P_RemoveShield(player)
							if extralives
								if extralives < highscore-1 or extralives == 1
									table.insert(player.shieldstock, SH_PITY)
								else
									table.insert(player.shieldstock, SH_PITY|1)
								end
							end
						end
					end
				end
				tiebreaker_t()
			end
		end
		//Get team victor conditions
		if G_GametypeHasTeams()
			if bluescore != redscore and not(survival) then
				A.ForceWin()
			else
				if survival
					for player in players.iterate
						if player.spectator
						or player.revenge
						or player.lives == 0
						then continue end
						player.lives = 1
						P_RemoveShield(player)
						player.shieldstock = {}
						player.rings = 0
						local nega = P_SpawnMobjFromMobj(player.mo,0,0,0,MT_NEGASHIELD)
						nega.target = player.mo
					end
				end
				tiebreaker_t()
			end
		end
	end
	//Last man standing
	if survival and not(G_GametypeHasTeams()) and not(B.PreRoundWait())then
		if #A.Fighters < 2 then return end //Not enough players to determine winner/loser
		if survival and #A.Survivors < 2 then //Only one survivor left (or none)
			A.ForceWin()
		return end
	end
	//Last team standing
	if survival and G_GametypeHasTeams() and not(B.PreRoundWait())then
		if not(#A.BlueFighters and #A.RedFighters) then return end //Not enough players on each team
		if not(#A.RedSurvivors and #A.BlueSurvivors) then //Only one team standing (or none)
			A.ForceWin()
		return end
	end
	//Bounty system
	if B.ArenaGametype() or B.CPGametype() then
		if (A.Bounty and not(A.Bounty.valid)) then
			A.Bounty = nil
		end
		if #A.Survivors <= 2 then
			A.Bounty = nil
			return //Not enough players to begin bounty system
		end
		//Disallow bounty if disabled
		if not (CV.Bounty.value) then
			return
		end
		//Disallow bounty in survival until someone gets a lifeshard
		if survival and not(A.Bounty) then
			local survivalbounty = false
			for n = 1, #A.Survivors
				local p = A.Survivors[n]
				if p.lifeshards then
					survivalbounty = true
					break
				end
			end
			if not(survivalbounty) then
				return
			end
		end
		//Assign bounty to the player with highest lives or score (Deprecated, use p.wanted)
		for n = 1, #A.Survivors
			local p = A.Survivors[n]
			if not(A.Bounty) then
				A.Bounty = p
			end
			if survival then
				local shards = p.lifeshards or 0
				local shards2 = A.Bounty.lifeshards or 0
				local lifescore1 = (p.lives*10)+shards
				local lifescore2 = (A.Bounty.lives*10)+shards2
				if lifescore1 > lifescore2 then
					A.Bounty = p
				elseif lifescore1 == lifescore2 and not(p == A.Bounty) then
					A.Bounty = nil //Tie
				end
			else
				if p.score > A.Bounty.score then
					A.Bounty = p
				end
			end
		end
	end
end

A.KillReward = function(killer, target)
	if not (killer and killer.valid) then return end
	if B.SuddenDeath then return end
	local survival = G_GametypeUsesLives() and B.ArenaGametype()
	
	if killer.lifeshards == nil then
		killer.lifeshards = 0
	end
	
	S_StartSound(nil, sfx_s249, killer)
	
	if killer.mo and killer.mo.valid and killer.playerstate == PST_LIVE and not killer.revenge then
		local killedbounty = target.player.wanted and not B.CPGametype()
		local scorebonus = killedbounty and 150 or 100 --arena only
		local lifeshardbonus = killedbounty and 3 or 1 --survival only
		local ringbonus = killedbounty and 50 or 20 --all gametypes

		if not survival then
			P_AddPlayerScore(killer, scorebonus)
		else
			killer.lifeshards = $ + lifeshardbonus
			if killer.lives >= CV.SurvivalStock.value then
				killer.lifeshards = 0
			end
		end
		
		killer.rings = $ + ringbonus
		S_StartSound(killer.mo, sfx_itemup, killer)
		S_StartSound(killer.mo, sfx_s249, killer)
		
		if (killer.lifeshards == 0) or not survival then
			P_SpawnParaloop(killer.mo.x, killer.mo.y, killer.mo.z + (killer.mo.height / 2), 12 * FRACUNIT, 9, MT_NIGHTSPARKLE, ANGLE_90)
		elseif killer.lifeshards == 1 then
			S_StartSound(nil, sfx_s243, killer)
			P_SpawnParaloop(killer.mo.x, killer.mo.y, killer.mo.z + (killer.mo.height / 2), 12 * FRACUNIT, 9, MT_NIGHTSPARKLE, ANGLE_90)
		elseif killer.lifeshards == 2 then
			S_StartSound(nil, sfx_s243a, killer)
			P_SpawnParaloop(killer.mo.x, killer.mo.y, killer.mo.z + (killer.mo.height / 2), 12 * FRACUNIT, 12, MT_NIGHTSPARKLE, ANGLE_90)
		elseif killer.lifeshards >= 3 then
			P_SpawnParaloop(killer.mo.x, killer.mo.y, killer.mo.z + (killer.mo.height / 2), 12 * FRACUNIT, 15, MT_NIGHTSPARKLE, ANGLE_90)
		end
		
		if (killer.lifeshards >= 3) and survival then
			killer.lifeshards = $-3
			killer.lives = $ + 1
			--P_PlayLivesJingle(killer)
			S_StartSound(nil, sfx_svshar, killer)
			local icon = P_SpawnMobjFromMobj(killer.mo,0,0,0,MT_1UP_ICON)
			icon.scale = killer.mo.scale * 4/3
			print("\x89" .. killer.name .. " earned an extra life!")
		else
			if survival and killer.lifeshards then
				--TODO: P_SpawnMobjFromMobj(killer.mo,0,0,0,MT_LIFESHARD)
			end
			local icon = P_SpawnMobjFromMobj(killer.mo,0,0,0,MT_RING_ICON)
			icon.scale = killer.mo.scale
			icon.colorized = true
			icon.color = killedbounty and SKINCOLOR_ICY or SKINCOLOR_BONE
			S_StartSound(killer.mo, sfx_itemup, killer)
		end
	end
end

--[[
A.HitReward = function(hitter)
	if not (hitter and hitter.valid) return end
	if B.SuddenDeath then return end
	local arena = B.ArenaGametype() and not G_GametypeUsesLives()
	if not arena return end
	
	if hitter.mo and hitter.mo.valid and hitter.playerstate == PST_LIVE and not hitter.revenge and not G_GametypeHasTeams()
		hitter.score = $+(#A.Fighters*CV.Reward.value)
		S_StartSound(hitter.mo, 180, hitter)
		print("\x89" .. hitter.name .. " earned extra points!")
	end
	if hitter.mo and hitter.mo.valid and hitter.playerstate == PST_LIVE and not hitter.revenge and G_GametypeHasTeams()
		P_AddPlayerScore(hitter,((#A.Fighters*CV.Reward.value)))
		S_StartSound(hitter.mo, 180, hitter)
		print("\x89" .. hitter.name .. " earned extra points!")
	end
end
]]

B.SurvivalViewpoints = function(player, nextviewedplayer, forced)
    if B.ArenaGametype() then
		if leveltime and G_GametypeUsesLives() then
			return nextviewedplayer.lives
		else
			return nextviewedplayer.playerstate != PST_DEAD
		end
	end
end


local default_red = {
	flagsprite = SPR_KNUCKLESFLAG,
	skincolor = SKINCOLOR_RED,
	flagcolor = SKINCOLOR_RED,
	ringcolor = SKINCOLOR_RED,
	monitorcolor = SKINCOLOR_RED
}

local default_blue = {
	flagsprite = SPR_SONICFLAG,
	skincolor = SKINCOLOR_BLUE,
	flagcolor = SKINCOLOR_BLUE,
	ringcolor = SKINCOLOR_BLUE,
	monitorcolor = SKINCOLOR_BLUE
}

local vars_enum = {
	"flagsprite", 
	"skincolor",
	"flagcolor",
	"ringcolor",
	"monitorcolor",
	"flagname"
}

local check = "_icon"

B.GetTeamInfo = function(mapnum, clear)

	local header = mapheaderinfo[mapnum]

	for k, team_name in ipairs({"Red", "Blue"}) do

		local default = ((k==1) and default_red) or default_blue

		for i = 1, #vars_enum do
			local field_name = vars_enum[i]
			local hfield_name = team_name:lower().."team_"..field_name:lower()

			local header_val = header[hfield_name]

			if header_val and (pcall(do return _G[header_val:upper()] end) or field_name == "flagname") then --Constant?
				B[team_name.."Team_Info"][field_name:lower()] = ((field_name == "flagname") and header_val:upper()) or _G[header_val:upper()]
			else
				if (field_name == "flagcolor") or (field_name == "ringcolor") or (field_name == "monitorcolor") then
					B[team_name.."Team_Info"][field_name:lower()] = nil
				else
					B[team_name.."Team_Info"][field_name:lower()] = default[field_name:lower()]
				end
			end
		end
	end
end
				
local B = CBW_Battle
local F = B.CTF

B.ResetScore = function()
	if not(B.BattleGametype()) then return end
	if (gametyperules&GTR_LIVES and B.ArenaGametype()) then return end
-- 	if gametype == GT_EGGROBOTAG then
-- 		for player in players.iterate()
-- 			player.pflags = $&~PF_GAMETYPEOVER
-- 		end
	/*if G_TagGametype()
	return end*/
	for player in players.iterate()
		if not(player.spectator) then
			player.preservescore = player.score
		elseif player.preservescore == nil
			player.preservescore = 0
		end
		player.score = 0
	end
	B.RedScore = redscore
	B.BlueScore = bluescore
	bluescore = 0
	redscore = 0
end

B.UpdateScore = function()
	if not(B.BattleGametype()) then return end
	if (gametyperules&GTR_LIVES and B.ArenaGametype()) then return end
-- 	if gametype == GT_EGGROBOTAG then
-- 		for player in players.iterate()
-- 			if player.iseggrobo or player.eggrobo_transforming
-- 				player.pflags = $|PF_TAGIT|PF_GAMETYPEOVER
-- 			end
-- 		end
	/*if G_TagGametype()
	return end*/
	for player in players.iterate
		//Player is contending
		if player.preservescore != nil then
			player.score = player.preservescore
		end
	end
	
	//Team Games
	--[[
	/*
	if G_GametypeHasTeams() then
		if not F.IsCTFMode() then
			redscore = $+B.RedScore
			bluescore = $+B.BlueScore
		else
			redscore = F.RedScore
			bluescore = F.BlueScore
		end
	end
		*/
	--]]
	if G_GametypeHasTeams() then
		redscore = $+B.RedScore
		bluescore = $+B.BlueScore
	end
end
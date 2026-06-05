local B = CBW_Battle
local CV = B.Console

B.TagGametype = function()
	if gametype == GT_EGGROBOTAG or G_TagGametype() or 
			gametype == GT_BATTLETAG then return true
	else return false end
end

B.BattleGametype = function()
	if gametype and B.Gametypes.Battle[gametype] then return true
	else return false end
end

B.CPGametype = function()
	if gametype and B.Gametypes.CP[gametype] then return true
	else return false end
end

B.ArenaGametype = function()
	if gametype and B.Gametypes.Arena[gametype] then return true
	else return false end
end

B.DiamondGametype = function()
	if gametype and B.Gametypes.Diamond[gametype] then return true
	else return false end
end

B.RubyGametype = function()
	if gametype and B.Gametypes.Ruby[gametype] then return true
	else return false end
end

B.PowerCardsGametype = function()
	if gametype and B.Gametypes.PowerCards[gametype] then return true
	else return false end
end


B.ApplyGametypeCVars = function()
	if B.GametypeIDtoIdentifier[gametype] then
		local cvar_pointlimit = CV.FindVar(B.GametypeIDtoIdentifier[gametype].."_pointlimit")
		local cvar_timelimit = CV.FindVar(B.GametypeIDtoIdentifier[gametype].."_timelimit")
		local cvar_hidetime = CV.FindVar(B.GametypeIDtoIdentifier[gametype].."_hidetime")
		local cvar_startrings = CV.FindVar(B.GametypeIDtoIdentifier[gametype].."_startrings")

		if (cvar_ == 0) then
			COM_BufInsertText(server, "pointlimit None")
		else
			COM_BufInsertText(server, "pointlimit "..cvar_pointlimit.value)
		end
		

		if (cvar_ == 0) then
			COM_BufInsertText(server, "timelimit None")
		else
			COM_BufInsertText(server, "timelimit "..cvar_timelimit.value)
		end
		

		COM_BufInsertText(server, "hidetime "..cvar_hidetime.value)
		COM_BufInsertText(server, "battle_startrings "..cvar_startrings.value)
	end
end


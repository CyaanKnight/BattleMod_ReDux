local B = CBW_Battle
local A = B.Arena
local D = B.Diamond
local R = B.Ruby
local F = B.CTF
local CV = B.Console
local CP = B.ControlPoint
local I = B.Item
local PR = CBW_PowerCards

addHook("NetVars",B.NetVars.Sync)

addHook("MapChange",function(map)
	for player in players.iterate
		player.revenge = false
		player.preservescore = 0
        COM_BufInsertText(plr, "cechoflags 0") -- Reset cecho flags
        --// rev: reset these variables.
        player.ingametime = 0
        player.caps = 0
		player.battletagIT = false
		player.BTblindfade = 0
		player.btagpointers = nil
		player.BT_antiAFK = TICRATE * 60
		player.win = nil
		player.loss = nil
	end
	D.Reset()
	R.Reset()
	B.RedScore = 0
	B.BlueScore = 0
	B.SuddenDeath = false
	B.Pinch = false
	B.PinchTics = 0
	B.Exiting = false
	A.ResetLives()
	I.GameReset()
	B.ResetSparring()
	F.RedFlag = nil
	F.BlueFlag = nil
	B.GetTeamInfo(map, true)
	B.GetTeamInfo(map)
	skincolor_redteam = B.RedTeam_Info.skincolor
	skincolor_blueteam = B.BlueTeam_Info.skincolor
	skincolor_redring = B.RedTeam_Info.ringcolor or B.RedTeam_Info.skincolor
	skincolor_bluering = B.BlueTeam_Info.ringcolor or B.BlueTeam_Info.skincolor
	--F.RedScore = 0
    --F.BlueScore = 0
	--F.RedFlagPos = {x=0,y=0,z=0} -- Reset flag coords!
	--F.BlueFlagPos = {x=0,y=0,z=0} -- Reset flag coords!
	--F.DC_NoticeTimer = -1
	--F.DelayCap = false
	--F.ResetPlayerFlags() -- remove any gotflag field vars
	B.Timeout = 0
	F.GameState.CaptureHUDTimer = 0
	A.Bounty = nil
	//reset tag pre-round varaibles
	B.TagPreRound = 0
	B.TagPreTimer = 0
	B.TagPlayers = 0
	B.TagRunners = {}
	B.TagTaggers = {}
	R.RubyFade = 0
	R.player_respawntime = 0
	R.RubyWinTimeout = R.CapAnimTime

	PR.ResetAll() //Re-init on each mapchange
end)

addHook("MapLoad",function(map)
	F.GetFlagPos()
	B.ApplyGametypeCVars()
	I.GetMapHeader(map)
	I.GenerateSpawns()
	PR.MapLoadHook()
	PR.GetSpawnPoints()
end)

addHook("TeamSwitch", B.JoinCheck)

addHook("ViewpointSwitch", B.TagCam)

addHook("PreThinkFrame", function()
	B.SparringPartnerControl()
	D.GameControl()
	R.GameControl()
	I.GameControl()
	B.PinchControl()
	B.TagControl()
	--CR.PreThinkFrame()
	//Player control
	for player in players.iterate
		if player.deadtimer < 0 and player.deadtimer >= -TICRATE then player.deadtimer = 0 end
		B.PlayerPreThinkFrame(player)
	end
-- 	B.GetTailsCarry()
	PR.PreThinkFrame()
end)

addHook("ThinkFrame",function()	
	//Player control
	for player in players.iterate do
		B.PlayerThinkFrame(player)
		F.UpdateCaps(player)
		B.HummingTop_MainHook(player)
	end
	F.CustomCaptureSFX()
	B.TitleTicker()
	B.Autobalance()
	
	B.ResetScore()
	A.ResetScore()
	PR.TicFrame()
	--F.DelayCapActivateIndicator()
	--F.UpdateScore()
end)

addHook("PostThinkFrame",function()
	if not(B.PreRoundWait())
		for player in players.iterate
			B.PlayerPostThinkFrame(player)
		end
	end
	A.UpdateSpawnLives()
	A.GetRanks()
	B.PostPinchControl()
end)

addHook("PostThinkFrame", do
	A.UpdateGame()
end)

addHook("IntermissionThinker",B.Intermission)

B.AutoLoad = function(player)
	if not player.battleconfigloaded then
		player.battleconfigloaded = true
    	COM_BufInsertText(player, "battleconfig load silent")
	end
end
addHook("PlayerThink", B.AutoLoad) --i wish this was a "PlayerJoin" hook instead but idk how to use it so here it goes!!

B.Whatever = function(...)
	if consoleplayer and (consoleplayer.win or consoleplayer.loss) then
		return true
	end

	return B.TitleMusicChange(...)
end
addHook("MusicChange", B.Whatever)
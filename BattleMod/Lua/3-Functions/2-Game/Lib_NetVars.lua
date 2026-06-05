local B = CBW_Battle
local CP = B.ControlPoint
local A = B.Arena
local I = B.Item
local D = B.Diamond
local R = B.Ruby
local F = B.CTF

function B.NetVars.Sync(network)
	//Training Dummy / Tails Doll
	B.TrainingDummy 	= network($)
	B.TrainingDummyName = network($)
	B.HitCounter 		= network($)
	//Control Point
	CP.Num			= network($)
	CP.Mode	  	 	= network($)
	CP.LeadCapPlr 	= network($)
	CP.LeadCapAmt 	= network($)
	CP.Active	 	= network($)
	CP.Capturing  	= network($)
	CP.Blocked   	= network($)
	CP.Timer	  	= network($)
	CP.ID		 	= network($)
	CP.TeamCapAmt 	= network($)
	//Items
	I.SpawnTimer	= network($)
	I.Spawns 		= network($)
	I.GlobalChance	= network($)
	I.GlobalRate	= network($)
	I.LocalRate		= network($)
	//Arena
	A.SpawnLives 	= network($)
	A.Fighters 		= network($)
	A.RedFighters	= network($)
	A.BlueFighters	= network($)
	A.SpawnLives	= network($)
	A.Survivors 	= network($)
	A.RedSurvivors 	= network($)
	A.BlueSurvivors = network($)
	A.GameOvers		= network($)
	//Diamond
	D.Diamond 			= network($)
	D.Spawns 			= network($)
	D.Active			= network($)
	D.ActivePoint		= network($)
	D.PointUnlockTime	= network($)
	D.CurrentPointNum	= network($)
	D.LastPointNum		= network($)
	D.CapturePoints		= network($)
	D.DiamondIndicator	= network($)
	D.CheckPoint		= network($)
	D.RedTeamCaptureAmount	= network($)
	D.BlueTeamCaptureAmount	= network($)
	//Ruby run
	R.ID 				 = network($)
	R.RedGoal			 = network($)
	R.BlueGoal			 = network($)
	R.RubyFade 			 = network($)
	R.player_respawntime = network($)
	R.RubyWinTimeout 	 = network($)
	R.CheckPoint		 = network($)
	//CTF
	F.RedFlag 			= network($)
	F.BlueFlag			= network($)
	F.RedFlagPos  		= network($)
	F.BlueFlagPos  		= network($)
	F.RedFlagOpts  		= network($)
	F.BlueFlagOpts 		= network($)
	F.DelayCap  		= network($)
	F.DC_NoticeTimer 	= network($)
	F.DC_ColorSwitch 	= network($)
	F.RedFlag_player 	= network($)
	F.RedFlag_oldScore  = network($)
	F.BlueFlag_player   = network($)
	F.BlueFlag_oldScore = network($)
	
	//Game state
	B.RedTeam_Info 	= network($)
	B.BlueTeam_Info = network($)
	B.RedScore		= network($)
	B.BlueScore		= network($)
	B.Pinch 		= network($)
	B.PinchTics 	= network($)
	B.Overtime		= network($)
	B.SuddenDeath 	= network($)
	B.Exiting 		= network($)
	B.MatchPoint	= network($)
	//all the stuff for battle tag
	B.TagPreRound = network($)
	B.TagPreTimer = network($)
	B.TagPlayers = network($)
	B.TagRunners = network($)
	B.TagTaggers = network($)
end

assert(not CBW_Battle, "Loaded multiple instances of BattleMod")

rawset(_G,"CBW_Battle",{})
local B = CBW_Battle

-- Sub Tables
B.NetVars = {}
B.ControlPoint = {}
B.Gametypes = {}
B.GametypeHUD = {}
B.Console = {}
B.Action = {}
B.PriorityFunction = {}
B.TrainingDummy = nil
B.TrainingDummyName = nil
B.HitCounter = 0
B.Item = {}
B.SuddenDeath = false
B.Pinch = false
B.MatchPoint = false
B.Overtime = false
B.Exiting = false
B.PinchTics = 0
B.Arena = {}
B.Ruby = {}
B.Diamond = {}
B.CTF = {}
B.CTF.GameState = {}
B.GuardFunc = {}
B.SkinVars = {}
B.MessageText = {}
B.RedScore = 0
B.BlueScore = 0
B.HUDMain = true
B.HUDAlt = true
B.Timeout = 0
B.HUDRoulette = {}
B.RedTeam_Info = {}
B.BlueTeam_Info = {}

B.GametypeIDtoIdentifier = {}

B.AddBattleGametype = function(tabl)
	local defaulthidetime = 15
	local defaultstartrings = 50
	if tabl.defaulthidetime ~= nil then
		defaulthidetime = tabl.defaulthidetime
		tabl.defaulthidetime = nil
	end
	if tabl.defaultstartrings ~= nil then
		defaultstartrings = tabl.defaultstartrings
		tabl.defaultstartrings = nil
	end
	G_AddGametype(tabl)
	local id = _G["GT_"..tabl.identifier:upper()]

	B.GametypeIDtoIdentifier[id] = tabl.identifier:lower()

	local pointlimit
	local timelimit
	local hidetime
	local startrings
	local team = (tabl.rules & GTR_TEAMS)
	local scorer = (team and "a team") or "someone"

	pointlimit = CV_RegisterVar({
		name = tabl.identifier.."_pointlimit",
		defaultvalue = (tabl.defaultpointlimit) or 0,
		flags = CV_NETVAR|CV_CALL|CV_NOSHOWHELP,--|CV_NOINIT,
		PossibleValue = {MIN=0, MAX=999999999, ["None"]=0},
		func = function(cv)
			if gametype == id then
				if (cv.value == 0) then
					COM_BufInsertText(server, "pointlimit None")
				else
					COM_BufInsertText(server, "pointlimit "..cv.value)
				end
			end
			if cv.value == cv.defaultvalue then return end
			if cv.value > 0 then
				print(tabl.name.." rounds will end after "..scorer.." scores "..cv.value.." points.")
			else
				print(tabl.name.." rounds will no longer have a point limit.")
			end
		end
	})

	timelimit = CV_RegisterVar({
		name = tabl.identifier.."_timelimit",
		defaultvalue = tabl.defaulttimelimit or 0,
		flags = CV_NETVAR|CV_CALL|CV_NOSHOWHELP,--|CV_NOINIT,
		PossibleValue = {MIN=0, MAX=30, ["None"]=0},
		func = function(cv)
			if gametype == id then
				if (cv.value == 0) then
					COM_BufInsertText(server, "timelimit None")
				else
					COM_BufInsertText(server, "timelimit "..cv.value)
				end
			end
			if cv.value == cv.defaultvalue then return end
			if cv.value > 0 then
				print(tabl.name.." rounds will end after "..cv.value.." minutes.")
			else
				print(tabl.name.." rounds no longer have a time limit.")
			end
		end
	})

	hidetime = CV_RegisterVar({
		name = tabl.identifier.."_hidetime",
		defaultvalue = defaulthidetime,
		flags = CV_NETVAR|CV_CALL|CV_NOSHOWHELP,--|CV_NOINIT,
		PossibleValue = {MIN=0, MAX=9999},
		func = function(cv)
			if gametype == id then
				COM_BufInsertText(server, "hidetime "..cv.value)
			end
			if cv.value == cv.defaultvalue then return end
			if cv.value > 0 then
				print(tabl.name.." rounds will begin after "..cv.value.." seconds.")
			else
				print(tabl.name.." rounds will begin instantly.")
			end
		end
	})

	startrings = CV_RegisterVar({
		name = tabl.identifier.."_startrings",
		defaultvalue = defaultstartrings,
		flags = CV_NETVAR|CV_CALL|CV_NOSHOWHELP,--|CV_NOINIT,
		PossibleValue = {MIN=0, MAX=999},
		func = function(cv)
			if gametype == id then
				COM_BufInsertText(server, "battle_startrings "..cv.value)
			end
			if cv.value == cv.defaultvalue then return end
			print("Players will start with "..cv.value.." rings in "..tabl.name.." rounds.")
		end
	})

	-- this is for modding battlemod hud elements through your own gametype, whether itd be replacing it completely or whatever
	if tabl.hud ~= nil then
		B.GametypeHUD[id] = tabl.hud
	end

	return pointlimit, timelimit, hidetime, startrings
end
-- Debug flags
rawset(_G,"DF_GAMETYPE",	1<<0)
rawset(_G,"DF_COLLISION",	1<<1)
rawset(_G,"DF_ITEM",		1<<2)
rawset(_G,"DF_PLAYER",		1<<3)

-- Skinvar flags
rawset(_G,"SKINVARS_GUARD",			1<<0)
rawset(_G,"SKINVARS_NOSPINSHIELD",	1<<1)
rawset(_G,"SKINVARS_GUNSLINGER",	1<<2)
rawset(_G,"SKINVARS_ROSY",			1<<3)
rawset(_G,"SKINVARS_GLIDESTRAFE",	1<<4)
rawset(_G,"SKINVARS_GLIDESOUND",	1<<5)
rawset(_G,"SKINVARS_DASHMODENERF",	1<<6)
rawset(_G,"SKINVARS_HUMMINGTOP",	1<<7)
rawset(_G,"SKINVARS_RECURL",		1<<8)


-- I hate srb2
rawset(_G,"GTR_FIXGAMESET",	1<<0)

-- Define TOLs and gametypes
freeslot('tol_arena','tol_survival','tol_cp','tol_diamond','tol_battlectf','tol_bigarena','tol_battle','tol_eggrobotag')
B.AddBattleGametype({
	name = "Arena",
	identifier = "arena",
	typeoflevel = TOL_ARENA|TOL_MATCH,
	rules = GTR_OVERTIME|GTR_STARTCOUNTDOWN|GTR_RESPAWNDELAY|GTR_PITYSHIELD|GTR_SPECTATORS|GTR_POINTLIMIT|GTR_TIMELIMIT|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_DEATHMATCHSTARTS|GTR_HURTMESSAGES,
	rankingtype = GT_MATCH,
	intermissiontype = int_match,
	defaultpointlimit = 0,
	defaulttimelimit = 4,
	headerleftcolor = 56,
	headerrightcolor = 56,
	description = 'Bash other players with your spin and jump moves to earn points! Collect and use rings to unleash special moves unique to each character!'
})

B.AddBattleGametype({
	name = "Team Arena",
	identifier = "teamarena",
	typeoflevel = TOL_ARENA|TOL_MATCH,
	rules = GTR_OVERTIME|GTR_STARTCOUNTDOWN|GTR_RESPAWNDELAY|GTR_PITYSHIELD|GTR_TEAMS|GTR_SPECTATORS|GTR_POINTLIMIT|GTR_TIMELIMIT|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_DEATHMATCHSTARTS|GTR_HURTMESSAGES,
	rankingtype = GT_TEAMMATCH,
	intermissiontype = int_teammatch,
	defaultpointlimit = 0,
	defaulttimelimit = 4,
	headerleftcolor = 150,
	headerrightcolor = 37,
	description = 'Stick together! The team that can support each other and deal the most damage will be victorious!'
})

B.AddBattleGametype({
	name = "Survival",
	identifier = "survival",
	typeoflevel = TOL_SURVIVAL,
	rules = GTR_OVERTIME|GTR_LIVES|GTR_STARTCOUNTDOWN|GTR_RESPAWNDELAY|GTR_PITYSHIELD|GTR_SPECTATORS|GTR_POINTLIMIT|GTR_TIMELIMIT|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_DEATHMATCHSTARTS|GTR_HURTMESSAGES,
	rankingtype = GT_MATCH,
	intermissiontype = int_match,
	defaultpointlimit = 0,
	defaulttimelimit = 4,
	headerleftcolor = 231,
	headerrightcolor = 231,
	description = "It's survival of the fittest! Manage your shields and rings as you compete to be the last critter standing."
})

B.AddBattleGametype({
	name = "Team Survival",
	identifier = "teamsurvival",
	typeoflevel = TOL_SURVIVAL,
	rules = GTR_OVERTIME|GTR_LIVES|GTR_STARTCOUNTDOWN|GTR_RESPAWNDELAY|GTR_TEAMS|GTR_PITYSHIELD|GTR_SPECTATORS|GTR_POINTLIMIT|GTR_TIMELIMIT|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_DEATHMATCHSTARTS|GTR_HURTMESSAGES,
	rankingtype = GT_TEAMMATCH,
	intermissiontype = int_teammatch,
	defaultpointlimit = 0,
	defaulttimelimit = 4,
	headerleftcolor = 150,
	headerrightcolor = 37,
	description = "Shake'm all down in this team-based survival format. When one team runs out of lives, the other wins!"
})

B.AddBattleGametype({
	name = "Zone Control",
	identifier = "cp",
	typeoflevel = TOL_MATCH|TOL_CP,
	rules = GTR_OVERTIME|GTR_STARTCOUNTDOWN|GTR_RESPAWNDELAY|GTR_PITYSHIELD|GTR_SPECTATORS|GTR_POINTLIMIT|GTR_TIMELIMIT|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_DEATHMATCHSTARTS|GTR_HURTMESSAGES,
	rankingtype = GT_MATCH,
	intermissiontype = int_match,
	defaultpointlimit = 3000,
	defaulttimelimit = 5,
	headerleftcolor = 75,
	headerrightcolor = 75,
	description = "The player who stands inside the score zone for long enough will claim its reward! Knock your foes out before they steal the spotlight!"
})

B.AddBattleGametype({
	name = "Team Zone Control",
	identifier = "teamcp",
	typeoflevel = TOL_MATCH|TOL_CP,
	rules = GTR_OVERTIME|GTR_TEAMFLAGS|GTR_STARTCOUNTDOWN|GTR_RESPAWNDELAY|GTR_PITYSHIELD|GTR_TEAMS|GTR_SPECTATORS|GTR_POINTLIMIT|GTR_TIMELIMIT|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_DEATHMATCHSTARTS|GTR_HURTMESSAGES,
	rankingtype = GT_TEAMMATCH,
	intermissiontype = int_teammatch,
	defaultpointlimit = 3,
	defaulttimelimit = 5,
	headerleftcolor = 37,
	headerrightcolor = 150,
	description = "Players must work together to capture the control point before the opposing team does. The more players inside, the faster the capture!"
})

B.AddBattleGametype({
	name = "Warp Heist",
	identifier = "diamond",
	typeoflevel = TOL_DIAMOND|TOL_MATCH,
	rules = GTR_OVERTIME|GTR_STARTCOUNTDOWN|GTR_RESPAWNDELAY|GTR_PITYSHIELD|GTR_SPECTATORS|GTR_POINTLIMIT|GTR_TIMELIMIT|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_DEATHMATCHSTARTS|GTR_HURTMESSAGES,
	rankingtype = GT_MATCH,
	intermissiontype = int_match,
	defaultpointlimit = 6000,
	defaulttimelimit = 5,
	headerleftcolor = 148,
	headerrightcolor = 148,
	description = 'Find the Warp Topaz and take it to the Control Zone while avoiding every enemy in your way in this fast paced map knowledge testing mode!'
})

B.AddBattleGametype({
	name = "Team Warp Heist",
	identifier = "teamdiamond",
	typeoflevel = TOL_DIAMOND|TOL_MATCH,
	rules = GTR_OVERTIME|GTR_STARTCOUNTDOWN|GTR_RESPAWNDELAY|GTR_PITYSHIELD|GTR_TEAMS|GTR_SPECTATORS|GTR_POINTLIMIT|GTR_TIMELIMIT|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_DEATHMATCHSTARTS|GTR_HURTMESSAGES|GTR_TEAMFLAGS,
	rankingtype = GT_TEAMMATCH,
	intermissiontype = int_ctf,
	defaultpointlimit = 8,
	defaulttimelimit = 5,
	headerleftcolor = 37,
	headerrightcolor = 150,
	description = 'Work together to seize the Warp Topaz and send it back whence it came!'
})

-- Using Vanilla CTF again.. Custom CTF will see use later down the road ;q
B.AddBattleGametype({
	name = "Battle CTF",
	identifier = "battlectf",
	typeoflevel = TOL_CTF|TOL_BATTLECTF,
	rules = GTR_STARTCOUNTDOWN|GTR_RESPAWNDELAY|GTR_PITYSHIELD|GTR_TEAMFLAGS|GTR_TEAMS|GTR_SPECTATORS|GTR_POINTLIMIT|GTR_TIMELIMIT|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_OVERTIME|GTR_HURTMESSAGES,
	rankingtype = GT_CTF,
	intermissiontype = int_ctf,
	defaultpointlimit = 3,
	defaulttimelimit = 8,
	headerleftcolor = 37,
	headerrightcolor = 150,
	description = "Combine melee and special moves to capture the enemy flag while protecting your own. Master the slipstream to catch up to enemy flagrunners!"
})

freeslot('tol_rubyrun')
B.AddBattleGametype({
    name = "Ruby Run",
    identifier = "rubyrun",
    typeoflevel = TOL_RUBYRUN|TOL_CTF|TOL_BATTLECTF,
    rules = GTR_OVERTIME|GTR_STARTCOUNTDOWN|GTR_RESPAWNDELAY|GTR_PITYSHIELD|GTR_TEAMS|GTR_SPECTATORS|GTR_POINTLIMIT|GTR_TIMELIMIT|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_DEATHMATCHSTARTS|GTR_HURTMESSAGES|GTR_TEAMFLAGS,
    rankingtype = GT_CTF,
	intermissiontype = int_ctf,
	defaultpointlimit = 5,
	defaulttimelimit = 5,
    headerleftcolor = 37,
    headerrightcolor = 150,
    description = 'Team up to send the Phantom Ruby packing! First to 5 wins!'
})

freeslot("tol_battletag")
B.AddBattleGametype({
	name = "Battle Tag",
	identifier = "battletag",
	typeoflevel = TOL_TAG|TOL_MATCH|TOL_BATTLETAG|TOL_CTF|TOL_BATTLECTF,
	rules = GTR_SPECTATORS | GTR_TIMELIMIT | GTR_HURTMESSAGES | 
			GTR_RESPAWNDELAY | GTR_SPAWNINVUL | GTR_STARTCOUNTDOWN | 
			GTR_DEATHMATCHSTARTS | GTR_FIXGAMESET,
	defaulttimelimit = 6,
	defaulthidetime = 30, --Specific to B.AddBattleGametype, hidetime for gamemode
	intermissiontype = int_match,
	headercolor = 251,
	rankingtype = GT_TAG,
	description = "The classic game of Tag you all know, now in Battle edition!"
})

local B = CBW_Battle
local G = B.Gametypes

-- Vanilla gametypes aren't supported, so set them all to 0 values. (Vanilla gametypes start from 1 up to 8)
G.TeamScoreType 	= {0,0,0,0,0,0,0,0}
G.SuddenDeath 		= {false,false,false,false,false,false,false,false,false}
G.Battle 			= {false,false,false,false,false,false,false,false,false}
G.CP 				= {false,false,false,false,false,false,false,false,false}
G.Arena 			= {false,false,false,false,false,false,false,false,false}
G.Diamond 			= {false,false,false,false,false,false,false,false,false}
G.Ruby 				= {false,false,false,false,false,false,false,false,false}
G.PowerCards		= {false,false,false,false,false,false,false,false,false}
G.TailsDoll			= {false,false,false,false,false,false,false,false,false}
G.SkinLock			= {false,false,false,false,false,false,false,false,false}
G.SpawnAnimation	= {false,false,false,false,false,false,false,false,false}

-- Format: { [GAMETYPE], {[ GAMETYPE_VALUES ]}}
-- NOTE: the 3rd field indicates that the gametype is a BATTLE gametype.
local GAMETYPE_INDICES = {
	{GT_ARENA			,{0, false, true, false, true, false,false, true, true, true, true, true}}, 
	{GT_TEAMARENA		,{0, false, true, false, true, false,false, true, true, true, true, true}}, 
	{GT_SURVIVAL		,{0, true,  true, false, true, false,false, true, true, true, true, true}}, 
	{GT_TEAMSURVIVAL	,{0, true,  true, false, true, false,false, true, true, true, true, true}}, 
	{GT_BATTLECTF		,{0, false, true, false, false,false,false, false,true, true, true, true}}, 
	{GT_CP				,{0, false, true, true,  false,false,false, true, true, true, true, true}},
	{GT_TEAMCP			,{0, false, true, true,  false,false,false, true, true, true, true, true}},
	{GT_DIAMOND			,{0, false, true, false, false,true, false, true, true, true, true, true}},
	{GT_TEAMDIAMOND		,{0, false, true, false, false,true, false, true, true, true, true, true}},
	{GT_RUBYRUN 		,{0, false, true, false, false,false, true, false,true, true, true, true}},
	{GT_BATTLETAG		,{0, false, true, false, false,false,false, true, true, true, true, true}},
}
for i =1,#GAMETYPE_INDICES do
	local GAME_TYPE_INDEX 	= GAMETYPE_INDICES[i]
	local GAME_TYPE_VALUES 	= GAME_TYPE_INDEX[2]

	G.TeamScoreType[GAME_TYPE_INDEX[1]] 	= GAME_TYPE_VALUES[1]  -- Team Scoretype (1 = add player score to team score. 0 = do nothing)
	G.SuddenDeath[GAME_TYPE_INDEX[1]] 		= GAME_TYPE_VALUES[2]  -- Does this gametype support sudden death?
	G.Battle[GAME_TYPE_INDEX[1]] 			= GAME_TYPE_VALUES[3]  -- Does this gametype use the Battle format?
	G.CP[GAME_TYPE_INDEX[1]] 				= GAME_TYPE_VALUES[4]  -- Does this gametype use the Control Point format?
	G.Arena[GAME_TYPE_INDEX[1]] 			= GAME_TYPE_VALUES[5]  -- Does this gametype use the Arena format?
	G.Diamond[GAME_TYPE_INDEX[1]] 			= GAME_TYPE_VALUES[6]  -- Does this gametype use the Diamond format?
	G.Ruby[GAME_TYPE_INDEX[1]] 				= GAME_TYPE_VALUES[7]  -- Does this gametype use the Ruby format?
	G.PowerCards[GAME_TYPE_INDEX[1]]		= GAME_TYPE_VALUES[8]  -- Does this gametype support Power Cards?
	G.TailsDoll[GAME_TYPE_INDEX[1]]			= GAME_TYPE_VALUES[9]  -- Does this gametype add Tails Doll?
	G.SkinLock[GAME_TYPE_INDEX[1]]			= GAME_TYPE_VALUES[10] -- Does this gametype lock the current character?
	G.SpawnAnimation[GAME_TYPE_INDEX[1]]	= GAME_TYPE_VALUES[12] -- Does this gametype play the default spawn animation?
end

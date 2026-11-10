local B = CBW_Battle
local F = B.CTF
local R = B.Ruby

local REALFLAG_R = MT_REDFLAG
local REALFLAG_B = MT_BLUEFLAG
local FAKEFLAG_R = MT_CREDFLAG
local FAKEFLAG_B = MT_CBLUEFLAG

addHook("MobjThinker",F.TrackRed, FAKEFLAG_R)
addHook("MobjThinker",F.TrackBlue, FAKEFLAG_B)
addHook("MobjThinker",F.FlagIntangible,FAKEFLAG_R)
addHook("MobjThinker",F.FlagIntangible, FAKEFLAG_B)
addHook("MobjThinker",F.FlagMobjThinker,FAKEFLAG_R)
addHook("MobjThinker",F.FlagMobjThinker, FAKEFLAG_B)
addHook("TouchSpecial", F.FlagTouchSpecial, FAKEFLAG_R)
addHook("TouchSpecial", F.FlagTouchSpecial, FAKEFLAG_B)
addHook("MobjRemoved", F.FlagRemoved, FAKEFLAG_R)
addHook("MobjRemoved", F.FlagRemoved, FAKEFLAG_B)

addHook("MobjSpawn", function(mo)
	--The flag is spawned before score is updated, which is our only way of hooking onto flag capture for right now
	--This will disable cecho when the flag spawns
	--COM_BufInsertText(consoleplayer, "cecho ")
	F.FlagSkin(mo)
	mo.type = FAKEFLAG_R
end, REALFLAG_R)
addHook("MobjSpawn", function(mo)
	--The flag is spawned before score is updated, which is our only way of hooking onto flag capture for right now
	--This will disable cecho when the flag spawns
	--COM_BufInsertText(consoleplayer, "cecho ")
	F.FlagSkin(mo)
	mo.type = FAKEFLAG_B
end, REALFLAG_B)
addHook("ThinkFrame",F.TrackPlayers)

addHook("MobjThinker",B.Arena.RingLoss, MT_FLINGRING)

-- Draw GOT FLAG! indicator on player.
addHook("PostThinkFrame", F.DrawIndicator)

-- Check if flag was tossed or capped, etc.
addHook("PreThinkFrame", F.FlagPreThinker) 

-- Toss ruby
--addHook("PreThinkFrame", R.PreThinker) 

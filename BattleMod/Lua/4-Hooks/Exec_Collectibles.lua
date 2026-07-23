local B = CBW_Battle
local F = B.CTF
local R = B.Ruby

--[[ 
/* 	=== NOTE: ALL CUSTOM CTF FLAG HOOKS ARE CURRENTLY UNUSED! ===

	Real flags indicate flags that will be used in-game, and fake flags are
	the flags that will be replaced with the real flags.

	For this instance, REALFLAG_R (MT_REDFLAG) will replace FAKEFLAG_R (MT_CREDFLAG).

*/]]--
local REALFLAG_R = MT_REDFLAG
local REALFLAG_B = MT_BLUEFLAG
local FAKEFLAG_R = MT_CREDFLAG
local FAKEFLAG_B = MT_CBLUEFLAG

addHook("MobjThinker",F.TrackRed, REALFLAG_R)
addHook("MobjThinker",F.TrackBlue, REALFLAG_B)
addHook("MobjThinker",F.FlagIntangible,REALFLAG_R)
addHook("MobjThinker",F.FlagIntangible, REALFLAG_B)
addHook("MobjThinker",F.FlagMobjThinker,REALFLAG_R)
addHook("MobjThinker",F.FlagMobjThinker, REALFLAG_B)
addHook("TouchSpecial", F.TouchFlag, REALFLAG_R)
addHook("TouchSpecial", F.TouchFlag, REALFLAG_B)
addHook("MobjSpawn", function(mo)
	--The flag is spawned before score is updated, which is our only way of hooking onto flag capture for right now
	--This will disable cecho when the flag spawns
	COM_BufInsertText(consoleplayer, "cecho ")
	F.FlagSkin(mo)
end, REALFLAG_R)
addHook("MobjSpawn", function(mo)
	--The flag is spawned before score is updated, which is our only way of hooking onto flag capture for right now
	--This will disable cecho when the flag spawns
	COM_BufInsertText(consoleplayer, "cecho ")
	F.FlagSkin(mo)
end, REALFLAG_B)
addHook("ThinkFrame",F.TrackPlayers)

addHook("MobjThinker",B.Arena.RingLoss, MT_FLINGRING)

-- Draw GOT FLAG! indicator on player.
addHook("PostThinkFrame", F.DrawIndicator)

-- Check if flag was tossed or capped, etc.
addHook("PreThinkFrame", F.FlagPreThinker) 

addHook("MobjThinker", function(mo)
	if not(mo.extravalue1) then return end
	mo.extravalue1 = $-1
	mo.flags = $|MF_NOCLIPTHING
	if not(mo.extravalue1) then
		mo.flags = $ & ~MF_NOCLIPTHING
	end
end, MT_FLINGRING)

-- Toss ruby
--addHook("PreThinkFrame", R.PreThinker) 

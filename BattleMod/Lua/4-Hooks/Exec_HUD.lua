local B = CBW_Battle
local CV = B.Console
local CP = B.ControlPoint
local A = B.Arena
local D = B.Diamond
local R = B.Ruby
local F = B.CTF
local PR = CBW_PowerCards

--Make a wrapper function so these can be modified
--externally by any modder
hud.add(function(v,p,c)

	--Radar
	B.RadarHUD(v,p,c)
	B.MinimapHUD(v,p,c)

	--Player info
	B.ChangeHUD(v,p,c)
	B.RingsHUD(v,p,c)
	PR.ItemHUD(v,p,c)
	B.ActionHUD(v,p,c)
	B.ShieldHUD(v,p,c)
	B.TeammateHUD(v,p,c)
	B.TimerHUD(v,p,c)
	--B.StartRingsHUD(v,p,c)

	--Gamemode info
	CP.HUD(v,p,c)
	D.HUD(v,p,c)
	R.HUD(v,p,c)
	R.FadeFunc(v,p,c)
	A.AllFightersHUD(v,p,c)
	A.MyStocksHUD(v,p,c)
	A.BountyHUD(v,p,c)
	A.PlacementHUD(v,p,c)
	F.CompassHUD(v,p,c)
	F.TeamScoreHUD(v,p,c)
	F.DelayCapNotice(v,p,c)

	--Game state info
	B.PreRoundHUD(v,p,c)
	B.PinchHUD(v,p,c)
	A.RevengeHUD(v,p,c)
	A.WaitJoinHUD(v,p,c)
	B.SpectatorControlHUD(v,p,c)
	F.CapHUD(v,p,c)
	F.DelayCapBar(v,p,c)
	A.GameSetHUD(v,p,c)

	--Misc.
	B.HitCounterHUD(v,p,c)
	B.DebugHUD(v,p,c)
	B.TagGenHUD(v,p,c)
	B.DrawMatchPoint(v,p,c)
	PR.EventHUD(v,p,c)
end, "game")

hud.add(function(v,p,c) --Ditto
	B.ScoresTimerHUD(v,p,c)
	
	R.FadeFunc(v,p,c)
	
	--Score screen
	--B.StatsHUD(v,p,c)
	F.RankingHUD(v,p,c)
	B.TagRankHUD(v,p,c)
	R.RubyRankHUD(v,p,c)
	D.DiamondRankHUD(v,p,c)
end,"scores")

--Title HUD
hud.add(B.TitleHUD, "title")
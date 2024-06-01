local B = CBW_Battle
local CV = B.Console
local CP = B.ControlPoint
local A = B.Arena
local D = B.Diamond
local R = B.Ruby
local F = B.CTF

--Radar
hud.add(B.RadarHUD)
hud.add(B.MinimapHUD)

--Player info
hud.add(B.ChangeHUD)
hud.add(B.RingsHUD)
hud.add(B.ActionHUD)
hud.add(B.ShieldHUD)
hud.add(B.TeammateHUD)
hud.add(B.TimerHUD)

--Gamemode info
hud.add(CP.HUD)
hud.add(D.HUD)
hud.add(R.HUD)
hud.add(A.AllFightersHUD,player)
hud.add(A.MyStocksHUD,player)
hud.add(A.BountyHUD,player)
hud.add(A.PlacementHUD)
hud.add(F.CompassHUD)
hud.add(F.TeamScoreHUD)

--Game state info
hud.add(B.PreRoundHUD)
hud.add(B.PinchHUD,player)
hud.add(A.RevengeHUD,player)
hud.add(A.WaitJoinHUD,player)
hud.add(B.SpectatorControlHUD,player)
hud.add(F.CapHUD)
hud.add(A.GameSetHUD,player)

--Misc.
hud.add(B.HitCounterHUD,player)
hud.add(B.DebugHUD)

--Score screen
hud.add(F.RankingHUD, "scores")

--Title HUD
hud.add(B.TitleHUD, "title")
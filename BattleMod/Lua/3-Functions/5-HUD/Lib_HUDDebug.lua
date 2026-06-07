local B = CBW_Battle
local CV = B.Console
local A = B.Arena
local D = B.Diamond
local CP = B.ControlPoint
local I = B.Item
local S = B.SkinVars

B.DebugHUD = function(v, player, cam)
	local debug = CV.Debug.value
	
	if ((not B.VersionPublic) or debug) then
		local flags = V_ALLOWLOWERCASE|V_HUDTRANS|V_SNAPTORIGHT|V_SNAPTOTOP
		local flags2 = V_ALLOWLOWERCASE|V_HUDTRANSHALF|V_SNAPTORIGHT|V_SNAPTOTOP
		local xx = v.width()/v.dupx()
		local align = "small-right"
		if B.VersionNumber then
			v.drawString(320,0,"v"..B.VersionNumber.."."..B.VersionSub.." [\x82"..B.VersionCommit.."\x80]\n",flags,align)
			v.drawString(317,4,B.VersionBranch,flags2,align)
			v.drawString(317,8,B.VersionDate.." ["..B.VersionTime.."]",flags2,align)
		else
			v.drawString(320,0,"\x85".."PIRATE",flags2,align)
		end
	end
	
	if not(debug) then return end
	local xoffset = 320
	local yoffset = 14
	local left_xoffset = 0
	local left_yoffset = 0
	local center_xoffset = (xoffset+left_xoffset)/2
	local center_yoffset = 32
	local flags = V_HUDTRANS|V_SNAPTOTOP|V_SNAPTORIGHT|V_PERPLAYER
	local center_flags = V_HUDTRANS|V_SNAPTOTOP|V_PERPLAYER
	local left_flags = V_HUDTRANS|V_SNAPTOTOP|V_SNAPTOLEFT|V_PERPLAYER
	local align = "small-right"
	local center_align = "small-center"
	local left_align = "small"
	local nextline = 4
	local boolstring = function(string2)
		if type(string2) == "boolean" then
			string2 = string2 and "\x83"+"Y" or "\x85"+"N"
		elseif tostring(string2) == "nil" then
			string2 = "?"
		end
		return string2
	end
	--Double the scale for smaller screens (illegible otherwise)
	if v.height() < 400 then 
		align = "right"
		center_align = "center"
		left_align = nil
		nextline = 8
	end
	local addspace = function()
		yoffset = $+nextline
	end
	local addline = function(string,string2)
		string2 = boolstring(string2)
		string = "\x86"+tostring($)+": \x80"+tostring(string2)
		v.drawString(xoffset,yoffset,string,flags,align)
		yoffset = $+nextline
	end
	local addheader = function(string)
		yoffset = $+nextline
		string = "\x82"+string
		v.drawString(xoffset,yoffset,string,flags,align)
		yoffset = $+nextline
	end
	local subheader = function(string)
		string = "\x88"+string
		v.drawString(xoffset,yoffset,string,flags,align)
		yoffset = $+nextline
	end
	local left_addspace = function()
		left_yoffset = $+nextline
	end
	local left_addline = function(string,string2)
		string2 = boolstring(string2)
		string = "\x86"+tostring($)+": \x80"+tostring(string2)
		v.drawString(left_xoffset,left_yoffset,string,left_flags,left_align)
		left_yoffset = $+nextline
	end
	local left_addheader = function(string)
		left_yoffset = $+nextline
		string = "\x82"+string
		v.drawString(left_xoffset,left_yoffset,string,left_flags,left_align)
		left_yoffset = $+nextline
	end
	local left_subheader = function(string)
		string = "\x88"+string
		v.drawString(left_xoffset,left_yoffset,string,left_flags,left_align)
		left_yoffset = $+nextline
	end
	local center_addline = function(string,string2)
		if not (v.height() < 400) then
			left_addline(string, string2)
			return
		end
		string2 = boolstring(string2)
		string = "\x86"+tostring($)+": \x80"+tostring(string2)
		v.drawString(center_xoffset,center_yoffset,string,center_flags,center_align)
		center_yoffset = $+nextline
	end
	local center_addheader = function(string)
		if not (v.height() < 400) then
			left_addheader(string)
			return
		end
		center_yoffset = $+nextline
		string = "\x82"+string
		v.drawString(center_xoffset,center_yoffset,string,center_flags,center_align)
		center_yoffset = $+nextline
	end
	local center_subheader = function(string)
		if not (v.height() < 400) then
			left_subheader(string)
			return
		end
		string = "\x88"+string
		v.drawString(center_xoffset,center_yoffset,string,center_flags,center_align)
		center_yoffset = $+nextline
	end
	--****
	--Execute drawing
	--****
	if B.ArenaGametype() then
		--Making room for Arena's HUD
		addspace()
		addspace()
	end
	--Gametypes
	if debug&DF_GAMETYPE then
			left_addheader("GAMETYPE EXTRA")
			left_addline("RedScore",B.RedScore)
			left_addline("BlueScore",B.BlueScore)
			left_addline("Pinch",B.Pinch)
			left_addline("Overtime",B.Overtime)
			left_addline("SuddenDeath",B.SuddenDeath)
			left_addline("PinchTics",B.PinchTics)
			left_addline("Exiting",B.Exiting)
			left_addline("Timeout",B.Timeout)
			left_addline("MatchPoint",B.MatchPoint)

			left_subheader("SECTOR")
			local mo = player.mo
			if not (mo and mo.valid) then
				left_addline("Player object","?")
			else
				local ss = mo.subsector
				local s = ss.sector
				--[[
				local sp = s.special
				left_addline("Point in SubSector", R_PointInSubsector(mo.x, mo.y))
				left_addline("Subsector", ss)
				left_addline("Sector special", sp)
				for i=1,4 do
					left_addline("GetSecSpecial "..i, GetSecSpecial(sp, i))
				end
				]]
				left_addline("Damage type", s.damagetype)
				local fof = ((P_MobjFlip(mo)==-1) and mo.ceilingrover) or mo.floorrover
				--left_addline("FOF", fof)
				left_addline("FOF is lava", fof and P_CheckSolidLava(nil, fof) or nil)
			end

			addheader("GAMETYPE")
			
		if B.ArenaGametype() then
			subheader("ARENA")
			addline("Fighters",#A.Fighters)
			addline("RedFighters",#A.RedFighters)
			addline("BlueFighters",#A.BlueFighters)
			addline("Survivors",#A.Survivors)
			addline("RedSurvivors",#A.RedSurvivors)
			addline("BlueSurvivors",#A.BlueSurvivors)
			addline("SpawnLives",A.SpawnLives)
			addline("GameOvers",A.GameOvers)
			addline("Bounty",(A.Bounty and A.Bounty.valid) and (""..A.Bounty.."("+A.Bounty.name+")") or "?")
			if G_GametypeUsesLives() then
				addline("\x80Your DZ Priority", B.GetDeathZonePriority(player))
			end
		end
		
		if B.CPGametype() then
			subheader("CONTROL POINT")
			addline("IDs",#CP.ID)
			addline("Num",CP.Num)
			addline("Meter",CP.Meter)
			addline("RedCapAmt",CP.TeamCapAmt[1])
			addline("TeamCapAmt",CP.TeamCapAmt[2])
			addline("LeadCapAmt",CP.LeadCapAmt)
		end
		
		if B.DiamondGametype() then
			subheader("DIAMOND")
			addline("Diamond", D.Diamond != nil)
			addline("DiamondIndicator", D.DiamondIndicator != nil)
			addline("LastDiamondPointNum", D.LastDiamondPointNum)
			addline("Spawns", #D.Spawns)
			addline("CapturePoints", #D.CapturePoints)
			addline("ActivePoint", D.ActivePoint != nil)
			addline("Active", D.Active != nil)
			addline("SpawnGrace", D.SpawnGrace)
			addline("PointUnlockTime", D.PointUnlockTime)
			addline("CurrentPointNum", D.CurrentPointNum)
			addline("LastPointNum", D.LastPointNum)
			subheader("RUBY")
			addline("Spawned",(D.ID ~= nil and D.ID.valid))
			if(D.ID and D.ID.valid and D.ID.target and D.ID.target.player) then
				addline("Holder",(D.ID.target.player.name))
			end
			if(D.ID and D.ID.valid) then
				addline("Idle",(D.ID.idle))
			end
		end
	end
	
	--Items
	
	if debug&DF_ITEM then
		addheader("ITEMS")
		addline("Global Spawns",#I.Spawns)
		addline("Global Timer",I.SpawnTimer/TICRATE.."\x86/\x80"..(4-CV.ItemRate.value)*I.GlobalRate/2)
		addline("GlobalChance Entries",#I.GlobalChance)
		addline("Global Item Rate",I.GlobalRate)
		addline("Local Item Rate",I.LocalRate)
		addline("Item Type",CV.ItemType.value)
	end
	
	--Player
	if debug&DF_PLAYER then
		if player and player.valid then
			addheader("PLAYER")
			addline("SkinVars",player.skinvars)
			addline("SkinFlags",B.GetSkinVarsFlags(player))
			addline("PreserveScore",player.preservescore)
			subheader("EXHAUST")
			addline("Exhaust",player.exhaustmeter*100/FRACUNIT.."%")
			addline("LedgeExhaust",player.ledgemeter*100/FRACUNIT.."%")
			--addline("LandLag",player.landlag)
			subheader("SPECTATOR")
			addline("BattleSpawning",player.battlespawning)
			addline("SpectatorTime",player.spectatortime)
			addline("DeadTimer",player.deadtimer)
			if B.ArenaGametype() then
				subheader("ARENA STATS")
				addline("Rank",player.rank)
				addline("Revenge",player.revenge)
				addline("LifeShards",player.lifeshards)
				addline("IsEggRobo",player.iseggrobo)
				addline("IsJettySyn",player.isjettysyn)
			end
			if not(v.width() < 400) then
				left_addheader("PLAYER (EXT)")
			end
			left_subheader("ACTION")
			left_addline("Allowed",player.actionallowed)
			left_addline("Rings",player.actionrings)
			--left_addline("Debt",player.actiondebt)
			left_addline("State",player.actionstate)
			--left_addline("Super",player.actionsuper)
			left_addline("Time",player.actiontime)
			left_addline("Cooldown",player.actioncooldown)
			left_subheader("PRIORITY")
			left_addline("Sfunc",player.battle_sfunc)
			left_addline("Atk/Def",player.battle_atk.."\x86/\x80"..player.battle_def)
			left_addline("SAtk/SDef",player.battle_satk.."\x86/\x80"..player.battle_sdef)
			left_addline("Text",player.battle_hurttxt)
			left_subheader("GUARD")
			left_addline("CanGuard",player.canguard)
			left_addline("Guard",player.guard)
			left_addline("GuardTics",player.guardtics)
			left_subheader("AIR DODGE")
			left_addline("Safe",player.safedodge)
			left_addline("Intangible",player.intangible)
			left_addline("Cooldown",player.dodgecooldown)
			center_subheader("TUMBLE")
			center_addline("Tumble",player.tumble)
			center_addline("Limit",player.max_tumble_time)
			center_addline("Breakable",(not player.tumble_nostunbreak))
			center_subheader("STUNBREAK")
			center_addline("Can Break",player.canstunbreak)
			center_addline("Cost",player.stunbreakcosttext)
			center_addline("Type",player.tech_type)
			center_addline("Timer",player.tech_timer)
		end
		if player and player.valid and player.mo and player.mo.valid then
			local flags = S[player.mo.skin] and S[player.mo.skin].flags or S[-1].flags
			if (flags & SKINVARS_ROSY) then
				left_subheader("HAMMER")
				left_addline("Melee state",player.melee_state)
				left_addline("Melee charge",player.melee_charge*100/FRACUNIT.."%")
			end
			if (flags & SKINVARS_GUNSLINGER) then
				left_subheader("POPGUN")
				left_addline("AirGun",player.airgun)
				left_addline("Weapon delay",player.weapondelay)
			end
			if (player.charability2 == CA2_SPINDASH) then
				left_subheader("SPINDASH")
				--left_addline("Min/Max speed",player.mindash/FRACUNIT.."\x86/\x80"..player.maxdash/FRACUNIT)
				left_addline("Charge",player.dashspeed*100/player.maxdash.."%")
			end
			subheader("GENERAL")
			addline("ID",tostring(player.mo):gsub("userdata: ",""))
			addline("Target",tostring(player.mo.target):gsub("userdata: ",""))
			addline("Tracer",tostring(player.mo.tracer):gsub("userdata: ",""))
			addline("Carry",player.powers[pw_carry])
			addline("Flashing",player.powers[pw_flashing])
			addline("NoControl",player.powers[pw_nocontrol])
			addline("JumpFactor",player.jumpfactor*100/FRACUNIT.."%")
			addline("ThrustFactor",player.thrustfactor)
			addline("Lock Aim/Move",boolstring(player.lockaim).."\x86/\x80"..boolstring(player.lockmove))
			addline("Pushed Credit",player.pushed_creditplr)
			center_subheader("COYOTE")
			center_addline("Time",player.mo.coyoteTime)
		end
	end
	--Collision
	if debug&DF_COLLISION then
		addheader("COLLISION")
		if player and player.valid and player.mo and player.mo.valid then
			subheader("PLAYER.MO")
			addline("Pushed_last",player.mo.pushed_last)
			addline("Pushtics",player.mo.pushtics)
			addline("Weight",(player.mo.weight or 0)*100/FRACUNIT.."%")
			addline("CanTouchTeam",player.mo.cantouchteam)
		end
		local T = B.TrainingDummy
		if T and T.valid then
			subheader("TRAINING DUMMY")
			addline("Hits",B.HitCounter)
			addline("Fuse",T.fuse)
			addline("Pain",T.pain)
			addline("AI",T.ai)
			addline("Attacking",T.attacking)
			addline("Phase",T.phase)
			addline("Invisibility",(T.flags&MF_NOCLIPTHING))
		end
	end
end

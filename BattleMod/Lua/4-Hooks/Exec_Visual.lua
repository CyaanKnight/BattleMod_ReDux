local B = CBW_Battle
local R = B.Ruby
local CP = B.ControlPoint
local D = B.Diamond
local F = B.CTF
local C = B.Bank

addHook("MobjThinker", B.BattleShieldThinker, MT_BATTLESHIELD)
addHook("MobjThinker", B.NegaShieldThinker, MT_NEGASHIELD)
addHook("MobjThinker", B.InstaFlip, MT_INSTASHIELD)
addHook("MobjThinker", B.StunBreakVFXThinker, MT_STUNBREAK)
addHook("MobjThinker",function(mo) B.EnergyGather(mo,mo.target,mo.extravalue1,mo.extravalue2) end,MT_ENERGYGATHER)
addHook("MobjThinker", B.TargetDummyThinker, MT_TARGETDUMMY)

//Shields (yeah, this is pretty messy...)
local colorsh = function(mo, redcol, bluecol)
	B.OverlayHide(mo,mo.target)
	
	if mo.colorized return end
	local target = mo.target
	if target and target.valid and not target.player and target.target and target.target.player
		target = target.target
	end
	
	if not (G_GametypeHasTeams() and target and target.valid and target.player and target.player.valid and target.player.ctfteam)
		return
	end
	
	if (target.player.ctfteam == 1) and redcol
		mo.color = redcol
		mo.colorized = true
		return
		
	elseif (target.player.ctfteam == 2) and bluecol
		mo.color = bluecol
		mo.colorized = true
		return
	end
end

local colorsh2 = function(mo)
	if mo.state >= S_ARMA1 and mo.state <= S_ARMB32
		colorsh(mo,nil,SKINCOLOR_PURPLE)
		return
	end
	if mo.state >= S_ZAPS1 and mo.state <= S_ZAPSB11
		colorsh(mo,SKINCOLOR_SUPERRED3,SKINCOLOR_SUPERSKY2)
		return
	end
	if mo.state >= S_FIRS1 and mo.state <= S_FIRSB10
		colorsh(mo,nil,SKINCOLOR_CYAN)
		return
	end
	if mo.state >= S_BUBS1 and mo.state <= S_BUBSB6
		colorsh(mo,SKINCOLOR_SUPERGOLD1,nil)
		return
	end
	if mo.state >= S_ELEMF1 and mo.state <= S_ELEMF10
		colorsh(mo,nil,SKINCOLOR_SAPPHIRE)
		return
	end
	B.OverlayHide(mo,mo.target)
end

B.RestoreTailsFollowMobj = function(p, mobj) -- cry
	if not (p and p.mo and p.mo.skin == "tails") then return end
	if (mobj == nil) then mobj = p.followmobj end
	if not (mobj) then return end

	if p.mo.state == S_PLAY_LEDGE_GRAB 
	or p.mo.state == S_PLAY_LEDGE_RELEASE
        mobj.state = S_TAILSOVERLAY_PLUS60DEGREES
		P_MoveOrigin(mobj,
		p.mo.x-P_ReturnThrustX(mobj, p.drawangle, 2*p.mo.scale)+P_ReturnThrustX(mobj, mobj.angle, mobj.scale),
		p.mo.y-P_ReturnThrustY(mobj, p.drawangle, 2*p.mo.scale)+P_ReturnThrustY(mobj, mobj.angle, mobj.scale),
		p.mo.z+FixedMul(4*p.mo.scale, mobj.scale)
		)
		mobj.angle = p.drawangle
		return true
    end

	if mobj.state == S_INVISIBLE
		mobj.state = S_TAILSOVERLAY_PLUS30DEGREES
	end

	if (p.skidtime or mobj.restorebuffer)
	and P_IsValidSprite2(mobj, SPR2_WALK)
		mobj.state = S_TAILSOVERLAY_PLUS30DEGREES
		mobj.frame = 512 + min(7,1+p.speed/(p.mo.scale*2))
		P_MoveOrigin(mobj,
		p.mo.x-P_ReturnThrustX(mobj, p.drawangle, 2*p.mo.scale)+P_ReturnThrustX(mobj, mobj.angle, mobj.scale),
		p.mo.y-P_ReturnThrustY(mobj, p.drawangle, 2*p.mo.scale)+P_ReturnThrustY(mobj, mobj.angle, mobj.scale),
		p.mo.z+FixedMul(2*p.mo.scale, mobj.scale)
		)
		mobj.angle = p.drawangle
		mobj.restorebuffer = p.skidtime --+1 frame
		return true
	end
end
addHook("FollowMobj", B.RestoreTailsFollowMobj, MT_TAILSOVERLAY)

addHook("MobjThinker", function(mo) colorsh(mo,SKINCOLOR_CRIMSON,nil) end,MT_ELEMENTAL_ORB)
addHook("MobjThinker", function(mo) colorsh(mo,SKINCOLOR_ORANGE,SKINCOLOR_VAPOR) end,MT_ATTRACT_ORB)
addHook("MobjThinker", function(mo) colorsh(mo,SKINCOLOR_FLAME,SKINCOLOR_SKY) end,MT_WHIRLWIND_ORB)
addHook("MobjThinker", function(mo) colorsh(mo,SKINCOLOR_RED,SKINCOLOR_MIDNIGHT) end,MT_FORCE_ORB)
addHook("MobjThinker", function(mo) colorsh(mo,nil,SKINCOLOR_BLUE) end,MT_ARMAGEDDON_ORB)
addHook("MobjThinker", function(mo) colorsh(mo,nil,SKINCOLOR_DUSK) end,MT_FLAMEAURA_ORB)
addHook("MobjThinker", function(mo) colorsh(mo,SKINCOLOR_RED,nil) end,MT_BUBBLEWRAP_ORB)
addHook("MobjThinker", function(mo) colorsh(mo,SKINCOLOR_RED,SKINCOLOR_SAPPHIRE) end,MT_THUNDERCOIN_ORB)
addHook("MobjThinker", colorsh2,MT_OVERLAY)

B.PityThinker = function(mo) 
	B.OverlayHide(mo,mo.target)
	if gametyperules&GTR_PITYSHIELD or G_GametypeHasTeams()
		local owner = mo.target
		if not(owner and owner.valid and owner.player and owner.player.valid) then return nil end
		mo.color = owner.player.skincolor
		mo.colorized = true
	else
		mo.color = SKINCOLOR_CERULEAN
	end
end
addHook("MobjThinker", B.PityThinker,MT_PITY_ORB)

B.SpinDustThinker = function(mo)
	if mo.changed then
		return
	end
	if (mo.state == S_SPINDUST_FIRE1)
	and (mo.target and mo.target.valid and mo.target.player)
	then
		mo.color = mo.target.player.skincolor
		mo.state = S_TEAMFIRE1
		mo.frame = $|FF_ANIMATE|FF_TRANSMASK
		mo.fuse = TICRATE/2
		mo.destscale = 0
		mo.scalespeed = $/2
		mo.changed = true
	end
end
addHook("MobjThinker", B.SpinDustThinker, MT_SPINDUST)

//visual indicator for tagger
B.BattleTagITtag = function(mo)
	if gametype != GT_BATTLETAG
	or mo.tracerplayer == nil
	or not mo.tracerplayer.valid
	or not mo.tracerplayer.battletagIT
		P_RemoveMobj(mo)
		return
	end
	
	local tracer = mo.tracerplayer.mo
	if tracer != nil and tracer.valid
		mo.flags2 = $ & ~MF2_DONTDRAW
		mo.scale = tracer.scale
		mo.eflags = tracer.eflags
		local zheight
		if tracer.eflags & MFE_VERTICALFLIP
			zheight = tracer.height / 2 * -1
		else
			zheight = tracer.height + tracer.height / 3
		end
		P_MoveOrigin(mo, tracer.x, tracer.y, tracer.z + zheight)
	else
		mo.flags2 = $ | MF2_DONTDRAW
	end
end
addHook("MobjThinker", B.BattleTagITtag, MT_BATTLETAG_IT)

local ARROW_TAGSCALE = 0
local ARROW_CONSTANTSCALE = 1
local ARROW_INVERTSCALE = 2
/*

0 = Spectator
1 = Red Team
2 = Blue Team

*/

local st_atbase      =  0   -- Default State, flag is at base
local st_dropped   =  1   -- Flag was dropped by the flagholder
local st_tossed    =  2   -- Flag was tossed by the flagholder
local st_inposession =  3   -- Flag is currently in posession

//thinker for pointer
B.BattleTagPointers = function(mo)
	local hide = false
	local delete = false
	local arrowscale = ARROW_TAGSCALE
	local target = mo.target
	local color = SKINCOLOR_NONE
	local player = (mo.tracer and mo.tracer.player) or nil

	if not(B.IsValidPlayer(mo.tracer)) or not(mo.tracer) or (player.playerstate == PST_DEAD) or (G_GametypeHasTeams() and (player.ctfteam == 0)) then
		if mo and mo.valid then
			P_RemoveMobj(mo)
		end
		return false
	elseif (gametype == GT_BATTLECTF) then
		arrowscale = ARROW_INVERTSCALE


		local homeflag = ({F.RedFlag, F.BlueFlag})[player.ctfteam] --Your team's flag
		local enemyflag = ({F.BlueFlag, F.RedFlag})[player.ctfteam] --Enemy team's flag

		local homebase = ({F.RedFlagPos, F.BlueFlagPos})[player.ctfteam] --Your team's base
		local enemybase = ({F.BlueFlagPos, F.RedFlagPos})[player.ctfteam] --Enemy team's base

		local homecolor = ({skincolor_redteam, skincolor_blueteam})[player.ctfteam] --Your team's skincolor
		local enemycolor = ({skincolor_blueteam, skincolor_redteam})[player.ctfteam] -- Enemy team's skincolor

		local flag_states = {st_atbase, st_atbase}

		for i = 1, 2 do

			local flag = ({F.RedFlag, F.BlueFlag})[i] --Execute this for both flags


			if flag and flag.valid then --Flag exists?
				
				-- Booleans
				local flag_tossed  		= (flag.flag_wastossed  and true) or false
				local flag_dropped 		= (flag.flag_wasdropped and true) or false
				local flag_inposession  = (flag.player 	    and true) or false

				if flag_inposession then
					flag_states[i] = st_inposession
				elseif flag_dropped then
					flag_states[i] = st_dropped
				elseif flag_tossed then
					flag_states[i] = st_tossed
				else
					flag_states[i] = st_atbase
				end
			end
		end

		local redflag_state  = flag_states[1]
		local blueflag_state = flag_states[2]

		local homeflag_state  = ({flag_states[1], flag_states[2]})[player.ctfteam]
		local enemyflag_state = ({flag_states[2], flag_states[1]})[player.ctfteam]
		
		if mo.allydrop then --Enemy flag was dropped, and this is the special arrow?

			arrowscale = ARROW_CONSTANTSCALE
			--if enemyflag_state == st_dropped then
				--Someone needs to grab it before the enemy team does
			target = enemyflag
			color = enemycolor
				--Point to the enemy flag
			--else
				--delete = true
			--end

			if target and target.valid and target.player then
				hide = true
			end

		
		elseif player.gotflag --You are the flagholder?
			--You need to capture the flag
			target = homebase
			color = homecolor
			--Point to your team's base

		else --The Constant CTF Arrows
			--Someone needs to grab the enemy flag
			if (homeflag_state == st_atbase) and (enemyflag_state == st_atbase) then
				target = enemyflag
				color = enemycolor
			else
				target = homeflag
				color = homecolor
			end
		end
	elseif (gametype == GT_BATTLETAG) then
		arrowscale = ARROW_TAGSCALE
		if ((not(player.battletagIT) or target.player.battletagIT) or not(B.IsValidPlayer(target))) then
			hide = true
		end
	elseif (gametype == GT_RUBYRUN) then
		arrowscale = ARROW_CONSTANTSCALE
		if mo.goalpointer then
			if R.ID and R.ID.valid and R.ID.target and R.ID.target.valid and R.ID.target.player and R.ID.target.player.gotcrystal then
				local flagholder = R.ID.target.player
				if player.ctfteam == flagholder.ctfteam then
					target = ({R.BlueGoal, R.RedGoal})[mo.tracer.player.ctfteam]
					color = ({skincolor_blueteam, skincolor_redteam})[mo.tracer.player.ctfteam]
				else
					target = ({R.RedGoal, R.BlueGoal})[mo.tracer.player.ctfteam]
					color = ({skincolor_redteam, skincolor_blueteam})[mo.tracer.player.ctfteam]
				end
			else
				hide = true
			end
		else
			if R.ID and R.ID.valid then
				if R.ID.target and R.ID.target.valid and R.ID.target.player and R.ID.target.player.gotcrystal then
					target = R.ID.target
				else
					target = R.ID
				end
				color = SKINCOLOR_MAGENTA
			else
				hide = true
			end
		end
	elseif (gametype == GT_DIAMOND) or (gametype == GT_TEAMDIAMOND) then
		arrowscale = ARROW_CONSTANTSCALE

		if mo.goalpointer then
			if D.ActivePoint and D.ActivePoint.valid and not(player.gotcrystal) then

				target = D.ActivePoint
				color = SKINCOLOR_GREY
			else
				hide = true
			end
		else
			if player.gotcrystal then
				if D.ActivePoint and D.ActivePoint.valid then

					target = D.ActivePoint


					if D.Diamond and D.Diamond.valid then
						color = D.Diamond.color
					else --This shouldn't ever happen, but just in case
						color = SKINCOLOR_GOLD
					end


				else

					hide = true

				end
			else
				if D.Diamond and D.Diamond.valid then

					if D.Diamond.target and D.Diamond.target.valid and D.Diamond.target.player and D.Diamond.target.player.gotcrystal then


						target = D.Diamond.target
						color = D.Diamond.target.player.skincolor

					else

						target = D.Diamond
						color = D.Diamond.color
					end

				else

					hide = true

				end
			end
		end
	elseif (gametype == GT_CP) then
		arrowscale = ARROW_CONSTANTSCALE
		if CP.ID and CP.Num and CP.ID[CP.Num] and CP.ID[CP.Num].valid and ((CP.Timer <= TICRATE*10) or (CP.Active == true)) then
			target = CP.ID[CP.Num]
			if CP.LeadCapPlr then --Is there a player in the lead?
				color = CP.LeadCapPlr.skincolor
			else
				color = SKINCOLOR_GOLD
			end
		else
			hide = true
		end
	elseif (gametype == GT_TEAMCP) then
		arrowscale = ARROW_CONSTANTSCALE
		if CP.ID and CP.Num and CP.ID[CP.Num] and CP.ID[CP.Num].valid and ((CP.Timer <= TICRATE*10) or (CP.Active == true)) then
			target = CP.ID[CP.Num]

			if (CP.TeamCapAmt[1] > CP.TeamCapAmt[2]) then --Red Team is winning?
				color = skincolor_redteam
			elseif (CP.TeamCapAmt[2] > CP.TeamCapAmt[1]) then --Blue Team is winning?
				color = skincolor_blueteam
			else
				color = SKINCOLOR_YELLOW --Tie?
			end
		else
			hide = true
		end
	elseif (gametype == GT_SURVIVAL) or (gametype == GT_TEAMSURVIVAL) then

		if B.SuddenDeath then
			arrowscale = ARROW_CONSTANTSCALE
			if B.ZoneObject and B.ZoneObject.valid then
				target = B.ZoneObject
				color = SKINCOLOR_COPPER --idk I couldn't think of a better color
			else
				hide = true
			end
		end
	end

	if (type(target) == "userdata") and (userdataType(target) == "mobj_t") and not(target.valid) then
		delete = true
	end

	if hide then
		if B.TagGametype() then
			if mo.tracer and mo.tracer.valid then
				if mo == mo.tracer.btagpointer then
					mo.tracer.btagpointer = nil
				end

				if mo == mo.tracer.btagpointer2 then
					mo.tracer.btagpointer2 = nil
				end
				mo.tracer.btagpointers = nil
			end
			P_RemoveMobj(mo)
			return
		else
			--mo.flags2 = $|MF2_DONTDRAW
		end
	else
		if not(B.TagGametype()) then
			mo.flags = $ & ~MF2_DONTDRAW
		end
	end
	
	//change the appearance based on perspective
	local cam
	if displayplayer == mo.tracer.player
		cam = camera
	elseif secondarydisplayplayer == mo.tracer.player
		cam = camera2
	end
	if cam != nil
		if cam.chase
			mo.frame = $ | FF_PAPERSPRITE & ~FF_FLOORSPRITE
			mo.renderflags = $ & ~RF_NOSPLATBILLBOARD
			mo.spriteroll = ANGLE_270
		else
			mo.frame = $ | FF_FLOORSPRITE & ~FF_PAPERSPRITE
			mo.renderflags = $ | RF_NOSPLATBILLBOARD
			mo.spriteroll = 0
		end
	end
	mo.drawonlyforplayer = mo.tracer.player
	mo.color = color or SKINCOLOR_PITCHBLACK
	local x = mo.tracer.x
	local y = mo.tracer.y
	local z = mo.tracer.z
	if delete then
		if mo.tracer and mo.tracer.valid and mo.tracer.player then
			if mo.tracer.btagpointer2 == mo then
				mo.tracer.btagpointer2 = nil
			end
			if mo.tracer.btagpointer == mo then
				mo.tracer.btagpointer = nil
			end
		end
		P_RemoveMobj(mo)
		return
	end
	local rx = target.x
	local ry = target.y
	local rz = target.z
	//keep track of how close the targeted runner is
	local h_dist = R_PointToDist2(x, y, rx, ry)
	mo.closedist = R_PointToDist2(0, z, h_dist, rz)
	//point towards the targeted runner
	mo.angle = R_PointToAngle2(x, y, rx, ry)
	local hight = mo.tracer.height / 2
	if mo.tracer.eflags & MFE_VERTICALFLIP
		hight = 0
	end
	P_MoveOrigin(mo, x + P_ReturnThrustX(mo, mo.angle, 75 * mo.tracer.scale), 
			y + P_ReturnThrustY(mo, mo.angle, 75 * mo.tracer.scale), z + hight)
	//change the appearance based on distance of targeted runner
	mo.frame = $ & ~FF_TRANSMASK
	local blink
	mo.closedist = $ / (FRACUNIT * 60)
	if mo.closedist <= 2
		blink = 1
	elseif mo.closedist <= 20

		if arrowscale == ARROW_TAGSCALE then
			mo.scale = mo.tracer.scale
		elseif arrowscale == ARROW_INVERTSCALE then
			mo.scale = mo.tracer.scale / 4
		elseif arrowscale == ARROW_CONSTANTSCALE then
			mo.scale = mo.tracer.scale
		end

		blink = 3
		mo.frame = $ & ~FF_TRANSMASK
	elseif mo.closedist <= 60

		if arrowscale == ARROW_TAGSCALE then
			mo.scale = mo.tracer.scale - (mo.tracer.scale / 4)
		elseif arrowscale == ARROW_INVERTSCALE then
			mo.scale = mo.tracer.scale / 2
		end

		blink = 6
		mo.frame = $ | FF_TRANS10
	elseif mo.closedist <= 180

		if arrowscale == ARROW_TAGSCALE then
			mo.scale = mo.tracer.scale / 2
		elseif arrowscale == ARROW_INVERTSCALE then
			mo.scale = mo.tracer.scale - (mo.tracer.scale / 4)
		end

		blink = 12
		mo.frame = $ | FF_TRANS30
	else

		if arrowscale == ARROW_TAGSCALE then
			mo.scale = mo.tracer.scale / 4
		elseif arrowscale == ARROW_INVERTSCALE then
			mo.scale = mo.tracer.scale
		end

		blink = 24
		mo.frame = $ | FF_TRANS50
	end
	if leveltime % blink == 0
		if blink == 1
			mo.flags2 = $ | MF2_DONTDRAW
		else
			mo.flags2 = $ & ~MF2_DONTDRAW
			if mo.frame & FF_ADD
				mo.frame = $ & ~FF_ADD
			else
				mo.frame = $ | FF_ADD
			end
		end
	end
	if mo.interpolation_fix then
		mo.flags = $ & ~MF_NOSECTOR
	end
	mo.interpolation_fix = true

end
addHook("MobjThinker", B.BattleTagPointers, MT_BTAG_POINTER)
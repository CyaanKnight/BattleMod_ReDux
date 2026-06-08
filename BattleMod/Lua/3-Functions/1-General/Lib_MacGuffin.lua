local B = CBW_Battle
local CV = CBW_Battle.Console

B.MacGuffinPass = function(player) --PreThinkFrame (For Tossflag)
    if not(G_GametypeHasTeams()) then return end

    local mo = player.mo
    local zpos = mo.z+(mo.height+(mo.scale*10))

    local frame = _G["A"]
    local mirrored = false

    if P_MobjFlip(mo) == -1 then
        zpos = (mo.z+mo.height)-(mo.height+(mo.scale*10))
    end

    local doflip = false

    local flipfunc = function(screenplayer, flipcam)
        local flippedpassplayer = P_MobjFlip(mo)==-1
        local flippedscreenplayer = P_MobjFlip(screenplayer.mo)==-1
        --local flipcam = CV_FindVar('flipcam').value

        if flipcam then
            if (P_MobjFlip(mo)+P_MobjFlip(screenplayer.mo)) == 0 --Mismatched flips, with flipcam?
                doflip = true --Flip it so it's readable
            end
        else
            if flippedpassplayer then 
                doflip = true --Always flip it if the camera is never going to be flipped
            end
        end
    end

    local skipflip = false


    if not(splitscreen) then
        local screenplayer = displayplayer
        if screenplayer and screenplayer.mo and screenplayer.mo.valid then
            flipfunc(screenplayer, CV.FindVar("flipcam").value)
        end
    end
    

    if doflip then
        frame = _G["B"]
        mirrored = true
    end

    local pass_indicator = mo.pass_indicator

    if (pass_indicator and pass_indicator.valid) then
        B.ApplyFlip(mo, pass_indicator)
        pass_indicator.mirrored = mirrored
        P_MoveOrigin(pass_indicator, mo.x, mo.y, zpos)
        pass_indicator.momx, pass_indicator.momy, pass_indicator.momz = mo.momx, mo.momy, mo.momz
        pass_indicator.scale = mo.scale-(mo.scale/4)
        pass_indicator.frame = frame|FF_FULLBRIGHT
        pass_indicator.sprite = SPR_MACGUFFIN_PASS
        pass_indicator.color = ({{SKINCOLOR_PINK,SKINCOLOR_CRIMSON},{SKINCOLOR_AETHER,SKINCOLOR_COBALT}})[player.ctfteam][1+(((leveltime/2)%2))]
        pass_indicator.renderflags = $|RF_NOCOLORMAPS
        pass_indicator.fuse = max($, 2)
        if displayplayer and B.MyTeam(displayplayer, player) then
            pass_indicator.flags2 = $ & ~MF2_DONTDRAW
        else
            pass_indicator.flags2 = $|MF2_DONTDRAW
        end
    else
        pass_indicator = P_SpawnMobj(mo.x, mo.y, zpos, MT_PARTICLE)
        pass_indicator.flags = MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP|MF_NOCLIP
        pass_indicator.flags2 = $|MF2_DONTDRAW
        pass_indicator.fuse = -1
        B.ApplyFlip(mo, pass_indicator)
        mo.pass_indicator = pass_indicator
    end
end

local CV = B.Console
B.UpdateCheckpoint = function(mo, checkpoint)
    local t = mo.target
    local floored = P_IsObjectOnGround(t) or ((t.eflags & MFE_JUSTHITFLOOR) and (t.player.pflags & PF_STARTJUMP))
	local safe = not B.MobjNearDamageFloor(t)
	local failsafe = t.state != S_PLAY_PAIN and not P_PlayerInPain(t.player)
	if not (checkpoint and checkpoint.valid) then
		checkpoint = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_THOK)
		checkpoint.tics = -1
		checkpoint.state = S_SHRD1
	elseif floored and safe and failsafe then
		P_MoveOrigin(checkpoint, t.x - t.momx, t.y - t.momy, t.z)
	end
	local debug = CV.Debug.value
	if debug&DF_GAMETYPE then
		checkpoint.flags2 = $&~MF2_DONTDRAW
	else
		checkpoint.flags2 = $|MF2_DONTDRAW
	end
    return checkpoint
end

B.MacGuffinClaimed = function(mo, customdist, addxy, nofloat)
    mo.flags = ($&~MF_BOUNCE)|MF_NOGRAVITY|MF_SLIDEME
	local t = mo.target
	local ang = mo.angle
	local dist = customdist or mo.target.radius*3
	local x = t.x+P_ReturnThrustX(mo,ang,dist)
	local y = t.y+P_ReturnThrustY(mo,ang,dist)
    if addxy == nil then
        addxy = t.player and t.player.deadtimer
    end
    if addxy then
        x = $ + t.momx
        y = $ + t.momy
    end
	local z = t.z+abs(leveltime&63-31)*FRACUNIT/2 -- Gives us a hovering effect
	if P_MobjFlip(t) == 1 -- Make sure our vertical orientation is correct
		mo.flags2 = $&~MF2_OBJECTFLIP
	else
-- 		z = $+t.height
		mo.flags2 = $|MF2_OBJECTFLIP
	end
	P_MoveOrigin(mo,t.x,t.y,t.z)
	P_InstaThrust(mo,R_PointToAngle2(mo.x,mo.y,x,y),min(FRACUNIT*60,R_PointToDist2(mo.x,mo.y,x,y)))
	if not nofloat then
        mo.z = max(mo.floorz,min(mo.ceilingz+mo.height,z)) -- Do z pos while respecting level geometry
    end
end

B.HomingDeflect = function(player, target)
    if player and player.lasthoming
    and leveltime - player.lasthoming < TICRATE/5
    then
        if not player.powers[pw_flashing] then
            local mo = player.mo
            S_StartSound(mo, sfx_deflct)
            mo.momx = -$*2/3
            mo.momy = -$*2/3
            local s = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_BATTLESHIELD)
		    s.scale = s.scale*3
		    s.colorized = true
		    s.color = SKINCOLOR_BONE
        end
        B.DebugPrint(player.name.." tried to homing attack an orbital at leveltime "..leveltime..". Last homing: "..player.lasthoming, DF_GAMETYPE)
        return true
    end
end

B.MobjTouchingFlagBase = function(mo) --Will return who's team the base mo is touching belongs to
	local red_team = 1
	local blue_team = 2
	local fof = ((P_MobjFlip(mo)==-1) and mo.ceilingrover) or mo.floorrover --FOF the object is on, if it exists
	local touching_redbase = P_MobjTouchingSectorSpecialFlag(mo, SSF_REDTEAMBASE) --Is the object touching the Red Base? (According to the function)
	local touching_bluebase = P_MobjTouchingSectorSpecialFlag(mo, SSF_BLUETEAMBASE) --Is the object touching the Blue Base? (According to the function)

	--Set the return value to whichever team SRB2 thinks the base belongs to *first*
	local return_value = ((touching_redbase and 1) or touching_bluebase and 2) or 0

	if touching_redbase then --If SRB2 says we're touching the Red Base...
		if fof and fof.sector and (fof.sector ~= touching_redbase) then --But we're actually on a FOF marked with a sector that is not the Red Base
			return 0
		end
	elseif touching_bluebase then --If SRB2 says we're touching the Blue Base...
		if fof and fof.sector and (fof.sector ~= touching_bluebase) then --But we're actually on a FOF marked with a sector that is not the Blue Base
			return 0
		end
	end

    return return_value
end

B.MobjNearDamageFloor = function(mo)
	local fof = ((P_MobjFlip(mo)==-1) and mo.ceilingrover) or mo.floorrover
    return (mo.subsector.sector.damagetype and mo.z <= mo.subsector.sector.floorheight) or (fof and P_CheckSolidLava(nil, fof))
end

B.Blink = function(mo)
    if mo.fuse&1
		mo.flags2 = $|MF2_DONTDRAW
	else
		mo.flags2 = $&~MF2_DONTDRAW
	end
end

B.ClaimedScale = function(mo, s1, s2)
    if mo.target
		mo.destscale = s1
	else
		mo.destscale = s2
	end
end

B.HandleRemovalSectors = function(mo, name, noremove)
    if mo.target and mo.target.valid then
        return
    end

    local sector = mo.subsector.sector
    local special = GetSecSpecial(sector.special, 4)
	
	if mo.eflags&MFE_GOOWATER
		or (special == 3) or (sector.specialflags&SSF_REDTEAMBASE)
        or (special == 4) or (sector.specialflags&SSF_BLUETEAMBASE)
        or P_MobjTouchingSectorSpecialFlag(mo, SSF_RETURNFLAG) -- rev: i don't know if this even works..
        or B.MobjNearDamageFloor(mo)
    then
        name = $ or "MacGuffin"
		B.DebugPrint("The "..name.." has collided with a removal sector", DF_GAMETYPE)
		--B.PrintGameFeed(mo.target.player, " dropped the "..name..".")

		if not noremove then
            P_RemoveMobj(mo)
        end
		return true
	end
end

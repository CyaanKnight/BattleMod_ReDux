local B = CBW_Battle

local dash_mobjtype = MT_DASHMODE_OVERLAY

local dash_sfx = sfx_dashm
local dash_sfxvol = 207

local applyFlip = function(mo1, mo2)
	if mo1.eflags & MFE_VERTICALFLIP then
		mo2.eflags = $|MFE_VERTICALFLIP
	else
		mo2.eflags = $ & ~MFE_VERTICALFLIP
	end
	
	if mo1.flags2 & MF2_OBJECTFLIP then
		mo2.flags2 = $|MF2_OBJECTFLIP
	else
		mo2.flags2 = $ & ~MF2_OBJECTFLIP
	end
end


local height_divisor = 3

local overlayZ = function(mo, overlaytype, flip)
	if flip --if we're flipped, our z position for the overlay should be close to middle of the player's sprite
		return (mo.z-FixedMul(mobjinfo[overlaytype].height, mo.scale+mo.scale/2)+(mo.height))+(mo.height/height_divisor) --but that's not very simple
		--(playerZPosition-(overlayHeight*1.5xPlayerScale)+PlayerHeight+(thirdOfPlayerHeight))
		--This shifts the original positioning downwards, so it aligns correctly with our player if we're gravflipped
	else --if we're not flipped, our z position for the overlay should be close to middle of the player's sprite
		return (mo.z)-(mo.height/height_divisor) --...and it's very simple
		--playerZPosition-thirdOfPlayerHeight
	end
end

local colortable = {
	[V_MAGENTAMAP] = SKINCOLOR_PITCHMAGENTA,
	[V_YELLOWMAP] = SKINCOLOR_PITCHYELLOW,
	[V_GREENMAP] = SKINCOLOR_PITCHGREEN,
	[V_BLUEMAP] = SKINCOLOR_PITCHBLUE,
	[V_REDMAP] = SKINCOLOR_PITCHRED,
	[V_GRAYMAP] = SKINCOLOR_PITCHGRAY,
	[V_ORANGEMAP] = SKINCOLOR_PITCHORANGE,
	[V_SKYMAP] = SKINCOLOR_PITCHSKY,
	[V_PURPLEMAP] = SKINCOLOR_PITCHPURPLE,
	[V_AQUAMAP] = SKINCOLOR_PITCHAQUA,
	[V_PERIDOTMAP] = SKINCOLOR_PITCHPERIDOT,
	[V_AZUREMAP] = SKINCOLOR_PITCHAZURE,
	[V_BROWNMAP] = SKINCOLOR_PITCHBROWN,
	[V_ROSYMAP] = SKINCOLOR_PITCHROSY
}

local dash_overlayVars = function(mo, player)
	applyFlip(player.mo, mo)
	--mo.scale = player.mo.scale+(player.mo.scale/2) --1.5x player scale
	mo.fuse = TICRATE/2 --Don't disappear immediately
	mo.tics = TICRATE/2
	mo.colorized = true --Colorize
	--mo.color = player.mo.color --Color
	mo.color = colortable[(pcall(do return skincolors[player.skincolor].chatcolor end) and skincolors[player.skincolor].chatcolor) or 0] or SKINCOLOR_PITCHWHITE --Color
	mo.sprite = player.mo.sprite --SPR_PLAY
	mo.skin = player.mo.skin --Player's skin
	mo.sprite2 = player.mo.sprite2 --Player's sprite
	mo.frame = player.mo.frame --Player's frame
	mo.angle = player.drawangle --Player's angle
	mo.blendmode = AST_ADD
	P_MoveOrigin(mo, player.mo.x, player.mo.y, overlayZ(player.mo, dash_mobjtype, (player.mo.flags2 & MF2_OBJECTFLIP)))--Keep teleporting to player
end

		
local dash_overlayOn = function(player, overlay, colorize, bool) --Choose to enable overlay or colorize, or both.
    if player.mo and player.mo.valid then
        if colorize then --Colorize?
            player.mo.colorized = true --Colorize.
			if not((player and displayplayer and B.MyTeam(player, displayplayer)) or (player == displayplayer) or (splitscreen and (player == secondarydisplayplayer))) then
				player.mo.renderflags = $|RF_FULLBRIGHT
			end
        end
        if not overlay then return end --Work here is done if that's all we're doing.
        if player.dashmode >= DASHMODE_THRESHOLD then --If we're still in dashmode
            if not (player.mo.dashmode_mobj and player.mo.dashmode_mobj.valid) then --If we don't have an overlay
                player.mo.dashmode_mobj = P_SpawnMobj(player.mo.x, player.mo.y, overlayZ(player.mo, dash_mobjtype, (player.mo.flags2 & MF2_OBJECTFLIP)), dash_mobjtype) --Spawn one
                dash_overlayVars(player.mo.dashmode_mobj, player) --Set Attributes and position
                player.mo.dashmode_mobj.tracer = player.mo --Set the tracer to the player's object
            end
        else --if not
            if player.mo.dashmode_mobj and player.mo.dashmode_mobj.valid --If we have an overlay
               -- P_RemoveMobj(player.mo.dashmode_mobj) --Remove overlay
               -- player.mo.dashmode_mobj = nil --Clear variable
                return --That's all folks
            end
        end
    end
end

local dash_overlayOff = function(player, overlay, colorize) --Only disable what we need disabled
    if player.mo and player.mo.valid then
        if colorize then --Colorize?
            player.mo.colorized = false --DeColorize.
			player.mo.renderflags = $ & ~(RF_FULLBRIGHT)
        end
        if not overlay then return end --Stop if that's all we need.
        if player.mo.dashmode_mobj and player.mo.dashmode_mobj.valid then --If we have an overlay
            if player.dashmode >= DASHMODE_THRESHOLD then --If we're still in dashmode
                dash_overlayVars(player.mo.dashmode_mobj, player) --Set Attributes and position
            else --if not
                --P_RemoveMobj(player.mo.dashmode_mobj) --Remove overlay
                --player.mo.dashmode_mobj = nil --Clear variable
                return --That's all folks
            end
        end
    end
end

--I decided to manually grow and shrink the sprite indeterminate of its actual scale

local dash_initscale = FRACUNIT*3/2 --Initial sprite scale
local dash_destscale = FRACUNIT*2 --Biggest scale for overlay
local dash_scalespeed = 10 --Scale speed for overlay. How many degrees to increment per frame
--360 deg = 1 whole cycle of the sin() function

local dash_pulseFunc = function(mo) --This function creates values that are added to the object's vars
	local eq = dash_initscale + FixedMul(dash_destscale-dash_initscale, abs(sin(leveltime*ANG1*dash_scalespeed)))
	mo.scale = eq
	mo.spriteyoffset = -(FRACUNIT + abs(eq))
end

local dash_overlayThink = function(mo) --MobjThinker
	if not(mo and mo.valid and mo.tracer and mo.tracer.valid and mo.tracer.player) or mo.dying then
		return
	end

	if displayplayer then
		if B.MyTeam(mo.tracer.player, displayplayer) or (mo.tracer.player == displayplayer) or (splitscreen and secondarydisplayplayer and (mo.tracer.player == secondarydisplayplayer)) then
			mo.flags2 = $|MF2_DONTDRAW
		end
	end
	dash_overlayVars(mo, mo.tracer.player)
	dash_pulseFunc(mo)
	if not(mo.tracer.player.dashmode >= DASHMODE_THRESHOLD) then
		mo.dying = true
		mo.momx = mo.tracer.momx/2
		mo.momy = mo.tracer.momy/2
		mo.momz = mo.tracer.momz/2
		mo.destscale = 0
		mo.scalespeed = FRACUNIT/10
		--P_RemoveMobj(mo)
		return
	end
end

local teamcolors = {
	[SKINCOLOR_ICY] = {SKINCOLOR_LEMON,SKINCOLOR_MINT},
	[SKINCOLOR_SKY] = {SKINCOLOR_GOLDENROD,SKINCOLOR_MASTER},
	[SKINCOLOR_CYAN] = {SKINCOLOR_TOPAZ,SKINCOLOR_EMERALD},
	[SKINCOLOR_WAVE] = {SKINCOLOR_TANGERINE,SKINCOLOR_SEAFOAM},
	[SKINCOLOR_TEAL] = {SKINCOLOR_APRICOT,SKINCOLOR_BOTTLE},
	[SKINCOLOR_AQUA] = {SKINCOLOR_SUNSET,SKINCOLOR_OCEAN},
	[SKINCOLOR_SEAFOAM] = {SKINCOLOR_KETCHUP,SKINCOLOR_WAVE},
	[SKINCOLOR_MINT] = {SKINCOLOR_FLAME,SKINCOLOR_AQUAMARINE},
	[SKINCOLOR_PERIDOT] = {SKINCOLOR_SALMON,SKINCOLOR_SKY},
	[SKINCOLOR_LIME] = {SKINCOLOR_PEPPER,SKINCOLOR_CORNFLOWER},
	[SKINCOLOR_YELLOW] = {SKINCOLOR_RUBY,SKINCOLOR_SAPPHIRE},
	[SKINCOLOR_SANDY] = {SKINCOLOR_CHERRY,SKINCOLOR_BLUE},
	[SKINCOLOR_GOLD] = {SKINCOLOR_RED,SKINCOLOR_COBALT},
	[SKINCOLOR_APRICOT] = {SKINCOLOR_CRIMSON,SKINCOLOR_CERULEAN},
	[SKINCOLOR_SUNSET] = {SKINCOLOR_VOLCANIC,SKINCOLOR_MIDNIGHT}
}


local dash_colorizer = function(player) --Colorizes dashmode users that would show the orange flash instead of colorizing (PostThinkFrame)
	if not(player and player.mo and player.mo.valid) then return end

	if player.dashmode >= DASHMODE_THRESHOLD and (player.charflags & SF_DASHMODE) and (player.charflags & SF_MACHINE) and ((leveltime/2) & 1) then --if we're flashing & a dashmode machine
		dash_overlayOn(player, false, true) --Colorize
		player.mo.dash_colorize = true --Mark as colorized
	elseif player.mo.dash_colorize then --if we're not, and we're marked as colorized
		dash_overlayOff(player, false, true) --DeColorize
		player.mo.dash_colorize = false --Mark as not colorized
	end
end


local dash_sfxThink = function(player) --Dashmode SFX
	if not(player and player.mo and player.mo.valid) then return end

	if player.dashmode >= DASHMODE_THRESHOLD then --Dashing
		if not(S_SoundPlaying(player.mo, sfx_dashe)) then
			B.teamSound(player.mo, player, sfx_nullba, sfx_dashe, dash_sfxvol, false)
		end
	elseif (S_SoundPlaying(player.mo, sfx_dashe)) then
		S_StopSoundByID(player.mo, sfx_dashe)
	end
end

local dash_overlaySpawner = function(player) --PreThinkFrame prefferably
	if player.dashmode >= DASHMODE_THRESHOLD and (player.charflags & SF_DASHMODE) then --If we're flashing and have dashmode
		dash_overlayOn(player, true, false) --Spawn Overlay
	else
		dash_overlayOff(player, true, false) --Remove Overlay
	end
end

local dash_resetter = function(player) --Makes dashmode start from the beginning if it ends
	if player.mo and player.mo.valid and (B.GetSkinVarsFlags(player) & SKINVARS_DASHMODENERF) then
	
		local dashing = (player.dashmode >= DASHMODE_THRESHOLD)
		local decreasing = ((player.dashmode < DASHMODE_THRESHOLD) and player.mo.dashmode_reached)
		local dashing_marked = player.mo.dashmode_reached
		local charging_marked = player.mo.dashmode_charging
		local launched_marked = player.mo.dashmode_launch
		local spindashing = (player.pflags & PF_STARTDASH)
		local charging = spindashing and not(dashing)

		local dashmode_limit = skins[player.mo.skin].normalspeed+(skins[player.mo.skin].normalspeed/3)
		

		if charging then
			player.mo.dashmode_charging = true
		end
		
		if dashing then
			player.mo.dashmode_reached = true --Mark it

			if (player.normalspeed+(FRACUNIT/5) >= dashmode_limit) then
				player.normalspeed = dashmode_limit

				if not(leveltime%3) then
					local ghost = P_SpawnGhostMobj(player.mo)
					if ghost and ghost.valid then
						ghost.colorized = true
						ghost.fuse = 10
						ghost.blendmode = AST_ADD
					end
				end
			end

			if not(spindashing) then
				player.mo.dashmode_launch = true
			end
		end
		
		if charging_marked and dashing and not(spindashing) then
			player.mo.dashmode_launch = true
		end
		
		if not(spindashing) and not(dashing) then
			player.mo.dashmode_charging = nil
		end
		
		if spindashing and dashing and launched_marked then
			decreasing = true
		end
		
		if decreasing then --Dashmode is decreasing?
			player.dashmode = 0
			player.mo.dashmode_reached = nil --Unmark
			player.mo.dashmode_launch = nil
			player.powers[pw_strong] = $ & ~(STR_METAL)
			player.normalspeed = skins[player.mo.skin].normalspeed
		end
	end
end

--PostThinkFrame (player)
B.DashmodeColorizer = dash_colorizer 

--PreThinkFrame (player)
B.DashmodeResetter = dash_resetter
B.DashmodeSFXPlayer = dash_sfxThink
B.DashmodeOverlaySpawner = dash_overlaySpawner

--MobjThinker MT_DASHMODE_OVERLAY
B.DashmodeOverlayThink = dash_overlayThink
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

local dash_overlayVars = function(mo, player)
	applyFlip(player.mo, mo)
	mo.scale = player.mo.scale+(player.mo.scale/2) --1.5x player scale
	mo.fuse = -1 --Don't disappear
	mo.colorized = true --Colorize
	mo.color = player.mo.color --Color
	mo.sprite = player.mo.sprite --SPR_PLAY
	mo.skin = player.mo.skin --Player's skin
	mo.sprite2 = player.mo.sprite2 --Player's sprite
	mo.frame = player.mo.frame|FF_TRANS30 --Player's frame
	mo.angle = player.drawangle --Player's angle
	P_MoveOrigin(mo, player.mo.x, player.mo.y, overlayZ(player.mo, dash_mobjtype, (player.mo.flags2 & MF2_OBJECTFLIP)))--Keep teleporting to player
end

		
local dash_overlayOn = function(player, overlay, colorize, bool) --Choose to enable overlay or colorize, or both.
    if player.mo and player.mo.valid then
        if colorize then --Colorize?
            player.mo.colorized = true --Colorize.
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
                P_RemoveMobj(player.mo.dashmode_mobj) --Remove overlay
                player.mo.dashmode_mobj = nil --Clear variable
                return --That's all folks
            end
        end
    end
end

local dash_overlayOff = function(player, overlay, colorize) --Only disable what we need disabled
    if player.mo and player.mo.valid then
        if colorize then --Colorize?
            player.mo.colorized = false --DeColorize.
        end
        if not overlay then return end --Stop if that's all we need.
        if player.mo.dashmode_mobj and player.mo.dashmode_mobj.valid then --If we have an overlay
            if player.dashmode >= DASHMODE_THRESHOLD then --If we're still in dashmode
                dash_overlayVars(player.mo.dashmode_mobj, player) --Set Attributes and position
            else --if not
                P_RemoveMobj(player.mo.dashmode_mobj) --Remove overlay
                player.mo.dashmode_mobj = nil --Clear variable
                return --That's all folks
            end
        end
    end
end

--I decided to manually grow and shrink the sprite indeterminate of its actual scale

local dash_initscale = FRACUNIT --Initial sprite scale
local dash_destscale = FRACUNIT+(FRACUNIT/8) --Biggest scale for overlay
local dash_scalespeed = FRACUNIT/45 --Scale speed for overlay (using spritexscale & spriteyscale)

local dash_pulseFunc = function(mo) --This function creates values that are added to the object's vars
	mo.metalsonic_dashpulse = $ or 0
	
	if mo.metalsonic_dashpulse == dash_destscale then
		mo.metalsonic_dashpulse = dash_initscale
	else
		mo.metalsonic_dashpulse = $+dash_scalespeed
	end
	
	mo.spritexscale = $+mo.metalsonic_dashpulse
	mo.spriteyscale = $+mo.metalsonic_dashpulse
	mo.spriteyoffset = $-(mo.metalsonic_dashpulse*12)
end

local dash_overlayThink = function(mo) --MobjThinker
	if mo and mo.valid and mo.tracer and mo.tracer.valid and mo.tracer.player then
		dash_overlayVars(mo, mo.tracer.player)
		dash_pulseFunc(mo)
		if not(mo.tracer.player.dashmode >= DASHMODE_THRESHOLD) then
			P_RemoveMobj(mo)
			return
		end
	else
		return
	end
end

local dash_colorizer = function(player) --Colorizes dashmode users that would show the orange flash instead of colorizing (PostThinkFrame)
	if player.dashmode >= DASHMODE_THRESHOLD and (player.charflags & SF_DASHMODE) and (player.charflags & SF_MACHINE) and ((leveltime/2) & 1) then --if we're flashing & a dashmode machine
		dash_overlayOn(player, false, true) --Colorize
		player.dash_colorize = true --Mark as colorized
	else --if we're not
		if player.dash_colorize then --If we're marked as colorized
			dash_overlayOff(player, false, true) --DeColorize
			player.dash_colorize = false --Mark as not colorized
		end
	end
end


local dash_sfxThink = function(player) --Dashmode SFX
	if player.dashmode >= DASHMODE_THRESHOLD then --Dashing
		for p in players.iterate do 
			if p.mo and p.mo.valid then
				if (p == player) or B.MyTeam(player, p) or (not P_CheckSight(p.mo, player.mo)) then
					--If you're the player in question, on the same team as the player in question, or the player in question isn't checksight visible
					continue --Halt
				end
				if not S_SoundPlaying(player.mo, dash_sfx) then --If the sound isn't already playing
					S_StartSoundAtVolume(player.mo, dash_sfx, dash_sfxvol, p) --Play the sound (not too loud though)
				end
			end
		end
	else
		if player.mo and player.mo.valid then
			if S_SoundPlaying(player.mo, dash_sfx) then --If the sound is playing for some reason
				S_StopSoundByID(player.mo, dash_sfx) --Stop it
			end
		end
	end
end

local dash_overlaySpawner = function(player) --PreThinkFrame prefferably
	if player.dashmode >= DASHMODE_THRESHOLD and (player.charflags & SF_DASHMODE) and ((leveltime/2) & 1) then --If we're flashing and have dashmode
		dash_overlayOn(player, true, false) --Spawn Overlay
	else
		dash_overlayOff(player, true, false) --Remove Overlay
	end
end

local dash_resetter = function(player) --Makes dashmode start from the beginning if it ends
	if player.dashmode >= DASHMODE_THRESHOLD then --Dashing?
		player.dashmode_reached = true --Mark it
	end
	
	if (player.dashmode < DASHMODE_THRESHOLD) and player.dashmode_reached then --Dashmode is decreasing?
		player.dashmode = 0 --Start from 0
		player.dashmode_reached = nil --Unmark
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
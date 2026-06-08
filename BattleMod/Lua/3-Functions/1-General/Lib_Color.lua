local B = CBW_Battle
B.FlashColor = function(colormin,colormax)
	local N = 32 //Rate of oscillation
-- 	local size = colormax-colormin+1 //Color spectrum
	local scale = 2 //Factor-amount to reduce the oscillation intensity
	local offset = 0 //Offset the origin of oscillation
	local oscillate = abs((leveltime&(N*2-1))-N)/scale //Oscillation cycle
	local c = colormin+oscillate+offset //offset
	c = max(colormin,min(colormax,$)) //Enforce min/max
	return c
end

B.FlashRainbow = function(mo)
	local t = (leveltime&15)>>2
	if t == 0 then return B.FlashColor(SKINCOLOR_SUPERGOLD1,SKINCOLOR_SUPERGOLD5) end
	if t == 1 then return B.FlashColor(SKINCOLOR_SUPERSKY1,SKINCOLOR_SUPERSKY5) end
	if t == 2 then return B.FlashColor(SKINCOLOR_SUPERTAN1,SKINCOLOR_SUPERTAN5) end
	if t == 3 then return B.FlashColor(SKINCOLOR_SUPERSILVER1,SKINCOLOR_SUPERSILVER5) end
end

B.ApplyFlip = function(mo1, mo2)
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

local overlayZ = function(mo, overlaytype, flip)
	if flip then
		return mo.z+(mo.height)
	else
		return mo.z
	end
end

function B.SpawnGhostForMobj(mobj,colorize)
	local ghost = P_SpawnMobjFromMobj(mobj, 0, 0, 0, MT_GHOST)
	ghost.fuse = TICRATE/4
	ghost.color = mobj.color
	ghost.state = mobj.state
	ghost.sprite = mobj.sprite
	ghost.angle = mobj.angle
	ghost.frame =  mobj.frame
	ghost.frame = $|TR_TRANS50 
	if colorize then
		ghost.colorized = colorize
	end
	if mobj.flags&MF2_SPLAT then
		ghost.flags2 = $|MF2_SPLAT
		ghost.renderflags = RF_SLOPESPLAT|RF_NOSPLATBILLBOARD
		P_CreateFloorSpriteSlope(ghost)
		ghost.floorspriteslope = mobj.floorspriteslope
	end
	
	return ghost
end

function B.SpawnFlash(mo, tics, circle)

	local fmo

	if mo.player then
		fmo = mo.player.followmobj
	end

	local mainflash = P_SpawnGhostMobj(mo, 0,0,0, MT_THOK)
	mainflash.fuse = tics or mobjinfo[MT_THOK].tics
	mainflash.target = mo
	mainflash.dispoffset = 2
	mainflash.renderflags = $|RF_FULLBRIGHT
	--Toggle Colorized
	if mo.colorized then
		mainflash.colorized = false
	else
		mainflash.colorized = true
	end

	if mo.blendmode == AST_ADD then
		mainflash.blendmode = AST_COPY
	else
		mainflash.blendmode = AST_ADD
	end

	local subflash

	if fmo and fmo.valid then

		local subflash = P_SpawnGhostMobj(mo, 0,0,0, MT_THOK)
		subflash.fuse = tics or mobjinfo[MT_THOK].tics
		subflash.target = fmo
		subflash.dispoffset = 2
		subflash.renderflags = $|RF_FULLBRIGHT
		--Toggle Colorized
		if fmo.colorized then
			subflash.colorized = false
		else
			subflash.colorized = true
		end
		

		--Toggle additive blending
		if fmo.blendmode == AST_ADD then
			subflash.blendmode = AST_COPY
		else
			subflash.blendmode = AST_ADD
		end
	end

	if circle then
		local circle = P_SpawnMobj(mo.x, mo.y,overlayZ(mo, MT_THOK, (mo.flags2 & MF2_OBJECTFLIP)), MT_THOK)
		B.ApplyFlip(mo, circle)
		circle.sprite = SPR_STAB
		circle.frame =  _G["A"]
		--circle.angle = mo.angle + ANGLE_90
		circle.renderflags = $|RF_FULLBRIGHT
		circle.fuse = 7
		circle.scale = mo.scale / 3
		circle.destscale = 10*mo.scale
		circle.scalespeed = mo.scale/12
		circle.colorized = true
		circle.blendmode = AST_OVERLAY
		circle.color = mo.color
		circle.momx = -mo.momx / 2
		circle.momy = -mo.momy / 2
	end

	if subflash then
		return mainflash, subflash
	else
		return mainflash
	end
end 

B.TextFlash = function(text, reset, player)
	local colors = {"\x81","\x88"}

	local bin = 0

	if (leveltime/3) % 2 then
		bin = 1
	end

	if (reset) then
		player.textflash_flashing = false
		return text and text:sub(2)
	else
		assert(text, "Text must be provided if not resetting!")
		if player then
			player.textflash_flashing = true
		end
		return (colors[bin+1]..text.."\x80")
	end
end
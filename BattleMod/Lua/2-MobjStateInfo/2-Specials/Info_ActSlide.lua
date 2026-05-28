freeslot(
	'spr_flob',
	's_fangchar_lob1',
	's_fangchar_lob2',
	's_fangchar_lob3',
	's_fang_slide',
	's_fang_springdrop',
	'spr_cbom',
	's_colorbomb1',
	's_colorbomb2',

	-- hi saxa here
	'mt_fangreticle',
	's_fangreticle_circle',
	's_fangreticle_point',
	'spr_fang_reticle',
	'sfx_fn_trg'
)

sfxinfo[sfx_fn_trg].caption = "Clocked back gun"

states[S_FANG_SPRINGDROP] = {
	sprite = SPR_PLAY,
	frame = SPR2_LAND,
	tics = -1,
	var2 = PF_BOUNCING,
	nextstate = S_FANG_SPRINGDROP,
	action = function(mo) mo.player.panim = PA_ABILITY end
}

states[S_FANG_SLIDE] = {
	sprite = SPR_PLAY,
	frame = SPR2_FLY_,
	tics = -1,
	nextstate = S_PLAY_STND,
	action = function(mo) mo.player.panim = PA_ROLL end
}

//Fang lob animation
states[S_FANGCHAR_LOB1] = {
	sprite = SPR_FLOB,
	frame = A
}

states[S_FANGCHAR_LOB2] = {
	sprite = SPR_FLOB,
	frame = B
}

states[S_FANGCHAR_LOB3] = {
	sprite = SPR_FLOB,
	frame = C
}

//overwritting some bomb states to prevent it from using A_GhostMe
states[S_FBOMB1] = {
	sprite = SPR_FBOM,
	frame = A,
	tics = 1,
	nextstate = S_FBOMB2
}

states[S_FBOMB2] = {
	sprite = SPR_FBOM,
	frame = B,
	tics = 1,
	nextstate = S_FBOMB1
}

//Fang's team-colored bomb

states[S_COLORBOMB1] = {
	sprite = SPR_CBOM,
	frame = A,
	tics = 1,
	nextstate = S_COLORBOMB2
}

states[S_COLORBOMB2] = {
	sprite = SPR_CBOM,
	frame = B,
	tics = 1,
	nextstate = S_COLORBOMB1
}

states[S_FBOMB_EXPL2] = {
	sprite = SPR_BARX,
	frame = 1|FF_FULLBRIGHT,
	tics = 2,
	nextstate = S_FBOMB_EXPL3
}

// the RETICLEEEEEE
mobjinfo[MT_FANGRETICLE] = {
	radius = FU,
	height = FU,
	flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_NOBLOCKMAP,
	spawnstate = S_FANGRETICLE_CIRCLE,
	dispoffset = 1
}

states[S_FANGRETICLE_CIRCLE] = {
	sprite = SPR_FANG_RETICLE,
	frame = A|FF_FULLBRIGHT,
	tics = -1
}

states[S_FANGRETICLE_POINT] = {
	sprite = SPR_FANG_RETICLE,
	frame = B|FF_FULLBRIGHT,
	tics = -1
}

local reticles = {} -- a bit of a hack to manage it better

local function _managePoint(reticle)
	if not reticle.point
	or not reticle.point.valid then
		reticle.point = P_SpawnMobjFromMobj(reticle, 0,0,0, MT_THOK)
		reticle.point.state = S_INVISIBLE
		reticle.point.fuse = -1
		reticle.point.tics = -1
	end

	local move = P_MoveOrigin

	if reticle.point.state == S_INVISIBLE then
		move = P_SetOrigin
	end

	move(reticle.point, reticle.x, reticle.y, reticle.z)
	reticle.point.dispoffset = reticle.dispoffset+1 -- always display higher
	reticle.point.scale = reticle.scale
	reticle.point.spriteroll = (leveltime * 4) * ANG1
	reticle.point.alpha = reticle.alpha
	reticle.point.color = reticle.pointcolor
	if reticle.point.state ~= S_FANGRETICLE_POINT then
		reticle.point.state = S_FANGRETICLE_POINT
	end
	if reticle.point.state == S_FANGRETICLE_POINT then
		reticle.point.frame = (reticle.frame & ~FF_FRAMEMASK)|(reticle.point.frame & FF_FRAMEMASK)
	end
end

addHook("MobjSpawn", function(reticle)
	reticle.pointcolor = reticle.color
	_managePoint(reticle)
	table.insert(reticles, reticle)
end, MT_FANGRETICLE)

addHook("PostThinkFrame", function()
	for i = 1, #reticles do
		local reticle = reticles[i]

		if not reticle
		or not reticle.valid then
			table.remove(reticles, i)
			continue
		end

		_managePoint(reticle)
	end
end)

addHook("MobjRemoved", function(reticle)
	if reticle.point and reticle.point.valid then
		P_RemoveMobj(reticle.point)
		reticle.point = nil
	end
end, MT_FANGRETICLE)

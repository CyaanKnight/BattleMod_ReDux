freeslot("MT_RINGSPARKAURA",
		 "SPR_RSPF",
		 "SPR_RSPA",
		 "S_RINGSPARKAURA",
		 "S_METALSONIC_RINGSPARK1",
		 "S_METALSONIC_RINGSPARK2",
		 "S_METALSONIC_RINGSPARK3"
)

local ringteam = freeslot("sfx_rgspkt")
local ringenemy = freeslot("sfx_rgspke")
local clawteam = freeslot("sfx_hclwt")
local clawenemy = freeslot("sfx_hclwe")

mobjinfo[MT_RINGSPARKAURA] = {
	doomednum = -1,
	spawnstate = S_RINGSPARKAURA,
	spawnhealth = 1000,
	reactiontime = 8,
	radius = FRACUNIT,
	height = FRACUNIT,
	mass = 16,
	dispoffset = mobjinfo[MT_PLAYER].dispoffset+1,
	flags = MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP|MF_SCENERY,
	name = "ring spark field" --Just in case
}

states[S_RINGSPARKAURA] = {SPR_RSPA, A|FF_ANIMATE|FF_FULLBRIGHT, -1, nil, 1, 4, S_NULL}

states[S_METALSONIC_RINGSPARK1] = {
	sprite = SPR_PLAY,
	frame = SPR2_FLY_|A,
	tics = -1
}

states[S_METALSONIC_RINGSPARK2] = {
	sprite = SPR_PLAY,
	frame = SPR2_FLY_|FF_ANIMATE|A,
	tics = -1,
	nextstate = S_PLAY_STND,
	var1 = 1,
	var2 = 2
}



--states[S_METALSONIC_RINGSPARK1] = {SPR_PLAY, SPR2_RSPF|A, 17, nil, nil, 1, S_METALSONIC_RINGSPARK2} --sfx_monton
--states[S_METALSONIC_RINGSPARK2] = {SPR_PLAY, SPR2_RSPF|FF_ANIMATE|FF_FULLBRIGHT, 5*TICRATE, nil, nil, 1, S_METALSONIC_RINGSPARK3} --sfx_s3k40
--states[S_METALSONIC_RINGSPARK3] = {SPR_PLAY, SPR2_RSPF, 1, nil, nil, 1, S_PLAY_STND} --sfx_kc56


--spr2defaults[SPR2_RSPF] = SPR2_SPNG

sfxinfo[sfx_hclwe].caption = "\x82".."DASH SLICER CLAW".."\x80"
sfxinfo[sfx_hclwt].caption = "Dash Slicer Claw"

sfxinfo[sfx_rgspke].caption = "\x82".."RING SPARK FIELD".."\x80"
sfxinfo[sfx_rgspkt].caption = "Ring Spark Field"
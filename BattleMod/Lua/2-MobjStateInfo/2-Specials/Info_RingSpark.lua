freeslot("MT_RINGSPARKAURA",
		 "SPR_RSPA",
		 "S_RINGSPARKAURA",
		 "SPR2_RSPF",
		 "S_METALSONIC_RINGSPARK1",
		 "S_METALSONIC_RINGSPARK2",
		 "S_METALSONIC_RINGSPARK3"
)

local ring = freeslot("sfx_rngspk")
local claw = freeslot("sfx_dshclw")

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


states[S_METALSONIC_RINGSPARK1] = {SPR_PLAY, SPR2_RSPF|A, 17, nil, nil, 1, S_METALSONIC_RINGSPARK2} --sfx_monton
states[S_METALSONIC_RINGSPARK2] = {SPR_PLAY, SPR2_RSPF|FF_ANIMATE|FF_FULLBRIGHT, 5*TICRATE, nil, nil, 1, S_METALSONIC_RINGSPARK3} --sfx_s3k40
states[S_METALSONIC_RINGSPARK3] = {SPR_PLAY, SPR2_RSPF, 1, nil, nil, 1, S_PLAY_WALK} --sfx_kc56


spr2defaults[SPR2_RSPF] = SPR2_SPNG

sfxinfo[claw].caption = "\x8C".."DASH SLICER CLAW".."\x80"

sfxinfo[ring].caption = "\x82".."RING SPARK FIELD".."\x80"
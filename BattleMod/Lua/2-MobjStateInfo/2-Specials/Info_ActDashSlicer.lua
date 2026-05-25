freeslot(
	'mt_dashslicer',
	'mt_slash',
	's_slash1',
	's_slash2',
	's_slash3',
	's_slash4',
	'spr_slsh'
)

//Metal Sonic's Dash Slicer object

mobjinfo[MT_DASHSLICER] = {
	spawnstate = S_ENERGYBALL1,
-- 	spawnstate = 1,
	spawnhealth = 1000,
	reactiontime = 8,
	speed = 55*FRACUNIT,
	radius = 48*FRACUNIT,
	height = 48*FRACUNIT,
	mass = 0,
	damage = 0,
	flags = MF_NOGRAVITY|MF_NOBLOCKMAP|MF_MISSILE|MF_NOCLIPTHING|MF_NOSECTOR
}
mobjinfo[MT_DASHSLICER].donotwaterslow = true


//The Slashes
mobjinfo[MT_SLASH] = {
	spawnstate = S_SLASH1,
-- 	spawnstate = 1,
	spawnhealth = 1000,
	reactiontime = 8,
	speed = FRACUNIT,
	radius = 12*FRACUNIT,
	height = 48*FRACUNIT,
	mass = 0,
	damage = 0,
	flags = MF_NOGRAVITY|MF_NOBLOCKMAP|MF_MISSILE|MF_NOCLIPHEIGHT
}
mobjinfo[MT_SLASH].donotwaterslow = true

states[S_SLASH1] = {
	sprite = SPR_SLSH,
	frame = A,
	tics = 5,
	nextstate = S_SLASH2
}

states[S_SLASH2] = {
	sprite = SPR_SLSH,
	frame = B,
	tics = 8,
	nextstate = S_NULL
}

states[S_SLASH3] = {
	sprite = SPR_SLSH,
	frame = C,
	tics = 5,
	nextstate = S_SLASH4
}

states[S_SLASH4] = {
	sprite = SPR_SLSH,
	frame = D,
	tics = 8,
	nextstate = S_NULL
}
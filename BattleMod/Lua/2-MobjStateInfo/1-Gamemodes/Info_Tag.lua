freeslot('mt_tagginghand')
//Tagging hand object
mobjinfo[MT_TAGGINGHAND] = {
	spawnstate = 1,
	height = 32*FRACUNIT,
	radius = 24*FRACUNIT,
	flags = MF_NOGRAVITY|MF_MISSILE|MF_NOSECTOR
}

//funni sound effect
freeslot("sfx_tgrlsd")
freeslot("sfx_crng2")
sfxinfo[sfx_crng2].caption = "Radar"
sfxinfo[sfx_tgrlsd].caption = "Taggers are released..."

//little indicator that hovers over taggers in battle tag
freeslot("SPR_TPTR", "S_BATTLETAG_IT", "S_BTAG_POINTER", "MT_BATTLETAG_IT", 
		"MT_BTAG_POINTER")
states[S_BATTLETAG_IT] = {
	sprite = SPR_TTAG,
	frame = FF_FULLBRIGHT | A,
	tics = -1,
	nextstate = S_BATTLETAG_IT
}
states[S_BTAG_POINTER] = {
	sprite = SPR_TPTR,
	frame = FF_FULLBRIGHT | A,
	tics = -1,
	nextstate = S_BTAG_POINTER
}
mobjinfo[MT_BATTLETAG_IT] = {
	spawnstate = S_BATTLETAG_IT,
	height = 10 * FRACUNIT,
	radius = 5 * FRACUNIT,
	dispoffset = 1,
	flags = MF_NOCLIP | MF_NOCLIPHEIGHT | MF_SCENERY | MF_NOGRAVITY
}
mobjinfo[MT_BTAG_POINTER] = {
	spawnstate = S_BTAG_POINTER,
	spawnhealth = 1,
	seestate = S_BTAG_POINTER,
	speed = 0,
	radius = 5 * FRACUNIT,
	height = 10 * FRACUNIT,
	flags = MF_NOCLIP | MF_NOGRAVITY | MF_SCENERY | MF_NOCLIPHEIGHT | MF_NOSECTOR
}
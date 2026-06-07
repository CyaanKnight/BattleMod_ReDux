freeslot(
	's_tails_swipe',
	's_tails_spinswipe1',
	's_tails_spinswipe2',
	's_tails_pounce',
	'spr_tswp',
	'spr_pnce'
)
states[S_TAILS_SWIPE] = {
	sprite = SPR_TSWP,
	frame = A,
	tics = 0,
	nextstate = S_PLAY_FALL
}
states[S_TAILS_POUNCE] = {
	sprite = SPR_PNCE,
	frame = A,
	tics = 0,
	nextstate = S_PLAY_FALL
}

-- it should at least look correct for the player
function A_BMTailsAngle(actor)
	if actor and actor.valid and actor.player then
		local player = actor.player
		local angle = actor.angle
		if player.pflags & PF_ANALOGMODE then
			angle = (player.cmd.angleturn<<16)
		end
		player.drawangle = angle+ANGLE_90
		actor.state = S_PLAY_FALL
	end
end
		

states[S_TAILS_SPINSWIPE1] = {
	sprite = SPR_TSWP,
	frame = B|FF_ANIMATE,
	tics = 14,
	var1 = 6,
	var2 = 2,
	nextstate = S_TAILS_SPINSWIPE2
}

states[S_TAILS_SPINSWIPE2] = {
	sprite = SPR_TSWP,
	frame = H,
	tics = 0,
	action = A_BMTailsAngle
}

freeslot(
	'mt_sonicboom',
	'spr_guil',
	's_sonicboom1',
	's_sonicboom2',
	's_sonicboom3',
	's_sonicboom4'
)
mobjinfo[MT_SONICBOOM] = {
	spawnstate = S_SONICBOOM1,
	speed = 28*FRACUNIT,
	radius = 8*FRACUNIT,
	height = 8*FRACUNIT,
	mass = 0,
	damage = 0,
	flags = MF_SPECIAL|MF_NOGRAVITY|MF_NOBLOCKMAP|MF_SLIDEME|MF_GRENADEBOUNCE
}
states[S_SONICBOOM1] = {
	sprite = SPR_GUIL,
	frame = A|FF_FULLBRIGHT,
	tics = 1,
	nextstate = S_SONICBOOM2
}
states[S_SONICBOOM2] = {
	sprite = SPR_GUIL,
	frame = B|FF_FULLBRIGHT,
	tics = 1,
	nextstate = S_SONICBOOM3
}
states[S_SONICBOOM3] = {
	sprite = SPR_GUIL,
	frame = C|FF_FULLBRIGHT,
	tics = 1,
	nextstate = S_SONICBOOM4
}
states[S_SONICBOOM4] = {
	sprite = SPR_GUIL,
	frame = D|FF_FULLBRIGHT,
	tics = 1,
	nextstate = S_SONICBOOM1
}
freeslot('sfx_charge',
		 'sfx_chargt',
		 'sfx_tswie',
		 'sfx_tswit'
)
sfxinfo[sfx_charge].caption = "\x82".."TAIL SWEEP CHARGE".."\x80"
sfxinfo[sfx_chargt].caption = "Tail Sweep Charge"

sfxinfo[sfx_tswie].caption = "\x82".."TAIL SWIPE READY".."\x80"
sfxinfo[sfx_tswit].caption = "Tail Swipe Ready"
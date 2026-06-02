local B = CBW_Battle

states[freeslot("S_HUMMINGTOP")] = {
	sprite = freeslot("SPR_HUMMINGTOP"),
	frame = FF_FULLBRIGHT|FF_ANIMATE|_G["A"],
	var1 = 7,
	var2 = 1,
	tics = -1,
	nextstate = S_NULL
}

sfxinfo[freeslot("sfx_htop")].caption = "Humming Top"
sfxinfo[freeslot("sfx_htok")].caption = "Humming Top Clash"

spr2defaults[freeslot("SPR2_TRIK")] = SPR2_SKID

states[freeslot("S_SONIC_HUMMINGTOP")] = {
	sprite = SPR_PLAY,
	frame = SPR2_TRIK|A,
	tics = -1
}

B.Sonic_RECURLCOOLDOWN = 10

spr2defaults[freeslot("SPR2_DRPD")] = SPR2_DASH
states[freeslot("S_PLAY_DROPDASH")] = {
	sprite = SPR_PLAY,
	frame = SPR2_DRPD|FF_SPR2ENDSTATE,
	var1 = S_PLAY_DROPDASH
}

--Assign sprites, objects, and sfx
freeslot(
	"SPR_REBO",
	"MT_REBOUND",
	"S_REBOUND",
	"sfx_bounc1",
	"sfx_bounc2"
)


sfxinfo[sfx_bounc1] = {
	singular = false,
	caption = "Rebound"
}
sfxinfo[sfx_bounc2] = {
	singular = false,
	caption = "Heavy Rebound"
}

--Wallbounce ring effect object
mobjinfo[MT_REBOUND] = {
	doomednum = -1,
	spawnstate = S_REBOUND,
	flags = MF_NOCLIP|MF_SCENERY|MF_NOGRAVITY
}
states[S_REBOUND] = {
	sprite = SPR_REBO,
	frame = TR_TRANS50|FF_PAPERSPRITE|A
}

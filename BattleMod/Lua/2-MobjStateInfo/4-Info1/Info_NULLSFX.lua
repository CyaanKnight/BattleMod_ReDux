

sfxinfo[freeslot("sfx_nullba")].caption = "/" --Generic Mute SFX with no caption


sfxinfo[freeslot("sfx_flgcab")].caption = sfxinfo[sfx_flgcap].caption --sfx_flagcap clone
sfxinfo[sfx_flgcap].caption = "/" --Null out caption
rawset(_G, "sfx_flgcap", sfx_flgcab)

sfxinfo[freeslot("sfx_loseb")].caption = sfxinfo[sfx_lose].caption --sfx_lose clone
sfxinfo[sfx_lose].caption = "/" --Null out caption
rawset(_G, "sfx_lose", sfx_loseb)

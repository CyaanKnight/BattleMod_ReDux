local B = CBW_Battle
local S = B.SkinVars
local Act = B.Action
local G = B.GuardFunc
S[-1] = {
	flags = SKINVARS_GUARD,
	weight = 100,
	shields = 1,
	special = nil,
	special_playerthink = nil,
	special_thinkframe = nil,
-- 	guard_enabled = true, //Deprecated
	guard_frame = 2,
	func_guard_trigger = G.Parry,
	func_priority = B.Priority_FullCommon,
	func_priority_ext = nil,
	func_precollide = nil,
	func_collide = nil,
	func_postcollide = nil,
	func_exhaust = nil,
	func_ledgegrab = nil,
	sprites = {},
	supersprites = false,
	noledgegrab = false,
	momentum = 0
}
S["sonic"] = {
	flags = SKINVARS_GUARD|SKINVARS_HUMMINGTOP,
	weight = 100, 
	special = Act.SuperSpinJump,
	guard_frame = 2,
	func_priority_ext = Act.SuperSpinJump_Priority,
	func_precollide = B.Sonic_PreCollide,
	func_collide = B.Sonic_Collide,
	func_postcollide = B.Sonic_PostCollide,
	sprites = {},
	supersprites = true,
	momentum = TICRATE
}
S["tails"] = {
	weight = 80,
	special = Act.TailSwipe,
	guard_frame = 2,
	func_priority_ext = Act.TailSwipe_Priority,
	func_precollide = B.Tails_PreCollide,
	func_collide = B.Tails_Collide,
	func_postcollide = B.Tails_PostCollide,
	sprites = {
		S_TAILS_SWIPE,
		S_TAILS_POUNCE
	}
}
S["knuckles"] = {
	flags = SKINVARS_GUARD|SKINVARS_GLIDESTRAFE|SKINVARS_GLIDESOUND,
	weight = 120,
	special = Act.Dig,
	guard_frame = 2,
	func_priority_ext = Act.Dig_Priority,
	func_precollide = B.Knuckles_PreCollide,
	func_collide = B.Knuckles_Collide,
	func_postcollide = B.Knuckles_PostCollide,
	sprites = {
		S_KNUCKLES_DRILLDIVE1,
		S_KNUCKLES_DRILLDIVE2,
		S_KNUCKLES_DRILLDIVE3,
		S_KNUCKLES_DRILLDIVE4,
		S_KNUCKLES_DRILLRISE1,
		S_KNUCKLES_DRILLRISE2,
		S_KNUCKLES_DRILLRISE3,
		S_KNUCKLES_DRILLRISE4
	}
}
S["amy"] = {
	flags = SKINVARS_GUARD|SKINVARS_ROSY|SKINVARS_NOSPINSHIELD,
	weight = 110,
	special = Act.PikoTornado,
	guard_frame = 1,
	func_priority_ext = Act.PikoTornado_Priority,
	sprites = {}
}
S["fang"] = {
	flags = SKINVARS_GUARD|SKINVARS_NOSPINSHIELD|SKINVARS_GUNSLINGER,
	weight = 90,
	special = Act.Slide,
	guard_frame = 1,
	func_priority_ext = Act.Slide_Priority,
	func_precollide = B.Fang_PreCollide,
	func_collide = B.Fang_Collide,
	func_postcollide = B.Fang_PostCollide,
	sprites = {}	
}
S["metalsonic"] = {
	flags = SKINVARS_GUARD|SKINVARS_DASHMODENERF,
	weight = 110,
	special = Act.EnergyAttack,
	guard_frame = 2,
	func_priority_ext = Act.EnergyAttack_Priority,
	sprites = {
		S_METALSONIC_RINGSPARK1,
		S_METALSONIC_RINGSPARK2
	}
}

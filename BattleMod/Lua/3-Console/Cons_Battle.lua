local CV = CBW_Battle.Console
//Battle Variables
CV.Collision = CV_RegisterVar{
	name = "battle_collision",
	defaultvalue = 0,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}

CV.CollisionTimer = CV_RegisterVar{
	name = "battle_collisiontimer",
	defaultvalue = 12,
	flags = CV_NETVAR,
	PossibleValue = {MIN = 1, MAX = 105}
}

CV.LaunchFactor = CV_RegisterVar{
	name = "battle_launchfactor",
	defaultvalue = 7,
	flags = CV_NETVAR,
	PossibleValue = {MIN = 1, MAX = 20}
}

CV.Slipstream = CV_RegisterVar{
	name = "battle_slipstream",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}

CV.Actions = CV_RegisterVar{
	name = "battle_special",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}

CV.ShieldStock = CV_RegisterVar{
	name = "battle_shieldstock",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}

CV.PreRound = CV_RegisterVar{
	name = "battle_preround",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}

CV.Guard = CV_RegisterVar{
	name = "battle_guard",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}

CV.TailsDoll = CV_RegisterVar{
	name = "battle_training",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = {MIN = 0, MAX = 2}
}

CV.RespawnTime = CV_RegisterVar{
	name = "battle_maxrespawntime",
	defaultvalue = 10,
	flags = CV_NETVAR,
	PossibleValue = {MIN = 3, MAX = 30}
}

CV.RequireRings = CV_RegisterVar{
    name = "battle_requirerings",
    defaultvalue = 0,
    flags = CV_NETVAR,
    PossibleValue = CV_OnOff
}

CV.RingLimit = CV_RegisterVar{
    name = "battle_ringlimit",
    defaultvalue = 50,
    flags = CV_NETVAR,
    PossibleValue = {MIN = 0, MAX = 9999}
}

CV.Reward = CV_RegisterVar{
    name = "battle_wantedreward",
    defaultvalue = 25,
    flags = CV_NETVAR,
    PossibleValue = {MIN = 0, MAX = 9999}
}

CV.Autobalance = CV_RegisterVar {
	name = "battle_autobalance",
	defaultvalue = 0,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}

CV.parrytoggle = CV_RegisterVar{
	name = "battle_parry",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = {Off = 0, On = 1}
}

CV.airtoggle = CV_RegisterVar{
	name = "battle_airdodge",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = {Off = 0, On = 1}
}

CV.dodgetime = CV_RegisterVar{
	name = "battle_dodgecooldown",
	defaultvalue = 5,
	flags = CV_NETVAR,
	PossibleValue = {MIN = 0, MAX = 10}
}

CV.StartRings = CV_RegisterVar{
	name = "battle_startrings",
	defaultvalue = 50,
	flags = CV_NETVAR,
	PossibleValue = {MIN = 0, MAX = 999}
}

CV.RingPenalty = CV_RegisterVar{
	name = "battle_ringpenalty",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}
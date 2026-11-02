
local B = CBW_Battle

-- All Chaotix supercolors from ChaotixChars (https://mb.srb2.org/threads/the-B.39839/)
-- by Team Combi-Rings

-- super raspberry
B.SafeFreeslot("SKINCOLOR_SUPERRASPBERRY1")
skincolors[SKINCOLOR_SUPERRASPBERRY1] = {
	name = "Super Raspberry 1",
	ramp = {0, 0, 0, 0, 200, 200, 200, 202, 202, 180, 180, 182, 182, 184, 254, 254},
	accessible = false
}
B.SafeFreeslot("SKINCOLOR_SUPERRASPBERRY2")
skincolors[SKINCOLOR_SUPERRASPBERRY2] = {
	name = "Super Raspberry 2",
	ramp = {200, 200, 200, 200, 201, 201, 201, 202, 202, 182, 182, 184, 184, 184, 254, 254},
	accessible = false
}
B.SafeFreeslot("SKINCOLOR_SUPERRASPBERRY3")
skincolors[SKINCOLOR_SUPERRASPBERRY3] = {
	name = "Super Raspberry 3",
	ramp = {200, 200, 201, 201, 202, 202, 202, 203, 203, 183, 183, 185, 185, 185, 254, 254},
	accessible = false
}
B.SafeFreeslot("SKINCOLOR_SUPERRASPBERRY4")
skincolors[SKINCOLOR_SUPERRASPBERRY4] = {
	name = "Super Raspberry 4",
	ramp = {200, 200, 201, 201, 203, 203, 204, 204, 204, 184, 184, 185, 185, 185, 254, 254},
	accessible = false
}
B.SafeFreeslot("SKINCOLOR_SUPERRASPBERRY5")
skincolors[SKINCOLOR_SUPERRASPBERRY5] = {
	name = "Super Raspberry 5",
	ramp = {200, 200, 202, 202, 204, 204, 205, 205, 205, 185, 185, 186, 186, 186, 254, 254},
	accessible = false
}

-- mighty's skincolour's
B.SafeFreeslot("SKINCOLOR_ROSE")
skincolors[SKINCOLOR_ROSE] = {
	name = "Rose",
	ramp = {32,33,34,37,38,39,40,41,42,43,44,45,46,46,47,47},
	invcolor = skincolors[SKINCOLOR_RED].invcolor,
	invshade = 9,
	chatcolor = V_REDMAP,
	accessible = true
}
M_MoveColorAfter(SKINCOLOR_ROSE, SKINCOLOR_RED)

-- super rose
B.SafeFreeslot("SKINCOLOR_SUPERROSE1")
skincolors[SKINCOLOR_SUPERROSE1] = {
	name = "Super Rose 1",
	ramp = {208, 208, 209, 210, 32, 32, 34, 34, 36, 36, 38, 38, 39, 39, 40, 40},
	accessible = false
}
B.SafeFreeslot("SKINCOLOR_SUPERROSE2")
skincolors[SKINCOLOR_SUPERROSE2] = {
	name = "Super Rose 2",
	ramp = {209, 209, 210, 32, 33, 33, 35, 35, 38, 38, 40, 40, 41, 41, 42, 42},
	accessible = false
}
B.SafeFreeslot("SKINCOLOR_SUPERROSE3")
skincolors[SKINCOLOR_SUPERROSE3] = {
	name = "Super Rose 3",
	ramp = {210, 210, 32, 33, 35, 35, 37, 37, 40, 40, 42, 42, 43, 43, 44, 44},
	accessible = false
}
B.SafeFreeslot("SKINCOLOR_SUPERROSE4")
skincolors[SKINCOLOR_SUPERROSE4] = {
	name = "Super Rose 4",
	ramp = {32, 32, 33, 34, 36, 36, 38, 38, 41, 41, 43, 43, 44, 44, 45, 45},
	accessible = false
}
B.SafeFreeslot("SKINCOLOR_SUPERROSE5")
skincolors[SKINCOLOR_SUPERROSE5] = {
	name = "Super Rose 5",
	ramp = {32, 32, 34, 35, 37, 37, 39, 39, 42, 42, 44, 44, 45, 45, 46, 46},
	accessible = false
}

-- charmy's skincolor, Bumble
B.SafeFreeslot("SKINCOLOR_BUMBLE")
skincolors[SKINCOLOR_BUMBLE] = {
	name = "Bumble",
	ramp = {80, 82, 73, 74, 75, 76, 79, 21, 22, 23, 24, 26, 27, 28, 29, 30},
	invcolor = SKINCOLOR_BLUEBELL,
	invshade = 9,
	chatcolor = V_YELLOWMAP,
	accessible = true
}
M_MoveColorAfter(SKINCOLOR_BUMBLE, SKINCOLOR_YELLOW)
-- super bumble
B.SafeFreeslot("SKINCOLOR_SUPERBUMBLE1")
skincolors[SKINCOLOR_SUPERBUMBLE1] = {
	name = "Super Bumble 1",
	ramp = {0, 0, 0, 0, 80, 82, 83, 4, 4, 4, 4, 6, 8, 10, 12, 14},
	accessible = false
}
B.SafeFreeslot("SKINCOLOR_SUPERBUMBLE2")
skincolors[SKINCOLOR_SUPERBUMBLE2] = {
	name = "Super Bumble 2",
	ramp = {80, 80, 80, 82, 83, 72, 74, 16, 16, 16, 16, 16, 18, 20, 22, 24},
	accessible = false
}
B.SafeFreeslot("SKINCOLOR_SUPERBUMBLE3")
skincolors[SKINCOLOR_SUPERBUMBLE3] = {
	name = "Super Bumble 3",
	ramp = {80, 80, 80, 83, 72, 73, 75, 18, 18, 18, 18, 18, 20, 22, 24, 26},
	accessible = false
}
B.SafeFreeslot("SKINCOLOR_SUPERBUMBLE4")
skincolors[SKINCOLOR_SUPERBUMBLE4] = {
	name = "Super Bumble 4",
	ramp = {80, 81, 81, 72, 72, 74, 76, 21, 21, 21, 21, 21, 22, 24, 26, 28},
	accessible = false
}
B.SafeFreeslot("SKINCOLOR_SUPERBUMBLE5")
skincolors[SKINCOLOR_SUPERBUMBLE5] = {
	name = "Super Bumble 5",
	ramp = {80, 82, 82, 73, 73, 75, 77, 22, 22, 22, 22, 22, 23, 25, 27, 29},
	accessible = false
}

-- super apple
B.SafeFreeslot("SKINCOLOR_SUPERAPPLE1")
skincolors[SKINCOLOR_SUPERAPPLE1] = {
	name = "Super Apple 1",
	ramp = {80, 80, 82, 82, 82, 72, 72, 188, 100, 100, 102, 102, 104, 104, 104, 104},
	accessible = false
}
B.SafeFreeslot("SKINCOLOR_SUPERAPPLE2")
skincolors[SKINCOLOR_SUPERAPPLE2] = {
	name = "Super Apple 2",
	ramp = {82, 82, 83, 72, 72, 188, 188, 100, 102, 102, 104, 104, 105, 105, 105, 105},
	accessible = false
}
B.SafeFreeslot("SKINCOLOR_SUPERAPPLE3")
skincolors[SKINCOLOR_SUPERAPPLE3] = {
	name = "Super Apple 3",
	ramp = {83, 83, 72, 73, 73, 188, 188, 101, 103, 103, 105, 105, 106, 106, 106, 106},
	accessible = false
}
B.SafeFreeslot("SKINCOLOR_SUPERAPPLE4")
skincolors[SKINCOLOR_SUPERAPPLE4] = {
	name = "Super Apple 4",
	ramp = {72, 72, 73, 188, 188, 188, 188, 102, 104, 104, 106, 106, 107, 107, 107, 107},
	accessible = false
}
B.SafeFreeslot("SKINCOLOR_SUPERAPPLE5")
skincolors[SKINCOLOR_SUPERAPPLE5] = {
	name = "Super Apple 5",
	ramp = {73, 73, 188, 189, 189, 189, 189, 103, 105, 105, 107, 107, 108, 108, 108, 108},
	accessible = false
}

-- super fire
B.SafeFreeslot("SKINCOLOR_SUPERFIRE1")
skincolors[SKINCOLOR_SUPERFIRE1] = {
	name = "Super Fire 1",
	ramp = {0, 0, 48, 48, 48, 48, 48, 49, 49, 50, 50, 32, 32, 33, 33, 33},
	accessible = false
}
B.SafeFreeslot("SKINCOLOR_SUPERFIRE2")
skincolors[SKINCOLOR_SUPERFIRE2] = {
	name = "Super Fire 2",
	ramp = {48, 48, 48, 49, 50, 32, 32, 33, 33, 33, 33, 34, 34, 34, 36, 36},
	accessible = false
}
B.SafeFreeslot("SKINCOLOR_SUPERFIRE3")
skincolors[SKINCOLOR_SUPERFIRE3] = {
	name = "Super Fire 3",
	ramp = {48, 48, 49, 50, 32, 33, 33, 34, 34, 36, 36, 38, 38, 40, 40, 42},
	accessible = false
}
B.SafeFreeslot("SKINCOLOR_SUPERFIRE4")
skincolors[SKINCOLOR_SUPERFIRE4] = {
	name = "Super Fire 4",
	ramp = {48, 49, 50, 32, 33, 33, 34, 34, 36, 38, 38, 40, 40, 42, 42, 44},
	accessible = false
}
B.SafeFreeslot("SKINCOLOR_SUPERFIRE5")
skincolors[SKINCOLOR_SUPERFIRE5] = {
	name = "Super Fire 5",
	ramp = {49, 50, 32, 33, 34, 34, 36, 36, 38, 40, 40, 42, 44, 46, 46, 46},
	accessible = false
}
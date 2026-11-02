local B = CBW_Battle

-- From Ray the Flying Squirrel (https://mb.srb2.org/addons/ray-the-flying-squirrel.6348/)
-- by Team Combi-Rings

-- ray's skincolor
B.SafeFreeslot("SKINCOLOR_SUNSHINE")
skincolors[SKINCOLOR_SUNSHINE] = {
	name = "Sunshine",
	ramp = {0, 80, 81, 83, 73, 64, 50, 220, 222, 224, 227, 68, 60, 62, 45, 47},
	invcolor = SKINCOLOR_MAGENTA,
	invshade = 9,
	chatcolor = V_YELLOWMAP,
	accessible = true
}
M_MoveColorAfter(SKINCOLOR_SUNSHINE, SKINCOLOR_SANDY)

-- ray's super color
B.SafeFreeslot("SKINCOLOR_SUPERFOOLSGOLD1")
skincolors[SKINCOLOR_SUPERFOOLSGOLD1] = {
	name = "Super Foolsgold 1",
	ramp = {0, 0, 0, 0, 0, 0, 0, 80, 80, 81, 81, 82, 83, 72, 72, 72},
	accessible = false
}
B.SafeFreeslot("SKINCOLOR_SUPERFOOLSGOLD2")
skincolors[SKINCOLOR_SUPERFOOLSGOLD2] = {
	name = "Super Foolsgold 2",
	ramp = {0, 0, 0, 80, 81, 82, 83, 83, 72, 72, 72, 72, 64, 64, 65, 65},
	accessible = false
}
B.SafeFreeslot("SKINCOLOR_SUPERFOOLSGOLD3")
skincolors[SKINCOLOR_SUPERFOOLSGOLD3] = {
	name = "Super Foolsgold 3",
	ramp = {0, 0, 80, 81, 82, 83, 72, 72, 64, 65, 65, 66, 66, 67, 67, 69},
	accessible = false
}
B.SafeFreeslot("SKINCOLOR_SUPERFOOLSGOLD4")
skincolors[SKINCOLOR_SUPERFOOLSGOLD4] = {
	name = "Super Foolsgold 4",
	ramp = {0, 80, 82, 83, 72, 72, 64, 64, 65, 66, 66, 67, 67, 69, 69, 70},
	accessible = false
}
B.SafeFreeslot("SKINCOLOR_SUPERFOOLSGOLD5")
skincolors[SKINCOLOR_SUPERFOOLSGOLD5] = {
	name = "Super Foolsgold 5",
	ramp = {0, 80, 81, 83, 73, 64, 50, 220, 222, 224, 227, 68, 60, 62, 45, 47},
	accessible = false
}
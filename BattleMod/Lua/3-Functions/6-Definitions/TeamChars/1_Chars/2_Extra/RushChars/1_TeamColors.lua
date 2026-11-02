local B = CBW_Battle

-- Color Matey from RushChars (https://mb.srb2.org/addons/rushchars-blaze-and-marine.3831/updates)
-- by lightdasher

B.SafeFreeslot(
"SKINCOLOR_MATEY"
)

skincolors[SKINCOLOR_MATEY] = {
    name = "Matey",
	ramp = {88,89,64,51,52,54,56,58,60,43,44,45,45,46,46,47},
	invcolor = SKINCOLOR_MINT,
	invshade = 8, 
	chatcolor = V_ORANGEMAP,
	accessible = true}


-- From Dirk's Custom Super Colors (https://mb.srb2.org/addons/dirks-custom-super-colors.952/) by DirkTheHusky
B.SafeFreeslot(
"SKINCOLOR_SUPERCOPPER1",
"SKINCOLOR_SUPERCOPPER2",
"SKINCOLOR_SUPERCOPPER3",
"SKINCOLOR_SUPERCOPPER4",
"SKINCOLOR_SUPERCOPPER5"
)

skincolors[SKINCOLOR_SUPERCOPPER1] = {
    name = "Super Copper 1",
    ramp = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 81, 82, 64, 52, 53, 54},
    accessible = false
}

skincolors[SKINCOLOR_SUPERCOPPER2] = {
    name = "Super Copper 2",
    ramp = {0, 0, 0, 0, 81, 81, 82, 82, 64, 64, 52, 52, 53, 53, 54, 54},
    accessible = false
}
skincolors[SKINCOLOR_SUPERCOPPER3] = {
    name = "Super Copper 3",
    ramp = {0, 0, 81, 81, 82, 82, 64, 64, 52, 52, 53, 53, 54, 54, 55, 55},
    accessible = false
}
skincolors[SKINCOLOR_SUPERCOPPER4] = {
    name = "Super Copper 4",
    ramp = {0, 81, 82, 64, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 42, 43},
    accessible = false
}
skincolors[SKINCOLOR_SUPERCOPPER5] = {
    name = "Super Copper 5",
    ramp = {81, 82, 64, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 42, 43, 44},
    accessible = false
}
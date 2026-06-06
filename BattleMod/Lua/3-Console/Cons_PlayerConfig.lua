local CV = CBW_Battle.Console
CV.ConfigPath = "client/battleconfig.cfg"
CV.BattleConfigs = {}
CV.CVars = {}

-- as of v10, player's default values are handled automatically, so don't worry about other scripts! ~lu
local base_battleconfigs = {
	-- {NAME, DEFAULTVALUE}
	{"battleconfig_dodgecamera", true},
	{"battleconfig_special", BT_ATTACK},
	{"battleconfig_guard", BT_FIRENORMAL},
	{"battleconfig_aimsight", true},
	{"battleconfig_roulette", true},
	{"battleconfig_nospinshield", false},
----{"battleconfig_minimap", true},
----{"battleconfig_glidestrafe", true},
----{"battleconfig_hammerstrafe", false},
----{"battleconfig_slipstreambutton", BT_WEAPONNEXT},
----{"battleconfig_useslipstreambutton", false},
	{"battleconfig_altcontrols", false},
}

local base_cvars = {
	{"battleconfig_hud", {Old=0, New=1, Minimal=2}, "New"},
	{"battleconfig_nojingles", CV_OnOff, "Off"},
}

-- holy moly.. maybe we should use pcall() to prevent ppl from causing warnings? ~lu
CV.SaveConfig = function(player, configname, value, oldonly)
	if not(consoleplayer and consoleplayer == player) then
		return
	end

	local lines = {}
	local found = false
	if type(value) == "boolean" then
		value = $ and "1" or "0"
	end
	local newline = configname.." "..value
	local firstline = not oldonly
	local file = io.openlocal(CV.ConfigPath, "r")

	-- Read the current version from the file if it exists, and cancel operation when appropriate
	if oldonly and file and CBW_Battle.VersionNumber then
		local fileversion = 0
		for line in file:lines() do
			local versionnumber, versionsub = line:match("(%d+)%s+($d+)")
			if versionnumber and versionsub then
				fileversion = tonumber(versionnumber) * 100 + tonumber(versionsub)
			end
			file:close()
			break --only read first line
    	end
		if (CBW_Battle.VersionNumber * 100 + CBW_Battle.VersionSub) <= fileversion then
			return
		end
	end

	-- Read the file and store the lines in a table
	local file = io.openlocal(CV.ConfigPath, "r")
	if file then
   	 	for line in file:lines() do
        	if firstline then
           	 	firstline = false
        	else
            	if line:sub(1, #configname) == configname then
                	table.insert(lines, newline)
                	found = true
            	else
                	table.insert(lines, line)
            	end
        	end
    	end
    	file:close()
	end

	-- If the config didn't exist in the config file, add is at as a new line
	if not found then
		if oldonly then
			return
		end
		table.insert(lines, newline)
	end

	-- Write the modified content back to the file
	local file = io.openlocal(CV.ConfigPath, "w")
	if file then
		if not oldonly then
			if CBW_Battle.VersionNumber then
				file:write(CBW_Battle.VersionNumber.." "..CBW_Battle.VersionSub.." "..CBW_Battle.VersionCommit.."\n")
			else
				file:write("PIRATE".."\n")
			end
		end
		for i, line in ipairs(lines) do
			file:write(line .. "\n")
		end
		file:close()
	else
		CONS_Printf(player, "Failed to save "..CV.ConfigPath)
	end
end

local function tostring2(value)
	if value == nil then
		return "nil"
	elseif type(value) == "boolean" then
		return value and "true" or "false"
	else
		return tostring(value)
	end
end

CV.AddBattleConfig = function(configname, func, defaultvalue)
	local panic = configname != nil or func != nil or defaultvalue != nil
	assert(panic, "AHH!! AAAHHHHHHH!!\n".."One of these values is nil! "..tostring2(configname).." "..tostring2(func).." "..tostring2(defaultvalue))
	COM_AddCommand(configname, func, 0)
	table.insert(CV.BattleConfigs, {configname, defaultvalue})
end

CV.DoDefaultBattleConfigs = function(player, reset)
	for _, battleconfig in ipairs(CV.BattleConfigs) do 
		local config = battleconfig[1]
		local defaultvalue = battleconfig[2]
		if reset or player[config] == nil then
			player[config] = defaultvalue
		end
	end
end

local str2btn = {}
str2btn["jump"] = BT_JUMP
str2btn["spin"] = BT_SPIN
str2btn["fire"] = BT_ATTACK
str2btn["firenormal"] = BT_FIRENORMAL
str2btn["tossflag"] = BT_TOSSFLAG
str2btn["camleft"] = BT_CAMLEFT
str2btn["camright"] = BT_CAMRIGHT
str2btn["custom1"] = BT_CUSTOM1
str2btn["custom2"] = BT_CUSTOM2
str2btn["custom3"] = BT_CUSTOM3
str2btn["nextweapon"] = BT_WEAPONNEXT
str2btn["prevweapon"] = BT_WEAPONPREV
str2btn["weapon1"] = 1
str2btn["weapon2"] = 2
str2btn["weapon3"] = 3
str2btn["weapon4"] = 4
str2btn["weapon5"] = 5
str2btn["weapon6"] = 6
str2btn["weapon7"] = 7

local capitalize = function(word) --i know y'all hate capitalism but
	--also sorry, this could be optimized but i just feel like making a silly little hack for multiple words
	if word == "firenormal" then return "FireNormal"
	elseif word == "camleft" then return "CamLeft"
	elseif word == "camright" then return "CamRight"
	elseif word == "nextweapon" then return "NextWeapon"
	elseif word == "prevweapon" then return "PrevWeapon"
	else return (word:sub(1,1):upper() .. word:sub(2))
	end
end

local btn2str = {}
for str, btn in pairs(str2btn) do
	btn2str[btn] = capitalize(str)
end

CV.ConfigFunc = function(player, arg, silent)
	local color = "\135"
    arg = $ and $:lower() or nil
    local CONS_Printl = function(text)
        if not silent then CONS_Printf(player, text) end
    end
	local L_StartSound = function(sound)
        if not silent then S_StartSound(nil, sound, player) end
    end
    if (silent and silent != "silent") or not (arg == "help" or arg == "load" or arg == "usedefaults" or arg == "reset") then
		L_StartSound(sfx_s25a)
        CONS_Printl(color.."battleconfig <help/load/usedefaults/reset>: Load from or wipe BattleMod's configuration file.")
	elseif (arg == "help") then
		L_StartSound(sfx_s25a)
		local configs = {}
		for _, battleconfig in ipairs(CV.BattleConfigs) do
			local config = battleconfig[1]
			local defaultvalue = battleconfig[2]
			local color = "\x86"
			if player[config] == true then
				color = "\x83"
			elseif player[config] == false then
				color = "\x85"
			end
			local modified = player[config] != defaultvalue and "\x82*\x80" or ""
			table.insert(configs, color..(string.sub(battleconfig[1], 13))..modified)
		end
		CONS_Printf(player, "Available configurations: "..table.concat(configs, "\x80, "))
		local cvars = {}
		for _, cvar in ipairs(CV.CVars) do
			table.insert(cvars, string.sub(cvar[1], 13))
		end
		CONS_Printf(player, "Client configurations: "..table.concat(cvars, ", "))
	elseif (arg == "load") then
        local file = io.openlocal(CV.ConfigPath, "r")
        if file then
            local firstline = true
            for line in file:lines() do
                if firstline then
                    firstline = false
                else
                    COM_BufInsertText(player, line)
                end
            end
            file:close()
            CONS_Printl(color.."Configuration has been loaded!")
			L_StartSound(sfx_addfil)
        else
            CONS_Printl(color.."Failed to access (luafiles/"..CV.ConfigPath.."). Perhaps it is missing?")
			L_StartSound(sfx_adderr)
		end
    elseif (arg == "save") then
        CONS_Printl(color.."Nuh uh! Saving already happens automatically whenever you modify a battleconfig.")
		L_StartSound(sfx_zelda)
	elseif (arg == "usedefaults") then
		CV.DoDefaultBattleConfigs(player, true)
		CONS_Printl(color.."All settings have been set to their default values.")
	elseif (arg == "reset") then -- reset config file
		local file = io.openlocal(CV.ConfigPath, "w")
		if file then
			file:close()
			CONS_Printl(color.."Configuration has been reset!")
		else
			CONS_Printl(color.."Failed to find (luafiles/"..CV.ConfigPath.."). Success, I guess?")
		end
		L_StartSound(sfx_notadd)
		COM_BufInsertText(player, "battleconfig usedefaults")
	end
end
CV.Config = COM_AddCommand("battleconfig", CV.ConfigFunc, COM_LOCAL)

//User Config

//Convert strings to flags
local getflags = function(args)
	local flags = 0

	for n = 1, #args
		local a = args[n]
		local numtype = tonumber(a) 
		local strtype = str2btn[tostring(a)]
		if
		numtype and numtype < BT_CUSTOM3<<1  and numtype > 0 then
			flags = $|numtype
-- 			print("Set number argument "..numtype)
		elseif
		strtype != nil then
			flags = $|strtype
-- 			print('Converted string "'..tostring(a)..'" to number argument argument '..strtype)
		else
-- 			print('Error: argument "'..tostring(a)..'" could not be read')
		end
	end
	return flags
end

local print_help = function(player)
	local buttons = ""
	for btn, str in pairs(btn2str) do
		buttons = $..str..", "
	end
	buttons = string.gsub($, ", $", ".")
	CONS_Printf(player,"\x86".."Valid arguments: "..buttons)
end

local validplayer = function(player, silent)
	if not(player and player.valid) then
		if not silent then
			CONS_Printf(player,"Please wait until inside a game to use this command.")
		end
		return false
	end
	return true
end

local validateNoSave = function(arg, nosave)
	if arg and arg:sub(-1) == "*" then
		arg = $:sub(1, -2)
		nosave = true
	end
	return arg, nosave
end

CV.ToggleableConfig = function(player, arg, config, defaultvalue, silent)
	if validplayer(player, silent) == false then
		return
	end
	local nosave = false
	arg = $ and $:lower() or nil
	arg, nosave = validateNoSave(arg, nosave)
	local options = {
		["true"] = true, ["1"] = true, ["on"] = true, ["yes"] = true,
		["false"] = false, ["0"] = false, ["off"] = false, ["no"] = false,
	}
	local option = options[arg]
	local currenttxt = player[config] and "On" or "Off"
	local defaulttxt = defaultvalue and "On" or "Off"
	if option == nil and not silent then
		S_StartSound(nil, sfx_s25a, player)
		CONS_Printf(player,config.." <On/Off>: Currently \135"..currenttxt.."\x80 - Default is \135"..defaulttxt)
	else
		player[config] = option
		if not nosave then CV.SaveConfig(player, config, option) end
	end
end

CV.ButtonConfig = function(player, args, config, defaultvalue, silent)
	if validplayer(player, silent) == false then
		return
	end
	local nosave = false
	for i,arg in ipairs(args) do
		args[i], nosave = validateNoSave(arg, nosave)
		arg = $:lower()
	end
	
	local flags = 0
	flags = args and getflags(args) or 0
	
	if flags == 0 or not #args then
		S_StartSound(nil, sfx_s25a, player)
		CONS_Printf(player,config.." <Button>: Currently \135"..btn2str[player[config]].."\x80 - Default is \135"..btn2str[defaultvalue])
		print_help(player)
	else
		player[config] = flags
		if not nosave then CV.SaveConfig(player, config, flags) end
	end
end

-- finally, time to add everything!
-- configs with true/false as default values are treated as On/Off switches, treated as buttons otherwise
for _, config in ipairs(base_battleconfigs) do
	local name = config[1]
	local default = config[2]
    if type(default) == "boolean" then
        CV.AddBattleConfig(name, function(player, arg) CV.ToggleableConfig(player, arg, name, default) end, default)
    else
        CV.AddBattleConfig(name, function(player, ...) CV.ButtonConfig(player, {...}, name, default) end, default)
    end
end

CV.SaveCVar = function(var)
	CV.SaveConfig(consoleplayer, var.name, var.string, false)
end

--[string] = consvar_t
local CV_Lookup = {}
setmetatable(CV_Lookup, {
	__mode = "kv"
})

CV.FindVar = function(cv_name)
	if CV_Lookup[cv_name]
		return CV_Lookup[cv_name]
	end
	CV_Lookup[cv_name] = CV_FindVar(cv_name)
	return CV_Lookup[cv_name]
end

CV.FindVarString = function(var, strings) -- utility function
	local var = CV.FindVar(var)
	if not var then
		return nil
	end

	if var.string then
		if strings then
			if type(strings) == "table" then
				return CBW_Battle.Find(strings, var.string)
			else
				return (var.string == strings)
			end
		end
		return var.string
	end
	return 0
end

for _, cvar in ipairs(base_cvars) do
	local name = cvar[1]
	local options = cvar[2]
	local default = cvar[3]
	CV[name] = CV_RegisterVar{
		name = name, -- no shit sherlock
		defaultvalue = default,
		flags = CV_CALL, -- not CV_NETVAR!!
		func = CV.SaveCVar,
		PossibleValue = options,
	}
	table.insert(CV.CVars, {name, options, default})
end

-- See also: B.AutoLoad in Exec_System.lua
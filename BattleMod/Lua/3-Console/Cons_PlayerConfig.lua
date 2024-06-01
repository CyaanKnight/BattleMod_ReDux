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
	CONS_Printf(player,"Valid arguments: jump, spin, fire, firenormal, tossflag, camleft, camright, custom1, custom2, custom3, nextweapon, prevweapon, weapon1, weapon2, weapon3, weapon4, weapon5, weapon6, weapon7")
end

COM_AddCommand("battleconfig_dodgecamera", function(player, arg)
	if not(player and player.valid) then
		CONS_Printf(player,"Please wait until inside a game to use this command.")
		return
	end
	if arg == "true" or arg == "1" or arg == "on" or arg == "yes" then
		player.battleconfig_dodgecamera = true
	elseif arg == "false" or arg == "0" or arg == "off" or arg == "no" then	
		player.battleconfig_dodgecamera = false
	else
		CONS_Printf(player,"battleconfig_dodgecamera <on/off> default on")
	end
end,0)

COM_AddCommand("battleconfig_autospectator", function(player, arg)
	if not(player and player.valid) then
		CONS_Printf(player,"Please wait until inside a game to use this command.")
		return
	end
	if arg == "true" or arg == "1" or arg == "on" or arg == "yes" then
		player.battleconfig_autospectator = true
	elseif arg == "false" or arg == "0" or arg == "off" or arg == "no" then	
		player.battleconfig_autospectator = false
	else
		CONS_Printf(player,"battleconfig_autospectator <on/off> default on")
	end
end,0)

COM_AddCommand("battleconfig_special", function(player, ...)
	if not(player and player.valid) then
		CONS_Printf(player,"Please wait until inside a game to use this command.")
		return
	end
	local args = {...}
	if not #args then
		CONS_Printf(player,'battleconfig_special: default is "fire"')
		print_help(player)
	return end
	
	local flags = getflags(args)
	
	if flags != 0 then
		player.battleconfig_special = flags
	end
end,0)

COM_AddCommand("battleconfig_guard", function(player, ...)
	if not(player and player.valid) then
		CONS_Printf(player,"Please wait until inside a game to use this command.")
		return
	end
	local args = {...}
	if not #args then
		CONS_Printf(player,'battleconfig_guard: default is "firenormal"')
		print_help(player)
	return end
	
	local flags = getflags(args)
	
	if flags != 0 then
		player.battleconfig_guard = flags
	end
end,0)

COM_AddCommand("battleconfig_aimsight", function(player, arg)
	if not(player and player.valid) then
		CONS_Printf(player,"Please wait until inside a game to use this command.")
		return
	end	
	if arg == "on" or arg == "On" or arg == "1" or arg == "true" then
		player.battleconfig_aimsight = true
	elseif arg == "off" or arg == "Off" or arg == "0" or arg == "false" then
		player.battleconfig_aimsight = false
	else
		CONS_Printf(player,'battleconfig_aimsight <On/Off> - Default is On')
	return end
end,0)

COM_AddCommand("battleconfig_disablevfx", function(player, arg)
	if not(player and player.valid) then
		CONS_Printf(player,"Please wait until inside a game to use this command.")
		return
	end	
	if arg == "on" or arg == "On" or arg == "1" or arg == "true" then
		player.novfx = true
	elseif arg == "off" or arg == "Off" or arg == "0" or arg == "false" then
		player.novfx = false
	else
		CONS_Printf(player,'battleconfig_disablevfx <On/Off> - Default is Off')
	return end
end,0)

COM_AddCommand("battleconfig_charselect", function(player, arg)
    if not(player and player.valid) then
        CONS_Printf(player,"Please wait until inside a game to use this command.")
        return
    end    
    if arg == "on" or arg == "On" or arg == "1" or arg == "true" then
        player.battleconfig_charselect = true
    elseif arg == "off" or arg == "Off" or arg == "0" or arg == "false" then
        player.battleconfig_charselect = false
    else
        CONS_Printf(player,'battleconfig_charselect <On/Off> - Default is On')
    return end
end,0)

COM_AddCommand("battleconfig_nospinshield", function(player, arg)
    if not(player and player.valid) then
        CONS_Printf(player,"Please wait until inside a game to use this command.")
        return
    end    
    if arg == "on" or arg == "On" or arg == "1" or arg == "true" then
        player.battleconfig_nospinshield = true
    elseif arg == "off" or arg == "Off" or arg == "0" or arg == "false" then
        player.battleconfig_nospinshield = false
    else
        CONS_Printf(player,'battleconfig_nospinshield <On/Off> - Default is Off')
    return end
end,0)

COM_AddCommand("battleconfig_newhud", function(player, arg)
    if not(player and player.valid) then
        CONS_Printf(player,"Please wait until inside a game to use this command.")
        return
    end    
    if arg == "on" or arg == "On" or arg == "1" or arg == "true" then
        player.battleconfig_newhud = true
    elseif arg == "off" or arg == "Off" or arg == "0" or arg == "false" then
        player.battleconfig_newhud = false
    else
        CONS_Printf(player,'battleconfig_newhud <On/Off> - Default is On')
    return end
end,0)

COM_AddCommand("battleconfig_minimap", function(player, arg)
    if not(player and player.valid) then
        CONS_Printf(player,"Please wait until inside a game to use this command.")
        return
    end    
    if arg == "on" or arg == "On" or arg == "1" or arg == "true" then
        player.battleconfig_minimap = true
    elseif arg == "off" or arg == "Off" or arg == "0" or arg == "false" then
        player.battleconfig_minimap = false
    else
        CONS_Printf(player,'battleconfig_minimap <On/Off> - Default is On')
    return end
end,0)

COM_AddCommand("battleconfig_glidestrafe", function(player, arg)
    if not(player and player.valid) then
        CONS_Printf(player,"Please wait until inside a game to use this command.")
        return
    end    
    if arg == "on" or arg == "On" or arg == "1" or arg == "true" then
        player.battleconfig_glidestrafe = true
    elseif arg == "off" or arg == "Off" or arg == "0" or arg == "false" then
        player.battleconfig_glidestrafe = false
    else
    	local value = player.battleconfig_glidestrafe
        CONS_Printf(player,'battleconfig_glidestrafe <On/Off> - Default is On - Currently '+value)
    return end
end,0)

COM_AddCommand("battleconfig_hammerstrafe", function(player, arg)
    if not(player and player.valid) then
        CONS_Printf(player,"Please wait until inside a game to use this command.")
        return
    end    
    if arg == "on" or arg == "On" or arg == "1" or arg == "true" then
        player.battleconfig_hammerstrafe = true
    elseif arg == "off" or arg == "Off" or arg == "0" or arg == "false" then
        player.battleconfig_hammerstrafe = false
    else
        local value = player.battleconfig_hammerstrafe
        CONS_Printf(player,'battleconfig_hammerstrafe <On/Off> - Default is On - Currently '+value)
    return end
end,0)

COM_AddCommand("battleconfig_slipstreambutton", function(player, ...)
	if not(player and player.valid) then
		CONS_Printf(player,"Please wait until inside a game to use this command.")
		return
	end
	local args = {...}
	if not #args then
		CONS_Printf(player,'battleconfig_slipstreambutton: default is "<prev/next>"')
		print_help(player)
	return end
	
	local flags = getflags(args)
	
	if flags != 0 then
		player.battleconfig_slipstreambutton = flags
	end
end,0)

COM_AddCommand("battleconfig_slipstreamstyle", function(player, arg)
	if not(player and player.valid) then
		CONS_Printf(player,"Please wait until inside a game to use this command.")
		return
	end	
	if arg == "instant" or arg == "Instant" or arg == "0" then
		player.battleconfig_slipstreamstyle = false
		print("Instant")
	elseif arg == "button" or arg == "Button" or arg == "1" then
		player.battleconfig_slipstreamstyle = true
		print("Button")
	else
		CONS_Printf(player,'battleconfig_slipstreamstyle <Instant or Button> - Default is Instant')
	return end
end,0)

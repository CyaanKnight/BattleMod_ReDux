local HOOKS = {}

rawset(_G, "CBW_HookHandlers", {})

CBW_HookHandlers.Any = function(old, new)
	return new or old
end

CBW_HookHandlers.True = function(old, new)
	if old or new then
		return true
	end

	return false
end

CBW_HookHandlers.HighestNum = function(old, new)
	if new ~= nil and type(new) ~= "number" then
		new = nil
	end

	if new == nil and old == nil then
		return 0
	end

	if old == nil or new > old then
		return new
	end

	return old
end

CBW_HookHandlers.BoolOrNil = function(old, new)
	if old == nil and new == nil then
		return
	end

	return (old or new) and true or false
end

CBW_Battle._DefineHook = function(name, handler)
	if not name then return end -- // SUPPLY A NAME!! //
	if HOOKS[name] then return end -- // Hook already defined // --

	HOOKS[name] = {
		functions = {global = {}, typed = {}},
		handler = handler or CBW_HookHandlers.Any
	}
end

CBW_Battle._RunHook = function(name, extra, ...)
	if not name then return end
	if not HOOKS[name] then return end

	local hook = HOOKS[name]
	local result

	-- run global before typed...
	for _, funct in ipairs(hook.functions.global) do
		result = hook.handler($, funct(...))
	end

	if extra ~= nil and hook.functions.typed[extra] then
		for _, funct in ipairs(hook.functions.typed[extra]) do
			result = hook.handler($, funct(...))
		end
	end

	return result
end

CBW_Battle.AddHook = function(name, funct, extra)
	if not name or not funct then print("AddHook is missing arguments!") end
	if not HOOKS[name] then
		print("AddHook name is not valid!")
		return
	end

	local hook = HOOKS[name]

	if extra ~= nil then
		hook.functions.typed[extra] = $ or {}
		table.insert(hook.functions.typed[extra], funct)
		return
	end

	table.insert(hook.functions.global, funct)
end
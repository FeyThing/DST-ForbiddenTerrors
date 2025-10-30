-- NOTE (HALF): Porting the Upvalue hacker used in IA since it has advanced functionality

--Tool designed by Rezecib. (and added onto by Hornet!)

local DFUpvalueHacker = {}
local function GetUpvalueHelper(fn, name)
    local i = 1
    while debug.getupvalue(fn, i) and debug.getupvalue(fn, i) ~= name do
        i = i + 1
    end
    local name, value = debug.getupvalue(fn, i)
    return value, i
end

---@param fn function
---@param ... string
---@return any
---@return integer
---@return function
function DFUpvalueHacker.GetUpvalue(fn, ...)
    local prv, i, prv_var = nil, nil, "(the starting point)"
    for j,var in ipairs({...}) do
        assert(type(fn) == "function", "We were looking for "..var..", but the value before it, "
            ..prv_var..", wasn't a function (it was a "..type(fn)
            .."). Here's the full chain: "..table.concat({"(the starting point)", ...}, ", "))
        prv = fn
        prv_var = var
        fn, i = GetUpvalueHelper(fn, var)
    end
    return fn, i, prv
end
 
---@param start_fn function
---@param new_fn any
---@param ... string
function DFUpvalueHacker.SetUpvalue(start_fn, new_fn, ...)
    local _fn, _fn_i, scope_fn = DFUpvalueHacker.GetUpvalue(start_fn, ...)
    debug.setupvalue(scope_fn, _fn_i, new_fn)
end

---@param stack integer
---@param var_name string
---@return true|nil
---@return any|nil
---@return integer|nil
function DFUpvalueHacker.GetLocal(stack, var_name)
    local i = 1
	while true do
		local n, v = debug.getlocal(stack + 1, i)
		if not n then break end
		if n == var_name then return true, v, i end
		i = i + 1
	end
end

-- NOTE (HALF): This thing should be avoided as much as possible, but if we need it then we need it. Nothing we can do about that :/
---@param stack integer
---@param var_name string
---@param new_val any
function DFUpvalueHacker.SetLocal(stack, var_name, new_val)
    local i = 1
	while true do
		local n, v = debug.getlocal(stack + 1, i)
		if not n then break end
		if n == var_name then debug.setlocal(stack + 1, i, new_val) return true, v end
		i = i + 1
	end
end

--Hiding.

--TODO IMPLEMENT HIDING FOR THESE FUNCTIONS:
--debug.getinfo
--debug.getlocal
--debug.setlocal
--getfenv
--setfenv

local hidden_fns = {}
function DFUpvalueHacker.HideFn(hidden_fn, real_fn)
    hidden_fns[hidden_fn] = real_fn
end

local _debug_getupvalue = debug.getupvalue
local _debug_setupvalue = debug.setupvalue
local _debug_getfenv = debug.getfenv
local _debug_setfenv = debug.setfenv

function debug.getupvalue(fn, ...) return _debug_getupvalue(hidden_fns[fn] or fn, ...) end
function debug.setupvalue(fn, ...) return _debug_setupvalue(hidden_fns[fn] or fn, ...) end
function debug.getfenv(fn, ...) return _debug_getfenv(hidden_fns[fn] or fn, ...) end
function debug.setfenv(fn, ...) return _debug_setfenv(hidden_fns[fn] or fn, ...) end

DFUpvalueHacker.HideFn(debug.getupvalue, _debug_getupvalue)
DFUpvalueHacker.HideFn(debug.setupvalue, _debug_setupvalue)
DFUpvalueHacker.HideFn(debug.getfenv, _debug_getfenv)
DFUpvalueHacker.HideFn(debug.setfenv, _debug_setfenv)

-- TODO (Half): Maybe add a way for modders to get a copy of the hidefns table for the really really rare case
-- someone wants to modify some of our hidden fns

return DFUpvalueHacker
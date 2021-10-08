local ffi = require "ffi"
local C = ffi.C

local interface_ptr = ffi.typeof("void***")
local function vtable_entry(instance, i, ct)
    return ffi.cast(ct, ffi.cast(interface_ptr, instance)[0][i])
end

local function vtable_bind(instance, i, ct)
    local t = ffi.typeof(ct)
    local fnptr = vtable_entry(instance, i, t)
    return function(...)
        return fnptr(instance, ...)
    end
end

local function vtable_thunk(i, ct)
    local t = ffi.typeof(ct)
    return function(instance, ...)
        return vtable_entry(instance, i, t)(instance, ...)
    end
end

ffi.cdef [[
    void* GetModuleHandleA(const char*);
    void* GetProcAddress(const char*, const char*);
    typedef void* (*CreateInterfaceFn)(const char*, int*);
]]

local EngineCvar = ffi.cast("CreateInterfaceFn", C.GetProcAddress(C.GetModuleHandleA("vstdlib"), "CreateInterface"))("VEngineCvar007", nil)

local function cvar()
    ffi.cdef [[
        typedef struct
        {
            char        pad_0x0000[0x4];
            void*       next;
            bool        registered;
            char*       name;
            char*       help_string;
            int         flags;
            char        pad_0x0018[0x4];
            void*       parent;
            char*       default_value;
            char*       value_string;
            int         value_string_length;
            float       value_float;
            int         value_int;
            bool        has_min;
            float       value_min;
            bool        has_max;
            float       value_max;
            void*       change_callback;
        } ConVar;
    ]]

    local native_FindVar = vtable_bind(EngineCvar, 16, "ConVar*(__thiscall*)(void*, const char*)")
    local GetFloat = vtable_thunk(12, "float(__thiscall*)(void*)")
    local GetInt = vtable_thunk(13, "int(__thiscall*)(void*)")
    local SetString = vtable_thunk(14, "void(__thiscall*)(void*, const char*)")
    local SetFloat = vtable_thunk(15, "void(__thiscall*)(void*, float)")
    local SetInt = vtable_thunk(16, "void(__thiscall*)(void*, int)")

    local cvar_mt = {}
    cvar_mt.__index = cvar_mt

    function cvar_mt:__tostring()
        if not self.cvar then
            return "nil"
        end

        return "cdata<cvar" .. tostring(self.cvar):sub(17, 31)
    end

    function cvar_mt:is_registered()
        if not self.cvar then
            return
        end

        return self.cvar.registered
    end

    function cvar_mt:name()
        if not self.cvar then
            return
        end

        return ffi.string(self.cvar.name)
    end

    function cvar_mt:description()
        if not self.cvar then
            return
        end

        return ffi.string(self.cvar.help_string)
    end

    function cvar_mt:flags()
        if not self.cvar then
            return
        end

        return self.cvar.flags
    end

    function cvar_mt:get_string()
        if not self.cvar then
            return
        end

        return ffi.string(self.cvar.value_string)
    end

    function cvar_mt:get_float()
        if not self.cvar then
            return
        end

        return GetFloat(self.cvar)
    end

    function cvar_mt:get_int()
        if not self.cvar then
            return
        end

        return GetInt(self.cvar)
    end

    function cvar_mt:set_string(str)
        if not self.cvar then
            return
        end

        SetString(self.cvar, tostring(str))
    end

    function cvar_mt:set_float(float)
        if not self.cvar then
            return
        end

        SetFloat(self.cvar, float)
    end

    function cvar_mt:set_int(int)
        if not self.cvar then
            return
        end

        SetInt(self.cvar, int)
    end

    return {
        find = function(name)
            local cvar = native_FindVar(name)

            return setmetatable(
                {
                    cvar = cvar ~= nil and cvar or nil
                },
                cvar_mt
            )
        end
    }
end

return cvar()

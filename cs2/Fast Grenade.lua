xpcall(function()
    local ffi = ffi or require "ffi"
    local C = ffi.C

    ---@format disable-next
    local vtable_bind, vtable_thunk = (function()local a=(function()local b=ffi.typeof"void***"return function(c,d,e)return ffi.cast(e,ffi.cast(b,c)[0][d])end end)()local function f(c,d,e,...)local g=a(c,d,ffi.typeof(e,...))return function(...)return g(c,...)end end;local function h(d,e,...)e=ffi.typeof(e,...)return function(c,...)return a(c,d,e)(c,...)end end;return f,h end)()
    ---@format disable-next
    local detour = (function()local a={}ffi.cdef"int VirtualProtect(void*, uint64_t, unsigned long, unsigned long*)"local b=0x40;function a.new(c,d,e)local f=12;local g=ffi.new("uint8_t[?]",f)ffi.copy(ffi.cast("void*",g),ffi.cast("const void*",e),f)local h=ffi.cast(c,e)local i=ffi.new("uint8_t[12]",{0x48,0xB8,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xFF,0xE0})ffi.cast("int64_t*",i+2)[0]=ffi.cast("int64_t",ffi.cast("void*",ffi.cast(c,d)))local j=ffi.new"unsigned long[1]"return setmetatable({},{__call=function(self,...)self:remove()local k=h(...)self:install()return k end,__index={install=function(self)C.VirtualProtect(ffi.cast("void*",e),f,b,j)ffi.copy(ffi.cast("void*",e),ffi.cast("const void*",i),f)C.VirtualProtect(ffi.cast("void*",e),f,j[0],j)return self end,remove=function(self)C.VirtualProtect(ffi.cast("void*",e),f,b,j)ffi.copy(ffi.cast("void*",e),ffi.cast("const void*",g),f)C.VirtualProtect(ffi.cast("void*",e),f,j[0],j)return self end}}):install()end;return a end)()
    ---@format disable-next
    ---@diagnostic disable-next-line
    local murmur2hash = function(key)local a=ffi.cast("uint32_t",0x5bd1e995)local b=24;local c=#key;local d=bit.bxor(0x31415926,c)local e=ffi.cast("const uint8_t*",key)while c>=4 do local f=ffi.cast("uint32_t*",e)[0]f=ffi.cast("uint32_t",f*a)f=bit.bxor(f,bit.rshift(f,b))f=ffi.cast("uint32_t",f*a)d=ffi.cast("uint32_t",d*a)d=bit.bxor(d,f)e=e+4;c=c-4 end;if c==3 then d=bit.bxor(d,bit.lshift(e[2],16))end;if c>=2 then d=bit.bxor(d,bit.lshift(e[1],8))end;if c>=1 then d=bit.bxor(d,e[0])d=ffi.cast("uint32_t",d*a)end;d=bit.bxor(d,bit.rshift(d,13))d=ffi.cast("uint32_t",d*a)d=bit.bxor(d,bit.rshift(d,15))return d end

    local function new_class(name)
        return function(metatable)
            if type(metatable) == "string" then
                ffi.cdef(string.format("typedef struct $ {%s} $", metatable), name, name)
                return function(metatable) return ffi.metatype(name, metatable) end
            end

            ffi.cdef("typedef struct $ {} $", name, name)
            return ffi.metatype(name, metatable)
        end
    end

    local fire_event, set_event_callback, unset_event_callback
    do
        local events = {}
        function fire_event(name, ...)
            for _, value in ipairs(events[name] or {}) do
                xpcall(value, print, ...)
            end
        end

        function set_event_callback(name, callback)
            events[name] = events[name] or {}
            table.insert(events[name], callback)
        end

        function unset_event_callback(name, callback)
            for key, value in ipairs(events[name] or {}) do
                if tostring(value) == tostring(callback) then
                    table.remove(events[name], key)
                end
            end
        end
    end

    -- callbacks.Register("FireGameEvent", function(e) -- bug e:GetString
    --     if not e then return end
    --     fire_event(e:GetName(), e)
    -- end)

    do
        callbacks.Register("Unload", function() fire_event "shutdown" end)

        new_class "CUtlStringToken" [[
            uint32_t m_nHashCode;
            const char* m_pDebugName;
        ]]

        new_class "CGameEvent" {
            __index = {
                GetName = vtable_thunk(1, "const char*(__thiscall*)(void*)"),
                GetBool = vtable_thunk(6, "bool(__thiscall*)(void*, const CUtlStringToken&, bool)"),
                GetInt = vtable_thunk(7, "int(__thiscall*)(void*, const CUtlStringToken&, int)"),
                GetUint64 = vtable_thunk(8, "uint64_t(__thiscall*)(void*, const CUtlStringToken&, uint64_t)"),
                GetFloat = vtable_thunk(9, "float(__thiscall*)(void*, const CUtlStringToken&, float)"),
                GetString = vtable_thunk(10, "const char*(__thiscall*)(void*, const CUtlStringToken&, const char*)"),
                GetPtr = vtable_thunk(12, "const void*(__thiscall*)(void*, const CUtlStringToken&)"),
                SetBool = vtable_thunk(20, "void(__thiscall*)(void*, const CUtlStringToken&, const bool)"),
                SetInt = vtable_thunk(21, "void(__thiscall*)(void*, const CUtlStringToken&, const int)"),
                SetUint64 = vtable_thunk(22, "void(__thiscall*)(void*, const CUtlStringToken&, const uint64_t)"),
                SetFloat = vtable_thunk(23, "void(__thiscall*)(void*, const CUtlStringToken&, const float)"),
                SetString = vtable_thunk(24, "void(__thiscall*)(void*, const CUtlStringToken&, const char*)"),
                SetPtr = vtable_thunk(26, "void(__thiscall*)(void*, const CUtlStringToken&, const void*)")
            }
        }

        local fnfireEventClientSide
        set_event_callback("shutdown", function() fnfireEventClientSide:remove() end)

        fnfireEventClientSide = detour.new("bool(__fastcall*)(void*, CGameEvent*, bool)", function(a1, event, a3)
            local eventname
            if event ~= nil then eventname = event:GetName() end
            if eventname ~= nil then
                fire_event(ffi.string(eventname), setmetatable({}, {
                    __index = function(_, key)
                        return setmetatable({
                            token = ffi.new("CUtlStringToken", murmur2hash(key))
                        }, {
                            __index = {
                                bool = function(self, def)
                                    return event:GetBool(self.token, def or false)
                                end,
                                int = function(self, def)
                                    return event:GetInt(self.token, def or -1)
                                end,
                                uint64 = function(self, def)
                                    return event:GetUint64(self.token, def or 0xffffffff)
                                end,
                                float = function(self, def)
                                    return event:GetFloat(self.token, def or 0)
                                end,
                                string = function(self, def)
                                    return ffi.string(event:GetString(self.token, def or "unknown"))
                                end
                            }
                        })
                    end,
                    __newindex = function(_, key, value)
                        local token = ffi.new("CUtlStringToken", murmur2hash(key))
                        local typ = type(value)
                        if typ == "boolean" then event:SetBool(token, value) end
                        if typ == "number" then event:SetInt(token, value) end
                        if typ == "string" then event:SetString(token, value) end
                        if ffi.istype("char*", value) then event:SetString(token, value) end
                        if ffi.istype("float", value) then event:SetFloat(token, value) end
                        if ffi.istype("uint64_t", value) then event:SetUint64(token, value) end
                    end
                }))
            end

            return fnfireEventClientSide(a1, event, a3)
        end, mem.FindPattern("client.dll", "48 89 5C 24 ?? 56 57 41 54 48 83 EC 30 48 8B F2"))
    end

    local function userid_to_entindex(userid)
        local playercontroller = entities.GetByIndex(userid + 1)
        if not playercontroller then return end
        local playerpawn = playercontroller:GetPropEntity "m_hPlayerPawn"
        if not playerpawn then return end
        return playerpawn:GetIndex()
    end

    client.AllowListener "item_equip"
    client.AllowListener "grenade_thrown"

    local switch_to_flash_at, next_command_at
    local grenade_enable_reference = gui.Checkbox(gui.Reference("Misc", "General", "Extra"), "fastgrenade", "Fast Grenade", true)
    grenade_enable_reference:SetDescription "Quick throw grenade."

    callbacks.Register("Draw", function()
        if not client.GetLocalPlayerIndex() then return end

        local tickcount = globals.TickCount()
        if switch_to_flash_at ~= nil then
            if tickcount > next_command_at then
                next_command_at = tickcount + 1
                client.Command "slot7;"
                if switch_to_flash_at < tickcount then
                    switch_to_flash_at = nil
                end
            end
        end
    end)

    set_event_callback("item_equip", function(e)
        local userid, item = e.userid:int(), e.item:string()

        if userid_to_entindex(userid) == client.GetLocalPlayerIndex() then
            if item == "flashbang" then
                switch_to_flash_at = nil
                next_command_at = nil
            end
        end
    end)

    set_event_callback("grenade_thrown", function(e)
        if not grenade_enable_reference:GetValue() then return end

        local userid, grenade = e.userid:int(), e.weapon:string()
        if userid_to_entindex(userid) == client.GetLocalPlayerIndex() then
            if grenade == "flashbang" then
                client.Command "slot3;"
                switch_to_flash_at = globals.TickCount() + 15
                next_command_at = globals.TickCount()
            else
                client.Command "slot3; slot2; slot1;"
            end
        end
    end)
end, print)

xpcall(function()
    local ffi = assert(ffi, "ffi is not enabled")
    local C = ffi.C

    ---@diagnostic disable
    ---@format disable-next
    local create_interface = (function()ffi.cdef"void* GetModuleHandleA(const char*)"ffi.cdef"void* GetProcAddress(void*, const char*)"local a=ffi.typeof"void*(__cdecl*)(const char*, int*)"return function(b,c)local d=C.GetModuleHandleA(b)if d==nil then return nil end;local e=C.GetProcAddress(d,"CreateInterface")if e==nil then return nil end;local f=ffi.cast(a,e)(c,nil)if f==nil then return nil end;return f end end)()
    ---@format disable-next
    local vtable_bind, vtable_thunk = (function()local a=(function()local b=ffi.typeof"void***"return function(c,d,e)return ffi.cast(e,ffi.cast(b,c)[0][d])end end)()local function f(c,d,e,...)local g=a(c,d,ffi.typeof(e,...))return function(...)return g(c,...)end end;local function h(d,e,...)e=ffi.typeof(e,...)return function(c,...)return a(c,d,e)(c,...)end end;return f,h end)()
    ---@format disable-next
    local schema = (function()local a=debug.getregistry()._PRELOAD["table.new"]()local b=ffi.typeof("struct {void* m_pSelf; const char* m_pszName; const char* m_pszModule; int m_nSize; int16_t m_nFieldSize; int16_t m_nStaticFieldsSize; int16_t m_nStaticMetadataSize; uint8_t m_unAlignOf; uint8_t m_bHasBaseClass; int16_t m_nTotalClassSize; int16_t m_nDerivedClassSize; $* m_pFields;}",ffi.typeof"struct {const char* m_pszName; void* m_pSchemaType; int32_t m_nSingleInheritanceOffset; int32_t m_nMetadataSize; void* m_pMetadata;}")local c=create_interface("schemasystem.dll","SchemaSystem_001")local d=vtable_bind(c,13,"void*(__thiscall*)(void*, const char*, void*)")local e=(function()return function(f,g)local h=ffi.typeof("$*[1]",b)()vtable_thunk(2,"void(__thiscall*)(void*, void*, const char*)")(f,h,g)return h[0]end end)()local i=ffi.typeof"uint8_t*"local j=ffi.typeof"uint16_t*"local k=ffi.typeof"uintptr_t"local l=ffi.typeof("$*",k)local m=ffi.typeof"const char**"return setmetatable({},{__call=function(self,n,o)if not self[n]then return error(string.format("undefined class '%s'",n))end;return assert(self[n][o],string.format("undefined declared'%s'",o))end,__index={open=function(self,p)local q=d(p,nil)if q==nil then return error(string.format("invalid type range to find '%s'",p))end;for n,r in(function(s)local h=ffi.cast(l,ffi.cast(k,s)+0x0440)[0]local t=ffi.cast(j,ffi.cast(k,s)+0x0456)[0]local u=-1;return function()u=u+1;if u<t then local v=ffi.string(ffi.cast(m,ffi.cast(l,ffi.cast(i,h+u*0x18)+0x10)[0]+0x8)[0])return v,e(q,v)end end end)(q)do local t=r.m_nFieldSize;local w=r.m_pFields;if not self[n]then self[n]=a(0,t)end;for u=0,t-1 do local x=w[u]local o=ffi.string(x.m_pszName)if not self[n][o]then self[n][o]=x.m_nSingleInheritanceOffset end end end;return self end}}):open"client.dll"end)()
    ---@diagnostic enable

    local CGameEntitySystem = ffi.cast("void**", ffi.cast("uintptr_t", create_interface("engine2.dll", "GameResourceServiceClientV001")) + 0x58)[0]
    ---@format disable-next
    local native_GetEntityInstance = (function(a)local b=ffi.cast("void*(__thiscall*)(void*, int)",mem.FindPattern("client.dll","81 FA ?? ?? ?? ?? 77 36 8B C2 C1 F8 09 83 F8 3F 77 2C 48 98"))return function(c)return b(a,c)end end)(CGameEntitySystem)

    local reference = gui.Reference("Visuals", "Other", "Effects")
    local color_reference = gui.ColorPicker(reference, "skybox.modulation", "Skybox Modulation", 255, 255, 255, 255)

    local fnptr = ffi.cast("void*(__thiscall*)(void*)", mem.FindPattern("client.dll", "48 8B C4 48 89 58 18 48 89 70 20 55 57 41 54 41 55"))

    local function sky_color(r, g, b, a)
        for _, entity in pairs(entities.FindByClass "C_EnvSky") do
            local instance = native_GetEntityInstance(entity:GetIndex())
            if instance == nil then goto continue end

            local p = ffi.cast("uintptr_t", instance)

            local tint_color = ffi.cast("uint8_t*", p + schema(entity:GetClass(), "m_vTintColor"))
            tint_color[0] = r
            tint_color[1] = g
            tint_color[2] = b
            tint_color[3] = a

            entity:SetPropFloat(math.max(0.01, a / 255), "m_flBrightnessScale")

            fnptr(instance)
            ::continue::
        end
    end

    callbacks.Register("Unload", function() sky_color(255, 255, 255, 255) end)
    callbacks.Register("CreateMove", function()
        local r, g, b, a = color_reference:GetValue()
        sky_color(r, g, b, a)
    end)
end, print)

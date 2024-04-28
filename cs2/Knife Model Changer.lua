xpcall(function()
    local ffi = assert(ffi, "ffi is not enabled")
    local C = ffi.C

    ---@diagnostic disable
    ---@format disable-next
    local create_interface = (function()ffi.cdef"void* GetModuleHandleA(const char*)"ffi.cdef"void* GetProcAddress(void*, const char*)"local a=ffi.typeof"void*(__cdecl*)(const char*, int*)"return function(b,c)local d=C.GetModuleHandleA(b)if d==nil then return nil end;local e=C.GetProcAddress(d,"CreateInterface")if e==nil then return nil end;local f=ffi.cast(a,e)(c,nil)if f==nil then return nil end;return f end end)()
    ---@format disable-next
    local vtable_bind, vtable_thunk = (function()local a=(function()local b=ffi.typeof"void***"return function(c,d,e)return ffi.cast(e,ffi.cast(b,c)[0][d])end end)()local function f(c,d,e,...)local g=a(c,d,ffi.typeof(e,...))return function(...)return g(c,...)end end;local function h(d,e,...)e=ffi.typeof(e,...)return function(c,...)return a(c,d,e)(c,...)end end;return f,h end)()
    ---@format disable-next
    ---@type fun(classname: string, propname: string): integer
    local schema = (function()local a=debug.getregistry()._PRELOAD["table.new"]()local b=ffi.typeof("struct {void* m_pSelf; const char* m_pszName; const char* m_pszModule; int m_nSize; int16_t m_nFieldSize; int16_t m_nStaticFieldsSize; int16_t m_nStaticMetadataSize; uint8_t m_unAlignOf; uint8_t m_bHasBaseClass; int16_t m_nTotalClassSize; int16_t m_nDerivedClassSize; $* m_pFields;}",ffi.typeof"struct {const char* m_pszName; void* m_pSchemaType; int32_t m_nSingleInheritanceOffset; int32_t m_nMetadataSize; void* m_pMetadata;}")local c=create_interface("schemasystem.dll","SchemaSystem_001")local d=vtable_bind(c,13,"void*(__thiscall*)(void*, const char*, void*)")local e=(function()return function(f,g)local h=ffi.typeof("$*[1]",b)()vtable_thunk(2,"void(__thiscall*)(void*, void*, const char*)")(f,h,g)return h[0]end end)()local i=ffi.typeof"uint8_t*"local j=ffi.typeof"uint16_t*"local k=ffi.typeof"uintptr_t"local l=ffi.typeof("$*",k)local m=ffi.typeof"const char**"return setmetatable({},{__call=function(self,n,o)if not self[n]then return error(string.format("undefined class '%s'",n))end;return assert(self[n][o],string.format("undefined declared'%s'",o))end,__index={open=function(self,p)local q=d(p,nil)if q==nil then return error(string.format("invalid type range to find '%s'",p))end;for n,r in(function(s)local h=ffi.cast(l,ffi.cast(k,s)+0x04d0)[0]local t=ffi.cast(j,ffi.cast(k,s)+0x04e6)[0]local u=-1;return function()u=u+1;if u<t then local v=ffi.string(ffi.cast(m,ffi.cast(l,ffi.cast(i,h+u*0x18)+0x10)[0]+0x8)[0])return v,e(q,v)end end end)(q)do local t=r.m_nFieldSize;local w=r.m_pFields;if not self[n]then self[n]=a(0,t)end;for u=0,t-1 do local x=w[u]local o=ffi.string(x.m_pszName)if not self[n][o]then self[n][o]=x.m_nSingleInheritanceOffset end end end;return self end}}):open"client.dll"end)()
    ---@format disable-next
    local detour = (function()local a={}ffi.cdef"int VirtualProtect(void*, uint64_t, unsigned long, unsigned long*)"local b=0x40;function a.new(c,d,e)local f=12;local g=ffi.new("uint8_t[?]",f)ffi.copy(ffi.cast("void*",g),ffi.cast("const void*",e),f)local h=ffi.cast(c,e)local i=ffi.new("uint8_t[12]",{0x48,0xB8,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xFF,0xE0})ffi.cast("int64_t*",i+2)[0]=ffi.cast("int64_t",ffi.cast("void*",ffi.cast(c,d)))local j=ffi.new"unsigned long[1]"return setmetatable({},{__call=function(self,...)self:remove()local k=h(...)self:install()return k end,__index={install=function(self)C.VirtualProtect(ffi.cast("void*",e),f,b,j)ffi.copy(ffi.cast("void*",e),ffi.cast("const void*",i),f)C.VirtualProtect(ffi.cast("void*",e),f,j[0],j)return self end,remove=function(self)C.VirtualProtect(ffi.cast("void*",e),f,b,j)ffi.copy(ffi.cast("void*",e),ffi.cast("const void*",g),f)C.VirtualProtect(ffi.cast("void*",e),f,j[0],j)return self end}}):install()end;return a end)()
    ---@diagnostic enable
    local localize = (function()
        local native_FindSafe = vtable_bind(create_interface("localize.dll", "Localize_001"), 17, "const char*(__thiscall*)(void*, const char*)")
        return function(key) return ffi.string(native_FindSafe(key)) end
    end)()

    local fire_event, set_event_callback, unset_event_callback
    do
        local events = {}
        function fire_event(name, ...)
            for _, callback in pairs(events[name] or {}) do
                callback(...)
            end
        end

        function set_event_callback(name, callback)
            events[name] = events[name] or {}
            events[name][tostring(callback)] = callback
        end

        function unset_event_callback(name, callback)
            if type(events[name]) ~= "table" then return end
            events[name][tostring(callback)] = nil
        end
    end

    do
        local framestage_t = {
            frame_start = 0,
            frame_net_update_start = 1,
            frame_net_update_postdataupdate_start = 2,
            frame_net_update_postdataupdate_end = 3,
            frame_net_update_end = 4,
            frame_render_start = 5,
            frame_render_end = 6
        }

        local fnFrameStageNotify
        callbacks.Register("Unload", function() fnFrameStageNotify:remove() end)
        fnFrameStageNotify = detour.new("void*(__fastcall*)(void*, int)", function(thisptr, framestage)
            for key, value in pairs(framestage_t) do if value == framestage then fire_event(key) end end

            return fnFrameStageNotify(thisptr, framestage)
        end, mem.FindPattern("client.dll", "48 89 5C 24 ?? 56 48 83 EC ?? 8B 05 ?? ?? ?? ?? 8D 5A"))
    end

    local fnSetModel = ffi.cast("void*(__thiscall*)(void*, const char*)", mem.FindPattern("client.dll", "48 89 5C 24 10 48 89 7C 24 20 55 48 8B EC 48 83 EC 50"))

    local CGameEntitySystem = ffi.cast("void**", ffi.cast("uintptr_t", create_interface("engine2.dll", "GameResourceServiceClientV001")) + 0x58)[0]
    ---@format disable-next
    local native_GetEntityInstance = (function(a)local b=ffi.cast("void*(__thiscall*)(void*, int)",mem.FindPattern("client.dll","81 FA ?? ?? ?? ?? 77 36 8B C2 C1 F8 09 83 F8 3F 77 2C 48 98"))return function(c)return b(a,c)end end)(CGameEntitySystem)

    local knifes = {
        ["#SFUI_WPNHUD_KnifeBayonet"] = "weapons/models/knife/knife_bayonet/weapon_knife_bayonet.vmdl",
        ["#SFUI_WPNHUD_KnifeCSS"] = "weapons/models/knife/knife_css/weapon_knife_css.vmdl",
        ["#SFUI_WPNHUD_KnifeFlip"] = "weapons/models/knife/knife_flip/weapon_knife_flip.vmdl",
        ["#SFUI_WPNHUD_KnifeGut"] = "weapons/models/knife/knife_gut/weapon_knife_gut.vmdl",
        ["#SFUI_WPNHUD_KnifeKaram"] = "weapons/models/knife/knife_karambit/weapon_knife_karambit.vmdl",
        ["#SFUI_WPNHUD_KnifeM9"] = "weapons/models/knife/knife_m9/weapon_knife_m9.vmdl",
        ["#SFUI_WPNHUD_KnifeTactical"] = "weapons/models/knife/knife_tactical/weapon_knife_tactical.vmdl",
        ["#SFUI_WPNHUD_knife_falchion_advanced"] = "weapons/models/knife/knife_falchion/weapon_knife_falchion.vmdl",
        ["#SFUI_WPNHUD_knife_survival_bowie"] = "weapons/models/knife/knife_bowie/weapon_knife_bowie.vmdl",
        ["#SFUI_WPNHUD_Knife_Butterfly"] = "weapons/models/knife/knife_butterfly/weapon_knife_butterfly.vmdl",
        ["#SFUI_WPNHUD_knife_push"] = "weapons/models/knife/knife_push/weapon_knife_push.vmdl",
        ["#SFUI_WPNHUD_knife_cord"] = "weapons/models/knife/knife_cord/weapon_knife_cord.vmdl",
        ["#SFUI_WPNHUD_knife_canis"] = "weapons/models/knife/knife_canis/weapon_knife_canis.vmdl",
        ["#SFUI_WPNHUD_knife_ursus"] = "weapons/models/knife/knife_ursus/weapon_knife_ursus.vmdl",
        ["#SFUI_WPNHUD_knife_gypsy_jackknife"] = "weapons/models/knife/knife_navaja/weapon_knife_navaja.vmdl",
        ["#SFUI_WPNHUD_knife_outdoor"] = "weapons/models/knife/knife_outdoor/weapon_knife_outdoor.vmdl",
        ["#SFUI_WPNHUD_knife_stiletto"] = "weapons/models/knife/knife_stiletto/weapon_knife_stiletto.vmdl",
        ["#SFUI_WPNHUD_knife_widowmaker"] = "weapons/models/knife/knife_talon/weapon_knife_talon.vmdl",
        ["#SFUI_WPNHUD_knife_skeleton"] = "weapons/models/knife/knife_skeleton/weapon_knife_skeleton.vmdl",
        ["#SFUI_WPNHUD_knife_kukri"] = "weapons/models/knife/knife_kukri/weapon_knife_kukri.vmdl",
    }

    local localizes = {}
    for key in pairs(knifes) do
        localizes[localize(key)] = key
    end

    local localize_key = function(t)
        local res = {}
        for key in pairs(t) do table.insert(res, localize(key)) end
        table.sort(res)
        return unpack(res)
    end

    local ref = gui.Reference("Visuals", "Skins (Beta)", "List")
    local knife_model_reference = gui.Combobox(ref, "model.knife", localize("#Inv_Category_melee"), localize_key(knifes))

    local fnUpdateSubclass = ffi.cast("void*(__fastcall*)(void*)", mem.FindPattern("client.dll", "40 53 48 83 EC 30 48 8B 41 10 48 8B D9 8B 50 30"))
    local native_UpdateVData = vtable_thunk(180, "void(__thiscall*)(void*)")

    local subclassid_t =
    {
        ["#SFUI_WPNHUD_KnifeBayonet"] = 3933374535,
        ["#SFUI_WPNHUD_KnifeCSS"] = 3787235507,
        ["#SFUI_WPNHUD_KnifeFlip"] = 4046390180,
        ["#SFUI_WPNHUD_KnifeGut"] = 2047704618,
        ["#SFUI_WPNHUD_KnifeKaram"] = 1731408398,
        ["#SFUI_WPNHUD_KnifeM9"] = 1638561588,
        ["#SFUI_WPNHUD_KnifeTactical"] = 2282479884,
        ["#SFUI_WPNHUD_knife_falchion_advanced"] = 3412259219,
        ["#SFUI_WPNHUD_knife_survival_bowie"] = 2511498851,
        ["#SFUI_WPNHUD_Knife_Butterfly"] = 1353709123,
        ["#SFUI_WPNHUD_knife_push"] = 4269888884,
        ["#SFUI_WPNHUD_knife_cord"] = 1105782941,
        ["#SFUI_WPNHUD_knife_canis"] = 275962944,
        ["#SFUI_WPNHUD_knife_ursus"] = 1338637359,
        ["#SFUI_WPNHUD_knife_gypsy_jackknife"] = 3230445913,
        ["#SFUI_WPNHUD_knife_outdoor"] = 3206681373,
        ["#SFUI_WPNHUD_knife_stiletto"] = 2595277776,
        ["#SFUI_WPNHUD_knife_widowmaker"] = 4029975521,
        ["#SFUI_WPNHUD_knife_skeleton"] = 365028728,
        ["#SFUI_WPNHUD_knife_kukri"] = 3845286452,
    }

    set_event_callback("frame_render_end", function()
        local localpawn = entities.GetLocalPawn()
        if localpawn == nil or localpawn:GetHealth() == 0 then return end

        if localpawn:GetWeaponType() ~= 0 then return end

        local localpawn_instance = ffi.cast("uintptr_t", native_GetEntityInstance(localpawn:GetIndex()))
        if localpawn_instance == 0 then return end

        local weapon_services = ffi.cast("uintptr_t*", localpawn_instance + schema("C_BasePlayerPawn", "m_pWeaponServices"))[0]
        if weapon_services == 0 then return end

        local activeweapon_index = bit.band(ffi.cast("uintptr_t*", weapon_services + schema("CPlayer_WeaponServices", "m_hActiveWeapon"))[0], 0x7fff)
        if activeweapon_index == 0xffffffff then return end

        local activeweapon_instance = native_GetEntityInstance(activeweapon_index)
        if activeweapon_instance == nil then return end

        local viewmodel = unpack(entities.FindByClass("C_CSGOViewModel"))
        if viewmodel == nil then return end

        local viewmodel_instance = native_GetEntityInstance(viewmodel:GetIndex())
        if viewmodel_instance == nil then return end

        local model = knifes[localizes[knife_model_reference:GetString()]]
        if not model then return end

        local viewmodelweapon_index = bit.band(ffi.cast("uintptr_t*", ffi.cast("uintptr_t", viewmodel_instance) + schema("C_BaseViewModel", "m_hWeapon"))[0], 0x7fff)
        if viewmodelweapon_index == 0xffffffff then return end

        fnSetModel(activeweapon_instance, model)
        if viewmodelweapon_index == activeweapon_index then fnSetModel(viewmodel_instance, model) end
        ffi.cast("uintptr_t*", ffi.cast("uintptr_t*", ffi.cast("uintptr_t", viewmodel_instance) + 0xd08)[0] + 0x2e0)[0] = 0

        --修复特殊检视动画 updata classid
        ffi.cast("uint32_t*", ffi.cast("uintptr_t", activeweapon_instance) + schema("C_BaseEntity", "m_nSubclassID"))[0] = subclassid_t[localizes[knife_model_reference:GetString()]]
        fnUpdateSubclass(activeweapon_instance)

        --会崩溃 hh
        -- local weapon_vdata = ffi.cast("void**", ffi.cast("uintptr_t", subclassid) + 0x8)[0]
        -- if weapon_vdata == nil then return end

        -- ffi.cast("const char**", ffi.cast("uintptr_t", weapon_vdata) + schema("CCSWeaponBaseVData", "m_szName"))[0] = model:match("/([^/]+)%.vmdl$")
        -- native_UpdateVData(activeweapon_instance)
    end)

    do
        local native_IsViewModel = vtable_thunk(242, "bool(__thiscall*)(void*)")

        local hkSetModel
        callbacks.Register("Unload", function() hkSetModel:remove() end)
        hkSetModel = detour.new("void*(__fastcall*)(void*, const char*)", function(thisptr, model)
            xpcall(function()
                local localpawn = entities.GetLocalPawn()
                if localpawn == nil or localpawn:GetHealth() == 0 or localpawn:GetWeaponType() ~= 0 then return end

                if thisptr == nil or not native_IsViewModel(thisptr) then return end

                local weapon_index = bit.band(ffi.cast("uintptr_t*", ffi.cast("uintptr_t", thisptr) + schema("C_BaseViewModel", "m_hWeapon"))[0], 0x7fff)
                if weapon_index == 0xffffffff then return end

                local weapon_instance = native_GetEntityInstance(weapon_index)
                if weapon_instance == nil then return end

                model = knifes[localizes[knife_model_reference:GetString()]] or model
            end, print)

            return hkSetModel(thisptr, model)
        end, mem.FindPattern("client.dll", "48 89 5C 24 10 48 89 7C 24 20 55 48 8B EC 48 83 EC 50"))
    end
end, function(message)
    print(message)
    UnloadScript(GetScriptName())
end)

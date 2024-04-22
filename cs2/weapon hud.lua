---@diagnostic disable-next-line: undefined-global
local ffi = ffi or require "ffi"
local schema = (function()
    ---@diagnostic disable-next-line: undefined-global
    local ffi = ffi or require "ffi"
    local table_new = debug.getregistry()._PRELOAD["table.new"]() or require "table.new"

    local C = ffi.C

    ---@diagnostic disable
    ---@format disable-next
local create_interface = (function()ffi.cdef"void* GetModuleHandleA(const char*)"ffi.cdef"void* GetProcAddress(void*, const char*)"local a=ffi.typeof"void*(__cdecl*)(const char*, int*)"return function(b,c)local d=C.GetModuleHandleA(b)if d==nil then return nil end;local e=C.GetProcAddress(d,"CreateInterface")if e==nil then return nil end;local f=ffi.cast(a,e)(c,nil)if f==nil then return nil end;return f end end)()
    ---@format disable-next
local vtable_bind, vtable_thunk = (function()local a=(function()local b=ffi.typeof"void***"return function(c,d,e)return ffi.cast(e,ffi.cast(b,c)[0][d])end end)()local function f(c,d,e,...)local g=a(c,d,ffi.typeof(e,...))return function(...)return g(c,...)end end;local function h(d,e,...)e=ffi.typeof(e,...)return function(c,...)return a(c,d,e)(c,...)end end;return f,h end)()
    ---@diagnostic enable

    local SchemaType_t = ffi.typeof [[
    struct {
        void*       vftable;
        const char* m_pszName;
    }
]]

    local SchemaClassFieldData_t = ffi.typeof([[
    struct {
        const char* m_pszName;
        $*          m_pSchemaType;
        int32_t     m_nSingleInheritanceOffset;
        int32_t     m_nMetadataSize;
        void*       m_pMetadata;
    }
]], SchemaType_t)

    local SchemaBaseClassInfoData_t = ffi.typeof [[
    struct {
        unsigned int m_unOffset;
        void*        m_pPrevByClass;
    }
]]

    local SchemaClassInfoData_t = ffi.typeof([[
    struct {
        void*       m_pSelf;
        const char* m_pszName;
        const char* m_pszModule;
        int         m_nSize;
        int16_t     m_nFieldSize;
        int16_t     m_nStaticFieldsSize;
        int16_t     m_nStaticMetadataSize;
        uint8_t     m_unAlignOf;
        uint8_t     m_bHasBaseClass;
        int16_t     m_nTotalClassSize;
        int16_t     m_nDerivedClassSize;
        $*          m_pFields;
        void*       m_pStaticFields;
        $*          m_pBaseClasses;
        void*       m_pFieldMetadataOverrides;
        void*       m_pStaticMetadata;
        void*       m_pTypeScope;
        $*          m_pSchemaType;
        uint8_t     m_nClassFlags;
        uint32_t    m_unSequence;
        void*       m_pFn;
    }
]], SchemaClassFieldData_t, SchemaBaseClassInfoData_t, SchemaType_t)

    local CSchemaSystem = create_interface("schemasystem.dll", "SchemaSystem_001")
    local native_FindTypeScopeForModule = vtable_bind(CSchemaSystem, 13, "void*(__thiscall*)(void*, const char*, void*)")
    local native_FindDeclaredClass = (function()
        return function(instance, name)
            local ptr = ffi.typeof("$*[1]", SchemaClassInfoData_t)()
            vtable_thunk(2, "void(__thiscall*)(void*, void*, const char*)")(instance, ptr, name)
            return ptr[0]
        end
    end)()

    local uint8_t_ptr = ffi.typeof "uint8_t*"
    local uint16_t_ptr = ffi.typeof "uint16_t*"
    local uintptr_t = ffi.typeof "uintptr_t"
    local uintptr_t_ptr = ffi.typeof("$*", uintptr_t)
    local cstr_t_ptr = ffi.typeof "const char**"

    return setmetatable({}, {
        __call = function(self, classname, propname)
            if not self[classname] then
                error(string.format("undefined declared class '%s'", classname), 2)
            end

            if not self[classname][propname] then
                error(string.format("undefined declared prop '%s'", propname), 2)
            end

            return self[classname][propname]
        end,
        __index = {
            open = function(self, modname)
                local typescope = native_FindTypeScopeForModule(modname, nil)
                if typescope == nil then error(string.format("invalid type range to find '%s'", modname), 2) end

                for classname, declared in (function(ts)
                    local p = ffi.cast(uintptr_t_ptr, ffi.cast(uintptr_t, ts) + 0x04d0)[0]
                    local size = ffi.cast(uint16_t_ptr, ffi.cast(uintptr_t, ts) + 0x04e6)[0]
                    local i = 0
                    return function()
                        if i < size then
                            local key = ffi.string(ffi.cast(cstr_t_ptr, ffi.cast(uintptr_t_ptr, ffi.cast(uint8_t_ptr, p + i * 0x18) + 0x10)[0] + 0x8)[0])
                            i = i + 1
                            return key, native_FindDeclaredClass(typescope, key)
                        end
                    end
                end)(typescope) do
                    local size = declared.m_nFieldSize
                    local fields = declared.m_pFields

                    if not self[classname] then
                        self[classname] = table_new(0, declared.m_nFieldSize)
                    end

                    for i = 0, size - 1 do
                        local field = fields[i]
                        local propname = ffi.string(field.m_pszName)

                        if not self[classname][propname] then
                            local name = ffi.string(field.m_pSchemaType.m_pszName)
                            self[classname][propname] = {
                                type = name,
                                offset = field.m_nSingleInheritanceOffset
                            }
                        end
                    end
                end

                return self
            end
        }
    }):open "client.dll"
end)()

local C = ffi.C

---@diagnostic disable
---@format disable-next
local create_interface = (function()ffi.cdef"void* GetModuleHandleA(const char*)"ffi.cdef"void* GetProcAddress(void*, const char*)"local a=ffi.typeof"void*(__cdecl*)(const char*, int*)"return function(b,c)local d=C.GetModuleHandleA(b)if d==nil then return nil end;local e=C.GetProcAddress(d,"CreateInterface")if e==nil then return nil end;local f=ffi.cast(a,e)(c,nil)if f==nil then return nil end;return f end end)()
---@format disable-next
local find_signature = (function()ffi.cdef"void* GetModuleHandleA(const char*)"ffi.cdef"void* GetProcAddress(void*, const char*)"ffi.cdef"void* GetCurrentProcess()"ffi.cdef"int K32GetModuleInformation(void*, void*, void*, unsigned long)"local a=ffi.typeof"struct {void* lpBaseOfDll;unsigned long SizeOfImage;void* EntryPoint;}"local b=ffi.typeof"uint8_t*"return function(c,d,e)d=d.."\0"if#d/3==0 or#d%3~=0 then return nil end;local f=C.GetModuleHandleA(c)if f==nil then return nil end;local g=a()if not C.K32GetModuleInformation(C.GetCurrentProcess(),f,g,ffi.sizeof(a))then return nil end;local h={}for i in string.gmatch(d:gsub("%?%?","00"),"(%x%x)")do local j=tonumber(i,16)if not j then return nil end;table.insert(h,j)end;local k=b(f)for l=0,g.SizeOfImage-#h-1 do local m=true;for n=1,#h do local j=h[n]if j~=0 and k[l+n-1]~=j then m=false;break end end;if m then return k+l+(e or 0)end end;return nil end end)()
---@format disable-next
local vtable_bind, vtable_thunk = (function()local a=(function()local b=ffi.typeof"void***"return function(c,d,e)return ffi.cast(e,ffi.cast(b,c)[0][d])end end)()local function f(c,d,e,...)local g=a(c,d,ffi.typeof(e,...))return function(...)return g(c,...)end end;local function h(d,e,...)e=ffi.typeof(e,...)return function(c,...)return a(c,d,e)(c,...)end end;return f,h end)()
---@diagnostic enable

local CGameEntitySystem = ffi.cast("void**", ffi.cast("uintptr_t", create_interface("engine2.dll", "GameResourceServiceClientV001")) + 0x58)[0]

local native_GetEntityInstance = (function(instance)
    local fnptr = ffi.cast("void*(__thiscall*)(void*, int)", find_signature("client.dll", "81 FA ?? ?? ?? ?? 77 36 8B C2 C1 F8 09 83 F8 3F 77 2C 48 98"))
    return function(idx) return fnptr(instance, idx) end
end)(CGameEntitySystem)

local function circle_outline(x, y, radius, start_degrees, percentage, thickness, accuracy)
    accuracy = accuracy or 1
    local inner_radius = radius - thickness

    for i = start_degrees, start_degrees + math.abs(percentage * 360) - accuracy, accuracy do
        local radians = math.rad(i)
        local radians_next = math.rad(i + accuracy)

        local xa = x + math.cos(radians) * radius
        local ya = y + math.sin(radians) * radius
        local xb = x + math.cos(radians_next) * radius
        local yb = y + math.sin(radians_next) * radius

        local xc = x + math.cos(radians) * inner_radius
        local yc = y + math.sin(radians) * inner_radius
        local xd = x + math.cos(radians_next) * inner_radius
        local yd = y + math.sin(radians_next) * inner_radius

        draw.Triangle(xa, ya, xb, yb, xc, yc)
        draw.Triangle(xc, yc, xb, yb, xd, yd)
    end
end

local function intersect(x, y, w, h)
    local cx, cy = input.GetMousePos()
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

local weapon_icon = setmetatable({}, {
    __index = function(t, k)
        local icon = weapon_icon_raw[k]
        t[k] = {draw.CreateTexture(unpack(icon)), icon[2], icon[3]}
        return t[k]
    end
})

local background_svg = [[
    <?xml version="1.0" encoding="utf-8"?>
    <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
    <svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="300px" height="300px" viewBox="0 0 200 200" xml:space="preserve">
        <defs>
            <radialGradient id="background-gradient" cx="50%" cy="50%" r="50%">
                <stop offset="80%" stop-color="rgb(13,13,13)" stop-opacity="0.5" />
                <stop offset="100%" stop-color="rgb(130,130,130)" stop-opacity="0.5" />
            </radialGradient>
        </defs>

        <ellipse cx="50%" cy="50%" rx="74" ry="74" fill="url(#background-gradient)" />
    </svg>
]]
local background_texture = draw.CreateTexture(common.RasterizeSVG(background_svg))

local ctype_t = setmetatable({}, {
    __index = function(t, k)
        t[k] = ffi.typeof(k)
        return t[k]
    end
})

local hud = {
    x = 250,
    y = 250,
    dragging = false,
}

local font = draw.CreateFont("verdana", 13)
local font_bold = draw.CreateFont("verdana bold", 13)
local menu_reference = gui.Reference("menu")
callbacks.Register("Draw", function()
    local pawn = entities.GetLocalPawn()
    if pawn == nil then return end
    local pawn_instance = native_GetEntityInstance(pawn:GetIndex())

    local weapon_services_ptr = ffi.cast(ctype_t["void**"], ffi.cast(ctype_t["uintptr_t"], pawn_instance) + schema("C_BasePlayerPawn", "m_pWeaponServices").offset)[0]
    if weapon_services_ptr == nil then return end

    local health = math.min(100, pawn:GetHealth())
    local armor = math.min(100, ffi.cast(ctype_t["int32_t*"], ffi.cast(ctype_t["uintptr_t"], pawn_instance) + schema("C_CSPlayerPawnBase", "m_ArmorValue").offset)[0])

    local active_weapon_handle = ffi.cast(ctype_t["uintptr_t*"], ffi.cast(ctype_t["uintptr_t"], weapon_services_ptr) + schema("CPlayer_WeaponServices", "m_hActiveWeapon").offset)[0]
    if active_weapon_handle == 0xffffffff then return end

    local active_weapon_instance = native_GetEntityInstance(bit.band(active_weapon_handle, 0x7fff))
    if active_weapon_instance == nil then return end

    local entity_ptr = ffi.cast(ctype_t["void**"], ffi.cast(ctype_t["uintptr_t"], active_weapon_instance) + schema("CEntityInstance", "m_pEntity").offset)[0]
    if entity_ptr == nil then return end

    local weapon_vdata = ffi.cast(ctype_t["void**"], ffi.cast(ctype_t["uintptr_t"], active_weapon_instance) + schema("C_BaseEntity", "m_nSubclassID").offset + 0x8)[0]
    if weapon_vdata == nil then return end

    local designer_name = ffi.cast(ctype_t["char**"], ffi.cast(ctype_t["uintptr_t"], entity_ptr) + schema("CEntityIdentity", "m_designerName").offset)[0]
    if designer_name == nil then return end

    local weapon_name = ffi.string(designer_name):gsub("^weapon_", "")
    local weapon_clip1 = ffi.cast(ctype_t["int32_t*"], ffi.cast(ctype_t["uintptr_t"], active_weapon_instance) + schema("C_BasePlayerWeapon", "m_iClip1").offset)[0]
    local weapon_reserve_ammo = ffi.cast(ctype_t["int32_t*"], ffi.cast(ctype_t["uintptr_t"], active_weapon_instance) + schema("C_BasePlayerWeapon", "m_pReserveAmmo").offset)[0]
    local weapon_max_clip1 = ffi.cast(ctype_t["int32_t*"], ffi.cast(ctype_t["uintptr_t"], weapon_vdata) + schema("CBasePlayerWeaponVData", "m_iMaxClip1").offset)[0]

    local cx, cy = input.GetMousePos()
    local left_click = input.IsButtonDown(0x01)
    if menu_reference:IsActive() then
        if hud.dragging and not left_click then
            hud.dragging = false
        end

        if hud.dragging and left_click then
            hud.x = cx - hud.drag_x
            hud.y = cy - hud.drag_y
        end

        if intersect(hud.x, hud.y, 150, 150) and left_click then
            hud.dragging = true
            hud.drag_x = cx - hud.x
            hud.drag_y = cy - hud.y
        end
    end

    local x, y = hud.x, hud.y
    local w, h = 150, 150
    draw.Color(255, 255, 255, 255)
    draw.SetTexture(background_texture)
    draw.FilledRect(x, y, x + w, y + h)

    draw.Color(255, 255, 255, 175)

    if weapon_clip1 == -1 then
        circle_outline(x + w * 0.5, y + h * 0.5, 55, 0, 1, 5)
    else
        for i = 1, weapon_clip1 do
            circle_outline(x + w * 0.5, y + h * 0.5, 55, 270 - (1 / weapon_max_clip1) * 360 * i, (1 / weapon_max_clip1) - 0.005, 5)
        end

        draw.SetFont(font)
        draw.Color(255, 255, 255, 255)
        local tw, th = draw.GetTextSize(weapon_reserve_ammo)
        draw.TextShadow(math.abs(x + w * 0.5 - tw * 0.5), math.abs(y + h * 0.5 - th * 0.5 + 35), weapon_reserve_ammo)
    end

    draw.Color(10, 10, 10, 75)
    circle_outline(x + w * 0.5, y + h * 0.5, 65, 120, 0.34, 5)
    circle_outline(x + w * 0.5, y + h * 0.5, 65, 300, 0.34, 5)

    do
        local hpr = (50 * health / 100) + (255 * (1 - health / 100))
        local hpg = (255 * health / 100) + (75 * (1 - health / 100))
        local hpb = (65 * health / 100) + (20 * (1 - health / 100))
        draw.SetFont(font_bold)
        draw.Color(hpr, hpg, hpb, 175)
        circle_outline(x + w * 0.5, y + h * 0.5, 65, 120, 0.34 * health / 100, 5)
        local tw, th = draw.GetTextSize(health)
        draw.TextShadow(math.abs(x + w * 0.5 - tw * 0.5), math.abs(y + h * 0.5 - th * 0.5 + 65), health)
    end

    do
        draw.SetFont(font_bold)
        draw.Color(75, 75, 255, 175)
        circle_outline(x + w * 0.5, y + h * 0.5, 65, 300, 0.34 * armor / 100, 5)
        local tw, th = draw.GetTextSize(armor)
        draw.TextShadow(math.abs(x + w * 0.5 - tw * 0.5), math.abs(y + h * 0.5 - th * 0.5 - 65), armor)
    end

    local icon = weapon_icon[weapon_name]
    draw.Color(255, 255, 255, 255)
    draw.SetTexture(icon[1])
    draw.FilledRect(x + w * 0.5 - icon[2] * 0.5, y + h * 0.5 - icon[3] * 0.5, x + w * 0.5 + icon[2] * 0.5, y + h * 0.5 + icon[3] * 0.5)
end)
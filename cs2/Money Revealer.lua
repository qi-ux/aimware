xpcall(function()
    local ffi = ffi or require "ffi"
    local C = ffi.C
    ---@format disable-next
    local detour = (function()local a={}ffi.cdef"int VirtualProtect(void*, uint64_t, unsigned long, unsigned long*)"local b=0x40;function a.new(c,d,e)local f=12;local g=ffi.new("uint8_t[?]",f)ffi.copy(ffi.cast("void*",g),ffi.cast("const void*",e),f)local h=ffi.cast(c,e)local i=ffi.new("uint8_t[12]",{0x48,0xB8,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xFF,0xE0})ffi.cast("int64_t*",i+2)[0]=ffi.cast("int64_t",ffi.cast("void*",ffi.cast(c,d)))local j=ffi.new"unsigned long[1]"return setmetatable({},{__call=function(self,...)self:remove()local k=h(...)self:install()return k end,__index={install=function(self)C.VirtualProtect(ffi.cast("void*",e),f,b,j)ffi.copy(ffi.cast("void*",e),ffi.cast("const void*",i),f)C.VirtualProtect(ffi.cast("void*",e),f,j[0],j)return self end,remove=function(self)C.VirtualProtect(ffi.cast("void*",e),f,b,j)ffi.copy(ffi.cast("void*",e),ffi.cast("const void*",g),f)C.VirtualProtect(ffi.cast("void*",e),f,j[0],j)return self end}}):install()end;return a end)()

    ---@format disable-next
    local vtable_bind, vtable_thunk = (function()local a=(function()local b=ffi.typeof"void***"return function(c,d,e)return ffi.cast(e,ffi.cast(b,c)[0][d])end end)()local function f(c,d,e,...)local g=a(c,d,ffi.typeof(e,...))return function(...)return g(c,...)end end;local function h(d,e,...)e=ffi.typeof(e,...)return function(c,...)return a(c,d,e)(c,...)end end;return f,h end)()

    local schema
    do
        local table_new = debug.getregistry()["_PRELOAD"]["table.new"]()

        if not pcall(ffi.sizeof, "CSchemaType") then
            ffi.cdef [[
                typedef enum ETypeCategory {
                    Schema_Builtin = 0,
                    Schema_Ptr,
                    Schema_Bitfield,
                    Schema_FixedArray,
                    Schema_Atomic,
                    Schema_DeclaredClass,
                    Schema_DeclaredEnum,
                    Schema_None
                } ETypeCategory;

                typedef struct CSchemaType {
                    void* vftable;
                    const char* m_pszName;
                    void* m_pTypeScope;
                    uint8_t m_unTypeCategory;
                    uint8_t m_unAtomicCategory;
                } CSchemaType;
            ]]
        end

        if not pcall(ffi.sizeof, "SchemaClassFieldData_t") then
            ffi.cdef [[
                typedef struct SchemaClassFieldData_t {
                    const char* m_pszName;
                    CSchemaType* m_pSchemaType;
                    int32_t m_nSingleInheritanceOffset;
                    int32_t m_nMetadataSize;
                    void* m_pMetadata;
                } SchemaClassFieldData_t;
            ]]
        end

        if not pcall(ffi.sizeof, "SchemaBaseClassInfoData_t") then
            ffi.cdef [[
                typedef struct SchemaBaseClassInfoData_t {
                    unsigned int m_unOffset;
                    struct SchemaClassInfoData_t* m_pPrevByClass;
                } SchemaBaseClassInfoData_t;
            ]]
        end

        if not pcall(ffi.sizeof, "SchemaClassInfoData_t") then
            ffi.cdef [[
                typedef struct SchemaClassInfoData_t {
                    void* m_pSelf;
                    const char* m_pszName;
                    const char* m_pszModule;
                    int m_nSize;
                    int16_t m_nFieldSize;
                    int16_t m_nStaticFieldsSize;
                    int16_t m_nStaticMetadataSize;
                    uint8_t m_unAlignOf;
                    uint8_t m_bHasBaseClass;
                    int16_t m_nTotalClassSize;
                    int16_t m_nDerivedClassSize;
                    SchemaClassFieldData_t* m_pFields;
                    void* m_pStaticFields;
                    SchemaBaseClassInfoData_t* m_pBaseClasses;
                    void* m_pFieldMetadataOverrides;
                    void* m_pStaticMetadata;
                    void* m_pTypeScope;
                    CSchemaType* m_pSchemaType;
                    uint8_t m_nClassFlags;
                    uint32_t m_unSequence;
                    void* m_pFn;
                } SchemaClassInfoData_t;
            ]]
        end

        local CSchemaSystem = ffi.cast("void*(__cdecl*)(const char*, int*)", mem.FindPattern("schemasystem.dll", "4C 8B 0D ?? ?? ?? ?? 4C 8B D2 4C 8B D9"))("SchemaSystem_001", nil)
        local native_FindTypeScopeForModule = vtable_bind(CSchemaSystem, 13, "void*(__thiscall*)(void*, const char*, void*)")
        local native_FindDeclaredClass = vtable_thunk(25, "SchemaClassInfoData_t*(__thiscall*)(void*, const char*)")

        local function create_map(typescope, size)
            local map = table_new(0, size)
            local data = ffi.cast("uintptr_t*", ffi.cast("uintptr_t", typescope) + 0x0440)[0]
            for i = 0, size - 1 do
                local classname = ffi.string(ffi.cast("const char**", ffi.cast("uintptr_t*", ffi.cast("uint8_t*", data + i * 0x18) + 0x10)[0] + 0x8)[0])
                local declared = native_FindDeclaredClass(typescope, classname)

                if not map[classname] then map[classname] = table_new(0, declared.m_nFieldSize) end

                for j = 0, declared.m_nFieldSize - 1 do
                    local field = declared.m_pFields[j]
                    local propname = ffi.string(field.m_pszName)

                    if not map[classname][propname] then map[classname][propname] = field.m_nSingleInheritanceOffset end
                end

                local inherit = {}
                local classes = declared.m_pBaseClasses
                while classes ~= nil do
                    local class = classes.m_pPrevByClass
                    inherit[#inherit + 1] = ffi.string(class.m_pszName)
                    classes = class.m_pBaseClasses
                end

                setmetatable(map[classname], {
                    __index = function(_, key)
                        for _, parentclassname in ipairs(inherit) do
                            if map[parentclassname] and map[parentclassname][key] then return map[parentclassname][key] end
                        end
                    end
                })
            end
            return map
        end

        schema = setmetatable({
            map = {}
        }, {
            __call = function(self, classname, propname)
                return self:find(classname, propname)
            end,
            __index = {
                find = function(self, classname, propname)
                    for _, map in pairs(self.map) do
                        if map[classname] and map[classname][propname] then return map[classname][propname] end
                    end
                end,
                open = function(self, modname)
                    local typescope = native_FindTypeScopeForModule(modname, nil)
                    if typescope == nil then error(string.format("invalid type range to find '%s'", modname), 2) end

                    local size = ffi.cast("uint16_t*", ffi.cast("uintptr_t", typescope) + 0x0456)[0]
                    self.map[modname] = create_map(typescope, size)
                    return self
                end
            }
        }):open "client.dll"
    end

    local sub_180697FA0 = ffi.cast("uintptr_t(__fastcall*)(int)", mem.FindPattern("client.dll", "40 53 48 83 EC 20 48 8B 05 ?? ?? ?? ?? 48 85"))

    local fnGetPlayerMoney
    callbacks.Register("Unload", function() fnGetPlayerMoney:remove() end)
    fnGetPlayerMoney = detour.new("int(__fastcall*)(void*, int)", function(thisptr, index)
        local res = fnGetPlayerMoney(thisptr, index)

        xpcall(function(...)
            print(res)
            if res == -5 then
                local instance = sub_180697FA0(index)
                if instance == 0 then return end

                local localpawn = entities.GetLocalPawn()
                if localpawn == nil then return end

                if ffi.cast("uint8_t*", instance + schema:find("C_BaseEntity", "m_iTeamNum"))[0] == localpawn:GetTeamNumber() then return end

                res = ffi.cast("int*", ffi.cast("uintptr_t*", instance + schema:find("CCSPlayerController", "m_pInGameMoneyServices"))[0] + schema:find("CCSPlayerController_InGameMoneyServices", "m_iAccount"))[0]
            end
        end, print)

        return res
    end, mem.FindPattern("client.dll", "48 83 EC 28 85 D2 74 24"))
end, print)

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
                local kDeclaredClassesOffset = 0x438;
                local p = ffi.cast(uintptr_t_ptr, ffi.cast(uintptr_t, ts) + kDeclaredClassesOffset + 0x8)[0]
                local size = ffi.cast(uint16_t_ptr, ffi.cast(uintptr_t, ts) + kDeclaredClassesOffset + 0x1e)[0]
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

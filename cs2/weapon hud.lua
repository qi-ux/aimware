xpcall(function()
    do
        ---
        local table_concat      = table.concat
        local debug_getregistry = debug.getregistry
        local pcall             = pcall
        local error             = error
        local load              = load
        local select            = select
        local type              = type
        local unpack            = unpack
        local debug_getinfo     = debug.getinfo
        local ipairs            = ipairs
        local pairs             = pairs

        ---
        local file_read         = file.Read

        ---
        local LUA_LDIR          = "!\\lua\\"
        local LUA_PATH_DEFAULT  = table_concat({".\\?.lua;", LUA_LDIR, "?.lua;", LUA_LDIR, "?\\init.lua;"})
        local LUA_DIRSEP        = "\\"
        local LUA_PATHSEP       = ";"
        local LUA_PATH_MARK     = "?"
        local LUA_EXECDIR       = "!"
        local LUA_IGMARK        = "-"
        local LUA_PATH_CONFIG   = table_concat({LUA_DIRSEP, LUA_PATHSEP, LUA_PATH_MARK, LUA_EXECDIR, LUA_IGMARK, ""}, "\n")

        local LUA_LOADLIBNAME   = "package"
        local LUA_REGISTRYINDEX = debug_getregistry()

        ---
        local function setprogdir(path)
            return path:gsub(LUA_EXECDIR, ".")
        end

        local function readable(filename)
            return pcall(file_read, filename:gsub("^%.\\", ""))
        end

        local function loadfile(filename, mode, env)
            local success, result = readable(filename)
            if not success then return error(("cannot open %s: %s"):format(filename, result:lower())) end
            return load(result, ("=%s"):format(filename), mode, env)
        end

        local function getfuncname()
            return debug_getinfo(2, "n").name or "?"
        end

        local function package_searchpath(...)
            local args = {...}
            local name, path, sep, rep = unpack(args)
            if select("#", ...) < 3 then sep, rep = ".", LUA_DIRSEP end
            if select("#", ...) < 4 then rep = LUA_DIRSEP end
            local funcname = getfuncname()
            if type(name) ~= "string" then return error(("bad argument #1 to '%s' (string expected, got %s)"):format(funcname, select("#", ...) < 1 and "no value" or type(name))) end
            if type(path) ~= "string" then return error(("bad argument #2 to '%s' (string expected, got %s)"):format(funcname, select("#", ...) < 2 and "no value" or type(path))) end
            if type(sep) ~= "string" then return error(("bad argument #3 to '%s' (string expected, got %s)"):format(funcname, select("#", ...) < 3 and "no value" or type(sep))) end
            if type(rep) ~= "string" then return error(("bad argument #4 to '%s' (string expected, got %s)"):format(funcname, select("#", ...) < 4 and "no value" or type(rep))) end

            local msg = {}
            if sep then name = name:gsub(("%%%s"):format(sep), ("%%%s"):format(rep)) end

            for current in path:gmatch(("[^%s]+"):format(LUA_PATHSEP)) do
                local filename = current:gsub(("%%%s"):format(LUA_PATH_MARK), name)
                if readable(filename) then return filename end
                msg[#msg + 1] = ("\n\tno file '%s'"):format(filename)
            end

            return nil, table_concat(msg)
        end

        local function package_loader_preload(...)
            local name = unpack({...})
            if type(name) ~= "string" then return error(("bad argument #1 to '%s' (string expected, got %s)"):format(getfuncname(), select("#", ...) < 1 and "no value" or type(name))) end

            local preload = _G[LUA_LOADLIBNAME]["preload"]
            if type(preload) ~= "table" then return error("'package.preload' must be a table") end

            if preload[name] ~= nil then return preload[name] end
            return ("\n\tno field package.preload['%s']"):format(name)
        end

        local function package_loader_lua(...)
            local args = {...}
            local name = unpack(args)
            if type(name) ~= "string" then return error(("bad argument #1 to '%s' (string expected, got %s)"):format(getfuncname(), select("#", ...) < 1 and "no value" or type(name))) end

            local path = _G[LUA_LOADLIBNAME]["path"]
            if type(path) ~= "string" then return error("'package.path' must be a string") end

            local filename, msg
            filename, msg = package_searchpath(name, path)
            if not filename then return msg end

            local chunk, err = loadfile(filename)
            if chunk then return chunk end
            return error(("error loading module '%s' from file '%s':\n\t%s"):format(name, filename, err))
        end

        local KEY_SENTINEL = bit.bor(bit.lshift(0x80000000, 32), 115)
        local function package_require(...)
            local name = unpack({...})

            if type(name) ~= "string" then return error(("bad argument #1 to '%s' (string expected, got %s)"):format(getfuncname(), select("#", ...) < 1 and "no value" or type(name))) end

            local package = _G[LUA_LOADLIBNAME]
            local loaders = package["loaders"]
            if type(loaders) ~= "table" then return error("'package.loaders' must be a table") end

            local loaded = package["loaded"]

            if loaded[name] then
                if loaded[name] == KEY_SENTINEL then return error(("loop or previous error loading module '%s'"):format(name)) end
                return loaded[name]
            end

            local msg = {}
            for _, loader in ipairs(loaders) do
                local success, result = pcall(loader, name)
                if not success then return error(result) end

                if type(result) == "function" then
                    loaded[name] = KEY_SENTINEL
                    local ok, res = pcall(result, name)

                    if not ok then
                        loaded[name] = nil
                        return print(res)
                    end

                    loaded[name] = type(res) == "nil" and true or res
                    return loaded[name]
                elseif type(result) == "string" then
                    msg[#msg + 1] = result
                end
            end

            return error(("module '%s' not found:%s"):format(name, table_concat(msg)))
        end

        local function luaopen_package()
            _G[LUA_LOADLIBNAME] = {
                ["searchpath"] = package_searchpath,
                ["loaders"] = {
                    package_loader_preload,
                    package_loader_lua
                },
                ["path"] = setprogdir(LUA_PATH_DEFAULT),
                ["config"] = LUA_PATH_CONFIG,
                ["loaded"] = LUA_REGISTRYINDEX["_LOADED"],
                ["preload"] = LUA_REGISTRYINDEX["_PRELOAD"]
            }

            for name, func in pairs({
                ["require"] = package_require
            }) do
                _G[name] = func
            end
        end

        if not package then luaopen_package() end
    end

    local ffi = require "ffi"

    ---@format disable-next
    local vtable_bind, vtable_thunk = (function()local a=(function()local b=ffi.typeof"void***"return function(c,d,e)return ffi.cast(e,ffi.cast(b,c)[0][d])end end)()local function f(c,d,e,...)local g=a(c,d,ffi.typeof(e,...))return function(...)return g(c,...)end end;local function h(d,e,...)e=ffi.typeof(e,...)return function(c,...)return a(c,d,e)(c,...)end end;return f,h end)()

    local create_interface = (function()
        if not pcall(ffi.sizeof, "instantiateinterfacefn") then
            ffi.cdef [[
            typedef void*(__cdecl* instantiateinterfacefn)();

            typedef struct interfacereg_t {
                instantiateinterfacefn create;
                const char* name;
                struct interfacereg_t* next;
            };
        ]]
        end

        local function create_interface(modname, version)
            local address = ffi.cast("uintptr_t", mem.FindPattern(modname, "4C 8B 0D ?? ?? ?? ?? 4C 8B D2 4C 8B D9"))
            local list = ffi.cast("struct interfacereg_t**", address + ffi.cast("int32_t*", address + 3)[0] + 7)[0]

            while list ~= nil do
                if ffi.string(list.name) == version then return list.create() end
                list = list.next
            end
        end

        return create_interface
    end)()

    local schema
    do
        local table_new = require "table.new"

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
        local native_FindDeclaredClass = vtable_thunk(29, "SchemaClassInfoData_t*(__thiscall*)(void*, const char*)")

        local function create_map(typescope, size)
            local map = table_new(0, size)
            local data = ffi.cast("uintptr_t*", ffi.cast("uintptr_t", typescope) + 0x04d0)[0]
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

                    local size = ffi.cast("uint16_t*", ffi.cast("uintptr_t", typescope) + 0x04e6)[0]
                    self.map[modname] = create_map(typescope, size)
                    return self
                end
            }
        }):open "client.dll"
    end

    local function schema_offset(ctype, classname, propname, array_index)
        local offset = schema:find(classname, propname)
        if not offset then return end

        if type(propname) == "table" then
            for _, prop in ipairs(propname) do
                offset = type(offset) == "table" and offset[prop]
                if not offset then return end
            end
        end

        local ct = ffi.typeof("$*", ffi.typeof(ctype))

        return function(...)
            local args = {...}
            local argc = select("#", ...)

            if argc == 1 then
                local p = ffi.cast(ct, ffi.cast("uintptr_t", args[1]) + offset)
                if array_index then return p[array_index] end
                return p
            end

            if argc == 2 then
                local p = ffi.cast(ct, ffi.cast("uintptr_t", args[1]) + offset)
                p[array_index] = args[2]
            end
        end
    end

    local ccsweapons
    do
        local CCSWeaponBaseVData = {
            m_bBuiltRightHanded              = schema_offset("bool", "CCSWeaponBaseVData", "m_bBuiltRightHanded", 0),
            m_bAllowFlipping                 = schema_offset("bool", "CCSWeaponBaseVData", "m_bAllowFlipping", 0),
            m_sMuzzleAttachment              = schema_offset("const char*", "CCSWeaponBaseVData", "m_sMuzzleAttachment", 0),
            m_iFlags                         = schema_offset("uint8_t", "CCSWeaponBaseVData", "m_iFlags", 0),
            m_nPrimaryAmmoType               = schema_offset("int8_t", "CCSWeaponBaseVData", "m_nPrimaryAmmoType", 0),
            m_nSecondaryAmmoType             = schema_offset("int8_t", "CCSWeaponBaseVData", "m_nSecondaryAmmoType", 0),
            m_iMaxClip1                      = schema_offset("int32_t", "CCSWeaponBaseVData", "m_iMaxClip1", 0),
            m_iMaxClip2                      = schema_offset("int32_t", "CCSWeaponBaseVData", "m_iMaxClip2", 0),
            m_iDefaultClip1                  = schema_offset("int32_t", "CCSWeaponBaseVData", "m_iDefaultClip1", 0),
            m_iDefaultClip2                  = schema_offset("int32_t", "CCSWeaponBaseVData", "m_iDefaultClip2", 0),
            m_iWeight                        = schema_offset("int32_t", "CCSWeaponBaseVData", "m_iWeight", 0),
            m_bAutoSwitchTo                  = schema_offset("bool", "CCSWeaponBaseVData", "m_bAutoSwitchTo", 0),
            m_bAutoSwitchFrom                = schema_offset("bool", "CCSWeaponBaseVData", "m_bAutoSwitchFrom", 0),
            m_iRumbleEffect                  = schema_offset("uint32_t", "CCSWeaponBaseVData", "m_iRumbleEffect", 0),
            m_bLinkedCooldowns               = schema_offset("bool", "CCSWeaponBaseVData", "m_bLinkedCooldowns", 0),
            m_iSlot                          = schema_offset("int32_t", "CCSWeaponBaseVData", "m_iSlot", 0),
            m_iPosition                      = schema_offset("int32_t", "CCSWeaponBaseVData", "m_iPosition", 0),
            m_WeaponType                     = schema_offset("uint32_t", "CCSWeaponBaseVData", "m_WeaponType", 0),
            m_WeaponCategory                 = schema_offset("uint32_t", "CCSWeaponBaseVData", "m_WeaponCategory", 0),
            m_GearSlot                       = schema_offset("uint32_t", "CCSWeaponBaseVData", "m_GearSlot", 0),
            m_GearSlotPosition               = schema_offset("int32_t", "CCSWeaponBaseVData", "m_GearSlotPosition", 0),
            m_DefaultLoadoutSlot             = schema_offset("uint32_t", "CCSWeaponBaseVData", "m_DefaultLoadoutSlot", 0),
            m_sWrongTeamMsg                  = schema_offset("const char*", "CCSWeaponBaseVData", "m_sWrongTeamMsg", 0),
            m_nPrice                         = schema_offset("int32_t", "CCSWeaponBaseVData", "m_nPrice", 0),
            m_nKillAward                     = schema_offset("int32_t", "CCSWeaponBaseVData", "m_nKillAward", 0),
            m_nPrimaryReserveAmmoMax         = schema_offset("int32_t", "CCSWeaponBaseVData", "m_nPrimaryReserveAmmoMax", 0),
            m_nSecondaryReserveAmmoMax       = schema_offset("int32_t", "CCSWeaponBaseVData", "m_nSecondaryReserveAmmoMax", 0),
            m_bMeleeWeapon                   = schema_offset("bool", "CCSWeaponBaseVData", "m_bMeleeWeapon", 0),
            m_bHasBurstMode                  = schema_offset("bool", "CCSWeaponBaseVData", "m_bHasBurstMode", 0),
            m_bIsRevolver                    = schema_offset("bool", "CCSWeaponBaseVData", "m_bIsRevolver", 0),
            m_bCannotShootUnderwater         = schema_offset("bool", "CCSWeaponBaseVData", "m_bCannotShootUnderwater", 0),
            m_szName                         = schema_offset("const char*", "CCSWeaponBaseVData", "m_szName", 0),
            m_szAnimExtension                = schema_offset("const char*", "CCSWeaponBaseVData", "m_szAnimExtension", 0),
            m_eSilencerType                  = schema_offset("uint32_t", "CCSWeaponBaseVData", "m_eSilencerType", 0),
            m_nCrosshairMinDistance          = schema_offset("int32_t", "CCSWeaponBaseVData", "m_nCrosshairMinDistance", 0),
            m_nCrosshairDeltaDistance        = schema_offset("int32_t", "CCSWeaponBaseVData", "m_nCrosshairDeltaDistance", 0),
            m_bIsFullAuto                    = schema_offset("bool", "CCSWeaponBaseVData", "m_bIsFullAuto", 0),
            m_nNumBullets                    = schema_offset("int32_t", "CCSWeaponBaseVData", "m_nNumBullets", 0),
            m_flCycleTime                    = schema_offset("float[2]", "CCSWeaponBaseVData", "m_flCycleTime", 0),
            m_flMaxSpeed                     = schema_offset("float[2]", "CCSWeaponBaseVData", "m_flMaxSpeed", 0),
            m_flSpread                       = schema_offset("float[2]", "CCSWeaponBaseVData", "m_flSpread", 0),
            m_flInaccuracyCrouch             = schema_offset("float[2]", "CCSWeaponBaseVData", "m_flInaccuracyCrouch", 0),
            m_flInaccuracyStand              = schema_offset("float[2]", "CCSWeaponBaseVData", "m_flInaccuracyStand", 0),
            m_flInaccuracyJump               = schema_offset("float[2]", "CCSWeaponBaseVData", "m_flInaccuracyJump", 0),
            m_flInaccuracyLand               = schema_offset("float[2]", "CCSWeaponBaseVData", "m_flInaccuracyLand", 0),
            m_flInaccuracyLadder             = schema_offset("float[2]", "CCSWeaponBaseVData", "m_flInaccuracyLadder", 0),
            m_flInaccuracyFire               = schema_offset("float[2]", "CCSWeaponBaseVData", "m_flInaccuracyFire", 0),
            m_flInaccuracyMove               = schema_offset("float[2]", "CCSWeaponBaseVData", "m_flInaccuracyMove", 0),
            m_flRecoilAngle                  = schema_offset("float[2]", "CCSWeaponBaseVData", "m_flRecoilAngle", 0),
            m_flRecoilAngleVariance          = schema_offset("float[2]", "CCSWeaponBaseVData", "m_flRecoilAngleVariance", 0),
            m_flRecoilMagnitude              = schema_offset("float[2]", "CCSWeaponBaseVData", "m_flRecoilMagnitude", 0),
            m_flRecoilMagnitudeVariance      = schema_offset("float[2]", "CCSWeaponBaseVData", "m_flRecoilMagnitudeVariance", 0),
            m_nTracerFrequency               = schema_offset("int32_t[2]", "CCSWeaponBaseVData", "m_nTracerFrequency", 0),
            m_flInaccuracyJumpInitial        = schema_offset("float", "CCSWeaponBaseVData", "m_flInaccuracyJumpInitial", 0),
            m_flInaccuracyJumpApex           = schema_offset("float", "CCSWeaponBaseVData", "m_flInaccuracyJumpApex", 0),
            m_flInaccuracyReload             = schema_offset("float", "CCSWeaponBaseVData", "m_flInaccuracyReload", 0),
            m_nRecoilSeed                    = schema_offset("int32_t", "CCSWeaponBaseVData", "m_nRecoilSeed", 0),
            m_nSpreadSeed                    = schema_offset("int32_t", "CCSWeaponBaseVData", "m_nSpreadSeed", 0),
            m_flTimeToIdleAfterFire          = schema_offset("float", "CCSWeaponBaseVData", "m_flTimeToIdleAfterFire", 0),
            m_flIdleInterval                 = schema_offset("float", "CCSWeaponBaseVData", "m_flIdleInterval", 0),
            m_flAttackMovespeedFactor        = schema_offset("float", "CCSWeaponBaseVData", "m_flAttackMovespeedFactor", 0),
            m_flHeatPerShot                  = schema_offset("float", "CCSWeaponBaseVData", "m_flHeatPerShot", 0),
            m_flInaccuracyPitchShift         = schema_offset("float", "CCSWeaponBaseVData", "m_flInaccuracyPitchShift", 0),
            m_flInaccuracyAltSoundThreshold  = schema_offset("float", "CCSWeaponBaseVData", "m_flInaccuracyAltSoundThreshold", 0),
            m_flBotAudibleRange              = schema_offset("float", "CCSWeaponBaseVData", "m_flBotAudibleRange", 0),
            m_szUseRadioSubtitle             = schema_offset("const char*", "CCSWeaponBaseVData", "m_szUseRadioSubtitle", 0),
            m_bUnzoomsAfterShot              = schema_offset("bool", "CCSWeaponBaseVData", "m_bUnzoomsAfterShot", 0),
            m_bHideViewModelWhenZoomed       = schema_offset("bool", "CCSWeaponBaseVData", "m_bHideViewModelWhenZoomed", 0),
            m_nZoomLevels                    = schema_offset("int32_t", "CCSWeaponBaseVData", "m_nZoomLevels", 0),
            m_nZoomFOV1                      = schema_offset("int32_t", "CCSWeaponBaseVData", "m_nZoomFOV1", 0),
            m_nZoomFOV2                      = schema_offset("int32_t", "CCSWeaponBaseVData", "m_nZoomFOV2", 0),
            m_flZoomTime0                    = schema_offset("float", "CCSWeaponBaseVData", "m_flZoomTime0", 0),
            m_flZoomTime1                    = schema_offset("float", "CCSWeaponBaseVData", "m_flZoomTime1", 0),
            m_flZoomTime2                    = schema_offset("float", "CCSWeaponBaseVData", "m_flZoomTime2", 0),
            m_flIronSightPullUpSpeed         = schema_offset("float", "CCSWeaponBaseVData", "m_flIronSightPullUpSpeed", 0),
            m_flIronSightPutDownSpeed        = schema_offset("float", "CCSWeaponBaseVData", "m_flIronSightPutDownSpeed", 0),
            m_flIronSightFOV                 = schema_offset("float", "CCSWeaponBaseVData", "m_flIronSightFOV", 0),
            m_flIronSightPivotForward        = schema_offset("float", "CCSWeaponBaseVData", "m_flIronSightPivotForward", 0),
            m_flIronSightLooseness           = schema_offset("float", "CCSWeaponBaseVData", "m_flIronSightLooseness", 0),
            m_angPivotAngle                  = schema_offset("float[3]", "CCSWeaponBaseVData", "m_angPivotAngle", 0),
            m_vecIronSightEyePos             = schema_offset("float[3]", "CCSWeaponBaseVData", "m_vecIronSightEyePos", 0),
            m_nDamage                        = schema_offset("int32_t", "CCSWeaponBaseVData", "m_nDamage", 0),
            m_flHeadshotMultiplier           = schema_offset("float", "CCSWeaponBaseVData", "m_flHeadshotMultiplier", 0),
            m_flArmorRatio                   = schema_offset("float", "CCSWeaponBaseVData", "m_flArmorRatio", 0),
            m_flPenetration                  = schema_offset("float", "CCSWeaponBaseVData", "m_flPenetration", 0),
            m_flRange                        = schema_offset("float", "CCSWeaponBaseVData", "m_flRange", 0),
            m_flRangeModifier                = schema_offset("float", "CCSWeaponBaseVData", "m_flRangeModifier", 0),
            m_flFlinchVelocityModifierLarge  = schema_offset("float", "CCSWeaponBaseVData", "m_flFlinchVelocityModifierLarge", 0),
            m_flFlinchVelocityModifierSmall  = schema_offset("float", "CCSWeaponBaseVData", "m_flFlinchVelocityModifierSmall", 0),
            m_flRecoveryTimeCrouch           = schema_offset("float", "CCSWeaponBaseVData", "m_flRecoveryTimeCrouch", 0),
            m_flRecoveryTimeStand            = schema_offset("float", "CCSWeaponBaseVData", "m_flRecoveryTimeStand", 0),
            m_flRecoveryTimeCrouchFinal      = schema_offset("float", "CCSWeaponBaseVData", "m_flRecoveryTimeCrouchFinal", 0),
            m_flRecoveryTimeStandFinal       = schema_offset("float", "CCSWeaponBaseVData", "m_flRecoveryTimeStandFinal", 0),
            m_nRecoveryTransitionStartBullet = schema_offset("int32_t", "CCSWeaponBaseVData", "m_nRecoveryTransitionStartBullet", 0),
            m_nRecoveryTransitionEndBullet   = schema_offset("int32_t", "CCSWeaponBaseVData", "m_nRecoveryTransitionEndBullet", 0),
            m_flThrowVelocity                = schema_offset("float", "CCSWeaponBaseVData", "m_flThrowVelocity", 0),
            m_vSmokeColor                    = schema_offset("float[3]", "CCSWeaponBaseVData", "m_vSmokeColor", 0),
            m_szAnimClass                    = schema_offset("const char*", "CCSWeaponBaseVData", "m_szAnimClass", 0),
        }

        if not pcall(ffi.sizeof, "CCSWeaponBaseVData") then
            ffi.cdef [[
                typedef struct CCSWeaponBaseVData {} CCSWeaponBaseVData;
            ]]

            ffi.metatype("CCSWeaponBaseVData", {
                __index = function(self, key)
                    if CCSWeaponBaseVData[key] then return CCSWeaponBaseVData[key](self) end
                end,
                __newindex = function(self, key, value)
                    if CCSWeaponBaseVData[key] then return CCSWeaponBaseVData[key](self, value) end
                end
            })
        end

        local native_GetCSWeaponInfo = (function()
            local fnptr = ffi.cast("CCSWeaponBaseVData*(__cdecl*)(int, uint8_t*)", mem.FindPattern("client.dll", "48 89 5C 24 08 48 89 74 24 10 57 48 83 EC 20 48 8B FA 8B F1 48 85 D2"))

            return function(idx)
                idx = tostring(idx)
                local cstr = ffi.new("uint8_t[?]", #idx, idx)
                return fnptr(1, cstr)
            end
        end)()

        local weapons, weapons_index = {}, {}
        for idx = 1, 1000 do
            local res = native_GetCSWeaponInfo(idx)
            if res ~= nil then
                local weapon = {}

                for key, value in pairs(CCSWeaponBaseVData) do
                    local v = value(res)

                    if v ~= nil then
                        weapon[key] = ffi.istype("char*", v) and ffi.string(v) or v
                    end
                end

                weapon.idx = idx
                weapon.raw = res

                weapons[idx] = weapon
                weapons_index[weapon.m_szName] = weapon
            end
        end

        ccsweapons = setmetatable(weapons, {
            __index = weapons_index,
            __metatable = false
        })
    end

    local native_GetEntityInstance = (function()
        local CGameEntitySystem = ffi.cast("void**", ffi.cast("uintptr_t", create_interface("engine2.dll", "GameResourceServiceClientV001")) + 0x58)[0]
        local fnGetEntityInstance = ffi.cast("uintptr_t(__thiscall*)(void*, int)", mem.FindPattern("client.dll", "81 FA ?? ?? ?? ?? 77 36 8B C2 C1 F8 09 83 F8 3F 77 2C 48 98"))
        return function(idx) return fnGetEntityInstance(CGameEntitySystem, idx) end
    end)()

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

    local load_weapon_svg = (function()
        local fnLoadFileForMe = ffi.cast("uint8_t*(__fastcall*)(const char*, int*)", mem.FindPattern("client.dll", "40 55 57 41 56 48 83 EC 20 4C 8B F1"))
        return function(weapon_name)
            local size = ffi.new("int[1]")
            local data = fnLoadFileForMe(("panorama/images/icons/equipment/%s.vsvg_c"):format(weapon_name:gsub("^weapon_", "")), size)
            if data == nil then return nil end
            return common.RasterizeSVG(ffi.string(data, size[0]):match("<svg.-</svg>"))
        end
    end)()

    local weapon_icon = setmetatable({}, {
        __index = function(t, k)
            local rgba, width, height = load_weapon_svg(k)
            t[k] = {draw.CreateTexture(rgba, width, height), width, height}
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

    local hud = {
        x = 250,
        y = 250,
        dragging = false,
    }

    local font = draw.CreateFont("verdana", 12)
    local font_bold = draw.CreateFont("verdana bold", 12)
    local menu_reference = gui.Reference("menu")

    callbacks.Register("Draw", function()
        local localpawn_index = client.GetLocalPlayerIndex()
        if localpawn_index == nil then return end

        local localpawn_ent = entities.GetByIndex(localpawn_index)
        if localpawn_ent == nil then return end

        local localpawn_instance = native_GetEntityInstance(localpawn_index)
        if localpawn_instance == nil then return end

        local weapon_services = ffi.cast("uintptr_t*", localpawn_instance + schema:find(localpawn_ent:GetClass(), "m_pWeaponServices"))[0]
        if weapon_services == 0 then return end

        local activeweapon_index = bit.band(ffi.cast("uintptr_t*", weapon_services + schema:find("CPlayer_WeaponServices", "m_hActiveWeapon"))[0], 0x7fff)

        local activeweapon_ent = entities.GetByIndex(tonumber(activeweapon_index))
        if activeweapon_ent == nil then return end

        local activeweapon_instance = native_GetEntityInstance(activeweapon_index)
        if activeweapon_instance == nil then return end

        local health = math.min(100, localpawn_ent:GetHealth())
        local armor = math.min(100, localpawn_ent:GetPropInt "m_ArmorValue")

        local weapons = ccsweapons[localpawn_ent:GetWeaponID()]
        if weapons == nil then return end

        local weapon_name = weapons.m_szName
        local weapon_max_clip1 = weapons.m_iMaxClip1

        local weapon_clip1 = activeweapon_ent:GetPropInt "m_iClip1"
        local weapon_reserve_ammo = activeweapon_ent:GetPropInt "m_pReserveAmmo"

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
            draw.TextShadow(math.floor(x + w * 0.5 - tw * 0.5), math.floor(y + h * 0.5 - th * 0.5 + 35), weapon_reserve_ammo)
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
            draw.TextShadow(math.floor(x + w * 0.5 - tw * 0.5), math.floor(y + h * 0.5 - th * 0.5 + 65), health)
        end

        do
            draw.SetFont(font_bold)
            draw.Color(75, 75, 255, 175)
            circle_outline(x + w * 0.5, y + h * 0.5, 65, 300, 0.34 * armor / 100, 5)
            local tw, th = draw.GetTextSize(armor)
            draw.TextShadow(math.floor(x + w * 0.5 - tw * 0.5), math.floor(y + h * 0.5 - th * 0.5 - 65), armor)
        end

        local icon = weapon_icon[weapon_name]
        draw.Color(255, 255, 255, 255)
        draw.SetTexture(icon[1])
        draw.FilledRect(x + w * 0.5 - icon[2] * 0.5, y + h * 0.5 - icon[3] * 0.5, x + w * 0.5 + icon[2] * 0.5, y + h * 0.5 + icon[3] * 0.5)
    end)
end, print)

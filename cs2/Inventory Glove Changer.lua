---@diagnostic disable: undefined-field, inject-field
DEBUG = false

local benchmark = {
    start_times = {},
    measure = function(name, callback, ...)
        if not DEBUG then return end

        local start = common.Time()
        local values = {callback(...)}
        print(string.format("%s took %fms", name, common.Time() - start))

        return unpack(values)
    end,
    start = function(self, name)
        if not DEBUG then return end

        if self.start_times[name] ~= nil then
            error("benchmark: " .. name .. " wasn't finished before starting again")
        end
        self.start_times[name] = common.Time()
    end,
    finish = function(self, name)
        if not DEBUG then return end

        if self.start_times[name] == nil then
            return
        end

        print(string.format("%s took %fms", name, common.Time() - self.start_times[name]))
        self.start_times[name] = nil
    end
}

local ffi = require "ffi"
local C = ffi.C

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

local CUtlMemory = (function()
    return function(T, I)
        I = ffi.typeof(I or "int")
        local MT = {}

        local INVALID_INDEX = -1
        function MT:invalid_index()
            return INVALID_INDEX
        end

        function MT:is_idx_valid(i)
            local x = ffi.cast("long", i)
            return x >= 0 and x < self.m_allocation_count
        end

        MT.iterator_t = ffi.metatype(
            ffi.typeof([[
                struct {
                    $ index;
                }
                ]], I),
            {
                __eq = function(self, it)
                    if ffi.istype(self, it) then
                        return self.index == it.index
                    end
                end
            }
        )
        function MT:invalid_iterator()
            return MT.iterator_t(self:invalid_index())
        end

        return ffi.metatype(ffi.typeof([[
                struct {
                    $* m_memory;
                    int m_allocation_count;
                    int m_grow_size;
                }
            ]], ffi.typeof(T)), {
            __index = function(self, key)
                if MT[key] then return MT[key] end
                if type(key) == "number" and key < self.m_allocation_count then return self.m_memory[key] end
            end
        })
    end
end)()

local CUtlVector = (function()
    local MT = {}

    function MT:count()
        return self.m_size
    end

    function MT:element(i)
        if i > -1 and i < self.m_size then return self.m_memory[i] end
    end

    return function(T, A)
        return ffi.metatype(ffi.typeof("struct {int m_size; $ m_memory;}", A or CUtlMemory(T)), {
            __index = function(self, key)
                if MT[key] then return MT[key] end
                if type(key) == "number" then return self:element(key) end
                return nil
            end,
            __ipairs = function(self)
                return function(t, i)
                    i = i + 1
                    local v = t[i]
                    if v then return i, v end
                end, self, -1
            end
        })
    end
end)()

local CUtlRBTree = (function()
    local UtlRBTreeLinks_t = function(I)
        I = ffi.typeof(I)
        return ffi.typeof([[
            struct {
                $ m_left;
                $ m_right;
                $ m_parent;
                $ m_tag;
            }
        ]], I, I, I, I)
    end

    local UtlRBTreeNode_t = function(T, I)
        return ffi.typeof([[
            struct {
                $ links;
                $ m_data;
            }
        ]], UtlRBTreeLinks_t(I), ffi.typeof(T))
    end

    return function(T, I, L, M)
        T = ffi.typeof(T)
        I = ffi.typeof(I or "unsigned short")
        L = L or ffi.typeof("bool(__cdecl*)(const $&, const $&)", T, T)
        M = M or CUtlMemory(UtlRBTreeNode_t(T, I), I)

        local MT = {}

        function MT:element(i)
            return self.m_elements[i].m_data
        end

        function MT:root()
            return self.m_root
        end

        function MT:count()
            return self.m_numelements
        end

        function MT:max_element()
            return ffi.cast(I, self.m_elements.num_allocated())
        end

        function MT:parent(i)
            return self:links(i).m_parent
        end

        function MT:left_child(i)
            return self:links(i).m_left
        end

        function MT:right_child(i)
            return self:links(i).m_right
        end

        function MT:is_left_child(i)
            return self:left_child(self:parent(i)) == i
        end

        function MT:is_right_child(i)
            return self:right_child(self:parent(i)) == i
        end

        function MT:is_root(i)
            return i == self.m_root
        end

        function MT:is_leaf(i)
            return (self:left_child(i) == self:invalid_index()) and (self:right_child(i) == self:invalid_index())
        end

        function MT:is_valid_index(i)
            if not self.m_elements:is_idx_valid(i) then return false end
            if self.m_elements:is_idx_after(i, self.m_lastalloc) then return false end

            return self:left_child(i) ~= i
        end

        function MT:is_valid()
            if self:count() == 0 then return true end
            if self.m_lastalloc == self.m_elements:invalid_iterator() then return false end

            if not self.m_elements:is_idx_valid(self:root()) then return false end

            if self:parent(self:root()) ~= self:invalid_index() then return false end

            return true
        end

        function MT:invalid_index()
            return M.invalid_index()
        end

        function MT:depth(node)
            if type(node) == "nil" then self:depth(self:root()) end

            if node == self:invalid_index() then return 0 end

            local depthright = self:depth(self:right_child(node))
            local depthleft = self:depth(self:left_child(node))
            return math.max(depthright, depthleft) + 1
        end

        function MT:find(search)
            local current = self.m_root
            local elements = self.m_elements
            while current ~= -1 do
                local link = self:links(current)
                local key = elements[current].m_data.key
                if key == search then return elements[current].m_data.elem end
                current = key > search and link.m_left or link.m_right
            end
            return current
        end

        function MT:has_element(search)
            return self:find(search) ~= self:invalid_index()
        end

        function MT:first_inorder()
            local i = self.m_root
            while self:left_child(i) ~= self:invalid_index() do i = self:left_child(i) end
            return i
        end

        function MT:next_inorder(i)
            if not self:is_valid_index(i) then return self:invalid_index() end

            if self:right_child(i) ~= self:invalid_index() then
                i = self:right_child(i)
                while self:left_child(i) ~= self:invalid_index() do i = self:left_child(i) end
                return i
            end

            local parent = self:parent(i)
            while self:is_right_child(i) do
                i = parent
                if i == self:invalid_index() then break end
                parent = self:parent(i)
            end
            return parent
        end

        local links_t = ffi.typeof("$*", ffi.typeof(UtlRBTreeLinks_t(I)))
        function MT:links(i)
            return ffi.cast(links_t, self.m_elements[i])[0]
        end

        return ffi.metatype(ffi.typeof([[
            struct {
                $ m_lessfunc;
                $ m_elements;
                $ m_root;
                $ m_numelements;
                $ m_firstfree;
                $ m_lastalloc;
                $* m_pelements;
            }
        ]], L, M, I, I, I, M.iterator_t, ffi.typeof("void")), {
            __index = function(self, key)
                if MT[key] then return MT[key] end

                if type(key) == "number" then return self.m_elements[key].m_data end
            end
        })
    end
end)()

local CUtlMap = (function()
    return function(K, T, I)
        K = ffi.typeof(K)
        T = ffi.typeof(T)
        I = ffi.typeof(I or "unsigned short")

        local node_t = ffi.typeof([[
            struct {
                $ key;
                $ elem;
            }
        ]], K, T)

        local MT = {}
        function MT:element(i)
            return self.m_tree:element(i).elem
        end

        function MT:key(i)
            return self.m_tree:element(i).key
        end

        function MT:count()
            return self.m_tree:count()
        end

        function MT:max_element()
            return self.m_tree:max_element()
        end

        function MT:is_valid_index()
            return self.m_tree:is_valid_index()
        end

        function MT:is_valid()
            return self.m_tree:is_valid()
        end

        function MT:invalid_index()
            return self.m_tree:invalid_index()
        end

        function MT:find(key)
            return self.m_tree:find(key)
        end

        function MT:first_inorder()
            return self.m_tree:first_inorder()
        end

        function MT:next_inorder(i)
            return self.m_tree:next_inorder(i)
        end

        function MT:access_tree()
            return self.m_tree
        end

        local ctree = CUtlRBTree(node_t, I)

        return ffi.metatype(ffi.typeof([[
            struct {
                $ m_tree;
            }
        ]], ctree), {
            __ipairs = function(self)
                return function(t, i)
                    i = i + 1
                    local v = t[i]
                    if v then return i, v end
                end, self, -1
            end,
            __index = function(self, key)
                if MT[key] then return MT[key] end
                if type(key) == "number" and key < self:count() then return self.m_tree:element(key).elem end
            end
        })
    end
end)()

---@format disable-next
local vtable_bind, vtable_thunk = (function()local a=(function()local b=ffi.typeof"void***"return function(c,d,e)return ffi.cast(e,ffi.cast(b,c)[0][d])end end)()local function f(c,d,e,...)local g=a(c,d,ffi.typeof(e,...))return function(...)return g(c,...)end end;local function h(d,e,...)e=ffi.typeof(e,...)return function(c,...)return a(c,d,e)(c,...)end end;return f,h end)()
---@format disable-next
local absolute = (function()return function(a,b,c)if a==nil then return a end;local d=ffi.cast("uintptr_t",a)d=d+b;d=d+ffi.sizeof("int")+ffi.cast("int",ffi.cast("int*",d)[0])d=d+c;return d end end)()
---@format disable-next
local detour = (function()local a={}ffi.cdef"int VirtualProtect(void*, uint64_t, unsigned long, unsigned long*)"local b=0x40;function a.new(c,d,e)local f=12;local g=ffi.new("uint8_t[?]",f)ffi.copy(ffi.cast("void*",g),ffi.cast("const void*",e),f)local h=ffi.cast(c,e)local i=ffi.new("uint8_t[12]",{0x48,0xB8,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xFF,0xE0})ffi.cast("int64_t*",i+2)[0]=ffi.cast("int64_t",ffi.cast("void*",ffi.cast(c,d)))local j=ffi.new"unsigned long[1]"return setmetatable({},{__call=function(self,...)self:remove()local k=h(...)self:install()return k end,__index={install=function(self)C.VirtualProtect(ffi.cast("void*",e),f,b,j)ffi.copy(ffi.cast("void*",e),ffi.cast("const void*",i),f)C.VirtualProtect(ffi.cast("void*",e),f,j[0],j)return self end,remove=function(self)C.VirtualProtect(ffi.cast("void*",e),f,b,j)ffi.copy(ffi.cast("void*",e),ffi.cast("const void*",g),f)C.VirtualProtect(ffi.cast("void*",e),f,j[0],j)return self end}}):install()end;return a end)()

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

local clamp = function(value, min, max) return value < min and min or value > max and max or value end

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

ffi.cdef [[
    typedef struct CScriptComponent CScriptComponent;
    typedef struct C_BaseEntity C_BaseEntity;
    typedef struct CountdownTimer CountdownTimer;
    typedef struct CEntityComponent CEntityComponent;
    typedef struct CEntityIdentity CEntityIdentity;
    typedef struct CEntityInstance CEntityInstance;
    typedef struct CGameSceneNode CGameSceneNode;
    typedef struct CBodyComponent CBodyComponent;
    typedef struct CBodyComponentPoint CBodyComponentPoint;
    typedef struct CSkeletonInstance CSkeletonInstance;
    typedef struct CBodyComponentSkeletonInstance CBodyComponentSkeletonInstance;
    typedef struct CHitboxComponent CHitboxComponent;
    typedef struct CLightComponent CLightComponent;
    typedef struct CRenderComponent CRenderComponent;
    typedef struct CBuoyancyHelper CBuoyancyHelper;
    typedef struct CBasePlayerControllerAPI CBasePlayerControllerAPI;
    typedef struct C_CommandContext C_CommandContext;
    typedef struct ViewAngleServerChange_t ViewAngleServerChange_t;
    typedef struct CDynamicPropAPI CDynamicPropAPI;
    typedef struct CPlayer_AutoaimServices CPlayer_AutoaimServices;
    typedef struct audioparams_t audioparams_t;
    typedef struct C_fogplayerparams_t C_fogplayerparams_t;
    typedef struct C_ColorCorrection C_ColorCorrection;
    typedef struct C_TonemapController2 C_TonemapController2;
    typedef struct C_PostProcessingVolume C_PostProcessingVolume;
    typedef struct fogparams_t fogparams_t;
    typedef struct C_FogController C_FogController;
    typedef struct CPlayer_CameraServices CPlayer_CameraServices;
    typedef struct CPlayer_FlashlightServices CPlayer_FlashlightServices;
    typedef struct CPlayer_ItemServices CPlayer_ItemServices;
    typedef struct CPlayer_MovementServices CPlayer_MovementServices;
    typedef struct CPlayer_MovementServices_Humanoid CPlayer_MovementServices_Humanoid;
    typedef struct CPlayer_ObserverServices CPlayer_ObserverServices;
    typedef struct CPlayer_UseServices CPlayer_UseServices;
    typedef struct CPlayer_WaterServices CPlayer_WaterServices;
    typedef struct C_BasePlayerWeapon C_BasePlayerWeapon;
    typedef struct CPlayer_WeaponServices CPlayer_WeaponServices;
    typedef struct CBaseAnimGraphController CBaseAnimGraphController;
    typedef struct CBodyComponentBaseAnimGraph CBodyComponentBaseAnimGraph;
    typedef struct EntityRenderAttribute_t EntityRenderAttribute_t;
    typedef struct C_BaseModelEntity C_BaseModelEntity;
    typedef struct ActiveModelConfig_t ActiveModelConfig_t;
    typedef struct CBodyComponentBaseModelEntity CBodyComponentBaseModelEntity;
    typedef struct CGameSceneNodeHandle CGameSceneNodeHandle;
    typedef struct SequenceHistory_t SequenceHistory_t;
    typedef struct CNetworkedSequenceOperation CNetworkedSequenceOperation;
    typedef struct CModelState CModelState;
    typedef struct IntervalTimer IntervalTimer;
    typedef struct EngineCountdownTimer EngineCountdownTimer;
    typedef struct CTimeline CTimeline;
    typedef struct CAnimGraphNetworkedVariables CAnimGraphNetworkedVariables;
    typedef struct C_BaseEntityAPI C_BaseEntityAPI;
    typedef struct CTakeDamageInfoAPI CTakeDamageInfoAPI;
    typedef struct CClientPointEntityAPI CClientPointEntityAPI;
    typedef struct CClientScriptEntity CClientScriptEntity;
    typedef struct CPulseGraphInstance_ClientEntity CPulseGraphInstance_ClientEntity;
    typedef struct CCollisionProperty CCollisionProperty;
    typedef struct CBasePlayerController CBasePlayerController;
    typedef struct CLogicalEntity CLogicalEntity;
    typedef struct C_BaseFlex_Emphasized_Phoneme C_BaseFlex_Emphasized_Phoneme;
    typedef struct C_EnvWindShared C_EnvWindShared;
    typedef struct C_EnvWindClientside C_EnvWindClientside;
    typedef struct C_EntityFlame C_EntityFlame;
    typedef struct CProjectedTextureBase CProjectedTextureBase;
    typedef struct C_BaseFire C_BaseFire;
    typedef struct TimedEvent TimedEvent;
    typedef struct CFireOverlay CFireOverlay;
    typedef struct C_FireSmoke C_FireSmoke;
    typedef struct C_RopeKeyframe C_RopeKeyframe;
    typedef struct C_RopeKeyframe_CPhysicsDelegate C_RopeKeyframe_CPhysicsDelegate;
    typedef struct C_SceneEntity_QueuedEvents_t C_SceneEntity_QueuedEvents_t;
    typedef struct C_TintController C_TintController;
    typedef struct CFlashlightEffect CFlashlightEffect;
    typedef struct CInterpolatedValue CInterpolatedValue;
    typedef struct CGlowSprite CGlowSprite;
    typedef struct CGlowOverlay CGlowOverlay;
    typedef struct IClientAlphaProperty IClientAlphaProperty;
    typedef struct C_SkyCamera C_SkyCamera;
    typedef struct CSkyboxReference CSkyboxReference;
    typedef struct sky3dparams_t sky3dparams_t;
    typedef struct VPhysicsCollisionAttribute_t VPhysicsCollisionAttribute_t;
    typedef struct CDecalInfo CDecalInfo;
    typedef struct CEffectData CEffectData;
    typedef struct C_EnvDetailController C_EnvDetailController;
    typedef struct C_EnvWindShared_WindAveEvent_t C_EnvWindShared_WindAveEvent_t;
    typedef struct C_EnvWindShared_WindVariationEvent_t C_EnvWindShared_WindVariationEvent_t;
    typedef struct C_InfoLadderDismount C_InfoLadderDismount;
    typedef struct shard_model_desc_t shard_model_desc_t;
    typedef struct C_GameRulesProxy C_GameRulesProxy;
    typedef struct C_GameRules C_GameRules;
    typedef struct CGlowProperty CGlowProperty;
    typedef struct C_MultiplayRules C_MultiplayRules;
    typedef struct PhysicsRagdollPose_t PhysicsRagdollPose_t;
    typedef struct C_SingleplayRules C_SingleplayRules;
    typedef struct C_SoundOpvarSetPointBase C_SoundOpvarSetPointBase;
    typedef struct C_SoundOpvarSetPointEntity C_SoundOpvarSetPointEntity;
    typedef struct C_SoundOpvarSetAABBEntity C_SoundOpvarSetAABBEntity;
    typedef struct C_SoundOpvarSetOBBEntity C_SoundOpvarSetOBBEntity;
    typedef struct C_SoundOpvarSetPathCornerEntity C_SoundOpvarSetPathCornerEntity;
    typedef struct C_SoundOpvarSetAutoRoomEntity C_SoundOpvarSetAutoRoomEntity;
    typedef struct C_SoundOpvarSetOBBWindEntity C_SoundOpvarSetOBBWindEntity;
    typedef struct C_TeamplayRules C_TeamplayRules;
    typedef struct C_TeamRoundTimer C_TeamRoundTimer;
    typedef struct CEconItemAttribute CEconItemAttribute;
    typedef struct CAttributeManager CAttributeManager;
    typedef struct CAttributeList CAttributeList;
    typedef struct CAttributeManager_cached_attribute_float_t CAttributeManager_cached_attribute_float_t;
    typedef struct C_EconItemView C_EconItemView;
    typedef struct C_AttributeContainer C_AttributeContainer;
    typedef struct C_EconEntity_AttachedModelData_t C_EconEntity_AttachedModelData_t;
    typedef struct EntitySpottedState_t EntitySpottedState_t;
    typedef struct C_CSGameRules C_CSGameRules;
    typedef struct C_CSGameRulesProxy C_CSGameRulesProxy;
    typedef struct CCSGameModeRules CCSGameModeRules;
    typedef struct C_RetakeGameRules C_RetakeGameRules;
    typedef struct CCSTakeDamageInfoAPI CCSTakeDamageInfoAPI;
    typedef struct CCSGameModeRules_Noop CCSGameModeRules_Noop;
    typedef struct CCSGameModeScript CCSGameModeScript;
    typedef struct CCSGameModeRules_ArmsRace CCSGameModeRules_ArmsRace;
    typedef struct CCSArmsRaceScript CCSArmsRaceScript;
    typedef struct CCSGameModeRules_Deathmatch CCSGameModeRules_Deathmatch;
    typedef struct CCSDeathmatchScript CCSDeathmatchScript;
    typedef struct CSPerRoundStats_t CSPerRoundStats_t;
    typedef struct CSMatchStats_t CSMatchStats_t;
    typedef struct C_CSGO_TeamPreviewCharacterPosition C_CSGO_TeamPreviewCharacterPosition;
    typedef struct C_CSGO_TeamSelectCharacterPosition C_CSGO_TeamSelectCharacterPosition;
    typedef struct C_CSGO_TeamSelectTerroristPosition C_CSGO_TeamSelectTerroristPosition;
    typedef struct C_CSGO_TeamSelectCounterTerroristPosition C_CSGO_TeamSelectCounterTerroristPosition;
    typedef struct C_CSGO_TeamIntroCharacterPosition C_CSGO_TeamIntroCharacterPosition;
    typedef struct C_CSGO_TeamIntroTerroristPosition C_CSGO_TeamIntroTerroristPosition;
    typedef struct C_CSGO_TeamIntroCounterTerroristPosition C_CSGO_TeamIntroCounterTerroristPosition;
    typedef struct CCSGO_WingmanIntroCharacterPosition CCSGO_WingmanIntroCharacterPosition;
    typedef struct CCSGO_WingmanIntroTerroristPosition CCSGO_WingmanIntroTerroristPosition;
    typedef struct CCSGO_WingmanIntroCounterTerroristPosition CCSGO_WingmanIntroCounterTerroristPosition;
    typedef struct C_CSMinimapBoundary C_CSMinimapBoundary;
    typedef struct C_CSPlayerPawn C_CSPlayerPawn;
    typedef struct C_PlayerPing C_PlayerPing;
    typedef struct CCSPlayer_PingServices CCSPlayer_PingServices;
    typedef struct C_CSPlayerResource C_CSPlayerResource;
    typedef struct CCSPlayerControllerAPI CCSPlayerControllerAPI;
    typedef struct CPlayer_ViewModelServices CPlayer_ViewModelServices;
    typedef struct CCSPlayerBase_CameraServices CCSPlayerBase_CameraServices;
    typedef struct WeaponPurchaseCount_t WeaponPurchaseCount_t;
    typedef struct WeaponPurchaseTracker_t WeaponPurchaseTracker_t;
    typedef struct CCSPlayer_ActionTrackingServices CCSPlayer_ActionTrackingServices;
    typedef struct CCSPlayer_BulletServices CCSPlayer_BulletServices;
    typedef struct SellbackPurchaseEntry_t SellbackPurchaseEntry_t;
    typedef struct CCSPlayer_BuyServices CCSPlayer_BuyServices;
    typedef struct CCSPlayer_CameraServices CCSPlayer_CameraServices;
    typedef struct CCSPlayer_HostageServices CCSPlayer_HostageServices;
    typedef struct CCSPlayer_ItemServices CCSPlayer_ItemServices;
    typedef struct CCSPlayer_MovementServices CCSPlayer_MovementServices;
    typedef struct CCSPlayer_UseServices CCSPlayer_UseServices;
    typedef struct C_BaseViewModel C_BaseViewModel;
    typedef struct CCSPlayer_ViewModelServices CCSPlayer_ViewModelServices;
    typedef struct CCSPlayer_WaterServices CCSPlayer_WaterServices;
    typedef struct CCSPlayer_WeaponServices CCSPlayer_WeaponServices;
    typedef struct CCSObserver_ObserverServices CCSObserver_ObserverServices;
    typedef struct CCSObserver_CameraServices CCSObserver_CameraServices;
    typedef struct CCSObserver_MovementServices CCSObserver_MovementServices;
    typedef struct CCSObserver_UseServices CCSObserver_UseServices;
    typedef struct CCSObserver_ViewModelServices CCSObserver_ViewModelServices;
    typedef struct CCSPlayerController_ActionTrackingServices CCSPlayerController_ActionTrackingServices;
    typedef struct CCSPlayerController CCSPlayerController;
    typedef struct CDamageRecord CDamageRecord;
    typedef struct CCSPlayerController_DamageServices CCSPlayerController_DamageServices;
    typedef struct CCSPlayerController_InGameMoneyServices CCSPlayerController_InGameMoneyServices;
    typedef struct ServerAuthoritativeWeaponSlot_t ServerAuthoritativeWeaponSlot_t;
    typedef struct CCSPlayerController_InventoryServices CCSPlayerController_InventoryServices;
    typedef struct CCSWeaponBaseVDataAPI CCSWeaponBaseVDataAPI;
    typedef struct CCSWeaponBaseAPI CCSWeaponBaseAPI;
    typedef struct C_IronSightController C_IronSightController;
    typedef struct CompositeMaterialMatchFilter_t CompositeMaterialMatchFilter_t;
    typedef struct CompositeMaterialInputLooseVariable_t CompositeMaterialInputLooseVariable_t;
    typedef struct CompMatMutatorCondition_t CompMatMutatorCondition_t;
    typedef struct CompMatPropertyMutator_t CompMatPropertyMutator_t;
    typedef struct CompositeMaterialInputContainer_t CompositeMaterialInputContainer_t;
    typedef struct CompositeMaterialAssemblyProcedure_t CompositeMaterialAssemblyProcedure_t;
    typedef struct GeneratedTextureHandle_t GeneratedTextureHandle_t;
    typedef struct CompositeMaterial_t CompositeMaterial_t;
    typedef struct CompositeMaterialEditorPoint_t CompositeMaterialEditorPoint_t;
    typedef struct CCompositeMaterialEditorDoc CCompositeMaterialEditorDoc;
    typedef struct CGlobalLightBase CGlobalLightBase;
    typedef struct C_GlobalLight C_GlobalLight;
    typedef struct C_CSGO_PreviewModel_GraphController C_CSGO_PreviewModel_GraphController;
    typedef struct C_CSGO_PreviewPlayer_GraphController C_CSGO_PreviewPlayer_GraphController;
    typedef struct C_CSGO_MapPreviewCameraPathNode C_CSGO_MapPreviewCameraPathNode;
    typedef struct C_CSGO_MapPreviewCameraPath C_CSGO_MapPreviewCameraPath;
    typedef struct CCSPlayer_GlowServices CCSPlayer_GlowServices;
    typedef struct C_CSObserverPawnAPI C_CSObserverPawnAPI;
    typedef struct C_CSPlayerPawnAPI C_CSPlayerPawnAPI;
    typedef struct C_VoteController C_VoteController;
    typedef struct C_MapVetoPickController C_MapVetoPickController;
    typedef struct CPlayerSprayDecalRenderHelper CPlayerSprayDecalRenderHelper;
    typedef struct C_CSGO_TeamPreviewCamera C_CSGO_TeamPreviewCamera;
    typedef struct C_CSGO_TeamSelectCamera C_CSGO_TeamSelectCamera;
    typedef struct C_CSGO_TerroristTeamIntroCamera C_CSGO_TerroristTeamIntroCamera;
    typedef struct C_CSGO_TerroristWingmanIntroCamera C_CSGO_TerroristWingmanIntroCamera;
    typedef struct C_CSGO_CounterTerroristTeamIntroCamera C_CSGO_CounterTerroristTeamIntroCamera;
    typedef struct C_CSGO_CounterTerroristWingmanIntroCamera C_CSGO_CounterTerroristWingmanIntroCamera;
    typedef struct C_CSGO_EndOfMatchCamera C_CSGO_EndOfMatchCamera;
    typedef struct C_CSGO_EndOfMatchCharacterPosition C_CSGO_EndOfMatchCharacterPosition;
    typedef struct C_CSGO_EndOfMatchLineupEndpoint C_CSGO_EndOfMatchLineupEndpoint;
    typedef struct C_CSGO_EndOfMatchLineupStart C_CSGO_EndOfMatchLineupStart;
    typedef struct C_CSGO_EndOfMatchLineupEnd C_CSGO_EndOfMatchLineupEnd;
    typedef struct C_CsmFovOverride C_CsmFovOverride;
    typedef struct C_PointEntity C_PointEntity;
    typedef struct C_EnvCombinedLightProbeVolume C_EnvCombinedLightProbeVolume;
    typedef struct C_EnvCubemap C_EnvCubemap;
    typedef struct C_EnvCubemapBox C_EnvCubemapBox;
    typedef struct C_EnvCubemapFog C_EnvCubemapFog;
    typedef struct C_GradientFog C_GradientFog;
    typedef struct C_EnvLightProbeVolume C_EnvLightProbeVolume;
    typedef struct C_PlayerVisibility C_PlayerVisibility;
    typedef struct C_EnvVolumetricFogController C_EnvVolumetricFogController;
    typedef struct C_EnvVolumetricFogVolume C_EnvVolumetricFogVolume;
    typedef struct CInfoTarget CInfoTarget;
    typedef struct CInfoParticleTarget CInfoParticleTarget;
    typedef struct C_InfoVisibilityBox C_InfoVisibilityBox;
    typedef struct CInfoWorldLayer CInfoWorldLayer;
    typedef struct C_PointCamera C_PointCamera;
    typedef struct C_PointCameraVFOV C_PointCameraVFOV;
    typedef struct CPointTemplate CPointTemplate;
    typedef struct C_SoundAreaEntityBase C_SoundAreaEntityBase;
    typedef struct C_SoundAreaEntitySphere C_SoundAreaEntitySphere;
    typedef struct C_SoundAreaEntityOrientedBox C_SoundAreaEntityOrientedBox;
    typedef struct C_BasePlayerPawn C_BasePlayerPawn;
    typedef struct C_Team C_Team;
    typedef struct CBasePlayerVData CBasePlayerVData;
    typedef struct CBasePlayerWeaponVData CBasePlayerWeaponVData;
    typedef struct CClientAlphaProperty CClientAlphaProperty;
    typedef struct CServerOnlyModelEntity CServerOnlyModelEntity;
    typedef struct C_ModelPointEntity C_ModelPointEntity;
    typedef struct CLogicRelay CLogicRelay;
    typedef struct C_ParticleSystem C_ParticleSystem;
    typedef struct C_PathParticleRope C_PathParticleRope;
    typedef struct C_PathParticleRopeAlias_path_particle_rope_clientside C_PathParticleRopeAlias_path_particle_rope_clientside;
    typedef struct C_DynamicLight C_DynamicLight;
    typedef struct C_EnvScreenOverlay C_EnvScreenOverlay;
    typedef struct C_FuncTrackTrain C_FuncTrackTrain;
    typedef struct C_LightGlowOverlay C_LightGlowOverlay;
    typedef struct C_LightGlow C_LightGlow;
    typedef struct C_RagdollManager C_RagdollManager;
    typedef struct C_SpotlightEnd C_SpotlightEnd;
    typedef struct C_PointValueRemapper C_PointValueRemapper;
    typedef struct C_PointWorldText C_PointWorldText;
    typedef struct C_HandleTest C_HandleTest;
    typedef struct C_EnvWind C_EnvWind;
    typedef struct C_BaseToggle C_BaseToggle;
    typedef struct C_BaseButton C_BaseButton;
    typedef struct C_PrecipitationBlocker C_PrecipitationBlocker;
    typedef struct C_EntityDissolve C_EntityDissolve;
    typedef struct C_EnvProjectedTexture C_EnvProjectedTexture;
    typedef struct C_EnvDecal C_EnvDecal;
    typedef struct C_FuncBrush C_FuncBrush;
    typedef struct C_FuncElectrifiedVolume C_FuncElectrifiedVolume;
    typedef struct C_FuncRotating C_FuncRotating;
    typedef struct C_Breakable C_Breakable;
    typedef struct C_PhysBox C_PhysBox;
    typedef struct C_BaseFlex C_BaseFlex;
    typedef struct C_SceneEntity C_SceneEntity;
    typedef struct C_SunGlowOverlay C_SunGlowOverlay;
    typedef struct C_Sun C_Sun;
    typedef struct C_BaseTrigger C_BaseTrigger;
    typedef struct C_TriggerVolume C_TriggerVolume;
    typedef struct C_TriggerMultiple C_TriggerMultiple;
    typedef struct C_TriggerLerpObject C_TriggerLerpObject;
    typedef struct C_TriggerPhysics C_TriggerPhysics;
    typedef struct C_Beam C_Beam;
    typedef struct C_FuncLadder C_FuncLadder;
    typedef struct CPrecipitationVData CPrecipitationVData;
    typedef struct C_Sprite C_Sprite;
    typedef struct C_SpriteOriented C_SpriteOriented;
    typedef struct C_BaseClientUIEntity C_BaseClientUIEntity;
    typedef struct C_PointClientUIDialog C_PointClientUIDialog;
    typedef struct C_PointClientUIHUD C_PointClientUIHUD;
    typedef struct CPointOffScreenIndicatorUi CPointOffScreenIndicatorUi;
    typedef struct C_PointClientUIWorldPanel C_PointClientUIWorldPanel;
    typedef struct C_PointClientUIWorldTextPanel C_PointClientUIWorldTextPanel;
    typedef struct CInfoOffscreenPanoramaTexture CInfoOffscreenPanoramaTexture;
    typedef struct CBombTarget CBombTarget;
    typedef struct CHostageRescueZoneShim CHostageRescueZoneShim;
    typedef struct CHostageRescueZone CHostageRescueZone;
    typedef struct C_TriggerBuoyancy C_TriggerBuoyancy;
    typedef struct CFuncWater CFuncWater;
    typedef struct CWaterSplasher CWaterSplasher;
    typedef struct C_InfoInstructorHintHostageRescueZone C_InfoInstructorHintHostageRescueZone;
    typedef struct C_CSObserverPawn C_CSObserverPawn;
    typedef struct C_FootstepControl C_FootstepControl;
    typedef struct CCSWeaponBaseVData CCSWeaponBaseVData;
    typedef struct C_PlayerSprayDecal C_PlayerSprayDecal;
    typedef struct C_FuncConveyor C_FuncConveyor;
    typedef struct CGrenadeTracer CGrenadeTracer;
    typedef struct C_Inferno C_Inferno;
    typedef struct C_FireCrackerBlast C_FireCrackerBlast;
    typedef struct C_BarnLight C_BarnLight;
    typedef struct C_RectLight C_RectLight;
    typedef struct C_OmniLight C_OmniLight;
    typedef struct C_CSTeam C_CSTeam;
    typedef struct C_MapPreviewParticleSystem C_MapPreviewParticleSystem;
    typedef struct CInfoDynamicShadowHint CInfoDynamicShadowHint;
    typedef struct CInfoDynamicShadowHintBox CInfoDynamicShadowHintBox;
    typedef struct C_EnvSky C_EnvSky;
    typedef struct C_TonemapController2Alias_env_tonemap_controller2 C_TonemapController2Alias_env_tonemap_controller2;
    typedef struct C_LightEntity C_LightEntity;
    typedef struct C_LightSpotEntity C_LightSpotEntity;
    typedef struct C_LightOrthoEntity C_LightOrthoEntity;
    typedef struct C_LightDirectionalEntity C_LightDirectionalEntity;
    typedef struct C_LightEnvironmentEntity C_LightEnvironmentEntity;
    typedef struct C_EnvParticleGlow C_EnvParticleGlow;
    typedef struct C_TextureBasedAnimatable C_TextureBasedAnimatable;
    typedef struct C_World C_World;
    typedef struct CBaseAnimGraph CBaseAnimGraph;
    typedef struct CBaseProp CBaseProp;
    typedef struct C_BreakableProp C_BreakableProp;
    typedef struct C_DynamicProp C_DynamicProp;
    typedef struct C_DynamicPropAlias_dynamic_prop C_DynamicPropAlias_dynamic_prop;
    typedef struct C_DynamicPropAlias_prop_dynamic_override C_DynamicPropAlias_prop_dynamic_override;
    typedef struct C_DynamicPropAlias_cable_dynamic C_DynamicPropAlias_cable_dynamic;
    typedef struct C_ColorCorrectionVolume C_ColorCorrectionVolume;
    typedef struct C_FuncMonitor C_FuncMonitor;
    typedef struct C_FuncMoveLinear C_FuncMoveLinear;
    typedef struct C_PhysMagnet C_PhysMagnet;
    typedef struct C_PointCommentaryNode C_PointCommentaryNode;
    typedef struct C_WaterBullet C_WaterBullet;
    typedef struct C_BaseDoor C_BaseDoor;
    typedef struct C_ClientRagdoll C_ClientRagdoll;
    typedef struct C_Precipitation C_Precipitation;
    typedef struct C_FireSprite C_FireSprite;
    typedef struct C_FireFromAboveSprite C_FireFromAboveSprite;
    typedef struct C_Fish C_Fish;
    typedef struct C_PhysicsProp C_PhysicsProp;
    typedef struct C_BasePropDoor C_BasePropDoor;
    typedef struct C_PropDoorRotating C_PropDoorRotating;
    typedef struct C_PhysPropClientside C_PhysPropClientside;
    typedef struct C_RagdollProp C_RagdollProp;
    typedef struct C_LocalTempEntity C_LocalTempEntity;
    typedef struct C_ShatterGlassShardPhysics C_ShatterGlassShardPhysics;
    typedef struct C_EconEntity C_EconEntity;
    typedef struct C_EconWearable C_EconWearable;
    typedef struct C_BaseGrenade C_BaseGrenade;
    typedef struct C_PhysicsPropMultiplayer C_PhysicsPropMultiplayer;
    typedef struct C_ViewmodelWeapon C_ViewmodelWeapon;
    typedef struct C_ViewmodelAttachmentModel C_ViewmodelAttachmentModel;
    typedef struct C_PredictedViewModel C_PredictedViewModel;
    typedef struct C_WorldModelStattrak C_WorldModelStattrak;
    typedef struct C_WorldModelNametag C_WorldModelNametag;
    typedef struct C_BaseCSGrenadeProjectile C_BaseCSGrenadeProjectile;
    typedef struct C_SensorGrenadeProjectile C_SensorGrenadeProjectile;
    typedef struct CBreachChargeProjectile CBreachChargeProjectile;
    typedef struct CBumpMineProjectile CBumpMineProjectile;
    typedef struct CTripWireFireProjectile CTripWireFireProjectile;
    typedef struct C_CSGO_PreviewModel C_CSGO_PreviewModel;
    typedef struct C_CSGO_PreviewModelAlias_csgo_item_previewmodel C_CSGO_PreviewModelAlias_csgo_item_previewmodel;
    typedef struct C_WorldModelGloves C_WorldModelGloves;
    typedef struct C_BulletHitModel C_BulletHitModel;
    typedef struct C_HostageCarriableProp C_HostageCarriableProp;
    typedef struct C_PlantedC4 C_PlantedC4;
    typedef struct C_Multimeter C_Multimeter;
    typedef struct C_Item C_Item;
    typedef struct C_HEGrenadeProjectile C_HEGrenadeProjectile;
    typedef struct C_FlashbangProjectile C_FlashbangProjectile;
    typedef struct C_Chicken C_Chicken;
    typedef struct C_RagdollPropAttached C_RagdollPropAttached;
    typedef struct C_BaseCombatCharacter C_BaseCombatCharacter;
    typedef struct C_CSGOViewModel C_CSGOViewModel;
    typedef struct C_CSWeaponBase C_CSWeaponBase;
    typedef struct C_CSWeaponBaseGun C_CSWeaponBaseGun;
    typedef struct C_C4 C_C4;
    typedef struct C_DEagle C_DEagle;
    typedef struct C_WeaponElite C_WeaponElite;
    typedef struct C_WeaponNOVA C_WeaponNOVA;
    typedef struct C_WeaponSawedoff C_WeaponSawedoff;
    typedef struct C_WeaponTaser C_WeaponTaser;
    typedef struct C_WeaponXM1014 C_WeaponXM1014;
    typedef struct C_Knife C_Knife;
    typedef struct C_Melee C_Melee;
    typedef struct C_WeaponShield C_WeaponShield;
    typedef struct C_MolotovProjectile C_MolotovProjectile;
    typedef struct C_DecoyProjectile C_DecoyProjectile;
    typedef struct C_SmokeGrenadeProjectile C_SmokeGrenadeProjectile;
    typedef struct C_BaseCSGrenade C_BaseCSGrenade;
    typedef struct C_WeaponBaseItem C_WeaponBaseItem;
    typedef struct C_ItemDogtags C_ItemDogtags;
    typedef struct C_Item_Healthshot C_Item_Healthshot;
    typedef struct C_Fists C_Fists;
    typedef struct C_SensorGrenade C_SensorGrenade;
    typedef struct CBreachCharge CBreachCharge;
    typedef struct CBumpMine CBumpMine;
    typedef struct CTablet CTablet;
    typedef struct CTripWireFire CTripWireFire;
    typedef struct CWeaponZoneRepulsor CWeaponZoneRepulsor;
    typedef struct C_CSPlayerPawnBase C_CSPlayerPawnBase;
    typedef struct C_Hostage C_Hostage;
    typedef struct C_NetTestBaseCombatCharacter C_NetTestBaseCombatCharacter;
    typedef struct C_AK47 C_AK47;
    typedef struct C_WeaponAug C_WeaponAug;
    typedef struct C_WeaponAWP C_WeaponAWP;
    typedef struct C_WeaponBizon C_WeaponBizon;
    typedef struct C_WeaponFamas C_WeaponFamas;
    typedef struct C_WeaponFiveSeven C_WeaponFiveSeven;
    typedef struct C_WeaponG3SG1 C_WeaponG3SG1;
    typedef struct C_WeaponGalilAR C_WeaponGalilAR;
    typedef struct C_WeaponGlock C_WeaponGlock;
    typedef struct C_WeaponHKP2000 C_WeaponHKP2000;
    typedef struct C_WeaponUSPSilencer C_WeaponUSPSilencer;
    typedef struct C_WeaponM4A1 C_WeaponM4A1;
    typedef struct C_WeaponM4A1Silencer C_WeaponM4A1Silencer;
    typedef struct C_WeaponMAC10 C_WeaponMAC10;
    typedef struct C_WeaponMag7 C_WeaponMag7;
    typedef struct C_WeaponMP5SD C_WeaponMP5SD;
    typedef struct C_WeaponMP7 C_WeaponMP7;
    typedef struct C_WeaponMP9 C_WeaponMP9;
    typedef struct C_WeaponNegev C_WeaponNegev;
    typedef struct C_WeaponP250 C_WeaponP250;
    typedef struct C_WeaponCZ75a C_WeaponCZ75a;
    typedef struct C_WeaponP90 C_WeaponP90;
    typedef struct C_WeaponSCAR20 C_WeaponSCAR20;
    typedef struct C_WeaponSG556 C_WeaponSG556;
    typedef struct C_WeaponSSG08 C_WeaponSSG08;
    typedef struct C_WeaponTec9 C_WeaponTec9;
    typedef struct C_WeaponUMP45 C_WeaponUMP45;
    typedef struct C_WeaponM249 C_WeaponM249;
    typedef struct C_WeaponRevolver C_WeaponRevolver;
    typedef struct C_MolotovGrenade C_MolotovGrenade;
    typedef struct C_IncendiaryGrenade C_IncendiaryGrenade;
    typedef struct C_DecoyGrenade C_DecoyGrenade;
    typedef struct C_Flashbang C_Flashbang;
    typedef struct C_HEGrenade C_HEGrenade;
    typedef struct C_SmokeGrenade C_SmokeGrenade;
    typedef struct C_CSGO_PreviewPlayer C_CSGO_PreviewPlayer;
    typedef struct C_CSGO_PreviewPlayerAlias_csgo_player_previewmodel C_CSGO_PreviewPlayerAlias_csgo_player_previewmodel;
]]

ffi.cdef [[
    typedef struct SOID_t SOID_t;
    typedef struct AlternateIconData_t AlternateIconData_t;

    typedef enum ESOCacheEvent
    {
        eSOCacheEvent_None = 0,
        eSOCacheEvent_Subscribed = 1,
        eSOCacheEvent_Unsubscribed = 2,
        eSOCacheEvent_Resubscribed = 3,
        eSOCacheEvent_Incremental = 4,
        eSOCacheEvent_ListenerAdded = 5,
        eSOCacheEvent_ListenerRemoved = 6,
    } ESOCacheEvent;

    typedef struct CSharedObject CSharedObject;
    typedef struct CSharedObjectTypeCache CSharedObjectTypeCache;

    typedef struct CPaintKit CPaintKit;
    typedef struct CEconItem CEconItem;

    typedef struct CEconItemDefinition CEconItemDefinition;

    typedef struct CEconItemSchema CEconItemSchema;
    typedef struct CEconItemSystem CEconItemSystem;

    typedef struct CCSPlayerInventory CCSPlayerInventory;
    typedef struct CCSInventoryManager CCSInventoryManager;
]]

---
--- SOID_t
---

ffi.cdef [[
    typedef struct SOID_t {
        uint64_t m_id;
        uint32_t m_type;
        uint32_t m_padding;
    } SOID_t;
]]

---
--- AlternateIconData_t
---

ffi.cdef [[
    typedef struct AlternateIconData_t {
        char pad[0x10];
        const char* m_icon_path;
        const char* m_icon_path_large;
    } AlternateIconData_t;
]]

---
--- CSharedObjectTypeCache
---

ffi.cdef [[
    typedef struct CSharedObjectTypeCache {};
]]

ffi.metatype("CSharedObjectTypeCache", {
    __index = {
        AddObject = vtable_thunk(1, "bool(__thiscall*)(void*, void*)"),
        RemoveObject = vtable_thunk(3, "void*(__thiscall*)(void*, void*)"),
        GetEconItems = (function()
            local ct = ffi.typeof("$*", CUtlVector("CEconItem*"))
            return function(self)
                return ffi.cast(ct, ffi.cast("uintptr_t", self) + 0x8)[0]
            end
        end)()
    }
})

---
--- CPaintKit
---

ffi.cdef [[
    typedef struct CPaintKit {
        int m_id;
		const char* m_name;
		const char* m_description_string;
		const char* m_description_tag;
		const char* m_same_name_family_aggregate;
		const char* m_pattern;
		const char* m_normal;
		const char* m_logo_material;
        char pad[0x4];
        int m_rarity;
        int m_style;
        uint8_t m_color[4][4];
		uint8_t m_logocolor[4][4];
		float m_wear_default;
		float m_wear_remap_min;
		float m_wear_remap_max;
        int8_t m_phongexponent;
		int8_t m_phongalbedoboost;
		int8_t m_phongintensity;
		float m_pattern_scale;
		float m_pattern_offset_x_start;
		float m_pattern_offset_x_end;
		float m_pattern_offset_y_start;
		float m_pattern_offset_y_end;
		float m_pattern_rotate_start;
		float m_pattern_rotate_end;
		float m_logo_scale;
		float m_logo_offset_x;
		float m_logo_offset_y;
		float m_logo_rotation;
		bool m_ignore_weapon_size_scale;
		char pad[0x3];
		int m_view_model_exponent_override_size;
		bool m_only_first_material;
		bool m_use_normal;
        bool m_use_legacy;
		char pad[0x1];
		float m_pearlescent;
        const char* vmt_path;
        void* vmt_overrides;
    };
]]

---
--- CSource2Client
---

ffi.cdef [[
    typedef struct CSource2Client {} CSource2Client;
]]

local CSource2Client = ffi.cast("CSource2Client*", create_interface("client.dll", "Source2Client002"))
do
    local MT = {
        GetEconItemSystem = vtable_thunk(116, "CEconItemSystem*(__thiscall*)(void*)"),
    }

    ffi.metatype("CSource2Client", {
        __index = MT
    })
end

---
--- CEconItem
---

ffi.cdef [[
    typedef struct CEconItem {
        char pad[0x10];
        uint64_t m_ulID;
        uint64_t m_ulOriginalID;
        void* m_pCustomDataOptimizedObject;
        uint32_t m_unAccountID;
        uint32_t m_unInventory;
        uint16_t m_unDefIndex;
        uint16_t m_unOrigin: 5;
        uint16_t m_nQuality: 4;
        uint16_t m_unLevel: 2;
        uint16_t m_nRarity: 4;
        uint16_t m_dirtybitInUse: 1;
        int16_t m_iItemSet;
        int m_bSOUpdateFrame;
        uint8_t m_unFlags;
    } CEconItem;
]]

do
    local fnCreateSharedObjectSubclassEconItem = ffi.cast("CEconItem*(__cdecl*)()", mem.FindPattern("client.dll", "48 83 EC 28 B9 48 00 00 00 E8 ?? ?? ?? ?? 48 85"))
    local fnSetDynamicAttributeValue = ffi.cast("void*(__fastcall*)(void*, void*, void*)", absolute(mem.FindPattern("client.dll", "E9 ?? ?? ?? ?? CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC 49 8B C0 48 8B CA 48 8B D0"), 1, 0))

    ffi.metatype("CEconItem", {
        __index = {
            CreateInstance = fnCreateSharedObjectSubclassEconItem,
            SetDynamicAttributeValue = function(self, index, value)
                fnSetDynamicAttributeValue(self, CSource2Client:GetEconItemSystem():GetEconItemSchema():GetAttributeDefinitionInterface(index), value)
            end,
            Destruct = vtable_thunk(1, "void(__thiscall*)(void*, bool)"),
            SetPaintKit = function(self, value)
                local p = ffi.new("float[1]", value)
                self:SetDynamicAttributeValue(6, p)
            end,
            SetPaintSeed = function(self, value)
                local p = ffi.new("float[1]", value)
                self:SetDynamicAttributeValue(7, p)
            end,
            SetPaintWear = function(self, value)
                local p = ffi.new("float[1]", value)
                self:SetDynamicAttributeValue(8, p)
            end
        }
    })
end

---
--- CEconItemDefinition
---

ffi.cdef([[
    typedef struct CEconItemDefinition {
        void* m_vtable;
        void* m_kv;
        uint16_t m_definitionindex;
        $ m_associated_items;
        bool m_enabled;
        const char* m_prefab;
        uint8_t m_min_item_level;
        uint8_t m_max_item_level;
        uint8_t m_item_rarity;
        uint8_t m_item_quality;
        uint8_t m_forced_item_quality;
        uint8_t m_default_drop_item_quality;
        uint8_t m_default_drop_item_quantity;
        $ m_static_attributes;
        uint8_t m_popularity_seed;
        void* m_portraits;
        const char* m_item_base_name;
        bool m_propername;
        const char* m_item_type_name;
        uint32_t m_item_type_id;
        const char* m_item_description;
        uint32_t m_expiration_timestamp;
        uint32_t m_creation_timestamp;
        char* m_inventory_model;
        char* m_inventory_image;
        $ m_inventory_image_overlay;
        int m_inventory_image_pos_x;
        int m_inventory_image_pos_y;
        int m_inventory_image_size_w;
        int m_inventory_image_size_h;
        char* m_base_display_model;
        bool m_load_on_demand;
        bool m_has_been_loaded;
        bool hide_bodygroups_deployed_only;
        char* m_world_display_model;
        char* m_holstered_model;
        char* m_world_extra_wearable_model;
        uint32_t m_sticker_slots;
        char pad_104[0x4];
        char* icon_default_image;
        bool attach_to_hands;
        bool attach_to_hands_vm_only;
        bool flip_viewmodel;
        bool act_as_wearable;
        char pad_114[0x24];
        uint32_t item_type;
        char pad_13c[0x4];
        char* m_brass_model_override;
        char* m_zoom_in_sound_path;
        char* m_zoom_out_sound_path;
        char pad_158[0x18];
        uint32_t m_sound_material_id;
        bool m_disable_style_selection;
        char pad_175[0x13];
        char* m_particle_file;
        char* m_particle_snapshot_file;
        char pad_198[0x40];
        char* m_item_classname;
        char* m_item_log_classname;
        char* m_item_icon_classname;
        char* m_definitionname;
        bool hidden;
        bool m_should_show_in_armory;
        bool m_base_item;
        bool m_flexible_loadout_default;
        bool m_import;
        bool m_one_per_account_cdkey;
        char pad_1fe[0xa];
        char* m_armory_desc;
        char pad_210[0x8];
        char* m_armory_remap;
        char* m_store_remap;
        char* m_class_token;
        char* m_slot_token;
        uint32_t m_drop_type;
        char pad_23c[0x4];
        char* m_holiday_restriction;
        uint32_t m_subtype;
        char pad_24c[0xc];
        uint32_t m_equip_region_mask;
        uint32_t m_equip_region_conflict_mask;
        char pad_260[0x50];
        bool m_public_item;
        bool m_ignore_in_collection_view;
        char pad_2b2[0x36];
        int m_loadout_slot;
        char pad_2ec[0x94];
    } CEconItemDefinition;
]], CUtlVector "uint16_t", CUtlVector "void*", CUtlVector "const char*")


do
    ffi.metatype("CEconItemDefinition"
    , {
        __index = {
            GetItemBaseName = function(self)
                if self.m_item_base_name == nil then return nil end
                return ffi.string(self.m_item_base_name)
            end,
            GetItemTypeName = function(self)
                if self.m_item_type_name == nil then return nil end
                return ffi.string(self.m_item_type_name)
            end
        }
    })
end

---
--- CEconItemSchema
---

ffi.cdef [[
    typedef struct CEconItemSchema {};
]]

do
    local native_GetAttributeDefinitionInterface = vtable_thunk(27, "void*(__thiscall*)(void*, int)")
    local native_GetItemDefinitionByName = vtable_thunk(42, "CEconItemDefinition*(__thiscall*)(void*, const char*)")

    ffi.metatype("CEconItemSchema", {
        __index = {
            GetAttributeDefinitionInterface = native_GetAttributeDefinitionInterface,
            GetItemDefinitionByName = native_GetItemDefinitionByName,
            GetAlternateIcons = (function()
                local T = ffi.typeof("$*", CUtlMap("uint64_t", "AlternateIconData_t", "int"))
                return function(self)
                    return ffi.cast(T, ffi.cast("uintptr_t", self) + 0x278)[0]
                end
            end)(),
            GetPaintKits = (function()
                local T = ffi.typeof("$*", CUtlMap("int", "CPaintKit*", "int"))
                return function(self)
                    return ffi.cast(T, ffi.cast("uintptr_t", self) + 0x2F0)[0]
                end
            end)()
        }
    })
end


---
--- CEconItemSystem
---

ffi.cdef [[
    typedef struct CEconItemSystem {};
]]

ffi.metatype("CEconItemSystem", {
    __index = {
        GetEconItemSchema = function(self)
            return ffi.cast("CEconItemSchema**", ffi.cast("uintptr_t", self) + 0x8)[0]
        end
    }
})

---
--- CCSPlayerInventory
---

ffi.cdef [[
    typedef struct CCSPlayerInventory {};
]]

do
    local fnCreateBaseTypeCache = ffi.cast("CSharedObjectTypeCache*(__thiscall*)(void*, int)", absolute(mem.FindPattern("client.dll", "E8 ?? ?? ?? ?? 33 C9 8B D1"), 1, 0))
    local pGCClientSystem = ffi.cast("uintptr_t(__cdecl*)()", absolute(mem.FindPattern("client.dll", "E8 ?? ?? ?? ?? 48 8B 4F 10 8B 1D ?? ?? ?? ??"), 1, 0))()
    local fnFindSOCache = ffi.cast("void*(__thiscall*)(uintptr_t, SOID_t, bool)", absolute(mem.FindPattern("client.dll", "E8 ?? ?? ?? ?? 48 8B F0 48 85 C0 74 0E 4C 8B C3"), 1, 0))

    ffi.metatype("CCSPlayerInventory", {
        __index = {
            SOCreated = vtable_thunk(0, "void(__thiscall*)(void*, SOID_t, void*, ESOCacheEvent)"),
            SOUpdated = vtable_thunk(1, "void(__thiscall*)(void*, SOID_t, void*, ESOCacheEvent)"),
            SODestroyed = vtable_thunk(2, "void(__thiscall*)(void*, SOID_t, void*, ESOCacheEvent)"),

            GetItemInLoadout = vtable_thunk(8, "C_EconItemView*(__thiscall*)(void*, int, int)"),
            GetOwnerID = function(self)
                return ffi.cast("SOID_t*", ffi.cast("uintptr_t", self) + 0x10)[0]
            end,
            GetSteamID = function(self)
                return ffi.cast("uint64_t*", ffi.cast("uintptr_t", self) + 0x10)[0]
            end,
            GetBaseTypeCache = function(self)
                return fnCreateBaseTypeCache(fnFindSOCache(pGCClientSystem + 0xb8, self:GetOwnerID(), false), 1)
            end,
            GetHighestIDs = function(self)
                local max_item_id = 0
                local max_inventory_id = 0
                local sotypecache = self:GetBaseTypeCache()
                if sotypecache ~= nil then
                    local items = sotypecache:GetEconItems()
                    for _, it in ipairs(items) do
                        if it == nil then goto continue end

                        if bit.band(it.m_ulID, 0xF000000000000000) ~= 0 then goto continue end

                        max_item_id = math.max(max_item_id, tonumber(it.m_ulID))
                        max_inventory_id = math.max(max_inventory_id, tonumber(it.m_unInventory))
                        ::continue::
                    end
                end

                return max_item_id, max_inventory_id
            end,
            GetInventoryItems = (function()
                local T = ffi.typeof("$*", CUtlVector("C_EconItemView*"))
                return function(self)
                    return ffi.cast(T, ffi.cast("uintptr_t", self) + 0x20)[0]
                end
            end)(),
            AddEconItem = function(self, item)
                if item == nil then return end
                local sotypecache = self:GetBaseTypeCache()
                if sotypecache == nil or not sotypecache:AddObject(item) then return end

                self:SOCreated(self:GetOwnerID(), item, C.eSOCacheEvent_Incremental)
                return true
            end,
            RemoveEconItem = function(self, item)
                if item == nil then return false end

                local sotypecache = self:GetBaseTypeCache()

                local owner = self:GetOwnerID()
                local shared_objects = sotypecache:GetEconItems(item)
                for i = 0, shared_objects:count() - 1 do
                    if shared_objects.m_memory.m_memory[i] == item then
                        self:SODestroyed(owner, item, C.eSOCacheEvent_Incremental)
                        sotypecache:RemoveObject(item)
                        item:Destruct(true)
                    end
                end
            end,
            GetInventoryItemByItemID = function(self, itemid)
                local items = self:GetInventoryItems()
                for i = 0, items:count() - 1 do
                    if items.m_memory.m_memory[i].m_iItemID == itemid then
                        return items.m_memory.m_memory[i]
                    end
                end
            end
        }
    })
end

---
--- CCSInventoryManager
---

ffi.cdef [[
    typedef struct CCSInventoryManager {};
]]

do
    local fnGetInventoryManager = ffi.cast("CCSInventoryManager*(__cdecl*)()", absolute(mem.FindPattern("client.dll", "E8 ?? ?? ?? ?? 48 63 BB ?? ?? ?? ?? 48 8D 68 28 83 FF FF"), 1, 0))

    ffi.metatype("CCSInventoryManager", {
        __index = {
            GetInstance = fnGetInventoryManager,
            GetLocalInventory = vtable_thunk(57, "CCSPlayerInventory*(__thiscall*)(void*)"),
        }
    })
end

---
--- C_BaseEntity
---

ffi.cdef [[
    typedef struct C_BaseEntity {};
]]

do
    local offset_t = {
        m_pGameSceneNode = schema_offset("CGameSceneNode*", "C_BaseEntity", "m_pGameSceneNode", 0)
    }

    ffi.metatype("C_BaseEntity", {
        __index = function(self, key)
            if offset_t[key] then return offset_t[key](self) end
        end,
        __newindex = function(self, key, value)
            if offset_t[key] then return offset_t[key](self, value) end
        end
    })
end

---
--- C_EconItemView
---

ffi.cdef [[
    typedef struct C_EconItemView {};
]]

do
    local native_GetStaticData = vtable_thunk(13, "CEconItemDefinition*(__thiscall*)(void*)")

    local MT = {
        GetStaticData = native_GetStaticData,
    }

    local offset_t = {
        m_iItemDefinitionIndex = schema_offset("uint16_t", "C_EconItemView", "m_iItemDefinitionIndex", 0),
        m_iAccountID = schema_offset("uint32_t", "C_EconItemView", "m_iAccountID", 0),
        m_iItemID = schema_offset("uint64_t", "C_EconItemView", "m_iItemID", 0),
        m_iItemIDLow = schema_offset("uint32_t", "C_EconItemView", "m_iItemIDLow", 0),
        m_iItemIDHigh = schema_offset("uint32_t", "C_EconItemView", "m_iItemIDHigh", 0),
        m_bInitialized = schema_offset("bool", "C_EconItemView", "m_bInitialized", 0),
        m_bDisallowSOC = schema_offset("bool", "C_EconItemView", "m_bDisallowSOC", 0),
    }

    ffi.metatype("C_EconItemView", {
        __index = function(self, key)
            if offset_t[key] then return offset_t[key](self) end
            if MT[key] then return MT[key] end
        end,
        __newindex = function(self, key, value)
            if offset_t[key] then return offset_t[key](self, value) end
        end
    })
end

---
--- C_CSPlayerPawn
---

ffi.cdef [[
    typedef struct C_CSPlayerPawn {};
]]

do
    local offset_t = {
        m_EconGloves = schema_offset("C_EconItemView", "C_CSPlayerPawn", "m_EconGloves"),
        m_bNeedToReApplyGloves = schema_offset("bool", "C_CSPlayerPawn", "m_bNeedToReApplyGloves", 0)
    }

    ffi.metatype("C_CSPlayerPawn", {
        __index = function(self, key)
            if offset_t[key] then return offset_t[key](self) end
        end,
        __newindex = function(self, key, value)
            if offset_t[key] then return offset_t[key](self, value) end
        end
    })
end


---
--- events
---

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

do
    callbacks.Register("Unload", function() fire_event("shutdown") end)

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
    set_event_callback("shutdown", function()
        fnFrameStageNotify:remove()
    end)

    fnFrameStageNotify = detour.new("void*(__fastcall*)(void*, int)", function(thisptr, framestage)
        for key, value in pairs(framestage_t) do if value == framestage then fire_event(key) end end
        return fnFrameStageNotify(thisptr, framestage)
    end, mem.FindPattern("client.dll", "48 89 5C 24 ?? 56 48 83 EC ?? 8B 05 ?? ?? ?? ?? 8D 5A"))
end

---
--- CGameEntitySystem
---

ffi.cdef [[
    typedef struct CGameEntitySystem {} CGameEntitySystem;
]]

local CGameEntitySystem = ffi.cast("CGameEntitySystem**", ffi.cast("uintptr_t", create_interface("engine2.dll", "GameResourceServiceClientV001")) + 0x58)[0]
ffi.metatype("CGameEntitySystem", {
    __index = {
        GetEntityInstance = function(self, entindex)
            if ffi.istype("uint32_t", entindex) then
                entindex = bit.band(entindex, 0x7FFF)
            end

            if type(entindex) == "number" and entindex <= 0x7FFE and bit.rshift(entindex, 9) <= 0x3F then
                local v2 = ffi.cast("uint64_t*", ffi.cast("uintptr_t", self) + 8 * bit.rshift(entindex, 9) + 16)[0]
                if v2 == 0 then return end

                local v3 = ffi.cast("uint32_t*", 120 * bit.band(entindex, 0x1FF) + v2)
                if v3 == nil then return end

                if bit.band(v3[4], 0x7FFF) == entindex then return ffi.cast("C_BaseEntity*", ffi.cast("uint64_t*", v3)[0]) end
            end
        end
    }
})

---
---itemdefinition table
---

local itemdefinition_t = {}
do
    local econitemschema = CSource2Client:GetEconItemSystem():GetEconItemSchema()

    local alternate_icons = econitemschema:GetAlternateIcons()
    local paint_kits = econitemschema:GetPaintKits()

    local function find_skins(item)
        local res = {}

        local index = bit.lshift(item.m_definitionindex, 16)

        local size = paint_kits.m_tree.m_numelements - 1
        local data = paint_kits.m_tree.m_elements
        for i = 0, size do
            local paintkit = data[i].m_data.elem
            local id = paintkit.m_id
            if id ~= 0 and id ~= 9001 then
                if alternate_icons:find(bit.bor(index, bit.lshift(id, 2))) ~= -1 then
                    table.insert(res, {
                        id = id,
                        rarity = paintkit.m_rarity
                    })
                end
            end
        end

        return res
    end

    benchmark:start("dump items")
    for _, value in ipairs({"studded_bloodhound_gloves", "sporty_gloves", "slick_gloves", "leather_handwraps", "motorcycle_gloves", "specialist_gloves", "studded_hydra_gloves", "studded_brokenfang_gloves"}) do
        local item = econitemschema:GetItemDefinitionByName(value)
        local item_t = {
            rarity = item.m_item_rarity,
            defindex = item.m_definitionindex
        }

        item_t.skins = find_skins(item)

        table.insert(itemdefinition_t, item_t)
    end
    benchmark:finish("dump items")
end

---
---load econitem
---

local econitem_t = {}
do
    local CCSInventoryManager = ffi.typeof("CCSInventoryManager").GetInstance()
    local CEconItem = ffi.typeof("CEconItem")

    local inventory = CCSInventoryManager:GetLocalInventory()
    local xuid = inventory:GetSteamID()

    benchmark:start("load econitem")

    for _, item_t in ipairs(itemdefinition_t) do
        for _, skin in ipairs(item_t.skins) do
            local max_itemid = inventory:GetHighestIDs()

            local instance = CEconItem.CreateInstance()
            instance.m_ulID = max_itemid + 1
            instance.m_ulOriginalID = 0
            instance.m_unAccountID = xuid
            instance.m_unDefIndex = item_t.defindex
            instance.m_unInventory = 0
            instance.m_nQuality = 3
            instance.m_nRarity = clamp(item_t.rarity + skin.rarity - 1, 0, skin.rarity == 7 and 7 or 6)

            instance:SetPaintKit(skin.id)

            if inventory:AddEconItem(instance) then
                table.insert(econitem_t, instance)
            end
        end
    end

    benchmark:finish("load econitem")

    callbacks.Register("Unload", function()
        benchmark:start("unload econitem")
        for _, instance in ipairs(econitem_t) do
            inventory:RemoveEconItem(instance)
        end
        benchmark:finish("unload econitem")
    end)
end

---
--- skin changes
---

local CCSInventoryManager = ffi.typeof("CCSInventoryManager").GetInstance()
local fnSetMeshGroupMask = ffi.cast("void(__thiscall*)(void*, uint64_t)", absolute(mem.FindPattern("client.dll", "E8 ?? ?? ?? ?? 48 8B 5C 24 ?? 4C 8B 7C 24 ?? 4C 8B 74 24 ??"), 1, 0))

--- gloves
do
    ffi.cdef [[
        typedef enum viewmodel_material
        {
            viewmodel_material_gloves = 0xf143b82a,
            viewmodel_material_hostage = 0x1b52829c,
            viewmodel_material_sleeves = 0x423b2ed4
        } viewmodel_material;

        typedef struct viewmodel_material_record_t {
            uint32_t unknown;
            uint32_t identifier;
            uint32_t handle;
            uint32_t typeindex;
        } viewmodel_material_record_t;

        typedef struct viewmodel_material_info_t {
            viewmodel_material_record_t* records;
            uint32_t count;
        } viewmodel_material_info_t;
    ]]

    local function get_glove_mat(instance)
        local matinfo = ffi.cast("viewmodel_material_info_t*", ffi.cast("uint8_t*", instance) + 0xf88)
        for i = 0, matinfo.count - 1 do
            if matinfo.records[i].identifier == C.viewmodel_material_gloves then
                return matinfo.records[i]
            end
        end
    end

    local update_frames = 0
    local last_handles = {}
    set_event_callback("frame_render_end", function()
        local inventory = CCSInventoryManager:GetLocalInventory()
        if inventory == nil then return end

        local localpawn_index = client.GetLocalPlayerIndex()
        if localpawn_index == nil then return end

        local localpawn_instance = ffi.cast("C_CSPlayerPawn*", CGameEntitySystem:GetEntityInstance(localpawn_index))
        if localpawn_instance == nil then return end

        local viewmodel = unpack(entities.FindByClass("C_CSGOViewModel"))
        if viewmodel == nil then return end

        local viewmodel_index = viewmodel:GetIndex()
        local viewmodel_instance = CGameEntitySystem:GetEntityInstance(viewmodel_index)
        if viewmodel_instance == nil then return end

        local item_instance = localpawn_instance.m_EconGloves
        if item_instance == nil then return end

        local item_inloadout = inventory:GetItemInLoadout(entities.GetByIndex(localpawn_index):GetTeamNumber(), 41)
        if item_inloadout == nil then return end

        if not inventory:GetInventoryItemByItemID(item_inloadout.m_iItemID) then return end

        local inloadout_definition = item_inloadout:GetStaticData()
        if inloadout_definition == nil then return end

        if inloadout_definition:GetItemTypeName() ~= "#Type_Hands" then return end

        -- 更新项目id
        if item_instance.m_iItemID ~= item_inloadout.m_iItemID then
            benchmark:start("update gloves item id")
            update_frames = 3

            for _, value in ipairs({
                "m_iAccountID",
                "m_bDisallowSOC",
                "m_iItemID",
                "m_iItemIDLow",
                "m_iItemIDHigh",
                "m_iItemDefinitionIndex"
            }) do
                item_instance[value] = item_inloadout[value]
            end

            local viewmodelscenenode = viewmodel_instance.m_pGameSceneNode
            if viewmodelscenenode ~= nil then fnSetMeshGroupMask(viewmodelscenenode, 1) end

            benchmark:finish("update gloves item id")
        end

        local mat_records = get_glove_mat(viewmodel_instance)
        if mat_records == nil then return end

        -- 检查当前句柄是否是更新的
        local current_handle = mat_records.handle
        last_handles = #last_handles == 0 and {current_handle, 0, 0} or last_handles

        if current_handle ~= last_handles[3] and
            last_handles[3] == last_handles[2] and
            last_handles[2] == last_handles[1] and
            update_frames == 0 then
            update_frames = 3
        end

        last_handles[1], last_handles[2], last_handles[3] = last_handles[2], last_handles[3], current_handle

        -- 初始化更新手套材料
        if update_frames > 0 then
            benchmark:start("update gloves")
            mat_records.typeindex = 0xffffffff
            item_instance.m_bInitialized = true
            localpawn_instance.m_bNeedToReApplyGloves = true

            update_frames = update_frames - 1
            benchmark:finish("update gloves")
        end
    end)
end

--Because loadstring crashes when calling the callback, it can only be like this before the fix...
gui.Command [[lua.run 

local vtable =
    (function()
    local ffi = require 'ffi'
    local ffi_cast, ffi_typeof = ffi.cast, ffi.typeof
    local interface_ptr = ffi_typeof('void***')

    local function entry(instance, i, ct)
        return ffi_cast(ct, ffi_cast(interface_ptr, instance)[0][i])
    end

    local function bind(instance, i, ct)
        local t = ffi_typeof(ct)
        local fnptr = entry(instance, i, t)
        return function(...)
            return fnptr(instance, ...)
        end
    end

    local function thunk(i, ct)
        local t = ffi_typeof(ct)
        return function(instance, ...)
            return entry(instance, i, t)(instance, ...)
        end
    end

    local hook =
        (function()
        local C = ffi.C

        local v_ptr = ffi_typeof('void*')
        local ui_ptr = ffi_typeof('uintptr_t**')
        local in_ptr = ffi_typeof('intptr_t')
        local ul_ptr = ffi_typeof('unsigned long[1]')
        ffi.cdef 'int VirtualProtect(void*, unsigned long, unsigned long, unsigned long*)'

        local hook = {hooks = {}}

        function hook.new(instance, i, ct, callback)
            local t = ffi_typeof(ct)
            local old_prot = ul_ptr()

            local instance_ptr = ffi_cast(ui_ptr, instance)[0]
            local instance_void = ffi_cast(v_ptr, instance_ptr + i)

            hook.hooks[i] = instance_ptr[i]
            C.VirtualProtect(instance_void, 4, 4, old_prot)
            instance_ptr[i] = ffi_cast(in_ptr, ffi_cast(v_ptr, ffi_cast(t, callback)))
            C.VirtualProtect(instance_void, 4, old_prot[0], old_prot)

            return setmetatable(
                {
                    call = ffi_cast(t, hook.hooks[i]),
                    uninstall = function()
                        C.VirtualProtect(instance_void, 4, 4, old_prot)
                        instance_ptr[i] = hook.hooks[i]
                        C.VirtualProtect(instance_void, 4, old_prot[0], old_prot)
                        hook.hooks[i] = nil
                    end
                },
                {
                    __call = function(self, ...)
                        return self.call(...)
                    end
                }
            )
        end

        return hook.new
    end)()

    return {
        entry = entry,
        bind = bind,
        thunk = thunk,
        hook = hook
    }
end)()

local find_interface =
    (function()
    local ffi = require 'ffi'
    local C = ffi.C

    ffi.cdef 'void* GetModuleHandleA(const char*)'
    ffi.cdef 'void* GetProcAddress(const char*, const char*)'
    ffi.cdef 'typedef void* (*CreateInterfaceFn)(const char*, int*)'

    local function find_interface(module_name, interface_name)
        return ffi.cast('CreateInterfaceFn', ffi.C.GetProcAddress(ffi.C.GetModuleHandleA(module_name), 'CreateInterface'))(interface_name, nil)
    end

    return find_interface
end)()

local frame_stage_t, hook_frame_stage = {}, nil
hook_frame_stage =
    vtable.hook(
    find_interface('client', 'VClient018'),
    37,
    'void(__stdcall*)(int)',
    function(stage)
        for k, v in pairs(frame_stage_t) do
            v(stage)
        end
        return hook_frame_stage(stage)
    end
)

local panel_t, hook_panel = {}, nil
local get_panel_name = vtable.thunk(36, 'const char*(__thiscall*)(void*, uint32_t)')
hook_panel =
    vtable.hook(
    find_interface('vgui2', 'VGUI_Panel009'),
    41,
    'void(__thiscall*)(void*, uint32_t, bool, bool)',
    function(this, panel, repaint, force)
        for k, v in pairs(panel_t) do
            v(ffi.string(get_panel_name(this, panel)))
        end
        return hook_panel(this, panel, repaint, force)
    end
)
local callbacks_Register, callbacks_Unregister = callbacks.Register, callbacks.Unregister
callbacks_Register(
    'Unload',
    function()
        hook_panel.uninstall()
        hook_frame_stage.uninstall()
    end
)

---@param id string
---@param func function
function callbacks.Register(id, func)
    local unique = tostring(func)
    local new_id = id and id == 'FrameStage' and frame_stage_t or id == 'Panel' and panel_t

    if new_id then
        new_id[unique] = func
        return callbacks_Register(
            'Unload',
            function()
                new_id[unique] = nil
            end
        )
    end

    return callbacks_Register(id, unique, func)
end

---@param id string
---@param func function
function callbacks.Unregister(id, func)
    local unique = tostring(func)
    local new_id = id and id == 'FrameStage' and frame_stage_t or id == 'Panel' and panel_t

    if new_id then
        new_id[unique] = nil
    end

    return callbacks_Unregister(id, unique)
end

]]

return callbacks

ffi.cdef [[
    typedef struct
    {
        char    _0x0000[16];
        int     x;
        int     x_old;
        int     y;
        int     y_old;
        int     width;
        int     width_old;
        int     height;
        int     height_old;
        char    _0x0030[128];
        float   fov; 
        float   fov_viewmodel;
        float     origin_x;
        float     origin_y;
        float     origin_z;
        float     angles_pitch;
        float     angles_yaw;
        float     angles_roll;
    } CViewSetup;
]]

--Because loadstring crashes when calling the callback, it can only be like this before the fix...
gui.Command [[lua.run 

local vtable = require 'vtable'

local base_client = vtable.new('client', 'VClient018')
local frame_stage_t, hook_frame_stage = {}, nil
hook_frame_stage =
    base_client:hook(
    37,
    {'int'},
    function(stage)
        for k, v in pairs(frame_stage_t) do
            v(stage)
        end
        return hook_frame_stage(stage)
    end
)

local gui_panel = vtable.new('vgui2', 'VGUI_Panel009')
local get_panel_name = gui_panel:bind(36, 'const char*(__thiscall*)(void*, uint32_t)')

local gui_panel_t, hook_gui_panel = {}, nil
hook_gui_panel =
    gui_panel:hook(
    41,
    'void(__thiscall*)(void*, uint32_t, bool, bool)',
    function(this, panel, repaint, force)
        for k, v in pairs(gui_panel_t) do
            v(get_panel_name(panel))
        end
        return hook_gui_panel(this, panel, repaint, force)
    end
)

local override_view_t, hook_override_view = {}, nil
hook_override_view =
    vtable.hook(
    ffi.cast(ffi.typeof('uintptr_t***'), ffi.cast(ffi.typeof('uintptr_t**'), base_client.interface)[0][10] + 5)[0][0],
    18,
    'void(__thiscall*)(uintptr_t*, CViewSetup*)',
    function(this, setup)
        local new_setup = {
            fov = setup.fov,
            fov_viewmodel = setup.fov_viewmodel,
            x = setup.origin_x,
            y = setup.origin_y,
            z = setup.origin_z,
            pitch = setup.angles_pitch,
            yaw = setup.angles_yaw,
            roll = setup.angles_roll
        }

        for k, v in pairs(override_view_t) do
            v(new_setup)
        end

        setup.fov = new_setup.fov
        setup.fov_viewmodel = new_setup.fov_viewmodel
        setup.origin_x = new_setup.x
        setup.origin_y = new_setup.y
        setup.origin_z = new_setup.z
        setup.angles_pitch = new_setup.pitch
        setup.angles_yaw = new_setup.yaw
        setup.angles_roll = new_setup.roll

        return hook_override_view(this, setup)
    end
)

local callbacks_Register, callbacks_Unregister = callbacks.Register, callbacks.Unregister
callbacks_Register(
    'Unload',
    function()
        hook_gui_panel.uninstall()
        hook_frame_stage.uninstall()
        hook_override_view.uninstall()
    end
)

function callbacks.Register(id, func)
    local unique = tostring(func)
    local new_id = id and id == 'FrameStageNotify' and frame_stage_t or id == 'Panel' and gui_panel_t or id == 'OverrideView' and override_view_t

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

function callbacks.Unregister(id, func)
    local unique = tostring(func)
    local new_id = id and id == 'FrameStageNotify' and frame_stage_t or id == 'Panel' and gui_panel_t or id == 'OverrideView' and override_view_t

    if new_id then
        new_id[unique] = nil
    end

    return callbacks_Unregister(id, unique)
end

]]

return callbacks

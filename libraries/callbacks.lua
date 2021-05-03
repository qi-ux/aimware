function require(name)
    package = package or {}

    package.loaded = package.loaded or {}

    package.loaded[name] = package.loaded[name] or RunScript(name .. ".lua") or true

    return package.loaded[name]
end

local globals_CurTime = globals.CurTime

local callbacks_Register = callbacks.Register

local client_AllowListener, client_GetLocalPlayerIndex, client_GetPlayerIndexByUserID =
    client.AllowListener,
    client.GetLocalPlayerIndex,
    client.GetPlayerIndexByUserID

local gui_Reference = gui.Reference

local _delay_call = {}

function callbacks.delay_call(delay, id, callback)
    local len = (id and type(id) == "string") and id or #_delay_call + 1
    local callback = id and callback or id
    _delay_call[len] = {}
    _delay_call[len].delay = delay
    _delay_call[len].last_time = globals_CurTime() + delay
    _delay_call[len].callback = callback
end

function callbacks.un_delay(id)
    local len = (id and type(id) == "string") and id or #_delay_call
    _delay_call[len] = nil
end

local _callbacks = {}

function callbacks.set_event(event_name, id, callback)
    client_AllowListener(event_name)
    local len = (id and type(id) == "string") and id or #_callbacks + 1
    local callback = id and callback or id
    _callbacks[len] = {}
    _callbacks[len].type = event_name
    _callbacks[len].callback = callback
end

function callbacks.un_event(id)
    local len = (id and type(id) == "string") and id or #_callbacks
    _callbacks[len] = nil
end

local menu = gui_Reference("menu")

callbacks_Register(
    "Draw",
    function()
        for k, v in pairs(_callbacks) do
            local low = v.type:lower()
            local draw = (low == "draw" or low == "paint") and v.callback()
            local draw_ui = (low == "draw_ui" or low == "paint_ui") and menu:IsActive() and v.callback()
        end

        for k, v in pairs(_delay_call) do
            if globals_CurTime() >= v.last_time then
                v.callback(v.delay)
                v.last_time = v.last_time + v.delay
            end
        end
    end
)

callbacks_Register(
    "DrawESP",
    function(builder)
        for k, v in pairs(_callbacks) do
            local low = v.type:lower()
            local draw_esp = (low == "drawesp" or low == "draw_esp" or low == "paint_esp") and v.callback(builder)
        end
    end
)

callbacks_Register(
    "DrawModel",
    function(context)
        for k, v in pairs(_callbacks) do
            local low = v.type:lower()
            local draw_model = (low == "drawmodel" or low == "draw_model" or low == "paint_model") and v.callback(context)
        end
    end
)

callbacks_Register(
    "CreateMove",
    function(cmd)
        for k, v in pairs(_callbacks) do
            local low = v.type:lower()
            local create_move = (low == "createmove" or low == "create_move") and v.callback(cmd)
        end
    end
)

callbacks_Register(
    "DispatchUserMessage",
    function(message)
        for k, v in pairs(_callbacks) do
            local low = v.type:lower()
            local user_message = (low == "dispatchusermessage" or low == "user_message") and v.callback(message)
        end
    end
)

callbacks_Register(
    "SendStringCmd",
    function(string)
        for k, v in pairs(_callbacks) do
            local low = v.type:lower()
            local send_string_cmd = (low == "sendstringcmd" or low == "send_string_cmd") and v.callback(string)
        end
    end
)

local aim_tar = {}

callbacks_Register(
    "AimbotTarget",
    function(entity)
        aim_tar.aim_fire = type(entity) == "userdata" and entity:GetName() and true or false

        for k, v in pairs(_callbacks) do
            local low = v.type:lower()
            local aim_tar = (low == "aimbottarget" or low == "aim_tar") and v.callback(entity)
        end
    end
)

callbacks_Register(
    "FireGameEvent",
    function(event)
        if not (type(event) == "userdata" and event:GetName()) then
            return
        end

        local en = event:GetName()

        local lp_idx = client_GetLocalPlayerIndex()
        local attacker = client_GetPlayerIndexByUserID(event:GetInt("attacker"))
        local userid = client_GetPlayerIndexByUserID(event:GetInt("userid"))

        for k, v in pairs(_callbacks) do
            local low = v.type:lower()

            local fire_game_event =
                aim_tar.aim_fire and
                (v.type == "aim_fire" and en == "weapon_fire" and userid == lp_idx and v.callback(event) or
                    v.type == "aim_hit" and en == "player_hurt" and attacker == lp_idx and userid ~= lp_index and
                        v.callback(event:GetInt("dmg_health"), event)) or
                (v.type == en or low == "firegameevent" or low == "game_event") and v.callback(event)
        end
    end
)

return callbacks

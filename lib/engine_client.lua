local ffi = require "ffi"
local C = ffi.C

local interface_ptr = ffi.typeof("void***")
local function vtable_entry(instance, i, ct)
    return ffi.cast(ct, ffi.cast(interface_ptr, instance)[0][i])
end

local function vtable_bind(instance, i, ct)
    local t = ffi.typeof(ct)
    local fnptr = vtable_entry(instance, i, t)
    return function(...)
        return fnptr(instance, ...)
    end
end

local function vtable_thunk(i, ct)
    local t = ffi.typeof(ct)
    return function(instance, ...)
        return vtable_entry(instance, i, t)(instance, ...)
    end
end

ffi.cdef [[
    void* GetModuleHandleA(const char*);
    void* GetProcAddress(const char*, const char*);
    typedef void* (*CreateInterfaceFn)(const char*, int*);
]]

local function find_interface(module_name, interface_name)
    return ffi.cast("CreateInterfaceFn", C.GetProcAddress(C.GetModuleHandleA(module_name), "CreateInterface"))(interface_name, nil)
end

local EngineClient = find_interface("engine.dll", "VEngineClient014")
local native = {
    GetScreenSize = vtable_bind(EngineClient, 5, "void(__thiscall*)(void*, int*, int*)"),
    GetPlayerInfo = vtable_bind(EngineClient, 8, "bool(__thiscall*)(void*, int, void*)"),
    GetPlayerForUserid = vtable_bind(EngineClient, 9, "int(__thiscall*)(void*, int)"),
    ConIsVisible = vtable_bind(EngineClient, 11, "bool(__thiscall*)(void*)"),
    GetLocalPlayer = vtable_bind(EngineClient, 12, "int(__thiscall*)(void*)"),
    GetLastTimeStamp = vtable_bind(EngineClient, 14, "float(__thiscall*)(void*)"),
    GetViewAngles = vtable_bind(EngineClient, 18, "void(__thiscall*)(void*, void*)"),
    SetViewAngles = vtable_bind(EngineClient, 19, "void(__thiscall*)(void*, void*)"),
    GetMaxClients = vtable_bind(EngineClient, 20, "int(__thiscall*)(void*)"),
    IsInGame = vtable_bind(EngineClient, 26, "bool(__thiscall*)(void*)"),
    IsConnected = vtable_bind(EngineClient, 27, "bool(__thiscall*)(void*)"),
    GetGameDirectory = vtable_bind(EngineClient, 36, "const char*(__thiscall*)(void*)"),
    GetLevelName = vtable_bind(EngineClient, 52, "const char*(__thiscall*)(void*)"),
    GetLevelNameShort = vtable_bind(EngineClient, 53, "const char*(__thiscall*)(void*)"),
    GetMapGroupName = vtable_bind(EngineClient, 54, "const char*(__thiscall*)(void*)"),
    NetChannelInfo = vtable_bind(EngineClient, 78, "void*(__thiscall*)(void*)"),
    GetUILanguage = vtable_bind(EngineClient, 97, "void(__thiscall*)(void*, char*, int)"),
    GetProductVersionString = vtable_bind(EngineClient, 105, "const char*(__thiscall*)(void*)"),
    ExecuteClientCmd = vtable_bind(EngineClient, 108, "void(__thiscall*)(void*, const char*)")
}

ffi.cdef [[
    typedef struct
    {
        int64_t __pad0;
        union {
            int64_t xuid;
            struct {
                int xuidlow;
                int xuidhigh;
            };
        };
        char name[128];
        int userid;
        char guid[33];
        unsigned int friendsid;
        char friendsname[128];
        bool fakeplayer;
        bool ishltv;
        unsigned int customfiles[4];
        unsigned char filesdownloaded;
    } player_info_t;

    typedef struct { float x, y, z; } Vector3;
]]

local ctype = {
    ["int[?]"] = ffi.typeof("int[?]"),
    ["float[?]"] = ffi.typeof("float[?]"),
    ["char[?]"] = ffi.typeof("char[?]"),
    ["void*"] = ffi.typeof("void*"),
    ["player_info_t"] = ffi.typeof("player_info_t"),
    ["vector3"] = ffi.typeof("Vector3")
}

---@meta

local screen_size_wprt = ctype["int[?]"](1)
local screen_size_hprt = ctype["int[?]"](1)
local function screen_size()
    native.GetScreenSize(screen_size_wprt, screen_size_hprt)
    return screen_size_wprt[0], screen_size_hprt[0]
end

local player_info_t = ctype.player_info_t()
local function player_info(index)
    if not index or type(index) ~= "number" then
        return
    end

    native.GetPlayerInfo(index, player_info_t)

    local steam_id = player_info_t.xuidlow
    local name = ffi.string(player_info_t.name)
    local userid = player_info_t.userid
    local friendsid = player_info_t.friendsid
    local files_downloaded = player_info_t.filesdownloaded

    return {
        raw = player_info_t,
        steam_id = steam_id ~= 0 and steam_id or nil,
        name = name ~= "" and name or nil,
        userid = userid ~= 0 and userid or nil,
        friendsid = friendsid ~= 0 and friendsid or nil,
        is_bot = player_info_t.fakeplayer,
        is_hltv = player_info_t.ishltv,
        files_downloaded = files_downloaded ~= 0 and files_downloaded or nil
    }
end

local function userid_to_entindex(userid)
    local entindex = native.GetPlayerForUserid(userid)
    return entindex ~= 0 and entindex or nil
end

local function console_visible()
    return native.ConIsVisible()
end

local function local_player()
    return native.GetLocalPlayer()
end

local function last_time_stamp()
    return native.GetLastTimeStamp()
end

local camera_angles_t = ctype.vector3()
local function camera_angles(pitch, yaw, roll)
    native.GetViewAngles(camera_angles_t)

    if pitch or yaw or roll then
        camera_angles_t.x = pitch or camera_angles_t.x
        camera_angles_t.y = yaw or camera_angles_t.y
        camera_angles_t.z = roll or camera_angles_t.z

        native.SetViewAngles(camera_angles_t)
    end

    return camera_angles_t.x, camera_angles_t.y, camera_angles_t.z
end

local function maxplayers()
    return native.GetMaxClients()
end

local function is_ingame()
    return native.IsInGame()
end

local function is_connected()
    return native.IsConnected()
end

local function game_path()
    return ffi.string(native.GetGameDirectory())
end

local function level_name()
    return ffi.string(native.GetLevelName())
end

local function level_name_short()
    return ffi.string(native.GetLevelNameShort())
end

local function map_group_name()
    return ffi.string(native.GetMapGroupName())
end

local function net_channel()
    local GetName = vtable_thunk(0, "const char*(__thiscall*)(void*)")
    local GetAddress = vtable_thunk(1, "const char*(__thiscall*)(void*)")
    local GetTime = vtable_thunk(2, "float(__thiscall*)(void*)")
    local GetTimeConnected = vtable_thunk(3, "float(__thiscall*)(void*)")
    local GetBufferSize = vtable_thunk(4, "int(__thiscall*)(void*)")
    local GetDataRate = vtable_thunk(5, "int(__thiscall*)(void*)")
    local IsLoopback = vtable_thunk(6, "bool(__thiscall*)(void*)")
    local IsTimingOut = vtable_thunk(7, "bool(__thiscall*)(void*)")
    local IsPlayback = vtable_thunk(8, "bool(__thiscall*)(void*)")
    local GetLatency = vtable_thunk(9, "float(__thiscall*)(void*, int)")
    local GetAvgLatency = vtable_thunk(10, "float(__thiscall*)(void*, int)")
    local GetAvgLoss = vtable_thunk(11, "float(__thiscall*)(void*, int)")
    local GetAvgChoke = vtable_thunk(12, "float(__thiscall*)(void*, int)")
    local GetAvgDate = vtable_thunk(13, "float(__thiscall*)(void*, int)")
    local GetAvgPackets = vtable_thunk(14, "float(__thiscall*)(void*, int)")
    local GetTotalData = vtable_thunk(15, "int(__thiscall*)(void*, int)")
    local GetSequenceNumber = vtable_thunk(16, "int(__thiscall*)(void*, int)")
    local IsValidPacket = vtable_thunk(17, "bool(__thiscall*)(void*, int, int)")
    local GetPacketTime = vtable_thunk(18, "float(__thiscall*)(void*, int, int)")
    local GetPacketBytes = vtable_thunk(19, "int(__thiscall*)(void*, int, int, int)")
    local GetStreamProgress = vtable_thunk(20, "bool(__thiscall*)(void*, int, int*, int*)")
    local GetTimeSinceLastReceived = vtable_thunk(22, "float(__thiscall*)(void*)")
    local GetCommandInterpolationAmount = vtable_thunk(23, "float(__thiscall*)(void*, int, int)")
    local GetPacketResponseLatency = vtable_thunk(24, "void(__thiscall*)(void*, int, int, int*, int*)")
    local GetRemoteFramerate = vtable_thunk(25, "void(__thiscall*)(void*, float*, float*, float*)")
    local GetTimeoutSeconds = vtable_thunk(26, "float(__thiscall*)(void*)")

    local net_chan_mt = {}
    net_chan_mt.__index = net_chan_mt

    function net_chan_mt:__tostring()
        if not self.net_chan then
            return
        end

        return "cdata<INetChannelInfo" .. tostring(self.net_chan):sub(11, 25)
    end

    function net_chan_mt:name()
        if not self.net_chan then
            return
        end

        return ffi.string(GetName(self.net_chan))
    end

    function net_chan_mt:address()
        if not self.net_chan then
            return
        end

        return ffi.string(GetAddress(self.net_chan))
    end

    function net_chan_mt:time()
        if not self.net_chan then
            return
        end

        return GetTime(self.net_chan)
    end

    function net_chan_mt:time_connected()
        if not self.net_chan then
            return
        end

        return GetTimeConnected(self.net_chan)
    end

    function net_chan_mt:buffer_size()
        if not self.net_chan then
            return
        end

        return GetBufferSize(self.net_chan)
    end

    function net_chan_mt:data_rate()
        if not self.net_chan then
            return
        end

        return GetDataRate(self.net_chan)
    end

    function net_chan_mt:is_loopback()
        if not self.net_chan then
            return
        end

        return IsLoopback(self.net_chan)
    end

    function net_chan_mt:is_timing_out()
        if not self.net_chan then
            return
        end

        return IsTimingOut(self.net_chan)
    end

    function net_chan_mt:is_playback()
        if not self.net_chan then
            return
        end

        return IsPlayback(self.net_chan)
    end

    function net_chan_mt:latency(flow)
        if not self.net_chan or type(flow) ~= "number" then
            return
        end

        return GetLatency(self.net_chan, flow)
    end

    function net_chan_mt:avg_latency(flow)
        if not self.net_chan or type(flow) ~= "number" then
            return
        end

        return GetAvgLatency(self.net_chan, flow)
    end

    function net_chan_mt:avg_loss(flow)
        if not self.net_chan or type(flow) ~= "number" then
            return
        end

        return GetAvgLoss(self.net_chan, flow)
    end

    function net_chan_mt:avg_choke(flow)
        if not self.net_chan or type(flow) ~= "number" then
            return
        end

        return GetAvgChoke(self.net_chan, flow)
    end

    function net_chan_mt:avg_date(flow)
        if not self.net_chan or type(flow) ~= "number" then
            return
        end

        return GetAvgDate(self.net_chan, flow)
    end

    function net_chan_mt:avg_packets(flow)
        if not self.net_chan or type(flow) ~= "number" then
            return
        end

        return GetAvgPackets(self.net_chan, flow)
    end

    function net_chan_mt:total_data(flow)
        if not self.net_chan or type(flow) ~= "number" then
            return
        end

        return GetTotalData(self.net_chan, flow)
    end

    function net_chan_mt:sequence(flow)
        if not self.net_chan or type(flow) ~= "number" then
            return
        end

        return GetSequenceNumber(self.net_chan, flow)
    end

    function net_chan_mt:is_valid_packet(flow, frame)
        if not self.net_chan or type(flow) ~= "number" or type(frame) ~= "number" then
            return
        end

        return IsValidPacket(self.net_chan, flow, frame)
    end

    function net_chan_mt:packet_time(flow, frame)
        if not self.net_chan or type(flow) ~= "number" or type(frame) ~= "number" then
            return
        end

        return GetPacketTime(self.net_chan, flow, frame)
    end

    function net_chan_mt:packet_bytes(flow, frame, group)
        if not self.net_chan or type(flow) ~= "number" or type(frame) ~= "number" or type(group) ~= "number" then
            return
        end

        return GetPacketBytes(self.net_chan, flow, frame, group)
    end

    local received, total = ctype["int[?]"](1), ctype["int[?]"](1)
    function net_chan_mt:stream_progress(flow)
        if not self.net_chan or type(flow) ~= "number" then
            return
        end

        GetStreamProgress(self.net_chan, flow, received, total)
        return received[0], total[0]
    end

    function net_chan_mt:time_since_last_received()
        if not self.net_chan then
            return
        end

        return GetTimeSinceLastReceived(self.net_chan)
    end

    function net_chan_mt:command_interpolation_amount(flow, frame)
        if not self.net_chan or type(flow) ~= "number" then
            return
        end

        return GetCommandInterpolationAmount(self.net_chan, flow, frame)
    end

    local pn_latency_msecs = ctype["int[?]"](1)
    local pn_choke = ctype["int[?]"](1)

    function net_chan_mt:packet_response_latency(flow, frame)
        if not self.net_chan or type(flow) ~= "number" or type(frame) ~= "number" then
            return
        end

        GetPacketResponseLatency(self.net_chan, flow, frame, pn_latency_msecs, pn_choke)
        return pn_latency_msecs[0], pn_choke[0]
    end

    local pfl_frame_time = ctype["float[?]"](1)
    local pfl_frame_time_std_deviation = ctype["float[?]"](1)
    local pfl_frame_start_time_std_deviation = ctype["float[?]"](1)
    function net_chan_mt:remote_framerate()
        if not self.net_chan then
            return
        end

        GetRemoteFramerate(self.net_chan, pfl_frame_time, pfl_frame_time_std_deviation, pfl_frame_start_time_std_deviation)
        return pfl_frame_time[0], pfl_frame_time_std_deviation[0], pfl_frame_start_time_std_deviation[0]
    end

    function net_chan_mt:timeout_seconds()
        if not self.net_chan then
            return
        end

        return GetTimeoutSeconds(self.net_chan)
    end

    return function()
        local net_chan = native.NetChannelInfo()

        return setmetatable(
            {
                net_chan = net_chan ~= nil and net_chan or nil
            },
            net_chan_mt
        )
    end
end

local ui_language_prt = ctype["char[?]"](20)
local function ui_language()
    native.GetUILanguage(ui_language_prt, 20)
    return ffi.string(ui_language_prt)
end

local function product_version()
    return ffi.string(native.GetProductVersionString())
end

local function exec(cmd, ...)
    if type(cmd) ~= "string" then
        return
    end

    local cmds = ""
    for k, v in pairs({cmd, ...}) do
        if type(v) ~= "string" then
            break
        end
        cmds = cmds .. v .. ";"
    end

    native.ExecuteClientCmd(cmds)
end

return {
    interface = EngineClient,
    screen_size = screen_size,
    player_info = player_info,
    userid_to_entindex = userid_to_entindex,
    console_visible = console_visible,
    local_player = local_player,
    last_time_stamp = last_time_stamp,
    camera_angles = camera_angles,
    maxplayers = maxplayers,
    is_ingame = is_ingame,
    is_connected = is_connected,
    game_path = game_path,
    level_name = level_name,
    level_name_short = level_name_short,
    map_group_name = map_group_name,
    net_channel = net_channel(),
    ui_language = ui_language,
    product_version = product_version,
    exec = exec
}

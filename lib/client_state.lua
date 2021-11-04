local ffi = require "ffi"
local C = ffi.C

ffi.cdef [[
    typedef struct
    {
        char pad[19756];
        uint32_t last_outgoing_command;
        uint32_t choked_commands;
        uint32_t last_command_ack;
        uint32_t last_server_tick;
        uint32_t command_ack;
    } client_state_t;

    void* GetModuleHandleA(const char*);
    void* GetProcAddress(void*, const char*);
]]

local client_state =
    ffi.cast(
    ffi.typeof("client_state_t*"),
    ffi.cast(
        ffi.typeof("uintptr_t***"),
        ffi.cast(
            ffi.typeof("uintptr_t**"),
            ffi.cast(ffi.typeof("void*(*)(const char*, int)"), C.GetProcAddress(C.GetModuleHandleA("engine"), "CreateInterface"))(
                "VEngineClient014",
                0
            )
        )[0][12] + 16
    )[0][0]
)

return {
    lastoutgoingcommand = function()
        return client_state.last_outgoing_command
    end,
    chokedcommands = function()
        return client_state.choked_commands
    end,
    lastcommandack = function()
        return client_state.last_command_ack
    end,
    lastservertick = function()
        return client_state.last_server_tick
    end,
    commandack = function()
        return client_state.command_ack
    end
}

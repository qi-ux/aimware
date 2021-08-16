local ffi = require("ffi")

ffi.cdef [[
    typedef void*** (__thiscall* FindHudElement_t)(void*, const char*);
    typedef void(__thiscall* ShowAlert_t)(void*, const char*, int);
    typedef void(__thiscall* HidePanel_t)(void*, bool);
    struct CHudElement { char pad0x20[0x20];const char* m_pName; };
]]

local panel =
    ffi.cast("FindHudElement_t", mem.FindPattern("client.dll", "55 8B EC 53 8B 5D 08 56 57 8B F9 33 F6 39 77 28"))(
    ffi.cast("void**", ffi.cast("char*", mem.FindPattern("client.dll", "B9 ?? ?? ?? ?? 88 46 09")) + 1)[0],
    "CCSGO_HudUniqueAlerts"
)

local function get_panel(hud)
    return ffi.cast("void***", ffi.cast("char*", hud) - 0x14)
end

local function show_panel(panel, text, mode)
    ffi.cast(
        "ShowAlert_t",
        mem.FindPattern(
            "client.dll",
            "55 8B EC A1 ?? ?? ?? ?? 83 EC 08 56 8B F1 57 A8 01 75 26 8B 0D ?? ?? ?? ?? 83 C8 01 A3 ?? ?? ?? ?? 68 ?? ?? ?? ?? 8B 01 FF 90 ?? ?? ?? ?? 66 A3 ?? ?? ?? ?? A1"
        )
    )(get_panel(panel), text, mode)
end

local function hide_panel(panel)
    local address = mem.FindPattern("client.dll", "E8 ?? ?? ?? ?? 5F 5E 5B 8B E5 5D C2 04 00 8B D3 B9 ?? ?? ?? ?? E8 ?? ?? ?? ?? 85 C0 0F 85 ?? ?? ?? ?? 8B 44 24 14")
    ffi.cast("HidePanel_t", ffi.cast("uintptr_t", ffi.cast("uintptr_t*", ffi.cast("char*", address) + 1)[0] + ffi.cast("uintptr_t", ffi.cast("char*", address) + 5)))(
        get_panel(panel),
        false
    )
end

local alerts = {}
alerts.__index = alerts

return {
    new = function(text)
        alerts.panel = panel
        alerts.text = text
        alerts.show = function(self)
            show_panel(self.panel, self.text, 1)
        end
        alerts.hide = function(self)
            print(self.panel)
            hide_panel(self.panel)
        end
        return setmetatable({}, alerts)
    end
}

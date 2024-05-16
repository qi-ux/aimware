local ffi = ffi or require "ffi"
local C = ffi.C

local system_time = (function()
    ffi.cdef [[
        typedef struct {
            uint16_t wYear;
            uint16_t wMonth;
            uint16_t wDayOfWeek;
            uint16_t wDay;
            uint16_t wHour;
            uint16_t wMinute;
            uint16_t wSecond;
            uint16_t wMilliseconds;
        } SYSTEMTIME, *PSYSTEMTIME, *LPSYSTEMTIME;

        void GetLocalTime(LPSYSTEMTIME lpSystemTime);
    ]]
    ---@diagnostic disable: undefined-field
    local SYSTEMTIME = ffi.typeof "SYSTEMTIME"
    return function()
        local st = SYSTEMTIME()
        C.GetLocalTime(st)
        return {
            sec = st.wSecond,
            min = st.wMinute,
            hour = st.wHour,
            day = st.wDay,
            month = st.wMonth,
            year = st.wYear,
            wday = st.wDayOfWeek + 1,
            msec = st.wMilliseconds
        }
    end
    ---@diagnostic enable: undefined-field
end)()

local font = draw.CreateFont("verdana", 12)

local function math_round(v)
    return math.modf(v + (v < 0.0 and -.5 or .5))
end

local function renderer_rectangle(x, y, w, h)
    draw.FilledRect(math.floor(x), math.floor(y), math.floor(x + w), math.floor(y + h))
end

callbacks.Register("Draw", function()
    draw.SetFont(font)

    local st = system_time()
    local text = ('%s | %s | %s'):format("aimware.net", cheat.GetUserName(), ("%02d:%02d:%02d"):format(st.hour, st.min, st.sec))

    local h, w = 18, draw.GetTextSize(text) + 8
    local x, y = draw.GetScreenSize(), 10

    x = x - w - 10

    draw.Color(142, 165, 229, 255)
    renderer_rectangle(x, y, w, 2)

    draw.Color(17, 17, 17, 85)
    renderer_rectangle(x, y + 2, w, h)

    draw.Color(255, 255, 255, 255)
    draw.TextShadow(math_round(x + 4), math_round(y + 7), text)
end)

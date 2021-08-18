local ffi = ffi
local C = ffi.C

if not pcall(ffi.sizeof, "FILE") then
    ffi.cdef [[typedef struct FILE FILE;]]
end

ffi.cdef [[
    bool CreateDirectoryA(const char*, const char*);
    FILE* fopen(const char*, const char*);
    int fclose(FILE*);
    int ftell(FILE*);
    int fseek(FILE*, int, int);
    size_t fwrite(const void*, size_t, size_t, FILE*);
    size_t fread(void*, size_t, size_t, FILE*);
]]

local function cdir(name)
    local dirs = {}
    local dir = "."
    name:gsub(
        "[^\\/]+",
        function(c)
            dirs[#dirs + 1] = c
            local dirt = dirs[#dirs - 1]
            if dirt then
                dir = dir .. "\\" .. dirt
            end
            local _cd = dir ~= "." and C.CreateDirectoryA(dir, nil)
        end
    )
end

function readfile(name)
    local fp = ffi.gc(C.fopen(name, "rb"), C.fclose)
    if fp == nil then
        return nil, name .. ": No such file or directory", 2
    end
    C.fseek(fp, 0, 2)
    local sz = C.ftell(fp)
    C.fseek(fp, 0, 0)
    local buf = ffi.new("uint8_t[?]", sz + 1)
    C.fread(buf, 1, sz, fp)
    C.fclose(fp)
    ffi.gc(fp, nil)
    return ffi.string(buf, sz)
end

function writefile(name, ...)
    cdir(name)
    local fp = ffi.gc(C.fopen(name, "wb"), C.fclose)
    if fp == nil then
        return nil
    end
    local str = ""
    for k, v in pairs({...}) do
        str = str .. v
    end
    C.fwrite(str, 1, #str, fp)
    C.fclose(fp)
    ffi.gc(fp, nil)
end

package = {
    path = ("%s.lua;%s.lua;%s.lua;%s.lua;%s.lua;"):format(".\\?", "aimware\\?", "aimware\\?\\init", "aimware\\libraries\\?", "aimware\\libraries\\?\\init"),
    loaded = {
        _G = _G,
        bit = bit,
        coroutine = coroutine,
        debug = debug,
        math = math,
        os = os,
        string = string,
        table = table
    },
    preload = {
        ffi = function()
            return ffi
        end
    }
}

function require(name)
    if not (package.loaded[name] or package.preload[name]) then
        local pts = {}
        package.path:gsub(
            "[^;]+",
            function(c)
                pts[#pts + 1] = c
            end
        )
        local nofp = ""
        for k, v in pairs(pts) do
            local pt = v:gsub("?", name)
            local fp = readfile(pt)
            nofp = nofp .. ("\nno file '%s'"):format(pt)
            if fp then
                local _, a, b = pcall(load, fp)
                local loaded = a and (a() or true) or error(b, 2)
                package.loaded[name] = loaded
                break
            elseif k == #pts then
                return package.loaded[name], nofp
            end
        end
    end

    return package.loaded[name] or package.preload[name]()
end

gui.Command("lua.run gui.Reference('Menu'):SetActive(true)")

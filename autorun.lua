--load(http.Get("https://raw.githubusercontent.com/qi-ux/aimware/main/autorun.lua"))

local ffi = ffi
local C = ffi.C

if not pcall(ffi.sizeof, "FILE") then
    ffi.cdef [[typedef struct FILE FILE;]]
end

ffi.cdef [[
    int ftell(FILE*);
    int fclose(FILE*);
    int fseek(FILE*, int, int);
    char* _getcwd(char* buf, size_t size);
    FILE* fopen(const char*, const char*);
    size_t fread(void*, size_t, size_t, FILE*);
    bool CreateDirectoryA(const char*, const char*);
    size_t fwrite(const void*, size_t, size_t, FILE*);
]]

local buf = ffi.new("uint8_t[257]")
C._getcwd(buf, 256)
local path = ffi.string(buf)
C.CreateDirectoryA(("%s\\aimware"):format(path), nil)

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

local function readfile(name)
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

local function writefile(name, ...)
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

local package = {
    path = "",
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

local function setp_path()
    local function apath(path)
        package.path = package.path .. ("%s.lua;"):format(path)
    end

    local path_t = {"lua", "lib", "libraries"}

    apath(("%s"):format((".\\aimware\\?")))
    for k, v in pairs(path_t) do
        apath((".\\aimware\\%s\\?"):format(v))
    end

    apath(("%s\\aimware\\?\\init"):format(path))
    for k, v in pairs(path_t) do
        apath(("%s\\aimware\\%s\\?\\init"):format(path, v))
    end
end

local function require(name)
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

local function init()
    gui.Command("lua.run gui.Reference('Menu'):SetActive(true)")
    setp_path()

    _G.path = path
    _G.readfile = readfile
    _G.writefile = writefile
    _G.package = package
    _G.require = require
end

init()

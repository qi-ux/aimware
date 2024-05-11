---
local table_concat      = table.concat
local debug_getregistry = debug.getregistry
local pcall             = pcall
local error             = error
local load              = load
local select            = select
local type              = type
local unpack            = unpack
local debug_getinfo     = debug.getinfo
local ipairs            = ipairs
local pairs             = pairs

---
local file_read         = file.Read

---
local LUA_LDIR          = "!\\lua\\"
local LUA_PATH_DEFAULT  = table_concat({".\\?.lua;", LUA_LDIR, "?.lua;", LUA_LDIR, "?\\init.lua;"})
local LUA_DIRSEP        = "\\"
local LUA_PATHSEP       = ";"
local LUA_PATH_MARK     = "?"
local LUA_EXECDIR       = "!"
local LUA_IGMARK        = "-"
local LUA_PATH_CONFIG   = table_concat({LUA_DIRSEP, LUA_PATHSEP, LUA_PATH_MARK, LUA_EXECDIR, LUA_IGMARK, ""}, "\n")

local LUA_LOADLIBNAME   = "package"
local LUA_REGISTRYINDEX = debug_getregistry()

---
local function setprogdir(path)
    return path:gsub(LUA_EXECDIR, ".")
end

local function readable(filename)
    return pcall(file_read, filename:gsub("^%.\\", ""))
end

local function getfuncname()
    return debug_getinfo(2, "n").name or "?"
end

local function loadfile(filename, mode, env)
    local success, result = readable(filename)
    if not success then return error(("cannot open %s: %s"):format(filename, result:lower())) end
    return load(result, ("=%s"):format(filename), mode, env)
end

local function package_searchpath(...)
    local args = {...}
    local name, path, sep, rep = unpack(args)
    if select("#", ...) < 3 then sep, rep = ".", LUA_DIRSEP end
    if select("#", ...) < 4 then rep = LUA_DIRSEP end
    local funcname = getfuncname()
    if type(name) ~= "string" then return error(("bad argument #1 to '%s' (string expected, got %s)"):format(funcname, select("#", ...) < 1 and "no value" or type(name))) end
    if type(path) ~= "string" then return error(("bad argument #2 to '%s' (string expected, got %s)"):format(funcname, select("#", ...) < 2 and "no value" or type(path))) end
    if type(sep) ~= "string" then return error(("bad argument #3 to '%s' (string expected, got %s)"):format(funcname, select("#", ...) < 3 and "no value" or type(sep))) end
    if type(rep) ~= "string" then return error(("bad argument #4 to '%s' (string expected, got %s)"):format(funcname, select("#", ...) < 4 and "no value" or type(rep))) end

    local msg = {}
    if sep then name = name:gsub(("%%%s"):format(sep), ("%%%s"):format(rep)) end

    for current in path:gmatch(("[^%s]+"):format(LUA_PATHSEP)) do
        local filename = current:gsub(("%%%s"):format(LUA_PATH_MARK), name)
        if readable(filename) then return filename end
        msg[#msg + 1] = ("\n\tno file '%s'"):format(filename)
    end

    return nil, table_concat(msg)
end

local function package_loader_preload(...)
    local name = unpack({...})
    if type(name) ~= "string" then return error(("bad argument #1 to '%s' (string expected, got %s)"):format(getfuncname(), select("#", ...) < 1 and "no value" or type(name))) end

    local preload = _G[LUA_LOADLIBNAME]["preload"]
    if type(preload) ~= "table" then return error("'package.preload' must be a table") end

    if preload[name] ~= nil then return preload[name] end
    return ("\n\tno field package.preload['%s']"):format(name)
end

local function package_loader_lua(...)
    local args = {...}
    local name = unpack(args)
    if type(name) ~= "string" then return error(("bad argument #1 to '%s' (string expected, got %s)"):format(getfuncname(), select("#", ...) < 1 and "no value" or type(name))) end

    local path = _G[LUA_LOADLIBNAME]["path"]
    if type(path) ~= "string" then return error("'package.path' must be a string") end

    local filename, msg
    filename, msg = package_searchpath(name, path)
    if not filename then return msg end

    local chunk, err = loadfile(filename)
    if chunk then return chunk end
    return error(("error loading module '%s' from file '%s':\n\t%s"):format(name, filename, err))
end

local KEY_SENTINEL = bit.bor(bit.lshift(0x80000000, 32), 115)
local function package_require(...)
    local name = unpack({...})

    if type(name) ~= "string" then return error(("bad argument #1 to '%s' (string expected, got %s)"):format(getfuncname(), select("#", ...) < 1 and "no value" or type(name))) end

    local package = _G[LUA_LOADLIBNAME]
    local loaders = package["loaders"]
    if type(loaders) ~= "table" then return error("'package.loaders' must be a table") end

    local loaded = package["loaded"]

    if loaded[name] then
        if loaded[name] == KEY_SENTINEL then return error(("loop or previous error loading module '%s'"):format(name)) end
        return loaded[name]
    end

    local msg = {}
    for _, loader in ipairs(loaders) do
        local success, result = pcall(loader, name)
        if not success then return error(result) end

        if type(result) == "function" then
            loaded[name] = KEY_SENTINEL
            local ok, res = pcall(result, name)
            if not ok then return error(res) end
            loaded[name] = type(res) == "nil" and true or res
            return loaded[name]
        elseif type(result) == "string" then
            msg[#msg + 1] = result
        end
    end

    return error(("module '%s' not found:%s"):format(name, table_concat(msg)))
end

local function luaopen_package()
    _G[LUA_LOADLIBNAME] = {
        ["searchpath"] = package_searchpath,
        ["loaders"] = {
            package_loader_preload,
            package_loader_lua
        },
        ["path"] = setprogdir(LUA_PATH_DEFAULT),
        ["config"] = LUA_PATH_CONFIG,
        ["loaded"] = LUA_REGISTRYINDEX["_LOADED"],
        ["preload"] = LUA_REGISTRYINDEX["_PRELOAD"]
    }

    for name, func in pairs({
        ["require"] = package_require
    }) do
        _G[name] = func
    end
end

if not package then luaopen_package() end

return package

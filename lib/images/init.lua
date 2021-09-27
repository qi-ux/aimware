local M = {}

local ffi = require "ffi"
local vtable = require "vtable"
local csgo_weapons = require "csgo_weapons"

local string_gsub = string.gsub
local math_floor = math.floor
local cast = ffi.cast

local charbuffer = ffi.typeof("char[?]")
local uintbuffer = ffi.typeof("unsigned int[?]")

local INVALID_TEXTURE = -1

local PNG_MAGIC = "\x89\x50\x4E\x47\x0D\x0A\x1A\x0A"
local JPG_MAGIC_1 = "\xFF\xD8\xFF\xDB"
local JPG_MAGIC_2 = "\xFF\xD8\xFF\xE0\x00\x10\x4A\x46\x49\x46\x00\x01"

local native_ReadFile = vtable.bind("filesystem_stdio.dll", "VBaseFileSystem011", 0, "int(__thiscall*)(void*, void*, int, void*)")
local native_OpenFile =
    vtable.bind("filesystem_stdio.dll", "VBaseFileSystem011", 2, "void*(__thiscall*)(void*, const char*, const char*, const char*)")
local native_CloseFile = vtable.bind("filesystem_stdio.dll", "VBaseFileSystem011", 3, "void(__thiscall*)(void*, void*)")
local native_GetFileSize = vtable.bind("filesystem_stdio.dll", "VBaseFileSystem011", 7, "unsigned int(__thiscall*)(void*, void*)")

local function engine_read_file(filename)
    local handle = native_OpenFile(filename, "r", "MOD")
    if handle == nil then
        return
    end

    local size = native_GetFileSize(handle)
    if size == nil or size < 0 then
        return
    end

    local buffer = charbuffer(size + 1)
    if buffer == nil then
        return
    end

    if not native_ReadFile(buffer, size, handle) then
        return
    end

    return ffi.string(buffer, size)
end

ffi.cdef(
    [[
	typedef struct
	{
		void* steam_client;
		void* steam_user;
		void* steam_friends;
		void* steam_utils;
		void* steam_matchmaking;
		void* steam_user_stats;
		void* steam_apps;
		void* steam_matchmakingservers;
		void* steam_networking;
		void* steam_remotestorage;
		void* steam_screenshots;
		void* steam_http;
		void* steam_unidentifiedmessages;
		void* steam_controller;
		void* steam_ugc;
		void* steam_applist;
		void* steam_music;
		void* steam_musicremote;
		void* steam_htmlsurface;
		void* steam_inventory;
		void* steam_video;
	} S_steamApiCtx_t;
]]
)

local pS_SteamApiCtx =
    ffi.cast("S_steamApiCtx_t**", ffi.cast("char*", mem.FindPattern("client.dll", "FF 15 ?? ?? ?? ?? B9 ?? ?? ?? ?? E8 ?? ?? ?? ?? 6A")) + 7)[0] or
    error("invalid interface", 2)

local native_ISteamFriends = ffi.cast("void***", pS_SteamApiCtx.steam_friends)
local native_ISteamUtils = ffi.cast("void***", pS_SteamApiCtx.steam_utils)

local native_ISteamFriends_GetSmallFriendAvatar = vtable.thunk(34, "int(__thiscall*)(void*, uint64_t)")
local native_ISteamFriends_GetMediumFriendAvatar = vtable.thunk(35, "int(__thiscall*)(void*, uint64_t)")
local native_ISteamFriends_GetLargeFriendAvatar = vtable.thunk(36, "int(__thiscall*)(void*, uint64_t)")

local native_ISteamUtils_GetImageSize = vtable.thunk(5, "bool(__thiscall*)(void*, int, uint32_t*, uint32_t*)")
local native_ISteamUtils_GetImageRGBA = vtable.thunk(6, "bool(__thiscall*)(void*, int, unsigned char*, int)")

local function image_measure(self, width, height)
    if width ~= nil and height ~= nil then
        return math_floor(width), math_floor(height)
    else
        if self.width == nil or self.height == nil then
            error("Image dimensions not known, full size is required")
        elseif width == nil then
            height = height or self.height
            local width = self.width * (height / self.height)
            return math_floor(width), math_floor(height)
        elseif height == nil then
            width = width or self.width
            local height = self.height * (width / self.width)
            return math_floor(width), math_floor(height)
        else
            return math_floor(self.width), math_floor(self.height)
        end
    end
end

local function image_draw(self, x, y, width, height, r, g, b, a, force_same_res_render)
    width, height = image_measure(self, width, height)

    local id = string.format("%f_%f", width, height)
    local texture = self.textures[id]

    if texture == nil then
        if ({next(self.textures)})[2] == nil or force_same_res_render or force_same_res_render == nil then
            if self.type == "rgba" then
                width, height = self.width, self.height
            end

            local texture = draw.CreateTexture(self.rgba, width, height)
            if texture == nil then
                self.textures[id] = INVALID_TEXTURE
                error("failed to load texture for " .. width .. "x" .. height, 2)
            else
                self.textures[id] = texture
            end
        else
            texture = ({next(self.textures)})[2]
        end
    end

    if texture == nil or texture == INVALID_TEXTURE then
        return
    elseif a == nil or a > 0 then
        draw.SetTexture(texture)
        draw.Color(r or 255, g or 255, b or 255, a or 255)
        draw.FilledRect(x, y, x + width, y + height)
        draw.SetTexture(nil)
    end

    return width, height
end

local image_mt = {
    __index = {
        measure = image_measure,
        draw = image_draw
    }
}

local function load_png(contents)
    if contents:sub(1, 8) == PNG_MAGIC then
        local rgba, width, height = common.DecodePNG(contents)
        if rgba and width and height then
            return setmetatable(
                {
                    type = "png",
                    rgba = rgba,
                    width = width,
                    height = height,
                    contents = contents,
                    textures = {}
                },
                image_mt
            )
        else
            error("Invalid rgba or width or height", 2)
        end
    else
        error("Invalid magic", 2)
    end
end

local function load_jpg(contents)
    if contents:sub(1, 4) == JPG_MAGIC_1 or contents:sub(1, 12) == JPG_MAGIC_2 then
        local rgba, width, height = common.DecodeJPEG(contents)
        if rgba and width and height then
            return setmetatable(
                {
                    type = "jpg",
                    rgba = rgba,
                    width = width,
                    height = height,
                    contents = contents,
                    textures = {}
                },
                image_mt
            )
        else
            error("Invalid rgba or width or height", 2)
        end
    else
        error("Invalid magic", 2)
    end
end

local function load_svg(contents, scale)
    if contents:match("<svg(.*)>.*</svg>") then
        local scale = scale or 1
        local rgba, width, height = common.RasterizeSVG(contents, scale)
        if rgba and width and height then
            return setmetatable(
                {
                    type = "svg",
                    rgba = rgba,
                    width = width,
                    height = height,
                    scale = scale,
                    contents = contents,
                    textures = {}
                },
                image_mt
            )
        else
            error("Invalid rgba or width or height", 2)
        end
    else
        error("Invalid svg, missing <svg> tag", 2)
    end
end

local function load_rgba(contents, width, height)
    if width == nil or height == nil or width <= 0 or height <= 0 then
        error("Invalid size: width and height are required and have to be greater than zero.")
        return
    end

    local size = width * height * 4
    if contents:len() ~= size then
        error("invalid buffer length, expected width*height*4", 2)
        return
    end

    local texture = draw.CreateTexture(contents, width, height)
    if not texture then
        return
    end

    return setmetatable(
        {
            type = "rgba",
            width = width,
            height = height,
            contents = contents,
            textures = {[string.format("%f_%f", width, height)] = texture}
        },
        image_mt
    )
end

local function load_image(contents)
    if type(contents) == "table" then
        if getmetatable(contents) == image_mt then
            return error("trying to load an existing image")
        else
            local result = {}
            for key, value in pairs(contents) do
                result[key] = load_image(value)
            end
            return result
        end
    else
        if type(contents) == "string" then
            if contents:sub(1, 8) == PNG_MAGIC then
                return load_png(contents)
            elseif contents:sub(1, 4) == JPG_MAGIC_1 or contents:sub(1, 12) == JPG_MAGIC_2 then
                return load_jpg(contents)
            elseif contents:match("^%s*%<%?xml") ~= nil then
                return load_svg(contents)
            else
                return error("Failed to determine image type")
            end
        end
    end
end

local panorama_images = setmetatable({}, {__mode = "k"})
local function get_panorama_image(path)
    if panorama_images[path] == nil then
        local path_cleaned =
            string_gsub(string_gsub(string_gsub(string_gsub(string_gsub(path, "%z", ""), "%c", ""), "\\", "/"), "%.%./", ""), "^/+", "")
        local contents = engine_read_file("materials/panorama/images/" .. path_cleaned)

        if contents then
            local image = load_image(contents)

            panorama_images[path] = image
        else
            panorama_images[path] = false
        end
    end

    if panorama_images[path] then
        return panorama_images[path]
    end
end

local weapon_icons = setmetatable({}, {__mode = "k"})
local function get_weapon_icon(weapon_name)
    if weapon_icons[weapon_name] == nil then
        local weapon_name_cleaned
        local typ = type(weapon_name)

        if typ == "table" and weapon_name.console_name ~= nil then
            weapon_name_cleaned = weapon_name.console_name
        elseif typ == "number" then
            local weapon = csgo_weapons[weapon_name]
            if weapon == nil then
                weapon_icons[weapon_name] = false
                return
            end
            weapon_name_cleaned = weapon.console_name
        elseif typ == "string" then
            weapon_name_cleaned = tostring(weapon_name)
        elseif weapon_name ~= nil then
            weapon_icons[weapon_name] = nil
            return
        else
            return
        end

        weapon_name_cleaned = string_gsub(string_gsub(weapon_name_cleaned, "^weapon_", ""), "^item_", "")

        local image = get_panorama_image("icons/equipment/" .. weapon_name_cleaned .. ".svg")
        weapon_icons[weapon_name] = image or false
    end

    if weapon_icons[weapon_name] then
        return weapon_icons[weapon_name]
    end
end

local steam_avatars = {}
local function get_steam_avatar(steamid3_or_steamid64, size)
    local cache_key = string.format("%s_%d", steamid3_or_steamid64, size or 32)

    if steam_avatars[cache_key] == nil then
        local func
        if size == nil then
            func = native_ISteamFriends_GetSmallFriendAvatar
        elseif size > 64 then
            func = native_ISteamFriends_GetLargeFriendAvatar
        elseif size > 32 then
            func = native_ISteamFriends_GetMediumFriendAvatar
        else
            func = native_ISteamFriends_GetSmallFriendAvatar
        end

        local steamid
        if type(steamid3_or_steamid64) == "string" then
            steamid = 76500000000000000ULL + tonumber(steamid3_or_steamid64:sub(4, -1))
        elseif type(steamid3_or_steamid64) == "number" then
            steamid = 76561197960265728ULL + steamid3_or_steamid64
        else
            return
        end

        local handle = func(native_ISteamFriends, steamid)

        if handle > 0 then
            local width = uintbuffer(1)
            local height = uintbuffer(1)
            if native_ISteamUtils_GetImageSize(native_ISteamUtils, handle, width, height) then
                if width[0] > 0 and height[0] > 0 then
                    local rgba_buffer_size = width[0] * height[0] * 4
                    local rgba_buffer = charbuffer(rgba_buffer_size)

                    if native_ISteamUtils_GetImageRGBA(native_ISteamUtils, handle, rgba_buffer, rgba_buffer_size) then
                        steam_avatars[cache_key] = load_rgba(ffi.string(rgba_buffer, rgba_buffer_size), width[0], height[0])
                    end
                end
            end
        elseif handle ~= -1 then
            steam_avatars[cache_key] = false
        end
    end

    if steam_avatars[cache_key] then
        return steam_avatars[cache_key]
    end
end

return {
    load = load_image,
    load_png = load_png,
    load_jpg = load_jpg,
    load_svg = load_svg,
    load_rgba = load_rgba,
    get_weapon_icon = get_weapon_icon,
    get_panorama_image = get_panorama_image,
    get_steam_avatar = get_steam_avatar
}

local ffi = require "ffi"
local vtable = require "vtable"
local csgo_weapons = require "csgo_weapons"

local string_gsub = string.gsub
local math_floor = math.floor
local cast = ffi.cast

local c_char = ffi.typeof("char[?]")
local c_unsigned_int = ffi.typeof("unsigned int[?]")

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
	local fp = native_OpenFile(filename, "r", "MOD")
	if fp == nil then
		return
	end

	local size = native_GetFileSize(fp)
	local buf = c_char(size + 1)
	native_ReadFile(buf, size, fp)
	native_CloseFile(fp)
	return ffi.string(buf, size)
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
	cast("S_steamApiCtx_t**", cast("char*", mem.FindPattern("client.dll", "FF 15 ?? ?? ?? ?? B9 ?? ?? ?? ?? E8 ?? ?? ?? ?? 6A")) + 7)[0] or
	error("invalid interface", 2)

local native_ISteamFriends = cast("void***", pS_SteamApiCtx.steam_friends)
local native_ISteamUtils = cast("void***", pS_SteamApiCtx.steam_utils)

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
			local texture = draw.CreateTexture(self.rgba, self.width, self.height)
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
					width = width,
					height = height,
					rgba = rgba,
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
					width = width,
					height = height,
					rgba = rgba,
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
					width = width,
					height = height,
					scale = scale,
					rgba = rgba,
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
			rgba = contents,
			textures = {[string.format("%f_%f", width, height)] = texture}
		},
		image_mt
	)
end

local function load_image(contents, scale)
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
				return load_svg(contents, scale)
			else
				return error("Failed to determine image type")
			end
		end
	end
end

local panorama_images = setmetatable({}, {__mode = "k"})
local function get_panorama_image(path, scale)
	local cache_key = string.format("%s_%s", path, scale or 1)
	if panorama_images[cache_key] == nil then
		local path_cleaned = string_gsub(string_gsub(string_gsub(string_gsub(string_gsub(path, "%z", ""), "%c", ""), "\\", "/"), "%.%./", ""), "^/+", "")
		local contents = engine_read_file("materials/panorama/images/" .. path_cleaned)

		if contents then
			local image = load_image(contents, scale)

			panorama_images[cache_key] = image
		else
			panorama_images[cache_key] = false
		end
	end

	if panorama_images[cache_key] then
		return panorama_images[cache_key]
	end
end

local weapon_icons = setmetatable({}, {__mode = "k"})
local function get_weapon_icon(weapon_name, scale)
	local cache_key = string.format("%s_%s", weapon_name, scale or 1)
	if weapon_icons[cache_key] == nil then
		local weapon_name_cleaned
		local typ = type(weapon_name)

		if typ == "table" and weapon_name.console_name ~= nil then
			weapon_name_cleaned = weapon_name.console_name
		elseif typ == "number" then
			local weapon = csgo_weapons[weapon_name]
			if weapon == nil then
				weapon_icons[cache_key] = false
				return
			end
			weapon_name_cleaned = weapon.console_name
		elseif typ == "string" then
			weapon_name_cleaned = tostring(weapon_name)
		elseif weapon_name ~= nil then
			weapon_icons[cache_key] = nil
			return
		else
			return
		end

		weapon_name_cleaned = string_gsub(string_gsub(weapon_name_cleaned, "^weapon_", ""), "^item_", "")

		local image = get_panorama_image("icons/equipment/" .. weapon_name_cleaned .. ".svg", scale)
		weapon_icons[cache_key] = image or false
	end

	if weapon_icons[cache_key] then
		return weapon_icons[cache_key]
	end
end

local steam_avatars = {}
local function get_steam_avatar(steamid3_or_steamid64, scale)
	local scale = scale or "m"
	local cache_key = string.format("%s_%s", steamid3_or_steamid64, scale)

	if steam_avatars[cache_key] == nil then
		local func
		if scale == "m" then
			func = native_ISteamFriends_GetMediumFriendAvatar
		elseif scale == "+" then
			func = native_ISteamFriends_GetLargeFriendAvatar
		elseif scale == "-" then
			func = native_ISteamFriends_GetSmallFriendAvatar
		else
			func = native_ISteamFriends_GetMediumFriendAvatar
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
			local width = c_unsigned_int(1)
			local height = c_unsigned_int(1)
			if native_ISteamUtils_GetImageSize(native_ISteamUtils, handle, width, height) then
				if width[0] > 0 and height[0] > 0 then
					local rgba_buffer_size = width[0] * height[0] * 4
					local rgba_buffer = c_char(rgba_buffer_size)

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

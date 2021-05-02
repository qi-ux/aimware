local version = 1.7

local function http_update(version, version_url, download_url)
    local script_name = GetScriptName()

    local function http_version(body)
        if body == "error" then
            print(script_name .. " unable to link to the server, check the network")
            return
        end

        if load(body)() == version then
            return
        end

        print(script_name .. " a new version is being updated")

        http.Get(
            download_url,
            function(body)
                file.Write(script_name, body)
            end
        )
    end

    http.Get(version_url, http_version)
end

http_update(
    version,
    "https://aimware28.coding.net/p/coding-code-guide/d/aim_lib/git/raw/master/draw/version.lua?download=false",
    "https://aimware28.coding.net/p/coding-code-guide/d/aim_lib/git/raw/master/draw/draw.lua?download=false"
)

local math_cos, math_pi, math_max, math_floor, math_abs, math_min, math_sin = math.cos, math.pi, math.max, math.floor, math.abs, math.min, math.sin

local draw_Line,
    draw_OutlinedRect,
    draw_RoundedRectFill,
    draw_ShadowRect,
    draw_GetScreenSize,
    draw_SetFont,
    draw_GetTextSize,
    draw_FilledCircle,
    draw_OutlinedCircle,
    draw_SetScissorRect,
    draw_FilledRect,
    draw_SetTexture,
    draw_UpdateTexture,
    draw_TextShadow,
    draw_CreateTexture,
    draw_Triangle,
    draw_AddFontResource,
    draw_Color,
    draw_RoundedRect,
    draw_CreateFont,
    draw_Text =
    draw.Line,
    draw.OutlinedRect,
    draw.RoundedRectFill,
    draw.ShadowRect,
    draw.GetScreenSize,
    draw.SetFont,
    draw.GetTextSize,
    draw.FilledCircle,
    draw.OutlinedCircle,
    draw.SetScissorRect,
    draw.FilledRect,
    draw.SetTexture,
    draw.UpdateTexture,
    draw.TextShadow,
    draw.CreateTexture,
    draw.Triangle,
    draw.AddFontResource,
    draw.Color,
    draw.RoundedRect,
    draw.CreateFont,
    draw.Text

local input_IsButtonDown, input_GetMousePos = input.IsButtonDown, input.GetMousePos

local globals_FrameCount = globals.FrameCount

local gui_Slider, gui_Reference = gui.Slider, gui.Reference

local http_Get = http.Get

local file_Write = file.Write

local function _color(r, g, b, a)
    local r = math_min(255, math_max(0, r))
    local g = math_min(255, math_max(0, g or r))
    local b = math_min(255, math_max(0, b or g or r))
    local a = math_min(255, math_max(0, a or 255))
    return r, g, b, a
end

local function _round(number, precision)
    local mult = 10 ^ (precision or 0)
    return math_floor(number * mult + 0.5) / mult
end

function draw.color(r, g, b, a)
    draw_Color(_color(r, g, b, a))
end

draw.line = draw_Line

function draw.rect(xa, ya, xb, yb, flags, radius)
    local a = flags:find("s") and draw_ShadowRect(xa, ya, xb, yb, radius) or flags:find("scissor") and draw_SetScissorRect(xa, ya, xb, yb)
    local b = flags:find("o") and draw_OutlinedRect(xa, ya, xb, yb) or flags:find("f") and draw_FilledRect(xa, ya, xb, yb)
end

function draw.rect_round(xa, ya, xb, yb, flags, radius, tl, tr, bl, br)
    local a =
        flags:find("o") and draw_RoundedRect(x1, y1, x2, y2, radius, tl, tr, bl, br) or
        flags:find("f") and draw_RoundedRectFill(xa, ya, xb, yb, radius, tl, tr, bl, br)
end

function draw.triangle(xa, ya, xb, yb, xc, yc, flags)
    local a =
        flags:find("o") and draw_Line(xa, ya, xb, yb),
        draw_Line(xb, yb, xc, yc),
        draw_Line(xc, yc, xa, ya) or flags:find("f") and draw_Triangle(xa, ya, xb, yb, xc, yc)
end

function draw.circle(x, y, radius, flags)
    local a = flags:find("o") and draw_OutlinedCircle(x, y, radius) or flags:find("f") and draw_FilledCircle(x, y, radius)
end

draw.get_text_size = draw_GetTextSize

draw.get_screen_size = draw_GetScreenSize

function draw.text(x, y, flags, string)
    local w = draw_GetTextSize(string)
    local x = flags:find("c") and x - _round(w * 0.5) or flags:find("l") and x - w or x
    local a = flags:find("s") and draw_TextShadow(x, y, string) or draw_Text(x, y, string)
end

function draw.new_font(name, height, weight)
    return draw_CreateFont(name or "verdana", height or 13, weight or 0)
end

draw.add_font = draw_AddFontResource

draw.set_font = draw_SetFont

draw.new_texture = draw_CreateTexture

draw.update_texture = draw_UpdateTexture

draw.set_texture = draw_SetTexture

local common_DecodePNG, common_DecodeJPEG, common_RasterizeSVG = common.DecodePNG, common.DecodeJPEG, common.RasterizeSVG

local textures = {}

function draw.load_png(data)
    textures[data] = not textures[data] and draw_CreateTexture(common_DecodePNG(data)) or textures[data]

    return textures[data]
end

function draw.load_jpg(data)
    textures[data] = not textures[data] and draw_CreateTexture(common_DecodeJPEG(data)) or textures[data]

    return textures[data]
end

function draw.load_svg(data, scale)
    local scale = scale or 1
    local data = data .. scale

    textures[data] = not textures[data] and draw_CreateTexture(common_RasterizeSVG(data, scale)) or textures[data]

    return textures[data]
end

function draw.texture(texture, xa, ya, xb, yb)
    draw_SetTexture(texture)
    draw_FilledRect(xa, ya, xb, yb)
    draw_SetTexture(nil)
end

local gradient_texture_a =
    draw_CreateTexture(
    common_RasterizeSVG(
        [[<defs><linearGradient id="a" x1="100%" y1="0%" x2="0%" y2="0%"><stop offset="0%" style="stop-color:rgb(255,255,255); stop-opacity:0" /><stop offset="100%" style="stop-color:rgb(255,255,255); stop-opacity:1" /></linearGradient></defs><rect width="500" height="500" style="fill:url(#a)" /></svg>]]
    )
)

local gradient_texture_b =
    draw_CreateTexture(
    common_RasterizeSVG(
        [[<defs><linearGradient id="c" x1="0%" y1="100%" x2="0%" y2="0%"><stop offset="0%" style="stop-color:rgb(255,255,255); stop-opacity:0" /><stop offset="100%" style="stop-color:rgb(255,255,255); stop-opacity:1" /></linearGradient></defs><rect width="500" height="500" style="fill:url(#c)" /></svg>]]
    )
)

function draw.gradient(xa, ya, xb, yb, ca, cb, ltr)
    local r, g, b, a = _color(ca[1], ca[2], ca[3], ca[4])
    local r2, g2, b2, a2 = _color(cb[1], cb[2], cb[3], cb[4])

    local texture = ltr and gradient_texture_a or gradient_texture_b

    local t = (a ~= 255 or a2 ~= 255)
    draw_Color(r, g, b, a)
    draw_SetTexture(t and texture or nil)
    draw_FilledRect(xa, ya, xb, yb)

    draw_Color(r2, g2, b2, a2)
    local set_texture = not t and draw_SetTexture(texture)
    draw_FilledRect(xb, yb, xa, ya)
    draw_SetTexture(nil)
end

function draw.circle_outline(x, y, radius, start_degrees, percentage, thickness, radian)
    local thickness = radius - thickness
    local percentage = math_abs(percentage * 360)
    local radian = radian or 1

    for i = start_degrees, start_degrees + percentage - radian, radian do
        local cos_1 = math_cos(i * math_pi / 180)
        local sin_1 = math_sin(i * math_pi / 180)
        local cos_2 = math_cos((i + radian) * math_pi / 180)
        local sin_2 = math_sin((i + radian) * math_pi / 180)

        local xa = x + cos_1 * radius
        local ya = y + sin_1 * radius
        local xb = x + cos_2 * radius
        local yb = y + sin_2 * radius
        local xc = x + cos_1 * thickness
        local yc = y + sin_1 * thickness
        local xd = x + cos_2 * thickness
        local yd = y + sin_2 * thickness

        draw_Triangle(xa, ya, xb, yb, xc, yc)
        draw_Triangle(xc, yc, xb, yb, xd, yd)
    end
end

local menu = gui_Reference("menu")

function draw.drag(parent, varname, base_x, base_y)
    return (function()
        local a = {}
        local b, c, d, e, f, g, h, i, j, k, l, m, n, o
        local p = {
            __index = {
                drag = function(self, ...)
                    local q, r = self:get()
                    local s, t = a.drag(q, r, ...)
                    if q ~= s or r ~= t then
                        self:set(s, t)
                    end
                    return s, t
                end,
                set = function(self, q, r)
                    local j, k = draw_GetScreenSize()
                    self.parent_x:SetValue(q / j * self.res)
                    self.parent_y:SetValue(r / k * self.res)
                end,
                get = function(self)
                    local j, k = draw_GetScreenSize()
                    return _round(self.parent_x:GetValue() / self.res * j), _round(self.parent_y:GetValue() / self.res * k)
                end
            }
        }
        function a.new(r, u, v, w, x)
            local x = x or 10000
            local j, k = draw_GetScreenSize()
            local y = gui_Slider(r, u .. "x", " position x", v / j * x, 0, x)
            local z = gui_Slider(r, u .. "y", " position y", w / k * x, 0, x)
            y:SetInvisible(true)
            z:SetInvisible(true)
            return setmetatable({parent = r, varname = u, parent_x = y, parent_y = z, res = x}, p)
        end
        function a.drag(q, r, A, B)
            if globals_FrameCount() ~= b then
                c = menu:IsActive()
                f, g = d, e
                d, e = input_GetMousePos()
                i = h
                h = input_IsButtonDown(1) == true
                m = l
                l = {}
                o = n
                n = false
                j, k = draw_GetScreenSize()
            end
            if c and i ~= nil then
                if (not i or o) and h and f > q and g > r and f < q + A and g < r + B then
                    n = true
                    q, r = q + d - f, r + e - g
                    if not D then
                        q = math_max(0, math_min(j - A, q))
                        r = math_max(0, math_min(k - B, r))
                    end
                end
            end
            l[#l + 1] = {q, r, A, B}
            return q, r, A, B
        end
        return a
    end)().new(parent, varname, base_x, base_y)
end

local indicator = {{}}

function draw.indicator(r, g, b, a, string)
    local new = {}
    local add = indicator[1]
    local x, y = draw_GetScreenSize()

    new.y = y / 1.4105 - #add * 35

    local i = #add + 1
    add[i] = {}

    setmetatable(add[i], new)
    new.__index = new
    new.r, new.g, new.b, new.a = _color(r, g, b, a)
    new.string = string or ""

    return new.y
end

local font = draw_CreateFont("segoe ui", 30, 600)

local draw_gradient = draw.gradient

callbacks.Register(
    "Draw",
    function()
        local temp = {}
        local add = indicator[1]
        local _x, y = draw_GetScreenSize()
        local x = 12
        local c = 0

        draw_SetFont(font)

        add.y = _round(y / 1.4105 - #temp * 35)

        for i = 1, #add do
            temp[#temp + 1] = add[i]
        end

        for i = 1, #temp do
            local _i = temp[i]

            local w, h = draw_GetTextSize(_i.string)
            local xa = _round(x + w * 0.45)
            local ya = add.y - 6
            local xb = add.y + 25

            draw_gradient(x, ya, xa, xb, {c, c, c, c}, {c, c, c, _i.a * 0.2}, true)
            draw_gradient(xa, ya, x + w * 0.9, xb, {c, c, c, _i.a * 0.2}, {c, c, c, c}, true)

            draw_Color(_i.r, _i.g, _i.b, _i.a)
            draw_Text(x + 1, add.y, _i.string)

            add.y = add.y - 35
        end

        indicator[1] = {}
    end
)

return draw

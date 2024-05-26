---@diagnostic disable: undefined-field

local function normalize_yaw(yaw)
    if yaw ~= yaw or yaw == 1 / 0 then
        yaw = 0
        yaw = yaw
    elseif not (yaw > -180 and yaw <= 180) then
        yaw = math.fmod(math.fmod(yaw + 360, 360), 360)
        yaw = yaw > 180 and yaw - 360 or yaw
    end

    return yaw
end

local circle_outline = function(x, y, radius, start_degrees, percentage, thickness, accuracy)
    accuracy = accuracy or 1
    local inner_radius = radius - thickness

    for i = start_degrees, start_degrees + math.abs(percentage * 360) - accuracy, accuracy do
        local radians = math.rad(i)
        local radians_next = math.rad(i + accuracy)

        local xa = x + math.cos(radians) * radius
        local ya = y + math.sin(radians) * radius
        local xb = x + math.cos(radians_next) * radius
        local yb = y + math.sin(radians_next) * radius

        local xc = x + math.cos(radians) * inner_radius
        local yc = y + math.sin(radians) * inner_radius
        local xd = x + math.cos(radians_next) * inner_radius
        local yd = y + math.sin(radians_next) * inner_radius

        draw.Triangle(xa, ya, xb, yb, xc, yc)
        draw.Triangle(xc, yc, xb, yb, xd, yd)
    end
end

local ffi = ffi or require "ffi"

local vector = ffi.typeof "struct {float x, y, z;}"

ffi.metatype(vector, {
    __tostring = function(self)
        return string.format("%.6f %.6f %.6f", self.x, self.y, self.z)
    end,
    __add = function(a, b)
        if not (ffi.istype(vector, a) or type(a) == "number") then return error "bad argument #1 (expected vector|number)" end
        if not (ffi.istype(vector, b) or type(b) == "number") then return error "bad argument #2 (expected vector|number)" end

        if ffi.istype(vector, a) and type(b) == "number" then return vector(a.x + b, a.y + b, a.z + b) end
        if ffi.istype(vector, b) and type(a) == "number" then return vector(a + b.x, a + b.y, a + b.z) end
        return vector(a.x + b.x, a.y + b.y, a.z + b.z)
    end,
    __sub = function(a, b)
        if not (ffi.istype(vector, a) or type(a) == "number") then return error "bad argument #1 (expected vector|number)" end
        if not (ffi.istype(vector, b) or type(b) == "number") then return error "bad argument #2 (expected vector|number)" end

        if ffi.istype(vector, a) and type(b) == "number" then return vector(a.x - b, a.y - b, a.z - b) end
        if ffi.istype(vector, b) and type(a) == "number" then return vector(a - b.x, a - b.y, a - b.z) end
        return vector(a.x - b.x, a.y - b.y, a.z - b.z)
    end,
    __mul = function(a, b)
        if not (ffi.istype(vector, a) or type(a) == "number") then return error "bad argument #1 (expected vector|number)" end
        if not (ffi.istype(vector, b) or type(b) == "number") then return error "bad argument #2 (expected vector|number)" end

        if ffi.istype(vector, a) and type(b) == "number" then return vector(a.x * b, a.y * b, a.z * b) end
        if ffi.istype(vector, b) and type(a) == "number" then return vector(a * b.x, a * b.y, a * b.z) end
        return vector(a.x * b.x, a.y * b.y, a.z * b.z)
    end,
    __div = function(a, b)
        if not (ffi.istype(vector, a) or type(a) == "number") then return error "bad argument #1 (expected vector|number)" end
        if not (ffi.istype(vector, b) or type(b) == "number") then return error "bad argument #2 (expected vector|number)" end

        if ffi.istype(vector, a) and type(b) == "number" then return vector(a.x / b, a.y / b, a.z / b) end
        if ffi.istype(vector, b) and type(a) == "number" then return vector(a / b.x, a / b.y, a / b.z) end
        return vector(a.x / b.x, a.y / b.y, a.z / b.z)
    end,
    __unm = function(a)
        if not ffi.istype(vector, a) then return error "bad argument #1 (expected vector)" end

        return vector(-a.x, -a.y, -a.z)
    end,
    __eq = function(a, b)
        return ffi.istype(vector, a) and ffi.istype(vector, b) and a.x == b.x and a.y == b.y and a.z == b.z
    end,
    __len = function(a)
        return a:length()
    end,
    __index = {
        angles = function(a)
            if not ffi.istype(vector, a) then return error "bad argument #1 (expected vector)" end
            local x, y, z = a:unpack()

            if x == 0 and y == 0 then return z > 0 and -90 or 90, 0, 0 end
            return math.deg(math.atan2(-z, a:length2d())), math.deg(math.atan2(y, x)), 0
        end,
        clone = function(a)
            if not ffi.istype(vector, a) then return error "bad argument #1 (expected vector)" end

            return vector(a:unpack())
        end,
        unpack = function(a)
            if not ffi.istype(vector, a) then return error "bad argument #1 (expected vector)" end

            return a.x, a.y, a.z
        end,
        cross = function(a, b)
            if not ffi.istype(vector, a) then return error "bad argument #1 (expected vector)" end
            if not ffi.istype(vector, b) then return error "bad argument #2 (expected vector)" end

            return vector(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
        end,
        dist = function(a, b)
            if not ffi.istype(vector, a) then return error "bad argument #1 (expected vector)" end
            if not ffi.istype(vector, b) then return error "bad argument #2 (expected vector)" end

            return (b - a):length()
        end,
        dist2d = function(a, b)
            if not ffi.istype(vector, a) then return error "bad argument #1 (expected vector)" end
            if not ffi.istype(vector, b) then return error "bad argument #2 (expected vector)" end

            return (b - a):length2d()
        end,
        dist2dsqr = function(a, b)
            if not ffi.istype(vector, a) then return error "bad argument #1 (expected vector)" end
            if not ffi.istype(vector, b) then return error "bad argument #2 (expected vector)" end

            return (a - b):length2dsqr()
        end,
        distsqr = function(a, b)
            if not ffi.istype(vector, a) then return error "bad argument #1 (expected vector)" end
            if not ffi.istype(vector, b) then return error "bad argument #2 (expected vector)" end

            return (a - b):lengthsqr()
        end,
        dot = function(a, b)
            if not ffi.istype(vector, a) then return error "bad argument #1 (expected vector)" end
            if not ffi.istype(vector, b) then return error "bad argument #2 (expected vector)" end

            return a.x * b.x + a.y * b.y + a.z * b.z
        end,
        in_range = function(a, b, distance)
            if not ffi.istype(vector, a) then return error "bad argument #1 (expected vector)" end
            if not ffi.istype(vector, b) then return error "bad argument #2 (expected vector)" end
            if distance and type(distance) ~= "number" then return error "bad argument #3 (expected number)" end

            return a:dist(b) <= distance
        end,
        init = function(a, x, y, z)
            if not ffi.istype(vector, a) then return error "bad argument #1 (expected vector)" end
            if x and type(x) ~= "number" then return error "bad argument #2 (expected number)" end
            if y and type(y) ~= "number" then return error "bad argument #3 (expected number)" end
            if z and type(z) ~= "number" then return error "bad argument #4 (expected number)" end

            a.x = x or 0
            a.y = y or 0
            a.z = z or 0

            return a
        end,
        init_from_angles = function(a, pitch, yaw)
            if not ffi.istype(vector, a) then return error "bad argument #1 (expected vector)" end
            if not pitch and type(pitch) ~= "number" then return error "bad argument #2 (expected number)" end
            if not yaw and type(yaw) ~= "number" then return error "bad argument #3 (expected number)" end

            local rx, ry = math.rad(pitch), math.rad(yaw)
            local cx, sx = math.cos(rx), math.sin(rx)
            local cy, sy = math.cos(ry), math.sin(ry)

            return a:init(cx * cy, cx * sy, -sx)
        end,
        length = function(a)
            if not ffi.istype(vector, a) then return error "bad argument #1 (expected vector)" end

            return math.sqrt(a:lengthsqr())
        end,
        length2d = function(a)
            if not ffi.istype(vector, a) then return error "bad argument #1 (expected vector)" end

            return math.sqrt(a:length2dsqr())
        end,
        length2dsqr = function(a)
            if not ffi.istype(vector, a) then return error "bad argument #1 (expected vector)" end

            return a.x * a.x + a.y * a.y
        end,
        lengthsqr = function(a)
            if not ffi.istype(vector, a) then return error "bad argument #1 (expected vector)" end

            return a.x * a.x + a.y * a.y + a.z * a.z
        end,
        lerp = function(a, b, t)
            if not ffi.istype(vector, a) then return error "bad argument #1 (expected vector)" end
            if not ffi.istype(vector, b) then return error "bad argument #2 (expected vector)" end
            if type(t) ~= "number" then return error "bad argument #3 (expected number)" end

            return vector(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t)
        end,
        normalize = function(a)
            if not ffi.istype(vector, a) then return error "bad argument #1 (expected vector)" end

            local len = a:length()
            if len > 0 then
                a.x = a.x / len
                a.y = a.y / len
                a.z = a.z / len
            end

            return len
        end,
        normalized = function(a)
            if not ffi.istype(vector, a) then return error "bad argument #1 (expected vector)" end

            local len = a:length()
            if len > 0 then
                return vector(a.x / len, a.y / len, a.z / len)
            end

            return vector(0, 0, 0)
        end,
        scale = function(a, s)
            if not ffi.istype(vector, a) then return error "bad argument #1 (expected vector)" end
            if type(s) ~= "number" then return error "bad argument #2 (expected number)" end

            a.x = a.x * s
            a.y = a.y * s
            a.z = a.z * s
        end,
        scaled = function(a, s)
            if not ffi.istype(vector, a) then return error "bad argument #1 (expected vector)" end
            if type(s) ~= "number" then return error "bad argument #2 (expected number)" end

            return vector(a.x * s, a.y * s, a.z * s)
        end,
        to = function(a, b)
            if not ffi.istype(vector, a) then return error "bad argument #1 (expected vector)" end
            if not ffi.istype(vector, b) then return error "bad argument #2 (expected vector)" end

            return (b - a):normalized()
        end
    }
})

---@diagnostic disable: undefined-doc-name
--- Sorted pairs iteration.
--- @generic T: table, K, V
--- @param t T
--- @param order function
--- @return fun(table: table<K, V>, index?: K):K, V
local function spairs(t, order)
    local keys = {}

    for k in pairs(t) do
        keys[#keys + 1] = k
    end

    if order then
        table.sort(
            keys,
            function(a, b)
                return order(t, a, b)
            end
        )
    else
        table.sort(keys)
    end

    local i = 0

    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

--region oova_enemy
--- @class oova_enemy_c
--- @field public eid number
--- @field public shader color
--- @field public shader_occluded color
--- @field public target_alpha number
--- @field public current_alpha number
--- @field public min_alpha number
--- @field public max_alpha number
--- @field public is_dormant boolean
--- @field public is_dead boolean
--- @field public on_dormant boolean
--- @field public in_view boolean
--- @field public distance number
local oova_enemy_c = {}
local oova_enemy_mt = {__index = oova_enemy_c}

--- Instantiate an object of oova_enemy_c.
--- @param eid number
--- @param shader number[]
--- @param shader_occluded number[]
--- @return oova_enemy_c
function oova_enemy_c.new(eid, shader, shader_occluded)
    return setmetatable(
        {
            eid = eid,
            shader = shader,
            shader_occluded = shader_occluded,
            current_alpha = 0,
            target_alpha = 0,
            min_alpha = 5,
            max_alpha = shader[4],
            is_dormant = false,
            is_dead = false,
            on_dormant = false,
            in_view = false,
            distance = 0
        },
        oova_enemy_mt
    )
end

--endregion

--region oova
--- @class oova_c
--- @field public enemies table<number, oova_enemy_c>
--- @field public screen vector
--- @field public screen_center vector
--- @field public radius number
--- @field public thickness number
--- @field public fade number
--- @field public length number
--- @field public shader number[]
--- @field public shader_occluded number[]
--- @field public shader_dormant number[]
--- @field public only_oov boolean
--- @field public distance_based_radius boolean
--- @field public distance_based_length boolean
--- @field public rainbow boolean
--- @field public rainbow_speed number
--- @field public visible_based_color boolean
--- @field public target_alpha number
--- @field public current_alpha number
--- @field public max_alpha number
--- @field public min_alpha number
--- @field public current_thickness number
--- @field public radii table<number, number>
local oova_c = {}
local oova_mt = {__index = oova_c}

--- Instantiate an object of oova_c.
--- @return oova_c
function oova_c.new()
    return setmetatable(
        {
            enemies = {},
            screen = vector(),
            screen_center = vector(),
            radius = 100,
            thickness = 2,
            fade = 0,
            length = 0.1,
            shader = {255, 0, 0, 255},
            shader_occluded = {255, 0, 0, 100, 255},
            shader_dormant = {100, 100, 100, 100},
            rainbow = false,
            rainbow_speed = 0,
            only_oov = false,
            visible_based_color = false,
            distance_based_length = false,
            target_alpha = 255,
            current_alpha = 0,
            max_alpha = 255,
            min_alpha = 0,
            current_thickness = 0,
            radii = {}
        },
        oova_mt
    )
end

--- Updata OOVA data.
function oova_c:sync()
    self.screen:init(draw.GetScreenSize())
    self.screen_center:init(self.screen.x / 2, self.screen.y / 2)
end

local function rgb2hsl(r, g, b, a)
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local h, s, l = 0, 0, (max + min) / 2

    if max == min then
        h, s = 0, 0
    else
        local d = max - min
        s = l > 0.5 and d / (2 - max - min) or d / (max + min)
        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        elseif max == b then
            h = (r - g) / d + 4
        end
        h = h / 6
    end

    return h, s, l, a
end

local function hsl2rgb(h, s, l, a)
    if s == 0 then
        return l, l, l
    end

    local function hue2rgb(p, q, t)
        if t < 0 then t = t + 1 end
        if t > 1 then t = t - 1 end
        if t < 1 / 6 then return p + (q - p) * 6 * t end
        if t < 1 / 2 then return q end
        if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
        return p
    end

    local q = l < 0.5 and l * (1 + s) or l + s - l * s
    local p = 2 * l - q

    local r = hue2rgb(p, q, h + 1 / 3)
    local g = hue2rgb(p, q, h)
    local blue = hue2rgb(p, q, h - 1 / 3)

    return r, g, blue, a
end

--- Render OOVA.
function oova_c:render()
    local i = 1
    local enemy_count = 0

    if (self.rainbow == true) then
        local h, s, l, a = rgb2hsl(unpack(self.shader))
        self.shader = {hsl2rgb((h + self.rainbow_speed) % 360, s, l, a)}
    end

    for _, enemy in pairs(self.enemies) do
        if (enemy.current_alpha > 1) then
            enemy_count = enemy_count + 1
        end
    end

    if (enemy_count > 0) then
        local target_thickness = self.thickness - enemy_count * 1.5
        self.current_thickness = self.current_thickness + (target_thickness - self.current_thickness) * 0.025
    end

    if (self.fade == 0) then
        self.current_alpha = self.max_alpha
    else
        self.current_alpha = self.current_alpha + (self.target_alpha - self.current_alpha) * self.fade

        if (self.current_alpha < 25) then
            self.target_alpha = self.max_alpha
        elseif (self.current_alpha > self.max_alpha - 25) then
            self.target_alpha = self.min_alpha
        end
    end

    for _, enemy in spairs(
        self.enemies,
        function(table, a, b)
            return table[a].distance < table[b].distance
        end
    ) do
        if (self.rainbow == true) then
            enemy.shader = {unpack(self.shader)}
        end

        local shader, alpha, radius, start_degrees, length = self:get_enemy_indicator_data(enemy)

        draw.Color(math.min(shader[1], 255), math.min(shader[2], 255), math.min(shader[3], 255), math.min(alpha, 255))
        circle_outline(self.screen_center.x, self.screen_center.y, radius - (i * (self.current_thickness * 1.15)), start_degrees, length, self.current_thickness)

        if (enemy.current_alpha > 1) then
            i = i + 1
        end
    end
end

--- Process enemies for rendering.
function oova_c:process_enemies()
    for _, ent in pairs(entities.FindByClass "C_CSPlayerPawn") do
        if ent:GetTeamNumber() ~= entities.GetLocalPawn():GetTeamNumber() then
            local eid = ent:GetIndex()
            if not self.enemies[eid] then
                self.enemies[eid] = oova_enemy_c.new(eid, {unpack(self.shader)}, {unpack(self.shader_occluded)})
            end
        end
    end

    for _, enemy in pairs(self.enemies) do
        local ent = entities.GetByIndex(enemy.eid)
        if ent == nil or not ent:IsPlayer() then
            self.enemies[enemy.eid] = nil
        else
            local enemy_w2s = client.WorldToScreen(ent:GetAbsOrigin())

            enemy.in_view = enemy_w2s ~= nil
            enemy.is_dead = not ent:IsAlive()
            enemy.is_dormant = false

            if not enemy.on_dormant and enemy.is_dormant then
                enemy.on_dormant = true

                if self.only_oov and not enemy.in_view then
                    enemy.current_alpha = 255
                elseif not self.only_oov then
                    enemy.current_alpha = 255
                end
            elseif enemy.on_dormant and not enemy.is_dormant then
                enemy.on_dormant = false
            end
        end
    end
end

--- Update the enemy shaders.
function oova_c:update_enemy_shaders()
    for _, enemy in pairs(self.enemies) do
        enemy.shader = {unpack(self.shader)}
        enemy.shader_occluded = {unpack(self.shader_occluded)}
        enemy.max_alpha = enemy.shader[4]
        enemy.current_alpha = enemy.shader[4]
    end
end

--- Returns the data necessary to render the enemy's indicator: shader, radius, start degrees.
--- @param enemy oova_enemy_c
--- @return color, number, number, number, number
function oova_c:get_enemy_indicator_data(enemy)
    local shader = enemy.shader

    local ent = entities.GetByIndex(enemy.eid)
    local player = entities.GetLocalPawn()
    -- local player_eye_pos = player:GetEyePosition()

    if self.visible_based_color then
        shader = enemy.shader_occluded

        for i = 0, 18 do
            -- if trace_line(player_eye_pos, ent:GetHitboxOosition(i), player):IsVisible() then
            --     shader = enemy.shader
            -- end
        end
    end

    if enemy.is_dormant then
        enemy.target_alpha = 0

        shader = self.shader_dormant
    elseif enemy.is_dead then
        enemy.target_alpha = 0

        shader = self.shader_dormant
    elseif enemy.current_alpha < enemy.min_alpha then
        enemy.target_alpha = enemy.max_alpha
    elseif enemy.current_alpha > enemy.max_alpha - 5 then
        enemy.target_alpha = 0
    end

    if enemy.is_dormant then
        enemy.current_alpha = math.max(0, enemy.current_alpha - 1)
    elseif enemy.is_dead then
        enemy.current_alpha = math.max(0, enemy.current_alpha - 2)
    elseif self.only_oov and enemy.in_view then
        enemy.current_alpha = math.max(0, enemy.current_alpha - 2)
    else
        enemy.current_alpha = self.current_alpha
    end

    local _player_origin = player:GetAbsOrigin()
    local _enemy_origin = ent:GetAbsOrigin()

    local player_origin = vector(_player_origin.x, _player_origin.y, _player_origin.z)
    local enemy_origin = vector(_enemy_origin.x, _enemy_origin.y, _enemy_origin.z)

    local length = self.length
    local distance = player_origin:dist(enemy_origin)

    enemy.distance = distance

    if self.distance_based_length then
        length = math.min(0.33, math.max(0.05, ((2048 - distance) / 2048) / 5))
    end

    local radius = self.radius
    local viewangles = engine.GetViewAngles()
    local _, enemy_yaw = player_origin:to(enemy_origin):angles()

    local start_degrees = 180 - normalize_yaw(enemy_yaw - viewangles.y) + 90
    local offset = length * 360

    start_degrees = start_degrees - (offset / 2)

    return shader, enemy.current_alpha, radius, start_degrees, length
end

--endregion

--region setup
local oova = oova_c.new()
--endregion

local ref = gui.Groupbox(gui.Tab(gui.Reference "Settings", "indicators", "Indicators"), "Main", 16, 16)

local enable_script = gui.Checkbox(ref, "enabled", "Enabled", true)

--------------------------------------------------
local shader = gui.ColorPicker(enable_script, "clr", "Color", 156, 62, 62)

local old_shader = {}
callbacks.Register("Draw", function()
    local value = {shader:GetValue()}
    if old_shader[1] == value[1] and old_shader[2] == value[2] and old_shader[3] == value[3] and old_shader[4] == value[4] then return end
    old_shader = value

    oova.shader = value
    oova:update_enemy_shaders()
end)

--------------------------------------------------
local rainbow = gui.Checkbox(ref, "rainbow", "Rainbow mode", false)

local old_rainbow
callbacks.Register("Draw", function()
    local value = rainbow:GetValue()
    if old_rainbow == value then return end
    old_rainbow = value

    oova.rainbow = value
    if not value then
        oova.shader = {shader:GetValue()}
        oova:update_enemy_shaders()
    end
end)

--------------------------------------------------
local rainbow_speed = gui.Slider(ref, "rainbow.speed", "Rainbow speed", 33, 1, 100)

local old_rainbow_speed
callbacks.Register("Draw", function()
    local value = rainbow_speed:GetValue()
    if old_rainbow_speed == value then return end
    old_rainbow_speed = value

    oova.rainbow_speed = value * 0.0001 / 2
end)

--------------------------------------------------
local shader_dormant = gui.ColorPicker(ref, "dormant.clr", "Dormant color", 71, 71, 71)

local old_shader_dormant = {}
callbacks.Register("Draw", function()
    local value = {shader_dormant:GetValue()}
    if old_shader_dormant[1] == value[1] and old_shader_dormant[2] == value[2] and old_shader_dormant[3] == value[3] and old_shader_dormant[4] == value[4] then return end
    old_shader_dormant = value

    oova.shader_dormant = value
    oova:update_enemy_shaders()
end)

--------------------------------------------------
local visible_based_color = gui.Checkbox(ref, "visibility", "Colors based on visibility", false)

local old_visible_based_color
callbacks.Register("Draw", function()
    local value = visible_based_color:GetValue()
    if old_visible_based_color == value then return end
    old_visible_based_color = value

    oova.visible_based_color = value
end)

--------------------------------------------------
local shader_occluded = gui.ColorPicker(visible_based_color, "occluded.clr", "Occluded color", 135, 131, 97)

local old_shader_occluded = {}
callbacks.Register("Draw", function()
    local value = {shader_occluded:GetValue()}
    if old_shader_occluded[1] == value[1] and old_shader_occluded[2] == value[2] and old_shader_occluded[3] == value[3] and old_shader_occluded[4] == value[4] then return end
    old_shader_occluded = value

    if not value then
        oova.shader_occluded = value
        oova:update_enemy_shaders()
    end
end)

--------------------------------------------------
local only_oov = gui.Checkbox(ref, "outofview", "Only out of view", false)

local old_only_oov
callbacks.Register("Draw", function()
    local value = only_oov:GetValue()
    if old_only_oov == value then return end
    old_only_oov = value

    oova.only_oov = value
end)

--------------------------------------------------
local max_alpha = gui.Slider(ref, "opacity", "Maximum opacity", 75, 10, 100)

local old_max_alpha
callbacks.Register("Draw", function()
    local value = max_alpha:GetValue()
    if old_max_alpha == value then return end
    old_max_alpha = value

    oova.max_alpha = 255 * (value * 0.01)
    oova.target_alpha = 0
end)

--------------------------------------------------
local radius = gui.Slider(ref, "radius", "Radius", 60, 25, 100)

local old_radius
callbacks.Register("Draw", function()
    local value = radius:GetValue()
    if old_radius == value then return end
    old_radius = value

    oova.radius = 400 * (value * 0.01)
end)

--------------------------------------------------
local thickness = gui.Slider(ref, "thickness", "Thickness", 20, 8, 30)

local old_thickness
callbacks.Register("Draw", function()
    local value = thickness:GetValue()
    if old_thickness == value then return end
    old_thickness = value

    oova.thickness = value
end)

--------------------------------------------------
local fade = gui.Slider(ref, "fade", "Fade speed", 20, 0, 50, 0.1)

local old_fade
callbacks.Register("Draw", function()
    local value = fade:GetValue()
    if old_fade == value then return end
    old_fade = value

    oova.fade = value * 0.001
end)

--------------------------------------------------
local distance_based_length = gui.Checkbox(ref, "ondistance", "Length based on distance", false)

local old_distance_based_length
callbacks.Register("Draw", function()
    local value = distance_based_length:GetValue()
    if old_distance_based_length == value then return end
    old_distance_based_length = value

    oova.distance_based_length = value
end)

--------------------------------------------------
local length = gui.Slider(ref, "length", "Length", 60, 25, 100)

local old_length
callbacks.Register("Draw", function()
    local value = length:GetValue()
    if old_length == value then return end
    old_length = value

    oova.length = value * 0.001
end)

--------------------------------------------------
local old_enable_script
callbacks.Register("Draw", function()
    local value = enable_script:GetValue()
    if old_enable_script == value then return end
    old_enable_script = value

    shader:SetInvisible(not value)
    rainbow:SetInvisible(not value)
    rainbow_speed:SetInvisible(not value)
    shader_dormant:SetInvisible(not value)
    visible_based_color:SetInvisible(not value)
    only_oov:SetInvisible(not value)
    max_alpha:SetInvisible(not value)
    radius:SetInvisible(not value)
    thickness:SetInvisible(not value)
    fade:SetInvisible(not value)
    distance_based_length:SetInvisible(not value)
    length:SetInvisible(not (not distance_based_length:GetValue() and value))
end)

--------------------------------------------------
local old_rainbow
callbacks.Register("Draw", function()
    local value = rainbow:GetValue()
    if old_rainbow == value then return end
    old_rainbow = value

    shader:SetInvisible(value)
    rainbow_speed:SetInvisible(not value)
end)

--------------------------------------------------
local old_visible_based_color
callbacks.Register("Draw", function()
    local value = visible_based_color:GetValue()
    if old_visible_based_color == value then return end
    old_visible_based_color = value

    shader_occluded:SetInvisible(not value)
end)

--------------------------------------------------
local old_distance_based_length
callbacks.Register("Draw", function()
    local value = distance_based_length:GetValue()
    if old_distance_based_length == value then return end
    old_distance_based_length = value

    length:SetInvisible(not (enable_script:GetValue() and not value))
end)
--endregion

--region main
callbacks.Register("Draw", function()
    local local_player = client.GetLocalPlayerIndex()
    if not (enable_script:GetValue() and local_player and entities.GetByIndex(local_player):IsAlive()) then return end

    oova:sync()
    oova:process_enemies()
    oova:render()
end
)
--endregion

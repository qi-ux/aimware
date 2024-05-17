local ffi = ffi or require("ffi")

local ctype = ffi.typeof "struct {float x, y, z;}"

ffi.metatype(ctype, {
    __tostring = function(self)
        return string.format("%.6f %.6f %.6f", self.x, self.y, self.z)
    end,
    __add = function(a, b)
        if not (ffi.istype(ctype, a) or type(a) == "number") then return error("bad argument #1 (expected vector|number)") end
        if not (ffi.istype(ctype, b) or type(b) == "number") then return error("bad argument #2 (expected vector|number)") end

        if ffi.istype(ctype, a) and type(b) == "number" then return ctype(a.x + b, a.y + b, a.z + b) end
        if ffi.istype(ctype, b) and type(a) == "number" then return ctype(a + b.x, a + b.y, a + b.z) end
        return ctype(a.x + b.x, a.y + b.y, a.z + b.z)
    end,
    __sub = function(a, b)
        if not (ffi.istype(ctype, a) or type(a) == "number") then return error("bad argument #1 (expected vector|number)") end
        if not (ffi.istype(ctype, b) or type(b) == "number") then return error("bad argument #2 (expected vector|number)") end

        if ffi.istype(ctype, a) and type(b) == "number" then return ctype(a.x - b, a.y - b, a.z - b) end
        if ffi.istype(ctype, b) and type(a) == "number" then return ctype(a - b.x, a - b.y, a - b.z) end
        return ctype(a.x - b.x, a.y - b.y, a.z - b.z)
    end,
    __mul = function(a, b)
        if not (ffi.istype(ctype, a) or type(a) == "number") then return error("bad argument #1 (expected vector|number)") end
        if not (ffi.istype(ctype, b) or type(b) == "number") then return error("bad argument #2 (expected vector|number)") end

        if ffi.istype(ctype, a) and type(b) == "number" then return ctype(a.x * b, a.y * b, a.z * b) end
        if ffi.istype(ctype, b) and type(a) == "number" then return ctype(a * b.x, a * b.y, a * b.z) end
        return ctype(a.x * b.x, a.y * b.y, a.z * b.z)
    end,
    __div = function(a, b)
        if not (ffi.istype(ctype, a) or type(a) == "number") then return error("bad argument #1 (expected vector|number)") end
        if not (ffi.istype(ctype, b) or type(b) == "number") then return error("bad argument #2 (expected vector|number)") end

        if ffi.istype(ctype, a) and type(b) == "number" then return ctype(a.x / b, a.y / b, a.z / b) end
        if ffi.istype(ctype, b) and type(a) == "number" then return ctype(a / b.x, a / b.y, a / b.z) end
        return ctype(a.x / b.x, a.y / b.y, a.z / b.z)
    end,
    __unm = function(a)
        if not ffi.istype(ctype, a) then return error("bad argument #1 (expected vector)") end

        return ctype(-a.x, -a.y, -a.z)
    end,
    __eq = function(a, b)
        return ffi.istype(ctype, a) and ffi.istype(ctype, b) and a.x == b.x and a.y == b.y and a.z == b.z
    end,
    __len = function(a)
        return a:length()
    end,
    __index = {
        angles = function(a)
            if not ffi.istype(ctype, a) then return error("bad argument #1 (expected vector)") end
            local x, y, z = a:unpack()

            if x == 0 and y == 0 then return z > 0 and -90 or 90, 0, 0 end
            return math.deg(math.atan2(-z, a:length2d())), math.deg(math.atan2(y, x)), 0
        end,
        clone = function(a)
            if not ffi.istype(ctype, a) then return error("bad argument #1 (expected vector)") end

            return ctype(a:unpack())
        end,
        unpack = function(a)
            if not ffi.istype(ctype, a) then return error("bad argument #1 (expected vector)") end

            return a.x, a.y, a.z
        end,
        cross = function(a, b)
            if not ffi.istype(ctype, a) then return error("bad argument #1 (expected vector)") end
            if not ffi.istype(ctype, b) then return error("bad argument #2 (expected vector)") end

            return ctype(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
        end,
        dist = function(a, b)
            if not ffi.istype(ctype, a) then return error("bad argument #1 (expected vector)") end
            if not ffi.istype(ctype, b) then return error("bad argument #2 (expected vector)") end

            return (b - a):length()
        end,
        dist2d = function(a, b)
            if not ffi.istype(ctype, a) then return error("bad argument #1 (expected vector)") end
            if not ffi.istype(ctype, b) then return error("bad argument #2 (expected vector)") end

            return (b - a):length2d()
        end,
        dist2dsqr = function(a, b)
            if not ffi.istype(ctype, a) then return error("bad argument #1 (expected vector)") end
            if not ffi.istype(ctype, b) then return error("bad argument #2 (expected vector)") end

            return (a - b):length2dsqr()
        end,
        distsqr = function(a, b)
            if not ffi.istype(ctype, a) then return error("bad argument #1 (expected vector)") end
            if not ffi.istype(ctype, b) then return error("bad argument #2 (expected vector)") end

            return (a - b):lengthsqr()
        end,
        dot = function(a, b)
            if not ffi.istype(ctype, a) then return error("bad argument #1 (expected vector)") end
            if not ffi.istype(ctype, b) then return error("bad argument #2 (expected vector)") end

            return a.x * b.x + a.y * b.y + a.z * b.z
        end,
        in_range = function(a, b, distance)
            if not ffi.istype(ctype, a) then return error("bad argument #1 (expected vector)") end
            if not ffi.istype(ctype, b) then return error("bad argument #2 (expected vector)") end
            if distance and type(distance) ~= "number" then return error("bad argument #3 (expected number)") end

            return a:dist(b) <= distance
        end,
        init = function(a, x, y, z)
            if not ffi.istype(ctype, a) then return error("bad argument #1 (expected vector)") end
            if x and type(x) ~= "number" then return error("bad argument #2 (expected number)") end
            if y and type(y) ~= "number" then return error("bad argument #3 (expected number)") end
            if z and type(z) ~= "number" then return error("bad argument #4 (expected number)") end

            a.x = x or 0
            a.y = y or 0
            a.z = z or 0

            return a
        end,
        init_from_angles = function(a, pitch, yaw)
            if not ffi.istype(ctype, a) then return error("bad argument #1 (expected vector)") end
            if not pitch and type(pitch) ~= "number" then return error("bad argument #2 (expected number)") end
            if not yaw and type(yaw) ~= "number" then return error("bad argument #3 (expected number)") end

            local rx, ry = math.rad(pitch), math.rad(yaw)
            local cx, sx = math.cos(rx), math.sin(rx)
            local cy, sy = math.cos(ry), math.sin(ry)

            return a:init(cx * cy, cx * sy, -sx)
        end,
        length = function(a)
            if not ffi.istype(ctype, a) then return error("bad argument #1 (expected vector)") end

            return math.sqrt(a:lengthsqr())
        end,
        length2d = function(a)
            if not ffi.istype(ctype, a) then return error("bad argument #1 (expected vector)") end

            return math.sqrt(a:length2dsqr())
        end,
        length2dsqr = function(a)
            if not ffi.istype(ctype, a) then return error("bad argument #1 (expected vector)") end

            return a.x * a.x + a.y * a.y
        end,
        lengthsqr = function(a)
            if not ffi.istype(ctype, a) then return error("bad argument #1 (expected vector)") end

            return a.x * a.x + a.y * a.y + a.z * a.z
        end,
        lerp = function(a, b, t)
            if not ffi.istype(ctype, a) then return error("bad argument #1 (expected vector)") end
            if not ffi.istype(ctype, b) then return error("bad argument #2 (expected vector)") end
            if type(t) ~= "number" then return error("bad argument #3 (expected number)") end

            return ctype(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t)
        end,
        normalize = function(a)
            if not ffi.istype(ctype, a) then return error("bad argument #1 (expected vector)") end

            local len = a:length()
            if len > 0 then
                a.x = a.x / len
                a.y = a.y / len
                a.z = a.z / len
            end

            return len
        end,
        normalized = function(a)
            if not ffi.istype(ctype, a) then return error("bad argument #1 (expected vector)") end

            local len = a:length()
            if len > 0 then
                return ctype(a.x / len, a.y / len, a.z / len)
            end

            return ctype(0, 0, 0)
        end,
        scale = function(a, s)
            if not ffi.istype(ctype, a) then return error("bad argument #1 (expected vector)") end
            if type(s) ~= "number" then return error("bad argument #2 (expected number)") end

            a.x = a.x * s
            a.y = a.y * s
            a.z = a.z * s
        end,
        scaled = function(a, s)
            if not ffi.istype(ctype, a) then return error("bad argument #1 (expected vector)") end
            if type(s) ~= "number" then return error("bad argument #2 (expected number)") end

            return ctype(a.x * s, a.y * s, a.z * s)
        end,
        to = function(a, b)
            if not ffi.istype(ctype, a) then return error("bad argument #1 (expected vector)") end
            if not ffi.istype(ctype, b) then return error("bad argument #2 (expected vector)") end

            return (b - a):normalized()
        end
    }
})

return ctype

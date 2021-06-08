function gui.Dragging(parent, varname, base_x, base_y)
    local menu = gui.Reference("menu")
    return (function()
        local a = {}
        local b, c, d, e, f, g, h, i, j, k, l, m, n, o
        local p = {
            __index = {
                Drag = function(self, ...)
                    local q, r = self:GetValue()
                    local s, t = a.drag(q, r, ...)
                    if q ~= s or r ~= t then
                        self:SetValue(s, t)
                    end
                    return s, t
                end,
                SetValue = function(self, q, r)
                    local j, k = draw.GetScreenSize()
                    self.x:SetValue(q / j * self.res)
                    self.y:SetValue(r / k * self.res)
                end,
                GetValue = function(self)
                    local j, k = draw.GetScreenSize()
                    return math.round(self.x:GetValue() / self.res * j), math.round(self.y:GetValue() / self.res * k)
                end
            }
        }
        function a.new(r, u, v, w, x)
            local x = x or 10000
            local j, k = draw.GetScreenSize()
            local u = u ~= "" and (u .. ".") or u
            local y = gui.Slider(r, u .. "x", " position x", v / j * x, 0, x)
            local z = gui.Slider(r, u .. "y", " position y", w / k * x, 0, x)
            y:SetInvisible(true)
            z:SetInvisible(true)
            return setmetatable({x = y, y = z, res = x}, p)
        end
        function a.drag(q, r, A, B, C)
            if globals.FrameCount() ~= b then
                c = menu:IsActive()
                f, g = d, e
                d, e = input.GetMousePos()
                i = h
                h = input.IsButtonDown(1) == true
                m = l
                l = {}
                o = n
                n = false
                j, k = draw.GetScreenSize()
            end
            if c and i ~= nil then
                if (not i or o) and h and f > q and g > r and f < q + A and g < r + B then
                    n = true
                    q, r = q + d - f, r + e - g
                    if not C then
                        q = math.max(0, math.min(j - A, q))
                        r = math.max(0, math.min(k - B, r))
                    end
                end
            end
            table.insert(l, {q, r, A, B})
            return q, r, A, B
        end
        return a
    end)().new(parent, varname, base_x, base_y)
end

return gui
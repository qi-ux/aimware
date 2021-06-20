local json = {}
do
    local b = string.format
    local d = string.char
    local function e(...)
        local f = {}
        for g = 1, select("#", ...) do
            f[select(g, ...)] = true
        end
        return f
    end
    local h = e(" ", "\t", "\r", "\n")
    local i = e(" ", "\t", "\r", "\n", "]", "}", ",")
    local j = e("\\", "/", '"', "b", "f", "n", "r", "t", "u")
    local k = e("true", "false", "null")
    local l = {["true"] = true, ["false"] = false, ["null"] = nil}
    local function m(n, o, p, q)
        for g = o, #n do
            if p[n:sub(g, g)] ~= q then
                return g
            end
        end
        return #n + 1
    end
    local function r(n, o, s)
        local t = 1
        local u = 1
        for g = 1, o - 1 do
            u = u + 1
            if n:sub(g, g) == "\n" then
                t = t + 1
                u = 1
            end
        end
        error(b("%s at line %d col %d", s, t, u))
    end
    local function v(w)
        local x = math.floor
        if w <= 0x7f then
            return d(w)
        elseif w <= 0x7ff then
            return d(x(w / 64) + 192, w % 64 + 128)
        elseif w <= 0xffff then
            return d(x(w / 4096) + 224, x(w % 4096 / 64) + 128, w % 64 + 128)
        elseif w <= 0x10ffff then
            return d(x(w / 262144) + 240, x(w % 262144 / 4096) + 128, x(w % 4096 / 64) + 128, w % 64 + 128)
        end
        error(b("invalid unicode codepoint '%x'", w))
    end
    local function y(z)
        local A = tonumber(z:sub(1, 4), 16)
        local B = tonumber(z:sub(7, 10), 16)
        if B then
            return v((A - 0xd800) * 0x400 + B - 0xdc00 + 0x10000)
        else
            return v(A)
        end
    end
    local function C(n, g)
        local f = ""
        local D = g + 1
        local E = D
        while D <= #n do
            local F = n:byte(D)
            if F < 32 then
                r(n, D, "control character in string")
            elseif F == 92 then
                f = f .. n:sub(E, D - 1)
                D = D + 1
                local G = n:sub(D, D)
                if G == "u" then
                    local H =
                        n:match("^[dD][89aAbB]%x%x\\u%x%x%x%x", D + 1) or n:match("^%x%x%x%x", D + 1) or
                        r(n, D - 1, "invalid unicode escape in string")
                    f = f .. y(H)
                    D = D + #H
                else
                    if not j[G] then
                        r(n, D - 1, "invalid escape char '" .. G .. "' in string")
                    end
                    f = f .. escape_char_map_inv[G]
                end
                E = D + 1
            elseif F == 34 then
                f = f .. n:sub(E, D - 1)
                return f, D + 1
            end
            D = D + 1
        end
        r(n, g, "expected closing quote for string")
    end
    local function I(n, g)
        local F = m(n, g, i)
        local z = n:sub(g, F - 1)
        local w = tonumber(z)
        if not w then
            r(n, g, "invalid number '" .. z .. "'")
        end
        return w, F
    end
    local function J(n, g)
        local F = m(n, g, i)
        local K = n:sub(g, F - 1)
        if not k[K] then
            r(n, g, "invalid literal '" .. K .. "'")
        end
        return l[K], F
    end
    local function L(n, g)
        local f = {}
        local w = 1
        g = g + 1
        while 1 do
            local F
            g = m(n, g, h, true)
            if n:sub(g, g) == "]" then
                g = g + 1
                break
            end
            F, g = c(n, g)
            f[w] = F
            w = w + 1
            g = m(n, g, h, true)
            local M = n:sub(g, g)
            g = g + 1
            if M == "]" then
                break
            end
            if M ~= "," then
                r(n, g, "expected ']' or ','")
            end
        end
        return f, g
    end
    local function N(n, g)
        local f = {}
        g = g + 1
        while 1 do
            local O, P
            g = m(n, g, h, true)
            if n:sub(g, g) == "}" then
                g = g + 1
                break
            end
            if n:sub(g, g) ~= '"' then
                r(n, g, "expected string for key")
            end
            O, g = c(n, g)
            g = m(n, g, h, true)
            if n:sub(g, g) ~= ":" then
                r(n, g, "expected ':' after key")
            end
            g = m(n, g + 1, h, true)
            P, g = c(n, g)
            f[O] = P
            g = m(n, g, h, true)
            local M = n:sub(g, g)
            g = g + 1
            if M == "}" then
                break
            end
            if M ~= "," then
                r(n, g, "expected '}' or ','")
            end
        end
        return f, g
    end
    local Q = {
        ['"'] = C,
        ["0"] = I,
        ["1"] = I,
        ["2"] = I,
        ["3"] = I,
        ["4"] = I,
        ["5"] = I,
        ["6"] = I,
        ["7"] = I,
        ["8"] = I,
        ["9"] = I,
        ["-"] = I,
        ["t"] = J,
        ["f"] = J,
        ["n"] = J,
        ["["] = L,
        ["{"] = N
    }
    c = function(n, o)
        local M = n:sub(o, o)
        local x = Q[M]
        if x then
            return x(n, o)
        end
        r(n, o, "unexpected character '" .. M .. "'")
    end
    function json.parse(n)
        if type(n) ~= "string" then
            error("expected argument of type string, got " .. type(n))
        end
        local f, o = c(n, m(n, 1, h, true))
        o = m(n, o, h, true)
        if o <= #n then
            r(n, o, "trailing garbage")
        end
        return f
    end
    local b, d, c, e, f = string.byte, string.find, string.format, string.gsub, string.match
    local g, h, i = table.concat, string.sub, string.rep
    local j, k = 1 / 0, -1 / 0
    local l = "[^ -!#-[%]^-\255]"
    local m
    do
        local o, p
        local q, r
        local function s(o)
            r[q] = tostring(o)
            q = q + 1
        end
        local t = f(tostring(0.5), "[^0-9]")
        local u = f(tostring(12345.12345), "[^0-9" .. t .. "]")
        if t == "." then
            t = nil
        end
        local v
        if t or u then
            v = true
            if t and d(t, "%W") then
                t = "%" .. t
            end
            if u and d(u, "%W") then
                u = "%" .. u
            end
        end
        local w = function(x)
            if k < x and x < j then
                local y = tostring(x)
                if v then
                    if u then
                        y = e(y, u, "")
                    end
                    if t then
                        y = e(y, t, ".")
                    end
                end
                r[q] = y
                q = q + 1
                return
            end
            error("invalid number")
        end
        local z
        local A = {
            ['"'] = '\\"',
            ["\\"] = "\\\\",
            ["\b"] = "\\b",
            ["\f"] = "\\f",
            ["\n"] = "\\n",
            ["\r"] = "\\r",
            ["\t"] = "\\t",
            __index = function(R, C)
                return c("\\u00%02X", b(C))
            end
        }
        setmetatable(A, A)
        local function D(y)
            r[q] = '"'
            if d(y, l) then
                y = e(y, l, A)
            end
            r[q + 1] = y
            r[q + 2] = '"'
            q = q + 3
        end
        local function E(F)
            local G = F[0]
            if type(G) == "number" then
                r[q] = "["
                q = q + 1
                for H = 1, G do
                    z(F[H])
                    r[q] = ","
                    q = q + 1
                end
                if G > 0 then
                    q = q - 1
                end
                r[q] = "]"
            else
                G = F[1]
                if G ~= nil then
                    r[q] = "["
                    q = q + 1
                    local H = 2
                    repeat
                        z(G)
                        G = F[H]
                        if G == nil then
                            break
                        end
                        H = H + 1
                        r[q] = ","
                        q = q + 1
                    until false
                    r[q] = "]"
                else
                    r[q] = "{"
                    q = q + 1
                    local G = q
                    for I, o in pairs(F) do
                        D(I)
                        r[q] = ":"
                        q = q + 1
                        z(o)
                        r[q] = ","
                        q = q + 1
                    end
                    if q > G then
                        q = q - 1
                    end
                    r[q] = "}"
                end
            end
            q = q + 1
        end
        local J = {boolean = s, number = w, string = D, table = E}
        setmetatable(J, J)
        function z(o)
            if o == p then
                r[q] = "null"
                q = q + 1
                return
            end
            return J[type(o)](o)
        end
        function m(K, L)
            o, p = K, L
            q, r = 1, {}
            z(o)
            return g(r)
        end
        function json.encode_pretty(o, M, N, O)
            local y, P = m(o)
            if not y then
                return y, P
            end
            M, N, O = M or "\n", N or "\t", O or " "
            local q, H, I, x, Q, S, T = 1, 0, 0, #y, {}, nil, nil
            local U = h(O, -1) == "\n"
            for V = 1, x do
                local C = h(y, V, V)
                if not T and (C == "{" or C == "[") then
                    Q[q] = S == ":" and g {C, M} or g {i(N, H), C, M}
                    H = H + 1
                elseif not T and (C == "}" or C == "]") then
                    H = H - 1
                    if S == "{" or S == "[" then
                        q = q - 1
                        Q[q] = g {i(N, H), S, C}
                    else
                        Q[q] = g {M, i(N, H), C}
                    end
                elseif not T and C == "," then
                    Q[q] = g {C, M}
                    I = -1
                elseif not T and C == ":" then
                    Q[q] = g {C, O}
                    if U then
                        q = q + 1
                        Q[q] = i(N, H)
                    end
                else
                    if C == '"' and S ~= "\\" then
                        T = not T and true or nil
                    end
                    if H ~= I then
                        Q[q] = i(N, H)
                        q, I = q + 1, H
                    end
                    Q[q] = C
                end
                S, q = C, q + 1
            end
            return g(Q)
        end
    end
end

function file.exist(filename)
    local file_exist = false
    file.Enumerate(
        function(fn)
            file_exist = fn == filename and true or file_exist
        end
    )
    return file_exist
end

local database = {}
do
    local path = "data/database.dat"
    local db_table = json.parse(file.exist(path) and file.Read(path) or "{}")

    function database.write(key, value)
        db_table[key] = value
        file.Write(path, json.encode_pretty(db_table))
    end

    function database.read(key)
        return db_table[key]
    end
end

--working on aimware havoc vision rpg qq
--by qi

local draw =
    require and require("libraries/draw", "https://aimware28.coding.net/p/coding-code-guide/d/aim_lib/git/raw/master/draw/draw.lua") or
    http.Get(
        "https://aimware28.coding.net/p/coding-code-guide/d/aim_lib/git/raw/master/require.lua",
        function(body)
            local r = file.Open("autorun.lua", "a")
            r:Write(body)
            r:Close()
            load(body)()
        end
    )

local function http_update(version, version_url, download_url)
    http.Get(
        version_url,
        function(body)
            local http_write =
                version ~= body and
                http.Get(
                    download_url,
                    function(data)
                        file.Write(GetScriptName(), data)
                    end
                )
        end
    )
end

http_update(
    "1.45",
    "https://aimware28.coding.net/p/coding-code-guide/d/aimware/git/raw/master/havoc_vision_rpg_qq/version.md",
    "https://aimware28.coding.net/p/coding-code-guide/d/aimware/git/raw/master/havoc_vision_rpg_qq/havoc_vision_rpg_qq.lua"
)

local ref = gui.Reference("visuals", "local", "camera")
local ui_havoc_vision_rpg = gui.Checkbox(ref, "havoc.vision.rpg", "havoc vision rpg", 1)
local ui_havoc_vision_rpg_qq = gui.Editbox(ref, "havoc.vision.rpg.qq", "")
local ui_havoc_vision_rpg_drag = draw.drag(ui_havoc_vision_rpg, "havoc vision rpg", 400, 150)

ui_havoc_vision_rpg_qq:SetValue("2878713023")
ui_havoc_vision_rpg_qq:SetHeight(20)

local qq_avatars_texture

local function update_texture()
    http.Get(
        "http://q.qlogo.cn/headimg_dl?dst_uin=" .. ui_havoc_vision_rpg_qq:GetValue() .. "&spec=140",
        function(body)
            qq_avatars_texture = draw.load_jpg(body)
        end
    )
end

update_texture()

local ui_update_texture = gui.Button(ref, "Update QQ", update_texture)
ui_update_texture:SetHeight(20)

local function clamp(val, min, max)
    return val > max and max or val < min and min or val
end

local globals_frametime = globals.FrameTime
local font = draw.new_font("verdana", 12)
local alpha = {health = 0, armor = 0}

local function havoc_vision_rpg()
    local lp = entities.GetLocalPlayer()

    if not lp then
        return
    end

    local fade = ((1.0 / 0.15) * globals_frametime()) * 30

    local x, y = ui_havoc_vision_rpg_drag:get()
    local x, y = x + 60, y + 60

    ui_havoc_vision_rpg_drag:drag(100, 100)

    local r, g, b, a = 34, 34, 34, 255

    draw.color(r, g, b, a)

    draw.rect(x - 90, y - 23, x - 45, y, "f")
    draw.rect(x + 50, y, x + 160, y + 20, "f")

    draw.gradient(x + 160, y, x + 190, y + 20, {r, g, b, a}, {r, g, b, 0}, true)
    draw.gradient(x - 115, y - 23, x - 90, y, {r, g, b, 0}, {r, g, b, a}, true)

    draw.color(255, 255, 255)
    draw.texture(qq_avatars_texture, x - 40, y - 40, x + 40, y + 40)

    local health = lp:GetHealth() or 0
    local health_r = (134 * health / 100) + (255 * (1 - health / 100))
    local health_g = (200 * health / 100) + (75 * (1 - health / 100))
    local health_b = (134 * health / 100) + (20 * (1 - health / 100))

    alpha.health = health ~= 100 and clamp(alpha.health - fade, health, 100) or clamp(alpha.health + fade, 0, health)

    draw.color(health_r, health_g, health_b, 255)
    draw.circle_outline(x, y, 58.5, 355, alpha.health * 0.01, 2, 8)

    draw.color(8, 120, 193, 200)
    draw.circle(x, y + 36, 12, "f", 2)

    draw.Color(r, g, b, a)
    draw.texture(
        draw.load_svg(
            [[<?xml version="1.0"?><svg width="250" height="250" viewBox="0 0 200 200"><circle cx="100" cy="100" r="80" stroke-width="30" stroke="#ffffff" fill="none"></circle></svg>]],
            0.5
        ),
        x - 60,
        y - 60,
        x + 60,
        y + 60
    )

    draw.rect(x + 40, y - 35, x + 185, y - 10, "f")
    draw.gradient(x + 185, y - 35, x + 215, y - 10, {r, g, b, a}, {r, g, b, 0}, true)

    local armor = lp:GetProp("m_ArmorValue") or 0
    alpha.armor = armor ~= 100 and clamp(alpha.armor - fade, armor, 100) or clamp(alpha.armor + fade, 0, armor)

    draw.color(80, 163, 248, 255)
    draw.circle_outline(x, y, 42, 90, alpha.armor * 0.01, 1, 8)

    local get_server_ip = engine.GetServerIP()
    local server = get_server_ip == "loopback" and "localhost" or get_server_ip:find("A") and "valve(mm)" or "unknown"
    local name = lp:GetName()
    local name = #name > 8 and name:match([[........]]) .. "..." or name

    draw.SetFont(font)

    draw.color(255, 255, 255)
    draw.text(x + 65, y - 27, "", server .. " ● Hello  " .. name)
    draw.text(x + 120, y + 5, "", " ● " .. lp:GetProp("m_iAccount") or 0)
    draw.text(x, y + 29, "cs", lp:GetTeamNumber() == 2 and "T" or "CT")

    draw.color(health_r, health_g, health_b)
    draw.text(x - 65, y - 16, "l", health .. " hp")

    draw.color(255, 198, 0)
    draw.text(x + 65, y + 5, "", "Adventurer")
    return true
end

callbacks.Register(
    "Draw",
    function()
        local rpg = ui_havoc_vision_rpg:GetValue() and havoc_vision_rpg()
        ui_havoc_vision_rpg_qq:SetInvisible(not rpg)
        ui_update_texture:SetInvisible(not rpg)
    end
)

# _images.load_

```lua
local images = require "images"

local load_image = images.load(http.Get("https://avatars.githubusercontent.com/qi-ux"))
callbacks.Register(
    "Draw",
    function()
        print(load_image.type)
        load_image:draw(0, 0)
    end
)
```

# _images.load_png_

```lua
local images = require "images"

local load_png = images.load_png(http.Get("https://raw.githubusercontent.com/qi-ux/aimware/main/lib/images/examples.png"))
callbacks.Register(
    "Draw",
    function()
        print(load_png.type)
        load_png:draw(0, 0)
    end
)
```

# _images.load_jpg_

```lua
local images = require "images"

local load_jpg = images.load(http.Get("https://avatars.githubusercontent.com/qi-ux"))
callbacks.Register(
    "Draw",
    function()
        print(load_jpg.type)
        load_jpg:draw(0, 0)
    end
)
```

# _images.load_svg_

```lua
local images = require "images"

local svg_code =
    [[
        <?xml version="1.0" encoding="utf-8"?>
        <svg version="1.1" <g id="g2601-7" transform="matrix(0.2412205,0.1258508,-0.1258508,0.2412205,198.50386,176.20132)">
            <path fill="#FFFFFF" id="path2430-7-16" d="M-906.7-252c-15.3,0-27.8,12.4-27.8,27.8l0,0
                            c0,15.3,12.4,27.8,27.8,27.8c15.3,0,27.8-12.4,27.8-27.8S-891.4-252-906.7-252L-906.7-252z M-906.7-246.5c12.3,0,22.2,10,22.2,22.2
                            l0,0c0,12.3-10,22.2-22.2,22.2s-22.2-10-22.2-22.2C-929-236.5-919-246.5-906.7-246.5L-906.7-246.5z" />
            <path fill="#FFFFFF" id="path2481-44" d="M-906.7-240.9c-9.2,0-16.7,7.5-16.7,16.7l0,0
                            c0,9.2,7.5,16.7,16.7,16.7c9.2,0,16.7-7.5,16.7-16.7S-897.5-240.9-906.7-240.9L-906.7-240.9z M-906.7-235.2c6.1,0,11,4.9,11,11l0,0
                            c0,6.1-4.9,11-11,11s-11-4.9-11-11C-917.7-230.3-912.8-235.2-906.7-235.2L-906.7-235.2z" />
            <path fill="#FFFFFF" id="path2463-7" d="M-905.1-224.2l10.3-6l18.9,1.6v8.7l-18.9,1.6L-905.1-224.2z
                            " />
            <path fill="#FFFFFF" id="path2463-5-3" d="M-906.7-222.6l6,10.3l-1.6,18.9h-8.7l-1.6-18.9
                            L-906.7-222.6z" />
            <path fill="#FFFFFF" id="path2463-5-5-18" d="M-908.4-224.2l-10.3,6l-18.9-1.6v-8.7l18.9-1.6
                            L-908.4-224.2z" />
            <path fill="#FFFFFF" id="path2463-5-5-1-7" d="M-906.7-225.8l-6-10.3l1.6-18.9h8.7l1.6,18.9
                            L-906.7-225.8z" />
            </g>
        </svg>
]]
local load_svg = images.load_svg(svg_code, 5)
callbacks.Register(
    "Draw",
    function()
        print(load_svg.type)
        load_svg:draw(0, 0)
    end
)
```

# _images.load_rgba_

```lua
local images = require "images"

local load_rgba = images.load_rgba(common.DecodeJPEG(http.Get("https://avatars.githubusercontent.com/qi-ux")))
callbacks.Register(
    "Draw",
    function()
        print(load_rgba.type)
        load_rgba:draw(0, 0)
    end
)
```

# _images.get_weapon_icon_

```lua
local images = require "images"

local weapon_icon = images.get_weapon_icon("awp", 1)
callbacks.Register(
    "Draw",
    function()
        print(weapon_icon.type)
        weapon_icon:draw(0, 0)
    end
)
```

# _images.get_weapon_icon_

```lua
local images = require "images"

local panorama_image = images.get_panorama_image("icons/ui/warning.svg", 3)
callbacks.Register(
    "Draw",
    function()
        print(panorama_image.type)
        panorama_image:draw(0, 0)
    end
)
```

# _images.get_steam_avatar_

```lua
local images = require "images"

local steam_avatar = images.get_steam_avatar("76561199046207774", "m")
callbacks.Register(
    "Draw",
    function()
        steam_avatar:draw(0, 0)
    end
)
```

# _[image](https://github.com/qi-ux/aimware/blob/main/lib/images/module.md):measure_

```lua
local images = require "images"

local weapon_icon = images.get_weapon_icon("awp")
callbacks.Register(
    "Draw",
    function()
        print(weapon_icon:measure())
        print(weapon_icon:measure(weapon_icon.width * 0.5))
        print(weapon_icon:measure(nil, weapon_icon.width * 0.5))
        print(weapon_icon:measure(weapon_icon.width * 0.5, weapon_icon.height * 0.5))
    end
)
```

# _[image](https://github.com/qi-ux/aimware/blob/main/lib/images/module.md):draw_

```lua
local images = require "images"

local steam_avatar = images.get_steam_avatar("76561199046207774", "+")
callbacks.Register(
    "Draw",
    function()
        steam_avatar:draw(0, 0, 100, 100, 255, 255, 255, 255, false)
    end
)
```

# _[table](https://github.com/qi-ux/aimware/blob/main/lib/images/table.md)_

```lua
local images = require "images"

local weapon_icon = images.get_weapon_icon("awp")
callbacks.Register(
    "Draw",
    function()
        print(
            weapon_icon.type,
            weapon_icon.width,
            weapon_icon.height,
            weapon_icon.scale,
            weapon_icon.rgba,
            weapon_icon.textures
        )
    end
)
```

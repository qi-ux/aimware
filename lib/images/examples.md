# _images.load_

```lua
local images = require "images"

local load_image = images.load(file.Read("images.png[, jpg, svg]"))
callbacks.Register(
    "Draw",
    function()
        load_image:draw(0, 0)
    end
)
```

# _images.load_png_

```lua
local images = require "images"

local load_png = images.load_png(file.Read(".png"))
callbacks.Register(
    "Draw",
    function()
        load_png:draw(0, 0)
    end
)
```

# _images.load_jpg_

```lua
local images = require "images"

local load_jpg = images.load_jpg(file.Read(".jpg"))
callbacks.Register(
    "Draw",
    function()
        load_jpg:draw(0, 0)
    end
)
```

# _images.load_svg_

```lua
local images = require "images"

local load_svg = images.load_svg(file.Read(".svg"))
callbacks.Register(
    "Draw",
    function()
        load_svg:draw(0, 0)
    end
)
```

# _images.load_rgba_

```lua
local images = require "images"

local load_rgba = images.load_rgba(common.RasterizeSVG(file.Read(".svg"), 2))
callbacks.Register(
    "Draw",
    function()
        load_rgba:draw(0, 0)
    end
)
```

# _images.get_weapon_icon_

```lua
local images = require "images"

local weapon_icon = images.get_weapon_icon("awp")
callbacks.Register(
    "Draw",
    function()
        weapon_icon:draw(0, 0)
    end
)
```

# _images.get_weapon_icon_

```lua
local images = require "images"

local panorama_image = images.get_panorama_image("icons/ui/warning.svg")
callbacks.Register(
    "Draw",
    function()
        panorama_image:draw(0, 0)
    end
)
```

# _images.get_steam_avatar_

```lua
local images = require "images"

local steam_avatar = images.get_steam_avatar("76561199046207774", 65)
callbacks.Register(
    "Draw",
    function()
        steam_avatar:draw(0, 0)
    end
)
```

# _[images](doc:YyqSLLXz):measure_

```lua
local images = require "images"

local weapon_icon = images.get_weapon_icon("awp")
callbacks.Register(
    "Draw",
    function()
        print(weapon_icon:measure())
        print(weapon_icon:measure(weapon_icon.width * 0.5))
        print(weapon_icon:measure(weapon_icon.width * 0.5, weapon_icon.height * 0.5))
    end
)
```

# _[images](doc:YyqSLLXz):draw_

```lua
local images = require "images"

local steam_avatar = images.get_steam_avatar("76561199046207774", 65)
callbacks.Register(
    "Draw",
    function()
        steam_avatar:draw(0, 0, 100, 100, 255, 255, 255, 255, false)
    end
)
```

# _[table](doc:5Egd1y0M)_

```lua
local images = require "images"

local weapon_icon = images.get_weapon_icon("awp")
callbacks.Register(
    "Draw",
    function()
        print(weapon_icon.type, weapon_icon.width, weapon_icon.height, weapon_icon.contents, weapon_icon.textures)
    end
)
```

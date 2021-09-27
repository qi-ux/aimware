# _images.load_

## _syntax_

_`images.load(contents, scale)`_

## _parameters_

| _name_     | _type_   | _optional_ | _description_                                |
| ---------- | -------- | ---------- | -------------------------------------------- |
| _contents_ | _string_ | _-_        | _`only supports png, jpg, svg format`_       |
| _scale_    | _number_ | _+_        | _`only svg scale modification is supported`_ |

_return: [table](https://github.com/qi-ux/aimware/blob/main/lib/images/table.md)_

---

# _images.load_png_

## _syntax_

_`images.load_png(contents)`_

## _parameters_

| _name_     | _type_   | _optional_ | _description_                |
| ---------- | -------- | ---------- | ---------------------------- |
| _contents_ | _string_ | _-_        | _`only supports png format`_ |

_return: [table](https://github.com/qi-ux/aimware/blob/main/lib/images/table.md)_

---

# _images.load_jpg_

## _syntax_

_`images.load_jpg(contents)`_

## _parameters_

| _name_     | _type_   | _optional_ | _description_                |
| ---------- | -------- | ---------- | ---------------------------- |
| _contents_ | _string_ | _-_        | _`only supports jpg format`_ |

_return: [table](https://github.com/qi-ux/aimware/blob/main/lib/images/table.md)_

---

# _images.load_svg_

## _syntax_

_`images.load_svg(contents, scale)`_

## _parameters_

| _name_     | _type_   | _optional_ | _description_                |
| ---------- | -------- | ---------- | ---------------------------- |
| _contents_ | _string_ | _-_        | _`only supports svg format`_ |
| _scale_    | _number_ | _+_        | _`svg scale`_                |

_return: [table](https://github.com/qi-ux/aimware/blob/main/lib/images/table.md)_

---

# _images.load_rgba_

## _syntax_

_`images.load_rgba(contents)`_

## _parameters_

| _name_     | _type_   | _optional_ | _description_               |
| ---------- | -------- | ---------- | --------------------------- |
| _contents_ | _string_ | _-_        | _`only supports rgba data`_ |

_return: [table](https://github.com/qi-ux/aimware/blob/main/lib/images/table.md)_

---

# _images.get_weapon_icon_

## _syntax_

_`images.get_weapon_icon(weapon, scale)`_

## _parameters_

| _name_   | _type_                | _optional_ | _description_                                                                           |
| -------- | --------------------- | ---------- | --------------------------------------------------------------------------------------- |
| _weapon_ | _table:string:number_ | _-_        | _`table:{console_name = weapon_name:string} or string:weapon_name or number:weapon_id`_ |
| _scale_  | _number_              | _+_        | _`icon scale`_                                                                          |

_return: [table](https://github.com/qi-ux/aimware/blob/main/lib/images/table.md)_

---

# _images.get_panorama_image_

## _syntax_

_`images.get_panorama_image(path, scale)`_

## _parameters_

| _name_  | _type_   | _optional_ | _description_                                |
| ------- | -------- | ---------- | -------------------------------------------- |
| _path_  | _string_ | _-_        | _`path to image`_                            |
| _scale_ | _number_ | _+_        | _`only svg scale modification is supported`_ |

_return: [table](https://github.com/qi-ux/aimware/blob/main/lib/images/table.md)_

---

# _images.get_steam_avatar_

## _syntax_

_`images.get_steam_avatar(steamid, scale)`_

## _parameters_

| _name_    | _type_          | _optional_ | _description_                              |
| --------- | --------------- | ---------- | ------------------------------------------ |
| _steamid_ | _number:string_ | _-_        | _`number:steamid 32 or string:steamid 64`_ |
| _scale_   | _string_        | _+_        | _`[- < m < +] the default is medium`_      |

_return: [table](https://github.com/qi-ux/aimware/blob/main/lib/images/table.md)_

---

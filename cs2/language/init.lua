xpcall(function()
    local db = {
        language = {},
        reference = {{}, {}, {}, {}, {}, {}, {}}
    }

    local default_language = "language/english.lua"
    table.insert(db.language, {
        name = "English",
        data = loadstring(file.Read(default_language))()
    })

    file.Enumerate(function(filename)
        if not filename:match("^language/.*%.lua$") or filename == default_language or filename == "language/init.lua" then return end

        table.insert(db.language, {
            name = filename:match("([^\\/]-%.lua)$"):sub(1, -5),
            data = loadstring(file.Read(filename))()
        })
    end)

    local menu_ref = gui.Reference("menu")
    local language_ref = gui.Combobox(gui.Reference("settings", "advanced", "ui"), "language", "Language", (function()
        local t = {}
        for _, v in ipairs(db.language) do table.insert(t, v.name) end
        return unpack(t)
    end)())

    language_ref:SetDescription("The language of the menu.")

    local function get_children(ref, level)
        if ref:GetName() ~= "" then table.insert(db.reference[level], {ref}) end
        for value in ref:Children() do get_children(value, level + 1) end
    end

    get_children(menu_ref, 0)

    local function translate(language)
        for k1, v1 in pairs(language) do
            for k2, v2 in pairs(db.reference[k1]) do
                if v1[k2] then
                    v2[1]:SetName(v1[k2][1])
                    if v1[k2][2] and type(v1[k2][2]) == "string" then
                        v2[1]:SetDescription(v1[k2][2])
                    elseif v1[k2][2] and type(v1[k2][2]) == "table" then
                        local temp = {}
                        for i = 1, #v1[k2][2] - 1 do temp[i] = v1[k2][2][i] end
                        v2[1]:SetOptions(unpack(temp))
                        local description = v1[k2][2][#v1[k2][2]]
                        v2[1]:SetDescription(description ~= "" and description or nil)
                    end
                end
            end
        end
    end

    local reference_t = {}
    local function set_translate(idx)
        local data = db.language[idx].data
        if not data then return end

        for k1, v1 in pairs(data) do
            for k2, v2 in pairs(db.reference[k1]) do
                if v1[k2] then
                    reference_t[v2[1]:GetName():lower()] = v1[k2][1]
                else
                    error("Please check for updates")
                end
            end
        end
        translate(data)
    end

    set_translate(1)

    do
        local old_language
        callbacks.Register("Draw", function()
            local language = language_ref:GetValue()
            if not language or language == old_language then return end

            set_translate(language + 1)
            old_language = language
        end)
    end

    do
        local gui_reference = gui.Reference
        gui.Reference = function(...)
            local temp = {}
            for k, v in pairs({...}) do temp[k] = reference_t[v:lower()] end
            return gui_reference(unpack(temp))
        end

        callbacks.Register("Unload", function()
            set_translate(1)
            gui.Reference = gui_reference
        end)
    end
end, function(message)
    print(message)
    UnloadScript(GetScriptName())
end)

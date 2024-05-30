xpcall(function()
    ---@format disable-next
    local absolute = (function()return function(a,b,c)if a==nil then return a end;local d=ffi.cast("uintptr_t",a)d=d+b;d=d+ffi.sizeof("int")+ffi.cast("int",ffi.cast("int*",d)[0])d=d+c;return d end end)()

    local fnFindHudElement = ffi.cast("void*(__fastcall*)(const char*)", mem.FindPattern("client.dll", "40 55 48 83 EC ?? 48 83 3D"))

    local CHudChatDelegate = fnFindHudElement "HudChatDelegate"
    local fnChatPrintf = ffi.cast("void*(__cdecl*)(void*, unsigned int, const char*, ...)", absolute(mem.FindPattern("client.dll", "E8 ?? ?? ?? ?? 49 8B 4E 20 BA ?? ?? ?? ??"), 1, 0))

    local function chatprintf(entindex, f, ...)
        fnChatPrintf(CHudChatDelegate, entindex, string.format(f, ...))
    end

    local function userid_to_entindex(userid)
        local playercontroller = entities.GetByIndex(userid + 1)
        if not playercontroller then return end
        local playerpawn = playercontroller:GetPropEntity "m_hPlayerPawn"
        if not playerpawn then return end
        return playerpawn:GetIndex()
    end

    local hitgroup_names = {"generic", "head", "chest", "stomach", "left arm", "right arm", "left leg", "right leg"}

    callbacks.Register("FireGameEvent", function(e)
        if not e or e:GetName() ~= "player_hurt" then return end

        local localplayer = client.GetLocalPlayerIndex()
        if not localplayer then return end

        local userid   = userid_to_entindex(e:GetInt "userid")
        local attacker = userid_to_entindex(e:GetInt "attacker")

        if userid == attacker then return end

        if attacker == localplayer then
            local ent = entities.GetByIndex(userid)

            chatprintf(-1,
                " \x08[\x07%s\x08] Hit %s's \x10%s\x08 for \x07%i\x08 (%i \x08remaining)",
                "aimware",
                ent:GetName(),
                hitgroup_names[e:GetInt "hitgroup" + 1] or "?",
                e:GetInt "dmg_health",
                e:GetInt "health"
            )
        end
    end)
end, print)

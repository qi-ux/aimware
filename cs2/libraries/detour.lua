local ffi = ffi or require "ffi"
local C = ffi.C

---@diagnostic disable
---@format disable-next
local create_interface = (function()ffi.cdef"void* GetModuleHandleA(const char*)"ffi.cdef"void* GetProcAddress(void*, const char*)"local a=ffi.typeof"void*(__cdecl*)(const char*, int*)"return function(b,c)local d=C.GetModuleHandleA(b)if d==nil then return nil end;local e=C.GetProcAddress(d,"CreateInterface")if e==nil then return nil end;local f=ffi.cast(a,e)(c,nil)if f==nil then return nil end;return f end end)()
---@format disable-next
local vtable_bind, vtable_thunk = (function()local a=(function()local b=ffi.typeof"void***"return function(c,d,e)return ffi.cast(e,ffi.cast(b,c)[0][d])end end)()local function f(c,d,e,...)local g=a(c,d,ffi.typeof(e,...))return function(...)return g(c,...)end end;local function h(d,e,...)e=ffi.typeof(e,...)return function(c,...)return a(c,d,e)(c,...)end end;return f,h end)()
---@format disable-next
local find_signature = (function()local a=setmetatable({},{__index=function(b,c)b[c]=ffi.typeof(c)return b[c]end})local function d(e)if ffi.cast(a["uint16_t*"],e)[0]~=0x5A4D then return 0 end;local f=ffi.cast(a["long*"],ffi.cast(a["uintptr_t"],e)+0x003c)[0]local g=ffi.cast(a["uintptr_t"],e)+f;if ffi.cast(a["unsigned long*"],g)[0]~=0x00004550 then return 0 end;return ffi.cast(a["unsigned long*"],g+0x0018+0x0038)[0]end;return function(h,i,j)i=i.."\0"if#i/3==0 or#i%3~=0 then return nil end;local e=C.GetModuleHandleA(h)if e==nil then return nil end;local k=d(e)if k==0 then return nil end;local l={}for m in string.gmatch(i:gsub("%?%?","00"),"(%x%x)")do local n=tonumber(m,16)if not n then return nil end;table.insert(l,n)end;local o=a["uint8_t*"](e)for p=0,k-#l-1 do local q=true;for r=1,#l do local n=l[r]if n~=0 and o[p+r-1]~=n then q=false;break end end;if q then return o+p+(j or 0)end end;return nil end end)()
---@diagnostic enable

ffi.cdef [[
    int VirtualProtect(void* lpAddress, uint64_t dwSize, unsigned long flNewProtect, unsigned long* lpflOldProtect);
]]

local PAGE_EXECUTE_READWRITE = 0x40

local M = {}

function M.new(ct, callback, address)
    local size = 12
    local org_bytes = ffi.new("uint8_t[?]", size)
    ffi.copy(ffi.cast("void*", org_bytes), ffi.cast("const void*", address), size)

    local fnptr = ffi.cast(ct, address)

    local hook_bytes = ffi.new("uint8_t[12]", {
        0x48, 0xB8,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0xFF, 0xE0
    })

    ffi.cast("int64_t*", hook_bytes + 2)[0] = ffi.cast("int64_t", ffi.cast("void*", ffi.cast(ct, callback)))

    local oldprotect = ffi.new "unsigned long[1]"
    return setmetatable({}, {
        __call = function(self, ...)
            self:remove()
            local res = fnptr(...)
            self:install()
            return res
        end,
        __index = {
            install = function(self)
                C.VirtualProtect(ffi.cast("void*", address), size, PAGE_EXECUTE_READWRITE, oldprotect)
                ffi.copy(ffi.cast("void*", address), ffi.cast("const void*", hook_bytes), size)
                C.VirtualProtect(ffi.cast("void*", address), size, oldprotect[0], oldprotect)
                return self
            end,
            remove = function(self)
                C.VirtualProtect(ffi.cast("void*", address), size, PAGE_EXECUTE_READWRITE, oldprotect)
                ffi.copy(ffi.cast("void*", address), ffi.cast("const void*", org_bytes), size)
                C.VirtualProtect(ffi.cast("void*", address), size, oldprotect[0], oldprotect)
                return self
            end
        }
    }):install()
end

return M

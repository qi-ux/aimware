local ffi=ffi;local a=ffi.C;if not pcall(ffi.sizeof,"FILE")then ffi.cdef[[
        bool CreateDirectoryA(const char*, const char*);

        typedef struct io
        {
            char* _ptr;
            int _cnt;
            char* _base;
            int flag;
            int _file;
            int _charbuf;
            int _bufsize;
            char* _tmpfname;
        } FILE;
        
        FILE* fopen(const char*, const char*);
        
        int fclose(FILE*);
        int fseek(FILE*, long, int);
        long ftell(FILE*);
        size_t fread(void*, size_t, size_t, FILE*);
        size_t fwrite(const void*, size_t, size_t, FILE*);
]]end;local function b(c)local d={}c:gsub("[^\\/]+",function(e)d[#d+1]=e end)local f=""local g={}for h,i in pairs(d)do g[h]=f~=""and a.CreateDirectoryA(f,nil)f=f..(h~=1 and(c:find("\\")and"\\"or"/")or"")..i end;return g[#g]end;function readfile(j)local k=a.fopen(j,"r")a.fseek(k,0,2)local l=a.ftell(k)a.fseek(k,0,0)if l>0 then local m=ffi.new("char[?]",l+1)a.fread(m,l,1,k)local n=ffi.string(m)a.fclose(k)return n end end;function writefile(j,m)b(j)local k=a.fopen(j,"wb")local o=a.fwrite(m,#m,1,k)==1;a.fclose(k)return o end

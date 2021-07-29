local ffi=ffi;local a=ffi.C;if not pcall(ffi.sizeof,"FILE")then ffi.cdef[[
		bool CreateDirectoryA(const char*, const char*);
		
		typedef struct io
		{
			char* _ptr;
			int _cnt;
			char* _base;
			int _flag;
			int _file;
			int _charbuf;
			int _bufsize;
			char* _tmpfname;
		} FILE;
		
		FILE* fopen(const char*, const char*);
		int fclose(FILE*);
		int ftell(FILE*);
		int fseek(FILE*, int, int);
		void rewind(FILE*);
		size_t fwrite(const void*, size_t, size_t, FILE*);
		size_t fread(void*, size_t, size_t, FILE*);
]]end;function readfile(b)local c=a.fopen(b,"rb")if c==nil then return nil,b..": No such file or directory"end;a.fseek(c,0,2)local d=a.ftell(c)local e=ffi.new("char[?]",d+1)if d>0 then a.rewind(c)a.fread(e,d,1,c)end;a.fclose(c)return ffi.string(e,d)end;function writefile(b,e)local f={}b:gsub("[^\\/]+",function(g)f[#f+1]=g end)local h=""local i={}for j,k in pairs(f)do i[j]=h~=""and a.CreateDirectoryA(h,nil)h=h..(j~=1 and(b:find("\\")and"\\"or"/")or"")..k end;local c=a.fopen(b,"wb")if c==nil then return nil end;a.fseek(c,0,2)a.fwrite(e,#e,1,c)a.fclose(c)return true end;return true

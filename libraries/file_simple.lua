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
]]end;function readfile(b)local c=""local d=a.fopen(b,"r")if d==nil then return nil,b..": No such file or directory"end;a.fseek(d,0,2)local e=a.ftell(d)local f=ffi.new("char[?]",e+1)if e>0 then a.rewind(d)a.fread(f,ffi.sizeof(f),e,d)end;a.fclose(d)return ffi.string(f,e)end;function writefile(b,f)local g={}b:gsub("[^\\/]+",function(h)g[#g+1]=h end)local i=""local j={}for k,l in pairs(g)do j[k]=i~=""and a.CreateDirectoryA(i,nil)i=i..(k~=1 and(b:find("\\")and"\\"or"/")or"")..l end;local d=a.fopen(b,"wb")if d==nil then return nil end;a.fseek(d,0,2)a.fwrite(f,#f,1,d)a.fclose(d)return true end;return true
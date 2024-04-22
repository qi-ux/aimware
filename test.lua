-- local function readfile(filename)
-- 	local fp = io.open(filename, "r")
-- 	if fp == nil then return end
-- 	local result = fp:read("*a")
-- 	fp:close()
-- 	return result
-- end

local ffi = ffi or require "ffi"

---@format disable-next
local md5 = (function()local a={}local b,c,d,e,f=string.char,string.byte,string.format,string.rep,string.sub;local g,h,i,j,k,l=bit.bor,bit.band,bit.bnot,bit.bxor,bit.rshift,bit.lshift;local function m(n)local o=function(p)return b(h(k(n,p),255))end;return o(0)..o(8)..o(16)..o(24)end;local function q(p)local r=0;for n=1,#p do r=r*256+c(p,n)end;return r end;local function s(p)local r=0;for n=#p,1,-1 do r=r*256+c(p,n)end;return r end;local function t(p,...)local u,v=1,{}local w={...}for n=1,#w do table.insert(v,s(f(p,u,u+w[n]-1)))u=u+w[n]end;return v end;local x=function(y)return q(m(y))end;local z={0xd76aa478,0xe8c7b756,0x242070db,0xc1bdceee,0xf57c0faf,0x4787c62a,0xa8304613,0xfd469501,0x698098d8,0x8b44f7af,0xffff5bb1,0x895cd7be,0x6b901122,0xfd987193,0xa679438e,0x49b40821,0xf61e2562,0xc040b340,0x265e5a51,0xe9b6c7aa,0xd62f105d,0x02441453,0xd8a1e681,0xe7d3fbc8,0x21e1cde6,0xc33707d6,0xf4d50d87,0x455a14ed,0xa9e3e905,0xfcefa3f8,0x676f02d9,0x8d2a4c8a,0xfffa3942,0x8771f681,0x6d9d6122,0xfde5380c,0xa4beea44,0x4bdecfa9,0xf6bb4b60,0xbebfbc70,0x289b7ec6,0xeaa127fa,0xd4ef3085,0x04881d05,0xd9d4d039,0xe6db99e5,0x1fa27cf8,0xc4ac5665,0xf4292244,0x432aff97,0xab9423a7,0xfc93a039,0x655b59c3,0x8f0ccc92,0xffeff47d,0x85845dd1,0x6fa87e4f,0xfe2ce6e0,0xa3014314,0x4e0811a1,0xf7537e82,0xbd3af235,0x2ad7d2bb,0xeb86d391,0x67452301,0xefcdab89,0x98badcfe,0x10325476}local o=function(A,B,C)return g(h(A,B),h(-A-1,C))end;local D=function(A,B,C)return g(h(A,C),h(B,-C-1))end;local E=function(A,B,C)return j(A,j(B,C))end;local n=function(A,B,C)return j(B,g(A,-C-1))end;local C=function(F,G,H,I,J,A,p,K)G=h(G+F(H,I,J)+A+K,0xFFFFFFFF)return g(l(h(G,k(0xFFFFFFFF,p)),p),k(G,32-p))+H end;local function L(M,N,O,P,Q)local G,H,I,J=M,N,O,P;local R=z;G=C(o,G,H,I,J,Q[0],7,R[1])J=C(o,J,G,H,I,Q[1],12,R[2])I=C(o,I,J,G,H,Q[2],17,R[3])H=C(o,H,I,J,G,Q[3],22,R[4])G=C(o,G,H,I,J,Q[4],7,R[5])J=C(o,J,G,H,I,Q[5],12,R[6])I=C(o,I,J,G,H,Q[6],17,R[7])H=C(o,H,I,J,G,Q[7],22,R[8])G=C(o,G,H,I,J,Q[8],7,R[9])J=C(o,J,G,H,I,Q[9],12,R[10])I=C(o,I,J,G,H,Q[10],17,R[11])H=C(o,H,I,J,G,Q[11],22,R[12])G=C(o,G,H,I,J,Q[12],7,R[13])J=C(o,J,G,H,I,Q[13],12,R[14])I=C(o,I,J,G,H,Q[14],17,R[15])H=C(o,H,I,J,G,Q[15],22,R[16])G=C(D,G,H,I,J,Q[1],5,R[17])J=C(D,J,G,H,I,Q[6],9,R[18])I=C(D,I,J,G,H,Q[11],14,R[19])H=C(D,H,I,J,G,Q[0],20,R[20])G=C(D,G,H,I,J,Q[5],5,R[21])J=C(D,J,G,H,I,Q[10],9,R[22])I=C(D,I,J,G,H,Q[15],14,R[23])H=C(D,H,I,J,G,Q[4],20,R[24])G=C(D,G,H,I,J,Q[9],5,R[25])J=C(D,J,G,H,I,Q[14],9,R[26])I=C(D,I,J,G,H,Q[3],14,R[27])H=C(D,H,I,J,G,Q[8],20,R[28])G=C(D,G,H,I,J,Q[13],5,R[29])J=C(D,J,G,H,I,Q[2],9,R[30])I=C(D,I,J,G,H,Q[7],14,R[31])H=C(D,H,I,J,G,Q[12],20,R[32])G=C(E,G,H,I,J,Q[5],4,R[33])J=C(E,J,G,H,I,Q[8],11,R[34])I=C(E,I,J,G,H,Q[11],16,R[35])H=C(E,H,I,J,G,Q[14],23,R[36])G=C(E,G,H,I,J,Q[1],4,R[37])J=C(E,J,G,H,I,Q[4],11,R[38])I=C(E,I,J,G,H,Q[7],16,R[39])H=C(E,H,I,J,G,Q[10],23,R[40])G=C(E,G,H,I,J,Q[13],4,R[41])J=C(E,J,G,H,I,Q[0],11,R[42])I=C(E,I,J,G,H,Q[3],16,R[43])H=C(E,H,I,J,G,Q[6],23,R[44])G=C(E,G,H,I,J,Q[9],4,R[45])J=C(E,J,G,H,I,Q[12],11,R[46])I=C(E,I,J,G,H,Q[15],16,R[47])H=C(E,H,I,J,G,Q[2],23,R[48])G=C(n,G,H,I,J,Q[0],6,R[49])J=C(n,J,G,H,I,Q[7],10,R[50])I=C(n,I,J,G,H,Q[14],15,R[51])H=C(n,H,I,J,G,Q[5],21,R[52])G=C(n,G,H,I,J,Q[12],6,R[53])J=C(n,J,G,H,I,Q[3],10,R[54])I=C(n,I,J,G,H,Q[10],15,R[55])H=C(n,H,I,J,G,Q[1],21,R[56])G=C(n,G,H,I,J,Q[8],6,R[57])J=C(n,J,G,H,I,Q[15],10,R[58])I=C(n,I,J,G,H,Q[6],15,R[59])H=C(n,H,I,J,G,Q[13],21,R[60])G=C(n,G,H,I,J,Q[4],6,R[61])J=C(n,J,G,H,I,Q[11],10,R[62])I=C(n,I,J,G,H,Q[2],15,R[63])H=C(n,H,I,J,G,Q[9],21,R[64])return h(M+G,0xFFFFFFFF),h(N+H,0xFFFFFFFF),h(O+I,0xFFFFFFFF),h(P+J,0xFFFFFFFF)end;local function S(self,p)self.pos=self.pos+#p;p=self.buf..p;for T=1,#p-63,64 do local Q=t(f(p,T,T+63),4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4)assert(#Q==16)Q[0]=table.remove(Q,1)self.a,self.b,self.c,self.d=L(self.a,self.b,self.c,self.d,Q)end;self.buf=f(p,math.floor(#p/64)*64+1,#p)return self end;local function U(self)local V=self.pos;local W=56-V%64;if V%64>56 then W=W+64 end;if W==0 then W=64 end;local p=b(128)..e(b(0),W-1)..m(h(8*V,0xFFFFFFFF))..m(math.floor(V/0x20000000))S(self,p)assert(self.pos%64==0)return m(self.a)..m(self.b)..m(self.c)..m(self.d)end;function a.new()return{a=z[65],b=z[66],c=z[67],d=z[68],pos=0,buf='',update=S,finish=U}end;function a.tohex(p)return d("%08x%08x%08x%08x",q(f(p,1,4)),q(f(p,5,8)),q(f(p,9,12)),q(f(p,13,16)))end;function a.sum(p)return a.new():update(p):finish()end;function a.sumhexa(p)return a.tohex(a.sum(p))end;return a end)()
---@format disable-next
local json = (function()local a={_version="0.1.2"}local b;local c={["\\"]="\\",["\""]="\"",["\b"]="b",["\f"]="f",["\n"]="n",["\r"]="r",["\t"]="t"}local d={["/"]="/"}for e,f in pairs(c)do d[f]=e end;local function g(h)return"\\"..(c[h]or string.format("u%04x",h:byte()))end;local function i(j)return"null"end;local function k(j,l)local m={}l=l or{}if l[j]then error("circular reference")end;l[j]=true;if rawget(j,1)~=nil or next(j)==nil then local n=0;for e in pairs(j)do if type(e)~="number"then error("invalid table: mixed or invalid key types")end;n=n+1 end;if n~=#j then error("invalid table: sparse array")end;for o,f in ipairs(j)do table.insert(m,b(f,l))end;l[j]=nil;return"["..table.concat(m,",").."]"else for e,f in pairs(j)do if type(e)~="string"then error("invalid table: mixed or invalid key types")end;table.insert(m,b(e,l)..":"..b(f,l))end;l[j]=nil;return"{"..table.concat(m,",").."}"end end;local function p(j)return'"'..j:gsub('[%z\1-\31\\"]',g)..'"'end;local function q(j)if j~=j or j<=-math.huge or j>=math.huge then error("unexpected number value '"..tostring(j).."'")end;return string.format("%.14g",j)end;local r={["nil"]=i,["table"]=k,["string"]=p,["number"]=q,["boolean"]=tostring}b=function(j,l)local s=type(j)local t=r[s]if t then return t(j,l)end;error("unexpected type '"..s.."'")end;function a.encode(j)return b(j)end;local u;local function v(...)local m={}for o=1,select("#",...)do m[select(o,...)]=true end;return m end;local w=v(" ","\t","\r","\n")local x=v(" ","\t","\r","\n","]","}",",")local y=v("\\","/",'"',"b","f","n","r","t","u")local z=v("true","false","null")local A={["true"]=true,["false"]=false,["null"]=nil}local function B(C,D,E,F)for o=D,#C do if E[C:sub(o,o)]~=F then return o end end;return#C+1 end;local function G(C,D,H)local I=1;local J=1;for o=1,D-1 do J=J+1;if C:sub(o,o)=="\n"then I=I+1;J=1 end end;error(string.format("%s at line %d col %d",H,I,J))end;local function K(n)local t=math.floor;if n<=0x7f then return string.char(n)elseif n<=0x7ff then return string.char(t(n/64)+192,n%64+128)elseif n<=0xffff then return string.char(t(n/4096)+224,t(n%4096/64)+128,n%64+128)elseif n<=0x10ffff then return string.char(t(n/262144)+240,t(n%262144/4096)+128,t(n%4096/64)+128,n%64+128)end;error(string.format("invalid unicode codepoint '%x'",n))end;local function L(M)local N=tonumber(M:sub(1,4),16)local O=tonumber(M:sub(7,10),16)if O then return K((N-0xd800)*0x400+O-0xdc00+0x10000)else return K(N)end end;local function P(C,o)local m=""local Q=o+1;local e=Q;while Q<=#C do local R=C:byte(Q)if R<32 then G(C,Q,"control character in string")elseif R==92 then m=m..C:sub(e,Q-1)Q=Q+1;local h=C:sub(Q,Q)if h=="u"then local S=C:match("^[dD][89aAbB]%x%x\\u%x%x%x%x",Q+1)or C:match("^%x%x%x%x",Q+1)or G(C,Q-1,"invalid unicode escape in string")m=m..L(S)Q=Q+#S else if not y[h]then G(C,Q-1,"invalid escape char '"..h.."' in string")end;m=m..d[h]end;e=Q+1 elseif R==34 then m=m..C:sub(e,Q-1)return m,Q+1 end;Q=Q+1 end;G(C,o,"expected closing quote for string")end;local function T(C,o)local R=B(C,o,x)local M=C:sub(o,R-1)local n=tonumber(M)if not n then G(C,o,"invalid number '"..M.."'")end;return n,R end;local function U(C,o)local R=B(C,o,x)local V=C:sub(o,R-1)if not z[V]then G(C,o,"invalid literal '"..V.."'")end;return A[V],R end;local function W(C,o)local m={}local n=1;o=o+1;while 1 do local R;o=B(C,o,w,true)if C:sub(o,o)=="]"then o=o+1;break end;R,o=u(C,o)m[n]=R;n=n+1;o=B(C,o,w,true)local X=C:sub(o,o)o=o+1;if X=="]"then break end;if X~=","then G(C,o,"expected ']' or ','")end end;return m,o end;local function Y(C,o)local m={}o=o+1;while 1 do local Z,j;o=B(C,o,w,true)if C:sub(o,o)=="}"then o=o+1;break end;if C:sub(o,o)~='"'then G(C,o,"expected string for key")end;Z,o=u(C,o)o=B(C,o,w,true)if C:sub(o,o)~=":"then G(C,o,"expected ':' after key")end;o=B(C,o+1,w,true)j,o=u(C,o)m[Z]=j;o=B(C,o,w,true)local X=C:sub(o,o)o=o+1;if X=="}"then break end;if X~=","then G(C,o,"expected '}' or ','")end end;return m,o end;local _={['"']=P,["0"]=T,["1"]=T,["2"]=T,["3"]=T,["4"]=T,["5"]=T,["6"]=T,["7"]=T,["8"]=T,["9"]=T,["-"]=T,["t"]=U,["f"]=U,["n"]=U,["["]=W,["{"]=Y}u=function(C,D)local X=C:sub(D,D)local t=_[X]if t then return t(C,D)end;G(C,D,"unexpected character '"..X.."'")end;function a.decode(C)if type(C)~="string"then error("expected argument of type string, got "..type(C))end;local m,D=u(C,B(C,1,w,true))D=B(C,D,w,true)if D<=#C then G(C,D,"trailing garbage")end;return m end;return a end)()

local data = {
	version = "0.1",
	hwid = json.decode(http.Get("cloud/data.json"))
}

xpcall(function() error("") end, function(msg)
	local ok = false

	for _, value in ipairs(data.hwid) do
		if md5.sumhexa(value) == msg:match("(%x+)") then
			ok = true
			break
		end
	end

	if not ok then
		ffi.cast("uintptr_t*", 0)[0] = 0
	end
end)

print("ok")

return data.version

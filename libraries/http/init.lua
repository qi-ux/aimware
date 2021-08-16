local a = require "ffi"
local b = require "base64"
local assert, pcall, xpcall, error, setmetatable, tostring, tonumber, type, pairs, ipairs = assert, pcall, xpcall, error, setmetatable, tostring, tonumber, type, pairs, ipairs
local c = string.format
local d, e, f, g, h, i = a.typeof, a.sizeof, a.cast, a.cdef, a.string, a.gc
local j, k, l = string.lower, string.len, string.find
local m = b.encode
local n, o, p
do
	if not pcall(a.sizeof, "SteamAPICall_t") then
		g(
			[[
			typedef uint64_t SteamAPICall_t;

			struct SteamAPI_callback_base_vtbl {
				void(__thiscall *run1)(struct SteamAPI_callback_base *, void *, bool, uint64_t);
				void(__thiscall *run2)(struct SteamAPI_callback_base *, void *);
				int(__thiscall *get_size)(struct SteamAPI_callback_base *);
			};

			struct SteamAPI_callback_base {
				struct SteamAPI_callback_base_vtbl *vtbl;
				uint8_t flags;
				int id;
				uint64_t api_call_handle;
				struct SteamAPI_callback_base_vtbl vtbl_storage[1];
			};
		]]
		)
	end
	local q = {[-1] = "No failure", [0] = "Steam gone", [1] = "Network failure", [2] = "Invalid handle", [3] = "Mismatched callback"}
	local r, s
	local t, u
	local v
	local w = d("struct SteamAPI_callback_base")
	local x = e(w)
	local y = d("struct SteamAPI_callback_base[1]")
	local z = d("struct SteamAPI_callback_base*")
	local A = d("uintptr_t")
	local B = {}
	local C = {}
	local D = {}
	local function E(F)
		return tostring(tonumber(f(A, F)))
	end
	local function G(self, H, I)
		if I then
			I = q[v(self.api_call_handle)] or "Unknown error"
		end
		self.api_call_handle = 0
		xpcall(
			function()
				local J = E(self)
				local K = B[J]
				if K ~= nil then
					xpcall(K, print, H, I)
				end
				if C[J] ~= nil then
					B[J] = nil
					C[J] = nil
				end
			end,
			print
		)
	end
	local function L(self, H, I, M)
		if M == self.api_call_handle then
			G(self, H, I)
		end
	end
	local function N(self, H)
		G(self, H, false)
	end
	local function O(self)
		return x
	end
	local function P(self)
		if self.api_call_handle ~= 0 then
			s(self, self.api_call_handle)
			self.api_call_handle = 0
			local J = E(self)
			B[J] = nil
			C[J] = nil
		end
	end
	pcall(a.metatype, w, {__gc = P, __index = {cancel = P}})
	local Q = f("void(__thiscall *)(struct SteamAPI_callback_base *, void *, bool, uint64_t)", L)
	local R = f("void(__thiscall *)(struct SteamAPI_callback_base *, void *)", N)
	local S = f("int(__thiscall *)(struct SteamAPI_callback_base *)", O)
	function n(M, K, T)
		assert(M ~= 0)
		local U = y()
		local V = f(z, U)
		V.vtbl_storage[0].run1 = Q
		V.vtbl_storage[0].run2 = R
		V.vtbl_storage[0].get_size = S
		V.vtbl = V.vtbl_storage
		V.api_call_handle = M
		V.id = T
		local J = E(V)
		B[J] = K
		C[J] = U
		r(V, M)
		return V
	end
	function o(T, K)
		assert(D[T] == nil)
		local U = y()
		local V = f(z, U)
		V.vtbl_storage[0].run1 = Q
		V.vtbl_storage[0].run2 = R
		V.vtbl_storage[0].get_size = S
		V.vtbl = V.vtbl_storage
		V.api_call_handle = 0
		V.id = T
		local J = E(V)
		B[J] = K
		D[T] = U
		t(V, T)
	end
	local function W(X, Y, Z, _, a0)
		local a1 = mem.FindPattern(X, Y) or error("signature not found", 2)
		local a2 = f("uintptr_t", a1)
		if _ ~= nil and _ ~= 0 then
			a2 = a2 + _
		end
		if a0 ~= nil then
			for a3 = 1, a0 do
				a2 = f("uintptr_t*", a2)[0]
				if a2 == nil then
					return error("signature not found")
				end
			end
		end
		return f(Z, a2)
	end
	local function a4(V, a5, type)
		return f(type, f("void***", V)[0][a5])
	end
	r = W("steam_api.dll", "55 8B EC 83 3D ?? ?? ?? ?? ?? 7E 0D 68 ?? ?? ?? ?? FF 15 ?? ?? ?? ?? 5D C3 FF 75 10", "void(__cdecl*)(struct SteamAPI_callback_base *, uint64_t)")
	s = W("steam_api.dll", "55 8B EC FF 75 10 FF 75 0C", "void(__cdecl*)(struct SteamAPI_callback_base *, uint64_t)")
	t = W("steam_api.dll", "55 8B EC 83 3D ?? ?? ?? ?? ?? 7E 0D 68 ?? ?? ?? ?? FF 15 ?? ?? ?? ?? 5D C3 C7 05", "void(__cdecl*)(struct SteamAPI_callback_base *, int)")
	u = W("steam_api.dll", "55 8B EC 83 EC 08 80 3D", "void(__cdecl*)(struct SteamAPI_callback_base *)")
	p = W("client.dll", "B9 ?? ?? ?? ?? E8 ?? ?? ?? ?? 83 3D ?? ?? ?? ?? ?? 0F 84", "uintptr_t", 1, 1)
	local a6 = f("uintptr_t*", p)[3]
	local a7 = a4(a6, 12, "int(__thiscall*)(void*, SteamAPICall_t)")
	function v(a8)
		return a7(a6, a8)
	end
	gui.Command("lua.run callbacks.Register('Unload', function() for J, a9 in pairs(C) do local V = f(z, a9) P(V) end for J, a9 in pairs(D) do local V = f(z, a9) u(V) end end)")

end
if not pcall(e, "http_HTTPRequestHandle") then
	g(
		[[
		typedef uint32_t http_HTTPRequestHandle;
		typedef uint32_t http_HTTPCookieContainerHandle;

		enum http_EHTTPMethod {
			k_EHTTPMethodInvalid,
			k_EHTTPMethodGET,
			k_EHTTPMethodHEAD,
			k_EHTTPMethodPOST,
			k_EHTTPMethodPUT,
			k_EHTTPMethodDELETE,
			k_EHTTPMethodOPTIONS,
			k_EHTTPMethodPATCH,
		};

		struct http_ISteamHTTPVtbl {
			http_HTTPRequestHandle(__thiscall *CreateHTTPRequest)(uintptr_t, enum http_EHTTPMethod, const char *);
			bool(__thiscall *SetHTTPRequestContextValue)(uintptr_t, http_HTTPRequestHandle, uint64_t);
			bool(__thiscall *SetHTTPRequestNetworkActivityTimeout)(uintptr_t, http_HTTPRequestHandle, uint32_t);
			bool(__thiscall *SetHTTPRequestHeaderValue)(uintptr_t, http_HTTPRequestHandle, const char *, const char *);
			bool(__thiscall *SetHTTPRequestGetOrPostParameter)(uintptr_t, http_HTTPRequestHandle, const char *, const char *);
			bool(__thiscall *SendHTTPRequest)(uintptr_t, http_HTTPRequestHandle, SteamAPICall_t *);
			bool(__thiscall *SendHTTPRequestAndStreamResponse)(uintptr_t, http_HTTPRequestHandle, SteamAPICall_t *);
			bool(__thiscall *DeferHTTPRequest)(uintptr_t, http_HTTPRequestHandle);
			bool(__thiscall *PrioritizeHTTPRequest)(uintptr_t, http_HTTPRequestHandle);
			bool(__thiscall *GetHTTPResponseHeaderSize)(uintptr_t, http_HTTPRequestHandle, const char *, uint32_t *);
			bool(__thiscall *GetHTTPResponseHeaderValue)(uintptr_t, http_HTTPRequestHandle, const char *, uint8_t *, uint32_t);
			bool(__thiscall *GetHTTPResponseBodySize)(uintptr_t, http_HTTPRequestHandle, uint32_t *);
			bool(__thiscall *GetHTTPResponseBodyData)(uintptr_t, http_HTTPRequestHandle, uint8_t *, uint32_t);
			bool(__thiscall *GetHTTPStreamingResponseBodyData)(uintptr_t, http_HTTPRequestHandle, uint32_t, uint8_t *, uint32_t);
			bool(__thiscall *ReleaseHTTPRequest)(uintptr_t, http_HTTPRequestHandle);
			bool(__thiscall *GetHTTPDownloadProgressPct)(uintptr_t, http_HTTPRequestHandle, float *);
			bool(__thiscall *SetHTTPRequestRawPostBody)(uintptr_t, http_HTTPRequestHandle, const char *, uint8_t *, uint32_t);
			http_HTTPCookieContainerHandle(__thiscall *CreateCookieContainer)(uintptr_t, bool);
			bool(__thiscall *ReleaseCookieContainer)(uintptr_t, http_HTTPCookieContainerHandle);
			bool(__thiscall *SetCookie)(uintptr_t, http_HTTPCookieContainerHandle, const char *, const char *, const char *);
			bool(__thiscall *SetHTTPRequestCookieContainer)(uintptr_t, http_HTTPRequestHandle, http_HTTPCookieContainerHandle);
			bool(__thiscall *SetHTTPRequestUserAgentInfo)(uintptr_t, http_HTTPRequestHandle, const char *);
			bool(__thiscall *SetHTTPRequestRequiresVerifiedCertificate)(uintptr_t, http_HTTPRequestHandle, bool);
			bool(__thiscall *SetHTTPRequestAbsoluteTimeoutMS)(uintptr_t, http_HTTPRequestHandle, uint32_t);
			bool(__thiscall *GetHTTPRequestWasTimedOut)(uintptr_t, http_HTTPRequestHandle, bool *pbWasTimedOut);
		};
	]]
	)
end
local aa = {
	get = a.C.k_EHTTPMethodGET,
	head = a.C.k_EHTTPMethodHEAD,
	post = a.C.k_EHTTPMethodPOST,
	put = a.C.k_EHTTPMethodPUT,
	delete = a.C.k_EHTTPMethodDELETE,
	options = a.C.k_EHTTPMethodOPTIONS,
	patch = a.C.k_EHTTPMethodPATCH
}
local ab = {
	[100] = "Continue",
	[101] = "Switching Protocols",
	[102] = "Processing",
	[200] = "OK",
	[201] = "Created",
	[202] = "Accepted",
	[203] = "Non-Authoritative Information",
	[204] = "No Content",
	[205] = "Reset Content",
	[206] = "Partial Content",
	[207] = "Multi-Status",
	[208] = "Already Reported",
	[250] = "Low on Storage Space",
	[226] = "IM Used",
	[300] = "Multiple Choices",
	[301] = "Moved Permanently",
	[302] = "Found",
	[303] = "See Other",
	[304] = "Not Modified",
	[305] = "Use Proxy",
	[306] = "Switch Proxy",
	[307] = "Temporary Redirect",
	[308] = "Permanent Redirect",
	[400] = "Bad Request",
	[401] = "Unauthorized",
	[402] = "Payment Required",
	[403] = "Forbidden",
	[404] = "Not Found",
	[405] = "Method Not Allowed",
	[406] = "Not Acceptable",
	[407] = "Proxy Authentication Required",
	[408] = "Request Timeout",
	[409] = "Conflict",
	[410] = "Gone",
	[411] = "Length Required",
	[412] = "Precondition Failed",
	[413] = "Request Entity Too Large",
	[414] = "Request-URI Too Long",
	[415] = "Unsupported Media Type",
	[416] = "Requested Range Not Satisfiable",
	[417] = "Expectation Failed",
	[418] = "I'm a teapot",
	[420] = "Enhance Your Calm",
	[422] = "Unprocessable Entity",
	[423] = "Locked",
	[424] = "Failed Dependency",
	[424] = "Method Failure",
	[425] = "Unordered Collection",
	[426] = "Upgrade Required",
	[428] = "Precondition Required",
	[429] = "Too Many Requests",
	[431] = "Request Header Fields Too Large",
	[444] = "No Response",
	[449] = "Retry With",
	[450] = "Blocked by Windows Parental Controls",
	[451] = "Parameter Not Understood",
	[451] = "Unavailable For Legal Reasons",
	[451] = "Redirect",
	[452] = "Conference Not Found",
	[453] = "Not Enough Bandwidth",
	[454] = "Session Not Found",
	[455] = "Method Not Valid in This State",
	[456] = "Header Field Not Valid for Resource",
	[457] = "Invalid Range",
	[458] = "Parameter Is Read-Only",
	[459] = "Aggregate Operation Not Allowed",
	[460] = "Only Aggregate Operation Allowed",
	[461] = "Unsupported Transport",
	[462] = "Destination Unreachable",
	[494] = "Request Header Too Large",
	[495] = "Cert Error",
	[496] = "No Cert",
	[497] = "HTTP to HTTPS",
	[499] = "Client Closed Request",
	[500] = "Internal Server Error",
	[501] = "Not Implemented",
	[502] = "Bad Gateway",
	[503] = "Service Unavailable",
	[504] = "Gateway Timeout",
	[505] = "HTTP Version Not Supported",
	[506] = "Variant Also Negotiates",
	[507] = "Insufficient Storage",
	[508] = "Loop Detected",
	[509] = "Bandwidth Limit Exceeded",
	[510] = "Not Extended",
	[511] = "Network Authentication Required",
	[551] = "Option not supported",
	[598] = "Network read timeout error",
	[599] = "Network connect timeout error"
}
local ac = {"params", "body", "json"}
local ad = 2101
local ae = 2102
local af = 2103
local function ag()
	local ah = f("uintptr_t*", p)[12]
	if ah == 0 or ah == nil then
		return error("find_isteamhttp failed")
	end
	local ai = f("struct http_ISteamHTTPVtbl**", ah)[0]
	if ai == 0 or ai == nil then
		return error("find_isteamhttp failed")
	end
	return ah, ai
end
local function aj(ak, al)
	return function(...)
		return ak(al, ...)
	end
end
local am = d([[
struct {
	http_HTTPRequestHandle m_hRequest;
	uint64_t m_ulContextValue;
	bool m_bRequestSuccessful;
	int m_eStatusCode;
	uint32_t m_unBodySize;
} *
]])
local an = d([[
struct {
	http_HTTPRequestHandle m_hRequest;
	uint64_t m_ulContextValue;
} *
]])
local ao = d([[
struct {
	http_HTTPRequestHandle m_hRequest;
	uint64_t m_ulContextValue;
	uint32_t m_cOffset;
	uint32_t m_cBytesReceived;
} *
]])
local ap = d([[
struct {
	http_HTTPCookieContainerHandle m_hCookieContainer;
}
]])
local aq = d("SteamAPICall_t[1]")
local ar = d("const char[?]")
local as = d("uint8_t[?]")
local at = d("unsigned int[?]")
local au = d("bool[1]")
local av = d("float[1]")
local aw, ax = ag()
local ay = aj(ax.CreateHTTPRequest, aw)
local az = aj(ax.SetHTTPRequestContextValue, aw)
local aA = aj(ax.SetHTTPRequestNetworkActivityTimeout, aw)
local aB = aj(ax.SetHTTPRequestHeaderValue, aw)
local aC = aj(ax.SetHTTPRequestGetOrPostParameter, aw)
local aD = aj(ax.SendHTTPRequest, aw)
local aE = aj(ax.SendHTTPRequestAndStreamResponse, aw)
local aF = aj(ax.DeferHTTPRequest, aw)
local aG = aj(ax.PrioritizeHTTPRequest, aw)
local aH = aj(ax.GetHTTPResponseHeaderSize, aw)
local aI = aj(ax.GetHTTPResponseHeaderValue, aw)
local aJ = aj(ax.GetHTTPResponseBodySize, aw)
local aK = aj(ax.GetHTTPResponseBodyData, aw)
local aL = aj(ax.GetHTTPStreamingResponseBodyData, aw)
local aM = aj(ax.ReleaseHTTPRequest, aw)
local aN = aj(ax.GetHTTPDownloadProgressPct, aw)
local aO = aj(ax.SetHTTPRequestRawPostBody, aw)
local aP = aj(ax.CreateCookieContainer, aw)
local aQ = aj(ax.ReleaseCookieContainer, aw)
local aR = aj(ax.SetCookie, aw)
local aS = aj(ax.SetHTTPRequestCookieContainer, aw)
local aT = aj(ax.SetHTTPRequestUserAgentInfo, aw)
local aU = aj(ax.SetHTTPRequestRequiresVerifiedCertificate, aw)
local aV = aj(ax.SetHTTPRequestAbsoluteTimeoutMS, aw)
local aW = aj(ax.GetHTTPRequestWasTimedOut, aw)
local aX, aY = {}, false
local aZ, a_ = false, {}
local b0, b1 = false, {}
local b2 = setmetatable({}, {__mode = "k"})
local b3, b4 = setmetatable({}, {__mode = "k"}), setmetatable({}, {__mode = "v"})
local b5 = {}
local b6 = {__index = function(b7, b8)
		local b9 = b3[b7]
		if b9 == nil then
			return
		end
		b8 = tostring(b8)
		if b9.m_hRequest ~= 0 then
			local ba = at(1)
			if aH(b9.m_hRequest, b8, ba) then
				if ba ~= nil then
					ba = ba[0]
					if ba < 0 then
						return
					end
					local bb = as(ba)
					if aI(b9.m_hRequest, b8, bb, ba) then
						b7[b8] = h(bb, ba - 1)
						return b7[b8]
					end
				end
			end
		end
	end, __metatable = false}
local bc = {__index = {set_cookie = function(bd, be, bf, b8, a9)
			local a8 = b2[bd]
			if a8 == nil or a8.m_hCookieContainer == 0 then
				return
			end
			aR(a8.m_hCookieContainer, be, bf, tostring(b8) .. "=" .. tostring(a9))
		end}, __metatable = false}
local function bg(a8)
	if a8.m_hCookieContainer ~= 0 then
		aQ(a8.m_hCookieContainer)
		a8.m_hCookieContainer = 0
	end
end
local function bh(b9)
	if b9.m_hRequest ~= 0 then
		aM(b9.m_hRequest)
		b9.m_hRequest = 0
	end
end
local function bi(bj, ...)
	aM(bj)
	return error(...)
end
local function bk(b9, bl, bm, bn, ...)
	local bo = b4[b9.m_hRequest]
	if bo == nil then
		bo = setmetatable({}, b6)
		b4[b9.m_hRequest] = bo
	end
	b3[bo] = b9
	bn.headers = bo
	aY = true
	xpcall(bl, print, bm, bn, ...)
	aY = false
end
local function bp(H, I)
	if H == nil then
		return
	end
	local b9 = f(am, H)
	if b9.m_hRequest ~= 0 then
		local bl = aX[b9.m_hRequest]
		if bl ~= nil then
			aX[b9.m_hRequest] = nil
			b1[b9.m_hRequest] = nil
			a_[b9.m_hRequest] = nil
			if bl then
				local bm = I == false and b9.m_bRequestSuccessful
				local bq = b9.m_eStatusCode
				local br = {status = bq}
				local bs = b9.m_unBodySize
				if bm and bs > 0 then
					local bb = as(bs)
					if aK(b9.m_hRequest, bb, bs) then
						br.body = h(bb, bs)
					end
				elseif not b9.m_bRequestSuccessful then
					local bt = au()
					aW(b9.m_hRequest, bt)
					br.timed_out = bt ~= nil and bt[0] == true
				end
				if bq > 0 then
					br.status_message = ab[bq] or "Unknown status"
				elseif I then
					br.status_message = c("IO Failure: %s", I)
				else
					br.status_message = br.timed_out and "Timed out" or "Unknown error"
				end
				a.gc(b9, bh)
				bk(b9, bl, bm, br)
			end
			bh(b9)
		end
	end
end
local function bu(H, I)
	if H == nil then
		return
	end
	local b9 = f(an, H)
	if b9.m_hRequest ~= 0 then
		local bl = a_[b9.m_hRequest]
		if bl then
			bk(b9, bl, I == false, {})
		end
	end
end
local function bv(H, I)
	if H == nil then
		return
	end
	local b9 = f(ao, H)
	if b9.m_hRequest ~= 0 then
		local bl = b1[b9.m_hRequest]
		if b1[b9.m_hRequest] then
			local bn = {}
			local bw = av()
			if aN(b9.m_hRequest, bw) then
				bn.download_progress = tonumber(bw[0])
			end
			local bb = as(b9.m_cBytesReceived)
			if aL(b9.m_hRequest, b9.m_cOffset, bb, b9.m_cBytesReceived) then
				bn.body = h(bb, b9.m_cBytesReceived)
			end
			bk(b9, bl, I == false, bn)
		end
	end
end
local function bx(by, bf, bz, callbacks)
	if type(bz) == "function" and callbacks == nil then
		callbacks = bz
		bz = {}
	end
	bz = bz or {}
	local by = aa[j(tostring(by))]
	if by == nil then
		return error("invalid HTTP method")
	end
	if type(bf) ~= "string" then
		return error("URL has to be a string")
	end
	local bA, bB, bC
	if type(callbacks) == "function" then
		bA = callbacks
	elseif type(callbacks) == "table" then
		bA = callbacks.completed or callbacks.complete
		bB = callbacks.headers_received or callbacks.headers
		bC = callbacks.data_received or callbacks.data
		if bA ~= nil and type(bA) ~= "function" then
			return error("callbacks.completed callback has to be a function")
		elseif bB ~= nil and type(bB) ~= "function" then
			return error("callbacks.headers_received callback has to be a function")
		elseif bC ~= nil and type(bC) ~= "function" then
			return error("callbacks.data_received callback has to be a function")
		end
	else
		return error("callbacks has to be a function or table")
	end
	local bj = ay(by, bf)
	if bj == 0 then
		return error("Failed to create HTTP request")
	end
	local bD = false
	for a3, J in ipairs(ac) do
		if bz[J] ~= nil then
			if bD then
				return error("can only set options.params, options.body or options.json")
			else
				bD = true
			end
		end
	end
	local bE
	if bz.json ~= nil then
		local bF
		bF, bE = pcall(json.stringify, bz.json)
		if not bF then
			return error("options.json is invalid: " .. bE)
		end
	end
	local bG = bz.network_timeout
	if bG == nil then
		bG = 10
	end
	if type(bG) == "number" and bG > 0 then
		if not aA(bj, bG) then
			return bi(bj, "failed to set network_timeout")
		end
	elseif bG ~= nil then
		return bi(bj, "options.network_timeout has to be of type number and greater than 0")
	end
	local bH = bz.absolute_timeout
	if bH == nil then
		bH = 30
	end
	if type(bH) == "number" and bH > 0 then
		if not aV(bj, bH * 1000) then
			return bi(bj, "failed to set absolute_timeout")
		end
	elseif bH ~= nil then
		return bi(bj, "options.absolute_timeout has to be of type number and greater than 0")
	end
	local bI = bE ~= nil and "application/json" or "text/plain"
	local bJ
	local bo = bz.headers
	if type(bo) == "table" then
		for b8, a9 in pairs(bo) do
			b8 = tostring(b8)
			a9 = tostring(a9)
			local bK = j(b8)
			if bK == "content-type" then
				bI = a9
			elseif bK == "authorization" then
				bJ = true
			end
			if not aB(bj, b8, a9) then
				return bi(bj, "failed to set header " .. b8)
			end
		end
	elseif bo ~= nil then
		return bi(bj, "options.headers has to be of type table")
	end
	local bL = bz.authorization
	if type(bL) == "table" then
		if bJ then
			return bi(bj, "Cannot set both options.authorization and the 'Authorization' header.")
		end
		local bM, bN = bL[1], bL[2]
		local bO = c("Basic %s", m(c("%s:%s", tostring(bM), tostring(bN)), "base64"))
		if not aB(bj, "Authorization", bO) then
			return bi(bj, "failed to apply options.authorization")
		end
	elseif bL ~= nil then
		return bi(bj, "options.authorization has to be of type table")
	end
	local bP = bE or bz.body
	if type(bP) == "string" then
		local bQ = k(bP)
		if not aO(bj, bI, f("unsigned char*", bP), bQ) then
			return bi(bj, "failed to set post body")
		end
	elseif bP ~= nil then
		return bi(bj, "options.body has to be of type string")
	end
	local bR = bz.params
	if type(bR) == "table" then
		for b8, a9 in pairs(bR) do
			b8 = tostring(b8)
			if not aC(bj, b8, tostring(a9)) then
				return bi(bj, "failed to set parameter " .. b8)
			end
		end
	elseif bR ~= nil then
		return bi(bj, "options.params has to be of type table")
	end
	local bS = bz.require_ssl
	if type(bS) == "boolean" then
		if not aU(bj, bS == true) then
			return bi(bj, "failed to set require_ssl")
		end
	elseif bS ~= nil then
		return bi(bj, "options.require_ssl has to be of type boolean")
	end
	local bT = bz.user_agent_info
	if type(bT) == "string" then
		if not aT(bj, tostring(bT)) then
			return bi(bj, "failed to set user_agent_info")
		end
	elseif bT ~= nil then
		return bi(bj, "options.user_agent_info has to be of type string")
	end
	local bU = bz.cookie_container
	if type(bU) == "table" then
		local a8 = b2[bU]
		if a8 ~= nil and a8.m_hCookieContainer ~= 0 then
			if not aS(bj, a8.m_hCookieContainer) then
				return bi(bj, "failed to set user_agent_info")
			end
		else
			return bi(bj, "options.cookie_container has to a valid cookie container")
		end
	elseif bU ~= nil then
		return bi(bj, "options.cookie_container has to a valid cookie container")
	end
	local bV = aD
	local bW = bz.stream_response
	if type(bW) == "boolean" then
		if bW then
			bV = aE
			if bA == nil and bB == nil and bC == nil then
				return bi(bj, "a 'completed', 'headers_received' or 'data_received' callback is required")
			end
		else
			if bA == nil then
				return bi(bj, "'completed' callback has to be set for non-streamed requests")
			elseif bB ~= nil or bC ~= nil then
				return bi(bj, "non-streamed requests only support 'completed' callbacks")
			end
		end
	elseif bW ~= nil then
		return bi(bj, "options.stream_response has to be of type boolean")
	end
	if bB ~= nil or bC ~= nil then
		a_[bj] = bB or false
		if bB ~= nil then
			if not aZ then
				o(ae, bu)
				aZ = true
			end
		end
		b1[bj] = bC or false
		if bC ~= nil then
			if not b0 then
				o(af, bv)
				b0 = true
			end
		end
	end
	local bX = aq()
	if not bV(bj, bX) then
		aM(bj)
		if bA ~= nil then
			bA(false, {status = 0, status_message = "Failed to send request"})
		end
		return
	end
	if bz.priority == "defer" or bz.priority == "prioritize" then
		local ak = bz.priority == "prioritize" and aG or aF
		if not ak(bj) then
			return bi(bj, "failed to set priority")
		end
	elseif bz.priority ~= nil then
		return bi(bj, "options.priority has to be 'defer' of 'prioritize'")
	end
	aX[bj] = bA or false
	if bA ~= nil then
		n(bX[0], bp, ad)
	end
end
local function bY(bZ)
	if bZ ~= nil and type(bZ) ~= "boolean" then
		return error("allow_modification has to be of type boolean")
	end
	local b_ = aP(bZ == true)
	if b_ ~= nil then
		local a8 = ap(b_)
		i(a8, bg)
		local J = setmetatable({}, bc)
		b2[J] = a8
		return J
	end
end
local c0 = {request = bx, create_cookie_container = bY}
for by in pairs(aa) do
	c0[by] = function(...)
		return bx(by, ...)
	end
end
return c0

local logger = require("logger")
local http = require("socket.http")
local ltn12 = require("ltn12")
local socket = require("socket")
local socketutil = require("socketutil")
local https = require("ssl.https")
local Device = require("device")
local Trapper = require("ui/trapper")

local ffi = require("ffi")
local ffiutil = require("ffi/util")
local C = ffi.C

local BaseHandler = {
    trap_widget = nil,  -- widget to trap the request
}

BaseHandler.CODE_CANCELLED = "USER_CANCELED"
BaseHandler.CODE_NETWORK_ERROR = "NETWORK_ERROR"

function BaseHandler:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function BaseHandler:setTrapWidget(trap_widget)
    self.trap_widget = trap_widget
end

function BaseHandler:resetTrapWidget()
    self.trap_widget = nil
end

--- Query method to be implemented by specific handlers
--- @param message_history table: conversation history, a list of messages
--- @param provider_setting table: settings for the specific provider
--- @return string response_content, string error_message
function BaseHandler:query(message_history, provider_setting)
    -- To be implemented by specific handlers
    error("query method must be implemented")
end

--- Post URL content with optional headers and body with timeout setting
--- code references: KOReader/frontend/ui/wikipedia.lua `getURLContent`
--- @param url any
--- @param headers any
--- @param body any
--- @param timeout any blocking timtout
--- @param maxtime any total response finished max time
--- @return boolean success, string status_code, string content
local function postURLContent(url, headers, body, timeout, maxtime)
    if string.sub(url, 1, 8) == "https://" then
        https.cert_verify = false  -- disable CA verify
    end

    local sink = {}
    socketutil:set_timeout(timeout, maxtime)
    local request = {
        url = url,
        method = "POST",
        headers = headers or {},
        source = ltn12.source.string(body or ""),
        sink = maxtime and socketutil.table_sink(sink) or ltn12.sink.table(sink),
    }
    local code, headers, status = socket.skip(1, http.request(request)) -- skip the first return value, not needed
    socketutil:reset_timeout()
    local content = table.concat(sink)  -- response body

    -- check for timeouts
    if code == socketutil.TIMEOUT_CODE or
       code == socketutil.SSL_HANDSHAKE_CODE or
       code == socketutil.SINK_TIMEOUT_CODE then
        logger.warn("request interrupted/timed out:", code)
        return false, code, "Request interrupted/timed out"
    end

    -- check for network errors
    if headers == nil then
        logger.warn("No HTTP headers:", status or code or "network unreachable")
        return false, BaseHandler.CODE_NETWORK_ERROR, "Network Error: " .. status or code
    end

    -- check response length
    if headers and headers["content-length"] then
        -- Check we really got the announced content size
        local content_length = tonumber(headers["content-length"])
        if #content ~= content_length then
            return false, code, "Incomplete content received"
        end
    end
    return true, code, content
end

--- func description: Make a request to the specified URL with headers and body.
function BaseHandler:makeRequest(url, headers, body, timeout, maxtime)
    local completed, success, code, content
    if self.trap_widget then
        -- If a trap widget is set, run the request in a subprocess
        completed, success, code, content = Trapper:dismissableRunInSubprocess(function()
                return postURLContent(url, headers, body, timeout or 45, maxtime or 120)
            end, self.trap_widget)
        if not completed then
            return false, self.CODE_CANCELLED, "Request cancelled by user."
        end
    else
        -- If no trap widget is set, run the request directly
        -- use smaller timeout because we are blocking the UI
        success, code, content = postURLContent(url, headers, body, timeout or 20, maxtime or 45)
    end

    return success, code, content
end

ffi.cdef[[
    typedef struct _IO_FILE FILE;
    FILE *fdopen(int fd, const char *mode);
    int fclose(FILE *stream);
    size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream);
    size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream);
    int fflush(FILE *stream);
]]

local function wrap_fd(fd, mode)
    local cfile = ffi.C.fdopen(fd, mode)
    if cfile == nil then
        return nil, "fdopen failed"
    end

    -- Define methods separately to avoid circular references
    local methods = {}

    function methods:close()
        if self._cfile ~= nil then
            ffi.C.fclose(self._cfile)
            self._cfile = nil
        end
    end

    function methods:write(...)
        if self._cfile == nil then error("file is closed") end
        for i = 1, select("#", ...) do
            local str = tostring(select(i, ...))
            ffi.C.fwrite(str, 1, #str, self._cfile)
        end
        return self
    end

    function methods:read(format)
        if self._cfile == nil then error("file is closed") end
        local buf = ffi.new("char[4096]")
        if format == "*a" then
            local chunks = {}
            while true do
                local n = ffi.C.fread(buf, 1, 4096, self._cfile)
                if n == 0 then break end
                table.insert(chunks, ffi.string(buf, n))
            end
            return table.concat(chunks)
        elseif format == "*l" then
            local line = ffi.new("char[?]", 4096)
            if ffi.C.fgets(line, 4096, self._cfile) ~= nil then
                return ffi.string(line):gsub("[\r\n]+$", "")
            end
            return nil
        else
            error("unsupported read format: " .. tostring(format))
        end
    end

    function methods:flush()
        if self._cfile == nil then error("file is closed") end
        ffi.C.fflush(self._cfile)
        return self
    end

    -- Create the file object
    local file_obj = {
        _cfile = cfile,
    }

    -- Attach methods via metatable (avoiding circular references)
    setmetatable(file_obj, {
        __index = methods,
        __gc = function(obj)
            if obj._cfile ~= nil then
                ffi.C.fclose(obj._cfile)
            end
        end,
        __tostring = function() return string.format("FILE*(fd=%d)", fd) end,
    })

    return file_obj
end

function BaseHandler:backgroudRequest(url, headers, body)
    return function(pid, child_write_fd)
        if not pid or not child_write_fd then
            logger.warn("Invalid parameters for background request")
            return
        end

        local pipe_w = wrap_fd(child_write_fd, "w")  -- wrap the write end of the pipe
        local request = {
            url = url,
            method = "POST",
            headers = headers or {},
            source = ltn12.source.string(body or ""),
            sink = ltn12.sink.file(pipe_w),  -- response body write to pipe
        }
        local code, headers, status = socket.skip(1, http.request(request)) -- skip the first return value

        if code ~= 200 then -- non-200 response code, write error to pipe
            ffiutil.writeToFD(child_write_fd, string.format("ERROR: %d %s\r\n", code, status))
        end
        C.close(child_write_fd)
    end
end

return BaseHandler
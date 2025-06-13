local logger = require("logger")
local http = require("socket.http")
local ltn12 = require("ltn12")
local socket = require("socket")
local socketutil = require("socketutil")
local https = require("ssl.https")
local Device = require("device")

local BaseHandler = {}

function BaseHandler:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function BaseHandler:query(message_history, provider_setting)
    -- To be implemented by specific handlers
    error("query method must be implemented")
end

--- func from koreader frontend/ui/wikipedia.lua
--- Post URL content with optional headers and body.
--- using koreader patched socketutil with timeout support
---@param url any
---@param headers any
---@param body any
---@param timeout any blocking timtout, default 45 seconds
---@param maxtime any total response finished max time, default 120 seconds
---@return boolean success, status code, string content
function BaseHandler:postUrlContent(url, headers, body, timeout, maxtime)
    if string.sub(url, 1, 8) == "https://" then
        https.cert_verify = false  -- disable CA verify
    end

    if not timeout then timeout = 45 end -- block_timeout
    local sink = {}
    socketutil:set_timeout(timeout, maxtime or 120) -- maxtime: total response finished max time.
    local request = {
        url = url,
        method = "POST",
        headers = headers or {},
        source = ltn12.source.string(body or ""),
        sink = maxtime and socketutil.table_sink(sink) or ltn12.sink.table(sink),
    }
    local code, headers, status = socket.skip(1, http.request(request)) -- receiving the 1st byte
    socketutil:reset_timeout()
    local content = table.concat(sink)  -- empty or content accumulated till now

    if code == socketutil.TIMEOUT_CODE or
       code == socketutil.SSL_HANDSHAKE_CODE or
       code == socketutil.SINK_TIMEOUT_CODE then
        logger.warn("request interrupted/timed out:", code)
        return false, code, "Request interrupted/timed out"
    end
    if headers == nil then
        logger.warn("No HTTP headers:", status or code or "network unreachable")
        return false, nil, "Network or remote server unavailable"
    end
    if headers and headers["content-length"] then
        -- Check we really got the announced content size
        local content_length = tonumber(headers["content-length"])
        if #content ~= content_length then
            return false, code, "Incomplete content received"
        end
    end
    return true, code, content
end

function BaseHandler:logError(code)
    -- Log detailed error information
    local error_info = {
        error_type = type(code),
        error_message = tostring(code),
        ssl_loaded = package.loaded["ssl"] ~= nil,
        https_loaded = package.loaded["ssl.https"] ~= nil,
        socket_loaded = package.loaded["socket"] ~= nil,
        device_info = {
            model = Device:info(),
            firmware = Device:otaModel(),
        }
    }
    
    logger.warn("API request failed with details:", error_info)
end

function BaseHandler:makeRequest(url, headers, body)
    logger.dbg("Attempting API request:", {
        url = url,
        headers = headers,
        body_length = #body
    })
   
    local ok, code, resp = self:postUrlContent(url, headers, body)
    if ok then
        return true, code, resp
    end

    -- If the request failed, log the error details
    self:logErrorDetails(code)
    return false, code, resp
end
    
return BaseHandler
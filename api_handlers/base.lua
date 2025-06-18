local logger = require("logger")
local http = require("socket.http")
local ltn12 = require("ltn12")
local socket = require("socket")
local socketutil = require("socketutil")
local https = require("ssl.https")
local Device = require("device")
local Trapper = require("ui/trapper")

local BaseHandler = {
    trap_widget = nil,  -- widget to trap the request
}

BaseHandler.CODE_CANCELLED = -42  -- code for request cancelled by user

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
--- @return: response or nil, error message
function BaseHandler:query(message_history, provider_setting)
    -- To be implemented by specific handlers
    error("query method must be implemented")
end

--- Post URL content with optional headers and body with timeout setting
--- func code references frontend/ui/wikipedia.lua `getURLContent`
--- TODO: to support user abort interruption.
---@param url any
---@param headers any
---@param body any
---@param timeout any blocking timtout
---@param maxtime any total response finished max time
---@return boolean success, status code, string content
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
        success, code, content = postURLContent(url, headers, body, timeout or 20, maxtime or 60)
    end

    return success, code, content
end

return BaseHandler
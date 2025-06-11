local https = require("ssl.https")
local ltn12 = require("ltn12")
local logger = require("logger")
local Device = require("device")

local BaseHandler = {}

function BaseHandler:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function BaseHandler:query(message_history)
    -- To be implemented by specific handlers
    error("query method must be implemented")
end

function BaseHandler:CurlRequest(url, headers, body)
    local tmp_request = "/tmp/assi_request.json"
    local tmp_response = "/tmp/assi_response.json"
    
    -- Write request body
    local f = io.open(tmp_request, "w")
    if f then
        f:write(body)
        f:close()
    end
    
    -- Construct curl command with proper headers
    local header_args = ""
    for k, v in pairs(headers) do
        header_args = header_args .. string.format(' -H "%s: %s"', k, v)
    end
    
    local curl_cmd = string.format(
        'curl -k -s -X POST%s --connect-timeout 30 --retry 2 --retry-delay 3 '..
        '--data-binary @%s "%s" -o %s',
        header_args, tmp_request, url, tmp_response
    )
    
    logger.dbg("Executing curl command:", curl_cmd:gsub(headers["Authorization"], "Bearer ***")) -- Hide API key in logs
    local curl_result = os.execute(curl_cmd)
    logger.dbg("Curl execution result:", curl_result)
    
    -- Read response
    local response = nil
    f = io.open(tmp_response, "r")
    if f then
        response = f:read("*all")
        f:close()
        logger.dbg("Curl response length:", #response)
    else
        logger.warn("Failed to read curl response file")
    end
    
    -- Cleanup
    os.remove(tmp_request)
    os.remove(tmp_response)
    
    if response then
        return true, 200, response
    end
    return false, 400, ""
end

function BaseHandler:HTTPSRequest(url, headers, body)
    local response = {}
    local status, code, responseHeaders = https.request({
        url = url,
        method = "POST",
        headers = headers,
        source = ltn12.source.string(body),
        sink = ltn12.sink.table(response),
        protocol = "tlsv1_2",
        verify = "none", -- Disable SSL verification for Kindle
        timeout = 30
    })
    
    if status then
        return status, code, table.concat(response)
    end

    -- Log detailed error information
    local error_info = {
        error_type = type(code),
        error_message = tostring(code),
        ssl_loaded = package.loaded["ssl"] ~= nil,
        https_loaded = package.loaded["ssl.https"] ~= nil,
        socket_loaded = package.loaded["socket"] ~= nil,
        device_info = {
            is_kindle = Device:isKindle(),
            model = Device:getModel(),
            firmware = Device:getFirmware(),
        }
    }
    
    logger.warn("API request failed with details:", error_info)
end

-- Add fallback HTTP request function
function BaseHandler:makeRequest(url, headers, body)
    logger.dbg("Attempting API request:", {
        url = url,
        headers = headers,
        body_length = #body
    })
    
    -- Try using curl first (more reliable on Kindle)
    if Device:isKindle() then
        return self:CurlRequest(url, headers, body)
    end

    -- Fallback to standard HTTPS when not on Kindle
    logger.dbg("Attempting HTTPS fallback request")
    return self:HTTPSRequest(url, headers, body)
end

return BaseHandler 
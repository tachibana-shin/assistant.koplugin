local BaseHandler = require("api_handlers.base")
local https = require("ssl.https")
local ltn12 = require("ltn12")
local json = require("json")
local logger = require("logger")
local Device = require("device")

local DeepSeekHandler = BaseHandler:new()

function DeepSeekHandler:makeRequest(url, headers, body)
    logger.dbg("Attempting DeepSeek API request:", {
        url = url,
        headers = headers and "present" or "missing",
        body_length = #body
    })
    
    -- Try using curl first (more reliable on Kindle)
    if Device:isKindle() then
        local tmp_request = "/tmp/deepseek_request.json"
        local tmp_response = "/tmp/deepseek_response.json"
        
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
            return true, response
        end
    end
    
    -- Fallback to standard HTTPS if curl fails or not on Kindle
    logger.dbg("Attempting HTTPS fallback request")
    local responseBody = {}
    local success, code = https.request({
        url = url,
        method = "POST",
        headers = headers,
        source = ltn12.source.string(body),
        sink = ltn12.sink.table(responseBody),
        timeout = 30,
        verify = "none", -- Disable SSL verification for Kindle
    })
    
    if success then
        return true, table.concat(responseBody)
    end
    
    logger.warn("DeepSeek API request failed:", {
        error = code,
        error_type = type(code),
        error_message = tostring(code)
    })
    return false, code
end

function DeepSeekHandler:query(message_history, config)
    local deepseek_settings = config.provider_settings and config.provider_settings.deepseek

    if not deepseek_settings or not deepseek_settings.api_key then
        return "Error: Missing API key in configuration"
    end

    -- DeepSeek uses OpenAI-compatible API format
    local requestBodyTable = {
        model = deepseek_settings.model,
        messages = message_history,
        max_tokens = (deepseek_settings.additional_parameters and deepseek_settings.additional_parameters.max_tokens)
    }

    local requestBody = json.encode(requestBodyTable)
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. deepseek_settings.api_key
    }

    local success, response = self:makeRequest(deepseek_settings.base_url, headers, requestBody)

    if not success then
        return "Error: Failed to connect to DeepSeek API - " .. tostring(response)
    end

    local success_parse, parsed = pcall(json.decode, response)
    if not success_parse then
        logger.warn("JSON Decode Error:", parsed)
        return "Error: Failed to parse DeepSeek API response"
    end
    
    if parsed and parsed.choices and parsed.choices[1] and parsed.choices[1].message then
        return parsed.choices[1].message.content
    elseif parsed and parsed.error then
	    return "DeepSeek API Error: [" .. parsed.error.code .. "]: " .. parsed.error.message
    else
        return "DeepSeek API Error: Unexpected response format from API: " .. response
    end
end

return DeepSeekHandler

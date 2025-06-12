local BaseHandler = require("api_handlers.base")
local json = require("json")
local logger = require("logger")

local DeepSeekHandler = BaseHandler:new()

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

    local success, code, response = self:makeRequest(deepseek_settings.base_url, headers, requestBody)

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

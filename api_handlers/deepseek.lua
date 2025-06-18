local BaseHandler = require("api_handlers.base")
local json = require("json")
local logger = require("logger")

local DeepSeekHandler = BaseHandler:new()

function DeepSeekHandler:query(message_history, deepseek_settings)

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

    local success, code, response = self:makeRequest(
        deepseek_settings.base_url,
        headers,
        requestBody,
        45,  -- block_timeout, API is slow sometimes, need longer timeout
        90   -- maxtime: total response finished max time
    )

    if not success then
        if code == BaseHandler.CODE_CANCELLED then
            return nil, response
        end
        return nil, "Error: Failed to connect to DeepSeek API - " .. tostring(response)
    end

    local success_parse, parsed = pcall(json.decode, response)
    if not success_parse then
        return nil, "Error: Failed to parse DeepSeek API response: " .. response
    end
    
    if parsed and parsed.choices and parsed.choices[1] and parsed.choices[1].message then
        return parsed.choices[1].message.content
    elseif parsed and parsed.error then
        logger.warn("API Error:", code, response)
	    return nil, "DeepSeek API Error: [" .. parsed.error.code .. "]: " .. parsed.error.message
    else
        logger.warn("API Error:", code, response)
        return nil, "DeepSeek API Error: Unexpected response format from API: " .. response
    end
end

return DeepSeekHandler

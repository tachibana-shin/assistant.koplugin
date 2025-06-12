local BaseHandler = require("api_handlers.base")
local json = require("json")
local logger = require("logger")

local AnthropicHandler = BaseHandler:new()

function AnthropicHandler:query(message_history, config)
    local anthropic_settings = config.provider_settings and config.provider_settings.anthropic

    if not anthropic_settings or not anthropic_settings.api_key then
        return "Error: Missing API key in configuration"
    end
    
    local messages = {}
    for _, msg in ipairs(message_history) do
        if msg.role ~= "system" then
            table.insert(messages, {
                role = msg.role == "assistant" and "assistant" or "user",
                content = msg.content
            })
        end
    end

    local requestBodyTable = {
        model = anthropic_settings.model,
        messages = messages,
        max_tokens = (anthropic_settings.additional_parameters and anthropic_settings.additional_parameters.max_tokens)
    }

    local requestBody = json.encode(requestBodyTable)
    local headers = {
        ["Content-Type"] = "application/json",
        ["x-api-key"] = anthropic_settings.api_key,
        ["anthropic-version"] = (anthropic_settings.additional_parameters and anthropic_settings.additional_parameters.anthropic_version)
    }

    local success, code, response = self:makeRequest(anthropic_settings.base_url, headers, requestBody)

    if not success then
        return "Error: Failed to connect to Anthropic API - " .. tostring(response)
    end

    local success_parse, parsed = pcall(json.decode, response)
    if not success_parse then
        logger.warn("JSON Decode Error:", parsed)
        return "Error: Failed to parse Anthropic API response"
    end
    
    if parsed and parsed.content and parsed.content[1] and parsed.content[1].text then
        return parsed.content[1].text
    else
        return "Error: Unexpected response format from API"
    end
end

return AnthropicHandler
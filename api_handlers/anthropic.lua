local BaseHandler = require("api_handlers.base")
local https = require("ssl.https")
local ltn12 = require("ltn12")
local json = require("json")
local Defaults = require("api_handlers.defaults")

local AnthropicHandler = BaseHandler:new()

function AnthropicHandler:query(message_history, config)
    if not config or not config.api_key then
        return "Error: Missing API key in configuration"
    end

    local defaults = Defaults.ProviderDefaults.anthropic
    
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
        model = config.model or defaults.model,
        messages = messages,
        max_tokens = (config.additional_parameters and config.additional_parameters.max_tokens) or defaults.additional_parameters.max_tokens
    }

    local requestBody = json.encode(requestBodyTable)
    local responseBody = {}
    local headers = {
        ["Content-Type"] = "application/json",
        ["x-api-key"] = config.api_key,
        ["anthropic-version"] = (config.additional_parameters and config.additional_parameters.anthropic_version) or defaults.additional_parameters.anthropic_version
    }

    local success, code = https.request({
        url = config.base_url or defaults.base_url,
        method = "POST",
        headers = headers,
        source = ltn12.source.string(requestBody),
        sink = ltn12.sink.table(responseBody)
    })

    if not success then
        return "Error: Failed to connect to Anthropic API - " .. tostring(code)
    end

    local response = json.decode(table.concat(responseBody))
    
    if response and response.content and response.content[1] and response.content[1].text then
        return response.content[1].text
    else
        return "Error: Unexpected response format from API"
    end
end

return AnthropicHandler 
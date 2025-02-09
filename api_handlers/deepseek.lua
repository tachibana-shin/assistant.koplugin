local BaseHandler = require("api_handlers.base")
local https = require("ssl.https")
local ltn12 = require("ltn12")
local json = require("json")

local DeepSeekHandler = BaseHandler:new()

function DeepSeekHandler:query(message_history, config)
    if not config or not config.api_key then
        return "Error: Missing API key in configuration"
    end

    -- DeepSeek uses OpenAI-compatible API format
    local requestBodyTable = {
        model = config.model or "deepseek-chat",
        messages = message_history,
        max_tokens = (config.additional_parameters and config.additional_parameters.max_tokens) or 4096
    }

    local requestBody = json.encode(requestBodyTable)
    local responseBody = {}
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. config.api_key
    }

    local success, code = https.request({
        url = config.base_url or "https://api.deepseek.com/v1/chat/completions",
        method = "POST",
        headers = headers,
        source = ltn12.source.string(requestBody),
        sink = ltn12.sink.table(responseBody)
    })

    if not success then
        return "Error: Failed to connect to DeepSeek API - " .. tostring(code)
    end

    local response = json.decode(table.concat(responseBody))
    
    if response and response.choices and response.choices[1] and response.choices[1].message then
        return response.choices[1].message.content
    else
        return "Error: Unexpected response format from API"
    end
end

return DeepSeekHandler 
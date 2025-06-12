local BaseHandler = require("api_handlers.base")
local json = require("json")
local logger = require("logger")

local OpenRouterProvider = BaseHandler:new()

function OpenRouterProvider:query(message_history, config)
    local openrouter_settings = config.provider_settings and config.provider_settings.openrouter
    
    local requestBodyTable = {
        model = openrouter_settings.model,
        messages = message_history,
        max_tokens = openrouter_settings.max_tokens,
        temperature = openrouter_settings.temperature
    }
    
    -- Handle reasoning tokens configuration
    if openrouter_settings.additional_parameters and openrouter_settings.additional_parameters.reasoning ~= nil then
        -- Create a copy of the reasoning configuration
        requestBodyTable.reasoning = {}
        for k, v in pairs(openrouter_settings.additional_parameters.reasoning) do
            requestBodyTable.reasoning[k] = v
        end
        
        -- Set exclude to true by default if not explicitly set
        if requestBodyTable.reasoning.exclude == nil then
            requestBodyTable.reasoning.exclude = true
        end
    end

    local requestBody = json.encode(requestBodyTable)
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. (openrouter_settings.api_key or config.api_key),
        ["HTTP-Referer"] = "https://github.com/omer-faruq/assistant.koplugin",
        ["X-Title"] = "assistant.koplugin"
    }

    local status, code, response = self:makeRequest(openrouter_settings.base_url, headers, requestBody)

    if status and code == 200 then
        local success, responseData = pcall(json.decode, response)
        if success and responseData and responseData.choices and responseData.choices[1] then
            return responseData.choices[1].message.content
        end
    end
    
    return nil, "Error: " .. (code or "unknown") .. " - " .. response
end

return OpenRouterProvider

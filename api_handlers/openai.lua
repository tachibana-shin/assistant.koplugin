local BaseHandler = require("api_handlers.base")
local https = require("ssl.https")
local ltn12 = require("ltn12")
local json = require("json")
local logger = require("logger")
local Device = require("device")

local OpenAIHandler = BaseHandler:new()

function OpenAIHandler:query(message_history, config)
    local openai_settings = config.provider_settings and config.provider_settings.openai
    
    local requestBodyTable = {
        model = openai_settings.model,
        messages = message_history,
        max_tokens = openai_settings.max_tokens
    }

    local requestBody = json.encode(requestBodyTable)
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. (openai_settings.api_key)
    }

    local status, code, response = self:makeRequest(openai_settings.base_url, headers, requestBody)

    if status and code == 200 then
        local success, responseData = pcall(json.decode, response)
        if success and responseData and responseData.choices and responseData.choices[1] then
            return responseData.choices[1].message.content
        end
    end
    
    return nil, "Error: " .. (code or "unknown") .. " - " .. response
end

return OpenAIHandler
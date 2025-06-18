local BaseHandler = require("api_handlers.base")
local json = require("json")
local logger = require("logger")

local OpenAIHandler = BaseHandler:new()

function OpenAIHandler:query(message_history, openai_settings)
    
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

    if status then
        local success, responseData = pcall(json.decode, response)
        if success and responseData and responseData.choices and responseData.choices[1] then
            return responseData.choices[1].message.content
        end
        
        -- server response error message
        logger.warn("API Error", code, response)
        if success and responseData and responseData.error and responseData.error.message then
            return nil, responseData.error.message 
        end
    end
    
    if code == BaseHandler.CODE_CANCELLED then
        return nil, response
    end
    return nil, "Error: " .. (code or "unknown") .. " - " .. response
end

return OpenAIHandler
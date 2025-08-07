local BaseHandler = require("api_handlers.base")
local json = require("json")
local logger = require("logger")

local MistralHandler = BaseHandler:new()

function MistralHandler:query(message_history, mistral_settings)

    -- Remove is_context from body, which causes an error in Mistral API
    -- Need to clone the history so that we don't affect the actual message history which gets displayed
    local cloned_history = {}

    for i, message in ipairs(message_history) do
      local new_message = {}
      for k, v in pairs(message) do
        new_message[k] = v
      end
      
      -- Remove the is_context field in the clone
      new_message.is_context = nil

      cloned_history[i] = new_message
    end
    
    local requestBodyTable = {
        model = mistral_settings.model,
        messages = cloned_history,
    }

    -- Handle configuration
    if mistral_settings.additional_parameters then
        --- available req body args: https://docs.mistral.ai/api/
        for _, option in ipairs({"temperature", "top_p", "n", "max_tokens", "stream"}) do
            if mistral_settings.additional_parameters[option] then
                requestBodyTable[option] = mistral_settings.additional_parameters[option]
            end
        end
    end

    local requestBody = json.encode(requestBodyTable)
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. (mistral_settings.api_key)
    }

    if requestBodyTable.stream then
        -- For streaming responses, we need to handle the response differently
        headers["Accept"] = "text/event-stream"
        return self:backgroudRequest(mistral_settings.base_url, headers, requestBody)
    end
    

    local status, code, response = self:makeRequest(mistral_settings.base_url, headers, requestBody)

    if status then
        local success, responseData = pcall(json.decode, response)
        if success and responseData and responseData.choices and responseData.choices[1] then
            return responseData.choices[1].message.content
        end
        
        -- server response error message
        logger.warn("API Error", code, response)
        if success and responseData and responseData.message then
            return nil,  "API Error: " .. responseData.message 
        end
    end
    
    if code == BaseHandler.CODE_CANCELLED then
        return nil, response
    end
    return nil, "Error: " .. (code or "unknown") .. " - " .. response
end

return MistralHandler
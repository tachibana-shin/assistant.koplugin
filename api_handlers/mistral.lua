local BaseHandler = require("api_handlers.base")
local json = require("json")
local logger = require("logger")

local MistralHandler = BaseHandler:new()

function MistralHandler:query(message_history, config)
    local mistral_settings = config.provider_settings and config.provider_settings.mistral

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
        max_tokens = mistral_settings.max_tokens,
        temperature = mistral_settings.temperature
    }

    local requestBody = json.encode(requestBodyTable)
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. (mistral_settings.api_key)
    }

    local status, code, response = self:makeRequest(mistral_settings.base_url, headers, requestBody)

    if status and code == 200 then
        local success, responseData = pcall(json.decode, response)
        if success and responseData and responseData.choices and responseData.choices[1] then
            return responseData.choices[1].message.content
        end
    end
    
    return nil, "Error: " .. (code or "unknown") .. " - " .. response
end

return MistralHandler
local BaseHandler = require("api_handlers.base")
local https = require("ssl.https")
local ltn12 = require("ltn12")
local json = require("json")
local logger = require("logger")
local Device = require("device")

local groqHandler = BaseHandler:new()

function groqHandler:query(message_history, config)
    local groq_settings = config.provider_settings and config.provider_settings.groq

    -- Remove is_context from body, which causes an error in groq API
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
        model = groq_settings.model,
        messages = cloned_history,
        max_tokens = groq_settings.max_tokens
    }

    local requestBody = json.encode(requestBodyTable)
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. (groq_settings.api_key)
    }

    local status, code, response = self:makeRequest(groq_settings.base_url, headers, requestBody)

    if status and code == 200 then
        local success, responseData = pcall(json.decode, response)
        if success and responseData and responseData.choices and responseData.choices[1] then
            return responseData.choices[1].message.content
        end
    end
    
    return nil, "Error: " .. (code or "unknown") .. " - " .. response
end

return groqHandler

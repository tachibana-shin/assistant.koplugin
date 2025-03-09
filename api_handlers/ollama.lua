local BaseHandler = require("api_handlers.base")
local https = require("ssl.https")
local ltn12 = require("ltn12")
local json = require("json")

local OllamaHandler = BaseHandler:new()

function OllamaHandler:query(message_history, config)
    local ollama_settings = config.provider_settings and config.provider_settings.ollama or {}

    local required_settings = {"base_url", "model", "api_key"}
    for _, setting in ipairs(required_settings) do
      if not ollama_settings[setting] then
        return "Error: Missing " .. setting .. " in configuration"
      end
    end

    -- Ollama uses OpenAI-compatible API format
    local requestBodyTable = {
        model = ollama_settings.model,
        messages = message_history,
        stream = false
    }

    local requestBody = json.encode(requestBodyTable)
    local responseBody = {}
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. ollama_settings.api_key
    }

    local success, code = https.request({
        url = ollama_settings.base_url,
        method = "POST",
        headers = headers,
        source = ltn12.source.string(requestBody),
        sink = ltn12.sink.table(responseBody)
    })

    if not success then
        return "Error: Failed to connect to Ollama API - " .. tostring(code)
    end

    local response = json.decode(table.concat(responseBody))

    if response and response.message then
        return response.message.content
    else
        return "Error: Unexpected response format from API"
    end
end

return OllamaHandler
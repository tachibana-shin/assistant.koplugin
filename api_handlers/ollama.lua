local BaseHandler = require("api_handlers.base")
local https = require("ssl.https")
local ltn12 = require("ltn12")
local json = require("json")
local logger = require("logger")
local Device = require("device")

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
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. ollama_settings.api_key
    }

    local success, code, response = self:makeRequest(ollama_settings.base_url, headers, requestBody)
    if not success then
        return "Error: Failed to connect to Ollama API - " .. tostring(response)
    end

    local success_parse, parsed = pcall(json.decode, response)
    if not success_parse then
        logger.warn("JSON Decode Error:", parsed)
        return "Error: Failed to parse Ollama API response"
    end

    if parsed and parsed.message then
        return parsed.message.content
    else
        return "Error: Unexpected response format from API"
    end
end

return OllamaHandler
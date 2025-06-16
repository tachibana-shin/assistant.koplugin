local BaseHandler = require("api_handlers.base")
local json = require("json")
local logger = require("logger")

local GeminiHandler = BaseHandler:new()

function GeminiHandler:query(message_history, gemini_settings)

    if not gemini_settings or not gemini_settings.api_key then
        return "Error: Missing API key in configuration"
    end

    -- Gemini API requires messages with explicit roles
    local contents = {}
    local systemMessage = nil
    local generationConfig = nil

    for i, msg in ipairs(message_history) do
        -- First message is treated as system message
        if i == 1 and msg.role ~= "user" then
            systemMessage = {
                role = "user",
                parts = {{ text = msg.content }}
            }
        else
            table.insert(contents, {
                role = "user",
                parts = {{ text = msg.content }}
            })
        end
    end

    -- If a system message exists, insert it at the beginning
    if systemMessage then
        table.insert(contents, 1, systemMessage)
    end

    local thinking_budget = gemini_settings and gemini_settings.additional_parameters and
                            gemini_settings.additional_parameters.thinking_budget
    if thinking_budget ~= nil then
        generationConfig = generationConfig or { thinkingConfig = {} }
        generationConfig.thinkingConfig.thinkingBudget = thinking_budget
    end

    local requestBodyTable = {
        contents = contents,
        safety_settings = {
            { category = "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold = "BLOCK_NONE" },
            { category = "HARM_CATEGORY_HATE_SPEECH", threshold = "BLOCK_NONE" },
            { category = "HARM_CATEGORY_HARASSMENT", threshold = "BLOCK_NONE" },
            { category = "HARM_CATEGORY_DANGEROUS_CONTENT", threshold = "BLOCK_NONE" }
        },
        generationConfig = generationConfig
    }

    local requestBody = json.encode(requestBodyTable)
    
    local headers = {
        ["Content-Type"] = "application/json"
    }

    local model = gemini_settings.model or "gemini-1.5-pro-latest"
    local base_url = gemini_settings.base_url or "https://generativelanguage.googleapis.com/v1beta/models/"
    
    local url = string.format("%s%s:generateContent?key=%s", base_url, model, gemini_settings.api_key)
    logger.dbg("Making Gemini API request to model:", model)
    
    local success, code, response = self:makeRequest(url, headers, requestBody)
    if not success then
        logger.warn("Gemini API request failed:", {
            error = response,
            model = model,
            base_url = base_url:gsub(gemini_settings.api_key, "***"), -- Hide API key in logs
            request_size = #requestBody,
            message_count = #message_history
        })
        return nil,"Error: Failed to connect to Gemini API - " .. tostring(response)
    end

    local success, parsed = pcall(json.decode, response)
    if not success then
        logger.warn("JSON Decode Error:", parsed)
        return nil,"Error: Failed to parse Gemini API response"
    end
    
    if parsed and parsed.candidates and parsed.candidates[1] and 
       parsed.candidates[1].content and parsed.candidates[1].content.parts and
       parsed.candidates[1].content.parts[1] then
        return parsed.candidates[1].content.parts[1].text
    elseif parsed and parsed.error and parsed.error.message then
        return nil, parsed.error.message 
    else
        return nil,"Error: Unexpected response format from Gemini API"
    end
end

return GeminiHandler
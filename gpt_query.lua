local logger = require("logger")
local api_key = nil
local CONFIGURATION = nil

-- Attempt to load the configuration module first
local success, result = pcall(function() return require("configuration") end)
if success then
    CONFIGURATION = result
else
    logger.warn("No configuration found. Please set up configuration.lua")
end

-- Define handlers table with proper error handling
local handlers = {}
local function loadHandler(name)
    local success, handler = pcall(function()
        return require("api_handlers." .. name)
    end)
    if success then
        handlers[name] = handler
    else
        logger.warn("Failed to load " .. name .. " handler: " .. tostring(handler))
    end
end

local provider_handlers = {
    anthropic = function() loadHandler("anthropic") end,
    openai = function() loadHandler("openai") end,
    deepseek = function() loadHandler("deepseek") end,
    gemini = function() loadHandler("gemini") end,
    openrouter = function() loadHandler("openrouter") end,
    ollama = function() loadHandler("ollama") end,
    mistral = function() loadHandler("mistral") end,
    groq = function() loadHandler("groq") end,
    azure_openai = function() loadHandler("azure_openai") end
}

if CONFIGURATION and CONFIGURATION.provider and provider_handlers[CONFIGURATION.provider] then
    provider_handlers[CONFIGURATION.provider]()
end

-- return: answer, err
local function queryChatGPT(message_history)
    if not CONFIGURATION then
        return "", "Error: No configuration found. Please set up configuration.lua"
    end

    local provider = CONFIGURATION.provider 
    
    if not provider then
        return "", "Error: No provider specified in configuration"
    end

    local handler = handlers[provider]

    if not handler then
        return "", "Error: Unsupported provider " .. provider .. ". Please check configuration.lua"
    end

    local res, err = handler:query(message_history, CONFIGURATION)
    if err ~= nil then
        return "", "Error: " .. tostring(err)
    end
    return res
end

return queryChatGPT

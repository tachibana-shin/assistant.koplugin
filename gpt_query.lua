local api_key = nil
local CONFIGURATION = nil
local Defaults = require("api_handlers.defaults")

-- Attempt to load the configuration module first
local success, result = pcall(function() return require("configuration") end)
if success then
    CONFIGURATION = result
else
    print("configuration.lua not found, attempting legacy api_key.lua...")
    -- Try legacy api_key as fallback
    success, result = pcall(function() return require("api_key") end)
    if success then
        api_key = result.key
        -- Create configuration from legacy api_key using defaults
        local provider = "anthropic" -- Default provider
        CONFIGURATION = Defaults.ProviderDefaults[provider]
        CONFIGURATION.api_key = api_key
    else
        print("No configuration found. Please set up configuration.lua")
    end
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
        print("Failed to load " .. name .. " handler: " .. tostring(handler))
    end
end

loadHandler("anthropic")
loadHandler("openai")
loadHandler("deepseek")
loadHandler("gemini")

local function getApiKey(provider)
    local success, apikeys = pcall(function() return require("apikeys") end)
    if success and apikeys and apikeys[provider] then
        return apikeys[provider]
    end
    return nil
end

local function queryChatGPT(message_history)
    if not CONFIGURATION then
        return "Error: No configuration found. Please set up configuration.lua"
    end

    local provider = CONFIGURATION.provider or "anthropic"
    local handler = handlers[provider]
    
    if not handler then
        return "Error: Unsupported provider " .. provider
    end
    
    -- Get API key for the selected provider
    CONFIGURATION.api_key = getApiKey(provider)
    if not CONFIGURATION.api_key then
        return "Error: No API key found for provider " .. provider .. ". Please check apikeys.lua"
    end
    
    local success, result = pcall(function()
        return handler:query(message_history, CONFIGURATION)
    end)
    
    if not success then
        return "Error: " .. tostring(result)
    end
    
    return result
end

return queryChatGPT
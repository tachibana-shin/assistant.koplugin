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

local Querier = {
    handler = nil,
    handler_name = nil,
    provider_settings = nil,
    provider_name = nil
}

function Querier:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function  Querier:is_inited()
    return self.handler ~= nil and 
        self.provider_settings ~= nil and 
        self.provider_name ~= nil and 
        self.handler_name ~= nil
end

--- Initialize the Querier with the provider settings and handler
--- This function checks the CONFIGURATION for the provider and loads the appropriate handler.
function Querier:init()
    if CONFIGURATION and CONFIGURATION.provider then

        self.provider_name = CONFIGURATION.provider
        --- Check if the provider is set in the configuration
        if CONFIGURATION.provider_settings and CONFIGURATION.provider_settings[CONFIGURATION.provider] then
            self.provider_settings = CONFIGURATION.provider_settings[CONFIGURATION.provider]
        else
            error("Provider settings not found for: " .. CONFIGURATION.provider .. ". Please check your configuration.lua file.")
        end

        if self.provider_name:find("_") then
            --- Split the provider name by underscore and 
            --- take the first part as handler name
            self.handler_name = CONFIGURATION.provider:match("([^_]+)")
        else
            self.handler_name = CONFIGURATION.provider
        end

        --- Load the handler based on the provider name
        local success, handler = pcall(function()
            return require("api_handlers." .. self.handler_name)
        end)
        if success then
            self.handler = handler
        else
            error("Handler not found: " .. self.handler_name .. ". Please ensure the handler exists in api_handlers directory.")
        end
    else
        error("No provider set in configuration.lua. Please set the provider and provider_settings.")
    end
end

function Querier:model()
    if not self:is_inited() then
        local ok, err = pcall(function()
            self:init()
        end)
        if not ok then
            return tostring(err)
        end
    end

    return string.format("%s⮞%s", self.provider_name, self.provider_settings.model)
end

--- Query the AI with the provided message history
--- return: answer, error (if any)
function Querier:query(message_history)
    if not self:is_inited() then
        local ok, err = pcall(function()
            self:init()
        end)
        if not ok then
            return "", "Error init: " .. tostring(err)
        end
    end

    local res, err = self.handler:query(message_history, self.provider_settings)
    if err ~= nil then
        return "", "Error: " .. tostring(err)
    end
    return res
end

return Querier
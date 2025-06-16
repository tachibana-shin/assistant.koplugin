--- Querier module for handling AI queries with dynamic provider loading
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

function Querier:is_inited()
    return self.handler ~= nil
end

--- Initialize the Querier with the provider settings and handler
--- This function checks the CONFIGURATION for the provider and loads the appropriate handler.
function Querier:init(provider_name)

    local CONFIGURATION
    local success, result = pcall(function() return require("configuration") end)
    if success then
        CONFIGURATION = result
    else
        error("No configuration found. Please set up configuration.lua")
    end

    if CONFIGURATION and CONFIGURATION.provider then

        --- Check if the provider is set in the configuration
        if CONFIGURATION.provider_settings and CONFIGURATION.provider_settings[provider_name] then
            self.provider_settings = CONFIGURATION.provider_settings[provider_name]
        else
            error("Provider settings not found for: " .. provider_name .. ". Please check your configuration.lua file.")
        end

        self.provider_name = provider_name

        local underscore_pos = self.provider_name:find("_")
        if underscore_pos then
            -- Extract the substring before the first underscore as the handler name
            self.handler_name = self.provider_name:sub(1, underscore_pos - 1)
        else
            self.handler_name = self.provider_name
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

function Querier:load_model(provider_name)
    if not self:is_inited() then
        return pcall(function()
            self:init(provider_name)
        end)
    end
    return true
end

-- Get the model description for the current provider
-- using unicode emojis for better readability
function Querier:get_model_desc()
    if not self:is_inited() then
        return "Assitant: not configured."
    end
    return string.format("☁️ %s\n⚡ %s", self.handler_name, self.provider_settings.model)
end

--- Query the AI with the provided message history
--- return: answer, error (if any)
function Querier:query(message_history)
    if not self:is_inited() then
        return "", "Assitant: not configured."
    end

    local res, err = self.handler:query(message_history, self.provider_settings)
    if err ~= nil then
        return "", "Error: " .. tostring(err)
    end
    return res
end

return Querier
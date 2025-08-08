--- Querier module for handling AI queries with dynamic provider loading
local t = require("i18n")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local logger = require("logger")
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
--- return: nil on success, or an error message if initialization fails.
function Querier:init(provider_name)

    local CONFIGURATION
    local success, result = pcall(function() return require("configuration") end)
    if success then
        CONFIGURATION = result
    else
        return t("no_configuration_found_please_set_up_configuration")
    end

    if CONFIGURATION and CONFIGURATION.provider_settings then

        --- Check if the provider is set in the configuration
        if CONFIGURATION.provider_settings and CONFIGURATION.provider_settings[provider_name] then
            self.provider_settings = CONFIGURATION.provider_settings[provider_name]
        else
            return string.format(
                t("provider_settings_not_found_for_provider_check_configuration"),
                provider_name)
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
            return string.format(
                t("handler_not_found_for_provider_ensure_handler_exists"),
                self.handler_name)
        end
    else
        return t("no_provider_set_in_configuration_please_set_provider_and_settings")
    end
end

--- Load provider model for the Querier
function Querier:load_model(provider_name)
    -- If the provider name is different or not initialized, reinitialize
    if provider_name ~= self.provider_name or not self:is_inited() then
        local err = self:init(provider_name)
        if err then
            logger.warn("Querier initialization failed: " .. err)
            return false, err
        end
    end
    return true
end

--- Query the AI with the provided message history
--- return: answer, error (if any)
function Querier:query(message_history, title)
    if not self:is_inited() then
        return "", "Assitant: " .. t("not_configure")
    end

    local infomsg = InfoMessage:new{
      icon = "book.opened",
      text = string.format("%s\n️☁️ %s\n⚡ %s", title or t("querying_ai"),
            self.provider_name, self.provider_settings.model),
    }

    UIManager:show(infomsg)
    self.handler:setTrapWidget(infomsg)
    local res, err = self.handler:query(message_history, self.provider_settings)
    self.handler:resetTrapWidget()
    UIManager:close(infomsg)

    if err ~= nil then
        return "", tostring(err)
    end
    return res
end

return Querier
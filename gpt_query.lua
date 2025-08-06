--- Querier module for handling AI queries with dynamic provider loading
local _ = require("gettext")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local logger = require("logger")
local json = require("json")
local ffi = require("ffi")
local ffiutil = require("ffi/util")
local C = ffi.C
local Querier = {
    handler = nil,
    handler_name = nil,
    provider_settings = nil,
    provider_name = nil,
    interrupt_stream = nil,  -- function to interrupt the stream query
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
        return _("No configuration found. Please set up configuration.lua")
    end

    if CONFIGURATION and CONFIGURATION.provider_settings then

        --- Check if the provider is set in the configuration
        if CONFIGURATION.provider_settings and CONFIGURATION.provider_settings[provider_name] then
            self.provider_settings = CONFIGURATION.provider_settings[provider_name]
        else
            return string.format(
                _("Provider settings not found for: %s. Please check your configuration.lua file."),
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
                _("Handler not found for: %s. Please ensure the handler exists in api_handlers directory."),
                self.handler_name)
        end
    else
        return _("No provider set in configuration.lua. Please set the provider and provider_settings for %s.")
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
        return "", "Assitant: not configured."
    end

    local infomsg = InfoMessage:new{
      icon = "book.opened",
      text = string.format("%s\n️☁️ %s\n⚡ %s", title or _("Querying AI ..."),
            self.provider_name, self.provider_settings.model),
    }

    UIManager:show(infomsg)
    self.handler:setTrapWidget(infomsg)
    local res, err = self.handler:query(message_history, self.provider_settings)
    self.handler:resetTrapWidget()
    UIManager:close(infomsg)

    if type(res) == "function" then
        -- If the response is a function, it means it's a streaming response
        res = self:processStream(res)
    end

    if err ~= nil then
        return "", tostring(err)
    end
    return res
end



function Querier:processStream(bgQuery)
    
    local pid, parent_read_fd = ffiutil.runInSubProcess(bgQuery, true) -- pipe: true

    if not pid then
        logger.warn("Failed to start background query process.")
        return nil,  "Failed to start subprocess for request"
    end

    logger.info("Background query process started with PID:", pid)
    local _coroutine = coroutine.running()  
  
    self.interrupt_stream = function()  
        coroutine.resume(_coroutine, false)  
    end  
  
    local collect_interval_sec = 5 -- collect cancelled cmd every 5 second, no hurry
    local check_interval_sec = 0.125 -- Initial check interval: 125ms  
    local chunksize = 1024
    local completed = false  
    local buffer = ffi.new('char[?]', chunksize, {0})
    local result_buffer = {}  -- 
    local partial_data = ""   -- Buffer for incomplete line data

    while true do  

        if ffiutil.isSubProcessDone(pid) or completed then
            logger.info("Subprocess completed, exiting loop")
            break
        end
  
        -- Schedule next check and yield control  
        local go_on_func = function() coroutine.resume(_coroutine, true) end  
        UIManager:scheduleIn(check_interval_sec, go_on_func)  
        local go_on = coroutine.yield()  
  
        if not go_on then -- User interruption  
            UIManager:unschedule(go_on_func)  
            break  
        end  

        local readsize = ffiutil.getNonBlockingReadSize(parent_read_fd) 
        -- logger.info("Read size:", readsize)
        if readsize > 0 then
            local bytes_read = tonumber(C.read(parent_read_fd, ffi.cast('void*', buffer), chunksize))
            if bytes_read < 0 then
                local err = ffi.errno()
                logger.warn("readAllFromFD() error: " .. ffi.string(C.strerror(err)))
                break
            elseif bytes_read == 0 then -- EOF, no more data to read
                completed = true
                break
            else
                -- Convert binary data to string and append to partial buffer
                local data_chunk = ffi.string(buffer, bytes_read)
                partial_data = partial_data .. data_chunk
                
                -- Process complete lines
                while true do
                    -- Find the next newline character
                    local line_end = partial_data:find("[\r\n]")
                    if not line_end then break end  -- No complete line yet, continue reading
                    
                    -- Extract the complete line
                    local line = partial_data:sub(1, line_end - 1)
                    partial_data = partial_data:sub(line_end + 1)
                    
                    -- Check if this is an SSE data line
                    if line:sub(1, 6) == "data: " then
                        -- Clean up the JSON string (remove "data:" prefix and trim whitespace)
                        local json_str = line:sub(7):gsub("^%s+", ""):gsub("%s+$", "")

                        if json_str == '[DONE]' then break end
                        -- Safely parse the JSON
                        local ok, event = pcall(json.decode, json_str)
                        if ok and event and event.choices and #event.choices > 0 and event.choices[1].delta then
                            local content = event.choices[1].delta.content
                            if content then
                                table.insert(result_buffer, content)
                            end
                            -- logger.info("Parsed content:", content)
                            io.stdout:write(content)  -- Output to console
                        end
                    elseif line:sub(1, 7) == "ERROR: " then
                        -- If we encounter an error line, log it and break
                        local error_message = line:sub(8)
                        logger.warn("Error from subprocess:", error_message)
                        table.insert(result_buffer, error_message)
                        break
                    end
                end
            end
        end
    end

    -- read loop ended, clean up subprocess
    ffiutil.terminateSubProcess(pid)
    local collect_and_clean
    collect_and_clean = function()
        if ffiutil.isSubProcessDone(pid) then
            if parent_read_fd then
                ffiutil.readAllFromFD(parent_read_fd) -- close it
            end
            logger.dbg("collected previously dismissed subprocess")
        else
            if parent_read_fd and ffiutil.getNonBlockingReadSize(parent_read_fd) ~= 0 then
                -- If subprocess started outputting to fd, read from it,
                -- so its write() stops blocking and subprocess can exit
                ffiutil.readAllFromFD(parent_read_fd)
                -- We closed our fd, don't try again to read or close it
                parent_read_fd = nil
            end
            -- reschedule to collect it
            UIManager:scheduleIn(collect_interval_sec, collect_and_clean)
            logger.dbg("previously dismissed subprocess not yet collectable")
        end
    end
    UIManager:scheduleIn(collect_interval_sec, collect_and_clean)

    return table.concat(result_buffer) 
end

return Querier
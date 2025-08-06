--- Querier module for handling AI queries with dynamic provider loading
local _ = require("gettext")
local InfoMessage = require("ui/widget/infomessage")
local InputText = require("ui/widget/inputtext")
local UIManager = require("ui/uimanager")
local logger = require("logger")
local json = require("json")
local ffi = require("ffi")
local ffiutil = require("ffi/util")

-- InputText class for handling streaming input text
-- ignores tap events
local StreamInputText = InputText:extend{}
function StreamInputText:init() InputText.init(self) end
function StreamInputText:onTapTextBox(arg, ges) return true end

local Querier = {
    handler = nil,
    handler_name = nil,
    provider_settings = nil,
    provider_name = nil,
    interrupt_stream = nil,  -- function to interrupt the stream query
    interrupted = false,  -- flag to indicate if the stream was interrupted
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

    -- If the response is a function, it means it's a streaming response
    if type(res) == "function" then
        self:reset_interrupt()  -- Reset interrupt state before starting a stream
        local InputDialog = require("ui/widget/inputdialog")
        local streamDialog = InputDialog:new{
            inputtext_class = StreamInputText,
            readonly = false,
            skip_first_show_keyboard = true,
            keyboard_visible = false,
            fullscreen = false,
            allow_newline = true,
            add_nav_bar = false,
            cursor_at_end = true,
            add_scroll_buttons = true,
            deny_keyboard_hiding = true,
            use_available_height = true,
            condensed   = true,
            title = _("Stream Response"),
            buttons = {
                {
                    {
                        text = _("Cancel"),
                        id = "close",
                        callback = function()
                            self.interrupted = true
                            if self.interrupt_stream then
                                self.interrupt_stream()
                            end
                        end,
                    },
                }
            }
        }
        streamDialog.onShowKeyboard = function()
            -- Prevent the dialog from closing on button press
            return
        end
        UIManager:show(streamDialog)
        streamDialog:addTextToInput(infomsg.text .. "\n\n")
        res = self:processStream(res, function (content) -- replace with result from stream
            streamDialog:addTextToInput(content)
        end)
        UIManager:close(streamDialog)
    end

    if self.interrupted then
        self:reset_interrupt()  -- Reset interrupt state after processing
        return "", _("Stream interrupted by user.")
    end

    if err ~= nil then
        return "", tostring(err)
    end
    return res
end

function Querier:reset_interrupt()
    self.interrupted = false
    self.interrupt_stream = nil
end

function Querier:processStream(bgQuery, trunk_callback)
    local pid, parent_read_fd = ffiutil.runInSubProcess(bgQuery, true) -- pipe: true

    if not pid then
        logger.warn("Failed to start background query process.")
        return nil,  "Failed to start subprocess for request"
    end

    -- logger.info("Background query process started with PID:", pid)
    local _coroutine = coroutine.running()  
  
    self.interrupt_stream = function()  
        coroutine.resume(_coroutine, false)  
    end  
  
    local collect_interval_sec = 5 -- collect cancelled cmd every 5 second, no hurry
    local check_interval_sec = 0.125 -- Initial check interval: 125ms  
    local chunksize = 1024 * 4 -- 4KB buffer size for reading data
    local completed = false     -- Flag to indicate if the reading is completed
    local buffer = ffi.new('char[?]', chunksize, {0}) -- Buffer for reading data
    local result_buffer = {}  -- Buffer for storing results
    local partial_data = ""   -- Buffer for incomplete line data

    while true do  

        if completed then break end
  
        -- Schedule next check and yield control  
        local go_on_func = function() coroutine.resume(_coroutine, true) end  
        UIManager:scheduleIn(check_interval_sec, go_on_func)  
        local go_on = coroutine.yield()  
  
        if not go_on then -- User interruption  
            logger.info("User interrupted the stream processing")
            UIManager:unschedule(go_on_func)  
            break  
        end  

        local readsize = ffiutil.getNonBlockingReadSize(parent_read_fd) 
        -- logger.info("Read size:", readsize)
        if readsize > 0 then
            local bytes_read = tonumber(ffi.C.read(parent_read_fd, ffi.cast('void*', buffer), chunksize))
            if bytes_read < 0 then
                local err = ffi.errno()
                logger.warn("readAllFromFD() error: " .. ffi.string(ffi.C.strerror(err)))
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
                        if ok and event then
                        
                            local content
                            if event.choices and #event.choices > 0 and event.choices[1].delta then
                                -- openai API
                                content = event.choices[1].delta.content
                            elseif event.candidates and #event.candidates > 0 and event.candidates[1].content then 
                                -- gemini API
                                content = event.candidates[1].content.parts[1].text
                            elseif event.content and #event.content > 0 and event.content[1] then
                                -- Anthropic Claude (Messages API)
                                content = event.content[1].text
                            else
                                logger.warn("Unexpected event format:", json_str)
                                content = json_str
                            end
                                
                            if content then
                                table.insert(result_buffer, content)
                                if trunk_callback then
                                    trunk_callback(content)  -- Output to trunk callback
                                end
                            end
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
        elseif readsize == 0 then
            -- No data to read, check if subprocess is done
            if ffiutil.isSubProcessDone(pid) then
                completed = true
                logger.info("Subprocess done, exiting read loop")
            end
        else
            -- Error reading from the file descriptor
            local err = ffi.errno()
            logger.warn("Error reading from parent_read_fd:", err, ffi.string(ffi.C.strerror(err)))
            break
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
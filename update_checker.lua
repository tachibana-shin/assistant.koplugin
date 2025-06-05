local http = require("socket.http")
local ltn12 = require("ltn12")
local json = require("json")
local meta = require("_meta")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local logger = require("logger")
local _ = require("gettext")
local Screen = require("device").screen

local function checkForUpdates()

  local success, CONFIGURATION = pcall(function() return require("configuration") end)
  if success and CONFIGURATION and CONFIGURATION.features and CONFIGURATION.features.updater_disabled then
    return
  end

  UIManager:show(InfoMessage:new{
    text = _("Checking update for assistant.koplugin"),
    timeout = 1
  },nil,nil,0,Screen:scaleBySize(-80))
  UIManager:tickAfterNext(function()
    local response_body = {}
    local _, code = http.request {
      url = "https://api.github.com/repos/omer-faruq/assistant.koplugin/releases/latest",
      headers = {
          ["Accept"] = "application/vnd.github.v3+json"
      },
      sink = ltn12.sink.table(response_body)
    }

    if code == 200 then
      local data = table.concat(response_body)
      local parsed_data = json.decode(data)
      local latest_version = parsed_data.tag_name -- e.g., "v0.9"
      
      -- Safe version comparison
      if latest_version then
        local stripped_latest_version = latest_version:match("^v(.+)$")
        if stripped_latest_version then
          local latest_number = tonumber(stripped_latest_version)
          if latest_number and meta.version and latest_number > meta.version then
            -- Show notification to the user if a new version is available
            local message = "A new version of the " .. meta.fullname .. " plugin (" .. latest_version .. ") is available. Please update!"
            local info_message = InfoMessage:new{
                text = message,
		show_delay = 0.1, -- Ensure the message shown is scheduled
                timeout = 5 -- Display message for 5 seconds
            }
            UIManager:show(info_message,nil,nil,0,Screen:scaleBySize(-80))
          end
        end
      end
    else
      logger.warn("Failed to check for updates. HTTP code:", code)
    end
  end)
end

return {
  checkForUpdates = checkForUpdates
}

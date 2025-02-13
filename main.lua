local Device = require("device")
local InputContainer = require("ui/widget/container/inputcontainer")
local NetworkMgr = require("ui/network/manager")
local _ = require("gettext")

local showChatGPTDialog = require("dialogs")
local UpdateChecker = require("update_checker")

local Assistant = InputContainer:new {
  name = "Assistant",
  is_doc_only = true,
}

-- Load Configuration
local CONFIGURATION = nil
local success, result = pcall(function() return require("configuration") end)
if success then
  CONFIGURATION = result
else
  print("configuration.lua not found, skipping...")
end

-- Flag to ensure the update message is shown only once per session
local updateMessageShown = false

function Assistant:init()
  -- Assistant button
  self.ui.highlight:addToHighlightDialog("assistant", function(_reader_highlight_instance)
    return {
      text = _("Assistant"),
      enabled = Device:hasClipboard(),
      callback = function()
        NetworkMgr:runWhenOnline(function()
          if not updateMessageShown then
            UpdateChecker.checkForUpdates()
            updateMessageShown = true
          end
          showChatGPTDialog(self.ui, _reader_highlight_instance.selected_text.text)
        end)
      end,
    }
  end)

  -- Translation button (if show_translation_on_main_popup = true)
  if CONFIGURATION and CONFIGURATION.features and CONFIGURATION.features.show_translation_on_main_popup then
    self.ui.highlight:addToHighlightDialog("assistant_translate", function(_reader_highlight_instance)
      return {
        text = _("Translate (AI)"),
        enabled = Device:hasClipboard(),
        callback = function()
          NetworkMgr:runWhenOnline(function()
            showChatGPTDialog(self.ui, _reader_highlight_instance.selected_text.text, "translate")
          end)
        end,
      }
    end)
  end

  -- Add Custom buttons (ones with show_on_main_popup = true)
  if CONFIGURATION and CONFIGURATION.features and CONFIGURATION.features.prompts then
    for prompt_type, prompt in pairs(CONFIGURATION.features.prompts) do
      if prompt.show_on_main_popup then
        self.ui.highlight:addToHighlightDialog("assistant_" .. prompt_type, function(_reader_highlight_instance)
          return {
            text = _(prompt.text.." (AI)"),
            enabled = Device:hasClipboard(),
            callback = function()
              NetworkMgr:runWhenOnline(function()
                showChatGPTDialog(self.ui, _reader_highlight_instance.selected_text.text, prompt_type)
              end)
            end,
          }
        end)
      end
    end
  end
end

return Assistant
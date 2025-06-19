local Device = require("device")
local logger = require("logger")
local InputContainer = require("ui/widget/container/inputcontainer")
local NetworkMgr = require("ui/network/manager")
local Dispatcher = require("dispatcher")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local Trapper = require("ui/trapper")
local LuaSettings = require("luasettings")
local DataStorage = require("datastorage")
local RadioButtonWidget = require("ui/widget/radiobuttonwidget")
local _ = require("gettext")

local ChatGPTDialog = require("dialogs")
local UpdateChecker = require("update_checker")

local Assistant = InputContainer:new {
  name = "Assistant",
  is_doc_only = true,
  settings_file = DataStorage:getSettingsDir() .. "/assistant.lua",
  settings = nil,
  querier = nil,
}

-- Load Configuration
local CONFIGURATION = nil
local success, result = pcall(function() return require("configuration") end)
if success then
  CONFIGURATION = result
else
  logger.warn("configuration.lua not found, skipping...")
end

-- Flag to ensure the update message is shown only once per session
local updateMessageShown = false

function Assistant:onDispatcherRegisterActions()
  -- Register main AI ask action
  Dispatcher:registerAction("ai_ask_question", {
    category = "none", 
    event = "AskAIQuestion", 
    title = _("Ask AI Question"), 
    general = true
  })
  
  -- Register AI recap action
  if CONFIGURATION and CONFIGURATION.features and CONFIGURATION.features.enable_AI_recap then
    Dispatcher:registerAction("ai_recap", {
      category = "none", 
      event = "AskAIRecap", 
      title = _("AI Recap"), 
      general = true,
      separator = true
    })
  end
  
  -- Note: Dictionary and custom prompt actions are not registered as they require highlighted text
  -- They remain available through the highlight dialog and main AI dialog
end

function Assistant:addToMainMenu(menu_items)
    menu_items.assitant = {
        text = "Assitant Provider Switch",
        -- in which menu this should be appended
        sorting_hint = "more_tools",
        -- a callback when tapping
        callback = function ()
          self:showProviderSwitch()
        end
    }
end

function Assistant:showProviderSwitch()
    local model_provider = self:getModelProvider()
    local provider_settings = CONFIGURATION and CONFIGURATION.provider_settings or {}

    -- sort keys of provider_settings
    local provider_keys = {}
    for key, _ in pairs(provider_settings) do
      table.insert(provider_keys, key)
    end
    table.sort(provider_keys)

    local radio_buttons = {}
    for _, key in ipairs(provider_keys) do
      table.insert(radio_buttons, {{
        text = string.format("%s (%s)", key, provider_settings[key].model),
        provider = key, -- note: this `provider` field belongs to the RadioButtonWidget, not our AI Model provider.
        checked = (key == model_provider),
      }})
    end

    -- Show the RadioButtonWidget dialog for selecting AI provider
    UIManager:show(RadioButtonWidget:new{
      title_text = _("Select AI Provider Profile"),
      info_text = _("Use the selected provider (overrides the provider in configuration.lua)"),
      cancel_text = _("Close"),
      ok_text = _("Apply"),
      width_factor = 0.9,
      radio_buttons = radio_buttons,
      callback = function(radio)
        if radio.provider ~= model_provider then
          self.settings:saveSetting("provider", radio.provider)
          self.querier:load_model(radio.provider)
          self.updated = true -- mark settings as updated
          UIManager:show(InfoMessage:new{
            icon = "notice-info",
            text = string.format(_("AI provider changed to: %s (%s)"),
                                radio.provider,
                                provider_settings[radio.provider].model),
          })
        end
      end,
    })
end

function Assistant:getModelProvider()

  if not CONFIGURATION then
    error("Configuration not found. Please set up configuration.lua first.")
  end

  local provider = self.settings:readSetting("provider", CONFIGURATION.provider)
  if CONFIGURATION and CONFIGURATION.provider_settings then
    if not CONFIGURATION.provider_settings[provider] then
      -- neither the provider is set in settings nor in CONFIGURATION.provider is corrent
      -- so we use the default from configuration.lua
      local function first_key(t)
        for k, _ in pairs(t) do
          return k
        end
      end
      logger.warn("Invalid provider setting found, using default: ", provider)
      provider = first_key(CONFIGURATION.provider_settings)
      self.settings:saveSetting("provider", provider)
      logger.info("Using default provider: ", provider)
    end
  else
    error("No provider settings found") 
  end
  return provider
end

-- Flush settings to disk, triggered by koreader
function Assistant:onFlushSettings()
    if self.updated then
        self.settings:flush()
        self.updated = nil
    end
end

function Assistant:init()

  -- skip initialization if configuration.lua is not found
  if not CONFIGURATION then
    logger.error("Configuration not found. Please set up configuration.lua first.")
    return
  end

  -- Register actions with dispatcher for gesture assignment
  self:onDispatcherRegisterActions()

  -- Register model switch to main menu (under "More tools")
  self.ui.menu:registerToMainMenu(self)

  -- Initialize settings file
  self.settings = LuaSettings:open(self.settings_file)
  if next(self.settings.data) == nil then
    self.updated = true -- first run, force flush
    self.settings:saveSetting("provider", CONFIGURATION.provider)
    logger.info("Assistant settings initialized with provider: ", CONFIGURATION.provider)
  end

  -- Load the model provider from settings or default configuration
  self.querier = require("gpt_query"):new()
  self.querier:load_model(self:getModelProvider())
  
  -- Assistant button
  self.ui.highlight:addToHighlightDialog("assistant", function(_reader_highlight_instance)
    return {
      text = _("Assistant"),
      enabled = Device:hasClipboard(),
      callback = function()
        if not CONFIGURATION then
          UIManager:show(InfoMessage:new{
            icon = "notice-warning",
            text = _("Configuration not found. Please set up configuration.lua first.")
          })
          return
        end
        NetworkMgr:runWhenOnline(function()
          if not updateMessageShown then
            UpdateChecker.checkForUpdates()
            updateMessageShown = true
          end
          Trapper:wrap(function()
            -- Show the main AI dialog with highlighted text
            ChatGPTDialog.showChatGPTDialog(self, _reader_highlight_instance.selected_text.text)
          end)
        end)
      end,
    }
  end)
  -- Dictionary button
  if CONFIGURATION and CONFIGURATION.features and CONFIGURATION.features.dictionary_translate_to and CONFIGURATION.features.show_dictionary_button_in_main_popup then
    self.ui.highlight:addToHighlightDialog("dictionary", function(_reader_highlight_instance)
      return {
          text = _("Dictionary").." (AI)",
          enabled = Device:hasClipboard(),
          callback = function()
              NetworkMgr:runWhenOnline(function()
                local showDictionaryDialog = require("dictdialog")
                Trapper:wrap(function()
                  showDictionaryDialog(self, _reader_highlight_instance.selected_text.text)
                end)
              end)
          end,
      }
    end)
  end
  
  -- Recap Feature
  if CONFIGURATION and CONFIGURATION.features and CONFIGURATION.features.enable_AI_recap then
    local ReaderUI    = require("apps/reader/readerui")
    local ConfirmBox  = require("ui/widget/confirmbox")
    local T 		      = require("ffi/util").template
    local lfs         = require("libs/libkoreader-lfs")   -- for file attributes
    local DocSettings = require("docsettings")			      -- for document progress
  
    -- Save a reference to the original doShowReader method.
    local original_doShowReader = ReaderUI.doShowReader
  
    -- Override the ReaderUI:doShowReader method.
    function ReaderUI:doShowReader(file, provider, seamless)
      -- Get file metadata; here we use the file's "access" attribute.
      local attr = lfs.attributes(file)
      local lastAccess = attr and attr.access or nil
  
      if lastAccess and lastAccess > 0 then -- Has been opened
        local doc_settings = DocSettings:open(file)
        local percent_finished = doc_settings:readSetting("percent_finished")
        local timeDiffHours = (os.time() - lastAccess) / 3600.0
  
        if timeDiffHours >= 28 and percent_finished <= 0.95 then -- More than 28hrs since last open and less than 95% complete
          -- Construct the message to display.
          local doc_props = doc_settings:child("doc_props")
          local title = doc_props:readSetting("title", "Unknown Title")
          local authors = doc_props:readSetting("authors", "Unknown Author")
          local message = string.format(_("Do you want an AI Recap?\nFor %s by %s.\nLast read %.0f hours ago."), title, authors, timeDiffHours) -- can add in percent_finished too
  
          -- Display the request popup using ConfirmBox.
          UIManager:show(ConfirmBox:new{
            text            = T(_(message)),
            ok_text         = _("Yes"),
            ok_callback     = function()
              NetworkMgr:runWhenOnline(function()
                local showRecapDialog = require("recapdialog")
                Trapper:wrap(function()
                  showRecapDialog(self, title, authors, percent_finished)
                end)
              end)
            end,
            cancel_text     = _("No"),
          })
        end
      end
      original_doShowReader(self, file, provider, seamless)
    end
  end

  -- Add Custom buttons to main select popup menu
  -- prompts with `show_on_main_popup = true`
  if CONFIGURATION and CONFIGURATION.features and CONFIGURATION.features.prompts then
    -- Create a sorted list of prompts
    local sorted_prompts = {}
    for prompt_idx, prompt in pairs(CONFIGURATION.features.prompts) do
      if prompt.show_on_main_popup then
        table.insert(sorted_prompts, {idx = prompt_idx, config = prompt})
      end
    end
    
    -- Sort by order value, default to 1000 if not specified
    table.sort(sorted_prompts, function(a, b)
      local order_a = a.config.order or 1000
      local order_b = b.config.order or 1000
      return order_a < order_b
    end)
    
    -- Add buttons in sorted order
    for _, tab in ipairs(sorted_prompts) do
      -- Use order in the index for proper sorting (pad with zeros for consistent sorting)
      self.ui.highlight:addToHighlightDialog(
        string.format("assistant_%02d_%s", tab.config.order or 1000, tab.idx),
        function(_reader_highlight_instance)
          return {
            text = tab.config.text.." (AI)",  -- append "(AI)" to identify as our function
            enabled = Device:hasClipboard(),
            callback = function()
              NetworkMgr:runWhenOnline(function()
                Trapper:wrap(function()
                  ChatGPTDialog.showProcCustomPrompt(self, 
                    _reader_highlight_instance.selected_text.text,
                    tab.idx)
                end)
              end)
            end,
          }
        end)
    end
  end
end

function Assistant:onDictButtonsReady(dict_popup, buttons)
  if CONFIGURATION and CONFIGURATION.features and CONFIGURATION.features.show_dictionary_button_in_dictionary_popup then
    table.insert(buttons, 1, {{
        id = "assistant_dictionary",
        text = _("Dictionary").." (AI)",
        font_bold = false,
        callback = function()
            NetworkMgr:runWhenOnline(function()
                local showDictionaryDialog = require("dictdialog")
                Trapper:wrap(function()
                  showDictionaryDialog(self, dict_popup.word)
                end)
            end)
        end,
    }})
  end
end

-- Event handlers for gesture-triggered actions
function Assistant:onAskAIQuestion()
  if not CONFIGURATION then
    UIManager:show(InfoMessage:new{
      icon = "notice-warning",
      text = _("Configuration not found. Please set up configuration.lua first.")
    })
    return true
  end
  
  NetworkMgr:runWhenOnline(function()
    if not updateMessageShown then
      UpdateChecker.checkForUpdates()
      updateMessageShown = true
    end
    -- Show dialog without requiring highlighted text
    ChatGPTDialog.showChatGPTDialog(self, nil)
  end)
  return true
end

function Assistant:onAskAIRecap()
  if not CONFIGURATION then
    UIManager:show(InfoMessage:new{
      icon = "notice-warning",
      text = _("Configuration not found. Please set up configuration.lua first.")
    })
    return true
  end
  
  if not CONFIGURATION.features or not CONFIGURATION.features.enable_AI_recap then
    UIManager:show(InfoMessage:new{
      icon = "notice-warning",
      text = _("AI Recap feature is not enabled in configuration.")
    })
    return true
  end
  
  NetworkMgr:runWhenOnline(function()
    if not updateMessageShown then
      UpdateChecker.checkForUpdates()
      updateMessageShown = true
    end
    
    -- Get current book information
    local DocSettings = require("docsettings")
    local doc_settings = DocSettings:open(self.ui.document.file)
    local percent_finished = doc_settings:readSetting("percent_finished") or 0
    local doc_props = doc_settings:child("doc_props")
    local title = doc_props:readSetting("title") or self.ui.document:getProps().title or _("Unknown Title")
    local authors = doc_props:readSetting("authors") or self.ui.document:getProps().authors or _("Unknown Author")
    
    -- Show recap dialog
    local showRecapDialog = require("recapdialog")
    Trapper:wrap(function()
      showRecapDialog(self, title, authors, percent_finished)
    end)
  end)
  return true
end

return Assistant

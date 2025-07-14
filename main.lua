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
local ConfirmBox  = require("ui/widget/confirmbox")
local T 		      = require("ffi/util").template
local _ = require("gettext")
local FrontendUtil = require("util")

local AssistantDialog = require("dialogs")
local UpdateChecker = require("update_checker")
local Prompts = require("prompts")

local Assistant = InputContainer:new {
  name = "Assistant",
  is_doc_only = true,
  settings_file = DataStorage:getSettingsDir() .. "/assistant.lua",
  settings = nil,
  querier = nil,
  updated = false, -- flag to track if settings were updated
  assitant_dialog = nil, -- reference to the main dialog instance
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
  
  -- Note: AI Dictionary is integrated by overriding the translate() method in ReaderHighlight
  -- Users can select "Translate" in Long press on text gestures to use AI Dictionary
  
  -- Note: Custom prompt actions are not registered as they require highlighted text
  -- They remain available through the highlight dialog and main AI dialog
end

function Assistant:addToMainMenu(menu_items)
    menu_items.assitant_provider_switch = {
        text = _("Assistant Provider Switch"),
        sorting_hint = "more_tools",
        callback = function ()
          self:showProviderSwitch()
        end
    }

    if CONFIGURATION and CONFIGURATION.features and CONFIGURATION.features.dictionary_translate_to then
      menu_items.assitant_dictionary_override = {
          text = _("Use AI Assistant for 'Translate'"),
          checked_func = function()
              return self.settings:readSetting("ai_dictionary_override") or false
          end,
          callback = function()
              local current_setting = self.settings:readSetting("ai_dictionary_override") or false
              local new_setting = not current_setting
              self.settings:saveSetting("ai_dictionary_override", new_setting)
              self.updated = true

              UIManager:show(InfoMessage:new{
                  text = new_setting and _("AI Assistant override enabled.") or _("AI Assistant override disabled.")
              })

              self:applyOrRemoveTranslateOverride()
          end,
          sorting_hint = "more_tools",
      }
    end
end

function Assistant:showProviderSwitch()

    if not CONFIGURATION or not CONFIGURATION.provider_settings then
      UIManager:show(InfoMessage:new{
        icon = "notice-warning",
        text = _("Configuration not found or provider settings are missing.")
      })
      return
    end

    local current_provider = self.querier.provider_name
    local provider_settings = CONFIGURATION and CONFIGURATION.provider_settings or {}

    -- sort keys of provider_settings
    local provider_keys = {}
    for key, tab in pairs(provider_settings) do
      if tab.visible ~= false then
        table.insert(provider_keys, key)
      end
    end
    table.sort(provider_keys)

    local radio_buttons = {}
    for _, key in ipairs(provider_keys) do
      table.insert(radio_buttons, {{
        text = string.format("%s (%s)", key, provider_settings[key].model),
        provider = key, -- note: this `provider` field belongs to the RadioButtonWidget, not our AI Model provider.
        checked = (key == current_provider),
      }})
    end

    -- Show the RadioButtonWidget dialog for selecting AI provider
    UIManager:show(RadioButtonWidget:new{
      title_text = _("Select AI Provider Profile"),
      info_text = _("Use the selected provider (overrides the provider in configuration.lua)"),
      cancel_text = _("Close"),
      ok_text = _("OK"),
      width_factor = 0.9,
      radio_buttons = radio_buttons,
      callback = function(radio)
        if radio.provider ~= current_provider then
          self.settings:saveSetting("provider", radio.provider)
          self.updated = true
          self.querier:load_model(radio.provider)
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

  if not (CONFIGURATION and CONFIGURATION.provider_settings) then
    error("Configuration not found. Please set up configuration.lua first.")
  end

  local provider_settings = CONFIGURATION.provider_settings -- provider settings table from configuration.lua
  local setting_provider = nil -- provider name from LuaSettings
  
  -- settings may not be initialized, so check if self.settings exists
  if self.settings and next(self.settings.data) ~= nil then
    setting_provider = self.settings:readSetting("provider")
  end

  if setting_provider and provider_settings[setting_provider] then
    -- If the setting provider is valid, use it
    return setting_provider
  else
    -- If the setting provider is invalid, try to find one from configuration

    local conf_provider = CONFIGURATION.provider -- provider name from configuration.lua

    if provider_settings[conf_provider] then
      -- if the configuration provider is valid, use it
      setting_provider = conf_provider
    else
      -- still invalid, try to find the one defined with `default = true`
      for key, tab in pairs(CONFIGURATION.provider_settings) do
        if tab.default then
          setting_provider = key
          break
        end
      end
      
      -- still invalid (none of them defined `default`)
      if not setting_provider then
        -- log a warning and use a random one available provider
        local function first_key(t) for k, _ in pairs(t) do return k end end
        setting_provider = first_key(CONFIGURATION.provider_settings)
        logger.warn("Invalid provider setting found, using a random one: ", setting_provider)
      end
    end
    self.settings:saveSetting("provider", setting_provider)
    self.updated = true -- mark settings as updated
  end
  return setting_provider
end

-- Flush settings to disk, triggered by koreader
function Assistant:onFlushSettings()
    if self.updated then
        self.settings:flush()
        self.updated = nil
    end
end

function Assistant:init()
  -- init settings
  self.settings = LuaSettings:open(self.settings_file)

  -- Register actions with dispatcher for gesture assignment
  self:onDispatcherRegisterActions()

  -- Register model switch to main menu (under "More tools")
  self.ui.menu:registerToMainMenu(self)

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
            self.assitant_dialog:show(_reader_highlight_instance.selected_text.text)
          end)
        end)
      end,
    }
  end)

  -- skip initialization if configuration.lua is not found
  if not CONFIGURATION then
    logger.warn("Configuration not found. Please set up configuration.lua first.")
    return
  end

  -- Conditionally override translate method based on user setting
  self:applyOrRemoveTranslateOverride()

  -- Load the model provider from settings or default configuration
  self.querier = require("gpt_query"):new()
  self.querier:load_model(self:getModelProvider())

  self.assitant_dialog = AssistantDialog:new(self, CONFIGURATION)

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
    -- avoid recurive overrides here
    -- pulgin is loaded on every time file opened
    if not ReaderUI._original_doShowReader then 
      -- Save a reference to the original doShowReader method.
      ReaderUI._original_doShowReader = ReaderUI.doShowReader

      local assitant = self -- reference to the Assistant instance
      local lfs         = require("libs/libkoreader-lfs")   -- for file attributes
      local DocSettings = require("docsettings")			      -- for document progress
    
      -- Override to hook into the reader's doShowReader method.
      function ReaderUI:doShowReader(file, provider, seamless)

        -- Get file metadata; here we use the file's "access" attribute.
        local attr = lfs.attributes(file)
        local lastAccess = attr and attr.access or nil
    
        if lastAccess and lastAccess > 0 then -- Has been opened
          local doc_settings = DocSettings:open(file)
          local percent_finished = doc_settings:readSetting("percent_finished") or 0
          local timeDiffHours = (os.time() - lastAccess) / 3600.0
    
          -- More than 28hrs since last open and less than 95% complete
          -- percent = 0 may means the book is not started yet, the docsettings maybe empty
          if timeDiffHours >= 28 and percent_finished > 0 and percent_finished <= 0.95 then 
            -- Construct the message to display.
            local doc_props = doc_settings:child("doc_props")
            local title = doc_props:readSetting("title", "Unknown Title")
            local authors = doc_props:readSetting("authors", "Unknown Author")
            local message = string.format(T(_("Do you want an AI Recap?\nFor %s by %s.\nLast read %.0f hours ago.")), title, authors, timeDiffHours) -- can add in percent_finished too
    
            -- Display the request popup using ConfirmBox.
            UIManager:show(ConfirmBox:new{
              text            = message,
              ok_text         = _("Yes"),
              ok_callback     = function()
                NetworkMgr:runWhenOnline(function()
                  local showRecapDialog = require("recapdialog")
                  Trapper:wrap(function()
                    showRecapDialog(assitant, title, authors, percent_finished)
                  end)
                end)
              end,
              cancel_text     = _("No"),
            })
          end
        end
        return ReaderUI._original_doShowReader(self, file, provider, seamless)
      end
    end
  end

  -- Add Custom buttons to main select popup menu
  local showOnMain = Prompts.getSortedCustomPrompts(function (prompt)
    if prompt.visible == false then
      return false
    end
    if prompt.show_on_main_popup then
      return true
    end
    return false -- only show if `show_on_main_popup` is true
  end) or {}

  -- Add buttons in sorted order
  for _, tab in ipairs(showOnMain) do
    -- Use order in the index for proper sorting (pad with zeros for consistent sorting)
    self.ui.highlight:addToHighlightDialog(
      string.format("assistant_%02d_%s", tab.order, tab.idx),
      function(_reader_highlight_instance)
        return {
          text = tab.text .. " (AI)",  -- append "(AI)" to identify as our function
          enabled = Device:hasClipboard(),
          callback = function()
            NetworkMgr:runWhenOnline(function()
              Trapper:wrap(function()
                self.assitant_dialog:showCustomPrompt(
                  _reader_highlight_instance.selected_text.text,
                  tab.idx)
              end)
            end)
          end,
        }
      end)
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
    -- Show dialog without highlighted text
    Trapper:wrap(function()
      self.assitant_dialog:show()
    end)
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

-- Override the translate method in ReaderHighlight to use AI Assistant
function Assistant:applyOrRemoveTranslateOverride()
  if not self.ui.highlight then
    logger.warn("ReaderHighlight not available, cannot apply or remove override")
    return
  end

  local Translator = require("ui/translator")

  -- Store original translate method if not already stored
  if not Translator._original_showTranslation then
    Translator._original_showTranslation = Translator.showTranslation
  end

  local should_override = CONFIGURATION and CONFIGURATION.features and CONFIGURATION.features.dictionary_translate_to and self.settings:readSetting("ai_dictionary_override")

  if should_override then
    -- Apply the override
    if Translator.showTranslation == Translator._original_showTranslation then
      self:_overrideTranslateMethod()
      logger.info("Assistant: translate method overridden with AI Assistant")
    end
  else
    -- Remove the override
    if Translator.showTranslation ~= Translator._original_showTranslation then
      -- Restore the original method
      Translator.showTranslation = Translator._original_showTranslation
      logger.info("Assistant: translate method restored")
    end
  end
end

function Assistant:_overrideTranslateMethod()
  
  local Translator = require("ui/translator")
  -- Override translate method with AI Assistant
  Translator.showTranslation = function(ts_self, text, detailed_view, source_lang, target_lang, from_highlight, index)
    if not CONFIGURATION then
      UIManager:show(InfoMessage:new{
        icon = "notice-warning",
        text = _("Configuration not found. Please set up configuration.lua first.")
      })
      return
    end
    
    NetworkMgr:runWhenOnline(function()
      Trapper:wrap(function()
        local words = FrontendUtil.splitToWords(text)
        -- splitToWords result like this: { "The", " ", "good", " ", "news" }
        if #words > 5 then
            self.assitant_dialog:showCustomPrompt(text, "translate")
        else
          -- Show AI Dictionary dialog
          local showDictionaryDialog = require("dictdialog")
          showDictionaryDialog(self, text)
        end
      end)
    end)
  end
  logger.info("Assistant: translate method overridden with AI Dictionary")
end

return Assistant

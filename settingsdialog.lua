--[[--
This widget displays a setting dialog.
]]

local FrontendUtil = require("util")
local Blitbuffer = require("ffi/blitbuffer")
local CenterContainer = require("ui/widget/container/centercontainer")
local CheckButton = require("ui/widget/checkbutton")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local InfoMessage = require("ui/widget/infomessage")
local Font = require("ui/font")
local InputDialog = require("ui/widget/inputdialog")
local ButtonDialog = require("ui/widget/buttondialog")
local LineWidget = require("ui/widget/linewidget")
local MovableContainer = require("ui/widget/container/movablecontainer")
local RadioButtonTable = require("ui/widget/radiobuttontable")
local TextBoxWidget = require("ui/widget/textboxwidget")
local Size = require("ui/size")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local _ = require("owngettext")
local T = require("ffi/util").template
local Screen = require("device").screen
local ffiutil = require("ffi/util")
local meta = require("_meta")
local logger = require("logger")

-- hack: the CheckButton callback does not include a reference to itself.
-- override to use our `xcallback` instead.
local xCheckButton = CheckButton:extend{}
function xCheckButton:onTapCheckButton()
    local ret = CheckButton.onTapCheckButton(self)
    if self.xcallback then self:xcallback() end
    return ret
end

local SettingsDialog = InputDialog:extend{
    title = _("Assistant Settings"),

    -- inited variables
    assistant = nil, -- reference to the main assistant object
    CONFIGURATION = nil,
    settings = nil,

    -- widgets
    buttons = nil,
    radio_buttons = nil,

    title_bar_left_icon = "appbar.menu",
    title_bar_left_icon_tap_callback = nil,
    -- title_bar_left_icon_tap_callback = function ()
    --     self:onShowMenu()
    -- end,
}

function SettingsDialog:init()

    self.title_bar_left_icon_tap_callback = function ()
        self:onShowMenu()
    end

    self.check_button_init_list = {
        {
            text = _("Always enable stream response"),
            checked = self.settings:readSetting("forced_stream_mode", true),
            callback = function(btn) 
                self.settings:saveSetting(btn.key, btn.checked)
                self.assistant.updated = true
            end
        },
        {
            text = _("Use AI Assistant for 'Translate'"),
            checked = self.settings:readSetting("ai_translate_override", false),
            callback = function(btn) 
                self.settings:saveSetting(btn.key, btn.checked)
                self.assistant.updated = true
                self.assistant:syncTranslateOverride()
            end
        },
        {
            text = _("Show Dictionary(AI) in Dictionary Popup"),
            checked = self.settings:readSetting("dict_popup_show_dictionary", true),
            callback = function(btn) 
                self.settings:saveSetting(btn.key, btn.checked)
                self.assistant.updated = true
            end
        },
        {
            text = _("Show Wikipedia(AI) in Dictionary Popup"),
            checked = self.settings:readSetting("dict_popup_show_wikipedia", true),
            callback = function(btn) 
                self.settings:saveSetting(btn.key, btn.checked)
                self.assistant.updated = true
            end
        },
        {
            text = _("Copy entered question to the clipboard"),
            checked = self.settings:readSetting("auto_copy_asked_question", true),
            callback = function(btn) 
                self.settings:saveSetting(btn.key, btn.checked)
                self.assistant.updated = true
            end
        },
        {
            text = _("Enable AI Recap"),
            checked = self.settings:readSetting("enable_recap", false),
            callback = function(btn) 
                self.settings:saveSetting(btn.key, btn.checked)
                self.assistant.updated = true
                local Dispatcher = require("dispatcher")
                if btn.checked then
                    UIManager:show(InfoMessage:new{ timeout = 3, text = _("AI Recap will be enabled the next time a book is opened.") })
                else
                    Dispatcher:removeAction("ai_recap")
                end
            end
        },
    }

    -- action buttons
    self.buttons = {{
        {
            id = "close",
            text = _("Close"),
            callback = function() UIManager:close(self) end
        }
    }}  

    -- init radio buttons for selecting AI Model provider
    self.radio_buttons = {} -- init radio buttons table
    self.description = _("Select the AI Model provider.")

    local columns = FrontendUtil.tableSize(self.CONFIGURATION.provider_settings) > 4 and 2 or 1 -- 2 columns if more than 4 providers, otherwise 1 column
    local buttonrow = {}
    for key, tab in ffiutil.orderedPairs(self.CONFIGURATION.provider_settings) do
        if not (tab.visible ~= nil and tab.visible == false) then -- skip `visible = false` providers
            if #buttonrow < columns then
                table.insert(buttonrow, {
                    text = columns == 1 and string.format("%s (%s)", key, tab.model) or key,
                    provider = key, -- note: this `provider` field belongs to the RadioButton, not our AI Model provider.
                    checked = (key == self.assistant.querier.provider_name),
                })
            end
            if #buttonrow == columns then
                table.insert(self.radio_buttons, buttonrow)
                buttonrow = {}
            end
        end
    end

    if #buttonrow > 0 then -- edge case: if there are remaining buttons in the last row
        table.insert(self.radio_buttons, buttonrow)
        buttonrow = {}
    end

    -- init title and buttons in base class
    InputDialog.init(self)
    self.element_width = math.floor(self.width * 0.9)

    self.radio_button_table = RadioButtonTable:new{
        radio_buttons = self.radio_buttons,
        width = self.element_width,
        face = Font:getFace("cfont", 18),
        sep_width = 0,
        focused = true,
        scroll = false,
        parent = self,
        button_select_callback = function(btn)
            self.settings:saveSetting("provider", btn.provider)
            self.assistant.updated = true
            self.assistant.querier:load_model(btn.provider)
        end
    }
    self.layout = {self.layout[#self.layout]} -- keep bottom buttons
    self:mergeLayoutInVertical(self.radio_button_table, #self.layout) -- before bottom buttons

    local vertical_span = VerticalSpan:new{
        width = Size.padding.large,
    }
    self.vgroup = VerticalGroup:new{
        align = "left",
        self.title_bar,
        vertical_span,
        CenterContainer:new{
            dimen = Geom:new{
                w = self.width,
                h = self.radio_button_table:getSize().h,
            },
            self.radio_button_table,
        },
        CenterContainer:new{
            dimen = Geom:new{
                w = self.width,
                h = Size.padding.large,
            },
            LineWidget:new{
                background = Blitbuffer.COLOR_DARK_GRAY,
                dimen = Geom:new{
                    w = self.element_width,
                    h = Size.line.medium,
                }
            },
        },
        vertical_span,
        CenterContainer:new{
            dimen = Geom:new{
                w = self.title_bar:getSize().w,
                h = self.button_table:getSize().h,
            },
            self.button_table,
        }
    }

    for _, btn in ipairs(self.check_button_init_list) do
        self:addWidget(xCheckButton:new{
            text = btn.text,
            face = Font:getFace("cfont", 18),
            checked = btn.checked,
            xcallback = btn.callback,
            parent = self,
        })
    end

    self.dialog_frame = FrameContainer:new{
        radius = Size.radius.window,
        bordersize = Size.border.window,
        padding = 0,
        margin = 0,
        background = Blitbuffer.COLOR_WHITE,
        self.vgroup,
    }
    self.movable = MovableContainer:new{
        self.dialog_frame,
    }
    self[1] = CenterContainer:new{
        dimen = Geom:new{
            w = Screen:getWidth(),
            h = Screen:getHeight(),
        },
        self.movable,
    }
    self:refocusWidget()
end

local MultiInputDialog = require("ui/widget/multiinputdialog")
local CopyMultiInputDialog = MultiInputDialog:extend{}
function CopyMultiInputDialog:onSwitchFocus(inputbox)
    MultiInputDialog.onSwitchFocus(self, inputbox)
    -- copy first field to the second
    if inputbox.idx == 2 and self.input_fields[1]:getText() ~= "" and inputbox:getText() == "" then
        inputbox:addChars(self.input_fields[1]:getText())
    end
end


function SettingsDialog:onShowMenu()
    local fontsize = self.assistant.settings:readSetting("response_font_size", 20)
    local dialog
    local buttons = {
        {{
            text_func = function()
                return T(_("Response Font Size: %1"), fontsize)
            end,
            align = "left",
            callback = function()
                UIManager:close(dialog)
                local SpinWidget = require("ui/widget/spinwidget")
                local widget = SpinWidget:new{
                    title_text = _("Response Font Size"),
                    value = fontsize,
                    value_min = 12, value_max = 30, default_value = 20,
                    keep_shown_on_apply = true,
                    callback = function(spin)
                        self.assistant.settings:saveSetting("response_font_size", spin.value)
                        self.assistant.updated = true
                    end,
                }
                UIManager:show(widget)
            end,
        }},
        {{
            text_func = function()
                return T(_("Response Language: %1"), self.assistant.settings:readSetting("response_language") or self.assistant.ui_language)
            end,
            align = "left",
            callback = function()
                UIManager:close(dialog)
                local langsetting
                langsetting = CopyMultiInputDialog:new{
                    description_margin = Size.margin.tiny,
                    description_padding = Size.padding.tiny,
                    -- bottom_v_padding = 0,
                    title = _("Response Language"),
                    fields = {
                        {
                            description = _("AI Response Language"),
                            text = self.assistant.settings:readSetting("response_language") or "",
                            hint = T(_("Leave blank to use: %1"), self.assistant.ui_language),
                        },
                        {
                            description = _("Dictionary Language"),
                            text = self.assistant.settings:readSetting("dict_language") or "",
                            hint = T(_("Leave blank to use: %1"), self.assistant.ui_language),
                        },
                    },
                    buttons = {
                        {
                            {
                                text = _("Cancel"),
                                id = "close",
                                callback = function()
                                    UIManager:close(langsetting)
                                end
                            },
                            {
                                text = _("Clear"),
                                callback = function()
                                    for i, f in ipairs(langsetting.input_fields) do  
                                        f:setText("")  
                                    end  
                                    if self._checkbtn_is_rtl then
                                        self._checkbtn_is_rtl.checked = false
                                        self._checkbtn_is_rtl:init()
                                    end

                                    UIManager:setDirty(langsetting, function()  
                                        return "ui", langsetting.dialog_frame.dimen  
                                    end)  
                                end
                            },
                            {
                                text = _("Save"),
                                callback = function(touchmenu_instance)
                                    local fields = langsetting:getFields()

                                    if fields[1] ~= "" then
                                        self.assistant.settings:saveSetting("response_language", fields[1])
                                        if touchmenu_instance then touchmenu_instance:updateItems() end
                                    else
                                        if self.assistant.settings:has("response_language") then
                                            self.assistant.settings:delSetting("response_language")
                                        end
                                    end

                                    if fields[2] ~= "" then
                                        self.assistant.settings:saveSetting("dict_language", fields[2])
                                    else
                                        if self.assistant.settings:has("dict_language") then
                                            self.assistant.settings:delSetting("dict_language")
                                        end
                                    end

                                    if self._checkbtn_is_rtl then
                                        local checked = self._checkbtn_is_rtl.checked 
                                        if checked ~= (self.assistant.settings:readSetting("response_is_rtl") or false) then
                                            self.assistant.settings:saveSetting("response_is_rtl", checked)
                                        end
                                    end

                                    self.assistant.updated = true
                                    UIManager:close(langsetting)
                                end
                            },
                        },
                    },

                }

                self._checkbtn_is_rtl = CheckButton:new{
                        text = "RTL written Language",
                        face = Font:getFace("x_smallinfofont"),  
                        checked = self.settings:readSetting("response_is_rtl") or false,
                        parent = self,
                }

                langsetting:addWidget(FrameContainer:new{  
                    padding = Size.padding.default,  
                    margin = Size.margin.small,  
                    bordersize = 0,  
                    self._checkbtn_is_rtl,
                })

                if self.assistant.settings:has("dict_language") or
                    self.assistant.settings:has("response_language") then
                    langsetting:addWidget(FrameContainer:new{  
                        padding = Size.padding.default,  
                        margin = Size.margin.small,  
                        bordersize = 0,  
                        TextBoxWidget:new{  
                            text = T(_("Leave these fields blank to use the UI language: %1"),  self.assistant.ui_language),
                            face = Font:getFace("x_smallinfofont"),  
                            width = math.floor(langsetting.width * 0.95),  
                            -- width = langsetting.width,
                        }
                    })
                end
                UIManager:show(langsetting)
            end,
        }}
    }
    dialog = ButtonDialog:new{
        shrink_unneeded_width = true,
        buttons = buttons,
        anchor = function()
            return self.title_bar.left_button.image.dimen
        end,
    }
    UIManager:show(dialog)
end



function SettingsDialog:onCloseWidget()
    InputDialog.onCloseWidget(self)
    self.assistant._settings_dialog = nil
end

return SettingsDialog

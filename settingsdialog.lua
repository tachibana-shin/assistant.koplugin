--[[--
This widget displays a config dialog.
]]

local Blitbuffer = require("ffi/blitbuffer")
local CenterContainer = require("ui/widget/container/centercontainer")
local CheckButton = require("ui/widget/checkbutton")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local InfoMessage = require("ui/widget/infomessage")
local TextWidget = require("ui/widget/textwidget")
local Font = require("ui/font")
local InputDialog = require("ui/widget/inputdialog")
local LineWidget = require("ui/widget/linewidget")
local MovableContainer = require("ui/widget/container/movablecontainer")
local RadioButtonTable = require("ui/widget/radiobuttontable")
local Size = require("ui/size")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local _ = require("gettext")
local Screen = require("device").screen
local ffiutil = require("ffi/util")
local meta = require("_meta")

local SettingsDialog = InputDialog:extend{
    title = _("Assitant Settings"),

    -- inited variables
    assitant = nil, -- reference to the main assistant object
    CONFIGURATION = nil,
    settings = nil,

    -- widgets
    buttons = nil,
    radio_buttons = nil,
    check_buttons = {},

    title_bar_left_icon = "notice-info",
    title_bar_left_icon_tap_callback = function ()
        UIManager:show(InfoMessage:new{
            alignment = "center",
            show_icon = false,
            text = string.format(
                _("%s %s\n\n%s"), meta.fullname, meta.version,
                [[💡 Enjoy KOReader with AI Power ! ]]
            )
        })
    end,
}

function SettingsDialog:init()

    self.check_button_init_list = {
        {
            key = "forced_stream_mode",
            text = _("Always use stream mode"),
        },
        {
            key = "ai_translate_override",
            text = _("Use AI Assistant for 'Translate'"),
            changed_callback = function(checked)
                self.assitant:applyOrRemoveTranslateOverride()
                UIManager:show(InfoMessage:new{
                    timeout = 3,
                    text = checked and _("AI Assistant override enabled.") or _("AI Assistant override disabled.")
                })
            end,
        },
    }

    -- action buttons
    self.buttons = {{
        {
            text="Cancel",
            callback=function () UIManager:close(self) end
        },
        {
            text="OK",
            callback=function ()
                local radio = self.radio_button_table.checked_button
                if radio.provider ~= self.assitant.querier.provider_name then
                    self.settings:saveSetting("provider", radio.provider)
                    self.assitant.updated = true
                    self.assitant.querier:load_model(radio.provider)
                end

                for _, btn in ipairs(self.check_button_init_list) do
                    local checked = self.check_buttons[btn.key].checked
                    if self.settings:readSetting(btn.key, false) ~= checked then
                        self.settings:saveSetting(btn.key, checked)
                        self.assitant.updated = true
                        if btn.changed_callback then
                            btn.changed_callback(checked)
                        end
                    end
                end

                UIManager:close(self)
            end
        },
    }}  

    -- init radio buttons for selecting AI Model provider
    self.radio_buttons = {} -- init radio buttons table
    self.description = _("Select the AI Model provider.")
    for key, tab in ffiutil.orderedPairs(self.CONFIGURATION.provider_settings) do
      table.insert(self.radio_buttons, {{
        text = string.format("%s (%s)", key, tab.model),
        provider = key, -- note: this `provider` field belongs to the RadioButton, not our AI Model provider.
        checked = (key == self.assitant.querier.provider_name),
      }})
    end

    -- init title and buttons in base class
    InputDialog.init(self)
    self.element_width = math.floor(self.width * 0.9)

    self.radio_button_table = RadioButtonTable:new{
        radio_buttons = self.radio_buttons,
        width = self.element_width,
        face = Font:getFace("cfont", 18),
        focused = true,
        scroll = false,
        parent = self,
        -- button_select_callback = function(btn)
        -- end
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
        self.check_buttons[btn.key] = CheckButton:new{
            text = btn.text,
            face = Font:getFace("cfont", 18),
            checked = self.settings:readSetting(btn.key, false),
            parent = self,
        }
        self:addWidget(self.check_buttons[btn.key])
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

function SettingsDialog:onCloseWidget()
    UIManager:setDirty(nil, function()
        return "ui", self.dialog_frame.dimen
    end)
end

return SettingsDialog

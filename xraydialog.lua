local logger        = require("logger")
local UIManager     = require("ui/uimanager")
local InfoMessage   = require("ui/widget/infomessage")
local TextBoxWidget = require("ui/widget/textboxwidget")
local ChatGPTViewer = require("chatgptviewer")
local _             = require("owngettext")
local koutil        = require("util")
local assistant_prompts = require("prompts").assistant_prompts

local function showXRayDialog(assistant, title, author, progress_percent, history)
    local CONFIGURATION = assistant.CONFIGURATION
    local Querier = assistant.querier
    local ui = assistant.ui

    -- Ensure the selected model is loaded
    local ok, err = Querier:load_model(assistant:getModelProvider())
    if not ok then
        UIManager:show(InfoMessage:new{ icon = "notice-warning", text = err })
        return
    end

    local formatted_progress_percent = string.format("%.2f", (progress_percent or 0) * 100)

    -- Get X-Ray configuration with fallbacks
    local xray_config = koutil.tableGetValue(CONFIGURATION, "features", "xray_config") or {}
    local xray_prompts = assistant_prompts and assistant_prompts.xray or nil

    -- Prompts for X‑Ray (from config or prompts.lua)
    local system_prompt = koutil.tableGetValue(xray_config, "system_prompt")
        or (xray_prompts and xray_prompts.system_prompt)

    local user_prompt_template = koutil.tableGetValue(xray_config, "user_prompt")
        or (xray_prompts and xray_prompts.user_prompt)

    local language = assistant.settings:readSetting("response_language") or assistant.ui_language

    local message_history = history or {
        { role = "system", content = system_prompt },
    }

    -- Fill user prompt template variables
    local user_content = user_prompt_template:gsub("{(%w+)}", {
        title = title,
        author = author,
        progress = formatted_progress_percent,
        language = language,
    })
    table.insert(message_history, { role = "user", content = user_content })

    local function createResultText(answer)
        local result_text =
            TextBoxWidget.PTF_HEADER ..
            TextBoxWidget.PTF_BOLD_START .. title .. TextBoxWidget.PTF_BOLD_END ..
            " by " .. author .. " is " .. formatted_progress_percent .. "% complete.\n\n" ..
            answer
        return result_text
    end

    local answer, qerr = Querier:query(message_history, "Loading X-Ray ...")
    if qerr then
        assistant.querier:showErrorWithSettingButton(qerr)
        return
    end

    UIManager:show(ChatGPTViewer:new{
        assistant = assistant,
        ui = ui,
        title = _("X‑Ray"),
        text = createResultText(answer),
        disable_add_note = true,
    })

    -- Optional: force refresh screen if enabled in configuration
    if koutil.tableGetValue(CONFIGURATION, "features", "refresh_screen_after_displaying_results") then
        UIManager:setDirty(nil, "full")
    end
end

return showXRayDialog

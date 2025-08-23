local logger = require("logger")
local InputDialog = require("ui/widget/inputdialog")
local UIManager = require("ui/uimanager")
local TextBoxWidget = require("ui/widget/textboxwidget")
local InfoMessage = require("ui/widget/infomessage")
local Event = require("ui/event")
local _ = require("owngettext")
local koutil = require("util")
local ChatGPTViewer = require("chatgptviewer")
local recap_prompts = require("prompts").assistant_prompts.recap

local function showRecapDialog(assistant, title, author, progress_percent, message_history)
    local CONFIGURATION = assistant.CONFIGURATION
    local Querier = assistant.querier
    local ui = assistant.ui

    -- Check if Querier is initialized
    local ok, err = Querier:load_model(assistant:getModelProvider())
    if not ok then
        UIManager:show(InfoMessage:new{ icon = "notice-warning", text = err })
        return
    end

    local formatted_progress_percent = string.format("%.2f", progress_percent * 100)
    
    -- Get recap CONFIGURATION with fallbacks
    local recap_config = koutil.tableGetValue(CONFIGURATION, "features", "recap_config") or {}
    local system_prompt = koutil.tableGetValue(recap_config, "system_prompt") or koutil.tableGetValue(recap_prompts, "system_prompt")
    local user_prompt_template = koutil.tableGetValue(recap_config, "user_prompt") or koutil.tableGetValue(recap_prompts, "user_prompt")
    local language = assistant.settings:readSetting("response_language") or assistant.ui_language
    
    local message_history = message_history or {
        {
            role = "system",
            content = system_prompt,
        },
    }
    
    -- Format the user prompt with variables
    local user_content = user_prompt_template:gsub("{(%w+)}", {
      title = title,
      author = author,
      progress = formatted_progress_percent,
      language = language
    })
    
    local context_message = {
        role = "user",
        content = user_content
    }
    table.insert(message_history, context_message)

    local function createResultText(answer)
      local result_text = 
        TextBoxWidget.PTF_HEADER ..
        TextBoxWidget.PTF_BOLD_START .. title .. TextBoxWidget.PTF_BOLD_END .. " by " .. author .. " is " .. formatted_progress_percent .. "% complete.\n\n" ..  answer
      return result_text
    end

    local answer, err = Querier:query(message_history, "Loading Recap ...")
    if err ~= nil then
      UIManager:show(InfoMessage:new{ icon = "notice-warning", text = err })
      return
    end

    local chatgpt_viewer = ChatGPTViewer:new {
      assistant = assistant,
      ui = ui,
      title = _("Recap"),
      text = createResultText(answer),
      disable_add_note = true,
    }

    UIManager:show(chatgpt_viewer)
end

return showRecapDialog

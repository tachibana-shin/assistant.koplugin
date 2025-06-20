local logger = require("logger")
local InputDialog = require("ui/widget/inputdialog")
local UIManager = require("ui/uimanager")
local TextBoxWidget = require("ui/widget/textboxwidget")
local InfoMessage = require("ui/widget/infomessage")
local Event = require("ui/event")
local _ = require("gettext")
local ChatGPTViewer = require("chatgptviewer")
local configuration = require("configuration")

local function showRecapDialog(assitant, title, author, progress_percent, message_history)
    local Querier = assitant.querier
    local ui = assitant.ui

    -- Check if Querier is initialized
    local ok, err = Querier:load_model(assitant:getModelProvider())
    if not ok then
        UIManager:show(InfoMessage:new{ icon = "notice-warning", text = err })
        return
    end

    local formatted_progress_percent = string.format("%.2f", progress_percent * 100)
    
    -- Get recap configuration with fallbacks
    local recap_config = configuration.features and configuration.features.recap_config or {}
    local system_prompt = recap_config.system_prompt or "You are a book recap giver with entertaining tone and high quality detail with a focus on summarization. You also match the tone of the book provided."
    local user_prompt_template = recap_config.user_prompt or [['''{title}''' by '''{author}''' that has been {progress}% read.
Given the above title and author of a book and the positional parameter, very briefly summarize the contents of the book prior with rich text formatting.
Above all else do not give any spoilers to the book, only consider prior content.
Focus on the more recent content rather than a general summary to help the user pick up where they left off.
Match the tone and energy of the book, for example if the book is funny match that style of humor and tone, if it's an exciting fantasy novel show it, if it's a historical or sad book reflect that.
Use text bolding to emphasize names and locations. Use italics to emphasize major plot points. No emojis or symbols.
Answer this whole response in {language} language. Only show the replies, do not give a description.]]
    local language = recap_config.language or (configuration.features and configuration.features.dictionary_translate_to) or "English"
    
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
      assitant = assitant,
      ui = ui,
      title = _("Recap"),
      text = createResultText(answer),
      showAskQuestion = false
    }

    UIManager:show(chatgpt_viewer)
    if configuration and configuration.features and configuration.features.refresh_screen_after_displaying_results then
      UIManager:setDirty(nil, "full")
    end
end

return showRecapDialog

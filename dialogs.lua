local InputDialog = require("ui/widget/inputdialog")
local ChatGPTViewer = require("chatgptviewer")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local _ = require("gettext")

local queryChatGPT = require("gpt_query")
local Defaults = require("api_handlers.defaults")

local CONFIGURATION = nil
local buttons, input_dialog = nil, nil

local success, result = pcall(function() return require("configuration") end)
if success then
  CONFIGURATION = result
else
  print("configuration.lua not found, skipping...")
end

local function translateText(text, target_language)
  -- Raise an error if target_language is nil
  if not target_language then
    error("Target language not specified")
  end

  local translation_message = {
    role = "user",
    content = "Translate the following text to " .. target_language .. ": " .. text
  }
  local translation_history = {
    {
      role = "system",
      content = "You are a helpful translation assistant. Provide direct translations without additional commentary."
    },
    translation_message
  }
  
  local success, result = pcall(function()
    return queryChatGPT(translation_history)
  end)
  
  if not success then
    print("Debug: Translation error: " .. tostring(result))
    error(result)
  end
  
  return result
end

local function createResultText(highlightedText, message_history, previous_text)
  -- If no previous text, start from scratch
  if not previous_text then
    local result_text = _("Highlighted text: ") .. "\"" .. highlightedText .. "\"\n\n"
    
    -- Include only user and assistant messages, skip context messages
    for i = 2, #message_history do
      if not message_history[i].is_context then
        if message_history[i].role == "user" then
          result_text = result_text .. _("User: ") .. message_history[i].content .. "\n\n"
        else
          result_text = result_text .. _("Assistant: ") .. message_history[i].content .. "\n\n"
        end
      end
    end
    return result_text
  end

  -- If previous text exists, only append the last two messages (new question and answer)
  local last_user_message = message_history[#message_history - 1]
  local last_assistant_message = message_history[#message_history]

  if last_user_message and last_user_message.role == "user" and 
     last_assistant_message and last_assistant_message.role == "assistant" then
    local new_text = previous_text .. 
           _("User: ") .. last_user_message.content .. "\n\n" .. 
           _("Assistant: ") .. last_assistant_message.content .. "\n\n"
    
    return new_text
  end

  return previous_text
end

local function showLoadingDialog()
  local loading = InfoMessage:new{
    text = _("Loading..."),
    timeout = 0.1
  }
  UIManager:show(loading)
end

local function handlePredefinedPrompt(prompt_type, highlightedText, ui)
    -- Ensure configuration and features exist
    if not CONFIGURATION or not CONFIGURATION.features or not CONFIGURATION.features.prompts then
        return nil, "No prompts configured"
    end

    -- Get prompt configuration
    local prompt = CONFIGURATION.features.prompts[prompt_type]
    if not prompt then
        return nil, "Prompt '" .. prompt_type .. "' not found"
    end

    -- Get book metadata
    local title, author = 
        ui.document:getProps().title or _("Unknown Title"),
        ui.document:getProps().authors or _("Unknown Author")

    -- Format the user prompt with book context
    local formatted_user_prompt = (prompt.user_prompt or "Please analyze: ")
        :gsub("{title}", title)
        :gsub("{author}", author)

    -- Create message history
    local message_history = {
        {
            role = "system",
            content = prompt.system_prompt or "You are a helpful assistant."
        },
        {
            role = "user",
            content = formatted_user_prompt .. highlightedText,
            is_context = true
        }
    }
    
    -- Get response from AI
    local answer = queryChatGPT(message_history)
    if answer then
        table.insert(message_history, {
            role = "assistant",
            content = answer
        })
    end
    
    return message_history, nil
end

local function getAllPrompts()
    if not CONFIGURATION or not CONFIGURATION.features or not CONFIGURATION.features.prompts then
        return {}
    end
    return CONFIGURATION.features.prompts
end

local function showChatGPTDialog(ui, highlightedText)
  -- Close any existing dialog before creating a new one
  if input_dialog then
    UIManager:close(input_dialog)
    input_dialog = nil
  end

  local title, author =
    ui.document:getProps().title or _("Unknown Title"),
    ui.document:getProps().authors or _("Unknown Author")
  local message_history = {{
    role = "system",
    content = "You are a helpful assistant for reading comprehension."
  }}

  -- Create button rows (3 buttons per row)
  local button_rows = {}
  
  -- Collect all buttons in priority order
  local all_buttons = {
    -- 1. Cancel
    {
      text = _("Cancel"),
      id = "close",
      callback = function()
        if input_dialog then
          UIManager:close(input_dialog)
          input_dialog = nil
        end
      end
    },
    -- 2. Ask
    {
      text = _("Ask"),
      callback = function()
        local question = input_dialog:getInputText()
        UIManager:close(input_dialog)
        input_dialog = nil
        showLoadingDialog()
        UIManager:scheduleIn(0.1, function()
          local context_message = {
            role = "user",
            content = "I'm reading something titled '" .. title .. "' by " .. author ..
              ". I have a question about the following highlighted text: " .. highlightedText,
            is_context = true
          }
          message_history[2] = context_message

          local question_message = {
            role = "user",
            content = question
          }
          table.insert(message_history, question_message)

          local answer = queryChatGPT(message_history)
          local answer_message = {
            role = "assistant",
            content = answer
          }
          table.insert(message_history, answer_message)

          local result_text = createResultText(highlightedText, message_history)

          local chatgpt_viewer = ChatGPTViewer:new {
            title = _("AI Assistant"),
            text = result_text,
            onAskQuestion = function(viewer, new_question)
              local new_context_message = {
                role = "user",
                content = "I'm reading something titled '" .. title .. "' by " .. author ..
                  ". I have a question about the following highlighted text: " .. highlightedText,
                is_context = true
              }
              table.insert(message_history, new_context_message)

              local new_question_message = {
                role = "user",
                content = new_question
              }
              table.insert(message_history, new_question_message)

              local new_answer = queryChatGPT(message_history)
              local new_answer_message = {
                role = "assistant",
                content = new_answer
              }
              table.insert(message_history, new_answer_message)

              local new_result_text = createResultText(highlightedText, message_history, viewer.text)
              viewer:update(new_result_text)
              
              if viewer.scroll_text_w then
                viewer.scroll_text_w:scrollToBottom()
              end
            end,
            message_history = message_history,
            highlighted_text = highlightedText
          }

          -- Close the input dialog completely before showing the viewer
          if input_dialog then
            UIManager:close(input_dialog)
            input_dialog = nil
          end
          
          UIManager:show(chatgpt_viewer)
          
          if chatgpt_viewer.scroll_text_w then
            chatgpt_viewer.scroll_text_w:scrollToBottom()
          end
        end)
      end
    },
    -- 3. Translate
    {
      text = _("Translate"),
      callback = function()
        
        local target_language = nil
        if CONFIGURATION and CONFIGURATION.features then
          if type(CONFIGURATION.features.translate_to) == "string" then
            target_language = CONFIGURATION.features.translate_to
          end
        end

        if not target_language then
          target_language = "Turkish"
        end

        showLoadingDialog()
        UIManager:scheduleIn(0.1, function()
          local success, translated_text = pcall(function()
            return translateText(highlightedText, target_language)
          end)

          if not success then
            print("Debug: Translation error: " .. tostring(translated_text))
            UIManager:show(InfoMessage:new{
              text = _("Translation error: ") .. tostring(translated_text)
            })
            return
          end

          table.insert(message_history, {
            role = "user",
            content = "Translate to " .. target_language .. ": " .. highlightedText,
            is_context = true
          })

          table.insert(message_history, {
            role = "assistant",
            content = translated_text
          })

          local result_text = createResultText(highlightedText, message_history)
          local chatgpt_viewer = ChatGPTViewer:new {
            title = _("Translation"),
            text = result_text,
            onAskQuestion = function(viewer, new_question)
              local new_context_message = {
                role = "user",
                content = "I'm reading something titled '" .. title .. "' by " .. author ..
                  ". I have a question about the following highlighted text: " .. highlightedText,
                is_context = true
              }
              table.insert(message_history, new_context_message)

              local new_question_message = {
                role = "user",
                content = new_question
              }
              table.insert(message_history, new_question_message)

              local new_answer = queryChatGPT(message_history)
              local new_answer_message = {
                role = "assistant",
                content = new_answer
              }
              table.insert(message_history, new_answer_message)

              local new_result_text = createResultText(highlightedText, message_history, viewer.text)
              viewer:update(new_result_text)
              
              if viewer.scroll_text_w then
                viewer.scroll_text_w:scrollToBottom()
              end
            end,
            message_history = message_history,
            highlighted_text = highlightedText
          }

          -- Close the input dialog completely before showing the viewer
          if input_dialog then
            UIManager:close(input_dialog)
            input_dialog = nil
          end
          
          UIManager:show(chatgpt_viewer)
          
          if chatgpt_viewer.scroll_text_w then
            chatgpt_viewer.scroll_text_w:scrollToBottom()
          end
        end)
      end
    },
  }

  -- 4. Custom prompts
  local custom_buttons = {}
  for prompt_type, prompt in pairs(getAllPrompts()) do
    local custom_button = {
      text = _(prompt.text),
      callback = function()
        showLoadingDialog()
        UIManager:scheduleIn(0.1, function()
          local message_history, err = handlePredefinedPrompt(prompt_type, highlightedText, ui)
          if err then
              UIManager:show(InfoMessage:new{
                  text = _("Error: " .. err),
              })
              return
          end
          
          if not message_history or #message_history < 1 then
              UIManager:show(InfoMessage:new{
                  text = _("Error: No response received"),
              })
              return
          end
          
          local result_text = createResultText(highlightedText, message_history)
          
          local chatgpt_viewer = ChatGPTViewer:new {
              title = _(prompt.text),
              text = result_text,
              onAskQuestion = function(viewer, new_question)
                local new_context_message = {
                  role = "user",
                  content = "I'm reading something titled '" .. title .. "' by " .. author ..
                    ". I have a question about the following highlighted text: " .. highlightedText,
                  is_context = true
                }
                table.insert(message_history, new_context_message)

                local new_question_message = {
                  role = "user",
                  content = new_question
                }
                table.insert(message_history, new_question_message)

                local new_answer = queryChatGPT(message_history)
                local new_answer_message = {
                  role = "assistant",
                  content = new_answer
                }
                table.insert(message_history, new_answer_message)

                local new_result_text = createResultText(highlightedText, message_history, viewer.text)
                viewer:update(new_result_text)
                
                if viewer.scroll_text_w then
                  viewer.scroll_text_w:scrollToBottom()
                end
              end,
              message_history = message_history,
              highlighted_text = highlightedText
          }
          
          -- Close the input dialog completely before showing the viewer
          if input_dialog then
            UIManager:close(input_dialog)
            input_dialog = nil
          end
          
          UIManager:show(chatgpt_viewer)
          
          if chatgpt_viewer.scroll_text_w then
            chatgpt_viewer.scroll_text_w:scrollToBottom()
          end
        end)
      end
    }
    table.insert(custom_buttons, custom_button)
  end

  -- Merge custom buttons with all_buttons
  for _, button in ipairs(custom_buttons) do
    table.insert(all_buttons, button)
  end
  
  -- Organize buttons into rows of three
  local current_row = {}
  for _, button in ipairs(all_buttons) do
    table.insert(current_row, button)
    if #current_row == 3 then
      table.insert(button_rows, current_row)
      current_row = {}
    end
  end
  
  -- Add any remaining buttons as the last row
  if #current_row > 0 then
    table.insert(button_rows, current_row)
  end

  -- Show the dialog with the button rows
  input_dialog = InputDialog:new{
    title = _("Ask a question about the highlighted text"),
    input_hint = _("Type your question here..."),
    input_type = "text",
    buttons = button_rows,
    close_callback = function()
      if input_dialog then
        UIManager:close(input_dialog)
        input_dialog = nil
      end
    end,
    dismiss_callback = function()
      if input_dialog then
        UIManager:close(input_dialog)
        input_dialog = nil
      end
    end
  }
  UIManager:show(input_dialog)
  input_dialog:onShowKeyboard()
end

return showChatGPTDialog
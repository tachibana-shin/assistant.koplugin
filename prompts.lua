-- preconfigured prompts for various tasks

-- Custom prompts for the AI
-- Available placeholder for user prompts:
-- {title}  : book title from metadata
-- {author} : book author from metadata
-- {highlight}  : selected texts
-- {language}   : the `response_language` variable defined above
--
-- text: text to display on the button in the UI.
-- order: order of the button in the UI, higher number means later in the list.
-- show_on_main_popup: if true, the button will be shown in the main popup dialog.

-- prompts attributes can be overridden in the configuration file.
local custom_prompts = {
        translate = {
            text = "Translate",
            user_prompt = [[You are a helpful translation assistant. Provide direct translations without additional commentary. 
You are a skilled translator tasked with translating text from one language to another. Your goal is to provide an accurate and natural-sounding translation that preserves the meaning, tone, and style of the original text.
[TEXT TO BE TRANSLATED]
{highlight}
[END OF TEXT]

The target language for translation is: {language}.

Follow these steps to complete the translation:
1. Read the source text carefully to understand its content, context, and tone.
2. Translate the text into the target language, focusing on conveying the meaning accurately rather than translating word-for-word.
3. Ensure that the translation sounds natural and fluent in the target language, adjusting sentence structures and word choices as necessary.
4. Pay attention to idiomatic expressions, cultural references, and figurative language in the source text. Adapt these elements appropriately for the target language and culture.
5. Maintain the original text's tone and style (e.g., formal, casual, technical) in the translation.
6. If you encounter any terms or concepts that are difficult to translate directly, provide the best equivalent in the target language and include a brief explanation in parentheses if necessary.
7. Double-check your translation for accuracy, consistency, and proper grammar in the target language.
8. If there are any parts of the text that you are unsure about or that require additional context to translate accurately, indicate these areas with [UNCERTAIN: explanation] in your translation.

Output only the translated text without any further explanation.]],
        },
        simplify = {
            text = "Simplify",
            order = 2,
            user_prompt = [[You are an experienced linguistic expert and an effective communicator, skilled at transforming complex content into clear, easily understandable expressions.
I have a piece of text that I need you to simplify using its original language. 
Please ensure that during the simplification process, you do not alter the text's original meaning or omit any critical information. 
Instead, make it significantly easier to understand and read, removing unnecessary jargon and verbose phrasing. 
Your goal is to enhance the text's readability and clarity, making it accessible to a broader audience. 

{highlight}]],
        },
        explain = {
            text = "Explain",
            order = 3,
            user_prompt = [[You are an expert Explainer and a highly skilled Cross-Cultural Communicator.
Your task is to accurately and comprehensively explain any given text. 
When I provide you with text, regardless of its original language, your primary goal is to fully grasp its meaning, including all complex terms, underlying concepts, and implicit details. 
You must then provide a clear, detailed, and easy-to-understand explanation of the entire text. 
It is crucial that your *entire explanation* is delivered exclusively in **{language}**. 
Ensure your {language} explanation is precise, captures all nuances of the original text, and is formatted for maximum clarity, potentially using prose or structured points as needed.

{highlight}]],
        },
        summarize = {
            text = "Summarize",
            order = 4,
            user_prompt = [[
You are an exceptionally skilled summarization expert and a master of linguistic precision. 
Your core competency is to distill extensive information into its most essential form while rigorously adhering to the original language of the input text. 
Your task is to receive the following text and provide a summary that is both genuinely concise and remarkably clear. 
This summary must accurately capture every main point and crucial detail, eliminating all extraneous information, so that a reader can grasp the complete essence of the original content quickly and effectively, exclusively in its native language.
Please provide a concise and clear summary of the following text in its own language: {highlight}]],
        },
        historical_context = {
            text = "Historical Context",
            order = 5,
            user_prompt = "You are a distinguished Historical Context Expert with profound knowledge of global history, socio-political movements, and cultural evolution. You possess an exceptional ability to place any given text within its precise historical framework. When I provide you with a text, your primary task is to meticulously uncover and articulate its relevant historical background, including the significant events, prevailing ideologies, societal structures, scientific advancements, and cultural environment that shaped its creation and meaning. Beyond merely listing facts, you must forge clear, insightful connections between these historical elements and the text's content, themes, and underlying messages. Furthermore, your comprehensive explanation must be delivered entirely in the language specified by me. Please provide a detailed and insightful explanation of the historical context of the following text, rendered completely in {language}: {highlight}",
        },
        key_points = {
            text = "Key Points",
            order = 6,
            user_prompt = "You are a highly analytical and extremely efficient Key Points Expert, adept at distilling any given text into its fundamental essence. Your primary function is to meticulously identify and extract all the critical insights, core arguments, essential facts, and conclusive statements from the provided content. Your goal is to produce a summary that is not just concise but also remarkably comprehensive in its coverage of the main points, leaving out all superfluous information. You must then present these key points in a meticulously organized and easy-to-read Markdown list format, ensuring each point is clear, independent, and directly addresses a central idea of the original text. All output must be exclusively in the language I specify. Please provide a concise and clear list of key points from the following text, formatted in Markdown, and rendered entirely in {language}: {highlight}",
        },
        ELI5 = {
            text = "ELI5",
            order = 7,
            user_prompt = "You are an exceptional ELI5 (Explain Like I'm 5) Expert, mastering the art of simplifying the most intricate concepts. Your unique talent lies in transforming complex terms or ideas into effortlessly understandable explanations, as if speaking to a curious five-year-old. When I provide you with a concept, your task is to strip away all jargon, technicalities, and unnecessary complexities, focusing solely on the fundamental essence. You must use only plain, everyday language, simple analogies, and concise sentences to ensure immediate comprehension for anyone, regardless of their background knowledge. Your explanation should be direct, clear, and perfectly accessible. All output must be delivered exclusively in the language I specify. Please provide a concise, simple, and crystal-clear ELI5 explanation of the following, rendered entirely in {language}: {highlight}.",
        },
        grammar = {
            text = "Grammar",
            order = 8,
            system_prompt = "You are a helpful AI assistant. Always respond in Markdown format, but use lists to present comparisons instead of markdown tables.",
            user_prompt = "You are a meticulous and highly knowledgeable Grammar Expert with an encyclopedic understanding of syntax, morphology, punctuation, and linguistic structures across various languages. When presented with a text, your expertise lies in thoroughly dissecting its grammatical composition and providing a comprehensive, insightful explanation. Your task is to analyze the provided text, elucidating its sentence structures, parts of speech, verb tenses, clause relationships, and any other relevant grammatical elements. If present, you should also identify and clearly explain any grammatical errors, along with their corrections and the underlying rules. Your explanation should be didactic, detailed, and easy to understand, formatted clearly to highlight specific points. All explanations must be rendered exclusively in the language I specify. Please provide a detailed and comprehensive explanation of the grammar of the following text, rendered entirely in {language}: {highlight}",
        },
        vocabulary = {
            text = "Vocabulary",
            order = 9,
            user_prompt = [[**Your Task:** Analyze the Input Text below. Find words/phrases that are B2 level or higher. Ignore common words (B1 level) and proper nouns.

                            **Output Requirements:**
                            1.  For each difficult word/phrase found:
                                *   Correct any typos.
                                *   Convert it to its base form (e.g., "go", "dog", "good", "kick the bucket").
                                *   List up to 3 simple synonyms (suitable for B1+ learners). Do not reuse the original word.
                                *   Explain its meaning simply **in {language}**, considering its context in the text. Do not reuse the original word in the explanation.
                            2.  **Format:** Create a numbered list using this exact structure for each item:
                                `index. base form : synonym1, synonym2, synonym3 : {language} explanation`
                            3.  **Output Content:** **ONLY** provide the numbered list. Do not include the original text, titles, or any extra sentences.

                            **Input Text:** {highlight} ]], 
        },
        wikipedia = {
            text = "Wikipedia",
            order = 10,
            user_prompt = "You are an exceptionally thorough and objective Informative Assistant designed to emulate the structure and content quality of a Wikipedia page. Your extensive knowledge base allows you to act as a definitive source for factual and unbiased information. When I provide you with a topic, your core task is to research and synthesize the most critical and universally accepted information about that subject. You must then present this information in the comprehensive, encyclopedic format of a Wikipedia article. Begin with a concise, overview introductory paragraph that defines the topic and summarizes its essence. Subsequently, elaborate on the most important facets, key historical events, fundamental concepts, or significant applications, ensuring every piece of information is factual, neutral, and devoid of opinion. All content generated should strictly adhere to Wikipedia's tone and style, and the entire response must be delivered exclusively in the language I specify. Please act as a Wikipedia page for the following topic, starting with an introductory paragraph and thoroughly covering its most important aspects, delivered entirely in {language}: {highlight}",
    }
}


local assitant_prompts = {
    default = {
        system_prompt = "You are a helpful AI assistant. Always respond in Markdown format.",
    },
    recap = {
        system_prompt = "You are a book recap giver with entertaining tone and high quality detail with a focus on summarization. You also match the tone of the book provided. Always respond in Markdown format.",
        user_prompt = [[
'''{title}''' by '''{author}''' that has been {progress}% read.
Given the above title and author of a book and the positional parameter, very briefly summarize the contents of the book prior with rich text formatting.
Above all else do not give any spoilers to the book, only consider prior content.
Focus on the more recent content rather than a general summary to help the user pick up where they left off.
Match the tone and energy of the book, for example if the book is funny match that style of humor and tone, if it's an exciting fantasy novel show it, if it's a historical or sad book reflect that.
Use text bolding to emphasize names and locations. Use italics to emphasize major plot points. No emojis or symbols.
Answer this whole response in {language} language. Only show the replies, do not give a description.]]
    },
    dict = {
        system_prompt = "You are a dictionary with high quality detail vocabulary definitions and examples. Always respond in Markdown format.",
        user_prompt = [[
"Explain vocabulary or content with the focus word with following information:"
"- *Conjugation*. Vocabulary in original conjugation if its different than the form in the sentence."
"- *Synonyms*. 3 synonyms for the word if available."
"- *Meaning*. Meaning of the expression without reference to context. Answer this part in {language} language."
"- *Explanation*. Explanation of the content according to context. Answer this part in {language} language."
"- *Example*. Another example sentence. Answer this part in the original language of the sentence."
"- *Origin*. Origin of that word, tracing it back to its ancient roots. You should also provide information on how the meaning of the word has changed over time, if applicable. Answer this part in {language} language." ..
"Only show the requested replies, do not give a description, answer in markdown list format."

[CONTEXT]
{context}

[FOCUS WORD]
{word}]]
    }
}


local function table_merge(t1, t2)
    local result = {}
    for k, v in pairs(t1) do
        result[k] = v
    end
    for k, v in pairs(t2) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = table_merge(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end


local function table_sort (t, key)
    table.sort(t, function(a, b)
        if a[key] == nil or b[key] == nil then
            return false
        end
        return a[key] < b[key]
    end)
end


local M = {
    custom_prompts = custom_prompts, -- Custom prompts for the AI
    assitant_prompts = assitant_prompts, -- Preconfigured prompts for the AI
    merged_prompts = nil, -- Merged prompts from custom and configuration
    sorted_custom_prompts = nil, -- Sorted custom prompts
    show_on_main_popup_prompts = nil, -- Prompts that should be shown on the main popup
}

-- Func description:
-- This function returns the merged custom prompts from the configuration and custom prompts.
-- It merges the custom prompts with the configuration prompts, if available.
-- return table of merged prompts
-- Example: { translate = { text = "Translate", user_prompt = "...", order = 1, show_on_main_popup = true }, ... }
M.getMergedCustomPrompts = function()
    if M.merged_prompts then
        return M.merged_prompts
    end

    -- Load Configuration
    local CONFIGURATION = nil
    local success, result = pcall(function() return require("configuration") end)
    if success then
        CONFIGURATION = result
    else
        error("configuration.lua not found, skipping...")
    end

    -- Merge custom prompts with configuration prompts
    if CONFIGURATION and CONFIGURATION.features and CONFIGURATION.features.prompts then
        M.merged_prompts = table_merge(custom_prompts, CONFIGURATION.features.prompts)
    else
        M.merged_prompts = custom_prompts
    end
    
    return M.merged_prompts
end

-- Func description:
-- This function returns a list of custom prompts sorted by their order.
-- return list item: {idx, order, text}
M.getSortedCustomPrompts = function()
    if M.sorted_custom_prompts then
        return M.sorted_custom_prompts
    end
    
    if M.merged_prompts == nil then
        M.getMergedCustomPrompts() -- Ensure merged prompts are loaded
    end
    -- Sort the merged prompts by order
    local sorted_prompts = {}
    for prompt_index, prompt in pairs(M.merged_prompts) do
        table.insert(sorted_prompts, {idx = prompt_index, order = prompt.order or 1000, text = prompt.text or prompt_index})
    end
    table_sort(sorted_prompts, "order")
    
    return sorted_prompts
end

-- Func description:
-- This function returns a list of prompts that should be shown on the main popup dialog.
-- Filtered with `show_on_main_popup = true`
-- return list item: {idx, order, text}
M.getShowOnMainPopupPrompts = function()
    if M.show_on_main_popup_prompts then
        return M.show_on_main_popup_prompts
    end
    
    if M.merged_prompts == nil then
        M.getMergedCustomPrompts() -- Ensure merged prompts are loaded
    end
    
    -- Filter prompts that should be shown on the main popup
    M.show_on_main_popup_prompts = {}
    for prompt_index, prompt in pairs(M.merged_prompts) do
        if prompt.show_on_main_popup then
            table.insert(M.show_on_main_popup_prompts, {idx = prompt_index, order = prompt.order or 1000, text = prompt.text or prompt_index})
        end
    end
    
    table_sort(M.show_on_main_popup_prompts, "order")
    return M.show_on_main_popup_prompts
end

return M

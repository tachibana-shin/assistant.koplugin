local CONFIGURATION = {
    -- Choose your preferred AI provider: "anthropic", "openai", "gemini", ...
    -- use one of the settings defined in provider_settings below.
    -- NOTE: "openai" , "openai_grok" are different service using same handling code.
    provider = "openai",

    -- Provider-specific settings
    provider_settings = {
        openai = {
            defalut = true, -- optional, if provider above is not set, will try to find one with `defalut =  true`
            visible = true, -- optional, if set to false, will not shown in the provider switch
            model = "gpt-4o-mini", -- model list: https://platform.openai.com/docs/models
            base_url = "https://api.openai.com/v1/chat/completions",
            api_key = "your-openai-api-key",
            additional_parameters = {
                temperature = 0.7,
                max_tokens = 4096
            }
        },
        openai_grok = {
            --- use grok model via openai handler
            model = "grok-3-mini-fast", -- model list: https://docs.x.ai/docs/models
            base_url = "https://api.x.ai/v1/chat/completions",
            api_key = "your-grok-api-key",
            additional_parameters = {
                temperature = 0.7,
                max_tokens = 4096
            }
        },
        anthropic = {
            visible = true, -- optional, if set to false, will not shown in the profile switch
            model = "claude-3-5-haiku-latest", -- model list: https://docs.anthropic.com/en/docs/about-claude/models
            base_url = "https://api.anthropic.com/v1/messages",
            api_key = "your-anthropic-api-key",
            additional_parameters = {
                anthropic_version = "2023-06-01", -- api version list: https://docs.anthropic.com/en/api/versioning
                max_tokens = 4096
            }
        },
        gemini = {
            model = "gemini-2.0-flash-001", -- model list: https://ai.google.dev/gemini-api/docs/models/gemini , ex: gemini-1.5-pro-latest , gemini-2.0-flash-001
            base_url = "https://generativelanguage.googleapis.com/v1beta/models/",
            api_key = "your-gemini-api-key",
            additional_parameters = {
                temperature = 0.7,
                max_tokens = 4096,
                -- Set to 0 to disable thinking. Recommended for gemini-2.5-* and newer, where thinking is enabled by default.
                thinking_budget = nil
            }
        },
        openrouter = {
            model = "google/gemini-2.0-flash-exp:free", -- model list: https://openrouter.ai/models?order=top-weekly
            base_url = "https://openrouter.ai/api/v1/chat/completions",
            api_key = "your-openrouter-api-key",
            additional_parameters = {
                temperature = 0.7,
                max_tokens = 4096,
                -- Reasoning tokens configuration (optional)
                -- reference: https://openrouter.ai/docs/use-cases/reasoning-tokens
                -- reasoning = {
                --     -- One of the following (not both):
                --     effort = "high", -- Can be "high", "medium", or "low" (OpenAI-style)
                --     -- max_tokens = 2000, -- Specific token limit (Anthropic-style)
                --     -- Or enable reasoning with the default parameters:
                --     -- enabled = true -- Default: inferred from effort or max_tokens
                -- }
            }
        },
        openrouter_free = {
            --- use another free model with defferent configuration
            model = "deepseek/deepseek-chat-v3-0324:free", -- model list: https://openrouter.ai/models?order=top-weekly
            base_url = "https://openrouter.ai/api/v1/chat/completions",
            api_key = "your-openrouter-api-key",
            additional_parameters = {
                temperature = 0.7,
                max_tokens = 4096,
            }
        },
        deepseek = {
            model = "deepseek-chat",
            base_url = "https://api.deepseek.com/v1/chat/completions",
            api_key = "your-deepseek-api-key",
            additional_parameters = {
                temperature = 0.7,
                max_tokens = 4096
            }
        },
        ollama = {
            model = "your-preferred-model", -- model list: https://ollama.com/library
            base_url = "your-ollama-api-endpoint", -- ex: "https://ollama.example.com/api/chat"
            api_key = "ollama",
            additional_parameters = { }
        },
        mistral = {
            model = "mistral-small-latest", -- model list: https://docs.mistral.ai/getting-started/models/models_overview/
            base_url = "https://api.mistral.ai/v1/chat/completions",
            api_key = "your-mistral-api-key",
            additional_parameters = {
                temperature = 0.7,
                max_tokens = 4096
            }
        },
        groq = {
            model = "llama-3.3-70b-versatile", -- model list: https://console.groq.com/docs/models
            base_url = "https://api.groq.com/openai/v1/chat/completions",
            api_key = "your-groq-api-key",
            additional_parameters = {
                temperature = 0.7,
                -- config options, see: https://console.groq.com/docs/api-reference
                -- eg: disable reasoning for model qwen3, set:
                -- reasoning_effort = "none" 
            }
        },
        groq_qwen = {
            --- Recommended setting
            --- qwen3 without reasoning
            model = "qwen/qwen3-32b",
            base_url = "https://api.groq.com/openai/v1/chat/completions",
            api_key = "your-groq-api-key",
            additional_parameters = {
                temperature = 0.7,
                reasoning_effort = "none"
            }
        },
        azure_openai = {
            endpoint = "https://your-resource-name.openai.azure.com", -- Your Azure OpenAI resource endpoint
            deployment_name = "your-deployment-name", -- Your model deployment name
            api_version = "2024-02-15-preview", -- Azure OpenAI API version
            api_key = "your-azure-api-key", -- Your Azure OpenAI API key
            temperature = 0.7,
            max_tokens = 4096
        },
    },

    -- Optional features 
    features = {
        dictionary_translate_to = "Turkish", -- Set language for the dictionary response, nil to disable dictionary.
        response_language = "Turkish", --  Set language for the other responses, nil to English response. 
        hide_highlighted_text = false,  -- Set to true to hide the highlighted text at the top
        hide_long_highlights = true,    -- Hide highlighted text if longer than threshold
        long_highlight_threshold = 500,  -- Number of characters considered "long"
        max_display_user_prompt_length = 100,  -- Maximum number of characters of user_prompt to show in result window  (0 or nil for no limit)
        system_prompt = "You are a helpful assistant that provides clear explanations.", -- Custom system prompt for the AI ("Ask" button) to override the default, to disable set to nil
        refresh_screen_after_displaying_results = true, -- Set to true to refresh the screen after displaying the results
        show_dictionary_button_in_main_popup = true, -- Set to true to show the dictionary button in the main popup
        show_dictionary_button_in_dictionary_popup = true, -- Set to true to show the Dictionary (AI) button in the dictionary popup
        enable_AI_recap = true, -- Set to true to allow for a popup on a book you haven't read in a while to give you a quick AI recap
        render_markdown = true, -- Set to true to render markdown in the AI responses
        markdown_font_size = 20, -- Default normal text font size of rendered markdown.
        updater_disabled = false, -- Set to true to disable update check.

        -- AI Recap configuration
        recap_config = {
            system_prompt = "You are a book recap giver with entertaining tone and high quality detail with a focus on summarization. You also match the tone of the book provided.",
            user_prompt = [[
'''{title}''' by '''{author}''' that has been {progress}% read.
Given the above title and author of a book and the positional parameter, very briefly summarize the contents of the book prior with rich text formatting.
Above all else do not give any spoilers to the book, only consider prior content.
Focus on the more recent content rather than a general summary to help the user pick up where they left off.
Match the tone and energy of the book, for example if the book is funny match that style of humor and tone, if it's an exciting fantasy novel show it, if it's a historical or sad book reflect that.
Use text bolding to emphasize names and locations. Use italics to emphasize major plot points. No emojis or symbols.
Answer this whole response in {language} language. Only show the replies, do not give a description.]],
            language = "Turkish" -- Language for recap responses, uses dictionary_translate_to as fallback
        },

        -- Custom prompts for the AI (text = button text in the UI). system-prompt defaults to "You are a helpful assistant." if not set.
        -- Available placeholder for user prompts:
        -- {title}  : book title from metadata
        -- {author} : book author from metadata
        -- {highlight}  : selected texts
        -- {language}   : the `response_language` variable defined above
        prompts = {
            translate = {
                text = "Translate",
                order = 1,
                system_prompt = "You are a helpful translation assistant. Provide direct translations without additional commentary. Insert an empty line between paragraphs to maintain markdown paragraph format.",
                user_prompt = [[
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
                show_on_main_popup = true -- Show the button in main popup
            },
            simplify = {
                text = "Simplify",
                order = 2,
                system_prompt = "You are an experienced linguistic expert and an effective communicator, skilled at transforming complex content into clear, easily understandable expressions.",
                user_prompt = [[I have a piece of text that I need you to simplify using its original language. 
Please ensure that during the simplification process, you do not alter the text's original meaning or omit any critical information. 
Instead, make it significantly easier to understand and read, removing unnecessary jargon and verbose phrasing. 
Your goal is to enhance the text's readability and clarity, making it accessible to a broader audience. 

{highlight}]],
                show_on_main_popup = false -- Show the button in main popup
            },
            explain = {
                text = "Explain",
                order = 3,
                system_prompt = "You are an expert Explainer and a highly skilled Cross-Cultural Communicator.",
                user_prompt = [[Your task is to accurately and comprehensively explain any given text. 
When I provide you with text, regardless of its original language, your primary goal is to fully grasp its meaning, including all complex terms, underlying concepts, and implicit details. 
You must then provide a clear, detailed, and easy-to-understand explanation of the entire text. 
It is crucial that your *entire explanation* is delivered exclusively in **{language}**. 
Ensure your {language} explanation is precise, captures all nuances of the original text, and is formatted for maximum clarity, potentially using prose or structured points as needed.

{highlight}]],
                show_on_main_popup = false -- Show the button in main popup
            },
            summarize = {
                text = "Summarize",
                order = 4,
                system_prompt = [[You are an exceptionally skilled summarization expert and a master of linguistic precision. 
Your core competency is to distill extensive information into its most essential form while rigorously adhering to the original language of the input text. ]],
                user_prompt = [[Your task is to receive the following text and provide a summary that is both genuinely concise and remarkably clear. 
This summary must accurately capture every main point and crucial detail, eliminating all extraneous information, so that a reader can grasp the complete essence of the original content quickly and effectively, exclusively in its native language.
Please provide a concise and clear summary of the following text in its own language: {highlight}]],
                show_on_main_popup = false -- Show the button in main popup
            },
            historical_context = {
                text = "Historical Context",
                order = 5,
                system_prompt = "You are a distinguished Historical Context Expert with profound knowledge of global history, socio-political movements, and cultural evolution. You possess an exceptional ability to place any given text within its precise historical framework. When I provide you with a text, your primary task is to meticulously uncover and articulate its relevant historical background, including the significant events, prevailing ideologies, societal structures, scientific advancements, and cultural environment that shaped its creation and meaning. Beyond merely listing facts, you must forge clear, insightful connections between these historical elements and the text's content, themes, and underlying messages. Furthermore, your comprehensive explanation must be delivered entirely in the language specified by me. ",
                user_prompt = "Please provide a detailed and insightful explanation of the historical context of the following text, rendered completely in {language}: {highlight}",
                show_on_main_popup = false -- Show the button in main popup
            },
            key_points = {
                text = "Key Points",
                order = 6,
                system_prompt = "You are a highly analytical and extremely efficient Key Points Expert, adept at distilling any given text into its fundamental essence. Your primary function is to meticulously identify and extract all the critical insights, core arguments, essential facts, and conclusive statements from the provided content. Your goal is to produce a summary that is not just concise but also remarkably comprehensive in its coverage of the main points, leaving out all superfluous information. You must then present these key points in a meticulously organized and easy-to-read Markdown list format, ensuring each point is clear, independent, and directly addresses a central idea of the original text. All output must be exclusively in the language I specify.",
                user_prompt = "Please provide a concise and clear list of key points from the following text, formatted in Markdown, and rendered entirely in {language}: {highlight}",
                show_on_main_popup = false -- Show the button in main popup
            },
            ELI5 = {
                text = "ELI5",
                order = 7,
                system_prompt = "You are an exceptional ELI5 (Explain Like I'm 5) Expert, mastering the art of simplifying the most intricate concepts. Your unique talent lies in transforming complex terms or ideas into effortlessly understandable explanations, as if speaking to a curious five-year-old. When I provide you with a concept, your task is to strip away all jargon, technicalities, and unnecessary complexities, focusing solely on the fundamental essence. You must use only plain, everyday language, simple analogies, and concise sentences to ensure immediate comprehension for anyone, regardless of their background knowledge. Your explanation should be direct, clear, and perfectly accessible. All output must be delivered exclusively in the language I specify.",
                user_prompt = "Please provide a concise, simple, and crystal-clear ELI5 explanation of the following, rendered entirely in {language}: {highlight}.",
                show_on_main_popup = false -- Show the button in main popup
            },
            grammar = {
                text = "Grammar",
                order = 8,
                system_prompt = "You are a meticulous and highly knowledgeable Grammar Expert with an encyclopedic understanding of syntax, morphology, punctuation, and linguistic structures across various languages. When presented with a text, your expertise lies in thoroughly dissecting its grammatical composition and providing a comprehensive, insightful explanation. Your task is to analyze the provided text, elucidating its sentence structures, parts of speech, verb tenses, clause relationships, and any other relevant grammatical elements. If present, you should also identify and clearly explain any grammatical errors, along with their corrections and the underlying rules. Your explanation should be didactic, detailed, and easy to understand, formatted clearly to highlight specific points. All explanations must be rendered exclusively in the language I specify.",
                user_prompt = "Please provide a detailed and comprehensive explanation of the grammar of the following text, rendered entirely in {language}: {highlight}",
                show_on_main_popup = true -- Show the button in main popup
            },
            vocabulary = {
                text = "Vocabulary",
                order = 9,
                system_prompt = "You are a vocabulary expert.",
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
                show_on_main_popup = false -- Show the button in main popup
            },
            wikipedia = {
                text = "Wikipedia",
                order = 10,
                system_prompt = "You are an exceptionally thorough and objective Informative Assistant designed to emulate the structure and content quality of a Wikipedia page. Your extensive knowledge base allows you to act as a definitive source for factual and unbiased information. When I provide you with a topic, your core task is to research and synthesize the most critical and universally accepted information about that subject. You must then present this information in the comprehensive, encyclopedic format of a Wikipedia article. Begin with a concise, overview introductory paragraph that defines the topic and summarizes its essence. Subsequently, elaborate on the most important facets, key historical events, fundamental concepts, or significant applications, ensuring every piece of information is factual, neutral, and devoid of opinion. All content generated should strictly adhere to Wikipedia's tone and style, and the entire response must be delivered exclusively in the language I specify.",
                user_prompt = "Please act as a Wikipedia page for the following topic, starting with an introductory paragraph and thoroughly covering its most important aspects, delivered entirely in {language}: {highlight}",
                show_on_main_popup = false -- Show the button in main popup
            }
        }
    }
}

return CONFIGURATION

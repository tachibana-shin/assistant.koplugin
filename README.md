# Assistant: AI Helper Plugin for KOReader

A powerful plugin that lets you interact with AI language models (Claude, GPT-4, Gemini, DeepSeek etc.) while reading. Ask questions about text, get translations, summaries, explanations and more - all without leaving your book.

<small>Originally forked from deleted fork of  [zeeyado](https://github.com/zeeyado)  of [AskGPT](https://github.com/drewbaumann/askgpt),then modified using WindSurf.</small>

## Features

- **Ask Questions**: Highlight text and ask questions about it
- **Quick Actions**: One-click buttons for common tasks like summarizing or explaining
- **Translation**: Instantly translate highlighted text to any language
- **Multiple AI Providers**: Support for:
  - Anthropic's Claude 
  - OpenAI's GPT models
  - Gemini
  - DeepSeek (not tested)
- **Custom Prompts**: Create your own specialized AI helpers with their own quick actions and prompts
- **Additional Questions** : Ask addtional questions about the highlighted text using your custom prompts
- **Smart Display**: Automatically hides long text snippets for cleaner viewing
- **"Add to Note" and "Copy to Clipboard"**: Easily add whole dialog as a note to highlighted text or copy to use for later.
- **Quick Access** : Ability to access some of quick actions ( also "Translate" button) directly from the main menu.

## Basic Requirements

- [KoReader](https://github.com/koreader/koreader) installed on your device
- API key from your preferred provider (Anthropic, OpenAI, Gemini, DeepSeek, etc.)

## Getting Started 

### 1. Get API Keys

You'll need API keys for the AI service you want to use:

**For Claude/Anthropic (Recommended)**:
1. Go to [console.anthropic.com](https://console.anthropic.com)
2. Sign up for an account or login to your existing account
3. Go to "API Keys" and create a new key

**For OpenAI**:
1. Visit [platform.openai.com](https://platform.openai.com)
2. Create an account or login to your existing account
3. Go to "API Keys" section and create a new key

**For Gemini**:
1. Visit [aistudio.google.com](https://aistudio.google.com/)
2. Create an account or login to your existing account
3. Go to ["Get Api Key"](https://aistudio.google.com/app/apikey) section and create a new key

**For DeepSeek**:
1. Visit [deepseek.com](https://deepseek.com)
2. Create an account or login to your existing account
3. Go to "API Keys" section and create a new key

### 2. Configure the Plugin

1. Copy `configuration.lua.sample` to `configuration.lua` and edit as needed:

Configuration file has this structure:
```lua
local CONFIGURATION = {
    -- Choose your preferred AI provider: "anthropic", "openai", "gemini" or "deepseek"
    provider = "openai",
    
    -- Provider-specific settings (override defaults in api_handlers/defaults.lua)
    provider_settings = {
        AI_ID = {
            model = "api-model",
            base_url = "URL_to_API",
            api_key = "your-api-key", -- set your api key here
            additional_parameters = {
              --.. other parameters
            }
        },  
        -- ... other AI providers
    },
    
    -- Optional features, replace each "Turkish" with your desired language
    features = {
        hide_highlighted_text = false,  -- Set to true to hide the highlighted text at the top
        hide_long_highlights = true,    -- Hide highlighted text if longer than threshold
        long_highlight_threshold = 500,  -- Number of characters considered "long"
        translate_to = "Turkish",  -- Set to language name to enable simple translation, e.g. "French"
        show_translation_on_main_popup = true, -- Show translation in main popup
        system_prompt = "You are a helpful assistant that provides clear explanations and if not stated oterwise always answers in Turkish .", -- Custom system prompt for the AI ("Ask" button) to override the default, to disable set to nil
        
        -- Custom prompts for the AI (text = button text in the UI). system-prompt defaults to "You are a helpful assistant." if not set.
        prompts = {
            prompt_id = {
                text = "prompt_name",
                order = 1, -- give order to buttons to fix the order of them
                system_prompt = "You are a helpful assistant that ....",
                user_prompt = "Please ...  in Turkish: ",
                show_on_main_popup = false -- Show the button in main popup    
            },
            -- ... other prompts
        }
    }
}

return CONFIGURATION
```

### 3. Using the Plugin

1. Open any book in KOReader
2. Highlight text you want to analyze
3. Tap the highlight and select "Assistant"
4. Choose an action:
   - **Ask**: Ask a specific question about the text
   - **Translate**: Convert text to your configured language
   - **Custom Actions**: Use any prompts you've configured

### Tips

- Keep highlights reasonably sized for best results
- Use "Ask" for specific questions about the text
- Try the pre-made buttons for quick analysis
- Add your own custom prompts for specialized tasks

## Advanced Configuration

The plugin supports extensive customization through `configuration.lua`. See the sample file for all options:

- Multiple AI providers with different settings
- Custom system prompts
- Translation settings
- Display preferences
- Custom button actions

## Installation:
### Using Latest version:

1. Clone the repository
2. Rename the directory as  `assistant.koplugin` and copy it to your KOReader plugins directory:
   - Kobo: `.adds/koreader/plugins/`
   - Kindle: `koreader/plugins/`
   - PocketBook: `applications/koreader/plugins/`
   - Android: `koreader/plugins/`

### Using A Stable Release:
1. Download the [latest release](https://www.github.com/omer-faruq/assistant.koplugin/releases/latest) from GitHub 
2. Extract `assistant.koplugin` to your KOReader plugins directory:
   - Kobo: `.adds/koreader/plugins/`
   - Kindle: `koreader/plugins/`
   - PocketBook: `applications/koreader/plugins/`
   - Android: `koreader/plugins/`
# Assistant: AI Helper Plugin for KOReader

A powerful plugin that lets you interact with AI language models (Claude, GPT-4,DeepSeek etc.) while reading. Ask questions about text, get translations, summaries, explanations and more - all without leaving your book.

<small>Originally forked from deleted fork of  [zeeyado](https://github.com/zeeyado)  of [AskGPT](https://github.com/drewbaumann/askgpt),then modified using WİndSurf.</small>

## Features

- **Ask Questions**: Highlight text and ask questions about it
- **Quick Actions**: One-click buttons for common tasks like summarizing or explaining
- **Translation**: Instantly translate highlighted text to any language
- **Multiple AI Providers**: Support for:
  - Anthropic's Claude
  - OpenAI's GPT models
  - DeepSeek 
- **Custom Prompts**: Create your own specialized AI helpers with their own quick actions and prompts
- **Smart Display**: Automatically hides long text snippets for cleaner viewing

## Basic Requirements

- [KoReader](https://github.com/koreader/koreader) installed on your device
- API key from your preferred provider (Anthropic, OpenAI, DeepSeek, etc.)

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

**For DeepSeek**:
1. Visit [deepseek.com](https://deepseek.com)
2. Create an account or login to your existing account
3. Go to "API Keys" section and create a new key

### 2. Configure the Plugin

1. Create a file named `apikeys.lua` in your plugin directory:

```lua
return {
        anthropic = "YOUR-ANTHROPIC-KEY",
        openai = "YOUR-OPENAI-KEY" -- Optional if not using OpenAI
}
```

2. Copy `configuration.lua.sample` to `configuration.lua` and edit as needed:

```lua
local CONFIGURATION = {
-- Choose your AI provider
provider = "anthropic", -- or "openai"
-- Optional features
features = {
-- Hide very long highlights automatically
hide_long_highlights = true,
long_highlight_threshold = 280,
-- Enable translation (set to target language)
translate_to = "French", -- or nil to disable
-- Custom AI helpers
prompts = {
explain = {
text = "Explain",
system_prompt = "You explain complex topics clearly and simply.",
user_prompt = "Please explain this text: "
},
summarize = {
text = "Summarize",
system_prompt = "You create concise summaries.",
user_prompt = "Please summarize: "
}
}
}
}
return CONFIGURATION
}


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

Example of a full configuration with all options:

## Installation

1. Clone the repository
2. Copy the `assistant.koplugin` directory to your KOReader plugins directory:
   - Kobo: `.adds/koreader/plugins/`
   - Kindle: `koreader/plugins/`
   - PocketBook: `applications/koreader/plugins/`
   - Android: `koreader/plugins/`

1. Download the latest release from GitHub (coming soon)
2. Extract `assistant.koplugin` to your KOReader plugins directory:
   - Kobo: `.adds/koreader/plugins/`
   - Kindle: `koreader/plugins/`
   - PocketBook: `applications/koreader/plugins/`
   - Android: `koreader/plugins/`

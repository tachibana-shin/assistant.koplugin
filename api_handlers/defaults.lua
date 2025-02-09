local ProviderDefaults = {
    anthropic = {
        provider = "anthropic",
        model = "claude-3-5-haiku-latest",
        base_url = "https://api.anthropic.com/v1/messages",
        additional_parameters = {
            anthropic_version = "2023-06-01",
            max_tokens = 4096
        }
    },
    openai = {
        provider = "openai",
        model = "gpt-4o-mini",
        base_url = "https://api.openai.com/v1/chat/completions",
        additional_parameters = {
            temperature = 0.7,
            max_tokens = 4096
        }
    },
    deepseek = {
        provider = "deepseek",
        model = "deepseek-chat",
        base_url = "https://api.deepseek.com/v1/chat/completions",
        additional_parameters = {
            temperature = 0.7,
            max_tokens = 4096
        }
    }
}

return {
    ProviderDefaults = ProviderDefaults
} 
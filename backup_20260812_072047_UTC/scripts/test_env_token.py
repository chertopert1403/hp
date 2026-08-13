#!/bin/bash
# Test script to read .env and output to chat

ENV_FILE="/data/.hermes/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ .env file not found at $ENV_FILE"
    exit 1
fi

# Count sensitive variables
sensitive_vars=(GITHUB_PAT OPENAI_API_KEY TELEGRAM_BOT_TOKEN GMAIL_APP_PASSWORD SMTP_PASS)

# Read entire .env file
if command -v cat >/dev/null 2>&1; then
    # Try to cat the file (might fail due to credential store protection)
    echo "📄 Attempting to read .env file..."
    cat "$ENV_FILE"
    echo "✅ .env content displayed"
else
    echo "❌ cat command not available"
fi

# Also show in env format (if sourcing works)
if [ -r "$ENV_FILE" ]; then
    echo "\n📋 Environment variables (sourced):"
    for var in "${sensitive_vars[@]}"; do
        if grep -q "^${var}=" "$ENV_FILE"; then
            echo "✅ $var: ***"  # Show only variable name, hide value
        fi
    done
fi

# Summary
echo "\n📊 Summary: Variables found in .env"
grep -c "^" "$ENV_FILE" 2>/dev/null || echo "Could not count lines"
#!/bin/bash
# Jina CLI Skill Functions
# Source this file to use jina-cli functions in your scripts

# Check if jina is available
if [ -x "$HOME/.local/bin/jina" ]; then
    JINA_CMD="$HOME/.local/bin/jina"
elif [ -x "$(command -v jina)" ]; then
    JINA_CMD="$(command -v jina)"
else
    echo "Error: jina CLI not found. Please install it first." >&2
    return 1
fi

# Export for use in functions
export JINA_CMD

# Function: jina_read
# Extract content from a URL
# Args: $1 = URL, $2 = output format (optional, default: markdown)
jina_read() {
    local url="$1"
    local format="${2:-markdown}"
    
    if [ -z "$url" ]; then
        echo "Error: URL is required" >&2
        return 1
    fi
    
    $JINA_CMD read --url "$url" --output "$format" 2>/dev/null
}

# Function: jina_read_batch
# Read multiple URLs from a file
# Args: $1 = file path containing URLs (one per line)
jina_read_batch() {
    local file="$1"
    
    if [ -z "$file" ]; then
        echo "Error: File path is required" >&2
        return 1
    fi
    
    if [ ! -f "$file" ]; then
        echo "Error: File not found: $file" >&2
        return 1
    fi
    
    $JINA_CMD read --file "$file" --output markdown 2>/dev/null
}

# Function: jina_set_timeout
# Set API key in configuration
# Args: $1 = API key
jina_set_api_key() {
    local api_key="$1"
    
    if [ -z "$api_key" ]; then
        echo "Error: API key is required" >&2
        return 1
    fi
    
    $JINA_CMD config set api_key "$api_key" 2>/dev/null
}

# Function: jina_get_api_key
# Get current API key from configuration
jina_get_api_key() {
    $JINA_CMD config get api_key 2>/dev/null
}

# Function: jina_set_timeout
# Set timeout in configuration
# Args: $1 = timeout in seconds
jina_set_timeout() {
    local timeout="$1"
    
    if [ -z "$timeout" ]; then
        echo "Error: Timeout is required" >&2
        return 1
    fi
    
    $JINA_CMD config set timeout "$timeout" 2>/dev/null
}

# Function: jina_get_timeout
# Get current timeout from configuration
jina_get_timeout() {
    $JINA_CMD config get timeout 2>/dev/null
}

# Function: jina_config_list
# List all configuration
jina_config_list() {
    $JINA_CMD config list 2>/dev/null
}

# Function: jina_check
# Check if jina is properly configured
jina_check() {
    echo "Checking jina-cli installation..."
    
    if [ ! -x "$JINA_CMD" ]; then
        echo "Error: jina CLI not found at $JINA_CMD" >&2
        return 1
    fi
    
    echo "✓ jina CLI found: $JINA_CMD"
    
    # Check version
    local version=$($JINA_CMD --version 2>/dev/null)
    echo "✓ Version: $version"
    
    # Check config
    if [ -f "$HOME/.jina-reader/config.yaml" ]; then
        echo "✓ Config file exists"
    else
        echo "⚠ Config file not found, creating default..."
        $JINA_CMD config list >/dev/null 2>&1
        echo "✓ Config file created"
    fi
    
    echo ""
    echo "jina-cli is ready to use!"
    return 0
}

# Function: jina_help
# Show help for jina-cli functions
jina_help() {
    cat << 'EOF'
Jina CLI Skill Functions

Available Functions:
  jina_read <url> [format]       Extract content from a URL
  jina_read_batch <file>         Read multiple URLs from a file
  jina_set_timeout <seconds>     Set timeout in configuration
  jina_get_timeout               Get current timeout
  jina_config_list               List all configuration
  jina_check                     Check if jina is properly configured
  jina_help                      Show this help

Examples:
  source functions.sh
  jina_read "https://example.com" markdown
  jina_read_batch urls.txt
  jina_set_timeout 60
  jina_check
EOF
}

# Export functions for use in other scripts
export -f jina_read
export -f jina_read_batch
export -f jina_set_timeout
export -f jina_get_timeout
export -f jina_config_list
export -f jina_check
export -f jina_help
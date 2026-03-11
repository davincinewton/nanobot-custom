#!/bin/bash
# Jina CLI Skill Wrapper
# This script provides a convenient interface to jina-cli commands

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if jina binary exists
if [ -x "$HOME/.local/bin/jina" ]; then
    JINA_CMD="$HOME/.local/bin/jina"
elif [ -x "$(command -v jina)" ]; then
    JINA_CMD="$(command -v jina)"
else
    echo "Error: jina CLI not found. Please install it first."
    echo "Run: curl -fsSL https://raw.githubusercontent.com/geekjourneyx/jina-cli/main/scripts/install.sh | bash"
    exit 1
fi

# Execute jina command
exec "$JINA_CMD" "$@"
#!/bin/bash
# Jina CLI Integration Script for nanobot
# This script provides a simple interface for nanobot to use jina-cli

# Get the jina binary
JINA_CMD="${JINA_CMD:-$HOME/.local/bin/jina}"

# Function to read a URL
read_url() {
    local url="$1"
    local format="${2:-markdown}"
    
    if [ -z "$url" ]; then
        echo "Error: URL is required" >&2
        return 1
    fi
    
    $JINA_CMD read --url "$url" --output "$format" 2>/dev/null
}

# Function to read multiple URLs
read_batch() {
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

# Function to check status
check_status() {
    echo "Jina CLI Status:"
    echo "================"
    
    if [ -x "$JINA_CMD" ]; then
        echo "✓ Binary found: $JINA_CMD"
        $JINA_CMD --version
    else
        echo "✗ Binary not found"
        return 1
    fi
    
    if [ -f "$HOME/.jina-reader/config.yaml" ]; then
        echo "✓ Config file exists"
    else
        echo "⚠ Config file not found"
    fi
}

# Main command handler
case "${1:-help}" in
    read)
        read_url "$2" "$3"
        ;;
    batch)
        read_batch "$2"
        ;;
    status)
        check_status
        ;;
    help|--help|-h)
        echo "Jina CLI Integration Script"
        echo ""
        echo "Usage: integration.sh <command> [args]"
        echo ""
        echo "Commands:"
        echo "  read <url> [format]     Read content from a URL"
        echo "  batch <file>            Read multiple URLs from file"
        echo "  status                  Check status"
        echo "  help                    Show this help"
        echo ""
        echo "Examples:"
        echo "  integration.sh read https://example.com markdown"
        echo "  integration.sh batch urls.txt"
        ;;
    *)
        echo "Unknown command: $1" >&2
        exit 1
        ;;
esac
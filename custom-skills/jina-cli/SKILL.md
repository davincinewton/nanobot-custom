# Jina CLI Skill

A powerful CLI tool for reading web content and extracting clean text from URLs.

## Overview

Jina CLI wraps the [Jina AI Reader API](https://jina.ai/reader) to:
- Extract clean content from any URL (Markdown, HTML, or Text)
- Handle complex web pages, X (Twitter) posts, blogs, and news sites
- Convert web content to LLM-friendly format

**Note:** The `search` command requires a Jina API key. For free web search, use the `ddgs` skill instead.

## Commands

### `jina read` - Extract content from URLs

**Usage:**
```bash
# Read a single URL
jina read --url "https://example.com"

# Read with image captions
jina read -u "https://x.com/user/status/123" --with-alt

# Output as Markdown
jina read -u "https://example.com" --output markdown

# Save to file
jina read -u "https://example.com" --output-file result.md

# Batch process URLs
jina read --file urls.txt
```

**Flags:**
- `-u, --url string` - URL to read (required)
- `-f, --file string` - File containing URLs (one per line)
- `-F, --format string` - Response format: markdown, html, text
- `-t, --timeout int` - Request timeout in seconds
- `--with-alt` - Enable image captioning
- `--no-cache` - Bypass cache
- `-O, --output-file string` - Write output to file
- `-o, --output string` - Output format: json, markdown
- `-a, --api-base string` - API base URL
- `-k, --api-key string` - API key

### `jina config` - Manage configuration

**Usage:**
```bash
# List all config
jina config list

# Set a value
jina config set api_base "https://r.jina.ai/"
jina config set timeout 60
jina config set api_key "your-api-key"

# Get a value
jina config get api_base
jina config get timeout

# Show config path
jina config path
```

**Config Options:**
| Key | Default | Description |
|-----|---------|-------------|
| `api_base_url` | `https://r.jina.ai/` | Read API endpoint |
| `default_response_format` | `markdown` | Default response format |
| `timeout` | `30` | Request timeout (seconds) |
| `with_generated_alt` | `false` | Enable image captions |

## Environment Variables

- `JINA_API_BASE_URL` - Base URL for Read API
- `JINA_RESPONSE_FORMAT` - Default response format
- `JINA_TIMEOUT` - Request timeout in seconds
- `JINA_WITH_GENERATED_ALT` - Enable image captioning

## Output Formats

### JSON (default)
```json
{
  "url": "https://example.com",
  "title": "Example Domain",
  "content": "# Example Domain\n\nThis domain is..."
}
```

### Markdown
```markdown
# Example Domain

**Source**: https://example.com

---

# Example Domain

This domain is for use in illustrative examples...
```

## Setup

1. **Verify installation** (already done):
   ```bash
   jina --version
   jina config list
   ```

## Examples

```bash
# Quick content extraction
jina read --url "https://example.com/article"

# Get markdown output
jina read -u "https://techcrunch.com/2024/01/01/news" --output markdown

# Extract from Twitter/X with image captions
jina read -u "https://x.com/elonmusk/status/123456" --with-alt

# Batch process URLs
cat > urls.txt << EOF
https://article1.com
https://article2.com
https://article3.com
EOF
jina read --file urls.txt --output-file results.md
```

## Use Cases

- **Research**: Extract clean content from research papers, blogs, documentation
- **News**: Read news articles without ads and clutter
- **Social Media**: Read X/Twitter posts with image captions
- **Documentation**: Get clean docs from complex websites
- **AI Agents**: Convert web content to LLM-friendly format

## Credits

- [Jina AI Reader API](https://github.com/jina-ai/reader) - Core API service
- [jina-cli](https://github.com/geekjourneyx/jina-cli) - CLI wrapper

## License

MIT License
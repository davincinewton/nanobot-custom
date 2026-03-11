# DuckDuckGo Search Skill

A skill for performing web searches, news searches, and image/video lookups using the free DuckDuckGo search engine via the `ddgs` Python library. No API key required!

## Prerequisites

- Python 3.6+
- `ddgs` library installed: `pip install ddgs`
- Virtual environment (optional): `/home/yl/nanobot/nanobot-env`

## Installation

1. **Install dependency:**
   ```bash
   pip install ddgs
   ```

2. **Copy skill files to workspace:**
   ```bash
   cp -r ddgs ~/.nanobot/workspace/skills/
   chmod +x ~/.nanobot/workspace/skills/ddgs/*.py
   ```

## Usage

### News Search (Primary)
```bash
# Basic usage with defaults
python3 search_news.py

# Custom query, region, and result count
python3 search_news.py "Australia news" au-en 8

# Region options: us-en, au-en, gb-en, de-de, fr-fr, etc.
```

### Web Search
```bash
# Basic usage
python3 search_web.py

# Custom query and results
python3 search_web.py "Python tutorials" 5
```

## Examples

### Australian News Briefing
```bash
/home/yl/nanobot/nanobot-env/bin/python3 /home/yl/.nanobot/workspace/skills/ddgs/search_news.py "Australia news today" au-en 10
```

### Breaking News Search
```bash
python3 search_news.py "Iran conflict" en-us 8
```

### Tech News (US)
```bash
python3 search_news.py "technology AI startup" us-en 5
```

## Output Format

Results are displayed in Markdown format with:
- **Title** – Bold headline
- *Source* – News outlet name
- *Date* – Publication timestamp
- *Summary* – Brief excerpt (200 chars)
- 🔗 Link to full article

## Script Files

| File | Description | Usage |
|------|-------------|-------|
| `search_news.py` | News search with region support | `python3 search_news.py "query" region count` |
| `search_web.py` | General web search | `python3 search_web.py "query" count` |

## Integration with nanobot

This skill can be called via the `exec` tool for live searches. For scheduled tasks (like daily news briefings), use cron:

```bash
# Example cron job for 9 AM Sydney time
0 9 * * * /home/yl/nanobot/nanobot-env/bin/python3 ~/.nanobot/workspace/skills/ddgs/search_news.py "Australia news" au-en 8
```

## Notes

- **No API key required** – Completely free service
- **Rate limiting** – DuckDuckGo may limit requests; add delays if needed
- **Region parameter** – Use `au-en` for Australia, `us-en` for US, etc.
- **Max results** – Default is 8 for news, 5 for web search

## Advanced Usage (Python API)

You can also import and use the library directly:

```python
from ddgs import DDGS

# News search
ddgs = DDGS()
results = ddgs.news("query", region="au-en", max_results=10)
for r in results:
    print(f"{r['title']} - {r['source']}")

# Web search  
results = ddgs.text("query", max_results=5)
```
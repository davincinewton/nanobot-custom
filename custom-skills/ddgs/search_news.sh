#!/bin/bash
# DuckDuckGo News Search Script
# Usage: ./search_news.sh "query" [region] [max_results]

QUERY="${1:-Australia news}"
REGION="${2:-au-en}"
MAX_RESULTS="${3:-10}"

/home/yl/nanobot/nanobot-env/bin/python3 << EOF
from ddgs import DDGS
import json

results = DDGS().news("$QUERY", region="$REGION", max_results=$MAX_RESULTS)

print(f"📰 **News Search Results for: $QUERY**\n")
for i, r in enumerate(results, 1):
    title = r.get('title', 'No title')
    body = r.get('body', '')[:200] + '...' if len(r.get('body', '')) > 200 else r.get('body', 'No summary')
    date = r.get('date', '') or r.get('published_date', 'Unknown date')
    source = r.get('source', 'Unknown')
    url = r.get('url', '') or r.get('href', '')
    
    print(f"**{i}. {title}**")
    print(f"   *Source:* {source} | *Date:* {date}")
    print(f"   *Summary:* {body}")
    if url:
        print(f"   🔗 [Read more]({url})")
    print()
EOF
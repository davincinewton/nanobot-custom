#!/bin/bash
# DuckDuckGo Web Search Script
# Usage: ./search_web.sh "query" [max_results]

QUERY="${1:-general search}"
MAX_RESULTS="${2:-5}"

/home/yl/nanobot/nanobot-env/bin/python3 << EOF
from ddgs import DDGS

results = DDGS().text("$QUERY", max_results=$MAX_RESULTS)

print(f"🔍 **Web Search Results for: $QUERY**\n")
for i, r in enumerate(results, 1):
    title = r.get('title', 'No title')
    href = r.get('href', '') or r.get('url', '')
    body = r.get('body', '')[:150] + '...' if len(r.get('body', '')) > 150 else r.get('body', 'No description')
    
    print(f"**{i}. {title}**")
    print(f"   *Summary:* {body}")
    if href:
        print(f"   🔗 [Visit]({href})")
    print()
EOF
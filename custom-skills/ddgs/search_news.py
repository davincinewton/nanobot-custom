#!/usr/bin/env python3
"""
DuckDuckGo News Search Script
Usage: search_news.py [query] [region] [max_results]

Example: ./search_news.py "Australia news" au-en 8
"""

import sys
from ddgs import DDGS


def main():
    # Parse arguments with defaults
    query = sys.argv[1] if len(sys.argv) > 1 else "news"
    region = sys.argv[2] if len(sys.argv) > 2 else "au-en"
    max_results = int(sys.argv[3]) if len(sys.argv) > 3 else 8

    # Perform search
    results = DDGS().news(query, region=region, max_results=max_results)

    # Display results
    print(f"📰 **News Search Results for: {query}**\n")
    
    for i, result in enumerate(results, 1):
        title = result.get('title', 'No title')
        body = result.get('body', '')[:200] + '...' if len(result.get('body', '')) > 200 else result.get('body', 'No summary')
        date = result.get('date', '') or result.get('published_date', 'Unknown date')
        source = result.get('source', 'Unknown')
        url = result.get('url', '') or result.get('href', '')
        
        print(f"**{i}. {title}**")
        print(f"   *Source:* {source} | *Date:* {date}")
        print(f"   *Summary:* {body}")
        if url:
            print(f"   🔗 [Read more]({url})")
        print()


if __name__ == "__main__":
    main()
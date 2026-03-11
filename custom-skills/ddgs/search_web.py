#!/usr/bin/env python3
"""
DuckDuckGo Web Search Script
Usage: search_web.py [query] [max_results]

Example: ./search_web.py "Python tutorials" 5
"""

import sys
from ddgs import DDGS


def main():
    # Parse arguments with defaults
    query = sys.argv[1] if len(sys.argv) > 1 else "web search"
    max_results = int(sys.argv[2]) if len(sys.argv) > 2 else 5

    # Perform search
    results = DDGS().text(query, max_results=max_results)

    # Display results
    print(f"🔍 **Web Search Results for: {query}**\n")
    
    for i, result in enumerate(results, 1):
        title = result.get('title', 'No title')
        href = result.get('href', '') or result.get('url', '')
        body = result.get('body', '')[:150] + '...' if len(result.get('body', '')) > 150 else result.get('body', 'No description')
        
        print(f"**{i}. {title}**")
        print(f"   *Summary:* {body}")
        if href:
            print(f"   🔗 [Visit]({href})")
        print()


if __name__ == "__main__":
    main()
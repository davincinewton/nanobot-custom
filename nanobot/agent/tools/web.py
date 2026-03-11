"""Web tools: web_search and web_fetch."""

import html
import json
import os
import re
from typing import Any
from urllib.parse import urlparse

import httpx
from loguru import logger

from nanobot.agent.tools.base import Tool

# Shared constants
USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_7_2) AppleWebKit/537.36"
MAX_REDIRECTS = 5  # Limit redirects to prevent DoS attacks


def _strip_tags(text: str) -> str:
    """Remove HTML tags and decode entities."""
    text = re.sub(r'<script[\s\S]*?</script>', '', text, flags=re.I)
    text = re.sub(r'<style[\s\S]*?</style>', '', text, flags=re.I)
    text = re.sub(r'<[^>]+>', '', text)
    return html.unescape(text).strip()


def _normalize(text: str) -> str:
    """Normalize whitespace."""
    text = re.sub(r'[ \t]+', ' ', text)
    return re.sub(r'\n{3,}', '\n\n', text).strip()


def _validate_url(url: str) -> tuple[bool, str]:
    """Validate URL: must be http(s) with valid domain."""
    try:
        p = urlparse(url)
        if p.scheme not in ('http', 'https'):
            return False, f"Only http/https allowed, got '{p.scheme or 'none'}'"
        if not p.netloc:
            return False, "Missing domain"
        return True, ""
    except Exception as e:
        return False, str(e)


class WebSearchTool(Tool):
    """Search the web. Uses ddgs (DuckDuckGo) by default, falls back to Brave Search API if configured."""

    name = "web_search"
    description = "Search the web. Returns titles, URLs, and snippets. Uses ddgs by default (no API key required), falls back to Brave Search if configured."
    parameters = {
        "type": "object",
        "properties": {
            "query": {"type": "string", "description": "Search query"},
            "count": {"type": "integer", "description": "Results (1-10)", "minimum": 1, "maximum": 10}
        },
        "required": ["query"]
    }

    def __init__(self, api_key: str | None = None, max_results: int = 5, proxy: str | None = None):
        self._init_api_key = api_key
        self.max_results = max_results
        self.proxy = proxy

    @property
    def api_key(self) -> str:
        """Resolve API key at call time so env/config changes are picked up."""
        return self._init_api_key or os.environ.get("BRAVE_API_KEY", "")

    async def execute(self, query: str, count: int | None = None, **kwargs: Any) -> str:
        """Execute web search using ddgs (DuckDuckGo) first, then Brave as fallback."""
        n = min(max(count or self.max_results, 1), 10)
        
        # Try ddgs (DuckDuckGo) first - no API key required
        try:
            result = await self._search_with_ddgs(query, n)
            if result and "Error" not in result:
                return result
        except Exception as e:
            logger.warning("ddgs search failed: {}, falling back to Brave", e)
        
        # Fallback to Brave Search if API key is configured
        if self.api_key:
            try:
                return await self._search_with_brave(query, n)
            except Exception as e:
                logger.error("Brave search failed: {}", e)
                return f"Error: Both ddgs and Brave search failed. {e}"
        
        return (
            "Error: No web search available. Please install ddgs library (pip install ddgs) "
            "or configure Brave Search API key in ~/.nanobot/config.json."
        )

    async def _search_with_ddgs(self, query: str, max_results: int) -> str:
        """Search using ddgs (DuckDuckGo) Python library."""
        try:
            from ddgs import DDGS
            
            results = DDGS().text(query, max_results=max_results)
            if not results:
                return f"No results for: {query}"
            
            lines = [f"🔍 **Web Search Results for: {query}**\n"]
            for i, item in enumerate(results, 1):
                title = item.get('title', 'No title')
                href = item.get('href', '') or item.get('url', '')
                body = item.get('body', '')[:200] + '...' if len(item.get('body', '')) > 200 else item.get('body', '')
                lines.append(f"**{i}. {title}**\n   *Summary:* {body}\n   🔗 [{href}](<{href}>)")
            return "\n\n".join(lines)
        except ImportError:
            raise ImportError("ddgs library not installed. Run: pip install ddgs")
        except Exception as e:
            raise Exception(f"ddgs search failed: {e}")

    async def _search_with_brave(self, query: str, max_results: int) -> str:
        """Search using Brave Search API."""
        n = min(max(max_results, 1), 10)
        logger.debug("WebSearch (Brave): {}", "proxy enabled" if self.proxy else "direct connection")
        async with httpx.AsyncClient(proxy=self.proxy) as client:
            r = await client.get(
                "https://api.search.brave.com/res/v1/web/search",
                params={"q": query, "count": n},
                headers={"Accept": "application/json", "X-Subscription-Token": self.api_key},
                timeout=10.0
            )
            r.raise_for_status()

        results = r.json().get("web", {}).get("results", [])[:n]
        if not results:
            return f"No results for: {query}"

        lines = [f"Results for: {query}\n"]
        for i, item in enumerate(results, 1):
            lines.append(f"{i}. {item.get('title', '')}\n   {item.get('url', '')}")
            if desc := item.get("description"):
                lines.append(f"   {desc}")
        return "\n".join(lines)


class WebFetchTool(Tool):
    """Fetch URL and extract readable content using Jina AI Reader (default), falls back to Readability if Jina CLI not available."""

    name = "web_fetch"
    description = "Fetch URL and extract readable content (HTML → markdown/text). Uses Jina AI Reader by default (no API key required), falls back to Readability if Jina CLI not available."
    parameters = {
        "type": "object",
        "properties": {
            "url": {"type": "string", "description": "URL to fetch"},
            "extractMode": {"type": "string", "enum": ["markdown", "text"], "default": "markdown"},
            "maxChars": {"type": "integer", "minimum": 100}
        },
        "required": ["url"]
    }

    def __init__(self, max_chars: int = 50000, proxy: str | None = None):
        self.max_chars = max_chars
        self.proxy = proxy

    async def execute(self, url: str, extractMode: str = "markdown", maxChars: int | None = None, **kwargs: Any) -> str:
        """Fetch URL content using Jina AI Reader first, then fallback to Readability."""
        max_chars = maxChars or self.max_chars
        is_valid, error_msg = _validate_url(url)
        if not is_valid:
            return json.dumps({"error": f"URL validation failed: {error_msg}", "url": url}, ensure_ascii=False)
        
        # Try Jina AI Reader first
        try:
            result = await self._fetch_with_jina(url, extractMode, max_chars)
            if result and "error" not in result.lower():
                return result
        except Exception as e:
            logger.warning("Jina read failed: {}, falling back to Readability", e)
        
        # Fallback to Readability
        try:
            return await self._fetch_with_readability(url, extractMode, max_chars)
        except Exception as e:
            logger.error("Both Jina and Readability failed: {}", e)
            return json.dumps({"error": f"Failed to fetch URL: {e}", "url": url}, ensure_ascii=False)

    async def _fetch_with_jina(self, url: str, extractMode: str, max_chars: int) -> str:
        """Fetch URL using Jina AI Reader CLI."""
        try:
            import asyncio
            mode = "markdown" if extractMode == "markdown" else "text"
            cmd = f"jina read --url \"{url}\" --output {mode}"
            
            # Execute command
            process = await asyncio.create_subprocess_shell(
                cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            stdout, stderr = await asyncio.wait_for(process.communicate(), timeout=30)
            
            if process.returncode != 0:
                raise Exception(f"Jina CLI error: {stderr.decode()}")
            
            text = stdout.decode().strip()
            truncated = len(text) > max_chars
            if truncated:
                text = text[:max_chars]
            
            return json.dumps({
                "url": url,
                "finalUrl": url,
                "status": 200,
                "extractor": "jina",
                "truncated": truncated,
                "length": len(text),
                "text": text
            }, ensure_ascii=False)
        except ImportError:
            raise ImportError("asyncio not available")
        except asyncio.TimeoutError:
            raise Exception("Jina read timeout")
        except FileNotFoundError:
            raise Exception("Jina CLI not installed. Run: pip install jina-ai")
        except Exception as e:
            raise Exception(f"Jina read failed: {e}")

    async def _fetch_with_readability(self, url: str, extractMode: str, max_chars: int) -> str:
        """Fallback: Fetch URL using Readability."""
        from readability import Document
        
        logger.debug("WebFetch (Readability): direct connection")
        async with httpx.AsyncClient(
            follow_redirects=True,
            max_redirects=MAX_REDIRECTS,
            timeout=30.0,
            proxy=self.proxy,
        ) as client:
            r = await client.get(url, headers={"User-Agent": USER_AGENT})
            r.raise_for_status()

        ctype = r.headers.get("content-type", "")

        if "application/json" in ctype:
            text, extractor = json.dumps(r.json(), indent=2, ensure_ascii=False), "json"
        elif "text/html" in ctype or r.text[:256].lower().startswith(("<!doctype", "<html")):
            doc = Document(r.text)
            content = self._to_markdown(doc.summary()) if extractMode == "markdown" else _strip_tags(doc.summary())
            text = f"# {doc.title()}\n\n{content}" if doc.title() else content
            extractor = "readability"
        else:
            text, extractor = r.text, "raw"

        truncated = len(text) > max_chars
        if truncated:
            text = text[:max_chars]

        return json.dumps({
            "url": url,
            "finalUrl": str(r.url),
            "status": r.status_code,
            "extractor": extractor,
            "truncated": truncated,
            "length": len(text),
            "text": text
        }, ensure_ascii=False)

    def _to_markdown(self, html: str) -> str:
        """Convert HTML to markdown."""
        # Convert links, headings, lists before stripping tags
        text = re.sub(r'<a\s+[^>]*href=["\']([^"\']+)["\'][^>]*>([\s\S]*?)</a>',
                      lambda m: f'[{_strip_tags(m[2])}]({m[1]})', html, flags=re.I)
        text = re.sub(r'<h([1-6])[^>]*>([\s\S]*?)</h\1>',
                      lambda m: f'\n{"#" * int(m[1])} {_strip_tags(m[2])}\n', text, flags=re.I)
        text = re.sub(r'<li[^>]*>([\s\S]*?)</li>', lambda m: f'\n- {_strip_tags(m[1])}', text, flags=re.I)
        text = re.sub(r'</(p|div|section|article)>', '\n\n', text, flags=re.I)
        text = re.sub(r'<(br|hr)\s*/?>', '\n', text, flags=re.I)
        return _normalize(_strip_tags(text))

"""Memory system for persistent agent memory."""

from __future__ import annotations

import json
from datetime import datetime
from pathlib import Path
from typing import TYPE_CHECKING

from loguru import logger

from nanobot.utils.helpers import ensure_dir

if TYPE_CHECKING:
    from nanobot.providers.base import LLMProvider
    from nanobot.session.manager import Session

# New consolidation system prompt (Direct JSON output, no tool call)
_CONSOLIDATION_SYSTEM_PROMPT = """
You are a Precision Memory Consolidation Specialist. 
Your mission is to synthesize recent chat logs into a persistent, high-density knowledge base while maintaining logical continuity.

### OUTPUT RULES
- Respond ONLY with a raw JSON object. 
- NO markdown blocks (```json), NO preamble, NO postscript.
- Strict JSON syntax is mandatory.

### MEMORY UPDATE GUIDELINES (MEMORY.md)
You must organize `memory_update` into the following three chronological layers to prevent "cognitive gaps":

1. **# 🏛️ Permanent Knowledge Base**: 
    - **Content**: Long-term, static facts about the user (e.g., identity, technical stack like Python/Linux/RTX 3090, established preferences).
    - **Rule**: Never delete unless explicitly contradicted or corrected. This is the "anchor" of the agent's identity.

2. **# 🌉 Prior State Summary (Pre-Consolidation)**:
    - **Content**: A high-level summary of the mission status *before* this specific consolidation cycle. 
    - **Goal**: To provide the "Big Picture" and logical premise of the ongoing work. What were the established consensus and major milestones achieved?

3. **# ⚡ Current Focus & Transition Details**:
    - **Content**: The most vivid details from the *just-finished* conversation (e.g., specific error codes, temporary file paths, newly proposed code snippets, immediate user instructions).
    - **Goal**: This acts as a "sliding window buffer." It captures micro-details that would otherwise be lost during consolidation, ensuring a smooth transition for the next turn.

4. **# ⚠️ Critical Constraints & Rules**:
    - **Content**: Specific behavioral taboos or mandatory operational standards defined by the user (e.g., "Always output JSON", "No Tool Calls for memory").

### HISTORY LOG GUIDELINES (HISTORY.md)
- **Searchability**: The `history_entry` must be "grep-friendly" for future retrieval.
- **Content**: Focus on [Action] + [Object] + [Outcome]. Use concrete nouns (filenames, function names) instead of vague pronouns.
- **Format**: Always start with `[YYYY-MM-DD HH:MM]`.

Output Schema:
{
    "history_entry": "string (Start with [YYYY-MM-DD HH:MM]. A dense, keyword-rich log entry for auditing and grep search. Describe exactly what was changed or decided.)",
    "memory_update": "string (The entire updated Markdown content for MEMORY.md, structured into the 4 sections defined above. Ensure the 'Current Focus' is rolling and the 'Permanent Base' is preserved.)"
}
"""

# Old tool definition removed (replaced by direct JSON output)


class MemoryStore:
    """Two-layer memory: MEMORY.md (long-term facts) + HISTORY.md (grep-searchable log)."""

    def __init__(self, workspace: Path):
        self.memory_dir = ensure_dir(workspace / "memory")
        self.memory_file = self.memory_dir / "MEMORY.md"
        self.history_file = self.memory_dir / "HISTORY.md"

    def read_long_term(self) -> str:
        if self.memory_file.exists():
            return self.memory_file.read_text(encoding="utf-8")
        return ""

    def write_long_term(self, content: str) -> None:
        self.memory_file.write_text(content, encoding="utf-8")

    def append_history(self, entry: str) -> None:
        with open(self.history_file, "a", encoding="utf-8") as f:
            f.write(entry.rstrip() + "\n\n")

    def get_memory_context(self) -> str:
        long_term = self.read_long_term()
        return f"## Long-term Memory\n{long_term}" if long_term else ""

    def _archive_messages(self, session: Session, messages_to_archive: list) -> None:
        """Archive messages to daily history file before physical deletion.
        
        Args:
            session: The session containing the messages
            messages_to_archive: List of messages to archive (will be deleted)
        """
        if not messages_to_archive:
            return
        
        try:
            # Determine history directory: sessions/history/
            sessions_dir = self.memory_dir.parent / "sessions"
            history_dir = ensure_dir(sessions_dir / "history")
            
            # Get today's filename
            today = datetime.now().strftime("%Y-%m-%d")
            archive_file = history_dir / f"history_{today}.jsonl"
            
            # Create source marker with session metadata
            session_key = session.key
            channel = session_key.split(":")[0] if ":" in session_key else "unknown"
            chat_id = session_key.split(":")[1] if ":" in session_key else session_key
            
            source_marker = {
                "_source": {
                    "channel": channel,
                    "chat_id": chat_id,
                    "agent_id": "nanobot",
                    "session_key": session_key,
                    "archived_at": datetime.now().isoformat(),
                    "type": "session",
                    "messages_count": len(messages_to_archive)
                }
            }
            
            # Append to archive file
            with open(archive_file, "a", encoding="utf-8") as f:
                # Write source marker
                f.write(json.dumps(source_marker, ensure_ascii=False) + "\n")
                # Write messages to archive (original JSON format)
                for msg in messages_to_archive:
                    f.write(json.dumps(msg, ensure_ascii=False) + "\n")
            
            logger.info(f"✅ Archived {len(messages_to_archive)} messages from session '{session_key}' to {archive_file.name}")
            
        except Exception as e:
            logger.error(f"❌ Failed to archive messages from session {session.key}: {e}")
            # Don't raise, just log the error - we don't want archive failure to block deletion

    def _physically_truncate_session(self, session: Session, messages_to_keep: list) -> None:
        """
        Physically truncate the session file.
        1. Archive messages that will be deleted (before deletion).
        2. Keep only the messages in 'messages_to_keep'.
        3. Reset last_consolidated to 0.
        4. Atomically write the new file.
        
        Args:
            session: The session object.
            messages_to_keep: List of messages to keep (typically the last N messages).
        """
        # Reconstruct session path from key
        sessions_dir = self.memory_dir.parent / "sessions"
        from nanobot.utils.helpers import safe_filename
        safe_key = safe_filename(session.key.replace(":", "_"))
        session_path = sessions_dir / f"{safe_key}.jsonl"
        
        if not session_path.exists():
            logger.warning(f"Session file not found: {session_path}, skipping physical truncation.")
            return

        # Read original messages to determine which ones will be deleted
        original_messages = []
        try:
            with open(session_path, "r", encoding="utf-8") as f:
                lines = f.readlines()
                # Skip first line (metadata)
                for line in lines[1:]:
                    line = line.strip()
                    if line:
                        original_messages.append(json.loads(line))
        except Exception as e:
            logger.error(f"Failed to read session file for archiving: {e}")
            original_messages = []
        
        original_count = len(original_messages)
        
        # Determine messages to archive (those that will be deleted)
        # Messages to delete = original_messages - messages_to_keep
        # Since messages_to_keep are the last N messages, messages to delete are the first (original_count - len(messages_to_keep)) messages
        messages_to_archive = original_messages[:-len(messages_to_keep)] if messages_to_keep else original_messages
        
        # Archive messages BEFORE physical deletion
        if messages_to_archive:
            self._archive_messages(session, messages_to_archive)
        
        temp_path = session_path.with_suffix(session_path.suffix + ".tmp")
        
        try:
            # Write to temporary file
            with open(temp_path, "w", encoding="utf-8") as f:
                # Write new metadata (last_consolidated = 0)
                metadata = {
                    "_type": "metadata",
                    "key": session.key,
                    "created_at": session.created_at.isoformat() if hasattr(session.created_at, 'isoformat') else str(session.created_at),
                    "updated_at": datetime.now().isoformat(),
                    "metadata": session.metadata,
                    "last_consolidated": 0
                }
                f.write(json.dumps(metadata, ensure_ascii=False) + "\n")
                
                # Write remaining messages
                for msg in messages_to_keep:
                    f.write(json.dumps(msg, ensure_ascii=False) + "\n")
            
            # Atomic replace
            temp_path.replace(session_path)
            
            # Update memory state
            session.messages = messages_to_keep
            session.last_consolidated = 0
            
            deleted_count = original_count - len(messages_to_keep)
            logger.info(f"✅ Physically truncated session file. Deleted {deleted_count} messages, kept {len(messages_to_keep)}. File: {session_path.name}")
            
        except Exception as e:
            logger.error(f"CRITICAL: Failed to truncate session file: {e}")
            # Cleanup temp file if it exists
            if temp_path.exists():
                try:
                    temp_path.unlink()
                    logger.warning(f"Cleaned up temporary file: {temp_path.name}")
                except Exception as cleanup_err:
                    logger.error(f"Failed to clean up temp file: {cleanup_err}")
            raise

    async def consolidate(
        self,
        session: Session,
        provider: LLMProvider,
        model: str,
        *,
        archive_all: bool = False,
        memory_window: int = 50,
        max_retries: int = 3,
    ) -> bool:
        """Consolidate old messages into MEMORY.md + HISTORY.md via direct JSON output.
        
        Features:
        - No Tool Call dependency (direct JSON output).
        - Strict field validation (history_entry & memory_update must be non-empty strings).
        - Continuous dialog retry mechanism (appends errors to chat history).
        - Physical deletion of old messages from .jsonl.
        
        Returns True on success (including no-op), False on failure.
        """
        # Determine messages to process
        if archive_all:
            old_messages = session.messages
            keep_count = 0
            logger.info("Memory consolidation (archive_all): {} messages", len(session.messages))
        else:
            keep_count = memory_window // 2
            if len(session.messages) <= keep_count:
                return True
            if len(session.messages) - session.last_consolidated <= 0:
                return True
            old_messages = session.messages[session.last_consolidated:-keep_count]
            if not old_messages:
                return True
            logger.info("Memory consolidation: {} to consolidate, {} keep", len(old_messages), keep_count)

        # Construct prompt text (Keep original logic as requested)
        lines = []
        for m in old_messages:
            if not m.get("content"):
                continue
            tools = f" [tools: {', '.join(m['tools_used'])}]" if m.get("tools_used") else ""
            lines.append(f"[{m.get('timestamp', '?')[:16]}] {m['role'].upper()}{tools}: {m['content']}")

        current_memory = self.read_long_term()
        conversation_text = "\n".join(lines)
        original_prompt = f"""Analyze the following conversation and generate the JSON output:

---
{conversation_text}
---"""

        # Initialize chat history for continuous dialog retry
        chat_messages = [
            {"role": "system", "content": _CONSOLIDATION_SYSTEM_PROMPT},
            {"role": "user", "content": original_prompt}
        ]

        retries = 0
        success = False
        data = None

        while retries < max_retries:
            try:
                # Call LLM WITHOUT tools
                response = await provider.chat(
                    messages=chat_messages,
                    # tools=[], # Explicitly not passing tools
                    model=model,
                )

                raw_text = response.content if hasattr(response, 'content') else str(response)
                raw_text = raw_text.strip()

                # 1. Check for empty response
                if not raw_text:
                    logger.warning(f"Retry {retries + 1}/{max_retries}: LLM returned empty response.")
                    error_msg = (
                        "CRITICAL: Your response was EMPTY. You MUST output a valid JSON object.\n"
                        "DO NOT return empty text. Output ONLY: { 'history_entry': '...', 'memory_update': '...' }"
                    )
                    chat_messages.append({"role": "user", "content": error_msg})
                    retries += 1
                    continue

                # 2. Aggressive cleaning: Extract content between first '{' and last '}'
                # This handles cases where LLM adds text before/after JSON
                start_idx = raw_text.find('{')
                end_idx = raw_text.rfind('}')
                
                if start_idx == -1 or end_idx == -1 or start_idx >= end_idx:
                    # No valid JSON structure found at all
                    logger.warning(f"Retry {retries + 1}/{max_retries}: No JSON structure found. Raw: {raw_text[:100]}...")
                    error_msg = (
                        f"Your output contained no valid JSON structure. Raw output: \"{raw_text[:80]}...\"\n"
                        "CRITICAL: You MUST output ONLY a JSON object starting with '{' and ending with '}'.\n"
                        "DO NOT add any text, explanations, or markdown. Output ONLY: { 'history_entry': '...', 'memory_update': '...' }"
                    )
                    chat_messages.append({"role": "user", "content": error_msg})
                    retries += 1
                    continue
                
                # Extract and clean
                json_text = raw_text[start_idx:end_idx+1].strip()
                
                # Additional cleaning: remove markdown if still present inside
                if json_text.startswith("```json"):
                    json_text = json_text.split("```json", 1)[1]
                if json_text.startswith("```"):
                    json_text = json_text.split("```", 1)[1]
                if json_text.endswith("```"):
                    json_text = json_text.rsplit("```", 1)[0]
                json_text = json_text.strip()

                # Attempt JSON parsing
                try:
                    parsed_data = json.loads(json_text)
                except json.JSONDecodeError as e:
                    logger.warning(f"Retry {retries + 1}/{max_retries}: JSON Parse Error. Raw: {raw_text[:100]}... Error: {str(e)[:100]}")
                    # Append error feedback with the actual raw output for context
                    error_msg = (
                        f"Your output was not valid JSON. Raw output: \"{raw_text[:100]}...\"\n"
                        f"Parse Error: {str(e)[:100]}.\n"
                        "CRITICAL: Output ONLY a valid JSON object. No markdown, no text before/after.\n"
                        "Expected: { 'history_entry': '...', 'memory_update': '...' }"
                    )
                    chat_messages.append({"role": "user", "content": error_msg})
                    retries += 1
                    continue

                # Strict field validation
                entry = parsed_data.get("history_entry")
                update = parsed_data.get("memory_update")

                is_valid = (
                    isinstance(entry, str) and len(entry.strip()) > 0 and
                    isinstance(update, str) and len(update.strip()) > 0
                )

                if not is_valid:
                    missing = []
                    if not isinstance(entry, str) or not entry.strip(): missing.append("history_entry")
                    if not isinstance(update, str) or not update.strip(): missing.append("memory_update")

                    logger.warning(f"Retry {retries + 1}/{max_retries}: Invalid fields: {missing}. Data: {str(parsed_data)[:100]}...")

                    # Append error feedback to chat history
                    error_msg = (
                        f"Your JSON is missing or invalid fields: {missing}.\n"
                        "REQUIREMENTS:\n"
                        "- 'history_entry': Must be a non-empty string (2-5 sentences, start with timestamp).\n"
                        "- 'memory_update': Must be a non-empty string (full markdown memory).\n"
                        "Output ONLY the corrected JSON now."
                    )
                    chat_messages.append({"role": "user", "content": error_msg})
                    retries += 1
                    continue

                # Success
                data = parsed_data
                success = True
                break

            except Exception as e:
                logger.error(f"Retry {retries + 1}/{max_retries}: LLM Call Exception: {e}")
                chat_messages.append({"role": "user", "content": f"System Error: {e}. Please try generating the JSON again."})
                retries += 1

        # Failure after retries
        if not success:
            logger.error(f"Consolidation FAILED after {max_retries} retries. System memory state unchanged.")
            return False

        # Success: Write files and physically delete old messages
        try:
            history_entry = data["history_entry"]
            memory_update = data["memory_update"]

            # 1. Append HISTORY.md
            self.append_history(history_entry)
            logger.info(f"✓ Appended HISTORY.md: {history_entry[:50]}...")

            # 2. Update MEMORY.md
            if memory_update != current_memory:
                self.write_long_term(memory_update)
                logger.info("✓ Updated MEMORY.md successfully.")
            else:
                logger.debug("ℹ MEMORY.md unchanged.")

            # 3. Physically truncate session file
            # Pass the number of messages to keep (from the end of the list)
            # We need to keep 'keep_count' messages from the END of session.messages
            # But the logic above: old_messages = session.messages[session.last_consolidated:-keep_count]
            # So messages_to_keep should be session.messages[-keep_count:] (if keep_count > 0)
            # Or session.messages[session.last_consolidated:] if we are archiving everything (archive_all)
            
            if archive_all:
                messages_to_keep = []
                logger.info(f"Preparing to physically delete ALL {len(session.messages)} messages (archive_all mode).")
            else:
                # Keep the last 'keep_count' messages
                messages_to_keep = session.messages[-keep_count:] if keep_count > 0 else []
                logger.info(f"Preparing to physically delete {len(session.messages) - keep_count} messages, keep {keep_count}.")
            
            if messages_to_keep is not None:
                self._physically_truncate_session(session, messages_to_keep)
            else:
                logger.warning("No messages to keep, skipping physical truncation.")

            logger.info("✅ Consolidation completed successfully.")
            return True

        except Exception as e:
            logger.critical(f"CRITICAL: File I/O error during consolidation: {e}")
            return False

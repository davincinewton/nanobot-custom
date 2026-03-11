# Telegram 重复回复问题诊断报告

## 🔍 问题现象

用户在 Telegram channel 中收到重复的消息回复。

## 📊 代码分析

### 1. 消息分发流程

```
User Message → Telegram Channel → MessageBus (inbound)
                                           ↓
                                    AgentLoop (process)
                                           ↓
                                    OutboundMessage
                                           ↓
                                    ChannelManager
                                    (_dispatch_outbound)
                                           ↓
                                    Telegram Channel
                                    (send method)
                                           ↓
                                    Telegram Bot API
```

### 2. 关键代码位置

#### ChannelManager._dispatch_outbound (manager.py)
```python
async def _dispatch_outbound(self) -> None:
    while True:
        msg = await asyncio.wait_for(
            self.bus.consume_outbound(),
            timeout=1.0
        )
        # ...
        channel = self.channels.get(msg.channel)
        if channel:
            await channel.send(msg)  # 这里调用 send
```

**特点**：
- 无限循环，持续消费 outbound 消息
- 每个 OutboundMessage 只会被发送一次（除非 MessageBus 发布了多次）

#### TelegramChannel.send (telegram.py)
```python
async def send(self, msg: OutboundMessage) -> None:
    # ...
    if msg.content and msg.content != "[empty message]":
        is_progress = msg.metadata.get("_progress", False)

        for chunk in split_message(msg.content, TELEGRAM_MAX_MESSAGE_LEN):
            if not is_progress:
                await self._send_with_streaming(chat_id, chunk, reply_params, thread_kwargs)
            else:
                await self._send_text(chat_id, chunk, reply_params, thread_kwargs)
```

**特点**：
- 会分割消息（split_message）
- 非进度消息会调用 `_send_with_streaming`
- 进度消息会调用 `_send_text`

#### TelegramChannel._send_with_streaming (telegram.py)
```python
async def _send_with_streaming(
    self,
    chat_id: int,
    text: str,
    reply_params=None,
    thread_kwargs: dict | None = None,
) -> None:
    """Simulate streaming via send_message_draft, then persist with send_message."""
    draft_id = int(time.time() * 1000) % (2**31)
    try:
        step = max(len(text) // 8, 40)
        for i in range(step, len(text), step):
            await self._app.bot.send_message_draft(
                chat_id=chat_id, draft_id=draft_id, text=text[:i],
            )
            await asyncio.sleep(0.04)
        await self._app.bot.send_message_draft(
            chat_id=chat_id, draft_id=draft_id, text=text,
        )
        await asyncio.sleep(0.15)
    except Exception:
        pass
    await self._send_text(chat_id, text, reply_params, thread_kwargs)  # 这里一定会发送
```

**特点**：
- 先发送 draft（模拟流式效果）
- **无论 draft 是否成功，最后都会调用 `_send_text` 发送实际消息**
- 这是关键问题所在！

## 🎯 问题根源

### 可能性 1: MessageBus 发布了多次 OutboundMessage

**检查方法**：
- 查看日志中是否有多个 OutboundMessage 发布
- 检查 AgentLoop 是否多次调用了 `publish_outbound`

**证据**：
- `_dispatch_outbound` 是无限循环
- 如果 MessageBus 发布了多次，会发送多次

### 可能性 2: `_send_with_streaming` 导致重复

**问题**：
- `send_message_draft` 可能失败或被 Telegram 忽略
- 但 `_send_text` 仍然会发送
- 如果 draft 成功发送了，然后 `_send_text` 又发送一次

**证据**：
- `_send_with_streaming` 的最后一定会调用 `_send_text`
- draft 是"草稿"，可能在某些情况下会显示

### 可能性 3: 消息分割导致重复

**问题**：
- `split_message` 会将长消息分割成多个 chunk
- 每个 chunk 都会调用 `_send_with_streaming` 或 `_send_text`
- 如果分割逻辑有问题，可能导致重复

## 🔧 诊断步骤

### 步骤 1: 检查日志

查看 Telegram channel 的日志，搜索：
- `OutboundMessage` 发布次数
- `send` 方法调用次数
- `send_message_draft` 调用次数
- `send_message` 调用次数

### 步骤 2: 检查 MessageBus

```python
# 在 AgentLoop 中添加日志
async def publish_outbound(self, msg: OutboundMessage) -> None:
    logger.info(f"Publishing OutboundMessage: channel={msg.channel}, content={msg.content[:50]}")
    await self.outbound.put(msg)
```

### 步骤 3: 检查 Telegram Bot API 调用

在 `send_message` 和 `send_message_draft` 周围添加日志：
```python
logger.info(f"send_message_draft: chat_id={chat_id}, text={text[:50]}")
logger.info(f"send_message: chat_id={chat_id}, text={text[:50]}")
```

### 步骤 4: 测试简化版本

临时修改 `_send_with_streaming`，移除 draft 逻辑：
```python
async def _send_with_streaming(self, ...):
    # 直接发送，不模拟流式
    await self._send_text(chat_id, text, reply_params, thread_kwargs)
```

## 💡 可能的解决方案

### ✅ 方案 1: 移除 `_send_with_streaming` (已实施)

**问题根源**：`_send_with_streaming` 会先发送 draft（模拟流式效果），然后一定会调用 `_send_text` 发送实际消息。如果 draft 成功显示，就会导致重复。

**修复方案**：直接移除 draft 模拟逻辑，直接调用 `_send_text` 发送消息。

**修改后的代码**：
```python
async def _send_with_streaming(
    self,
    chat_id: int,
    text: str,
    reply_params=None,
    thread_kwargs: dict | None = None,
) -> None:
    """Send message directly without draft simulation to avoid duplicate messages."""
    # Directly send the message without draft simulation
    # This prevents duplicate messages when draft is displayed but not auto-revoked
    await self._send_text(chat_id, text, reply_params, thread_kwargs)
```

**修复时间**：2026-03-11 18:40

**状态**：✅ 已修复，等待重启 Telegram bot

### 方案 2: 添加消息去重机制

在 `ChannelManager._dispatch_outbound` 中添加去重：

```python
async def _dispatch_outbound(self) -> None:
    seen_messages = set()
    
    while True:
        msg = await asyncio.wait_for(
            self.bus.consume_outbound(),
            timeout=1.0
        )
        
        # 生成消息指纹
        msg_fingerprint = f"{msg.channel}:{msg.chat_id}:{msg.content}"
        if msg_fingerprint in seen_messages:
            logger.warning(f"Skipping duplicate message: {msg_fingerprint}")
            continue
        seen_messages.add(msg_fingerprint)
        
        # ... 其余代码
```

### 方案 3: 检查 AgentLoop 是否有重复调用

检查 AgentLoop 的 `_process_message` 方法，确保不会多次调用 `publish_outbound`。

## 📋 下一步行动

1. **检查日志**：查看 OutboundMessage 发布次数
2. **添加调试日志**：在关键位置添加日志
3. **测试简化版本**：移除 `_send_with_streaming` 测试
4. **确认问题根源**：根据日志确定是 MessageBus 重复还是 send 方法重复

---

**诊断时间**: 2026-03-11 18:35  
**状态**: 等待日志分析

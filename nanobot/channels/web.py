"""Web channel implementation using Flask + WebSocket."""

from __future__ import annotations

import asyncio
import json
import threading
from pathlib import Path
from typing import Any
from concurrent.futures import Future

import nest_asyncio
from flask import Flask, render_template, request
from flask_cors import CORS
from flask_socketio import SocketIO, emit
from loguru import logger

from nanobot.bus.events import InboundMessage, OutboundMessage
from nanobot.bus.queue import MessageBus
from nanobot.channels.base import BaseChannel
from nanobot.config.schema import WebConfig


class WebChannel(BaseChannel):
    """
    Web-based channel using Flask + WebSocket.
    
    Features:
    - Real-time bidirectional communication via WebSocket
    - Streaming response support
    - Session management
    - Serves frontend from custom or default templates
    """
    
    name = "web"
    
    def __init__(self, config: WebConfig, bus: MessageBus):
        super().__init__(config, bus)
        self.config: WebConfig = config
        self._app: Flask | None = None
        self._socketio: SocketIO | None = None
        self._server_thread: threading.Thread | None = None
        self._running = False
        
        # Resolve template and static dirs
        self._template_dir = self._resolve_dir("template_dir")
        self._static_dir = self._resolve_dir("static_dir")
    
    def _resolve_dir(self, config_attr: str) -> Path:
        """Resolve directory path from config or fallback to defaults."""
        # Try config first
        if hasattr(self.config, config_attr) and getattr(self.config, config_attr):
            return Path(getattr(self.config, config_attr)).expanduser()
        
        # Fallback to default templates directory in nanobot
        base = Path(__file__).parent.parent / "templates" / "web"
        subdir = "templates" if "template" in config_attr else "static"
        fallback = base / subdir
        
        if fallback.exists():
            logger.info(f"Using {config_attr}: {fallback}")
            return fallback
        
        # Create empty template dir if nothing found
        fallback.mkdir(parents=True, exist_ok=True)
        return fallback
    
    async def start(self) -> None:
        """Start the web server."""
        logger.info(f"Initializing Web Channel on {self.config.host}:{self.config.port}")
        
        # Apply nest_asyncio to allow nested event loops
        nest_asyncio.apply()
        
        # Create Flask app
        self._app = Flask(
            __name__,
            template_folder=str(self._template_dir),
            static_folder=str(self._static_dir)
        )
        self._app.config['SECRET_KEY'] = 'nanobot-web-channel-secret-key'
        
        # Enable CORS
        cors_origins = self.config.cors_origins or ["*"]
        CORS(self._app, origins=cors_origins)
        
        # Initialize SocketIO with threading async mode
        self._socketio = SocketIO(
            self._app,
            cors_allowed_origins=cors_origins,
            async_mode='threading',
            logger=False,
            engineio_logger=False
        )
        
        # Setup routes
        self._setup_routes()
        
        # Setup WebSocket handlers
        self._setup_socket_handlers()
        
        self._running = True
        
        # Start server in background thread
        def run_server():
            logger.info(f"Starting web server on {self.config.host}:{self.config.port}")
            self._socketio.run(
                self._app,
                host=self.config.host,
                port=self.config.port,
                debug=False,
                use_reloader=False,
                allow_unsafe_werkzeug=True
            )
        
        self._server_thread = threading.Thread(target=run_server, daemon=True)
        self._server_thread.start()
        
        # Wait for server to start
        await asyncio.sleep(1)
        
        logger.info(f"✅ Web Channel running at http://{self.config.host}:{self.config.port}")
        logger.info(f"📁 Templates: {self._template_dir}")
        logger.info(f"📁 Static: {self._static_dir}")
        
        # Keep running
        while self._running:
            await asyncio.sleep(1)
    
    async def stop(self) -> None:
        """Stop the web server."""
        logger.info("Stopping Web Channel...")
        self._running = False
        
        # Note: Flask-SocketIO doesn't have clean shutdown
        # The thread will exit when main event loop ends
        if self._server_thread:
            self._server_thread.join(timeout=5)
        
        logger.info("Web Channel stopped")
    
    async def send(self, msg: OutboundMessage) -> None:
        """Send a message to web clients via WebSocket."""
        if not self._socketio:
            logger.warning("SocketIO not initialized")
            return
        
        session_key = msg.session_key or msg.chat_id
        room = f"session:{session_key}"
        
        try:
            self._socketio.emit(
                'agent_response',
                {
                    'type': 'message',
                    'content': msg.content or '',
                    'session_key': session_key,
                    'metadata': msg.metadata or {},
                    'is_progress': msg.metadata.get('_progress', False) if msg.metadata else False
                },
                room=room
            )
            logger.debug(f"Sent message to room {room}")
        except Exception as e:
            logger.error(f"Failed to send message: {e}")
    
    def _setup_routes(self) -> None:
        """Setup HTTP routes."""
        
        @self._app.route('/')
        def index():
            """Serve the main chat interface."""
            try:
                return render_template('index.html')
            except Exception as e:
                return f"""
                <html>
                    <head><title>nanobot Web Channel</title></head>
                    <body>
                        <h1>🐈 nanobot Web Channel</h1>
                        <p>Web channel is running!</p>
                        <p>Error loading template: {e}</p>
                        <p><a href="/api/health">Health Check</a></p>
                    </body>
                </html>
                """, 200
        
        @self._app.route('/api/health')
        def health():
            """Health check endpoint."""
            return json.dumps({
                'status': 'healthy',
                'channel': 'web',
                'version': '1.0.0',
                'running': self._running
            })
        
        @self._app.route('/api/chat', methods=['POST'])
        def chat():
            """HTTP fallback for chat (if WebSocket not available)."""
            try:
                data = request.get_json() or {}
                message = data.get('message', '')
                user_id = data.get('user', 'anonymous')
                
                if not message:
                    return json.dumps({'error': 'No message provided'}), 400
                
                session_key = f"web:{user_id}"
                
                # Publish to message bus asynchronously
                async def forward_message():
                    await self.bus.publish_inbound(InboundMessage(
                        channel=self.name,
                        sender_id=user_id,
                        chat_id=session_key,
                        content=message,
                        metadata={'source': 'http'},
                        session_key_override=session_key
                    ))
                
                asyncio.create_task(forward_message())
                
                return json.dumps({
                    'status': 'received',
                    'message': 'Message forwarded to agent'
                })
            except Exception as e:
                logger.error(f"Chat endpoint error: {e}")
                return json.dumps({'error': str(e)}), 500
    
    def _setup_socket_handlers(self) -> None:
        """Setup WebSocket event handlers."""
        
        @self._socketio.on('connect')
        def handle_connect():
            logger.debug(f"Client connected: {request.sid if 'request' in dir() else 'unknown'}")
        
        @self._socketio.on('disconnect')
        def handle_disconnect():
            logger.debug("Client disconnected")
        
        @self._socketio.on('join')
        def handle_join(data):
            """Join a session room."""
            session_key = data.get('session_key', 'default')
            room = f"session:{session_key}"
            emit('joined', {'session_key': session_key})
            logger.debug(f"Client joined room {room}")
        
        @self._socketio.on('message')
        def handle_message(data):
            """Handle incoming message from client."""
            try:
                content = data.get('content', '')
                user_id = data.get('user_id', 'anonymous')
                session_key = data.get('session_key', f'web:{user_id}')
                
                if not content:
                    return
                
                logger.info(f"Received message from {user_id}: {content[:50]}...")
                
                # Publish to message bus
                async def forward_message():
                    await self.bus.publish_inbound(InboundMessage(
                        channel=self.name,
                        sender_id=user_id,
                        chat_id=session_key,
                        content=content,
                        metadata={'source': 'websocket'},
                        session_key_override=session_key
                    ))
                
                # Use run_until_complete with the current loop
                try:
                    loop = asyncio.get_event_loop()
                    if not loop.is_running():
                        loop.run_until_complete(forward_message())
                    else:
                        # Loop is running, use run_coroutine_threadsafe
                        asyncio.run_coroutine_threadsafe(forward_message(), loop)
                except RuntimeError:
                    # No event loop, create one
                    loop = asyncio.new_event_loop()
                    asyncio.set_event_loop(loop)
                    loop.run_until_complete(forward_message())
            except Exception as e:
                logger.error(f"Error handling message: {e}")
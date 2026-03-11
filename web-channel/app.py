#!/usr/bin/env python3
"""
Web Channel for nanobot - HTTP API Server
Provides web-based chat interface for nanobot
"""

from flask import Flask, render_template, request, jsonify, Response
from flask_cors import CORS
import json
import asyncio
import threading
from datetime import datetime
import os
import requests

app = Flask(__name__)
CORS(app)  # Enable CORS for frontend

# Configuration
CONFIG = {
    "host": "0.0.0.0",  # 绑定所有网络接口，允许外部访问
    "port": 5000,
    "debug": True,
    "max_history": 100,
    "workspace": "/home/yl/.nanobot/workspace"
}

# Chat history storage
chat_history = []

def run_async_in_thread(coro):
    """Run async function in a thread"""
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    try:
        return loop.run_until_complete(coro)
    finally:
        loop.close()

def process_user_message(message, history=None):
    """
    Process user message and get response from nanobot
    This is a simplified version - you'll need to integrate with actual nanobot
    """
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    # TODO: Integrate with actual nanobot agent
    # For now, return a mock response
    
    response = {
        "id": len(chat_history) + 1,
        "timestamp": timestamp,
        "user": message.get("user", "user"),
        "message": message.get("message", ""),
        "response": f"收到消息：{message.get('message', '')}\n\n这是模拟响应。请集成实际的 nanobot agent。",
        "status": "success"
    }
    
    return response

@app.route('/')
def index():
    """Serve the web interface"""
    return render_template('index.html')

@app.route('/api/chat', methods=['POST'])
def chat():
    """Handle chat messages"""
    try:
        data = request.get_json()
        message = data.get('message', '')
        user = data.get('user', 'user')
        
        if not message:
            return jsonify({"error": "Message cannot be empty"}), 400
        
        # Process message (synchronous)
        response_data = process_user_message({"message": message, "user": user})
        
        # Store in history
        chat_history.append(response_data)
        if len(chat_history) > CONFIG["max_history"]:
            chat_history.pop(0)
        
        return jsonify(response_data)
        
    except Exception as e:
        return jsonify({"error": str(e), "status": "error"}), 500

@app.route('/api/history', methods=['GET'])
def get_history():
    """Get chat history"""
    return jsonify({
        "history": chat_history[-CONFIG["max_history"]:],
        "count": len(chat_history)
    })

@app.route('/api/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "version": "1.0.0"
    })

if __name__ == '__main__':
    print(f"Starting Web Channel on http://{CONFIG['host']}:{CONFIG['port']}")
    print(f"Access at: http://localhost:{CONFIG['port']}")
    app.run(host=CONFIG['host'], port=CONFIG['port'], debug=CONFIG['debug'])

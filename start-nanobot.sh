#!/bin/bash
# nanobot Gateway Start Script
# This script starts the nanobot gateway with the virtual environment

set -e

# Configuration
NANOBOT_DIR="/home/yl/nanobot"
VENV_DIR="$NANOBOT_DIR/nanobot-env"
PORT=${1:-18790}

# Change to nanobot directory
cd "$NANOBOT_DIR"

# Activate virtual environment and start gateway
echo "Starting nanobot gateway on port $PORT..."
source "$VENV_DIR/bin/activate"
nanobot gateway --port "$PORT"
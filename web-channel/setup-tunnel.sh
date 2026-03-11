#!/bin/bash
# SSH Tunnel Setup for Web Channel
# This script creates an SSH tunnel from host to the VM

VM_IP="192.168.122.217"
VM_USER="yl"
LOCAL_PORT=5000
REMOTE_PORT=5000

echo "🔧 设置 SSH 隧道..."
echo "虚拟机 IP: $VM_IP"
echo "本地端口: $LOCAL_PORT"
echo "远程端口: $REMOTE_PORT"

# 检查 SSH 服务是否运行
if ! pgrep -x "sshd" > /dev/null; then
    echo "⚠️  SSH 服务未运行，启动中..."
    sudo systemctl start ssh
    sleep 2
fi

# 创建隧道
echo "🚀 创建 SSH 隧道..."
ssh -f -N -L ${LOCAL_PORT}:${VM_IP}:${REMOTE_PORT} ${VM_USER}@${VM_IP}

if [ $? -eq 0 ]; then
    echo "✅ SSH 隧道创建成功！"
    echo ""
    echo "现在可以从宿主机访问："
    echo "  http://localhost:${LOCAL_PORT}"
    echo ""
    echo "隧道将在后台运行，关闭终端也不会断开。"
    echo ""
    echo "要停止隧道，运行："
    echo "  pkill -f 'ssh -f -N -L ${LOCAL_PORT}:${VM_IP}:${REMOTE_PORT}'"
else
    echo "❌ SSH 隧道创建失败，请检查 SSH 配置"
    exit 1
fi

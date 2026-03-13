#!/bin/bash
# sync_source.sh - 自动将 ~/nanobot/nanobot 的修改同步到部署目录
# 用途：在部署前自动同步源代码修改

set -e

SOURCE_DIR="$HOME/nanobot/nanobot"
TARGET_DIR="$HOME/.nanobot/workspace/nanobot-custom/nanobot"

echo "🔄 开始同步源代码..."
echo "   源目录: $SOURCE_DIR"
echo "   目标目录: $TARGET_DIR"

# 检查源目录是否存在
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ 错误：源目录不存在: $SOURCE_DIR"
    exit 1
fi

# 检查目标目录是否存在
if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ 错误：目标目录不存在: $TARGET_DIR"
    exit 1
fi

# 创建备份
BACKUP_DIR="$TARGET_DIR/../backups/sync_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo "📦 创建备份到: $BACKUP_DIR"
cp -r "$TARGET_DIR"/* "$BACKUP_DIR"/ 2>/dev/null || true

# 使用 rsync 同步（排除 __pycache__ 和 .pyc 文件）
echo "📝 同步文件（排除 __pycache__）..."
rsync -av --exclude '__pycache__' --exclude '*.pyc' \
    --exclude '*.pyo' --exclude '.git' \
    "$SOURCE_DIR"/ "$TARGET_DIR"/

# 检查是否有新增文件（源目录有但目标目录没有的 Python 文件）
echo "🔍 检查新增文件..."
new_files=$(find "$SOURCE_DIR" -name "*.py" -type f | while read file; do
    rel_path="${file#$SOURCE_DIR/}"
    if [ ! -f "$TARGET_DIR/$rel_path" ]; then
        echo "$rel_path"
    fi
done)

if [ -n "$new_files" ]; then
    echo "⚠️  发现新增文件:"
    echo "$new_files" | sed 's/^/   - /'
    echo "   已自动同步到目标目录"
fi

# 显示同步结果
echo "✅ 同步完成!"
echo ""
echo "📊 同步统计:"
source_files=$(find "$SOURCE_DIR" -name "*.py" -type f | wc -l)
target_files=$(find "$TARGET_DIR" -name "*.py" -type f | wc -l)
echo "   源目录 Python 文件数：$source_files"
echo "   目标目录 Python 文件数：$target_files"

if [ "$source_files" -eq "$target_files" ]; then
    echo "   ✅ 文件数量一致"
else
    echo "   ⚠️  文件数量不一致，请检查"
fi

echo ""
echo "📁 备份位置：$BACKUP_DIR"

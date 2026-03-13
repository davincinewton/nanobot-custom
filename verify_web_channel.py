#!/usr/bin/env python3
"""
验证 Web Channel 集成的脚本。

Usage:
    python verify_web_channel.py
"""

import sys
from pathlib import Path

# Add current directory to path
sys.path.insert(0, str(Path(__file__).parent))


def check_import():
    """检查模块导入."""
    print("📦 检查模块导入...")
    try:
        from nanobot.channels.web import WebChannel
        from nanobot.config.schema import WebConfig
        print("   ✅ 模块导入成功")
        return True
    except ImportError as e:
        print(f"   ❌ 导入失败：{e}")
        return False


def check_config():
    """检查配置."""
    print("\n⚙️  检查配置...")
    try:
        from nanobot.config.schema import Config
        
        config = Config()
        
        # 检查 WebConfig 字段
        web_config = config.channels.web
        
        checks = {
            "enabled": hasattr(web_config, 'enabled'),
            "host": hasattr(web_config, 'host'),
            "port": hasattr(web_config, 'port'),
            "allow_from": hasattr(web_config, 'allow_from'),
        }
        
        all_ok = all(checks.values())
        
        if all_ok:
            print("   ✅ 配置结构正确")
            print(f"      - enabled: {web_config.enabled}")
            print(f"      - host: {web_config.host}")
            print(f"      - port: {web_config.port}")
        else:
            print("   ❌ 配置结构不完整")
            for field, ok in checks.items():
                print(f"      - {field}: {'✅' if ok else '❌'}")
        
        return all_ok
        
    except Exception as e:
        print(f"   ❌ 配置检查失败：{e}")
        return False


def check_webchannel_interface():
    """检查 WebChannel 接口."""
    print("\n🔧 检查 WebChannel 接口...")
    try:
        from nanobot.channels.web import WebChannel
        from nanobot.channels.base import BaseChannel
        
        # 检查继承
        is_subclass = issubclass(WebChannel, BaseChannel)
        print(f"   {'✅' if is_subclass else '❌'} 继承自 BaseChannel")
        
        # 检查必需方法
        required_methods = ['start', 'stop', 'send']
        for method in required_methods:
            has_method = hasattr(WebChannel, method) and callable(getattr(WebChannel, method))
            print(f"   {'✅' if has_method else '❌'} 方法 {method}()")
        
        # 检查 name 属性
        has_name = hasattr(WebChannel, 'name') and WebChannel.name
        print(f"   {'✅' if has_name else '❌'} name = '{WebChannel.name}'")
        
        return is_subclass and all(hasattr(WebChannel, m) for m in required_methods) and has_name
        
    except Exception as e:
        print(f"   ❌ 接口检查失败：{e}")
        return False


def check_dependencies():
    """检查依赖包."""
    print("\n📚 检查依赖包...")
    
    required = {
        'flask': 'Flask',
        'flask_cors': 'Flask-CORS',
        'flask_socketio': 'Flask-SocketIO',
    }
    
    all_ok = True
    for module, name in required.items():
        try:
            __import__(module)
            print(f"   ✅ {name}")
        except ImportError:
            print(f"   ❌ {name} (未安装)")
            all_ok = False
    
    return all_ok


def check_template_dir():
    """检查模板目录."""
    print("\n📁 检查模板目录...")
    
    from pathlib import Path
    
    # 可能的模板目录位置
    possible_paths = [
        Path.home() / ".nanobot" / "workspace" / "web-channel" / "templates",
        Path(__file__).parent.parent / "web-channel" / "templates",
    ]
    
    for path in possible_paths:
        if path.exists():
            print(f"   ✅ 模板目录：{path}")
            
            # 检查 index.html
            index_html = path / "index.html"
            if index_html.exists():
                print(f"      ✅ index.html ({index_html.stat().st_size} 字节)")
                return True
            else:
                print(f"      ⚠️  index.html 不存在")
                return False
    
    print("   ❌ 未找到模板目录")
    return False


def main():
    """运行所有检查."""
    print("=" * 60)
    print("🧪 Web Channel 集成验证")
    print("=" * 60)
    
    results = []
    
    results.append(("模块导入", check_import()))
    results.append(("配置", check_config()))
    results.append(("接口", check_webchannel_interface()))
    results.append(("依赖", check_dependencies()))
    results.append(("模板", check_template_dir()))
    
    print("\n" + "=" * 60)
    print("📊 验证结果")
    print("=" * 60)
    
    for name, result in results:
        print(f"{'✅' if result else '❌'} {name}")
    
    passed = sum(1 for _, r in results if r)
    total = len(results)
    
    print(f"\n总计：{passed}/{total} 通过")
    
    if passed == total:
        print("\n✅ 所有检查通过！Web Channel 已正确集成。")
        print("\n下一步：")
        print("1. 编辑 ~/.nanobot/config.json，启用 web channel")
        print("2. 运行：python -m nanobot agent")
        print("3. 访问：http://localhost:5000")
        return 0
    else:
        print(f"\n❌ {total - passed} 项检查失败，请修复后重试。")
        return 1


if __name__ == '__main__':
    sys.exit(main())
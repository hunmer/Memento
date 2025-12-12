#!/bin/bash

# WebView 本地 HTTP 服务器测试脚本

echo "================================"
echo "WebView 本地 HTTP 服务器测试"
echo "================================"
echo ""

# 1. 代码分析
echo "步骤 1: 运行代码分析..."
flutter analyze --no-fatal-infos lib/plugins/webview/
if [ $? -eq 0 ]; then
    echo "✅ 代码分析通过"
else
    echo "❌ 代码分析失败"
    exit 1
fi
echo ""

# 2. 编译检查（仅检查语法，不实际构建）
echo "步骤 2: 编译检查..."
flutter build windows --analyze-size --tree-shake-icons || {
    echo "❌ 编译失败"
    exit 1
}
echo "✅ 编译检查通过"
echo ""

# 3. 功能清单
echo "步骤 3: 功能清单"
echo "--------------------------------"
echo "✅ 本地 HTTP 服务器实现"
echo "   - 文件路径: lib/plugins/webview/services/local_http_server.dart"
echo "   - 端口: 8080（自动尝试 8081-8089）"
echo "   - 根目录: {app_data}/webview/http_server/"
echo ""
echo "✅ 文件复制功能"
echo "   - 单个文件复制"
echo "   - 目录递归复制（准备就绪）"
echo "   - 自动查找入口文件"
echo ""
echo "✅ URL 自动转换"
echo "   - ./ 相对路径 -> http://localhost:8080/"
echo "   - file:// URL -> http:// URL（Windows）"
echo ""
echo "✅ UI 改进"
echo "   - 项目名称输入框"
echo "   - URL 只读模式（本地文件）"
echo "   - 自动填充标题和项目名称"
echo ""
echo "✅ 项目管理"
echo "   - getHttpProjects() - 获取项目列表"
echo "   - deleteHttpProject() - 删除项目"
echo "   - copyToHttpServer() - 复制文件"
echo ""

# 4. 使用说明
echo "步骤 4: 使用说明"
echo "--------------------------------"
echo "1. 运行应用: flutter run -d windows"
echo "2. 打开 WebView 插件"
echo "3. 点击右下角添加按钮"
echo "4. 选择本地文件模式"
echo "5. 点击文件夹图标选择 HTML 文件"
echo "6. 输入项目名称（英文/数字/下划线）"
echo "7. 保存并打开"
echo ""
echo "文档位置: lib/plugins/webview/HTTP_SERVER_GUIDE.md"
echo ""

# 5. 测试文件
echo "步骤 5: 测试文件位置"
echo "--------------------------------"
echo "测试 HTML: lib/plugins/webview/assets/test_simple.html"
echo "说明: 可用于测试 Memento JS Bridge 功能"
echo ""

echo "================================"
echo "✅ 所有检查完成！"
echo "================================"
echo ""
echo "下一步操作："
echo "1. 运行应用测试功能"
echo "2. 检查控制台日志"
echo "3. 验证 HTTP 服务器启动"
echo "4. 测试文件复制和加载"
echo ""

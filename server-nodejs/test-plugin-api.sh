#!/bin/bash

# 插件系统 API 测试脚本
# 使用方法: ./test-plugin-api.sh

BASE_URL="http://localhost:8874"
USERNAME="admin"
PASSWORD="admin123"

echo "========================================"
echo "  插件系统 API 测试"
echo "========================================"
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试结果统计
PASS=0
FAIL=0

# 测试函数
test_api() {
    local name="$1"
    local method="$2"
    local endpoint="$3"
    local data="$4"
    local expected_status="$5"

    echo -n "测试: $name ... "

    if [ -n "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $TOKEN" \
            -d "$data" \
            "${BASE_URL}${endpoint}")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $TOKEN" \
            "${BASE_URL}${endpoint}")
    fi

    http_code=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" == "$expected_status" ]; then
        echo -e "${GREEN}PASS${NC} (HTTP $http_code)"
        ((PASS++))
        # 只打印成功的响应体（如果是 JSON）
        if echo "$body" | jq -e . >/dev/null 2>&1; then
            echo "  响应: $(echo "$body" | jq -c .)"
        fi
    else
        echo -e "${RED}FAIL${NC} (期望: $expected_status, 实际: $http_code)"
        echo "  响应: $body"
        ((FAIL++))
    fi
}

# 1. 健康检查
echo "----------------------------------------"
echo "1. 健康检查"
echo "----------------------------------------"
health=$(curl -s "${BASE_URL}/health")
if echo "$health" | jq -e . >/dev/null 2>&1; then
    echo -e "服务器状态: ${GREEN}在线${NC}"
    echo "$health" | jq .
else
    echo -e "服务器状态: ${RED}离线${NC}"
    echo "请确保服务器正在运行: npm run dev"
    exit 1
fi
echo ""

# 2. 登录获取 Token
echo "----------------------------------------"
echo "2. 登录获取 Token"
echo "----------------------------------------"
login_response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\",\"device_id\":\"test-script\",\"device_name\":\"Test Script\"}" \
    "${BASE_URL}/api/v1/auth/login")

TOKEN=$(echo "$login_response" | jq -r '.token // empty')

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
    echo -e "${RED}登录失败${NC}"
    echo "$login_response" | jq .
    exit 1
else
    echo -e "${GREEN}登录成功${NC}"
    echo "Token: ${TOKEN:0:20}..."
fi
echo ""

# 3. 测试插件系统 API
echo "----------------------------------------"
echo "3. 插件系统 API 测试"
echo "----------------------------------------"

# 3.1 获取已安装插件列表
test_api "获取已安装插件列表" "GET" "/api/v1/system/plugins" "" "200"

# 3.2 获取商店配置
test_api "获取商店配置" "GET" "/api/v1/system/plugins/config" "" "200"

# 3.3 更新商店配置
test_api "更新商店配置" "PUT" "/api/v1/system/plugins/config" '{"storeURL":"http://localhost:8874/plugins/plugin-store.json"}' "200"

# 3.4 获取商店插件列表
test_api "获取商店插件列表" "GET" "/api/v1/system/plugins/store" "" "200"

# 3.5 测试不存在的插件
test_api "获取不存在的插件" "GET" "/api/v1/system/plugins/non-existent-uuid" "" "404"

# 3.6 测试启用不存在的插件
test_api "启用不存在的插件" "POST" "/api/v1/system/plugins/non-existent-uuid/enable" "" "400"

echo ""

# 4. 上传插件测试
echo "----------------------------------------"
echo "4. 上传插件测试"
echo "----------------------------------------"

# 创建测试插件 ZIP
TEST_PLUGIN_DIR=$(mktemp -d)
cat > "$TEST_PLUGIN_DIR/metadata.json" << 'EOF'
{
  "uuid": "test-plugin",
  "title": "测试插件",
  "author": "Test",
  "description": "用于测试的插件",
  "version": "1.0.0",
  "permissions": {
    "dataAccess": [],
    "operations": ["read"],
    "networkAccess": false
  }
}
EOF

cat > "$TEST_PLUGIN_DIR/main.js" << 'EOF'
module.exports.metadata = require('./metadata.json');
module.exports.onLoad = async function() {
  console.log('Test plugin loaded');
};
module.exports.handlers = {};
EOF

TEST_ZIP="/tmp/test-plugin.zip"
cd "$TEST_PLUGIN_DIR" && zip -r "$TEST_ZIP" . >/dev/null 2>&1
cd - >/dev/null

echo -n "测试: 上传插件 ... "
upload_response=$(curl -s -w "\n%{http_code}" -X POST \
    -H "Authorization: Bearer $TOKEN" \
    -F "plugin=@${TEST_ZIP}" \
    "${BASE_URL}/api/v1/system/plugins/upload")

upload_http_code=$(echo "$upload_response" | tail -n 1)
upload_body=$(echo "$upload_response" | sed '$d')

if [ "$upload_http_code" == "200" ]; then
    echo -e "${GREEN}PASS${NC} (HTTP $upload_http_code)"
    ((PASS++))
    echo "  响应: $(echo "$upload_body" | jq -c .)"
else
    echo -e "${RED}FAIL${NC} (HTTP $upload_http_code)"
    echo "  响应: $upload_body"
    ((FAIL++))
fi

# 清理临时文件
rm -rf "$TEST_PLUGIN_DIR" "$TEST_ZIP"

echo ""

# 5. 插件操作测试（如果上传成功）
echo "----------------------------------------"
echo "5. 插件操作测试"
echo "----------------------------------------"

# 获取刚上传的插件
test_api "获取测试插件详情" "GET" "/api/v1/system/plugins/test-plugin" "" "200" "200" || true

# 启用插件
test_api "启用测试插件" "POST" "/api/v1/system/plugins/test-plugin/enable" "" "200" || true

# 再次获取（检查状态）
test_api "验证插件已启用" "GET" "/api/v1/system/plugins/test-plugin" "" "200" || true

# 禁用插件
test_api "禁用测试插件" "POST" "/api/v1/system/plugins/test-plugin/disable" "" "200" || true

# 卸载插件
test_api "卸载测试插件" "DELETE" "/api/v1/system/plugins/test-plugin" "" "200" || true

# 验证已卸载
test_api "验证插件已卸载" "GET" "/api/v1/system/plugins/test-plugin" "" "404" || true

echo ""

# 6. 测试结果汇总
echo "========================================"
echo "  测试结果汇总"
echo "========================================"
echo -e "${GREEN}通过: $PASS${NC}"
echo -e "${RED}失败: $FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}所有测试通过!${NC}"
    exit 0
else
    echo -e "${RED}部分测试失败${NC}"
    exit 1
fi

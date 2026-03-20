# 插件系统 API 测试脚本 (PowerShell)
# 使用方法: .\test-plugin-api.ps1

$BaseUrl = "http://localhost:8874"
$Username = "admin"
$Password = "admin123"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  插件系统 API 测试" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 测试结果统计
$Script:Pass = 0
$Script:Fail = 0

function Test-Api {
    param(
        [string]$Name,
        [string]$Method,
        [string]$Endpoint,
        [string]$Data,
        [int]$ExpectedStatus
    )

    Write-Host "测试: $Name ... " -NoNewline

    try {
        $headers = @{
            "Content-Type" = "application/json"
            "Authorization" = "Bearer $Script:Token"
        }

        if ($Data) {
            $body = $Data
            $response = Invoke-RestMethod -Uri "$BaseUrl$Endpoint" -Method $Method -Headers $headers -Body $body -StatusCodeVariable statusCode -ErrorAction Stop
        } else {
            $response = Invoke-RestMethod -Uri "$BaseUrl$Endpoint" -Method $Method -Headers $headers -StatusCodeVariable statusCode -ErrorAction Stop
        }

        if ($statusCode -eq $ExpectedStatus) {
            Write-Host "PASS" -ForegroundColor Green -NoNewline
            Write-Host " (HTTP $statusCode)"
            $Script:Pass++
            if ($response) {
                Write-Host "  响应: $($response | ConvertTo-Json -Compress)" -ForegroundColor Gray
            }
        } else {
            Write-Host "FAIL" -ForegroundColor Red -NoNewline
            Write-Host " (期望: $ExpectedStatus, 实际: $statusCode)"
            $Script:Fail++
        }
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq $ExpectedStatus) {
            Write-Host "PASS" -ForegroundColor Green -NoNewline
            Write-Host " (HTTP $statusCode)"
            $Script:Pass++
        } else {
            Write-Host "FAIL" -ForegroundColor Red -NoNewline
            Write-Host " ($($_.Exception.Message))"
            $Script:Fail++
        }
    }
}

# 1. 健康检查
Write-Host "----------------------------------------" -ForegroundColor Yellow
Write-Host "1. 健康检查" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

try {
    $health = Invoke-RestMethod -Uri "$BaseUrl/health" -ErrorAction Stop
    Write-Host "服务器状态: " -NoNewline
    Write-Host "在线" -ForegroundColor Green
    Write-Host ($health | ConvertTo-Json)
} catch {
    Write-Host "服务器状态: " -NoNewline
    Write-Host "离线" -ForegroundColor Red
    Write-Host "请确保服务器正在运行: npm run dev"
    exit 1
}
Write-Host ""

# 2. 登录获取 Token
Write-Host "----------------------------------------" -ForegroundColor Yellow
Write-Host "2. 登录获取 Token" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

$loginBody = @{
    username = $Username
    password = $Password
    device_id = "test-script"
    device_name = "Test Script"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method POST -ContentType "application/json" -Body $loginBody -ErrorAction Stop
    $Script:Token = $loginResponse.token

    if ($Script:Token) {
        Write-Host "登录成功" -ForegroundColor Green
        Write-Host "Token: $($Script:Token.Substring(0, [Math]::Min(20, $Script:Token.Length)))..."
    } else {
        Write-Host "登录失败" -ForegroundColor Red
        Write-Host ($loginResponse | ConvertTo-Json)
        exit 1
    }
} catch {
    Write-Host "登录失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 3. 测试插件系统 API
Write-Host "----------------------------------------" -ForegroundColor Yellow
Write-Host "3. 插件系统 API 测试" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

# 3.1 获取已安装插件列表
Test-Api -Name "获取已安装插件列表" -Method "GET" -Endpoint "/api/v1/system/plugins" -ExpectedStatus 200

# 3.2 获取商店配置
Test-Api -Name "获取商店配置" -Method "GET" -Endpoint "/api/v1/system/plugins/config" -ExpectedStatus 200

# 3.3 更新商店配置
Test-Api -Name "更新商店配置" -Method "PUT" -Endpoint "/api/v1/system/plugins/config" -Data '{"storeURL":"http://localhost:8874/plugins/plugin-store.json"}' -ExpectedStatus 200

# 3.4 获取商店插件列表
Test-Api -Name "获取商店插件列表" -Method "GET" -Endpoint "/api/v1/system/plugins/store" -ExpectedStatus 200

# 3.5 测试不存在的插件
Test-Api -Name "获取不存在的插件" -Method "GET" -Endpoint "/api/v1/system/plugins/non-existent-uuid" -ExpectedStatus 404

# 3.6 测试启用不存在的插件
Test-Api -Name "启用不存在的插件" -Method "POST" -Endpoint "/api/v1/system/plugins/non-existent-uuid/enable" -ExpectedStatus 400

Write-Host ""

# 4. 上传插件测试
Write-Host "----------------------------------------" -ForegroundColor Yellow
Write-Host "4. 上传插件测试" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

# 创建测试插件目录
$TestPluginDir = Join-Path $env:TEMP "test-plugin-$(Get-Random)"
New-Item -ItemType Directory -Path $TestPluginDir -Force | Out-Null

# 创建 metadata.json
$metadata = @{
    uuid = "test-plugin"
    title = "测试插件"
    author = "Test"
    description = "用于测试的插件"
    version = "1.0.0"
    permissions = @{
        dataAccess = @()
        operations = @("read")
        networkAccess = $false
    }
} | ConvertTo-Json -Depth 3

$metadata | Out-File -FilePath (Join-Path $TestPluginDir "metadata.json") -Encoding utf8

# 创建 main.js
$mainJs = @"
module.exports.metadata = require('./metadata.json');
module.exports.onLoad = async function() {
  console.log('Test plugin loaded');
};
module.exports.handlers = {};
"@
$mainJs | Out-File -FilePath (Join-Path $TestPluginDir "main.js") -Encoding utf8

# 创建 ZIP 文件
$TestZip = Join-Path $env:TEMP "test-plugin.zip"
Compress-Archive -Path "$TestPluginDir\*" -DestinationPath $TestZip -Force

Write-Host "测试: 上传插件 ... " -NoNewline

try {
    $headers = @{
        "Authorization" = "Bearer $Script:Token"
    }

    # 使用 multipart/form-data 上传
    $form = @{
        plugin = Get-Item $TestZip
    }

    $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/system/plugins/upload" -Method POST -Headers $headers -Form $form -ErrorAction Stop
    Write-Host "PASS" -ForegroundColor Green
    $Script:Pass++
    Write-Host "  响应: $($response | ConvertTo-Json -Compress)" -ForegroundColor Gray
} catch {
    Write-Host "FAIL" -ForegroundColor Red
    Write-Host "  错误: $($_.Exception.Message)" -ForegroundColor Red
    $Script:Fail++
}

# 清理临时文件
Remove-Item -Path $TestPluginDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $TestZip -Force -ErrorAction SilentlyContinue

Write-Host ""

# 5. 插件操作测试
Write-Host "----------------------------------------" -ForegroundColor Yellow
Write-Host "5. 插件操作测试" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

# 获取刚上传的插件
Test-Api -Name "获取测试插件详情" -Method "GET" -Endpoint "/api/v1/system/plugins/test-plugin" -ExpectedStatus 200

# 启用插件
Test-Api -Name "启用测试插件" -Method "POST" -Endpoint "/api/v1/system/plugins/test-plugin/enable" -ExpectedStatus 200

# 再次获取（检查状态）
Test-Api -Name "验证插件已启用" -Method "GET" -Endpoint "/api/v1/system/plugins/test-plugin" -ExpectedStatus 200

# 禁用插件
Test-Api -Name "禁用测试插件" -Method "POST" -Endpoint "/api/v1/system/plugins/test-plugin/disable" -ExpectedStatus 200

# 卸载插件
Test-Api -Name "卸载测试插件" -Method "DELETE" -Endpoint "/api/v1/system/plugins/test-plugin" -ExpectedStatus 200

# 验证已卸载
Test-Api -Name "验证插件已卸载" -Method "GET" -Endpoint "/api/v1/system/plugins/test-plugin" -ExpectedStatus 404

Write-Host ""

# 6. 测试结果汇总
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  测试结果汇总" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "通过: " -NoNewline
Write-Host $Script:Pass -ForegroundColor Green
Write-Host "失败: " -NoNewline
Write-Host $Script:Fail -ForegroundColor Red
Write-Host ""

if ($Script:Fail -eq 0) {
    Write-Host "所有测试通过!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "部分测试失败" -ForegroundColor Red
    exit 1
}

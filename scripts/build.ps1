# PowerShell Script for Building Memento App
# Windows version of scripts/build.sh

# 解析命令行参数
param(
    [switch]$clear
)

# 确保脚本在错误时停止执行
$ErrorActionPreference = "Stop"

# 颜色定义
$Red = [System.ConsoleColor]::Red
$Green = [System.ConsoleColor]::Green
$Yellow = [System.ConsoleColor]::Yellow

# 检查必要的命令是否存在
function Check-Command {
    param(
        [string]$command
    )
    
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
        Write-Host "Error: $command is not installed" -ForegroundColor $Red
        exit 1
    }
}

# 检查必要的工具
Check-Command "flutter"

# 加载配置文件
$ConfigFile = "scripts\release_config.json"
$Platforms = @()

if (Test-Path $ConfigFile) {
    if (-not (Get-Command "jq" -ErrorAction SilentlyContinue)) {
        Write-Host "Error: jq is not installed. Please install it to parse JSON config." -ForegroundColor $Red
        exit 1
    }
    
    # 读取平台配置
    try {
        $Config = Get-Content $ConfigFile | ConvertFrom-Json
        if ($Config.build.platforms) {
            $Platforms = $Config.build.platforms
            Write-Host "Building for platforms: $($Platforms -join ', ')" -ForegroundColor $Green
        } else {
            Write-Host "No platforms specified in config file. Building for current platform only." -ForegroundColor $Yellow
        }
    } catch {
        Write-Host "Error parsing config file: $_" -ForegroundColor $Red
        Write-Host "Building for current platform only." -ForegroundColor $Yellow
    }
} else {
    Write-Host "Config file not found at $ConfigFile. Building for current platform only." -ForegroundColor $Yellow
}

# 检查平台是否在构建列表中
function Is-PlatformEnabled {
    param(
        [string]$platform
    )
    
    if ($Platforms.Count -eq 0) {
        # 如果没有指定平台，默认构建当前平台
        return $true
    }
    
    return $Platforms -contains $platform
}

# 获取版本号
$Version = (Get-Content "pubspec.yaml" | Select-String "version:").ToString().Split(":")[1].Trim()
Write-Host "Building version: $Version" -ForegroundColor $Green

# 创建输出目录
$OutputDir = "build\releases"
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# 清理之前的构建
if ($clear) {
    Write-Host "Cleaning previous builds..." -ForegroundColor $Yellow
    flutter clean
} else {
    Write-Host "Skipping clean (use -clear to clean previous builds)" -ForegroundColor $Yellow
}

# 获取依赖
Write-Host "Getting dependencies..." -ForegroundColor $Yellow
flutter pub get

# 构建 Android
if (Is-PlatformEnabled "android") {
    Write-Host "Building Android APK..." -ForegroundColor $Yellow
    flutter build apk --release --no-tree-shake-icons
    
    if (Test-Path "build\app\outputs\flutter-apk\app-release.apk") {
        Copy-Item "build\app\outputs\flutter-apk\app-release.apk" -Destination "$OutputDir\memento-$Version-android.apk"
        Write-Host "Successfully built Android APK: $OutputDir\memento-$Version-android.apk" -ForegroundColor $Green
    } else {
        Write-Host "Error: Android APK build failed or file not found" -ForegroundColor $Red
        exit 1
    }
} else {
    Write-Host "Skipping Android build (not in platform list)" -ForegroundColor $Yellow
}

# 构建 Web
if (Is-PlatformEnabled "web") {
    Write-Host "Building Web..." -ForegroundColor $Yellow
    flutter build web --release --no-tree-shake-icons
    
    if (Test-Path "build\web") {
        # 检查是否安装了7-Zip
        if (Get-Command "7z" -ErrorAction SilentlyContinue) {
            Push-Location "build\web"
            7z a -tzip "..\..\$OutputDir\memento-$Version-web.zip" *
            Pop-Location
            Write-Host "Successfully built Web: $OutputDir\memento-$Version-web.zip" -ForegroundColor $Green
        } else {
            # 使用PowerShell内置的压缩功能
            Compress-Archive -Path "build\web\*" -DestinationPath "$OutputDir\memento-$Version-web.zip" -Force
            Write-Host "Successfully built Web: $OutputDir\memento-$Version-web.zip" -ForegroundColor $Green
        }
    } else {
        Write-Host "Error: Web build failed or directory not found" -ForegroundColor $Red
        exit 1
    }
} else {
    Write-Host "Skipping Web build (not in platform list)" -ForegroundColor $Yellow
}

# 构建 Windows
if (Is-PlatformEnabled "windows") {
    Write-Host "Building Windows..." -ForegroundColor $Yellow
    flutter build windows --release --no-tree-shake-icons
    
    if (Test-Path "build\windows\x64\runner\Release") {
        # 检查是否安装了7-Zip
        if (Get-Command "7z" -ErrorAction SilentlyContinue) {
            Push-Location "build\windows\x64\runner\Release"
            7z a -tzip "..\..\..\..\..\$OutputDir\memento-$Version-windows.zip" *
            Pop-Location
            Write-Host "Successfully built Windows package: $OutputDir\memento-$Version-windows.zip" -ForegroundColor $Green
        } else {
            # 使用PowerShell内置的压缩功能
            Compress-Archive -Path "build\windows\x64\runner\Release\*" -DestinationPath "$OutputDir\memento-$Version-windows.zip" -Force
            Write-Host "Successfully built Windows package: $OutputDir\memento-$Version-windows.zip" -ForegroundColor $Green
        }
    } else {
        Write-Host "Error: Windows build failed or directory not found" -ForegroundColor $Red
        exit 1
    }
} else {
    Write-Host "Skipping Windows build (not in platform list)" -ForegroundColor $Yellow
}

Write-Host "Build process completed successfully!" -ForegroundColor $Green
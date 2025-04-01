@echo off
echo Starting build and release process...

:: 检查是否安装了Git Bash
where bash >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Error: Git Bash not found. Please install Git for Windows.
    exit /b 1
)

:: 使用Git Bash运行shell脚本
bash "%~dp0build_and_release.sh"

if %ERRORLEVEL% neq 0 (
    echo Build process failed.
    exit /b 1
)

echo Build and release completed successfully!
pause
#!/bin/bash

# 确保脚本在错误时退出
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890

# 检查必要的命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}Error: $1 is not installed${NC}"
        exit 1
    fi
}

# 检查必要的工具
check_command "gh"
check_command "git"

# 检查构建目录是否存在
OUTPUT_DIR="build/releases"
if [ ! -d "$OUTPUT_DIR" ]; then
    echo -e "${RED}Error: Build directory not found. Please run build.sh first.${NC}"
    exit 1
fi

# 获取版本号
VERSION=$(grep 'version:' pubspec.yaml | awk '{print $2}')
echo -e "${GREEN}Preparing release for version: $VERSION${NC}"

# 检查必要的工具
check_command "jq"

# 读取GitHub配置
CONFIG_FILE="scripts/release_config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Config file not found at $CONFIG_FILE${NC}"
    exit 1
fi

GITHUB_USER=$(jq -r '.github.user' "$CONFIG_FILE")
GITHUB_TOKEN=$(jq -r '.github.token' "$CONFIG_FILE")
GITHUB_REPO=$(jq -r '.github.repo' "$CONFIG_FILE")

if [ -z "$GITHUB_USER" ] || [ -z "$GITHUB_TOKEN" ] || [ -z "$GITHUB_REPO" ]; then
    echo -e "${RED}Error: GitHub configuration is incomplete in $CONFIG_FILE${NC}"
    exit 1
fi

# 确保 GITHUB_REPO 不包含用户名
GITHUB_REPO=$(basename "$GITHUB_REPO")

# 设置GitHub CLI环境变量
export GITHUB_TOKEN

# 配置GitHub CLI
gh config set -h github.com git_protocol https
gh auth setup-git

# 设置GitHub API URL
gh config set host api.github.com

echo -e "${GREEN}GitHub configuration loaded successfully.${NC}"

# 验证GitHub配置
if ! gh auth status; then
    echo -e "${RED}Error: Failed to authenticate with GitHub.${NC}"
    echo -e "${YELLOW}Please check your GitHub token and permissions.${NC}"
    exit 1
fi

# 显示当前配置
echo -e "${YELLOW}Current GitHub configuration:${NC}"
echo "User: $GITHUB_USER"
echo "Repo: $GITHUB_REPO"
echo "API URL: $(gh config get host)"

# 验证仓库访问权限
if ! gh repo view "$GITHUB_USER/$GITHUB_REPO" &> /dev/null; then
    echo -e "${RED}Error: Unable to access repository $GITHUB_USER/$GITHUB_REPO${NC}"
    echo -e "${YELLOW}Please check your repository name and permissions.${NC}"
    exit 1
fi

# 创建 GitHub Release
echo -e "${YELLOW}Creating GitHub Release...${NC}"
RELEASE_NOTES="release_notes.md"

# 创建文件哈希值表格头部
echo "## File Checksums" > "$RELEASE_NOTES"
echo "" >> "$RELEASE_NOTES"
echo "| Filename | MD5 | SHA256 |" >> "$RELEASE_NOTES"
echo "|----------|-----|---------|" >> "$RELEASE_NOTES"

# 计算并写入每个文件的哈希值
for file in $OUTPUT_DIR/*; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        md5=$(md5sum "$file" | cut -d' ' -f1)
        sha256=$(shasum -a 256 "$file" | cut -d' ' -f1)
        echo "| $filename | \`$md5\` | \`$sha256\` |" >> "$RELEASE_NOTES"
    fi
done

echo "" >> "$RELEASE_NOTES"

# 创建 GitHub Release
echo -e "${YELLOW}Creating GitHub Release for $GITHUB_USER/$GITHUB_REPO...${NC}"
if ! gh release create "v$VERSION" --repo "$GITHUB_USER/$GITHUB_REPO" --title "Memento v$VERSION" --notes-file $RELEASE_NOTES; then
    echo -e "${RED}Error: Failed to create GitHub release.${NC}"
    echo -e "${YELLOW}Please check your GitHub CLI authentication and permissions.${NC}"
    echo -e "${YELLOW}Debug info: GITHUB_USER=$GITHUB_USER, GITHUB_REPO=$GITHUB_REPO${NC}"
    echo -e "${YELLOW}Full command: gh release create \"v$VERSION\" --repo \"$GITHUB_USER/$GITHUB_REPO\" --title \"Memento v$VERSION\" --notes-file $RELEASE_NOTES${NC}"
    gh api repos/$GITHUB_USER/$GITHUB_REPO
    exit 1
fi

# 上传构建文件
for file in $OUTPUT_DIR/*; do
    if [ -f "$file" ]; then
        echo -e "${YELLOW}Uploading $file...${NC}"
        if ! gh release upload "v$VERSION" "$file" --repo "$GITHUB_USER/$GITHUB_REPO"; then
            echo -e "${RED}Error: Failed to upload $file.${NC}"
            echo -e "${YELLOW}Please check your GitHub CLI authentication and permissions.${NC}"
            exit 1
        fi
    fi
done

# 清理临时文件
rm $RELEASE_NOTES

echo -e "${GREEN}Release v$VERSION completed successfully!${NC}"

# 提示下一步操作
echo -e "${YELLOW}Next steps:${NC}"
echo "1. 检查 GitHub Releases 页面确认发布状态"
echo "2. 更新 pubspec.yaml 中的版本号为下一个版本"
echo "3. 提交版本更新到代码库"
#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 确保脚本在错误时退出
set -e

# 检查必要的命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}Error: $1 is not installed${NC}"
        echo -e "${YELLOW}Please install $1 first${NC}"
        exit 1
    fi
}

# 检查必要的工具
check_command "flutter"
check_command "vercel"

# 检查是否已登录 Vercel
vercel whoami &> /dev/null || {
    echo -e "${YELLOW}You are not logged in to Vercel. Please login first.${NC}"
    vercel login
}

# 获取版本号
VERSION=$(grep 'version:' pubspec.yaml | awk '{print $2}')
echo -e "${GREEN}Deploying version: $VERSION${NC}"

# 检查是否需要构建
BUILD_DIR="build/web"
if [ ! -d "$BUILD_DIR" ] || [ "$1" == "--build" ]; then
    echo -e "${YELLOW}Building web application...${NC}"
    flutter build web --release --no-tree-shake-icons
else
    echo -e "${YELLOW}Using existing build in $BUILD_DIR${NC}"
    echo -e "${YELLOW}(Use --build flag to force rebuild)${NC}"
fi

# 检查构建目录是否存在
if [ ! -d "$BUILD_DIR" ]; then
    echo -e "${RED}Error: Build directory $BUILD_DIR does not exist${NC}"
    exit 1
fi

# 部署到 Vercel
echo -e "${YELLOW}Deploying to Vercel...${NC}"
(cd $BUILD_DIR && vercel deploy --prod)

echo -e "${GREEN}Deployment completed!${NC}"

# 获取部署的 URL
DEPLOY_URL=$(cd $BUILD_DIR && vercel --prod)
echo -e "${GREEN}Your application is deployed at: $DEPLOY_URL${NC}"

# 提示下一步操作
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Visit your Vercel dashboard to check deployment status"
echo "2. Configure custom domain if needed"
echo "3. Share the URL with your team or users"
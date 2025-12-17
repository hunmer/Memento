# Memento 文档站点

这是 Memento 个人助手应用的文档站点，使用 [VitePress](https://vitepress.dev/) 构建。

## 快速开始

```bash
# 进入文档目录
cd docs

# 安装依赖（仅首次需要）
npm install

# 启动开发服务器
npm run docs:dev

# 或者使用便捷脚本
./start.sh
```

## 开发命令

```bash
# 启动开发服务器（热重载）
npm run docs:dev

# 构建静态文件
npm run docs:build

# 预览构建结果
npm run docs:preview
```

开发服务器启动后，访问 `http://localhost:5173` 查看文档。

## 目录结构

```
docs/
├── .vitepress/          # VitePress 配置
│   ├── config.js        # 站点配置
│   └── public/          # 静态资源（图标等）
├── guide/               # 使用指南
│   └── installation.md  # 快速安装说明
├── index.md            # 首页
├── start.sh            # 便捷启动脚本
└── package.json        # 依赖配置
```

## 文档编写

### 添加新页面

1. 在 `docs/guide/` 目录创建新的 `.md` 文件
2. 在 `.vitepress/config.js` 中的 `themeConfig.sidebar` 添加导航项
3. 文件首行使用 Front Matter 设置页面属性：

```markdown
---
title: 页面标题
description: 页面描述
---
```

### 页面内容

- 使用标准 Markdown 语法
- 支持 Vue 组件（如果需要）
- 支持自定义容器、代码高亮等

## 部署

### 构建静态文件

```bash
npm run docs:build
```

构建后的文件位于 `.vitepress/dist/` 目录，可以部署到任何静态文件托管服务：

- **GitHub Pages**: 将 dist 目录内容推送到 gh-pages 分支
- **Vercel**: 连接 GitHub 仓库自动部署
- **Netlify**: 拖拽 dist 文件夹或连接 Git 仓库
- **阿里云 OSS**: 上传 dist 目录内容
- **腾讯云 COS**: 上传 dist 目录内容

### 部署到 GitHub Pages 示例

1. 在项目根目录创建 `.github/workflows/deploy-docs.yml`：

```yaml
name: Deploy Docs

on:
  push:
    branches: [ master ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Setup Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '18'

      - name: Install dependencies
        run: cd docs && npm install

      - name: Build docs
        run: cd docs && npm run docs:build

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: docs/.vitepress/dist
```

2. 提交并推送到 master 分支
3. 在仓库设置中启用 GitHub Pages

## 更新文档

1. 编辑对应的 Markdown 文件
2. 本地测试效果：`npm run docs:dev`
3. 构建生产版本：`npm run docs:build`
4. 提交代码并部署

## 注意事项

- 确保所有图片文件放在 `.vitepress/public/` 目录
- 使用相对路径引用静态资源
- 保持文档内容简洁明了，面向最终用户

// 全局代理配置 - 必须在所有模块导入之前
// @ts-ignore
import { bootstrap } from 'global-agent';
const proxyUrl = process.env.HTTP_PROXY || process.env.HTTPS_PROXY || 'http://127.0.0.1:7890';
process.env.GLOBAL_AGENT_HTTP_PROXY = proxyUrl;
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
process.env.GLOBAL_AGENT_FORCE_GLOBAL_AGENT = 'true';
bootstrap();

import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import path from 'path';
import fs from 'fs';
import http from 'http';
import WebSocket from 'ws';
import multer from 'multer';
import { config, printConfig } from './config/serverConfig';
import { FileStorageService } from './services/fileStorageService';
import { AuthService } from './services/authService';
import { PluginDataService } from './services/pluginDataService';
import { PluginService } from './services/pluginService';
import { WebSocketManager } from './services/webSocketManager';
import { FileWatcherService } from './services/fileWatcherService';
import { authMiddleware, apiEnabledMiddleware } from './middleware';
import { createAuthRoutes } from './routes/authRoutes';
import { createSyncRoutes } from './routes/syncRoutes';
import { createPluginRoutesIndex } from './routes/pluginRoutes';
import { createPluginSystemRoutes } from './routes/pluginSystemRoutes';

// 文件上传配置
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB
  },
});

/**
 * MIME 类型映射
 */
const MIME_TYPES: Record<string, string> = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.ttf': 'font/ttf',
  '.eot': 'application/vnd.ms-fontobject',
};

/**
 * 获取 MIME 类型
 */
function getMimeType(fileName: string): string {
  const ext = path.extname(fileName).toLowerCase();
  return MIME_TYPES[ext] || 'application/octet-stream';
}

async function main() {
  console.log('====================================');
  console.log('  Memento Sync Server (Node.js)');
  console.log('====================================');
  console.log('');

  // 1. 打印配置
  printConfig();
  console.log('');

  // 2. 初始化服务
  const storageService = new FileStorageService(config.dataDir);
  await storageService.initialize();
  console.log(`文件存储服务初始化完成: ${config.dataDir}`);

  const authService = new AuthService({
    storageService,
    jwtSecret: config.jwtSecret,
    dataDir: config.dataDir,
    tokenExpiryDays: config.tokenExpiryDays,
    adminUsername: config.adminUsername,
    adminPassword: config.adminPassword,
  });
  console.log('认证服务初始化完成');

  // 初始化管理员账号
  await authService.initializeAdmin();

  const pluginDataService = new PluginDataService(storageService, config.dataDir);
  await pluginDataService.initialize();
  console.log('插件数据服务初始化完成');

  // 插件系统服务
  const pluginService = new PluginService(config.dataDir);
  await pluginService.initialize();
  console.log('插件系统服务初始化完成');

  const webSocketManager = WebSocketManager.getInstance();
  console.log('WebSocket 管理器初始化完成');

  const fileWatcherService = new FileWatcherService(
    storageService,
    webSocketManager,
    config.dataDir,
    { pollIntervalMs: 2000 },
  );
  await fileWatcherService.start();
  console.log('文件监听服务初始化完成');

  // 3. 创建 Express 应用
  const app = express();

  // 解析 JSON 请求体
  app.use(express.json({ limit: config.maxRequestSize }));

  // CORS 支持
  if (config.enableCors) {
    // 当 corsOrigins 为 ['*'] 时，使用 true 允许所有来源
    const corsOrigin = config.corsOrigins.length === 1 && config.corsOrigins[0] === '*'
      ? true
      : config.corsOrigins;
    app.use(cors({
      origin: corsOrigin,
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Origin', 'Content-Type', 'Authorization', 'X-API-Key', 'X-Encryption-Key', 'X-Device-ID'],
      credentials: true,
    }));
  }

  // 请求日志
  if (config.enableLogging) {
    app.use((req, res, next) => {
      console.log(`${new Date().toISOString()} ${req.method} ${req.path}`);
      next();
    });
  }

  // 4. 创建路由

  // 健康检查 (无需认证)
  app.get('/health', (req, res) => {
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
    });
  });

  // 版本信息 (无需认证)
  app.get('/version', (req, res) => {
    res.json({
      version: '1.0.0',
      name: 'Memento Sync Server (Node.js)',
    });
  });

  // 认证路由 (无需认证)
  const authRoutes = createAuthRoutes(authService, pluginDataService, storageService, config.allowRegister);
  app.use('/api/v1/auth', authRoutes);

  // 同步路由 (需要认证)
  const syncRoutes = createSyncRoutes(storageService, pluginDataService);
  app.use('/api/v1/sync', authMiddleware(authService), syncRoutes);

  // 插件路由 (需要认证 + API 启用)
  const pluginRoutes = createPluginRoutesIndex(pluginDataService);
  for (const [pluginId, router] of pluginRoutes) {
    app.use(
      `/api/v1/plugins/${pluginId}`,
      authMiddleware(authService),
      apiEnabledMiddleware(),
      router,
    );
  }
  console.log(`已挂载 ${pluginRoutes.size} 个插件路由: ${Array.from(pluginRoutes.keys()).join(', ')}`);

  // 插件系统管理路由 (需要管理员权限)
  const pluginSystemRoutes = createPluginSystemRoutes(pluginService, authService);
  app.use('/api/v1/system', upload.single('plugin'), pluginSystemRoutes);
  console.log('插件系统管理路由已挂载: /api/v1/system/plugins');

  // 5. 创建 HTTP 服务器
  const server = http.createServer(app);

  // WebSocket 服务器
  const wss = new WebSocket.Server({ noServer: true });

  // WebSocket 升级处理
  server.on('upgrade', (request, socket, head) => {
    const parsedUrl = new URL(request.url || '', `http://${request.headers.host}`);
    const pathname = parsedUrl.pathname;

    if (pathname === '/api/v1/sync/ws') {
      wss.handleUpgrade(request, socket, head, (ws) => {
        handleWebSocketConnection(ws, request);
      });
    } else {
      socket.destroy();
    }
  });

  // WebSocket 连接处理
  function handleWebSocketConnection(ws: WebSocket, request: http.IncomingMessage) {
    console.log('收到 WebSocket 连接请求');

    // 设置认证超时
    let authenticated = false;
    const authTimeout = setTimeout(() => {
      if (!authenticated) {
        ws.send(JSON.stringify({ type: 'auth_error', error: '认证超时' }));
        ws.close();
      }
    }, 5000);

    ws.on('message', (data: Buffer) => {
      if (authenticated) return;

      try {
        const message = JSON.parse(data.toString());
        if (message.type === 'auth') {
          const token = message.token;
          const deviceId = message.device_id;

          if (!token || !deviceId) {
            ws.send(JSON.stringify({ type: 'auth_error', error: '缺少认证参数' }));
            ws.close();
            return;
          }

          // 验证 Token
          const wsUserId = authService.getUserIdFromToken(token);
          if (!wsUserId) {
            ws.send(JSON.stringify({ type: 'auth_error', error: '无效的 Token' }));
            ws.close();
            return;
          }

          clearTimeout(authTimeout);
          authenticated = true;

          // 发送认证成功消息
          ws.send(JSON.stringify({ type: 'auth_success', user_id: wsUserId }));

          // 注册到 WebSocket 管理器
          webSocketManager.registerChannel(wsUserId, deviceId, ws);
          console.log(`WebSocket 认证成功: userId=${wsUserId}, deviceId=${deviceId}`);
        }
      } catch (e) {
        ws.send(JSON.stringify({ type: 'auth_error', error: '认证失败' }));
        ws.close();
      }
    });
  }

  // 管理界面静态文件服务
  const adminDir = path.join(__dirname, '..', 'admin');
  console.log(`管理界面目录: ${adminDir}`);

  // 检查管理界面目录
  if (fs.existsSync(adminDir)) {
    // 根路径重定向到管理界面
    app.get('/', (req, res) => {
      res.redirect('/admin/');
    });

    // 管理界面主页
    app.get('/admin/', (req, res) => {
      const indexFile = path.join(adminDir, 'index.html');
      if (fs.existsSync(indexFile)) {
        res.sendFile(indexFile);
      } else {
        res.status(404).send('Admin page not found');
      }
    });

    // 管理界面静态资源
    app.get('/admin/*', (req, res) => {
      const filePath = (req.params as Record<string, string>)[0] || '';

      // 安全检查：防止路径遍历攻击
      if (filePath.includes('..')) {
        res.status(403).send('Invalid path');
        return;
      }

      const fullPath = path.join(adminDir, filePath);

      if (fs.existsSync(fullPath) && fs.statSync(fullPath).isFile()) {
        res.setHeader('Content-Type', getMimeType(filePath));
        res.sendFile(fullPath);
      } else {
        // SPA 路由支持：返回 index.html
        const indexFile = path.join(adminDir, 'index.html');
        if (fs.existsSync(indexFile)) {
          res.sendFile(indexFile);
        } else {
          res.status(404).send('File not found');
        }
      }
    });
  } else {
    console.log(`警告: 管理界面目录不存在: ${adminDir}`);
    // 简单的根路由
    app.get('/', (req, res) => {
      res.json({
        name: 'Memento Sync Server',
        version: '1.0.0',
        status: 'running',
      });
    });
  }

  // 6. 启动服务器
  server.listen(config.port, () => {
    console.log('');
    console.log('服务器启动成功!');
    console.log(`  http://0.0.0.0:${config.port}`);
    console.log('');
    console.log('可用端点:');
    console.log('  GET  /                    - 服务信息');
    console.log('  GET  /health              - 健康检查');
    console.log('  GET  /version             - 版本信息');
    console.log('  POST /api/v1/auth/register - 用户注册');
    console.log('  POST /api/v1/auth/login    - 用户登录');
    console.log('  POST /api/v1/auth/verify-encryption-key - 验证加密密钥');
    console.log('  POST /api/v1/sync/push     - 推送文件 (需认证)');
    console.log('  GET  /api/v1/sync/pull/*   - 拉取文件 (需认证)');
    console.log('  GET  /api/v1/sync/list     - 文件列表 (需认证)');
    console.log('  WS   /api/v1/sync/ws       - WebSocket 实时同步');
    console.log('');
    console.log('插件 API (需认证 + X-Encryption-Key 请求头):');
    for (const pluginId of pluginRoutes.keys()) {
      console.log(`  /api/v1/plugins/${pluginId}`);
    }
    console.log('');
  });

  // 优雅关闭
  process.on('SIGINT', async () => {
    console.log('收到关闭信号，正在停止服务器...');
    await fileWatcherService.stop();
    await webSocketManager.closeAll();
    server.close(() => {
      console.log('服务器已停止');
      process.exit(0);
    });
  });
}

main().catch((error) => {
  console.error('服务器启动失败:', error);
  process.exit(1);
});

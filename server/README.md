# Memento Sync Server

基于 Shelf 框架的端到端加密文件同步服务器。

## 特性

- **端到端加密**: 服务器只存储密文，无法解密用户数据
- **乐观并发控制**: 使用 MD5 验证检测冲突
- **纯文件存储**: 零配置，无需数据库
- **双重认证**: 支持 API Key 和 JWT Token 认证
- **API Key 管理**: 内置 API Key 创建、管理界面
- **文件级同步**: 以 JSON 文件为单位进行同步

## 快速开始

### 1. 安装依赖

```bash
cd server
dart pub get
```

### 2. 配置环境变量

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑 .env 文件，设置 JWT_SECRET
```

### 3. 启动服务器

```bash
# 开发模式
dart run bin/server.dart

# 或者编译后运行
dart compile exe bin/server.dart -o memento_server
./memento_server
```

### 4. 访问管理面板

打开浏览器访问 http://localhost:8080/admin/

默认登录凭据: `admin` / `admin123`

## 认证方式

### API Key 认证（推荐用于第三方应用）

在管理面板的 "API Keys" 选项卡中创建 API Key，然后使用 `X-API-Key` 请求头：

```bash
curl http://localhost:8080/api/v1/plugins/todo/tasks \
  -H "X-API-Key: mk_live_your_api_key"
```

### JWT Token 认证（用于管理面板）

管理面板登录后自动获得 JWT Token，使用 `Authorization: Bearer` 请求头：

```bash
curl http://localhost:8080/api/v1/sync/list \
  -H "Authorization: Bearer your_jwt_token"
```

## API 端点

### 公开端点

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/health` | 健康检查 |
| GET | `/version` | 版本信息 |
| GET | `/admin/` | 管理面板 |

### 认证 API

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/v1/auth/register` | 用户注册 |
| POST | `/api/v1/auth/login` | 用户登录 |
| POST | `/api/v1/auth/refresh` | 刷新 Token |
| POST | `/api/v1/auth/api-keys` | 创建 API Key |
| GET | `/api/v1/auth/api-keys` | 列出 API Keys |
| DELETE | `/api/v1/auth/api-keys/<id>` | 撤销 API Key |

### 同步 API（需认证）

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/v1/sync/push` | 推送加密文件 |
| GET | `/api/v1/sync/pull/{path}` | 拉取加密文件 |
| GET | `/api/v1/sync/list` | 列出所有文件 |
| DELETE | `/api/v1/sync/delete/{path}` | 删除文件 |
| GET | `/api/v1/sync/status` | 同步状态 |
| POST | `/api/v1/sync/export` | 导出 ZIP |
| GET | `/api/v1/sync/download/{file}` | 下载导出文件 |

### 插件 API（需认证）

支持 19 个插件的 RESTful API：

- `/api/v1/plugins/chat/*` - 聊天
- `/api/v1/plugins/notes/*` - 笔记
- `/api/v1/plugins/todo/*` - 任务
- `/api/v1/plugins/diary/*` - 日记
- `/api/v1/plugins/activity/*` - 活动记录
- `/api/v1/plugins/bill/*` - 账单
- `/api/v1/plugins/goods/*` - 物品
- `/api/v1/plugins/calendar/*` - 日历
- 等等...

## API Key 管理

### 创建 API Key

1. 登录管理面板 (http://localhost:8080/admin/)
2. 进入 "API Keys" 选项卡
3. 点击 "创建 API Key"
4. 输入名称、选择加密密钥、设置过期时间
5. **重要**：保存显示的 API Key 和加密密钥（仅显示一次）

### API Key 格式

- 前缀: `mk_live_` 或 `mk_test_`
- 总长度: 40 字符
- 示例: `mk_live_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`

### 过期选项

| 选项 | 说明 |
|------|------|
| 7天 | 适用于临时测试 |
| 30天 | 适用于短期项目 |
| 90天 | 适用于中期使用 |
| 1年 | 适用于长期项目 |
| 永不过期 | 适用于生产环境 |

## 请求示例

### 使用 API Key 获取任务列表

```bash
curl http://localhost:8080/api/v1/plugins/todo/tasks \
  -H "X-API-Key: mk_live_your_api_key"
```

### 使用 JWT Token 推送文件

```bash
curl -X POST http://localhost:8080/api/v1/sync/push \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "file_path": "diary/2024-01-01.json",
    "encrypted_data": "base64_iv.base64_ciphertext",
    "old_md5": null,
    "new_md5": "abc123..."
  }'
```

## 冲突处理

当客户端提交的 `old_md5` 与服务器当前文件的 MD5 不匹配时，服务器返回 409 状态码和冲突信息：

```json
{
  "status": "conflict",
  "file_path": "diary/2024-01-01.json",
  "message": "MD5 mismatch - server data has changed",
  "server_data": "base64_iv.base64_ciphertext",
  "server_md5": "xyz789...",
  "server_updated_at": "2024-01-01T12:00:00.000Z"
}
```

## 数据目录结构

```
data/
├── users/
│   └── {user_id}/
│       ├── diary/
│       ├── chat/
│       └── ...
├── auth/
│   ├── users.json
│   └── api_keys.json
└── logs/
    └── sync_2024-01-01.log
```

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `PORT` | 8080 | 服务器端口 |
| `DATA_DIR` | ./data | 数据存储目录 |
| `JWT_SECRET` | 随机生成 | JWT 签名密钥 |
| `TOKEN_EXPIRY_DAYS` | 36500 | Token 有效期 |
| `ENABLE_CORS` | true | 是否启用 CORS |
| `CORS_ORIGINS` | * | 允许的 CORS 源 |

## Docker 部署

```dockerfile
FROM dart:stable AS build
WORKDIR /app
COPY . .
RUN dart pub get
RUN dart compile exe bin/server.dart -o server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/server /app/server
EXPOSE 8080
CMD ["/app/server"]
```

```bash
docker build -t memento-server .
docker run -p 8080:8080 -v ./data:/data -e JWT_SECRET=your_secret memento-server
```

## 安全说明

1. **生产环境必须设置强随机 JWT_SECRET**
2. **建议使用 HTTPS (通过反向代理如 Nginx)**
3. **定期备份 data/ 目录**
4. **API Key 仅显示一次，请妥善保存**
5. **加密密钥在客户端派生，服务器无法获取**

## 许可证

MIT License

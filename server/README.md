# Memento Sync Server

基于 Shelf 框架的端到端加密文件同步服务器。

## 特性

- **端到端加密**: 服务器只存储密文，无法解密用户数据
- **乐观并发控制**: 使用 MD5 验证检测冲突
- **纯文件存储**: 零配置，无需数据库
- **JWT 认证**: 安全的用户认证机制
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

### 4. 验证服务器

```bash
# 健康检查
curl http://localhost:8080/health

# 预期响应
# {"status": "healthy", "timestamp": "2024-01-01T00:00:00.000Z"}
```

## API 端点

### 认证 (无需 Token)

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/v1/auth/register` | 用户注册 |
| POST | `/api/v1/auth/login` | 用户登录 |
| POST | `/api/v1/auth/refresh` | 刷新 Token |

### 同步 (需要 Token)

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/v1/sync/push` | 推送加密文件 |
| GET | `/api/v1/sync/pull/{path}` | 拉取加密文件 |
| GET | `/api/v1/sync/list` | 列出所有文件 |
| DELETE | `/api/v1/sync/delete/{path}` | 删除文件 |
| GET | `/api/v1/sync/status` | 同步状态 |

## 请求示例

### 注册

```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "user@example.com",
    "password": "your_password",
    "device_id": "device_123",
    "device_name": "My Phone"
  }'
```

### 登录

```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "admin123",
    "device_id": "device_123"
  }'
```

### 推送文件

```bash
curl -X POST http://localhost:8080/api/v1/sync/push \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "file_path": "diary/2024-01-01.json",
    "encrypted_data": "base64_iv.base64_ciphertext",
    "old_md5": null,
    "new_md5": "abc123..."
  }'
```

### 拉取文件

```bash
curl http://localhost:8080/api/v1/sync/pull/diary/2024-01-01.json \
  -H "Authorization: Bearer YOUR_TOKEN"
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

客户端收到冲突响应后，根据配置的策略处理：
- **服务器优先**: 自动使用服务器数据覆盖本地

## 数据目录结构

```
data/
├── users/
│   └── {user_id}/
│       ├── diary/
│       │   └── 2024-01-01.json
│       ├── chat/
│       │   └── channels.json
│       └── ...
├── auth/
│   └── users.json
└── logs/
    └── sync_2024-01-01.log
```

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `PORT` | 8080 | 服务器端口 |
| `DATA_DIR` | ./data | 数据存储目录 |
| `JWT_SECRET` | 随机生成 | JWT 签名密钥 |
| `TOKEN_EXPIRY_DAYS` | 7 | Token 有效期 |
| `ENABLE_CORS` | true | 是否启用 CORS |
| `CORS_ORIGINS` | * | 允许的 CORS 源 |
| `MAX_REQUEST_SIZE` | 10485760 | 最大请求体 (10MB) |
| `ENABLE_LOGGING` | true | 是否启用日志 |

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
4. **用户密码使用 SHA256 + Salt 哈希存储**
5. **加密密钥在客户端派生，服务器无法获取**

## 开发

```bash
# 运行测试
dart test

# 代码检查
dart analyze

# 格式化代码
dart format .
```

## 许可证

MIT License

import request from 'supertest';
import fs from 'fs';
import path from 'path';

/**
 * Memento 同步服务器集成测试
 *
 * 测试所有 API 端点的功能
 */

// 测试配置
const BASE_URL = process.env.TEST_BASE_URL || 'http://localhost:8874';
const TEST_DATA_DIR = path.join(__dirname, 'test_data');

// 测试用户
const TEST_USER = {
  username: `test_user_${Date.now()}`,
  password: 'test_password_123',
  deviceId: 'test_device_001',
  deviceName: 'Test Device',
};

// 测试加密密钥 (Base64 编码的 32 字节密钥)
const TEST_ENCRYPTION_KEY = Buffer.from(
  '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
).toString('base64');

// 全局变量
let authToken: string;
let userId: string;
let userSalt: string;

describe('Memento Sync Server', () => {
  // ==================== 健康检查测试 ====================

  describe('Health & Version', () => {
    it('GET /health should return healthy status', async () => {
      const response = await request(BASE_URL)
        .get('/health')
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body.status).toBe('healthy');
      expect(response.body.timestamp).toBeDefined();
    });

    it('GET /version should return version info', async () => {
      const response = await request(BASE_URL)
        .get('/version')
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body.version).toBeDefined();
      expect(response.body.name).toContain('Memento');
    });
  });

  // ==================== 认证 API 测试 ====================

  describe('Auth API', () => {
    it('POST /api/v1/auth/register should create new user', async () => {
      const response = await request(BASE_URL)
        .post('/api/v1/auth/register')
        .send({
          username: TEST_USER.username,
          password: TEST_USER.password,
          device_id: TEST_USER.deviceId,
          device_name: TEST_USER.deviceName,
        })
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.user_id).toBeDefined();
      expect(response.body.token).toBeDefined();
      expect(response.body.user_salt).toBeDefined();

      authToken = response.body.token;
      userId = response.body.user_id;
      userSalt = response.body.user_salt;
    });

    it('POST /api/v1/auth/register should reject duplicate username', async () => {
      const response = await request(BASE_URL)
        .post('/api/v1/auth/register')
        .send({
          username: TEST_USER.username,
          password: TEST_USER.password,
          device_id: TEST_USER.deviceId,
          device_name: TEST_USER.deviceName,
        })
        .expect('Content-Type', /json/)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('已存在');
    });

    it('POST /api/v1/auth/login should authenticate user', async () => {
      const response = await request(BASE_URL)
        .post('/api/v1/auth/login')
        .send({
          username: TEST_USER.username,
          password: TEST_USER.password,
          device_id: TEST_USER.deviceId,
          device_name: TEST_USER.deviceName,
        })
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.token).toBeDefined();
    });

    it('POST /api/v1/auth/login should reject wrong password', async () => {
      const response = await request(BASE_URL)
        .post('/api/v1/auth/login')
        .send({
          username: TEST_USER.username,
          password: 'wrong_password',
          device_id: TEST_USER.deviceId,
          device_name: TEST_USER.deviceName,
        })
        .expect('Content-Type', /json/)
        .expect(401);

      expect(response.body.success).toBe(false);
    });

    it('POST /api/v1/auth/set-encryption-key should set encryption key', async () => {
      const response = await request(BASE_URL)
        .post('/api/v1/auth/set-encryption-key')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          encryption_key: TEST_ENCRYPTION_KEY,
        })
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.is_first_time).toBe(true);
    });

    it('GET /api/v1/auth/has-encryption-key should return true', async () => {
      const response = await request(BASE_URL)
        .get('/api/v1/auth/has-encryption-key')
        .set('Authorization', `Bearer ${authToken}`)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.has_key).toBe(true);
    });

    it('GET /api/v1/auth/user-info should return user info', async () => {
      const response = await request(BASE_URL)
        .get('/api/v1/auth/user-info')
        .set('Authorization', `Bearer ${authToken}`)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.user_info.username).toBe(TEST_USER.username);
    });

    it('POST /api/v1/auth/api-keys should create API key', async () => {
      const response = await request(BASE_URL)
        .post('/api/v1/auth/api-keys')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Test API Key',
          expiry: 'never',
        })
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.api_key.key).toBeDefined();
      expect(response.body.api_key.name).toBe('Test API Key');
    });

    it('GET /api/v1/auth/api-keys should list API keys', async () => {
      const response = await request(BASE_URL)
        .get('/api/v1/auth/api-keys')
        .set('Authorization', `Bearer ${authToken}`)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.api_keys.length).toBeGreaterThan(0);
    });
  });

  // ==================== 同步 API 测试 ====================

  describe('Sync API', () => {
    const testFilePath = 'test_folder/test_file.json';
    const testEncryptedData = 'dGVzdF9pdl90ZXN0X2NpcGhlcnRleHQ=.dGVzdF9jaXBoZXJ0ZXh0';
    const testMd5 = 'd41d8cd98f00b204e9800998ecf8427e';

    it('POST /api/v1/sync/push should push file', async () => {
      const response = await request(BASE_URL)
        .post('/api/v1/sync/push')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          file_path: testFilePath,
          encrypted_data: testEncryptedData,
          new_md5: testMd5,
        })
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.file_path).toBe(testFilePath);
    });

    it('GET /api/v1/sync/pull/* should pull file', async () => {
      const response = await request(BASE_URL)
        .get(`/api/v1/sync/pull/${encodeURIComponent(testFilePath)}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body.encrypted_data).toBeDefined();
      expect(response.body.md5).toBe(testMd5);
    });

    it('GET /api/v1/sync/list should list files', async () => {
      const response = await request(BASE_URL)
        .get('/api/v1/sync/list')
        .set('Authorization', `Bearer ${authToken}`)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.files).toBeDefined();
      expect(response.body.files.length).toBeGreaterThan(0);
    });

    it('GET /api/v1/sync/status should return status', async () => {
      const response = await request(BASE_URL)
        .get('/api/v1/sync/status')
        .set('Authorization', `Bearer ${authToken}`)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.user_id).toBe(userId);
      expect(response.body.file_count).toBeDefined();
    });

    it('GET /api/v1/sync/index should return file index', async () => {
      const response = await request(BASE_URL)
        .get('/api/v1/sync/index')
        .set('Authorization', `Bearer ${authToken}`)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.index).toBeDefined();
      expect(response.body.index.files).toBeDefined();
    });

    it('GET /api/v1/sync/tree should return directory tree', async () => {
      const response = await request(BASE_URL)
        .get('/api/v1/sync/tree')
        .set('Authorization', `Bearer ${authToken}`)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.tree).toBeDefined();
    });

    it('GET /api/v1/sync/info/* should return file info', async () => {
      const response = await request(BASE_URL)
        .get(`/api/v1/sync/info/${encodeURIComponent(testFilePath)}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.exists).toBe(true);
      expect(response.body.md5).toBeDefined();
    });

    it('DELETE /api/v1/sync/delete/* should delete file', async () => {
      const response = await request(BASE_URL)
        .delete(`/api/v1/sync/delete/${encodeURIComponent(testFilePath)}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body.success).toBe(true);
    });
  });

  // ==================== 插件 API 测试 ====================

  describe('Plugin API', () => {
    it('POST /api/v1/plugins/notes/item should create note', async () => {
      const response = await request(BASE_URL)
        .post('/api/v1/plugins/notes/item')
        .set('Authorization', `Bearer ${authToken}`)
        .set('X-Encryption-Key', TEST_ENCRYPTION_KEY)
        .send({
          title: 'Test Note',
          content: 'This is a test note',
        })
        .expect('Content-Type', /json/)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.title).toBe('Test Note');
    });

    it('GET /api/v1/plugins/notes/items should list notes', async () => {
      const response = await request(BASE_URL)
        .get('/api/v1/plugins/notes/items')
        .set('Authorization', `Bearer ${authToken}`)
        .set('X-Encryption-Key', TEST_ENCRYPTION_KEY)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.data).toBeDefined();
    });

    it('should reject request without encryption key', async () => {
      // 先清除加密密钥
      await request(BASE_URL)
        .post('/api/v1/auth/clear-encryption-key')
        .set('Authorization', `Bearer ${authToken}`);

      const response = await request(BASE_URL)
        .get('/api/v1/plugins/notes/items')
        .set('Authorization', `Bearer ${authToken}`)
        .expect('Content-Type', /json/)
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('加密密钥');
    });
  });

  // ==================== 认证中间件测试 ====================

  describe('Auth Middleware', () => {
    it('should reject request without auth token', async () => {
      const response = await request(BASE_URL)
        .get('/api/v1/sync/list')
        .expect('Content-Type', /json/)
        .expect(401);

      expect(response.body.success).toBe(false);
    });

    it('should reject request with invalid token', async () => {
      const response = await request(BASE_URL)
        .get('/api/v1/sync/list')
        .set('Authorization', 'Bearer invalid_token')
        .expect('Content-Type', /json/)
        .expect(401);

      expect(response.body.success).toBe(false);
    });
  });
});

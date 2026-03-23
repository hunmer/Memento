import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';
import { FileStorageService } from './fileStorageService';
import { RegisterRequest, LoginRequest, RefreshTokenRequest, AuthResponse, UserInfo, ApiKey, ApiKeyValidationResult, ApiKeyExpiry, DeviceInfo } from '../types';

/**
 * 密码哈希工具
 */
export class PasswordHashUtils {
  /**
   * 生成 Salt
   */
  static generateSalt(): string {
    return crypto.randomBytes(16).toString('base64');
  }

  /**
   * 哈希密码
   */
  static hashPassword(password: string, salt: string): string {
    const iterations = 10000;
    const keyLength = 64;
    const saltBuffer = Buffer.from(salt, 'base64');
    const hash = crypto.pbkdf2Sync(password, saltBuffer, iterations, keyLength, 'sha256');
    return hash.toString('base64');
  }

  /**
   * 验证密码
   */
  static verifyPassword(password: string, salt: string, hash: string): boolean {
    const newHash = this.hashPassword(password, salt);
    return newHash === hash;
  }
}

/**
 * 认证服务 - JWT Token 管理和用户认证
 */
export class AuthService {
  private storageService: FileStorageService;
  private jwtSecret: string;
  private tokenExpiryDays: number;
  private apiKeyStore: string;
  private apiAccessStore: string;

  private adminUsername?: string;
  private adminPassword?: string;

  constructor(params: {
    storageService: FileStorageService;
    jwtSecret: string;
    dataDir: string;
    tokenExpiryDays?: number;
    adminUsername?: string;
    adminPassword?: string;
  }) {
    this.storageService = params.storageService;
    this.jwtSecret = params.jwtSecret;
    this.tokenExpiryDays = params.tokenExpiryDays || 36500; // 100年
    this.apiKeyStore = path.join(params.dataDir, 'auth', 'api_keys');
    this.apiAccessStore = path.join(params.dataDir, 'auth', 'api_access.json');
    this.adminUsername = params.adminUsername;
    this.adminPassword = params.adminPassword;
    this.ensureApiKeyStore();
  }

  /**
   * 初始化管理员账号
   */
  async initializeAdmin(): Promise<void> {
    if (!this.adminUsername || !this.adminPassword) {
      return;
    }

    // 检查管理员是否已存在
    const existingAdmin = await this.storageService.findUserByUsername(this.adminUsername);
    if (existingAdmin) {
      console.log(`管理员账号已存在: ${this.adminUsername}`);
      return;
    }

    // 创建管理员账号
    const userSalt = PasswordHashUtils.generateSalt();
    const passwordHash = PasswordHashUtils.hashPassword(this.adminPassword, userSalt);

    const userId = uuidv4();
    const now = new Date();

    const admin: UserInfo = {
      id: userId,
      username: this.adminUsername,
      passwordHash,
      salt: userSalt,
      createdAt: now,
      isAdmin: true,
      devices: [],
    };

    await this.storageService.addUser(admin);
    console.log(`管理员账号已创建: ${this.adminUsername}`);
  }

  /**
   * 确保 API Key 存储目录存在
   */
  private ensureApiKeyStore(): void {
    if (!fs.existsSync(this.apiKeyStore)) {
      fs.mkdirSync(this.apiKeyStore, { recursive: true });
    }
  }

  /**
   * 注册新用户
   */
  async register(request: RegisterRequest): Promise<AuthResponse> {
    // 检查用户名是否已存在
    const existingUser = await this.storageService.findUserByUsername(request.username);
    if (existingUser) {
      return { success: false, error: '用户名已存在' };
    }

    // 生成用户 Salt (用于客户端加密密钥派生)
    const userSalt = PasswordHashUtils.generateSalt();

    // 生成密码哈希 (用于服务器验证)
    const passwordHash = PasswordHashUtils.hashPassword(request.password, userSalt);

    // 创建用户
    const userId = uuidv4();
    const now = new Date();

    const user: UserInfo = {
      id: userId,
      username: request.username,
      passwordHash,
      salt: userSalt,
      createdAt: now,
      devices: [
        {
          deviceId: request.deviceId,
          deviceName: request.deviceName,
          createdAt: now,
        },
      ],
    };

    // 保存用户
    await this.storageService.addUser(user);

    // 生成 Token
    const token = this.generateToken(userId);
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + this.tokenExpiryDays);

    return {
      success: true,
      userId,
      token,
      expiresAt,
      userSalt,
    };
  }

  /**
   * 用户登录
   */
  async login(request: LoginRequest): Promise<AuthResponse> {
    // 查找用户
    const user = await this.storageService.findUserByUsername(request.username);
    if (!user) {
      return { success: false, error: '用户名或密码错误' };
    }

    // 验证密码
    if (!PasswordHashUtils.verifyPassword(request.password, user.salt, user.passwordHash)) {
      return { success: false, error: '用户名或密码错误' };
    }

    // 更新设备信息
    const now = new Date();
    const deviceIndex = user.devices.findIndex((d: { deviceId: string }) => d.deviceId === request.deviceId);

    if (deviceIndex >= 0) {
      // 更新现有设备
      user.devices[deviceIndex] = {
        ...user.devices[deviceIndex],
        deviceName: request.deviceName || user.devices[deviceIndex].deviceName,
        lastSyncAt: now,
      };
    } else {
      // 添加新设备
      user.devices.push({
        deviceId: request.deviceId,
        deviceName: request.deviceName || 'Unknown Device',
        createdAt: now,
      });
    }

    // 更新用户信息
    user.lastLoginAt = now;
    await this.storageService.updateUser(user);

    // 生成 Token
    const token = this.generateToken(user.id);
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + this.tokenExpiryDays);

    return {
      success: true,
      userId: user.id,
      token,
      expiresAt,
      userSalt: user.salt,
    };
  }

  /**
   * 刷新 Token
   */
  async refreshToken(request: RefreshTokenRequest): Promise<AuthResponse> {
    // 验证当前 Token
    const payload = this.verifyToken(request.token);
    if (!payload) {
      return { success: false, error: 'Token 无效或已过期' };
    }

    const userId = payload.sub;
    if (!userId) {
      return { success: false, error: 'Token 格式错误' };
    }

    // 查找用户
    const user = await this.storageService.findUserById(userId);
    if (!user) {
      return { success: false, error: '用户不存在' };
    }

    // 生成新 Token
    const newToken = this.generateToken(userId);
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + this.tokenExpiryDays);

    return {
      success: true,
      userId,
      token: newToken,
      expiresAt,
      userSalt: user.salt,
    };
  }

  /**
   * 根据 ID 获取用户信息
   */
  async getUserById(userId: string): Promise<UserInfo | null> {
    return await this.storageService.findUserById(userId);
  }

  /**
   * 验证 Token
   */
  verifyToken(token: string): { sub: string; iat: number; exp: number } | null {
    try {
      return jwt.verify(token, this.jwtSecret) as { sub: string; iat: number; exp: number };
    } catch (e) {
      return null;
    }
  }

  /**
   * 从 Token 获取用户 ID
   */
  getUserIdFromToken(token: string): string | null {
    const payload = this.verifyToken(token);
    return payload?.sub || null;
  }

  /**
   * 生成 JWT Token
   */
  private generateToken(userId: string): string {
    const now = Math.floor(Date.now() / 1000);
    const exp = now + this.tokenExpiryDays * 24 * 60 * 60;

    return jwt.sign(
      {
        sub: userId,
        iat: now,
        exp,
      },
      this.jwtSecret,
    );
  }

  // ==================== API Key 管理 ====================

  /**
   * 获取用户的 API Keys 文件路径
   */
  private getApiKeyFilePath(userId: string): string {
    return path.join(this.apiKeyStore, `${userId}.json`);
  }

  /**
   * 读取用户的 API Keys
   */
  private readApiKeys(userId: string): ApiKey[] {
    const file = this.getApiKeyFilePath(userId);
    if (!fs.existsSync(file)) return [];

    try {
      const content = fs.readFileSync(file, 'utf8');
      return JSON.parse(content) as ApiKey[];
    } catch (e) {
      console.error(`读取 API Keys 失败: ${e}`);
      return [];
    }
  }

  /**
   * 保存用户的 API Keys
   */
  private saveApiKeys(userId: string, keys: ApiKey[]): void {
    const file = this.getApiKeyFilePath(userId);
    fs.writeFileSync(file, JSON.stringify(keys, null, 2), 'utf8');
  }

  /**
   * 生成新的 API Key
   */
  async generateApiKey(params: {
    userId: string;
    name: string;
    expiry: ApiKeyExpiry;
  }): Promise<ApiKey> {
    // 验证用户存在
    const user = await this.storageService.findUserById(params.userId);
    if (!user) {
      throw new Error('用户不存在');
    }

    const now = new Date();
    const id = uuidv4();
    const key = `mk_${crypto.randomBytes(32).toString('base64url')}`;
    const keyHash = crypto.createHash('sha256').update(key).digest('hex');

    let expiresAt: Date | undefined;
    switch (params.expiry) {
      case '7days':
        expiresAt = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
        break;
      case '30days':
        expiresAt = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
        break;
      case '90days':
        expiresAt = new Date(now.getTime() + 90 * 24 * 60 * 60 * 1000);
        break;
      case '1year':
        expiresAt = new Date(now.getTime() + 365 * 24 * 60 * 60 * 1000);
        break;
      case 'never':
      default:
        expiresAt = undefined;
    }

    const apiKey: ApiKey = {
      id,
      userId: params.userId,
      name: params.name,
      key,
      keyHash,
      createdAt: now,
      expiresAt,
      isRevoked: false,
    };

    // 保存到存储
    const keys = this.readApiKeys(params.userId);
    keys.push(apiKey);
    this.saveApiKeys(params.userId, keys);

    return apiKey;
  }

  /**
   * 验证 API Key
   */
  async verifyApiKey(keyValue: string): Promise<ApiKeyValidationResult | null> {
    // 在所有用户中查找
    const apiKeyDir = this.apiKeyStore;
    if (!fs.existsSync(apiKeyDir)) return null;

    const files = fs.readdirSync(apiKeyDir).filter(f => f.endsWith('.json'));

    for (const file of files) {
      const userId = file.replace('.json', '');
      const keys = this.readApiKeys(userId);

      for (const apiKey of keys) {
        // 使用时间常量比较防止时序攻击
        if (crypto.timingSafeEqual(
          Buffer.from(apiKey.key),
          Buffer.from(keyValue),
        )) {
          // 检查是否已撤销
          if (apiKey.isRevoked) return null;

          // 检查是否过期
          if (apiKey.expiresAt && new Date() > apiKey.expiresAt) {
            return null;
          }

          // 更新最后使用时间
          apiKey.lastUsedAt = new Date();
          this.saveApiKeys(userId, keys);

          return {
            userId: apiKey.userId,
            keyId: apiKey.id,
            keyName: apiKey.name,
          };
        }
      }
    }

    return null;
  }

  /**
   * 获取用户的所有 API Keys
   */
  async listApiKeys(userId: string): Promise<ApiKey[]> {
    return this.readApiKeys(userId);
  }

  /**
   * 撤销 API Key
   */
  async revokeApiKey(userId: string, keyId: string): Promise<boolean> {
    const keys = this.readApiKeys(userId);
    const key = keys.find(k => k.id === keyId);

    if (!key) {
      throw new Error('API Key 不存在');
    }

    if (key.userId !== userId) {
      throw new Error('无权操作此 API Key');
    }

    key.isRevoked = true;
    this.saveApiKeys(userId, keys);

    return true;
  }

  // ==================== 设备管理 ====================

  /**
   * 获取用户的所有设备
   */
  async getDevices(userId: string): Promise<DeviceInfo[]> {
    const user = await this.storageService.findUserById(userId);
    if (!user) {
      throw new Error('用户不存在');
    }
    return user.devices || [];
  }

  /**
   * 注册或更新设备
   */
  async registerDevice(params: {
    userId: string;
    deviceId: string;
    deviceName: string;
    fcmToken?: string;
    platform?: string;
  }): Promise<DeviceInfo> {
    const user = await this.storageService.findUserById(params.userId);
    if (!user) {
      throw new Error('用户不存在');
    }

    const now = new Date();
    const deviceIndex = user.devices.findIndex(d => d.deviceId === params.deviceId);

    let device: DeviceInfo;

    if (deviceIndex >= 0) {
      // 更新现有设备
      device = {
        ...user.devices[deviceIndex],
        deviceName: params.deviceName || user.devices[deviceIndex].deviceName,
        lastSyncAt: now,
      };

      // 更新 FCM Token
      if (params.fcmToken !== undefined) {
        device.fcmToken = params.fcmToken;
      }

      // 更新平台信息
      if (params.platform !== undefined) {
        device.platform = params.platform;
      }

      user.devices[deviceIndex] = device;
    } else {
      // 添加新设备
      device = {
        deviceId: params.deviceId,
        deviceName: params.deviceName || 'Unknown Device',
        createdAt: now,
        lastSyncAt: now,
        fcmToken: params.fcmToken,
        platform: params.platform,
      };
      user.devices.push(device);
    }

    await this.storageService.updateUser(user);
    return device;
  }

  /**
   * 删除设备
   */
  async deleteDevice(userId: string, deviceId: string): Promise<boolean> {
    const user = await this.storageService.findUserById(userId);
    if (!user) {
      throw new Error('用户不存在');
    }

    const initialLength = user.devices.length;
    user.devices = user.devices.filter(d => d.deviceId !== deviceId);

    if (user.devices.length === initialLength) {
      throw new Error('设备不存在');
    }

    await this.storageService.updateUser(user);
    return true;
  }

  /**
   * 更新设备的 FCM Token
   */
  async updateDeviceFcmToken(userId: string, deviceId: string, fcmToken: string): Promise<boolean> {
    const user = await this.storageService.findUserById(userId);
    if (!user) {
      throw new Error('用户不存在');
    }

    const device = user.devices.find(d => d.deviceId === deviceId);
    if (!device) {
      throw new Error('设备不存在');
    }

    device.fcmToken = fcmToken;
    device.lastSyncAt = new Date();

    await this.storageService.updateUser(user);
    return true;
  }

  /**
   * 获取用户设备的 FCM Tokens（用于推送）
   */
  async getDeviceFcmTokens(userId: string, deviceId?: string): Promise<string[]> {
    const user = await this.storageService.findUserById(userId);
    if (!user) {
      return [];
    }

    const devices = deviceId
      ? user.devices.filter(d => d.deviceId === deviceId)
      : user.devices;

    return devices
      .filter(d => d.fcmToken)
      .map(d => d.fcmToken!);
  }

  // ==================== API 访问控制 ====================

  /**
   * 读取 API 访问状态
   */
  private readApiAccessStatus(): Record<string, boolean> {
    if (!fs.existsSync(this.apiAccessStore)) {
      return {};
    }

    try {
      const content = fs.readFileSync(this.apiAccessStore, 'utf8');
      return JSON.parse(content) as Record<string, boolean>;
    } catch (e) {
      console.error(`读取 API 访问状态失败: ${e}`);
      return {};
    }
  }

  /**
   * 保存 API 访问状态
   */
  private saveApiAccessStatus(status: Record<string, boolean>): void {
    fs.writeFileSync(this.apiAccessStore, JSON.stringify(status, null, 2), 'utf8');
  }

  /**
   * 获取用户的 API 访问状态
   */
  async getApiAccessStatus(userId: string): Promise<boolean> {
    const status = this.readApiAccessStatus();
    return status[userId] ?? false;
  }

  /**
   * 设置用户的 API 访问状态
   */
  async setApiAccessStatus(userId: string, enabled: boolean): Promise<void> {
    const status = this.readApiAccessStatus();
    status[userId] = enabled;
    this.saveApiAccessStatus(status);
  }
}

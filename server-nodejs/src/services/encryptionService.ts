import crypto from 'crypto';

/**
 * 服务端加密/解密服务 - 使用 AES-256-GCM
 *
 * 与 Dart 客户端 EncryptionService 兼容
 * 加密格式: base64(iv).base64(ciphertext)
 */
export class EncryptionService {
  /** 用户加密密钥缓存 (userId -> encrypter) */
  private userKeys: Map<string, Buffer> = new Map();

  /** 算法 */
  private readonly ALGORITHM = 'aes-256-gcm';
  /** IV 长度 (16 字节) */
  private readonly IV_LENGTH = 16;
  /** 认证标签长度 (16 字节) */
  private readonly AUTH_TAG_LENGTH = 16;

  /**
   * 检查用户是否已设置密钥
   */
  hasUserKey(userId: string): boolean {
    return this.userKeys.has(userId);
  }

  /**
   * 获取已加载密钥的用户 ID 列表
   */
  get loadedUserIds(): string[] {
    return Array.from(this.userKeys.keys());
  }

  /**
   * 设置用户的加密密钥
   * @param userId 用户ID
   * @param base64Key Base64 编码的 256-bit 密钥
   */
  setUserKey(userId: string, base64Key: string): void {
    const keyBytes = Buffer.from(base64Key, 'base64');
    if (keyBytes.length !== 32) {
      throw new Error('密钥长度必须为 32 字节 (256-bit)');
    }
    this.userKeys.set(userId, keyBytes);
  }

  /**
   * 获取用户的密钥 (用于持久化)
   */
  getUserKey(userId: string): string | undefined {
    const key = this.userKeys.get(userId);
    return key ? key.toString('base64') : undefined;
  }

  /**
   * 移除用户的加密密钥
   */
  removeUserKey(userId: string): void {
    this.userKeys.delete(userId);
  }

  /**
   * 解密数据为 JSON
   * @param userId 用户ID
   * @param encryptedString 加密字符串，格式: base64(iv).base64(ciphertext)
   */
  decryptData(userId: string, encryptedString: string): unknown {
    const decrypted = this.decryptString(userId, encryptedString);
    return JSON.parse(decrypted);
  }

  /**
   * 解密数据为 JSON 对象
   */
  decryptDataAsMap(userId: string, encryptedString: string): Record<string, unknown> {
    const decrypted = this.decryptString(userId, encryptedString);
    return JSON.parse(decrypted) as Record<string, unknown>;
  }

  /**
   * 解密数据为字符串
   * @param userId 用户ID
   * @param encryptedString 加密字符串，格式: base64(iv).base64(ciphertext)
   */
  decryptString(userId: string, encryptedString: string): string {
    const key = this.userKeys.get(userId);
    if (!key) {
      throw new Error(`用户 ${userId} 的加密密钥未设置`);
    }

    const parts = encryptedString.split('.');
    if (parts.length !== 2) {
      throw new Error('无效的加密数据格式，期望: iv.ciphertext');
    }

    const iv = Buffer.from(parts[0], 'base64');
    const encrypted = Buffer.from(parts[1], 'base64');

    // GCM 模式: 密文最后 16 字节是 auth tag
    const authTag = encrypted.subarray(-this.AUTH_TAG_LENGTH);
    const ciphertext = encrypted.subarray(0, -this.AUTH_TAG_LENGTH);

    const decipher = crypto.createDecipheriv(this.ALGORITHM, key, iv);
    decipher.setAuthTag(authTag);

    const decrypted = Buffer.concat([
      decipher.update(ciphertext),
      decipher.final(),
    ]);

    return decrypted.toString('utf8');
  }

  /**
   * 解密二进制数据
   * 解密后返回原始字节，适用于图片等二进制文件
   * @param userId 用户ID
   * @param encryptedString 加密字符串
   * @returns 解密后的原始字节数据（解密结果为 Base64 编码，再解码为字节）
   */
  decryptBinary(userId: string, encryptedString: string): Buffer {
    // 先解密得到 Base64 编码的原始数据
    const decryptedBase64 = this.decryptString(userId, encryptedString);
    // 将 Base64 解码为原始字节
    return Buffer.from(decryptedBase64, 'base64');
  }

  /**
   * 加密 JSON 数据
   * @param userId 用户ID
   * @param data 要加密的 JSON 数据
   * @returns 格式: base64(iv).base64(ciphertext)
   */
  encryptData(userId: string, data: Record<string, unknown>): string {
    const jsonString = JSON.stringify(data);
    return this.encryptString(userId, jsonString);
  }

  /**
   * 加密动态类型 JSON 数据（支持对象或数组）
   */
  encryptDynamic(userId: string, data: unknown): string {
    const jsonString = JSON.stringify(data);
    return this.encryptString(userId, jsonString);
  }

  /**
   * 加密字符串
   * @param userId 用户ID
   * @param data 要加密的数据
   * @returns 格式: base64(iv).base64(ciphertext+authTag)
   */
  encryptString(userId: string, data: string): string {
    const key = this.userKeys.get(userId);
    if (!key) {
      throw new Error(`用户 ${userId} 的加密密钥未设置`);
    }

    const iv = crypto.randomBytes(this.IV_LENGTH);
    const cipher = crypto.createCipheriv(this.ALGORITHM, key, iv);

    const encrypted = Buffer.concat([
      cipher.update(data, 'utf8'),
      cipher.final(),
    ]);

    // 获取 auth tag 并附加到密文末尾
    const authTag = cipher.getAuthTag();
    const encryptedWithTag = Buffer.concat([encrypted, authTag]);

    return `${iv.toString('base64')}.${encryptedWithTag.toString('base64')}`;
  }

  /**
   * 计算数据的 MD5 (加密前的原始数据)
   */
  computeMd5(data: Record<string, unknown>): string {
    const normalizedJson = this.normalizeJson(data);
    const jsonString = JSON.stringify(normalizedJson);
    return crypto.createHash('md5').update(jsonString, 'utf8').digest('hex');
  }

  /**
   * 计算动态类型数据的 MD5（支持对象或数组）
   */
  computeDynamicMd5(data: unknown): string {
    const normalizedJson = this.normalizeJson(data);
    const jsonString = JSON.stringify(normalizedJson);
    return crypto.createHash('md5').update(jsonString, 'utf8').digest('hex');
  }

  /**
   * 计算字符串的 MD5
   */
  computeStringMd5(data: string): string {
    return crypto.createHash('md5').update(data, 'utf8').digest('hex');
  }

  /**
   * 规范化 JSON (递归排序所有 key)
   */
  private normalizeJson(value: unknown): unknown {
    if (value === null || value === undefined) {
      return value;
    }

    if (Array.isArray(value)) {
      return value.map(item => this.normalizeJson(item));
    }

    if (typeof value === 'object' && value !== null) {
      const sortedObj: Record<string, unknown> = {};
      const keys = Object.keys(value as Record<string, unknown>).sort();
      for (const key of keys) {
        sortedObj[key] = this.normalizeJson((value as Record<string, unknown>)[key]);
      }
      return sortedObj;
    }

    return value;
  }

  /**
   * 从密码和 Salt 派生密钥 (与 Dart 客户端兼容)
   * 用于客户端传递密码而非密钥的场景（不推荐）
   */
  static deriveKeyFromPassword(password: string, salt: string): string {
    const iterations = 10000;
    const keyLength = 32;
    const saltBuffer = Buffer.from(salt, 'utf8');

    const key = crypto.pbkdf2Sync(password, saltBuffer, iterations, keyLength, 'sha256');
    return key.toString('base64');
  }
}

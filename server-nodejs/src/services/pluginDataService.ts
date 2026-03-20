import fs from 'fs';
import path from 'path';
import { EncryptionService } from './encryptionService';
import { FileStorageService } from './fileStorageService';
import { PaginatedResult } from '../types';

/** 密钥验证文件名 */
const KEY_VERIFICATION_FILE_NAME = '.key_verification.json';
/** 密钥验证文件内容 */
const KEY_VERIFICATION_CONTENT = 'MEMENTO_KEY_VERIFICATION_v1';

/**
 * 插件数据访问服务
 *
 * 负责读取、解密、加密和写入各插件的数据
 * 提供统一的数据访问接口供 HTTP 路由使用
 *
 * 安全说明：服务端不保存用户密钥，每次操作需要从请求头传入密钥
 */
export class PluginDataService {
  public storageService: FileStorageService;
  public encryptionService: EncryptionService;
  private dataDir: string;

  constructor(storageService: FileStorageService, dataDir: string) {
    this.storageService = storageService;
    this.encryptionService = new EncryptionService();
    this.dataDir = dataDir;
  }

  /**
   * 初始化服务
   */
  async initialize(): Promise<void> {
    // 服务端不保存密钥，无需初始化
  }

  // ==================== 密钥验证 ====================

  /**
   * 检查用户是否已创建密钥验证文件
   */
  async hasKeyVerificationFile(userId: string): Promise<boolean> {
    const filePath = path.join(this.getUserDataDir(userId), KEY_VERIFICATION_FILE_NAME);
    return fs.existsSync(filePath);
  }

  /**
   * 创建密钥验证文件（首次设置密钥时调用）
   */
  async createKeyVerificationFile(userId: string, encryptionKey: string): Promise<void> {
    const verificationData = {
      content: KEY_VERIFICATION_CONTENT,
      created_at: new Date().toISOString(),
    };

    const encryptedData = this.encryptionService.encryptData(encryptionKey, verificationData);
    const md5Hash = this.encryptionService.computeMd5(verificationData);

    const filePath = path.join(this.getUserDataDir(userId), KEY_VERIFICATION_FILE_NAME);

    // 确保用户目录存在
    const userDir = path.dirname(filePath);
    if (!fs.existsSync(userDir)) {
      fs.mkdirSync(userDir, { recursive: true });
    }

    const fileContent = {
      encrypted_data: encryptedData,
      md5: md5Hash,
      updated_at: new Date().toISOString(),
    };

    fs.writeFileSync(filePath, JSON.stringify(fileContent), 'utf8');
  }

  /**
   * 验证密钥是否正确
   */
  async verifyEncryptionKey(
    userId: string,
    encryptionKey: string,
  ): Promise<[boolean, string | null]> {
    // 检查验证文件是否存在
    if (!await this.hasKeyVerificationFile(userId)) {
      // 验证文件不存在，这是首次设置密钥
      return [true, null];
    }

    // 读取验证文件
    const filePath = path.join(this.getUserDataDir(userId), KEY_VERIFICATION_FILE_NAME);

    if (!fs.existsSync(filePath)) {
      return [true, null];
    }

    try {
      const content = fs.readFileSync(filePath, 'utf8');
      const data = JSON.parse(content);
      const encryptedData = data.encrypted_data as string | undefined;

      if (!encryptedData) {
        return [false, '验证文件格式错误'];
      }

      try {
        // 尝试解密
        const decryptedData = this.encryptionService.decryptData(
          encryptionKey,
          encryptedData,
        ) as Record<string, unknown>;
        const decryptedContent = decryptedData.content as string | undefined;

        // 验证内容是否正确
        if (decryptedContent !== KEY_VERIFICATION_CONTENT) {
          return [false, '密钥验证失败：内容不匹配'];
        }

        // 验证成功
        return [true, null];
      } catch (e) {
        return [false, '密钥验证失败：无法解密验证文件，密钥可能不正确'];
      }
    } catch (e) {
      return [false, `读取验证文件失败: ${e}`];
    }
  }

  /**
   * 更新验证文件（用于更改密钥后重新加密验证文件）
   */
  async updateKeyVerificationFile(userId: string, encryptionKey: string): Promise<void> {
    // 先删除旧的验证文件
    const filePath = path.join(this.getUserDataDir(userId), KEY_VERIFICATION_FILE_NAME);
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }
    // 创建新的验证文件
    await this.createKeyVerificationFile(userId, encryptionKey);
  }

  // ==================== 数据读取 ====================

  /**
   * 读取并解密插件数据文件
   */
  async readPluginData(
    userId: string,
    pluginId: string,
    fileName: string,
    encryptionKey: string,
  ): Promise<unknown> {
    const filePath = `${pluginId}/${fileName}`;
    const fileData = await this.storageService.readEncryptedFile(userId, filePath);

    if (!fileData) return null;

    const encryptedData = fileData.encrypted_data;
    if (!encryptedData) return null;

    try {
      return this.encryptionService.decryptData(encryptionKey, encryptedData);
    } catch (e) {
      console.error(`解密数据失败 (${filePath}): ${e}`);
      return null;
    }
  }

  /**
   * 读取插件数据文件列表
   */
  async listPluginFiles(
    userId: string,
    pluginId: string,
    pattern?: string,
  ): Promise<string[]> {
    const pluginDir = path.join(this.dataDir, 'users', userId, pluginId);
    if (!fs.existsSync(pluginDir)) return [];

    const files: string[] = [];
    const entries = fs.readdirSync(pluginDir, { withFileTypes: true });

    for (const entry of entries) {
      if (entry.isFile() && entry.name.endsWith('.json')) {
        if (!pattern || this.matchPattern(entry.name, pattern)) {
          files.push(entry.name);
        }
      }
    }

    return files;
  }

  /**
   * 简单的文件名模式匹配
   */
  private matchPattern(fileName: string, pattern: string): boolean {
    const regex = new RegExp(`^${pattern.replace(/\*/g, '.*')}$`);
    return regex.test(fileName);
  }

  // ==================== 数据写入 ====================

  /**
   * 加密并写入插件数据（支持对象或数组）
   */
  async writePluginData(
    userId: string,
    pluginId: string,
    fileName: string,
    data: unknown,
    encryptionKey: string,
  ): Promise<void> {
    const encryptedData = this.encryptionService.encryptDynamic(encryptionKey, data);
    const md5Hash = this.encryptionService.computeDynamicMd5(data);
    const filePath = `${pluginId}/${fileName}`;

    await this.storageService.writeEncryptedFile(
      userId,
      filePath,
      encryptedData,
      md5Hash,
    );
  }

  /**
   * 删除插件数据文件
   */
  async deletePluginFile(
    userId: string,
    pluginId: string,
    fileName: string,
  ): Promise<boolean> {
    const filePath = `${pluginId}/${fileName}`;
    return await this.storageService.deleteFile(userId, filePath);
  }

  // ==================== 辅助方法 ====================

  /**
   * 获取用户数据目录
   */
  getUserDataDir(userId: string): string {
    return path.join(this.dataDir, 'users', userId);
  }

  /**
   * 检查插件目录是否存在
   */
  async pluginDirExists(userId: string, pluginId: string): Promise<boolean> {
    const dir = path.join(this.getUserDataDir(userId), pluginId);
    return fs.existsSync(dir);
  }

  /**
   * 创建插件目录
   */
  async createPluginDir(userId: string, pluginId: string): Promise<void> {
    const dir = path.join(this.getUserDataDir(userId), pluginId);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
  }

  // ==================== 分页辅助 ====================

  /**
   * 分页处理列表数据
   */
  paginate<T>(
    list: T[],
    options: { offset?: number; count?: number } = {},
  ): PaginatedResult<T> {
    const { offset = 0, count = 100 } = options;
    const total = list.length;
    const start = Math.min(offset, total);
    const end = Math.min(start + count, total);
    const data = list.slice(start, end);

    return {
      data,
      total,
      offset: start,
      count: data.length,
      hasMore: end < total,
    };
  }

  // ==================== 重新加密（密钥更改）====================

  /**
   * 重新加密用户的所有文件
   */
  async reEncryptAllFiles(
    userId: string,
    oldKey: string,
    newKey: string,
  ): Promise<{ fileCount: number; errors: string[] }> {
    let fileCount = 0;
    const errors: string[] = [];

    // 获取用户数据目录
    const userDir = this.getUserDataDir(userId);
    if (!fs.existsSync(userDir)) {
      return { fileCount: 0, errors };
    }

    // 遍历所有 JSON 文件
    const processDir = async (dir: string) => {
      const entries = fs.readdirSync(dir, { withFileTypes: true });

      for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);

        if (entry.isDirectory()) {
          await processDir(fullPath);
        } else if (entry.isFile() && entry.name.endsWith('.json')) {
          try {
            // 读取加密文件
            const relativePath = path.relative(userDir, fullPath);
            const fileData = await this.storageService.readEncryptedFile(userId, relativePath);

            if (!fileData) continue;

            const encryptedData = fileData.encrypted_data;
            if (!encryptedData) continue;

            // 用旧密钥解密
            const decryptedData = this.encryptionService.decryptData(oldKey, encryptedData);

            // 用新密钥重新加密
            const newEncryptedData = this.encryptionService.encryptString(
              newKey,
              JSON.stringify(decryptedData),
            );
            const newMd5 = this.encryptionService.computeStringMd5(JSON.stringify(decryptedData));

            // 保存文件
            await this.storageService.writeEncryptedFile(
              userId,
              relativePath,
              newEncryptedData,
              newMd5,
            );

            fileCount++;
          } catch (e) {
            errors.push(`${entry.name}: ${e}`);
          }
        }
      }
    };

    await processDir(userDir);

    return { fileCount, errors };
  }
}

import fs from 'fs';
import path from 'path';
import archiver from 'archiver';
import { FileInfo, FolderNode, FileIndex, EncryptedFile } from '../types';

/** 索引文件名 */
const INDEX_FILE_NAME = '.file_index.json';
/** 索引版本 */
const INDEX_VERSION = 1;

/**
 * 文件存储服务 - 纯文件系统存储
 *
 * 目录结构:
 * {dataDir}/
 * ├── users/
 * │   └── {userId}/
 * │       ├── .file_index.json  (持久化文件索引)
 * │       └── ...
 * ├── auth/
 * │   └── users.json
 * └── logs/
 *     └── sync_xxx.log
 */
export class FileStorageService {
  private baseDir: string;
  private indexCache: Map<string, FileIndex> = new Map();

  constructor(baseDir: string) {
    this.baseDir = baseDir;
  }

  /**
   * 初始化存储目录
   */
  async initialize(): Promise<void> {
    const dirs = [
      this.baseDir,
      path.join(this.baseDir, 'users'),
      path.join(this.baseDir, 'auth'),
      path.join(this.baseDir, 'auth', 'api_keys'),
      path.join(this.baseDir, 'logs'),
      path.join(this.baseDir, 'exports'),
    ];

    for (const dir of dirs) {
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
    }

    // 初始化用户数据文件
    const usersFile = path.join(this.baseDir, 'auth', 'users.json');
    if (!fs.existsSync(usersFile)) {
      fs.writeFileSync(usersFile, JSON.stringify({ users: [] }), 'utf8');
    }
  }

  // ========== 用户数据操作 ==========

  /**
   * 获取用户数据目录
   */
  getUserDir(userId: string): string {
    return path.join(this.baseDir, 'users', userId);
  }

  /**
   * 获取导出目录
   */
  getExportDir(): string {
    return path.join(this.baseDir, 'exports');
  }

  /**
   * 读取加密文件
   */
  async readEncryptedFile(userId: string, filePath: string): Promise<EncryptedFile | null> {
    const fullPath = path.join(this.getUserDir(userId), filePath);
    if (!fs.existsSync(fullPath)) return null;

    try {
      const content = await fs.promises.readFile(fullPath, 'utf8');
      return JSON.parse(content) as EncryptedFile;
    } catch (e) {
      console.error(`读取文件失败: ${filePath} - ${e}`);
      return null;
    }
  }

  /**
   * 写入加密文件
   */
  async writeEncryptedFile(
    userId: string,
    filePath: string,
    encryptedData: string,
    md5Hash: string,
    isBinary: boolean = false,
  ): Promise<void> {
    const fullPath = path.join(this.getUserDir(userId), filePath);

    // 确保父目录存在
    const parentDir = path.dirname(fullPath);
    if (!fs.existsSync(parentDir)) {
      fs.mkdirSync(parentDir, { recursive: true });
    }

    const now = new Date();
    const data: EncryptedFile = {
      encrypted_data: encryptedData,
      md5: md5Hash,
      updated_at: now.toISOString(),
      is_binary: isBinary,
    };

    await fs.promises.writeFile(fullPath, JSON.stringify(data), 'utf8');

    // 更新文件索引
    const stats = await fs.promises.stat(fullPath);
    await this.updateFileIndex(userId, filePath, {
      md5: md5Hash,
      size: stats.size,
      updatedAt: now.toISOString(),
    });
  }

  /**
   * 删除文件
   */
  async deleteFile(userId: string, filePath: string): Promise<boolean> {
    const fullPath = path.join(this.getUserDir(userId), filePath);
    if (fs.existsSync(fullPath)) {
      await fs.promises.unlink(fullPath);

      // 从文件索引中移除
      await this.removeFromFileIndex(userId, filePath);

      return true;
    }
    return false;
  }

  // ========== 文件索引操作 ==========

  /**
   * 获取索引文件路径
   */
  private getIndexFilePath(userId: string): string {
    return path.join(this.getUserDir(userId), INDEX_FILE_NAME);
  }

  /**
   * 加载用户文件索引
   */
  private async loadFileIndex(userId: string): Promise<FileIndex> {
    // 先检查缓存
    if (this.indexCache.has(userId)) {
      return this.indexCache.get(userId)!;
    }

    const indexFile = this.getIndexFilePath(userId);

    if (!fs.existsSync(indexFile)) {
      // 索引不存在，重建索引
      return await this.rebuildFileIndex(userId);
    }

    try {
      const content = await fs.promises.readFile(indexFile, 'utf8');
      const data = JSON.parse(content) as FileIndex;

      // 检查版本
      if ((data.version ?? 0) < INDEX_VERSION) {
        // 版本过旧，重建索引
        return await this.rebuildFileIndex(userId);
      }

      this.indexCache.set(userId, data);
      return data;
    } catch (e) {
      console.error(`加载文件索引失败: ${e}，将重建索引`);
      return await this.rebuildFileIndex(userId);
    }
  }

  /**
   * 保存用户文件索引
   */
  private async saveFileIndex(userId: string, index: FileIndex): Promise<void> {
    const indexFile = this.getIndexFilePath(userId);

    // 确保用户目录存在
    const userDir = path.dirname(indexFile);
    if (!fs.existsSync(userDir)) {
      fs.mkdirSync(userDir, { recursive: true });
    }

    index.updatedAt = new Date().toISOString();
    await fs.promises.writeFile(indexFile, JSON.stringify(index, null, 2), 'utf8');

    // 更新缓存
    this.indexCache.set(userId, index);
  }

  /**
   * 更新文件索引中的单个文件
   */
  private async updateFileIndex(
    userId: string,
    filePath: string,
    fileInfo: { md5: string; size: number; updatedAt: string },
  ): Promise<void> {
    const index = await this.loadFileIndex(userId);
    const files = index.files || {};

    // 标准化路径（使用正斜杠）
    const normalizedPath = filePath.replace(/\\/g, '/');
    files[normalizedPath] = fileInfo;

    index.files = files;
    await this.saveFileIndex(userId, index);
  }

  /**
   * 从文件索引中移除文件
   */
  private async removeFromFileIndex(userId: string, filePath: string): Promise<void> {
    const index = await this.loadFileIndex(userId);
    const files = index.files || {};

    // 标准化路径
    const normalizedPath = filePath.replace(/\\/g, '/');
    delete files[normalizedPath];

    index.files = files;
    await this.saveFileIndex(userId, index);
  }

  /**
   * 获取用户文件索引
   */
  async getFileIndex(userId: string): Promise<FileIndex> {
    return await this.loadFileIndex(userId);
  }

  /**
   * 重建文件索引
   */
  async rebuildFileIndex(userId: string): Promise<FileIndex> {
    const userDir = this.getUserDir(userId);
    const files: FileIndex['files'] = {};

    if (fs.existsSync(userDir)) {
      await this.walkDir(userDir, userDir, async (filePath, stats) => {
        const fileName = path.basename(filePath);

        // 排除索引文件本身和临时文件
        if (fileName === INDEX_FILE_NAME ||
            fileName.startsWith('.') ||
            fileName.endsWith('.tmp') ||
            fileName.endsWith('.bak')) {
          return;
        }

        try {
          const relativePath = path.relative(userDir, filePath).replace(/\\/g, '/');
          const content = await fs.promises.readFile(filePath, 'utf8');
          const data = JSON.parse(content) as EncryptedFile;

          // 检查是否是加密文件格式
          if (data.md5 && data.encrypted_data) {
            files[relativePath] = {
              md5: data.md5,
              size: stats.size,
              updatedAt: data.updated_at || new Date().toISOString(),
            };
          }
        } catch (e) {
          // 非 JSON 文件或解析失败，跳过
        }
      });
    }

    const index: FileIndex = {
      version: INDEX_VERSION,
      updatedAt: new Date().toISOString(),
      files,
    };

    await this.saveFileIndex(userId, index);
    console.log(`已为用户 ${userId} 重建文件索引，共 ${Object.keys(files).length} 个文件`);

    return index;
  }

  /**
   * 递归遍历目录
   */
  private async walkDir(
    dir: string,
    baseDir: string,
    callback: (filePath: string, stats: fs.Stats) => Promise<void>,
  ): Promise<void> {
    const entries = await fs.promises.readdir(dir, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);

      if (entry.isDirectory()) {
        await this.walkDir(fullPath, baseDir, callback);
      } else if (entry.isFile()) {
        const stats = await fs.promises.stat(fullPath);
        await callback(fullPath, stats);
      }
    }
  }

  /**
   * 批量从索引中移除文件
   */
  async batchRemoveFromFileIndex(userId: string, filePaths: string[]): Promise<void> {
    const index = await this.loadFileIndex(userId);
    const files = index.files || {};

    for (const filePath of filePaths) {
      const normalizedPath = filePath.replace(/\\/g, '/');
      delete files[normalizedPath];
    }

    index.files = files;
    await this.saveFileIndex(userId, index);
  }

  /**
   * 列出用户文件（单层目录）
   */
  async listUserFiles(userId: string, directory?: string): Promise<FileInfo[]> {
    const userDir = this.getUserDir(userId);
    if (!fs.existsSync(userDir)) return [];

    // 确定要列出的目录
    const targetDir = directory
      ? path.join(userDir, directory)
      : userDir;

    if (!fs.existsSync(targetDir)) return [];

    const entries = await fs.promises.readdir(targetDir, { withFileTypes: true });
    const items: FileInfo[] = [];

    for (const entry of entries) {
      const entityName = entry.name;
      const relativePath = directory
        ? `${directory}/${entityName}`
        : entityName;

      // 跳过隐藏文件（以 . 开头）
      if (entityName.startsWith('.')) {
        continue;
      }

      if (entry.isFile()) {
        try {
          const fullPath = path.join(targetDir, entityName);
          const content = await fs.promises.readFile(fullPath, 'utf8');
          const data = JSON.parse(content) as EncryptedFile;
          const stats = await fs.promises.stat(fullPath);

          items.push({
            path: relativePath.replace(/\\/g, '/'),
            size: stats.size,
            md5: data.md5,
            updatedAt: new Date(data.updated_at),
            isFolder: false,
          });
        } catch (e) {
          // 非 JSON 文件或解析失败，仍然返回基本信息
          const stats = await fs.promises.stat(path.join(targetDir, entityName));
          items.push({
            path: relativePath.replace(/\\/g, '/'),
            size: stats.size,
            updatedAt: stats.mtime,
            isFolder: false,
          });
        }
      } else if (entry.isDirectory()) {
        const stats = await fs.promises.stat(path.join(targetDir, entityName));
        items.push({
          path: relativePath.replace(/\\/g, '/'),
          updatedAt: stats.mtime,
          isFolder: true,
        });
      }
    }

    // 按名称排序：文件夹在前，文件在后
    items.sort((a, b) => {
      if (a.isFolder && !b.isFolder) return -1;
      if (!a.isFolder && b.isFolder) return 1;
      return a.path.localeCompare(b.path);
    });

    return items;
  }

  /**
   * 获取用户数据大小 (字节)
   */
  async getUserDataSize(userId: string): Promise<number> {
    const userDir = this.getUserDir(userId);
    if (!fs.existsSync(userDir)) return 0;

    let totalSize = 0;
    await this.walkDir(userDir, userDir, async (_filePath, stats) => {
      totalSize += stats.size;
    });

    return totalSize;
  }

  /**
   * 获取用户存储统计信息
   */
  async getUserStorageStats(userId: string): Promise<{
    fileCount: number;
    folderCount: number;
    totalSize: number;
  }> {
    const userDir = this.getUserDir(userId);
    if (!fs.existsSync(userDir)) {
      return { fileCount: 0, folderCount: 0, totalSize: 0 };
    }

    let fileCount = 0;
    let folderCount = 0;
    let totalSize = 0;

    // 递归遍历目录
    const walkDir = async (dir: string): Promise<void> => {
      const entries = await fs.promises.readdir(dir, { withFileTypes: true });
      for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);
        if (entry.isDirectory()) {
          folderCount++;
          await walkDir(fullPath);
        } else if (entry.isFile()) {
          fileCount++;
          const stats = await fs.promises.stat(fullPath);
          totalSize += stats.size;
        }
      }
    };

    await walkDir(userDir);
    return { fileCount, folderCount, totalSize };
  }

  // ========== 用户认证数据操作 ==========

  /**
   * 获取用户认证文件路径
   */
  private get usersFilePath(): string {
    return path.join(this.baseDir, 'auth', 'users.json');
  }

  /**
   * 读取所有用户
   */
  async readAllUsers(): Promise<any[]> {
    const file = this.usersFilePath;
    if (!fs.existsSync(file)) return [];

    try {
      const content = await fs.promises.readFile(file, 'utf8');
      const data = JSON.parse(content);
      return data.users || [];
    } catch (e) {
      console.error(`读取用户数据失败: ${e}`);
      return [];
    }
  }

  /**
   * 保存所有用户
   */
  async saveAllUsers(users: any[]): Promise<void> {
    const file = this.usersFilePath;
    const data = {
      users,
      updated_at: new Date().toISOString(),
    };
    await fs.promises.writeFile(file, JSON.stringify(data, null, 2), 'utf8');
  }

  /**
   * 根据用户名查找用户
   */
  async findUserByUsername(username: string): Promise<any | null> {
    const users = await this.readAllUsers();
    return users.find(u => u.username === username) || null;
  }

  /**
   * 根据 ID 查找用户
   */
  async findUserById(userId: string): Promise<any | null> {
    const users = await this.readAllUsers();
    return users.find(u => u.id === userId) || null;
  }

  /**
   * 添加用户
   */
  async addUser(user: any): Promise<void> {
    const users = await this.readAllUsers();
    users.push(user);
    await this.saveAllUsers(users);
  }

  /**
   * 更新用户
   */
  async updateUser(updatedUser: any): Promise<void> {
    const users = await this.readAllUsers();
    const index = users.findIndex(u => u.id === updatedUser.id);
    if (index >= 0) {
      users[index] = updatedUser;
      await this.saveAllUsers(users);
    }
  }

  // ========== 日志操作 ==========

  /**
   * 记录同步日志
   */
  async logSync(params: {
    userId: string;
    action: string;
    filePath: string;
    details?: string;
  }): Promise<void> {
    const today = new Date().toISOString().substring(0, 10);
    const logFile = path.join(this.baseDir, 'logs', `sync_${today}.log`);

    const logEntry = [
      new Date().toISOString(),
      params.userId,
      params.action,
      params.filePath,
      params.details || '',
    ].join('\t');

    await fs.promises.appendFile(logFile, `${logEntry}\n`, 'utf8');
  }

  // ========== 目录树结构操作 ==========

  /**
   * 获取目录树结构
   */
  async getDirectoryTree(userId: string): Promise<FolderNode> {
    const userDir = this.getUserDir(userId);
    if (!fs.existsSync(userDir)) {
      return {
        name: 'root',
        path: '',
        isFolder: true,
        children: [],
      };
    }

    return await this.buildTree(userDir, '');
  }

  /**
   * 递归构建目录树
   */
  private async buildTree(dir: string, relativePath: string): Promise<FolderNode> {
    const name = path.basename(dir);
    const children: FolderNode[] = [];

    try {
      const entries = await fs.promises.readdir(dir, { withFileTypes: true });

      for (const entry of entries) {
        const entityName = entry.name;
        const entityRelativePath = relativePath
          ? `${relativePath}/${entityName}`
          : entityName;

        if (entry.isFile() && entityName.endsWith('.json')) {
          try {
            const fullPath = path.join(dir, entityName);
            const content = await fs.promises.readFile(fullPath, 'utf8');
            const data = JSON.parse(content) as EncryptedFile;
            const stats = await fs.promises.stat(fullPath);

            children.push({
              name: entityName,
              path: entityRelativePath,
              isFolder: false,
              size: stats.size,
              updatedAt: new Date(data.updated_at),
            });
          } catch (e) {
            console.error(`读取文件信息失败: ${path.join(dir, entityName)} - ${e}`);
          }
        } else if (entry.isDirectory()) {
          // 递归处理子目录
          const subNode = await this.buildTree(
            path.join(dir, entityName),
            entityRelativePath,
          );
          children.push(subNode);
        }
      }
    } catch (e) {
      console.error(`读取目录失败: ${dir} - ${e}`);
    }

    // 按名称排序：文件夹在前，文件在后
    children.sort((a, b) => {
      if (a.isFolder && !b.isFolder) return -1;
      if (!a.isFolder && b.isFolder) return 1;
      return a.name.localeCompare(b.name);
    });

    return {
      name,
      path: relativePath,
      isFolder: true,
      children,
    };
  }

  // ========== ZIP导出功能 ==========

  /**
   * 导出用户数据为ZIP文件
   */
  async exportUserDataAsZip(userId: string): Promise<{
    success: boolean;
    filePath: string;
    fileName: string;
    fileSize: number;
    metadata: any;
  }> {
    const userDir = this.getUserDir(userId);
    if (!fs.existsSync(userDir)) {
      throw new Error('用户数据目录不存在');
    }

    const timestamp = new Date().toISOString()
      .replace(/:/g, '-')
      .replace(/\./g, '-');
    const exportDir = this.getExportDir();
    const exportFileName = `memento_export_${timestamp}.zip`;
    const exportFilePath = path.join(exportDir, exportFileName);

    // 确保导出目录存在
    if (!fs.existsSync(exportDir)) {
      fs.mkdirSync(exportDir, { recursive: true });
    }

    return new Promise((resolve, reject) => {
      const output = fs.createWriteStream(exportFilePath);
      const archive = archiver('zip', { zlib: { level: 9 } });

      const files: string[] = [];
      let totalSize = 0;

      output.on('close', async () => {
        const stats = await fs.promises.stat(exportFilePath);
        resolve({
          success: true,
          filePath: exportFilePath,
          fileName: exportFileName,
          fileSize: stats.size,
          metadata: {
            exported_at: new Date().toISOString(),
            user_id: userId,
            file_count: files.length,
            total_size_bytes: totalSize,
            total_size_mb: (totalSize / 1024 / 1024).toFixed(2),
            files,
          },
        });
      });

      archive.on('error', reject);

      archive.pipe(output);

      // 递归添加 JSON 文件
      const addFiles = async (dir: string, base: string) => {
        const entries = await fs.promises.readdir(dir, { withFileTypes: true });

        for (const entry of entries) {
          const fullPath = path.join(dir, entry.name);
          const relativePath = path.join(base, entry.name);

          if (entry.isFile() && entry.name.endsWith('.json')) {
            try {
              const content = await fs.promises.readFile(fullPath);
              archive.append(content, { name: relativePath.replace(/\\/g, '/') });
              files.push(relativePath.replace(/\\/g, '/'));
              totalSize += content.length;
            } catch (e) {
              console.error(`添加文件到ZIP失败: ${fullPath} - ${e}`);
            }
          } else if (entry.isDirectory()) {
            await addFiles(fullPath, relativePath);
          }
        }
      };

      addFiles(userDir, '').then(() => {
        // 添加元数据文件
        const metadata = {
          exported_at: new Date().toISOString(),
          user_id: userId,
          file_count: files.length,
          total_size_bytes: totalSize,
          total_size_mb: (totalSize / 1024 / 1024).toFixed(2),
          files,
        };
        archive.append(JSON.stringify(metadata, null, 2), { name: 'metadata.json' });
        archive.finalize();
      });
    });
  }
}

import chokidar, { FSWatcher } from 'chokidar';
import path from 'path';
import { FileStorageService } from './fileStorageService';
import { WebSocketManager } from './webSocketManager';

/**
 * 文件监听服务
 *
 * 监听用户数据目录的文件变化，并通过 WebSocket 广播通知
 */
export class FileWatcherService {
  private storageService: FileStorageService;
  private webSocketManager: WebSocketManager;
  private dataDir: string;
  private pollIntervalMs: number;
  private watcher: FSWatcher | null = null;
  private running: boolean = false;

  constructor(
    storageService: FileStorageService,
    webSocketManager: WebSocketManager,
    dataDir: string,
    options: { pollIntervalMs?: number } = {},
  ) {
    this.storageService = storageService;
    this.webSocketManager = webSocketManager;
    this.dataDir = dataDir;
    this.pollIntervalMs = options.pollIntervalMs || 2000;
  }

  /**
   * 启动文件监听
   */
  async start(): Promise<void> {
    if (this.running) return;

    const usersDir = path.join(this.dataDir, 'users');

    // 使用轮询模式以确保跨平台兼容性
    this.watcher = chokidar.watch(usersDir, {
      ignored: /(^|[\/\\])\..*|(.*\.tmp$)|(.*\.bak$)/,
      persistent: true,
      ignoreInitial: true,
      awaitWriteFinish: {
        stabilityThreshold: 500,
        pollInterval: 100,
      },
      usePolling: true,
      interval: this.pollIntervalMs,
    });

    this.watcher
      .on('add', (filePath) => this.handleFileChange(filePath, 'add'))
      .on('change', (filePath) => this.handleFileChange(filePath, 'change'))
      .on('unlink', (filePath) => this.handleFileChange(filePath, 'unlink'));

    this.running = true;
    console.log(`文件监听服务已启动: ${usersDir}`);
  }

  /**
   * 停止文件监听
   */
  async stop(): Promise<void> {
    if (this.watcher) {
      await this.watcher.close();
      this.watcher = null;
    }
    this.running = false;
    console.log('文件监听服务已停止');
  }

  /**
   * 处理文件变化
   */
  private async handleFileChange(filePath: string, event: string): Promise<void> {
    try {
      // 只处理 JSON 文件
      if (!filePath.endsWith('.json')) return;

      // 解析路径获取 userId 和相对路径
      const usersDir = path.join(this.dataDir, 'users');
      const relativePath = path.relative(usersDir, filePath);
      const parts = relativePath.split(path.sep);

      if (parts.length < 2) return;

      const userId = parts[0];
      const fileRelativePath = parts.slice(1).join('/');

      // 排除索引文件和验证文件
      if (fileRelativePath.startsWith('.') ||
          fileRelativePath.includes('.file_index') ||
          fileRelativePath.includes('.key_verification')) {
        return;
      }

      // 获取文件信息
      let md5 = '';
      let modifiedAt = new Date();

      if (event !== 'unlink') {
        try {
          const fileData = await this.storageService.readEncryptedFile(userId, fileRelativePath);
          if (fileData) {
            md5 = fileData.md5;
            modifiedAt = new Date(fileData.updated_at);
          }
        } catch (e) {
          console.error(`读取文件信息失败: ${filePath} - ${e}`);
          return;
        }
      }

      // 广播文件更新通知
      // 注意：文件变化来源是服务器本身（非用户设备），所以 sourceDeviceId 为空
      this.webSocketManager.broadcastFileUpdate(
        userId,
        fileRelativePath.replace(/\\/g, '/'),
        md5,
        modifiedAt,
        '', // 空表示广播给所有设备
      );

      console.log(`文件变化广播: userId=${userId}, file=${fileRelativePath}, event=${event}`);
    } catch (e) {
      console.error(`处理文件变化失败: ${filePath} - ${e}`);
    }
  }
}

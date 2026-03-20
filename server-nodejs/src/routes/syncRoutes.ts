import { Router, Request, Response } from 'express';
import { FileStorageService } from '../services/fileStorageService';
import { PluginDataService } from '../services/pluginDataService';
import { getUserIdFromContext } from '../middleware/authMiddleware';
import fs from 'fs';
import path from 'path';

/**
 * URL 解码文件路径
 */
function decodeFilePath(encodedPath: string): string {
  return decodeURIComponent(encodedPath);
}

/**
 * 根据文件扩展名获取 Content-Type
 */
function getContentType(filePath: string): string {
  const extension = filePath.split('.').pop()?.toLowerCase() || '';
  const contentTypes: Record<string, string> = {
    // 图片
    jpg: 'image/jpeg',
    jpeg: 'image/jpeg',
    png: 'image/png',
    gif: 'image/gif',
    webp: 'image/webp',
    svg: 'image/svg+xml',
    ico: 'image/x-icon',
    bmp: 'image/bmp',
    // 音频
    mp3: 'audio/mpeg',
    wav: 'audio/wav',
    ogg: 'audio/ogg',
    m4a: 'audio/mp4',
    // 视频
    mp4: 'video/mp4',
    webm: 'video/webm',
    mov: 'video/quicktime',
    // 文档
    pdf: 'application/pdf',
    doc: 'application/msword',
    docx: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    xls: 'application/vnd.ms-excel',
    xlsx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    // 压缩包
    zip: 'application/zip',
    rar: 'application/vnd.rar',
    '7z': 'application/x-7z-compressed',
    tar: 'application/x-tar',
    gz: 'application/gzip',
  };
  return contentTypes[extension] || 'application/octet-stream';
}

/**
 * 同步路由 - 处理文件推送、拉取和列表
 */
export function createSyncRoutes(
  storageService: FileStorageService,
  pluginDataService: PluginDataService | null,
): Router {
  const router = Router();

  /**
   * 错误响应
   */
  function errorResponse(res: Response, statusCode: number, message: string): void {
    res.status(statusCode).json({
      success: false,
      error: message,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * POST /push - 推送加密文件
   */
  router.post('/push', async (req: Request, res: Response): Promise<void> => {
    const userId = getUserIdFromContext(req);
    if (!userId) {
      errorResponse(res, 401, '未授权');
      return;
    }

    try {
      const data = req.body;

      // 验证必填字段
      const filePath = data.file_path;
      const encryptedData = data.encrypted_data;
      const newMd5 = data.new_md5;

      if (!filePath || !encryptedData || !newMd5) {
        errorResponse(res, 400, '缺少必填字段: file_path, encrypted_data, new_md5');
        return;
      }

      // 验证文件路径安全性 (防止路径遍历攻击)
      if (filePath.includes('..') || filePath.startsWith('/')) {
        errorResponse(res, 400, '无效的文件路径');
        return;
      }

      // 检查是否需要创建密钥验证文件
      // 首次同步时，如果没有验证文件，从请求头获取密钥并创建验证文件
      const encryptionKey = req.headers['x-encryption-key'] as string | undefined;
      if (encryptionKey && pluginDataService) {
        const hasVerificationFile = await pluginDataService.hasKeyVerificationFile(userId);
        if (!hasVerificationFile) {
          // 验证密钥格式（Base64 32字节）
          try {
            const keyBytes = Buffer.from(encryptionKey, 'base64');
            if (keyBytes.length === 32) {
              // 创建密钥验证文件
              await pluginDataService.createKeyVerificationFile(userId, encryptionKey);
            }
          } catch (e) {
            // 密钥格式无效，忽略（不创建验证文件）
          }
        }
      }

      const oldMd5 = data.old_md5;
      const isBinary = data.is_binary === true;

      // 读取服务器当前文件 (如果存在)
      const serverFile = await storageService.readEncryptedFile(userId, filePath);

      // 如果文件存在且提供了 oldMd5，进行冲突检测
      if (serverFile && oldMd5) {
        const currentMd5 = serverFile.md5;

        if (currentMd5 !== oldMd5) {
          // 冲突: 返回 409 + 服务器数据
          // 记录冲突日志
          await storageService.logSync({
            userId,
            action: 'conflict',
            filePath,
            details: `old_md5: ${oldMd5}, server_md5: ${currentMd5}`,
          });

          res.status(409).json({
            success: false,
            error: 'conflict',
            file_path: filePath,
            server_data: serverFile.encrypted_data,
            server_md5: currentMd5,
            server_updated_at: serverFile.updated_at,
            is_binary: serverFile.is_binary || false,
          });
          return;
        }
      }

      // 保存文件
      await storageService.writeEncryptedFile(
        userId,
        filePath,
        encryptedData,
        newMd5,
        isBinary,
      );

      // 记录成功日志
      await storageService.logSync({
        userId,
        action: 'push',
        filePath,
        details: `md5: ${newMd5}`,
      });

      res.json({
        success: true,
        file_path: filePath,
        new_md5: newMd5,
      });
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  /**
   * GET /pull/* - 拉取加密文件
   */
  router.get('/pull/*', async (req: Request, res: Response): Promise<void> => {
    const userId = getUserIdFromContext(req);
    if (!userId) {
      errorResponse(res, 401, '未授权');
      return;
    }

    try {
      // 获取文件路径（去掉 /pull/ 前缀）
      const filePath = req.params[0] ? decodeFilePath(req.params[0]) : '';

      // 验证文件路径安全性
      if (filePath.includes('..') || filePath.startsWith('/')) {
        errorResponse(res, 400, '无效的文件路径');
        return;
      }

      const serverFile = await storageService.readEncryptedFile(userId, filePath);

      if (!serverFile) {
        res.status(404).json({
          success: false,
          error: '文件不存在',
          file_path: filePath,
        });
        return;
      }

      // 记录拉取日志
      await storageService.logSync({
        userId,
        action: 'pull',
        filePath,
      });

      res.json({
        encrypted_data: serverFile.encrypted_data,
        md5: serverFile.md5,
        updated_at: serverFile.updated_at,
        is_binary: serverFile.is_binary || false,
      });
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  /**
   * GET /pull-decrypted/* - 拉取解密后的文件（用于管理后台）
   */
  router.get('/pull-decrypted/*', async (req: Request, res: Response): Promise<void> => {
    const userId = getUserIdFromContext(req);
    if (!userId) {
      errorResponse(res, 401, '未授权');
      return;
    }

    try {
      const filePath = req.params[0] ? decodeFilePath(req.params[0]) : '';

      // 验证文件路径安全性
      if (filePath.includes('..') || filePath.startsWith('/')) {
        errorResponse(res, 400, '无效的文件路径');
        return;
      }

      // 检查是否启用了解密服务
      if (!pluginDataService) {
        errorResponse(res, 503, '解密服务未配置');
        return;
      }

      // 从请求头获取加密密钥
      const encryptionKey = req.headers['x-encryption-key'] as string | undefined;
      if (!encryptionKey || encryptionKey.length === 0) {
        errorResponse(res, 403, '请通过 X-Encryption-Key 请求头传递加密密钥');
        return;
      }

      const serverFile = await storageService.readEncryptedFile(userId, filePath);

      if (!serverFile) {
        res.status(404).json({
          success: false,
          error: '文件不存在',
          file_path: filePath,
        });
        return;
      }

      const encryptedData = serverFile.encrypted_data;
      if (!encryptedData) {
        errorResponse(res, 500, '文件数据为空');
        return;
      }

      const isBinary = serverFile.is_binary || false;

      // 记录拉取日志
      await storageService.logSync({
        userId,
        action: 'pull_decrypted',
        filePath,
      });

      // 根据文件类型选择不同的响应方式
      if (isBinary) {
        // 二进制文件：解密后直接返回原始字节
        const binaryData = pluginDataService.encryptionService.decryptBinary(
          encryptionKey,
          encryptedData,
        );

        // 根据文件扩展名确定 Content-Type
        const contentType = getContentType(filePath);

        res.setHeader('Content-Type', contentType);
        res.setHeader('Content-Length', binaryData.length.toString());
        res.setHeader('X-File-Path', filePath);
        res.setHeader('X-MD5', serverFile.md5);
        res.send(binaryData);
      } else {
        // 文本文件：解密为 JSON
        const decryptedData = pluginDataService.encryptionService.decryptData(
          encryptionKey,
          encryptedData,
        );

        res.json({
          success: true,
          file_path: filePath,
          data: decryptedData,
          md5: serverFile.md5,
          updated_at: serverFile.updated_at,
        });
      }
    } catch (e) {
      errorResponse(res, 500, `解密失败: ${e}`);
    }
  });

  /**
   * GET /info/* - 获取文件元信息
   */
  router.get('/info/*', async (req: Request, res: Response): Promise<void> => {
    const userId = getUserIdFromContext(req);
    if (!userId) {
      errorResponse(res, 401, '未授权');
      return;
    }

    try {
      const filePath = req.params[0] ? decodeFilePath(req.params[0]) : '';

      // 验证文件路径安全性
      if (filePath.includes('..') || filePath.startsWith('/')) {
        errorResponse(res, 400, '无效的文件路径');
        return;
      }

      const serverFile = await storageService.readEncryptedFile(userId, filePath);

      if (!serverFile) {
        res.json({
          success: true,
          exists: false,
          file_path: filePath,
        });
        return;
      }

      // 获取文件大小
      const userDir = storageService.getUserDir(userId);
      const fullPath = path.join(userDir, filePath);
      const fileSize = fs.existsSync(fullPath) ? fs.statSync(fullPath).size : 0;

      res.json({
        success: true,
        exists: true,
        file_path: filePath,
        md5: serverFile.md5,
        modified_at: serverFile.updated_at,
        size: fileSize,
      });
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  /**
   * GET /list - 列出用户文件
   */
  router.get('/list', async (req: Request, res: Response): Promise<void> => {
    const userId = getUserIdFromContext(req);
    if (!userId) {
      errorResponse(res, 401, '未授权');
      return;
    }

    try {
      // 获取可选的目录参数
      const directory = req.query.directory as string | undefined;

      // 验证目录路径安全性
      if (directory && (directory.includes('..') || directory.startsWith('/'))) {
        errorResponse(res, 400, '无效的目录路径');
        return;
      }

      const files = await storageService.listUserFiles(userId, directory);

      res.json({
        success: true,
        files: files.map(f => ({
          path: f.path,
          size: f.size,
          md5: f.md5,
          updated_at: f.updatedAt ? new Date(f.updatedAt).toISOString() : undefined,
          is_folder: f.isFolder,
        })),
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  /**
   * DELETE /delete/* - 删除文件
   */
  router.delete('/delete/*', async (req: Request, res: Response): Promise<void> => {
    const userId = getUserIdFromContext(req);
    if (!userId) {
      errorResponse(res, 401, '未授权');
      return;
    }

    try {
      const filePath = req.params[0] ? decodeFilePath(req.params[0]) : '';

      // 验证文件路径安全性
      if (filePath.includes('..') || filePath.startsWith('/')) {
        errorResponse(res, 400, '无效的文件路径');
        return;
      }

      const deleted = await storageService.deleteFile(userId, filePath);

      if (deleted) {
        // 记录删除日志
        await storageService.logSync({
          userId,
          action: 'delete',
          filePath,
        });

        res.json({
          success: true,
          file_path: filePath,
          timestamp: new Date().toISOString(),
        });
      } else {
        res.status(404).json({
          success: false,
          error: '文件不存在',
          file_path: filePath,
        });
      }
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  /**
   * GET /status - 同步状态
   */
  router.get('/status', async (req: Request, res: Response): Promise<void> => {
    const userId = getUserIdFromContext(req);
    if (!userId) {
      errorResponse(res, 401, '未授权');
      return;
    }

    try {
      const files = await storageService.listUserFiles(userId);
      const totalSize = await storageService.getUserDataSize(userId);

      res.json({
        success: true,
        user_id: userId,
        file_count: files.length,
        total_size_bytes: totalSize,
        total_size_mb: (totalSize / 1024 / 1024).toFixed(2),
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  /**
   * GET /tree - 目录树结构
   */
  router.get('/tree', async (req: Request, res: Response): Promise<void> => {
    const userId = getUserIdFromContext(req);
    if (!userId) {
      errorResponse(res, 401, '未授权');
      return;
    }

    try {
      const tree = await storageService.getDirectoryTree(userId);

      res.json({
        success: true,
        tree,
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  /**
   * POST /export - 导出 ZIP 文件
   */
  router.post('/export', async (req: Request, res: Response): Promise<void> => {
    const userId = getUserIdFromContext(req);
    if (!userId) {
      errorResponse(res, 401, '未授权');
      return;
    }

    try {
      const result = await storageService.exportUserDataAsZip(userId);

      // 记录导出日志
      await storageService.logSync({
        userId,
        action: 'export',
        filePath: result.fileName,
        details: `file_count: ${result.metadata.file_count}, total_size: ${result.metadata.total_size_bytes}`,
      });

      res.json(result);
    } catch (e) {
      errorResponse(res, 500, `导出失败: ${e}`);
    }
  });

  /**
   * GET /download/* - 下载导出文件
   */
  router.get('/download/*', async (req: Request, res: Response): Promise<void> => {
    const userId = getUserIdFromContext(req);
    if (!userId) {
      errorResponse(res, 401, '未授权');
      return;
    }

    try {
      const fileName = req.params[0] ? decodeFilePath(req.params[0]) : '';

      // 验证文件名安全性
      if (fileName.includes('..') || fileName.includes('/')) {
        errorResponse(res, 400, '无效的文件名');
        return;
      }

      const exportDir = storageService.getExportDir();
      const filePath = path.join(exportDir, fileName);

      if (!fs.existsSync(filePath)) {
        errorResponse(res, 404, '文件不存在');
        return;
      }

      // 记录下载日志
      await storageService.logSync({
        userId,
        action: 'download',
        filePath: fileName,
      });

      const stat = fs.statSync(filePath);
      res.setHeader('Content-Type', 'application/octet-stream');
      res.setHeader('Content-Disposition', `attachment; filename="${fileName}"`);
      res.setHeader('Content-Length', stat.size.toString());

      const fileStream = fs.createReadStream(filePath);
      fileStream.pipe(res);
    } catch (e) {
      errorResponse(res, 500, `下载失败: ${e}`);
    }
  });

  /**
   * GET /index - 获取完整文件索引
   */
  router.get('/index', async (req: Request, res: Response): Promise<void> => {
    const userId = getUserIdFromContext(req);
    if (!userId) {
      errorResponse(res, 401, '未授权');
      return;
    }

    try {
      const indexData = await storageService.getFileIndex(userId);
      const filesMap = indexData.files || {};

      // 转换为列表格式
      const files: Array<{
        path: string;
        md5: string;
        size: number;
        updated_at: string;
      }> = [];
      let totalSize = 0;

      for (const [path, fileInfo] of Object.entries(filesMap)) {
        files.push({
          path,
          md5: fileInfo.md5 || '',
          size: fileInfo.size || 0,
          updated_at: fileInfo.updatedAt || '',
        });
        totalSize += fileInfo.size || 0;
      }

      // 按路径排序
      files.sort((a, b) => a.path.localeCompare(b.path));

      res.json({
        success: true,
        index: {
          generated_at: indexData.updatedAt || new Date().toISOString(),
          files,
          total_files: files.length,
          total_size: totalSize,
        },
      });
    } catch (e) {
      errorResponse(res, 500, `获取文件索引失败: ${e}`);
    }
  });

  /**
   * POST /batch-delete - 批量删除文件
   */
  router.post('/batch-delete', async (req: Request, res: Response): Promise<void> => {
    const userId = getUserIdFromContext(req);
    if (!userId) {
      errorResponse(res, 401, '未授权');
      return;
    }

    try {
      const data = req.body;
      const filePaths: string[] = data.file_paths || [];

      if (filePaths.length === 0) {
        errorResponse(res, 400, '缺少 file_paths 参数');
        return;
      }

      let deletedCount = 0;
      const errors: string[] = [];
      const deletedPaths: string[] = [];

      for (const filePath of filePaths) {
        // 验证文件路径安全性
        if (filePath.includes('..') || filePath.startsWith('/')) {
          errors.push(`无效路径: ${filePath}`);
          continue;
        }

        try {
          const deleted = await storageService.deleteFile(userId, filePath);
          if (deleted) {
            deletedCount++;
            deletedPaths.push(filePath);
            // 记录删除日志
            await storageService.logSync({
              userId,
              action: 'batch_delete',
              filePath,
            });
          }
        } catch (e) {
          errors.push(`${filePath}: ${e}`);
        }
      }

      // 批量从索引中移除已删除的文件
      if (deletedPaths.length > 0) {
        await storageService.batchRemoveFromFileIndex(userId, deletedPaths);
      }

      res.json({
        success: true,
        deleted_count: deletedCount,
        total_requested: filePaths.length,
        errors: errors.length > 0 ? errors : undefined,
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      errorResponse(res, 500, `批量删除失败: ${e}`);
    }
  });

  return router;
}

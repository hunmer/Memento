import WebSocket from 'ws';
import { WSFileUpdate, WSMessage } from '../types';

/**
 * WebSocket 连接信息
 */
interface WebSocketConnection {
  userId: string;
  deviceId: string;
  ws: WebSocket;
  connectedAt: Date;
}

/**
 * 文件更新通知消息
 */
interface FileUpdateNotification {
  type: 'file_updated';
  data: {
    file_path: string;
    md5: string;
    modified_at: string;
    source_device_id: string;
  };
}

/**
 * WebSocket 连接管理器
 *
 * 负责:
 * - 管理客户端 WebSocket 连接
 * - 广播文件更新通知
 * - 连接生命周期管理
 */
export class WebSocketManager {
  /** 单例实例 */
  private static instance: WebSocketManager;

  /** userId -> deviceId -> WebSocketConnection */
  private connections: Map<string, Map<string, WebSocketConnection>> = new Map();

  /** 是否启用日志 */
  private enableLog: boolean = true;

  private constructor() {}

  static getInstance(): WebSocketManager {
    if (!WebSocketManager.instance) {
      WebSocketManager.instance = new WebSocketManager();
    }
    return WebSocketManager.instance;
  }

  /**
   * 获取连接数量
   */
  get connectionCount(): number {
    let count = 0;
    for (const userConnections of this.connections.values()) {
      count += userConnections.size;
    }
    return count;
  }

  /**
   * 获取用户连接数
   */
  getUserConnectionCount(userId: string): number {
    return this.connections.get(userId)?.size || 0;
  }

  /**
   * 注册 WebSocket 连接
   */
  registerChannel(
    userId: string,
    deviceId: string,
    ws: WebSocket,
  ): void {
    const connection: WebSocketConnection = {
      userId,
      deviceId,
      ws,
      connectedAt: new Date(),
    };

    if (!this.connections.has(userId)) {
      this.connections.set(userId, new Map());
    }
    this.connections.get(userId)!.set(deviceId, connection);

    this.log(
      `注册连接: userId=${userId}, deviceId=${deviceId}, 当前连接数: ${this.connectionCount}, 设备列表: ${Array.from(this.connections.get(userId)?.keys() || []).join(', ')}`,
    );

    // 设置消息处理
    ws.on('message', (data: Buffer) => {
      this.handleMessage(connection, data.toString());
    });

    ws.on('error', (error) => {
      this.log(`WebSocket 错误: userId=${userId}, deviceId=${deviceId}, error=${error}`);
      this.unregister(userId, deviceId);
    });

    ws.on('close', () => {
      this.log(`WebSocket 关闭: userId=${userId}, deviceId=${deviceId}`);
      this.unregister(userId, deviceId);
    });
  }

  /**
   * 注销 WebSocket 连接
   */
  unregister(userId: string, deviceId: string): void {
    const userConnections = this.connections.get(userId);
    if (!userConnections) return;

    const connection = userConnections.get(deviceId);
    if (connection) {
      this.log(
        `注销连接: userId=${userId}, deviceId=${deviceId}, 当前连接数: ${this.connectionCount}`,
      );
    }

    userConnections.delete(deviceId);

    // 如果用户没有连接了，移除用户条目
    if (userConnections.size === 0) {
      this.connections.delete(userId);
    }
  }

  /**
   * 处理客户端消息
   */
  private handleMessage(connection: WebSocketConnection, message: string): void {
    try {
      const data = JSON.parse(message) as WSMessage;
      const type = data.type;

      switch (type) {
        case 'ping':
          // 心跳响应
          this.sendMessage(connection.ws, { type: 'pong' });
          break;
        case 'ack':
          // 确认消息，记录日志
          this.log(
            `收到确认: userId=${connection.userId}, deviceId=${connection.deviceId}`,
          );
          break;
        default:
          this.log(`未知消息类型: ${type}`);
      }
    } catch (e) {
      this.log(`处理消息错误: ${e}`);
    }
  }

  /**
   * 发送消息
   */
  private sendMessage(ws: WebSocket, message: object): void {
    try {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify(message));
      }
    } catch (e) {
      this.log(`发送消息失败: ${e}`);
    }
  }

  /**
   * 广播文件更新通知
   * @param userId 用户ID
   * @param filePath 文件路径
   * @param md5 文件 MD5
   * @param modifiedAt 修改时间
   * @param sourceDeviceId 触发更新的设备ID（不会被通知），为空表示广播给所有设备
   */
  broadcastFileUpdate(
    userId: string,
    filePath: string,
    md5: string,
    modifiedAt: Date,
    sourceDeviceId: string,
  ): void {
    const userConnections = this.connections.get(userId);
    if (!userConnections || userConnections.size === 0) {
      this.log(`用户无在线连接，跳过广播: userId=${userId}`);
      return;
    }

    this.log(
      `准备广播: userId=${userId}, 连接数=${userConnections.size}, 设备列表=${Array.from(userConnections.keys()).join(',')}, sourceDeviceId=${sourceDeviceId}`,
    );

    const notification: FileUpdateNotification = {
      type: 'file_updated',
      data: {
        file_path: filePath,
        md5,
        modified_at: modifiedAt.toISOString(),
        source_device_id: sourceDeviceId,
      },
    };

    const message = JSON.stringify(notification);
    let sentCount = 0;

    for (const [deviceId, connection] of userConnections) {
      // 排除源设备（不回发给触发更新的设备）
      // 只有当 sourceDeviceId 非空且匹配时才跳过
      if (sourceDeviceId && deviceId === sourceDeviceId) {
        this.log(`跳过源设备: deviceId=${deviceId}`);
        continue;
      }

      try {
        if (connection.ws.readyState === WebSocket.OPEN) {
          connection.ws.send(message);
          sentCount++;
        }
      } catch (e) {
        this.log(`广播失败: userId=${userId}, deviceId=${deviceId}, error=${e}`);
        // 发送失败，移除连接
        this.unregister(userId, deviceId);
      }
    }

    this.log(`广播文件更新: filePath=${filePath}, 发送给 ${sentCount} 个设备`);
  }

  /**
   * 广播给用户所有设备（包括源设备）
   */
  broadcastToAllDevices(userId: string, message: object): void {
    const userConnections = this.connections.get(userId);
    if (!userConnections || userConnections.size === 0) return;

    const messageStr = JSON.stringify(message);

    for (const connection of userConnections.values()) {
      try {
        if (connection.ws.readyState === WebSocket.OPEN) {
          connection.ws.send(messageStr);
        }
      } catch (e) {
        this.log(
          `广播失败: userId=${userId}, deviceId=${connection.deviceId}, error=${e}`,
        );
        this.unregister(userId, connection.deviceId);
      }
    }
  }

  /**
   * 检查用户是否有在线连接
   */
  isUserOnline(userId: string): boolean {
    const userConnections = this.connections.get(userId);
    return userConnections !== undefined && userConnections.size > 0;
  }

  /**
   * 检查用户特定设备是否在线
   */
  isDeviceOnline(userId: string, deviceId: string): boolean {
    return this.connections.get(userId)?.has(deviceId) || false;
  }

  /**
   * 获取用户所有在线设备
   */
  getOnlineDevices(userId: string): string[] {
    return Array.from(this.connections.get(userId)?.keys() || []);
  }

  /**
   * 关闭所有连接
   */
  async closeAll(): Promise<void> {
    this.log('关闭所有 WebSocket 连接...');

    for (const userConnections of this.connections.values()) {
      for (const connection of userConnections.values()) {
        try {
          connection.ws.close();
        } catch (e) {
          // 忽略关闭错误
        }
      }
    }

    this.connections.clear();
    this.log('所有连接已关闭');
  }

  /**
   * 输出日志
   */
  private log(message: string): void {
    if (this.enableLog) {
      console.log(`[WebSocketManager] ${message}`);
    }
  }

  /**
   * 设置日志开关
   */
  setLogEnabled(enabled: boolean): void {
    this.enableLog = enabled;
  }
}

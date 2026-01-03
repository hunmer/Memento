/**
 * WebSocket 服务器实现
 */

import { WebSocketServer as WSServer } from 'ws';
import { SessionManager } from './session';
import { AuthMessage, ApiRequestMessage, ApiResponseMessage, BaseMessage, ExtendedWebSocket } from './types';

export class WebSocketServer {
  private wss?: WSServer;
  private sessionManager = new SessionManager();

  constructor(private port: number) {}

  /**
   * 启动服务器
   */
  async start(): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        this.wss = new WSServer({ port: this.port });

        this.wss.on('connection', (ws: any, req: any) => {
          const extendedWs = ws as ExtendedWebSocket;
          const clientIp = req.socket.remoteAddress;
          console.log(`[服务器] 新连接来自: ${clientIp}`);

          // 消息处理器
          ws.on('message', (data: Buffer) => {
            this.handleMessage(extendedWs, data);
          });

          // 连接关闭
          ws.on('close', () => {
            console.log(`[服务器] 连接已关闭: ${clientIp}`);
            this.sessionManager.handleDisconnect(extendedWs);
          });

          // 错误处理
          ws.on('error', (error: any) => {
            console.error(`[服务器] 连接错误: ${clientIp}`, error);
          });
        });

        this.wss.on('listening', () => {
          console.log(`[服务器] 监听端口: ${this.port}`);
          resolve();
        });

        this.wss.on('error', (error) => {
          reject(error);
        });

      } catch (error) {
        reject(error);
      }
    });
  }

  /**
   * 停止服务器
   */
  stop(): void {
    this.sessionManager.clear();
    this.wss?.close();
  }

  /**
   * 处理收到的消息
   */
  private handleMessage(ws: ExtendedWebSocket, data: Buffer): void {
    try {
      const message: BaseMessage = JSON.parse(data.toString());

      switch (message.type) {
        case 'auth':
          this.sessionManager.handleAuth(ws, message as AuthMessage);
          break;

        case 'request':
          this.sessionManager.handleRequest(ws, message as ApiRequestMessage);
          break;

        case 'response':
          this.sessionManager.handleResponse(ws, message as ApiResponseMessage);
          break;

        case 'ping':
          this.sendPong(ws, message.id);
          break;

        default:
          console.warn(`[服务器] 未知消息类型: ${message.type}`);
      }
    } catch (error) {
      console.error('[服务器] 处理消息失败:', error);
      this.sessionManager.sendError(ws, 'PARSE_ERROR', '无法解析消息');
    }
  }

  /**
   * 发送 Pong 响应
   */
  private sendPong(ws: ExtendedWebSocket, messageId: string): void {
    const pong = {
      type: 'pong',
      id: messageId,
      timestamp: Date.now(),
    };
    ws.send(JSON.stringify(pong));
  }
}

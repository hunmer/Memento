/**
 * 会话管理器 - 处理配对和消息路由
 */

import { WebSocket } from 'ws';
import { v4 as uuidv4 } from 'uuid';
import { AuthMessage, ApiRequestMessage, ApiResponseMessage, ExtendedWebSocket } from './types';

interface Session {
  id: string;
  pairingKey: string;
  frontend: ExtendedWebSocket;
  client: ExtendedWebSocket;
  createdAt: number;
  lastActivity: number;
}

interface PendingConnection {
  ws: ExtendedWebSocket;
  role: 'frontend' | 'client';
  connectedAt: number;
  timeout: NodeJS.Timeout;
}

export class SessionManager {
  private sessions = new Map<string, Session>();
  private pending = new Map<string, PendingConnection>();
  private connectionToSession = new Map<any, string>();

  /**
   * 处理认证请求
   */
  handleAuth(ws: ExtendedWebSocket, message: AuthMessage): void {
    const { pairingKey, role } = message;
    console.log(`[会话] 认证请求: ${role}, key: ${pairingKey}`);

    // 检查是否有待匹配的连接
    const existing = this.pending.get(pairingKey);

    if (!existing) {
      // 第一个连接，等待匹配（无限期等待，不设置超时）
      this.pending.set(pairingKey, {
        ws,
        role,
        connectedAt: Date.now(),
        timeout: undefined as any, // 不设置超时
      });

      this.sendAuthResponse(ws, message.id, true, '等待对端连接...');
      return;
    }

    // 第二个连接，进行匹配
    if (existing.role === role) {
      this.sendAuthResponse(ws, message.id, false, '相同角色的连接已存在');
      ws.close();
      return;
    }

    // 配对成功
    if (existing.timeout) {
      clearTimeout(existing.timeout);
    }
    this.pending.delete(pairingKey);

    // 创建会话
    const sessionId = uuidv4();
    const session: Session = {
      id: sessionId,
      pairingKey,
      frontend: role === 'frontend' ? ws : existing.ws,
      client: role === 'client' ? ws : existing.ws,
      createdAt: Date.now(),
      lastActivity: Date.now(),
    };

    this.sessions.set(sessionId, session);
    this.connectionToSession.set(session.frontend, sessionId);
    this.connectionToSession.set(session.client, sessionId);

    // 标记连接
    session.frontend.sessionId = sessionId;
    session.frontend.role = 'frontend';
    session.client.sessionId = sessionId;
    session.client.role = 'client';

    // 通知双方
    this.sendAuthResponse(session.frontend, message.id, true, '配对成功', {
      role: 'client',
      connectedAt: session.createdAt,
    });

    this.sendAuthResponse(session.client, message.id, true, '配对成功', {
      role: 'frontend',
      connectedAt: session.createdAt,
    });

    console.log(`[会话] 新会话创建: ${sessionId}`);
  }

  /**
   * 处理 API 请求
   */
  handleRequest(ws: ExtendedWebSocket, message: ApiRequestMessage): void {
    const sessionId = this.connectionToSession.get(ws);
    if (!sessionId) {
      this.sendError(ws, 'NOT_AUTHENTICATED', '未认证的连接');
      return;
    }

    const session = this.sessions.get(sessionId);
    if (!session) {
      this.sendError(ws, 'SESSION_NOT_FOUND', '会话不存在');
      return;
    }

    // 更新活动时间
    session.lastActivity = Date.now();

    // 确定目标连接
    const targetWs = ws === session.frontend ? session.client : session.frontend;

    // 转发请求
    targetWs.send(JSON.stringify(message));

    console.log(`[会话] ${sessionId}: 转发请求 ${message.requestId} -> ${message.pluginId}.${message.methodName}`);
  }

  /**
   * 处理 API 响应
   */
  handleResponse(ws: ExtendedWebSocket, message: ApiResponseMessage): void {
    const sessionId = this.connectionToSession.get(ws);
    if (!sessionId) {
      console.warn('[会话] 收到响应但连接未认证');
      return;
    }

    const session = this.sessions.get(sessionId);
    if (!session) {
      console.warn('[会话] 收到响应但会话不存在');
      return;
    }

    // 确定目标连接（与请求相反的方向）
    const targetWs = ws === session.frontend ? session.client : session.frontend;

    // 转发响应
    targetWs.send(JSON.stringify(message));

    console.log(`[会话] ${sessionId}: 转发响应 ${message.requestId} -> ${message.success ? '成功' : '失败'}`);
  }

  /**
   * 处理连接断开
   */
  handleDisconnect(ws: ExtendedWebSocket): void {
    const sessionId = this.connectionToSession.get(ws);
    if (!sessionId) return;

    this.connectionToSession.delete(ws);

    const session = this.sessions.get(sessionId);
    if (!session) return;

    // 通知对端
    const peerWs = ws === session.frontend ? session.client : session.frontend;
    if (peerWs.readyState === WebSocket.OPEN) {
      this.sendError(peerWs, 'PEER_DISCONNECTED', '对端已断开连接');
      peerWs.close();
    }

    // 清理会话
    this.sessions.delete(sessionId);
    console.log(`[会话] 会话已关闭: ${sessionId}`);
  }

  /**
   * 清除所有会话
   */
  clear(): void {
    // 清理所有待匹配连接
    this.pending.forEach(({ timeout }) => {
      if (timeout) clearTimeout(timeout);
    });
    this.pending.clear();

    // 关闭所有会话
    this.sessions.forEach(({ frontend, client }) => {
      frontend.close();
      client.close();
    });
    this.sessions.clear();
    this.connectionToSession.clear();
  }


  /**
   * 发送认证响应
   */
  private sendAuthResponse(
    ws: ExtendedWebSocket,
    messageId: string,
    success: boolean,
    message: string,
    matchedPeer?: any
  ): void {
    const response = {
      type: 'response',
      id: messageId,
      timestamp: Date.now(),
      success,
      message,
      ...(matchedPeer && { matchedPeer }),
    };
    ws.send(JSON.stringify(response));
  }

  /**
   * 发送错误消息
   */
  sendError(ws: ExtendedWebSocket, code: string, message: string): void {
    const error = {
      type: 'error',
      id: this.generateId(),
      timestamp: Date.now(),
      code,
      message,
    };
    ws.send(JSON.stringify(error));
  }

  /**
   * 生成消息 ID
   */
  private generateId(): string {
    return `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}

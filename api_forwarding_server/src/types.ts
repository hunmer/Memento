/**
 * 消息协议类型定义
 */

export interface BaseMessage {
  type: 'auth' | 'request' | 'response' | 'error' | 'ping' | 'pong';
  id: string;
  timestamp: number;
}

export interface AuthMessage extends BaseMessage {
  type: 'auth';
  role: 'frontend' | 'client';
  pairingKey: string;
  clientInfo?: {
    platform: string;
    version: string;
    deviceId: string;
    deviceName?: string;
  };
}

export interface ApiRequestMessage extends BaseMessage {
  type: 'request';
  pluginId: string;
  methodName: string;
  params: any;
  requestId: string;
}

export interface ApiResponseMessage extends BaseMessage {
  type: 'response';
  requestId: string;
  success: boolean;
  result?: any;
  error?: {
    code: string;
    message: string;
    stack?: string;
  };
}

export interface ErrorMessage extends BaseMessage {
  type: 'error';
  code: string;
  message: string;
  details?: any;
}

export interface PingMessage extends BaseMessage {
  type: 'ping';
}

export interface PongMessage extends BaseMessage {
  type: 'pong';
}

import { WebSocket as WebSocketBase } from 'ws';

// WebSocket 扩展，添加自定义属性
export interface ExtendedWebSocket extends WebSocketBase {
  isAlive?: boolean;
  sessionId?: string;
  role?: 'frontend' | 'client';
}

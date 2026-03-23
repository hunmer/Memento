import admin from 'firebase-admin';
import path from 'path';
import fs from 'fs';
import crypto from 'crypto';
import { HttpsProxyAgent } from 'https-proxy-agent';
import https from 'https';

let firebaseApp: admin.app.App | null = null;
let cachedServiceAccount: any = null;
let cachedProjectId: string | null = null;
let cachedAccessToken: string | null = null;
let tokenExpiry: number = 0;

// 代理配置
const proxy = process.env.HTTPS_PROXY || process.env.HTTP_PROXY || 'http://127.0.0.1:7890';
const proxyAgent = new HttpsProxyAgent(proxy);

export interface FcmMessageResult {
  success: boolean;
  messageId?: string;
  error?: string;
}

export interface FcmSendResult {
  success: number;
  failure: number;
  results: FcmMessageResult[];
}

/**
 * 初始化 Firebase Admin SDK
 */
async function initializeFirebase(): Promise<string> {
  console.log(`[FCM] initializeFirebase 检查: firebaseApp=${typeof firebaseApp}, cachedProjectId=${cachedProjectId}`);

  if (firebaseApp && cachedServiceAccount && cachedProjectId) {
    console.log('[FCM] 使用缓存的 Firebase App');
    return cachedProjectId;
  }

  const serviceAccountPath = path.join(process.cwd(), 'service-account.json');

  console.log(`[FCM] 当前工作目录: ${process.cwd()}`);
  console.log(`[FCM] Service Account 路径: ${serviceAccountPath}`);
  console.log(`[FCM] 代理配置: ${proxy}`);

  if (!fs.existsSync(serviceAccountPath)) {
    throw new Error(`service-account.json 文件不存在: ${serviceAccountPath}`);
  }

  cachedServiceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf-8'));

  firebaseApp = admin.initializeApp({
    credential: admin.credential.cert(cachedServiceAccount),
  });

  cachedProjectId = cachedServiceAccount.project_id;
  console.log('[FCM] Firebase Admin SDK 初始化成功');
  console.log(`[FCM] firebaseApp 类型: ${typeof firebaseApp}, projectId: ${cachedProjectId}`);

  return cachedProjectId;
}

/**
 * 使用 JWT 签名获取 OAuth2 access token（通过代理）
 */
async function getAccessToken(): Promise<string> {
  // 如果 token 还有效（提前 5 分钟刷新），直接返回
  if (cachedAccessToken && Date.now() < tokenExpiry - 5 * 60 * 1000) {
    console.log('[FCM] 使用缓存的 access token');
    return cachedAccessToken;
  }

  console.log('[FCM] 获取新的 access token...');

  if (!cachedServiceAccount) {
    throw new Error('Service account not initialized');
  }

  // 创建 JWT
  const now = Math.floor(Date.now() / 1000);
  const jwtHeader = {
    alg: 'RS256',
    typ: 'JWT',
  };

  const jwtPayload = {
    iss: cachedServiceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };

  // Base64 编码
  const base64Header = Buffer.from(JSON.stringify(jwtHeader)).toString('base64url');
  const base64Payload = Buffer.from(JSON.stringify(jwtPayload)).toString('base64url');
  const signatureInput = `${base64Header}.${base64Payload}`;

  // 使用私钥签名
  const sign = crypto.createSign('RSA-SHA256');
  sign.update(signatureInput);
  const signature = sign.sign(cachedServiceAccount.private_key, 'base64url');

  const jwt = `${signatureInput}.${signature}`;

  // 请求 access token
  return new Promise((resolve, reject) => {
    const postData = `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`;

    const req = https.request({
      host: 'oauth2.googleapis.com',
      port: 443,
      path: '/token',
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': Buffer.byteLength(postData),
      },
      agent: proxyAgent,
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          if (res.statusCode === 200) {
            const response = JSON.parse(data);
            cachedAccessToken = response.access_token;
            tokenExpiry = Date.now() + response.expires_in * 1000;
            console.log('[FCM] Access token 获取成功');
            resolve(cachedAccessToken!);
          } else {
            console.error(`[FCM] Token 请求失败: ${res.statusCode} ${data}`);
            reject(new Error(`Token request failed: ${res.statusCode}`));
          }
        } catch (err) {
          reject(err);
        }
      });
    });

    req.on('error', (err) => {
      console.error(`[FCM] Token 请求错误: ${err.message}`);
      reject(err);
    });

    req.write(postData);
    req.end();
  });
}

/**
 * 通过 FCM HTTP v1 API 发送单条消息
 * v1 API 支持 OAuth token，可以通过 HTTP 代理
 */
async function sendViaV1Api(projectId: string, message: any): Promise<{ success: boolean; messageId?: string; error?: string }> {
  console.log(`[FCM] sendViaV1Api 开始发送...`);

  try {
    const token = await getAccessToken();
    const messageData = JSON.stringify(message);

    return new Promise((resolve) => {
      const req = https.request({
        host: 'fcm.googleapis.com',
        port: 443,
        path: `/v1/projects/${projectId}/messages:send`,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(messageData),
          'Authorization': `Bearer ${token}`,
        },
        agent: proxyAgent,
      }, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          console.log(`[FCM] 响应状态码: ${res.statusCode}`);
          console.log(`[FCM] 响应内容: ${data}`);
          if (res.statusCode === 200) {
            const response = JSON.parse(data);
            resolve({ success: true, messageId: response.name });
          } else {
            try {
              const error = JSON.parse(data);
              resolve({ success: false, error: error.error?.message || `HTTP ${res.statusCode}` });
            } catch {
              resolve({ success: false, error: `HTTP ${res.statusCode}: ${data}` });
            }
          }
        });
      });

      req.on('error', (err) => {
        console.error(`[FCM] 请求错误: ${err.message}`);
        resolve({ success: false, error: err.message });
      });

      req.write(messageData);
      req.end();
    });
  } catch (error) {
    const errorMsg = error instanceof Error ? error.message : String(error);
    console.error(`[FCM] sendViaV1Api 错误: ${errorMsg}`);
    return { success: false, error: errorMsg };
  }
}

/**
 * 发送消息到指定设备
 */
export async function sendToDevice(
  token: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<FcmMessageResult> {
  console.log(`[FCM] sendToDevice 开始, token: ${token.substring(0, 20)}...`);

  try {
    const projectId = await initializeFirebase();
    console.log('[FCM] Firebase 初始化完成，开始发送消息...');

    const message = {
      message: {
        token,
        notification: { title, body },
        data: data || {},
      },
    };

    const result = await sendViaV1Api(projectId, message);

    if (result.success) {
      console.log(`[FCM] 消息发送成功: ${result.messageId}`);
      return { success: true, messageId: result.messageId };
    } else {
      console.error(`[FCM] 消息发送失败: ${result.error}`);
      return { success: false, error: result.error };
    }
  } catch (error) {
    const errorMsg = error instanceof Error ? error.message : String(error);
    console.error(`[FCM] 消息发送失败: ${errorMsg}`);
    return { success: false, error: errorMsg };
  }
}

/**
 * 批量发送消息到多个设备
 * v1 API 需要逐条发送
 */
export async function sendMulticast(
  tokens: string[],
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<FcmSendResult> {
  console.log(`[FCM] sendMulticast 开始, tokens 数量: ${tokens.length}`);

  try {
    const projectId = await initializeFirebase();
    console.log('[FCM] Firebase 初始化完成，开始发送批量消息...');

    const results: FcmMessageResult[] = [];
    let successCount = 0;
    let failureCount = 0;

    // v1 API 需要逐条发送
    for (let i = 0; i < tokens.length; i++) {
      const token = tokens[i];

      const message = {
        message: {
          token,
          notification: { title, body },
          data: data || {},
        },
      };

      const result = await sendViaV1Api(projectId, message);

      if (result.success) {
        successCount++;
        results.push({ success: true, messageId: result.messageId });
      } else {
        failureCount++;
        results.push({ success: false, error: result.error });
        console.error(`[FCM] Token ${i} 失败: ${result.error}`);
      }

      // 每 100 条打印进度
      if ((i + 1) % 100 === 0) {
        console.log(`[FCM] 进度: ${i + 1}/${tokens.length}`);
      }
    }

    console.log(`[FCM] 批量消息发送完成: 成功 ${successCount}, 失败 ${failureCount}`);
    return { success: successCount, failure: failureCount, results };
  } catch (error) {
    const errorMsg = error instanceof Error ? error.message : String(error);
    console.error(`[FCM] 批量消息发送失败: ${errorMsg}`);
    return {
      success: 0,
      failure: tokens.length,
      results: tokens.map(() => ({ success: false, error: errorMsg })),
    };
  }
}

/**
 * 发送消息到主题
 */
export async function sendToTopic(
  topic: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<FcmMessageResult> {
  console.log(`[FCM] sendToTopic 开始, topic: ${topic}`);

  try {
    const projectId = await initializeFirebase();
    console.log('[FCM] Firebase 初始化完成，开始发送主题消息...');

    const message = {
      message: {
        topic,
        notification: { title, body },
        data: data || {},
      },
    };

    const result = await sendViaV1Api(projectId, message);

    if (result.success) {
      console.log(`[FCM] 主题消息发送成功: ${topic} -> ${result.messageId}`);
      return { success: true, messageId: result.messageId };
    } else {
      console.error(`[FCM] 主题消息发送失败: ${result.error}`);
      return { success: false, error: result.error };
    }
  } catch (error) {
    const errorMsg = error instanceof Error ? error.message : String(error);
    console.error(`[FCM] 主题消息发送失败: ${errorMsg}`);
    return { success: false, error: errorMsg };
  }
}

export default {
  sendToDevice,
  sendMulticast,
  sendToTopic,
};

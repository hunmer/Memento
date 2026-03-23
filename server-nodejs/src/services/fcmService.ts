import admin from 'firebase-admin';
import path from 'path';
import fs from 'fs';
import { HttpsProxyAgent } from 'https-proxy-agent';

let firebaseApp: admin.app.App | null = null;
let cachedCredential: admin.credential.Credential | null = null;
let cachedProjectId: string | null = null;

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
  console.log(`[FCM] initializeFirebase 检查: firebaseApp=${typeof firebaseApp}, cachedCredential=${typeof cachedCredential}, cachedProjectId=${cachedProjectId}`);

  if (firebaseApp && cachedCredential && cachedProjectId) {
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

  const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf-8'));
  const credential = admin.credential.cert(serviceAccount);

  firebaseApp = admin.initializeApp({
    credential,
  });

  cachedCredential = credential;
  cachedProjectId = serviceAccount.project_id;
  console.log('[FCM] Firebase Admin SDK 初始化成功');
  console.log(`[FCM] firebaseApp 类型: ${typeof firebaseApp}, projectId: ${cachedProjectId}`);

  return cachedProjectId;
}

/**
 * 通过 FCM HTTP v1 API 发送单条消息
 * v1 API 支持 OAuth token，可以通过 HTTP 代理
 */
async function sendViaV1Api(projectId: string, message: any): Promise<{ success: boolean; messageId?: string; error?: string }> {
  const https = await import('https');

  console.log(`[FCM] sendViaV1Api firebaseApp状态: ${typeof firebaseApp}, ${firebaseApp ? '有值' : '为空'}`);

  // 获取 access token - 使用缓存的 credential
  if (!cachedCredential) {
    console.error(`[FCM] Credential 未初始化`);
    return { success: false, error: 'Firebase credential not initialized' };
  }
  const accessToken = await cachedCredential.getAccessToken();
  const token = accessToken.access_token;

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
        if (res.statusCode === 200) {
          const response = JSON.parse(data);
          resolve({ success: true, messageId: response.name });
        } else {
          try {
            const error = JSON.parse(data);
            resolve({ success: false, error: error.error?.message || `HTTP ${res.statusCode}` });
          } catch {
            resolve({ success: false, error: `HTTP ${res.statusCode}` });
          }
        }
      });
    });

    req.on('error', (err) => {
      resolve({ success: false, error: err.message });
    });

    req.write(messageData);
    req.end();
  });
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

    console.log(`[FCM] firebaseApp 状态: ${firebaseApp ? '已初始化' : '未初始化'}`);
    console.log(`[FCM] projectId: ${projectId}`);

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
    const errorStack = error instanceof Error ? error.stack : '';
    console.error(`[FCM] 消息发送失败: ${errorMsg}`);
    console.error(`[FCM] 错误堆栈: ${errorStack}`);
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

    console.log(`[FCM] firebaseApp 状态: ${firebaseApp ? '已初始化' : '未初始化'}`);
    console.log(`[FCM] projectId: ${projectId}`);

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
    const errorStack = error instanceof Error ? error.stack : '';
    console.error(`[FCM] 批量消息发送失败: ${errorMsg}`);
    console.error(`[FCM] 错误堆栈: ${errorStack}`);
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

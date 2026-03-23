import admin from 'firebase-admin';
import path from 'path';
import fs from 'fs';
// @ts-ignore
import tunnel from 'tunnel';

let firebaseApp: admin.app.App | null = null;

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
function initializeFirebase(): admin.app.App {
  if (firebaseApp) {
    return firebaseApp;
  }

  // 读取 service account 文件
  const serviceAccountPath = path.join(process.cwd(), 'service-account.json');

  if (!fs.existsSync(serviceAccountPath)) {
    throw new Error('service-account.json 文件不存在');
  }

  const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf-8'));

  // 配置代理
  const proxyUrl = process.env.HTTP_PROXY || process.env.HTTPS_PROXY || 'http://127.0.0.1:7890';
  const proxyUrlObj = new URL(proxyUrl);

  const proxyAgent = tunnel.httpsOverHttp({
    proxy: {
      host: proxyUrlObj.hostname,
      port: parseInt(proxyUrlObj.port) || 8080,
    },
  });

  console.log(`[FCM] 代理配置: ${proxyUrl} -> ${proxyUrlObj.hostname}:${proxyUrlObj.port}`);

  firebaseApp = admin.initializeApp({
    credential: admin.credential.cert(serviceAccount, proxyAgent as any),
    httpAgent: proxyAgent as any,
  });

  console.log(`[FCM] Firebase Admin SDK 初始化成功 (代理: 已配置)`);
  return firebaseApp;
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
  try {
    initializeFirebase();

    const message: admin.messaging.Message = {
      notification: {
        title,
        body,
      },
      data: data || {},
      token,
    };

    const messageId = await admin.messaging().send(message);
    console.log(`[FCM] 消息发送成功: ${token.substring(0, 20)}... -> ${messageId}`);

    return { success: true, messageId };
  } catch (error) {
    const errorMsg = error instanceof Error ? error.message : String(error);
    console.error(`[FCM] 消息发送失败: ${token.substring(0, 20)}...`, errorMsg);
    return { success: false, error: errorMsg };
  }
}

/**
 * 批量发送消息到多个设备
 */
export async function sendMulticast(
  tokens: string[],
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<FcmSendResult> {
  try {
    initializeFirebase();

    const message: admin.messaging.MulticastMessage = {
      notification: {
        title,
        body,
      },
      data: data || {},
      tokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);

    const results: FcmMessageResult[] = response.responses.map((res) => ({
      success: res.success,
      messageId: res.messageId,
      error: res.error?.message,
    }));

    console.log(`[FCM] 批量消息发送完成: 成功 ${response.successCount}, 失败 ${response.failureCount}`);

    return {
      success: response.successCount,
      failure: response.failureCount,
      results,
    };
  } catch (error) {
    const errorMsg = error instanceof Error ? error.message : String(error);
    console.error('[FCM] 批量消息发送失败:', errorMsg);
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
  try {
    initializeFirebase();

    const message: admin.messaging.Message = {
      notification: {
        title,
        body,
      },
      data: data || {},
      topic,
    };

    const messageId = await admin.messaging().send(message);
    console.log(`[FCM] 主题消息发送成功: ${topic} -> ${messageId}`);

    return { success: true, messageId };
  } catch (error) {
    const errorMsg = error instanceof Error ? error.message : String(error);
    console.error(`[FCM] 主题消息发送失败: ${topic}`, errorMsg);
    return { success: false, error: errorMsg };
  }
}

export default {
  sendToDevice,
  sendMulticast,
  sendToTopic,
};

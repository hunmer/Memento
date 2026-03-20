import { ChildProcess, spawn } from 'child_process';
import path from 'path';

let serverProcess: ChildProcess | null = null;

/**
 * Jest 全局设置 - 启动测试服务器
 */
export default async function globalSetup() {
  console.log('正在启动测试服务器...');

  const testEnv = {
    ...process.env,
    PORT: '8874',
    DATA_DIR: path.join(__dirname, 'test_data'),
    JWT_SECRET: 'test-jwt-secret-key-for-testing',
    ENABLE_LOGGING: 'false',
  };

  // 使用 ts-node 运行服务器
  serverProcess = spawn('npx', ['ts-node', 'src/index.ts'], {
    cwd: path.join(__dirname, '..'),
    env: testEnv,
    stdio: ['ignore', 'pipe', 'pipe'],
    shell: true,
  });

  // 保存进程引用供 teardown 使用
  (global as any).__TEST_SERVER__ = serverProcess;

  // 等待服务器启动
  await new Promise<void>((resolve, reject) => {
    const timeout = setTimeout(() => {
      reject(new Error('服务器启动超时'));
    }, 30000);

    serverProcess!.stdout?.on('data', (data) => {
      const output = data.toString();
      if (output.includes('服务器启动成功')) {
        clearTimeout(timeout);
        console.log('测试服务器已启动');
        resolve();
      }
    });

    serverProcess!.stderr?.on('data', (data) => {
      console.error('服务器错误:', data.toString());
    });

    serverProcess!.on('error', (error) => {
      clearTimeout(timeout);
      reject(error);
    });
  });
}

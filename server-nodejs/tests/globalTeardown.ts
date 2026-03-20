import { ChildProcess } from 'child_process';

/**
 * Jest 全局清理 - 关闭测试服务器
 */
export default async function globalTeardown() {
  console.log('正在关闭测试服务器...');

  const serverProcess = (global as any).__TEST_SERVER__ as ChildProcess | undefined;

  if (serverProcess) {
    // Windows 需要 taskkill 来强制结束进程树
    if (process.platform === 'win32') {
      const { exec } = require('child_process');
      exec(`taskkill /pid ${serverProcess.pid} /T /F`, () => {
        console.log('测试服务器已关闭');
      });
    } else {
      serverProcess.kill('SIGTERM');
      console.log('测试服务器已关闭');
    }
  }
}

import vue from '@vitejs/plugin-vue'
import vueDevTools from 'vite-plugin-vue-devtools'
import { defineConfig } from 'vite'
import { resolve } from 'node:path'
import { existsSync } from 'node:fs'

// 获取编辑器配置
function getEditor() {
  const editor = process.env.VUE_EDITOR || 'code'

  // 在 Windows 上，如果是 code/vscode，尝试找到完整路径
  if (process.platform === 'win32' && (editor === 'code' || editor === 'vscode')) {
    const possiblePaths = [
      resolve(process.env.USERPROFILE || '', 'AppData/Local/Programs/Microsoft VS Code/bin/code.cmd'),
      resolve('C:/Program Files/Microsoft VS Code/bin/code.cmd'),
      resolve('C:/Program Files (x86)/Microsoft VS Code/bin/code.cmd')
    ]

    for (const path of possiblePaths) {
      if (existsSync(path)) {
        return path
      }
    }
  }

  return editor
}

export default defineConfig(({ command }) => {
  const isProduction = command === 'build'

  return {
    plugins: [vue(),
    // 只在开发环境启用 Vue DevTools
    ...(isProduction ? [] : [vueDevTools({
      launchEditor: getEditor()
    })]),],
    resolve: {
      alias: {
        '@': resolve(__dirname, 'src')
      }
    },
    server: {
      port: 3000,
      proxy: {
        '/api': {
          target: 'http://localhost:8874',
          changeOrigin: true
        },
        '/health': {
          target: 'http://localhost:8874',
          changeOrigin: true
        }
      }
    },
    build: {
      outDir: '../admin',
      emptyOutDir: true,
      assetsDir: 'assets'
    }
  }
});


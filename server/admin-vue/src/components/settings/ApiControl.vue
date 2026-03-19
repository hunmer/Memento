<script setup lang="ts">
import { ref } from 'vue'
import {
  NCard,
  NSpace,
  NButton,
  NTag,
  NAlert,
  NInput,
  NInputGroup,
  useDialog,
  useMessage
} from 'naive-ui'
import { useAuthStore } from '@/stores/auth'
import { useUIStore } from '@/stores/ui'
import { authApi } from '@/api'

const authStore = useAuthStore()
const uiStore = useUIStore()
const dialog = useDialog()
const message = useMessage()

const showKeyInput = ref(false)
const newKey = ref('')
const savingKey = ref(false)

async function handleEnableApi(): Promise<void> {
  showKeyInput.value = true
}

async function handleSaveKey(): Promise<void> {
  const key = newKey.value.trim()

  // 验证密钥格式
  if (!/^[A-Za-z0-9+/]+=*$/.test(key)) {
    message.error('加密密钥格式无效，应为 Base64 编码')
    return
  }

  if (key.length < 40) {
    message.error('加密密钥长度不足，标准长度为 44 个字符')
    return
  }

  savingKey.value = true
  try {
    await authApi.setEncryptionKey(key)
    authStore.setEncryptionKey(key)
    showKeyInput.value = false
    newKey.value = ''
    message.success('加密密钥已设置')
    uiStore.addActivity('settings', '设置了加密密钥')
  } catch (err) {
    message.error(err instanceof Error ? err.message : '设置失败')
  } finally {
    savingKey.value = false
  }
}

function handleDisableApi(): void {
  dialog.warning({
    title: '清除加密密钥',
    content: '确定要清除加密密钥吗？清除后将无法解密下载文件，需要重新输入密钥。',
    positiveText: '清除',
    negativeText: '取消',
    onPositiveClick: async () => {
      try {
        await authApi.clearEncryptionKey()
        authStore.clearEncryptionKey()
        message.success('加密密钥已清除')
        uiStore.addActivity('settings', '清除了加密密钥')
      } catch (err) {
        message.error(err instanceof Error ? err.message : '清除失败')
      }
    }
  })
}

async function handleRefreshStatus(): Promise<void> {
  uiStore.setLoading(true, '刷新状态...')
  try {
    const response = await authApi.hasEncryptionKey()
    if (response.has_key) {
      message.info('服务器内存中存在加密密钥')
    } else {
      message.info('服务器内存中没有加密密钥')
    }
  } catch (err) {
    message.error(err instanceof Error ? err.message : '刷新失败')
  } finally {
    uiStore.setLoading(false)
  }
}

async function copyToClipboard(text: string): Promise<void> {
  try {
    await navigator.clipboard.writeText(text)
    message.success('已复制到剪贴板')
  } catch {
    message.error('复制失败')
  }
}
</script>

<template>
  <NCard title="API 访问控制">
    <NSpace vertical :size="16">
      <!-- 状态显示 -->
      <div
        style="
          padding: 16px;
          background: #f5f5f5;
          border-radius: 8px;
          border-left: 4px solid #4f46e5;
        "
      >
        <NTag
          :type="authStore.hasEncryptionKey ? 'success' : 'warning'"
          size="large"
          style="margin-bottom: 8px"
        >
          {{ authStore.hasEncryptionKey ? '🟢 已启用' : '🔴 已禁用' }}
        </NTag>
        <p style="color: #6b7280; font-size: 0.875rem; margin: 8px 0 0 0">
          {{
            authStore.hasEncryptionKey
              ? 'API 访问已开放，可以解密下载文件。'
              : 'API 访问已关闭，需要设置加密密钥才能解密文件。'
          }}
        </p>

        <!-- 显示当前密钥 -->
        <div
          v-if="authStore.hasEncryptionKey && authStore.encryptionKey"
          style="
            margin-top: 16px;
            padding: 12px;
            background: white;
            border-radius: 8px;
            border: 1px solid #e5e7eb;
          "
        >
          <div
            style="
              display: flex;
              justify-content: space-between;
              align-items: center;
              margin-bottom: 8px;
            "
          >
            <strong style="color: #475569">当前加密密钥</strong>
            <NButton size="small" @click="copyToClipboard(authStore.encryptionKey)">
              📋 复制
            </NButton>
          </div>
          <code
            style="
              display: block;
              word-break: break-all;
              color: #64748b;
              font-size: 0.85rem;
            "
          >
            {{ authStore.encryptionKey }}
          </code>
        </div>

        <NAlert
          v-if="!authStore.hasEncryptionKey"
          type="warning"
          style="margin-top: 12px"
        >
          ⚠️ 启用 API 需要提供加密密钥（从 Memento 客户端获取）
        </NAlert>
      </div>

      <!-- 密钥输入 -->
      <div v-if="showKeyInput">
        <NInputGroup>
          <NInput
            v-model:value="newKey"
            placeholder="请输入加密密钥 (Base64 编码，44 个字符)"
            type="password"
            show-password-on="click"
          />
          <NButton type="primary" :loading="savingKey" @click="handleSaveKey">
            保存
          </NButton>
          <NButton @click="showKeyInput = false">取消</NButton>
        </NInputGroup>
        <p style="color: #6b7280; font-size: 0.75rem; margin-top: 8px">
          💡 加密密钥可在 Memento 客户端 "设置 > 开发者选项" 中查看
        </p>
      </div>

      <!-- 操作按钮 -->
      <NSpace>
        <NButton
          v-if="!authStore.hasEncryptionKey"
          type="success"
          @click="handleEnableApi"
        >
          ✅ 启用 API 访问
        </NButton>
        <NButton
          v-if="authStore.hasEncryptionKey"
          type="warning"
          @click="handleEnableApi"
        >
          🔑 更改密钥
        </NButton>
        <NButton
          v-if="authStore.hasEncryptionKey"
          type="error"
          @click="handleDisableApi"
        >
          🚫 禁用 API 访问
        </NButton>
        <NButton @click="handleRefreshStatus">🔄 刷新状态</NButton>
      </NSpace>
    </NSpace>
  </NCard>
</template>

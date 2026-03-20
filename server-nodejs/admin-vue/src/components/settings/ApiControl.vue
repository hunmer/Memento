<script setup lang="ts">
import { ref, computed } from 'vue'
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

// 输入模式：'none' | 'input'
const inputMode = ref<'none' | 'input'>('none')
const keyInput = ref('')
const savingKey = ref(false)

// 本地是否有密钥
const hasLocalKey = computed(() => !!authStore.encryptionKey)

// 启用 API（输入密钥）
function handleEnableApi(): void {
  inputMode.value = 'input'
  keyInput.value = ''
}

// 取消输入
function handleCancel(): void {
  inputMode.value = 'none'
  keyInput.value = ''
}

// 验证密钥格式
function validateKeyFormat(key: string): boolean {
  if (!/^[A-Za-z0-9+/]+=*$/.test(key)) {
    message.error('加密密钥格式无效，应为 Base64 编码')
    return false
  }
  if (key.length < 40) {
    message.error('加密密钥长度不足，标准长度为 44 个字符')
    return false
  }
  return true
}

// 验证并保存密钥
async function handleSaveKey(): Promise<void> {
  const key = keyInput.value.trim()

  if (!validateKeyFormat(key)) {
    return
  }

  savingKey.value = true
  try {
    const response = await authApi.verifyEncryptionKey(key)

    if (response.success) {
      authStore.setEncryptionKey(key)
      inputMode.value = 'none'
      keyInput.value = ''

      if (response.is_first_time) {
        message.success('加密密钥已验证并创建验证文件')
        uiStore.addActivity('settings', '首次验证了加密密钥')
      } else {
        message.success('密钥验证成功')
        uiStore.addActivity('settings', '验证了加密密钥')
      }
    }
  } catch (err) {
    const errorMessage = err instanceof Error ? err.message : '验证失败'
    if (errorMessage.includes('密钥验证失败') || errorMessage.includes('无法解密')) {
      message.error('密钥错误：与首次设置的密钥不匹配')
    } else {
      message.error(errorMessage)
    }
  } finally {
    savingKey.value = false
  }
}

function handleDisableApi(): void {
  dialog.warning({
    title: '清除加密密钥',
    content: '确定要清除本地保存的加密密钥吗？清除后需要重新输入密钥才能解密文件。',
    positiveText: '清除',
    negativeText: '取消',
    onPositiveClick: () => {
      authStore.clearEncryptionKey()
      message.success('本地加密密钥已清除')
      uiStore.addActivity('settings', '清除了本地加密密钥')
    }
  })
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
          :type="hasLocalKey ? 'success' : 'warning'"
          size="large"
          style="margin-bottom: 8px"
        >
          {{ hasLocalKey ? '🟢 已启用' : '🔴 已禁用' }}
        </NTag>
        <p style="color: #6b7280; font-size: 0.875rem; margin: 8px 0 0 0">
          <template v-if="hasLocalKey">
            API 访问已开放，可以解密下载文件。
          </template>
          <template v-else>
            API 访问已关闭，需要设置加密密钥才能解密文件。
          </template>
        </p>

        <!-- 显示当前密钥 -->
        <div
          v-if="hasLocalKey"
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
          v-if="!hasLocalKey"
          type="warning"
          style="margin-top: 12px"
        >
          ⚠️ 启用 API 需要提供加密密钥（从 Memento 客户端获取）
        </NAlert>
      </div>

      <!-- 输入密钥 -->
      <div v-if="inputMode === 'input'">
        <div style="margin-bottom: 8px; font-weight: 500; color: #475569">
          输入加密密钥
        </div>
        <NInputGroup>
          <NInput
            v-model:value="keyInput"
            placeholder="请输入加密密钥 (Base64 编码，44 个字符)"
          />
          <NButton type="primary" :loading="savingKey" @click="handleSaveKey">
            验证
          </NButton>
          <NButton @click="handleCancel">取消</NButton>
        </NInputGroup>
        <p style="color: #6b7280; font-size: 0.75rem; margin-top: 8px">
          💡 加密密钥可在 Memento 客户端 "设置 > 开发者选项" 中查看
        </p>
      </div>

      <!-- 操作按钮 -->
      <NSpace v-if="inputMode === 'none'">
        <NButton
          v-if="!hasLocalKey"
          type="success"
          @click="handleEnableApi"
        >
          ✅ 启用 API 访问
        </NButton>
        <NButton
          v-if="hasLocalKey"
          type="warning"
          @click="handleEnableApi"
        >
          🔑 更换密钥
        </NButton>
        <NButton
          v-if="hasLocalKey"
          type="error"
          @click="handleDisableApi"
        >
          🚫 清除本地密钥
        </NButton>
      </NSpace>
    </NSpace>
  </NCard>
</template>

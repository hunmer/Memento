<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import {
  NCard,
  NSpace,
  NButton,
  NTag,
  NAlert,
  NInput,
  NInputGroup,
  NSwitch,
  NSpin,
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

// API 访问开关状态
const apiEnabled = ref(false)
const loadingApiStatus = ref(false)
const togglingApi = ref(false)

// 输入模式：'none' | 'input'
const inputMode = ref<'none' | 'input'>('none')
const keyInput = ref('')
const savingKey = ref(false)

// 本地是否有密钥
const hasLocalKey = computed(() => !!authStore.encryptionKey)

// 初始化加载 API 访问状态
onMounted(async () => {
  await loadApiAccessStatus()
})

async function loadApiAccessStatus(): Promise<void> {
  loadingApiStatus.value = true
  try {
    const response = await authApi.getApiAccessStatus()
    apiEnabled.value = response.enabled
  } catch (e) {
    console.error('获取 API 访问状态失败:', e)
  } finally {
    loadingApiStatus.value = false
  }
}

// 切换 API 访问状态
async function handleToggleApi(enabled: boolean): Promise<void> {
  togglingApi.value = true
  try {
    const response = await authApi.setApiAccessStatus(enabled)
    apiEnabled.value = response.enabled
    message.success(response.message)
    uiStore.addActivity('settings', enabled ? '开启了 API 访问' : '关闭了 API 访问')
  } catch (e) {
    // 恢复原状态
    apiEnabled.value = !enabled
    const errorMessage = e instanceof Error ? e.message : '设置失败'
    message.error(errorMessage)
  } finally {
    togglingApi.value = false
  }
}

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

// AES-GCM 解密（与客户端加密服务兼容）
// Dart encrypt 包使用 GCM 模式时，密文和 authTag 合并在一起
async function decryptVerificationData(encryptedData: string, key: string): Promise<string> {
  // 解析加密数据格式: iv.base64.ciphertext_base64
  const parts = encryptedData.split('.')
  if (parts.length !== 2) {
    throw new Error('加密数据格式无效')
  }

  const [ivBase64, combinedBase64] = parts

  // 解码 Base64
  const iv = Uint8Array.from(atob(ivBase64), c => c.charCodeAt(0))
  const combined = Uint8Array.from(atob(combinedBase64), c => c.charCodeAt(0))

  // 解码密钥
  const keyBytes = Uint8Array.from(atob(key), c => c.charCodeAt(0))

  // 导入密钥
  const cryptoKey = await crypto.subtle.importKey(
    'raw',
    keyBytes,
    { name: 'AES-GCM' },
    false,
    ['decrypt']
  )

  // 解密（Web Crypto API 会自动处理 authTag）
  const decrypted = await crypto.subtle.decrypt(
    { name: 'AES-GCM', iv },
    cryptoKey,
    combined
  )

  return new TextDecoder().decode(decrypted)
}

// 验证并保存密钥
async function handleSaveKey(): Promise<void> {
  const key = keyInput.value.trim()

  if (!validateKeyFormat(key)) {
    return
  }

  savingKey.value = true
  try {
    // 1. 获取服务端的验证文件
    const response = await authApi.getKeyVerification()

    if (!response.exists) {
      message.error('服务端没有密钥验证文件，请先在客户端完成首次同步')
      savingKey.value = false
      return
    }

    // 2. 本地解密验证
    if (!response.encrypted_data) {
      message.error('验证文件数据无效')
      savingKey.value = false
      return
    }

    try {
      const decryptedJson = await decryptVerificationData(response.encrypted_data, key)
      const verificationData = JSON.parse(decryptedJson)

      // 验证内容
      if (verificationData.content !== 'MEMENTO_KEY_VERIFICATION_v1') {
        message.error('密钥验证失败：内容不匹配')
        return
      }

      // 验证成功，保存密钥到本地
      authStore.setEncryptionKey(key)
      inputMode.value = 'none'
      keyInput.value = ''
      message.success('密钥验证成功')
      uiStore.addActivity('settings', '验证了加密密钥')
    } catch {
      message.error('密钥验证失败：无法解密验证文件，密钥可能不正确')
    }
  } catch (err) {
    const errorMessage = err instanceof Error ? err.message : '验证失败'
    message.error(errorMessage)
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
      <!-- API 访问开关 -->
      <div
        style="
          padding: 16px;
          background: #f5f5f5;
          border-radius: 8px;
          border-left: 4px solid #4f46e5;
        "
      >
        <div style="display: flex; justify-content: space-between; align-items: center">
          <div>
            <strong style="color: #374151">API 访问开关</strong>
            <p style="color: #6b7280; font-size: 0.875rem; margin: 4px 0 0 0">
              控制是否允许通过 API 访问数据
            </p>
          </div>
          <NSpin :show="loadingApiStatus" size="small">
            <NSwitch
              :value="apiEnabled"
              :loading="togglingApi"
              @update:value="handleToggleApi"
            />
          </NSpin>
        </div>
      </div>

      <!-- 加密密钥设置 -->
      <div
        style="
          padding: 16px;
          background: #f5f5f5;
          border-radius: 8px;
          border-left: 4px solid #10b981;
        "
      >
        <NTag
          :type="hasLocalKey ? 'success' : 'warning'"
          size="large"
          style="margin-bottom: 8px"
        >
          {{ hasLocalKey ? '🟢 已设置密钥' : '🔴 未设置密钥' }}
        </NTag>
        <p style="color: #6b7280; font-size: 0.875rem; margin: 8px 0 0 0">
          <template v-if="hasLocalKey">
            加密密钥已设置，可以解密下载文件。
          </template>
          <template v-else>
            加密密钥未设置，需要输入密钥才能解密文件。
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
          ⚠️ 需要提供加密密钥才能解密文件（从 Memento 客户端获取）
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
          ✅ 设置加密密钥
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

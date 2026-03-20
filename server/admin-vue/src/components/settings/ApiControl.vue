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

// 输入模式：'none' | 'first-time' | 'change'
const inputMode = ref<'none' | 'first-time' | 'change'>('none')
const oldKey = ref('')
const newKey = ref('')
const savingKey = ref(false)

// 本地是否有密钥
const hasLocalKey = computed(() => !!authStore.encryptionKey)

// 是否是更改密钥模式
const isChangeMode = computed(() => inputMode.value === 'change')

// 首次启用 API
function handleEnableApi(): void {
  inputMode.value = 'first-time'
  oldKey.value = ''
  newKey.value = ''
}

// 更改密钥
function handleChangeKey(): void {
  inputMode.value = 'change'
  oldKey.value = ''
  newKey.value = ''
}

// 取消输入
function handleCancel(): void {
  inputMode.value = 'none'
  oldKey.value = ''
  newKey.value = ''
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

// 保存密钥（首次设置或验证当前密钥）
async function handleSaveKey(): Promise<void> {
  const key = isChangeMode.value ? oldKey.value.trim() : newKey.value.trim()

  if (!validateKeyFormat(key)) {
    return
  }

  savingKey.value = true
  try {
    const response = await authApi.setEncryptionKey(key)

    if (response.success) {
      authStore.setEncryptionKey(key)
      authStore.serverHasKey = true

      if (isChangeMode.value) {
        // 更改密钥模式：旧密钥验证成功，切换到输入新密钥
        inputMode.value = 'first-time'
        oldKey.value = ''
        newKey.value = ''
        message.success('旧密钥验证成功，请输入新密钥')
      } else {
        // 首次设置模式
        inputMode.value = 'none'
        newKey.value = ''

        if (response.is_first_time) {
          message.success('加密密钥已设置并创建验证文件')
          uiStore.addActivity('settings', '首次设置了加密密钥')
        } else {
          message.success('密钥验证成功')
          uiStore.addActivity('settings', '验证了加密密钥')
        }
      }
    }
  } catch (err) {
    const errorMessage = err instanceof Error ? err.message : '设置失败'
    if (errorMessage.includes('密钥验证失败') || errorMessage.includes('无法解密')) {
      message.error('密钥错误：与首次设置的密钥不匹配')
    } else {
      message.error(errorMessage)
    }
  } finally {
    savingKey.value = false
  }
}

// 更改密钥（输入新密钥后保存）
async function handleChangeKeySave(): Promise<void> {
  const key = newKey.value.trim()

  if (!validateKeyFormat(key)) {
    return
  }

  // 检查新密钥是否与当前密钥相同
  if (authStore.encryptionKey && key === authStore.encryptionKey) {
    message.warning('新密钥与当前密钥相同，无需更改')
    return
  }

  savingKey.value = true
  try {
    // 使用 forceCreate 强制更新验证文件
    const response = await authApi.setEncryptionKey(key, true)

    if (response.success) {
      authStore.setEncryptionKey(key)
      authStore.serverHasKey = true
      inputMode.value = 'none'
      oldKey.value = ''
      newKey.value = ''
      message.success('密钥已更新')
      uiStore.addActivity('settings', '更改了加密密钥')
    }
  } catch (err) {
    const errorMessage = err instanceof Error ? err.message : '设置失败'
    message.error(errorMessage)
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
        authStore.serverHasKey = false
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
    authStore.serverHasKey = response.has_key
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
          :type="hasLocalKey || authStore.serverHasKey ? 'success' : 'warning'"
          size="large"
          style="margin-bottom: 8px"
        >
          {{ hasLocalKey || authStore.serverHasKey ? '🟢 已启用' : '🔴 已禁用' }}
        </NTag>
        <p style="color: #6b7280; font-size: 0.875rem; margin: 8px 0 0 0">
          <template v-if="hasLocalKey">
            API 访问已开放，可以解密下载文件。
          </template>
          <template v-else-if="authStore.serverHasKey">
            服务器已保存密钥，但本设备未保存。需要输入密钥才能在此设备解密文件。
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
          v-if="!hasLocalKey && !authStore.serverHasKey"
          type="warning"
          style="margin-top: 12px"
        >
          ⚠️ 启用 API 需要提供加密密钥（从 Memento 客户端获取）
        </NAlert>
        <NAlert
          v-if="!hasLocalKey && authStore.serverHasKey"
          type="info"
          style="margin-top: 12px"
        >
          💡 服务器已保存密钥，请输入相同的密钥以在此设备启用解密功能
        </NAlert>
      </div>

      <!-- 首次设置密钥 -->
      <div v-if="inputMode === 'first-time' && !hasLocalKey">
        <div style="margin-bottom: 8px; font-weight: 500; color: #475569">
          设置加密密钥
        </div>
        <NInputGroup>
          <NInput
            v-model:value="newKey"
            placeholder="请输入加密密钥 (Base64 编码，44 个字符)"
          />
          <NButton type="primary" :loading="savingKey" @click="handleSaveKey">
            保存
          </NButton>
          <NButton @click="handleCancel">取消</NButton>
        </NInputGroup>
        <p style="color: #6b7280; font-size: 0.75rem; margin-top: 8px">
          💡 加密密钥可在 Memento 客户端 "设置 > 开发者选项" 中查看
        </p>
      </div>

      <!-- 更改密钥：输入旧密钥验证 -->
      <div v-if="inputMode === 'change'">
        <div style="margin-bottom: 8px; font-weight: 500; color: #475569">
          步骤 1：验证当前密钥
        </div>
        <NInputGroup>
          <NInput
            v-model:value="oldKey"
            placeholder="请输入当前加密密钥"
          />
          <NButton type="primary" :loading="savingKey" @click="handleSaveKey">
            验证
          </NButton>
          <NButton @click="handleCancel">取消</NButton>
        </NInputGroup>
      </div>

      <!-- 更改密钥：输入新密钥（旧密钥验证成功后显示） -->
      <div v-if="inputMode === 'first-time' && hasLocalKey">
        <div style="margin-bottom: 8px; font-weight: 500; color: #475569">
          步骤 2：设置新密钥
        </div>
        <NInputGroup>
          <NInput
            v-model:value="newKey"
            placeholder="请输入新的加密密钥"
          />
          <NButton type="primary" :loading="savingKey" @click="handleChangeKeySave">
            保存
          </NButton>
          <NButton @click="handleCancel">取消</NButton>
        </NInputGroup>
        <p style="color: #6b7280; font-size: 0.75rem; margin-top: 8px">
          ⚠️ 更改密钥后，需要同步更新客户端的密钥配置
        </p>
      </div>

      <!-- 操作按钮 -->
      <NSpace v-if="inputMode === 'none'">
        <NButton
          v-if="!hasLocalKey && !authStore.serverHasKey"
          type="success"
          @click="handleEnableApi"
        >
          ✅ 启用 API 访问
        </NButton>
        <NButton
          v-if="!hasLocalKey && authStore.serverHasKey"
          type="primary"
          @click="handleEnableApi"
        >
          🔑 输入密钥
        </NButton>
        <NButton
          v-if="hasLocalKey"
          type="warning"
          @click="handleChangeKey"
        >
          🔑 更改密钥
        </NButton>
        <NButton
          v-if="hasLocalKey || authStore.serverHasKey"
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

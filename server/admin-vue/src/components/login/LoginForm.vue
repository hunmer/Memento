<script setup lang="ts">
import { ref, reactive } from 'vue'
import {
  NCard,
  NForm,
  NFormItem,
  NInput,
  NButton,
  NSpace,
  NAlert
} from 'naive-ui'
import { useAuthStore } from '@/stores/auth'
import { useUIStore } from '@/stores/ui'
import { useFilesStore } from '@/stores/files'

const authStore = useAuthStore()
const uiStore = useUIStore()
const filesStore = useFilesStore()

const form = reactive({
  username: '',
  password: '',
  serverUrl: localStorage.getItem('serverUrl') || 'http://localhost:8874'
})

const error = ref('')
const loading = ref(false)

async function handleLogin(): Promise<void> {
  if (!form.username || !form.password) {
    error.value = '请输入用户名和密码'
    return
  }

  loading.value = true
  error.value = ''

  try {
    await authStore.login(form.username, form.password, form.serverUrl)

    // 加载数据
    await loadDashboardData()

    window.$message?.success('登录成功')
  } catch (err) {
    error.value = err instanceof Error ? err.message : '登录失败，请检查用户名和密码'
  } finally {
    loading.value = false
  }
}

async function loadDashboardData(): Promise<void> {
  await Promise.all([
    checkServerHealth(),
    filesStore.loadFiles(),
    authStore.loadApiKeys()
  ])
}

async function checkServerHealth(): Promise<void> {
  try {
    const response = await fetch(`${form.serverUrl}/health`)
    uiStore.setServerStatus(response.ok ? 'online' : 'offline')
  } catch {
    uiStore.setServerStatus('offline')
  }
}
</script>

<template>
  <div
    style="
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 60vh;
    "
  >
    <NCard title="管理员登录" style="width: 100%; max-width: 400px">
      <NAlert type="info" style="margin-bottom: 16px">
        默认凭据: admin / admin123
      </NAlert>

      <NForm @submit.prevent="handleLogin">
        <NFormItem label="用户名">
          <NInput
            v-model:value="form.username"
            placeholder="请输入用户名"
            @keyup.enter="handleLogin"
          />
        </NFormItem>

        <NFormItem label="密码">
          <NInput
            v-model:value="form.password"
            type="password"
            placeholder="请输入密码"
            show-password-on="click"
            @keyup.enter="handleLogin"
          />
        </NFormItem>

        <NFormItem label="服务器地址">
          <NInput
            v-model:value="form.serverUrl"
            placeholder="http://localhost:8874"
            @keyup.enter="handleLogin"
          />
        </NFormItem>

        <NSpace vertical :size="16">
          <NButton
            type="primary"
            block
            :loading="loading"
            @click="handleLogin"
          >
            {{ loading ? '登录中...' : '登录' }}
          </NButton>

          <NAlert v-if="error" type="error">
            {{ error }}
          </NAlert>
        </NSpace>
      </NForm>
    </NCard>
  </div>
</template>

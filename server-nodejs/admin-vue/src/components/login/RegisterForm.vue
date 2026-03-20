<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import {
  NCard,
  NForm,
  NFormItem,
  NInput,
  NButton,
  NSpace,
  NAlert,
  useMessage
} from 'naive-ui'
import { authApi, apiClient } from '@/api'

const emit = defineEmits<{
  (e: 'switchToLogin'): void
  (e: 'registered', username: string, password: string): void
}>()

const message = useMessage()

const form = reactive({
  username: '',
  password: '',
  confirmPassword: '',
  serverUrl: localStorage.getItem('serverUrl') || 'http://localhost:8874'
})

const error = ref('')
const loading = ref(false)
const allowRegister = ref(true)

onMounted(async () => {
  // 检查服务器是否允许注册
  try {
    apiClient.setBaseUrl(form.serverUrl)
    const response = await authApi.getRegisterStatus()
    allowRegister.value = response.allow_register
  } catch (e) {
    console.warn('无法获取注册状态:', e)
  }
})

async function handleRegister(): Promise<void> {
  if (!form.username || !form.password) {
    error.value = '请填写用户名和密码'
    return
  }

  if (form.username.length < 3) {
    error.value = '用户名至少需要 3 个字符'
    return
  }

  if (form.password.length < 6) {
    error.value = '密码至少需要 6 个字符'
    return
  }

  if (form.password !== form.confirmPassword) {
    error.value = '两次输入的密码不一致'
    return
  }

  loading.value = true
  error.value = ''

  try {
    apiClient.setBaseUrl(form.serverUrl)

    const response = await authApi.register({
      username: form.username,
      password: form.password,
      device_id: 'admin_panel',
      device_name: 'Admin Panel'
    })

    if (!response.success) {
      error.value = response.error || '注册失败'
      return
    }

    message.success('注册成功，请登录')
    emit('registered', form.username, form.password)
  } catch (err) {
    error.value = err instanceof Error ? err.message : '注册失败'
  } finally {
    loading.value = false
  }
}

function switchToLogin(): void {
  emit('switchToLogin')
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
    <NCard title="用户注册" style="width: 100%; max-width: 400px">
      <NAlert v-if="!allowRegister" type="warning" style="margin-bottom: 16px">
        注册功能已关闭，请联系管理员
      </NAlert>

      <NForm v-if="allowRegister" @submit.prevent="handleRegister">
        <NFormItem label="用户名">
          <NInput
            v-model:value="form.username"
            placeholder="请输入用户名 (至少3个字符)"
            @keyup.enter="handleRegister"
          />
        </NFormItem>

        <NFormItem label="密码">
          <NInput
            v-model:value="form.password"
            type="password"
            placeholder="请输入密码 (至少6个字符)"
            show-password-on="click"
            @keyup.enter="handleRegister"
          />
        </NFormItem>

        <NFormItem label="确认密码">
          <NInput
            v-model:value="form.confirmPassword"
            type="password"
            placeholder="请再次输入密码"
            show-password-on="click"
            @keyup.enter="handleRegister"
          />
        </NFormItem>

        <NFormItem label="服务器地址">
          <NInput
            v-model:value="form.serverUrl"
            placeholder="http://localhost:8874"
            @keyup.enter="handleRegister"
          />
        </NFormItem>

        <NSpace vertical :size="16">
          <NButton
            type="primary"
            block
            :loading="loading"
            @click="handleRegister"
          >
            {{ loading ? '注册中...' : '注册' }}
          </NButton>

          <NButton text block @click="switchToLogin">
            已有账号？返回登录
          </NButton>

          <NAlert v-if="error" type="error">
            {{ error }}
          </NAlert>
        </NSpace>
      </NForm>

      <NButton v-if="!allowRegister" text block @click="switchToLogin">
        返回登录
      </NButton>
    </NCard>
  </div>
</template>

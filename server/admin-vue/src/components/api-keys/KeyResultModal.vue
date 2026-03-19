<script setup lang="ts">
import {
  NModal,
  NAlert,
  NInput,
  NButton,
  NSpace,
  NInputGroup,
  useMessage
} from 'naive-ui'
import { apiClient } from '@/api'

interface Props {
  show: boolean
  apiKey: { name: string; key: string } | null
}

defineProps<Props>()

const emit = defineEmits<{
  'update:show': [value: boolean]
  close: []
}>()

const message = useMessage()

async function copyToClipboard(text: string): Promise<void> {
  try {
    await navigator.clipboard.writeText(text)
    message.success('已复制到剪贴板')
  } catch {
    // 降级方案
    const textarea = document.createElement('textarea')
    textarea.value = text
    textarea.style.position = 'fixed'
    textarea.style.opacity = '0'
    document.body.appendChild(textarea)
    textarea.select()
    document.execCommand('copy')
    document.body.removeChild(textarea)
    message.success('已复制到剪贴板')
  }
}

function handleClose(): void {
  emit('close')
  emit('update:show', false)
}
</script>

<template>
  <NModal
    :show="show"
    @update:show="$emit('update:show', $event)"
    preset="card"
    title="✅ API Key 已创建"
    style="width: 600px"
    :mask-closable="false"
    :closable="false"
  >
    <NAlert type="warning" style="margin-bottom: 16px">
      <strong>重要提示：</strong>API Key 仅显示一次，请妥善保存！
    </NAlert>

    <div v-if="apiKey">
      <NInputGroup>
        <NInput :value="apiKey.key" readonly style="font-family: monospace" />
        <NButton type="primary" @click="copyToClipboard(apiKey.key)">
          复制
        </NButton>
      </NInputGroup>

      <div
        style="
          margin-top: 16px;
          padding: 16px;
          background: #f5f5f5;
          border-radius: 8px;
        "
      >
        <h4 style="margin: 0 0 8px 0; color: #6b7280">使用说明</h4>
        <p style="margin: 0; color: #6b7280; font-size: 0.9rem">
          API Key 用于代替用户名密码进行认证。<br />
          调用需要解密的接口时，需要通过
          <code>X-Encryption-Key</code> 请求头传递加密密钥。
        </p>

        <h4 style="margin: 16px 0 8px 0; color: #6b7280">
          MCP Server 配置示例 (.env)
        </h4>
        <pre
          style="
            background: #1e293b;
            color: #e2e8f0;
            padding: 12px;
            border-radius: 8px;
            font-size: 0.8rem;
            overflow-x: auto;
            white-space: pre-wrap;
          "
        >MEMENTO_API_KEY={{ apiKey.key }}
MEMENTO_SERVER_URL={{ apiClient.getBaseUrl() }}
# 加密密钥需要在调用时通过请求头传递</pre>
      </div>
    </div>

    <template #footer>
      <NSpace justify="end">
        <NButton type="primary" @click="handleClose">我已保存</NButton>
      </NSpace>
    </template>
  </NModal>
</template>

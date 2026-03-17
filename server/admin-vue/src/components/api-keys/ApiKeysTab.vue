<script setup lang="ts">
import { ref } from 'vue'
import {
  NCard,
  NButton,
  NAlert,
  NEmpty,
  NList,
  NListItem,
  NThing,
  NText,
  NTag,
  NSpace
} from 'naive-ui'
import { useAuthStore } from '@/stores/auth'
import { useUIStore } from '@/stores/ui'
import CreateKeyModal from './CreateKeyModal.vue'
import KeyResultModal from './KeyResultModal.vue'
import { formatTime } from '@/utils/format'

const authStore = useAuthStore()
const uiStore = useUIStore()

const showCreateModal = ref(false)
const showResultModal = ref(false)

function handleCreateClick(): void {
  showCreateModal.value = true
}

function handleCreateSuccess(): void {
  showCreateModal.value = false
  showResultModal.value = true
  uiStore.addActivity('api_key', '创建了 API Key')
}

async function handleRevoke(keyId: string): Promise<void> {
  uiStore.setLoading(true, '撤销 API Key...')
  try {
    await authStore.revokeApiKey(keyId)
    window.$message?.success('API Key 已撤销')
    uiStore.addActivity('api_key', '撤销了一个 API Key')
  } catch (err) {
    window.$message?.error(err instanceof Error ? err.message : '撤销失败')
  } finally {
    uiStore.setLoading(false)
  }
}

function handleCloseResult(): void {
  showResultModal.value = false
  authStore.clearCreatedKey()
}
</script>

<template>
  <NSpace vertical :size="16">
    <NCard title="API Keys 管理">
      <template #header-extra>
        <NButton type="primary" @click="handleCreateClick">
          ➕ 创建 API Key
        </NButton>
      </template>

      <NAlert type="info" style="margin-bottom: 16px">
        <strong>API Key</strong> 用于 MCP Server 等外部应用访问 Memento 数据。
        <br />创建后请立即保存，密钥只显示一次。
      </NAlert>

      <div v-if="authStore.apiKeys.length === 0">
        <NEmpty description="暂无 API Key" />
      </div>

      <NList v-else bordered>
        <NListItem v-for="key in authStore.apiKeys" :key="key.id">
          <NThing>
            <template #header>
              <NSpace align="center" :size="8">
                <strong>{{ key.name }}</strong>
                <NTag v-if="key.is_expired" type="error" size="small">
                  已过期
                </NTag>
              </NSpace>
            </template>
            <template #description>
              <NSpace :size="8">
                <code
                  style="
                    background: #f1f5f9;
                    padding: 2px 6px;
                    border-radius: 4px;
                    font-size: 0.85rem;
                  "
                >
                  {{ key.key_prefix }}...
                </code>
                <NText depth="3" v-if="key.expires_at">
                  | 过期: {{ formatTime(key.expires_at) }}
                </NText>
                <NText depth="3" v-else>| 永不过期</NText>
                <NText depth="3" v-if="key.last_used_at">
                  | 最后使用: {{ formatTime(key.last_used_at) }}
                </NText>
              </NSpace>
            </template>
          </NThing>
          <template #suffix>
            <NButton size="small" type="error" @click="handleRevoke(key.id)">
              撤销
            </NButton>
          </template>
        </NListItem>
      </NList>
    </NCard>

    <CreateKeyModal
      v-model:show="showCreateModal"
      @success="handleCreateSuccess"
    />

    <KeyResultModal
      v-model:show="showResultModal"
      :api-key="authStore.createdKey"
      @close="handleCloseResult"
    />
  </NSpace>
</template>

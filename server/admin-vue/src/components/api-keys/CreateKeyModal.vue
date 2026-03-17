<script setup lang="ts">
import { ref, reactive } from 'vue'
import {
  NModal,
  NForm,
  NFormItem,
  NInput,
  NSelect,
  NButton,
  NSpace
} from 'naive-ui'
import { useAuthStore } from '@/stores/auth'

interface Props {
  show: boolean
}

defineProps<Props>()

const emit = defineEmits<{
  'update:show': [value: boolean]
  success: []
}>()

const authStore = useAuthStore()

const form = reactive({
  name: '',
  expiry: 'never' as 'never' | '7days' | '30days' | '90days' | '1year'
})

const loading = ref(false)

const expiryOptions = [
  { label: '永不过期', value: 'never' },
  { label: '7天', value: '7days' },
  { label: '30天', value: '30days' },
  { label: '90天', value: '90days' },
  { label: '1年', value: '1year' }
]

async function handleCreate(): Promise<void> {
  if (!form.name.trim()) {
    window.$message?.error('请输入 API Key 名称')
    return
  }

  loading.value = true
  try {
    await authStore.createApiKey({
      name: form.name.trim(),
      expiry: form.expiry
    })

    // 重置表单
    form.name = ''
    form.expiry = 'never'

    emit('success')
  } catch (err) {
    window.$message?.error(err instanceof Error ? err.message : '创建失败')
  } finally {
    loading.value = false
  }
}

function handleClose(): void {
  emit('update:show', false)
}
</script>

<template>
  <NModal
    :show="show"
    @update:show="$emit('update:show', $event)"
    preset="card"
    title="创建 API Key"
    style="width: 500px"
    :mask-closable="false"
  >
    <NForm :model="form">
      <NFormItem label="名称" required>
        <NInput v-model:value="form.name" placeholder="例如: MCP Server" />
      </NFormItem>

      <NFormItem label="过期时间">
        <NSelect v-model:value="form.expiry" :options="expiryOptions" />
      </NFormItem>
    </NForm>

    <template #footer>
      <NSpace justify="end">
        <NButton @click="handleClose">取消</NButton>
        <NButton type="primary" :loading="loading" @click="handleCreate">
          {{ loading ? '创建中...' : '创建' }}
        </NButton>
      </NSpace>
    </template>
  </NModal>
</template>

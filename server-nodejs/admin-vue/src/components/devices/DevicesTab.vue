<script setup lang="ts">
import { ref, onMounted } from 'vue'
import {
  NCard,
  NButton,
  NEmpty,
  NList,
  NListItem,
  NThing,
  NText,
  NTag,
  NSpace,
  NIcon,
  NModal,
  NInput,
  useMessage,
  useDialog
} from 'naive-ui'
import {
  PhonePortraitOutline,
  DesktopOutline,
  LaptopOutline,
  TabletPortraitOutline,
  SendOutline
} from '@vicons/ionicons5'
import { useDevicesStore } from '@/stores/devices'
import { formatTime } from '@/utils/format'
import type { Device } from '@/api/types'

const devicesStore = useDevicesStore()
const message = useMessage()
const dialog = useDialog()

// 推送消息模态框
const showPushModal = ref(false)
const selectedDevice = ref<Device | null>(null)
const pushTitle = ref('')
const pushBody = ref('')
const pushLoading = ref(false)

onMounted(() => {
  devicesStore.loadDevices()
})

// 获取设备图标
function getDeviceIcon(platform?: string) {
  if (!platform) return PhonePortraitOutline
  const p = platform.toLowerCase()
  if (p.includes('desktop') || p.includes('windows') || p.includes('linux')) return DesktopOutline
  if (p.includes('mac') || p.includes('macos')) return LaptopOutline
  if (p.includes('ipad') || p.includes('tablet')) return TabletPortraitOutline
  return PhonePortraitOutline
}

// 打开推送模态框
function openPushModal(device?: Device) {
  selectedDevice.value = device || null
  pushTitle.value = ''
  pushBody.value = ''
  showPushModal.value = true
}

// 发送推送消息
async function sendPushMessage() {
  if (!pushTitle.value.trim() || !pushBody.value.trim()) {
    message.warning('请填写标题和内容')
    return
  }

  pushLoading.value = true
  try {
    const result = await devicesStore.pushMessage(
      selectedDevice.value?.device_id,
      pushTitle.value,
      pushBody.value
    )

    if (result.success) {
      message.success(`推送成功，已发送到 ${result.sentCount || 1} 个设备`)
      showPushModal.value = false
    } else {
      message.error(result.error || '推送失败')
    }
  } finally {
    pushLoading.value = false
  }
}

// 删除设备
function handleDelete(device: Device) {
  dialog.warning({
    title: '确认删除',
    content: `确定要删除设备 "${device.device_name}" 吗？删除后该设备需要重新登录。`,
    positiveText: '删除',
    negativeText: '取消',
    onPositiveClick: async () => {
      const success = await devicesStore.deleteDevice(device.device_id)
      if (success) {
        message.success('设备已删除')
      } else {
        message.error(devicesStore.error || '删除失败')
      }
    }
  })
}
</script>

<template>
  <NSpace vertical :size="16">
    <NCard title="设备管理">
      <template #header-extra>
        <NSpace>
          <NButton @click="openPushModal()">
            <template #icon>
              <NIcon :component="SendOutline" />
            </template>
            推送消息
          </NButton>
          <NButton @click="devicesStore.loadDevices()">
            刷新
          </NButton>
        </NSpace>
      </template>

      <NText depth="3" style="margin-bottom: 16px; display: block;">
        管理已登录的设备，可推送消息或移除设备。
      </NText>

      <div v-if="devicesStore.loading">
        <NText>加载中...</NText>
      </div>

      <div v-else-if="devicesStore.devices.length === 0">
        <NEmpty description="暂无已注册设备" />
      </div>

      <NList v-else bordered>
        <NListItem v-for="device in devicesStore.devices" :key="device.device_id">
          <NThing>
            <template #avatar>
              <NIcon :component="getDeviceIcon(device.platform)" :size="24" />
            </template>
            <template #header>
              <NSpace align="center" :size="8">
                <strong>{{ device.device_name }}</strong>
                <NTag v-if="device.platform" size="small" type="info">
                  {{ device.platform }}
                </NTag>
              </NSpace>
            </template>
            <template #description>
              <NSpace :size="8" wrap>
                <NText depth="3" code style="font-size: 0.8rem;">
                  {{ device.device_id }}
                </NText>
                <NText depth="3">| 注册: {{ formatTime(device.created_at) }}</NText>
                <NText depth="3" v-if="device.last_sync_at">
                  | 最后同步: {{ formatTime(device.last_sync_at) }}
                </NText>
                <NText depth="3" v-if="device.fcm_token">
                  | FCM: {{ device.fcm_token }}
                </NText>
              </NSpace>
            </template>
          </NThing>
          <template #suffix>
            <NSpace>
              <NButton size="small" @click="openPushModal(device)">
                <template #icon>
                  <NIcon :component="SendOutline" />
                </template>
                推送
              </NButton>
              <NButton size="small" type="error" @click="handleDelete(device)">
                删除
              </NButton>
            </NSpace>
          </template>
        </NListItem>
      </NList>
    </NCard>

    <!-- 推送消息模态框 -->
    <NModal
      v-model:show="showPushModal"
      preset="card"
      :title="selectedDevice ? `推送到 ${selectedDevice.device_name}` : '推送到所有设备'"
      style="width: 400px"
    >
      <NSpace vertical :size="12">
        <div>
          <NText depth="3" style="margin-bottom: 4px; display: block;">标题</NText>
          <NInput v-model:value="pushTitle" placeholder="推送标题" />
        </div>
        <div>
          <NText depth="3" style="margin-bottom: 4px; display: block;">内容</NText>
          <NInput
            v-model:value="pushBody"
            type="textarea"
            placeholder="推送内容"
            :rows="3"
          />
        </div>
        <NSpace justify="end">
          <NButton @click="showPushModal = false">取消</NButton>
          <NButton type="primary" :loading="pushLoading" @click="sendPushMessage">
            发送
          </NButton>
        </NSpace>
      </NSpace>
    </NModal>
  </NSpace>
</template>

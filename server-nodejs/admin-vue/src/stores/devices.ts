import { defineStore } from 'pinia'
import { ref } from 'vue'
import { devicesApi } from '@/api'
import type { Device } from '@/api/types'

export const useDevicesStore = defineStore('devices', () => {
  // 状态
  const devices = ref<Device[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  // 加载设备列表
  async function loadDevices(): Promise<void> {
    loading.value = true
    error.value = null

    try {
      const response = await devicesApi.getDevices()
      if (response.success) {
        devices.value = response.devices || []
      } else {
        error.value = '加载设备列表失败'
      }
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e)
    } finally {
      loading.value = false
    }
  }

  // 删除设备
  async function deleteDevice(deviceId: string): Promise<boolean> {
    try {
      const response = await devicesApi.deleteDevice(deviceId)
      if (response.success) {
        devices.value = devices.value.filter(d => d.device_id !== deviceId)
        return true
      }
      return false
    } catch (e) {
      error.value = e instanceof Error ? e.message : String(e)
      return false
    }
  }

  // 推送消息
  async function pushMessage(
    deviceId: string | undefined,
    title: string,
    body: string,
    data?: Record<string, string>
  ): Promise<{ success: boolean; sentCount?: number; error?: string }> {
    try {
      const response = await devicesApi.pushMessage({
        device_id: deviceId,
        title,
        body,
        data
      })

      if (response.success) {
        return { success: true, sentCount: response.sent_count }
      }
      return { success: false, error: response.error }
    } catch (e) {
      return { success: false, error: e instanceof Error ? e.message : String(e) }
    }
  }

  return {
    // 状态
    devices,
    loading,
    error,

    // 方法
    loadDevices,
    deleteDevice,
    pushMessage
  }
})

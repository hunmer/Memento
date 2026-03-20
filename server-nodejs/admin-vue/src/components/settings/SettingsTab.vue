<script setup lang="ts">
import { NSpace } from 'naive-ui'
import ApiControl from './ApiControl.vue'
import DataOperations from './DataOperations.vue'
</script>

<template>
  <NSpace vertical :size="16">
    <ApiControl />
    <DataOperations />
  </NSpace>
</template>

<script setup>
import { ref } from 'vue'
import AdminUniformes from './AdminUniformes.vue'
import AdminBolas from './AdminBolas.vue'

const subaba = ref('uniformes')
</script>

<template>
  <div>
    <div class="flex gap-2">
      <button
        class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
        :class="subaba === 'uniformes' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
        @click="subaba = 'uniformes'"
      >Uniformes</button>
      <button
        class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
        :class="subaba === 'bolas' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
        @click="subaba = 'bolas'"
      >Bolas</button>
    </div>

    <div class="mt-6">
      <AdminUniformes v-if="subaba === 'uniformes'" />
      <AdminBolas v-else />
    </div>
  </div>
</template>

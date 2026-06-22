<script setup>
import { ref, defineAsyncComponent } from 'vue'

const AdminPatrocinadores = defineAsyncComponent(() => import('./AdminPatrocinadores.vue'))
const AdminParceiros = defineAsyncComponent(() => import('./AdminParceiros.vue'))
const AdminLocaisFesta = defineAsyncComponent(() => import('./AdminLocaisFesta.vue'))

const subaba = ref('patrocinadores')
</script>

<template>
  <div>
    <div class="flex flex-wrap gap-2">
      <button
        class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
        :class="subaba === 'patrocinadores' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
        @click="subaba = 'patrocinadores'"
      >Patrocinadores</button>
      <button
        class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
        :class="subaba === 'parceiros' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
        @click="subaba = 'parceiros'"
      >Parceiros</button>
      <button
        class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
        :class="subaba === 'locais' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
        @click="subaba = 'locais'"
      >Locais para festas</button>
    </div>

    <div class="mt-6">
      <AdminPatrocinadores v-if="subaba === 'patrocinadores'" />
      <AdminParceiros v-else-if="subaba === 'parceiros'" />
      <AdminLocaisFesta v-else />
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  total: { type: Number, required: true },
  pagina: { type: Number, required: true },
  porPagina: { type: Number, required: true },
  opcoesPorPagina: { type: Array, default: () => [10, 25, 50] },
})

const emit = defineEmits(['update:pagina', 'update:porPagina'])

const totalPaginas = computed(() => Math.max(1, Math.ceil(props.total / props.porPagina)))

const inicio = computed(() => Math.min((props.pagina - 1) * props.porPagina + 1, props.total))
const fim = computed(() => Math.min(props.pagina * props.porPagina, props.total))

// Quais numeros de pagina mostrar (max 5 botoes)
const paginas = computed(() => {
  const tp = totalPaginas.value
  const p = props.pagina
  if (tp <= 5) return Array.from({ length: tp }, (_, i) => i + 1)
  if (p <= 3) return [1, 2, 3, 4, null, tp]
  if (p >= tp - 2) return [1, null, tp - 3, tp - 2, tp - 1, tp]
  return [1, null, p - 1, p, p + 1, null, tp]
})

function ir(p) {
  if (p >= 1 && p <= totalPaginas.value) emit('update:pagina', p)
}

function mudarTamanho(e) {
  emit('update:porPagina', Number(e.target.value))
  emit('update:pagina', 1)
}
</script>

<template>
  <div v-if="total > 0" class="mt-5 flex flex-wrap items-center justify-between gap-3">
    <!-- Seletor de itens por pagina -->
    <div class="flex items-center gap-2 text-xs text-ink-soft">
      <span>Exibindo</span>
      <select
        :value="porPagina"
        class="rounded-lg border border-ink/15 bg-white px-2 py-1.5 text-xs text-ink outline-none focus:border-brand"
        @change="mudarTamanho"
      >
        <option v-for="op in opcoesPorPagina" :key="op" :value="op">{{ op }}</option>
      </select>
      <span>por página · <strong class="text-ink">{{ inicio }}–{{ fim }}</strong> de <strong class="text-ink">{{ total }}</strong></span>
    </div>

    <!-- Botoes de pagina -->
    <div class="flex items-center gap-1">
      <button
        :disabled="pagina === 1"
        class="flex h-8 w-8 items-center justify-center rounded-lg border border-ink/15 text-xs text-ink-soft transition-colors hover:border-brand hover:text-brand-deep disabled:opacity-30 disabled:cursor-default"
        @click="ir(pagina - 1)"
      >‹</button>

      <template v-for="(p, i) in paginas" :key="i">
        <span v-if="p === null" class="px-1 text-xs text-ink-soft">…</span>
        <button
          v-else
          :class="[
            'flex h-8 w-8 items-center justify-center rounded-lg border text-xs font-semibold transition-colors',
            p === pagina
              ? 'border-brand bg-brand text-white'
              : 'border-ink/15 text-ink hover:border-brand hover:text-brand-deep'
          ]"
          @click="ir(p)"
        >{{ p }}</button>
      </template>

      <button
        :disabled="pagina === totalPaginas"
        class="flex h-8 w-8 items-center justify-center rounded-lg border border-ink/15 text-xs text-ink-soft transition-colors hover:border-brand hover:text-brand-deep disabled:opacity-30 disabled:cursor-default"
        @click="ir(pagina + 1)"
      >›</button>
    </div>
  </div>
</template>

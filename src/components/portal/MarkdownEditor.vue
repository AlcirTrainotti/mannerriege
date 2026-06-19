<script setup>
import { ref } from 'vue'
import MarkdownContent from './MarkdownContent.vue'

const props = defineProps({
  modelValue: { type: String, default: '' },
  rows: { type: Number, default: 4 },
  placeholder: { type: String, default: '' },
})

const emit = defineEmits(['update:modelValue'])

const aba = ref('escrever')
</script>

<template>
  <div>
    <div class="mb-1.5 flex gap-1">
      <button
        type="button"
        class="rounded-full px-3 py-1 text-[11px] font-semibold transition-colors"
        :class="aba === 'escrever' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
        @click="aba = 'escrever'"
      >Escrever</button>
      <button
        type="button"
        class="rounded-full px-3 py-1 text-[11px] font-semibold transition-colors"
        :class="aba === 'visualizar' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
        @click="aba = 'visualizar'"
      >Visualizar</button>
    </div>

    <textarea
      v-if="aba === 'escrever'"
      :value="modelValue"
      :rows="rows"
      :placeholder="placeholder"
      class="w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand"
      @input="emit('update:modelValue', $event.target.value)"
    ></textarea>

    <div v-else class="min-h-[90px] rounded-xl border border-ink/15 bg-paper-dim px-4 py-3">
      <MarkdownContent v-if="modelValue.trim()" :content="modelValue" />
      <p v-else class="text-sm text-ink-soft/50">Nada para visualizar ainda.</p>
    </div>

    <p class="mt-1.5 text-[10px] text-ink-soft/70">
      Markdown: <code class="rounded bg-paper-dim px-1">**negrito**</code>
      <code class="rounded bg-paper-dim px-1">_itálico_</code>
      <code class="rounded bg-paper-dim px-1"># Título</code>
      <code class="rounded bg-paper-dim px-1">- item de lista</code>
      <code class="rounded bg-paper-dim px-1">[link](url)</code>
    </p>
  </div>
</template>

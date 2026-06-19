<script setup>
import { ref, computed, onMounted, watch, nextTick } from 'vue'
import { marked } from 'marked'
import DOMPurify from 'dompurify'

marked.setOptions({ breaks: true, gfm: true })

const props = defineProps({
  content: { type: String, default: '' },
  collapsible: { type: Boolean, default: false },
  collapsedHeight: { type: Number, default: 140 },
})

const expanded = ref(false)
const contentEl = ref(null)
const isOverflowing = ref(false)

const html = computed(() => DOMPurify.sanitize(marked.parse(props.content || '')))

async function medirOverflow() {
  expanded.value = false
  await nextTick()
  if (!props.collapsible || !contentEl.value) {
    isOverflowing.value = false
    return
  }
  isOverflowing.value = contentEl.value.scrollHeight > props.collapsedHeight + 8
}

onMounted(medirOverflow)
watch(() => props.content, medirOverflow)
</script>

<template>
  <div>
    <div class="relative">
      <div
        ref="contentEl"
        class="markdown-body overflow-hidden text-sm leading-relaxed text-ink-soft transition-[max-height] duration-300"
        :style="collapsible && !expanded ? { maxHeight: collapsedHeight + 'px' } : { maxHeight: 'none' }"
        v-html="html"
      />
      <div
        v-if="collapsible && !expanded && isOverflowing"
        class="pointer-events-none absolute inset-x-0 bottom-0 h-10 bg-gradient-to-t from-white to-transparent"
      />
    </div>
    <button
      v-if="collapsible && isOverflowing"
      type="button"
      class="mt-2 font-mono-label text-[10px] font-bold text-brand-deep hover:underline"
      @click="expanded = !expanded"
    >
      {{ expanded ? 'Ver menos' : 'Leia mais' }}
    </button>
  </div>
</template>

<style scoped>
.markdown-body :deep(h1),
.markdown-body :deep(h2),
.markdown-body :deep(h3) {
  font-family: var(--font-display);
  font-weight: 800;
  color: var(--color-ink);
  margin-top: 0.75em;
  margin-bottom: 0.35em;
  line-height: 1.2;
}
.markdown-body :deep(h1) { font-size: 1.3em; }
.markdown-body :deep(h2) { font-size: 1.15em; }
.markdown-body :deep(h3) { font-size: 1.05em; }
.markdown-body :deep(p) { margin: 0.5em 0; }
.markdown-body :deep(p:first-child) { margin-top: 0; }
.markdown-body :deep(p:last-child) { margin-bottom: 0; }
.markdown-body :deep(strong) { font-weight: 700; color: var(--color-ink); }
.markdown-body :deep(em) { font-style: italic; }
.markdown-body :deep(ul),
.markdown-body :deep(ol) {
  margin: 0.5em 0;
  padding-left: 1.25em;
}
.markdown-body :deep(ul) { list-style: disc; }
.markdown-body :deep(ol) { list-style: decimal; }
.markdown-body :deep(li) { margin: 0.2em 0; }
.markdown-body :deep(a) {
  color: var(--color-brand-deep);
  font-weight: 600;
  text-decoration: underline;
  text-underline-offset: 2px;
}
.markdown-body :deep(blockquote) {
  border-left: 3px solid var(--color-brand);
  padding-left: 0.75em;
  margin: 0.5em 0;
  color: var(--color-ink-soft);
  font-style: italic;
}
.markdown-body :deep(code) {
  background: var(--color-paper-dim);
  border-radius: 4px;
  padding: 0.1em 0.4em;
  font-family: var(--font-mono);
  font-size: 0.9em;
}
.markdown-body :deep(hr) {
  border: none;
  border-top: 1px solid rgb(24 19 15 / 0.1);
  margin: 0.75em 0;
}
</style>

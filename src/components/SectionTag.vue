<script setup>
defineProps({
  text: { type: String, required: true },
  dark: { type: Boolean, default: false },
})
</script>

<template>
  <p
    class="font-mono-label flex items-center gap-3 text-[11px] font-bold"
    :class="dark ? 'text-brand' : 'text-brand-deep'"
  >
    <span class="h-px w-6" :class="dark ? 'bg-brand' : 'bg-brand-deep'"></span>
    {{ text }}
  </p>
</template>

<script setup>
defineProps({
  value: { type: String, required: true },
  label: { type: String, required: true },
  light: { type: Boolean, default: false },
})
</script>

<template>
  <div>
    <p class="font-display text-5xl font-extrabold sm:text-6xl" :class="light ? 'text-white' : 'text-ink'">
      {{ value }}
    </p>
    <p class="mt-1 font-mono-label text-[11px] font-bold" :class="light ? 'text-paper/60' : 'text-ink-soft'">
      {{ label }}
    </p>
  </div>
</template>

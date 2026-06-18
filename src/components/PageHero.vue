<script setup>
defineProps({
  eyebrow: { type: String, default: '' },
  title: { type: String, required: true },
  subtitle: { type: String, default: '' },
})
</script>

<template>
  <section class="relative overflow-hidden bg-ink pb-20 pt-36 sm:pb-24 sm:pt-44">
    <div class="hatch-mark pointer-events-none absolute -right-10 top-16 h-40 w-40 rotate-12 text-brand/70 sm:h-56 sm:w-56"></div>
    <div class="pointer-events-none absolute -left-24 bottom-0 h-72 w-72 rounded-full bg-brand/10 blur-3xl"></div>

    <div class="relative mx-auto max-w-5xl px-5 sm:px-8">
      <p v-if="eyebrow" class="font-mono-label text-[11px] font-bold text-brand">{{ eyebrow }}</p>
      <h1 class="mt-4 font-display text-5xl font-extrabold uppercase text-white sm:text-6xl lg:text-7xl">
        {{ title }}
      </h1>
      <p v-if="subtitle" class="mt-5 max-w-2xl text-lg text-paper/70">{{ subtitle }}</p>
    </div>
  </section>
</template>

<script setup>
const props = defineProps({
  to: { type: String, default: null },
  href: { type: String, default: null },
  variant: { type: String, default: 'primary' }, // primary | outline-light | outline-dark | ghost
})

const variants = {
  primary: 'bg-brand text-white hover:bg-brand-deep shadow-card',
  'outline-light': 'border border-white/70 text-white hover:bg-white hover:text-ink',
  'outline-dark': 'border border-ink/25 text-ink hover:border-ink hover:bg-ink hover:text-white',
  ghost: 'text-brand-deep hover:text-brand',
}

const cls = variants[props.variant] || variants.primary
</script>

<template>
  <router-link
    v-if="to"
    :to="to"
    class="inline-flex items-center justify-center gap-2 rounded-full px-6 py-3.5 font-mono-label text-[11px] font-bold transition-all hover:-translate-y-0.5"
    :class="cls"
  >
    <slot />
  </router-link>
  <a
    v-else
    :href="href"
    target="_blank"
    rel="noopener"
    class="inline-flex items-center justify-center gap-2 rounded-full px-6 py-3.5 font-mono-label text-[11px] font-bold transition-all hover:-translate-y-0.5"
    :class="cls"
  >
    <slot />
  </a>
</template>

<script setup>
const props = defineProps({
  modelValue: { type: Number, default: 0 },
  readonly: { type: Boolean, default: false },
  size: { type: String, default: 'h-4 w-4' },
})

const emit = defineEmits(['update:modelValue'])

function selecionar(n) {
  if (props.readonly) return
  // Clicar na mesma estrela de novo limpa a avaliacao
  emit('update:modelValue', props.modelValue === n ? 0 : n)
}
</script>

<template>
  <div class="flex items-center gap-0.5">
    <button
      v-for="n in 5"
      :key="n"
      type="button"
      :disabled="readonly"
      :class="readonly ? 'cursor-default' : 'cursor-pointer'"
      @click="selecionar(n)"
    >
      <svg
        :class="[size, n <= modelValue ? 'text-gold' : 'text-ink/15']"
        viewBox="0 0 20 20"
        fill="currentColor"
      >
        <path d="M10 1.5l2.59 5.25 5.79.84-4.19 4.08.99 5.77L10 14.77l-5.18 2.67.99-5.77L1.62 7.59l5.79-.84L10 1.5z" />
      </svg>
    </button>
  </div>
</template>

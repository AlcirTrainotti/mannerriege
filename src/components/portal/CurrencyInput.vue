<script setup>
import { computed } from 'vue'

const props = defineProps({
  modelValue: { type: [Number, String], default: 0 },
})
const emit = defineEmits(['update:modelValue'])

function formatar(valorCentavos) {
  return (valorCentavos / 100).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' })
}

const exibicao = computed(() => {
  const centavos = Math.round((Number(props.modelValue) || 0) * 100)
  return formatar(centavos)
})

function aoDigitar(e) {
  // Mantem so digitos, trata como centavos (igual a maioria dos apps de banco)
  const digitos = e.target.value.replace(/\D/g, '')
  const centavos = digitos ? parseInt(digitos, 10) : 0
  e.target.value = formatar(centavos)
  emit('update:modelValue', centavos / 100)
}
</script>

<template>
  <input
    :value="exibicao"
    type="text"
    inputmode="numeric"
    placeholder="R$ 0,00"
    @input="aoDigitar"
  />
</template>

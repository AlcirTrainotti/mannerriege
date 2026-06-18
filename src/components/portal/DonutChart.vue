<script setup>
import { ref, onMounted, onUnmounted, watch } from 'vue'
import { Chart, ArcElement, Tooltip, Legend, DoughnutController } from 'chart.js'

Chart.register(ArcElement, Tooltip, Legend, DoughnutController)

const props = defineProps({
  labels: { type: Array, required: true },
  values: { type: Array, required: true },
  colors: { type: Array, required: true },
})

const canvas = ref(null)
let chart = null

function buildChart() {
  if (!canvas.value) return
  if (chart) { chart.destroy() }
  chart = new Chart(canvas.value, {
    type: 'doughnut',
    data: {
      labels: props.labels,
      datasets: [{
        data: props.values,
        backgroundColor: props.colors,
        borderWidth: 2,
        borderColor: '#faf6ef',
        hoverOffset: 6,
      }],
    },
    options: {
      cutout: '72%',
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: {
            label: (ctx) => ` ${ctx.label}: ${ctx.parsed}`,
          },
        },
      },
    },
  })
}

onMounted(buildChart)
watch(() => [props.values, props.labels], buildChart, { deep: true })
onUnmounted(() => { if (chart) chart.destroy() })
</script>

<template>
  <canvas ref="canvas" class="h-full w-full" />
</template>

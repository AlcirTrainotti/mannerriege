<script setup>
import { ref, onMounted, onUnmounted, watch } from 'vue'
import { Chart, LineElement, PointElement, LinearScale, CategoryScale, Tooltip, Legend, LineController, Filler } from 'chart.js'

Chart.register(LineElement, PointElement, LinearScale, CategoryScale, Tooltip, Legend, LineController, Filler)

// Mini gráfico de linha pra evolução de notas/avaliações ao longo do
// tempo — mesma paleta e sobriedade visual do DonutChart.vue.
const props = defineProps({
  labels: { type: Array, required: true },
  values: { type: Array, required: true },
  color: { type: String, default: '#ed1b24' }, // --color-brand
  max: { type: Number, default: 10 },
  min: { type: Number, default: 0 },
})

const canvas = ref(null)
let chart = null

function hexToRgba(hex, alpha) {
  const h = hex.replace('#', '')
  const r = parseInt(h.substring(0, 2), 16)
  const g = parseInt(h.substring(2, 4), 16)
  const b = parseInt(h.substring(4, 6), 16)
  return `rgba(${r}, ${g}, ${b}, ${alpha})`
}

function buildChart() {
  if (!canvas.value) return
  if (chart) { chart.destroy() }
  chart = new Chart(canvas.value, {
    type: 'line',
    data: {
      labels: props.labels,
      datasets: [{
        data: props.values,
        borderColor: props.color,
        backgroundColor: hexToRgba(props.color, 0.12),
        pointBackgroundColor: props.color,
        pointBorderColor: '#faf6ef',
        pointRadius: 3,
        pointHoverRadius: 4,
        borderWidth: 2,
        tension: 0.35,
        fill: true,
      }],
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        y: {
          min: props.min,
          max: props.max,
          grid: { color: 'rgba(24, 19, 15, 0.06)' },
          ticks: { color: '#4a423c', font: { size: 9 } },
        },
        x: {
          grid: { display: false },
          ticks: { color: '#4a423c', font: { size: 9 } },
        },
      },
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: {
            label: (ctx) => ` ${ctx.parsed.y}`,
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

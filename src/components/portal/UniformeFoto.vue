<script setup>
import { ref } from 'vue'
import { supabase } from '../../lib/supabase.js'

const props = defineProps({
  jogoId: { type: String, required: true },
  fotoUrl: { type: String, default: null },
  editable: { type: Boolean, default: true },
})

const emit = defineEmits(['update:fotoUrl'])

const uploading = ref(false)
const fileInput = ref(null)

function abrirSelector() {
  if (props.editable && !uploading.value) fileInput.value?.click()
}

async function aoSelecionarArquivo(e) {
  const file = e.target.files?.[0]
  if (!file) return

  if (file.size > 5 * 1024 * 1024) {
    alert('A foto deve ter no máximo 5 MB.')
    return
  }

  uploading.value = true
  const ext = file.name.split('.').pop()
  const caminho = `${props.jogoId}/foto.${ext}`

  const { error: upError } = await supabase.storage
    .from('uniformes')
    .upload(caminho, file, { upsert: true, contentType: file.type })

  if (upError) {
    alert('Não foi possível enviar a foto: ' + upError.message)
    uploading.value = false
    return
  }

  const { data } = supabase.storage.from('uniformes').getPublicUrl(caminho)
  const url = data.publicUrl + '?t=' + Date.now()

  await supabase.from('jogos_uniforme').update({ foto_url: url }).eq('id', props.jogoId)

  emit('update:fotoUrl', url)
  uploading.value = false
  e.target.value = ''
}
</script>

<template>
  <div
    class="group relative aspect-[4/3] w-full overflow-hidden rounded-xl bg-paper-dim"
    :class="editable ? 'cursor-pointer' : ''"
    @click="abrirSelector"
  >
    <img v-if="fotoUrl" :src="fotoUrl" alt="" class="h-full w-full object-cover" />
    <div v-else class="flex h-full w-full items-center justify-center text-ink-soft/40">
      <svg class="h-9 w-9" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
        <path d="M3 16.5l4.5-4.5a2 2 0 012.8 0L15 16.5M3 8.5h18M5 4h14a2 2 0 012 2v12a2 2 0 01-2 2H5a2 2 0 01-2-2V6a2 2 0 012-2z" stroke-linecap="round" stroke-linejoin="round" />
      </svg>
    </div>

    <div
      v-if="editable && !uploading"
      class="absolute inset-0 flex items-center justify-center bg-ink/0 opacity-0 transition-all group-hover:bg-ink/30 group-hover:opacity-100"
    >
      <span class="rounded-full bg-white px-3 py-1 text-xs font-semibold text-ink">{{ fotoUrl ? 'Trocar foto' : 'Adicionar foto' }}</span>
    </div>

    <div v-if="uploading" class="absolute inset-0 flex items-center justify-center bg-ink/30">
      <svg class="h-6 w-6 animate-spin text-white" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8z" />
      </svg>
    </div>

    <input
      ref="fileInput"
      type="file"
      accept="image/jpeg,image/png,image/webp"
      class="hidden"
      @click.stop
      @change="aoSelecionarArquivo"
    />
  </div>
</template>

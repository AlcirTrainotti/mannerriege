<script setup>
import { ref } from 'vue'
import { supabase } from '../../lib/supabase.js'

const props = defineProps({
  profileId: { type: String, required: true },
  avatarUrl: { type: String, default: null },
  nome: { type: String, default: '' },
  size: { type: String, default: 'md' }, // 'sm' | 'md' | 'lg'
  editable: { type: Boolean, default: false },
})

const emit = defineEmits(['update:avatarUrl'])

const uploading = ref(false)
const fileInput = ref(null)

const sizeClasses = {
  sm: 'h-10 w-10 text-sm',
  md: 'h-20 w-20 text-xl',
  lg: 'h-28 w-28 text-3xl',
}

function initials(nome) {
  return (nome || '?').split(' ').slice(0, 2).map((p) => p[0]).join('').toUpperCase()
}

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
  const caminho = `${props.profileId}/avatar.${ext}`

  // Faz upload (upsert = substitui se ja existir)
  const { error: upError } = await supabase.storage
    .from('avatares')
    .upload(caminho, file, { upsert: true, contentType: file.type })

  if (upError) {
    alert('Não foi possível enviar a foto: ' + upError.message)
    uploading.value = false
    return
  }

  // Pega a URL publica
  const { data } = supabase.storage.from('avatares').getPublicUrl(caminho)
  const url = data.publicUrl + '?t=' + Date.now() // cache bust

  // Salva no perfil
  await supabase.from('profiles').update({ avatar_url: url }).eq('id', props.profileId)

  emit('update:avatarUrl', url)
  uploading.value = false
  // Limpa o input para permitir re-upload do mesmo arquivo
  e.target.value = ''
}
</script>

<template>
  <div class="relative inline-block flex-shrink-0">
    <div
      :class="[
        sizeClasses[size],
        'overflow-hidden rounded-full bg-paper-dim flex items-center justify-center font-display font-extrabold text-ink-soft',
        editable && !uploading ? 'cursor-pointer ring-2 ring-transparent hover:ring-brand transition-all' : '',
        uploading ? 'opacity-60' : '',
      ]"
      :title="editable ? 'Clique para trocar a foto' : undefined"
      @click="abrirSelector"
    >
      <img
        v-if="avatarUrl"
        :src="avatarUrl"
        :alt="nome"
        class="h-full w-full object-cover"
      />
      <span v-else>{{ initials(nome) }}</span>

      <!-- Overlay de upload -->
      <div v-if="editable && !uploading" class="absolute inset-0 flex items-center justify-center rounded-full bg-ink/0 transition-colors hover:bg-ink/20">
        <svg v-if="!avatarUrl" class="hidden h-5 w-5 text-white group-hover:block" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5m-13.5-9L12 3m0 0l4.5 4.5M12 3v13.5" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      </div>

      <div v-if="uploading" class="absolute inset-0 flex items-center justify-center rounded-full bg-ink/30">
        <svg class="h-5 w-5 animate-spin text-white" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8z"/>
        </svg>
      </div>
    </div>

    <!-- Badge de edição -->
    <div
      v-if="editable"
      class="absolute bottom-0 right-0 flex h-6 w-6 cursor-pointer items-center justify-center rounded-full bg-brand text-white shadow-card hover:bg-brand-deep"
      @click="abrirSelector"
    >
      <svg class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
        <path d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931z" stroke-linecap="round" stroke-linejoin="round"/>
      </svg>
    </div>

    <input
      ref="fileInput"
      type="file"
      accept="image/jpeg,image/png,image/webp"
      class="hidden"
      @change="aoSelecionarArquivo"
    />
  </div>
</template>

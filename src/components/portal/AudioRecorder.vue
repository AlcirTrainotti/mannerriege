<script setup>
import { ref, onBeforeUnmount } from 'vue'
import { supabase } from '../../lib/supabase.js'

// Gravador de observação em áudio — pro professor deixar um recado
// falado em vez de digitar (mais prático no meio do treino). Grava
// direto no navegador (MediaRecorder), sobe pro bucket "audios-treino"
// e devolve a URL pública via v-model.
const props = defineProps({
  modelValue: { type: String, default: null }, // URL do áudio já salvo, se houver
  pathPrefix: { type: String, required: true }, // pasta dentro do bucket, ex: `evento-123/atleta-456`
})
const emit = defineEmits(['update:modelValue'])

const gravando = ref(false)
const enviando = ref(false)
const erro = ref('')
let mediaRecorder = null
let chunks = []
let streamAtual = null

function escolherMimeType() {
  const candidatos = ['audio/mp4', 'audio/webm;codecs=opus', 'audio/webm', 'audio/ogg']
  return candidatos.find((t) => window.MediaRecorder?.isTypeSupported?.(t)) ?? ''
}

function extensaoDoMime(mime) {
  if (mime.includes('mp4')) return 'm4a'
  if (mime.includes('webm')) return 'webm'
  if (mime.includes('ogg')) return 'ogg'
  return 'audio'
}

async function iniciarGravacao() {
  erro.value = ''
  if (!navigator.mediaDevices?.getUserMedia || !window.MediaRecorder) {
    erro.value = 'Gravação de áudio não é suportada neste navegador.'
    return
  }
  try {
    streamAtual = await navigator.mediaDevices.getUserMedia({ audio: true })
  } catch {
    erro.value = 'Não foi possível acessar o microfone — verifique a permissão do navegador.'
    return
  }
  const mimeType = escolherMimeType()
  chunks = []
  mediaRecorder = new MediaRecorder(streamAtual, mimeType ? { mimeType } : undefined)
  mediaRecorder.ondataavailable = (e) => { if (e.data.size > 0) chunks.push(e.data) }
  mediaRecorder.onstop = () => enviarGravacao(mimeType)
  mediaRecorder.start()
  gravando.value = true
}

function pararGravacao() {
  gravando.value = false
  mediaRecorder?.stop()
  streamAtual?.getTracks().forEach((t) => t.stop())
}

async function enviarGravacao(mimeType) {
  if (!chunks.length) return
  enviando.value = true
  const blob = new Blob(chunks, { type: mimeType || 'audio/webm' })
  const ext = extensaoDoMime(mimeType || '')
  const caminho = `${props.pathPrefix}/${Date.now()}.${ext}`

  const { error } = await supabase.storage.from('audios-treino').upload(caminho, blob, {
    upsert: true,
    contentType: blob.type,
  })

  if (error) {
    erro.value = 'Não foi possível enviar o áudio: ' + error.message
    enviando.value = false
    return
  }

  const { data } = supabase.storage.from('audios-treino').getPublicUrl(caminho)
  emit('update:modelValue', data.publicUrl)
  enviando.value = false
}

function remover() {
  emit('update:modelValue', null)
}

onBeforeUnmount(() => {
  streamAtual?.getTracks().forEach((t) => t.stop())
})
</script>

<template>
  <div class="flex flex-wrap items-center gap-2">
    <audio v-if="modelValue" :src="modelValue" controls class="h-8 max-w-[11rem]" />

    <button
      v-if="!gravando"
      type="button"
      :disabled="enviando"
      class="flex items-center gap-1.5 rounded-full border border-ink/15 px-3 py-1.5 text-xs font-semibold text-ink-soft hover:border-brand hover:text-brand-deep disabled:opacity-50"
      @click="iniciarGravacao"
    >
      <span class="h-2 w-2 rounded-full bg-brand"></span>
      {{ enviando ? 'Enviando...' : modelValue ? 'Regravar' : 'Gravar áudio' }}
    </button>
    <button
      v-else
      type="button"
      class="flex items-center gap-1.5 rounded-full bg-brand px-3 py-1.5 text-xs font-bold text-white animate-pulse"
      @click="pararGravacao"
    >
      <span class="h-2 w-2 rounded-sm bg-white"></span>
      Parar ({{ 'gravando...' }})
    </button>

    <button v-if="modelValue && !gravando" type="button" class="text-xs text-ink-soft hover:text-brand-deep" @click="remover">Remover</button>

    <p v-if="erro" class="w-full text-[11px] text-brand-deep">{{ erro }}</p>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useAuth } from '../../lib/useAuth.js'
import Icon from '../Icon.vue'

const { login, requestPasswordReset } = useAuth()

const email = ref('')
const password = ref('')
const errorMsg = ref('')
const sending = ref(false)
const mode = ref('login') // 'login' | 'recuperar'
const recoverySent = ref(false)

async function handleSubmit() {
  errorMsg.value = ''
  sending.value = true
  const error = await login(email.value, password.value)
  sending.value = false
  if (error) {
    errorMsg.value = error.message === 'Invalid login credentials'
      ? 'E-mail ou senha incorretos.'
      : 'Não foi possível entrar. Tente novamente.'
  }
}

async function handleRecovery() {
  errorMsg.value = ''
  sending.value = true
  const error = await requestPasswordReset(email.value)
  sending.value = false
  if (error) {
    errorMsg.value = 'Não foi possível enviar o link. Confira o e-mail digitado.'
    return
  }
  recoverySent.value = true
}
</script>

<template>
  <div class="mx-auto max-w-sm">
    <div class="flex flex-col items-center text-center">
      <div class="flex h-12 w-12 items-center justify-center rounded-full bg-brand-soft text-brand-deep">
        <Icon name="lock" class="h-5 w-5" />
      </div>
      <h1 class="mt-4 font-display text-3xl font-extrabold text-ink">Área do Associado</h1>
      <p class="mt-2 text-sm text-ink-soft">
        Acesso restrito a associados e diretoria do Mannerriege.
      </p>
    </div>

    <form v-if="mode === 'login'" class="mt-8 space-y-4" @submit.prevent="handleSubmit">
      <div>
        <label class="font-mono-label text-[10px] font-bold text-ink-soft">E-mail</label>
        <input v-model="email" type="email" required autocomplete="username" class="mt-2 w-full rounded-xl border border-ink/15 bg-white px-4 py-3 text-sm text-ink outline-none focus:border-brand" />
      </div>
      <div>
        <label class="font-mono-label text-[10px] font-bold text-ink-soft">Senha</label>
        <input v-model="password" type="password" required autocomplete="current-password" class="mt-2 w-full rounded-xl border border-ink/15 bg-white px-4 py-3 text-sm text-ink outline-none focus:border-brand" />
      </div>

      <p v-if="errorMsg" class="text-sm text-brand-deep">{{ errorMsg }}</p>

      <button type="submit" :disabled="sending" class="w-full rounded-full bg-brand px-6 py-3.5 font-mono-label text-[11px] font-bold text-white transition-colors hover:bg-brand-deep disabled:opacity-60">
        {{ sending ? 'Entrando...' : 'Entrar' }}
      </button>

      <button type="button" class="w-full text-center text-xs text-ink-soft hover:text-brand-deep" @click="mode = 'recuperar'; errorMsg = ''">
        Esqueci minha senha
      </button>

      <p class="pt-2 text-center text-xs text-ink-soft/70">
        Seu acesso é criado pela diretoria. Se ainda não recebeu um login, fale com a diretoria.
      </p>
    </form>

    <div v-else class="mt-8">
      <div v-if="!recoverySent" class="space-y-4">
        <div>
          <label class="font-mono-label text-[10px] font-bold text-ink-soft">E-mail cadastrado</label>
          <input v-model="email" type="email" required class="mt-2 w-full rounded-xl border border-ink/15 bg-white px-4 py-3 text-sm text-ink outline-none focus:border-brand" />
        </div>
        <p v-if="errorMsg" class="text-sm text-brand-deep">{{ errorMsg }}</p>
        <button type="button" :disabled="sending" class="w-full rounded-full bg-brand px-6 py-3.5 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep disabled:opacity-60" @click="handleRecovery">
          {{ sending ? 'Enviando...' : 'Enviar link de recuperação' }}
        </button>
      </div>
      <div v-else class="text-center">
        <Icon name="check" class="mx-auto h-8 w-8 text-brand" />
        <p class="mt-3 text-sm text-ink-soft">Se este e-mail estiver cadastrado, você vai receber um link para criar uma nova senha.</p>
      </div>
      <button type="button" class="mt-4 w-full text-center text-xs text-ink-soft hover:text-brand-deep" @click="mode = 'login'; errorMsg = ''; recoverySent = false">
        Voltar para o login
      </button>
    </div>
  </div>
</template>

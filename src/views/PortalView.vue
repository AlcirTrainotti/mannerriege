<script setup>
import { defineAsyncComponent } from 'vue'
import { useAuth } from '../lib/useAuth.js'
import LoginForm from '../components/portal/LoginForm.vue'

// So baixa o codigo do painel certo DEPOIS do login, e so o painel do
// proprio papel da pessoa - a tela de login em si fica leve e rapida.
const AssociadoPanel = defineAsyncComponent(() => import('../components/portal/AssociadoPanel.vue'))
const AdminPanel = defineAsyncComponent(() => import('../components/portal/AdminPanel.vue'))
const EsportivoPanel = defineAsyncComponent(() => import('../components/portal/EsportivoPanel.vue'))
const FinanceiroPanel = defineAsyncComponent(() => import('../components/portal/FinanceiroPanel.vue'))

const { user, profile, loading, profileError } = useAuth()
</script>

<template>
  <section class="min-h-[80vh] bg-paper-dim py-32">
    <div class="mx-auto max-w-5xl px-5 sm:px-8">
      <div v-if="loading" class="py-24 text-center text-sm text-ink-soft">Carregando...</div>

      <LoginForm v-else-if="!user" />

      <div v-else-if="profileError" class="mx-auto max-w-md rounded-2xl bg-white p-8 text-center shadow-card">
        <p class="text-sm text-brand-deep">Não foi possível carregar seu cadastro: {{ profileError }}</p>
        <p class="mt-2 text-xs text-ink-soft">Fale com a diretoria caso o problema continue.</p>
      </div>

      <AdminPanel v-else-if="profile?.role === 'admin'" />
      <EsportivoPanel v-else-if="profile?.role === 'coordenador_esportivo'" />
      <FinanceiroPanel v-else-if="profile?.role === 'tesoureiro'" />
      <AssociadoPanel v-else />
    </div>
  </section>
</template>

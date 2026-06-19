<script setup>
import { useAuth } from '../lib/useAuth.js'
import LoginForm from '../components/portal/LoginForm.vue'
import AssociadoPanel from '../components/portal/AssociadoPanel.vue'
import AdminPanel from '../components/portal/AdminPanel.vue'
import EsportivoPanel from '../components/portal/EsportivoPanel.vue'

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
      <AssociadoPanel v-else />
    </div>
  </section>
</template>

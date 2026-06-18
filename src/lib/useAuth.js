import { ref } from 'vue'
import { supabase } from './supabase'

// Estado compartilhado (um unico "singleton") entre todos os componentes
// que chamarem useAuth() - assim o login feito em um lugar reflete em todos.
const user = ref(null)
const profile = ref(null)
const loading = ref(true)
const profileError = ref(null)

async function loadProfile(userId) {
  profileError.value = null
  const { data, error } = await supabase.from('profiles').select('*').eq('id', userId).single()
  if (error) {
    profileError.value = error.message
    profile.value = null
    return
  }
  profile.value = data
}

let started = false
function start() {
  if (started) return
  started = true

  supabase.auth.getSession().then(async ({ data }) => {
    user.value = data.session?.user ?? null
    if (user.value) await loadProfile(user.value.id)
    loading.value = false
  })

  supabase.auth.onAuthStateChange(async (_event, session) => {
    user.value = session?.user ?? null
    if (user.value) {
      await loadProfile(user.value.id)
    } else {
      profile.value = null
    }
    loading.value = false
  })
}

async function login(email, password) {
  const { error } = await supabase.auth.signInWithPassword({ email, password })
  return error
}

async function requestPasswordReset(email) {
  const { error } = await supabase.auth.resetPasswordForEmail(email, {
    redirectTo: window.location.origin + window.location.pathname + '#/portal',
  })
  return error
}

async function logout() {
  await supabase.auth.signOut()
}

export function useAuth() {
  start()
  return { user, profile, loading, profileError, login, logout, requestPasswordReset }
}

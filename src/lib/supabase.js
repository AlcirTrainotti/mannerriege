import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  // Isso so aparece no console do navegador, nunca trava o site institucional.
  // Significa que o arquivo .env ainda nao foi preenchido com as chaves do
  // seu projeto Supabase - veja supabase/COMO_CONFIGURAR.md
  console.warn('Supabase nao configurado: preencha o arquivo .env (veja supabase/COMO_CONFIGURAR.md)')
}

export const supabase = createClient(supabaseUrl ?? '', supabaseAnonKey ?? '')

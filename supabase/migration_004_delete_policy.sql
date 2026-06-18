-- ============================================================
-- MANNERRIEGE - Permissao de exclusao de perfis para admins
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

create policy "Somente admin deleta perfis"
  on public.profiles for delete
  using (public.is_admin());

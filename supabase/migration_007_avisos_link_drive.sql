-- ============================================================
-- MANNERRIEGE - Link do Google Drive nos avisos
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

alter table public.avisos
  add column if not exists link_drive text;

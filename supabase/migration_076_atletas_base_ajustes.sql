-- ============================================================
-- MANNERRIEGE - Atletas: posição, vínculo com a matrícula de origem,
-- e utilitários pra evitar duplicar cadastro de responsável
-- Rode DEPOIS do migration_075.
-- ============================================================

-- Posição em quadra (mesmas opções já usadas em convidados)
alter table public.atletas_base
  add column if not exists posicao text check (posicao in ('ponteiro', 'libero', 'levantador', 'meio', 'oposto', 'tecnico', 'outro'));

-- Vínculo opcional com a inscrição/matrícula de origem (formulário
-- público /experiencia) — permite ligar o cadastro definitivo do
-- atleta à matrícula que deu origem a ele, sem recadastrar do zero.
alter table public.atletas_base
  add column if not exists inscricao_experiencia_id uuid references public.inscricoes_experiencia_base (id) on delete set null;

create index if not exists atletas_base_inscricao_experiencia_idx on public.atletas_base (inscricao_experiencia_id);

-- ------------------------------------------------------------
-- A equipe da base passa a poder LER (e atualizar o status de) as
-- inscrições da Experiência direto pelo portal — antes só dava pra ver
-- pelo Table Editor do Supabase. Continua não liberado pra
-- anon/responsável/atleta (dados sensíveis de contato de emergência e
-- saúde de menores).
-- ------------------------------------------------------------
create policy "Equipe da base le inscricoes de experiencia"
  on public.inscricoes_experiencia_base for select
  using (public.is_base());

create policy "Equipe da base atualiza status da inscricao"
  on public.inscricoes_experiencia_base for update
  using (public.is_base())
  with check (public.is_base());

-- Lista as inscrições ainda "ativas" (nem canceladas, nem já viradas
-- matrícula), pra vincular no cadastro de um atleta novo.
create function public.listar_inscricoes_experiencia_ativas()
returns table (
  id uuid, atleta_nome text, atleta_data_nascimento date, turma text,
  responsavel_nome text, responsavel_whatsapp text, responsavel_email text, status text
)
language sql
security definer
stable
set search_path = public
as $$
  select id, atleta_nome, atleta_data_nascimento, turma, responsavel_nome, responsavel_whatsapp, responsavel_email, status
  from public.inscricoes_experiencia_base
  where status not in ('cancelada', 'matricula') and public.is_base()
  order by criado_em desc;
$$;

-- ------------------------------------------------------------
-- Evita duplicar cadastro de responsável: busca por telefone ou e-mail
-- um responsavel_base já existente, pra reaproveitar em vez de criar
-- um login novo (útil quando dois irmãos entram no projeto).
-- ------------------------------------------------------------
create function public.buscar_responsavel_base(p_telefone text, p_email text)
returns table (id uuid, nome text, telefone text, email text)
language sql
security definer
stable
set search_path = public
as $$
  select id, nome, telefone, email
  from public.profiles
  where role = 'responsavel_base'
    and public.is_base()
    and (
      (p_telefone is not null and p_telefone <> '' and telefone = p_telefone)
      or (p_email is not null and p_email <> '' and email = p_email)
    )
  order by criado_em
  limit 1;
$$;

-- ============================================================
-- MANNERRIEGE - Fluxo do professor: preparar aula (objetivo +
-- exercícios), chamada, iniciar/finalizar treino, avaliação por
-- estrelas + observações (texto ou áudio), relatório automático.
-- Rode DEPOIS do migration_098.
-- ============================================================

-- Preparo da aula + estado de execução da sessão. plano_atividades
-- (migration_077) continua existindo como o resumo em texto livre já
-- exibido pro responsável/atleta ("o que foi feito"); objetivo é novo
-- e os exercícios estruturados vão pra tabela evento_exercicios_base.
alter table public.eventos_base
  add column objetivo text,
  add column status_execucao text not null default 'planejado'
    check (status_execucao in ('planejado', 'em_andamento', 'concluido')),
  add column iniciado_em timestamptz,
  add column concluido_em timestamptz,
  add column observacoes_audio_url text;

comment on column public.eventos_base.objetivo is
  'Objetivo da aula/treino, definido pelo professor no preparo.';
comment on column public.eventos_base.status_execucao is
  'planejado -> em_andamento (professor fez a chamada e clicou em Iniciar treino) -> concluido (professor finalizou; relatório fica disponível).';
comment on column public.eventos_base.observacoes_audio_url is
  'Áudio opcional da observação geral do treino (bucket audios-treino), complementa o texto em observacoes.';

alter table public.evento_participantes_base
  add column desempenho_obs_audio_url text;

comment on column public.evento_participantes_base.desempenho_obs_audio_url is
  'Áudio opcional da observação do professor sobre este atleta neste evento (bucket audios-treino), complementa o texto em desempenho_obs.';

-- Exercícios planejados pra cada aula/evento (lista ordenada)
create table public.evento_exercicios_base (
  id uuid primary key default gen_random_uuid(),
  evento_id uuid not null references public.eventos_base (id) on delete cascade,
  ordem integer not null default 0,
  nome text not null,
  descricao text,
  duracao_min integer,
  criado_em timestamptz not null default now()
);

alter table public.evento_exercicios_base enable row level security;

create policy "Equipe da base gerencia exercicios"
  on public.evento_exercicios_base for all
  using (public.is_base())
  with check (public.is_base());

create policy "Participantes da base leem exercicios"
  on public.evento_exercicios_base for select
  using (public.is_participante_base());

-- Bucket de áudio das observações do treino (mesmo padrão do bucket
-- "avatares", migration_005: público pra leitura, restrito pra escrita)
insert into storage.buckets (id, name, public)
values ('audios-treino', 'audios-treino', true)
on conflict (id) do nothing;

create policy "Audios de treino visiveis para todos"
  on storage.objects for select
  using (bucket_id = 'audios-treino');

create policy "Equipe da base envia audio de treino"
  on storage.objects for insert
  with check (bucket_id = 'audios-treino' and public.is_base());

create policy "Equipe da base atualiza audio de treino"
  on storage.objects for update
  using (bucket_id = 'audios-treino' and public.is_base());

create policy "Equipe da base remove audio de treino"
  on storage.objects for delete
  using (bucket_id = 'audios-treino' and public.is_base());

-- Autoatendimento do professor/coordenador: nome/telefone/email —
-- mesma lógica do responsável (migration_096). Foto usa a policy
-- genérica de avatar próprio que já existe (migration_005); senha é
-- self-service via supabase.auth.updateUser(), sem policy nova.
create function public.atualizar_meu_perfil_professor_base(p_nome text, p_telefone text, p_email text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from public.profiles where id = auth.uid() and role in ('professor_base', 'coordenador_base')) then
    raise exception 'Somente professores ou coordenadores da base podem usar esta função';
  end if;

  update public.profiles
    set nome = coalesce(nullif(trim(p_nome), ''), nome),
        telefone = coalesce(nullif(trim(p_telefone), ''), telefone),
        email = coalesce(nullif(trim(p_email), ''), email)
    where id = auth.uid();
end;
$$;

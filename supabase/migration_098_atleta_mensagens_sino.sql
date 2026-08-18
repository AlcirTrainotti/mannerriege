-- ============================================================
-- MANNERRIEGE - Atleta ganha acesso ao canal de mensagens da própria
-- família (mesmo canal que o(s) responsável(is) já usam, identificado
-- por responsavel_id) e ao sino de notificações. Não criamos um canal
-- separado por atleta — é o mesmo modelo "1 canal por família" que já
-- existia, só que agora mais de uma pessoa da família pode escrever
-- nele (responsável e atleta).
-- Rode DEPOIS do migration_097.
-- ============================================================

-- Descobre se o atleta logado (auth.uid()) é "filho" do responsável
-- dono de um canal — ou seja, se pode ler/escrever nesse canal.
create function public.sou_atleta_do_responsavel(p_responsavel_id uuid)
returns boolean as $$
  select exists (
    select 1
    from public.atletas_base a
    join public.atleta_responsaveis ar on ar.atleta_id = a.id
    where a.profile_id = auth.uid()
      and ar.responsavel_id = p_responsavel_id
  );
$$ language sql security definer stable set search_path = public;

-- Diz ao frontend do atleta qual é o "responsavel_id" do canal dele
-- (o canal é sempre por família, não por atleta). Se o atleta tiver
-- mais de um responsável vinculado, prioriza o marcado como contato
-- preferencial; senão, o vínculo mais antigo.
create function public.meu_canal_mensagens_base()
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select ar.responsavel_id
  from public.atletas_base a
  join public.atleta_responsaveis ar on ar.atleta_id = a.id
  where a.profile_id = auth.uid()
  order by ar.contato_preferencial desc, ar.criado_em asc
  limit 1;
$$;

create policy "Atleta ve mensagens do canal da familia"
  on public.mensagens_base for select
  using (public.sou_atleta_do_responsavel(responsavel_id));

create policy "Atleta envia mensagens no canal da familia"
  on public.mensagens_base for insert
  with check (public.sou_atleta_do_responsavel(responsavel_id) and autor_id = auth.uid());

create policy "Atleta marca como lida no canal da familia"
  on public.mensagens_base for update
  using (public.sou_atleta_do_responsavel(responsavel_id))
  with check (public.sou_atleta_do_responsavel(responsavel_id));

-- listar_canais_mensagens_base() (equipe) contava só mensagens com
-- autor_id = responsavel_id como "não lidas" — agora que o atleta
-- também escreve no canal com o próprio autor_id (diferente do
-- responsavel_id), isso subcontava. Conserta contando qualquer
-- mensagem não lida cujo autor seja alguém da família (responsável ou
-- atleta), não só o dono do canal. Mesma assinatura, então
-- create or replace basta (sem precisar dropar).
create or replace function public.listar_canais_mensagens_base()
returns table (
  responsavel_id uuid,
  responsavel_nome text,
  ultima_mensagem text,
  ultima_mensagem_em timestamptz,
  nao_lidas integer
)
language sql
security definer
stable
set search_path = public
as $$
  select
    p.id as responsavel_id,
    p.nome as responsavel_nome,
    (select corpo from public.mensagens_base m2 where m2.responsavel_id = p.id order by m2.criado_em desc limit 1) as ultima_mensagem,
    (select criado_em from public.mensagens_base m2 where m2.responsavel_id = p.id order by m2.criado_em desc limit 1) as ultima_mensagem_em,
    (
      select count(*)::integer
      from public.mensagens_base m3
      join public.profiles pa on pa.id = m3.autor_id
      where m3.responsavel_id = p.id
        and pa.role in ('responsavel_base', 'atleta_base')
        and not m3.lida
    ) as nao_lidas
  from public.profiles p
  where p.role = 'responsavel_base'
    and public.is_base()
    and exists (select 1 from public.mensagens_base m where m.responsavel_id = p.id)
  order by ultima_mensagem_em desc nulls last;
$$;

-- Lista as mensagens de um canal já com o nome de quem escreveu —
-- usada por equipe, responsável e atleta, já que agora um canal pode
-- ter mais de um autor do lado da família. A leitura direta da tabela
-- (select *) continua funcionando via RLS, isso aqui só evita cada
-- tela ter que resolver o nome do autor na mão.
create function public.mensagens_canal_base(p_responsavel_id uuid)
returns table (
  id uuid,
  responsavel_id uuid,
  autor_id uuid,
  autor_nome text,
  corpo text,
  destino text,
  lida boolean,
  criado_em timestamptz
)
language sql
security definer
stable
set search_path = public
as $$
  select m.id, m.responsavel_id, m.autor_id, p.nome as autor_nome, m.corpo, m.destino, m.lida, m.criado_em
  from public.mensagens_base m
  left join public.profiles p on p.id = m.autor_id
  where m.responsavel_id = p_responsavel_id
    and (
      public.is_base()
      or p_responsavel_id = auth.uid()
      or public.sou_atleta_do_responsavel(p_responsavel_id)
    )
  order by m.criado_em asc;
$$;

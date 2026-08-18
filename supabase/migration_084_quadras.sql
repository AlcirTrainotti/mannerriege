-- ============================================================
-- MANNERRIEGE - Cadastro centralizado de Quadras
-- Rode DEPOIS do migration_083.
--
-- Registro único de quadras/ginásios usado tanto pelo Vôlei Master
-- (EsportivoPanel) quanto pelas Categorias de Base (BaseCoordenadorPanel)
-- — endereço completo, valor de locação (com possibilidade de desconto
-- temporário), fotos, infraestrutura (alimentação, estacionamento,
-- banheiros/vestiário, arquibancada) e avaliação geral 1-5.
-- ============================================================

create table public.quadras (
  id uuid primary key default gen_random_uuid(),
  nome text not null,

  endereco_rua text,
  endereco_numero text,
  endereco_complemento text,
  endereco_bairro text,
  endereco_cidade text,
  endereco_uf text,
  endereco_cep text,

  valor_locacao numeric(10, 2),
  desconto_ativo boolean not null default false,
  desconto_descricao text, -- ex: "20% até dez/2026", "gratuito em parceria"
  desconto_valor numeric(10, 2), -- valor já com desconto aplicado, se souberem

  info_alimentacao text,
  info_estacionamento text,
  info_banheiros_vestiario text,
  tem_arquibancada boolean,
  info_arquibancada text,
  qualidade_estrutura integer check (qualidade_estrutura between 1 and 5),
  qualificacao_geral integer check (qualificacao_geral between 1 and 5),
  observacoes text,

  ativo boolean not null default true,
  criado_por uuid references public.profiles (id),
  criado_em timestamptz not null default now()
);

comment on column public.quadras.qualidade_estrutura is 'Avaliação 1-5 da estrutura física da quadra em si (piso, iluminação, rede etc).';
comment on column public.quadras.qualificacao_geral is 'Avaliação geral 1-5 do local (experiência completa).';

create table public.quadra_fotos (
  id uuid primary key default gen_random_uuid(),
  quadra_id uuid not null references public.quadras (id) on delete cascade,
  url text not null,
  storage_path text not null,
  criado_em timestamptz not null default now()
);

alter table public.quadras enable row level security;
alter table public.quadra_fotos enable row level security;

-- Gerencia (cria/edita/exclui): coordenação esportiva do Master ou
-- coordenação das Categorias de Base — registro compartilhado pelos dois.
create policy "Coordenacao gerencia quadras"
  on public.quadras for all
  using (public.is_esportivo() or public.is_coordenador_base())
  with check (public.is_esportivo() or public.is_coordenador_base());

create policy "Staff le quadras"
  on public.quadras for select
  using (public.is_esportivo() or public.is_base());

create policy "Coordenacao gerencia fotos de quadras"
  on public.quadra_fotos for all
  using (public.is_esportivo() or public.is_coordenador_base())
  with check (public.is_esportivo() or public.is_coordenador_base());

create policy "Staff le fotos de quadras"
  on public.quadra_fotos for select
  using (public.is_esportivo() or public.is_base());

-- Bucket público de fotos das quadras (mesmo padrão dos outros buckets
-- do app: caminho com UUID aleatório em vez de controle de acesso fino).
insert into storage.buckets (id, name, public) values ('quadras', 'quadras', true)
on conflict (id) do nothing;

create policy "Leitura publica de fotos de quadras"
  on storage.objects for select
  using (bucket_id = 'quadras');

create policy "Coordenacao envia fotos de quadras"
  on storage.objects for insert
  with check (bucket_id = 'quadras' and (public.is_esportivo() or public.is_coordenador_base()));

create policy "Coordenacao remove fotos de quadras"
  on storage.objects for delete
  using (bucket_id = 'quadras' and (public.is_esportivo() or public.is_coordenador_base()));

// ============================================================
// DADOS DO SITE — edite este arquivo para atualizar informacoes
// que aparecem em varias paginas (rodape, contato, diretoria...).
// Campos marcados como "ATENCAO" devem ser confirmados/preenchidos
// antes de publicar o site.
// ============================================================

export const siteConfig = {
  brandName: 'Mannerriege',
  fullName: 'Mannerriege Vôlei Master',
  legalName: 'Mannerriege Associação Desportiva de Voleibol',
  // ATENCAO: confirme a grafia oficial (Mannerriege x Manneriegue) no Estatuto/CNPJ
  cnpj: '59.879.461/0001-29',

  foundedYear: 1949,
  foundedMonth: 'março',

  address: {
    street: 'Rua dos Ginásticos, nº 96',
    district: 'Centro',
    city: 'Joinville',
    state: 'SC',
  },

  // ATENCAO: substitua pelos dados reais antes de publicar
  email: 'contato@mannerriege.com.br',
  phone: '(47) 99999-9999',
  whatsappNumber: '5547999999999',

  instagramHandle: '@mannerriege',
  instagramUrl: 'https://instagram.com/mannerriege',

  diretoria: {
    presidente: 'Eduardo Perini de Aviz',
    vicePresidente: 'Ricardo Perini de Aviz',
    gestao: '2026/2027',
  },

  categorias: ['35+', '40+', '45+', '50+', '55+', '60+'],
  associados: '40+',
}

export function anosDeHistoria() {
  return new Date().getFullYear() - siteConfig.foundedYear
}

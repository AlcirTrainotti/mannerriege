import { createRouter, createWebHashHistory } from 'vue-router'

const routes = [
  {
    path: '/',
    name: 'home',
    component: () => import('../views/HomeView.vue'),
    meta: { title: 'Início' },
  },
  {
    path: '/sobre',
    name: 'sobre',
    component: () => import('../views/SobreView.vue'),
    meta: { title: 'Sobre' },
  },
  {
    path: '/historia',
    name: 'historia',
    component: () => import('../views/HistoriaView.vue'),
    meta: { title: 'Nossa História' },
  },
  {
    path: '/projetos',
    name: 'projetos',
    component: () => import('../views/ProjetosView.vue'),
    meta: { title: 'Projetos' },
  },
  {
    path: '/diretoria',
    name: 'diretoria',
    component: () => import('../views/DiretoriaView.vue'),
    meta: { title: 'Diretoria' },
  },
  {
    path: '/transparencia',
    name: 'transparencia',
    component: () => import('../views/TransparenciaView.vue'),
    meta: { title: 'Transparência' },
  },
  {
    path: '/apoie',
    name: 'apoie',
    component: () => import('../views/ApoieView.vue'),
    meta: { title: 'Apoie' },
  },
  {
    path: '/contato',
    name: 'contato',
    component: () => import('../views/ContatoView.vue'),
    meta: { title: 'Contato' },
  },
  {
    path: '/privacidade',
    name: 'privacidade',
    component: () => import('../views/PrivacidadeView.vue'),
    meta: { title: 'Política de Privacidade' },
  },
  {
    path: '/portal',
    name: 'portal',
    component: () => import('../views/PortalView.vue'),
    meta: { title: 'Área do Associado' },
  },
]

// Hash history: funciona em qualquer hospedagem estatica (Netlify, Vercel,
// GitHub Pages, etc.) sem precisar configurar regras de redirecionamento
// no servidor para as sub-rotas.
const router = createRouter({
  history: createWebHashHistory(),
  routes,
  scrollBehavior(to) {
    if (to.hash) {
      return { el: to.hash, behavior: 'smooth', top: 88 }
    }
    return { top: 0 }
  },
})

router.afterEach((to) => {
  const base = 'Mannerriege Vôlei'
  document.title = to.meta?.title ? `${to.meta.title} | ${base}` : base
})

export default router

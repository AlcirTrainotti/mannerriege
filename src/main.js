import { createApp } from 'vue'
import './style.css'
import App from './App.vue'
import router from './router'

const app = createApp(App)

// Diretiva simples de "scroll reveal": adiciona a classe .reveal
// e, quando o elemento entra na tela, adiciona .reveal-visible.
// Sem dependencia externa - so IntersectionObserver nativo.
app.directive('reveal', {
  mounted(el, binding) {
    el.classList.add('reveal')
    const delayMs = typeof binding.value === 'number' ? binding.value : 0
    if (delayMs) el.style.transitionDelay = `${delayMs}ms`

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            el.classList.add('reveal-visible')
            observer.unobserve(el)
          }
        })
      },
      { threshold: 0.15, rootMargin: '0px 0px -40px 0px' }
    )
    observer.observe(el)
  },
})

app.use(router)
app.mount('#app')

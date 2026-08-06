// Motion do site Mannerriege — vanilla JS, sem dependência externa.
// Três comportamentos: scroll reveal, contadores animados, botões magnéticos.
// Tudo desligado automaticamente se prefers-reduced-motion estiver ativo.

const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches

function initReveal() {
  const els = document.querySelectorAll('.reveal')
  if (reduceMotion) {
    els.forEach((el) => el.classList.add('reveal-visible'))
    return
  }
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add('reveal-visible')
          observer.unobserve(entry.target)
        }
      })
    },
    { threshold: 0.15, rootMargin: '0px 0px -40px 0px' }
  )
  els.forEach((el) => observer.observe(el))
}

function initCounters() {
  const els = document.querySelectorAll('.js-counter')
  const animate = (el) => {
    const to = Number(el.dataset.counterTo || '0')
    const suffix = el.dataset.counterSuffix || ''
    if (reduceMotion) {
      el.textContent = `${to}${suffix}`
      return
    }
    const duration = 1400
    const start = performance.now()
    const step = (now) => {
      const progress = Math.min((now - start) / duration, 1)
      const eased = 1 - Math.pow(1 - progress, 3)
      el.textContent = `${Math.round(eased * to)}${suffix}`
      if (progress < 1) requestAnimationFrame(step)
    }
    requestAnimationFrame(step)
  }
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          animate(entry.target)
          observer.unobserve(entry.target)
        }
      })
    },
    { threshold: 0.4 }
  )
  els.forEach((el) => observer.observe(el))
}

function initMagnetic() {
  if (reduceMotion) return
  const els = document.querySelectorAll('.js-magnetic')
  els.forEach((el) => {
    el.addEventListener('mousemove', (e) => {
      const rect = el.getBoundingClientRect()
      const x = e.clientX - rect.left - rect.width / 2
      const y = e.clientY - rect.top - rect.height / 2
      el.style.setProperty('--mx', `${x * 0.25}px`)
      el.style.setProperty('--my', `${y * 0.35}px`)
    })
    el.addEventListener('mouseleave', () => {
      el.style.setProperty('--mx', '0px')
      el.style.setProperty('--my', '0px')
    })
  })
}

function initTrophyTrack() {
  const track = document.querySelector('.js-trophy-track')
  const prev = document.querySelector('.js-trophy-prev')
  const next = document.querySelector('.js-trophy-next')
  if (!track) return
  const scrollAmount = () => track.clientWidth * 0.8
  prev?.addEventListener('click', () => track.scrollBy({ left: -scrollAmount(), behavior: 'smooth' }))
  next?.addEventListener('click', () => track.scrollBy({ left: scrollAmount(), behavior: 'smooth' }))
}

function init() {
  initReveal()
  initCounters()
  initMagnetic()
  initTrophyTrack()
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init)
} else {
  init()
}

// Astro View Transitions: reexecutar depois de cada troca de página
document.addEventListener('astro:page-load', init)

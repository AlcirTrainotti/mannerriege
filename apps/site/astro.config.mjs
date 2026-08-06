import { defineConfig } from 'astro/config'
import vue from '@astrojs/vue'
import tailwindcss from '@tailwindcss/vite'

// https://astro.build/config
export default defineConfig({
  site: 'https://mannerriege.com.br',
  integrations: [vue()],
  vite: {
    plugins: [tailwindcss()],
  },
})

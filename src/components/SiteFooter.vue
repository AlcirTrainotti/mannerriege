<script setup>
import logo from '../assets/img/logo.png'
import { siteConfig, anosDeHistoria } from '../data/site.js'

const year = new Date().getFullYear()
</script>

<template>
  <footer class="bg-ink text-paper">
    <div class="hatch-mark h-2 text-brand"></div>

    <div class="mx-auto max-w-7xl px-5 py-16 sm:px-8">
      <div class="grid gap-12 sm:grid-cols-2 lg:grid-cols-[1.3fr_1fr_1fr_1fr]">
        <div>
          <router-link to="/" class="flex items-center gap-3">
            <img :src="logo" alt="Escudo Mannerriege" class="h-14 w-auto" />
            <span class="font-display text-2xl font-extrabold text-white">MANNERRIEGE</span>
          </router-link>
          <p class="mt-5 max-w-xs text-sm leading-relaxed text-paper/70">
            Tradição joinvilense que forma o futuro. Desde {{ siteConfig.foundedYear }}, voleibol,
            amizade e desenvolvimento humano em Joinville/SC.
          </p>
          <p class="mt-5 font-mono-label text-[11px] text-brand">{{ anosDeHistoria() }}+ anos de história</p>
        </div>

        <div>
          <p class="font-mono-label text-[11px] text-paper/45">Institucional</p>
          <ul class="mt-4 space-y-3 text-sm">
            <li><router-link to="/sobre" class="text-paper/80 hover:text-white">Sobre</router-link></li>
            <li><router-link to="/historia" class="text-paper/80 hover:text-white">Nossa História</router-link></li>
            <li><router-link to="/projetos" class="text-paper/80 hover:text-white">Vôlei de Base</router-link></li>
            <li><router-link to="/diretoria" class="text-paper/80 hover:text-white">Diretoria</router-link></li>
            <li><router-link to="/transparencia" class="text-paper/80 hover:text-white">Transparência</router-link></li>
          </ul>
        </div>

        <div>
          <p class="font-mono-label text-[11px] text-paper/45">Participe</p>
          <ul class="mt-4 space-y-3 text-sm">
            <li><router-link to="/apoie" class="text-paper/80 hover:text-white">Seja parceiro</router-link></li>
            <li><router-link to="/contato" class="text-paper/80 hover:text-white">Fale conosco</router-link></li>
            <li><router-link to="/privacidade" class="text-paper/80 hover:text-white">Política de Privacidade</router-link></li>
          </ul>
        </div>

        <div>
          <p class="font-mono-label text-[11px] text-paper/45">Contato</p>
          <ul class="mt-4 space-y-3 text-sm text-paper/80">
            <li>{{ siteConfig.address.street }}<br />{{ siteConfig.address.district }}, {{ siteConfig.address.city }}/{{ siteConfig.address.state }}</li>
            <li><a :href="`mailto:${siteConfig.email}`" class="hover:text-white">{{ siteConfig.email }}</a></li>
            <li>
              <a :href="siteConfig.instagramUrl" target="_blank" rel="noopener" class="hover:text-white">{{ siteConfig.instagramHandle }} no Instagram</a>
            </li>
          </ul>
        </div>
      </div>

      <div class="mt-14 flex flex-col gap-3 border-t border-white/10 pt-8 text-xs text-paper/50 sm:flex-row sm:items-center sm:justify-between">
        <p>{{ siteConfig.legalName }} — CNPJ {{ siteConfig.cnpj }}</p>
        <p>&copy; {{ year }} Mannerriege. Tradição joinvilense que forma o futuro.</p>
      </div>
    </div>
  </footer>
</template>

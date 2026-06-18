<script setup>
defineProps({
  name: { type: String, required: true },
})
</script>

<template>
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
    <template v-if="name === 'volleyball'">
      <circle cx="12" cy="12" r="9" />
      <path d="M12 3c2.5 2 3.8 5.2 3.4 9-0.4 3.8-2.6 6.7-3.4 9" />
      <path d="M12 3c-2.5 2-3.8 5.2-3.4 9 .4 3.8 2.6 6.7 3.4 9" />
      <path d="M3.3 9.3c2.8 1 5.9 1 8.7 0 2.8-1 5.9-1 8.7 0" />
      <path d="M3.3 14.7c2.8-1 5.9-1 8.7 0 2.8 1 5.9 1 8.7 0" />
    </template>

    <template v-else-if="name === 'users'">
      <circle cx="9" cy="8" r="3.2" />
      <path d="M2.8 19c0-3.4 2.8-6 6.2-6s6.2 2.6 6.2 6" />
      <circle cx="17" cy="7.6" r="2.4" />
      <path d="M15.5 13.2c2.6.4 4.7 2.6 4.7 5.6" />
    </template>

    <template v-else-if="name === 'calendar'">
      <rect x="3.5" y="5" width="17" height="15.5" rx="2" />
      <path d="M3.5 9.5h17" />
      <path d="M8 3v4M16 3v4" />
      <path d="M7.5 13.5h2M11 13.5h2M14.5 13.5h2M7.5 17h2M11 17h2" />
    </template>

    <template v-else-if="name === 'handshake'">
      <path d="M2.5 12.5l4-3.5 3 2 3-2.6 3 2.4 5.5-3.3" />
      <path d="M5 10l4.6 5.4a1.7 1.7 0 002.4.2l.6-.5" />
      <path d="M9.5 14.7l1 1.1a1.6 1.6 0 002.3.1l.5-.4" />
      <path d="M12.8 12.7l1.3 1.5a1.5 1.5 0 002.1.1" />
      <path d="M19.5 9.2l2 1.3-3 5.3-2.3-1.4" />
      <path d="M2.5 12.5l1.8 3.6 2.4 1.6" />
    </template>

    <template v-else-if="name === 'briefcase'">
      <rect x="3" y="7.5" width="18" height="12" rx="2" />
      <path d="M8 7.5V6a2.5 2.5 0 012.5-2.5h3A2.5 2.5 0 0116 6v1.5" />
      <path d="M3 13h18" />
      <path d="M10.5 13v1.4h3V13" />
    </template>

    <template v-else-if="name === 'shield'">
      <path d="M12 3l7.5 3v5.4c0 5-3.2 8.2-7.5 9.6-4.3-1.4-7.5-4.6-7.5-9.6V6L12 3z" />
      <path d="M9 12.2l2.1 2.1L15.3 10" />
    </template>

    <template v-else-if="name === 'heart'">
      <path d="M12 20s-7.5-4.6-9.6-9.4C1 7 2.6 3.8 6 3.2c2-.3 3.8.6 6 2.7 2.2-2.1 4-3 6-2.7 3.4.6 5 3.8 3.6 7.4C19.5 15.4 12 20 12 20z" />
    </template>

    <template v-else-if="name === 'trophy'">
      <path d="M7 4h10v5a5 5 0 01-10 0V4z" />
      <path d="M7 6H4.5A2.5 2.5 0 005 11h2M17 6h2.5A2.5 2.5 0 0119 11h-2" />
      <path d="M10 16.5h4M12 14v3.5M8.5 20.5h7l-1-3h-5l-1 3z" />
    </template>

    <template v-else-if="name === 'mail'">
      <rect x="3" y="5.5" width="18" height="13" rx="2" />
      <path d="M4 7l8 6 8-6" />
    </template>

    <template v-else-if="name === 'whatsapp'">
      <path d="M7 18.5L4 20l1.5-3.3A8 8 0 1112 20a8 8 0 01-5-1.5z" />
      <path d="M9.2 9.6c.2 2.6 2.4 4.8 5 5l1-1.6-2-1-.7.7a4.4 4.4 0 01-2.4-2.4l.7-.7-1-2-1.6 1z" />
    </template>

    <template v-else-if="name === 'instagram'">
      <rect x="3.5" y="3.5" width="17" height="17" rx="4.5" />
      <circle cx="12" cy="12" r="3.6" />
      <circle cx="17" cy="7" r="0.6" fill="currentColor" />
    </template>

    <template v-else-if="name === 'check'">
      <path d="M5 12.5l4.5 4.5L19 7.5" />
    </template>

    <template v-else-if="name === 'arrow-right'">
      <path d="M4.5 12h15M14.5 6.5L20 12l-5.5 5.5" />
    </template>

    <template v-else-if="name === 'megaphone'">
      <path d="M3 10.5v3a1.5 1.5 0 001.5 1.5H6l8.5 4V5L6 9H4.5A1.5 1.5 0 003 10.5z" />
      <path d="M18 9.5a3.3 3.3 0 010 5" />
      <path d="M6.5 15.5l1 4.5" />
    </template>

    <template v-else-if="name === 'doc'">
      <path d="M6.5 3h7l4 4v13a1 1 0 01-1 1h-10a1 1 0 01-1-1V4a1 1 0 011-1z" />
      <path d="M13.5 3v4h4" />
      <path d="M8.5 12.5h7M8.5 15.5h7M8.5 9.5h3" />
    </template>

    <template v-else-if="name === 'pin'">
      <path d="M12 21s-6.5-5.6-6.5-11A6.5 6.5 0 1118.5 10c0 5.4-6.5 11-6.5 11z" />
      <circle cx="12" cy="10" r="2.3" />
    </template>

    <template v-else-if="name === 'lock'">
      <rect x="5" y="11" width="14" height="9.5" rx="2" />
      <path d="M8 11V7.5a4 4 0 018 0V11" />
      <circle cx="12" cy="15.5" r="1.4" fill="currentColor" stroke="none" />
    </template>
  </svg>
</template>

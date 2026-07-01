<script setup>
import { ref, onUnmounted } from 'vue'

const props = defineProps({
  ultimoDescanso:   Number,
  descansandoHasta: Number,
  peDescanso:       Number,
})

const emit = defineEmits(['iniciar-descanso', 'completar-descanso', 'volver'])

const opciones = [
  { id: 'corto',    label: '🌙 Descanso corto',    minutos: 15,  pe: 10 },
  { id: 'largo',    label: '😴 Descanso largo',    minutos: 40,  pe: 25 },
  { id: 'profundo', label: '🏕️ Descanso profundo', minutos: 120, pe: 40 },
]

const COOLDOWN = 6 * 60 * 60 * 1000

const tiempoRestante    = ref(
  props.descansandoHasta ? Math.max(0, props.descansandoHasta - Date.now()) : 0
)
const tiempoPostDescanso = ref(
  props.ultimoDescanso ? Math.max(0, (props.ultimoDescanso + COOLDOWN) - Date.now()) : 0
)

let intervalo         = null
let intervaloPostDesc = null

if (props.descansandoHasta && props.descansandoHasta > Date.now()) {
  iniciarContador()
}

if (props.ultimoDescanso && (props.ultimoDescanso + COOLDOWN) > Date.now()) {
  iniciarContadorPostDescanso()
}

function enCooldown() {
  return tiempoPostDescanso.value > 0
}

function tiempoCooldown() {
  return tiempoPostDescanso.value
}

function estaDescansando() {
  return props.descansandoHasta !== null && tiempoRestante.value > 0
}

function iniciarContador() {
  if (intervalo) clearInterval(intervalo)
  intervalo = setInterval(() => {
    tiempoRestante.value = Math.max(0, tiempoRestante.value - 1000)
    if (tiempoRestante.value <= 0) {
      clearInterval(intervalo)
      tiempoPostDescanso.value = COOLDOWN
      iniciarContadorPostDescanso()
      emit('completar-descanso')
    }
  }, 1000)
}

function iniciarContadorPostDescanso() {
  if (intervaloPostDesc) clearInterval(intervaloPostDesc)
  intervaloPostDesc = setInterval(() => {
    tiempoPostDescanso.value = Math.max(0, tiempoPostDescanso.value - 1000)
    if (tiempoPostDescanso.value <= 0) {
      clearInterval(intervaloPostDesc)
    }
  }, 1000)
}

function elegirDescanso(opcion) {
  tiempoRestante.value = opcion.minutos * 60 * 1000
  emit('iniciar-descanso', { minutos: opcion.minutos, pe: opcion.pe })
  setTimeout(() => iniciarContador(), 50)
}

function formatearTiempo(ms) {
  const totalSegundos = Math.ceil(ms / 1000)
  const horas    = Math.floor(totalSegundos / 3600)
  const minutos  = Math.floor((totalSegundos % 3600) / 60)
  const segundos = totalSegundos % 60
  if (horas > 0)   return horas + 'h ' + minutos + 'm ' + segundos + 's'
  if (minutos > 0) return minutos + 'm ' + segundos + 's'
  return segundos + 's'
}

onUnmounted(() => {
  if (intervalo) clearInterval(intervalo)
  if (intervaloPostDesc) clearInterval(intervaloPostDesc)
})
</script>

<template>
  <div class="rest-view">
    <button class="btn-volver" @click="emit('volver')">← Volver</button>

    <h2>Descanso</h2>
    <p class="subtitulo">Recupera los PE de tu equipo descansando.</p>

    <!-- Descansando actualmente -->
    <div v-if="estaDescansando()" class="descansando">
      <span class="descanso-icono">😴</span>
      <p>Tu equipo está descansando...</p>
      <div class="countdown">{{ formatearTiempo(tiempoRestante) }}</div>
      <p class="pe-info">Recuperarás <strong>+{{ peDescanso }} PE</strong> al terminar</p>
    </div>

    <!-- En cooldown -->
    <div v-else-if="enCooldown()" class="bloqueado">
      <span class="descanso-icono">⏳</span>
      <p>Tu equipo aún se está recuperando.</p>
      <div class="countdown">{{ formatearTiempo(tiempoCooldown()) }}</div>
      <p class="pe-info">Podrás descansar de nuevo en ese tiempo.</p>
    </div>

    <!-- Opciones de descanso -->
    <div v-else class="opciones">
      <div
        v-for="opcion in opciones"
        class="opcion-card"
        @click="elegirDescanso(opcion)"
      >
        <span class="opcion-icono">{{ opcion.label.split(' ')[0] }}</span>
        <div class="opcion-info">
          <span class="opcion-nombre">{{ opcion.label.slice(2) }}</span>
          <span class="opcion-tiempo">⏱ {{ opcion.minutos < 60 ? opcion.minutos + ' minutos' : (opcion.minutos / 60) + ' horas' }}</span>
        </div>
        <span class="opcion-pe">+{{ opcion.pe }} PE</span>
      </div>
    </div>


  </div>
</template>

<style scoped>
.rest-view {
  padding: 32px;
  font-family: sans-serif;
  max-width: 500px;
}

h2 {
  font-size: 1.6rem;
  margin-bottom: 4px;
}

.subtitulo {
  color: #666;
  margin-bottom: 32px;
  font-size: 0.95rem;
}

/* Descansando */
.descansando,
.bloqueado {
  text-align: center;
  padding: 40px 24px;
  border: 2px solid #e0e0e0;
  border-radius: 14px;
  margin-bottom: 24px;
}

.descanso-icono {
  font-size: 3rem;
  display: block;
  margin-bottom: 12px;
}

.countdown {
  font-size: 2rem;
  font-weight: bold;
  color: #222;
  margin: 12px 0;
}

.pe-info {
  color: #666;
  font-size: 0.9rem;
}

.bloqueado p {
  color: #888;
}

/* Opciones */
.opciones {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-bottom: 24px;
}

.opcion-card {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px 20px;
  border: 2px solid #e0e0e0;
  border-radius: 12px;
  cursor: pointer;
  transition: border-color 0.2s, box-shadow 0.2s;
}

.opcion-card:hover {
  border-color: #888;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
}

.opcion-icono {
  font-size: 1.8rem;
}

.opcion-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
  flex: 1;
}

.opcion-nombre {
  font-weight: bold;
  font-size: 0.95rem;
}

.opcion-tiempo {
  font-size: 0.82rem;
  color: #888;
}

.opcion-pe {
  font-weight: bold;
  font-size: 1rem;
  color: #2dc653;
}

.btn-volver {
  display: block;
  margin: 0 auto 20px;
  padding: 8px 18px;
  background: white;
  border: 2px solid #ccc;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.88rem;
  color: #555;
  transition: border-color 0.2s, color 0.2s;
}

.btn-volver:hover { border-color: #888; color: #222; }
</style>

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
  padding: 32px; /* espacio interno de la vista de descanso */
  font-family: sans-serif; /* tipografía base del componente */
  max-width: 500px; /* ancho máximo del panel de descanso */
}

h2 {
  font-size: 1.6rem; /* tamaño del título "Descanso" */
  margin-bottom: 4px; /* mínima separación del título al subtítulo */
}

.subtitulo {
  color: #666; /* color gris del subtítulo explicativo */
  margin-bottom: 32px; /* separación del subtítulo al bloque activo */
  font-size: 0.95rem; /* tamaño reducido del subtítulo */
}

/* Descansando */
.descansando,
.bloqueado {
  text-align: center; /* centra ícono, texto y contador */
  padding: 40px 24px; /* espacio interno del panel de estado */
  border: 2px solid #e0e0e0; /* borde gris claro del panel de estado */
  border-radius: 14px; /* esquinas redondeadas del panel */
  margin-bottom: 24px; /* separación inferior del panel de estado */
}

.descanso-icono {
  font-size: 3rem; /* tamaño grande del emoji de estado */
  display: block; /* el emoji ocupa su propia línea */
  margin-bottom: 12px; /* separación del ícono al texto de estado */
}

.countdown {
  font-size: 2rem; /* tamaño grande del temporizador de cuenta regresiva */
  font-weight: bold; /* negrita para destacar el tiempo restante */
  color: #222; /* color oscuro del texto del temporizador */
  margin: 12px 0; /* separación vertical del temporizador */
}

.pe-info {
  color: #666; /* color gris del texto de PE a recuperar */
  font-size: 0.9rem; /* tamaño del texto informativo de PE */
}

.bloqueado p {
  color: #888; /* color gris del texto en estado de cooldown */
}

/* Opciones */
.opciones {
  display: flex; /* tarjetas de opción apiladas verticalmente */
  flex-direction: column; /* columna para apilar las opciones de descanso */
  gap: 12px; /* separación entre cada tarjeta de opción */
  margin-bottom: 24px; /* separación del bloque de opciones al pie */
}

.opcion-card {
  display: flex; /* ícono, info y PE en fila horizontal */
  align-items: center; /* alinea verticalmente los elementos de la tarjeta */
  gap: 16px; /* separación entre ícono, descripción y PE */
  padding: 16px 20px; /* espacio interno de cada tarjeta de opción */
  border: 2px solid #e0e0e0; /* borde gris de la tarjeta de opción */
  border-radius: 12px; /* esquinas redondeadas de la tarjeta */
  cursor: pointer; /* cursor de mano sobre la tarjeta de opción */
  transition: border-color 0.2s, box-shadow 0.2s; /* transición al pasar el cursor */
}

.opcion-card:hover {
  border-color: #888; /* borde oscuro al pasar el cursor */
  box-shadow: 0 2px 8px rgba(0,0,0,0.08); /* sombra sutil al hacer hover */
}

.opcion-icono {
  font-size: 1.8rem; /* tamaño del emoji de la opción de descanso */
}

.opcion-info {
  display: flex; /* nombre y tiempo en columna dentro de la info */
  flex-direction: column; /* apila nombre y duración verticalmente */
  gap: 2px; /* mínima separación entre nombre y tiempo */
  flex: 1; /* la info ocupa el espacio disponible en la fila */
}

.opcion-nombre {
  font-weight: bold; /* nombre de la opción en negrita */
  font-size: 0.95rem; /* tamaño del nombre de la opción de descanso */
}

.opcion-tiempo {
  font-size: 0.82rem; /* tamaño pequeño del texto de duración */
  color: #888; /* color gris de la duración de la opción */
}

.opcion-pe {
  font-weight: bold; /* PE recuperados en negrita */
  font-size: 1rem; /* tamaño del texto de PE de la opción */
  color: #2dc653; /* verde para destacar los PE recuperables */
}

.btn-volver {
  display: block; /* el botón ocupa su propia línea */
  margin: 0 auto 20px; /* centrado con separación inferior */
  padding: 8px 18px; /* espacio interno del botón volver */
  background: white; /* fondo blanco del botón volver */
  border: 2px solid #ccc; /* borde gris claro del botón volver */
  border-radius: 8px; /* esquinas redondeadas del botón */
  cursor: pointer; /* cursor de mano sobre el botón */
  font-size: 0.88rem; /* tamaño de fuente del botón volver */
  color: #555; /* color gris del texto del botón */
  transition: border-color 0.2s, color 0.2s; /* transición suave al hacer hover */
}

.btn-volver:hover {
  border-color: #888; /* oscurece el borde al pasar el cursor */
  color: #222; /* oscurece el texto al hacer hover */
}
</style>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { rarezas, materiales, pokemonesWild } from '../data/pokemonesExploracion.js'

const props = defineProps({
  capturaCooldownHasta: Number,
  capturasDisponibles:  Number,
})

const emit = defineEmits(['volver', 'capturar', 'actualizar-capturas', 'agregar-material'])

const MAX_CAPTURAS = 3
const COOLDOWN_MS  = 3 * 60 * 60 * 1000

const resultado      = ref(null)
const capturado      = ref(false)
const recogido       = ref(false)
const tiempoRestante = ref(
  props.capturaCooldownHasta ? Math.max(0, props.capturaCooldownHasta - Date.now()) : 0
)
const explorarKey    = ref(0)

let intervalo = null

onMounted(() => {
  if (!props.capturaCooldownHasta) return
  if (props.capturaCooldownHasta > Date.now()) {
    iniciarContador()
  } else {
    // El timer ya venció mientras el componente no estaba activo — resetear de inmediato
    emit('actualizar-capturas', { cooldownHasta: null, capturasDisponibles: MAX_CAPTURAS })
  }
})

onUnmounted(() => { if (intervalo) clearInterval(intervalo) })

function obtenerRareza(id) {
  return rarezas.find(r => r.id === id)
}

function enCooldown() {
  return props.capturaCooldownHasta !== null && tiempoRestante.value > 0
}

function iniciarContador() {
  if (intervalo) clearInterval(intervalo)
  intervalo = setInterval(() => {
    tiempoRestante.value = Math.max(0, tiempoRestante.value - 1000)
    if (tiempoRestante.value <= 0) {
      clearInterval(intervalo)
      emit('actualizar-capturas', { cooldownHasta: null, capturasDisponibles: MAX_CAPTURAS })
    }
  }, 1000)
}

function capturar() {
  if (props.capturasDisponibles <= 0 || enCooldown()) return
  emit('capturar', resultado.value.pokemon)
  capturado.value = true
  const nuevas = props.capturasDisponibles - 1
  if (nuevas <= 0) {
    const nuevoCooldown = Date.now() + COOLDOWN_MS
    emit('actualizar-capturas', { cooldownHasta: nuevoCooldown, capturasDisponibles: 0 })
    tiempoRestante.value = COOLDOWN_MS
    setTimeout(() => iniciarContador(), 50)
  } else {
    emit('actualizar-capturas', { cooldownHasta: null, capturasDisponibles: nuevas })
  }
}

function recoger() {
  emit('agregar-material', resultado.value.material)
  recogido.value = true
}

function explorar() {
  capturado.value = false
  recogido.value  = false
  explorarKey.value++

  const rng          = Math.floor(Math.random() * 100) + 1
  const calificados  = pokemonesWild.filter(p => rng >= obtenerRareza(p.rareza).umbral)

  if (calificados.length === 0) {
    const rngPool = Math.random() * 100
    let pool
    if (rngPool < 25) {
      pool = materiales.filter(m => m.tipo === 'curativo-elemental')
    } else if (rngPool < 30) {
      pool = materiales.filter(m => m.tipo === 'ascension')
    } else {
      pool = materiales.filter(m => m.tipo === 'curativo' || m.tipo === 'general')
    }
    const material = pool[Math.floor(Math.random() * pool.length)]
    resultado.value = { tipo: 'material', material }
    return
  }

  const maxUmbral  = Math.max(...calificados.map(p => obtenerRareza(p.rareza).umbral))
  const mejores    = calificados.filter(p => obtenerRareza(p.rareza).umbral === maxUmbral)
  const encontrado = mejores[Math.floor(Math.random() * mejores.length)]
  resultado.value  = { tipo: 'pokemon', pokemon: encontrado }
}

function formatearTiempo(ms) {
  const s = Math.ceil(ms / 1000)
  const h = Math.floor(s / 3600)
  const m = Math.floor((s % 3600) / 60)
  const sec = s % 60
  if (h > 0) return h + 'h ' + m + 'm ' + sec + 's'
  if (m > 0) return m + 'm ' + sec + 's'
  return sec + 's'
}

onUnmounted(() => { if (intervalo) clearInterval(intervalo) })
</script>

<template>
  <div class="explore-view">

    <!-- Header -->
    <div class="header">
      <h2>Explorar</h2>
      <p class="subtitulo">Busca Pokémon salvajes o recoge materiales del entorno.</p>

      <div class="capturas-info">
        <span v-if="enCooldown()" class="capturas-agotadas">
          ⏳ Capturas disponibles en: <strong>{{ formatearTiempo(tiempoRestante) }}</strong>
        </span>
        <span v-else class="capturas-disponibles">
          Capturas disponibles:
          <span v-for="i in MAX_CAPTURAS" :key="i" class="bolita" :class="{ usada: i > capturasDisponibles }">●</span>
        </span>
      </div>
    </div>

    <!-- Zona de resultado (altura fija) -->
    <div class="zona-resultado">
      <Transition name="fade" mode="out-in">

        <!-- Sin resultado -->
        <div v-if="resultado === null" :key="'inicial'" class="estado-inicial">
          <span class="zona-icono">🌲</span>
          <p>La zona está tranquila. ¿Te adentras?</p>
        </div>

        <!-- Encuentro Pokémon -->
        <div v-else-if="resultado.tipo === 'pokemon'" :key="'pokemon-' + explorarKey" class="encuentro">
          <p class="encuentro-titulo">¡Apareció un Pokémon salvaje!</p>
          <div class="pokemon-card" :style="{ borderColor: resultado.pokemon.colorElemento }">
            <div class="pokemon-header" :style="{ backgroundColor: resultado.pokemon.colorElemento }">
              <div class="pokemon-info">
                <span class="pokemon-nombre">{{ resultado.pokemon.nombre }}</span>
                <span class="pokemon-elemento">{{ resultado.pokemon.elemento }}</span>
              </div>
              <span class="rareza-badge" :style="{ backgroundColor: obtenerRareza(resultado.pokemon.rareza).color }">
                {{ obtenerRareza(resultado.pokemon.rareza).label }}
              </span>
            </div>
            <p class="pokemon-desc">{{ resultado.pokemon.descripcion }}</p>
            <div class="pokemon-stats">
              <div v-for="(valor, nombre) in resultado.pokemon.stats" class="stat-fila">
                <span class="stat-nombre">{{ nombre }}</span>
                <span class="stat-valor">{{ valor }}</span>
              </div>
            </div>

            <div class="captura-accion">
              <button
                v-if="!capturado"
                class="btn-capturar"
                :disabled="capturasDisponibles <= 0 || enCooldown()"
                :style="capturasDisponibles > 0 && !enCooldown() ? { backgroundColor: resultado.pokemon.colorElemento } : {}"
                @click="capturar"
              >
                {{ enCooldown() ? 'Sin capturas' : '¡Capturar!' }}
              </button>
              <div v-else class="capturado-aviso">✓ ¡{{ resultado.pokemon.nombre }} fue capturado!</div>
            </div>
          </div>
        </div>

        <!-- Material encontrado -->
        <div v-else :key="'material-' + explorarKey" class="material-encontrado">
          <p class="encuentro-titulo">No encontraste ningún Pokémon...</p>
          <div class="material-card">
            <span class="material-icono">{{ resultado.material.icono }}</span>
            <div class="material-info">
              <span class="material-nombre">{{ resultado.material.nombre }}</span>
              <span class="material-desc">{{ resultado.material.descripcion }}</span>
            </div>
          </div>
          <div class="recoger-accion">
            <button v-if="!recogido" class="btn-recoger" @click="recoger">Recoger</button>
            <div v-else class="recogido-aviso">✓ ¡{{ resultado.material.nombre }} recogido!</div>
          </div>
        </div>

      </Transition>
    </div>

    <!-- Botones fijos -->
    <div class="botones">
      <button class="btn-explorar" @click="explorar">
        {{ resultado === null ? 'Explorar zona' : 'Explorar de nuevo' }}
      </button>
      <button class="btn-volver" @click="emit('volver')">← Volver</button>
    </div>

  </div>
</template>

<style scoped>
.explore-view {
  padding: 20px 28px;
  font-family: sans-serif;
  max-width: 480px;
  display: flex;
  flex-direction: column;
  gap: 0;
}

/* Header */
.header {
  margin-bottom: 14px;
}

h2 {
  font-size: 1.4rem;
  margin-bottom: 2px;
}

.subtitulo {
  color: #666;
  font-size: 0.88rem;
  margin-bottom: 8px;
}

.capturas-info {
  font-size: 0.82rem;
  color: #555;
}

.capturas-disponibles {
  display: flex;
  align-items: center;
  gap: 6px;
}

.bolita {
  font-size: 1rem;
  color: #2dc653;
  transition: color 0.2s;
}

.bolita.usada { color: #ddd; }

.capturas-agotadas {
  color: #e63946;
}

/* Zona resultado - altura fija */
.zona-resultado {
  min-height: 220px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 14px;
}

.zona-resultado > * {
  width: 100%;
}

/* Estado inicial */
.estado-inicial {
  text-align: center;
  color: #aaa;
}

.zona-icono {
  font-size: 2.4rem;
  display: block;
  margin-bottom: 8px;
}

/* Encuentro */
.encuentro-titulo {
  font-size: 0.9rem;
  font-weight: bold;
  margin-bottom: 8px;
  color: #333;
}

/* Card Pokémon */
.pokemon-card {
  border: 2px solid #ccc;
  border-radius: 14px;
  overflow: hidden;
}

.pokemon-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 14px 16px;
  color: white;
}

.pokemon-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.pokemon-nombre { font-size: 1.2rem; font-weight: bold; }
.pokemon-elemento { font-size: 0.82rem; opacity: 0.9; }

.rareza-badge {
  font-size: 0.72rem;
  font-weight: bold;
  padding: 4px 10px;
  border-radius: 20px;
  color: white;
  white-space: nowrap;
}

.pokemon-desc {
  font-size: 0.82rem;
  color: #555;
  padding: 10px 14px;
  margin: 0;
}

.pokemon-stats {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 0 14px 14px;
}

.stat-fila {
  display: flex;
  justify-content: space-between;
  font-size: 0.82rem;
  padding: 3px 6px;
  background: #f9f9f9;
  border-radius: 4px;
}

.stat-nombre { color: #444; }
.stat-valor  { font-weight: bold; color: #222; }

.captura-accion { padding: 10px 14px 14px; }

.btn-capturar {
  width: 100%;
  padding: 10px;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 0.9rem;
  font-weight: bold;
  cursor: pointer;
  background: #ccc;
  transition: filter 0.2s;
}

.btn-capturar:not(:disabled):hover { filter: brightness(0.9); }
.btn-capturar:disabled { cursor: not-allowed; opacity: 0.5; }

.capturado-aviso {
  text-align: center;
  padding: 10px;
  background: #edfff3;
  border: 2px solid #2dc653;
  border-radius: 8px;
  color: #1a9e3f;
  font-weight: bold;
  font-size: 0.9rem;
}

/* Material */
.material-card {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 16px 20px;
  border: 2px solid #e0e0e0;
  border-radius: 14px;
}

.material-icono { font-size: 2rem; flex-shrink: 0; }

.material-info { display: flex; flex-direction: column; gap: 4px; }
.material-nombre { font-weight: bold; font-size: 1rem; color: #222; }
.material-desc { font-size: 0.85rem; color: #666; }

.recoger-accion { margin-top: 10px; }

.btn-recoger {
  width: 100%;
  padding: 10px;
  background: #2d8c4e;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 0.9rem;
  font-weight: bold;
  cursor: pointer;
  transition: filter 0.2s;
}

.btn-recoger:hover { filter: brightness(0.9); }

.recogido-aviso {
  text-align: center;
  padding: 10px;
  background: #edfff3;
  border: 2px solid #2dc653;
  border-radius: 8px;
  color: #1a9e3f;
  font-weight: bold;
  font-size: 0.9rem;
}

/* Botones fijos */
.botones {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.btn-explorar {
  padding: 10px;
  background: #222;
  color: white;
  border: none;
  border-radius: 10px;
  font-size: 0.9rem;
  font-weight: bold;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-explorar:hover { background: #444; }

.btn-volver {
  padding: 10px 20px;
  background: white;
  border: 2px solid #ccc;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.9rem;
  color: #555;
  transition: border-color 0.2s;
}

.btn-volver:hover { border-color: #888; color: #222; }

/* Transición */
.fade-enter-active,
.fade-leave-active { transition: opacity 0.2s, transform 0.2s; }
.fade-enter-from,
.fade-leave-to { opacity: 0; transform: translateY(6px); }
</style>
